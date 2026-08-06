import 'dart:math';

extension FileSizeExtensions on int {
  /// Converts a file size in bytes to a human-readable string.
  /// Example: 1024 -> "1.0 KB"
  String toReadableFileSize({int decimals = 1}) {
    if (this <= 0) return "0 B";
    
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(this) / log(1024)).floor();
    
    // Fallback if i exceeds the suffix array length
    if (i >= suffixes.length) {
      i = suffixes.length - 1;
    }
    
    final size = this / pow(1024, i);
    
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
