import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_spotlight_card.dart';

void main() {
  Widget host() => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SbSpotlightCard(
          width: 300,
          height: 200,
          child: const Text('content'),
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

  testWidgets('SbSpotlightCard hides the spotlight at rest', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets(
    'SbSpotlightCard fades spotlight in on hover and tracks pointer',
    (tester) async {
      await tester.pumpWidget(host());
      final gesture = await hoverMouse(tester);
      final topLeft = tester.getTopLeft(find.byType(SbSpotlightCard));

      await gesture.moveTo(topLeft + const Offset(90, 60));
      await tester.pumpAndSettle();

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, closeTo(1.0, 0.01));

      // The radial gloss is centered where the pointer is.
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Opacity),
              matching: find.byType(Container),
            )
            .first,
      );
      final gradient =
          (container.decoration! as BoxDecoration).gradient! as RadialGradient;
      final focus = gradient.center as FractionalOffset;
      expect(focus.dx, closeTo(90 / 300, 0.05));
      expect(focus.dy, closeTo(60 / 200, 0.05));
    },
  );

  testWidgets('SbSpotlightCard fades spotlight out on exit', (tester) async {
    await tester.pumpWidget(host());
    final gesture = await hoverMouse(tester);
    final topLeft = tester.getTopLeft(find.byType(SbSpotlightCard));

    await gesture.moveTo(topLeft + const Offset(90, 60));
    await tester.pumpAndSettle();
    expect(find.byType(Opacity), findsWidgets);

    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.byType(Opacity), findsNothing);
  });
}
