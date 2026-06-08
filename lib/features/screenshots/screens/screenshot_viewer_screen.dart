import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/loading_widget.dart';
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
      loading: () => const Center(child: LoadingWidget()),
      error: (error, _) => _buildError(context, error.toString()),
      data: (screenshots) {
        if (screenshots.isEmpty) {
          return _buildError(context, 'No screenshots found');
        }
        final currentId = int.tryParse(screenshotId) ?? 0;
        final initialIndex = screenshots.indexWhere((s) => s.id == currentId);
        final startIndex = initialIndex >= 0 ? initialIndex : 0;
        debugPrint('[Viewer] Gallery: ${screenshots.length} screenshots, initialIndex=$startIndex');
        return _PageViewer(
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
      loading: () => const Center(child: LoadingWidget()),
      error: (error, _) => _buildError(context, error.toString()),
      data: (screenshot) {
        if (screenshot == null) {
          return _buildError(context, 'Screenshot not found');
        }
        return _SingleViewer(filePath: screenshot.filePath, onClose: () => context.pop());
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _PageViewer extends StatefulWidget {
  final List<ScreenshotModel> screenshots;
  final int initialIndex;

  const _PageViewer({required this.screenshots, required this.initialIndex});

  @override
  State<_PageViewer> createState() => _PageViewerState();
}

class _PageViewerState extends State<_PageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    debugPrint('[PageViewer] initState: initialIndex=$_currentIndex total=${widget.screenshots.length}');
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
          onPageChanged: (index) {
            debugPrint('[PageViewer] onPageChanged: $index');
            setState(() => _currentIndex = index);
          },
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
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: Text(
            '${_currentIndex + 1} / ${widget.screenshots.length}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _SingleViewer extends StatelessWidget {
  final String filePath;
  final VoidCallback onClose;

  const _SingleViewer({required this.filePath, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Center(child: _ZoomableImage(filePath: '', heroTag: 'single')),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
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
              ..translate(_offset.dx, _offset.dy)
              ..scale(_scale),
            alignment: Alignment.center,
            child: Image.file(
              File(widget.filePath),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image,
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
