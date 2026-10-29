import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/color_extensions.dart';
import 'package:screenshot_brain/core/utils/constants.dart';
import 'package:screenshot_brain/core/utils/object_extensions.dart';
import 'package:screenshot_brain/core/utils/scroll_utils.dart';

Widget _scrollList(
  ScrollController controller, {
  int count = 100,
  ScrollPhysics? physics,
  ScrollBehavior? scrollBehavior,
}) {
  Widget list = ListView(
    controller: controller,
    physics: physics,
    children: [
      for (var i = 0; i < count; i++)
        SizedBox(height: 50, child: Text('Item $i')),
    ],
  );
  if (scrollBehavior != null) {
    list = ScrollConfiguration(behavior: scrollBehavior, child: list);
  }
  return MaterialApp(
    home: Scaffold(body: SizedBox.expand(child: list)),
  );
}

/// Invokes the helper without awaiting its future: awaiting an `animateTo`
/// future inside a widget test hangs the fake-async clock (documented
/// Flutter framework behaviour), so tests fire the animation and pump.
void _fireScroll(Future<void> future) {
  // Ignore: completion is driven by pumping frames.
  future;
}

class _StretchingBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return ScrollUtils.buildOverscrollIndicator(context, child, details);
  }
}

void main() {
  group('ObjectExtensions.let', () {
    test('returns the block result and receives the receiver', () {
      var seen = -1;
      final result = 21.let((value) {
        seen = value;
        return value * 2;
      });
      expect(result, 42);
      expect(seen, 21);
    });

    test('does not guard null: the block runs with a null argument', () {
      // Contrast with letIfNotNull: `let` is Kotlin-style and always invokes.
      final String? nullableName = null;
      final result = nullableName.let((value) => value == null ? 'ran' : 'no');
      expect(result, 'ran');
    });

    test('can change type and is chainable', () {
      expect(5.let((v) => '$v!').let((s) => s.length), 2);
    });

    test('also returns the identical receiver and runs side effects once', () {
      final calls = <String>[];
      final buffer = StringBuffer();
      final returned = buffer.also((b) => calls.add('first')).also((b) {
        b.write('x');
        calls.add('second');
      });
      expect(identical(returned, buffer), isTrue);
      expect(calls, ['first', 'second']);
      expect(buffer.toString(), 'x');
    });

    test('also passes the receiver (including null) to the block', () {
      Object? captured = 'sentinel';
      final String? nothing = null;
      final result = nothing.also((value) => captured = value);
      expect(captured, isNull);
      expect(result, isNull);
    });
  });

  group('NullableObjectExtensions.letIfNotNull', () {
    test('null receiver: block is skipped and null is returned', () {
      var invoked = false;
      final String? value = null;
      final result = value.letIfNotNull((v) {
        invoked = true;
        return v.length;
      });
      expect(result, isNull);
      expect(invoked, isFalse);
    });

    // Gives a value a nullable static type, as real optional data (JSON
    // lookups, query params) would, so the null-guard behaviour applies.
    T? maybe<T>(T value) => value;

    test('non-null receiver: block runs with the promoted value', () {
      final value = maybe('abcd');
      expect(value.letIfNotNull((v) => v.length), 4);
    });

    test('falsy-but-non-null receivers still invoke the block', () {
      final flag = maybe(false);
      final empty = maybe('');
      final zero = maybe(0);
      expect(flag.letIfNotNull((v) => !v), isTrue);
      expect(empty.letIfNotNull((v) => v.isEmpty), isTrue);
      expect(zero.letIfNotNull((v) => v + 1), 1);
    });

    test('a block returning null yields null', () {
      final value = maybe('text');
      expect(value.letIfNotNull((v) => int.tryParse(v)), isNull);
    });

    test('chains: second letIfNotNull short-circuits on a null result', () {
      final value = maybe('12');
      final result = value
          .letIfNotNull((v) => int.tryParse(v))
          .letIfNotNull((i) => i * 10);
      expect(result, 120);

      final bad = maybe('not-a-number');
      final badResult = bad
          .letIfNotNull((v) => int.tryParse(v))
          .letIfNotNull((i) => i * 10);
      expect(badResult, isNull);
    });
  });

  group('ColorExtensions.darken / lighten', () {
    double lightnessOf(Color color) => HSLColor.fromColor(color).lightness;

    const base = Color(0xFF7F1D1D); // dark-ish red, hue 0, mid saturation

    test('default amount shifts lightness by 0.1 in each direction', () {
      final baseL = lightnessOf(base);
      expect(lightnessOf(base.darken()), closeTo(baseL - 0.1, 0.005));
      expect(lightnessOf(base.lighten()), closeTo(baseL + 0.1, 0.005));
    });

    test('amount 0 is a no-op returning the identical color value', () {
      expect(base.darken(0), base);
      expect(base.lighten(0), base);
    });

    test('full darken of white clamps to black and full lighten of black '
        'clamps to white', () {
      expect(Colors.white.darken(1.0), const Color(0xFF000000));
      expect(Colors.black.lighten(1.0), const Color(0xFFFFFFFF));
    });

    test('clamping at the extremes: cannot go below black or above white', () {
      expect(Colors.black.darken(0.5), const Color(0xFF000000));
      expect(Colors.white.lighten(0.5), const Color(0xFFFFFFFF));
      expect(lightnessOf(Colors.grey.darken(1.0)), 0.0);
      expect(lightnessOf(Colors.grey.lighten(1.0)), 1.0);
    });

    test('hue and saturation are preserved, only lightness changes', () {
      const red = Color(0xFFFF0000);
      final hsl = HSLColor.fromColor(red.darken(0.2));
      expect(hsl.hue, closeTo(0.0, 0.001));
      expect(hsl.saturation, closeTo(1.0, 0.001));
      expect(hsl.lightness, closeTo(0.5 - 0.2, 0.005));
    });

    test('alpha (opacity) survives darken/lighten round-trip', () {
      const translucent = Color(0x80FF8800);
      expect(translucent.darken(0.2).a, translucent.a);
      expect(translucent.lighten(0.2).a, translucent.a);
      expect(translucent.darken(0.2).lighten(0.2).a, translucent.a);
      // Fully transparent stays fully transparent.
      expect(const Color(0x00123456).darken(0.4).a, 0.0);
      expect(const Color(0x00123456).lighten(0.4).a, 0.0);
    });

    test('darkening more yields a strictly darker color (monotonic)', () {
      final l0 = lightnessOf(base);
      final l1 = lightnessOf(base.darken(0.1));
      final l2 = lightnessOf(base.darken(0.2));
      expect(l1, lessThan(l0));
      expect(l2, lessThan(l1));
    });

    test('darken then lighten round-trips lightness within quantization '
        'error', () {
      // Colors are 8-bit quantized, so the round trip cannot be bit-exact.
      // Keep the intermediate lightness away from the 0/1 extremes, where
      // quantization collapses saturation and the round trip degrades.
      final back = base.darken(0.1).lighten(0.1);
      expect(lightnessOf(back), closeTo(lightnessOf(base), 0.01));
      for (final (a, b) in [
        (back.r, base.r),
        (back.g, base.g),
        (back.b, base.b),
      ]) {
        expect((a - b).abs(), lessThanOrEqualTo(0.012)); // ~3/255
      }
    });

    test('out-of-range amounts assert in debug mode', () {
      expect(() => base.darken(-0.01), throwsA(isA<AssertionError>()));
      expect(() => base.darken(1.01), throwsA(isA<AssertionError>()));
      expect(() => base.lighten(-0.5), throwsA(isA<AssertionError>()));
      expect(() => base.lighten(2.0), throwsA(isA<AssertionError>()));
      // Boundary values 0 and 1 are valid.
      expect(base.darken(0.0), base);
      expect(base.lighten(1.0), isA<Color>());
    });

    test('hex parsing: darken/lighten act on ARGB-parsed colors correctly', () {
      // Pure blue channel: only .b set; darkening must scale it down,
      // lightening pushes toward a paler blue with hue preserved.
      // (Amount 0.3, not 0.5: a full 0.5 shift lands exactly on black/white,
      // where hue is undefined.)
      const pureBlue = Color(0xFF0000FF);
      final darker = pureBlue.darken(0.3);
      expect(darker.b, lessThan(pureBlue.b));
      expect(HSLColor.fromColor(darker).hue, closeTo(240.0, 1.0));
      final lighter = pureBlue.lighten(0.3);
      expect(lighter.r, greaterThan(pureBlue.r));
      expect(HSLColor.fromColor(lighter).hue, closeTo(240.0, 1.0));
    });
  });

  group('AppConstants', () {
    test('identity constants match the documented app contract', () {
      expect(AppConstants.appName, 'Screenshot Brain');
      expect(AppConstants.screenshotsFolder, 'Screenshots');
    });

    test('numeric configuration constants are within valid ranges', () {
      expect(AppConstants.ocrConfidenceThreshold, 70);
      expect(AppConstants.ocrConfidenceThreshold, inInclusiveRange(0, 100));
      expect(AppConstants.maxRecentScreenshots, 50);
      expect(AppConstants.maxRecentScreenshots, greaterThan(0));
    });

    test('date format patterns are the expected intl patterns', () {
      expect(AppConstants.dateFormat, 'dd MMM yyyy');
      expect(AppConstants.dateTimeFormat, 'dd MMM yyyy HH:mm');
      expect(AppConstants.dateTimeFormat, startsWith(AppConstants.dateFormat));
    });
  });

  group('ScrollUtils', () {
    testWidgets('scrollToTop is a safe no-op for an unattached controller', (
      tester,
    ) async {
      final controller = ScrollController();
      await ScrollUtils.scrollToTop(controller);
      expect(controller.hasClients, isFalse);
      controller.dispose();
    });

    testWidgets('scrollToBottom is a safe no-op for an unattached controller', (
      tester,
    ) async {
      final controller = ScrollController();
      await ScrollUtils.scrollToBottom(controller);
      expect(controller.hasClients, isFalse);
      controller.dispose();
    });

    testWidgets('helpers are safe after the scrollable is disposed', (
      tester,
    ) async {
      final controller = ScrollController();
      await tester.pumpWidget(_scrollList(controller, count: 20));
      expect(controller.hasClients, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(controller.hasClients, isFalse);
      await ScrollUtils.scrollToTop(controller);
      await ScrollUtils.scrollToBottom(controller);
      controller.dispose();
    });

    testWidgets('scrollToTop returns a scrolled list to offset 0', (
      tester,
    ) async {
      final controller = ScrollController();
      await tester.pumpWidget(_scrollList(controller));
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(controller.position.pixels, greaterThan(0));

      _fireScroll(ScrollUtils.scrollToTop(controller));
      await tester.pumpAndSettle();
      expect(controller.position.pixels, 0.0);
      controller.dispose();
    });

    testWidgets('scrollToTop when already at the target completes cleanly', (
      tester,
    ) async {
      final controller = ScrollController();
      await tester.pumpWidget(_scrollList(controller));
      _fireScroll(ScrollUtils.scrollToTop(controller));
      await tester.pumpAndSettle();
      expect(controller.position.pixels, 0.0);
      controller.dispose();
    });

    testWidgets('scrollToBottom lands exactly on maxScrollExtent and shows '
        'the last item (no off-by-one)', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(_scrollList(controller, count: 100));

      _fireScroll(ScrollUtils.scrollToBottom(controller));
      await tester.pumpAndSettle();

      final position = controller.position;
      expect(position.pixels, position.maxScrollExtent);
      expect(find.text('Item 99'), findsOneWidget);
      // First item is far outside the cache extent once fully scrolled.
      expect(find.text('Item 0'), findsNothing);
      controller.dispose();
    });

    testWidgets('scrollToBottom already at the bottom stays put', (
      tester,
    ) async {
      final controller = ScrollController();
      await tester.pumpWidget(_scrollList(controller));
      controller.jumpTo(controller.position.maxScrollExtent);
      final max = controller.position.maxScrollExtent;

      _fireScroll(ScrollUtils.scrollToBottom(controller));
      await tester.pumpAndSettle();
      expect(controller.position.pixels, max);
      controller.dispose();
    });

    testWidgets('zero-extent viewport (content smaller than viewport)', (
      tester,
    ) async {
      final controller = ScrollController();
      // Two short items in an expanded viewport: nothing to scroll.
      await tester.pumpWidget(_scrollList(controller, count: 2));
      expect(controller.position.maxScrollExtent, 0.0);

      _fireScroll(ScrollUtils.scrollToBottom(controller));
      await tester.pumpAndSettle();
      expect(controller.position.pixels, 0.0);

      _fireScroll(ScrollUtils.scrollToTop(controller));
      await tester.pumpAndSettle();
      expect(controller.position.pixels, 0.0);
      controller.dispose();
    });

    testWidgets('scrollToTop recovers from a negative overscrolled offset', (
      tester,
    ) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        _scrollList(controller, physics: const BouncingScrollPhysics()),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ListView)),
      );
      await gesture.moveBy(const Offset(0, 150)); // overscroll past the top
      await gesture.up();
      expect(controller.position.pixels, lessThan(0));

      _fireScroll(ScrollUtils.scrollToTop(controller));
      await tester.pumpAndSettle();
      expect(controller.position.pixels, 0.0);
      controller.dispose();
    });

    testWidgets('custom duration is honoured: animation is in flight after '
        'partial pumping', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(_scrollList(controller));
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final start = controller.position.pixels;
      expect(start, greaterThan(0));

      _fireScroll(
        ScrollUtils.scrollToTop(
          controller,
          duration: const Duration(milliseconds: 400),
        ),
      );
      // First pump starts the animation ticker; only later pumps advance it.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.position.pixels, greaterThan(0));
      expect(controller.position.pixels, lessThan(start));

      await tester.pumpAndSettle();
      expect(controller.position.pixels, 0.0);
      controller.dispose();
    });

    testWidgets('zero duration is rejected by the animateTo contract', (
      tester,
    ) async {
      final controller = ScrollController();
      await tester.pumpWidget(_scrollList(controller));
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();

      await expectLater(
        ScrollUtils.scrollToTop(controller, duration: Duration.zero),
        throwsA(isA<AssertionError>()),
      );
      controller.dispose();
    });

    testWidgets('scrollToBottom works with one controller attached to '
        'multiple scroll views (regression: threw StateError)', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: ListView(
                    controller: controller,
                    children: [
                      for (var i = 0; i < 20; i++)
                        SizedBox(height: 50, child: Text('A$i')),
                    ],
                  ),
                ),
                SizedBox(
                  height: 250,
                  child: ListView(
                    controller: controller,
                    children: [
                      for (var i = 0; i < 40; i++)
                        SizedBox(height: 50, child: Text('B$i')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(controller.positions.length, 2);

      _fireScroll(ScrollUtils.scrollToBottom(controller));
      await tester.pumpAndSettle();

      for (final position in controller.positions) {
        expect(position.pixels, position.maxScrollExtent);
      }
      controller.dispose();
    });

    testWidgets('scrollToTop works with one controller attached to '
        'multiple scroll views (regression: controller.animateTo threw '
        'StateError via controller.position)', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: ListView(
                    controller: controller,
                    children: [
                      for (var i = 0; i < 20; i++)
                        SizedBox(height: 50, child: Text('A$i')),
                    ],
                  ),
                ),
                SizedBox(
                  height: 250,
                  child: ListView(
                    controller: controller,
                    children: [
                      for (var i = 0; i < 40; i++)
                        SizedBox(height: 50, child: Text('B$i')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(controller.positions.length, 2);

      // Scroll both views away from the top so the call has work to do.
      await tester.drag(find.byType(ListView).first, const Offset(0, -100));
      await tester.drag(find.byType(ListView).last, const Offset(0, -120));
      await tester.pumpAndSettle();
      for (final position in controller.positions) {
        expect(position.pixels, greaterThan(0));
      }

      _fireScroll(ScrollUtils.scrollToTop(controller));
      await tester.pumpAndSettle();

      for (final position in controller.positions) {
        expect(position.pixels, 0.0);
      }
      controller.dispose();
    });

    testWidgets('buildOverscrollIndicator returns a stretching indicator '
        'wrapping the exact child with the scrollable direction', (
      tester,
    ) async {
      late BuildContext capturedContext;
      final child = const Text('content');
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return child;
            },
          ),
        ),
      );

      const details = ScrollableDetails(direction: AxisDirection.right);
      final indicator = ScrollUtils.buildOverscrollIndicator(
        capturedContext,
        child,
        details,
      );

      expect(indicator, isA<StretchingOverscrollIndicator>());
      final stretching = indicator as StretchingOverscrollIndicator;
      expect(identical(stretching.child, child), isTrue);
      expect(stretching.axisDirection, AxisDirection.right);

      for (final direction in AxisDirection.values) {
        final built =
            ScrollUtils.buildOverscrollIndicator(
                  capturedContext,
                  child,
                  ScrollableDetails(direction: direction),
                )
                as StretchingOverscrollIndicator;
        expect(built.axisDirection, direction);
      }
    });

    testWidgets('installed as an overscroll indicator in a real scroll tree', (
      tester,
    ) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        _scrollList(
          controller,
          count: 10,
          scrollBehavior: _StretchingBehavior(),
        ),
      );
      expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
      controller.dispose();
    });
  });
}
