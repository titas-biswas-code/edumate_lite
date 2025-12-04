import 'dart:async';
import 'package:dartz/dartz.dart';
import '../interfaces/input_source.dart';
import '../interfaces/chunking_strategy.dart';
import '../interfaces/embedding_provider.dart';
import '../interfaces/vector_store.dart';
import '../entities/material.dart';
import '../entities/chunk.dart';
import '../../objectbox.g.dart' as obx;
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';
import '../../core/constants/app_constants.dart';

/// Material Processor
/// Orchestrates the full pipeline from input to indexed chunks
class MaterialProcessor {
  final List<InputSource> inputAdapters;
  final ChunkingStrategy chunkingStrategy;
  final EmbeddingProvider embeddingProvider;
  final VectorStore vectorStore;
  final obx.Box<Material> materialBox;

  MaterialProcessor({
    required this.inputAdapters,
    required this.chunkingStrategy,
    required this.embeddingProvider,
    required this.vectorStore,
    required this.materialBox,
  });

  /// Process a new material with chunking in background isolate
  Stream<ProcessingProgress> process(MaterialInput input) async* {
    AppLogger.info(
      '🎯 Starting material processing: "${input.title}" (${input.sourceType})',
    );
    Material? material;

    try {
      // Create material entity
      material = Material(
        title: input.title,
        sourceType: input.sourceType,
        subject: input.subject,
        gradeLevel: input.gradeLevel,
        status: 'processing',
      );

      final materialId = materialBox.put(material);
      material.id = materialId;

      AppLogger.debug('✅ Material entity created (ID: $materialId)');

      yield ProcessingProgress(
        progress: 0.05,
        stage: 'created',
        message: 'Material created',
        material: material,
      );

      // Find appropriate input adapter
      InputSource? adapter;
      for (final a in inputAdapters) {
        if (a.sourceType == input.sourceType) {
          adapter = a;
          break;
        }
      }

      if (adapter == null) {
        throw ProcessingException(
          'No adapter found for source type: ${input.sourceType}',
        );
      }

      // Extract content
      yield ProcessingProgress(
        progress: 0.1,
        stage: 'extracting',
        message: 'Extracting content...',
        material: material,
      );

      // INCREMENTAL PROCESSING: Process and store batches as they arrive
      final textBuffer = StringBuffer();
      int totalChunksProcessed = 0;
      int sequenceIndex = 0;

      await for (final extractProgress in adapter.extractContent(
        input.content,
      )) {
        if (extractProgress.error != null) {
          material.status = 'failed';
          material.errorMessage = extractProgress.error;
          materialBox.put(material);

          yield ProcessingProgress(
            progress: 0,
            stage: 'extraction_failed',
            error: extractProgress.error,
            material: material,
          );
          return;
        }

        // Map extraction progress to 0.1-0.3
        yield ProcessingProgress(
          progress: 0.1 + (extractProgress.progress * 0.2),
          stage: 'extracting',
          message: extractProgress.currentPage ?? 'Extracting...',
          material: material,
        );

        // Process batch of extracted text immediately
        if (extractProgress.extractedText != null &&
            extractProgress.extractedText!.trim().isNotEmpty) {
          final batchText = extractProgress.extractedText!;
          textBuffer.write(batchText);

          AppLogger.debug('🔪 Chunking batch (${batchText.length} chars)');

          // Chunk this batch (no longer in isolate - need async token counting)
          final batchChunkResults = await chunkingStrategy.chunk(batchText, {
            'sourceType': input.sourceType,
            'subject': input.subject,
          });

          AppLogger.debug(
            '✅ Got ${batchChunkResults.length} chunks from batch',
          );

          // Generate embeddings for this batch in smaller groups
          if (batchChunkResults.isNotEmpty) {
            // Process in smaller batches for better UX and stability
            final texts = batchChunkResults.map((r) => r.content).toList();

            for (
              int i = 0;
              i < texts.length;
              i += AppConstants.embeddingBatchSize
            ) {
              final end = (i + AppConstants.embeddingBatchSize < texts.length)
                  ? i + AppConstants.embeddingBatchSize
                  : texts.length;
              final batchTexts = texts.sublist(i, end);
              final batchNum = (i ~/ AppConstants.embeddingBatchSize) + 1;
              final totalBatches =
                  (texts.length / AppConstants.embeddingBatchSize).ceil();

              // Update progress before embedding
              yield ProcessingProgress(
                progress: 0.3 + (extractProgress.progress * 0.2),
                stage: 'embedding',
                message:
                    'Embedding batch $batchNum/$totalBatches (${batchTexts.length} chunks)...',
                material: material,
              );

              AppLogger.debug(
                '🔢 Embedding batch $batchNum/$totalBatches: '
                '${batchTexts.length} chunks [${i + 1}-$end/${texts.length}]',
              );

              final batchEmbeddings = await embeddingProvider.embedBatch(
                batchTexts,
              );

              // Create and store chunk entities immediately (free memory)
              final chunksToStore = <Chunk>[];
              for (var j = 0; j < batchTexts.length; j++) {
                final chunkResult = batchChunkResults[i + j];
                final embedding = batchEmbeddings[j];

                final chunk = Chunk(
                  content: chunkResult.content,
                  embedding: embedding,
                  pageNumber: chunkResult.pageNumber,
                  sectionIndex: chunkResult.sectionIndex,
                  sequenceIndex: sequenceIndex++,
                  chunkType: chunkResult.chunkType,
                  metadataJson: chunkResult.metadata.toString(),
                );

                chunk.material.target = material;
                chunksToStore.add(chunk);
              }

              // Store immediately after each batch (better memory management)
              AppLogger.debug(
                '💾 Storing ${chunksToStore.length} chunks from batch $batchNum',
              );
              await vectorStore.storeBatch(chunksToStore);

              totalChunksProcessed += chunksToStore.length;

              // Update progress after storing
              yield ProcessingProgress(
                progress: 0.3 + (extractProgress.progress * 0.2),
                stage: 'embedding',
                message:
                    'Stored batch $batchNum/$totalBatches (${totalChunksProcessed} total chunks)',
                material: material,
              );
            }
          }
        }
      }

      // Validate we got some content
      if (totalChunksProcessed == 0) {
        material.status = 'failed';
        material.errorMessage = 'No content extracted';
        materialBox.put(material);

        yield ProcessingProgress(
          progress: 0,
          stage: 'extraction_failed',
          error: 'No content could be extracted from the material',
          material: material,
        );
        return;
      }

      AppLogger.info(
        '✅ Total chunks processed and stored: $totalChunksProcessed',
      );

      // All chunks already stored incrementally per-batch above

      // Update material with final count
      material.status = 'completed';
      material.processedAt = DateTime.now();
      material.chunkCount = totalChunksProcessed;
      materialBox.put(material);

      AppLogger.info(
        '🎉 Material processing completed: "${material.title}" ($totalChunksProcessed chunks)',
      );

      yield ProcessingProgress(
        progress: 1.0,
        stage: 'completed',
        message: 'Processed $totalChunksProcessed chunks',
        isComplete: true,
        result: material,
        material: material,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Material processing failed: "${input.title}"',
        e,
        stackTrace,
      );

      if (material != null) {
        material.status = 'failed';
        material.errorMessage = e.toString();
        materialBox.put(material);
        AppLogger.debug(
          'Material status updated to failed (ID: ${material.id})',
        );
      }

      yield ProcessingProgress(
        progress: 0,
        stage: 'failed',
        error: 'Processing failed: $e',
        material: material,
      );
    }
  }

  /// Reprocess a failed material
  Stream<ProcessingProgress> reprocess(int materialId) async* {
    try {
      final material = materialBox.get(materialId);
      if (material == null) {
        yield ProcessingProgress(
          progress: 0,
          stage: 'failed',
          error: 'Material not found',
        );
        return;
      }

      // Delete existing chunks
      await vectorStore.deleteByMaterial(materialId);

      // Reprocess with original path
      if (material.originalFilePath != null) {
        final input = MaterialInput(
          title: material.title,
          sourceType: material.sourceType,
          content: material.originalFilePath,
          subject: material.subject,
          gradeLevel: material.gradeLevel,
        );

        await for (final progress in process(input)) {
          yield progress;
        }
      } else {
        yield ProcessingProgress(
          progress: 0,
          stage: 'failed',
          error: 'Original file path not available',
        );
      }
    } catch (e) {
      yield ProcessingProgress(
        progress: 0,
        stage: 'failed',
        error: 'Reprocess failed: $e',
      );
    }
  }

  /// Delete material and its chunks
  Future<Either<Failure, Unit>> deleteMaterial(int materialId) async {
    try {
      // Delete chunks
      await vectorStore.deleteByMaterial(materialId);

      // Delete material
      final removed = materialBox.remove(materialId);
      if (!removed) {
        return Left(StorageFailure('Material not found'));
      }

      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure('Failed to delete material: $e'));
    }
  }
}

/// Input for material processing
class MaterialInput {
  final String title;
  final String sourceType;
  final dynamic content; // File path, bytes, etc.
  final String? subject;
  final int? gradeLevel;

  MaterialInput({
    required this.title,
    required this.sourceType,
    required this.content,
    this.subject,
    this.gradeLevel,
  });
}

/// Progress update during processing
class ProcessingProgress {
  final double progress; // 0.0 to 1.0
  final String stage; // 'extracting', 'chunking', 'embedding', 'storing', etc.
  final String? message;
  final bool isComplete;
  final Material? result;
  final Material? material;
  final String? error;

  ProcessingProgress({
    required this.progress,
    required this.stage,
    this.message,
    this.isComplete = false,
    this.result,
    this.material,
    this.error,
  });
}
