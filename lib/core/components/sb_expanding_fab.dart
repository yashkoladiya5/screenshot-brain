import 'package:flutter/material.dart';
import '../design/tokens.dart';
import 'dart:math' as math;

class SbExpandingFabItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const SbExpandingFabItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class SbExpandingFab extends StatefulWidget {
  final IconData mainIcon;
  final List<SbExpandingFabItem> items;
  final double distance;
  final Color? backgroundColor;
  final Color? iconColor;

  const SbExpandingFab({
    super.key,
    this.mainIcon = Icons.add_rounded,
    required this.items,
    this.distance = 70.0,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<SbExpandingFab> createState() => _SbExpandingFabState();
}

class _SbExpandingFabState extends State<SbExpandingFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
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
    final colorScheme = theme.colorScheme;
    
    final bg = widget.backgroundColor ?? colorScheme.primary;
    final fg = widget.iconColor ?? colorScheme.onPrimary;

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Background overlay when open
        if (_isOpen || _controller.isAnimating)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return IgnorePointer(
                  ignoring: !_isOpen,
                  child: GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.2 * _expandAnimation.value),
                    ),
                  ),
                );
              },
            ),
          ),
          
        ..._buildExpandingActionButtons(theme, colorScheme),
        _buildTapToOpenFab(bg, fg),
      ],
    );
  }

  Widget _buildTapToOpenFab(Color bg, Color fg) {
    return IgnorePointer(
      ignoring: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transformAlignment: Alignment.center,
        transform: Matrix4.rotationZ(_isOpen ? math.pi / 4 : 0),
        child: FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SBRadius.xl),
          ),
          child: Icon(widget.mainIcon, size: 28),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons(ThemeData theme, ColorScheme colorScheme) {
    final children = <Widget>[];
    final count = widget.items.length;
    final step = 90.0 / (count - 1);

    for (int i = 0; i < count; i++) {
      final angleInDegrees = step * i;
      final angleInRadians = angleInDegrees * math.pi / 180.0;
      final item = widget.items[i];

      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _toggle();
                item.onTap();
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color ?? colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(
                  item.icon,
                  color: item.color != null ? Colors.white : colorScheme.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return children;
  }
}

class _ExpandingActionButton extends StatelessWidget {
  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.scale(
            scale: progress.value,
            child: Opacity(
              opacity: progress.value,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
