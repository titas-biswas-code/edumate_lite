/// Abstract interface for chunking strategies
/// Implement this to add domain-specific chunking logic
abstract class ChunkingStrategy {
  /// Strategy identifier
  String get strategyId;

  /// Chunk the given text into semantic units
  ///
  /// [text] - Raw text to chunk
  /// [metadata] - Additional context (source type, subject, etc.)
  ///
  /// Returns list of ChunkResult with text and metadata
  Future<List<ChunkResult>> chunk(
    String text,
    Map<String, dynamic> metadata,
  );

  /// Optimal chunk size for this strategy (in tokens, approximate)
  int get targetChunkSize;

  /// Overlap between chunks (in tokens, approximate)
  int get chunkOverlap;
}

/// Result of chunking operation
class ChunkResult {
  final String content;
  final String chunkType;
  final int? pageNumber;
  final int? sectionIndex;
  final Map<String, dynamic> metadata;

  ChunkResult({
    required this.content,
    required this.chunkType,
    this.pageNumber,
    this.sectionIndex,
    this.metadata = const {},
  });
}

