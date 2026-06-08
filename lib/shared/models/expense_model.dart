import 'package:isar/isar.dart';

part 'expense_model.g.dart';

@collection
class ExpenseModel {
  Id id = Isar.autoIncrement;
  late int screenshotId;
  double? amount;
  String? merchant;
  DateTime? expenseDate;
  String? category;
  String? description;
  late DateTime createdAt;
}
