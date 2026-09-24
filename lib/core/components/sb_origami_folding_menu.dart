import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbOrigamiFoldingMenu extends StatefulWidget {
  final List<Widget> menuItems;
  final Widget closedWidget;
  final double itemHeight;
  final double width;
  final Duration animationDuration;

  const SbOrigamiFoldingMenu({
    super.key,
    required this.menuItems,
    required this.closedWidget,
    this.itemHeight = 60.0,
    this.width = 250.0,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<SbOrigamiFoldingMenu> createState() => _SbOrigamiFoldingMenuState();
}

class _SbOrigamiFoldingMenuState extends State<SbOrigamiFoldingMenu> with SingleTickerProviderStateMixin {
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
    return SizedBox(
      width: widget.width,
      // Provide enough height for the closed widget plus all items dropping down
      // If closed, it just takes up itemHeight.
      height: widget.itemHeight * (widget.menuItems.length + 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The top header/toggle button
          GestureDetector(
            onTap: _toggleMenu,
            child: SizedBox(
              width: widget.width,
              height: widget.itemHeight,
              child: widget.closedWidget,
            ),
          ),
          
          // The folding items
          ...List.generate(widget.menuItems.length, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Calculate when this specific item should start animating
                // We want a cascading effect, so item 0 unfolds first, then item 1, etc.
                final double totalItems = widget.menuItems.length.toDouble();
                final double delay = (index / totalItems) * 0.5; // items start between 0.0 and 0.5
                final double duration = 0.5; // each takes 50% of the total animation time
                
                final Animation<double> itemAnimation = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(
                    delay,
                    (delay + duration).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                );

                // Origami fold math
                // When 0, folded flat (90 degrees). When 1, unfolded flat (0 degrees).
                // The angle goes from pi/2 to 0.
                final double foldAngle = (1.0 - itemAnimation.value) * (math.pi / 2);
                
                // We alternate the hinge direction to make it fold like an accordion
                final bool isEven = index % 2 == 0;
                
                // The actual rotation applied
                final double rotationAngle = isEven ? -foldAngle : foldAngle;
                
                // Fractional alignment depends on if we are hinging from the top or bottom
                // But in this simple cascade, we hinge from the top of each item relative to the one above it
                final FractionalOffset alignment = FractionalOffset.topCenter;

                // Scale the height slightly as it folds so it physically takes up less space
                final double currentHeight = widget.itemHeight * itemAnimation.value;

                // Opacity fades in
                final double opacity = itemAnimation.value.clamp(0.0, 1.0);

                // Add dynamic lighting/shadow to simulate the fold
                final double shadowIntensity = (1.0 - itemAnimation.value) * 0.5;

                return Transform(
                  alignment: alignment,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // Perspective distortion
                    ..rotateX(rotationAngle),
                  child: Opacity(
                    opacity: opacity,
                    child: SizedBox(
                      width: widget.width,
                      height: currentHeight,
                      child: Stack(
                        children: [
                          widget.menuItems[index],
                          // Shadow overlay
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: shadowIntensity),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
