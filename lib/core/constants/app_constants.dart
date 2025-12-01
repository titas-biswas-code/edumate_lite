/// Application-wide constants
class AppConstants {
  AppConstants._();

  // AI Model Configuration (bundled assets)
  // EmbeddingGemma-300M (768-dimensional embeddings, 2048 token context)
  // From: litert-community/embeddinggemma-300m (PUBLIC - no auth needed)
  static const String embeddingModelAsset =
      'assets/models/embeddinggemma-300M_seq2048_mixed-precision.tflite';
  static const String embeddingTokenizerAsset =
      'assets/models/sentencepiece.model';
  
  // Gemma 3 Nano E2B (multimodal - text + vision)  
  // From: google/gemma-3n-E2B-it-litert-preview (gated - needs access request)
  static const String inferenceModelAsset =
      'assets/models/gemma-3n-E2B-it-int4.task';

  static const int embeddingDimension = 768;
  static const int maxEmbeddingTokens = 2048; // EmbeddingGemma supports 2048 tokens
  static const int maxInferenceTokens = 2048;

  // Chunking Configuration (optimized for 2048-token embeddings)
  // WORD-BASED LIMITS (no estimation - direct and reliable)
  // Model: 2048 tokens | Prompt: ~15 tokens | Safety buffer: ~200 tokens
  // Available: ~1833 tokens | Worst case ratio: 4x tokens/word
  // Safe max: 1833 / 4 = 458 words → use 400 for safety
  static const int targetChunkWords = 350; // Target: 350 words (conservative)
  static const int maxChunkWords = 450; // Hard limit: 450 words (450*4 = 1800 tokens worst case)
  static const int chunkOverlapWords = 40; // Overlap: 40 words
  
  // Legacy token-based (keep for backward compatibility)
  static const int targetChunkSizeTokens = targetChunkWords * 3;
  static const int chunkOverlapTokens = chunkOverlapWords * 3;
  static const int maxChunkSizeTokens = maxChunkWords * 3;

  // RAG Configuration
  static const int retrievalTopK = 5;
  static const double similarityThreshold = 0.5;
  static const int maxContextTokens = 2000;

  // Conversation Configuration
  static const int maxContextMessages = 6;

  // File Size Limits
  static const int maxPdfSizeMb = 500; // Increased for textbooks
  static const int maxImageSizeMb = 10;
  static const int maxPdfPages = 3000; // Support full textbooks
  
  // Streaming Processing Configuration
  static const int pdfPageBatchSize = 10; // Process 10 pages at a time
  static const int embeddingBatchSize = 20; // Embed 20 chunks at a time
  static const int storageBatchSize = 50; // Store 50 chunks at a time

  // Storage Requirements
  static const int minRequiredStorageGb = 6;
  static const int embeddingModelSizeMb = 300;
  static const int inferenceModelSizeGb = 4;

  // UI Constants
  static const int messageAnimationDurationMs = 300;
}

