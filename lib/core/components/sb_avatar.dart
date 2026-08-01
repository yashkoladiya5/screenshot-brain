import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SbAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.radius = SBRadius.xl,
    this.backgroundColor,
    this.foregroundColor,
  }) : assert(imageUrl != null || initials != null, 'Either imageUrl or initials must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bg = backgroundColor ?? colorScheme.primaryContainer;
    final fg = foregroundColor ?? colorScheme.onPrimaryContainer;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      foregroundColor: fg,
      child: Text(
        initials ?? '',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
