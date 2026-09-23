import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbInteractiveGlobe extends StatefulWidget {
  final double radius;
  final Color globeColor;
  final Color lineColor;
  final int latLines;
  final int lonLines;

  const SbInteractiveGlobe({
    super.key,
    this.radius = 150.0,
    this.globeColor = const Color(0xFF1E1E1E),
    this.lineColor = const Color(0xFF00FF00),
    this.latLines = 10,
    this.lonLines = 20,
  });

  @override
  State<SbInteractiveGlobe> createState() => _SbInteractiveGlobeState();
}

class _SbInteractiveGlobeState extends State<SbInteractiveGlobe> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  
  // Variables for dragging
  Offset? _lastFocalPoint;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(); // Auto rotation
    
    _controller.addListener(() {
      // Only auto-rotate if we aren't being dragged
      if (_lastFocalPoint == null && mounted) {
        setState(() {
          _rotationY += 0.01;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _lastFocalPoint = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastFocalPoint != null) {
      final Offset delta = details.localPosition - _lastFocalPoint!;
      setState(() {
        // Dragging X axis rotates around Y axis, and vice versa
        _rotationY += delta.dx * 0.01;
        _rotationX -= delta.dy * 0.01;
      });
      _lastFocalPoint = details.localPosition;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _lastFocalPoint = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.globeColor,
          boxShadow: [
            BoxShadow(
              color: widget.lineColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ]
        ),
        child: ClipOval(
          child: CustomPaint(
            painter: _GlobePainter(
              rotationX: _rotationX,
              rotationY: _rotationY,
              radius: widget.radius,
              lineColor: widget.lineColor,
              latLines: widget.latLines,
              lonLines: widget.lonLines,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  final double rotationX;
  final double rotationY;
  final double radius;
  final Color lineColor;
  final int latLines;
  final int lonLines;

  _GlobePainter({
    required this.rotationX,
    required this.rotationY,
    required this.radius,
    required this.lineColor,
    required this.latLines,
    required this.lonLines,
  });

  // Convert 3D spherical coordinates to 2D screen coordinates
  Offset _project3DTo2D(double lat, double lon, double center_x, double center_y) {
    // 1. Spherical to 3D Cartesian
    double x = radius * math.cos(lat) * math.sin(lon);
    double y = radius * math.sin(lat);
    double z = radius * math.cos(lat) * math.cos(lon);

    // 2. Rotate around X axis
    double tempY = y * math.cos(rotationX) - z * math.sin(rotationX);
    double tempZ = y * math.sin(rotationX) + z * math.cos(rotationX);
    y = tempY;
    z = tempZ;

    // 3. Rotate around Y axis
    double tempX = x * math.cos(rotationY) + z * math.sin(rotationY);
    z = -x * math.sin(rotationY) + z * math.cos(rotationY);
    x = tempX;

    // 4. Project to 2D (orthographic projection for simplicity, ignoring Z for depth rendering)
    // We only render points that are facing the camera (z > 0)
    // Actually, for a wireframe globe, rendering the back is fine, but it gets messy. 
    // We'll render everything but change opacity based on Z.
    return Offset(center_x + x, center_y + y);
  }

  // Calculate Z depth for a point to determine opacity
  double _getZDepth(double lat, double lon) {
    double x = radius * math.cos(lat) * math.sin(lon);
    double y = radius * math.sin(lat);
    double z = radius * math.cos(lat) * math.cos(lon);

    double tempY = y * math.cos(rotationX) - z * math.sin(rotationX);
    double tempZ = y * math.sin(rotationX) + z * math.cos(rotationX);
    z = tempZ;

    double tempX = x * math.cos(rotationY) + z * math.sin(rotationY);
    z = -x * math.sin(rotationY) + z * math.cos(rotationY);
    
    return z;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final paintFront = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintBack = Paint()
      ..color = lineColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw Longitude lines (vertical slices)
    for (int i = 0; i < lonLines; i++) {
      double lon = (i / lonLines) * 2 * math.pi;
      
      final pathFront = Path();
      final pathBack = Path();
      
      bool firstFront = true;
      bool firstBack = true;

      // Draw from north pole to south pole
      for (double lat = -math.pi / 2; lat <= math.pi / 2 + 0.01; lat += math.pi / 30) {
        Offset pt = _project3DTo2D(lat, lon, cx, cy);
        double z = _getZDepth(lat, lon);

        if (z >= 0) {
          if (firstFront) {
            pathFront.moveTo(pt.dx, pt.dy);
            firstFront = false;
          } else {
            pathFront.lineTo(pt.dx, pt.dy);
          }
        } else {
          if (firstBack) {
            pathBack.moveTo(pt.dx, pt.dy);
            firstBack = false;
          } else {
            pathBack.lineTo(pt.dx, pt.dy);
          }
        }
      }
      canvas.drawPath(pathBack, paintBack);
      canvas.drawPath(pathFront, paintFront);
    }

    // Draw Latitude lines (horizontal rings)
    for (int i = 1; i < latLines; i++) {
      double lat = -math.pi / 2 + (i / latLines) * math.pi;
      
      final pathFront = Path();
      final pathBack = Path();
      
      bool firstFront = true;
      bool firstBack = true;

      for (double lon = 0; lon <= 2 * math.pi + 0.01; lon += math.pi / 30) {
        Offset pt = _project3DTo2D(lat, lon, cx, cy);
        double z = _getZDepth(lat, lon);

        if (z >= 0) {
          if (firstFront) {
            pathFront.moveTo(pt.dx, pt.dy);
            firstFront = false;
          } else {
            pathFront.lineTo(pt.dx, pt.dy);
          }
        } else {
          if (firstBack) {
            pathBack.moveTo(pt.dx, pt.dy);
            firstBack = false;
          } else {
            pathBack.lineTo(pt.dx, pt.dy);
          }
        }
      }
      canvas.drawPath(pathBack, paintBack);
      canvas.drawPath(pathFront, paintFront);
    }
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
           oldDelegate.rotationY != rotationY ||
           oldDelegate.radius != radius ||
           oldDelegate.lineColor != lineColor;
  }
}
