import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class SbNeonPulseButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;
  final Color neonColor;
  final double width;
  final double height;

  const SbNeonPulseButton({
    super.key,
    required this.onTap,
    this.text = 'ACTIVATE',
    this.neonColor = const Color(0xFF00FFCC), // Cyberpunk Cyan
    this.width = 200.0,
    this.height = 60.0,
  });

  @override
  State<SbNeonPulseButton> createState() => _SbNeonPulseButtonState();
}

class _SbNeonPulseButtonState extends State<SbNeonPulseButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // Controls the idle breathing/pulsing neon glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Controls the physical press-down and light-burst effect
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _pressController]),
        builder: (context, child) {
          // 1. Idle Pulse Physics
          // Use easeInOut for a smoother breathing curve
          final double pulse = Curves.easeInOut.transform(_pulseController.value);
          
          // 2. Press Physics
          final double pressProgress = _pressController.value;
          
          // Physical scale down when pressed
          final double scale = 1.0 - (pressProgress * 0.05);
          
          // 3. Dynamic Glow Calculation
          // Base glow breathes from 10 to 20
          // But when pressed, it flares up violently to 50
          final double glowIntensity = 10.0 + (pulse * 10.0) + (pressProgress * 30.0);
          
          // Outer flare alpha increases when pressed
          final double outerAlpha = 0.2 + (pulse * 0.2) + (pressProgress * 0.4);

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Layer 1: Ambient Outer Glow Flare
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: widget.neonColor.withValues(alpha: outerAlpha),
                          blurRadius: glowIntensity * 2,
                          spreadRadius: glowIntensity * 0.5,
                        )
                      ]
                    ),
                  ),
                  
                  // Layer 2: The physical wireframe border
                  CustomPaint(
                    size: Size(widget.width, widget.height),
                    painter: _NeonWireframePainter(
                      color: widget.neonColor,
                      glowIntensity: glowIntensity,
                      isPressed: _isPressed,
                      pulse: pulse,
                    ),
                  ),
                  
                  // Layer 3: The Text Core
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: _isPressed ? Colors.white : widget.neonColor,
                      fontSize: widget.height * 0.35,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      shadows: [
                        Shadow(
                          color: widget.neonColor,
                          blurRadius: _isPressed ? 20.0 : 5.0 + (pulse * 5.0),
                        )
                      ]
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class _NeonWireframePainter extends CustomPainter {
  final Color color;
  final double glowIntensity;
  final bool isPressed;
  final double pulse;

  _NeonWireframePainter({
    required this.color,
    required this.glowIntensity,
    required this.isPressed,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height / 2),
    );

    // 1. Draw the blurry inner neon core
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = color.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
    canvas.drawRRect(rrect, glowPaint);

    // 2. Draw the hot white-hot filament center
    final Paint corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = isPressed ? Colors.white : Color.lerp(color, Colors.white, 0.7)!;
      
    canvas.drawRRect(rrect, corePaint);

    // 3. Draw high-tech corner brackets (Cyberpunk aesthetic)
    final double bracketLen = size.height * 0.4;
    final double bracketOffset = pulse * 2.0; // Brackets float slightly with the pulse
    
    final Paint bracketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withValues(alpha: 0.9);
      
    final Path bracketPath = Path();
    
    // Top Left bracket
    bracketPath.moveTo(bracketLen, -bracketOffset);
    bracketPath.lineTo(-bracketOffset, -bracketOffset);
    bracketPath.lineTo(-bracketOffset, bracketLen);
    
    // Bottom Right bracket
    bracketPath.moveTo(size.width - bracketLen, size.height + bracketOffset);
    bracketPath.lineTo(size.width + bracketOffset, size.height + bracketOffset);
    bracketPath.lineTo(size.width + bracketOffset, size.height - bracketLen);

    canvas.drawPath(bracketPath, bracketPaint);
    
    // Add glowing dots on the brackets
    final Paint dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(-bracketOffset, bracketLen), 2.0, dotPaint);
    canvas.drawCircle(Offset(size.width + bracketOffset, size.height - bracketLen), 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _NeonWireframePainter oldDelegate) {
    return true; // Always repaint due to continuous pulsing
  }
}
