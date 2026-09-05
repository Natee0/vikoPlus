import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/groups/groups_repository.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
import '../common/vikoplus_screen.dart';
import '../notifications/notification_icon_button.dart';

class StaffPortalScreen extends ConsumerWidget {
  const StaffPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(activeGroupProvider);
    final treasurer = group?.role == 'TREASURER';
    final role = treasurer ? 'Treasurer' : 'Secretary';
    final links = <(IconData, String, String)>[
      (Icons.groups_outlined, 'Members', '/members'),
      (
        Icons.account_balance_wallet_outlined,
        'Contribution register',
        '/contributions',
      ),
      if (treasurer)
        (Icons.add_card_outlined, 'Record payment', '/contributions/record'),
      if (!treasurer)
        (
          Icons.history,
          'Historical records',
          '/groups/history?groupId=${Uri.encodeComponent(group!.id)}&returnTo=%2Fsecretary%2Fdashboard',
        ),
      (Icons.bar_chart, 'Reports', '/reports'),
      (Icons.notifications_outlined, 'Send reminders', '/reminders/new'),
      (Icons.account_balance_outlined, 'My loans', '/loans'),
      if (treasurer)
        (Icons.fact_check_outlined, 'Loan applications', '/loans/applications'),
      (
        Icons.assignment_turned_in_outlined,
        'Guarantees and repayments',
        '/loans/tasks',
      ),
    ];
    return VikoplusScreen(
      title: group?.name ?? '$role Portal',
      bottomNavigationIndex: 0,
      showBackButton: false,
      actions: const [NotificationIconButton(), AuthLogoutIconButton()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$role Dashboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final link in links)
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(link.$1),
                title: Text(link.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(link.$3),
              ),
            ),
        ],
      ),
    );
  }
}
