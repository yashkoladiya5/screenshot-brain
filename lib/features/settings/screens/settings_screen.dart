import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Scanning'),
          SwitchListTile(
            title: const Text('Auto-scan screenshots'),
            subtitle: const Text('Automatically scan for new screenshots'),
            value: settings.autoScanEnabled,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleAutoScan(),
          ),
          SwitchListTile(
            title: const Text('OCR on Wi-Fi only'),
            subtitle: const Text('Process OCR only when connected to Wi-Fi'),
            value: settings.ocrOnWifiOnly,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleOcrWifiOnly(),
          ),
          ListTile(
            title: const Text('Scan Interval'),
            subtitle: Text('Every ${settings.scanIntervalHours} hours'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showIntervalPicker(context, ref, settings.scanIntervalHours),
          ),
          const Divider(),
          const _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: settings.darkModeEnabled,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleDarkMode(),
          ),
          const Divider(),
          const _SectionHeader(title: 'About'),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Database'),
            subtitle: const Text('Isar Local Database'),
          ),
          const Divider(),
          _buildDangerZone(context),
        ],
      ),
    );
  }

  void _showIntervalPicker(BuildContext context, WidgetRef ref, int current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Scan Interval'),
        children: [6, 12, 24, 48, 72].map((hours) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(settingsProvider.notifier).setScanInterval(hours);
              Navigator.pop(ctx);
            },
            child: Text('$hours hours${hours == current ? ' (current)' : ''}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Data Management'),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text('Rescan All Screenshots', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          subtitle: const Text('Clear all data and rescan'),
          onTap: () => _confirmRescan(context),
        ),
      ],
    );
  }

  void _confirmRescan(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rescan All?'),
        content: const Text('This will clear all existing data and rescan your screenshots. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text('Rescan', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
