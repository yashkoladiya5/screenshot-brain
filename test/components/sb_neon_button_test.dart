import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_neon_button.dart';

Widget _host({required VoidCallback onPressed, bool isPulsing = true}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SbNeonButton(
          onPressed: onPressed,
          isPulsing: isPulsing,
          child: const Text('LAUNCH'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the label and invokes onPressed on tap', (tester) async {
    int taps = 0;
    await tester.pumpWidget(_host(onPressed: () => taps++));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('LAUNCH'), findsOneWidget);

    await tester.tap(find.byType(SbNeonButton));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
  });

  testWidgets('the pulse glow animates over time when isPulsing', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onPressed: () {}));
    await tester.pump(const Duration(milliseconds: 10));

    final Finder container = find.descendant(
      of: find.byType(SbNeonButton),
      matching: find.byType(AnimatedContainer),
    );

    BoxDecoration target() =>
        (tester.widget<AnimatedContainer>(container).decoration
            as BoxDecoration);

    final double blurAtStart = target().boxShadow!.first.blurRadius;
    await tester.pump(const Duration(milliseconds: 700));
    final double blurLater = target().boxShadow!.first.blurRadius;

    // Glow oscillates (repeat(reverse: true)) -> intensity changes mid-pulse.
    expect(blurLater, isNot(blurAtStart));
  });

  testWidgets('inner glow uses BlurStyle.inner (SDK has no BoxShadow.inset)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onPressed: () {}, isPulsing: false));
    await tester.pump(const Duration(milliseconds: 10));

    final BoxDecoration decoration =
        tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byType(SbNeonButton),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration
            as BoxDecoration;
    final List<BoxShadow> shadows = decoration.boxShadow!;

    expect(
      shadows.any((BoxShadow s) => s.blurStyle == BlurStyle.inner),
      isTrue,
    );
  });

  testWidgets('DefaultTextStyle tints the child with the neon color', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onPressed: () {}));
    await tester.pump(const Duration(milliseconds: 10));

    final DefaultTextStyle textStyle = tester.widget(
      find.descendant(
        of: find.byType(SbNeonButton),
        matching: find.byType(DefaultTextStyle),
      ),
    );
    expect(textStyle.style.color, Colors.cyanAccent);
  });
}
