import 'dart:ui';
import 'package:flutter/material.dart';

class SbGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double blur;
  final double opacity;
  final double height;

  const SbGlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.blur = 15.0,
    this.opacity = 0.6,
    this.height = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Account for the system status bar at the top
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height + statusBarHeight,
          padding: EdgeInsets.only(top: statusBarHeight),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: opacity),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
          ),
          child: NavigationToolbar(
            leading: leading ?? _buildDefaultLeading(context),
            middle: title != null
                ? DefaultTextStyle(
                    style: theme.textTheme.titleLarge!.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    child: title!,
                  )
                : null,
            trailing: actions != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  )
                : null,
            centerMiddle: true,
          ),
        ),
      ),
    );
  }

  Widget? _buildDefaultLeading(BuildContext context) {
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    final bool useCloseButton = parentRoute is PageRoute<dynamic> && parentRoute.fullscreenDialog;

    if (canPop) {
      return useCloseButton ? const CloseButton() : const BackButton();
    }
    return null;
  }
}
