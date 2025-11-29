import 'package:flutter_test/flutter_test.dart';
import 'package:edumate_lite/domain/interfaces/vector_store.dart';
import 'package:edumate_lite/domain/entities/chunk.dart';
import 'package:edumate_lite/domain/entities/material.dart';

/// Mock implementation for testing
class MockVectorStore implements VectorStore {
  final List<Chunk> _chunks = [];
  final Map<int, int> _chunkToMaterial = {}; // Track materialId per chunk
  int _nextId = 1;

  @override
  Future<int> store(Chunk chunk) async {
    chunk.id = _nextId++;
    _chunks.add(chunk);
    // Store material relationship
    if (chunk.material.target != null) {
      _chunkToMaterial[chunk.id] = chunk.material.target!.id;
    }
    return chunk.id;
  }

  @override
  Future<List<int>> storeBatch(List<Chunk> chunks) async {
    final ids = <int>[];
    for (final chunk in chunks) {
      ids.add(await store(chunk));
    }
    return ids;
  }

  @override
  Future<List<ScoredChunk>> search(
    List<double> queryEmbedding, {
    int topK = 5,
    double threshold = 0.5,
    List<int>? materialIds,
  }) async {
    // Simple mock: return chunks with fixed score
    var results = _chunks.where((c) {
      if (materialIds != null && materialIds.isNotEmpty) {
        final matId = _chunkToMaterial[c.id];
        return matId != null && materialIds.contains(matId);
      }
      return true;
    }).map((c) => ScoredChunk(chunk: c, score: 0.8)).toList();

    results = results.where((sc) => sc.score >= threshold).toList();
    return results.take(topK).toList();
  }

  @override
  Future<void> deleteByMaterial(int materialId) async {
    final toRemove = _chunks.where((c) {
      final matId = _chunkToMaterial[c.id];
      return matId == materialId;
    }).toList();
    
    for (final chunk in toRemove) {
      _chunks.remove(chunk);
      _chunkToMaterial.remove(chunk.id);
    }
  }

  @override
  Future<Chunk?> getById(int id) async {
    try {
      return _chunks.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Chunk>> getByMaterial(int materialId) async {
    return _chunks.where((c) {
      final matId = _chunkToMaterial[c.id];
      return matId == materialId;
    }).toList();
  }
}

void main() {
  group('VectorStore Interface', () {
    late MockVectorStore vectorStore;
    late Material testMaterial;

    setUp(() {
      vectorStore = MockVectorStore();
      testMaterial = Material(
        title: 'Test Material',
        sourceType: 'pdf',
      );
      testMaterial.id = 1;
    });

    test('store saves chunk and returns ID', () async {
      final chunk = Chunk(
        content: 'Test content',
        sequenceIndex: 0,
      );
      chunk.material.target = testMaterial;

      final id = await vectorStore.store(chunk);

      expect(id, greaterThan(0));
      expect(chunk.id, id);
    });

    test('storeBatch saves multiple chunks', () async {
      final chunks = List.generate(
        3,
        (i) => Chunk(
          content: 'Content $i',
          sequenceIndex: i,
        )..material.target = testMaterial,
      );

      final ids = await vectorStore.storeBatch(chunks);

      expect(ids.length, 3);
      expect(ids.every((id) => id > 0), isTrue);
    });

    test('search returns chunks with scores', () async {
      // Store some chunks
      final chunks = List.generate(
        5,
        (i) => Chunk(
          content: 'Content $i',
          sequenceIndex: i,
          embedding: List.generate(768, (j) => j * 0.1),
        )..material.target = testMaterial,
      );
      await vectorStore.storeBatch(chunks);

      // Search
      final queryEmbedding = List.generate(768, (i) => i * 0.1);
      final results = await vectorStore.search(queryEmbedding, topK: 3);

      expect(results.length, lessThanOrEqualTo(3));
      expect(results.every((r) => r.score >= 0 && r.score <= 1), isTrue);
    });

    test('search filters by threshold', () async {
      final chunk = Chunk(
        content: 'Test content',
        sequenceIndex: 0,
      )..material.target = testMaterial;
      await vectorStore.store(chunk);

      final queryEmbedding = List.generate(768, (i) => i * 0.1);
      final results = await vectorStore.search(
        queryEmbedding,
        threshold: 0.9, // High threshold
      );

      // Mock returns 0.8, so should be filtered out
      expect(results.isEmpty, isTrue);
    });

    test('getById returns correct chunk', () async {
      final chunk = Chunk(
        content: 'Test content',
        sequenceIndex: 0,
      )..material.target = testMaterial;
      final id = await vectorStore.store(chunk);

      final retrieved = await vectorStore.getById(id);

      expect(retrieved, isNotNull);
      expect(retrieved?.id, id);
      expect(retrieved?.content, 'Test content');
    });

    test('getById returns null for non-existent ID', () async {
      final retrieved = await vectorStore.getById(999);
      expect(retrieved, isNull);
    });

    test('getByMaterial returns all chunks for material', () async {
      final chunks = List.generate(
        3,
        (i) => Chunk(
          content: 'Content $i',
          sequenceIndex: i,
        )..material.target = testMaterial,
      );
      await vectorStore.storeBatch(chunks);

      final retrieved = await vectorStore.getByMaterial(testMaterial.id);

      expect(retrieved.length, 3);
    });

    test('deleteByMaterial removes all chunks for material', () async {
      final chunks = List.generate(
        3,
        (i) => Chunk(
          content: 'Content $i',
          sequenceIndex: i,
        )..material.target = testMaterial,
      );
      await vectorStore.storeBatch(chunks);

      await vectorStore.deleteByMaterial(testMaterial.id);
      final retrieved = await vectorStore.getByMaterial(testMaterial.id);

      expect(retrieved.isEmpty, isTrue);
    });
  });
}

