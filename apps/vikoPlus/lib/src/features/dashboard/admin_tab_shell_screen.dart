import '../../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../routing/portal_route_guard.dart';

import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';

class AdminTabShellScreen extends ConsumerWidget {
  const AdminTabShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(activeGroupProvider);
    final recordsTab = group?.role == 'SECRETARY';
    final isAdmin = group?.role == 'GROUP_ADMIN';
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: switch (navigationShell.currentIndex) {
          3 => isAdmin ? 3 : 4,
          4 => 4,
          _ => navigationShell.currentIndex,
        },
        onDestinationSelected: (index) {
          if (isAdmin && index == 2) {
            context.go(portalPaymentsRoute(group));
            return;
          }
          if (!isAdmin && index == 3) {
            context.go(portalPaymentsRoute(group));
            return;
          }
          if (!isAdmin && index == 4) {
            context.go(portalMoreRoute(group));
            return;
          }
          if (index == 0) {
            context.go(portalHomeRoute(group));
            return;
          }
          if (recordsTab && index == 2) {
            context.go(portalContributionsRoute(group));
            return;
          }
          if (isAdmin && index == 4) {
            context.go(portalMoreRoute(group));
            return;
          }
          final branchIndex = index;
          if (branchIndex == navigationShell.currentIndex) return;

          navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: AppLocalizations.of(context).home,
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2),
            label: AppLocalizations.of(context).members,
          ),
          if (!isAdmin)
            NavigationDestination(
              icon: Icon(
                recordsTab
                    ? Icons.history_edu_outlined
                    : Icons.savings_outlined,
              ),
              selectedIcon: Icon(
                recordsTab ? Icons.history_edu : Icons.savings,
              ),
              label: recordsTab
                  ? context.vt('Records')
                  : AppLocalizations.of(context).registerTab,
            ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: AppLocalizations.of(context).payments,
          ),
          if (group?.role == 'GROUP_ADMIN')
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: AppLocalizations.of(context).reports,
            ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more),
            label: AppLocalizations.of(context).more,
          ),
        ],
      ),
    );
  }
}
