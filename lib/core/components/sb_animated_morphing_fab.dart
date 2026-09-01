import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbAnimatedMorphingFab extends StatefulWidget {
  final IconData icon;
  final Widget expandedContent;
  final Color backgroundColor;
  final Color foregroundColor;
  final double fabSize;
  final double expandedWidth;
  final double expandedHeight;

  const SbAnimatedMorphingFab({
    super.key,
    required this.icon,
    required this.expandedContent,
    this.backgroundColor = const Color(0xFF6200EE),
    this.foregroundColor = Colors.white,
    this.fabSize = 64.0,
    this.expandedWidth = 300.0,
    this.expandedHeight = 250.0,
  });

  @override
  State<SbAnimatedMorphingFab> createState() => _SbAnimatedMorphingFabState();
}

class _SbAnimatedMorphingFabState extends State<SbAnimatedMorphingFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

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

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = Curves.fastLinearToSlowEaseIn.transform(_controller.value);

        final double currentWidth = widget.fabSize + (widget.expandedWidth - widget.fabSize) * t;
        final double currentHeight = widget.fabSize + (widget.expandedHeight - widget.fabSize) * t;
        final double currentRadius = (widget.fabSize / 2) * (1.0 - t) + 16.0 * t;

        return Stack(
          alignment: Alignment.bottomRight, 
          children: [
            GestureDetector(
              onTap: _isExpanded ? null : _toggle,
              child: Container(
                width: currentWidth,
                height: currentHeight,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(currentRadius),
                  boxShadow: [
                    BoxShadow(
                      color: widget.backgroundColor.withValues(alpha: 0.3),
                      blurRadius: 10 + (10 * t),
                      offset: const Offset(0, 5),
                    )
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(currentRadius),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Transform.rotate(
                          angle: t * math.pi / 2, 
                          child: Opacity(
                            opacity: (1.0 - (t * 2)).clamp(0.0, 1.0),
                            child: Icon(
                              widget.icon,
                              color: widget.foregroundColor,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      
                      if (_controller.value > 0.0)
                        Align(
                          alignment: Alignment.topLeft,
                          child: Opacity(
                            opacity: ((t - 0.5) * 2).clamp(0.0, 1.0),
                            child: SizedBox(
                              width: widget.expandedWidth,
                              height: widget.expandedHeight,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: widget.expandedContent),
                                  
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: Icon(Icons.close, color: widget.foregroundColor.withValues(alpha: 0.7)),
                                      onPressed: _toggle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
