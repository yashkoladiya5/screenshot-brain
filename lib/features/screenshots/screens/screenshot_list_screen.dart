import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/screenshot_provider.dart';
import '../../../core/design/tokens.dart';
import '../../../core/components/sb_loading.dart';
import '../../../core/components/sb_card.dart';
import '../../../core/components/sb_empty_state.dart';
import '../../../core/theme/app_colors.dart';

class ScreenshotListScreen extends ConsumerWidget {
  const ScreenshotListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotsAsync = ref.watch(screenshotListProvider);
    final isScanning = ref.watch(scanningProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isScanning
            ? null
            : () => ref.read(scanScreenshotsProvider.notifier).scan(),
        icon: isScanning
            ? SizedBox(
                width: SBSizes.iconMd,
                height: SBSizes.iconMd,
                child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
              )
            : const Icon(Icons.document_scanner_rounded, size: SBSizes.iconMd),
        label: Text(isScanning ? 'Scanning...' : 'Scan'),
      ),
      body: screenshotsAsync.when(
        loading: () => const SbLoading(message: 'Loading screenshots...'),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(SBSpacing.xl),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(SBRadius.xxl),
                ),
                child: Icon(Icons.error_outline_rounded, size: 40, color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: SBSpacing.lg),
              Text('Error: $error', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: SBSpacing.lg),
              FilledButton(
                onPressed: () => ref.invalidate(screenshotListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (screenshots) {
          if (screenshots.isEmpty) {
            return SbEmptyState(
              icon: Icons.photo_library_outlined,
              title: 'No Screenshots Yet',
              subtitle: 'Tap Scan to find and organize your screenshots',
              actionLabel: 'Scan Now',
              onAction: () => ref.read(scanScreenshotsProvider.notifier).scan(),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(screenshotListProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(SBSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: SBSpacing.md,
                mainAxisSpacing: SBSpacing.md,
                childAspectRatio: 0.72,
              ),
              itemCount: screenshots.length,
              itemBuilder: (context, index) {
                final screenshot = screenshots[index];
                final catColor = _categoryColor(screenshot.category);
                return SbCard(
                  padding: EdgeInsets.zero,
                  onTap: () => context.push('/screenshots/${screenshot.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(SBRadius.xl)),
                          child: Image.file(
                            File(screenshot.filePath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image_rounded, size: 48),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(SBSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: catColor,
                                    borderRadius: BorderRadius.circular(SBRadius.full),
                                  ),
                                ),
                                const SizedBox(width: SBSpacing.xs),
                                Expanded(
                                  child: Text(
                                    screenshot.categoryDisplay,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: catColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: SBSpacing.xxs),
                            Text(
                              screenshot.dateDisplay,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Payments': return AppColors.categoryPayments;
      case 'UPI Receipts': return AppColors.categoryUpi;
      case 'Shopping': return AppColors.categoryShopping;
      case 'Travel Tickets': return AppColors.categoryTravel;
      case 'Bills': return AppColors.categoryBills;
      case 'Documents': return AppColors.categoryDocuments;
      case 'OTP Screenshots': return AppColors.categoryOtp;
      case 'Addresses': return AppColors.categoryAddress;
      case 'Notes': return AppColors.categoryNotes;
      case 'Social Media': return AppColors.categorySocial;
      default: return AppColors.categoryOther;
    }
  }
}
