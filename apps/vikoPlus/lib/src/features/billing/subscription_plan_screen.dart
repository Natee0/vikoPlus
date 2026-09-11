import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/billing/billing_repository.dart';
import '../../core/config/app_config.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_screen.dart';

class SubscriptionPlanScreen extends ConsumerStatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  ConsumerState<SubscriptionPlanScreen> createState() =>
      _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState
    extends ConsumerState<SubscriptionPlanScreen> {
  final _phoneController = TextEditingController();
  String? _selectedPlanCode;
  String? _loadedGroupId;
  Future<AccessPlansResult>? _plansFuture;
  String _checkoutUrl = '';
  bool _walletPromptStarted = false;
  bool _isWaitingForPayment = false;
  int _paymentAttemptToken = 0;
  int _paymentSecondsRemaining = 62;
  String _errorMessage = '';
  bool _isStartingCheckout = false;
  Timer? _paymentExpiryTimer;

  @override
  void dispose() {
    _paymentExpiryTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  Uri _billingReturnUri(String path) {
    final apiBaseUri = Uri.parse(AppConfig.VIKOPLUS_API_BASE_URL);
    return apiBaseUri.replace(path: path, query: '');
  }

  Future<AccessPlansResult>? _plansFor(String? groupId) {
    if (groupId == null || groupId.isEmpty) return null;
    if (_loadedGroupId != groupId || _plansFuture == null) {
      _setPlansFuture(groupId);
    }
    return _plansFuture;
  }

  void _setPlansFuture(String groupId, [Future<AccessPlansResult>? future]) {
    _loadedGroupId = groupId;
    _plansFuture =
        future ?? ref.read(billingRepositoryProvider).accessPlans(groupId);
  }

  Future<void> _refresh() async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) return;
    final future = ref
        .read(billingRepositoryProvider)
        .accessPlans(activeGroup.id);
    setState(() => _setPlansFuture(activeGroup.id, future));
    await future;
  }

  AccessPlanSummary? _selectedPlan(List<AccessPlanSummary> plans) {
    for (final plan in plans) {
      if (plan.code == _selectedPlanCode) return plan;
    }
    if (plans.isEmpty) return null;
    return plans.first;
  }

  Future<void> _startCheckout(
    String groupId,
    AccessPlanSummary plan,
  ) async {
    if (_isStartingCheckout || _isWaitingForPayment) return;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = context.vt(
          'Enter a phone number to receive the Sayari Pay USSD prompt.',
        );
      });
      return;
    }

    try {
      final attemptToken = ++_paymentAttemptToken;
      setState(() {
        _checkoutUrl = '';
        _walletPromptStarted = false;
        _isWaitingForPayment = false;
        _paymentSecondsRemaining = 62;
        _errorMessage = '';
        _isStartingCheckout = true;
      });
      final checkout = await ref
          .read(billingRepositoryProvider)
          .createAccessCheckout(
            groupId,
            AccessCheckoutInput(
              planCode: plan.code,
              successUrl: _billingReturnUri('/billing/success').toString(),
              cancelUrl: _billingReturnUri('/billing/cancelled').toString(),
              buyerPhone: phone,
            ),
          );
      if (!mounted) return;
      setState(() {
        _checkoutUrl = checkout.checkoutUrl;
        _walletPromptStarted = checkout.walletPaymentStarted;
        _isWaitingForPayment = checkout.walletPaymentStarted;
      });
      if (checkout.walletPaymentStarted) {
        _startPaymentExpiryTimer(groupId, attemptToken);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            checkout.walletPaymentStarted
                ? context.vt('Payment prompt sent to your phone.')
                : context.vt('Checkout link is ready.'),
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = context.vt(AuthFailure.from(error).message));
    } finally {
      if (mounted) {
        setState(() => _isStartingCheckout = false);
      }
    }
  }

  void _startPaymentExpiryTimer(String groupId, int attemptToken) {
    _paymentExpiryTimer?.cancel();
    final expiresAt = DateTime.now().add(const Duration(seconds: 62));
    setState(() => _paymentSecondsRemaining = 62);
    _paymentExpiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || attemptToken != _paymentAttemptToken) {
        timer.cancel();
        return;
      }
      final remaining = expiresAt.difference(DateTime.now()).inSeconds + 1;
      final nextRemaining = remaining.clamp(0, 62).toInt();
      if (_paymentSecondsRemaining != nextRemaining) {
        setState(() => _paymentSecondsRemaining = nextRemaining);
      }
      if (nextRemaining <= 0) {
        timer.cancel();
        _expirePaymentAttempt(groupId, attemptToken);
      }
    });
  }

  Future<void> _expirePaymentAttempt(String groupId, int attemptToken) async {
    if (!mounted || attemptToken != _paymentAttemptToken) return;
    final billing = ref.read(billingRepositoryProvider);
    try {
      final latest = await billing.subscription(groupId);
      if (!mounted || attemptToken != _paymentAttemptToken) return;
      if (latest.hasPaidFeatureAccess) {
        ref.read(activeGroupProvider.notifier).updateSubscriptionAccess(
              hasPaidFeatureAccess: latest.hasPaidFeatureAccess,
              planCode: latest.planCode,
              stateValue: latest.state,
              endsAt: latest.currentPeriodEndsAt,
            );
        _paymentExpiryTimer?.cancel();
        setState(() {
          _isWaitingForPayment = false;
          _paymentSecondsRemaining = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.vt('Payment confirmed.'))),
        );
        return;
      }
    } on Object {
      // If status lookup fails, still try to cancel the expired prompt below.
    }

    try {
      await billing.cancelSubscription(groupId);
    } on Object {
      // The prompt has already expired on the phone; keep the UI recoverable.
    }

    if (!mounted || attemptToken != _paymentAttemptToken) return;
    setState(() {
      _walletPromptStarted = false;
      _isWaitingForPayment = false;
      _paymentSecondsRemaining = 62;
      _checkoutUrl = '';
      _errorMessage = context.vt(
        'Payment prompt expired. Please try again.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: context.vt('Group Access'),
      backRoute: '/groups/onboarding-success',
      onRefresh: activeGroup == null ? null : _refresh,
      child: activeGroup == null
          ? _MissingGroupState(onChooseGroup: () => context.go('/groups'))
          : FutureBuilder<AccessPlansResult>(
              future: _plansFor(activeGroup.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return AuthErrorMessage(
                    message: context.vt('Could not load access plans.'),
                  );
                }

                final plans = snapshot.data!.plans;
                final selected = _selectedPlan(plans);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${context.vt('Activate')} ${activeGroup.name}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.vt(
                        'The group administrator pays platform access for this group. Member contributions remain separate manual records.',
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (plans.isEmpty)
                      const _NoPlansCard()
                    else ...[
                      for (final plan in plans) ...[
                        _AccessPlanCard(
                          plan: plan,
                          price: formatters.money(
                            plan.priceMinor,
                            currency: plan.currency,
                          ),
                          selected:
                              plan.code == (_selectedPlanCode ?? selected?.code),
                          onTap: () {
                            setState(() => _selectedPlanCode = plan.code);
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                    AuthField(
                      label: context.vt('Payment phone number'),
                      hint: context.vt('Example: 0744000000'),
                      icon: Icons.phone_iphone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      helperText: context.vt(
                        'Sayari Pay will send a USSD prompt to this number.',
                      ),
                      onSubmitted: (_) {
                        if (selected != null && !_isWaitingForPayment) {
                          _startCheckout(activeGroup.id, selected);
                        }
                      },
                    ),
                    if (_walletPromptStarted || _checkoutUrl.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _PaymentPromptCard(
                        url: _checkoutUrl,
                        walletPromptStarted: _walletPromptStarted,
                        secondsRemaining: _paymentSecondsRemaining,
                        onCopy: () async {
                          if (_checkoutUrl.isEmpty) return;
                          await Clipboard.setData(
                            ClipboardData(text: _checkoutUrl),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.vt('Checkout link copied.'),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    AuthErrorMessage(message: _errorMessage),
                    if (_errorMessage.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: selected == null || _isStartingCheckout
                          ? null
                          : _isWaitingForPayment
                              ? null
                              : () => _startCheckout(activeGroup.id, selected),
                      icon: _isStartingCheckout
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_outline, size: 18),
                      label: Text(
                        _isStartingCheckout
                            ? context.vt('Sending payment prompt')
                            : _isWaitingForPayment
                                ? context.vt('Waiting for confirmation')
                                : context.vt('Send payment prompt'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => context.go('/dashboard'),
                      child: Text(context.vt('Open admin dashboard')),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _MissingGroupState extends StatelessWidget {
  const _MissingGroupState({required this.onChooseGroup});

  final VoidCallback onChooseGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthErrorMessage(
          message: context.vt('Select a group to manage billing.'),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: onChooseGroup,
          child: Text(context.vt('Choose Group')),
        ),
      ],
    );
  }
}

class _NoPlansCard extends StatelessWidget {
  const _NoPlansCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.vt('Access plans are not available yet.'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessPlanCard extends StatelessWidget {
  const _AccessPlanCard({
    required this.plan,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final AccessPlanSummary plan;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryContainer.withValues(alpha: 0.08)
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          padding: AppInsets.card,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected
                  ? AppColors.primaryContainer
                  : AppColors.outlineVariant,
            ),
            boxShadow: AppShadows.level1(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          _billingCadence(plan),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? AppColors.primary : AppColors.outline,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                price,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (plan.description?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  plan.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
              if (plan.trialDays > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                _IncludedFeature(
                  label: context.vt('{days} days free trial').replaceAll(
                        '{days}',
                        '${plan.trialDays}',
                      ),
                ),
              ],
              _IncludedFeature(
                label: context.vt('Admin dashboard and member register'),
              ),
              _IncludedFeature(
                label: context.vt('Contribution tracking and reports'),
              ),
              _IncludedFeature(
                label: context.vt(
                  'Manual member payments stay separate from app access',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _billingCadence(AccessPlanSummary plan) {
    final interval = plan.interval == 'YEAR' ? 'year' : 'month';
    if (plan.intervalCount == 1) return 'Per group, billed every $interval';
    return 'Per group, billed every ${plan.intervalCount} ${interval}s';
  }
}

class _IncludedFeature extends StatelessWidget {
  const _IncludedFeature({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentPromptCard extends StatelessWidget {
  const _PaymentPromptCard({
    required this.url,
    required this.walletPromptStarted,
    required this.secondsRemaining,
    required this.onCopy,
  });

  final String url;
  final bool walletPromptStarted;
  final int secondsRemaining;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final isUssdPrompt = walletPromptStarted && url.isEmpty;
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: isUssdPrompt
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.secondary,
                  ),
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
                  isUssdPrompt
                      ? context.vt(
                          'Open the USSD prompt, enter your mobile money PIN, and keep this screen open while we confirm payment.',
                        )
                      : url.isEmpty
                      ? context.vt('Waiting for payment confirmation.')
                      : url,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                if (isUssdPrompt) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Text(
                      context
                          .vt('{seconds}s remaining to confirm')
                          .replaceAll('{seconds}', '$secondsRemaining'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (url.isNotEmpty)
            IconButton(
              tooltip: context.vt('Copy checkout link'),
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined),
            ),
        ],
      ),
    );
  }
}
