import 'package:flutter/material.dart';
import 'dart:math' as math;

class Sb3dPerspectiveCarousel extends StatefulWidget {
  final List<Widget> items;
  final double radius;
  final double itemWidth;
  final double itemHeight;

  const Sb3dPerspectiveCarousel({
    super.key,
    required this.items,
    this.radius = 160.0,
    this.itemWidth = 140.0,
    this.itemHeight = 200.0,
  }) : assert(items.length > 0);

  @override
  State<Sb3dPerspectiveCarousel> createState() => _Sb3dPerspectiveCarouselState();
}

class _Sb3dPerspectiveCarouselState extends State<Sb3dPerspectiveCarousel> with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _springAnimation;
  
  // The absolute rotation angle of the entire carousel (in radians)
  double _currentAngle = 0.0;
  
  // Used for tracking drag gestures
  double _dragStartAngle = 0.0;
  
  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _springController.addListener(() {
      setState(() {
        _currentAngle = _springAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_springController.isAnimating) {
      _springController.stop();
    }
    _dragStartAngle = _currentAngle;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Convert horizontal pixel drag to radian rotation
      // Moving 1 full radius horizontally = 1 radian of rotation
      _currentAngle += details.delta.dx / widget.radius;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // When released, we want to snap to the nearest item perfectly
    
    // The angle difference between each item
    final double anglePerItem = (math.pi * 2) / widget.items.length;
    
    // Add velocity momentum to the angle before snapping
    final double velocity = details.primaryVelocity ?? 0;
    double targetAngle = _currentAngle + (velocity / 1000.0);
    
    // Find the nearest perfectly aligned angle
    // We round to the nearest multiple of anglePerItem
    int nearestIndex = (targetAngle / anglePerItem).round();
    double finalAngle = nearestIndex * anglePerItem;
    
    _springAnimation = Tween<double>(
      begin: _currentAngle,
      end: finalAngle,
    ).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.easeOutCubic, // Smooth snap
      )
    );
    
    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final int itemCount = widget.items.length;
    final double anglePerItem = (math.pi * 2) / itemCount;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _onPanEnd(DragEndDetails()),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SizedBox(
          width: double.infinity,
          height: widget.itemHeight * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(itemCount, (index) {
              // Calculate the mathematical position of this item on the 3D cylinder
              
              // 1. Calculate the item's individual angle relative to the current carousel rotation
              final double itemAngle = (index * anglePerItem) + _currentAngle;
              
              // Normalize angle between -pi and pi so we know if it's in front or behind
              double normalizedAngle = itemAngle % (math.pi * 2);
              if (normalizedAngle > math.pi) normalizedAngle -= math.pi * 2;
              if (normalizedAngle < -math.pi) normalizedAngle += math.pi * 2;
              
              // 2. 3D Math: Z-index depth calculation
              // -1.0 means it's at the very back, 1.0 means it's at the very front
              final double depth = math.cos(normalizedAngle);
              
              // 3. If it's completely in the back (depth < -0.5) we could hide it for performance,
              // but we'll render it with scaling to simulate true 3D
              
              // 4. Calculate X position on the screen based on sine (horizontal spread)
              final double xOffset = math.sin(normalizedAngle) * widget.radius;
              
              // 5. Calculate scale (items in the back are smaller)
              // depth is [-1, 1]. We map it to [0.5, 1.0] for scale.
              final double scale = 0.75 + (depth * 0.25);
              
              // 6. Calculate opacity (fade out items in the far back)
              // If depth is less than 0 (in back half), start fading
              final double opacity = depth > -0.2 ? 1.0 : (1.0 + (depth + 0.2)).clamp(0.0, 1.0);

              // 7. Calculate Y offset for a slight "tilt" effect (closer items dip slightly)
              final double yOffset = (1.0 - depth) * 20.0;

              // We apply a Z-index approximation. Flutter Stack renders back-to-front.
              // To get perfect z-sorting, we would sort the children list by depth.
              // We'll wrap this in a Positioned but we must sort them!
              
              return _CarouselItemData(
                widget: widget.items[index],
                depth: depth,
                xOffset: xOffset,
                yOffset: yOffset,
                scale: scale,
                opacity: opacity,
                angle: normalizedAngle,
              );
            })
            // Sort by depth so the front items render on top of back items!
            ..sort((a, b) => a.depth.compareTo(b.depth))
            // Map to actual widgets
            ..map((data) {
              return Transform.translate(
                offset: Offset(data.xOffset, data.yOffset),
                child: Transform.scale(
                  scale: data.scale,
                  child: Opacity(
                    opacity: data.opacity,
                    child: Container(
                      width: widget.itemWidth,
                      height: widget.itemHeight,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2 * data.depth.clamp(0.0, 1.0)),
                            blurRadius: 20 * data.scale,
                            offset: Offset(0, 10 * data.scale),
                          )
                        ]
                      ),
                      child: data.widget,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// Helper class to store calculations so we can sort them before rendering
class _CarouselItemData {
  final Widget widget;
  final double depth;
  final double xOffset;
  final double yOffset;
  final double scale;
  final double opacity;
  final double angle;

  _CarouselItemData({
    required this.widget,
    required this.depth,
    required this.xOffset,
    required this.yOffset,
    required this.scale,
    required this.opacity,
    required this.angle,
  });
}
