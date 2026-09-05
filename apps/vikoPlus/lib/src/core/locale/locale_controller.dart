import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../auth/auth_session.dart';
import '../auth/auth_secure_storage.dart';

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends AsyncNotifier<Locale?> {
  static const _storage = FlutterSecureStorage();
  @override
  Future<Locale?> build() async {
    final user = ref.watch(authSessionProvider.select((session) => session.user));
    final code = user?.preferredLocale ?? await _storage.read(key: 'vikoplus.locale') ?? 'en';
    return Locale(code == 'sw' ? 'sw' : 'en');
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'sw'].contains(locale.languageCode)) return;
    final session = ref.read(authSessionProvider);
    if (session.isAuthenticated) {
      await ref.read(apiClientProvider).patch<void>('/me/language', data: {'locale': locale.languageCode});
      final current = ref.read(authSessionProvider);
      if (current.user?.id != session.user?.id) return;
      final user = AuthUser.fromJson({...current.user!.toJson(), 'preferredLocale': locale.languageCode});
      ref.read(authSessionProvider.notifier).setAuthenticated(accessToken: current.accessToken!, refreshToken: current.refreshToken!, user: user);
      await ref.read(authSecureStorageProvider).saveSession(ref.read(authSessionProvider));
    }
    await _storage.write(key: 'vikoplus.locale', value: locale.languageCode);
    state = AsyncData(locale);
  }
}
