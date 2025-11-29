import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../domain/interfaces/input_source.dart';
import '../../core/errors/exceptions.dart';
import 'image_input_adapter.dart';

/// Camera input adapter
/// Extends image adapter with camera-specific preprocessing
class CameraInputAdapter implements InputSource {
  final ImageInputAdapter _imageAdapter = ImageInputAdapter();

  @override
  String get sourceType => 'camera';

  @override
  String get displayName => 'Camera Capture';

  @override
  List<String> get supportedExtensions => []; // Not file-based

  @override
  bool canHandle(dynamic input) {
    // Camera adapter handles Uint8List (captured image bytes)
    return input is Uint8List;
  }

  @override
  Stream<ExtractionProgress> extractContent(dynamic input) async* {
    if (!canHandle(input)) {
      yield ExtractionProgress(
        progress: 0,
        error: 'Invalid input type. Expected image bytes from camera.',
      );
      return;
    }

    try {
      final imageBytes = input as Uint8List;

      // Apply camera-specific preprocessing
      yield ExtractionProgress(
        progress: 0.1,
        currentPage: 'Enhancing image...',
      );

      final enhancedBytes = await _enhanceForOCR(imageBytes);

      yield ExtractionProgress(
        progress: 0.3,
        currentPage: 'Processing...',
      );

      // Delegate to image adapter for actual extraction
      await for (final progress in _imageAdapter.extractContent(enhancedBytes)) {
        // Adjust progress to account for preprocessing
        final adjustedProgress = 0.3 + (progress.progress * 0.7);
        yield ExtractionProgress(
          progress: adjustedProgress,
          currentPage: progress.currentPage,
          extractedText: progress.extractedText,
          isComplete: progress.isComplete,
          error: progress.error,
        );
      }
    } catch (e) {
      yield ExtractionProgress(
        progress: 0,
        error: 'Failed to process camera image: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getMetadata(dynamic input) async {
    if (!canHandle(input)) {
      throw FileException('Invalid input type');
    }

    final metadata = await _imageAdapter.getMetadata(input);
    metadata['source'] = 'camera';
    return metadata;
  }

  /// Enhance image for better OCR results
  Future<Uint8List> _enhanceForOCR(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        return bytes;
      }

      // Apply enhancements
      var enhanced = image;

      // Increase contrast for better text visibility
      enhanced = img.adjustColor(
        enhanced,
        contrast: 1.2,
        brightness: 1.05,
      );

      // Sharpen slightly
      enhanced = img.adjustColor(
        enhanced,
        saturation: 0.8, // Reduce saturation (move toward grayscale)
      );

      // Re-encode
      return Uint8List.fromList(img.encodeJpg(enhanced, quality: 90));
    } catch (e) {
      // If enhancement fails, return original
      return bytes;
    }
  }
}

