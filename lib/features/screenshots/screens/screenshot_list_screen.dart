import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/screenshot_provider.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

class ScreenshotListScreen extends ConsumerWidget {
  const ScreenshotListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotsAsync = ref.watch(screenshotListProvider);
    final isScanning = ref.watch(scanningProvider);

    debugPrint('[ScreenshotListScreen] build() scanning=$isScanning asyncState=${screenshotsAsync.isLoading ? "loading" : screenshotsAsync.hasError ? "error" : "data"}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isScanning
            ? null
            : () => ref.read(scanScreenshotsProvider.notifier).scan(),
        icon: isScanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.scanner),
        label: Text(isScanning ? 'Scanning...' : 'Scan Screenshots'),
      ),
      body: screenshotsAsync.when(
        loading: () => const LoadingWidget(message: 'Loading screenshots...'),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(screenshotListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (screenshots) {
          debugPrint('[ScreenshotListScreen] data() count=${screenshots.length}');
          if (screenshots.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.photo_library_outlined,
              title: 'No Screenshots Yet',
              subtitle: 'Tap the button below to scan your screenshots',
              actionLabel: 'Scan Now',
              onAction: () => ref.read(scanScreenshotsProvider.notifier).scan(),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(screenshotListProvider);
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: screenshots.length,
              itemBuilder: (context, index) {
                final screenshot = screenshots[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/screenshots/${screenshot.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.file(
                            File(screenshot.filePath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                screenshot.categoryDisplay,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                screenshot.dateDisplay,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
