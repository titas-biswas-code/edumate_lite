import 'package:flutter_test/flutter_test.dart';
import 'package:edumate_lite/domain/services/rag_engine.dart';
import 'package:edumate_lite/domain/interfaces/embedding_provider.dart';
import 'package:edumate_lite/domain/interfaces/vector_store.dart';
import 'package:edumate_lite/domain/interfaces/inference_provider.dart';
import 'package:edumate_lite/domain/entities/chunk.dart';
import 'package:edumate_lite/domain/entities/material.dart';
import 'package:edumate_lite/domain/entities/message.dart';
import 'dart:typed_data';

/// Mock implementations for testing
class MockEmbeddingProvider implements EmbeddingProvider {
  @override
  String get modelId => 'mock';

  @override
  int get dimension => 768;

  @override
  bool get isReady => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<double>> embed(String text) async {
    return List.generate(768, (i) => i / 768);
  }

  @override
  Future<List<double>> embedQuery(String query) async {
    return List.generate(768, (i) => i / 768);
  }

  @override
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    return [for (final text in texts) await embed(text)];
  }

  @override
  Future<void> dispose() async {}
}

class MockVectorStore implements VectorStore {
  final List<Chunk> _chunks = [];

  void addChunk(Chunk chunk) {
    _chunks.add(chunk);
  }

  @override
  Future<int> store(Chunk chunk) async => 1;

  @override
  Future<List<int>> storeBatch(List<Chunk> chunks) async => [1, 2, 3];

  @override
  Future<List<ScoredChunk>> search(
    List<double> queryEmbedding, {
    int topK = 5,
    double threshold = 0.5,
    List<int>? materialIds,
  }) async {
    return _chunks
        .map((c) => ScoredChunk(chunk: c, score: 0.85))
        .take(topK)
        .toList();
  }

  @override
  Future<void> deleteByMaterial(int materialId) async {}

  @override
  Future<Chunk?> getById(int id) async => null;

  @override
  Future<List<Chunk>> getByMaterial(int materialId) async => _chunks;
}

class MockInferenceProvider implements InferenceProvider {
  @override
  String get modelId => 'mock';

  @override
  bool get isReady => true;

  @override
  bool get supportsVision => true;

  @override
  Future<void> initialize() async {}

  @override
  Stream<String> generate({
    required String systemPrompt,
    required String context,
    required String query,
    List<Message>? conversationHistory,
  }) async* {
    yield 'This is ';
    yield 'a test ';
    yield 'response.';
  }

  @override
  Stream<String> generateWithImage({
    required String systemPrompt,
    required Uint8List imageBytes,
    required String query,
  }) async* {
    yield 'Image response.';
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('RagEngine', () {
    late RagEngine ragEngine;
    late MockEmbeddingProvider embeddingProvider;
    late MockVectorStore vectorStore;
    late MockInferenceProvider inferenceProvider;

    setUp(() {
      embeddingProvider = MockEmbeddingProvider();
      vectorStore = MockVectorStore();
      inferenceProvider = MockInferenceProvider();

      ragEngine = RagEngine(
        embeddingProvider: embeddingProvider,
        vectorStore: vectorStore,
        inferenceProvider: inferenceProvider,
      );

      // Add some test chunks
      final material = Material(title: 'Test', sourceType: 'pdf');
      material.id = 1;

      for (var i = 0; i < 5; i++) {
        final chunk = Chunk(
          content: 'Test content $i',
          sequenceIndex: i,
        )..material.target = material;
        vectorStore.addChunk(chunk);
      }
    });

    test('answer returns Right with valid query', () async {
      final result = await ragEngine.answer('What is a test?');

      expect(result.isRight(), isTrue);
    });

    test('answer returns Left for empty query', () async {
      final result = await ragEngine.answer('');

      expect(result.isLeft(), isTrue);
    });

    test('answer streams response chunks', () async {
      final result = await ragEngine.answer('What is a test?');

      await result.fold(
        (failure) => fail('Should not fail'),
        (stream) async {
          final responses = await stream.toList();
          expect(responses.length, greaterThan(0));
          expect(responses.last.isComplete, isTrue);
        },
      );
    });

    test('answer includes retrieved chunks in response', () async {
      final result = await ragEngine.answer('What is a test?');

      await result.fold(
        (failure) => fail('Should not fail'),
        (stream) async {
          final responses = await stream.toList();
          final lastResponse = responses.last;
          expect(lastResponse.retrievedChunks, isNotNull);
          expect(lastResponse.retrievedChunks!.isNotEmpty, isTrue);
        },
      );
    });

    test('answer handles no context found scenario', () async {
      // Use empty vector store
      final emptyVectorStore = MockVectorStore(); // No chunks added

      final strictEngine = RagEngine(
        embeddingProvider: embeddingProvider,
        vectorStore: emptyVectorStore,
        inferenceProvider: inferenceProvider,
      );

      final result = await strictEngine.answer('What is a test?');

      await result.fold(
        (failure) => fail('Should not fail'),
        (stream) async {
          final responses = await stream.toList();
          // Should get no context found response
          expect(responses.length, 1);
          expect(responses.first.confidenceScore, 0.0);
          expect(responses.first.content, contains('don\'t have enough information'));
        },
      );
    });

    test('generateQuiz returns Right with valid material IDs', () async {
      final result = await ragEngine.generateQuiz([1]);

      expect(result.isRight(), isTrue);
    });

    test('generateQuiz returns Left for empty material list', () async {
      final result = await ragEngine.generateQuiz([]);

      expect(result.isLeft(), isTrue);
    });

    test('generateQuiz streams quiz content', () async {
      final result = await ragEngine.generateQuiz([1], questionCount: 5);

      await result.fold(
        (failure) => fail('Should not fail'),
        (stream) async {
          final responses = await stream.toList();
          expect(responses.length, greaterThan(0));
          expect(responses.last.isComplete, isTrue);
        },
      );
    });
  });
}

