import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbLiquidFillButton extends StatefulWidget {
  final String text;
  final VoidCallback onFilled;
  final Duration fillDuration;
  final Color liquidColor;
  final Color backgroundColor;
  final Color textColor;
  final double width;
  final double height;

  const SbLiquidFillButton({
    super.key,
    required this.text,
    required this.onFilled,
    this.fillDuration = const Duration(seconds: 2),
    this.liquidColor = const Color(0xFF00E5FF),
    this.backgroundColor = const Color(0xFF1E293B),
    this.textColor = Colors.white,
    this.width = 240.0,
    this.height = 70.0,
  });

  @override
  State<SbLiquidFillButton> createState() => _SbLiquidFillButtonState();
}

class _SbLiquidFillButtonState extends State<SbLiquidFillButton> with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _waveController;
  
  bool _isFilled = false;

  @override
  void initState() {
    super.initState();
    // Controls the overall fill level (0.0 to 1.0)
    _fillController = AnimationController(
      vsync: this,
      duration: widget.fillDuration,
    );
    
    _fillController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isFilled = true);
        widget.onFilled();
      }
    });

    // Controls the perpetual wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _fillController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_isFilled) {
      _fillController.forward();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isFilled) {
      _fillController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: AnimatedBuilder(
        animation: _fillController,
        builder: (context, child) {
          // Add a subtle bounce effect when the button is fully filled
          final double scale = _isFilled ? 1.05 : 1.0 - (_fillController.value * 0.05);
          
          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.height / 2),
                boxShadow: [
                  BoxShadow(
                    color: widget.liquidColor.withValues(alpha: _fillController.value * 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The liquid fill layer
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _LiquidPainter(
                            fillLevel: _fillController.value,
                            wavePhase: _waveController.value,
                            liquidColor: widget.liquidColor,
                          ),
                        );
                      }
                    ),
                  ),
                  
                  // The text overlay
                  Text(
                    _isFilled ? 'COMPLETE!' : widget.text,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      // Subtle glow on the text based on fill level
                      shadows: [
                        Shadow(
                          color: widget.liquidColor.withValues(alpha: _fillController.value),
                          blurRadius: 8,
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

class _LiquidPainter extends CustomPainter {
  final double fillLevel; // 0.0 to 1.0
  final double wavePhase; // 0.0 to 1.0
  final Color liquidColor;

  _LiquidPainter({
    required this.fillLevel,
    required this.wavePhase,
    required this.liquidColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillLevel == 0) return;

    final Paint paint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;
      
    final Paint darkPaint = Paint()
      ..color = liquidColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Y coordinate of the "water level". 
    // Fill level 0 = size.height (bottom)
    // Fill level 1 = 0 (top)
    final double waterLevel = size.height * (1.0 - fillLevel);
    
    // As it gets fuller, the waves should calm down.
    final double waveHeight = 15.0 * (1.0 - fillLevel).clamp(0.0, 1.0);

    // Draw the background darker wave (offset phase)
    _drawWave(canvas, size, waterLevel, waveHeight, wavePhase + 0.5, darkPaint);
    
    // Draw the foreground main wave
    _drawWave(canvas, size, waterLevel, waveHeight, wavePhase, paint);
  }
  
  void _drawWave(Canvas canvas, Size size, double waterLevel, double waveHeight, double phase, Paint paint) {
    final Path path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, waterLevel);
    
    // Draw the wavy surface
    for (double i = 0; i <= size.width; i++) {
      // 2 * pi for a full sine wave across the width. We use 1.5 waves.
      final double normalizedX = i / size.width;
      final double angle = (normalizedX * 1.5 * 2 * math.pi) + (phase * 2 * math.pi);
      
      final double y = waterLevel + math.sin(angle) * waveHeight;
      path.lineTo(i, y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel || oldDelegate.wavePhase != wavePhase;
  }
}
