import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbCircularMenuItem {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;

  const SbCircularMenuItem({
    required this.icon,
    required this.onTap,
    this.color,
    this.iconColor,
  });
}

class SbCircularMenu extends StatefulWidget {
  final List<SbCircularMenuItem> items;
  final double radius;
  final Color? toggleButtonColor;
  final Color? toggleButtonIconColor;
  final double itemSize;
  final double toggleSize;
  
  const SbCircularMenu({
    super.key,
    required this.items,
    this.radius = 100.0,
    this.toggleButtonColor,
    this.toggleButtonIconColor,
    this.itemSize = 48.0,
    this.toggleSize = 56.0,
  }) : assert(items.length > 0);

  @override
  State<SbCircularMenu> createState() => _SbCircularMenuState();
}

class _SbCircularMenuState extends State<SbCircularMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toggleColor = widget.toggleButtonColor ?? theme.colorScheme.primary;
    final toggleIconColor = widget.toggleButtonIconColor ?? theme.colorScheme.onPrimary;
    
    // We create a bounding box large enough to hold the expanded menu
    final double boxSize = (widget.radius + widget.itemSize) * 2;

    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Items
          ...List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            final itemBg = item.color ?? theme.colorScheme.surface;
            final itemFg = item.iconColor ?? theme.colorScheme.primary;
            
            // Calculate angle. If only 1 item, put it on top.
            // If multiple, spread them evenly in a circle.
            // Note: subtracting pi/2 to start at the top (12 o'clock)
            final double angle = widget.items.length == 1 
                ? -math.pi / 2 
                : -math.pi / 2 + (index * (2 * math.pi / widget.items.length));

            return AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                // Calculate position based on radius and animation progress
                final double currentRadius = widget.radius * _animation.value;
                final double dx = math.cos(angle) * currentRadius;
                final double dy = math.sin(angle) * currentRadius;
                
                // Add staggered scale and fade effect
                final double itemProgress = (_animation.value - (index * 0.1)).clamp(0.0, 1.0);
                
                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(
                    scale: itemProgress,
                    child: Opacity(
                      opacity: itemProgress,
                      child: child,
                    ),
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  _toggleMenu();
                  item.onTap();
                },
                child: Container(
                  width: widget.itemSize,
                  height: widget.itemSize,
                  decoration: BoxDecoration(
                    color: itemBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Icon(
                    item.icon,
                    color: itemFg,
                    size: widget.itemSize * 0.5,
                  ),
                ),
              ),
            );
          }),
          
          // The Central Toggle Button
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value * math.pi * 0.75, // Rotate 135 degrees to form an 'X'
                child: child,
              );
            },
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                width: widget.toggleSize,
                height: widget.toggleSize,
                decoration: BoxDecoration(
                  color: toggleColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: toggleColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: toggleIconColor,
                  size: widget.toggleSize * 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
