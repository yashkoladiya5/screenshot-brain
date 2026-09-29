import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbLiquidFillSlider extends StatefulWidget {
  final double width;
  final double height;
  final Color liquidColor;
  final Color emptyColor;
  final ValueChanged<double>? onChanged;
  final double initialValue;

  const SbLiquidFillSlider({
    super.key,
    this.width = 300.0,
    this.height = 60.0,
    this.liquidColor = const Color(0xFF00B0FF),
    this.emptyColor = const Color(0xFF263238),
    this.onChanged,
    this.initialValue = 0.5,
  });

  @override
  State<SbLiquidFillSlider> createState() => _SbLiquidFillSliderState();
}

class _SbLiquidFillSliderState extends State<SbLiquidFillSlider> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  
  double _value = 0.5; // 0.0 to 1.0
  double _dragVelocity = 0.0;
  Offset? _lastDragPos;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.clamp(0.0, 1.0);
    
    // This drives the continuous sine wave animation of the liquid surface
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _updateValueFromPosition(Offset localPosition) {
    setState(() {
      _value = (localPosition.dx / widget.width).clamp(0.0, 1.0);
      if (widget.onChanged != null) {
        widget.onChanged!(_value);
      }
      
      if (_lastDragPos != null) {
        final double dx = localPosition.dx - _lastDragPos!.dx;
        // The faster we drag, the more the liquid "sloshes" (higher amplitude)
        _dragVelocity = (_dragVelocity * 0.8) + (dx * 0.2);
      }
      
      _lastDragPos = localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) {
        _lastDragPos = details.localPosition;
        _updateValueFromPosition(details.localPosition);
      },
      onPanUpdate: (details) {
        _updateValueFromPosition(details.localPosition);
      },
      onPanEnd: (details) {
        _lastDragPos = null;
        // Let the slosh slowly settle back to 0
        _settleSlosh();
      },
      onPanCancel: () {
        _lastDragPos = null;
        _settleSlosh();
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.emptyColor,
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
              inset: true, // Inner shadow to look like a glass tube
            )
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: Stack(
            children: [
              // Liquid Fill Background
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  // If we aren't dragging, the slosh naturally settles down
                  if (_lastDragPos == null) {
                    _dragVelocity *= 0.95; 
                  }
                  
                  return CustomPaint(
                    size: Size(widget.width, widget.height),
                    painter: _LiquidFillPainter(
                      fillPercent: _value,
                      time: _waveController.value,
                      liquidColor: widget.liquidColor,
                      sloshVelocity: _dragVelocity,
                    ),
                  );
                }
              ),
              
              // Glossy reflection on the glass tube
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.2),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              
              // Text readout
              Align(
                alignment: Alignment.center,
                child: Text(
                  '${(_value * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1))
                    ]
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _settleSlosh() async {
    // A simple loop to bleed off the drag velocity after release
    while (_dragVelocity.abs() > 0.1 && mounted) {
      await Future.delayed(const Duration(milliseconds: 16));
      if (mounted) {
        setState(() {
          _dragVelocity *= 0.9;
        });
      }
    }
    if (mounted) {
      setState(() {
        _dragVelocity = 0.0;
      });
    }
  }
}

// Custom Extension to add inner shadow support to BoxDecoration
extension InnerShadow on BoxShadow {
  bool get inset => true; // Just a placeholder, Flutter's default BoxShadow doesn't natively support inset well, but we use a workaround inside the painter if needed, or we just rely on the gradient overlay.
}

class _LiquidFillPainter extends CustomPainter {
  final double fillPercent; // 0.0 to 1.0
  final double time; // 0.0 to 1.0
  final Color liquidColor;
  final double sloshVelocity;

  _LiquidFillPainter({
    required this.fillPercent,
    required this.time,
    required this.liquidColor,
    required this.sloshVelocity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercent == 0.0) return;

    final double fillWidth = size.width * fillPercent;
    
    // We draw two overlapping sine waves to create depth in the liquid
    // Back wave (darker, moves faster)
    _drawWave(
      canvas: canvas,
      size: size,
      fillWidth: fillWidth,
      time: time * 1.5,
      color: liquidColor.withValues(alpha: 0.5),
      amplitudeOffset: sloshVelocity * 0.8,
      phaseOffset: math.pi, // Opposite phase
    );
    
    // Front wave (brighter, normal speed)
    _drawWave(
      canvas: canvas,
      size: size,
      fillWidth: fillWidth,
      time: time,
      color: liquidColor,
      amplitudeOffset: sloshVelocity,
      phaseOffset: 0.0,
    );
    
    // Draw some bubbles in the liquid
    _drawBubbles(canvas, size, fillWidth);
  }
  
  void _drawWave({
    required Canvas canvas,
    required Size size,
    required double fillWidth,
    required double time,
    required Color color,
    required double amplitudeOffset,
    required double phaseOffset,
  }) {
    final Paint paint = Paint()..color = color;
    final Path path = Path();
    
    path.moveTo(0, size.height);
    path.lineTo(0, 0); // Start at top left
    
    // The wave is drawn along the vertical right edge of the fill
    // If the fill is very small or very large, we flatten the wave so it doesn't break the container
    double edgeDamping = 1.0;
    if (fillPercent < 0.1) edgeDamping = fillPercent / 0.1;
    if (fillPercent > 0.9) edgeDamping = (1.0 - fillPercent) / 0.1;
    
    // Base amplitude + slosh amplitude based on drag velocity
    final double baseAmplitude = 5.0 * edgeDamping;
    final double dynamicAmplitude = (baseAmplitude + amplitudeOffset).clamp(-20.0, 20.0);
    
    // Draw the wavy edge from top to bottom
    for (double y = 0; y <= size.height; y++) {
      // We map Y to a sine wave. 
      // time * math.pi * 2 makes it continuously scroll.
      final double wave = math.sin((y / size.height * math.pi * 2) + (time * math.pi * 2) + phaseOffset);
      
      final double x = fillWidth + (wave * dynamicAmplitude);
      path.lineTo(x, y);
    }
    
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawBubbles(Canvas canvas, Size size, double fillWidth) {
    // Generate deterministic pseudo-random bubbles based on time
    // This gives the illusion of bubbles rising without tracking state
    final Paint bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final int bubbleCount = (fillPercent * 15).toInt();
    
    for (int i = 0; i < bubbleCount; i++) {
      // Seed based on bubble index
      final double startX = (i * 47) % fillWidth;
      
      // Speed varies per bubble
      final double speed = 0.2 + ((i * 13) % 10) / 20.0;
      
      // Y position moves up over time and wraps around
      final double y = size.height - ((time * size.height * speed * 5) % size.height);
      
      // Small horizontal wobble
      final double wobble = math.sin(time * math.pi * 10 + i) * 2.0;
      final double x = startX + wobble;
      
      // Only draw if inside the liquid bounds (roughly)
      if (x < fillWidth - 10 && y > 0) {
        final double radius = 1.0 + (i % 4);
        canvas.drawCircle(Offset(x, y), radius, bubblePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidFillPainter oldDelegate) {
    return true; // Always repaint for continuous wave and bubbles
  }
}
