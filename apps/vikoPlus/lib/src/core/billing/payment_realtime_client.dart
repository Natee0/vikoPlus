import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../auth/auth_session.dart';
import '../config/app_config.dart';

final paymentRealtimeClientProvider = Provider<PaymentRealtimeClient>((ref) {
  return PaymentRealtimeClient(ref);
});

class PaymentRealtimeClient {
  const PaymentRealtimeClient(this._ref);

  final Ref _ref;

  Stream<PaymentRealtimeEvent> watchGroup(String groupId) {
    final token = _ref.read(authSessionProvider).accessToken;
    if (token == null || token.isEmpty) {
      return const Stream<PaymentRealtimeEvent>.empty();
    }

    late final io.Socket socket;
    final controller = StreamController<PaymentRealtimeEvent>(
      onCancel: () {
        socket.dispose();
      },
    );

    socket = io.io(
      _socketBaseUrl(),
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/socket.io')
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    socket.onConnect((_) {
      socket.emit('payment.watch', {'groupId': groupId});
    });
    socket.on('payment.updated', (payload) {
      if (payload is Map) {
        controller.add(
          PaymentRealtimeEvent.fromJson(Map<String, dynamic>.from(payload)),
        );
      }
    });
    socket.onConnectError((_) {});
    socket.onError((_) {});
    socket.connect();
    return controller.stream;
  }

  String _socketBaseUrl() {
    final uri = Uri.parse(AppConfig.VIKOPLUS_API_BASE_URL);
    final path = uri.path.replaceFirst(RegExp(r'/v1/?$'), '');
    final normalizedPath = path.replaceFirst(RegExp(r'/+$'), '');
    final namespacePath = normalizedPath.isEmpty
        ? '/payments'
        : '$normalizedPath/payments';
    return uri
        .replace(path: namespacePath, query: '')
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }
}

class PaymentRealtimeEvent {
  const PaymentRealtimeEvent({
    required this.groupId,
    required this.productType,
    required this.status,
    this.orderId,
    this.planCode,
    this.packageCode,
    this.remainingCredits,
  });

  factory PaymentRealtimeEvent.fromJson(Map<String, dynamic> json) {
    return PaymentRealtimeEvent(
      groupId: json['groupId'] as String? ?? '',
      productType: json['productType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      orderId: json['orderId'] as String?,
      planCode: json['planCode'] as String?,
      packageCode: json['packageCode'] as String?,
      remainingCredits: json['remainingCredits'] as int?,
    );
  }

  final String groupId;
  final String productType;
  final String status;
  final String? orderId;
  final String? planCode;
  final String? packageCode;
  final int? remainingCredits;

  bool get isConfirmed => status == 'ACTIVE' || status == 'PAID';
}
