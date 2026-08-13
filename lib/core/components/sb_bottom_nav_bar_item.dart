import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbBottomNavBarItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final int? badgeCount;

  const SbBottomNavBarItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.badgeCount,
  });

  /// Converts this custom item definition into a standard Flutter NavigationDestination
  NavigationDestination toNavigationDestination(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget iconWidget = Icon(icon, color: colorScheme.onSurfaceVariant);
    Widget activeIconWidget = Icon(activeIcon ?? icon, color: colorScheme.onSecondaryContainer);

    if (badgeCount != null && badgeCount! > 0) {
      final badgeText = badgeCount! > 99 ? '99+' : badgeCount.toString();
      
      iconWidget = Badge(
        label: Text(badgeText),
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
        child: iconWidget,
      );
      
      activeIconWidget = Badge(
        label: Text(badgeText),
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
        child: activeIconWidget,
      );
    }

    return NavigationDestination(
      icon: iconWidget,
      selectedIcon: activeIconWidget,
      label: label,
    );
  }
}
