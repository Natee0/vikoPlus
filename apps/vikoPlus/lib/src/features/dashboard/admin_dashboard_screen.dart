import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/auth/profile_provider.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_logout_controls.dart';
import '../auth/auth_widgets.dart';
import '../common/info_card.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';
import '../notifications/notification_icon_button.dart';
import 'dashboard_monthly_trend_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({this.showBottomNavigation = true, super.key});

  final bool showBottomNavigation;

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String? _loadedDashboardGroupId;
  Future<GroupDashboardResult>? _dashboardFuture;

  Future<GroupDashboardResult>? _dashboardFor(String? groupId) {
    if (groupId == null || groupId.isEmpty) return null;
    if (_loadedDashboardGroupId != groupId || _dashboardFuture == null) {
      _setDashboardFuture(groupId);
    }
    return _dashboardFuture;
  }

  void _setDashboardFuture(
    String groupId, [
    Future<GroupDashboardResult>? future,
  ]) {
    _loadedDashboardGroupId = groupId;
    _dashboardFuture =
        future ?? ref.read(groupsRepositoryProvider).dashboard(groupId);
  }

  Future<void> _refresh() async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) return;
    final future = ref.read(groupsRepositoryProvider).dashboard(activeGroup.id);
    setState(() => _setDashboardFuture(activeGroup.id, future));
    await future;
  }

  String _setupRoute(String path, GroupAccessSummary? group) {
    final route = group == null
        ? path
        : '$path?groupId=${Uri.encodeComponent(group.id)}';
    final separator = route.contains('?') ? '&' : '?';
    return '$route${separator}returnTo=${Uri.encodeComponent('/dashboard')}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final activeGroup = ref.watch(activeGroupProvider);
    final dashboardFuture = _dashboardFor(activeGroup?.id);

    return VikoplusScreen(
      title: activeGroup?.name ?? loc.adminDashboard,
      bottomNavigationIndex: 0,
      showBottomNavigation: widget.showBottomNavigation,
      onRefresh: activeGroup == null ? null : _refresh,
      actions: [
        const NotificationIconButton(),
        IconButton(
          tooltip: loc.myGroups,
          onPressed: () => context.go('/groups'),
          icon: const Icon(Icons.groups_2_outlined),
        ),
        const AuthLogoutIconButton(),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ref.watch(profileDisplayNameProvider).isEmpty
                ? loc.welcomeTitle
                : loc.helloName(ref.watch(profileDisplayNameProvider)),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            activeGroup == null ? loc.selectGroupTools : loc.manageGroupSummary,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),
          _AdminMetricsBlock(
            dashboardFuture: dashboardFuture,
            formatters: formatters,
            totalTitle: loc.totalContributions,
            membersTitle: loc.members,
          ),
          const SizedBox(height: 16),
          SectionHeader(title: loc.monthlyTrend),
          const SizedBox(height: 12),
          _AdminMonthlyTrendBlock(
            dashboardFuture: dashboardFuture,
            formatters: formatters,
          ),
          const SizedBox(height: 16),
          SectionHeader(title: loc.quickActions),
          const SizedBox(height: 12),
          ActionTile(
            title: loc.contributionSetup,
            subtitle: loc.contributionSetupDescription,
            icon: Icons.price_change_outlined,
            route: _setupRoute('/groups/contributions', activeGroup),
            color: AppColors.secondaryGreen,
          ),
          const SizedBox(height: 12),
          ActionTile(
            title: context.vt('Group expenses'),
            subtitle: context.vt('Record and approve group spending'),
            icon: Icons.receipt_long_outlined,
            route: '/expenses',
            color: AppColors.secondaryGreen,
          ),
          const SizedBox(height: 12),
          ActionTile(
            title: loc.historicalRecords,
            subtitle: loc.historicalRecordsDescription,
            icon: Icons.history_edu_outlined,
            route: _setupRoute('/groups/history', activeGroup),
            color: AppColors.gold,
          ),
          const SizedBox(height: 12),
          ActionTile(
            title: loc.loans,
            subtitle: loc.loanReviewDescription,
            icon: Icons.account_balance_wallet_outlined,
            route: '/loans',
            color: AppColors.secondaryGreen,
          ),
          const SizedBox(height: 12),
          ActionTile(
            title: loc.myGroups,
            subtitle: loc.switchGroupsDescription,
            icon: Icons.hub_outlined,
            route: '/groups',
          ),
          const SizedBox(height: 12),
          ActionTile(
            title: loc.reviewPayments,
            subtitle: context.vt('Approve or reject submitted contributions'),
            icon: Icons.fact_check_outlined,
            route: '/contributions',
            color: AppColors.secondaryGreen,
          ),
        ],
      ),
    );
  }
}

class _AdminMetricsBlock extends StatelessWidget {
  const _AdminMetricsBlock({
    required this.dashboardFuture,
    required this.formatters,
    required this.totalTitle,
    required this.membersTitle,
  });

  final Future<GroupDashboardResult>? dashboardFuture;
  final AppFormatters formatters;
  final String totalTitle;
  final String membersTitle;

  @override
  Widget build(BuildContext context) {
    final future = dashboardFuture;
    if (future == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthErrorMessage(
            message: 'Select a group to load live metrics.',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/groups'),
            child: const Text('Choose Group'),
          ),
        ],
      );
    }

    return FutureBuilder<GroupDashboardResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const AuthErrorMessage(
            message: 'Could not load dashboard metrics.',
          );
        }
        final metrics = snapshot.data!.metrics;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoCard(
              title: context.vt('Cash balance'),
              value: formatters.money(metrics.cashBalanceMinor),
              icon: Icons.savings_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: context.vt('Outstanding'),
                    value: formatters.compactMoney(metrics.outstandingMinor),
                    icon: Icons.pending_actions_outlined,
                    accentColor: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InfoCard(
                    title: membersTitle,
                    value: '${metrics.membersCount}',
                    icon: Icons.groups_2_outlined,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AdminMonthlyTrendBlock extends StatelessWidget {
  const _AdminMonthlyTrendBlock({
    required this.dashboardFuture,
    required this.formatters,
  });

  final Future<GroupDashboardResult>? dashboardFuture;
  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    final future = dashboardFuture;
    if (future == null) {
      return DashboardMonthlyTrendCard(
        trend: const [],
        formatters: formatters,
      );
    }
    return FutureBuilder<GroupDashboardResult>(
      future: future,
      builder: (context, snapshot) => DashboardMonthlyTrendCard(
        trend: snapshot.data?.metrics.monthlyTrend ?? const [],
        formatters: formatters,
        loading:
            !snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting,
      ),
    );
  }
}
