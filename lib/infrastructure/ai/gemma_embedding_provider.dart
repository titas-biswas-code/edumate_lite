import 'package:flutter_gemma/flutter_gemma.dart';
import '../../domain/interfaces/embedding_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

/// Gemma-based embedding provider using EmbeddingGemma-300M
class GemmaEmbeddingProvider implements EmbeddingProvider {
  bool _isReady = false;
  EmbeddingModel? _embeddingModel;
  
  @override
  String get modelId => 'EmbeddingGemma-300M';

  @override
  int get dimension => AppConstants.embeddingDimension;

  @override
  bool get isReady => _isReady;

  @override
  Future<void> initialize() async {
    try {
      // Check if active embedding model exists
      if (!FlutterGemma.hasActiveEmbedder()) {
        throw ModelException('No active embedding model. Please download first.');
      }

      // Get the active embedding model with GPU support if available
      try {
        _embeddingModel = await FlutterGemma.getActiveEmbedder(
          preferredBackend: PreferredBackend.gpu,
        );
        _isReady = true;
      } catch (e) {
        // Try CPU fallback
        try {
          _embeddingModel = await FlutterGemma.getActiveEmbedder(
            preferredBackend: PreferredBackend.cpu,
          );
          _isReady = true;
        } catch (e2) {
          throw ModelException(
            'Failed to create embedding model instance. '
            'Error: $e',
          );
        }
      }
    } catch (e) {
      _isReady = false;
      rethrow;
    }
  }

  @override
  Future<List<double>> embed(String text) async {
    if (!_isReady || _embeddingModel == null) {
      throw ModelException('Embedding provider not initialized');
    }

    if (text.isEmpty) {
      throw ModelException('Text cannot be empty');
    }

    try {
      // Generate single embedding
      final embedding = await _embeddingModel!.generateEmbedding(text);
      // Proper type conversion from dynamic/Object? to double
      return List<double>.from(embedding);
    } catch (e) {
      throw ModelException('Embedding generation failed: $e');
    }
  }

  @override
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    if (!_isReady || _embeddingModel == null) {
      throw ModelException('Embedding provider not initialized');
    }

    if (texts.isEmpty) {
      throw ModelException('Text list cannot be empty');
    }

    try {
      // Use batch API
      final embeddings = await _embeddingModel!.generateEmbeddings(texts);
      // Proper type conversion for each embedding vector
      return embeddings
          .map((embedding) => List<double>.from(embedding))
          .toList();
    } catch (e) {
      throw ModelException('Batch embedding generation failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _isReady = false;
    _embeddingModel = null;
  }
}





