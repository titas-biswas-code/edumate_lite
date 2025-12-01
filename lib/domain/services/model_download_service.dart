import 'package:dartz/dartz.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:embedding_gemma/embedding_gemma.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/app_constants.dart';
import '../../stores/model_download_store.dart';

/// Service to load AI models from bundled assets
/// Models are pre-downloaded and packaged with the app
class ModelDownloadService {
  final ModelDownloadStore downloadStore;

  ModelDownloadService(this.downloadStore);

  /// Load embedding model from bundled assets (flutter_gemma pattern)
  Future<Either<Failure, Unit>> loadEmbeddingModel() async {
    try {
      downloadStore.setEmbeddingStatus(ModelDownloadStatus.downloading);
      downloadStore.setEmbeddingProgress(0.0);

      // Install embedding model using builder pattern (same as flutter_gemma)
      await EmbeddingGemma.installModel()
          .modelFromAsset(AppConstants.embeddingModelAsset)
          .tokenizerFromAsset(AppConstants.embeddingTokenizerAsset)
          .withProgress((progress) {
            Future.microtask(() {
              downloadStore.setEmbeddingProgress(progress);
            });
          })
          .install();

      downloadStore.setEmbeddingStatus(ModelDownloadStatus.completed);
      return const Right(unit);
    } catch (e) {
      downloadStore.setEmbeddingStatus(ModelDownloadStatus.failed);
      downloadStore.setEmbeddingError(e.toString());
      return Left(StorageFailure('Failed to load embedding model: $e'));
    }
  }

  /// Load inference model from bundled assets (async - non-blocking)
  Future<Either<Failure, Unit>> loadInferenceModel() async {
    try {
      downloadStore.setInferenceStatus(ModelDownloadStatus.downloading);
      downloadStore.setInferenceProgress(0.0);

      // Install inference model from bundled assets
      // This runs asynchronously and won't block UI
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      )
          .fromAsset(AppConstants.inferenceModelAsset)
          .withProgress((progress) {
            // Update progress - this callback runs on different thread
            Future.microtask(() {
              downloadStore.setInferenceProgress(progress / 100);
            });
          })
          .install();

      downloadStore.setInferenceStatus(ModelDownloadStatus.completed);
      return const Right(unit);
    } catch (e) {
      downloadStore.setInferenceStatus(ModelDownloadStatus.failed);
      downloadStore.setInferenceError(e.toString());
      return Left(StorageFailure('Failed to load inference model: $e'));
    }
  }

  /// Check if models are already downloaded
  Future<bool> checkModelsDownloaded() async {
    try {
      // Check if embedding model is installed (same pattern as flutter_gemma)
      final hasEmbedding = await EmbeddingGemma.hasActiveModel();
      
      // Check if inference model exists in flutter_gemma registry
      final hasInference = FlutterGemma.hasActiveModel();

      if (hasEmbedding) {
        downloadStore.setEmbeddingStatus(ModelDownloadStatus.completed);
      }

      if (hasInference) {
        downloadStore.setInferenceStatus(ModelDownloadStatus.completed);
      }

      return hasEmbedding && hasInference;
    } catch (e) {
      return false;
    }
  }

  /// Get list of all installed models
  Future<List<String>> getInstalledModels() async {
    try {
      return await FlutterGemma.listInstalledModels();
    } catch (e) {
      return [];
    }
  }

  /// Delete a model
  Future<Either<Failure, Unit>> deleteModel(String modelName) async {
    try {
      await FlutterGemma.uninstallModel(modelName);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure('Failed to delete model: $e'));
    }
  }
}



