import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../shared/models/screenshot_model.dart';
import '../shared/models/expense_model.dart';

class DatabaseService {
  static late Isar instance;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    instance = await Isar.open(
      [ScreenshotModelSchema, ExpenseModelSchema],
      directory: dir.path,
      inspector: true,
    );
    _initialized = true;
  }

  static Isar get db {
    if (!_initialized) {
      throw Exception(
        'Database not initialized. Call DatabaseService.init() first.',
      );
    }
    return instance;
  }
}
