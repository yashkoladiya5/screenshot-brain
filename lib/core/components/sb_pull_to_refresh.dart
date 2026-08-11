import 'package:flutter/material.dart';

class SbPullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const SbPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      strokeWidth: 2.5,
      child: child,
    );
  }
}
