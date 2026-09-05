import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_logout_controls.dart';
import '../auth/auth_widgets.dart';
import '../common/info_card.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';
import '../notifications/notification_icon_button.dart';

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

    return VikoplusScreen(
      title: activeGroup?.name ?? 'Admin Dashboard',
      bottomNavigationIndex: 0,
      showBottomNavigation: widget.showBottomNavigation,
      onRefresh: activeGroup == null ? null : _refresh,
      actions: [
        const NotificationIconButton(),
        IconButton(
          tooltip: 'My groups',
          onPressed: () => context.go('/groups'),
          icon: const Icon(Icons.groups_2_outlined),
        ),
        const AuthLogoutIconButton(),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hello, Admin',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            activeGroup == null
                ? 'Select a group to load live administration tools.'
                : 'Manage contributions, members, loans and reminders.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),
          _AdminMetricsBlock(
            dashboardFuture: _dashboardFor(activeGroup?.id),
            formatters: formatters,
            totalTitle: loc.totalContributions,
            membersTitle: loc.members,
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Monthly trend'),
          const SizedBox(height: 12),
          const _MonthlyTrendPlaceholder(),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Record payment',
            subtitle: 'Allocate a contribution across one or more periods',
            icon: Icons.add_card_outlined,
            route: '/contributions/record',
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Members',
            subtitle: 'Review balances, roles and contact details',
            icon: Icons.groups_2_outlined,
            route: '/members',
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Loans',
            subtitle: 'Borrowing power, active loans and repayment tracking',
            icon: Icons.account_balance_wallet_outlined,
            route: '/loans',
            color: AppColors.secondaryGreen,
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Reports',
            subtitle: 'View outstanding dues and member analysis',
            icon: Icons.analytics_outlined,
            route: '/reports',
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Reminder Centre',
            subtitle: 'Create campaigns, templates and delivery tracking',
            icon: Icons.notifications_active_outlined,
            route: '/reminders',
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Admin settings',
            subtitle: 'Roles, fees, penalties, security and audit logs',
            icon: Icons.tune_outlined,
            route: '/settings/admin',
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'My groups',
            subtitle:
                'Switch groups, create another group or join by invitation',
            icon: Icons.hub_outlined,
            route: '/groups',
          ),
          const SizedBox(height: 12),
          ActionTile(
            title: 'Contribution setup',
            subtitle:
                'Set joining fee, membership contribution and payment rules',
            icon: Icons.price_change_outlined,
            route: _setupRoute('/groups/contributions', activeGroup),
            color: AppColors.secondaryGreen,
          ),
          const SizedBox(height: 12),
          ActionTile(
            title: 'Historical records',
            subtitle: 'Import old contribution data one by one or in bulk',
            icon: Icons.history_edu_outlined,
            route: _setupRoute('/groups/history', activeGroup),
            color: AppColors.gold,
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
          const AuthErrorMessage(message: 'Select a group to load live metrics.'),
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
              title: totalTitle,
              value: formatters.money(metrics.collectedMinor),
              icon: Icons.savings_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Outstanding',
                    value: formatters.money(metrics.outstandingMinor),
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

class _MonthlyTrendPlaceholder extends StatelessWidget {
  const _MonthlyTrendPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.show_chart, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Monthly trend will appear after approved contribution payments are available.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
