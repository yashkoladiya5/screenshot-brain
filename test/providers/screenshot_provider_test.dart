import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/features/screenshots/models/screenshot_item.dart';
import 'package:screenshot_brain/features/screenshots/providers/screenshot_provider.dart';
import 'package:screenshot_brain/features/screenshots/repositories/screenshot_repository.dart';
import 'package:screenshot_brain/shared/models/screenshot_model.dart';

/// Test double for [ScreenshotRepository]: `implements` (never `extends`), so
/// the repository's `final Isar db = DatabaseService.db` field initializer —
/// which throws without a native Isar — is never evaluated.
class _FakeRepo implements ScreenshotRepository {
  _FakeRepo({this.items = const [], this.searchResults = const []});

  final List<ScreenshotItem> items;
  final List<ScreenshotItem> searchResults;

  final List<ScreenshotModel> saved = [];
  final Map<int, String> categories = {};
  final Map<int, String> texts = {};
  final Set<int> expenses = {};
  int getAllCalls = 0;

  @override
  Future<List<ScreenshotItem>> getAllScreenshots({String? category}) async {
    getAllCalls++;
    return items;
  }

  @override
  Future<ScreenshotItem?> getScreenshotById(int id) async {
    for (final candidate in items) {
      if (candidate.id == id) return candidate;
    }
    return null;
  }

  @override
  Future<List<ScreenshotItem>> searchScreenshots(String query) async =>
      searchResults;

  @override
  Future<int> saveScreenshot(ScreenshotModel model) async {
    saved.add(model);
    return model.id;
  }

  @override
  Future<void> updateCategory(int id, String category) async =>
      categories[id] = category;

  @override
  Future<void> updateExtractedText(int id, String text) async =>
      texts[id] = text;

  @override
  Future<void> markAsExpense(int id, bool isExpense) async {
    if (isExpense) expenses.add(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not needed');
}

ScreenshotItem item({int id = 1, String filePath = '/sdcard/a.png'}) {
  return ScreenshotItem(
    id: id,
    filePath: filePath,
    createdAt: DateTime.utc(2025),
  );
}

void main() {
  group('knownFilePaths', () {
    test('collects non-empty paths and dedupes', () {
      final paths = knownFilePaths([
        item(filePath: '/a.png'),
        item(id: 2, filePath: '/b.png'),
        item(id: 3, filePath: '/a.png'),
      ]);
      expect(paths, {'/a.png', '/b.png'});
    });

    test('blank paths are dropped and an empty list yields an empty set', () {
      expect(knownFilePaths([item(filePath: '')]), isEmpty);
      expect(knownFilePaths(const []), isEmpty);
    });
  });

  group('filesNotIn', () {
    late Directory tempDir;
    late File a;
    late File b;
    late File c;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('scan_pure_test');
      a = File('${tempDir.path}/a.png');
      b = File('${tempDir.path}/b.png');
      c = File('${tempDir.path}/c.png');
      for (final file in [a, b, c]) {
        await file.writeAsBytes(List.filled(1024, 0));
      }
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('keeps only files whose path is unknown, preserving order', () {
      expect(filesNotIn([a, b, c], {b.path}), [a, c]);
      expect(filesNotIn([a, b, c], {a.path, c.path}), [b]);
    });

    test('an empty known set short-circuits to the original list', () {
      final files = [a, b, c];
      expect(filesNotIn(files, const {}), same(files));
    });

    test('everything-known and empty input produce an empty result', () {
      expect(filesNotIn([a, b], {a.path, b.path}), isEmpty);
      expect(filesNotIn(const [], {'/x.png'}), isEmpty);
    });
  });

  group('newScreenshotModel', () {
    test('records path, mtime and size, flagged as untouched', () {
      final modified = DateTime.utc(2025, 6, 18, 16, 30);
      final model = newScreenshotModel(
        filePath: '/sdcard/Pictures/shot.png',
        modified: modified,
        sizeInBytes: 2048,
      );

      expect(model.filePath, '/sdcard/Pictures/shot.png');
      expect(model.createdAt, modified);
      expect(model.fileSize, 2048);
      expect(model.isProcessed, isFalse);
      expect(model.isExpense, isFalse);
      expect(model.thumbnailPath, isNull);
      expect(model.extractedText, isNull);
      expect(model.category, isNull);
      expect(model.width, isNull);
      expect(model.height, isNull);
    });

    test('zero/negative sizes are stored verbatim for the UI to degrade', () {
      expect(
        newScreenshotModel(
          filePath: '/z.png',
          modified: DateTime.utc(2025),
          sizeInBytes: 0,
        ).fileSize,
        0,
      );
      expect(
        newScreenshotModel(
          filePath: '/z.png',
          modified: DateTime.utc(2025),
          sizeInBytes: -1,
        ).fileSize,
        -1,
      );
    });
  });

  group('ScanOutcome', () {
    test('defaults are all-zero and printable', () {
      const outcome = ScanOutcome();
      expect(outcome.databaseReady, isTrue);
      expect(outcome.wasAborted, isFalse);
      expect(outcome.changedAnything, isFalse);
      expect(outcome.discovered, 0);
      expect(outcome.persisted, 0);
      expect(outcome.duplicatesSkipped, 0);
      expect(outcome.failures, 0);
      expect(
        outcome.toString(),
        'ScanOutcome(databaseReady: true, discovered: 0, persisted: 0, '
        'duplicatesSkipped: 0, failures: 0)',
      );
    });

    test('aborted sentinel carries no counters', () {
      const outcome = ScanOutcome.aborted();
      expect(outcome.wasAborted, isTrue);
      expect(outcome.databaseReady, isFalse);
      expect(outcome.changedAnything, isFalse);
    });

    test('changedAnything gates cache invalidation on real inserts', () {
      expect(
        const ScanOutcome(discovered: 3, duplicatesSkipped: 3).changedAnything,
        isFalse,
      );
      expect(const ScanOutcome(persisted: 1).changedAnything, isTrue);
    });
  });

  group('list/detail/search providers with an injected repository', () {
    test('screenshotListProvider returns repository items', () async {
      final items = [item(id: 1), item(id: 2, filePath: '/b.png')];
      final container = ProviderContainer(
        overrides: [
          screenshotRepositoryProvider.overrideWithValue(
            _FakeRepo(items: items),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(screenshotListProvider.future), items);
    });

    test('screenshotDetailProvider resolves a family id or null', () async {
      final container = ProviderContainer(
        overrides: [
          screenshotRepositoryProvider.overrideWithValue(
            _FakeRepo(items: [item(id: 5, filePath: '/five.png')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        (await container.read(screenshotDetailProvider(5).future))?.filePath,
        '/five.png',
      );
      expect(await container.read(screenshotDetailProvider(99).future), isNull);
    });

    test('searchScreenshotsProvider forwards the query result', () async {
      final container = ProviderContainer(
        overrides: [
          screenshotRepositoryProvider.overrideWithValue(
            _FakeRepo(searchResults: [item(id: 3, filePath: '/amazon.png')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final results = await container.read(
        searchScreenshotsProvider('amazon').future,
      );
      expect(results.single.filePath, '/amazon.png');
    });

    test('scanningProvider starts idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(scanningProvider), isFalse);
    });
  });

  group('scan() database guard', () {
    test(
      'aborts before touching photo_manager/ML Kit when DB is closed',
      () async {
        final repo = _FakeRepo(items: [item()]);
        final container = ProviderContainer(
          overrides: [screenshotRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        // No DatabaseService.init() in a unit test → the ready guard fires and
        // the scan returns instead of letting the `db` getter throw.
        final notifier = container.read(scanScreenshotsProvider.notifier);
        await notifier.scan();

        expect(container.read(scanningProvider), isFalse);
        expect(repo.getAllCalls, 0);
        expect(repo.saved, isEmpty);
        // The abort is silent by design (screens fire-and-forget), so no
        // AsyncError is published for it either.
        expect(container.read(scanScreenshotsProvider).hasError, isFalse);
      },
    );

    test('scan() stays Future<void>-compatible for UI subclasses', () async {
      // The home/list screens inject a recording subclass; keeping the
      // override signature stable (`Future<void> scan()`) is part of the API.
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          scanScreenshotsProvider.overrideWith(
            () => _RecordingScan(() => calls++),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(scanScreenshotsProvider.notifier).scan();
      await container.read(scanScreenshotsProvider.notifier).scan();
      expect(calls, 2);
    });
  });
}

/// Mirrors the shape the screens use: a `ScanScreenshotsNotifier` whose
/// `scan()` is replaced without touching Isar or ML Kit.
class _RecordingScan extends ScanScreenshotsNotifier {
  _RecordingScan(this.onScan);

  final void Function() onScan;

  @override
  Future<void> scan() async => onScan();
}
