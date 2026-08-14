import 'package:flutter/material.dart';

class SbCircularAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SbCircularAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40.0,
    this.backgroundColor,
    this.foregroundColor,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bg = backgroundColor ?? colorScheme.primaryContainer;
    final fg = foregroundColor ?? colorScheme.onPrimaryContainer;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: colorScheme.surfaceContainerHighest,
        onBackgroundImageError: (_, __) {
          // If image fails, it falls back to background color naturally
        },
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: name != null && name!.isNotEmpty
          ? Text(
              _getInitials(name!),
              style: theme.textTheme.titleMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.35, // Scale text relative to avatar size
              ),
            )
          : Icon(
              Icons.person_rounded,
              color: fg,
              size: size * 0.6,
            ),
    );
  }
}
