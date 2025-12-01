import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/embedding_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/src/main/kotlin/io/flutter/embedding_gemma/EmbeddingApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'io.flutter.embedding_gemma',
  ),
  swiftOut: 'ios/Classes/EmbeddingApi.g.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'embedding_gemma',
))
enum EmbeddingBackend {
  CPU,
  GPU,
  GPU_FLOAT16,
  GPU_MIXED,
}

class InitializeRequest {
  final String modelPath;
  final String tokenizerPath;
  final int dimensions;
  final EmbeddingBackend backend;

  InitializeRequest({
    required this.modelPath,
    required this.tokenizerPath,
    required this.dimensions,
    required this.backend,
  });
}

class InitializeResponse {
  final EmbeddingBackend actualBackend;

  InitializeResponse({required this.actualBackend});
}

class EmbedRequest {
  final String text;
  final bool isQuery;

  EmbedRequest({
    required this.text,
    required this.isQuery,
  });
}

class EmbedBatchRequest {
  final List<String> texts;
  final bool isQuery;

  EmbedBatchRequest({
    required this.texts,
    required this.isQuery,
  });
}

class EmbeddingResult {
  final List<double> embedding;

  EmbeddingResult({required this.embedding});
}

class BatchEmbeddingResult {
  final List<List<double>> embeddings;

  BatchEmbeddingResult({required this.embeddings});
}

class TokenCountRequest {
  final String text;
  final bool withPrompt;

  TokenCountRequest({
    required this.text,
    required this.withPrompt,
  });
}

class TokenCountResult {
  final int tokenCount;

  TokenCountResult({required this.tokenCount});
}

@HostApi()
abstract class EmbeddingGemmaApi {
  @async
  InitializeResponse initialize(InitializeRequest request);

  @async
  EmbeddingResult embed(EmbedRequest request);

  @async
  BatchEmbeddingResult embedBatch(EmbedBatchRequest request);

  @async
  TokenCountResult countTokens(TokenCountRequest request);

  void dispose();
}
