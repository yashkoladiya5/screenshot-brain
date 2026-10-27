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

    test('multi-word query uses AND semantics across fields, not a phrase', () {
      // Real screenshots rarely contain the exact phrase "train ticket";
      // the words are scattered across the file name, the OCR text and the
      // category. Every token must match somewhere, but not necessarily
      // together or in the same field.
      final ticket = makeScreenshot(
        filePath: '/sdcard/Pictures/train_booking.png',
        extractedText: 'PNR 555 status: ticket confirmed',
        category: 'Travel Tickets',
      );
      expect(screenshotMatchesQuery(ticket, 'train ticket'), isTrue);
      expect(screenshotMatchesQuery(ticket, 'pnr confirmed hotels'), isFalse);
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

    test('multi-word query keeps only screenshots containing every token', () {
      final corpus = [
        makeScreenshot(
          filePath: '/a/train_booking.png',
          extractedText: 'Ticket confirmed PNR 555',
          category: 'Travel Tickets',
        ),
        makeScreenshot(
          filePath: '/a/train_station_photo.png',
          extractedText: 'Selfie at the platform',
        ),
      ];
      final results = filterScreenshotsByQuery(corpus, 'train ticket');
      expect(results, hasLength(1));
      expect(results.single.filePath, '/a/train_booking.png');
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

    testWidgets('a late response for an abandoned query cannot poison '
        'the kept-last-results behaviour', (tester) async {
      final slowOnly = makeScreenshot(
        filePath: '/slow.png',
        extractedText: 'only slow matches here',
      );
      final fastOnly = makeScreenshot(
        filePath: '/fast.png',
        extractedText: 'only fast matches here',
      );
      final corpus = [slowOnly, fastOnly];
      container = buildContainer((query) async {
        backendCalls.add(query);
        if (query == 'slow') {
          await Future<void>.delayed(const Duration(milliseconds: 600));
        }
        return filterScreenshotsByQuery(corpus, query);
      });
      container.listen(searchResultsProvider, (_, _) {});

      container.read(searchQueryProvider.notifier).state = 'slow';
      await tester.pump(const Duration(milliseconds: 400));
      expect(backendCalls, ['slow'], reason: 'slow fetch is still in flight');

      container.read(searchQueryProvider.notifier).state = 'fast';
      await tester.pump(const Duration(milliseconds: 400));
      expect(backendCalls, ['slow', 'fast']);
      expect(
        container.read(searchResultsProvider).value!.single.filePath,
        '/fast.png',
      );

      // The abandoned 'slow' fetch now lands late. It must not be remembered
      // as the last results, otherwise clearing the query resurrects it.
      await tester.pump(const Duration(milliseconds: 600));
      container.read(searchQueryProvider.notifier).state = '';
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      final value = container.read(searchResultsProvider).value;
      expect(value, hasLength(1));
      expect(
        value!.single.filePath,
        '/fast.png',
        reason: 'stale slow response overwrote the newest results',
      );
    });

    testWidgets('a late failure for an abandoned query does not surface '
        'as an error over newer results', (tester) async {
      container = buildContainer((query) async {
        backendCalls.add(query);
        if (query == 'boom') {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          throw StateError('late boom');
        }
        return [makeScreenshot(filePath: '/ok.png', extractedText: 'ok query')];
      });
      container.listen(searchResultsProvider, (_, _) {});

      container.read(searchQueryProvider.notifier).state = 'boom';
      await tester.pump(const Duration(milliseconds: 400));
      expect(backendCalls, ['boom']);

      container.read(searchQueryProvider.notifier).state = 'ok';
      await tester.pump(const Duration(milliseconds: 400));
      expect(backendCalls, ['boom', 'ok']);
      expect(container.read(searchResultsProvider).value, hasLength(1));

      await tester.pump(const Duration(milliseconds: 600));
      final state = container.read(searchResultsProvider);
      expect(
        state.hasError,
        isFalse,
        reason: 'stale boom rejection leaked into current state',
      );
      expect(state.value, hasLength(1));
    });
  });
}
