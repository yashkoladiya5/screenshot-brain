import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbSwipeableCard extends StatelessWidget {
  final Widget child;
  final Widget background;
  final Widget? secondaryBackground;
  final VoidCallback onDismissed;

  const SbSwipeableCard({
    super.key,
    required this.child,
    required this.background,
    required this.onDismissed,
    this.secondaryBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(), // Ideally this should be passed in for lists
      direction: secondaryBackground == null 
          ? DismissDirection.startToEnd 
          : DismissDirection.horizontal,
      onDismissed: (direction) => onDismissed(),
      background: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SBRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: background,
      ),
      secondaryBackground: secondaryBackground != null 
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SBRadius.lg),
              ),
              clipBehavior: Clip.antiAlias,
              child: secondaryBackground,
            )
          : null,
      child: child,
    );
  }
}
