import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/billing/payment_realtime_client.dart';
import '../../core/config/app_config.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/group_setup_draft.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_screen.dart';

class ConfigureRemindersScreen extends ConsumerStatefulWidget {
  const ConfigureRemindersScreen({this.groupId, this.returnTo, super.key});

  final String? groupId;
  final String? returnTo;

  @override
  ConsumerState<ConfigureRemindersScreen> createState() =>
      _ConfigureRemindersScreenState();
}

class _ConfigureRemindersScreenState
    extends ConsumerState<ConfigureRemindersScreen> {
  static const _paymentWaitSeconds = 180;

  static const _template =
      'Hi {member_name}, this is a friendly reminder that your payment of {amount} for your group is due soon.';

  String _errorMessage = '';
  String _checkoutUrl = '';
  String? _selectedPackageCode;
  String? _loadedPackagesGroupId;
  Future<ReminderPackagesResult>? _packagesFuture;
  final _paymentPhoneController = TextEditingController();
  final _customReminderCreditsController = TextEditingController(text: '10');
  final _continueActionKey = GlobalKey();
  Timer? _paymentExpiryTimer;
  bool _isSubmitting = false;
  bool _isStartingCheckout = false;
  bool _walletPromptStarted = false;
  bool _isWaitingForPayment = false;
  bool _isPollingPaymentStatus = false;
  bool _reminderPaymentConfirmed = false;
  bool _useCustomReminderCredits = false;
  int _paymentAttemptToken = 0;
  int _creditBalanceBeforePayment = 0;
  bool _enabled = false;
  bool _loadingSettings = true;
  bool _settingsLoaded = false;
  int _paymentSecondsRemaining = _paymentWaitSeconds;
  StreamSubscription<PaymentRealtimeEvent>? _paymentEventsSubscription;
  final Set<int> _offsets = {-3, 0};

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSettings);
  }

  @override
  void dispose() {
    _paymentExpiryTimer?.cancel();
    _paymentEventsSubscription?.cancel();
    _paymentPhoneController.dispose();
    _customReminderCreditsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final id = _groupId;
    try {
      if (id != null) {
        final settings = await ref
            .read(groupsRepositoryProvider)
            .reminderSettings(id);
        if (!mounted) {
          return;
        }
        setState(() {
          _enabled = settings['enabled'] == true;
          _settingsLoaded = true;
          _offsets
            ..clear()
            ..addAll((settings['offsets'] as List? ?? [-3, 0]).cast<int>());
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = context.vt(AuthFailure.from(error).message));
      }
    } finally {
      if (mounted) {
        setState(() => _loadingSettings = false);
      }
    }
  }

  String? get _groupId {
    final widgetGroupId = widget.groupId;
    if (widgetGroupId != null && widgetGroupId.isNotEmpty) {
      return widgetGroupId;
    }
    final draftGroupId = ref.read(groupSetupDraftProvider).createdGroupId;
    if (draftGroupId != null && draftGroupId.isNotEmpty) {
      return draftGroupId;
    }
    return ref.read(activeGroupProvider)?.id;
  }

  String get _backRoute {
    final returnTo = widget.returnTo;
    if (returnTo != null && returnTo.isNotEmpty) {
      return returnTo;
    }
    if (widget.groupId == null && ref.read(activeGroupProvider) != null) {
      return '/dashboard';
    }

    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) {
      return '/groups/contributions';
    }
    return '/groups/contributions?groupId=${Uri.encodeComponent(groupId)}';
  }

  Uri _billingReturnUri(String path) {
    final apiBaseUri = Uri.parse(AppConfig.VIKOPLUS_API_BASE_URL);
    return apiBaseUri.replace(path: path, query: '');
  }

  Future<void> _startPackageCheckout(
    ReminderPackageSummary package,
    int quantity,
  ) async {
    final groupId = _groupId;
    if (_isStartingCheckout) {
      return;
    }
    if (groupId == null || groupId.isEmpty) {
      setState(
        () => _errorMessage = context.vt(
          'Create a group before buying reminders.',
        ),
      );
      return;
    }
    final phone = _paymentPhoneController.text.trim();
    if (phone.isEmpty) {
      setState(
        () => _errorMessage = context.vt(
          'Enter a phone number to receive the Sayari Pay USSD prompt.',
        ),
      );
      return;
    }
    if (quantity < 1) {
      setState(
        () => _errorMessage = context.vt(
          'Enter the number of reminder credits to buy.',
        ),
      );
      return;
    }

    try {
      final attemptToken = ++_paymentAttemptToken;
      final repository = ref.read(groupsRepositoryProvider);
      setState(() {
        _errorMessage = '';
        _checkoutUrl = '';
        _isStartingCheckout = true;
        _walletPromptStarted = false;
        _isWaitingForPayment = false;
      });
      final currentCredits = await repository.reminderPackages(groupId);
      if (!mounted || attemptToken != _paymentAttemptToken) {
        return;
      }
      setState(() {
        _creditBalanceBeforePayment = currentCredits.credits.remaining;
        _reminderPaymentConfirmed = false;
      });
      final checkout = await repository.createReminderPackageCheckout(
            groupId,
            ReminderPackageCheckoutInput(
              packageCode: package.code,
              quantity: quantity,
              successUrl: _billingReturnUri('/billing/success').toString(),
              cancelUrl: _billingReturnUri('/billing/cancelled').toString(),
              buyerPhone: phone,
            ),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _checkoutUrl = checkout.walletPaymentStarted ? '' : checkout.checkoutUrl;
        _walletPromptStarted = checkout.walletPaymentStarted;
        _isWaitingForPayment = checkout.walletPaymentStarted;
      });
      if (checkout.walletPaymentStarted) {
        _startPaymentExpiryTimer(groupId, attemptToken);
        _watchPaymentEvents(groupId, attemptToken);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            checkout.walletPaymentStarted
                ? context.vt('Reminder payment prompt sent to your phone.')
                : context.vt('Checkout link is ready.'),
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = context.vt(AuthFailure.from(error).message));
    } finally {
      if (mounted) {
        setState(() => _isStartingCheckout = false);
      }
    }
  }

  void _startPaymentExpiryTimer(String groupId, int attemptToken) {
    _paymentExpiryTimer?.cancel();
    final expiresAt = DateTime.now().add(
      const Duration(seconds: _paymentWaitSeconds),
    );
    setState(() => _paymentSecondsRemaining = _paymentWaitSeconds);
    _paymentExpiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || attemptToken != _paymentAttemptToken) {
        timer.cancel();
        return;
      }
      final remaining = expiresAt.difference(DateTime.now()).inSeconds + 1;
      final nextRemaining = remaining.clamp(0, _paymentWaitSeconds).toInt();
      if (_paymentSecondsRemaining != nextRemaining) {
        setState(() => _paymentSecondsRemaining = nextRemaining);
      }
      if (nextRemaining <= 0) {
        timer.cancel();
        final confirmed = await _confirmReminderPaymentIfReady(
          groupId,
          attemptToken,
        );
        if (confirmed) return;
        await _paymentEventsSubscription?.cancel();
        _paymentEventsSubscription = null;
        setState(() {
          _walletPromptStarted = false;
          _isWaitingForPayment = false;
          _paymentSecondsRemaining = _paymentWaitSeconds;
          _checkoutUrl = '';
          _errorMessage = context.vt(
            'Payment prompt expired. If you confirmed payment, pull to refresh before buying again.',
          );
        });
      } else if (nextRemaining % 3 == 0) {
        final confirmed = await _confirmReminderPaymentIfReady(
          groupId,
          attemptToken,
        );
        if (confirmed) {
          timer.cancel();
        }
      }
    });
  }

  void _watchPaymentEvents(String groupId, int attemptToken) {
    _paymentEventsSubscription?.cancel();
    _paymentEventsSubscription = ref
        .read(paymentRealtimeClientProvider)
        .watchGroup(groupId)
        .listen((event) {
      if (!mounted ||
          attemptToken != _paymentAttemptToken ||
          event.groupId != groupId ||
          event.productType != 'reminder-package' ||
          !event.isConfirmed) {
        return;
      }
      unawaited(_confirmReminderPaymentIfReady(groupId, attemptToken));
    });
  }

  Future<bool> _confirmReminderPaymentIfReady(
    String groupId,
    int attemptToken,
  ) async {
    if (_isPollingPaymentStatus ||
        !mounted ||
        attemptToken != _paymentAttemptToken) {
      return false;
    }
    _isPollingPaymentStatus = true;
    try {
      final result = await ref.read(groupsRepositoryProvider).reminderPackages(
            groupId,
          );
      if (!mounted || attemptToken != _paymentAttemptToken) return false;
      if (result.credits.remaining <= _creditBalanceBeforePayment) {
        return false;
      }
      final future = Future<ReminderPackagesResult>.value(result);
      final messenger = ScaffoldMessenger.of(context);
      final confirmedMessage = context.vt('Payment confirmed.');
      _paymentExpiryTimer?.cancel();
      await _paymentEventsSubscription?.cancel();
      _paymentEventsSubscription = null;
      if (!mounted || attemptToken != _paymentAttemptToken) return false;
      setState(() {
        _setPackagesFuture(groupId, future);
        _walletPromptStarted = false;
        _isWaitingForPayment = false;
        _reminderPaymentConfirmed = true;
        _paymentSecondsRemaining = 0;
        _checkoutUrl = '';
        _errorMessage = '';
      });
      messenger.showSnackBar(SnackBar(content: Text(confirmedMessage)));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetContext = _continueActionKey.currentContext;
        if (!mounted || targetContext == null) return;
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.82,
        );
      });
      return true;
    } on Object {
      return false;
    } finally {
      _isPollingPaymentStatus = false;
    }
  }

  ReminderPackageSummary? _selectedPackage(
    List<ReminderPackageSummary> packages,
  ) {
    for (final package in packages) {
      if (package.code == _selectedPackageCode) {
        return package;
      }
    }
    if (packages.isEmpty) {
      return null;
    }
    return packages.first;
  }

  void _setPackagesFuture(
    String groupId, [
    Future<ReminderPackagesResult>? future,
  ]) {
    _loadedPackagesGroupId = groupId;
    _packagesFuture =
        future ?? ref.read(groupsRepositoryProvider).reminderPackages(groupId);
  }

  Future<ReminderPackagesResult>? _packagesFor(String? groupId) {
    if (groupId == null || groupId.isEmpty) {
      return null;
    }
    if (_loadedPackagesGroupId != groupId || _packagesFuture == null) {
      _setPackagesFuture(groupId);
    }
    return _packagesFuture;
  }

  Future<void> _refresh() async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) {
      return;
    }
    final future = ref.read(groupsRepositoryProvider).reminderPackages(groupId);
    setState(() => _setPackagesFuture(groupId, future));
    await future;
    await _loadSettings();
  }

  Future<void> _save({required bool configureLater}) async {
    final groupId = _groupId;
    if (_isSubmitting || _loadingSettings) {
      return;
    }
    if (!_settingsLoaded) {
      setState(
        () => _errorMessage = context.vt(
          'Refresh to load the current reminder settings before saving.',
        ),
      );
      return;
    }
    if (groupId == null || groupId.isEmpty) {
      setState(
        () => _errorMessage = context.vt(
          'Create a group before setting reminders.',
        ),
      );
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      await ref
          .read(groupsRepositoryProvider)
          .saveReminderSettings(
            groupId,
            ReminderSettingsInput(
              dueReminderTemplate: configureLater
                  ? null
                  : Localizations.localeOf(context).languageCode == 'sw'
                  ? 'Habari {member_name}, malipo yako ya {amount} yanatakiwa tarehe {due_date}.'
                  : _template,
              enabled: !configureLater && _enabled,
              offsets: _offsets.toList()..sort(),
              locale: Localizations.localeOf(context).languageCode,
            ),
          );
      if (!mounted) {
        return;
      }
      ref.read(groupSetupDraftProvider.notifier).reset();
      final returnTo = widget.returnTo;
      if (returnTo != null && returnTo.isNotEmpty) {
        context.go(returnTo);
      } else if (widget.groupId == null &&
          ref.read(activeGroupProvider) != null) {
        context.go('/dashboard');
      } else {
        context.go(
          '/groups/onboarding-success?groupId=${Uri.encodeComponent(groupId)}',
        );
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = context.vt(AuthFailure.from(error).message));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupId = _groupId;
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: context.vt('Configure Reminders'),
      backRoute: _backRoute,
      preferBackRoute: true,
      onRefresh: groupId == null ? null : _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReminderPackagePicker(
            groupId: groupId,
            packagesFuture: _packagesFor(groupId),
            selectedPackageCode: _selectedPackageCode,
            isStartingCheckout: _isStartingCheckout,
            isWaitingForPayment: _isWaitingForPayment,
            isPaymentConfirmed: _reminderPaymentConfirmed,
            useCustomReminderCredits: _useCustomReminderCredits,
            paymentPhoneController: _paymentPhoneController,
            customReminderCreditsController: _customReminderCreditsController,
            formatters: formatters,
            selectedPackage: _selectedPackage,
            onPackageSelected: (code) {
              setState(() => _selectedPackageCode = code);
            },
            onCustomModeChanged: (value) {
              setState(() => _useCustomReminderCredits = value);
            },
            onCustomCreditsChanged: (_) => setState(() {}),
            onStartCheckout: _startPackageCheckout,
          ),
          if (!_reminderPaymentConfirmed) ...[
            if (_walletPromptStarted || _checkoutUrl.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _ReminderPaymentPromptCard(
                walletPromptStarted: _walletPromptStarted,
                url: _checkoutUrl,
                secondsRemaining: _paymentSecondsRemaining,
              ),
            ],
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            const _ReminderPaymentConfirmedCard(),
          ],
          const SizedBox(height: AppSpacing.md),
          _ScheduleAccordion(
            offsets: _offsets,
            enabled: !_loadingSettings,
            onChanged: (offset, selected) => setState(() {
              if (selected) {
                _offsets.add(offset);
              } else {
                _offsets.remove(offset);
              }
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          _ToggleCard(
            value: _enabled,
            onChanged: _loadingSettings
                ? null
                : (value) => setState(() => _enabled = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthErrorMessage(message: _errorMessage),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            key: _continueActionKey,
            onPressed: _isSubmitting
                ? null
                : () => _save(configureLater: false),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSizes.inputHeight),
            ),
            label: Text(
              _isSubmitting
                  ? context.vt('Saving')
                  : context.vt('Save and Continue'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: _isSubmitting ? null : () => _save(configureLater: true),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSizes.inputHeight),
            ),
            child: Text(context.vt('Configure Later')),
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level1(),
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          value: value,
          contentPadding: EdgeInsets.zero,
          onChanged: onChanged,
          title: Text(
            context.vt('Enable Automatic Reminders'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            context.vt(
              'Send automated payment alerts to members. Admin pays messaging costs separately from member contributions.',
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderPackagePicker extends StatelessWidget {
  const _ReminderPackagePicker({
    required this.groupId,
    required this.packagesFuture,
    required this.selectedPackageCode,
    required this.isStartingCheckout,
    required this.isWaitingForPayment,
    required this.isPaymentConfirmed,
    required this.useCustomReminderCredits,
    required this.paymentPhoneController,
    required this.customReminderCreditsController,
    required this.formatters,
    required this.selectedPackage,
    required this.onPackageSelected,
    required this.onCustomModeChanged,
    required this.onCustomCreditsChanged,
    required this.onStartCheckout,
  });

  final String? groupId;
  final Future<ReminderPackagesResult>? packagesFuture;
  final String? selectedPackageCode;
  final bool isStartingCheckout;
  final bool isWaitingForPayment;
  final bool isPaymentConfirmed;
  final bool useCustomReminderCredits;
  final TextEditingController paymentPhoneController;
  final TextEditingController customReminderCreditsController;
  final AppFormatters formatters;
  final ReminderPackageSummary? Function(List<ReminderPackageSummary> packages)
  selectedPackage;
  final ValueChanged<String> onPackageSelected;
  final ValueChanged<bool> onCustomModeChanged;
  final ValueChanged<String> onCustomCreditsChanged;
  final void Function(ReminderPackageSummary package, int quantity)
  onStartCheckout;

  @override
  Widget build(BuildContext context) {
    final currentGroupId = groupId;
    if (currentGroupId == null || currentGroupId.isEmpty) {
      return AuthErrorMessage(
        message: context.vt(
          'Create a group before choosing reminder packages.',
        ),
      );
    }

    return FutureBuilder<ReminderPackagesResult>(
      future: packagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return AuthErrorMessage(
            message: context.vt('Could not load reminder packages.'),
          );
        }

        final result = snapshot.data!;
        final packages = result.packages;
        if (packages.isEmpty) {
          return Container(
            padding: AppInsets.compactCard,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Text(
              context.vt('Reminder package prices are not available yet.'),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          );
        }

        final selected = selectedPackage(packages);
        final customQuantity =
            int.tryParse(customReminderCreditsController.text.trim()) ?? 0;
        final checkoutQuantity = useCustomReminderCredits
            ? customQuantity
            : selected?.quantity ?? 0;
        final totalMinor = (selected?.amountMinor ?? 0) * checkoutQuantity;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReminderCreditCard(credits: result.credits),
            const SizedBox(height: AppSpacing.md),
            _SectionLabel(context.vt('Reminder Package')),
            const SizedBox(height: AppSpacing.sm),
            _ReminderPurchaseModeSelector(
              useCustom: useCustomReminderCredits,
              onChanged: onCustomModeChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (useCustomReminderCredits) ...[
              DropdownButtonFormField<String>(
                initialValue: selected?.code,
                decoration: InputDecoration(
                  labelText: context.vt('Package name'),
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
                items: [
                  for (final package in packages)
                    DropdownMenuItem(
                      value: package.code,
                      child: Text(package.name),
                    ),
                ],
                onChanged: isStartingCheckout || isWaitingForPayment
                    ? null
                    : (value) {
                        if (value != null) onPackageSelected(value);
                      },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: customReminderCreditsController,
                enabled: !isStartingCheckout && !isWaitingForPayment,
                keyboardType: TextInputType.number,
                onChanged: onCustomCreditsChanged,
                decoration: InputDecoration(
                  labelText: context.vt('Custom reminder credits'),
                  hintText: '100',
                  prefixIcon: const Icon(Icons.add_card_outlined),
                  helperText: context.vt(
                    'Enter how many reminder credits you want to buy.',
                  ),
                ),
              ),
              if (selected != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _customPackageHelper(context, selected),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ] else ...[
              for (final package in packages) ...[
                _ReminderPackageTile(
                  package: package,
                  price: _packagePrice(context, package),
                  selected:
                      package.code ==
                      (selectedPackageCode ?? selected?.code ?? ''),
                  onTap: () => onPackageSelected(package.code),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
            if (!isPaymentConfirmed) ...[
              const SizedBox(height: AppSpacing.xs),
              _CheckoutTotalCard(
                total: formatters.money(
                  totalMinor,
                  currency: selected?.currency ?? 'TZS',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AuthField(
                label: context.vt('Payment phone number'),
                hint: '0785 123 456',
                icon: Icons.phone_android_outlined,
                controller: paymentPhoneController,
                keyboardType: TextInputType.phone,
                helperText: context.vt(
                  'Sayari Pay will send a USSD prompt to this number.',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed:
                    selected == null ||
                        isStartingCheckout ||
                        isWaitingForPayment ||
                        checkoutQuantity < 1
                    ? null
                    : () => onStartCheckout(selected, checkoutQuantity),
                icon: isStartingCheckout || isWaitingForPayment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_outline, size: 18),
                label: Text(
                  isStartingCheckout
                      ? context.vt('Sending payment prompt')
                      : isWaitingForPayment
                      ? context.vt('Waiting for confirmation')
                      : context.vt('Buy reminder package'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size.fromHeight(AppSizes.inputHeight),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _packagePrice(
    BuildContext context,
    ReminderPackageSummary package,
  ) {
    final creditsLabel = context.vt(
      package.quantity == 1 ? 'message' : 'messages',
    );
    final price = formatters.money(
      package.amountMinor,
      currency: package.currency,
    );
    return '${package.quantity} $creditsLabel - '
        '$price ${context.vt('per message')}';
  }

  String _customPackageHelper(
    BuildContext context,
    ReminderPackageSummary package,
  ) {
    final price = formatters.money(
      package.amountMinor,
      currency: package.currency,
    );
    return '${_channelLabel(context, package.channel)} · '
        '$price ${context.vt('per message')}';
  }

  String _channelLabel(BuildContext context, String? channel) {
    return switch (channel) {
      'SMS' => context.vt('SMS reminders'),
      'WHATSAPP' => context.vt('WhatsApp reminders'),
      'BOTH' => context.vt('SMS and WhatsApp reminders'),
      _ => context.vt('Reminder messages'),
    };
  }
}

class _ReminderPurchaseModeSelector extends StatelessWidget {
  const _ReminderPurchaseModeSelector({
    required this.useCustom,
    required this.onChanged,
  });

  final bool useCustom;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment(
          value: false,
          icon: const Icon(Icons.inventory_2_outlined, size: 18),
          label: Text(context.vt('Preset packages')),
        ),
        ButtonSegment(
          value: true,
          icon: const Icon(Icons.tune_outlined, size: 18),
          label: Text(context.vt('Custom credits')),
        ),
      ],
      selected: {useCustom},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ReminderCreditCard extends StatelessWidget {
  const _ReminderCreditCard({required this.credits});

  final ReminderCreditSummary credits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.vt('Reminder credits'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${context.vt('Purchased')}: ${credits.purchased} · '
                  '${context.vt('Used')}: ${credits.used}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${credits.remaining}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderPaymentPromptCard extends StatelessWidget {
  const _ReminderPaymentPromptCard({
    required this.walletPromptStarted,
    required this.url,
    required this.secondsRemaining,
  });

  final bool walletPromptStarted;
  final String url;
  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            walletPromptStarted
                ? Icons.phone_android_outlined
                : Icons.check_circle_outline,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.vt(
                    walletPromptStarted
                        ? 'Payment prompt sent'
                        : 'Checkout link ready',
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  walletPromptStarted
                      ? context.vt(
                          'Enter your mobile money PIN on the phone prompt. Reminder credits unlock after Sayari confirms payment.',
                        )
                      : url,
                  maxLines: walletPromptStarted ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                if (walletPromptStarted) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${context.vt('Waiting for confirmation')} '
                    '(${secondsRemaining}s)',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderPaymentConfirmedCard extends StatelessWidget {
  const _ReminderPaymentConfirmedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.vt('Reminder package purchased'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  context.vt(
                    'Finish the reminder schedule, then save to continue.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderPackageTile extends StatelessWidget {
  const _ReminderPackageTile({
    required this.package,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final ReminderPackageSummary package;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.secondaryContainer.withValues(alpha: 0.35)
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          padding: AppInsets.compactCard,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _channelIcon(package.channel),
                color: selected ? AppColors.secondary : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      package.description?.isNotEmpty == true
                          ? package.description!
                          : _channelLabel(context, package.channel),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      price,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.secondary : AppColors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _channelIcon(String? channel) {
    return switch (channel) {
      'SMS' => Icons.sms_outlined,
      'WHATSAPP' => Icons.chat_outlined,
      'BOTH' => Icons.forum_outlined,
      _ => Icons.campaign_outlined,
    };
  }

  String _channelLabel(BuildContext context, String? channel) {
    return switch (channel) {
      'SMS' => context.vt('SMS reminders'),
      'WHATSAPP' => context.vt('WhatsApp reminders'),
      'BOTH' => context.vt('SMS and WhatsApp reminders'),
      _ => context.vt('Reminder messages'),
    };
  }
}

class _CheckoutTotalCard extends StatelessWidget {
  const _CheckoutTotalCard({required this.total});

  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.vt('Estimated checkout total'),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          Text(
            total,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleAccordion extends StatelessWidget {
  const _ScheduleAccordion({
    required this.offsets,
    required this.enabled,
    required this.onChanged,
  });

  final Set<int> offsets;
  final bool enabled;
  final void Function(int offset, bool selected) onChanged;

  static const _entries = {
    -30: '30 days before due date',
    -21: '21 days before due date',
    -14: '14 days before due date',
    -7: '7 days before due date',
    -3: '3 days before due date',
    -1: '1 day before due date',
    0: 'On due date',
    1: '1 day overdue',
    3: '3 days overdue',
    7: '7 days overdue',
    14: '14 days overdue',
  };

  @override
  Widget build(BuildContext context) {
    final selectedLabel = context.vtf('{count} selected', {
      'count': offsets.length,
    });
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        leading: const Icon(Icons.event_repeat_outlined),
        title: Text(
          context.vt('Schedule'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(selectedLabel),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        children: [
          for (final entry in _entries.entries) ...[
            _ScheduleTile(
              label: context.vt(entry.value),
              selected: offsets.contains(entry.key),
              onChanged: enabled
                  ? (selected) => onChanged(entry.key, selected == true)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.label,
    required this.onChanged,
    this.selected = false,
  });
  final ValueChanged<bool?>? onChanged;

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Checkbox(value: selected, onChanged: onChanged),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

