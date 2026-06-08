import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/category_provider.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

class CategoryScreenshotsScreen extends ConsumerWidget {
  final String categoryName;
  const CategoryScreenshotsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotsAsync = ref.watch(screenshotsByCategoryProvider(categoryName));

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: screenshotsAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (screenshots) {
          if (screenshots.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.photo_library_outlined,
              title: 'No $categoryName Screenshots',
              subtitle: 'Screenshots in this category will appear here',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 0.75,
            ),
            itemCount: screenshots.length,
            itemBuilder: (context, index) {
              final screenshot = screenshots[index];
              return GestureDetector(
                onTap: () => context.push('/viewer/${screenshot.id}?category=${Uri.encodeComponent(categoryName)}'),
                child: Hero(
                  tag: 'screenshot_${screenshot.id}',
                  child: Image.file(
                    File(screenshot.filePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image, size: 32),
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
}
