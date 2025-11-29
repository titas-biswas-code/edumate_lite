import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:edumate_lite/config/service_locator.dart';
import 'package:edumate_lite/domain/services/material_processor.dart';
import 'package:edumate_lite/domain/services/rag_engine.dart';
import 'package:edumate_lite/domain/services/ai_initialization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Material Processing Integration Tests', () {
    setUpAll(() async {
      // Initialize flutter_gemma
      await FlutterGemma.initialize();

      // Setup service locator
      await setupServiceLocator();

      // Load models from assets
      // Note: Models must be in assets/models/ for these tests to work

      // Initialize AI providers
      final aiInit = getIt<AiInitializationService>();
      final result = await aiInit.initializeProviders();

      result.fold(
        (failure) =>
            throw Exception('Failed to initialize AI: ${failure.message}'),
        (_) => debugPrint('✅ AI providers initialized'),
      );
    });

    testWidgets('Process text material end-to-end', (tester) async {
      final processor = getIt<MaterialProcessor>();

      // Load sample text
      final sampleText = await rootBundle.loadString(
        'test/fixtures/sample.txt',
      );

      // Process material
      final input = MaterialInput(
        title: 'Photosynthesis Test',
        sourceType: 'text',
        content: sampleText,
        subject: 'science',
        gradeLevel: 7,
      );

      ProcessingProgress? lastProgress;
      await for (final progress in processor.process(input)) {
        lastProgress = progress;
        debugPrint(
          'Progress: ${progress.stage} - ${(progress.progress * 100).toInt()}%',
        );

        if (progress.error != null) {
          fail('Processing failed: ${progress.error}');
        }

        if (progress.isComplete) {
          break;
        }
      }

      // Verify processing completed
      expect(lastProgress, isNotNull);
      expect(lastProgress!.isComplete, isTrue);
      expect(lastProgress.result, isNotNull);
      expect(lastProgress.result!.status, 'completed');
      expect(lastProgress.result!.chunkCount, greaterThan(0));

      debugPrint('✅ Material processed: ${lastProgress.result!.chunkCount} chunks');
    });

    testWidgets('Search and retrieve from processed material', (tester) async {
      final ragEngine = getIt<RagEngine>();

      // Ask a question
      final result = await ragEngine.answer('What is photosynthesis?');

      await result.fold((failure) => fail('RAG failed: ${failure.message}'), (
        stream,
      ) async {
        final responses = await stream.toList();

        expect(responses, isNotEmpty);
        expect(responses.last.isComplete, isTrue);

        // Should have retrieved chunks
        expect(responses.last.retrievedChunks, isNotNull);
        expect(responses.last.retrievedChunks!.isNotEmpty, isTrue);

        // Build full response
        final fullResponse = responses
            .where((r) => !r.isComplete)
            .map((r) => r.content)
            .join();

        debugPrint('✅ AI Response: $fullResponse');
        expect(fullResponse, isNotEmpty);
      });
    });
  });
}
