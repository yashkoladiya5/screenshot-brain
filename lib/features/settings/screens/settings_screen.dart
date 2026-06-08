import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../../../core/design/tokens.dart';
import '../../../core/components/sb_card.dart';
import '../../../core/theme/theme_extensions.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sb = context.sb;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(SBSpacing.lg),
        children: [
          _Section(title: 'Scanning'),
          SbCard(
            child: Column(
              children: [
                _SettingSwitch(
                  icon: Icons.sync_rounded,
                  title: 'Auto-scan screenshots',
                  subtitle: 'Automatically scan for new screenshots',
                  value: settings.autoScanEnabled,
                  onChanged: (_) => ref.read(settingsProvider.notifier).toggleAutoScan(),
                ),
                const Divider(height: 1, indent: 52),
                _SettingSwitch(
                  icon: Icons.wifi_rounded,
                  title: 'OCR on Wi-Fi only',
                  subtitle: 'Process OCR only when connected to Wi-Fi',
                  value: settings.ocrOnWifiOnly,
                  onChanged: (_) => ref.read(settingsProvider.notifier).toggleOcrWifiOnly(),
                ),
                const Divider(height: 1, indent: 52),
                _SettingTile(
                  icon: Icons.timer_rounded,
                  title: 'Scan Interval',
                  subtitle: 'Every ${settings.scanIntervalHours} hours',
                  onTap: () => _showIntervalPicker(context, ref, settings.scanIntervalHours),
                ),
              ],
            ),
          ),

          const SizedBox(height: SBSpacing.xxl),
          _Section(title: 'Appearance'),
          SbCard(
            child: _SettingSwitch(
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: 'Use dark theme',
              value: settings.darkModeEnabled,
              onChanged: (_) => ref.read(settingsProvider.notifier).toggleDarkMode(),
            ),
          ),

          const SizedBox(height: SBSpacing.xxl),
          _Section(title: 'About'),
          SbCard(
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '1.0.0',
                ),
                const Divider(height: 1, indent: 52),
                _SettingTile(
                  icon: Icons.storage_rounded,
                  title: 'Database',
                  subtitle: 'Isar Local Database',
                ),
              ],
            ),
          ),

          const SizedBox(height: SBSpacing.xxl),
          _Section(title: 'Data'),
          SbCard(
            child: _SettingTile(
              icon: Icons.refresh_rounded,
              title: 'Rescan All Screenshots',
              subtitle: 'Clear all data and rescan',
              trailing: Icon(Icons.chevron_right_rounded, color: sb.textTertiary, size: SBSizes.iconMd),
              onTap: () => _confirmRescan(context),
            ),
          ),

          const SizedBox(height: SBSpacing.xxxl),
        ],
      ),
    );
  }

  void _showIntervalPicker(BuildContext context, WidgetRef ref, int current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scan Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [6, 12, 24, 48, 72].map((hours) {
            return RadioListTile<int>(
              title: Text('$hours hours'),
              value: hours,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setScanInterval(value);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
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
            onPressed: () => Navigator.pop(ctx),
            child: Text('Rescan', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SBSpacing.md),
      child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: context.sb.textSecondary)),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm, vertical: SBSpacing.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SBSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SBRadius.sm),
            ),
            child: Icon(icon, size: SBSizes.iconMd, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: SBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: SBSpacing.xxs),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SBRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm, vertical: SBSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(SBSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(SBRadius.sm),
              ),
              child: Icon(icon, size: SBSizes.iconMd, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: SBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: SBSpacing.xxs),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
