import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_session.dart';

final profileDisplayNameProvider = Provider<String>((ref) {
  final profile = ref.watch(profileProvider).asData?.value;
  final name = (profile?['displayName'] as String?)?.trim();
  if (name != null && name.isNotEmpty) return name;
  return ref.watch(authSessionProvider).user?.displayName?.trim() ?? '';
});

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
