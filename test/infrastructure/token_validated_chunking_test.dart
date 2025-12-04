import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:edumate_lite/infrastructure/chunking/token_validated_chunking_strategy.dart';
import 'package:edumate_lite/core/constants/app_constants.dart';
import 'package:embedding_gemma/embedding_gemma.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TokenValidatedChunkingStrategy - Real PDF Tests', () {
    late EmbeddingGemma embeddingModel;
    late TokenValidatedChunkingStrategy strategy;

    setUpAll(() async {
      // Install embedding model for token counting
      await EmbeddingGemma.installModel()
          .modelFromAsset(
            'assets/models/embeddinggemma-300M_seq2048_mixed-precision.tflite',
          )
          .tokenizerFromAsset('assets/models/sentencepiece.model')
          .install();

      embeddingModel = await EmbeddingGemma.getActiveModel(
        backend: EmbeddingBackend.CPU, // Use CPU for tests
      );

      strategy = TokenValidatedChunkingStrategy(embeddingModel: embeddingModel);
    });

    tearDownAll(() {
      embeddingModel.dispose();
    });

    test('extracts and chunks sample Biology PDF page', () async {
      final pdfFile = File('assets/sample_docs/Biology2e-WEB.pdf');
      expect(await pdfFile.exists(), true, reason: 'Sample PDF should exist');

      // Extract first page
      final bytes = await pdfFile.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      expect(document.pages.count, greaterThan(0));

      final textExtractor = PdfTextExtractor(document);
      final textLines = textExtractor.extractTextLines(
        startPageIndex: 0,
        endPageIndex: 0,
      );

      // Build text with paragraph detection
      final buffer = StringBuffer();
      var lastY = 0.0;

      for (final line in textLines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;

        if (lastY > 0 && (line.bounds.top - lastY) > 15) {
          buffer.writeln(); // Paragraph break
        }

        buffer.writeln(text);
        lastY = line.bounds.bottom;
      }

      final extractedText = buffer.toString();
      document.dispose();

      print('\n=== Biology PDF Page 1 ===');
      print('Extracted ${extractedText.length} characters');
      print(
        'Paragraphs: ${extractedText.split(RegExp(r'\n+')).where((p) => p.trim().isNotEmpty).length}',
      );

      // Chunk the text
      final chunks = await strategy.chunk(extractedText, {'pageNumber': 1});

      print('Generated ${chunks.length} chunks\n');

      // Validate all chunks
      for (var i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        final actualTokens = chunk.metadata['actual_tokens'] as int;
        final words = chunk.metadata['words'] as int;

        print('Chunk $i:');
        print('  Words: $words');
        print('  Actual Tokens: $actualTokens');
        print(
          '  Preview: ${chunk.content.substring(0, chunk.content.length > 80 ? 80 : chunk.content.length)}...',
        );

        // All chunks must be under hard limit
        expect(
          actualTokens,
          lessThanOrEqualTo(AppConstants.maxChunkSizeTokens),
          reason:
              'Chunk $i has $actualTokens tokens, exceeds max ${AppConstants.maxChunkSizeTokens}',
        );
      }
    });

    test('no data loss - all content preserved', () async {
      const testText = '''First paragraph with important data.
      
Second paragraph with more important data.
      
Third paragraph with critical information that must not be lost.''';

      final chunks = await strategy.chunk(testText, {});

      // Reconstruct text from chunks (remove overlap duplicates manually for test)
      final allContent = chunks.map((c) => c.content).join(' ');

      // Check all key phrases are preserved
      expect(allContent, contains('First paragraph'));
      expect(allContent, contains('important data'));
      expect(allContent, contains('Second paragraph'));
      expect(allContent, contains('Third paragraph'));
      expect(allContent, contains('critical information'));
      expect(allContent, contains('must not be lost'));
    });

    test('handles very long sentence by word-splitting', () async {
      // Create a sentence with 1000 words (will exceed 2048 tokens)
      final longSentence = List.generate(1000, (i) => 'word$i').join(' ') + '.';

      final chunks = await strategy.chunk(longSentence, {});

      expect(
        chunks.length,
        greaterThan(1),
        reason: 'Should split long sentence',
      );

      // Verify all chunks are under limit
      for (final chunk in chunks) {
        final tokens = chunk.metadata['actual_tokens'] as int;
        expect(tokens, lessThanOrEqualTo(AppConstants.maxChunkSizeTokens));
      }

      // Verify no data loss (all words present)
      final allWords = chunks.map((c) => c.content).join(' ');
      for (var i = 0; i < 1000; i++) {
        expect(
          allWords,
          contains('word$i'),
          reason: 'Word word$i should be preserved',
        );
      }
    });

    test('maximizes chunk size near 1800 tokens', () async {
      // Create text that should fit in one chunk
      final mediumText = List.generate(
        500,
        (i) =>
            'This is sentence number $i with educational content about biology. ',
      ).join('');

      final chunks = await strategy.chunk(mediumText, {});

      print('\n=== Medium Text Test ===');
      print('Input: ~500 sentences');
      print('Chunks: ${chunks.length}');

      for (var i = 0; i < chunks.length; i++) {
        final tokens = chunks[i].metadata['actual_tokens'] as int;
        final words = chunks[i].metadata['words'] as int;
        print('Chunk $i: $words words, $tokens actual tokens');

        // Should be close to target (1800) not conservative (450)
        if (chunks.length > 1) {
          expect(
            tokens,
            greaterThan(1000),
            reason: 'Should maximize chunk size, not be overly conservative',
          );
        }
      }
    });

    test('extracts multiple PDF pages and validates chunking', () async {
      final pdfFile = File('assets/sample_docs/Biology2e-WEB.pdf');
      if (!await pdfFile.exists()) {
        print('Skipping: Sample PDF not found');
        return;
      }

      final bytes = await pdfFile.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      // Test first 5 pages
      final pagesToTest = document.pages.count > 5 ? 5 : document.pages.count;
      var totalChunks = 0;
      var totalCharsProcessed = 0;

      print('\n=== Biology PDF Multi-Page Test ===');

      for (var pageIdx = 0; pageIdx < pagesToTest; pageIdx++) {
        final textExtractor = PdfTextExtractor(document);
        final textLines = textExtractor.extractTextLines(
          startPageIndex: pageIdx,
          endPageIndex: pageIdx,
        );

        final buffer = StringBuffer();
        var lastY = 0.0;

        for (final line in textLines) {
          final text = line.text.trim();
          if (text.isEmpty) continue;

          if (lastY > 0 && (line.bounds.top - lastY) > 15) {
            buffer.writeln();
          }

          buffer.writeln(text);
          lastY = line.bounds.bottom;
        }

        final pageText = buffer.toString();
        if (pageText.trim().isEmpty) continue;

        totalCharsProcessed += pageText.length;

        final chunks = await strategy.chunk(pageText, {
          'pageNumber': pageIdx + 1,
        });
        totalChunks += chunks.length;

        print(
          'Page ${pageIdx + 1}: ${pageText.length} chars → ${chunks.length} chunks',
        );

        // Validate each chunk
        for (final chunk in chunks) {
          final tokens = chunk.metadata['actual_tokens'] as int;
          expect(
            tokens,
            lessThanOrEqualTo(AppConstants.maxChunkSizeTokens),
            reason: 'Page ${pageIdx + 1} chunk exceeded token limit',
          );
        }
      }

      document.dispose();

      print('Total: $totalCharsProcessed chars → $totalChunks chunks');
      print('Avg chunk size: ${totalCharsProcessed ~/ totalChunks} chars');

      expect(totalChunks, greaterThan(0));
    });
  });
}
