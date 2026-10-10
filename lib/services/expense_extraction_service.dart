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

  /// Extracts the most likely expense amount from [text].
  ///
  /// Candidates are collected from three passes, best bucket wins, and within
  /// a bucket the largest value is preferred:
  /// 1. numbers on lines mentioning total / amount paid / payable,
  /// 2. currency-tagged numbers (₹, $, €, £, Rs., INR, USD, EUR, GBP),
  /// 3. bare numbers as a last resort.
  /// Dates (12/05/2024, 05-Dec-2024), phone numbers and long reference
  /// numbers are rejected.
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
  /// the match) and implausibly long digit strings (reference numbers).
  static double? _validatedNumber(String haystack, int offset, String raw) {
    final end = offset + raw.length;
    final before = offset > 0 ? haystack[offset - 1] : '';
    final after = end < haystack.length ? haystack[end] : '';
    // Glued to a date/phone/range separator or another digit: not an amount.
    if (before == '/' || after == '/' || before == '-' || after == '-') {
      return null;
    }
    if (RegExp(r'\d').hasMatch(before) || RegExp(r'\d').hasMatch(after)) {
      return null;
    }
    return _parseNumber(raw);
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
      final digits = s;
      if (digits.length > 8) return null; // phone / UTR / ref number
      value = double.tryParse(digits);
    } else {
      return null; // malformed grouping like 1,29990
    }

    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 9) return null;
    if (value == null || !value.isFinite || value <= 0) return null;
    return value;
  }

  // -------------------------------------------------------------- merchant

  static final List<RegExp> _merchantPatterns = [
    RegExp(
      r'(?:paid\s+to|sent\s+to|transferred?\s+to|payment\s+to|paid\s+via|debited\s+from|merchant\s+name|merchant|vendor|store|seller)\s*[:\-]?\s*(.+)',
      caseSensitive: false,
    ),
    RegExp(
      r"(?:from|at)\s+([A-Z][A-Za-z&'\.]+(?:\s+[A-Z][A-Za-z&'\.]+){0,3})(?=\s+(?:on|at|for|₹|\$|€|£|Rs|\d|\.|,|;|$))",
    ),
  ];

  static final RegExp _noiseLineRe = RegExp(
    r'^(?:payment|receipt|transaction|thank\s+you|screenshot|order\s+(?:id|number|#)?|txn|upi|invoice|amount|total|date|time|status|success(?:ful)?|completed|debited|credited|balance)\b',
    caseSensitive: false,
  );

  /// Best-effort merchant / payee / store name from [text].
  ///
  /// Tries explicit "paid to / sent to / merchant ..." patterns first, then
  /// falls back to the first line that looks like a proper name (letters
  /// only, title-cased, 1-4 words).
  static String? extractMerchant(String text) {
    for (final pattern in _merchantPatterns) {
      final match = pattern.firstMatch(text);
      final merchant = _cleanMerchant(match?.group(1));
      if (merchant != null) return merchant;
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
    // Keep only the leading run of capitalized words ("Swiggy for lunch" -> "Swiggy").
    final words = merchant.split(RegExp(r'\s+'));
    final kept = <String>[];
    for (final w in words) {
      if (!RegExp(r"^[A-Z][A-Za-z&'\.]*$").hasMatch(w)) break;
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
    final words = s.split(RegExp(r'\s+'));
    if (words.length > 4) return false;
    // Every word must start with a capital letter (or all-caps brand).
    return words.every((w) => RegExp(r"^[A-Z][A-Za-z&'\.]*$").hasMatch(w));
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
    r'(?<!\d)(\d{1,2})[\s.\-/]+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?[\s,\-/]+(\d{2,4})(?!\d)',
    caseSensitive: false,
  );

  static final RegExp _monthDayYearRe = RegExp(
    r'(?<!\d)(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?[\s]+(\d{1,2}),?[\s]+(\d{2,4})(?!\d)',
    caseSensitive: false,
  );

  /// Extracts the transaction date from OCR [text].
  ///
  /// Understands `dd/mm/yyyy` (and `mm/dd` when the day slot can only be a
  /// month), `dd Mon yyyy`, `Mon dd, yyyy`. Two-digit years are expanded
  /// (<30 -> 20xx). Impossible calendar dates (31 Feb, month 13, year outside
  /// 1900..now+5y) are rejected and scanning continues.
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
