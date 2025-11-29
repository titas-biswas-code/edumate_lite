import 'package:dartz/dartz.dart';
import '../interfaces/embedding_provider.dart';
import '../interfaces/inference_provider.dart';
import '../../core/errors/failures.dart';

/// Service to initialize AI providers after models are loaded
class AiInitializationService {
  final EmbeddingProvider embeddingProvider;
  final InferenceProvider inferenceProvider;

  AiInitializationService({
    required this.embeddingProvider,
    required this.inferenceProvider,
  });

  /// Initialize both AI providers
  Future<Either<Failure, Unit>> initializeProviders() async {
    try {
      // Initialize embedding provider
      await embeddingProvider.initialize();

      // Initialize inference provider
      await inferenceProvider.initialize();

      return const Right(unit);
    } catch (e) {
      return Left(ModelFailure('Failed to initialize AI providers: $e'));
    }
  }

  /// Check if both providers are ready
  bool get areProvidersReady =>
      embeddingProvider.isReady && inferenceProvider.isReady;
}

