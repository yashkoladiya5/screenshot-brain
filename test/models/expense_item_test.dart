import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/shared/models/expense_item.dart';
import 'package:screenshot_brain/shared/models/expense_model.dart';

ExpenseModel model({
  int id = 1,
  int screenshotId = 1,
  double? amount,
  String? merchant,
  DateTime? expenseDate,
  String? category,
  String? description,
  DateTime? createdAt,
}) {
  return ExpenseModel()
    ..id = id
    ..screenshotId = screenshotId
    ..amount = amount
    ..merchant = merchant
    ..expenseDate = expenseDate
    ..category = category
    ..description = description
    ..createdAt = createdAt ?? DateTime.utc(2025, 6, 18, 9);
}

void main() {
  group('ExpenseItem.fromModel', () {
    test('mirrors every persisted field', () {
      final spent = DateTime.utc(2025, 6, 17, 20, 45);
      final created = DateTime.utc(2025, 6, 18, 9);
      final item = ExpenseItem.fromModel(
        model(
          id: 9,
          screenshotId: 3,
          amount: 129900,
          merchant: 'Decathlon',
          expenseDate: spent,
          category: 'Sports',
          description: 'In-store purchase',
          createdAt: created,
        ),
      );

      expect(item.id, 9);
      expect(item.screenshotId, 3);
      expect(item.amount, 129900);
      expect(item.merchant, 'Decathlon');
      expect(item.expenseDate, spent);
      expect(item.category, 'Sports');
      expect(item.description, 'In-store purchase');
      expect(item.createdAt, created);
      expect(item.status, ExpenseStatus.complete);
    });

    test('an unset late screenshotId/createdAt degrades to sentinels', () {
      final item = ExpenseItem.fromModel(ExpenseModel());
      expect(item.screenshotId, 0);
      expect(item.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(item.amount, isNull);
      expect(item.status, ExpenseStatus.unparsed);
    });
  });

  group('ExpenseItem.status mapping', () {
    test('derives completeness from amount + merchant presence', () {
      expect(ExpenseItem.fromModel(model()).status, ExpenseStatus.unparsed);
      expect(
        ExpenseItem.fromModel(model(amount: 10)).status,
        ExpenseStatus.amountOnly,
      );
      expect(
        ExpenseItem.fromModel(model(merchant: 'Zomato')).status,
        ExpenseStatus.merchantOnly,
      );
      expect(
        ExpenseItem.fromModel(model(amount: 10, merchant: 'Zomato')).status,
        ExpenseStatus.complete,
      );
    });

    test('whitespace-only merchant counts as missing', () {
      final item = ExpenseItem.fromModel(model(amount: 5, merchant: '   '));
      expect(item.hasMerchant, isFalse);
      expect(item.status, ExpenseStatus.amountOnly);
      expect(item.merchantDisplay, 'Unknown merchant');
      expect(item.statusLabel, 'Amount only');
      expect(item.status.hasUsableData, isTrue);
      expect(ExpenseItem.fromModel(model()).status.hasUsableData, isFalse);
    });
  });

  group('ExpenseItem money formatting (Indian grouping)', () {
    test('formats with lakh/crore grouping and the rupee symbol', () {
      expect(
        ExpenseItem.fromModel(model(amount: 129900)).amountDisplay,
        '₹1,29,900.00',
      );
      expect(
        ExpenseItem.fromModel(model(amount: 10000000)).amountDisplay,
        '₹1,00,00,000.00',
      );
      expect(
        ExpenseItem.fromModel(model(amount: 143.5)).amountDisplay,
        '₹143.50',
      );
      expect(
        ExpenseItem.fromModel(model(amount: 0.005)).amountDisplay,
        contains('₹'),
      );
    });

    test('zero, negative and null amounts are all defined', () {
      expect(ExpenseItem.fromModel(model(amount: 0)).amountDisplay, '₹0.00');
      final negative = ExpenseItem.fromModel(
        model(amount: -1234.5),
      ).amountDisplay;
      expect(negative, '-₹1,234.50');
      expect(ExpenseItem.fromModel(model()).amountDisplay, 'N/A');
      expect(ExpenseItem.fromModel(model()).amountDisplayWhole, 'N/A');
      expect(ExpenseItem.fromModel(model()).amountDisplayCompact, 'N/A');
    });

    test('whole-rupee and compact variants stay rupee-tagged', () {
      expect(
        ExpenseItem.fromModel(model(amount: 7250)).amountDisplayWhole,
        '₹7,250',
      );
      expect(
        ExpenseItem.fromModel(model(amount: 150000)).amountDisplayCompact,
        startsWith('₹'),
      );
    });
  });

  group('ExpenseItem text and date formatting', () {
    test('date displays fall back to placeholders', () {
      final item = ExpenseItem.fromModel(
        model(expenseDate: DateTime.utc(2023, 10, 24)),
      );
      expect(item.dateDisplay, '24 Oct 2023');
      expect(item.standardDateDisplay, 'Oct 24, 2023');
      expect(item.monthLabel, 'Oct 2023');

      final missing = ExpenseItem.fromModel(model());
      expect(missing.dateDisplay, 'N/A');
      expect(missing.standardDateDisplay, 'N/A');
      expect(missing.monthLabel, '');
    });

    test('category and description never return null', () {
      expect(ExpenseItem.fromModel(model()).categoryDisplay, 'Uncategorized');
      expect(
        ExpenseItem.fromModel(model(category: '')).categoryDisplay,
        'Uncategorized',
      );
      expect(ExpenseItem.fromModel(model()).descriptionDisplay, '');
      expect(
        ExpenseItem.fromModel(
          model(description: '  UPI   payment\nto seller '),
        ).descriptionDisplay,
        'UPI payment to seller',
      );
      final long = ExpenseItem.fromModel(
        model(description: 'x' * 150),
      ).descriptionDisplay;
      expect(long.length, 101);
      expect(long.endsWith('…'), isTrue);
    });

    test('created timestamp renders relative to a pinned clock', () {
      final item = ExpenseItem.fromModel(
        model(createdAt: DateTime.utc(2025, 6, 18, 16, 30)),
      );
      expect(
        item.createdDisplayAgainst(DateTime.utc(2025, 6, 18, 18)),
        'Today at 4:30 PM',
      );
      expect(
        item.createdDisplayAgainst(DateTime.utc(2025, 6, 19)),
        'Yesterday at 4:30 PM',
      );
      expect(
        item.createdDisplayAgainst(DateTime.utc(2030, 1, 1)),
        'Jun 18, 2025',
      );
    });
  });

  group('ExpenseItem copyWith / equality', () {
    final base = ExpenseItem.fromModel(
      model(
        id: 4,
        screenshotId: 8,
        amount: 500,
        merchant: 'Swiggy',
        expenseDate: DateTime.utc(2025, 6, 1),
        category: 'Food',
      ),
    );

    test('copyWith preserves unset fields', () {
      final copy = base.copyWith(amount: 750, description: 'late night');
      expect(copy.amount, 750);
      expect(copy.description, 'late night');
      expect(copy.id, base.id);
      expect(copy.screenshotId, base.screenshotId);
      expect(copy.merchant, base.merchant);
      expect(copy.expenseDate, base.expenseDate);
      expect(copy.category, base.category);
      expect(copy.createdAt, base.createdAt);
      expect(base.copyWith(), base);
    });

    test('value equality, hashing and toString', () {
      expect(
        base,
        ExpenseItem.fromModel(
          model(
            id: 4,
            screenshotId: 8,
            amount: 500,
            merchant: 'Swiggy',
            expenseDate: DateTime.utc(2025, 6, 1),
            category: 'Food',
          ),
        ),
      );
      expect(base.hashCode, base.copyWith().hashCode);
      expect(base.copyWith(merchant: 'Zomato') == base, isFalse);
      expect({base, base.copyWith(amount: 1)}.length, 2);
      expect(base.toString(), contains('status: complete'));
      expect(base.toString(), contains('screenshotId: 8'));
    });
  });
}
