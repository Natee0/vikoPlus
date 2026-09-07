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
    final entries = <(IconData, String, String, String)>[
      (
        Icons.hub_outlined,
        context.vt('My groups'),
        context.vt('Switch, create or join a group'),
        '/groups',
      ),
      if (role == 'GROUP_ADMIN') ...[
        (
          Icons.tune_outlined,
          context.vt('Admin settings'),
          context.vt(
            'Group rules, member roles, historical records and audit logs',
          ),
          '/settings/admin',
        ),
        (
          Icons.credit_card_outlined,
          context.vt('Billing overview'),
          context.vt('Group access subscription and payments'),
          '/billing',
        ),
      ],
      if (isStaffPortalRole(role))
        (
          Icons.notifications_active_outlined,
          context.vt('Reminder Centre'),
          context.vt('SMS reminders and delivery history'),
          '/reminders',
        ),
      if (role == 'MEMBER' || isStaffPortalRole(role))
        (
          Icons.account_balance_wallet_outlined,
          context.vt('My loans'),
          context.vt('Applications, guarantees and repayments'),
          '/loans',
        ),
      if (role == 'SECRETARY')
        (
          Icons.history_edu_outlined,
          context.vt('Historical records'),
          context.vt('Import previous group records'),
          '/groups/history?groupId=${Uri.encodeComponent(group!.id)}&returnTo=${Uri.encodeComponent(portalMoreRoute(group))}',
        ),
      (
        Icons.account_circle_outlined,
        context.vt('My profile'),
        context.vt('Photo and account details'),
        '/profile/complete',
      ),
      (
        Icons.notifications_outlined,
        context.vt('Notifications'),
        context.vt('Personal alert preferences'),
        '/settings/notifications',
      ),
      (
        Icons.language_outlined,
        context.vt('Language'),
        context.vt('English or Swahili'),
        '/language',
      ),
    ];

    return VikoplusScreen(
      title: context.vt('More'),
      bottomNavigationIndex: 4,
      showBottomNavigation: showBottomNavigation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in entries) ...[
            ActionTile(
              icon: entry.$1,
              title: entry.$2,
              subtitle: entry.$3,
              route: entry.$4,
            ),
            const SizedBox(height: 12),
          ],
          const AuthLogoutTile(),
        ],
      ),
    );
  }
}
