import 'package:isar/isar.dart';

part 'screenshot_model.g.dart';

@collection
class ScreenshotModel {
  Id id = Isar.autoIncrement;
  late String filePath;
  String? thumbnailPath;
  String? extractedText;
  String? category;
  late DateTime createdAt;
  int? fileSize;
  int? width;
  int? height;
  bool isProcessed = false;
  bool isExpense = false;
}
