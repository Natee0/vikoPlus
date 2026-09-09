import '../../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';

class MemberTabShellScreen extends StatelessWidget {
  const MemberTabShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (navigationShell.currentIndex == 0) {
          context.go('/groups');
          return;
        }
        navigationShell.goBranch(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          if (index == navigationShell.currentIndex) return;

          navigationShell.goBranch(index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: AppLocalizations.of(context).home,
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: AppLocalizations.of(context).history,
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: AppLocalizations.of(context).payments,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: AppLocalizations.of(context).account,
          ),
        ],
        ),
      ),
    );
  }
}
