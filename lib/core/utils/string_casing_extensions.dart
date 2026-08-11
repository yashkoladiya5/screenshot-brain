extension StringCasingExtensions on String {
  /// Converts the first character of the string to uppercase and the rest to lowercase.
  /// Example: "hElLo".toCapitalized() -> "Hello"
  String toCapitalized() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Converts the string to Title Case (capitalizes the first letter of each word).
  /// Example: "hello world".toTitleCase() -> "Hello World"
  String toTitleCase() {
    if (isEmpty) return this;
    return replaceAll(RegExp(r' +'), ' ')
        .split(' ')
        .map((str) => str.toCapitalized())
        .join(' ');
  }
}
