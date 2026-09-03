import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({this.showBottomNavigation = true, super.key});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'More',
      bottomNavigationIndex: 4,
      showBottomNavigation: showBottomNavigation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          ActionTile(
            title: 'My groups',
            subtitle: 'Switch, create, or join groups you can access',
            icon: Icons.hub_outlined,
            route: '/groups',
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Billing overview',
            subtitle: 'Plan, automatic renewal and payment method',
            icon: Icons.credit_card_outlined,
            route: '/billing',
            color: AppColors.gold,
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Reminder Centre',
            subtitle: 'SMS and WhatsApp campaigns',
            icon: Icons.notifications_active_outlined,
            route: '/reminders',
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Loans',
            subtitle: 'Borrowing power, applications and repayments',
            icon: Icons.account_balance_wallet_outlined,
            route: '/loans',
            color: AppColors.secondaryGreen,
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Member roles',
            subtitle: 'Administrators, treasurers and member permissions',
            icon: Icons.admin_panel_settings_outlined,
            route: '/settings/roles',
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Audit logs',
            subtitle: 'Payment, role and subscription history',
            icon: Icons.manage_search_outlined,
            route: '/settings/audit',
            color: AppColors.secondaryGreen,
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Admin settings',
            subtitle: 'Currency, penalties and group controls',
            icon: Icons.tune_outlined,
            route: '/settings/admin',
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Contribution setup',
            subtitle: 'Joining fee, membership fee and payment rules',
            icon: Icons.price_change_outlined,
            route: '/groups/contributions',
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Historical records',
            subtitle: 'Add old records manually or import a CSV',
            icon: Icons.history_edu_outlined,
            route: '/groups/history',
            color: AppColors.gold,
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Create or join group',
            subtitle: 'Open first-time group setup choices',
            icon: Icons.group_add_outlined,
            route: '/create-or-join-group',
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Security',
            subtitle: 'Security PIN and approval protection',
            icon: Icons.shield_outlined,
            route: '/settings/security',
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Notifications',
            subtitle: 'Alerts and delivery preferences',
            icon: Icons.notifications_outlined,
            route: '/settings/notifications',
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'App settings',
            subtitle: 'Display preferences and local app setup',
            icon: Icons.settings_outlined,
            route: '/settings/app',
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Complete profile',
            subtitle: 'Photo, phone and account identity',
            icon: Icons.account_circle_outlined,
            route: '/profile/complete',
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Language',
            subtitle: 'English and Swahili-ready settings',
            icon: Icons.language_outlined,
            route: '/language',
          ),
          SizedBox(height: 12),
          ActionTile(
            title: 'Logout',
            subtitle: 'Leave this role preview and return to sign in',
            icon: Icons.logout_outlined,
            route: '/sign-in',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}
