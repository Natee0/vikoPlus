import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../routing/portal_route_guard.dart';
import '../auth/auth_logout_controls.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class MoreMenuScreen extends ConsumerWidget {
  const MoreMenuScreen({this.showBottomNavigation = true, super.key});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(activeGroupProvider);
    final role = group?.role;
    final entries = <_MoreEntry>[
      if (role == 'GROUP_ADMIN') ...[
        _MoreEntry(
          icon: Icons.tune_outlined,
          title: context.vt('Admin Settings'),
          subtitle: context.vt(
            'Group rules, member roles, historical records and audit logs',
          ),
          route: '/settings/admin',
        ),
        _MoreEntry(
          icon: Icons.credit_card_outlined,
          title: context.vt('Billing overview'),
          subtitle: context.vt('Group access subscription and payments'),
          route: '/billing',
        ),
      ],
      if (isStaffPortalRole(role))
        _MoreEntry(
          icon: Icons.fact_check_outlined,
          title: context.vt('Review payments'),
          subtitle: context.vt('Approve or reject submitted contributions'),
          route: '/contributions',
        ),
      if (role == 'GROUP_ADMIN' || role == 'TREASURER')
        _MoreEntry(
          icon: Icons.receipt_long_outlined,
          title: context.vt('Group expenses'),
          subtitle: context.vt('Record group spending for approval'),
          route: '/expenses',
        ),
      if (role == 'TREASURER' || role == 'SECRETARY')
        _MoreEntry(
          icon: Icons.groups_2_outlined,
          title: context.vt('Group Profile'),
          subtitle: context.vt('Review group identity and deletion requests'),
          route: '/settings/group-profile',
        ),
      if (isStaffPortalRole(role))
        _MoreEntry(
          icon: Icons.notifications_active_outlined,
          title: context.vt('Reminder Centre'),
          subtitle: context.vt('SMS reminders and delivery history'),
          route: '/reminders',
        ),
      if (role == 'MEMBER' || isStaffPortalRole(role))
        _MoreEntry(
          icon: Icons.account_balance_wallet_outlined,
          title: context.vt('My loans'),
          subtitle: context.vt('Applications, guarantees and repayments'),
          route: '/loans',
        ),
      if (role == 'SECRETARY')
        _MoreEntry(
          icon: Icons.history_edu_outlined,
          title: context.vt('Historical records'),
          subtitle: context.vt('Import previous group records'),
          route:
              '/groups/history?groupId=${Uri.encodeComponent(group!.id)}&returnTo=${Uri.encodeComponent(portalMoreRoute(group))}',
        ),
      _MoreEntry(
        icon: Icons.language_outlined,
        title: context.vt('Language'),
        subtitle: context.vt('English or Swahili'),
        route: '/language',
      ),
      _MoreEntry(
        icon: Icons.logout_outlined,
        title: context.vt('Logout'),
        subtitle: context.vt('End your session on this device'),
        isLogout: true,
      ),
      _MoreEntry(
        icon: Icons.hub_outlined,
        title: context.vt('My Groups'),
        subtitle: context.vt('Switch, create or join a group'),
        route: '/groups',
      ),
      _MoreEntry(
        icon: Icons.account_circle_outlined,
        title: context.vt('My Profile'),
        subtitle: context.vt('Photo and account details'),
        route: '/profile/complete',
      ),
      _MoreEntry(
        icon: Icons.notifications_outlined,
        title: context.vt('Notifications'),
        subtitle: context.vt('Personal alert preferences'),
        route: '/settings/notifications',
      ),
    ]..sort(
        (a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

    return VikoplusScreen(
      title: context.vt('More'),
      bottomNavigationIndex: 4,
      showBottomNavigation: showBottomNavigation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in entries) ...[
            if (entry.isLogout)
              const AuthLogoutTile()
            else
              ActionTile(
                icon: entry.icon,
                title: entry.title,
                subtitle: entry.subtitle,
                route: entry.route!,
              ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _MoreEntry {
  const _MoreEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
    this.isLogout = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;
  final bool isLogout;
}
