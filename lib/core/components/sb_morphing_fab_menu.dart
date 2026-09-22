import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbMorphingFabMenu extends StatefulWidget {
  final List<IconData> menuIcons;
  final List<VoidCallback> onMenuPressed;
  final IconData primaryIcon;
  final Color primaryColor;
  final Color menuColor;

  const SbMorphingFabMenu({
    super.key,
    required this.menuIcons,
    required this.onMenuPressed,
    this.primaryIcon = Icons.add,
    this.primaryColor = const Color(0xFF6200EA),
    this.menuColor = const Color(0xFF3700B3),
  }) : assert(menuIcons.length == onMenuPressed.length, 'Icons and callbacks must match');

  @override
  State<SbMorphingFabMenu> createState() => _SbMorphingFabMenuState();
}

class _SbMorphingFabMenuState extends State<SbMorphingFabMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

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
    return SizedBox(
      width: 70, // Fixed width to accommodate the FAB
      // Height needs to be large enough to hold all the expanded items
      height: 70.0 + (widget.menuIcons.length * 70.0),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Render the menu items first so they are behind the main FAB
          ...List.generate(widget.menuIcons.length, (index) {
            return _AnimatedMenuItem(
              controller: _controller,
              index: index,
              totalItems: widget.menuIcons.length,
              icon: widget.menuIcons[index],
              color: widget.menuColor,
              onPressed: () {
                _toggle();
                widget.onMenuPressed[index]();
              },
            );
          }),

          // The main morphing FAB
          GestureDetector(
            onTap: _toggle,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Morphing shape animation:
                // From Circle (borderRadius 35) to Rounded Rectangle (borderRadius 16)
                final double borderRadius = Tween<double>(begin: 35.0, end: 16.0)
                    .animate(CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeInOut,
                    ))
                    .value;

                // Rotation animation:
                // From 0 to 45 degrees (pi/4) to turn '+' into 'x'
                final double rotation = Tween<double>(begin: 0.0, end: math.pi / 4)
                    .animate(CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeInOutBack,
                    ))
                    .value;

                return Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: widget.primaryColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: rotation,
                      child: Icon(
                        widget.primaryIcon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
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

class _AnimatedMenuItem extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final int totalItems;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _AnimatedMenuItem({
    required this.controller,
    required this.index,
    required this.totalItems,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Calculate the staggered interval for this specific item
        // Items closer to the bottom (lower index) appear first
        final double intervalStart = (index / totalItems) * 0.5;
        final double intervalEnd = intervalStart + 0.5;
        
        final Animation<double> itemAnimation = CurvedAnimation(
          parent: controller,
          curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutBack),
        );

        // Slide upwards translation based on index
        // index 0 is bottom-most menu item (closest to FAB)
        final double targetY = -((index + 1) * 70.0);
        final double currentY = targetY * itemAnimation.value;
        
        // Scale and fade
        final double scale = itemAnimation.value;
        final double opacity = itemAnimation.value.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, currentY),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: onPressed,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
