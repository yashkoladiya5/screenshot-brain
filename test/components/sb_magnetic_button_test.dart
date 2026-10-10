import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_magnetic_button.dart';

void main() {
  var pressCount = 0;

  Widget host() => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SbMagneticButton(
          onPressed: () => pressCount++,
          child: const Text('Tap'),
        ),
      ),
    ),
  );

  Transform buttonTransform(WidgetTester tester) => tester.widget<Transform>(
    find.descendant(
      of: find.byType(SbMagneticButton),
      matching: find.byType(Transform),
    ),
  );

  setUp(() => pressCount = 0);

  testWidgets('SbMagneticButton pulls toward the cursor on hover', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    final center = tester.getCenter(find.byType(SbMagneticButton));

    // Cursor right/below center => positive translate entries (storage 12/13).
    await gesture.moveTo(center + const Offset(60, 20));
    await tester.pump();
    await tester.pumpAndSettle();

    final storage = buttonTransform(tester).transform.storage;
    expect(storage[12], greaterThan(0.0));
    expect(storage[13], greaterThan(0.0));

    // Cursor up/left of center => negative pull.
    await gesture.moveTo(center - const Offset(60, 30));
    await tester.pump();
    await tester.pumpAndSettle();

    final flipped = buttonTransform(tester).transform.storage;
    expect(flipped[12], lessThan(0.0));
    expect(flipped[13], lessThan(0.0));
  });

  testWidgets('SbMagneticButton elastically resets on exit', (tester) async {
    await tester.pumpWidget(host());
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    final center = tester.getCenter(find.byType(SbMagneticButton));
    await gesture.moveTo(center + const Offset(60, 20));
    await tester.pumpAndSettle();

    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();

    final storage = buttonTransform(tester).transform.storage;
    expect(storage[12], closeTo(0.0, 1e-3));
    expect(storage[13], closeTo(0.0, 1e-3));
  });

  testWidgets('SbMagneticButton still fires onPressed on tap', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('Tap'));
    await tester.pump();
    expect(pressCount, 1);
  });
}
