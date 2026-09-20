import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbLiquidBottomNav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<IconData> icons;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;

  const SbLiquidBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.icons,
    this.backgroundColor = Colors.white,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<SbLiquidBottomNav> createState() => _SbLiquidBottomNavState();
}

class _SbLiquidBottomNavState extends State<SbLiquidBottomNav> with TickerProviderStateMixin {
  late AnimationController _controller;
  late double _previousIndex;
  
  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(SbLiquidBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex.toDouble();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.transparent, // Important so shadow works behind curve
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The background with the liquid dip
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Interpolate between previous and current selected index
              final double currentIndex = _previousIndex + 
                (widget.selectedIndex - _previousIndex) * 
                Curves.easeInOutBack.transform(_controller.value);

              return CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 80),
                painter: _LiquidNavPainter(
                  backgroundColor: widget.backgroundColor,
                  currentIndex: currentIndex,
                  itemCount: widget.icons.length,
                ),
              );
            },
          ),
          
          // The Icons and the floating active circle
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(widget.icons.length, (index) {
                final bool isSelected = index == widget.selectedIndex;
                
                return GestureDetector(
                  onTap: () {
                    if (!isSelected) {
                      widget.onItemSelected(index);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / widget.icons.length,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The floating active circle that goes into the dip
                        if (isSelected)
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              // We bounce the circle slightly when it arrives
                              final double scale = _controller.isAnimating 
                                  ? 1.0 - (math.sin(_controller.value * math.pi) * 0.2)
                                  : 1.0;
                              return Transform.translate(
                                // Push it up slightly above the bar
                                offset: const Offset(0, -20),
                                child: Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.activeColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: widget.activeColor.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        )
                                      ]
                                    ),
                                    child: Icon(
                                      widget.icons[index],
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }
                          ),
                          
                        // The inactive icon that disappears when selected
                        if (!isSelected)
                          Icon(
                            widget.icons[index],
                            color: widget.inactiveColor,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidNavPainter extends CustomPainter {
  final Color backgroundColor;
  final double currentIndex;
  final int itemCount;

  _LiquidNavPainter({
    required this.backgroundColor,
    required this.currentIndex,
    required this.itemCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
      
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final itemWidth = size.width / itemCount;
    // The exact X center of the currently selected item
    final centerX = (itemWidth * currentIndex) + (itemWidth / 2);
    
    final Path path = Path();
    path.moveTo(0, 0); // Start top left
    
    // Draw line to just before the curve starts
    final double curveWidth = itemWidth * 0.8; 
    final double startCurveX = centerX - (curveWidth / 2);
    final double endCurveX = centerX + (curveWidth / 2);
    
    // If the curve start is somehow negative due to bounce, we handle it organically
    path.lineTo(startCurveX.clamp(0.0, size.width), 0);
    
    // Draw the liquid dip using a cubic bezier curve
    // The dip goes downwards into the navbar (so positive Y)
    final double dipDepth = 35.0;
    
    path.cubicTo(
      startCurveX + (curveWidth * 0.2), 0, // Control point 1 (pull down smoothly)
      startCurveX + (curveWidth * 0.2), dipDepth, // Control point 2 (bottom curve)
      centerX, dipDepth, // Target point (exact center bottom of dip)
    );
    
    path.cubicTo(
      endCurveX - (curveWidth * 0.2), dipDepth, // Control point 1
      endCurveX - (curveWidth * 0.2), 0, // Control point 2
      endCurveX.clamp(0.0, size.width), 0, // Target point (back to top edge)
    );
    
    path.lineTo(size.width, 0); // Line to top right
    path.lineTo(size.width, size.height); // Down to bottom right
    path.lineTo(0, size.height); // Across to bottom left
    path.close(); // Back to top left

    // Draw shadow first
    canvas.drawPath(path, shadowPaint);
    // Fill the shape
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidNavPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}
