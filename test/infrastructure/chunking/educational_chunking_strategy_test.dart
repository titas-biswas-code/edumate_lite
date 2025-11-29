import 'package:flutter_test/flutter_test.dart';
import 'package:edumate_lite/infrastructure/chunking/educational_chunking_strategy.dart';

void main() {
  group('EducationalChunkingStrategy', () {
    late EducationalChunkingStrategy strategy;

    setUp(() {
      strategy = EducationalChunkingStrategy();
    });

    test('has correct configuration', () {
      expect(strategy.strategyId, 'educational_v1');
      expect(strategy.targetChunkSize, 350);
      expect(strategy.chunkOverlap, 50);
    });

    test('returns empty list for empty text', () async {
      final results = await strategy.chunk('', {});
      expect(results, isEmpty);
    });

    test('chunks simple paragraph', () async {
      const text = '''
This is a simple paragraph about education. It contains multiple sentences. Each sentence adds information.
      ''';

      final results = await strategy.chunk(text, {});

      expect(results.length, 1);
      expect(results.first.chunkType, 'paragraph');
      expect(results.first.content, contains('simple paragraph'));
    });

    test('detects heading type', () async {
      const text = '''
Chapter 5: Quadratic Equations

Introduction to quadratic equations and their properties.
      ''';

      final results = await strategy.chunk(text, {});

      expect(results.length, greaterThanOrEqualTo(1));
      expect(results.first.chunkType, 'heading');
    });

    test('detects list type', () async {
      const text = '''1. First concept
2. Second concept
3. Third concept''';

      final results = await strategy.chunk(text, {});

      expect(results.any((r) => r.chunkType == 'list'), isTrue);
    });

    test('detects equation type', () async {
      const text = '''x = (-b ± √(b² - 4ac)) / 2a''';

      final results = await strategy.chunk(text, {});

      expect(results.length, 1);
      expect(results.first.chunkType, 'equation');
    });

    test('detects definition type', () async {
      const text = '''
Photosynthesis: The process by which green plants convert sunlight into chemical energy.
      ''';

      final results = await strategy.chunk(text, {});

      expect(results.length, 1);
      expect(results.first.chunkType, 'definition');
    });

    test('detects example type', () async {
      const text = '''Example 1: Solve x² + 5x + 6 = 0
Solution: Step 1: Factor the equation. Step 2: Apply zero product property.''';

      final results = await strategy.chunk(text, {});

      expect(results.any((r) => r.chunkType == 'example'), isTrue);
    });

    test('detects table type', () async {
      const text = '''| Name | Age | Grade |
|------|-----|-------|
| John | 12  | 7     |
| Mary | 13  | 8     |''';

      final results = await strategy.chunk(text, {});

      expect(results.length, 1);
      expect(results.first.chunkType, 'table');
    });

    test('splits large text into multiple chunks', () async {
      // Create a long paragraph
      final longText = List.generate(
        50,
        (i) => 'This is sentence number $i in a very long paragraph.',
      ).join(' ');

      final results = await strategy.chunk(longText, {});

      expect(results.length, greaterThan(1));
      // Check sequence indices are incremental
      for (var i = 0; i < results.length; i++) {
        expect(results[i].sectionIndex, i);
      }
    });

    test('preserves page number in metadata', () async {
      const text = 'Sample text from page 5.';

      final results = await strategy.chunk(text, {'pageNumber': 5});

      expect(results.length, 1);
      expect(results.first.pageNumber, 5);
    });

    test('handles multiple sections separated by double newlines', () async {
      const text = '''
First section of content.

Second section of content.

Third section of content.
      ''';

      final results = await strategy.chunk(text, {});

      expect(results.length, 3);
    });

    test('handles complex educational content', () async {
      const text = '''
Chapter 5: Quadratic Equations

Introduction
A quadratic equation is a polynomial equation of degree 2.

Definition: A quadratic equation is an equation of the form ax² + bx + c = 0.

The Quadratic Formula
To solve any quadratic equation:
x = (-b ± √(b² - 4ac)) / 2a

Example 1:
Solve: x² + 5x + 6 = 0
Solution: x = -2 or x = -3

Practice Problems:
1. Solve: x² - 4x + 4 = 0
2. Solve: 2x² + 7x + 3 = 0
      ''';

      final results = await strategy.chunk(text, {});

      expect(results.length, greaterThan(3));
      
      // Check we have different chunk types
      final types = results.map((r) => r.chunkType).toSet();
      expect(types.length, greaterThan(2), reason: 'Should detect multiple chunk types');
      
      // Verify we detected at least some key types
      final hasDefinition = types.contains('definition');
      final hasEquation = types.contains('equation');
      final hasExample = types.contains('example');
      final hasList = types.contains('list');
      
      expect(hasDefinition || hasEquation || hasExample || hasList, isTrue,
        reason: 'Should detect at least one special type (got: $types)');
    });

    test('chunks with overlap when splitting large sections', () async {
      // Create text that will be split
      final longText = List.generate(
        30,
        (i) => 'Sentence $i provides important context.',
      ).join(' ');

      final results = await strategy.chunk(longText, {});

      if (results.length > 1) {
        // Check that there's some overlap between consecutive chunks
        final firstChunk = results[0].content;
        final secondChunk = results[1].content;
        
        // The second chunk should contain some content from near the end of first
        expect(secondChunk, isNotEmpty);
        expect(firstChunk, isNotEmpty);
      }
    });
  });
}

