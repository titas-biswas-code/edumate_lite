import '../../domain/interfaces/input_source.dart';

/// Simple text input adapter for direct text input
class TextInputAdapter implements InputSource {
  @override
  String get sourceType => 'text';

  @override
  String get displayName => 'Text';

  @override
  List<String> get supportedExtensions => ['.txt'];

  @override
  bool canHandle(dynamic input) {
    return input is String;
  }

  @override
  Stream<ExtractionProgress> extractContent(dynamic input) async* {
    if (!canHandle(input)) {
      yield ExtractionProgress(
        progress: 0,
        error: 'Invalid input type. Expected String.',
      );
      return;
    }

    try {
      final text = input as String;

      yield ExtractionProgress(
        progress: 0.5,
        currentPage: 'Processing text...',
      );

      yield ExtractionProgress(
        progress: 1.0,
        extractedText: text,
        isComplete: true,
      );
    } catch (e) {
      yield ExtractionProgress(
        progress: 0,
        error: 'Failed to process text: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getMetadata(dynamic input) async {
    final text = input as String;
    return {
      'length': text.length,
      'wordCount': text.split(RegExp(r'\s+')).length,
    };
  }
}

