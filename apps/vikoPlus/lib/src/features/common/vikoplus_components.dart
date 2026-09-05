import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    this.color = AppColors.primaryGreen,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final action = actionLabel;

    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppShadows.level1(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.surfaceContainer,
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          if (action != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onAction,
              child: Text(action),
            ),
          ],
        ],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.color = AppColors.primaryGreen,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () {
          if (GoRouterState.of(context).uri.toString() == route) return;
          context.go(route);
        },
        child: Padding(
          padding: AppInsets.compactCard,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressBlock extends StatelessWidget {
  const ProgressBlock({
    required this.title,
    required this.value,
    required this.caption,
    required this.progress,
    super.key,
  });

  final String title;
  final String value;
  final String caption;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level1(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress.clamp(0, 1).toDouble(),
              backgroundColor: AppColors.lightGreen,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    required this.initials,
    this.color = AppColors.primaryGreen,
    super.key,
  });

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
