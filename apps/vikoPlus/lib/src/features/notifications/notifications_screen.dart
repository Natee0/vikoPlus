import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Notifications',
      backRoute: '/dashboard',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NotificationTile(
            title: 'July contribution due',
            subtitle: '10 members still have outstanding July dues.',
            icon: Icons.notifications_active_outlined,
            unread: true,
          ),
          SizedBox(height: AppSpacing.sm),
          _NotificationTile(
            title: 'Receipt created',
            subtitle: 'Emmanuel Malekela Madahula payment was approved.',
            icon: Icons.receipt_long_outlined,
          ),
          SizedBox(height: AppSpacing.sm),
          _NotificationTile(
            title: 'Reminder package active',
            subtitle: 'SMS and WhatsApp reminders are ready for campaigns.',
            icon: Icons.forum_outlined,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.unread = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: unread ? AppColors.primaryContainer : AppColors.outlineVariant,
        ),
        boxShadow: AppShadows.level1(),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: unread
                ? AppColors.primaryContainer
                : AppColors.surfaceContainer,
            child: Icon(
              icon,
              color: unread ? AppColors.onPrimary : AppColors.primary,
            ),
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
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
