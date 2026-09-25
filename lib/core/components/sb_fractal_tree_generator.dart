import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbFractalTreeGenerator extends StatefulWidget {
  final int maxDepth;
  final double trunkLength;
  final double branchAngle;
  final double lengthDecay;
  final Color trunkColor;
  final Color leafColor;
  final Color backgroundColor;

  const SbFractalTreeGenerator({
    super.key,
    this.maxDepth = 9,
    this.trunkLength = 120.0,
    this.branchAngle = math.pi / 5,
    this.lengthDecay = 0.67,
    this.trunkColor = const Color(0xFF5D4037),
    this.leafColor = const Color(0xFF4CAF50),
    this.backgroundColor = const Color(0xFFF5F5F6),
  });

  @override
  State<SbFractalTreeGenerator> createState() => _SbFractalTreeGeneratorState();
}

class _SbFractalTreeGeneratorState extends State<SbFractalTreeGenerator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // We allow the user to dynamically bend the tree using drag gestures
  double _windAngle = 0.0;
  
  @override
  void initState() {
    super.initState();
    // The animation controller is used to "grow" the tree when it first appears
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Horizontal drag bends the tree like wind
      // Details.delta.dx is mapped to radians
      _windAngle += details.delta.dx * 0.01;
      
      // Clamp the wind so the tree doesn't break
      _windAngle = _windAngle.clamp(-math.pi / 3, math.pi / 3);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // When released, the wind slowly dies down to 0
    // We could use an animation controller for this, but for simplicity we'll just snap it back
    // or leave it bent. Let's animate it back to 0.
    final double startAngle = _windAngle;
    
    AnimationController springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    Animation<double> springAnim = Tween<double>(begin: startAngle, end: 0.0).animate(
      CurvedAnimation(parent: springController, curve: Curves.elasticOut)
    );
    
    springAnim.addListener(() {
      setState(() {
        _windAngle = springAnim.value;
      });
    });
    
    springController.forward().then((_) => springController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _onPanEnd(DragEndDetails()),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: widget.backgroundColor,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _FractalTreePainter(
                growthProgress: _controller.value,
                windAngle: _windAngle,
                maxDepth: widget.maxDepth,
                trunkLength: widget.trunkLength,
                branchAngle: widget.branchAngle,
                lengthDecay: widget.lengthDecay,
                trunkColor: widget.trunkColor,
                leafColor: widget.leafColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FractalTreePainter extends CustomPainter {
  final double growthProgress;
  final double windAngle;
  final int maxDepth;
  final double trunkLength;
  final double branchAngle;
  final double lengthDecay;
  final Color trunkColor;
  final Color leafColor;

  _FractalTreePainter({
    required this.growthProgress,
    required this.windAngle,
    required this.maxDepth,
    required this.trunkLength,
    required this.branchAngle,
    required this.lengthDecay,
    required this.trunkColor,
    required this.leafColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Start drawing from the bottom center of the screen
    final Offset startPoint = Offset(size.width / 2, size.height);
    
    // We use a mathematical recursive function to draw the tree
    _drawBranch(
      canvas: canvas,
      start: startPoint,
      length: trunkLength * growthProgress, // The tree "grows" from 0 to full length
      angle: -math.pi / 2, // -90 degrees (pointing straight up)
      depth: maxDepth,
    );
  }

  void _drawBranch({
    required Canvas canvas,
    required Offset start,
    required double length,
    required double angle,
    required int depth,
  }) {
    if (depth == 0) {
      // Draw a leaf at the end of the final branches
      final Paint leafPaint = Paint()
        ..color = leafColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(start, 3.0, leafPaint);
      return;
    }

    // Thickness decreases as we go higher up the tree
    final double thickness = (depth * 1.5).clamp(1.0, 15.0);
    
    // Color interpolates from trunk to leaf as we go higher
    final double colorProgress = 1.0 - (depth / maxDepth);
    final Color branchColor = Color.lerp(trunkColor, leafColor.withValues(alpha: 0.6), colorProgress)!;

    final Paint branchPaint = Paint()
      ..color = branchColor
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    // The wind effect applies more strongly to the thinner branches at the top
    final double flexibility = 1.0 - (depth / maxDepth);
    final double currentAngle = angle + (windAngle * flexibility);

    // Calculate the end point of this branch using trigonometry
    final Offset end = Offset(
      start.dx + math.cos(currentAngle) * length,
      start.dy + math.sin(currentAngle) * length,
    );

    // Draw this branch
    canvas.drawLine(start, end, branchPaint);

    // If we're still growing, we stagger the child branches so they sprout sequentially
    // rather than all at once.
    final double activationThreshold = 1.0 - (depth / maxDepth);
    if (growthProgress > activationThreshold) {
      // Calculate how far along the child branch growth is
      final double childGrowthScale = (growthProgress - activationThreshold) / (1.0 - activationThreshold);
      final double childLength = length * lengthDecay * childGrowthScale.clamp(0.0, 1.0);
      
      if (childLength > 1.0) {
        // Recursive call: Draw Right Branch
        _drawBranch(
          canvas: canvas,
          start: end,
          length: childLength,
          angle: currentAngle + branchAngle,
          depth: depth - 1,
        );

        // Recursive call: Draw Left Branch
        _drawBranch(
          canvas: canvas,
          start: end,
          length: childLength,
          angle: currentAngle - branchAngle,
          depth: depth - 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FractalTreePainter oldDelegate) {
    return oldDelegate.growthProgress != growthProgress || oldDelegate.windAngle != windAngle;
  }
}
