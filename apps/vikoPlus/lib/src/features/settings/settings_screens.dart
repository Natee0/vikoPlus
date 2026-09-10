import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/roles/vikoplus_role.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class AdminSettingsDashboardScreen extends ConsumerWidget {
  const AdminSettingsDashboardScreen({super.key});

  String _setupRoute(String path, GroupAccessSummary? group) {
    final route = group == null
        ? path
        : '$path?groupId=${Uri.encodeComponent(group.id)}';
    final separator = route.contains('?') ? '&' : '?';
    return '$route${separator}returnTo=${Uri.encodeComponent('/settings/admin')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final actions = [
      _SettingsAction(
        title: context.vt('Audit logs'),
        subtitle: context.vt('Payment, role and subscription history'),
        icon: Icons.manage_search_outlined,
        route: '/settings/audit',
      ),
      _SettingsAction(
        title: context.vt('Contribution penalties'),
        subtitle: context.vt('Late-fee rules and grace periods'),
        icon: Icons.gavel_outlined,
        route: '/settings/contribution-penalties',
      ),
      _SettingsAction(
        title: context.vt('Contribution setup'),
        subtitle: context.vt(
          'Set joining fee, membership fee and payment rules',
        ),
        icon: Icons.price_change_outlined,
        route: _setupRoute('/groups/contributions', activeGroup),
      ),
      _SettingsAction(
        title: context.vt('Currency and fees'),
        subtitle: context.vt(
          'TZS defaults, platform access and messaging charges',
        ),
        icon: Icons.payments_outlined,
        route: '/settings/currency-fees',
        color: AppColors.gold,
      ),
      _SettingsAction(
        title: context.vt('Group profile'),
        subtitle: context.vt('Update the group icon and visible identity'),
        icon: Icons.groups_2_outlined,
        route: '/settings/group-profile',
        color: AppColors.primary,
      ),
      _SettingsAction(
        title: context.vt('Historical records'),
        subtitle: context.vt(
          'Import previous group contributions and old ledgers',
        ),
        icon: Icons.history_edu_outlined,
        route: _setupRoute('/groups/history', activeGroup),
        color: AppColors.secondaryGreen,
      ),
      _SettingsAction(
        title: context.vt('Member roles'),
        subtitle: context.vt(
          'Assign chairperson, treasurer, secretary and member access',
        ),
        icon: Icons.admin_panel_settings_outlined,
        route: '/settings/roles',
      ),
    ]..sort(
        (a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

    return VikoplusScreen(
      title: context.vt('Admin Settings'),
      backRoute: '/more',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SettingsHero(),
          const SizedBox(height: AppSpacing.md),
          for (final action in actions) ...[
            ActionTile(
              title: action.title,
              subtitle: action.subtitle,
              icon: action.icon,
              route: action.route,
              color: action.color,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SettingsAction {
  const _SettingsAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.color = AppColors.primaryGreen,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
}

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: context.vt('App Settings'),
      backRoute: '/more',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingSwitch(
            title: context.vt('Compact dashboard'),
            subtitle: context.vt(
              'Show denser cards for frequent administrators.',
            ),
            value: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingSwitch(
            title: context.vt('Use device language'),
            subtitle: context.vt(
              'Keep English and Swahili-ready text aligned.',
            ),
            value: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          ActionTile(
            title: context.vt('Language'),
            subtitle: context.vt('Choose English or Swahili'),
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
      title: context.vt('Security'),
      backRoute: '/more',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SecurityCard(),
          const SizedBox(height: AppSpacing.md),
          ActionTile(
            title: context.vt('Change security PIN'),
            subtitle: context.vt(
              'Protect approvals and group administration actions',
            ),
            icon: Icons.pin_outlined,
            route: '/settings/security/pin',
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingSwitch(
            title: context.vt('Require PIN for payment approvals'),
            subtitle: context.vt(
              'Treasurer and admin actions ask for extra confirmation.',
            ),
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
      title: context.vt('Change PIN'),
      backRoute: '/settings/security',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _IconHero(icon: Icons.lock_reset_outlined),
          const SizedBox(height: AppSpacing.md),
          TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.vt('Current PIN'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.vt('New PIN'),
              prefixIcon: const Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.vt('Confirm PIN'),
              prefixIcon: const Icon(Icons.verified_user_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/settings/security'),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(context.vt('Update PIN')),
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
      title: context.vt('Notification Preferences'),
      backRoute: '/more',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingSwitch(
            title: context.vt('Payment confirmations'),
            subtitle: context.vt('Notify me when receipts are created.'),
            value: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingSwitch(
            title: context.vt('Contribution reminders'),
            subtitle: context.vt(
              'Receive reminders before and after due dates.',
            ),
            value: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingSwitch(
            title: context.vt('Role changes'),
            subtitle: context.vt('Alert members when their access changes.'),
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
      title: context.vt('Member Roles'),
      backRoute: '/settings/admin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.vt(
              'The chairperson/admin assigns these roles when inviting or adding members.',
            ),
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

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: context.vt('Audit Logs'),
      backRoute: '/settings/admin',
      child: activeGroup == null
          ? AuthErrorMessage(
              message: context.vt('Select a group to view audit logs.'),
            )
          : FutureBuilder<AuditLogResult>(
              future: ref
                  .read(groupsRepositoryProvider)
                  .auditLog(activeGroup.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return AuthErrorMessage(
                    message: context.vt('Could not load audit logs.'),
                  );
                }

                final entries = snapshot.data!.entries;
                if (entries.isEmpty) {
                  return EmptyStateCard(
                    icon: Icons.manage_search_outlined,
                    title: context.vt('No audit logs yet'),
                    message: context.vt(
                      'Group administration activity will appear here.',
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in entries) ...[
                      _AuditTile(
                        title: _auditTitle(entry.action),
                        subtitle: entry.reason ?? entry.entityType,
                        time: formatters.date(entry.createdAt),
                        icon: _auditIcon(entry.action),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

class CurrencyFeesScreen extends StatelessWidget {
  const CurrencyFeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: context.vt('Currency & Fees'),
      backRoute: '/settings/admin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FeeTile(
            title: context.vt('Primary currency'),
            value: 'TZS - Tanzanian Shilling',
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeTile(
            title: context.vt('Group access'),
            value: 'TZS 10,000 / year',
            icon: Icons.workspace_premium_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeTile(
            title: context.vt('SMS reminders'),
            value: 'TZS 50 per SMS',
            icon: Icons.sms_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeTile(
            title: context.vt('WhatsApp reminders'),
            value: 'TZS 50 per message',
            icon: Icons.chat_outlined,
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
              context.vt(
                'Manage group rules, billing controls and admin access.',
              ),
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
      child: Row(
        children: [
          const _IconHero(icon: Icons.shield_outlined, small: true),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.vt(
                'Security PIN is enabled for sensitive group actions.',
              ),
            ),
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

String _auditTitle(String action) {
  return action
      .toLowerCase()
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

IconData _auditIcon(String action) {
  final normalized = action.toLowerCase();
  if (normalized.contains('role')) return Icons.admin_panel_settings_outlined;
  if (normalized.contains('payment')) return Icons.receipt_long_outlined;
  if (normalized.contains('loan')) return Icons.account_balance_wallet_outlined;
  if (normalized.contains('subscription')) {
    return Icons.workspace_premium_outlined;
  }
  return Icons.manage_search_outlined;
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
