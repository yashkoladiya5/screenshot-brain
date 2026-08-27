import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbRadialMenuItem {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const SbRadialMenuItem({
    required this.icon,
    required this.onTap,
    this.color,
  });
}

class SbAnimatedRadialMenu extends StatefulWidget {
  final List<SbRadialMenuItem> items;
  final IconData mainIcon;
  final Color? mainColor;
  final double radius;
  final double buttonSize;

  const SbAnimatedRadialMenu({
    super.key,
    required this.items,
    this.mainIcon = Icons.add,
    this.mainColor,
    this.radius = 100.0,
    this.buttonSize = 56.0,
  }) : assert(items.length > 0);

  @override
  State<SbAnimatedRadialMenu> createState() => _SbAnimatedRadialMenuState();
}

class _SbAnimatedRadialMenuState extends State<SbAnimatedRadialMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
    });
    
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainBtnColor = widget.mainColor ?? theme.colorScheme.primary;

    return SizedBox(
      width: widget.radius * 2 + widget.buttonSize,
      height: widget.radius * 2 + widget.buttonSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Render child items
          ...List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            // Calculate angle: evenly distributed across a full circle
            final double angle = (index * (2 * math.pi / widget.items.length)) - (math.pi / 2);
            
            return _RadialMenuButton(
              controller: _controller,
              angle: angle,
              radius: widget.radius,
              icon: item.icon,
              color: item.color ?? theme.colorScheme.secondary,
              onTap: () {
                _toggleMenu();
                item.onTap();
              },
            );
          }),
          
          // Render main toggle button on top
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Rotate the main button slightly when open (e.g. turning + into x)
              return Transform.rotate(
                angle: _controller.value * math.pi / 4,
                child: FloatingActionButton(
                  elevation: 8,
                  backgroundColor: mainBtnColor,
                  onPressed: _toggleMenu,
                  child: Icon(
                    widget.mainIcon,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RadialMenuButton extends StatelessWidget {
  final AnimationController controller;
  final double angle;
  final double radius;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RadialMenuButton({
    required this.controller,
    required this.angle,
    required this.radius,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Animate out from the center based on controller value
        // Use a spring/elastic curve for bounce
        final CurvedAnimation curve = CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutBack,
        );
        
        final double currentRadius = curve.value * radius;
        final double dx = math.cos(angle) * currentRadius;
        final double dy = math.sin(angle) * currentRadius;
        
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: curve.value,
            child: Opacity(
              opacity: controller.value.clamp(0.0, 1.0),
              child: FloatingActionButton.small(
                heroTag: null, // Prevent hero tag collisions
                elevation: 4,
                backgroundColor: color,
                onPressed: onTap,
                child: Icon(icon, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
