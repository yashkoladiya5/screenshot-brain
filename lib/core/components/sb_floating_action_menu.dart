import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbFloatingActionMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const SbFloatingActionMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class SbFloatingActionMenu extends StatefulWidget {
  final List<SbFloatingActionMenuItem> items;
  final IconData mainIcon;
  final IconData activeIcon;

  const SbFloatingActionMenu({
    super.key,
    required this.items,
    this.mainIcon = Icons.add_rounded,
    this.activeIcon = Icons.close_rounded,
  });

  @override
  State<SbFloatingActionMenu> createState() => _SbFloatingActionMenuState();
}

class _SbFloatingActionMenuState extends State<SbFloatingActionMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...List.generate(widget.items.length, (index) {
          final item = widget.items[index];
          final itemColor = item.color ?? colorScheme.primary;

          return ScaleTransition(
            scale: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: SBSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: SBSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(SBRadius.sm),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      item.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: SBSpacing.sm),
                  FloatingActionButton.small(
                    heroTag: 'fab_$index',
                    onPressed: () {
                      _toggleMenu();
                      item.onTap();
                    },
                    backgroundColor: itemColor,
                    foregroundColor: colorScheme.onPrimary,
                    child: Icon(item.icon),
                  ),
                ],
              ),
            ),
          );
        }),
        FloatingActionButton(
          heroTag: 'fab_main',
          onPressed: _toggleMenu,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          child: RotationTransition(
            turns: _rotateAnimation,
            child: Icon(_isOpen ? widget.activeIcon : widget.mainIcon),
          ),
        ),
      ],
    );
  }
}
