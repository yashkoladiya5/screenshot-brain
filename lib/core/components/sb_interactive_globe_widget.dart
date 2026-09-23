import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbInteractiveGlobeWidget extends StatefulWidget {
  final double radius;
  final Color oceanColor;
  final Color landColor;
  final List<Offset> points; // Lat/Long mapped to -1 to 1

  const SbInteractiveGlobeWidget({
    super.key,
    this.radius = 150.0,
    this.oceanColor = const Color(0xFF1E88E5),
    this.landColor = const Color(0xFF81C784),
    this.points = const [],
  });

  @override
  State<SbInteractiveGlobeWidget> createState() => _SbInteractiveGlobeWidgetState();
}

class _SbInteractiveGlobeWidgetState extends State<SbInteractiveGlobeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationX = 0.0; // Up/down rotation
  double _rotationY = 0.0; // Left/right rotation
  
  // Physics simulation
  double _velocityX = 0.0;
  double _velocityY = 0.0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..addListener(_updatePhysics);
    
    // Start continuous physics loop
    _controller.repeat();
    
    // Initial gentle spin
    _velocityY = 0.005;
  }

  void _updatePhysics() {
    setState(() {
      // Apply velocity to rotation
      _rotationX += _velocityX;
      _rotationY += _velocityY;
      
      // Add a tiny bit of friction to slow down interaction spins, but keep a base spin
      _velocityX *= 0.95;
      
      if (_velocityY.abs() > 0.005) {
        _velocityY *= 0.95; // Slow down fast spins
      } else if (_velocityY >= 0 && _velocityY < 0.005) {
        _velocityY = 0.005; // Base auto-spin right
      } else if (_velocityY < 0 && _velocityY > -0.005) {
        _velocityY = -0.005; // Base auto-spin left
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Convert screen drag to rotation velocity
    // Dragging right (positive delta) should rotate the globe right (positive Y)
    _velocityY = details.delta.dx * 0.01;
    
    // Dragging down (positive delta) should rotate the globe down (positive X)
    _velocityX = details.delta.dy * 0.01;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      child: Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.oceanColor,
          boxShadow: [
            // Inner shadow for 3D sphere effect
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: widget.radius * 0.5,
              spreadRadius: -widget.radius * 0.1,
              offset: Offset(-widget.radius * 0.2, -widget.radius * 0.2),
              blurStyle: BlurStyle.inner,
            ),
            // Outer glow/atmosphere
            BoxShadow(
              color: widget.oceanColor.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ]
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _GlobePainter(
            rotationX: _rotationX,
            rotationY: _rotationY,
            landColor: widget.landColor,
            points: widget.points.isEmpty ? _generateRandomContinents() : widget.points,
          ),
        ),
      ),
    );
  }
  
  // Helper to generate some random points that look vaguely like landmasses
  List<Offset> _generateRandomContinents() {
    final math.Random rand = math.Random(42); // Fixed seed so it doesn't change every frame
    final List<Offset> points = [];
    
    // Create clumps of points
    for (int i = 0; i < 5; i++) {
      final double centerLat = (rand.nextDouble() * 2) - 1;
      final double centerLon = (rand.nextDouble() * 2) - 1;
      
      for (int j = 0; j < 40; j++) {
        // Normal distribution around the center
        final double lat = (centerLat + ((rand.nextDouble() - 0.5) * 0.5)).clamp(-1.0, 1.0);
        final double lon = (centerLon + ((rand.nextDouble() - 0.5) * 0.8));
        
        // Wrap longitude
        double wrappedLon = lon;
        if (wrappedLon > 1.0) wrappedLon -= 2.0;
        if (wrappedLon < -1.0) wrappedLon += 2.0;
        
        points.add(Offset(wrappedLon, lat));
      }
    }
    
    return points;
  }
}

class _GlobePainter extends CustomPainter {
  final double rotationX;
  final double rotationY;
  final Color landColor;
  final List<Offset> points; // x = longitude (-1 to 1), y = latitude (-1 to 1)

  _GlobePainter({
    required this.rotationX,
    required this.rotationY,
    required this.landColor,
    required this.points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    
    final Paint landPaint = Paint()
      ..color = landColor
      ..style = PaintingStyle.fill;
      
    // Create a 3D rotation matrix
    // In our simplified math:
    // Longitude (-1 to 1) maps to -pi to pi
    // Latitude (-1 to 1) maps to -pi/2 to pi/2
    
    for (final point in points) {
      // 1. Convert lat/lon to spherical coordinates on a unit sphere (radius 1)
      final double lonAngle = point.dx * math.pi; // theta
      final double latAngle = point.dy * (math.pi / 2); // phi
      
      // Standard spherical to cartesian
      double x = math.cos(latAngle) * math.sin(lonAngle);
      double y = math.sin(latAngle);
      double z = math.cos(latAngle) * math.cos(lonAngle);
      
      // 2. Apply Y rotation (spin around vertical axis)
      final double cosY = math.cos(rotationY);
      final double sinY = math.sin(rotationY);
      
      double newX = x * cosY - z * sinY;
      double newZ = x * sinY + z * cosY;
      
      x = newX;
      z = newZ;
      
      // 3. Apply X rotation (spin around horizontal axis)
      final double cosX = math.cos(rotationX);
      final double sinX = math.sin(rotationX);
      
      double newY = y * cosX - z * sinX;
      newZ = y * sinX + z * cosX;
      
      y = newY;
      z = newZ;
      
      // 4. Project onto 2D screen
      // If z < 0, it's on the back of the globe, don't draw it
      if (z > 0) {
        // Simple orthographic projection
        final double screenX = center.dx + (x * radius);
        final double screenY = center.dy + (y * radius);
        
        // Draw larger points at center, smaller at edges to enhance 3D effect
        final double pointSize = 6.0 * z;
        
        canvas.drawCircle(Offset(screenX, screenY), pointSize, landPaint);
      }
    }
    
    // Draw latitude/longitude grid lines for better 3D perception
    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    // We can draw a simple equator as an example of 3D path math
    final Path equatorPath = Path();
    bool isFirstPoint = true;
    
    for (double i = -1.0; i <= 1.0; i += 0.05) {
      final double lonAngle = i * math.pi;
      final double latAngle = 0.0; // Equator
      
      double x = math.cos(latAngle) * math.sin(lonAngle);
      double y = math.sin(latAngle);
      double z = math.cos(latAngle) * math.cos(lonAngle);
      
      final double cosY = math.cos(rotationY);
      final double sinY = math.sin(rotationY);
      
      double newX = x * cosY - z * sinY;
      double newZ = x * sinY + z * cosY;
      x = newX;
      z = newZ;
      
      final double cosX = math.cos(rotationX);
      final double sinX = math.sin(rotationX);
      
      double newY = y * cosX - z * sinX;
      newZ = y * sinX + z * cosX;
      y = newY;
      z = newZ;
      
      if (z >= 0) {
        final double screenX = center.dx + (x * radius);
        final double screenY = center.dy + (y * radius);
        
        if (isFirstPoint) {
          equatorPath.moveTo(screenX, screenY);
          isFirstPoint = false;
        } else {
          equatorPath.lineTo(screenX, screenY);
        }
      } else {
        isFirstPoint = true; // Break the line if it goes behind the globe
      }
    }
    
    canvas.drawPath(equatorPath, gridPaint);
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) {
    return oldDelegate.rotationX != rotationX || 
           oldDelegate.rotationY != rotationY;
  }
}
