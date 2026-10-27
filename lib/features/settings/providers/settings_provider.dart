import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable application settings.
///
/// This is the single source of truth for user preferences. Equality is
/// value-based so that [StateNotifier] skips redundant notifications when a
/// mutation produces an identical state.
class AppSettings {
  final bool autoScanEnabled;
  final bool ocrOnWifiOnly;
  final int scanIntervalHours;
  final ThemeMode themeMode;

  const AppSettings({
    this.autoScanEnabled = true,
    this.ocrOnWifiOnly = false,
    this.scanIntervalHours = 24,
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    bool? autoScanEnabled,
    bool? ocrOnWifiOnly,
    int? scanIntervalHours,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      autoScanEnabled: autoScanEnabled ?? this.autoScanEnabled,
      ocrOnWifiOnly: ocrOnWifiOnly ?? this.ocrOnWifiOnly,
      scanIntervalHours: scanIntervalHours ?? this.scanIntervalHours,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.autoScanEnabled == autoScanEnabled &&
        other.ocrOnWifiOnly == ocrOnWifiOnly &&
        other.scanIntervalHours == scanIntervalHours &&
        other.themeMode == themeMode;
  }

  @override
  int get hashCode =>
      Object.hash(autoScanEnabled, ocrOnWifiOnly, scanIntervalHours, themeMode);

  @override
  String toString() =>
      'AppSettings(autoScan: $autoScanEnabled, wifiOnlyOcr: $ocrOnWifiOnly, '
      'interval: ${scanIntervalHours}h, theme: ${themeMode.name})';
}

/// Persistence hook point for [AppSettings].
///
/// The app currently has no on-device settings storage wired up; this seam
/// keeps the notifier storage-agnostic so any backing store (a file, the
/// existing Isar database, etc.) can be plugged into [SettingsNotifier] later
/// without touching the UI layer.
abstract class SettingsPersistence {
  const SettingsPersistence();

  /// Returns previously stored settings, or null when nothing is stored yet.
  Future<AppSettings?> load();

  /// Persists the latest settings. Must never throw to the caller's face;
  /// failures are logged and ignored by [SettingsNotifier].
  Future<void> save(AppSettings settings);
}

/// Process-lifetime in-memory persistence (the default when nothing is
/// injected). Keeps the last committed snapshot available across notifier
/// rebuilds within a session.
class InMemorySettingsPersistence implements SettingsPersistence {
  AppSettings? _snapshot;

  @override
  Future<AppSettings?> load() async => _snapshot;

  @override
  Future<void> save(AppSettings settings) async => _snapshot = settings;
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier(persistence: InMemorySettingsPersistence());
});

/// Derived theme selection, watchable by the app root so a settings change is
/// applied immediately wherever `MaterialApp.themeMode` is defined.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsProvider.select((s) => s.themeMode)),
);

/// Effective brightness for the current selection given the platform
/// brightness (useful when [ThemeMode.system] is selected).
final resolvedBrightnessProvider = Provider<Brightness>((ref) {
  final mode = ref.watch(themeModeProvider);
  final platform =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;
  switch (mode) {
    case ThemeMode.light:
      return Brightness.light;
    case ThemeMode.dark:
      return Brightness.dark;
    case ThemeMode.system:
      return platform;
  }
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier({SettingsPersistence? persistence})
    : _persistence = persistence,
      super(const AppSettings()) {
    // A notifier built over a non-empty store IS an app restart: pull the
    // stored snapshot back in right away, otherwise the const defaults would
    // silently win and every persisted preference is lost on launch.
    unawaited(load());
  }

  final SettingsPersistence? _persistence;

  /// True once a mutation went through [_commit] in this session: a restore
  /// resolving later must never clobber what the user just changed.
  bool _hasUserMutation = false;

  /// True once the initial restore has been resolved (applied or skipped).
  bool _restoreApplied = false;

  /// Restores persisted settings (if any) without notifying when unchanged.
  /// Runs automatically at construction and is safe to call again: it never
  /// overwrites a real user change or a snapshot already applied.
  Future<void> load() async {
    final persistence = _persistence;
    if (persistence == null || _restoreApplied || _hasUserMutation) return;
    AppSettings? stored;
    try {
      stored = await persistence.load();
    } catch (_) {
      // A store that cannot be read behaves like an empty one: keep defaults.
      _restoreApplied = true;
      return;
    }
    if (_restoreApplied || _hasUserMutation || !mounted) return;
    _restoreApplied = true;
    if (stored != null && stored != state) {
      state = stored;
    }
  }

  void toggleAutoScan() =>
      _commit(state.copyWith(autoScanEnabled: !state.autoScanEnabled));

  void toggleOcrWifiOnly() =>
      _commit(state.copyWith(ocrOnWifiOnly: !state.ocrOnWifiOnly));

  void setScanInterval(int hours) {
    final clamped = hours.clamp(1, 24 * 7);
    _commit(state.copyWith(scanIntervalHours: clamped));
  }

  void setThemeMode(ThemeMode mode) => _commit(state.copyWith(themeMode: mode));

  /// The only path that mutates [state]: no-op on identical settings, so
  /// listeners fire only on a real change.
  void _commit(AppSettings next) {
    if (next == state) return;
    _hasUserMutation = true;
    state = next;
    final persistence = _persistence;
    if (persistence == null) return;
    try {
      unawaited(
        persistence.save(next).catchError((Object _) {
          // Persistence must never break the UI state update.
        }),
      );
    } catch (_) {
      // A store that throws SYNCHRONOUSLY must also not break the UI: this
      // runs straight inside a switch/radio tap handler, and the seam
      // contract promises failures are logged and ignored here.
    }
  }
}
