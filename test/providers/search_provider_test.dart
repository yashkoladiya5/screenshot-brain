import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_brain/features/search/providers/search_provider.dart';
import 'package:screenshot_brain/shared/models/screenshot_model.dart';

ScreenshotModel makeScreenshot({
  required String filePath,
  String? extractedText,
  String? category,
}) {
  return ScreenshotModel()
    ..filePath = filePath
    ..extractedText = extractedText
    ..category = category
    ..createdAt = DateTime(2026, 1, 1);
}

void main() {
  group('normalizeSearchQuery', () {
    test('trims leading/trailing whitespace', () {
      expect(normalizeSearchQuery('  invoice '), 'invoice');
    });

    test('collapses internal whitespace runs into single spaces', () {
      expect(normalizeSearchQuery('train   ticket\n\tupi'), 'train ticket upi');
    });

    test('lowercases for case-insensitive matching', () {
      expect(normalizeSearchQuery('GPAY Receipt'), 'gpay receipt');
    });

    test('whitespace-only input normalizes to empty', () {
      expect(normalizeSearchQuery('   \n\t '), '');
    });
  });

  group('screenshotMatchesQuery', () {
    final screenshot = makeScreenshot(
      filePath: '/sdcard/Pictures/Amazon_Order_1.png',
      extractedText: 'Your Order has been placed',
      category: 'Shopping',
    );

    test('matches extracted text case-insensitively', () {
      expect(screenshotMatchesQuery(screenshot, 'order has'), isTrue);
    });

    test('matches file path case-insensitively', () {
      expect(screenshotMatchesQuery(screenshot, 'amazon'), isTrue);
    });

    test('matches category case-insensitively', () {
      expect(screenshotMatchesQuery(screenshot, 'shopping'), isTrue);
    });

    test('does not match when nothing contains the query', () {
      expect(screenshotMatchesQuery(screenshot, 'otp'), isFalse);
    });

    test('empty query never matches', () {
      expect(screenshotMatchesQuery(screenshot, ''), isFalse);
    });
  });

  group('filterScreenshotsByQuery', () {
    final seed = [
      makeScreenshot(
        filePath: '/a/upi_receipt.png',
        extractedText: 'Paid via GPAY',
        category: 'UPI Receipts',
      ),
      makeScreenshot(
        filePath: '/b/train_ticket.png',
        extractedText: 'Indian Railways booking',
        category: 'Travel Tickets',
      ),
      makeScreenshot(filePath: '/c/notes.png', extractedText: null),
    ];

    test('returns only matching screenshots', () {
      final results = filterScreenshotsByQuery(seed, 'gpay');
      expect(results, hasLength(1));
      expect(results.single.filePath, '/a/upi_receipt.png');
    });

    test('matches across category field', () {
      final results = filterScreenshotsByQuery(seed, 'travel');
      expect(results.single.filePath, '/b/train_ticket.png');
    });

    test('empty query returns no results (callers keep last results)', () {
      expect(filterScreenshotsByQuery(seed, ''), isEmpty);
    });
  });

  group('searchResultsProvider debounce', () {
    late ProviderContainer container;
    late List<String> backendCalls;
    final seed = [
      makeScreenshot(
        filePath: '/a/train_ticket.png',
        extractedText: 'Train ticket PNR 12345',
        category: 'Travel Tickets',
      ),
      makeScreenshot(
        filePath: '/b/gpay.png',
        extractedText: 'Paid 200 via GPAY',
        category: 'UPI Receipts',
      ),
    ];

    ProviderContainer buildContainer(
      Future<List<ScreenshotModel>> Function(String) searcher,
    ) {
      return ProviderContainer(
        overrides: [screenshotSearcherProvider.overrideWithValue(searcher)],
      );
    }

    setUp(() {
      backendCalls = [];
    });

    tearDown(() {
      container.dispose();
    });

    // The flutter_test binding runs the body in a fake-async zone, so
    // tester.pump(duration) pumps the debounce Timer manually without real
    // wall-clock waiting.
    testWidgets('fast typing collapses into a single backend call', (
      tester,
    ) async {
      container = buildContainer((query) async {
        backendCalls.add(query);
        return filterScreenshotsByQuery(seed, query);
      });
      container.listen(searchResultsProvider, (_, _) {});

      container.read(searchQueryProvider.notifier).state = 't';
      container.read(searchQueryProvider.notifier).state = 'tr';
      container.read(searchQueryProvider.notifier).state = 'tra';
      expect(backendCalls, isEmpty);

      await tester.pump(const Duration(milliseconds: 200));
      expect(backendCalls, isEmpty, reason: 'still inside the 300ms window');

      await tester.pump(const Duration(milliseconds: 150));
      expect(backendCalls, [
        'tra',
      ], reason: 'one call with the final query only');
      expect(container.read(searchResultsProvider).value, hasLength(1));
    });

    testWidgets('each keystroke restarts the debounce window', (tester) async {
      container = buildContainer((query) async {
        backendCalls.add(query);
        return filterScreenshotsByQuery(seed, query);
      });
      container.listen(searchResultsProvider, (_, _) {});

      container.read(searchQueryProvider.notifier).state = 'g';
      await tester.pump(const Duration(milliseconds: 250));
      container.read(searchQueryProvider.notifier).state = 'gp';
      await tester.pump(const Duration(milliseconds: 250));
      expect(backendCalls, isEmpty, reason: 'timer restarted before firing');

      await tester.pump(const Duration(milliseconds: 100));
      expect(backendCalls, ['gp']);
    });

    testWidgets('query is normalized before hitting the backend', (
      tester,
    ) async {
      container = buildContainer((query) async {
        backendCalls.add(query);
        return filterScreenshotsByQuery(seed, query);
      });
      container.listen(searchResultsProvider, (_, _) {});

      container.read(searchQueryProvider.notifier).state = '  TRAIN   Ticket  ';
      await tester.pump(const Duration(milliseconds: 400));
      expect(backendCalls, ['train ticket']);
      expect(container.read(searchResultsProvider).value, hasLength(1));
    });

    testWidgets('whitespace-only query never hits the backend', (tester) async {
      container = buildContainer((query) async {
        backendCalls.add(query);
        return filterScreenshotsByQuery(seed, query);
      });
      container.listen(searchResultsProvider, (_, _) {});

      container.read(searchQueryProvider.notifier).state = '   ';
      await tester.pump(const Duration(seconds: 2));
      expect(backendCalls, isEmpty);
      expect(container.read(searchResultsProvider).value, isEmpty);
    });

    testWidgets('empty query keeps the last non-empty results', (tester) async {
      container = buildContainer((query) async {
        backendCalls.add(query);
        return filterScreenshotsByQuery(seed, query);
      });
      container.listen(searchResultsProvider, (_, _) {});

      container.read(searchQueryProvider.notifier).state = 'gpay';
      await tester.pump(const Duration(milliseconds: 400));
      expect(container.read(searchResultsProvider).value, hasLength(1));

      container.read(searchQueryProvider.notifier).state = '';
      await tester.pump(const Duration(seconds: 1));
      expect(backendCalls, [
        'gpay',
      ], reason: 'clearing the query must not re-query');
      expect(
        container.read(searchResultsProvider).value,
        hasLength(1),
        reason: 'previous results are kept while the field is empty',
      );
    });

    testWidgets('backend failures surface as AsyncError', (tester) async {
      container = buildContainer((query) async {
        backendCalls.add(query);
        throw StateError('db exploded');
      });
      container.listen(searchResultsProvider, (_, _) {});

      container.read(searchQueryProvider.notifier).state = 'anything';
      await tester.pump(const Duration(milliseconds: 400));

      final state = container.read(searchResultsProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('db exploded'));
    });
  });
}
