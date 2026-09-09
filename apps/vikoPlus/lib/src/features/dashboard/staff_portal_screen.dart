import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/profile_provider.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';
import '../notifications/notification_icon_button.dart';
import 'dashboard_monthly_trend_card.dart';

class StaffPortalScreen extends ConsumerStatefulWidget {
  const StaffPortalScreen({super.key});

  @override
  ConsumerState<StaffPortalScreen> createState() => _StaffPortalScreenState();
}

class _StaffPortalScreenState extends ConsumerState<StaffPortalScreen> {
  String? _groupId;
  Future<GroupDashboardResult>? _future;

  Future<GroupDashboardResult> _load(String id) {
    return ref.read(groupsRepositoryProvider).dashboard(id);
  }

  Future<void> _refresh() async {
    final id = ref.read(activeGroupProvider)?.id;
    if (id == null) {
      return;
    }
    final future = _load(id);
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    if (_groupId != group?.id) {
      _groupId = group?.id;
      _future = group == null ? null : _load(group.id);
    }
    final displayName = ref.watch(profileDisplayNameProvider);
    final secretaryName = displayName.isEmpty
        ? context.vt('Welcome')
        : displayName;

    return VikoplusScreen(
      title: group?.name ?? context.vt('Secretary Portal'),
      bottomNavigationIndex: 0,
      showBackButton: false,
      onRefresh: _refresh,
      actions: const [NotificationIconButton(), AuthLogoutIconButton()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _timeGreeting(context),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            secretaryName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            context.vt('Manage member records and group documentation.'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<GroupDashboardResult>(
            future: _future,
            builder: (context, snapshot) {
              final metrics = snapshot.data?.metrics;
              final formatters = AppFormatters(
                Localizations.localeOf(context).toLanguageTag(),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SecretarySummaryCard(
                    membersCount: metrics?.membersCount ?? 0,
                    collected: formatters.compactMoney(
                      metrics?.collectedMinor ?? 0,
                    ),
                    outstanding: formatters.compactMoney(
                      metrics?.outstandingMinor ?? 0,
                    ),
                    loading:
                        !snapshot.hasData &&
                        snapshot.connectionState == ConnectionState.waiting,
                  ),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AuthErrorMessage(
                      message: context.vt('Could not load dashboard metrics.'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  SectionHeader(title: context.vt('Monthly trend')),
                  const SizedBox(height: AppSpacing.xs),
                  DashboardMonthlyTrendCard(
                    trend: metrics?.monthlyTrend ?? const [],
                    formatters: formatters,
                    loading:
                        !snapshot.hasData &&
                        snapshot.connectionState == ConnectionState.waiting,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: context.vt('Secretary duties')),
          const SizedBox(height: AppSpacing.xs),
          _SecretaryActionTile(
            title: context.vt('Member directory'),
            subtitle: context.vt('View member contacts, roles and status'),
            icon: Icons.groups_2_outlined,
            route: '/members',
          ),
          const SizedBox(height: AppSpacing.xs),
          _SecretaryActionTile(
            title: context.vt('Historical records'),
            subtitle: context.vt('Import previous group records'),
            icon: Icons.history_edu_outlined,
            route: group == null
                ? '/groups'
                : '/groups/history?groupId=${Uri.encodeComponent(group.id)}&returnTo=${Uri.encodeComponent('/secretary/dashboard')}',
          ),
          const SizedBox(height: AppSpacing.xs),
          _SecretaryActionTile(
            title: context.vt('Send reminders'),
            subtitle: context.vt('Prepare notices for members with dues'),
            icon: Icons.notifications_active_outlined,
            route: '/reminders/new',
          ),
          const SizedBox(height: AppSpacing.xs),
          _SecretaryActionTile(
            title: context.vt('Review payments'),
            subtitle: context.vt('Approve or reject submitted contributions'),
            icon: Icons.fact_check_outlined,
            route: '/contributions',
          ),
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: context.vt('Personal actions')),
          const SizedBox(height: AppSpacing.xs),
          _SecretaryActionTile(
            title: context.vt('My payments'),
            subtitle: context.vt('Pay your own group contributions'),
            icon: Icons.payments_outlined,
            route: '/payments/select',
          ),
          const SizedBox(height: AppSpacing.xs),
          _SecretaryActionTile(
            title: context.vt('My loans'),
            subtitle: context.vt('Applications, guarantees and repayments'),
            icon: Icons.account_balance_wallet_outlined,
            route: '/loans',
          ),
        ],
      ),
    );
  }

  String _timeGreeting(BuildContext context) {
    final isSwahili = Localizations.localeOf(context).languageCode == 'sw';
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return isSwahili ? 'Habari za asubuhi,' : 'Good morning,';
    }
    if (hour < 17) {
      return isSwahili ? 'Habari za mchana,' : 'Good afternoon,';
    }
    return isSwahili ? 'Habari za jioni,' : 'Good evening,';
  }
}

class _SecretarySummaryCard extends StatelessWidget {
  const _SecretarySummaryCard({
    required this.membersCount,
    required this.collected,
    required this.outstanding,
    required this.loading,
  });

  final int membersCount;
  final String collected;
  final String outstanding;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: AppColors.onPrimary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  context.vt('Group records snapshot'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _SnapshotMetric(
                label: context.vt('Members'),
                value: '$membersCount',
              ),
              _SnapshotMetric(label: context.vt('Collected'), value: collected),
              _SnapshotMetric(
                label: context.vt('Outstanding'),
                value: outstanding,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecretaryActionTile extends StatelessWidget {
  const _SecretaryActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ActionTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      route: route,
      color: AppColors.primary,
    );
  }
}
