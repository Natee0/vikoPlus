import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class StitchScreenCatalogScreen extends StatelessWidget {
  const StitchScreenCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Stitch Screens',
      backRoute: '/more',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _CatalogIntro(),
          SizedBox(height: AppSpacing.md),
          _CatalogSection(
            title: 'Onboarding',
            screens: [
              _CatalogLink(
                'Splash screen',
                '/',
                Icons.motion_photos_on_outlined,
              ),
              _CatalogLink(
                'Welcome screen',
                '/welcome',
                Icons.waving_hand_outlined,
              ),
              _CatalogLink(
                'Select language',
                '/language',
                Icons.language_outlined,
              ),
              _CatalogLink('Sign in', '/sign-in', Icons.login_outlined),
              _CatalogLink(
                'Create account',
                '/create-account',
                Icons.person_add_alt_outlined,
              ),
              _CatalogLink(
                'Verify account',
                '/verify-account',
                Icons.mark_email_read_outlined,
              ),
              _CatalogLink(
                'Complete your profile',
                '/profile/complete',
                Icons.account_circle_outlined,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _CatalogSection(
            title: 'Groups',
            screens: [
              _CatalogLink('My groups', '/groups', Icons.hub_outlined),
              _CatalogLink(
                'Create or join group',
                '/create-or-join-group',
                Icons.group_add_outlined,
              ),
              _CatalogLink(
                'Create group',
                '/groups/create',
                Icons.add_business_outlined,
              ),
              _CatalogLink(
                'Join group invitation',
                '/groups/join',
                Icons.mark_email_unread_outlined,
              ),
              _CatalogLink(
                'Verify group details',
                '/groups/verify',
                Icons.verified_outlined,
              ),
              _CatalogLink(
                'Financial year 1',
                '/groups/financial-year/start',
                Icons.calendar_month_outlined,
              ),
              _CatalogLink(
                'Financial year 2',
                '/groups/financial-year/review',
                Icons.event_repeat_outlined,
              ),
              _CatalogLink(
                'Configure contributions',
                '/groups/contributions',
                Icons.price_change_outlined,
              ),
              _CatalogLink(
                'Configure reminders',
                '/groups/reminders',
                Icons.notifications_active_outlined,
              ),
              _CatalogLink(
                'Onboarding success',
                '/groups/onboarding-success',
                Icons.check_circle_outline,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _CatalogSection(
            title: 'Admin & Members',
            screens: [
              _CatalogLink(
                'Administrator dashboard',
                '/dashboard',
                Icons.dashboard_outlined,
              ),
              _CatalogLink(
                'Dashboard empty state',
                '/dashboard/empty',
                Icons.dashboard_customize_outlined,
              ),
              _CatalogLink('Member list', '/members', Icons.groups_2_outlined),
              _CatalogLink(
                'Invite members',
                '/members/invite',
                Icons.group_add_outlined,
              ),
              _CatalogLink(
                'Add member',
                '/members/add',
                Icons.person_add_alt_outlined,
              ),
              _CatalogLink(
                'Member profile fully paid',
                '/members',
                Icons.verified_user_outlined,
              ),
              _CatalogLink(
                'Member profile outstanding',
                '/members',
                Icons.pending_actions_outlined,
              ),
              _CatalogLink(
                'Roles and permissions',
                '/settings/roles',
                Icons.admin_panel_settings_outlined,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _CatalogSection(
            title: 'Finance & Reports',
            screens: [
              _CatalogLink(
                'Contribution register July',
                '/contributions',
                Icons.savings_outlined,
              ),
              _CatalogLink(
                'Record payment select member',
                '/contributions/record/select-member',
                Icons.person_search_outlined,
              ),
              _CatalogLink(
                'Record payment details',
                '/contributions/record/details',
                Icons.add_card_outlined,
              ),
              _CatalogLink(
                'Digital receipt admin',
                '/contributions',
                Icons.receipt_long_outlined,
              ),
              _CatalogLink(
                'Reports dashboard',
                '/reports',
                Icons.bar_chart_outlined,
              ),
              _CatalogLink(
                'Outstanding report',
                '/reports/outstanding',
                Icons.pending_actions_outlined,
              ),
              _CatalogLink(
                'Member analysis',
                '/reports/member-analysis',
                Icons.analytics_outlined,
              ),
              _CatalogLink(
                'Report filters',
                '/reports/filters',
                Icons.filter_alt_outlined,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _CatalogSection(
            title: 'Reminders & Settings',
            screens: [
              _CatalogLink(
                'Reminder centre',
                '/reminders',
                Icons.notifications_outlined,
              ),
              _CatalogLink(
                'Send new reminder',
                '/reminders/new',
                Icons.schedule_send_outlined,
              ),
              _CatalogLink(
                'Message templates',
                '/reminders/templates',
                Icons.article_outlined,
              ),
              _CatalogLink(
                'Campaign details',
                '/reminders/campaigns/july-dues',
                Icons.campaign_outlined,
              ),
              _CatalogLink(
                'Notifications',
                '/notifications',
                Icons.notifications_active_outlined,
              ),
              _CatalogLink(
                'Notification preferences',
                '/settings/notifications',
                Icons.tune_outlined,
              ),
              _CatalogLink(
                'Admin settings',
                '/settings/admin',
                Icons.settings_outlined,
              ),
              _CatalogLink(
                'App settings',
                '/settings/app',
                Icons.app_settings_alt_outlined,
              ),
              _CatalogLink(
                'Security settings',
                '/settings/security',
                Icons.shield_outlined,
              ),
              _CatalogLink(
                'Change security PIN',
                '/settings/security/pin',
                Icons.pin_outlined,
              ),
              _CatalogLink(
                'Audit logs',
                '/settings/audit',
                Icons.manage_search_outlined,
              ),
              _CatalogLink(
                'Currency fees',
                '/settings/currency-fees',
                Icons.payments_outlined,
              ),
              _CatalogLink(
                'Contribution penalties',
                '/settings/contribution-penalties',
                Icons.gavel_outlined,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _CatalogSection(
            title: 'Member Portal',
            screens: [
              _CatalogLink(
                'Member dashboard',
                '/member/dashboard',
                Icons.dashboard_outlined,
              ),
              _CatalogLink(
                'Member dashboard new user',
                '/member/dashboard/new',
                Icons.person_add_alt_outlined,
              ),
              _CatalogLink(
                'My contributions',
                '/member/contributions',
                Icons.history_outlined,
              ),
              _CatalogLink(
                'Dues and arrears',
                '/member/dues',
                Icons.pending_actions_outlined,
              ),
              _CatalogLink(
                'My profile',
                '/member/profile',
                Icons.person_outline,
              ),
              _CatalogLink(
                'Select contribution',
                '/member/payments/select',
                Icons.checklist_outlined,
              ),
              _CatalogLink(
                'Payment method',
                '/member/payments/method',
                Icons.account_balance_wallet_outlined,
              ),
              _CatalogLink(
                'Review payment 1',
                '/member/payments/review/mobile-money',
                Icons.fact_check_outlined,
              ),
              _CatalogLink(
                'Review payment 2',
                '/member/payments/review/cash',
                Icons.fact_check_outlined,
              ),
              _CatalogLink(
                'Payment successful 1',
                '/member/payments/success/mobile-money',
                Icons.check_circle_outline,
              ),
              _CatalogLink(
                'Payment successful 2',
                '/member/payments/success/cash',
                Icons.check_circle_outline,
              ),
              _CatalogLink(
                'Digital receipt member',
                '/member/receipts/latest',
                Icons.receipt_long_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatalogIntro extends StatelessWidget {
  const _CatalogIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level1(),
      ),
      child: Text(
        'Temporary preview map for every screen discovered from Stitch. Use this while polishing static screens before API wiring.',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({required this.title, required this.screens});

  final String title;
  final List<_CatalogLink> screens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.sm),
        for (final screen in screens) ...[
          ActionTile(
            title: screen.title,
            subtitle: screen.route,
            icon: screen.icon,
            route: screen.route,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _CatalogLink {
  const _CatalogLink(this.title, this.route, this.icon);

  final String title;
  final String route;
  final IconData icon;
}
