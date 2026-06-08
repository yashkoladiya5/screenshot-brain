import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../providers/screenshot_provider.dart';

class ScreenshotDetailScreen extends ConsumerWidget {
  final String screenshotId;
  const ScreenshotDetailScreen({super.key, required this.screenshotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(screenshotId) ?? 0;
    final screenshotAsync = ref.watch(screenshotDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final screenshot = await ref.read(screenshotDetailProvider(id).future);
              if (screenshot != null) {
                await Share.shareXFiles(
                  [XFile(screenshot.filePath)],
                  text: screenshot.extractedText ?? 'No text extracted',
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
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
                ref.invalidate(screenshotListProvider);
                context.pop();
              }
            },
          ),
        ],
      ),
      body: screenshotAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => AppErrorWidget(message: error.toString(), onRetry: () => ref.invalidate(screenshotDetailProvider(id))),
        data: (screenshot) {
          if (screenshot == null) {
            return const AppErrorWidget(message: 'Screenshot not found');
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(screenshot.filePath),
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.broken_image, size: 64)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoChip(context, 'Category', screenshot.categoryDisplay, Icons.label),
                const SizedBox(height: 8),
                _buildInfoChip(context, 'Date', screenshot.dateDisplay, Icons.calendar_today),
                if (screenshot.isExpense) ...[
                  const SizedBox(height: 8),
                  _buildInfoChip(context, 'Expense', 'Contains expense data', Icons.currency_rupee),
                ],
                const SizedBox(height: 24),
                Text('Extracted Text', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    screenshot.extractedText ?? 'No text extracted yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
