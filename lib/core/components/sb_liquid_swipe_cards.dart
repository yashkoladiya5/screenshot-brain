import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbLiquidSwipeCards extends StatefulWidget {
  final List<Widget> cards;
  final List<Color> colors;

  const SbLiquidSwipeCards({
    super.key,
    required this.cards,
    required this.colors,
  }) : assert(cards.length == colors.length, 'Number of cards must match number of colors');

  @override
  State<SbLiquidSwipeCards> createState() => _SbLiquidSwipeCardsState();
}

class _SbLiquidSwipeCardsState extends State<SbLiquidSwipeCards> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  
  // Track drag position for the liquid effect
  double _dragValue = 0.0;
  double _touchY = 0.0;
  
  // Animation for when user releases the drag
  late AnimationController _springController;
  late Animation<double> _springAnimation;
  
  bool _isSwipingNext = true;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _springController.addListener(() {
      setState(() {
        _dragValue = _springAnimation.value;
      });
    });
    
    _springController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // If we completed a full swipe (dragValue hit 1.0)
        if (_dragValue == 1.0) {
          setState(() {
            if (_isSwipingNext) {
              _currentIndex = (_currentIndex + 1) % widget.cards.length;
            } else {
              _currentIndex = (_currentIndex - 1 + widget.cards.length) % widget.cards.length;
            }
            // Reset state
            _dragValue = 0.0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_springController.isAnimating) return;
    setState(() {
      _touchY = details.localPosition.dy;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_springController.isAnimating) return;
    
    setState(() {
      _touchY = details.localPosition.dy;
      
      // Calculate how far we've dragged relative to screen width
      final double screenWidth = MediaQuery.of(context).size.width;
      
      // Horizontal drag
      double dragDelta = -details.delta.dx / screenWidth;
      
      if (_dragValue == 0.0 && dragDelta != 0) {
        _isSwipingNext = dragDelta > 0;
      }
      
      // Apply drag if it's in the correct direction
      if (_isSwipingNext && dragDelta > 0) {
        _dragValue += dragDelta;
      } else if (!_isSwipingNext && dragDelta < 0) {
        _dragValue += dragDelta.abs();
      }
      
      _dragValue = _dragValue.clamp(0.0, 1.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_springController.isAnimating) return;
    
    // Determine if we should complete the swipe or snap back
    final double velocity = details.primaryVelocity ?? 0.0;
    
    bool shouldComplete = false;
    
    if (_isSwipingNext) {
      shouldComplete = _dragValue > 0.4 || velocity < -500;
    } else {
      shouldComplete = _dragValue > 0.4 || velocity > 500;
    }

    _springAnimation = Tween<double>(
      begin: _dragValue,
      end: shouldComplete ? 1.0 : 0.0,
    ).animate(
      CurvedAnimation(
        parent: _springController,
        curve: shouldComplete ? Curves.easeOutCubic : Curves.elasticOut,
      )
    );
    
    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();

    // The index of the card we are revealing
    int nextIndex = _isSwipingNext 
        ? (_currentIndex + 1) % widget.cards.length
        : (_currentIndex - 1 + widget.cards.length) % widget.cards.length;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _onPanEnd(DragEndDetails()),
      child: Stack(
        children: [
          // 1. Bottom Card (The one being revealed)
          Container(
            color: widget.colors[nextIndex],
            child: widget.cards[nextIndex],
          ),
          
          // 2. Top Card (The current one being clipped via Liquid Physics)
          ClipPath(
            clipper: _LiquidClipper(
              dragValue: _dragValue,
              touchY: _touchY,
              isSwipingNext: _isSwipingNext,
            ),
            child: Container(
              color: widget.colors[_currentIndex],
              child: widget.cards[_currentIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidClipper extends CustomClipper<Path> {
  final double dragValue; // 0.0 to 1.0
  final double touchY;
  final bool isSwipingNext;

  _LiquidClipper({
    required this.dragValue,
    required this.touchY,
    required this.isSwipingNext,
  });

  @override
  Path getClip(Size size) {
    final Path path = Path();
    
    if (dragValue == 0.0) {
      // Show full top card
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }
    
    if (dragValue == 1.0) {
      // Show nothing (fully clipped)
      return path;
    }

    // Mathematical Liquid Curve Physics
    
    // How far the base flat edge has moved across the screen
    final double baseEdgeX = isSwipingNext 
        ? size.width * (1.0 - (dragValue * 0.8)) // Right to left
        : size.width * (dragValue * 0.8);        // Left to right
        
    // How deep the liquid "bubble" stretches where the finger is
    final double bubbleDepth = size.width * 0.4 * dragValue;
    
    // The exact X coordinate of the tip of the liquid bubble
    final double tipX = isSwipingNext 
        ? baseEdgeX - bubbleDepth 
        : baseEdgeX + bubbleDepth;

    // We draw a bezier curve from the top of the screen, bulging at the touch Y, to the bottom
    
    if (isSwipingNext) {
      // Swiping Next (Right to Left)
      // The area to the LEFT of the curve is kept
      
      path.moveTo(0, 0); // Top left
      path.lineTo(baseEdgeX, 0); // Top right of the visible part
      
      // Control points for the bezier curve
      // The curve starts at baseEdgeX at the top, bulges into tipX at touchY, and returns to baseEdgeX at bottom
      
      // Upper curve
      path.cubicTo(
        baseEdgeX, touchY - 150, // Control point 1 (pulls down from top)
        tipX, touchY - 100,      // Control point 2 (pulls into the bubble)
        tipX, touchY             // End point (tip of the bubble)
      );
      
      // Lower curve
      path.cubicTo(
        tipX, touchY + 100,      // Control point 1 (pulls out of the bubble)
        baseEdgeX, touchY + 150, // Control point 2 (pulls down to bottom)
        baseEdgeX, size.height   // End point (bottom right of visible part)
      );
      
      path.lineTo(0, size.height); // Bottom left
      path.close();
      
    } else {
      // Swiping Previous (Left to Right)
      // The area to the RIGHT of the curve is kept
      
      path.moveTo(size.width, 0); // Top right
      path.lineTo(baseEdgeX, 0);  // Top left of the visible part
      
      // Upper curve
      path.cubicTo(
        baseEdgeX, touchY - 150, 
        tipX, touchY - 100,      
        tipX, touchY             
      );
      
      // Lower curve
      path.cubicTo(
        tipX, touchY + 100,      
        baseEdgeX, touchY + 150, 
        baseEdgeX, size.height   
      );
      
      path.lineTo(size.width, size.height); // Bottom right
      path.close();
    }
    
    return path;
  }

  @override
  bool shouldReclip(covariant _LiquidClipper oldClipper) {
    return oldClipper.dragValue != dragValue || 
           oldClipper.touchY != touchY || 
           oldClipper.isSwipingNext != isSwipingNext;
  }
}
