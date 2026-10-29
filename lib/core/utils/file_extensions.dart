import 'dart:math';

/// Image extensions the app accepts for screenshot import.
const List<String> kAllowedImageExtensions = [
  'jpg',
  'jpeg',
  'png',
  'heic',
  'heif',
  'webp',
  'gif',
  'bmp',
  'tiff',
  'tif',
];

extension FileSizeExtensions on int {
  /// Converts a file size in bytes to a human-readable string.
  /// Example: 1024 -> "1.0 KB"
  ///
  /// When the rounded display would reach the next unit — `1048575` bytes
  /// is under 1 MB but renders as `1024.0 KB` at one decimal — the value is
  /// promoted, so the string never shows a full 1024 of one suffix.
  String toReadableFileSize({int decimals = 1}) {
    if (this <= 0) return "0 B";

    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(this) / log(1024)).floor();

    // Fallback if i exceeds the suffix array length
    if (i >= suffixes.length) {
      i = suffixes.length - 1;
    }

    var size = this / pow(1024, i);

    // Rounding up to 1024 at the chosen precision means the number belongs
    // in the next unit (`1024.0 KB` -> `1.0 MB`). One promotion is enough:
    // the resized value sits just above 1.0.
    if (i < suffixes.length - 1 &&
        double.parse(size.toStringAsFixed(decimals)) >= 1024) {
      i += 1;
      size = this / pow(1024, i);
    }

    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Compact Indian-app style size: binary thresholds but short suffixes,
  /// e.g. 1536 -> "1.5 K", 5 * 1024 * 1024 -> "5.0 M". Bytes below 1 KB
  /// still render as "N B". Rounded values that would show `1024.0` promote
  /// to the next suffix, same as [toReadableFileSize].
  String toReadableFileSizeCompact() {
    if (this <= 0) return "0 B";

    const suffixes = ["B", "K", "M", "G", "T"];
    var i = (log(this) / log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;

    var size = this / pow(1024, i);
    if (i < suffixes.length - 1 &&
        double.parse(size.toStringAsFixed(1)) >= 1024) {
      i += 1;
      size = this / pow(1024, i);
    }

    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}

extension ScreenshotPathExtensions on String {
  /// Lower-cased file extension without the dot ('' when there is none).
  String get fileExtension {
    final base = split('/').last.split(r'\').last;
    final dot = base.lastIndexOf('.');
    if (dot <= 0 || dot == base.length - 1) return '';
    return base.substring(dot + 1).toLowerCase();
  }

  /// True when this path/filename carries an extension from
  /// [kAllowedImageExtensions] (case-insensitive).
  bool get isAllowedImageExtension =>
      kAllowedImageExtensions.contains(fileExtension);

  /// Makes a path-derived string safe to use as a local file name.
  /// Proven against traversal and separator tricks:
  /// * `../../../etc/passwd` -> `passwd`
  /// * leading `/`, backslashes, drive letters (`C:\tmp\x.png`) -> basename
  /// * null bytes and other control characters are stripped
  /// * reserved characters `:*?"<>|` become `_`; spaces are collapsed
  /// * leading/trailing dots are trimmed (no `..`, no `.hidden` surprises)
  /// * empty results fall back to `file`
  String get sanitizedFileName {
    // Strip null bytes / control chars first (they must not survive).
    var s = replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    // Normalize separators, then drop a Windows drive prefix (only when a
    // real path follows, so names like 'a:b.png' keep their colon).
    s = s.replaceAll(r'\', '/');
    s = s.replaceFirst(RegExp(r'^[A-Za-z]:(?=/)'), '');
    s = s.split('/').last;
    // Replace filesystem-hostile characters.
    s = s.replaceAll(RegExp(r'[:*?"<>|]'), '_');
    // Collapse whitespace runs to a single space.
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Strip leading/trailing dots so `..` and `.foo.` cannot escape or hide.
    s = s.replaceAll(RegExp(r'^\.+'), '').replaceAll(RegExp(r'\.+$'), '');
    if (s.isEmpty) s = 'file';
    return s;
  }

  /// Collision-free naming: inserts/increments a ` (N)` suffix before the
  /// extension. `img.png` -> `img (2).png`; `img (2).png` -> `img (3).png`.
  /// Dotless names and hidden-style names get the suffix appended directly.
  String get nextUniqueName {
    final name = sanitizedFileName;
    final dot = name.lastIndexOf('.');
    final hasExt = dot > 0 && dot != name.length - 1;
    final stem = hasExt ? name.substring(0, dot) : name;
    final ext = hasExt ? name.substring(dot) : '';

    final trailing = RegExp(r'^(.*?) \((\d+)\)$').firstMatch(stem);
    if (trailing != null) {
      // Digit runs past the int range (20+ digits — OCR'd reference numbers
      // do land inside parentheses in file names) make `int.parse` throw
      // FormatException and kill the save flow; an unparseable counter is
      // simply not a counter, so start the sequence at (2).
      final counter = int.tryParse(trailing.group(2)!);
      if (counter != null) {
        return '${trailing.group(1)} (${counter + 1})$ext';
      }
    }
    return '$stem (2)$ext';
  }
}
