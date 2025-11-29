/// Utility for estimating token counts for Gemma models
/// Based on SentencePiece tokenizer characteristics
class TokenEstimator {
  TokenEstimator._();

  /// Estimate tokens from text
  /// Uses empirical formula: words * 1.3 + punctuation * 0.5
  static int estimate(String text) {
    if (text.isEmpty) return 0;

    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final punctuation =
        RegExp(r'''[.,!?;:\-(){}\[\]"'`]''').allMatches(text).length;
    return (words * 1.3 + punctuation * 0.5).ceil();
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

