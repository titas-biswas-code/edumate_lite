/// Abstract interface for embedding generation
/// Allows swapping embedding models without changing business logic
abstract class EmbeddingProvider {
  /// Model identifier
  String get modelId;

  /// Embedding dimension
  int get dimension;

  /// Initialize the embedding model
  Future<void> initialize();

  /// Generate embedding for a single text
  Future<List<double>> embed(String text);

  /// Generate embeddings for multiple texts (batch processing)
  Future<List<List<double>>> embedBatch(List<String> texts);

  /// Check if model is ready
  bool get isReady;

  /// Cleanup resources
  Future<void> dispose();
}

