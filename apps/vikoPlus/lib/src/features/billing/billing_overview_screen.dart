import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/billing/billing_repository.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../routing/portal_route_guard.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_screen.dart';

class BillingOverviewScreen extends ConsumerStatefulWidget {
  const BillingOverviewScreen({super.key});

  @override
  ConsumerState<BillingOverviewScreen> createState() =>
      _BillingOverviewScreenState();
}

class _BillingOverviewScreenState extends ConsumerState<BillingOverviewScreen> {
  String? _loadedGroupId;
  Future<GroupSubscriptionSummary>? _subscriptionFuture;

  Future<GroupSubscriptionSummary> _subscriptionFor(String groupId) {
    if (_loadedGroupId != groupId || _subscriptionFuture == null) {
      _setSubscriptionFuture(groupId);
    }
    return _subscriptionFuture!;
  }

  void _setSubscriptionFuture(
    String groupId, [
    Future<GroupSubscriptionSummary>? future,
  ]) {
    _loadedGroupId = groupId;
    _subscriptionFuture =
        future ?? ref.read(billingRepositoryProvider).subscription(groupId);
  }

  Future<void> _refresh() async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) return;
    final future = ref
        .read(billingRepositoryProvider)
        .subscription(activeGroup.id);
    setState(() => _setSubscriptionFuture(activeGroup.id, future));
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: context.vt('Service Payment Summary'),
      backRoute: portalHomeRoute(activeGroup),
      preferBackRoute: true,
      onRefresh: activeGroup == null ? null : _refresh,
      child: activeGroup == null
          ? _MissingGroupState(onChooseGroup: () => context.go('/groups'))
          : FutureBuilder<GroupSubscriptionSummary>(
              future: _subscriptionFor(activeGroup.id),
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
                      AuthErrorMessage(
                        message: context.vt(
                          'No group access subscription is active yet.',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: () => context.go('/billing/plans'),
                        child: Text(context.vt('Choose Access Plan')),
                      ),
                    ],
                  );
                }

                final subscription = snapshot.data!;
                if (activeGroup.hasPaidFeatureAccess !=
                        subscription.hasPaidFeatureAccess ||
                    activeGroup.subscriptionPlanCode != subscription.planCode ||
                    activeGroup.subscriptionState != subscription.state ||
                    activeGroup.subscriptionEndsAt !=
                        subscription.currentPeriodEndsAt) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ref
                        .read(activeGroupProvider.notifier)
                        .updateSubscriptionAccess(
                          hasPaidFeatureAccess:
                              subscription.hasPaidFeatureAccess,
                          planCode: subscription.planCode,
                          stateValue: subscription.state,
                          endsAt: subscription.currentPeriodEndsAt,
                        );
                  });
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BillingStatusCard(
                      title: context.vt('Group'),
                      value: activeGroup.name,
                      icon: Icons.groups_2_outlined,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _BillingStatusCard(
                      title: context.vt('Access status'),
                      value: _statusLabel(context, subscription),
                      icon: Icons.verified_user_outlined,
                      color: subscription.hasPaidFeatureAccess
                          ? AppColors.secondary
                          : AppColors.warning,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _BillingStatusCard(
                      title: context.vt('Plan'),
                      value: subscription.planCode,
                      icon: Icons.workspace_premium_outlined,
                      color: AppColors.tertiaryFixedDim,
                    ),
                    if (subscription.currentPeriodEndsAt != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _BillingStatusCard(
                        title: subscription.cancelAtPeriodEnd
                            ? context.vt('Ends on')
                            : context.vt('Renews on'),
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
                              context.vt(
                                'This billing only covers Vikoplus platform access. Member contributions and loans remain manual group records.',
                              ),
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
                      label: Text(context.vt('Change access plan')),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: () => context.go(portalHomeRoute(activeGroup)),
                      child: Text(context.vt('Open admin dashboard')),
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _statusLabel(
    BuildContext context,
    GroupSubscriptionSummary subscription,
  ) {
    final state = subscription.state.replaceAll('_', ' ').toLowerCase();
    final label = '${state[0].toUpperCase()}${state.substring(1)}';
    return context.vt(label);
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
