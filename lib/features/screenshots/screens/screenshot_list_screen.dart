import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../categories/providers/category_provider.dart';
import '../models/screenshot_item.dart';
import '../providers/screenshot_provider.dart';
import '../../../core/design/tokens.dart';
import '../../../core/components/sb_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';

/// Browse, filter and scan the screenshot library.
///
/// Async states render through the shared widget family (LoadingWidget /
/// AppErrorWidget with a wired retry / EmptyStateWidget), and the category
/// filter chips are fed from [categoryCountsProvider], whose counts come
/// from the repository's screenshot table.
class ScreenshotListScreen extends ConsumerStatefulWidget {
  const ScreenshotListScreen({super.key});

  @override
  ConsumerState<ScreenshotListScreen> createState() =>
      _ScreenshotListScreenState();
}

class _ScreenshotListScreenState extends ConsumerState<ScreenshotListScreen> {
  static const String _allLabel = 'All';

  /// Longest edge (physical px) a tile is decoded at. Screenshots are
  /// full-resolution bitmaps; decoding them at native size for a ~160px tile
  /// multiplies memory by 5-10x per row and storms the rasterizer once the
  /// library grows past a few hundred items. ResizeImage bounds the decode.
  static const int _tileDecodeWidth = 512;

  /// Selected chip label, or null when unfiltered.
  String? _selectedCategory;

  void _selectCategory(String? category) {
    setState(() => _selectedCategory = category);
  }

  @override
  Widget build(BuildContext context) {
    final screenshotsAsync = ref.watch(screenshotListProvider);
    final isScanning = ref.watch(scanningProvider);
    final categoryCounts = ref.watch(categoryCountsProvider);

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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.document_scanner_rounded, size: SBSizes.iconMd),
        label: Text(isScanning ? 'Scanning...' : 'Scan'),
      ),
      body: screenshotsAsync.when(
        loading: () => const LoadingWidget(message: 'Loading screenshots...'),
        // Previously this branch swallowed the failure behind a plain
        // message; now it surfaces through the shared error widget with a
        // retry that invalidates and re-runs the query.
        error: (error, stack) {
          // Technical detail stays in the logs (repo-wide debugPrint pattern);
          // the user sees a short, actionable sentence instead of a dump.
          debugPrint(
            '[ScreenshotList] Could not load screenshots: $error\n$stack',
          );
          return AppErrorWidget(
            title: 'Could not load screenshots',
            message: "We couldn't load your screenshots. Please try again.",
            retryLabel: 'Try again',
            onRetry: () => ref.invalidate(screenshotListProvider),
          );
        },
        data: (screenshots) {
          // The chip badges come from categoryCountsProvider, which buckets
          // uncategorized rows (category == null) into `Other`. Filtering on
          // categoryDisplay ('Uncategorized') instead made the 'Other' badge
          // promise rows its grid then dropped, so both sides use the same
          // effectiveCategoryOf bucketing.
          final filtered = _selectedCategory == null
              ? screenshots
              : screenshots
                    .where(
                      (s) =>
                          effectiveCategoryOf(s.category) == _selectedCategory,
                    )
                    .toList();

          return Column(
            children: [
              _CategoryFilterBar(
                categoryCounts: categoryCounts,
                selectedCategory: _selectedCategory,
                totalLabel: _allLabel,
                onSelected: _selectCategory,
              ),
              Expanded(child: _buildBody(context, screenshots, filtered)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<ScreenshotItem> all,
    List<ScreenshotItem> filtered,
  ) {
    if (filtered.isEmpty) {
      final selected = _selectedCategory;
      if (selected != null && all.isNotEmpty) {
        return EmptyStateWidget(
          icon: Icons.filter_alt_off_outlined,
          title: 'No $selected screenshots',
          subtitle: 'No screenshots in this category yet.',
          actionLabel: 'Clear filter',
          onAction: () => _selectCategory(null),
        );
      }
      return EmptyStateWidget(
        icon: Icons.photo_library_outlined,
        title: 'No Screenshots Yet',
        subtitle: 'Tap Scan to find and organize your screenshots',
        actionLabel: 'Scan Now',
        onAction: () => ref.read(scanScreenshotsProvider.notifier).scan(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(screenshotListProvider);
        ref.invalidate(categoryCountsProvider);
        // Await only to keep the material spinner until the reload settles;
        // a failure must NOT escape this callback — RefreshIndicator would
        // leave its spinner hanging on an unhandled error. The reload's
        // AsyncError state is what renders the failure, via the when() below.
        try {
          await ref.read(screenshotListProvider.future);
        } catch (_) {}
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(SBSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: SBSpacing.md,
          mainAxisSpacing: SBSpacing.md,
          childAspectRatio: 0.72,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final screenshot = filtered[index];
          final catColor = _categoryColor(screenshot.categoryDisplay);
          return SbCard(
            padding: EdgeInsets.zero,
            onTap: () => context.push('/screenshots/${screenshot.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(SBRadius.xl),
                    ),
                    child: Image(
                      // ResizeImage bounds the actual decode (targetWidth in
                      // the codec), so a row costs thumbnail-scale memory
                      // even when the screenshot file is full resolution.
                      image: ResizeImage(
                        FileImage(File(screenshot.filePath)),
                        width: _tileDecodeWidth,
                      ),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
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
                              borderRadius: BorderRadius.circular(
                                SBRadius.full,
                              ),
                            ),
                          ),
                          const SizedBox(width: SBSpacing.xs),
                          Expanded(
                            child: Text(
                              screenshot.categoryDisplay,
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(color: catColor),
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
  }
}

/// Horizontal chip bar fed by repository category counts. Rendered only when
/// counts are available; a failed counts query degrades to no filter bar
/// rather than hiding the whole library behind an error.
class _CategoryFilterBar extends StatelessWidget {
  final AsyncValue<Map<String, int>> categoryCounts;
  final String? selectedCategory;
  final String totalLabel;
  final ValueChanged<String?> onSelected;

  const _CategoryFilterBar({
    required this.categoryCounts,
    required this.selectedCategory,
    required this.totalLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final counts = categoryCounts.valueOrNull;
    if (counts == null || counts.isEmpty) return const SizedBox.shrink();

    final labels = counts.keys.toList()..sort();
    return SizedBox(
      key: const Key('categoryFilterChips'),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg),
        itemCount: labels.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: SBSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return FilterChip(
              label: Text(totalLabel),
              selected: selectedCategory == null,
              onSelected: (_) => onSelected(null),
            );
          }
          final label = labels[index - 1];
          final count = counts[label] ?? 0;
          return FilterChip(
            label: Text('$label ($count)'),
            selected: selectedCategory == label,
            onSelected: (picked) => onSelected(picked ? label : null),
          );
        },
      ),
    );
  }
}

Color _categoryColor(String? category) {
  switch (category) {
    case 'Payments':
      return AppColors.categoryPayments;
    case 'UPI Receipts':
      return AppColors.categoryUpi;
    case 'Shopping':
      return AppColors.categoryShopping;
    case 'Travel Tickets':
      return AppColors.categoryTravel;
    case 'Bills':
      return AppColors.categoryBills;
    case 'Documents':
      return AppColors.categoryDocuments;
    case 'OTP Screenshots':
      return AppColors.categoryOtp;
    case 'Addresses':
      return AppColors.categoryAddress;
    case 'Notes':
      return AppColors.categoryNotes;
    case 'Social Media':
      return AppColors.categorySocial;
    default:
      return AppColors.categoryOther;
  }
}
