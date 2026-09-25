import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbMagneticDock extends StatefulWidget {
  final List<IconData> icons;
  final ValueChanged<int> onIconTapped;
  final double baseSize;
  final double magnifiedSize;
  final double influenceRadius;
  final Color backgroundColor;
  final Color iconColor;

  const SbMagneticDock({
    super.key,
    required this.icons,
    required this.onIconTapped,
    this.baseSize = 50.0,
    this.magnifiedSize = 100.0,
    this.influenceRadius = 150.0,
    this.backgroundColor = const Color(0x88000000),
    this.iconColor = Colors.white,
  }) : assert(icons.length > 0);

  @override
  State<SbMagneticDock> createState() => _SbMagneticDockState();
}

class _SbMagneticDockState extends State<SbMagneticDock> {
  // We track the exact X position of the user's finger during a drag
  double? _touchX;

  void _updateTouchPosition(double x) {
    setState(() {
      _touchX = x;
    });
  }

  void _clearTouchPosition() {
    setState(() {
      _touchX = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the entire dock in a gesture detector to track continuous horizontal drags
    return GestureDetector(
      onPanUpdate: (details) => _updateTouchPosition(details.localPosition.dx),
      onPanEnd: (_) => _clearTouchPosition(),
      onPanCancel: _clearTouchPosition,
      onTapDown: (details) => _updateTouchPosition(details.localPosition.dx),
      onTapUp: (_) => _clearTouchPosition(),
      onTapCancel: _clearTouchPosition,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: widget.magnifiedSize + 20, // Need enough height to allow the icons to grow
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ]
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.icons.length, (index) {
              return _DockIcon(
                icon: widget.icons[index],
                index: index,
                touchX: _touchX,
                totalIcons: widget.icons.length,
                baseSize: widget.baseSize,
                magnifiedSize: widget.magnifiedSize,
                influenceRadius: widget.influenceRadius,
                iconColor: widget.iconColor,
                onTapped: () => widget.onIconTapped(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final double? touchX;
  final int totalIcons;
  final double baseSize;
  final double magnifiedSize;
  final double influenceRadius;
  final Color iconColor;
  final VoidCallback onTapped;

  const _DockIcon({
    required this.icon,
    required this.index,
    required this.touchX,
    required this.totalIcons,
    required this.baseSize,
    required this.magnifiedSize,
    required this.influenceRadius,
    required this.iconColor,
    required this.onTapped,
  });

  @override
  Widget build(BuildContext context) {
    // We use a LayoutBuilder to get the exact X position of this specific icon on the screen
    return LayoutBuilder(
      builder: (context, constraints) {
        // Because Row lays out children sequentially, we can estimate this icon's center position
        // relative to the entire Row's width.
        // A more complex implementation would use GlobalKeys to get exact render box positions,
        // but for a smooth continuous gesture inside a constrained box, estimating is extremely fast and effective.
        
        // We calculate what percentage of the way across the dock this icon sits
        final double percentX = (index + 0.5) / totalIcons;
        
        // If we know the touchX (from the parent), we need to figure out how close the finger is to THIS icon
        double currentSize = baseSize;
        double translateY = 0.0;
        
        if (touchX != null) {
          // We have to map the touchX (which is relative to the entire screen width because of the parent GestureDetector)
          // to find its distance from our estimated center
          final double screenWidth = MediaQuery.of(context).size.width;
          
          // Estimate this icon's exact X coordinate on the screen
          // The dock is centered, so we account for the padding and spacing
          final double estimatedIconCenterX = (screenWidth / 2) - ((totalIcons * baseSize) / 2) + (index * baseSize) + (baseSize / 2);
          
          // Calculate exact distance from finger to this icon
          final double distance = (touchX! - estimatedIconCenterX).abs();
          
          if (distance < influenceRadius) {
            // The finger is close! Calculate a magnification factor using a bell curve (cosine)
            // so it smoothly ramps up and ramps down
            final double normalizedDistance = distance / influenceRadius; // 0.0 to 1.0
            
            // We use cosine to get a smooth bell curve: cos(0) = 1 (max magnification), cos(pi/2) = 0 (base size)
            final double magnificationFactor = math.cos(normalizedDistance * math.pi / 2);
            
            // Apply magnification
            currentSize = baseSize + ((magnifiedSize - baseSize) * magnificationFactor);
            
            // Also translate it UP slightly so the bottom of the icons stay aligned
            translateY = -(currentSize - baseSize) * 0.5;
          }
        }
        
        // We use AnimatedContainer to smoothly animate back to baseSize when the user lets go
        return GestureDetector(
          onTap: onTapped,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: touchX == null ? const Duration(milliseconds: 300) : const Duration(milliseconds: 50), // Fast response when dragging, slow bounce back when released
            curve: touchX == null ? Curves.elasticOut : Curves.easeOut,
            width: currentSize,
            height: currentSize,
            margin: EdgeInsets.symmetric(horizontal: currentSize * 0.1),
            transform: Matrix4.identity()..translate(0.0, translateY),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(currentSize * 0.25), // Apple style squircle
              border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1.0),
              boxShadow: touchX != null && currentSize > baseSize + 5 
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.3),
                      blurRadius: 10 * (currentSize / magnifiedSize),
                      offset: const Offset(0, 5),
                    )
                  ]
                : null,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: currentSize * 0.5,
            ),
          ),
        );
      }
    );
  }
}
