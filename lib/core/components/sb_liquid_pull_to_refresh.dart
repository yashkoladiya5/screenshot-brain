import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbLiquidPullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? liquidColor;
  final Color? indicatorColor;

  const SbLiquidPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.liquidColor,
    this.indicatorColor,
  });

  @override
  State<SbLiquidPullToRefresh> createState() => _SbLiquidPullToRefreshState();
}

class _SbLiquidPullToRefreshState extends State<SbLiquidPullToRefresh> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _pullDistance = 0.0;
  bool _isRefreshing = false;
  
  final double _maxPullDistance = 120.0;
  final double _refreshThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
        // Pulling down past top
        setState(() {
          _pullDistance = (_pullDistance - notification.scrollDelta!).clamp(0.0, _maxPullDistance);
        });
      } else if (_pullDistance > 0 && notification.scrollDelta! > 0) {
        // Pushing back up
        setState(() {
          _pullDistance = (_pullDistance - notification.scrollDelta!).clamp(0.0, _maxPullDistance);
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_pullDistance >= _refreshThreshold) {
        _startRefresh();
      } else {
        _animateBackToZero();
      }
    }
    return false;
  }

  void _startRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    
    // Animate to refresh position
    _controller.value = _pullDistance / _maxPullDistance;
    await _controller.animateTo(_refreshThreshold / _maxPullDistance, curve: Curves.easeOutBack);
    
    // Wait for the actual refresh task
    await widget.onRefresh();
    
    if (mounted) {
      // Animate away
      await _controller.animateTo(0.0, curve: Curves.easeIn);
      setState(() {
        _pullDistance = 0.0;
        _isRefreshing = false;
      });
    }
  }

  void _animateBackToZero() {
    _controller.value = _pullDistance / _maxPullDistance;
    _controller.animateTo(0.0, curve: Curves.easeOut).then((_) {
      if (mounted) {
        setState(() {
          _pullDistance = 0.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bg = widget.liquidColor ?? colorScheme.primaryContainer;
    final fg = widget.indicatorColor ?? colorScheme.primary;

    final displayPull = _isRefreshing ? _controller.value * _maxPullDistance : _pullDistance;
    final curveIntensity = displayPull / _maxPullDistance;

    return Stack(
      children: [
        // Liquid Background
        if (displayPull > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: displayPull,
            child: ClipPath(
              clipper: _LiquidClipper(curveIntensity: curveIntensity),
              child: Container(
                color: bg,
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20 * curveIntensity),
                  child: Transform.rotate(
                    angle: curveIntensity * math.pi * 2,
                    child: _isRefreshing 
                        ? SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: fg, strokeWidth: 3)
                          )
                        : Icon(Icons.refresh_rounded, color: fg, size: 28 * curveIntensity),
                  ),
                ),
              ),
            ),
          ),
          
        // Content
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: Transform.translate(
            offset: Offset(0, displayPull),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _LiquidClipper extends CustomClipper<Path> {
  final double curveIntensity;

  _LiquidClipper({required this.curveIntensity});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - (40 * curveIntensity));
    
    // Draw bezier curve for the bottom liquid drop effect
    path.quadraticBezierTo(
      size.width / 2, 
      size.height + (20 * curveIntensity), // The drop goes down
      size.width, 
      size.height - (40 * curveIntensity),
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _LiquidClipper oldClipper) {
    return oldClipper.curveIntensity != curveIntensity;
  }
}
