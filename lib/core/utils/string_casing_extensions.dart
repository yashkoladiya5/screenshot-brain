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
    return replaceAll(
      RegExp(r' +'),
      ' ',
    ).split(' ').map((str) => str.toCapitalized()).join(' ');
  }

  /// Converts to `snake_case` from camel/Pascal/kebab/spaced input.
  ///
  /// Word boundaries are detected between lower/digit and uppercase runs
  /// and inside acronyms: `'HTMLParser'.toSnakeCase()` -> `'html_parser'`,
  /// `'userID'` -> `'user_id'`, `'Foo2Bar'` -> `'foo2_bar'`.
  String toSnakeCase() {
    final separated = replaceAll(
      RegExp(r'(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
      '_',
    );
    return separated
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '')
        .toLowerCase();
  }

  /// Converts to `kebab-case`; the mirror of [toSnakeCase].
  /// Example: `'userID'.toKebabCase()` -> `'user-id'`.
  String toKebabCase() => toSnakeCase().replaceAll('_', '-');

  /// Converts to `camelCase`.
  ///
  /// `'user_name'` -> `'userName'`, `'UserName'` -> `'userName'`,
  /// `'USER_ID'` -> `'userId'`. Acronym runs are title-cased (`ID` -> `Id`
  /// inside), matching common linter expectations.
  String toCamelCase() {
    final pascal = toPascalCase();
    if (pascal.isEmpty) return pascal;
    return '${pascal[0].toLowerCase()}${pascal.substring(1)}';
  }

  /// Converts to `PascalCase`.
  /// Example: `'http server'` -> `'HttpServer'`.
  String toPascalCase() {
    final snake = toSnakeCase();
    if (snake.isEmpty) return '';
    final buffer = StringBuffer();
    for (final word in snake.split('_')) {
      if (word.isEmpty) continue;
      buffer.write('${word[0].toUpperCase()}${word.substring(1)}');
    }
    return buffer.toString();
  }
}
