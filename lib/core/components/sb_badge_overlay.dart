import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbBadgeOverlay extends StatelessWidget {
  final Widget child;
  final String? label;
  final bool showBadge;
  final Color? badgeColor;
  final Color? textColor;
  final Offset offset;

  const SbBadgeOverlay({
    super.key,
    required this.child,
    this.label,
    this.showBadge = true,
    this.badgeColor,
    this.textColor,
    this.offset = const Offset(4, -4),
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bColor = badgeColor ?? colorScheme.error;
    final tColor = textColor ?? colorScheme.onError;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: offset.dy,
          right: offset.dx,
          child: Container(
            padding: EdgeInsets.all(label == null ? 4.0 : 2.0).copyWith(
              left: label == null ? 4.0 : 6.0,
              right: label == null ? 4.0 : 6.0,
            ),
            decoration: BoxDecoration(
              color: bColor,
              shape: label == null ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: label == null ? null : BorderRadius.circular(SBRadius.full),
              border: Border.all(color: colorScheme.surface, width: 1.5),
            ),
            constraints: const BoxConstraints(
              minWidth: 10,
              minHeight: 10,
            ),
            child: label != null
                ? Text(
                    label!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
