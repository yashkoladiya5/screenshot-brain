import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_gauge_chart.dart';

Widget host({required double value, String? label}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SbGaugeChart(value: value, label: label),
      ),
    ),
  );
}

void main() {
  testWidgets('SbGaugeChart shows exactly 70% for value 0.7', (tester) async {
    // Guards the rounding contract: the label must always show the nearest
    // whole percent, never one below it (see the 0.29 case below).
    await tester.pumpWidget(host(value: 0.7));
    await tester.pumpAndSettle();

    expect(find.text('70%'), findsOneWidget);
  });

  testWidgets('SbGaugeChart shows exactly 29% for value 0.29', (tester) async {
    // 0.29 * 100 == 28.999999999999996 in IEEE-754 doubles: truncating with
    // toInt() renders "28%" for a 29% gauge.
    await tester.pumpWidget(host(value: 0.29));
    await tester.pumpAndSettle();

    expect(find.text('29%'), findsOneWidget);
  });

  testWidgets('SbGaugeChart shows both range extremes', (tester) async {
    await tester.pumpWidget(host(value: 0.0));
    await tester.pumpAndSettle();
    expect(find.text('0%'), findsOneWidget);

    await tester.pumpWidget(host(value: 1.0, label: 'OCR accuracy'));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('OCR accuracy'), findsOneWidget);
  });

  testWidgets('SbGaugeChart updates the displayed percentage when the value changes', (
    tester,
  ) async {
    await tester.pumpWidget(host(value: 0.25));
    await tester.pumpAndSettle();
    expect(find.text('25%'), findsOneWidget);

    await tester.pumpWidget(host(value: 0.55));
    await tester.pumpAndSettle();
    expect(find.text('55%'), findsOneWidget);
  });
}
