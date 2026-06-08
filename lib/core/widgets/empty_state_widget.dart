import 'package:flutter/material.dart';
import '../components/sb_empty_state.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SbEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
