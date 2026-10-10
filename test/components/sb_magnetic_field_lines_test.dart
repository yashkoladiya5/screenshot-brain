import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_magnetic_field_lines.dart';

void main() {
  final Key northKey = UniqueKey();
  final Key southKey = UniqueKey();

  Widget host({ValueChanged<Offset>? onMagnetMoved}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SbMagneticFieldLines(
            size: 280,
            poleSeparation: 88,
            linesPerPole: 6,
            onMagnetMoved: onMagnetMoved,
            northPoleKey: northKey,
            southPoleKey: southKey,
          ),
        ),
      ),
    );
  }

  group('SbMagneticFieldLines.fieldAt (monopole-pair physics)', () {
    test('field points away from the north pole above the magnet', () {
      const Offset north = Offset(0, -44);
      const Offset south = Offset(0, 44);
      final Offset b = SbMagneticFieldLines.fieldAt(
        const Offset(0, -120),
        north,
        south,
      );
      // Screen coords: away from north (which sits on top) is -y.
      expect(b.dy, lessThan(0));
      expect(b.dx.abs(), lessThan(1e-6 * b.dy.abs() + 1e-9));
    });

    test('equatorial field is antiparallel to the dipole moment', () {
      const Offset north = Offset(0, -44);
      const Offset south = Offset(0, 44);
      final Offset b = SbMagneticFieldLines.fieldAt(
        const Offset(100, 0),
        north,
        south,
      );
      // Moment points S->N (screen -y); equatorial B must point +y.
      expect(b.dy, greaterThan(0));
      expect(b.dx.abs(), lessThan(1e-9));
    });

    test('magnitude follows the 1/d^2 pole falloff far away', () {
      const Offset north = Offset(0, -44);
      const Offset south = Offset(0, 44);
      final Offset near = SbMagneticFieldLines.fieldAt(
        const Offset(0, -200),
        north,
        south,
      );
      final Offset far = SbMagneticFieldLines.fieldAt(
        const Offset(0, -400),
        north,
        south,
      );
      // Doubled axial distance: nearly the 1/d^3 dipole falloff (the
      // finite pole separation adds small corrections).
      final double ratio = near.distance / far.distance;
      expect(ratio, inInclusiveRange(6.5, 9.5));
    });

    test('RK4 streamline stays on the field direction (straight axis)', () {
      const Offset north = Offset(0, -44);
      const Offset south = Offset(0, 44);
      // Seeded exactly on the axis above the north pole, the streamline
      // must remain vertical: every RK4 step has dx == 0.
      Offset p = const Offset(0, -60);
      for (int i = 0; i < 20; i++) {
        final Offset next = SbMagneticFieldLines.rk4Step(p, 4.0, north, south);
        expect(next.dx, closeTo(0, 1e-9));
        expect(next.dy, lessThan(p.dy));
        p = next;
      }
    });
  });

  testWidgets('renders both pole markers symmetric about the center', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 32));

    final Offset n = tester.getCenter(find.byKey(northKey));
    final Offset s = tester.getCenter(find.byKey(southKey));
    final Offset stage = tester.getCenter(find.byType(SbMagneticFieldLines));
    expect(n.dx, closeTo(s.dx, 0.01));
    expect(s.dy - n.dy, closeTo(88, 0.01));
    final Offset midpoint = (n + s) / 2;
    expect(midpoint.dx, closeTo(stage.dx, 0.5));
    expect(midpoint.dy, closeTo(stage.dy, 0.5));
  });

  testWidgets('dragging the magnet translates both poles exactly', (
    tester,
  ) async {
    final List<Offset> reports = [];
    await tester.pumpWidget(host(onMagnetMoved: reports.add));
    await tester.pump(const Duration(milliseconds: 32));

    final Offset nBefore = tester.getCenter(find.byKey(northKey));
    final Offset sBefore = tester.getCenter(find.byKey(southKey));

    await tester.drag(find.byType(SbMagneticFieldLines), const Offset(30, -20));
    await tester.pump(const Duration(milliseconds: 16));

    final Offset nAfter = tester.getCenter(find.byKey(northKey));
    final Offset sAfter = tester.getCenter(find.byKey(southKey));
    expect(nAfter - nBefore, const Offset(30, -20));
    expect(sAfter - sBefore, const Offset(30, -20));
    expect(reports, isNotEmpty);
    expect(reports.last.dx, closeTo(140 + 30, 0.5));
    expect(reports.last.dy, closeTo(140 - 20, 0.5));
  });

  testWidgets('magnet cannot be dragged outside the stage bounds', (
    tester,
  ) async {
    final List<Offset> reports = [];
    await tester.pumpWidget(host(onMagnetMoved: reports.add));
    await tester.pump(const Duration(milliseconds: 32));

    await tester.drag(
      find.byType(SbMagneticFieldLines),
      const Offset(900, 900),
    );
    await tester.pump(const Duration(milliseconds: 16));

    final Offset s = tester.getCenter(find.byKey(southKey));
    final Offset stage = tester.getTopLeft(find.byType(SbMagneticFieldLines));
    // South pole marker (16px wide) stays fully inside the stage.
    expect(s.dy, lessThanOrEqualTo(stage.dy + 280 - 8 + 0.01));
    expect(s.dx, lessThanOrEqualTo(stage.dx + 280 - 8 + 0.01));
    // Magnet center was clamped to (size - pad) on both axes: pad = 54.
    expect(reports.last.dx, closeTo(226, 0.5));
    expect(reports.last.dy, closeTo(226, 0.5));
  });

  testWidgets('compass needle animation keeps pumping without error', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    // The ticker runs forever (dash flow); pump a burst of frames and
    // assert the widget survives and still renders both poles.
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byKey(northKey), findsOneWidget);
    expect(find.byKey(southKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
