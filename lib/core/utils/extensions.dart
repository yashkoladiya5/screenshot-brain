import 'package:flutter/material.dart';

import 'string_validators.dart';

/// Barrel over the app's core Dart extensions.
///
/// `export`s (not duplicate definitions) keep every extension single-homed in
/// its own library. In particular all `DateTime` behaviour comes from exactly
/// one extension — [DateTimeExtensions] in `date_extensions.dart` — so an
/// importer of this barrel can never hit an ambiguous extension member on
/// `DateTime`.
export 'date_extensions.dart';
export 'file_extensions.dart';
export 'string_casing_extensions.dart';
export 'string_extensions.dart';

extension StringExtension on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Truncates to 100 UTF-16 code units plus an ellipsis.
  ///
  /// The cut backs off by one unit when it would land inside a surrogate
  /// pair (emoji in screenshot OCR text is common), so the result never
  /// carries a dangling half that corrupts rendering or encoding.
  String get truncated {
    if (length <= 100) return this;
    var cut = 100;
    if ((codeUnitAt(cut - 1) & 0xFC00) == 0xD800) cut -= 1;
    return '${substring(0, cut)}...';
  }

  /// Strict address check shared with the form validators; `contains('@')`
  /// accepted `'@'`, `'a@@b.com'` and `'user@'`, which is never valid.
  bool get isEmail => StringValidators.isValidEmail(this);

  bool get isPhoneNumber =>
      RegExp(r'^[\+]?[(]?[0-9]{1,4}[)]?[-\s\./0-9]*$').hasMatch(this);
}

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
