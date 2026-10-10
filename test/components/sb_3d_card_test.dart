import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_3d_card.dart';

void main() {
  Widget host() => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Sb3DCard(
          width: 300,
          height: 400,
          child: const ColoredBox(color: Colors.green),
        ),
      ),
    ),
  );

  Transform cardTransform(WidgetTester tester) => tester.widget<Transform>(
    find.descendant(
      of: find.byType(Sb3DCard),
      matching: find.byType(Transform),
    ),
  );

  Future<TestGesture> hoverMouse(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    return gesture;
  }

  testWidgets('Sb3DCard tilts on mouse hover and shows gloss', (tester) async {
    await tester.pumpWidget(host());
    final gesture = await hoverMouse(tester);
    final topLeft = tester.getTopLeft(find.byType(Sb3DCard));

    // Hover top edge: pointer above center => rotateX entry positive.
    await gesture.moveTo(topLeft + const Offset(60, 40));
    await tester.pumpAndSettle();

    expect(cardTransform(tester).transform.entry(2, 1), greaterThan(0.01));
    // Gloss overlay only renders while hovering (second Stack child).
    final stack = tester.widget<Stack>(
      find
          .descendant(of: find.byType(Sb3DCard), matching: find.byType(Stack))
          .first,
    );
    expect(stack.children.length, 2); // content + gloss
  });

  testWidgets('Sb3DCard resets toward center after pointer exit', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    final gesture = await hoverMouse(tester);
    final topLeft = tester.getTopLeft(find.byType(Sb3DCard));

    await gesture.moveTo(topLeft + const Offset(60, 40));
    await tester.pumpAndSettle();
    expect(cardTransform(tester).transform.entry(2, 1), greaterThan(0.01));

    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(cardTransform(tester).transform.entry(2, 1), closeTo(0.0, 1e-3));
  });

  testWidgets('Sb3DCard touch pan tilts via synthetic hover event', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    final topLeft = tester.getTopLeft(find.byType(Sb3DCard));

    final gesture = await tester.startGesture(topLeft + const Offset(150, 200));
    await gesture.moveBy(const Offset(100, 160)); // toward bottom-right
    await tester.pumpAndSettle();

    // Pointer below/right of center => negative rotateX entry.
    expect(cardTransform(tester).transform.entry(2, 1), lessThan(-0.01));

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
