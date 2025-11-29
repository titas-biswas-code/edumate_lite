import 'package:flutter_gemma/flutter_gemma.dart';
import '../../domain/interfaces/embedding_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';

/// Gemma-based embedding provider using EmbeddingGemma-300M
/// 
/// IMPORTANT: flutter_gemma returns dynamic types that need explicit casting
/// - generateEmbedding() returns `List<dynamic>` (needs cast to `List<double>`)
/// - generateEmbeddings() returns `List<dynamic>` where each item is `List<dynamic>`
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
    AppLogger.info('🚀 Initializing EmbeddingGemma provider...');
    
    try {
      // Check if active embedding model exists
      if (!FlutterGemma.hasActiveEmbedder()) {
        AppLogger.error('❌ No active embedding model found');
        throw ModelException('No active embedding model. Please download first.');
      }

      AppLogger.debug('✅ Active embedder found, attempting GPU initialization...');

      // Get the active embedding model with GPU support if available
      try {
        _embeddingModel = await FlutterGemma.getActiveEmbedder(
          preferredBackend: PreferredBackend.gpu,
        );
        _isReady = true;
        AppLogger.info('✅ Embedding model initialized with GPU backend');
      } catch (e) {
        AppLogger.warning('⚠️  GPU initialization failed, falling back to CPU', e);
        
        // Try CPU fallback
        try {
          _embeddingModel = await FlutterGemma.getActiveEmbedder(
            preferredBackend: PreferredBackend.cpu,
          );
          _isReady = true;
          AppLogger.info('✅ Embedding model initialized with CPU backend');
        } catch (e2) {
          AppLogger.error('❌ CPU initialization also failed', e2);
          throw ModelException(
            'Failed to create embedding model instance. '
            'GPU Error: $e, CPU Error: $e2',
          );
        }
      }
      
      AppLogger.info('✅ EmbeddingGemma ready (dimension: $dimension)');
    } catch (e, stackTrace) {
      _isReady = false;
      AppLogger.error('❌ Embedding provider initialization failed', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<double>> embed(String text) async {
    if (!_isReady || _embeddingModel == null) {
      AppLogger.error('❌ Embedding provider not initialized');
      throw ModelException('Embedding provider not initialized');
    }

    if (text.isEmpty) {
      AppLogger.warning('⚠️  Empty text provided to embed()');
      throw ModelException('Text cannot be empty');
    }

    try {
      AppLogger.debug('📝 Generating embedding for text (length: ${text.length})');
      
      // Generate single embedding (returns List<dynamic>)
      final embeddingRaw = await _embeddingModel!.generateEmbedding(text);
      
      AppLogger.verbose('Raw embedding type: ${embeddingRaw.runtimeType}');
      
      // Convert from dynamic List to List<double> robustly
      final embedding = (embeddingRaw as List)
          .map((dynamic e) => (e as num).toDouble())
          .toList();
      
      AppLogger.debug('✅ Generated embedding (dim: ${embedding.length})');
      
      // Validate dimension
      if (embedding.length != dimension) {
        AppLogger.warning(
          '⚠️  Unexpected embedding dimension: ${embedding.length}, expected: $dimension'
        );
      }
      
      return embedding;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Embedding generation failed', e, stackTrace);
      throw ModelException('Embedding generation failed: $e');
    }
  }

  @override
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    AppLogger.info('📦 embedBatch called with ${texts.length} texts');
    
    if (!_isReady || _embeddingModel == null) {
      AppLogger.error('❌ Embedding provider not initialized');
      throw ModelException('Embedding provider not initialized');
    }

    if (texts.isEmpty) {
      AppLogger.warning('⚠️  Empty text list provided to embedBatch()');
      throw ModelException('Text list cannot be empty');
    }

    try {
      AppLogger.debug('🔄 Calling generateEmbeddings() with ${texts.length} texts');
      
      // Use batch API - returns List<dynamic> where each element is List<dynamic>
      final embeddingsRaw = await _embeddingModel!.generateEmbeddings(texts);
      
      AppLogger.verbose(
        'Raw embeddings type: ${embeddingsRaw.runtimeType}, '
        'length: ${embeddingsRaw.length}'
      );
      
      // Validate count
      if (embeddingsRaw.length != texts.length) {
        AppLogger.warning(
          '⚠️  Embedding count mismatch: got ${embeddingsRaw.length}, expected ${texts.length}'
        );
      }
      
      AppLogger.debug(
          '🔨 Converting ${embeddingsRaw.length} embeddings to List<List<double>>');

      // Convert each embedding from a dynamic list to List<double> robustly.
      final result = (embeddingsRaw as List).map((dynamic embeddingRaw) {
        final embeddingList = embeddingRaw as List;
        final embedding = embeddingList
            .map((dynamic e) => (e as num).toDouble())
            .toList();

        if (embedding.length != dimension) {
          AppLogger.warning(
              '⚠️ Unexpected embedding dimension: ${embedding.length}, expected: $dimension');
        }
        return embedding;
      }).toList();

      AppLogger.info('✅ Successfully generated ${result.length} embeddings');
      return result;
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Batch embedding generation failed for ${texts.length} texts',
        e,
        stackTrace,
      );
      throw ModelException('Batch embedding generation failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _isReady = false;
    _embeddingModel = null;
  }
}
