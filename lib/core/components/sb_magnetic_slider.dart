import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:math' as math;

class SbMagneticSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double width;
  final double height;
  final Color activeColor;
  final Color inactiveColor;

  const SbMagneticSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = double.infinity,
    this.height = 60.0,
    this.activeColor = const Color(0xFFE91E63),
    this.inactiveColor = const Color(0xFFFCE4EC),
  });

  @override
  State<SbMagneticSlider> createState() => _SbMagneticSliderState();
}

class _SbMagneticSliderState extends State<SbMagneticSlider> with TickerProviderStateMixin {
  late AnimationController _springController;
  
  double _dragVelocity = 0.0;
  double _lastDragPosition = 0.0;
  int _lastDragTime = 0;
  bool _isDragging = false;
  double _magneticPull = 0.0;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _springController.addListener(() {
      setState(() {
        _magneticPull = _springController.value * _dragVelocity * 10.0;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _updateValue(double dx, double maxWidth) {
    double newValue = (dx / maxWidth).clamp(0.0, 1.0);
    
    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (_lastDragTime > 0) {
      final double deltaDistance = dx - _lastDragPosition;
      final int deltaTime = currentTime - _lastDragTime;
      
      if (deltaTime > 0) {
        final double velocity = deltaDistance / deltaTime;
        _dragVelocity = velocity.clamp(-3.0, 3.0);
        
        setState(() {
          _magneticPull = _dragVelocity * 15.0; // Dynamic stretching based on speed
        });
      }
    }
    
    _lastDragPosition = dx;
    _lastDragTime = currentTime;
    
    widget.onChanged(newValue);
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    setState(() => _isDragging = true);
    _springController.stop();
    _updateValue(details.localPosition.dx, constraints.maxWidth);
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    _updateValue(details.localPosition.dx, constraints.maxWidth);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _lastDragTime = 0;
    });
    
    // Spring back to normal shape
    _springController.value = 1.0;
    _springController.animateTo(0.0, curve: Curves.elasticOut);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth == double.infinity 
            ? MediaQuery.of(context).size.width 
            : constraints.maxWidth;
            
        return GestureDetector(
          onPanStart: (details) => _onPanStart(details, constraints),
          onPanUpdate: (details) => _onPanUpdate(details, constraints),
          onPanEnd: _onPanEnd,
          onPanCancel: () => _onPanEnd(DragEndDetails()),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: CustomPaint(
              painter: _MagneticSliderPainter(
                value: widget.value,
                activeColor: widget.activeColor,
                inactiveColor: widget.inactiveColor,
                magneticPull: _magneticPull,
                isDragging: _isDragging,
              ),
            ),
          ),
        );
      }
    );
  }
}

class _MagneticSliderPainter extends CustomPainter {
  final double value;
  final Color activeColor;
  final Color inactiveColor;
  final double magneticPull;
  final bool isDragging;

  _MagneticSliderPainter({
    required this.value,
    required this.activeColor,
    required this.inactiveColor,
    required this.magneticPull,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double thumbRadius = size.height / 2;
    
    // Draw inactive track
    final Paint inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;
      
    final RRect trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.25, size.width, size.height * 0.5),
      Radius.circular(size.height * 0.25),
    );
    canvas.drawRRect(trackRect, inactivePaint);

    final double thumbCenter = thumbRadius + (size.width - thumbRadius * 2) * value;

    // Draw active track that magnetically attaches to the thumb
    final Paint activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
      
    final Path activePath = Path();
    activePath.moveTo(0, size.height * 0.25);
    activePath.lineTo(thumbCenter - thumbRadius - magneticPull.abs(), size.height * 0.25);
    
    // Bezier curve to magnetic thumb
    activePath.cubicTo(
      thumbCenter - thumbRadius, size.height * 0.25, 
      thumbCenter - thumbRadius, 0, 
      thumbCenter + magneticPull, 0
    );
    
    activePath.lineTo(thumbCenter + magneticPull, size.height);
    
    activePath.cubicTo(
      thumbCenter - thumbRadius, size.height, 
      thumbCenter - thumbRadius, size.height * 0.75, 
      thumbCenter - thumbRadius - magneticPull.abs(), size.height * 0.75
    );
    
    activePath.lineTo(0, size.height * 0.75);
    activePath.close();
    
    canvas.drawPath(activePath, activePaint);

    // Draw the Thumb
    final Paint thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final Paint thumbShadow = Paint()
      ..color = activeColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      
    final Offset thumbOffset = Offset(thumbCenter + magneticPull, size.height / 2);
    
    // Scale thumb slightly when dragging
    final double currentRadius = isDragging ? thumbRadius * 0.8 : thumbRadius * 0.9;
    
    canvas.drawCircle(thumbOffset, currentRadius, thumbShadow);
    canvas.drawCircle(thumbOffset, currentRadius, thumbPaint);
    
    // Inner dot
    canvas.drawCircle(thumbOffset, currentRadius * 0.3, activePaint);
  }

  @override
  bool shouldRepaint(covariant _MagneticSliderPainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.magneticPull != magneticPull ||
           oldDelegate.isDragging != isDragging;
  }
}
