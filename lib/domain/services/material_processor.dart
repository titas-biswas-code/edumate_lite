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

  /// Process a new material
  Stream<ProcessingProgress> process(MaterialInput input) async* {
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

      String? extractedText;
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

        if (extractProgress.extractedText != null) {
          extractedText = extractProgress.extractedText;
        }

        // Map extraction progress to 0.1-0.3
        yield ProcessingProgress(
          progress: 0.1 + (extractProgress.progress * 0.2),
          stage: 'extracting',
          message: extractProgress.currentPage ?? 'Extracting...',
          material: material,
        );
      }

      if (extractedText == null || extractedText.trim().isEmpty) {
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

      // Chunk content
      yield ProcessingProgress(
        progress: 0.3,
        stage: 'chunking',
        message: 'Chunking content...',
        material: material,
      );

      final chunkResults = await chunkingStrategy.chunk(extractedText, {
        'sourceType': input.sourceType,
        'subject': input.subject,
      });

      if (chunkResults.isEmpty) {
        material.status = 'failed';
        material.errorMessage = 'No chunks generated';
        materialBox.put(material);

        yield ProcessingProgress(
          progress: 0,
          stage: 'chunking_failed',
          error: 'Failed to chunk content',
          material: material,
        );
        return;
      }

      yield ProcessingProgress(
        progress: 0.4,
        stage: 'chunking',
        message: 'Created ${chunkResults.length} chunks',
        material: material,
      );

      // Generate embeddings in batch (more efficient)
      yield ProcessingProgress(
        progress: 0.4,
        stage: 'embedding',
        message: 'Generating embeddings for ${chunkResults.length} chunks...',
        material: material,
      );

      // Extract all texts for batch processing
      final texts = chunkResults.map((r) => r.content).toList();

      // Generate all embeddings in batch
      // Note: This still runs on main thread but is more efficient than individual calls
      final embeddings = await embeddingProvider.embedBatch(texts);

      yield ProcessingProgress(
        progress: 0.7,
        stage: 'embedding',
        message: 'Creating chunks...',
        material: material,
      );

      // Create chunk entities with embeddings
      final chunks = <Chunk>[];
      for (var i = 0; i < chunkResults.length; i++) {
        final chunkResult = chunkResults[i];
        final embedding = embeddings[i];

        final chunk = Chunk(
          content: chunkResult.content,
          embedding: embedding,
          pageNumber: chunkResult.pageNumber,
          sectionIndex: chunkResult.sectionIndex,
          sequenceIndex: i,
          chunkType: chunkResult.chunkType,
          metadataJson: chunkResult.metadata.toString(),
        );

        chunk.material.target = material;
        chunks.add(chunk);
      }

      // Store chunks in vector store (batch)
      yield ProcessingProgress(
        progress: 0.8,
        stage: 'storing',
        message: 'Storing chunks...',
        material: material,
      );

      await vectorStore.storeBatch(chunks);

      // Update material
      material.status = 'completed';
      material.processedAt = DateTime.now();
      material.chunkCount = chunks.length;
      materialBox.put(material);

      yield ProcessingProgress(
        progress: 1.0,
        stage: 'completed',
        message: 'Processing complete',
        isComplete: true,
        result: material,
        material: material,
      );
    } catch (e) {
      if (material != null) {
        material.status = 'failed';
        material.errorMessage = e.toString();
        materialBox.put(material);
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
