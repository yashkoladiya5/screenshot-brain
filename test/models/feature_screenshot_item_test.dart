import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/date_extensions.dart';
import 'package:screenshot_brain/features/screenshots/models/screenshot_item.dart';

/// Covers the view model the screenshot list and detail screens render (the
/// `features/screenshots` copy of `ScreenshotItem`), not the shared one.
ScreenshotItem _item({String? category, required DateTime createdAt}) =>
    ScreenshotItem(
      id: 1,
      filePath: '/tmp/1.png',
      category: category,
      createdAt: createdAt,
    );

void main() {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  group('dateDisplay', () {
    test('a capture taken minutes ago reads Today', () {
      expect(
        _item(createdAt: now.subtract(const Duration(minutes: 5))).dateDisplay,
        'Today',
      );
    });

    test('a capture from before midnight reads Yesterday, not Today', () {
      // 23:59 the previous day is one calendar day back, but only minutes or
      // hours have elapsed, so the old elapsed-24h-block math (`difference`
      // .inDays) labelled it 'Today' for the whole of today.
      final lateLastNight = startOfToday.subtract(const Duration(minutes: 1));
      expect(_item(createdAt: lateLastNight).dateDisplay, 'Yesterday');
    });

    test('a future timestamp never renders a negative day count', () {
      // A screenshot restored from a backup with a skewed clock used to fall
      // through both equality checks and print '-2 days ago'.
      final twoDaysAhead = startOfToday.add(const Duration(days: 2));
      expect(_item(createdAt: twoDaysAhead).dateDisplay, 'Today');
    });

    test('walks the day window and switches to the numeric date at a week', () {
      final fourDaysAgo = startOfToday.subtract(const Duration(days: 4));
      expect(_item(createdAt: fourDaysAgo).dateDisplay, '4 days ago');

      final weekAgo = startOfToday.subtract(const Duration(days: 7));
      expect(
        weekAgo.dayOffsetFrom(DateTime.now()),
        -7,
        reason: 'fixture must sit exactly seven calendar days back',
      );
      expect(
        _item(createdAt: weekAgo).dateDisplay,
        '${weekAgo.day}/${weekAgo.month}/${weekAgo.year}',
      );
    });
  });

  group('categoryDisplay', () {
    test(
      'falls back to the placeholder for null, empty and blank categories',
      () {
        expect(
          _item(category: null, createdAt: now).categoryDisplay,
          'Uncategorized',
        );
        expect(
          _item(category: '', createdAt: now).categoryDisplay,
          'Uncategorized',
        );
        expect(
          _item(category: '   ', createdAt: now).categoryDisplay,
          'Uncategorized',
        );
      },
    );

    test(
      'trims padded categories so the badge matches the analytics bucket',
      () {
        expect(
          _item(category: '  Bills  ', createdAt: now).categoryDisplay,
          'Bills',
        );
      },
    );
  });
}
