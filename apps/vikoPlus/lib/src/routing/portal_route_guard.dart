import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/groups/groups_repository.dart';
import '../core/auth/auth_session.dart';
import '../theme/app_colors.dart';

enum PortalArea {
  admin,
  treasurer,
  secretary,
  staff,
  financeStaff,
  paymentReviewer,
  records,
  member,
  group,
}

class PortalRouteGuard extends ConsumerWidget {
  const PortalRouteGuard({required this.area, required this.child, super.key});

  final PortalArea area;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final authenticated = ref.watch(authSessionProvider).isAuthenticated;
    final role = activeGroup?.role;
    final allowed = switch (area) {
      PortalArea.admin => role == 'GROUP_ADMIN',
      PortalArea.treasurer => role == 'GROUP_ADMIN' || role == 'TREASURER',
      PortalArea.secretary => role == 'GROUP_ADMIN' || role == 'SECRETARY',
      PortalArea.staff => isStaffPortalRole(role),
      PortalArea.financeStaff => role == 'GROUP_ADMIN' || role == 'TREASURER',
      PortalArea.paymentReviewer =>
        role == 'GROUP_ADMIN' || role == 'TREASURER' || role == 'SECRETARY',
      PortalArea.records => role == 'GROUP_ADMIN' || role == 'SECRETARY',
      PortalArea.member => role == 'MEMBER',
      PortalArea.group => role == 'MEMBER' || isStaffPortalRole(role),
    };

    if (authenticated && allowed) return child;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || !TickerMode.valuesOf(context).enabled) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;
      context.go(authenticated ? portalHomeRoute(activeGroup) : '/sign-in');
    });

    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

bool isStaffPortalRole(String? role) {
  return role == 'GROUP_ADMIN' || role == 'TREASURER' || role == 'SECRETARY';
}

String portalHomeRoute(GroupAccessSummary? group) {
  if (group == null) return '/groups';
  if (group.role == 'MEMBER') return '/member/dashboard';
  if (group.role == 'TREASURER') return '/treasurer/dashboard';
  if (group.role == 'SECRETARY') return '/secretary/dashboard';
  if (group.role == 'GROUP_ADMIN') return '/dashboard';
  return '/groups';
}

String portalMembersRoute(GroupAccessSummary? group) {
  if (group?.role == 'MEMBER') return '/member/profile';
  return '/members';
}

String portalContributionsRoute(GroupAccessSummary? group) {
  if (group?.role == 'MEMBER') return '/member/contributions';
  if (group?.role == 'SECRETARY') {
    final id = group?.id;
    if (id == null) return '/groups';
    return '/groups/history?groupId=${Uri.encodeComponent(id)}&returnTo=${Uri.encodeComponent('/secretary/dashboard')}';
  }
  return '/contributions';
}

String portalPaymentsRoute(GroupAccessSummary? group) {
  if (group == null) return '/groups';
  if (group.role == 'MEMBER') return '/member/payments/select';
  return '/payments/select';
}

int portalPaymentsTabIndex(GroupAccessSummary? group) {
  return group?.role == 'GROUP_ADMIN' ? 2 : 3;
}

int portalReportsTabIndex(GroupAccessSummary? group) {
  return group?.role == 'GROUP_ADMIN' ? 3 : 0;
}

int portalMoreTabIndex(GroupAccessSummary? group) {
  return group?.role == 'GROUP_ADMIN' ? 4 : 4;
}

String portalReportsRoute(GroupAccessSummary? group) {
  return group?.role == 'GROUP_ADMIN' ? '/reports' : portalHomeRoute(group);
}

String portalMoreRoute(GroupAccessSummary? group) {
  if (group?.role == 'TREASURER') return '/treasurer/more';
  if (group?.role == 'SECRETARY') return '/secretary/more';
  if (group?.role == 'MEMBER') return '/member/profile';
  return '/more';
}

String routeForGroupRole(String role) {
  if (role == 'MEMBER') return '/member/dashboard';
  if (role == 'TREASURER') return '/treasurer/dashboard';
  if (role == 'SECRETARY') return '/secretary/dashboard';
  if (role == 'GROUP_ADMIN') return '/dashboard';
  return '/groups';
}
