import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class SbPlasmaGlobeButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final Color plasmaColor;
  final Widget? child;

  const SbPlasmaGlobeButton({
    super.key,
    required this.onTap,
    this.size = 150.0,
    this.plasmaColor = const Color(0xFFE040FB), // Purple/Pink plasma
    this.child,
  });

  @override
  State<SbPlasmaGlobeButton> createState() => _SbPlasmaGlobeButtonState();
}

class _SbPlasmaGlobeButtonState extends State<SbPlasmaGlobeButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Track where the user is touching the globe
  Offset? _touchPosition;
  
  // A list to track the random wandering targets for the lightning bolts
  final List<_LightningBolt> _bolts = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(_updatePhysics);
    
    // Initialize 4-5 random lightning bolts
    final math.Random random = math.Random();
    for (int i = 0; i < 5; i++) {
      _bolts.add(_LightningBolt(
        angle: random.nextDouble() * math.pi * 2,
        targetAngle: random.nextDouble() * math.pi * 2,
        speed: 0.02 + random.nextDouble() * 0.03,
      ));
    }
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updatePhysics() {
    if (!mounted) return;
    final math.Random random = math.Random();
    
    setState(() {
      for (final bolt in _bolts) {
        // If the globe is being touched, all bolts rapidly aggressively target the finger!
        if (_touchPosition != null) {
          // We calculate the angle from the center (size/2, size/2) to the touch position
          final double centerX = widget.size / 2;
          final double centerY = widget.size / 2;
          final double dx = _touchPosition!.dx - centerX;
          final double dy = _touchPosition!.dy - centerY;
          
          final double touchAngle = math.atan2(dy, dx);
          
          // Smoothly interpolate the bolt's angle toward the touch angle
          // We use a faster speed so the plasma "snaps" to the finger
          bolt.angle = _lerpAngle(bolt.angle, touchAngle, 0.15);
        } else {
          // Normal idle state: wander around randomly
          bolt.angle = _lerpAngle(bolt.angle, bolt.targetAngle, bolt.speed);
          
          // If we reached the target angle, pick a new random target
          if ((bolt.angle - bolt.targetAngle).abs() < 0.1) {
            bolt.targetAngle = random.nextDouble() * math.pi * 2;
            bolt.speed = 0.01 + random.nextDouble() * 0.03;
          }
        }
      }
    });
  }
  
  // Helper to interpolate angles correctly (taking the shortest path around the circle)
  double _lerpAngle(double a, double b, double t) {
    double delta = (b - a) % (math.pi * 2);
    if (delta > math.pi) delta -= math.pi * 2;
    if (delta < -math.pi) delta += math.pi * 2;
    return a + delta * t;
  }

  void _onPanDown(DragDownDetails details) {
    setState(() {
      _touchPosition = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _touchPosition = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _touchPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanDown: _onPanDown,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _onPanEnd(DragEndDetails()),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Glass globe effect
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
              Colors.black.withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: widget.plasmaColor.withValues(alpha: _touchPosition != null ? 0.4 : 0.1),
              blurRadius: 30,
              spreadRadius: 5,
            )
          ]
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The plasma lightning generator
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _PlasmaPainter(
                bolts: _bolts,
                color: widget.plasmaColor,
                time: _controller.value,
                isTouched: _touchPosition != null,
                touchPosition: _touchPosition,
              ),
            ),
            
            // Central core electrode
            Container(
              width: widget.size * 0.2,
              height: widget.size * 0.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: widget.plasmaColor,
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ]
              ),
            ),
            
            // Optional child (like a label)
            if (widget.child != null)
              widget.child!,
              
            // Specular reflection (makes it look like a shiny glass sphere)
            Positioned(
              top: widget.size * 0.1,
              left: widget.size * 0.15,
              child: Container(
                width: widget.size * 0.3,
                height: widget.size * 0.15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(widget.size * 0.3, widget.size * 0.15)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.6),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  )
                ),
                transform: Matrix4.rotationZ(-0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightningBolt {
  double angle;
  double targetAngle;
  double speed;

  _LightningBolt({
    required this.angle,
    required this.targetAngle,
    required this.speed,
  });
}

class _PlasmaPainter extends CustomPainter {
  final List<_LightningBolt> bolts;
  final Color color;
  final double time;
  final bool isTouched;
  final Offset? touchPosition;

  _PlasmaPainter({
    required this.bolts,
    required this.color,
    required this.time,
    required this.isTouched,
    required this.touchPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final Offset center = Offset(centerX, centerY);
    final double radius = size.width / 2;
    
    final math.Random random = math.Random((time * 1000).toInt()); // Deterministic random per frame for jitter

    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
    final Paint corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < bolts.length; i++) {
      final bolt = bolts[i];
      
      // If touched, we calculate exact distance to the touch to stop the bolt at the glass edge
      // If not touched, they hit the outer glass edge
      double targetRadius = radius - 4.0;
      double endAngle = bolt.angle;
      
      if (isTouched && touchPosition != null) {
        // Add extreme high-frequency jitter to the angle when touched, simulating high voltage
        endAngle += (random.nextDouble() - 0.5) * 0.2;
      }
      
      final Offset end = Offset(
        centerX + math.cos(endAngle) * targetRadius,
        centerY + math.sin(endAngle) * targetRadius,
      );

      // We draw the lightning using a fractal subdivision technique
      final Path boltPath = Path();
      boltPath.moveTo(center.dx, center.dy);
      
      // Subdivide the line into segments
      int segments = 8;
      double currentX = center.dx;
      double currentY = center.dy;
      
      for (int j = 1; j <= segments; j++) {
        // Calculate standard interpolated point
        final double t = j / segments;
        final double baseX = center.dx + (end.dx - center.dx) * t;
        final double baseY = center.dy + (end.dy - center.dy) * t;
        
        // Add perpendicular jitter to create the jagged lightning shape
        // Amplitude is higher in the middle, zero at the ends
        final double midPulse = math.sin(t * math.pi); 
        final double jitterAmplitude = isTouched ? 15.0 : 8.0;
        
        final double jitter = (random.nextDouble() - 0.5) * jitterAmplitude * midPulse;
        
        // Perpendicular vector
        final double dx = end.dx - center.dx;
        final double dy = end.dy - center.dy;
        final double len = math.sqrt(dx * dx + dy * dy);
        final double perpX = -dy / len;
        final double perpY = dx / len;
        
        currentX = baseX + perpX * jitter;
        currentY = baseY + perpY * jitter;
        
        boltPath.lineTo(currentX, currentY);
      }
      
      // Sometimes draw a branching fork
      if (random.nextDouble() > 0.7) {
        // Fork logic could go here, for now simple lines are fast and effective
      }

      // Draw the glow
      canvas.drawPath(boltPath, glowPaint);
      
      // Draw the hot white core
      canvas.drawPath(boltPath, corePaint);
      
      // Draw a bright impact spot where it hits the glass
      if (isTouched) {
        canvas.drawCircle(end, 4.0, Paint()..color = Colors.white);
        canvas.drawCircle(end, 12.0, Paint()..color = color.withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlasmaPainter oldDelegate) {
    return true; // Always repaint while animating
  }
}
