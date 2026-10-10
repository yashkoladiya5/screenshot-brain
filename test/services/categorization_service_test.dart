import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/services/categorization_service.dart';

void main() {
  group('categorize', () {
    test('returns Other for empty or blank text', () {
      expect(CategorizationService.categorize(''), 'Other');
      expect(CategorizationService.categorize('   '), 'Other');
    });

    test('returns Other when no keyword clears the confidence threshold', () {
      expect(CategorizationService.categorize('a walk in the park'), 'Other');
      // Single generic "bill" (weight 3) is below the threshold.
      expect(CategorizationService.categorize('the bill is due'), 'Other');
    });

    test('categorizes UPI receipts', () {
      expect(
        CategorizationService.categorize(
          'UPI transaction successful\nTrxID 43219876\npaid to Rajesh',
        ),
        'UPI Receipts',
      );
    });

    test('categorizes travel tickets via multi-word phrase', () {
      expect(
        CategorizationService.categorize(
          'Please find my boarding pass attached',
        ),
        'Travel Tickets',
      );
      expect(
        CategorizationService.categorize('IRCTC ticket booked'),
        'Travel Tickets',
      );
    });

    test('categorizes OTP screenshots', () {
      expect(
        CategorizationService.categorize(
          'Your OTP is 123456. Do not share it.',
        ),
        'OTP Screenshots',
      );
    });

    test('categorizes social media, bills and documents', () {
      expect(
        CategorizationService.categorize('instagram profile post'),
        'Social Media',
      );
      expect(
        CategorizationService.categorize('credit card bill statement'),
        'Bills',
      );
      expect(
        CategorizationService.categorize('Here is my PAN card photo'),
        'Documents',
      );
    });

    test('matching is case-insensitive', () {
      expect(
        CategorizationService.categorize('AMAZON ORDER CONFIRMED'),
        'Shopping',
      );
      expect(
        CategorizationService.categorize('Amazon order confirmed'),
        'Shopping',
      );
    });

    test('word-boundary safe: no substring false hits', () {
      // "border" must not trigger the "order" keyword.
      expect(CategorizationService.categorize('my border collie dog'), 'Other');
      // "billion" must not trigger "bill", "receipt" inside other words either.
      expect(
        CategorizationService.categorize('a billion dollars fund'),
        'Other',
      );
    });

    test('ties are resolved by category priority order', () {
      // "amazon" (Shopping 6) vs "flight" (Travel 6): Travel Tickets has
      // higher priority than Shopping.
      expect(
        CategorizationService.categorize('amazon flight'),
        'Travel Tickets',
      );
      // UPI Receipts outranks Payments when both clear equally strong cues.
      expect(
        CategorizationService.categorize('bhim upi payment'),
        'UPI Receipts',
      );
    });

    test('stronger combined score beats priority order', () {
      expect(
        CategorizationService.categorize(
          'flight booking on amazon delivered and shipped',
        ),
        'Shopping',
      );
    });
  });

  group('isExpense', () {
    test('false for empty text', () {
      expect(CategorizationService.isExpense(''), isFalse);
    });

    test('true for payment vocabulary', () {
      expect(CategorizationService.isExpense('Payment successful'), isTrue);
      expect(CategorizationService.isExpense('Paid to Swiggy ₹250'), isTrue);
      expect(
        CategorizationService.isExpense('You received a receipt and invoice'),
        isTrue,
      );
      expect(CategorizationService.isExpense('Rs. 1,299 amount paid'), isTrue);
    });

    test('currency-tagged amounts count as structural cues', () {
      expect(CategorizationService.isExpense('₹500 paid'), isTrue);
      expect(CategorizationService.isExpense('150.00 EUR payment'), isTrue);
    });

    test('false for non-payment text', () {
      expect(
        CategorizationService.isExpense('lorem ipsum dolor sit amet'),
        isFalse,
      );
      expect(CategorizationService.isExpense('my border collie dog'), isFalse);
      // "sent" must not match inside "consent".
      expect(CategorizationService.isExpense('consent form signed'), isFalse);
      expect(CategorizationService.isExpense('a walk in the park'), isFalse);
    });

    test('isolated weak words are not enough', () {
      expect(CategorizationService.isExpense('total'), isFalse);
      expect(CategorizationService.isExpense('paid'), isFalse);
    });
  });
}
