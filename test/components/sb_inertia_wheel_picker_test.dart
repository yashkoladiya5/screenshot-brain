import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_inertia_wheel_picker.dart';

const List<String> _items = [
  'Zero',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Twelve',
];

Widget _host({
  required int initialIndex,
  ValueChanged<int>? onChanged,
  Key? selectedKey,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 260,
          child: SbInertiaWheelPicker(
            items: _items,
            initialIndex: initialIndex,
            onSelectionChanged: onChanged,
            itemExtent: 44,
            height: 240,
            selectedKey: selectedKey,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the initial selection centered', (tester) async {
    final key = UniqueKey();
    await tester.pumpWidget(_host(initialIndex: 4, selectedKey: key));
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('Four'), findsOneWidget);
    final Finder selected = find.byKey(key);
    expect(selected, findsOneWidget);

    // The selected label must sit on the focal line (widget center).
    final Offset pickerCenter = tester.getCenter(
      find.byType(SbInertiaWheelPicker),
    );
    final Offset selectedCenter = tester.getCenter(selected);
    expect(selectedCenter.dy, closeTo(pickerCenter.dy, 1.0));
  });

  testWidgets('dragging down by 2 item extents selects index - 2', (
    tester,
  ) async {
    final key = UniqueKey();
    final List<int> emitted = [];
    await tester.pumpWidget(
      _host(initialIndex: 6, selectedKey: key, onChanged: emitted.add),
    );
    await tester.pump(const Duration(milliseconds: 50));

    await tester.drag(
      find.byType(SbInertiaWheelPicker),
      const Offset(0, 2 * 44),
    );
    await tester.pumpAndSettle();

    // Direct manipulation: finger moves down, earlier items arrive.
    expect(emitted.last, 4);
    expect(tester.widget<Text>(find.byKey(key)).data, 'Four');
  });

  testWidgets('fling coasts under friction and snaps onto a detent', (
    tester,
  ) async {
    final key = UniqueKey();
    final List<int> emitted = [];
    await tester.pumpWidget(
      _host(initialIndex: 0, selectedKey: key, onChanged: emitted.add),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Fling upward: wheel spins toward later items.
    await tester.fling(
      find.byType(SbInertiaWheelPicker),
      const Offset(0, -120),
      1000,
    );

    // During the fling gesture the finger itself advances the wheel by
    // 120/44 = 2.7 items. With v0 = 1000/44 = 22.7 items/s capped at 18
    // and viscous friction k = 3.2, the analytic coast adds
    // v0/k = 5.6 items, so the detent lands near 8.
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final int early = emitted.isEmpty ? 0 : emitted.last;

    await tester.pumpAndSettle();

    expect(emitted, isNotEmpty);
    final int finalIndex = emitted.last;
    // The wheel kept coasting for a long time after the first 160ms.
    expect(finalIndex, greaterThan(early));
    expect(finalIndex, inInclusiveRange(7, 9));
    expect(tester.widget<Text>(find.byKey(key)).data, _items[finalIndex]);

    // Detent geometry: after settling, selected label is centered again
    // and its immediate neighbour sits one arc slot lower. The chord is
    // R*sin(pitch) = itemExtent * sin(pitch)/pitch with pitch = pi/7.
    final Offset pickerCenter = tester.getCenter(
      find.byType(SbInertiaWheelPicker),
    );
    final Offset selCenter = tester.getCenter(find.byKey(key));
    expect(selCenter.dy, closeTo(pickerCenter.dy, 1.0));
    final double slotChord = 44 * math.sin(math.pi / 7) / (math.pi / 7);
    final Offset neighbourCenter = tester.getCenter(
      find.text(_items[finalIndex + 1]),
    );
    expect(neighbourCenter.dy - selCenter.dy, closeTo(slotChord, 1.5));
  });

  testWidgets('tapping an off-center item springs the wheel to it', (
    tester,
  ) async {
    final key = UniqueKey();
    final List<int> emitted = [];
    await tester.pumpWidget(
      _host(initialIndex: 3, selectedKey: key, onChanged: emitted.add),
    );
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Five'));
    await tester.pumpAndSettle();

    expect(emitted.last, 5);
    expect(tester.widget<Text>(find.byKey(key)).data, 'Five');
  });

  testWidgets('clamps to the last item and stops', (tester) async {
    final key = UniqueKey();
    final List<int> emitted = [];
    await tester.pumpWidget(
      _host(initialIndex: 10, selectedKey: key, onChanged: emitted.add),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Massive fling upward: must not overshoot past the final item.
    await tester.fling(
      find.byType(SbInertiaWheelPicker),
      const Offset(0, -600),
      3000,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(emitted.last, _items.length - 1);
    expect(tester.widget<Text>(find.byKey(key)).data, 'Twelve');
  });

  testWidgets('velocity cap keeps flings sane (no negative index)', (
    tester,
  ) async {
    final key = UniqueKey();
    final List<int> emitted = [];
    await tester.pumpWidget(
      _host(initialIndex: 1, selectedKey: key, onChanged: emitted.add),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(SbInertiaWheelPicker)),
    );
    await gesture.moveBy(const Offset(0, 120));
    await gesture.moveBy(const Offset(0, 120));
    await gesture.moveBy(const Offset(0, 160));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(emitted, isNotEmpty);
    expect(emitted.last, greaterThanOrEqualTo(0));
    expect(emitted.last, 0); // hard stop at the first item
  });
}
