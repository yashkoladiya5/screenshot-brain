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
}
