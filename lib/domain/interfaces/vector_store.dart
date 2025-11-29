import '../entities/chunk.dart';

/// Abstract interface for vector storage and retrieval
abstract class VectorStore {
  /// Store a chunk with its embedding
  Future<int> store(Chunk chunk);

  /// Store multiple chunks (batch)
  Future<List<int>> storeBatch(List<Chunk> chunks);

  /// Search for similar chunks
  ///
  /// [queryEmbedding] - Vector to search for
  /// [topK] - Number of results to return
  /// [threshold] - Minimum similarity score (0.0 - 1.0)
  /// [materialIds] - Optional filter by material IDs
  Future<List<ScoredChunk>> search(
    List<double> queryEmbedding, {
    int topK = 5,
    double threshold = 0.5,
    List<int>? materialIds,
  });

  /// Delete chunks by material ID
  Future<void> deleteByMaterial(int materialId);

  /// Get chunk by ID
  Future<Chunk?> getById(int id);

  /// Get all chunks for a material
  Future<List<Chunk>> getByMaterial(int materialId);
}

/// Chunk with similarity score
class ScoredChunk {
  final Chunk chunk;
  final double score;

  ScoredChunk({required this.chunk, required this.score});
}

