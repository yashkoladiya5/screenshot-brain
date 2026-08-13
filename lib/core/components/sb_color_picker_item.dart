import 'package:flutter/material.dart';

class SbColorPickerItem extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const SbColorPickerItem({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine checkmark color based on background luminance
    final checkColor = color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colorScheme.onSurface : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                spreadRadius: 1,
              ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.check_rounded,
                color: checkColor,
                size: size * 0.6,
              )
            : null,
      ),
    );
  }
}
