import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_star_rating.dart';

Widget staticHost({required double rating}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SbStarRating(rating: rating),
      ),
    ),
  );
}

/// Controlled host: the widget's displayed rating only changes through
/// [SbStarRating.onRatingChanged] or explicit external updates to [notifier].
Widget controlledHost(
  ValueNotifier<double> notifier, {
  void Function(double)? onEmit,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: ValueListenableBuilder<double>(
          valueListenable: notifier,
          builder: (context, value, child) => SbStarRating(
            rating: value,
            onRatingChanged: (next) {
              onEmit?.call(next);
              if (next != notifier.value) {
                notifier.value = next;
              }
            },
          ),
        ),
      ),
    ),
  );
}

/// Width of the clipped (filled) part of the [index]th star. The default
/// starSize is 32, so a full star clips to 32.0 and a half star to 16.0.
double activeStarWidth(WidgetTester tester, int index) {
  final clipRect = tester.widget<ClipRect>(
    find
        .descendant(
          of: find.byType(SbStarRating),
          matching: find.byType(ClipRect),
        )
        .at(index),
  );
  final clipper = clipRect.clipper!;
  return clipper.getClip(const Size(32, 32)).width;
}

void main() {
  testWidgets('SbStarRating renders 4.5 as four full stars plus one half star', (
    tester,
  ) async {
    await tester.pumpWidget(staticHost(rating: 4.5));
    await tester.pumpAndSettle();

    expect(find.byType(ClipRect), findsNWidgets(5));
    for (var star = 0; star < 4; star++) {
      expect(
        activeStarWidth(tester, star),
        closeTo(32.0, 0.5),
        reason: 'star $star should be fully filled',
      );
    }
    expect(activeStarWidth(tester, 4), closeTo(16.0, 0.5));
  });

  testWidgets('SbStarRating keeps applying external ratings after a canceled drag', (
    tester,
  ) async {
    final notifier = ValueNotifier<double>(2.0);
    addTearDown(notifier.dispose);
    final emitted = <double>[];
    await tester.pumpWidget(
      controlledHost(notifier, onEmit: emitted.add),
    );
    await tester.pumpAndSettle();

    final topLeft = tester.getTopLeft(find.byType(SbStarRating));
    // Press at x=140 (4.4/5 across the row), then drag past slop to x=110:
    // a horizontal drag in progress, rating becomes 3.5.
    final gesture = await tester.startGesture(topLeft + const Offset(140, 16));
    await tester.pump();
    await gesture.moveTo(topLeft + const Offset(110, 16));
    await tester.pump();
    // Diagnostic: the drag recognizer must have fired during the gesture.
    expect(emitted, contains(3.5), reason: 'drag must reach onRatingChanged');
    // The system steals the gesture: the pointer is canceled, so
    // onHorizontalDragEnd never runs and the drag state must reset anyway.
    await gesture.cancel();
    await tester.pump();

    // While the pointer is gone, an external controller sets the rating to 0.5.
    notifier.value = 0.5;
    await tester.pumpAndSettle();

    // The widget must show the new external rating, not stay stuck at 3.5.
    expect(activeStarWidth(tester, 0), closeTo(16.0, 0.5));
    expect(activeStarWidth(tester, 1), closeTo(0.0, 0.5));
  });

  testWidgets('SbStarRating exposes its rating to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(staticHost(rating: 3.5));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Rating'), findsOneWidget);
    // The nested GestureDetector already contributes tap/scroll semantics
    // actions; assert the label and readable value the wrapper must provide.
    final ratingNode = tester.getSemantics(find.bySemanticsLabel('Rating'));
    expect(ratingNode.label, 'Rating');
    expect(ratingNode.value, '3.5 out of 5 stars');

    handle.dispose();
  });
}
