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

    test('possessive and quote-marked keywords still match', () {
      // OCR routinely attaches straight apostrophes to words (possessives,
      // quote residue); they must not break whole-token keyword matching.
      expect(
        CategorizationService.categorize("Instagram's new post"),
        'Social Media',
      );
      expect(CategorizationService.categorize("Flipkart's sale"), 'Shopping');
      expect(
        CategorizationService.categorize("Enter the 'OTP' shared with you"),
        'OTP Screenshots',
      );
    });
  });

  group('tokenize', () {
    test('strips leading/trailing apostrophes and possessive endings', () {
      expect(CategorizationService.tokenize("'paid to' users' amazon's"), [
        'paid',
        'to',
        'users',
        'amazon',
      ]);
      // A lone quoted token must not survive as a bare apostrophe remnant.
      expect(CategorizationService.tokenize("' ' ''"), isEmpty);
    });

    test('keeps interior apostrophes in contractions', () {
      expect(CategorizationService.tokenize("don't"), ["don't"]);
    });
  });

  group('scoreCategories', () {
    test('scores table categories missing from the priority list', () {
      // The documented contract is "highest-scoring category among [table]":
      // a category absent from [priority] must still be considered, not
      // silently dropped to the fallback bucket.
      const table = {
        'Alpha': {'waldo': 9},
        'Beta': {'zorp': 9},
      };
      expect(
        CategorizationService.scoreCategories('waldo', table, const ['Beta']),
        'Alpha',
      );
      // A priority category still wins an exact tie over an unranked one.
      expect(
        CategorizationService.scoreCategories('waldo zorp', table, const [
          'Beta',
        ]),
        'Beta',
      );
    });

    test('unranked categories tie-break deterministically (alphabetical)', () {
      const table = {
        'Zulu': {'alpha': 5},
        'Alpha': {'alpha': 5},
      };
      expect(
        CategorizationService.scoreCategories('alpha', table, const []),
        'Alpha',
      );
    });

    test('priority entries not present in the table are ignored safely', () {
      const table = {
        'Alpha': {'waldo': 9},
      };
      expect(
        CategorizationService.scoreCategories('waldo', table, const ['Nope']),
        'Alpha',
      );
      expect(
        CategorizationService.scoreCategories('nothing', table, const ['Nope']),
        'Other',
      );
    });
  });

  group('inflected bank-alert word forms', () {
    // Debit/credit alerts are the archetypal Payments screenshot, but the
    // keywords only matched the base forms "debit"/"credit": "debited" and
    // "credited" fell through to Other, and a bare debit alert was not
    // flagged as an expense at all.
    test('categorizes SMS-style debit and credit alerts as Payments', () {
      expect(
        CategorizationService.categorize(
          'INR 1,200.00 has been debited from your account XX3456 on '
          '12-01-2026. Available balance: Rs 4,500.00',
        ),
        'Payments',
      );
      expect(
        CategorizationService.categorize(
          'Rs 25,000.00 credited to your account XX9876 on 01-02-2026',
        ),
        'Payments',
      );
    });

    test('a bare debit alert is detected as an expense', () {
      expect(
        CategorizationService.isExpense(
          'Rs.1200 debited from your a/c XX3456 on 12/01/2026',
        ),
        isTrue,
      );
    });

    test('inflected forms do not resurrect substring false positives', () {
      // "debited" is accepted as a whole token, but "debitcard" or "credit"
      // glued inside other words must still not match.
      expect(CategorizationService.categorize('my debitcard wallet'), 'Other');
      expect(
        CategorizationService.isExpense('incredit loan marketing'),
        isFalse,
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
      // The symbol must work on both sides of the amount for every currency;
      // "500 ₨" (trailing Nepali rupee) was silently unrecognized.
      expect(CategorizationService.isExpense('paid 500 ₨ to Sita'), isTrue);
      expect(CategorizationService.isExpense('₨500 paid to Sita'), isTrue);
      expect(CategorizationService.isExpense('paid 250 € to Sita'), isTrue);
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
