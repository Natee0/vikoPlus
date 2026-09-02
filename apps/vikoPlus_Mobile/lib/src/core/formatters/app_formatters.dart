import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters(this.localeName);

  final String localeName;

  String money(int amountMinor, {String currency = 'TZS'}) {
    return NumberFormat.currency(
      locale: localeName,
      name: currency,
      symbol: currency,
      decimalDigits: 0,
    ).format(amountMinor);
  }

  String compactPercent(num value) {
    return NumberFormat.percentPattern(localeName).format(value);
  }

  String date(DateTime value) {
    return DateFormat.yMMMd(localeName).format(value);
  }
}
