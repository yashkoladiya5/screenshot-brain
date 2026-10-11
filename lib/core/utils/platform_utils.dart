import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform detection helpers.
///
/// All checks are [kIsWeb]-first: on the web `dart:io` is unavailable and
/// touching [Platform] throws, so every OS getter short-circuits to false
/// there. Off the web the [Platform] lookups are additionally guarded so a
/// host without a concrete OS binding (some test/embedded run contexts)
/// degrades to `false` instead of throwing [UnsupportedError] in debug.
class PlatformUtils {
  /// Checks if the current environment is running on the Web.
  static bool get isWeb => kIsWeb;

  /// Checks if the current platform is iOS (excluding Web).
  static bool get isIOS => _check(() => Platform.isIOS);

  /// Checks if the current platform is Android (excluding Web).
  static bool get isAndroid => _check(() => Platform.isAndroid);

  /// Checks if the current platform is macOS (excluding Web).
  static bool get isMacOS => _check(() => Platform.isMacOS);

  /// Checks if the current platform is Windows (excluding Web).
  static bool get isWindows => _check(() => Platform.isWindows);

  /// Checks if the current platform is Linux (excluding Web).
  static bool get isLinux => _check(() => Platform.isLinux);

  /// Helper to check if the platform is a desktop operating system natively.
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// Helper to check if the platform is a mobile operating system natively.
  static bool get isMobile => isIOS || isAndroid;

  /// A lowercase, human-readable platform name safe for logs and debug
  /// banners; returns `web` on the web and `unknown` when the host platform
  /// cannot be determined.
  static String get operatingSystem {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystem;
    } on UnsupportedError {
      return 'unknown';
    }
  }

  static bool _check(bool Function() test) {
    if (kIsWeb) return false;
    try {
      return test();
    } on UnsupportedError {
      // Debug/embedded fallback: an unqueryable platform is treated as
      // "not this OS" rather than crashing the widget tree.
      return false;
    }
  }
}
