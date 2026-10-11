import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_double_spring_tilt.dart';

void main() {
  group('springStep integrator', () {
    test('matches the analytic solution of an undamped oscillator', () {
      // zeta = 0, k = 100 -> omega = 10, x(t) = cos(10 t) from x0=1, v0=0.
      double x = 1.0, v = 0.0;
      const double k = 100.0, dt = 1 / 600;
      for (int i = 0; i < 600; i++) {
        final r = SbDoubleSpringTilt.springStep(
          x: x,
          v: v,
          target: 0,
          stiffness: k,
          dampingRatio: 0,
          dt: dt,
        );
        x = r.x;
        v = r.v;
      }
      // One full period later the semi-implicit Euler (symplectic) scheme
      // returns close to the start with bounded energy error.
      expect(x, closeTo(math.cos(10.0 * 1.0), 0.05));
      expect(v, closeTo(-10.0 * math.sin(10.0 * 1.0), 0.2));
    });

    test('underdamped chase overshoots the target, damped does not', () {
      double x = 0, v = 0;
      bool overshoot = false;
      for (int i = 0; i < 400; i++) {
        final r = SbDoubleSpringTilt.springStep(
          x: x,
          v: v,
          target: 1,
          stiffness: 180,
          dampingRatio: 0.3,
          dt: 1 / 60,
        );
        x = r.x;
        v = r.v;
        if (x > 1.05) overshoot = true;
      }
      expect(overshoot, isTrue);
      expect(x, closeTo(1, 1e-3));

      double xd = 0, vd = 0;
      bool pastTarget = false;
      for (int i = 0; i < 400; i++) {
        final r = SbDoubleSpringTilt.springStep(
          x: xd,
          v: vd,
          target: 1,
          stiffness: 180,
          dampingRatio: 1.0,
          dt: 1 / 60,
        );
        xd = r.x;
        vd = r.v;
        if (xd > 1.0001) pastTarget = true;
      }
      expect(pastTarget, isFalse);
      expect(xd, closeTo(1, 1e-2));
    });
  });

  Widget host({
    Key? tiltKey,
    ValueChanged<Offset>? onTiltChanged,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: SbDoubleSpringTilt(
                tiltKey: tiltKey,
                onTiltChanged: onTiltChanged,
                child: const ColoredBox(color: Colors.teal),
              ),
            ),
          ),
        ),
      );

  Matrix4 tiltMatrix(WidgetTester tester, Key key) =>
      tester.widget<Transform>(find.byKey(key)).transform;

  testWidgets('drag tilts the card and the matrix carries perspective', (
    tester,
  ) async {
    final key = UniqueKey();
    final List<Offset> tilts = [];
    await tester.pumpWidget(host(tiltKey: key, onTiltChanged: tilts.add));

    final Offset centre = tester.getCenter(find.byType(SbDoubleSpringTilt));
    final TestGesture g = await tester.startGesture(centre);
    await g.moveBy(const Offset(60, -30));
    // Integrate in sub-33 ms steps (the component clamps each tick to
    // 1/30 s, so one pump(200ms) would only advance 33 ms of physics).
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    // rotateY(angle) puts +sin(angle) in row 0 col 2; dragging right of
    // centre means a positive target, so the entry goes positive.
    expect(tiltMatrix(tester, key).entry(0, 2), greaterThan(0.01));
    // rotateX puts +sin in row 2 col 1; dragging *above* centre (negative
    // dy) maps to a negative X tilt target (tile faces away from the top).
    expect(tiltMatrix(tester, key).entry(2, 1), lessThan(-0.01));
    // Perspective lives in the w row (row 3, col 2) and survives
    // rotations: it must equal the configured depth scaled by tile size.
    expect(
      tiltMatrix(tester, key).entry(3, 2),
      closeTo(-0.0018 * (160 / 300), 1e-4),
    );

    // The visual tilt comes from the *follower*, which ramps toward the
    // driver instead of snapping: the first reported sample during the
    // hold is strictly smaller than the latest one.
    final Offset last = tilts.last;
    expect(tilts.length, greaterThan(2));
    expect(tilts.first.dx.abs(), lessThan(last.dx.abs()));
    await g.up();
    await tester.pumpAndSettle();
  });

  testWidgets('release with fling rings out: sign change then rest at zero', (
    tester,
  ) async {
    final key = UniqueKey();
    final List<Offset> tilts = [];
    await tester.pumpWidget(host(tiltKey: key, onTiltChanged: tilts.add));

    final Offset centre = tester.getCenter(find.byType(SbDoubleSpringTilt));
    final TestGesture g = await tester.startGesture(centre);
    // Two timed moves build real pointer velocity (~800 px/s on the last).
    await g.moveBy(const Offset(15, 0),
        timeStamp: const Duration(milliseconds: 25));
    await tester.pump(const Duration(milliseconds: 25));
    await g.moveBy(const Offset(40, 0),
        timeStamp: const Duration(milliseconds: 50));
    // Hold long enough for the springs to visibly charge before release.
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 25));
    }
    await g.up();

    // At release the follower tilt is positive (dragged right).
    expect(tilts.last.dx, greaterThan(0.01));

    // Fling velocity is injected into the driver, so the cascade rings:
    // the follower swings *past* zero to the opposite side.
    for (int i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 25));
    }
    expect(tilts.any((o) => o.dx < -0.01), isTrue);

    // And it must settle back to gyro-rest.
    await tester.pumpAndSettle();
    expect(tiltMatrix(tester, key).entry(0, 2), closeTo(0, 1e-3));
    expect(tiltMatrix(tester, key).entry(2, 1), closeTo(0, 1e-3));
  });

  testWidgets('tilt is exactly zero at rest before any interaction', (
    tester,
  ) async {
    final key = UniqueKey();
    await tester.pumpWidget(host(tiltKey: key));
    await tester.pump();
    expect(tiltMatrix(tester, key).entry(0, 2), 0.0);
    expect(tiltMatrix(tester, key).entry(1, 2), 0.0);
  });
}
