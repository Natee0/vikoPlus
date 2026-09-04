import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/group_setup_draft.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_screen.dart';

class ConfigureRemindersScreen extends ConsumerStatefulWidget {
  const ConfigureRemindersScreen({this.groupId, super.key});

  final String? groupId;

  @override
  ConsumerState<ConfigureRemindersScreen> createState() =>
      _ConfigureRemindersScreenState();
}

class _ConfigureRemindersScreenState
    extends ConsumerState<ConfigureRemindersScreen> {
  static const _template =
      'Hi {member_name}, this is a friendly reminder that your payment of {amount} for Sofia Wajukuu is due soon.';

  String _errorMessage = '';
  String _checkoutUrl = '';
  String? _selectedPackageCode;
  String? _loadedPackagesGroupId;
  Future<ReminderPackagesResult>? _packagesFuture;
  int _packageQuantity = 100;
  bool _isSubmitting = false;
  bool _isStartingCheckout = false;

  String? get _groupId {
    final widgetGroupId = widget.groupId;
    if (widgetGroupId != null && widgetGroupId.isNotEmpty) {
      return widgetGroupId;
    }
    return ref.read(groupSetupDraftProvider).createdGroupId;
  }

  Uri _billingReturnUri(String path) {
    final apiBaseUri = Uri.parse(AppConfig.VIKOPLUS_API_BASE_URL);
    return apiBaseUri.replace(path: path, query: '');
  }

  Future<void> _startPackageCheckout(ReminderPackageSummary package) async {
    final groupId = _groupId;
    if (_isStartingCheckout) return;
    if (groupId == null || groupId.isEmpty) {
      setState(() => _errorMessage = 'Create a group before buying reminders.');
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _checkoutUrl = '';
        _isStartingCheckout = true;
      });
      final checkout = await ref
          .read(groupsRepositoryProvider)
          .createReminderPackageCheckout(
            groupId,
            ReminderPackageCheckoutInput(
              packageCode: package.code,
              quantity: _packageQuantity,
              successUrl: _billingReturnUri('/billing/success').toString(),
              cancelUrl: _billingReturnUri('/billing/cancelled').toString(),
            ),
          );
      await Clipboard.setData(ClipboardData(text: checkout.checkoutUrl));
      if (!mounted) return;
      setState(() => _checkoutUrl = checkout.checkoutUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout link copied to clipboard.')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isStartingCheckout = false);
      }
    }
  }

  ReminderPackageSummary? _selectedPackage(
    List<ReminderPackageSummary> packages,
  ) {
    for (final package in packages) {
      if (package.code == _selectedPackageCode) return package;
    }
    if (packages.isEmpty) return null;
    return packages.first;
  }

  Future<ReminderPackagesResult>? _packagesFor(String? groupId) {
    if (groupId == null || groupId.isEmpty) return null;
    if (_loadedPackagesGroupId != groupId || _packagesFuture == null) {
      _loadedPackagesGroupId = groupId;
      _packagesFuture = ref.read(groupsRepositoryProvider).reminderPackages(
            groupId,
          );
    }
    return _packagesFuture;
  }

  Future<void> _save({required bool configureLater}) async {
    final groupId = _groupId;
    if (_isSubmitting) return;
    if (groupId == null || groupId.isEmpty) {
      setState(() => _errorMessage = 'Create a group before setting reminders.');
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      await ref.read(groupsRepositoryProvider).saveReminderSettings(
            groupId,
            ReminderSettingsInput(
              dueReminderTemplate: configureLater ? null : _template,
            ),
          );
      if (!mounted) return;
      ref.read(groupSetupDraftProvider.notifier).reset();
      context.go(
        '/groups/onboarding-success?groupId=${Uri.encodeComponent(groupId)}',
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
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
      title: 'Configure Reminders',
      backRoute: groupId == null
          ? '/groups/contributions'
          : '/groups/contributions?groupId=${Uri.encodeComponent(groupId)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ToggleCard(),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Reminder Package'),
          const SizedBox(height: AppSpacing.sm),
          _ReminderPackagePicker(
            groupId: groupId,
            packagesFuture: _packagesFor(groupId),
            selectedPackageCode: _selectedPackageCode,
            packageQuantity: _packageQuantity,
            isStartingCheckout: _isStartingCheckout,
            formatters: formatters,
            selectedPackage: _selectedPackage,
            onPackageSelected: (code) {
              setState(() => _selectedPackageCode = code);
            },
            onQuantityChanged: (quantity) {
              setState(() => _packageQuantity = quantity);
            },
            onStartCheckout: _startPackageCheckout,
          ),
          if (_checkoutUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _CheckoutLinkCard(
              url: _checkoutUrl,
              onCopy: () async {
                await Clipboard.setData(ClipboardData(text: _checkoutUrl));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checkout link copied.')),
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Schedule'),
          const SizedBox(height: AppSpacing.sm),
          const _ScheduleTile(label: '3 days before due date', selected: true),
          const SizedBox(height: AppSpacing.xs),
          const _ScheduleTile(label: 'On due date', selected: true),
          const SizedBox(height: AppSpacing.xs),
          const _ScheduleTile(label: '3 days overdue'),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Message Preview'),
          const SizedBox(height: AppSpacing.sm),
          const _MessagePreview(),
          const SizedBox(height: AppSpacing.md),
          AuthErrorMessage(message: _errorMessage),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed:
                _isSubmitting ? null : () => _save(configureLater: false),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: Text(_isSubmitting ? 'Saving' : 'Save and Continue'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: _isSubmitting ? null : () => _save(configureLater: true),
            child: const Text('Configure Later'),
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard();

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
          value: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (_) {},
          title: Text(
            'Enable Automatic Reminders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: const Text(
            'Send automated payment alerts to members. Admin pays messaging costs separately from member contributions.',
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
    required this.packageQuantity,
    required this.isStartingCheckout,
    required this.formatters,
    required this.selectedPackage,
    required this.onPackageSelected,
    required this.onQuantityChanged,
    required this.onStartCheckout,
  });

  final String? groupId;
  final Future<ReminderPackagesResult>? packagesFuture;
  final String? selectedPackageCode;
  final int packageQuantity;
  final bool isStartingCheckout;
  final AppFormatters formatters;
  final ReminderPackageSummary? Function(List<ReminderPackageSummary> packages)
      selectedPackage;
  final ValueChanged<String> onPackageSelected;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<ReminderPackageSummary> onStartCheckout;

  @override
  Widget build(BuildContext context) {
    final currentGroupId = groupId;
    if (currentGroupId == null || currentGroupId.isEmpty) {
      return const AuthErrorMessage(
        message: 'Create a group before choosing reminder packages.',
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
          return const AuthErrorMessage(
            message: 'Could not load reminder packages.',
          );
        }

        final packages = snapshot.data!.packages;
        if (packages.isEmpty) {
          return Container(
            padding: AppInsets.compactCard,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Text(
              'Reminder package prices are not available yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          );
        }

        final selected = selectedPackage(packages);
        final totalMinor = (selected?.amountMinor ?? 0) * packageQuantity;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final package in packages) ...[
              _ReminderPackageTile(
                package: package,
                price: '${formatters.money(
                  package.amountMinor,
                  currency: package.currency,
                )} per message',
                selected: package.code ==
                    (selectedPackageCode ?? selected?.code ?? ''),
                onTap: () => onPackageSelected(package.code),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<int>(
              initialValue: packageQuantity,
              decoration: const InputDecoration(
                labelText: 'Message credits',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 100, child: Text('100 messages')),
                DropdownMenuItem(value: 500, child: Text('500 messages')),
                DropdownMenuItem(value: 1000, child: Text('1,000 messages')),
                DropdownMenuItem(value: 5000, child: Text('5,000 messages')),
              ],
              onChanged: (value) {
                if (value == null) return;
                onQuantityChanged(value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _CheckoutTotalCard(
              total: formatters.money(
                totalMinor,
                currency: selected?.currency ?? 'TZS',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: selected == null || isStartingCheckout
                  ? null
                  : () => onStartCheckout(selected),
              icon: isStartingCheckout
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline, size: 18),
              label: Text(
                isStartingCheckout
                    ? 'Creating checkout'
                    : 'Create checkout link',
              ),
            ),
          ],
        );
      },
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

class _CheckoutLinkCard extends StatelessWidget {
  const _CheckoutLinkCard({required this.url, required this.onCopy});

  final String url;
  final VoidCallback onCopy;

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
          const Icon(Icons.check_circle_outline, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkout link ready',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy checkout link',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined),
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
                          : _channelLabel(package.channel),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
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

  String _channelLabel(String? channel) {
    return switch (channel) {
      'SMS' => 'SMS reminders',
      'WHATSAPP' => 'WhatsApp reminders',
      'BOTH' => 'SMS and WhatsApp reminders',
      _ => 'Reminder messages',
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
              'Estimated checkout total',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
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

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.label, this.selected = false});

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
          Checkbox(value: selected, onChanged: (_) {}),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Hi {member_name}, this is a friendly reminder that your payment of {amount} for Sofia Wajukuu is due soon.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
