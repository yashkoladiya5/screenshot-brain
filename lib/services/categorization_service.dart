class CategorizationService {
  static const Map<String, List<String>> _categoryKeywords = {
    'Payments': ['payment', 'paid', 'payment successful', 'transaction', 'debit', 'credit', 'bank', 'account'],
    'UPI Receipts': ['upi', 'gpay', 'google pay', 'phonepe', 'paytm', 'bhim', 'upi ref', 'trxid', 'transaction id'],
    'Shopping': ['amazon', 'flipkart', 'myntra', 'order', 'order confirmed', 'shipped', 'delivered', 'invoice', 'purchase', 'zomato', 'swiggy', 'blinkit', 'zepto'],
    'Travel Tickets': ['train', 'railway', 'irctc', 'flight', 'boarding pass', 'ticket', 'pnr', 'bus', 'cab', 'uber', 'ola', 'booking'],
    'Bills': ['bill', 'electricity', 'water bill', 'gas', 'mobile bill', 'recharge', 'broadband', 'credit card bill', 'insurance'],
    'Documents': ['aadhar', 'pan card', 'voter', 'passport', 'license', 'certificate', 'admit card', 'marksheet', 'degree', 'document'],
    'OTP Screenshots': ['otp', 'one time password', 'verification code', 'login code', 'otp for'],
    'Addresses': ['address', 'location', 'map', 'delivery address', 'shipping address', 'home', 'office'],
    'Notes': ['note', 'notes', 'reminder', 'todo', 'task', 'list', 'idea', 'important'],
    'Social Media': ['instagram', 'facebook', 'twitter', 'linkedin', 'whatsapp', 'telegram', 'snapchat', 'social', 'post', 'profile'],
  };

  static String categorize(String text) {
    if (text.isEmpty) return 'Other';
    final lowerText = text.toLowerCase();
    final scores = <String, int>{};

    for (final entry in _categoryKeywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          score += keyword.length;
        }
      }
      if (score > 0) scores[entry.key] = score;
    }

    if (scores.isEmpty) return 'Other';
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static bool isExpense(String text) {
    if (text.isEmpty) return false;
    final lowerText = text.toLowerCase();
    final expenseKeywords = [
      'paid', 'payment', 'debit', 'credit', 'amount', 'rs', '₹', '\$', 'total',
      'invoice', 'bill', 'receipt', 'transaction', 'purchase', 'order',
      'paid to', 'sent', 'transferred', 'upi', 'gpay', 'phonepe', 'paytm',
    ];
    return expenseKeywords.any((k) => lowerText.contains(k));
  }
}
