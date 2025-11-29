/// Application-wide constants
class AppConstants {
  AppConstants._();

  // AI Model Configuration (bundled assets)
  // EmbeddingGemma-300M (768-dimensional embeddings)
  // From: litert-community/embeddinggemma-300m (PUBLIC - no auth needed)
  static const String embeddingModelAsset =
      'assets/models/embeddinggemma-300M_seq512_mixed-precision.tflite';
  static const String embeddingTokenizerAsset =
      'assets/models/sentencepiece.model';
  
  // Gemma 3 Nano E2B (multimodal - text + vision)  
  // From: google/gemma-3n-E2B-it-litert-preview (gated - needs access request)
  static const String inferenceModelAsset =
      'assets/models/gemma-3n-E2B-it-int4.task';

  static const int embeddingDimension = 768;
  static const int maxInferenceTokens = 2048;

  // Chunking Configuration
  static const int targetChunkSizeTokens = 350;
  static const int chunkOverlapTokens = 50;
  static const int maxChunkSizeTokens = 500;

  // RAG Configuration
  static const int retrievalTopK = 5;
  static const double similarityThreshold = 0.5;
  static const int maxContextTokens = 2000;

  // Conversation Configuration
  static const int maxContextMessages = 6;

  // File Size Limits
  static const int maxPdfSizeMb = 50;
  static const int maxImageSizeMb = 10;
  static const int maxPdfPages = 100;

  // Storage Requirements
  static const int minRequiredStorageGb = 6;
  static const int embeddingModelSizeMb = 300;
  static const int inferenceModelSizeGb = 4;

  // UI Constants
  static const int messageAnimationDurationMs = 300;
}

