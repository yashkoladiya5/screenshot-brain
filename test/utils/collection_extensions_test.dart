import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/iterable_extensions.dart';
import 'package:screenshot_brain/core/utils/list_extensions.dart';
import 'package:screenshot_brain/core/utils/map_extensions.dart';

class _Expense {
  const _Expense(this.title, this.category, this.amount);
  final String title;
  final String category;
  final num amount;
}

void main() {
  group('ListExtensions', () {
    test('elementAtOrNull returns null out of bounds', () {
      expect([1, 2, 3].elementAtOrNull(1), 2);
      expect([1, 2, 3].elementAtOrNull(3), isNull);
      expect([1, 2, 3].elementAtOrNull(-1), isNull);
      expect(<int>[].elementAtOrNull(0), isNull);
    });

    test('uniqueBy keeps first occurrence per key', () {
      final expenses = const [
        _Expense('chai', 'food', 20),
        _Expense('tea', 'food', 15),
        _Expense('bus', 'travel', 30),
      ];
      expect(expenses.uniqueBy((e) => e.category).map((e) => e.title), [
        'chai',
        'bus',
      ]);
    });

    test('separatedBy interleaves separators', () {
      expect([1, 2, 3].separatedBy((index) => 0), [1, 0, 2, 0, 3]);
      expect([7].separatedBy((index) => 0), [7]);
      expect(<int>[].separatedBy((index) => 0), <int>[]);
    });

    test('chunkBy splits into fixed-size batches with short tail', () {
      expect([1, 2, 3, 4, 5].chunkBy(2), [
        [1, 2],
        [3, 4],
        [5],
      ]);
      expect([1, 2, 3].chunkBy(5), [
        [1, 2, 3],
      ]);
      expect([1, 2].chunkBy(2), [
        [1, 2],
      ]);
      expect(<int>[].chunkBy(3), <List<int>>[]);
      expect(() => [1].chunkBy(0), throwsAssertionError);
    });

    test('distinctBy drops later duplicates by key', () {
      final expenses = const [
        _Expense('chai', 'food', 20),
        _Expense('bus', 'travel', 30),
        _Expense('metro', 'travel', 40),
      ];
      expect(expenses.distinctBy((e) => e.category).map((e) => e.title), [
        'chai',
        'bus',
      ]);
    });

    test('secondOrNull', () {
      expect([1, 2, 3].secondOrNull, 2);
      expect([1].secondOrNull, isNull);
      expect(<int>[].secondOrNull, isNull);
    });

    test('sortedBy returns a sorted copy without touching the original', () {
      final source = [3, 1, 2];
      expect(source.sortedBy((e) => e), [1, 2, 3]);
      expect(source, [3, 1, 2]);
      expect(
        source.sortedBy((e) => e, descending: true),
        [3, 2, 1],
        reason: 'descending reverses the comparator',
      );
      final expenses = const [_Expense('a', 'x', 50), _Expense('b', 'y', 10)];
      expect(expenses.sortedBy((e) => e.amount).map((e) => e.title), [
        'b',
        'a',
      ]);
    });

    test('zip pairs up to the shorter list', () {
      expect(
        ['a', 'b', 'c'].zip([1, 2], (String s, int i) => '$s$i').toList(),
        ['a1', 'b2'],
      );
      expect(['a'].zip(<int>[], (String s, int i) => s).toList(), isEmpty);
    });
  });

  group('NumListExtensions.movingAverage', () {
    test('grows the window at the start then slides', () {
      expect([1, 2, 3, 4].movingAverage(2), [1.0, 1.5, 2.5, 3.5]);
      expect([1.5, 2.5, 3.0].movingAverage(3), [1.5, 2.0, 7.0 / 3.0]);
    });

    test('window of 1 is the identity, oversized window averages all', () {
      expect([2, 4].movingAverage(1), [2.0, 4.0]);
      expect([2, 4].movingAverage(10), [2.0, 3.0]);
      expect(<int>[].movingAverage(3), isEmpty);
      expect(() => [1].movingAverage(0), throwsAssertionError);
    });
  });

  group('IterableExtensions', () {
    test('mapIndexed passes the index', () {
      expect(['a', 'b'].mapIndexed((i, e) => '$i$e').toList(), ['0a', '1b']);
    });

    test('groupBy buckets elements preserving order', () {
      final expenses = const [
        _Expense('chai', 'food', 20),
        _Expense('bus', 'travel', 30),
        _Expense('samosa', 'food', 15),
      ];
      final grouped = expenses.groupBy((e) => e.category);
      expect(grouped.keys, ['food', 'travel']);
      expect(grouped['food']!.length, 2);
    });

    test('firstWhereOrNull returns null when nothing matches', () {
      final items = [1, 2, 3];
      expect(items.firstWhereOrNull((e) => e.isEven), 2);
      expect(items.firstWhereOrNull((e) => e > 10), isNull);
    });

    test('groupBySum totals per key, ints stay int', () {
      final expenses = const [
        _Expense('chai', 'food', 20),
        _Expense('samosa', 'food', 15),
        _Expense('bus', 'travel', 30),
      ];
      final sums = expenses.groupBySum((e) => e.category, (e) => e.amount);
      expect(sums, {'food': 35, 'travel': 30});
      expect(sums['food'], isA<int>());

      final mixed = const [_Expense('a', 'x', 10), _Expense('b', 'x', 2.5)];
      expect(mixed.groupBySum((e) => e.category, (e) => e.amount)['x'], 12.5);
    });
  });

  group('MapExtensions', () {
    test('getAs casts by type', () {
      final map = <String, dynamic>{'n': 42, 's': 'text'};
      expect(map.getAs<int>('n'), 42);
      expect(map.getAs<String>('n'), isNull);
      expect(map.getAs<int>('missing'), isNull);
    });

    test('compact removes null values', () {
      expect({'a': 1, 'b': null}.compact(), {'a': 1});
      expect(<String, int?>{}.compact(), isEmpty);
    });

    test('mapKeys transforms keys with collision strategies', () {
      expect({1: 'a', 2: 'b'}.mapKeys((k, v) => 'key$k'), {
        'key1': 'a',
        'key2': 'b',
      });
      // Both keys collapse to the same value: last one wins by default.
      expect({1: 'a', 2: 'b'}.mapKeys((k, v) => 'same'), {'same': 'b'});
      expect(
        {
          1: 'a',
          2: 'b',
        }.mapKeys((k, v) => 'same', onCollision: (existing, _) => existing),
        {'same': 'a'},
      );
    });

    test('mapValues transforms values with key access', () {
      expect({1: 2, 2: 3}.mapValues((k, v) => k * v), {1: 2, 2: 6});
    });

    test('invert swaps pairs and handles value collisions', () {
      expect({'a': 1, 'b': 2}.invert(), {1: 'a', 2: 'b'});
      // Two keys share a value: last wins by default...
      expect({'a': 1, 'b': 1}.invert(), {1: 'b'});
      // ...or the callback decides (keep the alphabetically first key).
      expect(
        {'b': 1, 'a': 1}.invert(
          onCollision: (existing, incoming) =>
              existing.compareTo(incoming) <= 0 ? existing : incoming,
        ),
        {1: 'a'},
      );
    });

    test('sortByValue orders entries by value', () {
      final spends = {'food': 350, 'travel': 120, 'fun': 200};
      final ascending = spends.sortByValue();
      expect(ascending.keys.toList(), ['travel', 'fun', 'food']);
      expect(ascending.values.toList(), [120, 200, 350]);
      expect(spends.sortByValue(descending: true).keys.first, 'food');
      expect(spends, {'food': 350, 'travel': 120, 'fun': 200});
    });

    test('deepMerge merges nested maps recursively, other wins', () {
      final base = <String, dynamic>{
        'theme': <String, dynamic>{'mode': 'dark', 'accent': 'blue'},
        'limit': 100,
        'tags': <String>['a'],
      };
      final patch = <String, dynamic>{
        'theme': <String, dynamic>{'accent': 'green'},
        'limit': 200,
        'tags': <String>['b'],
        'fresh': true,
      };
      final merged = base.deepMerge(patch);
      expect(merged['theme'], {'mode': 'dark', 'accent': 'green'});
      expect(merged['limit'], 200);
      expect(merged['tags'], ['b'], reason: 'lists are replaced whole');
      expect(merged['fresh'], isTrue);
      expect(base['limit'], 100, reason: 'source map is not mutated');
    });
  });
}
