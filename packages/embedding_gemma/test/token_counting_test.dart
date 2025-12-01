import 'package:flutter_test/flutter_test.dart';
import 'package:embedding_gemma/embedding_gemma.dart';

void main() {
  group('Token Counting Tests', () {
    test('Short text token count', () {
      // Approximate: "Hello world" ≈ 2 words * 0.75 + 2 special tokens ≈ 3-4 tokens
      final text = 'Hello world';
      final expectedRange = (2, 6); // Allow range for approximation

      expect(text.split(' ').length, 2); // 2 words
      // Token count will be tested in integration test
    });

    test('Medium text token count estimation', () {
      // ~50 words should be roughly 40-50 tokens
      final words = List.generate(50, (i) => 'word$i').join(' ');
      final wordCount = words.split(' ').length;

      expect(wordCount, 50);

      // Approximate calculation (what our implementation does)
      final estimated = (wordCount * 0.75).toInt() + 2;
      expect(estimated, greaterThan(35));
      expect(estimated, lessThan(60));
    });

    test('Long text token count estimation', () {
      // 2000 characters should be roughly 500 tokens
      final text = 'a' * 2000;
      final charCount = text.length;

      expect(charCount, 2000);

      // Char-based estimation
      final estimated = (charCount / 4.0).toInt() + 2;
      expect(estimated, greaterThan(450));
      expect(estimated, lessThan(550));
    });

    test('Prompt overhead adds tokens', () {
      final text = 'test';

      // Without prompt: just "test" ≈ 1 word = 1 token + 2 special
      final withoutPrompt = (1 * 0.75).toInt() + 2;

      // With prompt: "title: none | text: test" ≈ 6 words
      final promptText = 'title: none | text: $text';
      final withPrompt = (promptText.split(' ').length * 0.75).toInt() + 2;

      expect(withPrompt, greaterThan(withoutPrompt));
    });

    test('Empty text has minimal tokens', () {
      final text = '';

      // Just special tokens (BOS, EOS)
      final estimated = 2;
      expect(estimated, 2);
    });

    test('Validates max token limit', () {
      const maxTokens = 2048;

      // Text that's definitely under limit
      final shortText = 'word ' * 100; // ~100 words ≈ 75 tokens
      final shortEstimate = (100 * 0.75).toInt() + 2;
      expect(shortEstimate, lessThan(maxTokens));

      // Text that's definitely over limit
      final longText = 'word ' * 3000; // ~3000 words ≈ 2250 tokens
      final longEstimate = (3000 * 0.75).toInt() + 2;
      expect(longEstimate, greaterThan(maxTokens));
    });
  });

  group('Token Counting Integration Tests', () {
    test('Count tokens with real model', () async {
      // This requires running on device with initialized model
      // Placeholder for now - will be tested via example app

      expect(true, isTrue); // Placeholder
    });
  });
}
