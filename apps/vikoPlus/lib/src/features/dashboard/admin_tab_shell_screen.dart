import '../../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/groups/groups_repository.dart';
import '../../routing/portal_route_guard.dart';

import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';

class AdminTabShellScreen extends ConsumerWidget {
  const AdminTabShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(activeGroupProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex:
            group?.role != 'GROUP_ADMIN' && navigationShell.currentIndex >= 3
            ? 3
            : navigationShell.currentIndex,
        onDestinationSelected: (index) {
          if (group?.role != 'GROUP_ADMIN' && index == 3) {
            context.go(portalMoreRoute(group));
            return;
          }
          if (index == 0) {
            context.go(portalHomeRoute(group));
            return;
          }
          if (index == 4) {
            context.go(portalMoreRoute(group));
            return;
          }
          if (index == navigationShell.currentIndex) return;

          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
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
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: AppLocalizations.of(context).registerTab,
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
