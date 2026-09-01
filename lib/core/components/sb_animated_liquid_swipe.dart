import 'package:flutter/material.dart';

class SbAnimatedLiquidSwipe extends StatefulWidget {
  final Widget backgroundPage;
  final Widget foregroundPage;
  final double revealThreshold;

  const SbAnimatedLiquidSwipe({
    super.key,
    required this.backgroundPage,
    required this.foregroundPage,
    this.revealThreshold = 0.5, 
  });

  @override
  State<SbAnimatedLiquidSwipe> createState() => _SbAnimatedLiquidSwipeState();
}

class _SbAnimatedLiquidSwipeState extends State<SbAnimatedLiquidSwipe> with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  double _touchY = 0.0;
  bool _isDragging = false;
  bool _isRevealed = false;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _springController.addListener(() {
      setState(() {
        _dragPosition = _springAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isRevealed) return;
    setState(() {
      _isDragging = true;
      _touchY = details.localPosition.dy;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isRevealed || !_isDragging) return;
    
    setState(() {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      _dragPosition = renderBox.size.width - details.localPosition.dx;
      _touchY = details.localPosition.dy;
      
      if (_dragPosition < 0) _dragPosition = 0;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isRevealed || !_isDragging) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final screenWidth = renderBox.size.width;

    setState(() {
      _isDragging = false;
    });

    if (_dragPosition > screenWidth * widget.revealThreshold) {
      _springAnimation = Tween<double>(begin: _dragPosition, end: screenWidth * 1.5).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic)
      );
      _springController.forward(from: 0.0).then((_) {
        setState(() {
          _isRevealed = true;
        });
      });
    } else {
      _springAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.elasticOut)
      );
      _springController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          widget.backgroundPage,
          
          if (!_isRevealed)
            ClipPath(
              clipper: _LiquidClipper(
                dragDistance: _dragPosition,
                touchY: _touchY,
              ),
              child: widget.foregroundPage,
            ),
        ],
      ),
    );
  }
}

class _LiquidClipper extends CustomClipper<Path> {
  final double dragDistance;
  final double touchY;

  _LiquidClipper({
    required this.dragDistance,
    required this.touchY,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    
    if (dragDistance == 0) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    final double rightEdge = size.width;
    final double peakX = rightEdge - dragDistance;
    final double peakY = touchY;

    final double curveSpread = 150.0 + (dragDistance * 0.5); 

    path.lineTo(0, size.height); 
    path.lineTo(rightEdge, size.height); 
    
    path.lineTo(rightEdge, peakY + curveSpread);

    path.quadraticBezierTo(
      rightEdge, peakY, 
      peakX, peakY 
    );

    path.quadraticBezierTo(
      rightEdge, peakY, 
      rightEdge, peakY - curveSpread 
    );

    path.lineTo(rightEdge, 0); 
    path.close(); 

    return path;
  }

  @override
  bool shouldReclip(covariant _LiquidClipper oldClipper) {
    return oldClipper.dragDistance != dragDistance || oldClipper.touchY != touchY;
  }
}
