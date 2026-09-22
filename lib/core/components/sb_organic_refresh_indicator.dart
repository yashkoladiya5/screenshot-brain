import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbOrganicRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color liquidColor;
  final Color backgroundColor;
  final double height;
  final double animSpeedFactor;

  const SbOrganicRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.liquidColor = const Color(0xFF3498DB),
    this.backgroundColor = Colors.white,
    this.height = 120.0,
    this.animSpeedFactor = 2.0,
  });

  @override
  State<SbOrganicRefreshIndicator> createState() => _SbOrganicRefreshIndicatorState();
}

class _SbOrganicRefreshIndicatorState extends State<SbOrganicRefreshIndicator> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pullController;
  
  double _pullDistance = 0.0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1500 / widget.animSpeedFactor).round()),
    )..repeat();

    _pullController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pullController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isRefreshing) return false;

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels < 0) {
        setState(() {
          _pullDistance = (notification.metrics.pixels.abs() * 0.5).clamp(0.0, widget.height);
        });
      } else if (_pullDistance > 0) {
        setState(() {
          _pullDistance = 0.0;
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_pullDistance >= widget.height * 0.8) {
        _triggerRefresh();
      } else {
        _snapBack();
      }
    }
    return false;
  }

  Future<void> _triggerRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    
    _pullController.duration = const Duration(milliseconds: 200);
    
    final animation = Tween<double>(begin: _pullDistance, end: widget.height).animate(
      CurvedAnimation(parent: _pullController, curve: Curves.easeOutCubic)
    );
    
    animation.addListener(() {
      setState(() {
        _pullDistance = animation.value;
      });
    });
    
    await _pullController.forward(from: 0.0);
    
    await widget.onRefresh();
    
    await _snapBack();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _snapBack() async {
    _pullController.duration = const Duration(milliseconds: 400);
    
    final animation = Tween<double>(begin: _pullDistance, end: 0.0).animate(
      CurvedAnimation(parent: _pullController, curve: Curves.elasticOut)
    );
    
    animation.addListener(() {
      setState(() {
        _pullDistance = animation.value;
      });
    });
    
    await _pullController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: widget.height,
          child: Container(color: widget.backgroundColor),
        ),
        
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _pullDistance,
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                painter: _LiquidWavePainter(
                  animationValue: _waveController.value,
                  color: widget.liquidColor,
                  waveHeight: (_pullDistance / widget.height) * 20.0, 
                ),
              );
            }
          ),
        ),
        
        if (_pullDistance > 0)
          Positioned(
            top: (_pullDistance / 2) - 15, 
            left: MediaQuery.of(context).size.width / 2 - 15,
            child: Opacity(
              opacity: (_pullDistance / widget.height).clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: _pullDistance * 0.05,
                child: const Icon(Icons.refresh, color: Colors.white, size: 30),
              ),
            ),
          ),

        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: Transform.translate(
            offset: Offset(0, _pullDistance),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double waveHeight;

  _LiquidWavePainter({
    required this.animationValue,
    required this.color,
    required this.waveHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0); 
    
    for (double i = 0; i <= size.width; i++) {
      final wave1 = math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * waveHeight;
      final wave2 = math.cos((i / size.width * 3 * math.pi) + (animationValue * 4 * math.pi)) * (waveHeight * 0.5);
      
      path.lineTo(i, size.height + wave1 + wave2);
    }
    
    path.lineTo(size.width, 0); 
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color ||
           oldDelegate.waveHeight != waveHeight;
  }
}
