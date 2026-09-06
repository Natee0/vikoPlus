import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters(this.localeName);

  final String localeName;

  String money(int amountMinor, {String currency = 'TZS'}) {
    final formatter = NumberFormat.decimalPattern(localeName)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = 0;
    final amount = formatter.format(amountMinor);
    return '${currency.trim()} $amount';
  }

  String compactPercent(num value) {
    return NumberFormat.percentPattern(localeName).format(value);
  }

  String compactMoney(int amountMinor, {String currency = 'TZS'}) {
    const suffixes = ['', 'K', 'M', 'B', 'T'];
    var scaled = amountMinor.toDouble();
    var unit = 0;
    while (scaled.abs() >= 1000 && unit < suffixes.length - 1) {
      scaled /= 1000;
      unit++;
    }
    if (unit == 0) return money(amountMinor, currency: currency);
    scaled = (scaled * 10).round() / 10;
    if (scaled.abs() >= 1000 && unit < suffixes.length - 1) {
      scaled /= 1000;
      unit++;
    }
    final number = NumberFormat('0.#', localeName).format(scaled);
    return '${currency.trim()} $number${suffixes[unit]}';
  }

  String date(DateTime value) {
    return DateFormat.yMMMd(localeName).format(value);
  }
}
