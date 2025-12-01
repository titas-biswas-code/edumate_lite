import 'package:flutter_test/flutter_test.dart';
import 'package:edumate_lite/infrastructure/chunking/educational_chunking_strategy.dart';
import 'package:edumate_lite/core/utils/token_estimator.dart';
import 'package:edumate_lite/core/constants/app_constants.dart';

void main() {
  group('EducationalChunkingStrategy - Token Limit Tests', () {
    late EducationalChunkingStrategy strategy;

    setUp(() {
      strategy = EducationalChunkingStrategy();
    });

    test('respects targetChunkSize constant', () {
      expect(strategy.targetChunkSize, equals(AppConstants.targetChunkSizeTokens));
      expect(strategy.targetChunkSize, equals(1200)); // Verify it's 1200
    });

    test('respects maxChunkSize - no chunk exceeds 1400 tokens', () async {
      // Create a very long text (should create multiple chunks)
      final longText = List.generate(2000, (i) => 'word').join(' ');
      
      final chunks = await strategy.chunk(longText, {});
      
      expect(chunks.isNotEmpty, true);
      
      for (final chunk in chunks) {
        final tokens = TokenEstimator.estimate(chunk.content);
        expect(
          tokens,
          lessThanOrEqualTo(AppConstants.maxChunkSizeTokens),
          reason: 'Chunk has $tokens tokens, exceeds max ${AppConstants.maxChunkSizeTokens}',
        );
      }
    });

    test('creates more chunks with smaller token limits', () async {
      // Same text should create more chunks with 1200 limit vs 1800 limit
      final text = List.generate(3000, (i) => 'word$i').join(' ');
      
      final chunks = await strategy.chunk(text, {});
      
      // With 1200 token target and 1.6x estimator:
      // 3000 words * 1.6 = 4800 tokens
      // Should create at least 4800 / 1200 = 4 chunks
      expect(chunks.length, greaterThanOrEqualTo(4));
      
      print('Generated ${chunks.length} chunks from 3000 words');
      for (var i = 0; i < chunks.length; i++) {
        final tokens = TokenEstimator.estimate(chunks[i].content);
        print('Chunk $i: $tokens tokens');
      }
    });

    test('splits long sections correctly', () async {
      // Create text that needs splitting
      final longSection = List.generate(1000, (i) => 
        'This is sentence number $i with some content. '
      ).join('');
      
      final chunks = await strategy.chunk(longSection, {});
      
      expect(chunks.length, greaterThan(1));
      
      // Check all chunks are within limits
      for (final chunk in chunks) {
        final tokens = TokenEstimator.estimate(chunk.content);
        expect(tokens, lessThanOrEqualTo(AppConstants.maxChunkSizeTokens));
      }
    });

    test('token estimator is conservative enough', () {
      // Test various texts
      final tests = [
        ('hello world', 4),  // 2 words * 1.6 = 3.2 -> 4
        ('The quick brown fox jumps.', 11), // 5 words * 1.6 + punct = 8 + 0.3 = 9
        (List.generate(100, (i) => 'word').join(' '), 160), // 100 * 1.6 = 160
        (List.generate(1000, (i) => 'test').join(' '), 1600), // 1000 * 1.6 = 1600
      ];
      
      for (final (text, minExpected) in tests) {
        final estimated = TokenEstimator.estimate(text);
        expect(
          estimated,
          greaterThanOrEqualTo(minExpected),
          reason: 'Text "$text" estimated $estimated, expected >= $minExpected',
        );
      }
    });

    test('realistic PDF text stays under limits', () async {
      // Simulate realistic educational content
      final realisticText = '''
Chapter 1: Introduction to Biology

Biology is the scientific study of life and living organisms. It encompasses various fields including molecular biology, genetics, ecology, and evolution.

Key Concepts:
- Cell theory: All living things are made of cells
- Evolution: Species change over time through natural selection
- Genetics: Heredity and variation in organisms
- Homeostasis: Maintenance of internal stability

The scope of biology ranges from microscopic molecules to entire ecosystems. Modern biology integrates knowledge from chemistry, physics, mathematics, and computer science to understand life processes.

Example 1: Cell Structure
A typical animal cell contains organelles such as the nucleus, mitochondria, endoplasmic reticulum, and Golgi apparatus. Each organelle performs specific functions essential for cell survival.

The cell membrane acts as a selective barrier, controlling what enters and exits the cell. This selective permeability is crucial for maintaining cellular homeostasis.
''';

      final chunks = await strategy.chunk(realisticText, {});
      
      print('\n=== Realistic PDF Text Test ===');
      print('Input words: ${realisticText.split(RegExp(r'\s+')).length}');
      print('Chunks generated: ${chunks.length}');
      
      for (var i = 0; i < chunks.length; i++) {
        final tokens = TokenEstimator.estimate(chunks[i].content);
        final words = chunks[i].content.split(RegExp(r'\s+')).length;
        print('Chunk $i: $words words, ~$tokens tokens (type: ${chunks[i].chunkType})');
        
        expect(
          tokens,
          lessThanOrEqualTo(AppConstants.maxChunkSizeTokens),
          reason: 'Chunk $i exceeded max tokens',
        );
      }
    });
  });
}

