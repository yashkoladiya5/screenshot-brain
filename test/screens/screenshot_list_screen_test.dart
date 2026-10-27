import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/widgets/empty_state_widget.dart';
import 'package:screenshot_brain/core/widgets/error_widget.dart';
import 'package:screenshot_brain/core/widgets/loading_widget.dart';
import 'package:screenshot_brain/features/categories/providers/category_provider.dart';
import 'package:screenshot_brain/features/screenshots/models/screenshot_item.dart';
import 'package:screenshot_brain/features/screenshots/providers/screenshot_provider.dart';
import 'package:screenshot_brain/features/screenshots/screens/screenshot_list_screen.dart';

/// 1x1 transparent PNG written to a temp dir so Image.file decodes cleanly.
late final Directory _tmpDir;
late final String _pngA;
late final String _pngB;
late final String _pngC;

ScreenshotItem _item({
  required int id,
  required String path,
  required String? category,
}) => ScreenshotItem(
  id: id,
  filePath: path,
  category: category,
  createdAt: DateTime.now(),
  fileSize: 1024,
  isProcessed: true,
);

List<Override> _overrides({
  required List<ScreenshotItem> items,
  Map<String, int> counts = const {'Bills': 2, 'Travel Tickets': 1},
}) => [
  screenshotListProvider.overrideWith((ref) async => items),
  categoryCountsProvider.overrideWith((ref) async => counts),
];

Widget _wrap(List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: const MaterialApp(home: ScreenshotListScreen()),
);

class _RecordingScanNotifier extends ScanScreenshotsNotifier {
  int scanCalls = 0;

  @override
  Future<ScanOutcome> scan() async {
    scanCalls++;
    return const ScanOutcome();
  }
}

void main() {
  setUpAll(() {
    _tmpDir = Directory.systemTemp.createTempSync('sb_list_test');
    const pngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    final bytes = base64Decode(pngBase64);
    for (final name in ['a.png', 'b.png', 'c.png']) {
      File('${_tmpDir.path}/$name').writeAsBytesSync(bytes);
    }
    _pngA = '${_tmpDir.path}/a.png';
    _pngB = '${_tmpDir.path}/b.png';
    _pngC = '${_tmpDir.path}/c.png';
  });

  tearDownAll(() => _tmpDir.deleteSync(recursive: true));

  group('ScreenshotListScreen', () {
    testWidgets('renders the shared LoadingWidget while the query runs', (
      tester,
    ) async {
      final gate = Completer<List<ScreenshotItem>>();
      final items = [_item(id: 1, path: _pngA, category: 'Bills')];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            screenshotListProvider.overrideWith((ref) => gate.future),
            categoryCountsProvider.overrideWith((ref) async => const {}),
          ],
          child: const MaterialApp(home: ScreenshotListScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(LoadingWidget), findsOneWidget);
      expect(find.text('Loading screenshots...'), findsOneWidget);

      // Resolve before teardown so nothing dangles.
      gate.complete(items);
      await tester.pumpAndSettle();
      expect(find.byType(LoadingWidget), findsNothing);
    });

    testWidgets('errors surface through AppErrorWidget and retry re-runs '
        'the query (no more swallowed failures)', (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            screenshotListProvider.overrideWith((ref) async {
              attempts++;
              throw StateError('isar closed');
            }),
            categoryCountsProvider.overrideWith((ref) async => const {}),
          ],
          child: const MaterialApp(home: ScreenshotListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(find.textContaining('isar closed'), findsOneWidget);

      await tester.tap(find.byKey(const Key('appErrorRetryButton')));
      await tester.pumpAndSettle();

      expect(attempts, greaterThan(1));
    });

    testWidgets('renders tiles plus repository-fed category filter chips', (
      tester,
    ) async {
      final items = [
        _item(id: 1, path: _pngA, category: 'Bills'),
        _item(id: 2, path: _pngB, category: 'Bills'),
        _item(id: 3, path: _pngC, category: 'Travel Tickets'),
      ];
      await tester.pumpWidget(_wrap(_overrides(items: items)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('categoryFilterChips')), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Bills (2)'), findsOneWidget);
      expect(find.text('Travel Tickets (1)'), findsOneWidget);
      // Tiles render the raw category labels (chips carry the counts, so the
      // bare 'Bills' texts come only from the grid).
      expect(find.text('Bills'), findsNWidgets(2));
    });

    testWidgets('selecting a chip filters the grid and clears again', (
      tester,
    ) async {
      final items = [
        _item(id: 1, path: _pngA, category: 'Bills'),
        _item(id: 2, path: _pngB, category: 'Bills'),
        _item(id: 3, path: _pngC, category: 'Travel Tickets'),
      ];
      await tester.pumpWidget(_wrap(_overrides(items: items)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Travel Tickets (1)'));
      await tester.pumpAndSettle();

      // Only the single Travel Tickets tile remains; Bills tiles are gone.
      expect(find.text('Travel Tickets'), findsOneWidget);
      expect(find.text('Bills'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Bills'), findsNWidgets(2));
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'All'))
            .selected,
        isTrue,
      );
    });

    testWidgets('filtered-to-empty shows a clear-filter empty state', (
      tester,
    ) async {
      final items = [_item(id: 1, path: _pngA, category: 'Bills')];
      await tester.pumpWidget(
        _wrap(_overrides(items: items, counts: const {'Bills': 1, 'Notes': 3})),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notes (3)'));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('No Notes screenshots'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Clear filter'));
      await tester.pumpAndSettle();
      expect(find.text('Bills'), findsNWidgets(1));
    });

    testWidgets('library-empty state triggers the scan provider action', (
      tester,
    ) async {
      final scanNotifier = _RecordingScanNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._overrides(items: const []),
            scanScreenshotsProvider.overrideWith(() => scanNotifier),
          ],
          child: const MaterialApp(home: ScreenshotListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('No Screenshots Yet'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Scan Now'));
      await tester.pump();
      expect(scanNotifier.scanCalls, 1);
    });

    // DEFECT PROOF: categoryCountsProvider buckets uncategorized rows
    // (category == null) into 'Other' via countByBucket, but the grid filter
    // compared the chip label against ScreenshotItem.categoryDisplay, which
    // renders those rows as 'Uncategorized'. Tapping 'Other (N)' therefore
    // hid the very rows the badge counted and showed a bogus empty state.
    testWidgets('Other chip filters with the same bucketing its badge counts', (
      tester,
    ) async {
      final items = [
        _item(id: 1, path: _pngA, category: 'Bills'),
        _item(id: 2, path: _pngB, category: null),
      ];
      await tester.pumpWidget(
        _wrap(_overrides(items: items, counts: const {'Bills': 1, 'Other': 1})),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Other (1)'));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsNothing);
      expect(find.text('Uncategorized'), findsOneWidget);
      expect(find.text('Bills'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Uncategorized'), findsOneWidget);
      expect(find.text('Bills'), findsOneWidget);
    });

    // DEFECT PROOF: onRefresh awaited screenshotListProvider.future directly,
    // so a reload that threw completed the RefreshIndicator callback with an
    // unhandled error — the spinner never closed and the failure surfaced as
    // an uncaught exception instead of the AppErrorWidget path.
    testWidgets('a failing pull-to-refresh lands on the error widget, not an '
        'unhandled exception with a hanging spinner', (tester) async {
      var calls = 0;
      final items = [_item(id: 1, path: _pngA, category: 'Bills')];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            screenshotListProvider.overrideWith((ref) async {
              calls++;
              if (calls > 1) throw StateError('refresh exploded');
              return items;
            }),
            categoryCountsProvider.overrideWith(
              (ref) async => const {'Bills': 1},
            ),
          ],
          child: const MaterialApp(home: ScreenshotListScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);

      await tester.flingFrom(
        tester.getCenter(find.byType(GridView)),
        const Offset(0, 300),
        1200,
      );
      await tester.pumpAndSettle();

      expect(calls, greaterThan(1));
      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(find.textContaining('refresh exploded'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // DEFECT PROOF: every tile fed a full-resolution File image into the
    // widget tree (bare Image.file, no ResizeImage/memCache bound). A library
    // of hundreds of screenshots means hundreds of multi-megapixel bitmap
    // decodes for ~150px tiles; the grid must request a downsampled decode.
    testWidgets('tiles decode screenshots at thumbnail scale, not full size', (
      tester,
    ) async {
      final items = [
        _item(id: 1, path: _pngA, category: 'Bills'),
        _item(id: 2, path: _pngB, category: 'Travel Tickets'),
      ];
      await tester.pumpWidget(_wrap(_overrides(items: items)));
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<Image>(
        find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Image),
        ),
      );
      expect(tiles, isNotEmpty);
      for (final image in tiles) {
        expect(
          image.image,
          isA<ResizeImage>(),
          reason: 'unbounded full-resolution decode per tile',
        );
      }
    });
  });
}
