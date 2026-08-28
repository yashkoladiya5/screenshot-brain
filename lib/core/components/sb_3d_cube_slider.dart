import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class Sb3DCubeSlider extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final Color backgroundColor;

  const Sb3DCubeSlider({
    super.key,
    required this.children,
    this.height = 200.0,
    this.backgroundColor = Colors.black,
  }) : assert(children.length > 1);

  @override
  State<Sb3DCubeSlider> createState() => _Sb3DCubeSliderState();
}

class _Sb3DCubeSliderState extends State<Sb3DCubeSlider> {
  late PageController _pageController;
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController()
      ..addListener(() {
        setState(() {
          _currentPageValue = _pageController.page ?? 0.0;
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
    return Container(
      height: widget.height,
      color: widget.backgroundColor,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.children.length,
        itemBuilder: (context, index) {
          // Calculate how far this page is from the center
          // 0 = center, -1 = left, 1 = right
          final double value = index - _currentPageValue;
          
          // If a page is completely out of view, don't waste math on it
          if (value <= -1.0 || value >= 1.0) {
            return const SizedBox.shrink();
          }

          // We want the cube faces to rotate up to 90 degrees (pi/2 radians)
          final double rotationY = value * (math.pi / 2);
          
          // When rotating away, we push it back in Z space to complete the cube illusion
          final double z = (value.abs() * widget.height / 2);
          
          // And we adjust X position so the edges stay perfectly aligned
          final double x = value * (widget.height / 2);

          // Darken the page as it turns away from the user
          final double opacity = (1 - value.abs().clamp(0.0, 1.0));

          return Transform(
            alignment: value < 0 ? Alignment.centerRight : Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..translate(x, 0.0, -z) // Move back and shift
              ..rotateY(rotationY), // Rotate
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.children[index],
                // Add a dynamic shadow overlay that gets darker as it rotates away
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: (1.0 - opacity) * 0.8),
                    ),
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
