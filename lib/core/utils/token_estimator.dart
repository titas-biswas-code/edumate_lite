/// Utility for estimating token counts for Gemma models
/// Based on SentencePiece tokenizer characteristics
class TokenEstimator {
  TokenEstimator._();

  /// Estimate tokens from text
  /// VERY conservative formula for SentencePiece (EmbeddingGemma tokenizer)
  /// Observed: chunks estimated at 1400 actually have 3332 tokens
  /// Real ratio: 3332/1400 = 2.38x
  /// Using 2.5x for safety margin
  static int estimate(String text) {
    if (text.isEmpty) return 0;

    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final punctuation =
        RegExp(r'''[.,!?;:\-(){}\[\]"'`]''').allMatches(text).length;
    
    // Very conservative: 2.5 tokens per word + punctuation
    return (words * 2.5 + punctuation * 0.5).ceil();
  }

  /// Check if text fits within token limit
  static bool fitsInLimit(String text, int limit) {
    return estimate(text) <= limit;
  }

  /// Truncate text to fit token limit (approximate)
  static String truncateToLimit(String text, int limit) {
    final estimated = estimate(text);
    if (estimated <= limit) return text;

    final ratio = limit / estimated;
    final targetLength = (text.length * ratio * 0.95).toInt();
    
    if (targetLength >= text.length) return text;
    return text.substring(0, targetLength);
  }

  /// Estimate tokens for a list of strings
  static int estimateBatch(List<String> texts) {
    return texts.fold(0, (sum, text) => sum + estimate(text));
  }
}

