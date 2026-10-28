import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/database_service.dart';

// 1. App entry point: the whole bootstrap runs inside its own error zone so
//    both synchronous and asynchronous uncaught errors are logged instead of
//    silently terminating the isolate.
void main() {
  runZonedGuarded<void>(_bootstrap, _reportUncaughtError);
}

// 2. Error-boundary plumbing.
Future<void> _bootstrap() async {
  // 3. Initialize Flutter bindings.
  WidgetsFlutterBinding.ensureInitialized();

  // Framework errors (build/layout/paint): present them through the standard
  // debug reporting channel — logged in the console, subtree shows the error
  // widget, the app itself keeps running.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportUncaughtError(details.exception, details.stack ?? StackTrace.empty);
  };

  // Platform/engine-originated errors that never reach FlutterError.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _reportUncaughtError(error, stack);
    return true; // Handled: log it, do not crash.
  };

  // 4. Initialize the database service. A failure here is reported but does
  //    not block runApp — the UI surfaces its own error states downstream.
  //    The timeout bounds the wait: a hung native open must not keep the app
  //    from ever rendering; the open continues in the background and the
  //    scan path re-checks `DatabaseService.isInitialized` on every call.
  try {
    await DatabaseService.init().timeout(_databaseInitTimeout);
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'database bootstrap',
      ),
    );
  }

  // 5. Build the startup provider overrides — a real, disk-backed settings
  //    store behind the SettingsPersistence seam. This only resolves a path;
  //    it never reads the file synchronously, and it degrades to the
  //    in-memory default store (empty override list) on any failure.
  final overrides = await buildStartupOverrides();

  // 6. Run the application. Cold start and hot restart both come through
  //    this function, so the same overrides apply to every ProviderScope.
  runApp(
    ProviderScope(overrides: overrides, child: const ScreenshotBrainApp()),
  );
}

/// How long the first frame may wait on the Isar open before the app renders
/// anyway. Generous: a healthy local open is milliseconds.
const Duration _databaseInitTimeout = Duration(seconds: 10);

void _reportUncaughtError(Object error, StackTrace stack) {
  debugPrint('Screenshot Brain: uncaught error -> $error');
  debugPrintStack(stackTrace: stack);
}
