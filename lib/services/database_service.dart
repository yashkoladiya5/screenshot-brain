import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../shared/models/screenshot_model.dart';
import '../shared/models/expense_model.dart';

/// Process-wide lazy singleton around the Isar database.
///
/// [init] is idempotent and concurrency-safe: simultaneous callers share one
/// shared opening [Future], so two Isar instances can never be opened for the
/// same directory. If opening fails the guard resets and a later caller can
/// retry.
class DatabaseService {
  DatabaseService._();

  static Isar? _instance;
  static Future<void>? _opening;

  /// Whether the database is ready for synchronous access via [db].
  static bool get isInitialized => _instance != null;

  /// Opens the database if needed. Concurrent calls await the same Future.
  static Future<void> init() {
    if (_instance != null) return Future.value();
    return _opening ??= _open();
  }

  static Future<void> _open() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _instance = await Isar.open(
        [ScreenshotModelSchema, ExpenseModelSchema],
        directory: dir.path,
        inspector: true,
      );
    } catch (_) {
      // Allow a later init() call to retry instead of caching the failure.
      _opening = null;
      rethrow;
    }
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
  /// (used by tests and shutdown). Safe to call when never initialized.
  static Future<void> close() async {
    final instance = _instance;
    _instance = null;
    _opening = null;
    if (instance != null) {
      await instance.close();
    }
  }
}
