import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_liquid_fill_button.dart';

Widget _host({required VoidCallback onFilled, String text = 'HOLD'}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SbLiquidFillButton(
          text: text,
          onFilled: onFilled,
          fillDuration: const Duration(milliseconds: 600),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('holding until full fires onFilled once and shows COMPLETE', (
    tester,
  ) async {
    int filled = 0;
    await tester.pumpWidget(_host(onFilled: () => filled++));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(SbLiquidFillButton)),
    );
    // First frame after forward() only starts the ticker (elapsed 0), so
    // pump once, then go past the 600ms fill duration.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(filled, 1);
    expect(find.text('COMPLETE!'), findsOneWidget);

    // A second hold must not re-fire once filled.
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.startGesture(
      tester.getCenter(find.byType(SbLiquidFillButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 100));
    expect(filled, 1);
  });

  testWidgets('early release drains the liquid without firing onFilled', (
    tester,
  ) async {
    int filled = 0;
    await tester.pumpWidget(_host(onFilled: () => filled++));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(SbLiquidFillButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(filled, 0);
    // Text has drained back to the original label.
    expect(find.text('HOLD'), findsOneWidget);
  });

  testWidgets('pointer cancel behaves like an early release', (tester) async {
    int filled = 0;
    await tester.pumpWidget(_host(onFilled: () => filled++));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(SbLiquidFillButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    // Dispatch a real PointerCancelEvent (e.g. system gesture steal).
    await gesture.cancel();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(filled, 0);
    expect(find.text('HOLD'), findsOneWidget);
  });
}
