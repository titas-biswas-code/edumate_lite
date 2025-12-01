import 'embedding_api.g.dart';
import 'installation_builder.dart';
import 'model_manager.dart';

/// EmbeddingGemma-300M (768 dims, 2048 token context) embedding provider
class EmbeddingGemma {
  final EmbeddingGemmaApi _api;
  final int dimensions;
  bool _isInitialized = false;
  EmbeddingBackend? _actualBackend;

  EmbeddingGemma._({
    required EmbeddingGemmaApi api,
    required this.dimensions,
  }) : _api = api;

  /// Get the actual backend being used (may differ from requested due to fallback)
  EmbeddingBackend? get actualBackend => _actualBackend;

  /// Install embedding model from assets (flutter_gemma pattern)
  static EmbeddingInstallationBuilder installModel() {
    return EmbeddingInstallationBuilder();
  }

  /// Get active embedding model (flutter_gemma pattern)
  static Future<EmbeddingGemma> getActiveModel({
    EmbeddingBackend backend = EmbeddingBackend.GPU,
  }) async {
    final manager = EmbeddingModelManager.instance;
    final activeModel = await manager.getActiveModel();

    if (activeModel == null) {
      throw StateError(
        'No active embedding model. Use EmbeddingGemma.installModel() first.',
      );
    }

    return create(
      modelPath: activeModel['modelPath'] as String,
      tokenizerPath: activeModel['tokenizerPath'] as String,
      dimensions: activeModel['dimensions'] as int,
      backend: backend,
    );
  }

  /// Check if an active model is set
  static Future<bool> hasActiveModel() async {
    final manager = EmbeddingModelManager.instance;
    return await manager.hasActiveModel();
  }

  /// Create EmbeddingGemma with absolute file paths
  static Future<EmbeddingGemma> create({
    required String modelPath,
    required String tokenizerPath,
    required int dimensions,
    EmbeddingBackend backend = EmbeddingBackend.GPU,
  }) async {
    final api = EmbeddingGemmaApi();
    final instance = EmbeddingGemma._(
      api: api,
      dimensions: dimensions,
    );

    await instance._initialize(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      backend: backend,
    );

    return instance;
  }

  Future<void> _initialize({
    required String modelPath,
    required String tokenizerPath,
    required EmbeddingBackend backend,
  }) async {
    final request = InitializeRequest(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      dimensions: dimensions,
      backend: backend,
    );

    final response = await _api.initialize(request);
    _actualBackend = response.actualBackend;
    _isInitialized = true;
  }

  /// Embed a document for storage
  Future<List<double>> embed(String text) async {
    _checkInitialized();
    final request = EmbedRequest(text: text, isQuery: false);
    final result = await _api.embed(request);
    return result.embedding;
  }

  /// Embed a query for retrieval
  Future<List<double>> embedQuery(String query) async {
    _checkInitialized();
    final request = EmbedRequest(text: query, isQuery: true);
    final result = await _api.embed(request);
    return result.embedding;
  }

  /// Batch embed documents
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    _checkInitialized();
    final request = EmbedBatchRequest(texts: texts, isQuery: false);
    final result = await _api.embedBatch(request);
    return result.embeddings;
  }

  /// Batch embed queries
  Future<List<List<double>>> embedQueryBatch(List<String> queries) async {
    _checkInitialized();
    final request = EmbedBatchRequest(texts: queries, isQuery: true);
    final result = await _api.embedBatch(request);
    return result.embeddings;
  }

  /// Count tokens for text (approximate)
  ///
  /// [text]: Text to count tokens for
  /// [withPrompt]: Include task prompt overhead (default: true)
  ///
  /// Returns approximate token count (±10% accuracy).
  /// Uses character-based estimation: ~4 chars per token for English.
  ///
  /// Example:
  /// ```dart
  /// final count = await embedder.countTokens('Your text here');
  /// if (count > 2000) {
  ///   print('Text too long, need to chunk');
  /// }
  /// ```
  Future<int> countTokens(String text, {bool withPrompt = true}) async {
    _checkInitialized();
    final request = TokenCountRequest(text: text, withPrompt: withPrompt);
    final result = await _api.countTokens(request);
    return result.tokenCount;
  }

  /// Dispose resources
  void dispose() {
    if (_isInitialized) {
      _api.dispose();
      _isInitialized = false;
    }
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('EmbeddingGemma not initialized');
    }
  }
}
