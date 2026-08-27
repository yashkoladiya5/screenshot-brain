import 'package:flutter/material.dart';
import 'dart:math' as math;

class Sb3DCarousel extends StatefulWidget {
  final List<Widget> items;
  final double height;
  final double itemWidth;
  final double perspective;

  const Sb3DCarousel({
    super.key,
    required this.items,
    this.height = 300.0,
    this.itemWidth = 200.0,
    this.perspective = 0.002,
  }) : assert(items.length > 0);

  @override
  State<Sb3DCarousel> createState() => _Sb3DCarouselState();
}

class _Sb3DCarouselState extends State<Sb3DCarousel> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    // Use a viewport fraction to show adjacent items
    _pageController = PageController(viewportFraction: 0.6);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          // Calculate distance from center (0 = center, -1 = left, 1 = right)
          final double diff = (index - _currentPage);
          final double absDiff = diff.abs();
          
          // Interpolate values for the 3D effect
          // Scale down items that are further away
          final double scale = (1 - (absDiff * 0.3)).clamp(0.5, 1.0);
          // Rotate items on the Y axis
          final double rotateY = -diff * math.pi / 4;
          // Shift items slightly back in Z space
          final double translateZ = -absDiff * 100;
          // Fade out items that are further away
          final double opacity = (1 - (absDiff * 0.5)).clamp(0.0, 1.0);

          final matrix = Matrix4.identity()
            ..setEntry(3, 2, widget.perspective) // Apply perspective
            ..translate(0.0, 0.0, translateZ) // Push back
            ..rotateY(rotateY) // Rotate towards center
            ..scale(scale); // Scale down

          return Transform(
            transform: matrix,
            alignment: Alignment.center,
            child: Opacity(
              opacity: opacity,
              child: Center(
                child: SizedBox(
                  width: widget.itemWidth,
                  // Let height be determined by parent constraints or child
                  child: widget.items[index],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
