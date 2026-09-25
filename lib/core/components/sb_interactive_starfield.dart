import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:math' as math;

class SbInteractiveStarfield extends StatefulWidget {
  final int starCount;
  final Color starColor;
  final Color backgroundColor;
  final double baseSpeed;

  const SbInteractiveStarfield({
    super.key,
    this.starCount = 200,
    this.starColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.baseSpeed = 1.0,
  });

  @override
  State<SbInteractiveStarfield> createState() => _SbInteractiveStarfieldState();
}

class _SbInteractiveStarfieldState extends State<SbInteractiveStarfield> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];
  final math.Random _random = math.Random();
  
  double _warpSpeedMultiplier = 1.0;
  Offset _panOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updatePhysics);
    
    _controller.repeat();
  }

  void _initStars(Size size) {
    if (_stars.isNotEmpty) return;
    
    for (int i = 0; i < widget.starCount; i++) {
      _stars.add(_Star(
        // Distribute randomly in 3D space (-1 to 1 for X/Y, 0 to 1 for Z)
        x: (_random.nextDouble() - 0.5) * 2,
        y: (_random.nextDouble() - 0.5) * 2,
        z: _random.nextDouble(), 
        prevZ: 0.0,
      ));
    }
  }

  void _updatePhysics() {
    if (_stars.isEmpty) return;
    
    // Smoothly decay warp speed and pan offset back to normal when not touching
    _warpSpeedMultiplier += (1.0 - _warpSpeedMultiplier) * 0.1;
    _panOffset = Offset(
      _panOffset.dx * 0.9,
      _panOffset.dy * 0.9
    );
    
    setState(() {
      for (final star in _stars) {
        star.prevZ = star.z;
        // Move star closer to the camera (Z decreases)
        // Speed depends on warp multiplier
        star.z -= 0.005 * widget.baseSpeed * _warpSpeedMultiplier;
        
        // If star goes past the camera (Z <= 0), reset it to the far distance (Z = 1)
        if (star.z <= 0) {
          star.x = (_random.nextDouble() - 0.5) * 2;
          star.y = (_random.nextDouble() - 0.5) * 2;
          star.z = 1.0;
          star.prevZ = 1.0;
        }
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Touching the screen increases speed (warp drive!) and shifts perspective
    _warpSpeedMultiplier = 10.0;
    
    // Shift the vanishing point opposite to the drag direction
    _panOffset = Offset(
      (_panOffset.dx - details.delta.dx * 0.05).clamp(-1.0, 1.0),
      (_panOffset.dy - details.delta.dy * 0.05).clamp(-1.0, 1.0)
    );
  }
  
  void _onPanDown(DragDownDetails details) {
    _warpSpeedMultiplier = 10.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_stars.isEmpty && mounted) {
        _initStars(MediaQuery.of(context).size);
      }
    });

    return GestureDetector(
      onPanDown: _onPanDown,
      onPanUpdate: _onPanUpdate,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: widget.backgroundColor,
        child: CustomPaint(
          painter: _StarfieldPainter(
            stars: _stars,
            starColor: widget.starColor,
            panOffset: _panOffset,
            isWarping: _warpSpeedMultiplier > 2.0,
          ),
        ),
      ),
    );
  }
}

class _Star {
  double x; // -1 to 1
  double y; // -1 to 1
  double z; // 0 to 1 (depth)
  double prevZ;

  _Star({
    required this.x,
    required this.y,
    required this.z,
    required this.prevZ,
  });
}

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final Color starColor;
  final Offset panOffset;
  final bool isWarping;

  _StarfieldPainter({
    required this.stars,
    required this.starColor,
    required this.panOffset,
    required this.isWarping,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(
      (size.width / 2) + (panOffset.dx * size.width * 0.5), 
      (size.height / 2) + (panOffset.dy * size.height * 0.5)
    );
    
    final Paint paint = Paint()
      ..color = starColor
      ..strokeCap = StrokeCap.round;

    for (final star in stars) {
      // 3D to 2D projection formula:
      // screenX = (x / z) * fov + screenCenterX
      
      // We map the virtual X/Y (-1 to 1) to screen coordinates
      final double fov = size.width; 
      
      final double screenX = (star.x / star.z) * fov + center.dx;
      final double screenY = (star.y / star.z) * fov + center.dy;
      
      // Don't draw if outside screen
      if (screenX < 0 || screenX > size.width || screenY < 0 || screenY > size.height) {
        continue;
      }
      
      // Size depends on depth (closer = bigger)
      // If z is 1, size is small. If z is 0.1, size is big.
      final double starSize = (1.0 - star.z) * 3.0;
      paint.strokeWidth = starSize.clamp(0.5, 4.0);
      
      // Opacity fades in from the distance
      final double opacity = (1.0 - star.z).clamp(0.1, 1.0);
      paint.color = starColor.withValues(alpha: opacity);

      // If warping, we draw lines from previous Z to current Z to create motion blur trails
      if (isWarping && star.prevZ != star.z) {
        final double prevScreenX = (star.x / star.prevZ) * fov + center.dx;
        final double prevScreenY = (star.y / star.prevZ) * fov + center.dy;
        
        canvas.drawLine(Offset(prevScreenX, prevScreenY), Offset(screenX, screenY), paint);
      } else {
        // Just draw a point
        canvas.drawPoints(PointMode.points, [Offset(screenX, screenY)], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return true; // Continuously animating
  }
}
