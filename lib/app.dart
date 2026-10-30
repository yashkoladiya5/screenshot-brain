import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/screenshots/providers/screenshot_provider.dart';
import 'features/settings/providers/settings_provider.dart';

/// File name of the persisted settings snapshot, inside the application
/// documents directory (the same location the Isar database lives in).
const String kSettingsFileName = 'app_settings.json';

/// Serializes and restores [AppSettings] as a small JSON file.
///
/// This is the disk-backed implementation of the [SettingsPersistence] seam:
/// a preference changed in the UI is written through [save] and pulled back
/// in by [SettingsNotifier.load] on the next launch, so settings survive a
/// restart of the shipped app.
class FileSettingsPersistence implements SettingsPersistence {
  FileSettingsPersistence(this._file);

  final File _file;

  /// The file this store reads and writes. Exposed for tests/diagnostics.
  @visibleForTesting
  File get file => _file;

  @override
  Future<AppSettings?> load() async {
    try {
      final raw = await _file.readAsString();
      return decodeAppSettings(raw);
    } catch (_) {
      // No file yet (first launch) or an unreadable one behaves like an
      // empty store: the notifier keeps its defaults.
      return null;
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    try {
      await _file.writeAsString(encodeAppSettings(settings));
    } catch (error, stack) {
      // Seam contract: persistence failures never reach the caller.
      debugPrint('[SettingsStore] save failed (ignored): $error');
      // The exception alone rarely identifies a failed write — the path is
      // usually a full disk, a revoked sandbox or a concurrent rename.
      debugPrintStack(stackTrace: stack);
    }
  }
}

/// Encodes [settings] in the on-disk format.
String encodeAppSettings(AppSettings settings) => jsonEncode({
  'autoScanEnabled': settings.autoScanEnabled,
  'ocrOnWifiOnly': settings.ocrOnWifiOnly,
  'scanIntervalHours': settings.scanIntervalHours,
  'themeMode': settings.themeMode.name,
});

/// Restores an [AppSettings] from the on-disk format.
///
/// Returns null for anything that is not a JSON object, and falls back to the
/// default value per missing/invalid field — a partially corrupted file must
/// never brick the settings screen.
AppSettings? decodeAppSettings(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return AppSettings(
      autoScanEnabled: decoded['autoScanEnabled'] is bool
          ? decoded['autoScanEnabled'] as bool
          : true,
      ocrOnWifiOnly: decoded['ocrOnWifiOnly'] is bool
          ? decoded['ocrOnWifiOnly'] as bool
          : false,
      scanIntervalHours: decoded['scanIntervalHours'] is num
          ? (decoded['scanIntervalHours'] as num).toInt()
          : 24,
      themeMode: _themeModeFromName(decoded['themeMode']) ?? ThemeMode.system,
    );
  } catch (_) {
    return null;
  }
}

ThemeMode? _themeModeFromName(Object? name) {
  if (name is! String) return null;
  for (final mode in ThemeMode.values) {
    if (mode.name == name) return mode;
  }
  return null;
}

/// The settings file inside the given documents directory. Pure path
/// computation, so the storage location has exactly one definition and is
/// unit-testable.
@visibleForTesting
File settingsFileFor(Directory documentsDirectory) =>
    File('${documentsDirectory.path}/$kSettingsFileName');

/// Provider overrides injected into the root `ProviderScope` at startup.
///
/// Today this is only the file-backed [SettingsPersistence] wired through the
/// existing `SettingsNotifier(persistence: ...)` seam. On any failure (no
/// documents directory available, unwritable file) it returns no overrides,
/// so the app falls back to the in-memory default store instead of failing to
/// render.
Future<List<Override>> buildStartupOverrides({
  Future<Directory> Function()? documentsDirectory,
}) async {
  try {
    final directory =
        await (documentsDirectory ?? getApplicationDocumentsDirectory)();
    return settingsOverridesFor(settingsFileFor(directory));
  } catch (error, stack) {
    debugPrint('[app bootstrap] settings store unavailable: $error');
    debugPrintStack(stackTrace: stack);
    return const [];
  }
}

/// Wraps [settingsFile] in the override that gives the app its persistent
/// settings store.
List<Override> settingsOverridesFor(File settingsFile) => [
  settingsProvider.overrideWith(
    (ref) =>
        SettingsNotifier(persistence: FileSettingsPersistence(settingsFile)),
  ),
];

class ScreenshotBrainApp extends ConsumerStatefulWidget {
  const ScreenshotBrainApp({super.key});

  @override
  ConsumerState<ScreenshotBrainApp> createState() => _ScreenshotBrainAppState();
}

/// App root with the lifecycle-driven auto-scan scheduling.
///
/// `ScanScreenshotsNotifier.scanIfDue()` already owns the policy (enabled
/// flag + cadence + stamping); what was missing was any production caller.
/// This state is that caller: it fires the gate once after the first frame
/// and again whenever the app returns to the foreground, and tears the
/// lifecycle listener down with itself.
class _ScreenshotBrainAppState extends ConsumerState<ScreenshotBrainApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _scheduleAutoScan);
    // The launch-time pass runs right after the first frame: boot rendering
    // is never blocked by the scan scheduler.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAutoScan());
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _scheduleAutoScan() {
    if (!mounted) return;
    unawaited(_runAutoScan());
  }

  Future<void> _runAutoScan() async {
    // Hydrate the settings first. The restore runs asynchronously behind the
    // persistence seam, and the cadence gate must see the user's stored
    // enabled flag — not the in-memory defaults — before deciding to scan.
    await ref.read(settingsProvider.notifier).load();
    if (!mounted) return;
    await ref.read(scanScreenshotsProvider.notifier).scanIfDue();
  }

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Screenshot Brain',
      debugShowCheckedModeBanner: false,
      theme: ScreenshotBrainTheme.light,
      darkTheme: ScreenshotBrainTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
