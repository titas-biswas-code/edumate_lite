// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Extract PDF paragraphs to file', () async {
    final pdfPath = 'assets/sample_docs/Biology2e-preface-cleaned.pdf';
    final outputPath = 'test/extracted_paragraphs.txt';

    print('Reading PDF: $pdfPath');

    final file = File(pdfPath);
    expect(file.existsSync(), true, reason: 'PDF not found');

    final bytes = file.readAsBytesSync();
    final document = PdfDocument(inputBytes: bytes);

    print('PDF pages: ${document.pages.count}');

    final output = StringBuffer();
    output.writeln('=' * 80);
    output.writeln('PDF EXTRACTION DEBUG');
    output.writeln('File: $pdfPath');
    output.writeln('Pages: ${document.pages.count}');
    output.writeln('=' * 80);
    output.writeln();

    // Extract first 10 pages
    final pagesToExtract = 10.clamp(1, document.pages.count);

    for (var i = 0; i < pagesToExtract; i++) {
      final extractor = PdfTextExtractor(document);

      output.writeln('-' * 80);
      output.writeln('PAGE ${i + 1}');
      output.writeln('-' * 80);

      // Extract text lines
      final textLines = extractor.extractTextLines(startPageIndex: i, endPageIndex: i);

      output.writeln('Text lines found: ${textLines.length}');
      output.writeln();

      // Group lines into paragraphs
      final paragraphs = <String>[];
      var currentParagraph = StringBuffer();
      double? lastY;

      for (final line in textLines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;

        final y = line.bounds.top;

        // New paragraph if gap > 15 points
        if (lastY != null && (y - lastY).abs() > 15) {
          if (currentParagraph.isNotEmpty) {
            paragraphs.add(currentParagraph.toString().trim());
            currentParagraph = StringBuffer();
          }
        }

        if (currentParagraph.isNotEmpty) {
          currentParagraph.write(' ');
        }
        currentParagraph.write(text);
        lastY = line.bounds.bottom;
      }

      if (currentParagraph.isNotEmpty) {
        paragraphs.add(currentParagraph.toString().trim());
      }

      output.writeln('Paragraphs found: ${paragraphs.length}');
      output.writeln();

      for (var j = 0; j < paragraphs.length; j++) {
        final para = paragraphs[j];
        final words = para.split(RegExp(r'\s+')).length;
        final chars = para.length;

        output.writeln('>>> PARA ${j + 1} [${chars} chars, ${words} words]:');
        output.writeln(para);
        output.writeln('<<< END PARA ${j + 1}');
        output.writeln();
      }
    }

    document.dispose();

    // Write to file
    final outputFile = File(outputPath);
    outputFile.writeAsStringSync(output.toString());

    print('Done! Output: $outputPath');
    print('Total output chars: ${output.length}');
  });
}

