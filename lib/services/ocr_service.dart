import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer;

  OcrService() : _recognizer = TextRecognizer();

  Future<String> extractText(String imagePath) async {
    try {
      return await _processImage(InputImage.fromFilePath(imagePath));
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  Future<String> extractTextFromFile(File imageFile) async {
    try {
      return await _processImage(InputImage.fromFile(imageFile));
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  Future<String> _processImage(InputImage inputImage) async {
    final RecognizedText recognisedText =
        await _recognizer.processImage(inputImage);
    return recognisedText.text;
  }

  void dispose() {
    _recognizer.close();
  }
}
