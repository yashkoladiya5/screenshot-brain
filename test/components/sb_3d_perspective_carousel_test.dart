import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/components/sb_3d_perspective_carousel.dart';

Widget _host({required int count, double radius = 160}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Sb3dPerspectiveCarousel(
          radius: radius,
          itemWidth: 100,
          itemHeight: 140,
          items: List<Widget>.generate(
            count,
            (i) => Text('Item $i', key: Key('item-$i')),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders all items with the first one in front and centered', (
    tester,
  ) async {
    await tester.pumpWidget(_host(count: 4));
    await tester.pump(const Duration(milliseconds: 50));

    for (int i = 0; i < 4; i++) {
      expect(find.byKey(Key('item-$i')), findsOneWidget);
    }

    // At angle 0, item 0 sits at the front (xOffset == 0 => widget center).
    final Offset carouselCenter = tester.getCenter(
      find.byType(Sb3dPerspectiveCarousel),
    );
    final Offset frontCenter = tester.getCenter(
      find.byKey(const Key('item-0')),
    );
    expect(frontCenter.dx, closeTo(carouselCenter.dx, 1.0));

    // Its neighbours are swung out to +/- radius along the sine curve.
    final Offset right = tester.getCenter(find.byKey(const Key('item-1')));
    final Offset left = tester.getCenter(find.byKey(const Key('item-3')));
    expect(right.dx - carouselCenter.dx, closeTo(160.0, 2.0));
    expect(left.dx - carouselCenter.dx, closeTo(-160.0, 2.0));
  });

  testWidgets('depth sorting puts the front-most item last in the stack', (
    tester,
  ) async {
    await tester.pumpWidget(_host(count: 4));
    await tester.pump(const Duration(milliseconds: 50));

    // The stack paints children back-to-front, so the item with the greatest
    // depth must be the last painted. Opacity widgets appear in child order.
    final List<double> opacities = find
        .descendant(
          of: find.byType(Sb3dPerspectiveCarousel),
          matching: find.byType(Opacity),
        )
        .evaluate()
        .map((e) => (e.widget as Opacity).opacity)
        .toList();
    // Sorted ascending by depth means the last rendered child is the
    // front item (full opacity, depth == 1 at angle 0).
    expect(opacities.length, greaterThanOrEqualTo(2));
    expect(opacities.last, 1.0);
  });

  testWidgets('drag rotates the ring and release snaps one item to front', (
    tester,
  ) async {
    await tester.pumpWidget(_host(count: 4, radius: 160));
    await tester.pump(const Duration(milliseconds: 50));

    final Offset carouselCenter = tester.getCenter(
      find.byType(Sb3dPerspectiveCarousel),
    );

    final TestGesture gesture = await tester.startGesture(carouselCenter);
    // Four deliberate steps of -40px => -1 radian total (one radius of drag).
    for (int i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }

    // While dragging, Item 0 (initially dead-center) has swung away.
    final Offset draggedFront = tester.getCenter(
      find.byKey(const Key('item-0')),
    );
    expect((draggedFront.dx - carouselCenter.dx).abs(), greaterThan(20.0));

    await gesture.up();
    // 600ms spring snap animation; the first pump only kicks the ticker,
    // so run several frames. After it, exactly one item sits centered.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 150));

    final int centered = List<int>.generate(4, (i) => i).where((i) {
      // The front/back poles both cross the center column, but only the
      // true front item is centered on BOTH axes (back items dip 40px
      // lower via yOffset == (1 - depth) * 20).
      final Offset p = tester.getCenter(find.byKey(Key('item-$i')));
      return (p.dx - carouselCenter.dx).abs() < 4.0 &&
          (p.dy - carouselCenter.dy).abs() < 4.0;
    }).length;
    expect(centered, 1);

    // With zero release velocity the -1 rad drag snaps to -pi/2, bringing
    // Item 1 to the front.
    final Offset front = tester.getCenter(find.byKey(const Key('item-1')));
    expect(front.dx, closeTo(carouselCenter.dx, 2.0));
    expect(front.dy, closeTo(carouselCenter.dy, 2.0));
  });
}
