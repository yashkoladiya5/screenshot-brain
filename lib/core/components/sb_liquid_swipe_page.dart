import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbLiquidSwipePage extends StatefulWidget {
  final Widget child;
  final Widget nextChild;
  final Color liquidColor;

  const SbLiquidSwipePage({
    super.key,
    required this.child,
    required this.nextChild,
    this.liquidColor = const Color(0xFF6200EE),
  });

  @override
  State<SbLiquidSwipePage> createState() => _SbLiquidSwipePageState();
}

class _SbLiquidSwipePageState extends State<SbLiquidSwipePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  double _screenWidth = 0.0;
  double _screenHeight = 0.0;
  double _dragY = 0.0; // Where the user is pulling from on the Y axis

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_controller.isAnimating) _controller.stop();
    setState(() {
      _isDragging = true;
      _dragY = details.localPosition.dy;
      // We start the drag from the right edge
      _dragOffset = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Delta dx is negative when swiping right-to-left
      _dragOffset -= details.delta.dx;
      // Clamp to screen width so they can't drag past
      _dragOffset = _dragOffset.clamp(0.0, _screenWidth);
      _dragY = details.localPosition.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    final double velocity = details.primaryVelocity ?? 0.0;
    final double normalizedOffset = _dragOffset / _screenWidth;

    // If dragged past 40% or swiped fast left
    if (normalizedOffset > 0.4 || velocity < -500) {
      _animateTo(_screenWidth);
    } else {
      // Snap back to right edge
      _animateTo(0.0);
    }
  }

  void _animateTo(double targetOffset) {
    final animation = Tween<double>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });

    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;

    // We only need to show the liquid effect if we're dragging or animating
    final bool showLiquid = _dragOffset > 0;

    return Stack(
      children: [
        // 1. The base page
        widget.child,
        
        // 2. The liquid clip path containing the next page
        if (showLiquid)
          ClipPath(
            clipper: _LiquidSwipeClipper(
              dragOffset: _dragOffset,
              dragY: _dragY,
              screenWidth: _screenWidth,
              screenHeight: _screenHeight,
            ),
            child: Container(
              color: widget.liquidColor, // The liquid color border
              child: Stack(
                children: [
                  // Next page content slightly inset so the liquid color shows as a border
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: widget.nextChild,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        // 3. Invisible gesture detector to capture the swipe from the right edge
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 30, // 30px edge area to start swipe
          child: GestureDetector(
            onHorizontalDragStart: _onPanStart,
            onHorizontalDragUpdate: _onPanUpdate,
            onHorizontalDragEnd: _onPanEnd,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}

class _LiquidSwipeClipper extends CustomClipper<Path> {
  final double dragOffset;
  final double dragY;
  final double screenWidth;
  final double screenHeight;

  _LiquidSwipeClipper({
    required this.dragOffset,
    required this.dragY,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // If no drag, nothing is clipped (meaning the next page is hidden)
    if (dragOffset <= 0) {
      return path; // Empty path
    }
    
    // If fully dragged, show everything
    if (dragOffset >= screenWidth) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    // The liquid droplet curve
    // We start from the top right
    path.moveTo(size.width, 0);
    
    // Line down to where the curve starts (above drag point)
    final double curveRadius = screenHeight * 0.3; // How wide the liquid droplet is
    final double startY = (dragY - curveRadius).clamp(0.0, size.height);
    path.lineTo(size.width, startY);
    
    // The curve pointing leftwards
    // We use a cubic bezier to make a nice droplet shape
    final double peakX = size.width - dragOffset; // How far we dragged left
    final double endY = (dragY + curveRadius).clamp(0.0, size.height);
    
    // Control points for organic droplet shape
    path.cubicTo(
      size.width - (dragOffset * 0.3), startY + (curveRadius * 0.2), // CP1
      peakX, dragY - (curveRadius * 0.2), // CP2
      peakX, dragY, // End point (peak)
    );
    
    path.cubicTo(
      peakX, dragY + (curveRadius * 0.2), // CP1
      size.width - (dragOffset * 0.3), endY - (curveRadius * 0.2), // CP2
      size.width, endY, // End point (bottom of droplet)
    );
    
    // Finish path to bottom right
    path.lineTo(size.width, size.height);
    
    // We need to enclose the area to the right of the path
    path.lineTo(size.width * 2, size.height);
    path.lineTo(size.width * 2, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _LiquidSwipeClipper oldClipper) {
    return oldClipper.dragOffset != dragOffset || oldClipper.dragY != dragY;
  }
}
