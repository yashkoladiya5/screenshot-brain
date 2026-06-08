import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/category_provider.dart';
import '../../../core/design/tokens.dart';
import '../../../core/components/sb_loading.dart';
import '../../../core/components/sb_empty_state.dart';
import '../../../core/theme/app_colors.dart';

class CategoryScreenshotsScreen extends ConsumerWidget {
  final String categoryName;
  const CategoryScreenshotsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotsAsync = ref.watch(screenshotsByCategoryProvider(categoryName));
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
            Text(categoryName),
          ],
        ),
      ),
      body: screenshotsAsync.when(
        loading: () => const SbLoading(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (screenshots) {
          if (screenshots.isEmpty) {
            return SbEmptyState(
              icon: Icons.photo_library_outlined,
              title: 'No $categoryName Screenshots',
              subtitle: 'Screenshots in this category will appear here',
            );
          }
          return GridView.builder(
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
                    child: Image.file(
                      File(screenshot.filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_rounded, size: 24),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _categoryColor(String category) {
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
