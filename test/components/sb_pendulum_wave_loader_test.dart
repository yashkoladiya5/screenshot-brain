import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_pendulum_wave_loader.dart';

void main() {
  const double width = 300.0;
  const double height = 200.0;
  const int count = 5;
  const int baseSwings = 8;
  const double amp = 0.45;
  const Duration cycle = Duration(milliseconds: 240);

  const SbPendulumWaveLoader loader = SbPendulumWaveLoader(
    width: width,
    height: height,
    count: count,
    baseSwings: baseSwings,
    cycle: cycle,
    amplitudeRadians: amp,
    bobRadius: 8.0,
  );

  group('pendulum-wave math', () {
    test('oscillation counts are consecutive integers', () {
      for (int i = 0; i < count; i++) {
        expect(loader.swingsAt(i), baseSwings + i);
      }
    });

    test('lengths follow T = 2 pi sqrt(L/g): L_i ~ (n_min / n_i)^2', () {
      final double l0 = loader.lengthAt(0, 100);
      expect(l0, 100.0);
      expect(loader.lengthAt(1, 100), closeTo(100 * math.pow(8 / 9, 2), 1e-9));
      expect(loader.lengthAt(4, 100), closeTo(100 * math.pow(8 / 12, 2), 1e-9));
      // Strictly shorter as counts grow.
      for (int i = 1; i < count; i++) {
        expect(loader.lengthAt(i, 100), lessThan(loader.lengthAt(i - 1, 100)));
      }
    });

    test('angleAt is the small-angle closed form', () {
      expect(loader.angleAt(0, 2), closeTo(amp, 1e-12));
      // At half of pendulum 0's own period (cycle / (2 * n_0) = 15 ms)
      // its angle is exactly flipped.
      expect(loader.angleAt(0.015, 0), closeTo(-amp, 1e-6));
      // At the common cycle every integer count returns to +A.
      final double tC = cycle.inMicroseconds / 1e6;
      for (int i = 0; i < count; i++) {
        expect(loader.angleAt(tC, i), closeTo(amp, 1e-6));
      }
    });
  });

  Offset originOf(WidgetTester tester) =>
      tester.getTopLeft(find.byType(SbPendulumWaveLoader));

  Offset bobCentre(WidgetTester tester, int i) =>
      tester.getCenter(find.byKey(ValueKey('sb-pwl-bob-$i'))) -
      originOf(tester);

  Future<void> pumpMs(WidgetTester tester, int total, int step) async {
    for (int t = 0; t < total; t += step) {
      await tester.pump(Duration(milliseconds: step));
    }
  }

  testWidgets('bobs hang at the release angle at t=0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, height: height, child: loader),
          ),
        ),
      ),
    );
    // One frame at elapsed 0: simulation time is still zero.
    await tester.pump();
    for (int i = 0; i < count; i++) {
      final Offset expected = loader.bobAt(i, 0);
      expect(bobCentre(tester, i).dx, closeTo(expected.dx, 1.5));
      expect(bobCentre(tester, i).dy, closeTo(expected.dy, 1.5));
    }
  });

  testWidgets('half a cycle: even counts stay right, odd counts flip left', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, height: height, child: loader),
          ),
        ),
      ),
    );
    await tester.pump();
    final Map<int, Offset> initial = {
      for (int i = 0; i < count; i++) i: bobCentre(tester, i),
    };

    await pumpMs(tester, cycle.inMilliseconds ~/ 2, 20); // 120 ms

    for (int i = 0; i < count; i++) {
      final double theta = loader.angleAt(0.120, i);
      final Offset pivot = loader.pivotAt(i);
      final double l = loader.lengthAt(i, height * 0.72);
      final double xExpected = pivot.dx + l * math.sin(theta);
      expect(bobCentre(tester, i).dx, closeTo(xExpected, 2.0));
    }
    // n_0 = 8 (even) -> still near its release side; n_1 = 9 -> mirrored.
    expect(
      bobCentre(tester, 0).dx - initial[0]!.dx,
      lessThan(3.0),
    );
    expect(
      bobCentre(tester, 1).dx,
      lessThan(initial[1]!.dx - 10.0),
    );
    // The integer-ratio structure: ALL even-count bobs are back in phase,
    // ALL odd-count bobs exactly mirrored.
    expect(
      (bobCentre(tester, 2).dx - initial[2]!.dx).abs(),
      lessThan(3.0),
      reason: 'bob 2 (10 swings) must be in phase at T/2',
    );
    expect(
      bobCentre(tester, 3).dx,
      lessThan(initial[3]!.dx - 10.0),
      reason: 'bob 3 (11 swings) must be anti-phase at T/2',
    );
  });

  testWidgets('a full cycle re-phases the whole wave exactly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, height: height, child: loader),
          ),
        ),
      ),
    );
    await tester.pump();
    final Map<int, Offset> initial = {
      for (int i = 0; i < count; i++) i: bobCentre(tester, i),
    };

    // The mid-cycle snapshot is far from home...
    await pumpMs(tester, cycle.inMilliseconds ~/ 2, 20);
    final midDeviation =
        (bobCentre(tester, 1) - initial[1]!).distance;
    expect(midDeviation, greaterThan(10.0));

    // ...and after the common period EVERY bob is back at the release
    // position — the defining property of integer harmonic ratios.
    await pumpMs(tester, cycle.inMilliseconds ~/ 2, 20);
    for (int i = 0; i < count; i++) {
      expect(
        (bobCentre(tester, i) - initial[i]!).distance,
        lessThan(1.0),
        reason: 'bob $i must return home at t=cycle',
      );
    }
  });
}
