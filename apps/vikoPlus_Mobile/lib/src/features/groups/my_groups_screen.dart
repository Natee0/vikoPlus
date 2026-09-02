import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class MyGroupsScreen extends StatelessWidget {
  const MyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'My Groups',
      backRoute: '/dashboard',
      actions: [
        IconButton(
          tooltip: 'Logout',
          onPressed: () => context.go('/sign-in'),
          icon: const Icon(Icons.logout_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose a group to open, create a new group, or join one using an invitation.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: _GroupActionButton(
                  label: 'Create group',
                  route: '/groups/create',
                  icon: Icons.add_circle_outline,
                  filled: true,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GroupActionButton(
                  label: 'Join group',
                  route: '/groups/join',
                  icon: Icons.group_add_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Groups you can access'),
          const SizedBox(height: AppSpacing.sm),
          const _GroupAccessCard(
            name: 'Sofia Wajukuu',
            subtitle: 'Owner and chairperson',
            role: 'Admin',
            status: 'Active',
            members: '23 members',
            route: '/dashboard',
            icon: Icons.admin_panel_settings_outlined,
            highlighted: true,
          ),
          SizedBox(height: AppSpacing.sm),
          const _GroupAccessCard(
            name: 'Upendo Savings',
            subtitle: 'Treasurer workspace',
            role: 'Treasurer',
            status: 'Active',
            members: '41 members',
            route: '/contributions',
            icon: Icons.account_balance_wallet_outlined,
          ),
          SizedBox(height: AppSpacing.sm),
          const _GroupAccessCard(
            name: 'Familia Mshikamano',
            subtitle: 'Member contribution portal',
            role: 'Member',
            status: 'Active',
            members: '18 members',
            route: '/member/dashboard',
            icon: Icons.person_outline,
          ),
          SizedBox(height: AppSpacing.sm),
          const _GroupAccessCard(
            name: 'Bima ya Jamii',
            subtitle: 'Invitation waiting for confirmation',
            role: 'Invited',
            status: 'Pending',
            members: '12 members',
            route: '/groups/verify',
            icon: Icons.mark_email_unread_outlined,
          ),
        ],
      ),
    );
  }
}

class _GroupActionButton extends StatelessWidget {
  const _GroupActionButton({
    required this.label,
    required this.route,
    required this.icon,
    this.filled = false,
  });

  final String label;
  final String route;
  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: () => context.go(route),
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => context.go(route),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _GroupAccessCard extends StatelessWidget {
  const _GroupAccessCard({
    required this.name,
    required this.subtitle,
    required this.role,
    required this.status,
    required this.members,
    required this.route,
    required this.icon,
    this.highlighted = false,
  });

  final String name;
  final String subtitle;
  final String role;
  final String status;
  final String members;
  final String route;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final accent = highlighted ? AppColors.primaryContainer : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: highlighted
              ? AppColors.primaryContainer
              : AppColors.outlineVariant,
          width: highlighted ? 1.6 : 1,
        ),
        boxShadow: AppShadows.level1(),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => context.go(route),
        child: Padding(
          padding: AppInsets.compactCard,
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        StatusPill(
                          label: status,
                          color: status == 'Pending'
                              ? AppColors.warning
                              : AppColors.primaryGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MiniChip(label: role, icon: Icons.badge_outlined),
                        _MiniChip(
                          label: members,
                          icon: Icons.groups_2_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
