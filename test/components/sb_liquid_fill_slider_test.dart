import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_liquid_fill_slider.dart';

Widget _host({required List<double> emitted, double initialValue = 0.5}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SbLiquidFillSlider(
          width: 300,
          height: 60,
          initialValue: initialValue,
          onChanged: emitted.add,
        ),
      ),
    ),
  );
}

void main() {
  // The slosh settle loop decays drag velocity with 16ms delayed timers; the
  // wave controller repeats forever so pumpAndSettle cannot be used. Pump a
  // bounded window of frames to let every pending timer drain.
  Future<void> settleSlosh(WidgetTester tester) async {
    for (int i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('renders the initial value as a percentage readout', (
    tester,
  ) async {
    final List<double> emitted = [];
    await tester.pumpWidget(_host(emitted: emitted, initialValue: 0.5));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('dragging toward the right end raises the value', (tester) async {
    final List<double> emitted = [];
    await tester.pumpWidget(_host(emitted: emitted, initialValue: 0.2));
    await tester.pump(const Duration(milliseconds: 50));
    emitted.clear();

    final Rect bar = tester.getRect(find.byType(SbLiquidFillSlider));
    final TestGesture gesture = await tester.startGesture(
      Offset(bar.left + 10, bar.center.dy),
    );
    await tester.pump();
    // Sweep across the tube to the far right edge.
    await gesture.moveTo(Offset(bar.right, bar.center.dy));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    await settleSlosh(tester);

    expect(emitted, isNotEmpty);
    expect(emitted.first, lessThan(0.1));
    expect(emitted.last, greaterThan(0.9));
  });

  testWidgets('dragging back to the left drains toward zero', (tester) async {
    final List<double> emitted = [];
    await tester.pumpWidget(_host(emitted: emitted, initialValue: 0.8));
    await tester.pump(const Duration(milliseconds: 50));

    final Rect bar = tester.getRect(find.byType(SbLiquidFillSlider));
    final TestGesture gesture = await tester.startGesture(
      Offset(bar.right - 10, bar.center.dy),
    );
    await tester.pump();
    await gesture.moveTo(Offset(bar.left, bar.center.dy));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    await settleSlosh(tester);

    expect(emitted.last, lessThan(0.05));
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('value is clamped when the drag leaves the tube', (tester) async {
    final List<double> emitted = [];
    await tester.pumpWidget(_host(emitted: emitted));
    await tester.pump(const Duration(milliseconds: 50));

    final Rect bar = tester.getRect(find.byType(SbLiquidFillSlider));
    final TestGesture gesture = await tester.startGesture(
      Offset(bar.center.dx, bar.center.dy),
    );
    await tester.pump();
    // Overshoot far past the right edge.
    await gesture.moveTo(Offset(bar.right + 200, bar.center.dy));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    await settleSlosh(tester);

    expect(emitted.last, greaterThanOrEqualTo(1.0));
    expect(emitted.last, lessThanOrEqualTo(1.0));
  });
}
