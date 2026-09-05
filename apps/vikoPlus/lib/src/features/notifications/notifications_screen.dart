import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<NotificationsResult> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<NotificationsResult> _loadNotifications() {
    return ref.read(groupsRepositoryProvider).notifications();
  }

  void _reload() {
    _notificationsFuture = _loadNotifications();
  }

  Future<void> _refresh() async {
    final future = _loadNotifications();
    setState(() => _notificationsFuture = future);
    await future;
  }

  Future<void> _markRead(NotificationSummary notification) async {
    if (!notification.isUnread) return;
    await ref.read(groupsRepositoryProvider).markNotificationRead(
          notification.id,
        );
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: 'Notifications',
      backRoute: '/dashboard',
      onRefresh: _refresh,
      child: FutureBuilder<NotificationsResult>(
        future: _notificationsFuture,
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthErrorMessage(
                  message: 'Could not load notifications.',
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => setState(_reload),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try Again'),
                ),
              ],
            );
          }

          final notifications = snapshot.data!.notifications;
          if (notifications.isEmpty) {
            return const EmptyStateCard(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications',
              message: 'Important group updates will appear here.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final notification in notifications) ...[
                _NotificationTile(
                  notification: notification,
                  time: formatters.date(notification.createdAt),
                  onTap: () => _markRead(notification),
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.time,
    required this.onTap,
  });

  final NotificationSummary notification;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = notification.isUnread;

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          padding: AppInsets.compactCard,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color:
                  unread ? AppColors.primaryContainer : AppColors.outlineVariant,
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
                  _iconFor(notification.title),
                  color: unread ? AppColors.onPrimary : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w700,
                          ),
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
        ),
      ),
    );
  }

  IconData _iconFor(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('receipt') || normalized.contains('payment')) {
      return Icons.receipt_long_outlined;
    }
    if (normalized.contains('reminder')) {
      return Icons.notifications_active_outlined;
    }
    if (normalized.contains('loan')) {
      return Icons.account_balance_wallet_outlined;
    }
    return Icons.notifications_outlined;
  }
}
