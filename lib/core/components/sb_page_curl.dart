import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbPageCurl extends StatefulWidget {
  final Widget frontPage;
  final Widget backPage;
  final Widget underlyingPage;
  
  const SbPageCurl({
    super.key,
    required this.frontPage,
    required this.backPage,
    required this.underlyingPage,
  });

  @override
  State<SbPageCurl> createState() => _SbPageCurlState();
}

class _SbPageCurlState extends State<SbPageCurl> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      // Start drag offset near the bottom right corner usually
      _dragOffset = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;

    // Decide whether to turn the page completely or snap back
    // If dragged past halfway, complete the turn
    if (_dragOffset.dx < size.width / 2) {
      // Animate to full open (left edge)
      final anim = Tween<Offset>(
        begin: _dragOffset, 
        end: Offset(-size.width, _dragOffset.dy)
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      
      anim.addListener(() {
        setState(() {
          _dragOffset = anim.value;
        });
      });
      _controller.forward(from: 0.0);
    } else {
      // Snap back to closed (bottom right)
      final anim = Tween<Offset>(
        begin: _dragOffset, 
        end: Offset(size.width, size.height)
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      
      anim.addListener(() {
        setState(() {
          _dragOffset = anim.value;
        });
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        
        // If not dragging and not animating, default to bottom right corner
        Offset currentOffset = _isDragging || _controller.isAnimating 
            ? _dragOffset 
            : Offset(size.width, size.height);
            
        // Clamp the offset to make sure the math doesn't break
        currentOffset = Offset(
          currentOffset.dx.clamp(-size.width, size.width),
          currentOffset.dy.clamp(0.0, size.height),
        );

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: () => _onPanEnd(DragEndDetails()),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. The underlying page (revealed when front turns)
              widget.underlyingPage,
              
              // 2. The front page being clipped
              ClipPath(
                clipper: _PageCurlFrontClipper(dragOffset: currentOffset),
                child: widget.frontPage,
              ),
              
              // 3. The back of the turning page (the curled part)
              ClipPath(
                clipper: _PageCurlBackClipper(dragOffset: currentOffset),
                child: Transform(
                  // Mirror the back page horizontally so it reads correctly when flipped
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: widget.backPage,
                ),
              ),
              
              // 4. A shadow to sell the 3D effect of the curl
              if (currentOffset.dx < size.width)
                CustomPaint(
                  painter: _PageCurlShadowPainter(dragOffset: currentOffset),
                  child: const SizedBox.expand(),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Math for folding a page corner to a point (x, y)
// See classic paper fold geometry: The fold line is the perpendicular bisector 
// of the line segment from the corner to the drag point.

class _PageCurlFrontClipper extends CustomClipper<Path> {
  final Offset dragOffset;

  _PageCurlFrontClipper({required this.dragOffset});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    if (dragOffset.dx >= size.width) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    final double px = dragOffset.dx;
    final double py = dragOffset.dy;
    
    // Bottom right corner is (W, H)
    final double cx = size.width;
    final double cy = size.height;
    
    // Midpoint between corner and drag point
    final double mx = (px + cx) / 2;
    final double my = (py + cy) / 2;
    
    // Slope of line from corner to drag point
    final double dx = cx - px;
    final double dy = cy - py;
    
    // The fold line passes through (mx, my) and is perpendicular to (dx, dy)
    // Equation of fold line: dy * (Y - my) + dx * (X - mx) = 0
    // Y = my - (dx/dy) * (X - mx)
    // X = mx - (dy/dx) * (Y - my)
    
    // Intersects with right edge (X = W)
    final double intersectRightY = dy == 0 ? 0 : my - (dx / dy) * (cx - mx);
    
    // Intersects with bottom edge (Y = H)
    final double intersectBottomX = dx == 0 ? 0 : mx - (dy / dx) * (cy - my);

    // Clip the front page (everything above/left of the fold line)
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    
    if (intersectRightY > 0 && intersectRightY < size.height) {
      path.lineTo(size.width, intersectRightY);
    } else if (intersectRightY <= 0) {
      // Fold line intersects top edge
      final double intersectTopX = dx == 0 ? 0 : mx - (dy / dx) * (0 - my);
      path.lineTo(intersectTopX.clamp(0.0, size.width), 0);
    }
    
    if (intersectBottomX > 0 && intersectBottomX < size.width) {
      path.lineTo(intersectBottomX, size.height);
    } else if (intersectBottomX <= 0) {
      // Fold line intersects left edge
      final double intersectLeftY = dy == 0 ? 0 : my - (dx / dy) * (0 - mx);
      path.lineTo(0, intersectLeftY.clamp(0.0, size.height));
    }
    
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _PageCurlFrontClipper oldClipper) => oldClipper.dragOffset != dragOffset;
}

class _PageCurlBackClipper extends CustomClipper<Path> {
  final Offset dragOffset;

  _PageCurlBackClipper({required this.dragOffset});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    if (dragOffset.dx >= size.width) return path;

    final double px = dragOffset.dx;
    final double py = dragOffset.dy;
    final double cx = size.width;
    final double cy = size.height;
    final double mx = (px + cx) / 2;
    final double my = (py + cy) / 2;
    final double dx = cx - px;
    final double dy = cy - py;
    
    final double intersectRightY = dy == 0 ? 0 : my - (dx / dy) * (cx - mx);
    final double intersectBottomX = dx == 0 ? 0 : mx - (dy / dx) * (cy - my);

    // The back of the page is bounded by the drag point and the two intersection points
    path.moveTo(px, py);
    
    if (intersectRightY > 0 && intersectRightY < size.height) {
      path.lineTo(size.width, intersectRightY);
    }
    
    if (intersectBottomX > 0 && intersectBottomX < size.width) {
      path.lineTo(intersectBottomX, size.height);
    }
    
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _PageCurlBackClipper oldClipper) => oldClipper.dragOffset != dragOffset;
}

class _PageCurlShadowPainter extends CustomPainter {
  final Offset dragOffset;

  _PageCurlShadowPainter({required this.dragOffset});

  @override
  void paint(Canvas canvas, Size size) {
    if (dragOffset.dx >= size.width) return;

    final double px = dragOffset.dx;
    final double py = dragOffset.dy;
    final double cx = size.width;
    final double cy = size.height;
    final double mx = (px + cx) / 2;
    final double my = (py + cy) / 2;
    final double dx = cx - px;
    final double dy = cy - py;
    
    final double intersectRightY = dy == 0 ? 0 : my - (dx / dy) * (cx - mx);
    final double intersectBottomX = dx == 0 ? 0 : mx - (dy / dx) * (cy - my);

    final Path shadowPath = Path();
    
    if (intersectRightY > 0 && intersectBottomX > 0) {
      // Draw a line along the fold
      shadowPath.moveTo(size.width, intersectRightY);
      shadowPath.lineTo(intersectBottomX, size.height);
      
      canvas.drawPath(
        shadowPath, 
        Paint()
          ..color = Colors.black.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0)
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PageCurlShadowPainter oldDelegate) => oldDelegate.dragOffset != dragOffset;
}
