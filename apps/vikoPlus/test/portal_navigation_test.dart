import 'package:vikoplus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vikoplus/src/core/auth/auth_session.dart';
import 'package:vikoplus/src/core/groups/groups_repository.dart';
import 'package:vikoplus/src/core/groups/group_access_events.dart';
import 'package:vikoplus/src/features/common/vikoplus_screen.dart';
import 'package:vikoplus/src/routing/portal_route_guard.dart';
import 'package:vikoplus/src/routing/app_router.dart';
import 'package:vikoplus/src/features/more/more_menu_screen.dart';
import 'package:vikoplus/src/features/common/vikoplus_components.dart';

const memberGroup = GroupAccessSummary(
  id: 'joined-group',
  name: 'Joined Group',
  role: 'MEMBER',
  status: 'ACTIVE',
  membersCount: 2,
);

void signIn(ProviderContainer container, String userId) {
  container
      .read(authSessionProvider.notifier)
      .setAuthenticated(
        accessToken: 'test-access',
        refreshToken: 'test-refresh',
        user: AuthUser(id: userId),
      );
}

void main() {
  testWidgets(
    'staff shell survives repeated exits and re-entry without duplicate keys',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      signIn(container, 'admin');
      container
          .read(activeGroupProvider.notifier)
          .setGroup(
            const GroupAccessSummary(
              id: 'group',
              name: 'Group',
              role: 'GROUP_ADMIN',
              status: 'ACTIVE',
              membersCount: 1,
            ),
          );
      final shell = appRouter.configuration.routes
          .whereType<StatefulShellRoute>()
          .first;
      final router = GoRouter(
        initialLocation: '/members',
        routes: [
          StatefulShellRoute.indexedStack(
            pageBuilder: shell.pageBuilder,
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/members',
                    builder: (_, _) => const Text('Members body'),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/reports',
                    builder: (_, _) => const Text('Reports body'),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/detail',
            builder: (_, _) => const Scaffold(body: Text('Detail')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        router.push('/detail');
        await tester.pumpAndSettle();
        router.go('/reports');
        await tester.pumpAndSettle();
        router.go('/detail');
        await tester.pumpAndSettle();
        router.go('/members');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Members body'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test('revoking one group preserves login and other selected groups', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    signIn(container, 'user');
    container.read(activeGroupProvider.notifier).setGroup(memberGroup);
    container.read(groupAccessEventsProvider.notifier).denied('another-group');
    expect(container.read(activeGroupProvider)?.id, memberGroup.id);
    container.read(groupAccessEventsProvider.notifier).denied(memberGroup.id);
    expect(container.read(activeGroupProvider), isNull);
    expect(container.read(authSessionProvider).isAuthenticated, isTrue);
  });
  for (final role in ['GROUP_ADMIN', 'TREASURER', 'SECRETARY', 'MEMBER']) {
    testWidgets('$role More menu has unique role-appropriate entries', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      signIn(container, 'user');
      container
          .read(activeGroupProvider.notifier)
          .setGroup(
            GroupAccessSummary(
              id: 'group',
              name: 'Group',
              role: role,
              status: 'ACTIVE',
              membersCount: 3,
            ),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MoreMenuScreen(),
          ),
        ),
      );
      final tiles = tester
          .widgetList<ActionTile>(find.byType(ActionTile))
          .toList();
      final routes = tiles.map((tile) => tile.route).toList();
      expect(routes.toSet().length, routes.length);
      expect(routes.contains('/settings/admin'), role == 'GROUP_ADMIN');
      expect(routes.contains('/billing'), role == 'GROUP_ADMIN');
      expect(routes.contains('/reminders'), role != 'MEMBER');
      expect(routes, isNot(contains('/create-or-join-group')));
      expect(routes, isNot(contains('/settings/roles')));
    });
  }
  for (final role in ['TREASURER', 'SECRETARY']) {
    testWidgets('$role cannot enter admin or the other staff portal', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      signIn(container, 'staff-user');
      final group = GroupAccessSummary(
        id: 'group',
        name: 'Group',
        role: role,
        status: 'ACTIVE',
        membersCount: 3,
      );
      container.read(activeGroupProvider.notifier).setGroup(group);
      final home = portalHomeRoute(group);
      expect(home, '/${role.toLowerCase()}/dashboard');
      expect(routeForGroupRole(role), home);
      final router = GoRouter(
        initialLocation: '/admin',
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, _) => const PortalRouteGuard(
              area: PortalArea.admin,
              child: Text('Forbidden admin content'),
            ),
          ),
          GoRoute(
            path: '/other',
            builder: (_, _) => PortalRouteGuard(
              area: role == 'TREASURER'
                  ? PortalArea.secretary
                  : PortalArea.treasurer,
              child: const Text('Forbidden other portal'),
            ),
          ),
          GoRoute(
            path: home,
            builder: (_, _) => const Scaffold(body: Text('Staff home')),
          ),
          GoRoute(
            path: '/detail',
            builder: (_, _) => const VikoplusScreen(
              title: 'Detail',
              backRoute: '/dashboard',
              child: Text('Shared detail'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Forbidden admin content'), findsNothing);
      expect(find.text('Staff home'), findsOneWidget);
      router.go('/other');
      await tester.pumpAndSettle();
      expect(find.text('Forbidden other portal'), findsNothing);
      expect(find.text('Staff home'), findsOneWidget);
      router.go('/detail');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      expect(find.text('Staff home'), findsOneWidget);
    });
  }
  test('application routes compile with loan and settings screens', () {
    expect(appRouter.configuration.routes, isNotEmpty);
  });
  test(
    'account changes clear the selected group but token refresh keeps it',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      signIn(container, 'first-user');
      container.read(activeGroupProvider.notifier).setGroup(memberGroup);
      signIn(container, 'first-user');
      expect(container.read(activeGroupProvider), memberGroup);
      container.read(authSessionProvider.notifier).clear();
      expect(container.read(activeGroupProvider), isNull);
      signIn(container, 'second-user');
      expect(container.read(activeGroupProvider), isNull);
    },
  );

  testWidgets('member cannot open admin portal and shared Back returns home', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    signIn(container, 'member-user');
    container.read(activeGroupProvider.notifier).setGroup(memberGroup);
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const PortalRouteGuard(
            area: PortalArea.admin,
            child: Scaffold(body: Text('Admin portal')),
          ),
        ),
        GoRoute(
          path: '/member/dashboard',
          builder: (_, _) => const Scaffold(body: Text('Member portal')),
        ),
        GoRoute(
          path: '/detail',
          builder: (_, _) => const VikoplusScreen(
            title: 'Detail',
            backRoute: '/dashboard',
            child: Text('Shared detail'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Admin portal'), findsNothing);
    expect(find.text('Member portal'), findsOneWidget);
    router.go('/detail');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Member portal'), findsOneWidget);
    expect(find.text('Admin portal'), findsNothing);
  });
}
