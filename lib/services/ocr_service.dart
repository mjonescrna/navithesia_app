import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Service class for handling OCR functionality
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  /// Picks an image from the camera or gallery and performs OCR
  Future<String?> scanText({required bool useCamera}) async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: useCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1800,
      );

      if (pickedImage == null) {
        // User canceled selection
        return null;
      }

      final File imageFile = File(pickedImage.path);
      return await recognizeText(imageFile);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Recognizes text from an image file
  Future<String?> recognizeText(File imageFile) async {
    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      String fullText = recognizedText.text;
      return fullText;
    } catch (e) {
      debugPrint('Error recognizing text: $e');
      return null;
    }
  }

  /// Process OCR text to extract procedure-related information
  List<String> extractPotentialProcedures(String ocrText) {
    // Simple extraction heuristic - can be refined later
    List<String> lines = ocrText.split('\n');
    List<String> potentialProcedures = [];

    // Look for potential procedure names (longer phrases that could be procedures)
    for (String line in lines) {
      String trimmed = line.trim();
      if (trimmed.length > 10 &&
          !trimmed.contains('@') && // Filter out emails
          !trimmed.contains('http') && // Filter out URLs
          !trimmed.startsWith('id:') && // Filter out IDs
          !trimmed.startsWith('date:') && // Filter out dates
          !RegExp(r'^\d+$').hasMatch(trimmed)) {
        // Filter out pure numbers
        potentialProcedures.add(trimmed);
      }
    }

    return potentialProcedures;
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}
