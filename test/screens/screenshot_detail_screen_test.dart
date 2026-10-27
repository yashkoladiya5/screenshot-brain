import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot_brain/core/widgets/empty_state_widget.dart';
import 'package:screenshot_brain/core/widgets/error_widget.dart';
import 'package:screenshot_brain/core/widgets/loading_widget.dart';
import 'package:screenshot_brain/features/screenshots/models/screenshot_item.dart';
import 'package:screenshot_brain/features/screenshots/providers/screenshot_provider.dart';
import 'package:screenshot_brain/features/screenshots/screens/screenshot_detail_screen.dart';

late final Directory _tmpDir;
late final String _pngPath;

ScreenshotItem _item({String? text, DateTime? createdAt, int? fileSize}) =>
    ScreenshotItem(
      id: 7,
      filePath: _pngPath,
      category: 'Bills',
      extractedText: text,
      createdAt: createdAt ?? DateTime(2026, 2, 3, 9, 30),
      fileSize: fileSize,
    );

/// The screen keeps its go_router contract (`context.pop` on delete, push to
/// `/viewer/:id`), so tests mount it inside a real router harness.
Widget _wrap(List<Override> overrides) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('LIB_ROOT'))),
      ),
      GoRoute(
        path: '/screenshots/:id',
        builder: (context, state) =>
            ScreenshotDetailScreen(screenshotId: state.pathParameters['id']!),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _openDetail(
  WidgetTester tester,
  List<Override> overrides, {
  bool settle = true,
}) async {
  await tester.pumpWidget(_wrap(overrides));
  final router = GoRouter.of(tester.element(find.text('LIB_ROOT').first));
  router.push('/screenshots/7');
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // The detail query never resolves (pending spinner); settle would hang.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  setUpAll(() {
    _tmpDir = Directory.systemTemp.createTempSync('sb_detail_test');
    const pngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    final bytes = base64Decode(pngBase64);
    _pngPath = '${_tmpDir.path}/shot.png';
    File(_pngPath).writeAsBytesSync(bytes);
  });

  tearDownAll(() => _tmpDir.deleteSync(recursive: true));

  group('ScreenshotDetailScreen', () {
    testWidgets('shows shared LoadingWidget while the detail query runs', (
      tester,
    ) async {
      final gate = Completer<ScreenshotItem?>();
      await _openDetail(tester, [
        screenshotDetailProvider.overrideWith((ref, id) => gate.future),
      ], settle: false);

      expect(find.byType(LoadingWidget), findsOneWidget);
      expect(find.text('Loading details...'), findsOneWidget);

      // Resolve before teardown so nothing dangles.
      gate.complete(_item());
      await tester.pumpAndSettle();
      expect(find.byType(LoadingWidget), findsNothing);
    });

    testWidgets('renders formatted date/size via the shared utils', (
      tester,
    ) async {
      await _openDetail(tester, [
        screenshotDetailProvider.overrideWith(
          (ref, id) async => _item(
            createdAt: DateTime.now(),
            fileSize: 1572864, // 1.5 MiB
            text: 'Electricity bill Rs 1,200',
          ),
        ),
      ]);

      expect(find.text('Bills'), findsOneWidget);
      // toRelativeString() -> 'Today at h:mm'; toReadableFileSize -> 1.5 MB.
      expect(find.textContaining('Today at'), findsOneWidget);
      expect(find.text('1.5 MB'), findsOneWidget);
      expect(find.text('Electricity bill Rs 1,200'), findsOneWidget);
    });

    testWidgets('missing screenshot renders the shared empty state', (
      tester,
    ) async {
      await _openDetail(tester, [
        screenshotDetailProvider.overrideWith((ref, id) async => null),
      ]);

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('Screenshot not found'), findsOneWidget);
    });

    testWidgets('query errors surface through AppErrorWidget with a '
        'working retry', (tester) async {
      var attempts = 0;
      await _openDetail(tester, [
        screenshotDetailProvider.overrideWith((ref, id) async {
          attempts++;
          throw StateError('row vanished');
        }),
      ]);

      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(
        find.text("We couldn't load these details. Please try again."),
        findsOneWidget,
      );
      // Was a defect: this asserted the raw 'row vanished' dump on screen.
      expect(find.textContaining('row vanished'), findsNothing);

      await tester.tap(find.byKey(const Key('appErrorRetryButton')));
      await tester.pumpAndSettle();

      expect(attempts, greaterThan(1));
    });

    testWidgets('a failed delete shows a friendly message, not an exception '
        'dump', (tester) async {
      await _openDetail(tester, [
        screenshotDetailProvider.overrideWith(
          (ref, id) async => _item(text: 'short text'),
        ),
        deleteScreenshotProvider.overrideWith((ref, id) async {
          throw StateError('isar write failed');
        }),
      ]);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await tester.pumpAndSettle();

      // Friendly action...
      expect(
        find.text('Could not delete this screenshot.'),
        findsOneWidget,
      );
      // ...and no raw `Delete failed: <error>` dump in the tree.
      expect(find.textContaining('isar write failed'), findsNothing);
      // A failed delete must not pop the screen.
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('long extracted text collapses by default and expands on '
        'toggle', (tester) async {
      final longText = 'Receipt line. ' * 40;
      await _openDetail(tester, [
        screenshotDetailProvider.overrideWith(
          (ref, id) async => _item(text: longText, fileSize: 2048),
        ),
      ]);

      expect(find.text('Show more'), findsOneWidget);
      expect(find.text('Show less'), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('extractedTextToggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('extractedTextToggle')));
      await tester.pumpAndSettle();

      expect(find.text('Show less'), findsOneWidget);
      expect(find.byKey(const Key('extractedTextScroller')), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('delete confirmation awaits the provider, then pops back '
        'to the previous route', (tester) async {
      final deleted = <int>[];
      await _openDetail(tester, [
        screenshotDetailProvider.overrideWith(
          (ref, id) async => _item(text: 'short text'),
        ),
        deleteScreenshotProvider.overrideWith((ref, id) async {
          deleted.add(id);
        }),
      ]);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Delete Screenshot'), findsOneWidget);

      // Cancel keeps the screen mounted.
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(deleted, isEmpty);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await tester.pumpAndSettle();

      expect(deleted, [7]);
      expect(find.text('LIB_ROOT'), findsOneWidget);
      expect(find.text('Details'), findsNothing);
    });
  });
}
