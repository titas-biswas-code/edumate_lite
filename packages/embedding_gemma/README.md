# embedding_gemma

On-device text embeddings using **EmbeddingGemma-300M** (768 dimensions, 2048 token context) with Google's RAG library.

## Installation

```yaml
dependencies:
  embedding_gemma:
    path: packages/embedding_gemma
```

## Usage (flutter_gemma pattern)

### 1. Install Model (One-Time Setup)

```dart
import 'package:embedding_gemma/embedding_gemma.dart';

// Install from bundled assets (like flutter_gemma's installModel())
await EmbeddingGemma.installModel()
  .modelFromAsset('assets/models/embeddinggemma-300M_seq2048_mixed-precision.tflite')
  .tokenizerFromAsset('assets/models/sentencepiece.model')
  .withProgress((progress) {
    print('Installing: ${(progress * 100).toInt()}%');
  })
  .install();
```

### 2. Use Active Model (Like flutter_gemma's getActiveModel())

```dart
// Get the installed model
final embedder = await EmbeddingGemma.getActiveModel(
  backend: EmbeddingBackend.GPU,
);

// Generate embeddings
final docEmbedding = await embedder.embed('Your document text');
final queryEmbedding = await embedder.embedQuery('Your search query');

// Batch processing
final embeddings = await embedder.embedBatch(['Doc 1', 'Doc 2', 'Doc 3']);

// Clean up
embedder.dispose();
```

### 3. Check if Model is Installed

```dart
if (await EmbeddingGemma.hasActiveModel()) {
  // Model is ready
  final embedder = await EmbeddingGemma.getActiveModel();
} else {
  // Install model first
  await EmbeddingGemma.installModel()
    .modelFromAsset(...)
    .tokenizerFromAsset(...)
    .install();
}
```

## Integration Example (Your App Pattern)

```dart
// In model_download_service.dart
Future<Either<Failure, Unit>> loadEmbeddingModel() async {
  try {
    downloadStore.setEmbeddingStatus(ModelDownloadStatus.downloading);
    
    // Install using fluent API (same pattern as flutter_gemma)
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
    return Left(StorageFailure('Failed to load embedding model: $e'));
  }
}

// In gemma_embedding_provider.dart
@override
Future<void> initialize() async {
  // Get active model (like flutter_gemma)
  _embeddingModel = await EmbeddingGemma.getActiveModel(
    backend: EmbeddingBackend.GPU,
  );
  _isReady = true;
}
```

## API Reference

### EmbeddingBackend

```dart
enum EmbeddingBackend {
  CPU,           // CPU with multi-threading
  GPU,           // GPU acceleration (default)
  GPU_FLOAT16,   // GPU with reduced precision
  GPU_MIXED,     // Mixed precision
}
```

### Task Prompting

Automatic task-specific prompting (per Google's EmbeddingGemma spec):

- **Documents**: `"title: none | text: {text}"`
- **Queries**: `"task: search result | query: {text}"`

## Architecture

```
App calls:
  EmbeddingGemma.installModel()
    .modelFromAsset(...)
    .tokenizerFromAsset(...)
    .install()
        ↓
  Copies assets to app documents directory
  Saves paths to SharedPreferences
        ↓
  EmbeddingGemma.getActiveModel()
        ↓
  Loads from saved paths
  Uses Google's GemmaEmbeddingModel (RAG library)
        ↓
  embedder.embed(...) / embedQuery(...)
        ↓
  Returns 768-dim normalized vectors
```

## Performance

- **Installation**: ~10-30s (one-time, 187MB model)
- **Initialization**: ~50-150ms
- **Single embedding**: ~50-150ms (GPU) / ~200-500ms (CPU)
- **Batch**: Processed sequentially

## Platform Support

- **Android**: minSdk 26, TFLite with GPU delegate
- **iOS**: iOS 12.0+, TFLite with Metal delegate

## License

MIT
