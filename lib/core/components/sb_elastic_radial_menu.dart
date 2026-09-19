import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbElasticRadialMenu extends StatefulWidget {
  final List<Widget> menuItems;
  final Widget centerButton;
  final double radius;
  final Duration animationDuration;
  final double centerButtonSize;
  final double menuItemSize;
  final Color backgroundColor;

  const SbElasticRadialMenu({
    super.key,
    required this.menuItems,
    required this.centerButton,
    this.radius = 120.0,
    this.animationDuration = const Duration(milliseconds: 400),
    this.centerButtonSize = 70.0,
    this.menuItemSize = 50.0,
    this.backgroundColor = Colors.transparent,
  });

  @override
  State<SbElasticRadialMenu> createState() => _SbElasticRadialMenuState();
}

class _SbElasticRadialMenuState extends State<SbElasticRadialMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      width: (widget.radius * 2) + widget.menuItemSize,
      height: (widget.radius * 2) + widget.menuItemSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            
          ...List.generate(widget.menuItems.length, (index) {
            final double angle = (2 * math.pi / widget.menuItems.length) * index;
            final double adjustedAngle = angle - (math.pi / 2);
            
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double curvedValue = Curves.elasticOut.transform(_controller.value);
                
                final double currentRadius = widget.radius * curvedValue;
                final double x = currentRadius * math.cos(adjustedAngle);
                final double y = currentRadius * math.sin(adjustedAngle);
                
                final double opacity = (_controller.value * 2).clamp(0.0, 1.0);
                
                final double scale = (_controller.value * 1.5).clamp(0.0, 1.0);

                return Transform.translate(
                  offset: Offset(x, y),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: SizedBox(
                        width: widget.menuItemSize,
                        height: widget.menuItemSize,
                        child: widget.menuItems[index],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          GestureDetector(
            onTap: _toggleMenu,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double rotation = _controller.value * (math.pi / 4);
                
                return Transform.rotate(
                  angle: rotation,
                  child: SizedBox(
                    width: widget.centerButtonSize,
                    height: widget.centerButtonSize,
                    child: widget.centerButton,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
