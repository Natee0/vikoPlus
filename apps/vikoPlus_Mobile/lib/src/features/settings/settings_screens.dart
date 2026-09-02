import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/roles/vikoplus_role.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class AdminSettingsDashboardScreen extends StatelessWidget {
  const AdminSettingsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Admin Settings',
      backRoute: '/more',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsHero(),
          SizedBox(height: AppSpacing.md),
          ActionTile(
            title: 'Member roles',
            subtitle:
                'Assign chairperson, treasurer, secretary and member access',
            icon: Icons.admin_panel_settings_outlined,
            route: '/settings/roles',
          ),
          SizedBox(height: AppSpacing.sm),
          ActionTile(
            title: 'Currency and fees',
            subtitle: 'TZS defaults, platform access and messaging charges',
            icon: Icons.payments_outlined,
            route: '/settings/currency-fees',
            color: AppColors.gold,
          ),
          SizedBox(height: AppSpacing.sm),
          ActionTile(
            title: 'Contribution setup',
            subtitle: 'Set joining fee, membership fee and payment rules',
            icon: Icons.price_change_outlined,
            route: '/groups/contributions',
          ),
          SizedBox(height: AppSpacing.sm),
          ActionTile(
            title: 'Contribution penalties',
            subtitle: 'Late-fee rules and grace periods',
            icon: Icons.gavel_outlined,
            route: '/settings/contribution-penalties',
          ),
          SizedBox(height: AppSpacing.sm),
          ActionTile(
            title: 'Audit logs',
            subtitle: 'Payment, role and subscription history',
            icon: Icons.manage_search_outlined,
            route: '/settings/audit',
          ),
        ],
      ),
    );
  }
}

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'App Settings',
      backRoute: '/more',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _SettingSwitch(
            title: 'Compact dashboard',
            subtitle: 'Show denser cards for frequent administrators.',
            value: true,
          ),
          SizedBox(height: AppSpacing.sm),
          _SettingSwitch(
            title: 'Use device language',
            subtitle: 'Keep English and Swahili-ready text aligned.',
            value: false,
          ),
          SizedBox(height: AppSpacing.sm),
          ActionTile(
            title: 'Language',
            subtitle: 'Choose English or Swahili',
            icon: Icons.language_outlined,
            route: '/language',
          ),
        ],
      ),
    );
  }
}

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Security',
      backRoute: '/more',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SecurityCard(),
          SizedBox(height: AppSpacing.md),
          ActionTile(
            title: 'Change security PIN',
            subtitle: 'Protect approvals and group administration actions',
            icon: Icons.pin_outlined,
            route: '/settings/security/pin',
          ),
          SizedBox(height: AppSpacing.sm),
          _SettingSwitch(
            title: 'Require PIN for payment approvals',
            subtitle: 'Treasurer and admin actions ask for extra confirmation.',
            value: true,
          ),
        ],
      ),
    );
  }
}

class ChangeSecurityPinScreen extends StatelessWidget {
  const ChangeSecurityPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Change PIN',
      backRoute: '/settings/security',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _IconHero(icon: Icons.lock_reset_outlined),
          const SizedBox(height: AppSpacing.md),
          const TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Current PIN',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'New PIN',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Confirm PIN',
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/settings/security'),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Update PIN'),
          ),
        ],
      ),
    );
  }
}

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Notification Preferences',
      backRoute: '/more',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingSwitch(
            title: 'Payment confirmations',
            subtitle: 'Notify me when receipts are created.',
            value: true,
          ),
          SizedBox(height: AppSpacing.sm),
          _SettingSwitch(
            title: 'Contribution reminders',
            subtitle: 'Receive reminders before and after due dates.',
            value: true,
          ),
          SizedBox(height: AppSpacing.sm),
          _SettingSwitch(
            title: 'Role changes',
            subtitle: 'Alert members when their access changes.',
            value: true,
          ),
        ],
      ),
    );
  }
}

class MemberRolesPermissionsScreen extends StatelessWidget {
  const MemberRolesPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Member Roles',
      backRoute: '/settings/admin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'The chairperson/admin assigns these roles when inviting or adding members.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final role in VikoplusRole.values.where(
            (role) => role != VikoplusRole.newUser,
          )) ...[
            _RolePermissionCard(role: role),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Audit Logs',
      backRoute: '/settings/admin',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuditTile(
            title: 'Role assigned',
            subtitle: 'Amina Issa was assigned Secretary',
            time: 'Today, 09:15',
            icon: Icons.admin_panel_settings_outlined,
          ),
          SizedBox(height: AppSpacing.sm),
          _AuditTile(
            title: 'Payment recorded',
            subtitle: 'TZS 70,000 receipt created for Emmanuel Malekela',
            time: 'Yesterday',
            icon: Icons.receipt_long_outlined,
          ),
          SizedBox(height: AppSpacing.sm),
          _AuditTile(
            title: 'Group access activated',
            subtitle: 'Annual access paid by chairperson/admin',
            time: 'Aug 30',
            icon: Icons.workspace_premium_outlined,
          ),
        ],
      ),
    );
  }
}

class CurrencyFeesScreen extends StatelessWidget {
  const CurrencyFeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Currency & Fees',
      backRoute: '/settings/admin',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FeeTile(
            title: 'Primary currency',
            value: 'TZS - Tanzanian Shilling',
            icon: Icons.account_balance_outlined,
          ),
          SizedBox(height: AppSpacing.sm),
          _FeeTile(
            title: 'Group access',
            value: 'TZS 10,000 / year',
            icon: Icons.workspace_premium_outlined,
          ),
          SizedBox(height: AppSpacing.sm),
          _FeeTile(
            title: 'SMS reminders',
            value: 'TZS 50 per SMS',
            icon: Icons.sms_outlined,
          ),
          SizedBox(height: AppSpacing.sm),
          _FeeTile(
            title: 'WhatsApp reminders',
            value: 'TZS 50 per message',
            icon: Icons.chat_outlined,
          ),
        ],
      ),
    );
  }
}

class ContributionPenaltiesScreen extends StatelessWidget {
  const ContributionPenaltiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Contribution Penalties',
      backRoute: '/settings/admin',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingSwitch(
            title: 'Enable late penalties',
            subtitle: 'Apply a charge after the grace period ends.',
            value: true,
          ),
          SizedBox(height: AppSpacing.sm),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Penalty amount',
              hintText: '2000',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Grace period',
              hintText: '3 days',
              prefixIcon: Icon(Icons.event_available_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level2(),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_outlined, color: AppColors.onPrimary, size: 40),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Manage group rules, billing controls and admin access.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level1(),
      ),
      child: const Row(
        children: [
          _IconHero(icon: Icons.shield_outlined, small: true),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('Security PIN is enabled for sensitive group actions.'),
          ),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          value: value,
          onChanged: (_) {},
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}

class _RolePermissionCard extends StatelessWidget {
  const _RolePermissionCard({required this.role});

  final VikoplusRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceContainer,
            child: Icon(role.icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.label,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  role.description,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _FeeTile(title: title, value: '$subtitle\n$time', icon: icon);
  }
}

class _FeeTile extends StatelessWidget {
  const _FeeTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level1(),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceContainer,
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconHero extends StatelessWidget {
  const _IconHero({required this.icon, this.small = false});

  final IconData icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: small ? 56 : 104,
        height: small ? 56 : 104,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: small ? 28 : 52),
      ),
    );
  }
}
