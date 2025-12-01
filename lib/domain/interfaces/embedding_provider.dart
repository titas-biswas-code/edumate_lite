/// Abstract interface for embedding generation
/// Allows swapping embedding models without changing business logic
abstract class EmbeddingProvider {
  /// Model identifier
  String get modelId;

  /// Embedding dimension
  int get dimension;

  /// Initialize the embedding model
  Future<void> initialize();

  /// Generate embedding for a single text (document/chunk)
  Future<List<double>> embed(String text);

  /// Generate embedding for a query (optimized prompt for retrieval)
  Future<List<double>> embedQuery(String query) => embed(query);

  /// Generate embeddings for multiple texts (batch processing)
  Future<List<List<double>>> embedBatch(List<String> texts);

  /// Check if model is ready
  bool get isReady;

  /// Cleanup resources
  Future<void> dispose();
}

