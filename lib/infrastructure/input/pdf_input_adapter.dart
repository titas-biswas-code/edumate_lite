import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/interfaces/input_source.dart';
import '../../core/errors/exceptions.dart';

/// PDF input adapter using Syncfusion PDF
class PdfInputAdapter implements InputSource {
  @override
  String get sourceType => 'pdf';

  @override
  String get displayName => 'PDF Document';

  @override
  List<String> get supportedExtensions => ['.pdf'];

  @override
  bool canHandle(dynamic input) {
    if (input is String) {
      return input.toLowerCase().endsWith('.pdf');
    }
    if (input is File) {
      return input.path.toLowerCase().endsWith('.pdf');
    }
    return false;
  }

  @override
  Stream<ExtractionProgress> extractContent(dynamic input) async* {
    if (!canHandle(input)) {
      yield ExtractionProgress(
        progress: 0,
        error: 'Invalid input type. Expected PDF file path or File object.',
      );
      return;
    }

    try {
      // Get file path
      final String filePath;
      if (input is String) {
        filePath = input;
      } else if (input is File) {
        filePath = input.path;
      } else {
        throw FileException('Invalid input type');
      }

      // Check file exists
      final file = File(filePath);
      if (!await file.exists()) {
        yield ExtractionProgress(
          progress: 0,
          error: 'File not found: $filePath',
        );
        return;
      }

      // Load PDF document
      yield ExtractionProgress(
        progress: 0.1,
        currentPage: 'Loading PDF...',
      );

      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      final pageCount = document.pages.count;
      final extractedPages = <String>[];

      // Extract text from each page
      for (var i = 0; i < pageCount; i++) {
        final text = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);

        if (text.isNotEmpty) {
          extractedPages.add(text);
        }

        // Report progress
        final progress = 0.1 + (0.8 * (i + 1) / pageCount);
        yield ExtractionProgress(
          progress: progress,
          currentPage: 'Page ${i + 1}/$pageCount',
          extractedText: text.isNotEmpty ? text : null,
        );
      }

      // Dispose document
      document.dispose();

      // Final result
      final fullText = extractedPages.join('\n\n');
      
      if (fullText.trim().isEmpty) {
        yield ExtractionProgress(
          progress: 1.0,
          isComplete: true,
          error: 'No text found. PDF may contain only images or scanned content.',
        );
      } else {
        yield ExtractionProgress(
          progress: 1.0,
          extractedText: fullText,
          isComplete: true,
        );
      }
    } catch (e) {
      yield ExtractionProgress(
        progress: 0,
        error: 'Failed to extract PDF content: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getMetadata(dynamic input) async {
    try {
      final String filePath;
      if (input is String) {
        filePath = input;
      } else if (input is File) {
        filePath = input.path;
      } else {
        throw FileException('Invalid input type');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw FileException('File not found');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final metadata = <String, dynamic>{
        'pageCount': document.pages.count,
        'fileSize': bytes.length,
        'fileName': file.path.split('/').last,
        'filePath': filePath,
      };

      // Try to extract document info
      if (document.documentInformation.title.isNotEmpty) {
        metadata['title'] = document.documentInformation.title;
      }
      if (document.documentInformation.author.isNotEmpty) {
        metadata['author'] = document.documentInformation.author;
      }
      if (document.documentInformation.subject.isNotEmpty) {
        metadata['subject'] = document.documentInformation.subject;
      }

      document.dispose();

      return metadata;
    } catch (e) {
      throw FileException('Failed to extract metadata: $e');
    }
  }
}

