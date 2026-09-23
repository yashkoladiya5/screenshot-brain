import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbLiquidSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Color liquidColor;
  final Color backgroundColor;
  final double width;
  final double height;

  const SbLiquidSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.liquidColor = const Color(0xFF6200EA),
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.width = double.infinity,
    this.height = 80.0,
  }) : assert(value >= 0.0 && value <= 1.0);

  @override
  State<SbLiquidSlider> createState() => _SbLiquidSliderState();
}

class _SbLiquidSliderState extends State<SbLiquidSlider> with TickerProviderStateMixin {
  late AnimationController _stretchController;
  late AnimationController _wobbleController;
  
  double _dragVelocity = 0.0;
  double _lastDragPosition = 0.0;
  int _lastDragTime = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    
    // Controls the stretching of the thumb when dragged fast
    _stretchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Controls the organic wobble of the liquid edge
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _stretchController.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  void _updateValueFromPosition(double dx, double maxWidth) {
    // Convert touch X position to a 0.0 to 1.0 value
    double newValue = (dx / maxWidth).clamp(0.0, 1.0);
    
    // Calculate drag velocity for physics
    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (_lastDragTime > 0) {
      final double deltaDistance = dx - _lastDragPosition;
      final int deltaTime = currentTime - _lastDragTime;
      
      if (deltaTime > 0) {
        final double velocity = deltaDistance / deltaTime;
        setState(() {
          _dragVelocity = velocity.clamp(-5.0, 5.0);
          _stretchController.value = (_dragVelocity.abs() / 5.0).clamp(0.0, 1.0);
        });
      }
    }
    
    _lastDragPosition = dx;
    _lastDragTime = currentTime;
    
    widget.onChanged(newValue);
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    setState(() {
      _isDragging = true;
    });
    _updateValueFromPosition(details.localPosition.dx, constraints.maxWidth);
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    _updateValueFromPosition(details.localPosition.dx, constraints.maxWidth);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragVelocity = 0.0;
      _lastDragTime = 0;
    });
    
    // Bounce the stretch back to normal
    _stretchController.reverse();
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
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ]
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedBuilder(
              animation: Listenable.merge([_wobbleController, _stretchController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _LiquidSliderPainter(
                    value: widget.value,
                    color: widget.liquidColor,
                    wobbleValue: _wobbleController.value,
                    stretchValue: _stretchController.value,
                    dragVelocity: _dragVelocity,
                    isDragging: _isDragging,
                  ),
                );
              }
            ),
          ),
        );
      }
    );
  }
}

class _LiquidSliderPainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color color;
  final double wobbleValue; // 0.0 to 1.0 (continuous animation)
  final double stretchValue; // 0.0 to 1.0 (based on drag speed)
  final double dragVelocity; // Negative = dragging left, Positive = dragging right
  final bool isDragging;

  _LiquidSliderPainter({
    required this.value,
    required this.color,
    required this.wobbleValue,
    required this.stretchValue,
    required this.dragVelocity,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final double fillWidth = size.width * value;
    
    // If the slider is at 0, draw nothing
    if (fillWidth <= 0) return;
    
    final Path path = Path();
    
    // Start at top left
    path.moveTo(0, 0);
    
    // If we aren't dragging, the edge just has a gentle organic wobble
    // If we are dragging, the edge stretches and leans in the direction of the drag
    
    // Base X position of the edge
    final double edgeX = fillWidth;
    
    // How much the liquid stretches forward or backward based on velocity
    // Velocity is capped at +/- 5.0, so this stretches up to 40px
    final double dynamicStretch = dragVelocity * 8.0; 
    
    // We construct the vertical edge of the liquid.
    // We use a cubic bezier curve to make it look like a bulging droplet
    
    // Top corner of the fill
    path.lineTo(edgeX, 0);
    
    // The curve. We calculate control points.
    // If dragging right (positive stretch), the center bulges to the right.
    // If dragging left (negative stretch), the center bulges to the left.
    // The wobble adds a continuous breathing effect.
    
    final double wobbleOffset = math.sin(wobbleValue * 2 * math.pi) * 5.0;
    
    // We want the bulge to happen in the middle of the height
    final double middleY = size.height / 2;
    
    // Total horizontal offset for the center point
    final double centerOffsetX = edgeX + dynamicStretch + (isDragging ? 0 : wobbleOffset);
    
    path.cubicTo(
      edgeX + (dynamicStretch * 0.5), size.height * 0.2, // Control Point 1 (top curve)
      centerOffsetX, size.height * 0.3, // Control Point 2 (entering the bulge)
      centerOffsetX, middleY, // Center point of the bulge
    );
    
    path.cubicTo(
      centerOffsetX, size.height * 0.7, // Control Point 1 (leaving the bulge)
      edgeX + (dynamicStretch * 0.5), size.height * 0.8, // Control Point 2 (bottom curve)
      edgeX, size.height, // Target: bottom corner of the fill
    );
    
    // Draw back to bottom left
    path.lineTo(0, size.height);
    
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Draw the Thumb (the circle indicator)
    final Paint thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final Paint thumbShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
    // Thumb position tracks the center of the bulge!
    final Offset thumbCenter = Offset(centerOffsetX.clamp(15.0, size.width - 15.0), middleY);
    
    canvas.drawCircle(thumbCenter, 15, thumbShadowPaint); // Shadow
    canvas.drawCircle(thumbCenter, 12, thumbPaint); // Inner circle
  }

  @override
  bool shouldRepaint(covariant _LiquidSliderPainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.wobbleValue != wobbleValue ||
           oldDelegate.stretchValue != stretchValue ||
           oldDelegate.dragVelocity != dragVelocity ||
           oldDelegate.isDragging != isDragging;
  }
}
