import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_pixel_dissolve_reveal.dart';

void main() {
  group('value noise math', () {
    test('hashPoint is deterministic and in [0, 1)', () {
      final double a = SbPixelDissolveReveal.hashPoint(3, 7, 1337);
      final double b = SbPixelDissolveReveal.hashPoint(3, 7, 1337);
      expect(a, b);
      expect(a, inInclusiveRange(0.0, 1.0));
      expect(SbPixelDissolveReveal.hashPoint(4, 7, 1337), isNot(a));
      // Different seeds must change the lattice.
      expect(SbPixelDissolveReveal.hashPoint(3, 7, 42), isNot(a));
    });

    test('valueNoise2d is smooth: continuous and bounded', () {
      double n(double x) =>
          SbPixelDissolveReveal.valueNoise2d(x, 0.5, 99);
      for (int i = 0; i < 40; i++) {
        final double x = i * 0.13;
        expect(n(x), inInclusiveRange(0.0, 1.0));
        // smootherstep keeps successive samples close; a hard bilinear on
        // raw hashes would still pass locally, but the derivative-zero
        // curve bounds the step tightly for a small epsilon.
        expect(
          (n(x + 0.001) - n(x)).abs(),
          lessThan(0.05),
        );
      }
      // Exact on the lattice: valueNoise at integer points equals the
      // hash of that lattice corner.
      expect(
        SbPixelDissolveReveal.valueNoise2d(5, 2, 1337),
        closeTo(SbPixelDissolveReveal.hashPoint(5, 2, 1337), 1e-12),
      );
    });

    test('cellThreshold stays in [0, 1] and is seed-stable', () {
      for (int col = 0; col < 8; col++) {
        for (int row = 0; row < 8; row++) {
          final double t = SbPixelDissolveReveal.cellThreshold(
            col: col,
            row: row,
            cols: 8,
            rows: 8,
            seed: 1337,
            radialBias: 0.35,
            radialCenter: const Offset(0.5, 0.5),
          );
          expect(t, inInclusiveRange(0.0, 1.0));
        }
      }
      expect(
        SbPixelDissolveReveal.cellThreshold(
          col: 3,
          row: 4,
          cols: 8,
          rows: 8,
          seed: 1337,
          radialBias: 0.35,
          radialCenter: const Offset(0.5, 0.5),
        ),
        SbPixelDissolveReveal.cellThreshold(
          col: 3,
          row: 4,
          cols: 8,
          rows: 8,
          seed: 1337,
          radialBias: 0.35,
          radialCenter: const Offset(0.5, 0.5),
        ),
      );
    });

    test('pure radial bias reveals centre first, corners last', () {
      double tAt(double cx, double cy, int col, int row) =>
          SbPixelDissolveReveal.cellThreshold(
            col: col,
            row: row,
            cols: 8,
            rows: 8,
            seed: 1337,
            radialBias: 1.0, // noise weight 0 -> deterministic geometry
            radialCenter: Offset(cx, cy),
          );
      final double centre = tAt(0.5, 0.5, 3, 3);
      final double corner = tAt(0.5, 0.5, 7, 7);
      expect(centre, lessThan(corner));
    });

    test('higher progress never reveals fewer cells', () {
      int visible(double p) {
        int n = 0;
        for (int col = 0; col < 10; col++) {
          for (int row = 0; row < 10; row++) {
            if (p >=
                SbPixelDissolveReveal.cellThreshold(
                  col: col,
                  row: row,
                  cols: 10,
                  rows: 10,
                  seed: 7,
                  radialBias: 0.35,
                  radialCenter: const Offset(0.5, 0.5),
                )) {
              n++;
            }
          }
        }
        return n;
      }

      final int early = visible(0.2);
      final int late = visible(0.8);
      final int all = visible(1.0);
      expect(early, lessThan(late));
      expect(late, lessThanOrEqualTo(all));
      expect(all, 100);
    });
  });

  group('widget dissolve', () {
    Widget host({
      required ValueChanged<double> onProgress,
      required VoidCallback onCompleted,
      bool autoPlay = true,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: SbPixelDissolveReveal(
                  pixelSize: 10,
                  duration: const Duration(milliseconds: 600),
                  autoPlay: autoPlay,
                  onProgressChanged: onProgress,
                  onRevealCompleted: onCompleted,
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        );

    testWidgets('autoPlay sweeps progress from 0 to 1 and completes once', (
      tester,
    ) async {
      final List<double> progress = [];
      int completions = 0;
      await tester.pumpWidget(
        host(
          onProgress: (p) => progress.add(p),
          onCompleted: () => completions++,
        ),
      );
      await tester.pump();
      expect(progress.first, lessThan(0.5));
      await tester.pump(const Duration(milliseconds: 300));
      final double mid = progress.last;
      expect(mid, greaterThan(0.2));
      expect(mid, lessThan(0.95));
      await tester.pumpAndSettle();
      expect(progress.last, 1.0);
      expect(completions, 1);

      // ClipPath mask exists around the child.
      expect(
        find.descendant(
          of: find.byType(SbPixelDissolveReveal),
          matching: find.byType(ClipPath),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tap replays the dissolve from zero', (tester) async {
      final List<double> progress = [];
      int completions = 0;
      await tester.pumpWidget(
        host(
          onProgress: (p) => progress.add(p),
          onCompleted: () => completions++,
        ),
      );
      await tester.pumpAndSettle();
      expect(completions, 1);

      await tester.tap(find.byType(SbPixelDissolveReveal));
      await tester.pump();
      expect(progress.last, lessThan(0.2)); // restarted
      await tester.pumpAndSettle();
      expect(progress.last, 1.0);
      expect(completions, 2);
    });

    testWidgets('autoPlay=false waits for a tap', (tester) async {
      final List<double> progress = [];
      await tester.pumpWidget(
        host(
          autoPlay: false,
          onProgress: (p) => progress.add(p),
          onCompleted: () {},
        ),
      );
      await tester.pumpAndSettle();
      expect(progress, isEmpty);
      await tester.tap(find.byType(SbPixelDissolveReveal));
      await tester.pumpAndSettle();
      expect(progress.last, 1.0);
    });
  });
}
