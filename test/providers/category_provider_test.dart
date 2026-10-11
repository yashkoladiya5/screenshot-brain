import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/features/categories/providers/category_provider.dart';

void main() {
  group('kCategoryList', () {
    test('is the canonical vocabulary with no duplicates', () {
      expect(kCategoryList, hasLength(11));
      expect(kCategoryList.toSet(), hasLength(kCategoryList.length));
      expect(kCategoryList, contains('Other'));
    });
  });

  group('orderCategoryCounts', () {
    test('empty input yields empty output', () {
      expect(orderCategoryCounts({}), isEmpty);
    });

    test('sorts by descending count', () {
      final ordered = orderCategoryCounts({'Bills': 2, 'Payments': 9, 'Notes': 5});
      expect(ordered.keys.toList(), ['Payments', 'Notes', 'Bills']);
    });

    test('count ties fall back to canonical vocabulary order', () {
      final ordered = orderCategoryCounts({'Notes': 3, 'Payments': 3, 'Bills': 3});
      expect(ordered.keys.toList(), ['Payments', 'Bills', 'Notes']);
    });

    test('unknown categories rank after canonical ones on ties', () {
      final ordered = orderCategoryCounts({'Zebra': 4, 'Bills': 4});
      expect(ordered.keys.toList(), ['Bills', 'Zebra']);
    });

    test('multiple unknown categories sort alphabetically', () {
      final ordered = orderCategoryCounts({'Zebra': 1, 'Abyss': 1, 'Mesa': 1});
      expect(ordered.keys.toList(), ['Abyss', 'Mesa', 'Zebra']);
    });

    test('includeEmpty seeds canonical categories with zero counts', () {
      final ordered = orderCategoryCounts(
        {'Bills': 1},
        includeEmpty: true,
      );
      expect(ordered['Bills'], 1);
      expect(ordered['Payments'], 0);
      expect(ordered, hasLength(kCategoryList.length));
    });

    test('includeEmpty drops zero-count non-canonical entries', () {
      final ordered = orderCategoryCounts(
        {'Ghost': 0, 'Bills': 2},
        includeEmpty: true,
      );
      expect(ordered.containsKey('Ghost'), isFalse);
      expect(ordered['Bills'], 2);
    });

    test('without includeEmpty zero counts are preserved', () {
      final ordered = orderCategoryCounts({'Ghost': 0, 'Bills': 2});
      expect(ordered['Ghost'], 0);
      expect(ordered.keys.toList(), ['Bills', 'Ghost']);
    });

    test('custom canonical list changes tie order', () {
      final ordered = orderCategoryCounts(
        {'Notes': 1, 'Bills': 1},
        canonical: ['Notes', 'Bills'],
      );
      expect(ordered.keys.toList(), ['Notes', 'Bills']);
    });

    test('is deterministic regardless of input insertion order', () {
      final a = orderCategoryCounts({'Bills': 3, 'Payments': 3, 'Notes': 1});
      final b = orderCategoryCounts({'Notes': 1, 'Payments': 3, 'Bills': 3});
      expect(a.keys.toList(), b.keys.toList());
    });
  });
}
