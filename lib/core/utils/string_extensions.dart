extension StringExtensions on String {
  /// Capitalizes the first letter of the string, keeping the rest as-is.
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
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(this);
  }

  /// Truncates the string to the specified length and appends '...'
  String truncate(int length) {
    if (this.length <= length) return this;
    return '${substring(0, length)}...';
  }

  /// Collapses every run of whitespace into a single space and trims ends.
  ///
  /// `'  hello \t\n world ' -> 'hello world'`.
  String collapseWhitespace() => trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Truncates to at most [maxRunes] code points and appends [ellipsis].
  ///
  /// Counting by runes (code points) instead of UTF-16 code units means an
  /// emoji in the kept portion is never cut into a dangling surrogate.
  /// Caveat: grapheme clusters drawn from several code points (skin-tone
  /// emoji, flags, combining marks) count as multiple runes, so a cluster
  /// may still be split between its members.
  String truncateWithEllipsis(int maxRunes, {String ellipsis = '…'}) {
    assert(maxRunes > 0, 'maxRunes must be positive, got $maxRunes');
    if (runes.length <= maxRunes) return this;
    final kept = String.fromCharCodes(runes.take(maxRunes));
    return '$kept$ellipsis';
  }

  /// Masks everything but the last [visibleSuffix] characters with
  /// [maskChar], e.g. card numbers: `'4111111111111234'.maskMiddle()`
  /// -> `'************1234'`. Strings no longer than the suffix stay intact.
  String maskMiddle({int visibleSuffix = 4, String maskChar = '*'}) {
    assert(visibleSuffix >= 0, 'visibleSuffix must not be negative');
    if (length <= visibleSuffix) return this;
    return maskChar * (length - visibleSuffix) +
        substring(length - visibleSuffix);
  }

  /// Uppercased initials of the whitespace-separated words, at most
  /// [maxLength] of them. Words without a letter (digits, punctuation)
  /// are skipped: `'Rahul 123 Das'.initials()` -> `'RD'`.
  String initials({int maxLength = 2, String separator = ''}) {
    assert(maxLength > 0, 'maxLength must be positive, got $maxLength');
    final letterPattern = RegExp(r'\p{L}', unicode: true);
    final picked = <String>[];
    for (final word in split(RegExp(r'\s+'))) {
      if (picked.length >= maxLength) break;
      final match = letterPattern.firstMatch(word);
      if (match != null) picked.add(match.group(0)!.toUpperCase());
    }
    return picked.join(separator);
  }

  /// URL-safe ASCII slug: lowercased, alphanumeric runs joined by
  /// [separator], leading/trailing separators trimmed.
  ///
  /// Caveat: characters outside `a-z0-9` are dropped, not transliterated
  /// (`'Café' -> 'caf'`), so accented input loses information.
  String slugify({String separator = '-'}) {
    var slug = trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      separator,
    );
    while (slug.startsWith(separator)) {
      slug = slug.substring(separator.length);
    }
    while (slug.endsWith(separator)) {
      slug = slug.substring(0, slug.length - separator.length);
    }
    return slug;
  }
}
