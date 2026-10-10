/// Categorizes OCR text from screenshots into high-level buckets and decides
/// whether a screenshot looks like an expense/payment receipt.
///
/// Matching is deliberately conservative:
/// * text is tokenized on case-insensitive word boundaries, so `order` never
///   matches inside `border` and `bill` never matches inside `billion`;
/// * every keyword carries a weight (specific brands/phrases score higher
///   than generic words) and multi-word phrases must match as a consecutive
///   token sequence;
/// * a category only wins when its weighted score clears a confidence
///   threshold, otherwise the text falls back to `Other`;
/// * ties between categories are resolved by an explicit priority order.
class CategorizationService {
  /// Per-category weighted keywords. Single words match whole tokens;
  /// phrases (containing a space) match consecutive tokens in order.
  static const Map<String, Map<String, int>> _weightedKeywords = {
    'Payments': {
      'payment': 4,
      'paid': 3,
      'transaction': 3,
      'debit': 3,
      'credit': 3,
      'bank': 3,
      'account': 2,
      'payment successful': 6,
      'amount': 2,
    },
    'UPI Receipts': {
      'upi': 6,
      'gpay': 5,
      'google pay': 5,
      'phonepe': 5,
      'paytm': 5,
      'bhim': 5,
      'upi ref': 8,
      'trxid': 6,
      'transaction id': 4,
      'paid to': 4,
    },
    'Shopping': {
      'amazon': 6,
      'flipkart': 6,
      'myntra': 6,
      'order': 3,
      'order confirmed': 8,
      'shipped': 5,
      'delivered': 4,
      'invoice': 3,
      'purchase': 3,
      'zomato': 5,
      'swiggy': 5,
      'blinkit': 5,
      'zepto': 5,
    },
    'Travel Tickets': {
      'irctc': 8,
      'boarding pass': 8,
      'pnr': 7,
      'railway': 6,
      'flight': 6,
      'train': 4,
      'ticket': 3,
      'bus': 2,
      'cab': 3,
      'uber': 5,
      'ola': 5,
      'booking': 2,
    },
    'Bills': {
      'bill': 3,
      'electricity': 5,
      'electricity bill': 8,
      'water bill': 6,
      'gas bill': 5,
      'mobile bill': 6,
      'recharge': 5,
      'broadband': 5,
      'credit card bill': 8,
      'insurance': 4,
      'postpaid': 5,
    },
    'Documents': {
      'aadhar': 8,
      'aadhaar': 8,
      'pan card': 8,
      'voter': 5,
      'passport': 8,
      'license': 5,
      'certificate': 6,
      'admit card': 6,
      'marksheet': 7,
      'degree': 4,
      'document': 3,
    },
    'OTP Screenshots': {
      'otp': 8,
      'one time password': 8,
      'verification code': 7,
      'login code': 5,
      'do not share': 4,
      'expires': 2,
    },
    'Addresses': {
      'address': 5,
      'delivery address': 7,
      'shipping address': 7,
      'location': 3,
      'map': 2,
      'pin code': 4,
    },
    'Notes': {
      'note': 3,
      'notes': 3,
      'reminder': 4,
      'todo': 5,
      'task': 3,
      'list': 1,
      'idea': 2,
      'important': 1,
    },
    'Social Media': {
      'instagram': 7,
      'facebook': 7,
      'twitter': 6,
      'linkedin': 7,
      'whatsapp': 7,
      'telegram': 6,
      'snapchat': 7,
      'social media': 5,
      'post': 1,
      'profile': 1,
    },
  };

  /// Tie-break order when two categories score the same: earlier wins.
  static const List<String> _categoryPriority = [
    'OTP Screenshots',
    'UPI Receipts',
    'Travel Tickets',
    'Documents',
    'Bills',
    'Shopping',
    'Payments',
    'Social Media',
    'Addresses',
    'Notes',
  ];

  /// Minimum weighted score a category needs to be reported.
  static const int _confidenceThreshold = 4;

  static const Map<String, int> _expenseCues = {
    'payment': 4,
    'paid': 3,
    'receipt': 4,
    'invoice': 4,
    'upi': 3,
    'transaction': 2,
    'debit': 2,
    'credit': 2,
    'purchase': 3,
    'bill': 3,
    'amount': 2,
    'total': 1,
    'transferred': 3,
    'gpay': 3,
    'phonepe': 3,
    'paytm': 3,
    'bhim': 3,
    'balance': 1,
    'paid to': 3,
  };

  /// Currency + digits (either order) is a strong structural expense signal.
  static final RegExp _currencyAmountRe = RegExp(
    r'(?:₹|₨|\$|€|£|\bRs\.?|\bINR|\bUSD|\bEUR|\bGBP)\s*\d|\d[\d.,]*\s*(?:₹|\$|€|£|\bRs\.?|\bINR|\bUSD|\bEUR|\bGBP)',
    caseSensitive: false,
  );

  static const double _expenseThreshold = 4;

  /// Case-insensitive, word-boundary-safe tokenizer.
  /// Tokens keep letters, digits and apostrophes (`don't` -> `don't`).
  static List<String> tokenize(String text) {
    return RegExp(
      r"[\p{L}\p{N}']+",
      unicode: true,
    ).allMatches(text.toLowerCase()).map((m) => m[0]!).toList();
  }

  /// Weighted score of [keywords] against [text].
  ///
  /// Each keyword counts once no matter how many times it appears. Multi-word
  /// phrases must appear as consecutive tokens. Exposed so sibling services
  /// (e.g. expense extraction) can reuse the same matching engine.
  static int weightedScore(String text, Map<String, int> keywords) {
    final tokens = tokenize(text);
    if (tokens.isEmpty) return 0;
    int score = 0;
    for (final entry in keywords.entries) {
      final phrase = entry.key
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      if (phrase.isEmpty) continue;
      if (_containsPhrase(tokens, phrase)) score += entry.value;
    }
    return score;
  }

  static bool _containsPhrase(List<String> tokens, List<String> phrase) {
    if (phrase.length == 1) return tokens.contains(phrase[0]);
    final first = phrase[0];
    for (var i = 0; i <= tokens.length - phrase.length; i++) {
      if (tokens[i] != first) continue;
      var hit = true;
      for (var j = 1; j < phrase.length; j++) {
        if (tokens[i + j] != phrase[j]) {
          hit = false;
          break;
        }
      }
      if (hit) return true;
    }
    return false;
  }

  /// Highest-scoring category among [table], or [fallback] when nothing
  /// clears [threshold]. Ties resolve via [priority] order (earlier wins).
  static String scoreCategories(
    String text,
    Map<String, Map<String, int>> table,
    List<String> priority, {
    int threshold = _confidenceThreshold,
    String fallback = 'Other',
  }) {
    if (text.trim().isEmpty) return fallback;
    String? best;
    var bestScore = 0;
    for (final category in priority) {
      final keywords = table[category];
      if (keywords == null) continue;
      final score = weightedScore(text, keywords);
      if (score > bestScore) {
        bestScore = score;
        best = category;
      }
    }
    if (best == null || bestScore < threshold) return fallback;
    return best;
  }

  /// Categorizes OCR [text] into one of the known categories or `Other`.
  static String categorize(String text) {
    return scoreCategories(
      text,
      _weightedKeywords,
      _categoryPriority,
      threshold: _confidenceThreshold,
    );
  }

  /// True when [text] looks like a payment/expense receipt: a payment-flavoured
  /// vocabulary score (with a bonus for a currency-tagged amount) must clear
  /// the confidence threshold.
  static bool isExpense(String text) {
    if (text.trim().isEmpty) return false;
    var score = weightedScore(text, _expenseCues).toDouble();
    if (_currencyAmountRe.hasMatch(text)) score += 3;
    return score >= _expenseThreshold;
  }
}
