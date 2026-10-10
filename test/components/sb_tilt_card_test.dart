import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_tilt_card.dart';

void main() {
  const cardSize = Size(300, 400);

  Widget host() => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SbTiltCard(
          width: cardSize.width,
          height: cardSize.height,
          child: const ColoredBox(color: Colors.blue),
        ),
      ),
    ),
  );

  Future<TestGesture> hoverMouse(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    return gesture;
  }

  Transform cardTransform(WidgetTester tester) => tester.widget<Transform>(
    find.descendant(
      of: find.byType(SbTiltCard),
      matching: find.byType(Transform),
    ),
  );

  testWidgets('SbTiltCard starts untilted at rest', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(cardTransform(tester).transform.entry(2, 1), closeTo(0.0, 1e-6));
  });

  testWidgets('SbTiltCard mouse hover tilts toward the pointer', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    final gesture = await hoverMouse(tester);
    final topLeft = tester.getTopLeft(find.byType(SbTiltCard));

    // Upper-left quadrant: pointer above center => positive rotateX entry.
    await gesture.moveTo(topLeft + const Offset(40, 40));
    await tester.pumpAndSettle();
    expect(cardTransform(tester).transform.entry(2, 1), greaterThan(0.01));

    // Lower-right quadrant flips the tilt sign.
    await gesture.moveTo(topLeft + const Offset(260, 360));
    await tester.pumpAndSettle();
    expect(cardTransform(tester).transform.entry(2, 1), lessThan(-0.01));
  });

  testWidgets('SbTiltCard springs back to zero on pointer exit', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    final gesture = await hoverMouse(tester);
    final topLeft = tester.getTopLeft(find.byType(SbTiltCard));

    await gesture.moveTo(topLeft + const Offset(40, 40));
    await tester.pumpAndSettle();
    expect(cardTransform(tester).transform.entry(2, 1), greaterThan(0.01));

    await gesture.moveTo(Offset.zero); // leave the card
    await tester.pumpAndSettle();
    expect(cardTransform(tester).transform.entry(2, 1), closeTo(0.0, 1e-3));
  });

  testWidgets('SbTiltCard touch pan drives the same tilt path', (tester) async {
    await tester.pumpWidget(host());
    final center = tester.getCenter(find.byType(SbTiltCard));

    // Long-press style drag so the GestureDetector pan recognizer wins.
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(80, 60));
    await tester.pumpAndSettle();
    expect(cardTransform(tester).transform.entry(2, 1), lessThan(-0.01));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(cardTransform(tester).transform.entry(2, 1), closeTo(0.0, 1e-3));
  });
}
