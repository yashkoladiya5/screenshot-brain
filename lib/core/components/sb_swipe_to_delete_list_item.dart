import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbSwipeToDeleteListItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final String deleteText;
  final IconData deleteIcon;

  const SbSwipeToDeleteListItem({
    super.key,
    required this.child,
    required this.onDelete,
    this.deleteText = 'Delete',
    this.deleteIcon = Icons.delete_outline_rounded,
  });

  @override
  State<SbSwipeToDeleteListItem> createState() => _SbSwipeToDeleteListItemState();
}

class _SbSwipeToDeleteListItemState extends State<SbSwipeToDeleteListItem> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _isDismissed = true;
        });
        widget.onDelete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: SBSpacing.xl),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(SBRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.deleteIcon,
              color: colorScheme.onError,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              widget.deleteText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(SBRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: widget.child,
      ),
    );
  }
}
