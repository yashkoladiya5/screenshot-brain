import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbAnimatedLiquidRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color liquidColor;
  final Color backgroundColor;

  const SbAnimatedLiquidRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.liquidColor = const Color(0xFF3498DB),
    this.backgroundColor = Colors.white,
  });

  @override
  State<SbAnimatedLiquidRefresh> createState() => _SbAnimatedLiquidRefreshState();
}

class _SbAnimatedLiquidRefreshState extends State<SbAnimatedLiquidRefresh> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  final double _maxDrag = 150.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isRefreshing) return false;

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels < 0) {
        setState(() {
          _dragOffset = (-notification.metrics.pixels).clamp(0.0, _maxDrag);
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragOffset > _maxDrag * 0.7) {
        _startRefresh();
      } else {
        setState(() {
          _dragOffset = 0.0;
        });
      }
    }
    return false;
  }

  Future<void> _startRefresh() async {
    setState(() {
      _isRefreshing = true;
      _dragOffset = _maxDrag * 0.5;
    });
    
    _controller.repeat();
    
    await widget.onRefresh();
    
    if (mounted) {
      _controller.stop();
      setState(() {
        _isRefreshing = false;
        _dragOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: widget.backgroundColor,
          width: double.infinity,
          height: double.infinity,
        ),
        
        if (_dragOffset > 0 || _isRefreshing)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _LiquidPainter(
                  dragOffset: _dragOffset,
                  animationValue: _isRefreshing ? _controller.value : 0.0,
                  color: widget.liquidColor,
                  isRefreshing: _isRefreshing,
                ),
                child: SizedBox(
                  height: _dragOffset,
                  width: double.infinity,
                  child: Center(
                    child: _isRefreshing 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Icon(
                            Icons.arrow_downward, 
                            color: Colors.white.withValues(alpha: (_dragOffset / _maxDrag).clamp(0.0, 1.0)),
                          ),
                  ),
                ),
              );
            }
          ),

        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double dragOffset;
  final double animationValue;
  final Color color;
  final bool isRefreshing;

  _LiquidPainter({
    required this.dragOffset,
    required this.animationValue,
    required this.color,
    required this.isRefreshing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, dragOffset * 0.5);

    if (isRefreshing) {
      for (double i = 0; i <= size.width; i++) {
        final wave = math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * 10;
        path.lineTo(i, (dragOffset * 0.5) + wave);
      }
    } else {
      final double stretch = dragOffset * 0.5;
      path.quadraticBezierTo(
        size.width / 2, dragOffset * 0.5 + stretch, 
        size.width, dragOffset * 0.5
      );
    }

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.dragOffset != dragOffset || 
           oldDelegate.animationValue != animationValue ||
           oldDelegate.isRefreshing != isRefreshing;
  }
}
