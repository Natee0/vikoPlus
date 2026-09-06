import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_session.dart';

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(
    authSessionProvider.select((session) => session.user?.id),
  );
  if (userId == null) return {};
  final response = await ref
      .watch(apiClientProvider)
      .get<Map<String, dynamic>>('/me/profile');
  final body = response.data!;
  return body['data'] is Map
      ? Map<String, dynamic>.from(body['data'] as Map)
      : body;
});
