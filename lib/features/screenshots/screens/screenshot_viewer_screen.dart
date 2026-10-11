import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../shared/models/screenshot_model.dart';
import '../../categories/providers/category_provider.dart';
import '../models/screenshot_item.dart';
import '../providers/screenshot_provider.dart';

/// Fullscreen screenshot viewer with zoom, Hero transitions, a swipeable
/// category gallery, and share/delete overlay actions wired through the
/// existing screenshot providers.
class ScreenshotViewerScreen extends ConsumerWidget {
  final String screenshotId;
  final String? categoryName;

  const ScreenshotViewerScreen({
    super.key,
    required this.screenshotId,
    this.categoryName,
  });

  int get _parsedId => int.tryParse(screenshotId) ?? 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showGallery = categoryName != null;
    final galleryAsync = showGallery
        ? ref.watch(screenshotsByCategoryProvider(categoryName!))
        : null;
    final singleAsync = !showGallery
        ? ref.watch(screenshotDetailProvider(_parsedId))
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: showGallery
          ? _buildGallery(context, ref, galleryAsync!)
          : _buildSingle(context, ref, singleAsync!),
    );
  }

  /// Shared error surface tuned for the dark viewer: retry re-runs the
  /// watched query; close leaves the viewer.
  Widget _errorView(
    BuildContext context,
    WidgetRef ref, {
    required Object error,
    required VoidCallback retry,
  }) {
    return Column(
      children: [
        const _ViewerCloseButton(),
        Expanded(
          child: AppErrorWidget(
            title: 'Could not load this screenshot',
            message: error.toString(),
            icon: Icons.broken_image_rounded,
            onRetry: retry,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: SBSpacing.xxl),
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ),
      ],
    );
  }

  Widget _buildGallery(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ScreenshotModel>> galleryAsync,
  ) {
    return galleryAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => _errorView(
        context,
        ref,
        error: error,
        retry: () =>
            ref.invalidate(screenshotsByCategoryProvider(categoryName!)),
      ),
      data: (screenshots) {
        if (screenshots.isEmpty) {
          return Column(
            children: [
              const _ViewerCloseButton(),
              const Expanded(
                child: EmptyStateWidget(
                  icon: Icons.broken_image_rounded,
                  title: 'No screenshots found',
                  semanticsLabel: 'No screenshots in this category',
                ),
              ),
            ],
          );
        }
        final initialIndex = screenshots.indexWhere((s) => s.id == _parsedId);
        return _GalleryPager(
          screenshots: screenshots,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        );
      },
    );
  }

  Widget _buildSingle(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<ScreenshotItem?> singleAsync,
  ) {
    return singleAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => _errorView(
        context,
        ref,
        error: error,
        retry: () => ref.invalidate(screenshotDetailProvider(_parsedId)),
      ),
      data: (screenshot) {
        if (screenshot == null) {
          return const Column(
            children: [
              _ViewerCloseButton(),
              Expanded(
                child: EmptyStateWidget(
                  icon: Icons.image_not_supported_outlined,
                  title: 'Screenshot not found',
                ),
              ),
            ],
          );
        }
        return _ImageViewer(screenshot: screenshot);
      },
    );
  }
}

class _ViewerCloseButton extends StatelessWidget {
  const _ViewerCloseButton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          tooltip: 'Close',
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}

/// Overlay action row (share / delete) shared by the single and gallery
/// viewer modes; both call the same provider-backed mutations.
class _ViewerActions extends ConsumerWidget {
  final ScreenshotItem item;
  final VoidCallback? onDeleted;

  const _ViewerActions({required this.item, this.onDeleted});

  Future<void> _share(WidgetRef ref) =>
      Share.shareXFiles([XFile(item.filePath)], text: item.extractedText ?? '');

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Screenshot'),
        content: const Text('Are you sure you want to delete this screenshot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirmDelete'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      // Provider performs the DB delete and invalidates list/home itself.
      await ref.read(deleteScreenshotProvider(item.id).future);
      onDeleted?.call();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white, size: 26),
          tooltip: 'Share',
          onPressed: () => _share(ref),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 26,
          ),
          tooltip: 'Delete',
          onPressed: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }
}

/// Adapts a [ScreenshotModel] row to the item shape the overlay actions use.
ScreenshotItem _itemFromModel(ScreenshotModel model) => ScreenshotItem(
  id: model.id,
  filePath: model.filePath,
  thumbnailPath: model.thumbnailPath,
  extractedText: model.extractedText,
  category: model.category,
  createdAt: model.createdAt,
  fileSize: model.fileSize,
  isProcessed: model.isProcessed,
  isExpense: model.isExpense,
);

class _GalleryPager extends ConsumerStatefulWidget {
  final List<ScreenshotModel> screenshots;
  final int initialIndex;

  const _GalleryPager({required this.screenshots, required this.initialIndex});

  @override
  ConsumerState<_GalleryPager> createState() => _GalleryPagerState();
}

class _GalleryPagerState extends ConsumerState<_GalleryPager> {
  late PageController _pageController;
  late int _currentIndex;
  late List<ScreenshotModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.screenshots);
    _currentIndex = widget.initialIndex.clamp(0, _items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCurrentDeleted(int deletedId) {
    final index = _items.indexWhere((s) => s.id == deletedId);
    if (index < 0) return;
    setState(() {
      _items.removeAt(index);
      if (_items.isEmpty) {
        context.pop();
        return;
      }
      _currentIndex = index.clamp(0, _items.length - 1);
    });
    if (_items.isNotEmpty) {
      _pageController.jumpToPage(_currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _items[_currentIndex];
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _items.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            final screenshot = _items[index];
            return _ZoomableImage(
              filePath: screenshot.filePath,
              heroTag: index == widget.initialIndex
                  ? 'screenshot_${screenshot.id}'
                  : 'viewer_${screenshot.id}',
            );
          },
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Close',
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SBSpacing.md,
                        vertical: SBSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(SBRadius.lg),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${_items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                _ViewerActions(
                  item: _itemFromModel(current),
                  onDeleted: () => _onCurrentDeleted(current.id),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageViewer extends ConsumerWidget {
  final ScreenshotItem screenshot;

  const _ImageViewer({required this.screenshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: _ZoomableImage(
            filePath: screenshot.filePath,
            heroTag: 'screenshot_${screenshot.id}',
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: 'Close',
                onPressed: () => context.pop(),
              ),
              const Spacer(),
              _ViewerActions(item: screenshot, onDeleted: () => context.pop()),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final String filePath;
  final String heroTag;

  const _ZoomableImage({required this.filePath, required this.heroTag});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;

  void _onScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
    _previousOffset = _offset;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale).clamp(1.0, 4.0);
      _offset = _previousOffset + details.focalPointDelta;
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_scale <= 1.0) {
      setState(() {
        _scale = 1.0;
        _offset = Offset.zero;
      });
    }
  }

  void _onDoubleTap() {
    setState(() {
      if (_scale > 1.0) {
        _scale = 1.0;
        _offset = Offset.zero;
      } else {
        _scale = 2.5;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      onDoubleTap: _onDoubleTap,
      child: Center(
        child: Hero(
          tag: widget.heroTag,
          child: Transform(
            transform: Matrix4.identity()
              ..translateByDouble(_offset.dx, _offset.dy, 0.0, 1.0)
              ..scaleByDouble(_scale, _scale, 1.0, 1.0),
            alignment: Alignment.center,
            child: Image.file(
              File(widget.filePath),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_rounded,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
