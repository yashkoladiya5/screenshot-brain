import 'num_extensions.dart';

extension IntExtensions on int {
  /// Simple pluralization helper.
  /// Example: `1.pluralize('item')` -> "1 item"
  /// Example: `5.pluralize('item')` -> "5 items"
  String pluralize(String singular, [String? plural]) {
    final pluralWord = plural ?? '${singular}s';
    return this == 1 ? '$this $singular' : '$this $pluralWord';
  }

  /// Returns true if the integer is between [min] and [max] (inclusive).
  bool isBetween(int min, int max) {
    return this >= min && this <= max;
  }

  /// Clamps into `[min, max]`, asserting that `min <= max`.
  ///
  /// Keeps the int type (the `num` extension would widen to num):
  /// `15.coerceIn(0, 10)` -> `10`.
  int coerceIn(int min, int max) {
    assert(min <= max, 'min ($min) must not exceed max ($max)');
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Formats this integer with Indian digit grouping and a currency symbol.
  ///
  /// Example: `129900.toIndianRupees()` -> `'₹1,29,900'`,
  /// `5000.toIndianRupees(decimals: 2)` -> `'₹5,000.00'`.
  String toIndianRupees({String symbol = '₹', int decimals = 0}) =>
      formatIndianNumber(this, symbol: symbol, decimals: decimals);
}
