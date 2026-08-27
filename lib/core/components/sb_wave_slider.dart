import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbWaveSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;

  const SbWaveSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.activeColor,
    this.inactiveColor,
    this.height = 60.0,
  });

  @override
  State<SbWaveSlider> createState() => _SbWaveSliderState();
}

class _SbWaveSliderState extends State<SbWaveSlider> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  bool _isDragging = false;
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void didUpdateWidget(SbWaveSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && widget.value != _currentValue) {
      _currentValue = widget.value;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _updateValue(double localX, double width) {
    final double percentage = (localX / width).clamp(0.0, 1.0);
    final double newValue = widget.min + (percentage * (widget.max - widget.min));
    
    if (_currentValue != newValue) {
      setState(() {
        _currentValue = newValue;
      });
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = widget.activeColor ?? theme.colorScheme.primary;
    final inactive = widget.inactiveColor ?? theme.colorScheme.surfaceContainerHighest;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double percentage = ((_currentValue - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
        
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            setState(() => _isDragging = true);
            _waveController.repeat();
            _updateValue(details.localPosition.dx, width);
          },
          onHorizontalDragUpdate: (details) {
            _updateValue(details.localPosition.dx, width);
          },
          onHorizontalDragEnd: (_) {
            setState(() => _isDragging = false);
            _waveController.stop();
          },
          onTapDown: (details) {
            setState(() => _isDragging = true);
            _waveController.repeat();
            _updateValue(details.localPosition.dx, width);
          },
          onTapUp: (_) {
            setState(() => _isDragging = false);
            _waveController.stop();
          },
          onTapCancel: () {
            setState(() => _isDragging = false);
            _waveController.stop();
          },
          child: SizedBox(
            height: widget.height,
            width: width,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WaveSliderPainter(
                    percentage: percentage,
                    activeColor: active,
                    inactiveColor: inactive,
                    wavePhase: _waveController.value * math.pi * 2,
                    isDragging: _isDragging,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _WaveSliderPainter extends CustomPainter {
  final double percentage;
  final Color activeColor;
  final Color inactiveColor;
  final double wavePhase;
  final bool isDragging;

  _WaveSliderPainter({
    required this.percentage,
    required this.activeColor,
    required this.inactiveColor,
    required this.wavePhase,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double trackHeight = 4.0;
    final double thumbRadius = isDragging ? 12.0 : 8.0;
    
    final double centerY = size.height / 2;
    final double activeWidth = size.width * percentage;

    // Draw inactive track
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;
      
    canvas.drawLine(
      Offset(activeWidth, centerY),
      Offset(size.width, centerY),
      inactivePaint,
    );

    // Draw active track (as a wave if dragging)
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, centerY);

    if (isDragging && activeWidth > 20) {
      // Draw wave up to the thumb
      final int segments = (activeWidth / 10).floor().clamp(1, 100);
      for (int i = 0; i <= segments; i++) {
        final double x = (activeWidth / segments) * i;
        
        // Dampen the wave near the ends (0 and activeWidth)
        final double dampening = math.sin((x / activeWidth) * math.pi);
        
        // Calculate wave height
        final double waveHeight = math.sin((x * 0.1) + wavePhase) * 10 * dampening;
        
        path.lineTo(x, centerY + waveHeight);
      }
    } else {
      // Draw straight line
      path.lineTo(activeWidth, centerY);
    }

    canvas.drawPath(path, activePaint);

    // Draw Thumb
    final thumbPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset(activeWidth, centerY), thumbRadius, thumbPaint);
    
    // Thumb inner shadow/highlight
    if (isDragging) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(activeWidth - 2, centerY - 2), thumbRadius * 0.4, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveSliderPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
           oldDelegate.wavePhase != wavePhase ||
           oldDelegate.isDragging != isDragging ||
           oldDelegate.activeColor != activeColor;
  }
}
