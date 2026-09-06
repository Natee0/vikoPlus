import 'package:flutter_test/flutter_test.dart';
import 'package:vikoplus/src/core/formatters/app_formatters.dart';

void main() {
  for (final locale in ['en', 'sw']) {
    test('currency spacing for $locale', () {
      final formatter = AppFormatters(locale);
      expect(formatter.money(0), 'TZS 0');
      expect(formatter.money(10000), 'TZS 10,000');
      expect(formatter.money(-1000), 'TZS -1,000');
      expect(formatter.money(0, currency: 'KES'), 'KES 0');
      expect(formatter.compactMoney(0), 'TZS 0');
      expect(formatter.compactMoney(999), 'TZS 999');
      expect(formatter.compactMoney(100000), 'TZS 100K');
      expect(formatter.compactMoney(12500), 'TZS 12.5K');
      expect(formatter.compactMoney(999999), 'TZS 1M');
      expect(formatter.compactMoney(100000000), 'TZS 100M');
      expect(formatter.compactMoney(1000000000), 'TZS 1B');
      expect(formatter.compactMoney(1000000000000), 'TZS 1T');
      expect(formatter.compactMoney(-12500), 'TZS -12.5K');
    });
  }
}
