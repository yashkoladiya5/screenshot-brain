import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_spring_chain_slider.dart';

void main() {
  const double width = 280.0;
  const double start = 0.28;
  const double end = 0.72;

  group('integrateThumb physics', () {
    test('free thumb converges to its home from a displaced start', () {
      double p = 1.0, v = 0.0;
      for (int i = 0; i < 600; i++) {
        final r = SbSpringChainSlider.integrateThumb(
          p: p,
          v: v,
          home: 0.5,
          other: 0.5,
          anchorStiffness: 160,
          couplingStiffness: 240,
          dampingRatio: 0.8,
          dt: 1 / 60,
        );
        p = r.p;
        v = r.v;
      }
      expect(p, closeTo(0.5, 1e-3));
      expect(v, closeTo(0, 1e-3));
    });

    test('underdamped coupling makes the follower overshoot its home', () {
      double p = 0.28, v = 0.0;
      double maxSeen = p;
      for (int i = 0; i < 300; i++) {
        final r = SbSpringChainSlider.integrateThumb(
          p: p,
          v: v,
          home: 0.28,
          other: 0.6, // dragged far away: coupling spring pulls this thumb
          anchorStiffness: 160,
          couplingStiffness: 240,
          dampingRatio: 0.25,
          dt: 1 / 60,
        );
        p = r.p;
        v = r.v;
        maxSeen = p > maxSeen ? p : maxSeen;
      }
      // Pulled toward 0.6 but anchored at 0.28 -> steady state sits between.
      expect(p, greaterThan(0.28));
      expect(p, lessThan(0.6));
      // Underdamping means it must ring past its equilibrium.
      expect(maxSeen, greaterThan(p + 1e-9));
    });
  });

  Widget host({ValueChanged<RangeValues>? onRangeChanged}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SbSpringChainSlider(
          width: width,
          initialStart: start,
          initialEnd: end,
          leftThumbKey: const ValueKey('thumb-left'),
          rightThumbKey: const ValueKey('thumb-right'),
          onRangeChanged: onRangeChanged,
        ),
      ),
    ),
  );

  double thumbX(WidgetTester tester, String key) =>
      tester.getCenter(find.byKey(ValueKey(key))).dx -
      tester.getTopLeft(find.byType(SbSpringChainSlider)).dx;

  testWidgets('thumbs rest exactly at their home fractions', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    expect(thumbX(tester, 'thumb-left'), closeTo(start * width, 1.0));
    expect(thumbX(tester, 'thumb-right'), closeTo(end * width, 1.0));
  });

  testWidgets('dragging one thumb pulls the other via the coupling spring', (
    tester,
  ) async {
    final List<RangeValues> ranges = [];
    await tester.pumpWidget(host(onRangeChanged: ranges.add));
    await tester.pump();

    final double rightBefore = thumbX(tester, 'thumb-right');
    final Offset leftThumb =
        tester.getCenter(find.byKey(const ValueKey('thumb-left')));

    final TestGesture g = await tester.startGesture(leftThumb);
    await g.moveBy(const Offset(60, 0));
    await tester.pump();
    // The dragged thumb follows the finger exactly (kinematic).
    expect(thumbX(tester, 'thumb-left'), closeTo((start * width) + 60, 2.0));

    // The free thumb lags: no instant jump to its new equilibrium...
    expect(thumbX(tester, 'thumb-right'), closeTo(rightBefore, 6.0));
    // ...but the compressed coupling spring pushes it away from the
    // dragged thumb, i.e. rightward, over the next frames.
    await tester.pump(const Duration(milliseconds: 120));
    expect(thumbX(tester, 'thumb-right'), greaterThan(rightBefore + 4.0));

    // Range callback saw the widening gap and stayed ordered.
    expect(ranges, isNotEmpty);
    for (final RangeValues rv in ranges) {
      expect(rv.start, lessThanOrEqualTo(rv.end));
      expect(rv.start, greaterThanOrEqualTo(0.0));
      expect(rv.end, lessThanOrEqualTo(1.0));
    }

    await g.up();
    // Release: the whole chain rings home, settling without flying off.
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(thumbX(tester, 'thumb-left'), closeTo(start * width, 1.0));
    expect(thumbX(tester, 'thumb-right'), closeTo(end * width, 1.0));
  });

  testWidgets('hard stops absorb velocity at the track ends', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump();
    final Offset rightThumb =
        tester.getCenter(find.byKey(const ValueKey('thumb-right')));
    final TestGesture g = await tester.startGesture(rightThumb);
    await g.moveBy(const Offset(200, 0)); // way past the end of the track
    await tester.pump();
    expect(thumbX(tester, 'thumb-right'), lessThanOrEqualTo(width + 1.0));
    await g.up();
    await tester.pumpAndSettle();
    expect(thumbX(tester, 'thumb-right'), closeTo(end * width, 1.0));
  });
}
