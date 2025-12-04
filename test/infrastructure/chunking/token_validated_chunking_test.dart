import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Test chunking strategy with actual Biology PDF
/// Run with: flutter test test/infrastructure/chunking/token_validated_chunking_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Token Validated Chunking Strategy', () {
    // Char limits matching the strategy
    const int targetChars = 4300;
    const int maxChars = 5100;
    const double charsPerToken = 2.68;

    test('Extract and chunk Biology PDF - verify chunk sizes', () async {
      // Load actual PDF
      final file = File('assets/sample_docs/Biology2e-WEB.pdf');
      if (!file.existsSync()) {
        print('⚠️  Test PDF not found, skipping');
        return;
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      print('📄 PDF loaded: ${document.pages.count} pages');

      // Extract first 10 pages
      final buffer = StringBuffer();
      final textExtractor = PdfTextExtractor(document);

      for (var i = 0; i < 10 && i < document.pages.count; i++) {
        final textLines = textExtractor.extractTextLines(
          startPageIndex: i,
          endPageIndex: i,
        );

        double lastY = 0;
        for (final line in textLines) {
          final text = line.text.trim();
          if (text.isEmpty) continue;

          // Paragraph break on vertical gap
          if (lastY > 0 && (line.bounds.top - lastY) > 15) {
            buffer.writeln();
            buffer.writeln();
          }
          buffer.writeln(text);
          lastY = line.bounds.bottom;
        }
        buffer.writeln();
      }

      document.dispose();

      final fullText = buffer.toString();
      print('📝 Extracted ${fullText.length} chars from 10 pages');

      // Split into paragraphs
      final paragraphs = fullText
          .split(RegExp(r'\n\s*\n'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      print('📑 Found ${paragraphs.length} paragraphs');

      // Simulate chunking with char limits
      final chunks = <String>[];
      var currentParagraphs = <String>[];
      var currentChars = 0;

      for (final paragraph in paragraphs) {
        final paragraphChars = paragraph.length;

        // Single paragraph too long?
        if (paragraphChars > maxChars) {
          // Save current
          if (currentParagraphs.isNotEmpty) {
            chunks.add(currentParagraphs.join('\n\n'));
            currentParagraphs = [];
            currentChars = 0;
          }

          // Split long paragraph by sentences
          final sentences = paragraph
              .split(RegExp(r'(?<=[.!?])\s+'))
              .where((s) => s.trim().isNotEmpty)
              .toList();

          var sentenceBuffer = <String>[];
          var sentenceChars = 0;

          for (final sentence in sentences) {
            if (sentenceChars + sentence.length > targetChars &&
                sentenceBuffer.isNotEmpty) {
              chunks.add(sentenceBuffer.join(' '));
              sentenceBuffer = [];
              sentenceChars = 0;
            }
            sentenceBuffer.add(sentence);
            sentenceChars += sentence.length + 1;
          }

          if (sentenceBuffer.isNotEmpty) {
            chunks.add(sentenceBuffer.join(' '));
          }
          continue;
        }

        final newChars = currentChars + paragraphChars + 2;

        if (newChars > targetChars && currentParagraphs.isNotEmpty) {
          chunks.add(currentParagraphs.join('\n\n'));
          currentParagraphs = [paragraph];
          currentChars = paragraphChars;
        } else {
          currentParagraphs.add(paragraph);
          currentChars = newChars;
        }
      }

      // Finalize
      if (currentParagraphs.isNotEmpty) {
        chunks.add(currentParagraphs.join('\n\n'));
      }

      print('\n📊 CHUNKING RESULTS:');
      print('Total chunks: ${chunks.length}');

      var totalChars = 0;
      var maxChunkChars = 0;
      var minChunkChars = double.maxFinite.toInt();
      var overLimitCount = 0;

      for (var i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        final chars = chunk.length;
        final estimatedTokens = (chars / charsPerToken).round();

        totalChars += chars;
        if (chars > maxChunkChars) maxChunkChars = chars;
        if (chars < minChunkChars) minChunkChars = chars;

        if (chars > maxChars) {
          overLimitCount++;
          print('  ❌ Chunk ${i + 1}: $chars chars (~$estimatedTokens tokens) - OVER LIMIT!');
        } else {
          print('  ✅ Chunk ${i + 1}: $chars chars (~$estimatedTokens tokens)');
        }
      }

      print('\n📈 STATISTICS:');
      print('  Total chars processed: $totalChars');
      print('  Average chunk size: ${(totalChars / chunks.length).round()} chars');
      print('  Min chunk: $minChunkChars chars');
      print('  Max chunk: $maxChunkChars chars');
      print('  Target limit: $targetChars chars (~${(targetChars / charsPerToken).round()} tokens)');
      print('  Max limit: $maxChars chars (~${(maxChars / charsPerToken).round()} tokens)');
      print('  Chunks over limit: $overLimitCount');

      // Assertions
      expect(chunks.length, greaterThan(0), reason: 'Should create at least one chunk');
      expect(overLimitCount, equals(0), reason: 'No chunk should exceed max limit');
      expect(maxChunkChars, lessThanOrEqualTo(maxChars), reason: 'Max chunk should be within limit');

      print('\n✅ All ${chunks.length} chunks within limits!');
    });

    test('Verify char-to-token ratio assumptions', () {
      // Test strings of various lengths
      final testStrings = [
        'Hello world', // 11 chars
        'The quick brown fox jumps over the lazy dog.', // 44 chars
        'This is a longer sentence with more words to test the token estimation accuracy.', // 80 chars
        '''Biology is the scientific study of life. It is a natural science with a broad 
scope but has several unifying themes that tie it together as a single, coherent 
field. For instance, all organisms are made up of cells that process hereditary 
information encoded in genes, which can be transmitted to future generations.''', // ~320 chars
      ];

      print('\n📊 CHAR-TO-TOKEN RATIO ANALYSIS:');
      print('Using assumed ratio: $charsPerToken chars/token');

      for (final text in testStrings) {
        final chars = text.length;
        final words = text.split(RegExp(r'\s+')).length;
        final estimatedTokens = (chars / charsPerToken).round();

        print('\n  Text: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
        print('  Chars: $chars, Words: $words, Est. Tokens: $estimatedTokens');
        print('  Words/Token ratio: ${(words / estimatedTokens).toStringAsFixed(2)}');
      }

      // With real tokenizer, we'd compare estimated vs actual
      // For now, just verify the math is consistent
      expect((100 / charsPerToken).round(), equals(37)); // ~37 tokens for 100 chars
      expect((4300 / charsPerToken).round(), equals(1604)); // Target
      expect((5100 / charsPerToken).round(), equals(1903)); // Max
    });

    test('Sentence splitting preserves content', () {
      const longParagraph = '''
Biology is the scientific study of life. It is a natural science with a broad scope. 
All organisms are made up of cells that process hereditary information. 
Genes can be transmitted to future generations through reproduction.
Evolution is a central concept that explains the unity and diversity of life.
Natural selection is the primary mechanism of evolution proposed by Darwin.
''';

      final sentences = longParagraph
          .split(RegExp(r'(?<=[.!?])\s+'))
          .where((s) => s.trim().isNotEmpty)
          .map((s) => s.trim())
          .toList();

      print('\n📝 SENTENCE SPLITTING:');
      print('Original: ${longParagraph.length} chars');
      print('Sentences found: ${sentences.length}');

      var reconstructed = sentences.join(' ');
      print('Reconstructed: ${reconstructed.length} chars');

      for (var i = 0; i < sentences.length; i++) {
        print('  ${i + 1}. ${sentences[i]}');
      }

      // Verify no content lost (allowing for whitespace normalization)
      final originalWords = longParagraph.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final reconstructedWords = reconstructed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

      expect(reconstructedWords, equals(originalWords),
          reason: 'Sentence splitting should preserve all words');
    });

    test('Overlap calculation works correctly', () {
      final paragraphs = [
        'First paragraph with some content.',
        'Second paragraph with more content here.',
        'Third paragraph that is the last one.',
      ];

      const overlapChars = 270;

      String getOverlap(List<String> paras) {
        if (paras.isEmpty) return '';
        final lastPara = paras.last;
        if (lastPara.length <= overlapChars) {
          return lastPara;
        }
        // Get last sentence
        final sentences = lastPara
            .split(RegExp(r'(?<=[.!?])\s+'))
            .where((s) => s.isNotEmpty)
            .toList();
        if (sentences.isNotEmpty && sentences.last.length <= overlapChars) {
          return sentences.last;
        }
        return '';
      }

      final overlap = getOverlap(paragraphs);
      print('\n📝 OVERLAP CALCULATION:');
      print('Last paragraph: "${paragraphs.last}"');
      print('Overlap (${overlap.length} chars): "$overlap"');

      expect(overlap.length, lessThanOrEqualTo(overlapChars));
      expect(overlap, isNotEmpty);
    });
  });
}

