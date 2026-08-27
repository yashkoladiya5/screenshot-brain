import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbLiquidSwipe extends StatefulWidget {
  final List<Widget> pages;
  final List<Color> colors;
  final bool enableLoop;

  const SbLiquidSwipe({
    super.key,
    required this.pages,
    required this.colors,
    this.enableLoop = false,
  }) : assert(pages.length == colors.length && pages.length > 0);

  @override
  State<SbLiquidSwipe> createState() => _SbLiquidSwipeState();
}

class _SbLiquidSwipeState extends State<SbLiquidSwipe> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentIndex = 0;
  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, double width) {
    setState(() {
      // We only allow dragging from right to left for the next page, or left to right for prev page
      _dragOffset -= details.delta.dx;
      // Clamp based on whether we can go next or prev
      if (!widget.enableLoop) {
        if (_currentIndex == 0 && _dragOffset < 0) _dragOffset = 0;
        if (_currentIndex == widget.pages.length - 1 && _dragOffset > 0) _dragOffset = 0;
      }
    });
  }

  void _onPanEnd(DragEndDetails details, double width) {
    setState(() {
      _isDragging = false;
    });
    
    // Threshold to switch page
    if (_dragOffset.abs() > width * 0.3 || details.velocity.pixelsPerSecond.dx.abs() > 500) {
      if (_dragOffset > 0) {
        // Go Next
        _goToPage(_currentIndex + 1);
      } else if (_dragOffset < 0) {
        // Go Prev
        _goToPage(_currentIndex - 1);
      }
    } else {
      // Snap back
      _resetDrag();
    }
  }

  void _goToPage(int newIndex) {
    if (widget.enableLoop) {
      if (newIndex < 0) newIndex = widget.pages.length - 1;
      if (newIndex >= widget.pages.length) newIndex = 0;
    } else {
      if (newIndex < 0 || newIndex >= widget.pages.length) {
        _resetDrag();
        return;
      }
    }
    
    // Animate the rest of the way
    final tween = Tween<double>(begin: _dragOffset, end: _dragOffset > 0 ? MediaQuery.of(context).size.width : -MediaQuery.of(context).size.width);
    final animation = tween.animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });
    
    _animationController.forward(from: 0.0).then((_) {
      setState(() {
        _currentIndex = newIndex;
        _dragOffset = 0.0;
      });
    });
  }

  void _resetDrag() {
    final tween = Tween<double>(begin: _dragOffset, end: 0.0);
    final animation = tween.animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
    
    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });
    
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        
        int nextIndex = _currentIndex;
        if (_dragOffset > 0) {
          nextIndex = _currentIndex + 1;
        } else if (_dragOffset < 0) {
          nextIndex = _currentIndex - 1;
        }
        
        if (widget.enableLoop) {
          if (nextIndex >= widget.pages.length) nextIndex = 0;
          if (nextIndex < 0) nextIndex = widget.pages.length - 1;
        } else {
          if (nextIndex >= widget.pages.length) nextIndex = _currentIndex;
          if (nextIndex < 0) nextIndex = _currentIndex;
        }

        final double dragPercent = (_dragOffset.abs() / width).clamp(0.0, 1.0);
        final bool isNext = _dragOffset > 0;

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: (details) => _onPanUpdate(details, width),
          onPanEnd: (details) => _onPanEnd(details, width),
          child: Stack(
            children: [
              // Bottom Page (The page we are revealing)
              Container(
                color: widget.colors[nextIndex],
                child: widget.pages[nextIndex],
              ),
              
              // Top Page (The page we are pulling away)
              // Clipped with the liquid effect
              ClipPath(
                clipper: _LiquidSwipeClipper(
                  dragPercent: dragPercent,
                  isNext: isNext,
                  // We simulate a touch point in the vertical center for the wave origin
                  touchY: height / 2,
                ),
                child: Container(
                  color: widget.colors[_currentIndex],
                  child: widget.pages[_currentIndex],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiquidSwipeClipper extends CustomClipper<Path> {
  final double dragPercent;
  final bool isNext;
  final double touchY;

  _LiquidSwipeClipper({
    required this.dragPercent,
    required this.isNext,
    required this.touchY,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    
    if (dragPercent == 0.0) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    // We draw the shape of the page being PEELED AWAY.
    // If going Next (dragging left), we peel from the Right edge.
    // If going Prev (dragging right), we peel from the Left edge.
    
    final double maxWaveDepth = size.width * 0.8;
    final double currentDepth = dragPercent * maxWaveDepth;
    
    // The vertical spread of the wave increases as we drag further
    final double waveSpread = size.height * 0.3 + (dragPercent * size.height * 0.5);

    if (isNext) {
      // Peeling from the right
      path.lineTo(size.width, 0);
      path.lineTo(size.width, touchY - waveSpread);
      
      // Top curve of the wave
      path.cubicTo(
        size.width, touchY - waveSpread / 2, // cp1
        size.width - currentDepth, touchY - waveSpread / 4, // cp2
        size.width - currentDepth, touchY, // end
      );
      
      // Bottom curve of the wave
      path.cubicTo(
        size.width - currentDepth, touchY + waveSpread / 4, // cp1
        size.width, touchY + waveSpread / 2, // cp2
        size.width, touchY + waveSpread, // end
      );
      
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.lineTo(0, 0);
    } else {
      // Peeling from the left
      path.lineTo(0, touchY - waveSpread);
      
      // Top curve of the wave
      path.cubicTo(
        0, touchY - waveSpread / 2,
        currentDepth, touchY - waveSpread / 4,
        currentDepth, touchY,
      );
      
      // Bottom curve of the wave
      path.cubicTo(
        currentDepth, touchY + waveSpread / 4,
        0, touchY + waveSpread / 2,
        0, touchY + waveSpread,
      );
      
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _LiquidSwipeClipper oldClipper) {
    return oldClipper.dragPercent != dragPercent || 
           oldClipper.isNext != isNext ||
           oldClipper.touchY != touchY;
  }
}
