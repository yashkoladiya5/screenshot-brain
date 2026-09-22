import 'package:flutter/material.dart';
import 'dart:math' as math;

class Sb3DCubeCarousel extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;

  const Sb3DCubeCarousel({
    super.key,
    required this.children,
    this.height = 300.0,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
  });

  @override
  State<Sb3DCubeCarousel> createState() => _Sb3DCubeCarouselState();
}

class _Sb3DCubeCarouselState extends State<Sb3DCubeCarousel> {
  late PageController _pageController;
  double _currentPageValue = 0.0;
  bool _isAutoPlaying = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page ?? 0.0;
      });
    });

    if (widget.autoPlay && widget.children.isNotEmpty) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _isAutoPlaying = true;
    _autoPlayLoop();
  }

  Future<void> _autoPlayLoop() async {
    while (_isAutoPlaying) {
      await Future.delayed(widget.autoPlayInterval);
      if (!mounted || !_isAutoPlaying) break;
      
      final int nextPage = ((_pageController.page ?? 0) + 1).toInt() % widget.children.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _isAutoPlaying = false;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox();

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.children.length,
        itemBuilder: (context, index) {
          // Calculate how far this page is from the exact center
          // 0 = exactly centered, -1 = exactly one page to the left, 1 = exactly one page to the right
          final double distance = (_currentPageValue - index);
          
          // If a page is more than 1 screen away, it's fully hidden and we don't need to do complex math
          if (distance.abs() > 1) {
            return const SizedBox();
          }

          // The rotation angle ranges from -90 degrees (-pi/2) to 90 degrees (pi/2)
          final double rotationAngle = distance * (math.pi / 2);
          
          // Determine the pivot point based on which direction it's rotating
          final FractionalOffset alignment = distance > 0 
              ? FractionalOffset.centerRight 
              : FractionalOffset.centerLeft;

          // As the face rotates away, we darken it to simulate lighting/shadows
          final double fadeValue = 1.0 - distance.abs();
          
          return Transform(
            alignment: alignment,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Perspective distortion
              ..rotateY(rotationAngle), // Rotate on the Y axis to make it a cube face
            child: Stack(
              children: [
                // The actual widget content
                widget.children[index],
                
                // The dynamic lighting shadow overlay
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: (1 - fadeValue) * 0.8),
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
