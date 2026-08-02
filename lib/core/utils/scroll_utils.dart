import 'package:flutter/material.dart';

class ScrollUtils {
  /// Scrolls the provided [ScrollController] to the very top.
  static Future<void> scrollToTop(ScrollController controller, {Duration duration = const Duration(milliseconds: 300)}) async {
    if (!controller.hasClients) return;
    await controller.animateTo(
      0,
      duration: duration,
      curve: Curves.easeOut,
    );
  }

  /// Scrolls the provided [ScrollController] to the very bottom.
  static Future<void> scrollToBottom(ScrollController controller, {Duration duration = const Duration(milliseconds: 300)}) async {
    if (!controller.hasClients) return;
    await controller.animateTo(
      controller.position.maxScrollExtent,
      duration: duration,
      curve: Curves.easeOut,
    );
  }

  /// Removes the glowing scroll behavior on Android when at the edge.
  static Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}
