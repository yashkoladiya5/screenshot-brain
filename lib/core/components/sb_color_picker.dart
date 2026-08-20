import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final double itemSize;
  final double spacing;

  const SbColorPicker({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    this.itemSize = 36.0,
    this.spacing = SBSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: colors.map((color) {
          final isSelected = color.value == selectedColor.value;
          
          return Padding(
            padding: EdgeInsets.only(right: spacing),
            child: GestureDetector(
              onTap: () => onColorSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: isSelected ? itemSize + 8 : itemSize,
                height: isSelected ? itemSize + 8 : itemSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 3.0 : 1.0,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8.0,
                        spreadRadius: 2.0,
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: itemSize * 0.5,
                        color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
