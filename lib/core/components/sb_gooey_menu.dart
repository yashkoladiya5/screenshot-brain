import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../design/tokens.dart';

class SbGooeyMenuItem {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const SbGooeyMenuItem({
    required this.icon,
    required this.onTap,
    this.color,
  });
}

class SbGooeyMenu extends StatefulWidget {
  final List<SbGooeyMenuItem> items;
  final IconData mainIcon;
  final Color? mainColor;
  final double radius;
  final double buttonSize;

  const SbGooeyMenu({
    super.key,
    required this.items,
    this.mainIcon = Icons.add,
    this.mainColor,
    this.radius = 80.0,
    this.buttonSize = 56.0,
  }) : assert(items.length > 0);

  @override
  State<SbGooeyMenu> createState() => _SbGooeyMenuState();
}

class _SbGooeyMenuState extends State<SbGooeyMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
          // 1. The Gooey Background filter
          // This applies a blur and then sharpens the alpha channel to create a liquid merge effect
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      1, 0, 0, 0, 0,
                      0, 1, 0, 0, 0,
                      0, 0, 1, 0, 0,
                      0, 0, 0, 20, -1000, // Alpha thresholding (sharpens blurred edges)
                    ]),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The central blob
                        Container(
                          width: widget.buttonSize,
                          height: widget.buttonSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mainBtnColor,
                          ),
                        ),
                        
                        // The escaping child blobs
                        ...List.generate(widget.items.length, (index) {
                          // Angle based on items
                          final double angle = (index * (2 * math.pi / widget.items.length)) - (math.pi / 2);
                          
                          // Use an elastic curve for the gooey stretch
                          final CurvedAnimation curve = CurvedAnimation(
                            parent: _controller,
                            curve: Interval(
                              (index / widget.items.length) * 0.5, // Stagger start times
                              1.0,
                              curve: Curves.elasticOut,
                            ),
                          );
                          
                          final double currentRadius = curve.value * widget.radius;
                          final double dx = math.cos(angle) * currentRadius;
                          final double dy = math.sin(angle) * currentRadius;
                          
                          return Transform.translate(
                            offset: Offset(dx, dy),
                            child: Container(
                              width: widget.buttonSize * 0.8,
                              height: widget.buttonSize * 0.8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.items[index].color ?? theme.colorScheme.secondary,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // 2. The Interactive Icons (no blur, positioned exactly over the blobs)
          ...List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            final double angle = (index * (2 * math.pi / widget.items.length)) - (math.pi / 2);
            
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final CurvedAnimation curve = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(
                    (index / widget.items.length) * 0.5,
                    1.0,
                    curve: Curves.elasticOut,
                  ),
                );
                
                final double currentRadius = curve.value * widget.radius;
                final double dx = math.cos(angle) * currentRadius;
                final double dy = math.sin(angle) * currentRadius;
                
                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(
                    scale: curve.value.clamp(0.0, 1.0), // Don't let icon get too big during elastic bounce
                    child: Opacity(
                      opacity: curve.value.clamp(0.0, 1.0),
                      child: GestureDetector(
                        onTap: () {
                          _toggleMenu();
                          item.onTap();
                        },
                        child: SizedBox(
                          width: widget.buttonSize * 0.8,
                          height: widget.buttonSize * 0.8,
                          child: Icon(item.icon, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          
          // 3. Main Center Icon
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * math.pi / 4, // Rotate to make X
                child: GestureDetector(
                  onTap: _toggleMenu,
                  child: Container(
                    width: widget.buttonSize,
                    height: widget.buttonSize,
                    color: Colors.transparent, // Capture taps
                    child: Icon(
                      widget.mainIcon,
                      color: theme.colorScheme.onPrimary,
                    ),
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
