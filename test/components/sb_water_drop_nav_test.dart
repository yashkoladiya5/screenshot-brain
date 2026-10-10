import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_water_drop_nav.dart';

const List<SbWaterDropNavItem> _items = [
  SbWaterDropNavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
  ),
  SbWaterDropNavItem(
    icon: Icons.search_outlined,
    activeIcon: Icons.search,
    label: 'Search',
  ),
  SbWaterDropNavItem(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
  ),
];

Widget _host({required int selected, required ValueChanged<int> onSelect}) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const Expanded(child: SizedBox.shrink()),
          SbWaterDropNav(
            items: _items,
            selectedIndex: selected,
            onItemSelected: onSelect,
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('renders every item with its inactive icon and label', (
    tester,
  ) async {
    await tester.pumpWidget(_host(selected: 0, onSelect: (_) {}));
    await tester.pump(const Duration(milliseconds: 50));

    // Selected item shows its active icon and hides the label.
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    // Unselected items show their icon plus label.
    expect(find.byIcon(Icons.search_outlined), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('tapping another tab reports the new index', (tester) async {
    final List<int> selected = [];
    await tester.pumpWidget(_host(selected: 0, onSelect: selected.add));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pump();

    expect(selected, [1]);
  });

  testWidgets('tapping the already-selected tab does not re-emit', (
    tester,
  ) async {
    final List<int> selected = [];
    await tester.pumpWidget(_host(selected: 1, onSelect: selected.add));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    expect(selected, isEmpty);
  });

  testWidgets('switching selectedIndex animates the drop and updates icons', (
    tester,
  ) async {
    await tester.pumpWidget(_host(selected: 0, onSelect: (_) {}));
    await tester.pump(const Duration(milliseconds: 50));

    // Parent rebuilds with the new index (controlled widget).
    await tester.pumpWidget(_host(selected: 2, onSelect: (_) {}));
    // The 400ms drop travel animation must not throw mid-flight.
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
