class DateUtils {
  /// Returns a friendly time ago string, e.g., "5 mins ago", "Just now"
  static String timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} years ago';
    }
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} months ago';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} mins ago';
    }
    return 'Just now';
  }

  /// Checks if two dates fall on the same calendar day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
