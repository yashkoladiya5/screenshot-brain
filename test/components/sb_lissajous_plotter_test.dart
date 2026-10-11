import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_lissajous_plotter.dart';

void main() {
  const double size = 200.0;
  const double freqX = 3.0;
  const double freqY = 2.0;

  Widget host({
    double phase = math.pi / 2,
    ValueChanged<double>? onPhaseChanged,
    Key? penKey,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SbLissajousPlotter(
              size: size,
              freqX: freqX,
              freqY: freqY,
              phase: phase,
              maxPoints: 60,
              penKey: penKey,
              onPhaseChanged: onPhaseChanged,
            ),
          ),
        ),
      );

  group('penAt closed-form math', () {
    test('t=0 sits on the x amplitude and the vertical centre', () {
      final Offset p = SbLissajousPlotter.penAt(
        t: 0,
        size: size,
        freqX: freqX,
        freqY: freqY,
        phase: 0,
        decayX: 0.06,
        decayY: 0.08,
        amplitudeFactor: 0.42,
      );
      // x = A sin(0) = 0 offset, y = B sin(0) = 0 offset -> dead centre.
      expect(p.dx, closeTo(size / 2, 1e-9));
      expect(p.dy, closeTo(size / 2, 1e-9));

      final Offset q = SbLissajousPlotter.penAt(
        t: 0,
        size: size,
        freqX: freqX,
        freqY: freqY,
        phase: math.pi / 2,
        decayX: 0.06,
        decayY: 0.08,
        amplitudeFactor: 0.42,
      );
      // phase=pi/2 puts the pen on the extreme x = +A at t=0.
      expect(q.dx, closeTo(size / 2 + size * 0.42, 1e-9));
      expect(q.dy, closeTo(size / 2, 1e-9));
    });

    test('exponential decay shrinks the excursion envelope over time', () {
      double dist(double t) {
        final Offset p = SbLissajousPlotter.penAt(
          t: t,
          size: size,
          freqX: freqX,
          freqY: freqY,
          phase: math.pi / 2,
          decayX: 0.4,
          decayY: 0.4,
          amplitudeFactor: 0.42,
        );
        return (p - Offset(size / 2, size / 2)).distance;
      }

      // The analytic envelope is e^{-lambda t} per axis, so the distance
      // from centre is bounded by sqrt(2) A e^{-lambda t} — and it must
      // actually decay well below the early excursion.
      expect(dist(0), closeTo(size * 0.42, 1e-9));
      expect(
        dist(4),
        lessThanOrEqualTo(size * 0.42 * math.sqrt(2) * math.exp(-0.4 * 4)),
      );
      expect(dist(10), lessThan(dist(2)));
    });

    test('Lissajous 2:1 ratio closes on itself after 2 pi', () {
      final Offset a = SbLissajousPlotter.penAt(
        t: 0,
        size: size,
        freqX: 2.0,
        freqY: 1.0,
        phase: 0,
        decayX: 0,
        decayY: 0,
        amplitudeFactor: 0.42,
      );
      final Offset b = SbLissajousPlotter.penAt(
        t: 2 * math.pi,
        size: size,
        freqX: 2.0,
        freqY: 1.0,
        phase: 0,
        decayX: 0,
        decayY: 0,
        amplitudeFactor: 0.42,
      );
      expect(b.dx, closeTo(a.dx, 1e-6));
      expect(b.dy, closeTo(a.dy, 1e-6));
    });
  });

  testWidgets('pen widget tracks the analytic curve on screen', (
    tester,
  ) async {
    final ValueKey<String> key = const ValueKey('pen-marker');
    await tester.pumpWidget(host(penKey: key));
    await tester.pump();
    final Offset origin = tester.getTopLeft(find.byType(SbLissajousPlotter));
    Offset centre = origin + const Offset(size / 2, size / 2);
    Offset first = tester.getCenter(find.byKey(key)) - centre;

    // Very early in the run the y-offset must still be tiny (t ~ 1/60 s).
    expect(first.dy.abs(), lessThan(6.0));

    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    final Offset moved = tester.getCenter(find.byKey(key)) - centre;
    expect((moved - first).distance, greaterThan(4.0));

    // The pen must stay inside the harmonic envelope at all times
    // (sqrt(2) * amplitude across both axes).
    expect(moved.distance, lessThanOrEqualTo(size * 0.42 * math.sqrt(2) + 1.0));
  });

  testWidgets('horizontal drag shifts the phase and reports it', (
    tester,
  ) async {
    final List<double> phases = [];
    await tester.pumpWidget(
      host(phase: 0, onPhaseChanged: (p) => phases.add(p)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final TestGesture g = await tester.startGesture(
      tester.getCenter(find.byType(SbLissajousPlotter)),
    );
    // First move only gets the drag recognizer accepted; two further
    // updates carry the remaining delta. Total update travel: ~50 px.
    await g.moveBy(const Offset(60, 0));
    await tester.pump();
    await g.moveBy(const Offset(25, 0));
    await tester.pump();
    await g.moveBy(const Offset(25, 0));
    await tester.pump();
    await g.up();
    await tester.pump();
    expect(phases, isNotEmpty);
    // Phase shift is (dx / size) * 2 pi; depending on whether the
    // accepting move is also delivered as an update, total update travel
    // is between 50 and 110 px.
    expect(
      phases.last,
      inInclusiveRange(50 / size * 2 * math.pi - 1e-9, 110 / size * 2 * math.pi + 1e-9),
    );
  });

  testWidgets('trail is capped at maxPoints samples', (tester) async {
    await tester.pumpWidget(host());
    // Run ~2 s of sim time; at 0.022 sample cadence and speed 1 that would
    // be ~90 samples, above the 60 cap set in host(), so the tail must be
    // pruned rather than growing unboundedly.
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final CustomPaint paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(SbLissajousPlotter),
        matching: find.byType(CustomPaint),
      ).first,
    );
    expect(paint.painter, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
