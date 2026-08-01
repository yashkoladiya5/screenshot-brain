extension StringExtensions on String {
  /// Capitalizes the first letter of the string.
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes the first letter of every word in the string.
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalizeFirst()).join(' ');
  }

  /// Checks if a string is a valid email.
  bool get isValidEmail {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegExp.hasMatch(this);
  }

  /// Truncates the string to the specified length and appends '...'
  String truncate(int length) {
    if (this.length <= length) return this;
    return '${substring(0, length)}...';
  }
}
