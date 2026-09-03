import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
import '../common/vikoplus_screen.dart';

class DashboardEmptyStateScreen extends StatelessWidget {
  const DashboardEmptyStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Sofia Wajukuu',
      bottomNavigationIndex: 0,
      showBackButton: false,
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_none_outlined),
        ),
        const AuthLogoutIconButton(),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text(
              'U',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: AppShadows.level1(),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const CircleAvatar(
                      radius: 54,
                      backgroundColor: AppColors.surfaceContainer,
                      child: Icon(
                        Icons.groups_2,
                        color: AppColors.primary,
                        size: 42,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -2,
                      bottom: 18,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.onTertiaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Welcome to Sofia\nWajukuu',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your group is ready. Complete the setup below to start tracking contributions and managing members.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/members/add'),
                    icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                    label: const Text('Add First Member'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: AppInsets.compactCard,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: AppShadows.level1(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Setup Progress',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '2 of 5 steps completed',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: const LinearProgressIndicator(
                    value: 0.4,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _SetupStepTile(
                  title: 'Group Created',
                  completed: true,
                  route: '/groups/create',
                ),
                SizedBox(height: AppSpacing.xs),
                const _SetupStepTile(
                  title: 'Financial Year Set',
                  completed: true,
                  route: '/groups/financial-year',
                ),
                SizedBox(height: AppSpacing.xs),
                const _SetupStepTile(
                  title: 'Add First Member',
                  route: '/members/add',
                ),
                SizedBox(height: AppSpacing.xs),
                const _SetupStepTile(
                  title: 'Configure Contributions',
                  route: '/groups/contributions',
                ),
                SizedBox(height: AppSpacing.xs),
                const _SetupStepTile(
                  title: 'Invite Members',
                  route: '/members/invite',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupStepTile extends StatelessWidget {
  const _SetupStepTile({
    required this.title,
    required this.route,
    this.completed = false,
  });

  final String title;
  final String route;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? AppColors.primaryContainer : AppColors.outline;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  completed ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: completed
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (!completed)
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
