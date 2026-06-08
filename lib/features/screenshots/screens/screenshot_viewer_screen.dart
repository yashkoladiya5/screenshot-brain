import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/components/sb_loading.dart';
import '../../../shared/models/screenshot_model.dart';
import '../../categories/providers/category_provider.dart';
import '../models/screenshot_item.dart';
import '../providers/screenshot_provider.dart';

class ScreenshotViewerScreen extends ConsumerWidget {
  final String screenshotId;
  final String? categoryName;

  const ScreenshotViewerScreen({
    super.key,
    required this.screenshotId,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showGallery = categoryName != null;
    final galleryAsync = showGallery
        ? ref.watch(screenshotsByCategoryProvider(categoryName!))
        : null;
    final singleAsync = !showGallery
        ? ref.watch(screenshotDetailProvider(int.tryParse(screenshotId) ?? 0))
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: showGallery
          ? _buildGallery(context, galleryAsync!)
          : _buildSingle(context, singleAsync!),
    );
  }

  Widget _buildGallery(
    BuildContext context,
    AsyncValue<List<ScreenshotModel>> galleryAsync,
  ) {
    return galleryAsync.when(
      loading: () => const Center(child: SbLoading()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
            const SizedBox(height: SBSpacing.lg),
            Text(error.toString(), style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: SBSpacing.lg),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      data: (screenshots) {
        if (screenshots.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
                const SizedBox(height: SBSpacing.lg),
                const Text('No screenshots found', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: SBSpacing.lg),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
        final currentId = int.tryParse(screenshotId) ?? 0;
        final initialIndex = screenshots.indexWhere((s) => s.id == currentId);
        final startIndex = initialIndex >= 0 ? initialIndex : 0;
        return _GalleryPager(
          screenshots: screenshots,
          initialIndex: startIndex,
        );
      },
    );
  }

  Widget _buildSingle(
    BuildContext context,
    AsyncValue<ScreenshotItem?> singleAsync,
  ) {
    return singleAsync.when(
      loading: () => const Center(child: SbLoading()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
            const SizedBox(height: SBSpacing.lg),
            Text(error.toString(), style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: SBSpacing.lg),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      data: (screenshot) {
        if (screenshot == null) {
          return const Center(child: Text('Screenshot not found', style: TextStyle(color: Colors.white70)));
        }
        return _ImageViewer(
          filePath: screenshot.filePath,
          heroTag: 'screenshot_${screenshot.id}',
          onClose: () => context.pop(),
        );
      },
    );
  }
}

class _GalleryPager extends StatefulWidget {
  final List<ScreenshotModel> screenshots;
  final int initialIndex;

  const _GalleryPager({required this.screenshots, required this.initialIndex});

  @override
  State<_GalleryPager> createState() => _GalleryPagerState();
}

class _GalleryPagerState extends State<_GalleryPager> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.screenshots.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            final screenshot = widget.screenshots[index];
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
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.xs),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(SBRadius.lg),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.screenshots.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final String filePath;
  final String heroTag;
  final VoidCallback onClose;

  const _ImageViewer({required this.filePath, required this.heroTag, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: _ZoomableImage(filePath: filePath, heroTag: heroTag),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 12,
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            onPressed: onClose,
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
              errorBuilder: (_, __, ___) => const Icon(
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
