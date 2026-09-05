import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/groups/groups_repository.dart';
import '../../routing/portal_route_guard.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import 'vikoplus_design_widgets.dart';

class VikoplusScreen extends ConsumerWidget {
  const VikoplusScreen({
    required this.child,
    this.title,
    this.actions,
    this.bottomNavigationIndex,
    this.backRoute,
    this.showBackButton,
    this.showBottomNavigation = true,
    this.onRefresh,
    this.preferBackRoute = false,
    super.key,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final int? bottomNavigationIndex;
  final String? backRoute;
  final bool? showBackButton;
  final bool showBottomNavigation;
  final RefreshCallback? onRefresh;
  final bool preferBackRoute;

  void _goBack(
    BuildContext context, {
    required String? route,
    bool preferRoute = false,
  }) {
    if (preferRoute && route != null) {
      context.go(route);
      return;
    }

    if (context.canPop()) {
      context.pop();
      return;
    }

    if (route != null) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final effectiveBackRoute = backRoute == '/dashboard'
        ? portalHomeRoute(activeGroup)
        : backRoute == '/more'
        ? portalMoreRoute(activeGroup)
        : backRoute;
    final shouldShowBack =
        showBackButton ??
        (bottomNavigationIndex == null && effectiveBackRoute != null);
    final topActions = actions;

    final scaffold = Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (title != null)
              VikoplusTopBar(
                title: title!,
                onBack: shouldShowBack
                    ? () => _goBack(
                        context,
                        route: effectiveBackRoute,
                        preferRoute: preferBackRoute,
                      )
                    : null,
                trailing: topActions == null || topActions.isEmpty
                    ? null
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: topActions,
                      ),
                trailingWidth: (topActions?.length ?? 0) > 1
                    ? AppSizes.iconButton * topActions!.length
                    : AppSizes.iconButton,
              ),
            Expanded(
              child: VikoplusConstrainedContent(
                child: onRefresh == null
                    ? _ScreenList(
                        bottomNavigationIndex: bottomNavigationIndex,
                        child: child,
                      )
                    : RefreshIndicator.adaptive(
                        onRefresh: onRefresh!,
                        triggerMode: RefreshIndicatorTriggerMode.anywhere,
                        child: _ScreenList(
                          bottomNavigationIndex: bottomNavigationIndex,
                          child: child,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          bottomNavigationIndex == null || !showBottomNavigation
          ? null
          : NavigationBar(
              selectedIndex: bottomNavigationIndex!,
              onDestinationSelected: (index) {
                if (index == bottomNavigationIndex) return;

                switch (index) {
                  case 0:
                    context.go(portalHomeRoute(activeGroup));
                    break;
                  case 1:
                    context.go(portalMembersRoute(activeGroup));
                    break;
                  case 2:
                    context.go(portalContributionsRoute(activeGroup));
                    break;
                  case 3:
                    context.go(portalReportsRoute(activeGroup));
                    break;
                  case 4:
                    context.go(portalMoreRoute(activeGroup));
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_2_outlined),
                  selectedIcon: Icon(Icons.groups_2),
                  label: 'Members',
                ),
                NavigationDestination(
                  icon: Icon(Icons.savings_outlined),
                  selectedIcon: Icon(Icons.savings),
                  label: 'Register',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  selectedIcon: Icon(Icons.more),
                  label: 'More',
                ),
              ],
            ),
    );

    if (!preferBackRoute || effectiveBackRoute == null) {
      return scaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack(context, route: effectiveBackRoute, preferRoute: true);
        }
      },
      child: scaffold,
    );
  }
}

class _ScreenList extends StatelessWidget {
  const _ScreenList({required this.child, required this.bottomNavigationIndex});

  final Widget child;
  final int? bottomNavigationIndex;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMobile,
        AppSpacing.md,
        AppSpacing.screenMobile,
        bottomNavigationIndex == null
            ? AppSpacing.lg
            : AppSpacing.xl + AppSpacing.lg,
      ),
      children: [child],
    );
  }
}
