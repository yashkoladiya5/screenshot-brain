import '../shared/models/expense_model.dart';
import 'categorization_service.dart';

/// Extracts structured expense data (amount, merchant, date, category) from
/// raw OCR text of payment/receipt screenshots.
///
/// All matching is static and side-effect free; heuristics are intentionally
/// conservative so that dates, phone numbers and reference numbers are not
/// mistaken for amounts.
class ExpenseExtractionService {
  ExpenseExtractionService._();

  // ---------------------------------------------------------------- amount

  static const String _currencyToken =
      r'(?:₹|\$|€|£|\bRs\.?|\bINR|\bUSD|\bEUR|\bGBP)';

  /// A number with optional thousands separators / decimals:
  /// `1,299`, `1.299,90`, `1299,90`, `1299.90`, `50`.
  static final RegExp _numberRe = RegExp(r'\d[\d.,]*\d|\d');

  static final RegExp _currencyAmountRe = RegExp(
    '(?:$_currencyToken)\\s*(\\d[\\d.,]*\\d|\\d)|(\\d[\\d.,]*\\d|\\d)\\s*(?:$_currencyToken)',
    caseSensitive: false,
  );

  static final RegExp _totalLineRe = RegExp(
    r'\b(grand\s+total|total\s+amount|amount\s+paid|net\s+amount|amount\s+due|balance\s+due|total|payable|amount)\b',
    caseSensitive: false,
  );

  static final RegExp _digitRe = RegExp(r'\d');

  /// Longest digit run that can still be money. Kept identical to
  /// `StringValidators._maxAmountDigits` (the form side of the same rule):
  /// longer runs are UTR / reference / card numbers.
  static const int _maxAmountDigits = 9;

  /// Digit totals at or above this are one number split across spaces.
  static const int _maxSpacedClusterDigits = 10;

  /// Extracts the most likely expense amount from [text].
  ///
  /// Candidates are collected from three passes, best bucket wins, and within
  /// a bucket the largest value is preferred:
  /// 1. numbers on lines mentioning total / amount paid / payable,
  /// 2. currency-tagged numbers (₹, $, €, £, Rs., INR, USD, EUR, GBP),
  /// 3. bare numbers as a last resort.
  /// Dates (12/05/2024, 05-Dec-2024), phone numbers (`9876543210` and the
  /// space-grouped `98765 43210`) and long reference numbers are rejected.
  /// The Indian bill notation that closes a price with `/-.` (`Rs. 500/-`) is
  /// accepted as an amount.
  static double? extractAmount(String text) {
    if (text.trim().isEmpty) return null;

    // Bucket 2: currency-tagged matches (validated by adjacency + parsing).
    final tagged = <double>[];
    for (final match in _currencyAmountRe.allMatches(text)) {
      final raw = match[1] ?? match[2]!;
      // Dart Match has no per-group offsets; locate the digits inside the
      // full currency-tagged match instead.
      final offset = match.start + match[0]!.indexOf(raw);
      final value = _validatedNumber(text, offset, raw);
      if (value != null) tagged.add(value);
    }

    // Bucket 1: numbers found on total/amount lines.
    final totals = <double>[];
    for (final line in text.split('\n')) {
      if (!_totalLineRe.hasMatch(line)) continue;
      for (final match in _numberRe.allMatches(line)) {
        final value = _validatedNumber(line, match.start, match[0]!);
        if (value != null) totals.add(value);
      }
    }

    // Bucket 3: any standalone number.
    final bare = <double>[];
    for (final match in _numberRe.allMatches(text)) {
      final value = _validatedNumber(text, match.start, match[0]!);
      if (value != null) bare.add(value);
    }

    for (final bucket in [totals, tagged, bare]) {
      if (bucket.isNotEmpty) {
        return bucket.reduce((a, b) => a >= b ? a : b);
      }
    }
    return null;
  }

  /// Parses [raw] into a positive amount, rejecting fragments of longer digit
  /// runs, dates/phones (digit adjacent to `/`, `-` or another digit outside
  /// the match), whitespace-split phone/card clusters and implausibly long
  /// digit strings (reference numbers).
  static double? _validatedNumber(String haystack, int offset, String raw) {
    final end = offset + raw.length;
    bool digitAt(int i) =>
        i >= 0 && i < haystack.length && _digitRe.hasMatch(haystack[i]);
    final before = offset > 0 ? haystack[offset - 1] : '';
    final after = end < haystack.length ? haystack[end] : '';
    // Glued to a hyphenated date / range or to another digit: not an amount.
    if (before == '-' || after == '-') return null;
    if (digitAt(offset - 1) || digitAt(end)) return null;
    // A slash only disqualifies the number when it joins digits (`12/05`,
    // `3/10`). Bills and invoices close the price with `/-.` — `Rs. 500/-`,
    // `1,200/=` — where nothing numeric follows the slash, and treating that
    // marker as a date separator dropped the total of the whole receipt.
    if (before == '/' && digitAt(offset - 2)) return null;
    if (after == '/' && digitAt(end + 1)) return null;
    // `98765 43210` / `4111 1111 1111 1112`: OCR splits phones, UTRs and card
    // numbers on spaces, which makes every group look like an amount.
    if (_spacedClusterDigits(haystack, offset, end) >=
        _maxSpacedClusterDigits) {
      return null;
    }
    return _parseNumber(raw);
  }

  /// Total digits in the run of number groups that continues [raw] across
  /// inline spaces (line breaks end the run, so a total on the next line is
  /// never folded into the group above it).
  static int _spacedClusterDigits(String haystack, int offset, int end) {
    final leftGroup = RegExp(r'(\d+)[ \t]+$');
    final rightGroup = RegExp(r'^[ \t]+(\d+)');
    var start = offset;
    var stop = end;
    while (start > 0) {
      final match = leftGroup.firstMatch(haystack.substring(0, start));
      if (match == null) break;
      start = match.start;
    }
    while (stop < haystack.length) {
      final match = rightGroup.firstMatch(haystack.substring(stop));
      if (match == null) break;
      stop += match[0]!.length;
    }
    return _digitRe.allMatches(haystack.substring(start, stop)).length;
  }

  static double? _parseNumber(String raw) {
    var s = raw;
    while (s.isNotEmpty && (s.endsWith(',') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }
    if (s.isEmpty) return null;

    double? value;
    if (RegExp(r'^\d{1,3}(,\d{3})+(\.\d{1,2})?$').hasMatch(s)) {
      // 1,299 / 1,299.90
      value = double.tryParse(s.replaceAll(',', ''));
    } else if (RegExp(r'^\d{1,3}(,\d{2,3}){2,}(\.\d{1,2})?$').hasMatch(s)) {
      // Indian grouping: 1,29,900
      value = double.tryParse(s.replaceAll(',', ''));
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+(,\d{1,2})?$').hasMatch(s)) {
      // 1.299 / 1.299,90 (European)
      value = double.tryParse(s.replaceAll('.', '').replaceFirst(',', '.'));
    } else if (RegExp(r'^\d+,\d{1,2}$').hasMatch(s)) {
      // 1299,90 (decimal comma)
      value = double.tryParse(s.replaceFirst(',', '.'));
    } else if (RegExp(r'^\d+\.\d{1,2}$').hasMatch(s)) {
      // 1299.90
      value = double.tryParse(s);
    } else if (RegExp(r'^\d+$').hasMatch(s)) {
      value = double.tryParse(s);
    } else {
      return null; // malformed grouping like 1,29990
    }

    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.length > _maxAmountDigits) return null;
    if (value == null || !value.isFinite || value <= 0) return null;
    return value;
  }

  // -------------------------------------------------------------- merchant

  static final List<RegExp> _merchantPatterns = [
    // `[ \t]` and not `\s`: the label sits at the end of a line on real OCR
    // output ("... Paytm Merchant\nsent to Anil Kitchen"), and a `\s*` between
    // the label and the capture walked over the newline and grabbed the next
    // line instead.
    RegExp(
      r'(?:paid[ \t]+to|sent[ \t]+to|transferred?[ \t]+to|payment[ \t]+to|'
      r'paid[ \t]+via|debited[ \t]+from|merchant[ \t]+name|merchant|vendor|'
      r'store|seller)[ \t]*[:\-]?[ \t]*(.+)',
      caseSensitive: false,
    ),
    // The label is matched letter by letter so the captured name keeps its
    // case-sensitive `[A-Z]` requirement: a single `caseSensitive: false` flag
    // would fold the class too and let "at sent to Anil" win with "sent".
    // OCR capitalises the label whenever it opens a line ("From Big Bazaar on
    // 12/05"), which the previous lower-case-only pattern threw away.
    RegExp(
      r"\b(?:[Ff][Rr][Oo][Mm]|[Aa][Tt])[ \t]+"
      r"([A-Z][A-Za-z&'\.]+(?:[ \t]+[A-Z][A-Za-z&'\.]+){0,3})"
      r'(?=\s+(?:on|at|for|₹|\$|€|£|Rs|\d|\.|,|;|$))',
    ),
  ];

  static final RegExp _noiseLineRe = RegExp(
    r'^(?:payment|receipt|transaction|thank\s+you|screenshot|order\s+(?:id|number|#)?|txn|upi|invoice|amount|total|date|time|status|success(?:ful)?|completed|debited|credited|balance)\b',
    caseSensitive: false,
  );

  /// Words that close a merchant name when OCR glues the next field onto the
  /// payee line (`BigBasket! Total 350`, `sent to kirana store for milk`).
  static final RegExp _merchantStopWordRe = RegExp(
    r'^(?:total|subtotal|amount|paid|pay|date|time|status|txn|transaction|ref|'
    r'reference|balance|item|items|tax|gst|discount|change|tendered|utr|upi|'
    r'cash|card|order|id|for|and|or|the|a|an|to|at|of|in|on|my|me|our|your|'
    r'this|that|from|by|via|is|was|with)\b',
    caseSensitive: false,
  );

  /// Punctuation OCR sticks to the end of a payee word (`BigBasket!`,
  /// `Croma?`, `Bata-`). The final `.` is kept because it also marks the end
  /// of the name.
  static final RegExp _trailingPunctRe = RegExp(r'[!?*:,]+$');

  static final RegExp _titleWordRe = RegExp(r"^[A-Z][A-Za-z&'\.]*$");
  static final RegExp _lowerWordRe = RegExp(r"^[a-z][a-z&'\.]*$");

  /// Marketing prose that reads exactly like a merchant name to the fallback
  /// (every word title-cased, no digits) but never is one.
  static const Set<String> _taglineWords = {
    'best',
    'biggest',
    'largest',
    'trusted',
    'leading',
    'online',
    'marketplace',
    'offers',
    'offer',
    'deals',
    'deal',
    'discount',
    'save',
    'guaranteed',
    'visit',
    'website',
    'download',
    'app',
    'wow',
    'free',
    'promo',
  };

  /// Domain-looking fallback lines (`Www.Bigbasket.Com`) are a URL, not the
  /// store name.
  static final RegExp _domainWordRe = RegExp(
    r'(?:\bwww\b|\.(?:com|net|org|in|co|io|app|dev|info|biz)\b)',
    caseSensitive: false,
  );

  /// Best-effort merchant / payee / store name from [text].
  ///
  /// Tries explicit "paid to / sent to / merchant ..." labels first, then
  /// falls back to the first line that looks like a proper name (letters
  /// only, title-cased, 1-4 words). Every labelled match is examined, not just
  /// the first one, because the label that appears first on a receipt is often
  /// noise ("Paid via UPI" above the real "Paid to BigBasket").
  static String? extractMerchant(String text) {
    for (final pattern in _merchantPatterns) {
      for (final match in pattern.allMatches(text)) {
        final merchant = _cleanMerchant(match.group(1));
        if (merchant != null) return merchant;
      }
    }

    // Fallback: first name-like line, skipping OCR noise.
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (_looksLikeMerchantName(line)) return line;
    }
    return null;
  }

  static String? _cleanMerchant(String? raw) {
    if (raw == null) return null;
    var merchant = raw.trim();
    // Cut at list separators introduced by OCR.
    merchant = merchant.split(RegExp(r'[\n,;]')).first.trim();
    // Drop trailing price/date noise: cut at the first currency token or digit.
    final cut = merchant.indexOf(
      RegExp(r'[₹$€£\d]|\b(?:INR|USD|EUR|GBP|Rs)\b'),
    );
    if (cut >= 0) merchant = merchant.substring(0, cut);
    final words = merchant
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(_trailingPunctRe, ''))
        .where((w) => w.isNotEmpty)
        .toList();
    // Keep the leading run of name words ("Swiggy for lunch" -> "Swiggy").
    // A run that starts lowercase is kept too (OCR spells payees in lower
    // case), but the run must stay in one case so prose after the name still
    // cuts it off.
    final kept = <String>[];
    for (final w in words) {
      if (_merchantStopWordRe.hasMatch(w)) break;
      final title = _titleWordRe.hasMatch(w);
      if (!title && !_lowerWordRe.hasMatch(w)) break;
      if (kept.isNotEmpty && _titleWordRe.hasMatch(kept.first) != title) break;
      kept.add(w);
      // A word ending with "." closes the name (sentence boundary).
      if (w.endsWith('.') || kept.length == 4) break;
    }
    merchant = kept.join(' ').replaceAll(RegExp(r'[\s.\-:/]+$'), '').trim();
    if (merchant.length < 2 || merchant.length > 50) return null;
    if (_noiseLineRe.hasMatch(merchant)) return null;
    return merchant;
  }

  static bool _looksLikeMerchantName(String candidate) {
    final s = candidate.trim();
    if (s.length < 2 || s.length > 50) return false;
    if (_noiseLineRe.hasMatch(s)) return false;
    // No currency/digit noise: real merchant names in receipts are letters.
    if (RegExp(r'(?:₹|\$|€|£|\d|[:/])').hasMatch(s)) return false;
    if (_domainWordRe.hasMatch(s)) return false;
    final words = s.split(RegExp(r'\s+'));
    if (words.length > 4) return false;
    // Taglines ("Best Offers Online") are title-cased marketing prose, not a
    // store name.
    if (words.any((w) => _taglineWords.contains(w.toLowerCase()))) return false;
    // Every word must start with a capital letter (or all-caps brand).
    return words.every((w) => _titleWordRe.hasMatch(w));
  }

  // ------------------------------------------------------------------ date

  static const Map<String, int> _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static final RegExp _numericDateRe = RegExp(
    r'(?<!\d)(\d{1,2})([/\-.])(\d{1,2})\2(\d{2,4})(?!\d)',
  );

  static final RegExp _dayMonthYearRe = RegExp(
    r'(?<!\d)(\d{1,2})(?:st|nd|rd|th)?[\s.\-/]+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?,?[\s,\-/]+(\d{2,4})(?!\d)',
    caseSensitive: false,
  );

  static final RegExp _monthDayYearRe = RegExp(
    r'(?<!\d)(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?,?[\s]+(\d{1,2}),?[\s]+(\d{2,4})(?!\d)',
    caseSensitive: false,
  );

  /// Extracts the transaction date from OCR [text].
  ///
  /// Understands `dd/mm/yyyy` (and `mm/dd` when the day slot can only be a
  /// month), `dd Mon yyyy` (also with an ordinal day: `1st Jan 2024`),
  /// `Mon dd, yyyy` (with or without a comma after the month name). Two-digit
  /// years are expanded (<30 -> 20xx). Impossible calendar dates (31 Feb,
  /// month 13, year outside 1900..now+5y) are rejected and scanning continues.
  static DateTime? extractDate(String text) {
    if (text.trim().isEmpty) return null;

    for (final match in _numericDateRe.allMatches(text)) {
      var a = int.parse(match.group(1)!);
      var b = int.parse(match.group(3)!);
      final year = _normalizeYear(int.parse(match.group(4)!));
      if (year == null) continue;
      // Day-first unless that is impossible (e.g. 05/12 is ambiguous -> dd/mm,
      // 12/25 must be mm/dd).
      var day = a;
      var month = b;
      if (day > 12 && month <= 12) {
        // already dd/mm
      } else if (month > 12 && day <= 12) {
        final t = day;
        day = month;
        month = t;
      }
      final date = _buildDate(year, month, day);
      if (date != null) return date;
    }

    for (final match in _dayMonthYearRe.allMatches(text)) {
      final day = int.parse(match.group(1)!);
      final month = _months[match.group(2)!.toLowerCase()];
      final year = _normalizeYear(int.parse(match.group(3)!));
      if (month == null || year == null) continue;
      final date = _buildDate(year, month, day);
      if (date != null) return date;
    }

    for (final match in _monthDayYearRe.allMatches(text)) {
      final month = _months[match.group(1)!.toLowerCase()];
      final day = int.parse(match.group(2)!);
      final year = _normalizeYear(int.parse(match.group(3)!));
      if (month == null || year == null) continue;
      final date = _buildDate(year, month, day);
      if (date != null) return date;
    }

    // ISO fallback (yyyy-mm-dd) with the same validity checks.
    final iso = RegExp(
      r'(?<!\d)(\d{4})-(\d{2})-(\d{2})(?!\d)',
    ).firstMatch(text);
    if (iso != null) {
      final date = _buildDate(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
      if (date != null) return date;
    }
    return null;
  }

  static int? _normalizeYear(int raw) {
    if (raw < 100) {
      return raw < 30 ? 2000 + raw : 1900 + raw;
    }
    return raw;
  }

  static DateTime? _buildDate(int year, int month, int day) {
    if (year < 1900 || year > DateTime.now().year + 5) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    if (day > daysInMonth) return null;
    return DateTime(year, month, day);
  }

  // --------------------------------------------------------------- expense

  /// Builds an [ExpenseModel] from OCR [text]. Never throws; fields fall back
  /// to null / today / `Other` when they cannot be inferred.
  static ExpenseModel extractExpense(String text, int screenshotId) {
    final expense = ExpenseModel();
    expense.screenshotId = screenshotId;
    expense.amount = extractAmount(text);
    expense.merchant = extractMerchant(text);
    expense.expenseDate = extractDate(text) ?? DateTime.now();
    expense.category = _determineExpenseCategory(text);
    expense.description = text.length > 200
        ? '${text.substring(0, 200)}...'
        : text;
    expense.createdAt = DateTime.now();
    return expense;
  }

  static const Map<String, Map<String, int>> _expenseCategoryKeywords = {
    'Food': {
      'zomato': 6,
      'swiggy': 6,
      'dominos': 5,
      'mcdonalds': 5,
      'restaurant': 4,
      'cafe': 4,
      'coffee': 3,
      'grocery': 5,
      'food': 3,
      'dinner': 2,
      'lunch': 2,
      'breakfast': 2,
      'eatery': 3,
      'dineout': 5,
    },
    'Travel': {
      'uber': 6,
      'ola': 6,
      'flight': 6,
      'irctc': 7,
      'indigo': 5,
      'makemytrip': 6,
      'boarding pass': 7,
      'railway': 6,
      'cab': 5,
      'auto': 2,
      'train': 4,
      'bus': 2,
      'fuel': 5,
      'petrol': 5,
      'diesel': 5,
      'hotel': 5,
      'metro': 4,
    },
    'Shopping': {
      'amazon': 6,
      'flipkart': 6,
      'myntra': 6,
      'ajio': 5,
      'meesho': 5,
      'shopping': 4,
      'clothes': 3,
      'clothing': 3,
      'shoes': 3,
      'electronics': 4,
      'purchase': 2,
      'order': 2,
      'fashion': 3,
    },
    'Bills': {
      'bill': 4,
      'recharge': 5,
      'postpaid': 5,
      'prepaid': 4,
      'broadband': 5,
      'electricity': 5,
      'electricity bill': 6,
      'water bill': 6,
      'gas bill': 6,
      'mobile bill': 6,
      'credit card bill': 6,
      'maintenance': 4,
      'subscription': 4,
    },
    'Healthcare': {
      'pharmacy': 7,
      'medicine': 6,
      'hospital': 6,
      'clinic': 6,
      'doctor': 5,
      'health': 3,
      'medical': 4,
      'apollo pharmacy': 7,
      'pharmaceutical': 5,
    },
    'Entertainment': {
      'netflix': 7,
      'spotify': 7,
      'bookmyshow': 7,
      'cinema': 6,
      'movie': 5,
      'theatre': 4,
      'concert': 6,
      'game': 4,
      'gaming': 4,
      'prime video': 6,
      'hotstar': 6,
    },
  };

  static const List<String> _expenseCategoryPriority = [
    'Healthcare',
    'Food',
    'Travel',
    'Entertainment',
    'Bills',
    'Shopping',
  ];

  static String _determineExpenseCategory(String text) {
    return CategorizationService.scoreCategories(
      text,
      _expenseCategoryKeywords,
      _expenseCategoryPriority,
      threshold: 4,
    );
  }
}
