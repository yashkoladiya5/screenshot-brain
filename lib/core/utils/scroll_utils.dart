import 'package:flutter/material.dart';

class ScrollUtils {
  /// Scrolls the provided [ScrollController] to the very top.
  /// Iterates all attached positions (same rationale as [scrollToBottom]):
  /// `controller.animateTo` routes through `controller.position`, which
  /// throws StateError when one controller drives more than one scroll view
  /// (tabbed panes, split views), so a "back to top" gesture crashed there.
  static Future<void> scrollToTop(
    ScrollController controller, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    if (!controller.hasClients) return;
    await Future.wait<void>(<Future<void>>[
      for (final ScrollPosition position in List<ScrollPosition>.of(
        controller.positions,
      ))
        position.animateTo(0, duration: duration, curve: Curves.easeOut),
    ]);
  }

  /// Scrolls the provided [ScrollController] to the very bottom.
  static Future<void> scrollToBottom(
    ScrollController controller, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    if (!controller.hasClients) return;
    // Iterate all attached positions: a single controller can drive more
    // than one scroll view, and `controller.position` throws in that case.
    // Each view animates to its own maximum extent.
    await Future.wait<void>(<Future<void>>[
      for (final ScrollPosition position in List<ScrollPosition>.of(
        controller.positions,
      ))
        position.animateTo(
          position.maxScrollExtent,
          duration: duration,
          curve: Curves.easeOut,
        ),
    ]);
  }

  /// Removes the glowing scroll behavior on Android when at the edge.
  static Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}
