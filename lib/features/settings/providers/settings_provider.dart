import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  final bool autoScanEnabled;
  final bool darkModeEnabled;
  final bool ocrOnWifiOnly;
  final int scanIntervalHours;

  const AppSettings({
    this.autoScanEnabled = true,
    this.darkModeEnabled = false,
    this.ocrOnWifiOnly = false,
    this.scanIntervalHours = 24,
  });

  AppSettings copyWith({
    bool? autoScanEnabled,
    bool? darkModeEnabled,
    bool? ocrOnWifiOnly,
    int? scanIntervalHours,
  }) {
    return AppSettings(
      autoScanEnabled: autoScanEnabled ?? this.autoScanEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      ocrOnWifiOnly: ocrOnWifiOnly ?? this.ocrOnWifiOnly,
      scanIntervalHours: scanIntervalHours ?? this.scanIntervalHours,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  void toggleAutoScan() => state = state.copyWith(autoScanEnabled: !state.autoScanEnabled);
  void toggleDarkMode() => state = state.copyWith(darkModeEnabled: !state.darkModeEnabled);
  void toggleOcrWifiOnly() => state = state.copyWith(ocrOnWifiOnly: !state.ocrOnWifiOnly);
  void setScanInterval(int hours) => state = state.copyWith(scanIntervalHours: hours);
}
