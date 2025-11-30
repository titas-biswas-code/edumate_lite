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
        throw ModelException(
          'No active embedding model. Please download first.',
        );
      }

      AppLogger.debug(
        '✅ Active embedder found, attempting GPU initialization...',
      );

      // Get the active embedding model with GPU support if available
      try {
        _embeddingModel = await FlutterGemma.getActiveEmbedder(
          preferredBackend: PreferredBackend.gpu,
        );
        _isReady = true;
        AppLogger.info('✅ Embedding model initialized with GPU backend');
      } catch (e) {
        AppLogger.warning(
          '⚠️  GPU initialization failed, falling back to CPU',
          e,
        );

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
      AppLogger.error(
        '❌ Embedding provider initialization failed',
        e,
        stackTrace,
      );
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
      AppLogger.debug(
        '📝 Generating embedding for text (length: ${text.length})',
      );

      // Keep as dynamic to avoid CastList wrapper
      final dynamic embeddingRaw = await _embeddingModel!.generateEmbedding(
        text,
      );

      AppLogger.verbose('Raw embedding type: ${embeddingRaw.runtimeType}');

      // Eagerly convert using dynamic access to bypass CastList
      final embedding = <double>[];
      if (embeddingRaw is List) {
        final int count = (embeddingRaw as dynamic).length as int;
        for (int i = 0; i < count; i++) {
          final dynamic value = (embeddingRaw as dynamic)[i];
          if (value is num) {
            embedding.add(value.toDouble());
          }
        }
      }

      AppLogger.debug('✅ Generated embedding (dim: ${embedding.length})');

      if (embedding.length != dimension) {
        AppLogger.warning(
          '⚠️  Unexpected embedding dimension: ${embedding.length}, expected: $dimension',
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
      // WORKAROUND: flutter_gemma's generateEmbeddings() returns broken CastList
      // Call embed() individually instead - it works fine
      AppLogger.debug(
        '⚠️  Using individual embed() calls instead of broken batch API (${texts.length} texts)',
      );

      final result = <List<double>>[];
      
      for (int i = 0; i < texts.length; i++) {
        AppLogger.verbose('  [$i/${texts.length}] Generating embedding...');
        final embedding = await embed(texts[i]);
        result.add(embedding);
      }

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
