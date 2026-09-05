import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/groups/groups_repository.dart';

class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.go('/notifications'),
      icon: FutureBuilder<NotificationsResult>(
        future: ref.read(groupsRepositoryProvider).notifications(),
        builder: (context, snapshot) {
          final notifications = snapshot.data?.notifications ?? const [];
          final unreadCount = notifications.where((item) => item.isUnread).length;
          final icon = Icon(
            unreadCount > 0
                ? Icons.notifications_active_outlined
                : Icons.notifications_outlined,
          );

          if (unreadCount == 0) return icon;

          return Badge(
            smallSize: 8,
            label: unreadCount > 9 ? const Text('9+') : null,
            child: icon,
          );
        },
      ),
    );
  }
}
