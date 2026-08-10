import 'package:intl/intl.dart';

extension DoubleExtensions on double {
  /// Formats the double as a currency string.
  /// Example: 1234.5.toCurrencyString() -> "$1,234.50"
  String toCurrencyString({
    String locale = 'en_US',
    String symbol = '\$',
    int decimalDigits = 2,
  }) {
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(this);
  }

  /// Formats the double as a compact currency string.
  /// Example: 1500000.toCompactCurrency() -> "$1.5M"
  String toCompactCurrency({
    String locale = 'en_US',
    String symbol = '\$',
  }) {
    return NumberFormat.compactCurrency(
      locale: locale,
      symbol: symbol,
    ).format(this);
  }

  /// Formats the double to a specified number of decimal places without trailing zeros.
  /// Example: 1.5000.toMaxDecimals(2) -> "1.5"
  String toMaxDecimals([int decimals = 2]) {
    String formatted = toStringAsFixed(decimals);
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0*$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }
    return formatted;
  }
}
