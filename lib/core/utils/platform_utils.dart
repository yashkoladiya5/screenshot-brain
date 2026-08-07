import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtils {
  /// Checks if the current environment is running on the Web.
  static bool get isWeb => kIsWeb;

  /// Checks if the current platform is iOS (excluding Web).
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Checks if the current platform is Android (excluding Web).
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Checks if the current platform is macOS (excluding Web).
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Checks if the current platform is Windows (excluding Web).
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Checks if the current platform is Linux (excluding Web).
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  
  /// Helper to check if the platform is a desktop operating system natively.
  static bool get isDesktop => isMacOS || isWindows || isLinux;
  
  /// Helper to check if the platform is a mobile operating system natively.
  static bool get isMobile => isIOS || isAndroid;
}
