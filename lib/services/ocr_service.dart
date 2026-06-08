import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer;

  OcrService() : _recognizer = TextRecognizer();

  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognisedText = await _recognizer.processImage(inputImage);
      return recognisedText.text;
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  Future<String> extractTextFromFile(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognisedText = await _recognizer.processImage(inputImage);
      return recognisedText.text;
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  void dispose() {
    _recognizer.close();
  }
}
