import 'package:flutter_test/flutter_test.dart';
import 'package:embedding_gemma/embedding_gemma.dart';
import 'dart:io';

void main() {
  group('Batch Embedding Tests', () {
    test('Batch embedding with real model', () async {
      // This test requires model files
      final modelPath =
          '/data/user/0/com.example.embedding_gemma_example/app_flutter/embedding_models/embeddinggemma-300M_seq2048_mixed-precision.tflite';
      final tokenizerPath =
          '/data/user/0/com.example.embedding_gemma_example/app_flutter/embedding_models/sentencepiece.model';

      if (!File(modelPath).existsSync() || !File(tokenizerPath).existsSync()) {
        print('⚠️ Test skipped: Model files not found');
        return;
      }

      try {
        print('Creating embedder with CPU backend...');
        final embedder = await EmbeddingGemma.create(
          modelPath: modelPath,
          tokenizerPath: tokenizerPath,
          dimensions: 768,
          backend: EmbeddingBackend.CPU,
        );

        print('Testing single embedding first...');
        final singleEmbedding = await embedder.embed('Test text');
        print('Single embedding: ${singleEmbedding.length} dimensions');
        expect(singleEmbedding.length, 768);

        print('Testing batch embeddings...');
        final texts = [
          'First document',
          'Second document',
          'Third document',
        ];

        print('Calling embedBatch with ${texts.length} texts...');
        final embeddings = await embedder.embedBatch(texts);

        print('Batch result received!');
        print('Type: ${embeddings.runtimeType}');
        print('Length: ${embeddings.length}');

        expect(embeddings.length, 3);

        for (int i = 0; i < embeddings.length; i++) {
          print(
              'Embedding $i: type=${embeddings[i].runtimeType}, length=${embeddings[i].length}');
          expect(embeddings[i].length, 768);

          // Try to access individual values to trigger any lazy cast issues
          final firstValue = embeddings[i][0];
          print('  First value: $firstValue (type: ${firstValue.runtimeType})');
          expect(firstValue, isA<double>());
        }

        embedder.dispose();
        print('✅ Batch embedding test passed!');
      } catch (e, stack) {
        print('❌ Test failed: $e');
        print('Stack trace: $stack');
        rethrow;
      }
    });
  });
}
