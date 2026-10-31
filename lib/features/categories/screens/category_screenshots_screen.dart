import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/category_provider.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/theme/app_colors.dart';

class CategoryScreenshotsScreen extends ConsumerWidget {
  final String categoryName;

  /// Longest edge (physical px) a grid thumbnail is decoded at. Three columns
  /// of ~110dp tiles need ~330px on a 3x phone; decoding every capture at
  /// native resolution costs several times that per tile, and the grid builds
  /// a tile per visible row as the user scrolls.
  static const int _thumbDecodeWidth = 384;

  const CategoryScreenshotsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotsAsync = ref.watch(
      screenshotsByCategoryProvider(categoryName),
    );
    final catColor = _categoryColor(categoryName);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: catColor,
                borderRadius: BorderRadius.circular(SBRadius.full),
              ),
            ),
            const SizedBox(width: SBSpacing.sm),
            // AppBar bounds the title as a whole, not this Row's children: an
            // OCR'd category label longer than the screen overflowed the Row
            // and clipped the dot instead of the name.
            Expanded(
              child: Text(
                categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: screenshotsAsync.when(
        loading: () => LoadingWidget(
          message: 'Loading $categoryName screenshots...',
          icon: Icons.photo_library_rounded,
        ),
        error: (error, stack) {
          // Technical detail stays in the logs (repo-wide debugPrint pattern);
          // the user sees a short, actionable sentence instead of a dump.
          debugPrint(
            '[CategoryScreenshots] Could not load $categoryName screenshots: '
            '$error\n$stack',
          );
          return AppErrorWidget(
            title: 'Could not load screenshots',
            message:
                "We couldn't load the screenshots in this category. "
                'Please try again.',
            icon: Icons.photo_library_outlined,
            onRetry: () =>
                ref.invalidate(screenshotsByCategoryProvider(categoryName)),
          );
        },
        data: (screenshots) {
          if (screenshots.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.photo_library_outlined,
              title: 'No $categoryName Screenshots',
              subtitle: 'Screenshots in this category will appear here',
            );
          }
          // Same gap the categories grid had: this list is a FutureProvider
          // that only re-reads on invalidate, and nothing here could trigger
          // one, so a scan finishing in the background stayed invisible.
          return RefreshIndicator(
            onRefresh: () async {
              try {
                final reloaded = ref.refresh(
                  screenshotsByCategoryProvider(categoryName).future,
                );
                await reloaded;
              } catch (error, stack) {
                debugPrint(
                  '[CategoryScreenshots] Pull-to-refresh failed: $error\n$stack',
                );
              }
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(SBSpacing.sm),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: SBSpacing.xs,
                mainAxisSpacing: SBSpacing.xs,
                childAspectRatio: 0.72,
              ),
              itemCount: screenshots.length,
              itemBuilder: (context, index) {
                final screenshot = screenshots[index];
                return GestureDetector(
                  onTap: () => context.push(
                    '/viewer/${screenshot.id}?category=${Uri.encodeComponent(categoryName)}',
                  ),
                  child: Hero(
                    tag: 'screenshot_${screenshot.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(SBRadius.sm),
                      child: Image(
                        // Same bound the screenshot grid uses: the codec decodes
                        // at _thumbDecodeWidth instead of the capture's real
                        // width, so the library can hold thousands of tiles.
                        image: ResizeImage(
                          FileImage(File(screenshot.filePath)),
                          width: _thumbDecodeWidth,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            size: 24,
                          ),
                        ),
                      ),
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

  Color _categoryColor(String category) {
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
}
