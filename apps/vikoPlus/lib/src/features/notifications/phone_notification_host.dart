import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_session.dart';
import '../../core/groups/groups_repository.dart';

class PhoneNotificationHost extends ConsumerStatefulWidget {
  const PhoneNotificationHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PhoneNotificationHost> createState() =>
      _PhoneNotificationHostState();
}

class _PhoneNotificationHostState extends ConsumerState<PhoneNotificationHost> {
  static const _pollInterval = Duration(seconds: 45);
  static final _shownNotificationIds = <String>{};

  final _plugin = FlutterLocalNotificationsPlugin();
  Timer? _timer;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenSubscription;
  bool _initialized = false;
  bool _seeded = false;
  bool _polling = false;
  String? _registeredToken;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageSubscription?.cancel();
    _tokenSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(initializationSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _showRemoteMessage,
    );
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) {
      unawaited(_registerToken(token));
    });
    _initialized = true;
  }

  void _syncPolling(bool authenticated) {
    if (!authenticated) {
      _timer?.cancel();
      _timer = null;
      _seeded = false;
      _registeredToken = null;
      return;
    }
    unawaited(_registerCurrentToken());
    if (_timer != null) {
      return;
    }
    unawaited(_poll());
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(_poll()));
  }

  Future<void> _poll() async {
    if (_polling || !_initialized) {
      return;
    }
    _polling = true;
    try {
      final result = await ref.read(groupsRepositoryProvider).notifications();
      final unread = result.notifications.where((item) => item.isUnread);
      if (!_seeded) {
        _shownNotificationIds.addAll(unread.map((item) => item.id));
        _seeded = true;
        return;
      }

      for (final notification in unread) {
        if (!_shownNotificationIds.add(notification.id)) {
          continue;
        }
        await _plugin.show(
          notification.id.hashCode & 0x7fffffff,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'vikoplus_group_alerts',
              'Vikoplus group alerts',
              channelDescription:
                  'Payment, loan, reminder, and group activity alerts.',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: notification.id,
        );
      }
    } catch (_) {
      // Notification polling should never interrupt the active screen.
    } finally {
      _polling = false;
    }
  }

  Future<void> _registerCurrentToken() async {
    if (!_initialized) {
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (_) {
      // Push token registration is retried by the next notification poll.
    }
  }

  Future<void> _registerToken(String token) async {
    if (_registeredToken == token) {
      return;
    }
    final authenticated = ref.read(authSessionProvider).isAuthenticated;
    if (!authenticated) {
      return;
    }
    try {
      await ref
          .read(groupsRepositoryProvider)
          .registerPushToken(token: token, platform: _platformName);
      _registeredToken = token;
    } catch (_) {
      // Keep the app usable even when token sync fails.
    }
  }

  Future<void> _showRemoteMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    if (title == null || body == null || title.isEmpty || body.isEmpty) {
      return;
    }

    await _plugin.show(
      (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) &
          0x7fffffff,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vikoplus_group_alerts',
          'Vikoplus group alerts',
          channelDescription:
              'Payment, loan, reminder, and group activity alerts.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['notificationId'],
    );
  }

  String get _platformName {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'web',
    };
  }

  @override
  Widget build(BuildContext context) {
    final authenticated = ref.watch(
      authSessionProvider.select((session) => session.isAuthenticated),
    );
    _syncPolling(authenticated);
    return widget.child;
  }
}
