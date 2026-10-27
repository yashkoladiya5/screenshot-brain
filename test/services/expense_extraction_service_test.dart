import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/services/expense_extraction_service.dart';
import 'package:screenshot_brain/shared/models/expense_model.dart';
import 'package:screenshot_brain/core/utils/string_validators.dart';

void main() {
  group('extractAmount', () {
    test('parses currency-prefixed amounts across symbols', () {
      expect(ExpenseExtractionService.extractAmount('₹1,299.00'), 1299.0);
      expect(ExpenseExtractionService.extractAmount('Rs. 500 paid'), 500.0);
      expect(ExpenseExtractionService.extractAmount('Paid ₹2,450'), 2450.0);
      expect(ExpenseExtractionService.extractAmount('€50'), 50.0);
      expect(ExpenseExtractionService.extractAmount('£120.50'), 120.5);
      expect(ExpenseExtractionService.extractAmount('\$25.99'), 25.99);
      expect(ExpenseExtractionService.extractAmount('100 USD'), 100.0);
      expect(ExpenseExtractionService.extractAmount('INR 750'), 750.0);
    });

    test('handles thousands separators and decimal commas', () {
      expect(ExpenseExtractionService.extractAmount('Rs 1299,90'), 1299.90);
      expect(ExpenseExtractionService.extractAmount('1.299,90 €'), 1299.90);
      expect(
        ExpenseExtractionService.extractAmount('₹1,29,900 paid'),
        isNotNull,
      );
      expect(ExpenseExtractionService.extractAmount('Rs. 12,345'), 12345.0);
    });

    test('prefers the total line over smaller line items', () {
      expect(
        ExpenseExtractionService.extractAmount(
          '₹500 advance payment\nTotal 1,200',
        ),
        1200.0,
      );
      expect(
        ExpenseExtractionService.extractAmount('Items 5\nTotal: 450'),
        450.0,
      );
      expect(
        ExpenseExtractionService.extractAmount(
          'Amount Paid: ₹2,450 (incl. ₹50 fee)',
        ),
        2450.0,
      );
    });

    test('rejects dates and phone numbers masquerading as amounts', () {
      expect(
        ExpenseExtractionService.extractAmount('Payment done on 12/05/2024'),
        isNull,
      );
      expect(
        ExpenseExtractionService.extractAmount('dated 05-Dec-2024'),
        isNull,
      );
      expect(
        ExpenseExtractionService.extractAmount('call 9876543210 now'),
        isNull,
      );
      expect(
        ExpenseExtractionService.extractAmount('Transaction ID 432198765432'),
        isNull,
      );
    });

    test('still finds the amount next to a date', () {
      expect(
        ExpenseExtractionService.extractAmount('05/12/2024 ₹1,299'),
        1299.0,
      );
    });

    test('returns null for empty or numberless text', () {
      expect(ExpenseExtractionService.extractAmount(''), isNull);
      expect(ExpenseExtractionService.extractAmount('   '), isNull);
      expect(ExpenseExtractionService.extractAmount('no digits here'), isNull);
    });
  });

  group('extractDate', () {
    test('parses December month names (regression: was mis-spelled "Dev")', () {
      expect(
        ExpenseExtractionService.extractDate('Paid on 5 Dec 2024'),
        DateTime(2024, 12, 5),
      );
      expect(
        ExpenseExtractionService.extractDate('Payment dated 25 December 2024'),
        DateTime(2024, 12, 25),
      );
      expect(
        ExpenseExtractionService.extractDate('05-Dec-2024'),
        DateTime(2024, 12, 5),
      );
      expect(
        ExpenseExtractionService.extractDate('Dec 24, 2024'),
        DateTime(2024, 12, 24),
      );
    });

    test('parses other month names and numeric forms', () {
      expect(
        ExpenseExtractionService.extractDate('3 Nov 2024'),
        DateTime(2024, 11, 3),
      );
      expect(
        ExpenseExtractionService.extractDate('12/05/2024'),
        DateTime(2024, 5, 12),
      );
      expect(
        ExpenseExtractionService.extractDate('2024-05-12'),
        DateTime(2024, 5, 12),
      );
    });

    test('day-first unless impossible, then month-first', () {
      expect(
        ExpenseExtractionService.extractDate('25/12/2024'),
        DateTime(2024, 12, 25),
      );
      expect(
        ExpenseExtractionService.extractDate('12/25/2024'),
        DateTime(2024, 12, 25),
      );
    });

    test('expands two-digit years', () {
      expect(
        ExpenseExtractionService.extractDate('5 Dec 24'),
        DateTime(2024, 12, 5),
      );
      expect(
        ExpenseExtractionService.extractDate('01/02/99'),
        DateTime(1999, 2, 1),
      );
    });

    test('rejects impossible calendar dates and implausible years', () {
      expect(ExpenseExtractionService.extractDate('31/02/2024'), isNull);
      expect(ExpenseExtractionService.extractDate('13/13/2024'), isNull);
      expect(
        ExpenseExtractionService.extractDate('29/02/2023'),
        isNull,
      ); // not a leap year
      expect(ExpenseExtractionService.extractDate('01/01/3000'), isNull);
      expect(ExpenseExtractionService.extractDate('no date at all'), isNull);
      expect(ExpenseExtractionService.extractDate(''), isNull);
    });

    test('accepts leap day in leap years', () {
      expect(
        ExpenseExtractionService.extractDate('29/02/2024'),
        DateTime(2024, 2, 29),
      );
    });
  });

  group('extractMerchant', () {
    test('reads explicit payee patterns', () {
      expect(
        ExpenseExtractionService.extractMerchant('Paid to Swiggy'),
        'Swiggy',
      );
      expect(
        ExpenseExtractionService.extractMerchant('Merchant: BigBasket'),
        'BigBasket',
      );
      expect(
        ExpenseExtractionService.extractMerchant(
          '₹250 paid to Rajesh Kumar for lunch',
        ),
        'Rajesh Kumar',
      );
      expect(
        ExpenseExtractionService.extractMerchant(
          'sent to Amazon India. Track your order',
        ),
        'Amazon India',
      );
    });

    test('falls back to the first name-like line, skipping noise', () {
      expect(
        ExpenseExtractionService.extractMerchant(
          'Zomato\nOrder confirmed\nTotal ₹350',
        ),
        'Zomato',
      );
      expect(
        ExpenseExtractionService.extractMerchant(
          'Payment Successful\nUber India\n₹120',
        ),
        'Uber India',
      );
    });

    test('returns null when nothing looks like a merchant', () {
      expect(ExpenseExtractionService.extractMerchant('123 456'), isNull);
      expect(ExpenseExtractionService.extractMerchant(''), isNull);
      expect(
        ExpenseExtractionService.extractMerchant('thank you, come again'),
        isNull,
      );
    });
  });

  group('extractExpense', () {
    test('builds a full expense model from a receipt', () {
      final text = 'Swiggy\nPaid to Swiggy ₹350 on 12/05/2024\nTotal 350';
      final expense = ExpenseExtractionService.extractExpense(text, 42);
      expect(expense.screenshotId, 42);
      expect(expense.amount, 350.0);
      expect(expense.merchant, 'Swiggy');
      expect(expense.expenseDate, DateTime(2024, 5, 12));
      expect(expense.category, 'Food');
      expect(expense.description, text);
      expect(expense.createdAt, isA<DateTime>());
    });

    test('categorizes expense subtypes', () {
      ExpenseModel cat(String t) =>
          ExpenseExtractionService.extractExpense(t, 1);
      expect(cat('Flipkart order delivered').category, 'Shopping');
      expect(cat('Uber ride ₹120').category, 'Travel');
      expect(cat('mobile recharge ₹499').category, 'Bills');
      expect(cat('netflix subscription').category, 'Entertainment');
      expect(cat('pharmacy bill ₹800').category, 'Healthcare');
      expect(cat('random screenshot text').category, 'Other');
    });

    test('defaults gracefully on junk text', () {
      final before = DateTime.now();
      final expense = ExpenseExtractionService.extractExpense('hello world', 7);
      expect(expense.amount, isNull);
      expect(expense.merchant, isNull);
      expect(expense.category, 'Other');
      expect(
        expense.expenseDate!.isBefore(
          before.subtract(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });

    test('truncates long descriptions', () {
      final expense = ExpenseExtractionService.extractExpense('a' * 250, 1);
      expect(expense.description!.length, 203);
      expect(expense.description!.endsWith('...'), isTrue);
    });
  });

  // ----------------------------------------------------------------- defects
  // Every expectation below was proven against the shipped parser first: the
  // inputs are real OCR shapes (bills priced `Rs. 500/-`, phone numbers
  // grouped `98765 43210`, sentence-initial `From Big Bazaar`, lowercase
  // payees, tagline lines) that the old code dropped or mis-read.

  group('extractAmount Indian "/-" bill notation', () {
    test('reads the trailing "/-" (and "/=") price marker as an amount', () {
      expect(ExpenseExtractionService.extractAmount('Total Rs. 500/-'), 500.0);
      expect(
        ExpenseExtractionService.extractAmount('Grand Total ₹1,200.00/-'),
        1200.0,
      );
      expect(
        ExpenseExtractionService.extractAmount('Amount 1,29,900/-'),
        129900.0,
      );
      expect(ExpenseExtractionService.extractAmount('Rs 250/= only'), 250.0);
      expect(ExpenseExtractionService.extractAmount('500/-'), 500.0);
    });

    test('still rejects slash-separated dates and fractions', () {
      expect(
        ExpenseExtractionService.extractAmount('Payment done on 12/05/2024'),
        isNull,
      );
      expect(ExpenseExtractionService.extractAmount('page 3/10'), isNull);
      expect(
        ExpenseExtractionService.extractAmount('Total 1,200 dated 05/12/2024'),
        1200.0,
      );
    });
  });

  group('extractAmount digit ceiling shared with StringValidators', () {
    test('a 9-digit magnitude amount is money, 10+ digits is a reference', () {
      expect(
        ExpenseExtractionService.extractAmount('Amount 123456789'),
        123456789.0,
      );
      expect(ExpenseExtractionService.extractAmount('₹999999999'), 999999999.0);
      expect(ExpenseExtractionService.extractAmount('₹9999999999'), isNull);
      expect(ExpenseExtractionService.extractAmount('call 9876543210'), isNull);
    });

    test('stays in lockstep with the validators single source of truth', () {
      // lib/core/utils/string_validators.dart mirrors this pipeline; any drift
      // means a form accepts an amount extraction can never produce (or the
      // other way round).
      for (final amount in [
        '50',
        '1299.90',
        '1299,90',
        '1,299',
        '1,299.90',
        '1,29,900',
        '1,29,900.50',
        '1.299,90',
        '12345678',
        '123456789',
        '999999999',
        '9999999999',
        '1234567890123',
      ]) {
        expect(
          ExpenseExtractionService.extractAmount('Total $amount'),
          StringValidators.parseAmount(amount),
          reason: 'pipeline and validator disagree on "$amount"',
        );
      }
      for (final amount in ['₹1,29,900', 'Rs. 450', 'INR 2,500', '1,234.56']) {
        expect(
          ExpenseExtractionService.extractAmount('Total $amount'),
          StringValidators.parseAmount(amount),
          reason: 'pipeline and validator disagree on "$amount"',
        );
      }
    });
  });

  group('extractAmount space-grouped number runs', () {
    test('rejects phones and card numbers split by spaces', () {
      expect(
        ExpenseExtractionService.extractAmount('call 98765 43210'),
        isNull,
      );
      expect(ExpenseExtractionService.extractAmount('98765 43210'), isNull);
      expect(
        ExpenseExtractionService.extractAmount('card 4111 1111 1111 1112'),
        isNull,
      );
      expect(
        ExpenseExtractionService.extractAmount('utr 123456 789012 345678'),
        isNull,
      );
    });

    test('keeps genuine amounts that merely sit next to small numbers', () {
      expect(
        ExpenseExtractionService.extractAmount('Sl no 1 Amount 250'),
        250.0,
      );
      expect(
        ExpenseExtractionService.extractAmount('Items 5\nTotal: 450'),
        450.0,
      );
      expect(
        ExpenseExtractionService.extractAmount('2 tablets 500 mg ₹1,200'),
        1200.0,
      );
    });
  });

  group('extractDate ordinals and month-name punctuation', () {
    test('parses ordinal day suffixes', () {
      expect(
        ExpenseExtractionService.extractDate('Paid on 1st Jan 2024'),
        DateTime(2024, 1, 1),
      );
      expect(
        ExpenseExtractionService.extractDate('Invoice dated 22nd October 2024'),
        DateTime(2024, 10, 22),
      );
      expect(
        ExpenseExtractionService.extractDate('5th March, 2024'),
        DateTime(2024, 3, 5),
      );
      expect(
        ExpenseExtractionService.extractDate('31st Dec 2024'),
        DateTime(2024, 12, 31),
      );
    });

    test('parses a comma between the month name and the day', () {
      expect(
        ExpenseExtractionService.extractDate('January, 5, 2024'),
        DateTime(2024, 1, 5),
      );
      expect(
        ExpenseExtractionService.extractDate('Dec., 5 2024'),
        DateTime(2024, 12, 5),
      );
    });

    test('ordinals never turn a phone or ref run into a date', () {
      expect(
        ExpenseExtractionService.extractDate('Ref 1234567890123456'),
        isNull,
      );
      expect(ExpenseExtractionService.extractDate('2nd Feb 9999'), isNull);
    });
  });

  group('extractMerchant real-OCR shapes', () {
    test('drops trailing punctuation instead of losing the name', () {
      expect(
        ExpenseExtractionService.extractMerchant('Paid to BigBasket!'),
        'BigBasket',
      );
      expect(
        ExpenseExtractionService.extractMerchant(
          'Paid to BigBasket! Total 350',
        ),
        'BigBasket',
      );
      expect(
        ExpenseExtractionService.extractMerchant('Merchant: Croma?'),
        'Croma',
      );
    });

    test('keeps looking after a label match that is only noise', () {
      expect(
        ExpenseExtractionService.extractMerchant(
          'Paid via UPI\nPaid to BigBasket',
        ),
        'BigBasket',
      );
      expect(
        ExpenseExtractionService.extractMerchant(
          'Paid through Paytm Merchant\nsent to Anil Kitchen',
        ),
        'Anil Kitchen',
      );
    });

    test('matches a sentence-initial From / At label', () {
      expect(
        ExpenseExtractionService.extractMerchant('From Big Bazaar on 12/05'),
        'Big Bazaar',
      );
      expect(
        ExpenseExtractionService.extractMerchant('At Decathlon for ₹4,999'),
        'Decathlon',
      );
    });

    test('keeps a lowercase payee as the OCR spelled it', () {
      expect(
        ExpenseExtractionService.extractMerchant('₹350 paid to bigbasket'),
        'bigbasket',
      );
      expect(
        ExpenseExtractionService.extractMerchant('sent to alexa.'),
        'alexa',
      );
      expect(
        ExpenseExtractionService.extractMerchant(
          'paid to rajesh kumar for lunch',
        ),
        'rajesh kumar',
      );
      expect(
        ExpenseExtractionService.extractMerchant('paid to upi id'),
        isNull,
      );
    });

    test('refuses taglines and domain lines in the fallback', () {
      expect(
        ExpenseExtractionService.extractMerchant(
          'Best Offers Online\nTotal ₹350',
        ),
        isNull,
      );
      expect(
        ExpenseExtractionService.extractMerchant(
          'Www.Bigbasket.Com\nTotal ₹350',
        ),
        isNull,
      );
      expect(
        ExpenseExtractionService.extractMerchant(
          'Pay Using Our App\nTotal ₹350',
        ),
        isNull,
      );
      expect(
        ExpenseExtractionService.extractMerchant(
          'India\'s Largest Marketplace\nTotal ₹350',
        ),
        isNull,
      );
    });

    test('still returns the real merchant from a noisy receipt', () {
      expect(
        ExpenseExtractionService.extractMerchant(
          'Best Offers Online\nSpice Garden\nTotal ₹1,200',
        ),
        'Spice Garden',
      );
    });
  });

  group('category priority wiring', () {
    test('every keyword category is ranked, so none is ignored', () {
      ExpenseModel cat(String t) =>
          ExpenseExtractionService.extractExpense(t, 1);
      expect(cat('doctor clinic visit medicine').category, 'Healthcare');
      expect(cat('zomato swiggy dinner restaurant').category, 'Food');
      expect(cat('irctc boarding pass train').category, 'Travel');
      expect(cat('netflix hotstar cinema movie').category, 'Entertainment');
      expect(cat('electricity bill recharge broadband').category, 'Bills');
      expect(cat('amazon flipkart myntra clothes').category, 'Shopping');
    });

    test('ties resolve by the documented priority, not table order', () {
      // 'zomato' (Food, 6) vs 'amazon' (Shopping, 6): Food is ranked before
      // Shopping, so Food must win regardless of map iteration order.
      expect(
        ExpenseExtractionService.extractExpense('amazon zomato', 1).category,
        'Food',
      );
      expect(
        ExpenseExtractionService.extractExpense('zomato amazon', 1).category,
        'Food',
      );
    });
  });
}
