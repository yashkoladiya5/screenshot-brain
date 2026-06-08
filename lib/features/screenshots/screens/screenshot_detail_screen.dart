import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/screenshot_provider.dart';
import '../../../core/design/tokens.dart';
import '../../../core/components/sb_loading.dart';
import '../../../core/components/sb_card.dart';
import '../../../core/theme/app_colors.dart';

class ScreenshotDetailScreen extends ConsumerWidget {
  final String screenshotId;
  const ScreenshotDetailScreen({super.key, required this.screenshotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(screenshotId) ?? 0;
    final screenshotAsync = ref.watch(screenshotDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: () async {
              final screenshot = await ref.read(screenshotDetailProvider(id).future);
              if (screenshot != null) {
                await Share.shareXFiles(
                  [XFile(screenshot.filePath)],
                  text: screenshot.extractedText ?? '',
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Screenshot'),
                  content: const Text('Are you sure you want to delete this screenshot?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                ref.read(deleteScreenshotProvider(id));
                ref.invalidate(screenshotListProvider);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: screenshotAsync.when(
        loading: () => const SbLoading(),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: SBSpacing.lg),
              Text('Error: $error'),
              const SizedBox(height: SBSpacing.lg),
              FilledButton(
                onPressed: () => ref.invalidate(screenshotDetailProvider(id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (screenshot) {
          if (screenshot == null) {
            return const Center(child: Text('Screenshot not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(SBSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screenshot preview
                GestureDetector(
                  onTap: () => context.push('/viewer/$screenshotId'),
                  child: SbCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(SBRadius.xl),
                      child: Image.file(
                        File(screenshot.filePath),
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Center(child: Icon(Icons.broken_image_rounded, size: 64)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: SBSpacing.xxl),

                // Info section
                SbCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.label_rounded,
                        label: 'Category',
                        value: screenshot.categoryDisplay,
                        valueColor: AppColors.categoryPayments,
                      ),
                      const Divider(height: SBSpacing.xxl),
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: screenshot.dateDisplay,
                      ),
                      if (screenshot.isExpense) ...[
                        const Divider(height: SBSpacing.xxl),
                        _InfoRow(
                          icon: Icons.currency_rupee_rounded,
                          label: 'Expense',
                          value: 'Contains expense data',
                          valueColor: AppColors.success,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: SBSpacing.xxl),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/viewer/$screenshotId'),
                        icon: const Icon(Icons.fullscreen_rounded, size: SBSizes.iconMd),
                        label: const Text('Open Fullscreen'),
                      ),
                    ),
                    const SizedBox(width: SBSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final s = await ref.read(screenshotDetailProvider(id).future);
                          if (s != null) {
                            await Share.shareXFiles(
                              [XFile(s.filePath)],
                              text: s.extractedText ?? '',
                            );
                          }
                        },
                        icon: const Icon(Icons.share_rounded, size: SBSizes.iconMd),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SBSpacing.xxl),

                // Extracted text
                Text('Extracted Text', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: SBSpacing.md),
                SbCard(
                  child: Text(
                    screenshot.extractedText ?? 'No text extracted yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
                const SizedBox(height: SBSpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
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
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: SBSpacing.xxs),
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor ?? theme.colorScheme.onSurface,
              )),
            ],
          ),
        ),
      ],
    );
  }
}
