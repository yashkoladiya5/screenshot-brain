import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/shared/models/screenshot_item.dart';
import 'package:screenshot_brain/shared/models/screenshot_model.dart';

ScreenshotModel model({
  int id = 1,
  String filePath = '/sdcard/Pictures/Screenshots/Screenshot_2025-06-18.png',
  String? thumbnailPath,
  String? extractedText,
  String? category,
  DateTime? createdAt,
  int? fileSize,
  int? width,
  int? height,
  bool isProcessed = false,
  bool isExpense = false,
}) {
  return ScreenshotModel()
    ..id = id
    ..filePath = filePath
    ..thumbnailPath = thumbnailPath
    ..extractedText = extractedText
    ..category = category
    ..createdAt = createdAt ?? DateTime.utc(2025, 6, 18, 16, 30)
    ..fileSize = fileSize
    ..width = width
    ..height = height
    ..isProcessed = isProcessed
    ..isExpense = isExpense;
}

void main() {
  group('ScreenshotItem.fromModel', () {
    test('mirrors every persisted field', () {
      final created = DateTime.utc(2025, 3, 2, 9, 15);
      final item = ScreenshotItem.fromModel(
        model(
          id: 42,
          filePath: '/a/b/c.png',
          thumbnailPath: '/thumbs/c.jpg',
          extractedText: 'Uber 143.00',
          category: 'Travel',
          createdAt: created,
          fileSize: 2048,
          width: 1080,
          height: 2400,
          isProcessed: true,
        ),
      );

      expect(item.id, 42);
      expect(item.filePath, '/a/b/c.png');
      expect(item.thumbnailPath, '/thumbs/c.jpg');
      expect(item.extractedText, 'Uber 143.00');
      expect(item.category, 'Travel');
      expect(item.createdAt, created);
      expect(item.fileSize, 2048);
      expect(item.width, 1080);
      expect(item.height, 2400);
      expect(item.isProcessed, isTrue);
      expect(item.isExpense, isFalse);
      expect(item.status, ScreenshotStatus.processed);
    });

    test('defaults are applied for a bare model', () {
      final item = ScreenshotItem.fromModel(
        ScreenshotModel()
          ..filePath = '/x.png'
          ..createdAt = DateTime.utc(2024),
      );
      expect(item.id, isA<int>());
      expect(item.isProcessed, isFalse);
      expect(item.isExpense, isFalse);
      expect(item.status, ScreenshotStatus.pending);
      expect(item.statusLabel, 'Pending');
      expect(item.categoryDisplay, 'Uncategorized');
      expect(item.fileSize, isNull);
      expect(item.width, isNull);
    });

    test('an unset late filePath/createdAt does not throw', () {
      final item = ScreenshotItem.fromModel(ScreenshotModel());
      expect(item.filePath, '');
      expect(item.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(item.status, ScreenshotStatus.pending);
    });
  });

  group('ScreenshotItem.status mapping', () {
    test('isProcessed/isExpense collapse to one enum', () {
      expect(
        ScreenshotItem.fromModel(model()).status,
        ScreenshotStatus.pending,
      );
      expect(
        ScreenshotItem.fromModel(model(isProcessed: true)).status,
        ScreenshotStatus.processed,
      );
      // isExpense wins over isProcessed==false: the classifier set the flag,
      // the row is by definition not awaiting OCR.
      expect(
        ScreenshotItem.fromModel(model(isExpense: true)).status,
        ScreenshotStatus.expense,
      );
      expect(
        ScreenshotItem.fromModel(
          model(isProcessed: true, isExpense: true),
        ).status,
        ScreenshotStatus.expense,
      );
    });

    test('labels and convenience flags read naturally', () {
      final pending = ScreenshotItem.fromModel(model());
      expect(pending.statusLabel, 'Pending');
      expect(pending.status.isPending, isTrue);
      expect(pending.status.needsProcessing, isTrue);
      expect(pending.status.isExpense, isFalse);
      expect(
        ScreenshotItem.fromModel(model(isProcessed: true)).statusLabel,
        'Processed',
      );
      expect(
        ScreenshotItem.fromModel(model(isExpense: true)).status.isExpense,
        isTrue,
      );
    });
  });

  group('ScreenshotItem display formatting', () {
    test('size uses the shared readable file-size formatter', () {
      expect(
        ScreenshotItem.fromModel(model(fileSize: 1024)).fileSizeDisplay,
        '1.0 KB',
      );
      expect(
        ScreenshotItem.fromModel(
          model(fileSize: 5 * 1024 * 1024),
        ).fileSizeDisplay,
        '5.0 MB',
      );
      expect(
        ScreenshotItem.fromModel(model(fileSize: 512)).fileSizeDisplay,
        '512.0 B',
      );
    });

    test('null / zero / negative sizes degrade instead of crashing', () {
      expect(ScreenshotItem.fromModel(model()).fileSizeDisplay, 'Unknown size');
      expect(
        ScreenshotItem.fromModel(model(fileSize: 0)).fileSizeDisplay,
        '0 B',
      );
      expect(
        ScreenshotItem.fromModel(model(fileSize: -7)).fileSizeDisplay,
        '0 B',
      );
    });

    test('dimensions guard against missing and nonsensical values', () {
      expect(
        ScreenshotItem.fromModel(
          model(width: 1080, height: 2400),
        ).dimensionsDisplay,
        '1080×2400',
      );
      expect(
        ScreenshotItem.fromModel(model(width: 0, height: 0)).dimensionsDisplay,
        '—',
      );
      expect(
        ScreenshotItem.fromModel(model(width: 1080)).dimensionsDisplay,
        '—',
      );
    });

    test('file name, extension and supportability come from the path', () {
      final png = ScreenshotItem.fromModel(
        model(filePath: '/sdcard/Pictures/Screenshots/S宝_1.PNG'),
      );
      expect(png.fileName, 'S宝_1.PNG');
      expect(png.fileExtension, 'png');
      expect(png.isSupportedImage, isTrue);

      final windows = ScreenshotItem.fromModel(
        model(filePath: r'C:\Users\Yash\Pictures\shot.jpg'),
      );
      expect(windows.fileName, 'shot.jpg');

      final none = ScreenshotItem.fromModel(
        model(filePath: '/tmp/noextension'),
      );
      expect(none.fileExtension, '');
      expect(none.isSupportedImage, isFalse);
      expect(ScreenshotItem.fromModel(model(filePath: '')).fileName, '');
    });

    test('category placeholder distinguishes null from empty', () {
      expect(
        ScreenshotItem.fromModel(model()).categoryDisplay,
        'Uncategorized',
      );
      expect(
        ScreenshotItem.fromModel(model(category: '')).categoryDisplay,
        'Uncategorized',
      );
      expect(
        ScreenshotItem.fromModel(model(category: 'Bills')).categoryDisplay,
        'Bills',
      );
    });

    test(
      'text preview collapses whitespace, truncates, and stays null-safe',
      () {
        final multiline = ScreenshotItem.fromModel(
          model(extractedText: '  Flipkart   Order\n   placed  \n\n '),
        );
        expect(multiline.textPreview, 'Flipkart Order placed');
        expect(multiline.hasExtractedText, isTrue);

        expect(ScreenshotItem.fromModel(model()).textPreview, isNull);
        expect(
          ScreenshotItem.fromModel(model(extractedText: '')).textPreview,
          isNull,
        );
        expect(
          ScreenshotItem.fromModel(model(extractedText: '   \n')).textPreview,
          isNull,
        );
        expect(
          ScreenshotItem.fromModel(
            model(extractedText: '   '),
          ).hasExtractedText,
          isFalse,
        );

        final long = ScreenshotItem.fromModel(model(extractedText: 'a' * 200));
        expect(long.textPreview!.length, 81); // 80 chars + ellipsis
        expect(long.textPreview!.endsWith('…'), isTrue);
      },
    );

    test('dates render through the canonical DateTime extension', () {
      final item = ScreenshotItem.fromModel(
        model(createdAt: DateTime.utc(2023, 10, 24, 16, 30)),
      );
      expect(item.standardDateDisplay, 'Oct 24, 2023');
      expect(
        item.dateDisplayAgainst(DateTime.utc(2023, 10, 24, 8)),
        'Today at 4:30 PM',
      );
      expect(
        item.dateDisplayAgainst(DateTime.utc(2023, 10, 25, 8)),
        'Yesterday at 4:30 PM',
      );
      expect(item.dateDisplayAgainst(DateTime.utc(2024, 1, 1)), 'Oct 24, 2023');
    });
  });

  group('ScreenshotItem copyWith / equality', () {
    final base = ScreenshotItem.fromModel(
      model(id: 7, filePath: '/a.png', category: 'Travel', fileSize: 2048),
    );

    test('copyWith changes only the supplied fields', () {
      final copy = base.copyWith(category: 'Bills', isProcessed: true);
      expect(copy.category, 'Bills');
      expect(copy.isProcessed, isTrue);
      expect(copy.id, base.id);
      expect(copy.filePath, base.filePath);
      expect(copy.createdAt, base.createdAt);
      expect(copy.fileSize, base.fileSize);
      expect(copy.width, base.width);
      expect(copy.thumbnailPath, base.thumbnailPath);
      expect(base.copyWith(), base);
    });

    test('value equality and hash consistency', () {
      expect(
        base,
        ScreenshotItem.fromModel(
          model(id: 7, filePath: '/a.png', category: 'Travel', fileSize: 2048),
        ),
      );
      expect(
        base.hashCode,
        ScreenshotItem.fromModel(
          model(id: 7, filePath: '/a.png', category: 'Travel', fileSize: 2048),
        ).hashCode,
      );
      expect(base.copyWith(id: 8) == base, isFalse);
      expect(base.copyWith(category: null).category, 'Travel');
      expect({base, base.copyWith(id: 8)}.length, 2);
    });

    test('toString carries the derived status', () {
      expect(base.toString(), contains('status: pending'));
      expect(
        base.copyWith(isProcessed: true).toString(),
        contains('status: processed'),
      );
      expect(base.toString(), contains('id: 7'));
    });
  });
}
