import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_logout_controls.dart';
import '../auth/auth_widgets.dart';
import '../common/info_card.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({this.showBottomNavigation = true, super.key});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final activeGroup = ref.watch(activeGroupProvider);

    return VikoplusScreen(
      title: loc.adminDashboardTitle,
      bottomNavigationIndex: 0,
      showBottomNavigation: showBottomNavigation,
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.go('/notifications'),
          icon: const Badge(
            smallSize: 8,
            child: Icon(Icons.notifications_outlined),
          ),
        ),
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
            'Current group: ${activeGroup?.name ?? sofiaFinancialYear}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),
          _AdminMetricsBlock(
            groupId: activeGroup?.id,
            formatters: formatters,
            totalTitle: loc.totalContributions,
            membersTitle: loc.members,
          ),
          const SizedBox(height: 12),
          ProgressBlock(
            title: "This month's collection",
            value: formatters.money(65000),
            caption: '13 paid, 10 outstanding for July',
            progress: 0.65,
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Monthly trend'),
          const SizedBox(height: 12),
          _MonthlyTrend(formatters: formatters),
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
          const ActionTile(
            title: 'Contribution setup',
            subtitle:
                'Set joining fee, membership contribution and payment rules',
            icon: Icons.price_change_outlined,
            route: '/groups/contributions',
            color: AppColors.secondaryGreen,
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Historical records',
            subtitle: 'Import old contribution data one by one or in bulk',
            icon: Icons.history_edu_outlined,
            route: '/groups/history',
            color: AppColors.gold,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(loc.contributionRule),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMetricsBlock extends ConsumerWidget {
  const _AdminMetricsBlock({
    required this.groupId,
    required this.formatters,
    required this.totalTitle,
    required this.membersTitle,
  });

  final String? groupId;
  final AppFormatters formatters;
  final String totalTitle;
  final String membersTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = groupId;
    if (id == null || id.isEmpty) {
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
      future: ref.read(groupsRepositoryProvider).dashboard(id),
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

class _MonthlyTrend extends StatelessWidget {
  const _MonthlyTrend({required this.formatters});

  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    const maxValue = 65000;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 164,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final entry in sofiaMonthTotals)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: formatters.money(entry.$2),
                          child: Container(
                            height: 92 * (entry.$2 / maxValue),
                            constraints: const BoxConstraints(minHeight: 8),
                            decoration: BoxDecoration(
                              color: entry.$1 == 'Jul'
                                  ? AppColors.primaryGreen
                                  : AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.$1,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
