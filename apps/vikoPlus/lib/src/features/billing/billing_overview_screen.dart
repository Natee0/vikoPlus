import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/billing/billing_repository.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_screen.dart';

class BillingOverviewScreen extends ConsumerWidget {
  const BillingOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: 'Billing',
      backRoute: '/billing/plans',
      child: activeGroup == null
          ? _MissingGroupState(onChooseGroup: () => context.go('/groups'))
          : FutureBuilder<GroupSubscriptionSummary>(
              future: ref
                  .read(billingRepositoryProvider)
                  .subscription(activeGroup.id),
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthErrorMessage(
                        message: 'No group access subscription is active yet.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: () => context.go('/billing/plans'),
                        child: const Text('Choose Access Plan'),
                      ),
                    ],
                  );
                }

                final subscription = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BillingStatusCard(
                      title: 'Group',
                      value: activeGroup.name,
                      icon: Icons.groups_2_outlined,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _BillingStatusCard(
                      title: 'Access status',
                      value: _statusLabel(subscription),
                      icon: Icons.verified_user_outlined,
                      color: subscription.hasPaidFeatureAccess
                          ? AppColors.secondary
                          : AppColors.warning,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _BillingStatusCard(
                      title: 'Plan',
                      value: subscription.planCode,
                      icon: Icons.workspace_premium_outlined,
                      color: AppColors.tertiaryFixedDim,
                    ),
                    if (subscription.currentPeriodEndsAt != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _BillingStatusCard(
                        title: subscription.cancelAtPeriodEnd
                            ? 'Ends on'
                            : 'Renews on',
                        value: formatters.date(
                          subscription.currentPeriodEndsAt!,
                        ),
                        icon: Icons.event_repeat_outlined,
                        color: AppColors.secondary,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: AppInsets.compactCard,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.primaryContainer,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'This billing only covers Vikoplus platform access. Member contributions and loans remain manual group records.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/billing/plans'),
                      icon: const Icon(Icons.credit_card_outlined),
                      label: const Text('Change access plan'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Open admin dashboard'),
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _statusLabel(GroupSubscriptionSummary subscription) {
    final state = subscription.state.replaceAll('_', ' ').toLowerCase();
    return '${state[0].toUpperCase()}${state.substring(1)}';
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
        const AuthErrorMessage(message: 'Select a group to manage billing.'),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: onChooseGroup,
          child: const Text('Choose Group'),
        ),
      ],
    );
  }
}

class _BillingStatusCard extends StatelessWidget {
  const _BillingStatusCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level1(),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
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
