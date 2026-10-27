import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/theme/app_theme.dart';
import 'package:screenshot_brain/core/widgets/empty_state_widget.dart';
import 'package:screenshot_brain/features/search/providers/search_provider.dart';
import 'package:screenshot_brain/features/search/screens/search_screen.dart';
import 'package:screenshot_brain/shared/models/screenshot_model.dart';

late final Directory _tmpDir;
late final String _png;

ScreenshotModel _make({required String text, String? category}) {
  return ScreenshotModel()
    ..filePath = _png
    ..extractedText = text
    ..category = category
    ..createdAt = DateTime(2026, 1, 1);
}

/// True when some RichText in the tree renders [token] as its own span with
/// a highlight background — i.e. the query term is actually emphasised.
bool _highlightsToken(WidgetTester tester, String token) {
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    final root = rich.text;
    if (root is! TextSpan) continue;
    var found = false;
    root.visitChildren((child) {
      if (child is TextSpan &&
          child.text?.toLowerCase() == token &&
          child.style?.backgroundColor != null) {
        found = true;
        return false;
      }
      return true;
    });
    if (found) return true;
  }
  return false;
}

void main() {
  late List<ScreenshotModel> seed;

  setUpAll(() {
    _tmpDir = Directory.systemTemp.createTempSync('sb_search_test');
    const pngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    File('${_tmpDir.path}/a.png').writeAsBytesSync(base64Decode(pngBase64));
    _png = '${_tmpDir.path}/a.png';
  });

  tearDownAll(() => _tmpDir.deleteSync(recursive: true));

  setUp(() {
    seed = [
      _make(
        text: 'Paid amount 500 via GPAY confirmed',
        category: 'UPI Receipts',
      ),
      _make(text: 'Selfie at the station', category: 'Notes'),
    ];
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        screenshotSearcherProvider.overrideWithValue(
          (query) async => filterScreenshotsByQuery(seed, query),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Widget wrap(ProviderContainer container) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: ScreenshotBrainTheme.light,
      home: const SearchScreen(),
    ),
  );

  group('SearchScreen', () {
    testWidgets('restores the persisted query into the text field', (
      tester,
    ) async {
      // The query survives in the global provider after leaving the screen;
      // reopening must show the same text in the field that produced the
      // visible results, not an empty box over stale results.
      final container = makeContainer();
      container.read(searchQueryProvider.notifier).state = 'gpay';

      await tester.pumpWidget(wrap(container));
      await tester.pump(const Duration(milliseconds: 400));

      final field = tester.widget<TextField>(
        find.byKey(const Key('searchInput')),
      );
      expect(field.controller, isNotNull);
      expect(
        field.controller!.text,
        'gpay',
        reason: 'empty field above results from an earlier query is a lie',
      );
    });

    testWidgets('clear button empties the field, the query and the results', (
      tester,
    ) async {
      final container = makeContainer();
      container.read(searchQueryProvider.notifier).state = 'gpay';

      await tester.pumpWidget(wrap(container));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byKey(const Key('searchClearButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(container.read(searchQueryProvider), '');
      final field = tester.widget<TextField>(
        find.byKey(const Key('searchInput')),
      );
      expect(field.controller!.text, isEmpty);
      expect(find.text('Suggestions'), findsOneWidget);
      expect(find.byType(EmptyStateWidget), findsNothing);
    });

    testWidgets('multi-word queries highlight every token separately', (
      tester,
    ) async {
      // Matching is per-token AND, so results can arrive without the exact
      // phrase ever occurring; the preview must still highlight each word.
      final container = makeContainer();
      container.read(searchQueryProvider.notifier).state = 'paid gpay';

      await tester.pumpWidget(wrap(container));
      await tester.pump(const Duration(milliseconds: 400));

      expect(_highlightsToken(tester, 'paid'), isTrue);
      expect(_highlightsToken(tester, 'gpay'), isTrue);
    });
  });
}
