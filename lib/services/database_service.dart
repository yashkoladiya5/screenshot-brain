import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../shared/models/screenshot_model.dart';
import '../shared/models/expense_model.dart';

/// Replacement point for the real [Isar.open]: a test can hand the service a
/// fake database without touching the native library.
typedef IsarOpenFunction =
    Future<Isar> Function(
      List<CollectionSchema<dynamic>> schemas,
      String directoryPath,
    );

/// Process-wide lazy singleton around the Isar database.
///
/// [init] is idempotent and concurrency-safe: simultaneous callers share one
/// shared opening [Future], so two Isar instances can never be opened for the
/// same directory. If opening fails the guard resets and a later caller can
/// retry. [close] invalidates an open that is still in flight: the instance
/// produced by that open is shut down instead of being installed, so a close
/// can never be resurrected by a late-completing open.
class DatabaseService {
  DatabaseService._();

  static Isar? _instance;
  static Future<void>? _opening;

  /// Bumped by every [close]; an in-flight [_open] compares its generation to
  /// decide whether its result was already obsolete when it landed.
  static int _generation = 0;

  /// The collections the database is opened with. Exposed so tests can pin
  /// the option set without opening Isar.
  ///
  /// Frozen: this list is handed straight to the (injectable) opener, so a
  /// consumer that sorts or trims the list it receives would silently change
  /// which collections every later open registers — a dropped schema means
  /// Isar refuses to open or a whole collection's rows become unreachable.
  @visibleForTesting
  static final List<CollectionSchema<dynamic>> collectionSchemas =
      List.unmodifiable([ScreenshotModelSchema, ExpenseModelSchema]);

  static Future<Isar> _defaultOpen(
    List<CollectionSchema<dynamic>> schemas,
    String directoryPath,
  ) {
    return Isar.open(schemas, directory: directoryPath, inspector: true);
  }

  static Future<Directory> _defaultDocumentsDirectory() =>
      getApplicationDocumentsDirectory();

  static IsarOpenFunction _opener = _defaultOpen;
  static Future<Directory> Function() _documentsDirectory =
      _defaultDocumentsDirectory;

  /// Test seam: replaces the native [Isar.open] call. Pass null to restore
  /// production behavior. Never used by app code.
  @visibleForTesting
  static set testOpener(IsarOpenFunction? opener) {
    _opener = opener ?? _defaultOpen;
  }

  /// Test seam: replaces `getApplicationDocumentsDirectory`. Pass null to
  /// restore production behavior.
  @visibleForTesting
  static set testDocumentsDirectory(Future<Directory> Function()? provider) {
    _documentsDirectory = provider ?? _defaultDocumentsDirectory;
  }

  /// Whether the database is ready for synchronous access via [db].
  static bool get isInitialized => _instance != null;

  /// Opens the database if needed. Concurrent calls await the same Future.
  static Future<void> init() {
    if (_instance != null) return Future.value();
    return _opening ??= _open();
  }

  /// The directory the database is stored in, derived from the documents
  /// directory. Isolated as a pure function so the path computation is
  /// testable and the storage location has exactly one definition.
  @visibleForTesting
  static String databaseDirectoryPath(Directory documentsDirectory) =>
      documentsDirectory.path;

  static Future<void> _open() async {
    final generation = _generation;
    Isar opened;
    try {
      final dir = await _documentsDirectory();
      opened = await _opener(collectionSchemas, databaseDirectoryPath(dir));
    } catch (_) {
      if (generation == _generation) {
        // Allow a later init() call to retry instead of caching the failure.
        // When a close() already superseded this open, the shared guard belongs
        // to a newer one and must not be cleared here.
        _opening = null;
      }
      rethrow;
    }
    if (generation != _generation) {
      // close() ran while this open was still in flight. The freshly opened
      // instance is an orphan: shut it down rather than installing it, or the
      // singleton would claim an initialized database that callers already
      // asked to tear down (and leak the native handle).
      await opened.close();
      return;
    }
    _instance = opened;
  }

  /// The open database. Throws [StateError] when [init] has not completed.
  static Isar get db {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'Database not initialized. Call DatabaseService.init() first.',
      );
    }
    return instance;
  }

  /// Alias of [db] kept for callers that used the old `instance` accessor.
  static Isar get instance => db;

  /// The open database, or null when not initialized (no throwing path).
  static Isar? get maybeDb => _instance;

  /// Completes once the database is open; equivalent to awaiting [init]
  /// and reading [db].
  static Future<Isar> ready() async {
    await init();
    return db;
  }

  /// Closes the database and resets the singleton so [init] can open it again
  /// (used by tests and shutdown). Safe to call when never initialized, and
  /// safe to call while an open is still in flight: that open's result is
  /// closed on arrival instead of being installed.
  static Future<void> close() async {
    final instance = _instance;
    _instance = null;
    _opening = null;
    _generation++;
    if (instance != null) {
      await instance.close();
    }
  }
}
