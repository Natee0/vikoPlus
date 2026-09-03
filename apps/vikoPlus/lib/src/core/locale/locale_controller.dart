import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = AsyncData(locale);
  }
}
