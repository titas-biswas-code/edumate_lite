# EduMate Lite - Technical Design Document

**Version:** 1.1  
**Target:** MVP (V1)  
**Last Updated:** November 27, 2025

---

## 1. Executive Summary

### 1.1 Product Overview
EduMate Lite is an on-device AI-powered educational assistant targeting middle school students (grades 5-10) and their parents. The app provides instant explanations, generates practice quizzes, and answers questions based on user-provided educational materials.

### 1.2 Key Value Propositions
- **Privacy-First:** All AI processing happens on-device. No data leaves the phone.
- **Offline Capable:** Works without internet connection.
- **Zero API Costs:** No recurring cloud AI costs.
- **COPPA Friendly:** No child data collection concerns.

### 1.3 Core Features (MVP)
1. Import educational materials (PDF, images, camera capture)
2. Extract and chunk content for semantic search
3. Answer questions using RAG (Retrieval-Augmented Generation)
4. Generate practice quizzes from materials
5. Conversational follow-up within context

---

## 2. Technical Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  Home Screen │  │ Chat Screen  │  │  Materials Manager   │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        APPLICATION LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ ChatOrchest- │  │   Quiz       │  │    Material          │   │
│  │    rator     │  │  Generator   │  │    Processor         │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         DOMAIN LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │   RAG        │  │  Chunking    │  │   Conversation       │   │
│  │   Engine     │  │  Service     │  │   Manager            │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     INFRASTRUCTURE LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  ObjectBox   │  │  flutter_    │  │   Input Adapters     │   │
│  │  VectorStore │  │  gemma       │  │  (File/Camera/etc)   │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| UI Framework | Flutter | Cross-platform mobile |
| State Management | Riverpod | Reactive state, DI |
| Local Database | ObjectBox | Vector storage, metadata |
| AI Inference | flutter_gemma | On-device LLM |
| Embedding Model | EmbeddingGemma-300M | Text embeddings (768D) |
| Inference Model | Gemma 3 Nano E2B | Vision + Text generation |
|| PDF Processing | syncfusion_flutter_pdf | Text extraction |
| Image Processing | image | Image manipulation |
| Camera | camera | Photo capture |
| File Picker | file_picker | Document selection |

### 2.3 Model Specifications & Storage

| Component | Model/Version | Size | Download URL | Notes |
|-----------|---------------|------|--------------|-------|
| Embedding | EmbeddingGemma-300M | ~300MB | HuggingFace litert-community | 768-dim vectors |
| Inference | Gemma 3 Nano E2B int4 | ~3-4GB | HuggingFace google/gemma-3n-E2B-it | Multimodal support |
| Total Storage | First Install | ~3.5-4.5GB | - | Plus ~1GB for app + data |

**Model Download Strategy:**
- Download on first launch (onboarding flow)
- Show storage requirement before download
- Prompt for WiFi/cellular choice if >1GB
- Support pause/resume with exponential backoff
- Cache in app documents directory
- Validate with checksums/ETags

**Platform Minimums:**
- Android: API 21+ (tested on 15+)
- iOS: 16.0+ (MediaPipe requirement)
- Storage: 6GB free space recommended
- RAM: 6GB+ device RAM for smooth performance

### 2.4 Background Processing Architecture

**Isolate Strategy:**
All heavy operations run in isolates to prevent UI blocking:

```dart
// Heavy operations requiring isolates:
1. PDF text extraction (>10 pages)
2. Batch embedding generation
3. Text chunking for large documents
4. Model initialization
5. Vector search (if >10K chunks)
```

**Implementation Pattern:**
```dart
// Use Riverpod + compute for isolate execution
Future<List<Chunk>> _chunkInIsolate(String text) async {
  return await compute(_chunkingTask, text);
}

static List<Chunk> _chunkingTask(String text) {
  // Heavy chunking logic runs in isolate
  return chunks;
}
```

**Progress Reporting:**
- Use SendPort for progress updates from isolates
- Stream progress to UI via Riverpod StateNotifier
- Cancel support via ReceivePort

### 2.5 Token Estimation Utility

```dart
// ===========================================================
// FILE: lib/core/utils/token_estimator.dart
// ===========================================================

/// Accurate token estimation for Gemma models
/// Based on SentencePiece tokenizer characteristics
class TokenEstimator {
  /// Estimate tokens from text
  /// Uses empirical formula: words * 1.3 + punctuation * 0.5
  static int estimate(String text) {
    final words = text.split(RegExp(r'\s+')).length;
    final punctuation = RegExp(r'[.,!?;:\-(){}[\]"\'`]').allMatches(text).length;
    return (words * 1.3 + punctuation * 0.5).ceil();
  }
  
  /// Check if text fits within token limit
  static bool fitsInLimit(String text, int limit) {
    return estimate(text) <= limit;
  }
  
  /// Truncate text to fit token limit (approximate)
  static String truncateToLimit(String text, int limit) {
    final estimated = estimate(text);
    if (estimated <= limit) return text;
    
    final ratio = limit / estimated;
    final targetLength = (text.length * ratio * 0.95).toInt();
    return text.substring(0, targetLength);
  }
}
```

### 2.6 Model Management State Machine

```dart
// ===========================================================
// FILE: lib/domain/entities/model_state.dart
// ===========================================================

enum ModelStatus {
  notDownloaded,
  downloading,
  paused,
  downloadFailed,
  downloaded,
  initializing,
  initFailed,
  ready,
}

class ModelState {
  final ModelStatus status;
  final double downloadProgress; // 0.0 - 1.0
  final String? errorMessage;
  final int? bytesDownloaded;
  final int? totalBytes;
  
  // State transitions
  bool get canDownload => status == ModelStatus.notDownloaded || 
                          status == ModelStatus.downloadFailed;
  bool get canPause => status == ModelStatus.downloading;
  bool get canResume => status == ModelStatus.paused;
  bool get canInitialize => status == ModelStatus.downloaded;
  bool get isReady => status == ModelStatus.ready;
}
```

**Model Download UI Flow:**
1. Check storage availability
2. Show size warning + WiFi/cellular choice
3. Start download with progress bar
4. Support pause/resume/cancel
5. Auto-initialize after download
6. Show error with retry on failure

### 2.7 Handling "No Context Found" in RAG

**Strategy when vector search returns no relevant chunks:**

```dart
// In RagEngine.answer()
if (retrievedChunks.isEmpty || retrievedChunks.first.score < threshold) {
  yield RagResponse(
    content: '''I don't have enough information in your study materials to answer this question accurately.

Possible reasons:
- This topic hasn't been uploaded yet
- Try rephrasing your question
- Upload relevant materials for this topic

Would you like me to:
1. Suggest what materials to upload
2. Try answering from general knowledge (less accurate)
3. Rephrase and search again''',
    isComplete: true,
    confidenceScore: 0.0,
  );
  return;
}

// Low confidence (score 0.5-0.7)
if (retrievedChunks.first.score < 0.7) {
  // Prefix response with confidence warning
  yield RagResponse(
    content: "⚠️ I found some related content, but I'm not very confident. Here's what I found:\n\n",
    isComplete: false,
    confidenceScore: retrievedChunks.first.score,
  );
}
```

### 2.8 UI/UX Design Guidelines

**Design System:**
- Material Design 3 (Material You)
- Dynamic color theming
- Dark/Light mode support
- Smooth animations (300ms standard)

**Key Screens:**
1. **Onboarding:** Model download + permissions
2. **Home:** Quick actions (Ask Question, Add Material, Recent Chats)
3. **Chat:** Message bubbles, source cards, typing indicators
4. **Materials Library:** Grid/List toggle, filter by subject
5. **Add Material:** Multi-tab (PDF/Image/Camera)

**Animation Guidelines:**
- Message appearance: Slide up + fade (300ms)
- Loading states: Shimmer effects
- Progress bars: Smooth interpolation
- Page transitions: Shared element transitions

**Accessibility:**
- Min touch target: 48x48dp
- Screen reader support
- High contrast mode
- Scalable fonts (respect system settings)

---

## 3. Data Models

### 3.1 Core Entities

```dart
// ===========================================================
// FILE: lib/domain/entities/material.dart
// ===========================================================

/// Represents an uploaded educational material
@Entity()
class Material {
  @Id()
  int id = 0;
  
  String title;
  String? description;
  
  /// Original file path (for reference, file may be deleted)
  String? originalFilePath;
  
  /// Source type: 'pdf', 'image', 'camera', 'text'
  String sourceType;
  
  /// Subject tag: 'math', 'science', 'history', 'english', 'other'
  String? subject;
  
  /// Grade level: 5-10
  int? gradeLevel;
  
  /// Processing status: 'pending', 'processing', 'completed', 'failed'
  String status;
  
  /// Error message if processing failed
  String? errorMessage;
  
  /// Timestamps
  @Property(type: PropertyType.date)
  DateTime createdAt;
  
  @Property(type: PropertyType.date)
  DateTime? processedAt;
  
  /// Total chunks generated from this material
  int chunkCount;
  
  Material({
    required this.title,
    this.description,
    this.originalFilePath,
    required this.sourceType,
    this.subject,
    this.gradeLevel,
    this.status = 'pending',
    this.errorMessage,
    DateTime? createdAt,
    this.processedAt,
    this.chunkCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();
}
```

```dart
// ===========================================================
// FILE: lib/domain/entities/chunk.dart
// ===========================================================

/// Represents a chunk of text extracted from a material
@Entity()
class Chunk {
  @Id()
  int id = 0;
  
  /// Reference to parent material
  final material = ToOne<Material>();
  
  /// The actual text content
  String content;
  
  /// Vector embedding for HNSW search
  @HnswIndex(dimensions: 768, neighborsPerNode: 30, indexingSearchCount: 200)
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;
  
  /// Position in original document (page number, section, etc.)
  int? pageNumber;
  int? sectionIndex;
  
  /// Chunk sequence within the material
  int sequenceIndex;
  
  /// Chunk type: 'paragraph', 'heading', 'list', 'table', 'equation'
  String chunkType;
  
  /// Word count for filtering
  int wordCount;
  
  /// Metadata as JSON string
  String? metadataJson;
  
  Chunk({
    required this.content,
    this.embedding,
    this.pageNumber,
    this.sectionIndex,
    required this.sequenceIndex,
    this.chunkType = 'paragraph',
    int? wordCount,
    this.metadataJson,
  }) : wordCount = wordCount ?? content.split(' ').length;
}
```

```dart
// ===========================================================
// FILE: lib/domain/entities/conversation.dart
// ===========================================================

/// Represents a conversation session
@Entity()
class Conversation {
  @Id()
  int id = 0;
  
  String title;
  
  /// Optional link to specific material context
  final material = ToOne<Material>();
  
  @Property(type: PropertyType.date)
  DateTime createdAt;
  
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  
  /// Number of messages in conversation
  int messageCount;
  
  Conversation({
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.messageCount = 0,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
}
```

```dart
// ===========================================================
// FILE: lib/domain/entities/message.dart
// ===========================================================

/// Represents a single message in a conversation
@Entity()
class Message {
  @Id()
  int id = 0;
  
  /// Reference to parent conversation
  final conversation = ToOne<Conversation>();
  
  /// Message role: 'user', 'assistant', 'system'
  String role;
  
  /// Message content
  String content;
  
  /// Retrieved chunk IDs used for this response (JSON array)
  String? retrievedChunkIds;
  
  /// Confidence score of the response (0.0 - 1.0)
  double? confidenceScore;
  
  @Property(type: PropertyType.date)
  DateTime timestamp;
  
  /// Sequence in conversation
  int sequenceIndex;
  
  Message({
    required this.role,
    required this.content,
    this.retrievedChunkIds,
    this.confidenceScore,
    DateTime? timestamp,
    required this.sequenceIndex,
  }) : timestamp = timestamp ?? DateTime.now();
}
```

### 3.2 ObjectBox Vector Index Configuration

```dart
// ===========================================================
// FILE: lib/infrastructure/database/objectbox_config.dart
// ===========================================================

/// ObjectBox configuration with HNSW vector index
/// 
/// IMPLEMENTATION NOTES:
/// - ObjectBox supports HNSW index for vector similarity search
/// - EmbeddingGemma produces 768-dimensional vectors
/// - Use @HnswIndex annotation on embedding field

// In Chunk entity, add annotation:
// @HnswIndex(dimensions: 768, neighborsPerNode: 30, indexingSearchCount: 200)
// @Property(type: PropertyType.floatVector)
// List<double>? embedding;

// Query example:
// final query = box.query(Chunk_.embedding.nearestNeighborsF32(queryVector, 10)).build();
// final results = query.findWithScores();
```

---

## 4. Interface Definitions

### 4.1 Input Source Interface

```dart
// ===========================================================
// FILE: lib/domain/interfaces/input_source.dart
// ===========================================================

/// Abstract interface for all input sources
/// Implement this to add new input methods (e.g., URL, audio, handwriting)
abstract class InputSource {
  /// Unique identifier for this input type
  String get sourceType;
  
  /// Human-readable name
  String get displayName;
  
  /// Supported file extensions (empty for non-file sources)
  List<String> get supportedExtensions;
  
  /// Check if this source can handle the given input
  bool canHandle(dynamic input);
  
  /// Extract raw text content from the input
  /// Returns a stream for progress updates on large files
  Stream<ExtractionProgress> extractContent(dynamic input);
  
  /// Get metadata about the input (page count, dimensions, etc.)
  Future<Map<String, dynamic>> getMetadata(dynamic input);
}

/// Progress update during content extraction
class ExtractionProgress {
  final double progress; // 0.0 to 1.0
  final String? currentPage;
  final String? extractedText;
  final bool isComplete;
  final String? error;
  
  ExtractionProgress({
    required this.progress,
    this.currentPage,
    this.extractedText,
    this.isComplete = false,
    this.error,
  });
}
```

### 4.2 Chunking Strategy Interface

```dart
// ===========================================================
// FILE: lib/domain/interfaces/chunking_strategy.dart
// ===========================================================

/// Abstract interface for chunking strategies
/// Implement this to add domain-specific chunking logic
abstract class ChunkingStrategy {
  /// Strategy identifier
  String get strategyId;
  
  /// Chunk the given text into semantic units
  /// 
  /// [text] - Raw text to chunk
  /// [metadata] - Additional context (source type, subject, etc.)
  /// 
  /// Returns list of ChunkResult with text and metadata
  Future<List<ChunkResult>> chunk(String text, Map<String, dynamic> metadata);
  
  /// Optimal chunk size for this strategy (in tokens, approximate)
  int get targetChunkSize;
  
  /// Overlap between chunks (in tokens, approximate)
  int get chunkOverlap;
}

/// Result of chunking operation
class ChunkResult {
  final String content;
  final String chunkType;
  final int? pageNumber;
  final int? sectionIndex;
  final Map<String, dynamic> metadata;
  
  ChunkResult({
    required this.content,
    required this.chunkType,
    this.pageNumber,
    this.sectionIndex,
    this.metadata = const {},
  });
}
```

### 4.3 Embedding Provider Interface

```dart
// ===========================================================
// FILE: lib/domain/interfaces/embedding_provider.dart
// ===========================================================

/// Abstract interface for embedding generation
/// Allows swapping embedding models without changing business logic
abstract class EmbeddingProvider {
  /// Model identifier
  String get modelId;
  
  /// Embedding dimension
  int get dimension;
  
  /// Initialize the embedding model
  Future<void> initialize();
  
  /// Generate embedding for a single text
  Future<List<double>> embed(String text);
  
  /// Generate embeddings for multiple texts (batch processing)
  Future<List<List<double>>> embedBatch(List<String> texts);
  
  /// Check if model is ready
  bool get isReady;
  
  /// Cleanup resources
  Future<void> dispose();
}
```

### 4.4 Vector Store Interface

```dart
// ===========================================================
// FILE: lib/domain/interfaces/vector_store.dart
// ===========================================================

/// Abstract interface for vector storage and retrieval
/// ObjectBox implementation provided, but can swap to others
abstract class VectorStore {
  /// Store a chunk with its embedding
  Future<int> store(Chunk chunk);
  
  /// Store multiple chunks (batch)
  Future<List<int>> storeBatch(List<Chunk> chunks);
  
  /// Search for similar chunks
  /// 
  /// [queryEmbedding] - Vector to search for
  /// [topK] - Number of results to return
  /// [threshold] - Minimum similarity score (0.0 - 1.0)
  /// [materialIds] - Optional filter by material IDs
  Future<List<ScoredChunk>> search(
    List<double> queryEmbedding, {
    int topK = 5,
    double threshold = 0.5,
    List<int>? materialIds,
  });
  
  /// Delete chunks by material ID
  Future<void> deleteByMaterial(int materialId);
  
  /// Get chunk by ID
  Future<Chunk?> getById(int id);
  
  /// Get all chunks for a material
  Future<List<Chunk>> getByMaterial(int materialId);
}

/// Chunk with similarity score
class ScoredChunk {
  final Chunk chunk;
  final double score;
  
  ScoredChunk({required this.chunk, required this.score});
}
```

### 4.5 Inference Provider Interface

```dart
// ===========================================================
// FILE: lib/domain/interfaces/inference_provider.dart
// ===========================================================

/// Abstract interface for LLM inference
/// Allows swapping models without changing business logic
abstract class InferenceProvider {
  /// Model identifier
  String get modelId;
  
  /// Initialize the inference model
  Future<void> initialize();
  
  /// Generate a response given context and query
  /// 
  /// [systemPrompt] - System instructions
  /// [context] - Retrieved context from RAG
  /// [query] - User's question
  /// [conversationHistory] - Previous messages for continuity
  Stream<String> generate({
    required String systemPrompt,
    required String context,
    required String query,
    List<Message>? conversationHistory,
  });
  
  /// Generate with image input (for camera captures)
  Stream<String> generateWithImage({
    required String systemPrompt,
    required Uint8List imageBytes,
    required String query,
  });
  
  /// Check if model is ready
  bool get isReady;
  
  /// Check if model supports vision
  bool get supportsVision;
  
  /// Cleanup resources
  Future<void> dispose();
}
```

### 4.6 Knowledge Source Interface (For V1.5+ Extensibility)

```dart
// ===========================================================
// FILE: lib/domain/interfaces/knowledge_source.dart
// ===========================================================

/// Abstract interface for knowledge sources
/// Enables adding external sources like Wikipedia in V1.5
abstract class KnowledgeSource {
  /// Source identifier
  String get sourceId;
  
  /// Human-readable name
  String get displayName;
  
  /// Whether this source requires internet
  bool get requiresNetwork;
  
  /// Retrieve relevant content for a query
  /// 
  /// [query] - User's question
  /// [context] - Additional context from local RAG
  /// [limit] - Maximum items to return
  Future<List<KnowledgeResult>> retrieve(
    String query, {
    String? context,
    int limit = 3,
  });
  
  /// Check if source is available
  Future<bool> isAvailable();
}

/// Result from a knowledge source
class KnowledgeResult {
  final String content;
  final String source;
  final String? url;
  final double? relevanceScore;
  final Map<String, dynamic> metadata;
  
  KnowledgeResult({
    required this.content,
    required this.source,
    this.url,
    this.relevanceScore,
    this.metadata = const {},
  });
}
```

---

## 5. Component Specifications

### 5.1 Input Adapters

#### 5.1.1 PDF Input Adapter

```dart
// ===========================================================
// FILE: lib/infrastructure/input/pdf_input_adapter.dart
// ===========================================================

/// PDF Input Adapter Implementation
/// 
/// DEPENDENCIES:
/// - syncfusion_flutter_pdf: ^27.1.48 (for PDF text extraction)
/// - path_provider: ^2.1.0 (for temp file handling)
/// 
/// IMPLEMENTATION STEPS:
/// 1. Load PDF document from file path
/// 2. Iterate through pages
/// 3. Extract text from each page
/// 4. Preserve page numbers in metadata
/// 5. Handle encrypted PDFs gracefully
/// 6. Stream progress updates
/// 
/// EDGE CASES:
/// - Scanned PDFs (image-only): Return empty text, flag for OCR
/// - Password protected: Return error with appropriate message
/// - Corrupted files: Catch exceptions, return partial content if possible
/// - Very large files (>50 pages): Process in batches, yield progress

class PdfInputAdapter implements InputSource {
  @override
  String get sourceType => 'pdf';
  
  @override
  String get displayName => 'PDF Document';
  
  @override
  List<String> get supportedExtensions => ['.pdf'];
  
  // ... implementation details in code
}
```

#### 5.1.2 Image Input Adapter

```dart
// ===========================================================
// FILE: lib/infrastructure/input/image_input_adapter.dart
// ===========================================================

/// Image Input Adapter Implementation
/// Uses Gemma 3 Nano vision for text extraction
/// 
/// DEPENDENCIES:
/// - flutter_gemma: ^x.x.x (for vision model)
/// - image: ^x.x.x (for image processing)
/// 
/// IMPLEMENTATION STEPS:
/// 1. Load image from file or camera bytes
/// 2. Resize if too large (max 1024px on longest edge)
/// 3. Convert to supported format (JPEG/PNG)
/// 4. Send to Gemma 3 Nano with extraction prompt
/// 5. Parse structured response
/// 
/// PROMPT FOR EXTRACTION:
/// "Extract all text from this image. Preserve the structure including:
/// - Headings and subheadings
/// - Paragraphs
/// - Lists (numbered or bulleted)
/// - Tables (format as markdown)
/// - Mathematical equations (use LaTeX notation)
/// Return ONLY the extracted text, no commentary."

class ImageInputAdapter implements InputSource {
  @override
  String get sourceType => 'image';
  
  @override
  String get displayName => 'Image';
  
  @override
  List<String> get supportedExtensions => ['.jpg', '.jpeg', '.png', '.webp'];
  
  // ... implementation details in code
}
```

#### 5.1.3 Camera Input Adapter

```dart
// ===========================================================
// FILE: lib/infrastructure/input/camera_input_adapter.dart
// ===========================================================

/// Camera Input Adapter Implementation
/// Extends image adapter with camera-specific handling
/// 
/// DEPENDENCIES:
/// - camera: ^x.x.x (for camera access)
/// - image: ^x.x.x (for image processing)
/// 
/// IMPLEMENTATION STEPS:
/// 1. Capture image from camera
/// 2. Auto-detect document boundaries (optional, V2)
/// 3. Apply perspective correction (optional, V2)
/// 4. Enhance contrast for text visibility
/// 5. Pass to ImageInputAdapter for extraction
/// 
/// CONFIGURATION:
/// - Default resolution: 1920x1080
/// - Flash mode: auto
/// - Focus mode: auto (tap to focus)

class CameraInputAdapter implements InputSource {
  final ImageInputAdapter _imageAdapter;
  
  @override
  String get sourceType => 'camera';
  
  @override
  String get displayName => 'Camera Capture';
  
  @override
  List<String> get supportedExtensions => []; // Not file-based
  
  // ... implementation details in code
}
```

### 5.2 Chunking Service

#### 5.2.1 Educational Content Chunking Strategy

```dart
// ===========================================================
// FILE: lib/infrastructure/chunking/educational_chunking_strategy.dart
// ===========================================================

/// Educational Content Chunking Strategy
/// Optimized for textbooks, notes, and educational materials
/// 
/// CHUNKING RULES:
/// 
/// 1. HEADING DETECTION:
///    - Lines in ALL CAPS or Title Case followed by paragraph
///    - Lines starting with numbers (1., 1.1, Chapter 1, etc.)
///    - Lines significantly shorter than average paragraph
///    - Keep heading with following content
/// 
/// 2. PARAGRAPH CHUNKING:
///    - Split on double newlines
///    - Target size: 200-500 tokens (~150-400 words)
///    - Overlap: 50 tokens for context continuity
/// 
/// 3. LIST HANDLING:
///    - Keep entire list together if < 500 tokens
///    - Otherwise, split by logical groups (numbered sections)
///    - Preserve list markers in chunk
/// 
/// 4. TABLE HANDLING:
///    - Keep entire table as single chunk if < 800 tokens
///    - For large tables, split by rows with header repeated
///    - Format as markdown table
/// 
/// 5. EQUATION HANDLING:
///    - Keep equation with surrounding context
///    - Include 1-2 sentences before and after
///    - Preserve LaTeX formatting
/// 
/// 6. DEFINITION/TERM HANDLING:
///    - Detect patterns: "Term: definition" or "Term - definition"
///    - Keep term and definition together
///    - Tag as 'definition' type
/// 
/// 7. EXAMPLE/PROBLEM HANDLING:
///    - Detect patterns: "Example:", "Problem:", "Exercise:"
///    - Keep problem and solution together
///    - Tag as 'example' type

class EducationalChunkingStrategy implements ChunkingStrategy {
  @override
  String get strategyId => 'educational_v1';
  
  @override
  int get targetChunkSize => 350; // tokens
  
  @override
  int get chunkOverlap => 50; // tokens
  
  // Implementation should include:
  // - Regex patterns for headings, lists, tables, equations
  // - Token estimation (word count * 1.3 as rough estimate)
  // - Recursive splitting for oversized chunks
  // - Metadata tagging for chunk types
}
```

#### 5.2.2 Subject-Specific Enhancements

```dart
// ===========================================================
// FILE: lib/infrastructure/chunking/subject_enhancers.dart
// ===========================================================

/// Subject-specific chunking enhancements
/// 
/// MATH ENHANCER:
/// - Detect equation blocks (between $$ or \[ \])
/// - Keep step-by-step solutions together
/// - Preserve variable definitions with usage
/// - Detect theorem/proof structures
/// 
/// SCIENCE ENHANCER:
/// - Detect experiment procedures (Aim, Materials, Method, Observation, Conclusion)
/// - Keep diagrams descriptions with references
/// - Preserve chemical equations
/// - Detect hypothesis-evidence structures
/// 
/// HISTORY ENHANCER:
/// - Detect timeline entries (dates followed by events)
/// - Keep cause-effect narratives together
/// - Preserve quoted sources with context
/// - Detect person-event associations
/// 
/// ENGLISH/LITERATURE ENHANCER:
/// - Detect poetry (short lines, stanza breaks)
/// - Keep quotes with analysis
/// - Preserve dialogue exchanges
/// - Detect character-trait associations

abstract class SubjectEnhancer {
  String get subjectId;
  List<ChunkResult> enhance(List<ChunkResult> chunks, String subject);
}
```

### 5.3 RAG Engine

```dart
// ===========================================================
// FILE: lib/domain/services/rag_engine.dart
// ===========================================================

/// RAG (Retrieval-Augmented Generation) Engine
/// Orchestrates retrieval and generation for Q&A
/// 
/// WORKFLOW:
/// 1. Receive user query
/// 2. Generate query embedding
/// 3. Retrieve relevant chunks from vector store
/// 4. Rerank chunks by relevance (optional, using cross-attention)
/// 5. Construct prompt with context
/// 6. Generate response using inference model
/// 7. Return response with source attributions
/// 
/// PROMPT TEMPLATE:
/// ```
/// You are EduMate, a helpful educational assistant for students in grades 5-10.
/// 
/// CONTEXT FROM STUDY MATERIALS:
/// ---
/// {retrieved_chunks}
/// ---
/// 
/// INSTRUCTIONS:
/// 1. Answer the question using ONLY the context provided above.
/// 2. If the context doesn't contain enough information, say so honestly.
/// 3. Use simple language appropriate for middle school students.
/// 4. When explaining concepts, use examples and analogies.
/// 5. For math problems, show step-by-step solutions.
/// 6. If asked to create a quiz, generate 5 questions with answers.
/// 
/// STUDENT'S QUESTION: {query}
/// 
/// YOUR RESPONSE:
/// ```

class RagEngine {
  final EmbeddingProvider embeddingProvider;
  final VectorStore vectorStore;
  final InferenceProvider inferenceProvider;
  
  /// Configuration
  final int retrievalTopK;
  final double similarityThreshold;
  final int maxContextTokens;
  
  RagEngine({
    required this.embeddingProvider,
    required this.vectorStore,
    required this.inferenceProvider,
    this.retrievalTopK = 5,
    this.similarityThreshold = 0.5,
    this.maxContextTokens = 2000,
  });
  
  /// Answer a question using RAG
  Stream<RagResponse> answer(
    String query, {
    List<int>? materialIds,
    List<Message>? conversationHistory,
  });
  
  /// Generate a quiz from materials
  Stream<RagResponse> generateQuiz(
    List<int> materialIds, {
    int questionCount = 5,
    String? topic,
  });
}

/// Response from RAG engine
class RagResponse {
  final String content;
  final bool isComplete;
  final List<ScoredChunk>? retrievedChunks;
  final double? confidenceScore;
  
  RagResponse({
    required this.content,
    this.isComplete = false,
    this.retrievedChunks,
    this.confidenceScore,
  });
}
```

### 5.4 Conversation Manager

```dart
// ===========================================================
// FILE: lib/domain/services/conversation_manager.dart
// ===========================================================

/// Conversation Manager
/// Handles multi-turn conversations with context preservation
/// 
/// RESPONSIBILITIES:
/// 1. Create and manage conversation sessions
/// 2. Store and retrieve conversation history
/// 3. Provide context window management
/// 4. Enable follow-up questions
/// 
/// CONTEXT WINDOW STRATEGY:
/// - Keep last N messages (configurable, default 6)
/// - Always include system prompt
/// - Include retrieved chunks from most recent query
/// - Summarize older context if needed (V2)
/// 
/// FOLLOW-UP DETECTION:
/// - Pronouns without antecedent ("it", "this", "that")
/// - Continuation phrases ("also", "and what about", "more about")
/// - Comparative questions ("what's the difference", "how is X related to Y")
/// - Clarification requests ("can you explain", "what do you mean")

class ConversationManager {
  final Box<Conversation> conversationBox;
  final Box<Message> messageBox;
  
  /// Maximum messages to include in context
  final int maxContextMessages;
  
  ConversationManager({
    required this.conversationBox,
    required this.messageBox,
    this.maxContextMessages = 6,
  });
  
  /// Create a new conversation
  Future<Conversation> createConversation({
    required String title,
    int? materialId,
  });
  
  /// Add a message to conversation
  Future<Message> addMessage(
    int conversationId, {
    required String role,
    required String content,
    List<int>? retrievedChunkIds,
    double? confidenceScore,
  });
  
  /// Get conversation history for context
  Future<List<Message>> getContextHistory(int conversationId);
  
  /// Detect if query is a follow-up
  bool isFollowUp(String query, List<Message> history);
  
  /// Get all conversations
  Future<List<Conversation>> getAllConversations();
  
  /// Delete a conversation
  Future<void> deleteConversation(int conversationId);
}
```

### 5.5 Material Processor

```dart
// ===========================================================
// FILE: lib/domain/services/material_processor.dart
// ===========================================================

/// Material Processor
/// Orchestrates the full pipeline from input to indexed chunks
/// 
/// PIPELINE:
/// 1. Receive input (file path, image bytes, etc.)
/// 2. Detect appropriate input adapter
/// 3. Extract raw text content
/// 4. Apply chunking strategy
/// 5. Generate embeddings for each chunk
/// 6. Store chunks in vector store
/// 7. Update material status
/// 
/// PROCESSING MODES:
/// - Foreground: Show progress UI, user waits
/// - Background: Process while user continues (with notification)
/// 
/// ERROR HANDLING:
/// - Partial success: Store what was processed, mark material as partial
/// - Complete failure: Mark material as failed with error message
/// - Retry logic: Allow manual retry for failed materials

class MaterialProcessor {
  final List<InputSource> inputAdapters;
  final ChunkingStrategy chunkingStrategy;
  final EmbeddingProvider embeddingProvider;
  final VectorStore vectorStore;
  final Box<Material> materialBox;
  
  MaterialProcessor({
    required this.inputAdapters,
    required this.chunkingStrategy,
    required this.embeddingProvider,
    required this.vectorStore,
    required this.materialBox,
  });
  
  /// Process a new material
  Stream<ProcessingProgress> process(MaterialInput input);
  
  /// Reprocess a failed material
  Stream<ProcessingProgress> reprocess(int materialId);
  
  /// Delete material and its chunks
  Future<void> deleteMaterial(int materialId);
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
  final String stage; // 'extracting', 'chunking', 'embedding', 'storing'
  final String? message;
  final bool isComplete;
  final Material? result;
  final String? error;
  
  ProcessingProgress({
    required this.progress,
    required this.stage,
    this.message,
    this.isComplete = false,
    this.result,
    this.error,
  });
}
```

---

## 6. Project Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── prompt_templates.dart
│   │   └── subject_tags.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── utils/
│   │   ├── text_utils.dart
│   │   ├── token_estimator.dart
│   │   └── logger.dart
│   └── extensions/
│       └── string_extensions.dart
│
├── domain/
│   ├── entities/
│   │   ├── material.dart
│   │   ├── chunk.dart
│   │   ├── conversation.dart
│   │   └── message.dart
│   ├── interfaces/
│   │   ├── input_source.dart
│   │   ├── chunking_strategy.dart
│   │   ├── embedding_provider.dart
│   │   ├── vector_store.dart
│   │   ├── inference_provider.dart
│   │   └── knowledge_source.dart        # V1.5
│   └── services/
│       ├── rag_engine.dart
│       ├── conversation_manager.dart
│       ├── material_processor.dart
│       └── quiz_generator.dart
│
├── infrastructure/
│   ├── database/
│   │   ├── objectbox.dart
│   │   ├── objectbox.g.dart              # Generated
│   │   └── objectbox_vector_store.dart
│   ├── input/
│   │   ├── pdf_input_adapter.dart
│   │   ├── image_input_adapter.dart
│   │   └── camera_input_adapter.dart
│   ├── chunking/
│   │   ├── educational_chunking_strategy.dart
│   │   └── subject_enhancers.dart
│   ├── ai/
│   │   ├── gemma_embedding_provider.dart
│   │   └── gemma_inference_provider.dart
│   └── knowledge/                         # V1.5
│       ├── local_knowledge_source.dart
│       └── wikipedia_knowledge_source.dart
│
├── application/
│   ├── providers/
│   │   ├── material_providers.dart
│   │   ├── chat_providers.dart
│   │   ├── ai_providers.dart
│   │   └── settings_providers.dart
│   └── notifiers/
│       ├── chat_notifier.dart
│       ├── material_notifier.dart
│       └── processing_notifier.dart
│
└── presentation/
    ├── screens/
    │   ├── home/
    │   │   ├── home_screen.dart
    │   │   └── widgets/
    │   ├── chat/
    │   │   ├── chat_screen.dart
    │   │   └── widgets/
    │   │       ├── message_bubble.dart
    │   │       ├── input_bar.dart
    │   │       └── source_card.dart
    │   ├── materials/
    │   │   ├── materials_screen.dart
    │   │   ├── add_material_screen.dart
    │   │   └── widgets/
    │   ├── camera/
    │   │   ├── camera_screen.dart
    │   │   └── widgets/
    │   └── settings/
    │       └── settings_screen.dart
    ├── widgets/
    │   ├── common/
    │   │   ├── loading_indicator.dart
    │   │   └── error_display.dart
    │   └── shared/
    │       └── subject_chip.dart
    └── theme/
        ├── app_theme.dart
        └── colors.dart
```

---

## 7. Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal:** Project setup and core infrastructure

| Task | Priority | Estimate |
|------|----------|----------|
| Create Flutter project with folder structure | P0 | 2h |
| Set up ObjectBox with entities | P0 | 4h |
| Implement ObjectBox vector store | P0 | 4h |
| Set up Riverpod providers skeleton | P0 | 2h |
| Create basic navigation and screens | P1 | 4h |

**Deliverable:** App shell with database ready

### Phase 2: AI Integration (Week 2)
**Goal:** Get on-device AI working

| Task | Priority | Estimate |
|------|----------|----------|
| Integrate flutter_gemma | P0 | 4h |
| Implement EmbeddingProvider with EmbeddingGemma | P0 | 4h |
| Implement InferenceProvider with Gemma 3 Nano | P0 | 4h |
| Model download and management | P0 | 4h |
| Test embedding and inference | P0 | 2h |

**Deliverable:** Working AI inference on device

### Phase 3: Input Pipeline (Week 3)
**Goal:** Accept and process materials

| Task | Priority | Estimate |
|------|----------|----------|
| Implement PDF input adapter | P0 | 6h |
| Implement Image input adapter | P0 | 4h |
| Implement Camera input adapter | P0 | 4h |
| Implement Educational chunking strategy | P0 | 8h |
| Implement Material processor | P0 | 4h |
| Materials management UI | P1 | 4h |

**Deliverable:** Can upload and process materials

### Phase 4: RAG & Chat (Week 4)
**Goal:** Working Q&A functionality

| Task | Priority | Estimate |
|------|----------|----------|
| Implement RAG engine | P0 | 6h |
| Implement Conversation manager | P0 | 4h |
| Chat UI with message bubbles | P0 | 6h |
| Source attribution display | P1 | 3h |
| Follow-up question handling | P0 | 4h |

**Deliverable:** Working chat with RAG

### Phase 5: Polish & Quiz (Week 5)
**Goal:** Complete MVP features

| Task | Priority | Estimate |
|------|----------|----------|
| Quiz generation feature | P0 | 6h |
| Home screen with quick actions | P1 | 4h |
| Settings screen | P2 | 3h |
| Error handling & edge cases | P0 | 6h |
| UI polish and animations | P2 | 4h |
| Testing and bug fixes | P0 | 8h |

**Deliverable:** Complete MVP

### Phase 6: Subject Enhancements (Week 6)
**Goal:** Add subject-specific chunking enhancements

| Task | Priority | Estimate |
|------|----------|----------|
| Math enhancer (equations, proofs) | P1 | 4h |
| Science enhancer (experiments, procedures) | P1 | 4h |
| History enhancer (timelines, cause-effect) | P1 | 3h |
| English enhancer (poetry, quotes) | P1 | 3h |
| Subject detection logic | P1 | 2h |
| Testing with real textbooks | P0 | 4h |

**Deliverable:** Enhanced chunking for all subjects

---

## 8. Configuration & Constants

```dart
// ===========================================================
// FILE: lib/core/constants/app_constants.dart
// ===========================================================

class AppConstants {
  // AI Model Configuration
  static const String embeddingModelUrl = 
    'https://huggingface.co/litert-community/embeddinggemma-300m/resolve/main/embeddinggemma-300M_seq512_mixed-precision.tflite';
  static const String embeddingTokenizerUrl = 
    'https://huggingface.co/litert-community/embeddinggemma-300m/resolve/main/sentencepiece.model';
  static const String inferenceModelUrl = 
    'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task';
  
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
  
  // UI Constants
  static const int messageAnimationDurationMs = 300;
}
```

```dart
// ===========================================================
// FILE: lib/core/constants/prompt_templates.dart
// ===========================================================

class PromptTemplates {
  static const String systemPrompt = '''
You are EduMate, a friendly and helpful educational assistant for students in grades 5-10.

Your role is to:
1. Answer questions clearly using simple language appropriate for middle school students
2. Explain concepts step-by-step with examples and analogies
3. Help with homework and practice problems
4. Create quizzes and practice questions when asked
5. Always be encouraging and supportive

Guidelines:
- Use ONLY the provided context to answer questions
- If you don't have enough information, say so honestly
- For math problems, show all steps clearly
- Use bullet points for lists
- Be concise but thorough
''';

  static const String ragPromptTemplate = '''
CONTEXT FROM STUDY MATERIALS:
---
{context}
---

STUDENT'S QUESTION: {query}

Provide a helpful response based on the context above.
''';

  static const String quizPromptTemplate = '''
CONTEXT FROM STUDY MATERIALS:
---
{context}
---

Create a quiz with {count} questions based on the material above.
Topic focus: {topic}

Format each question as:
Q1: [Question]
A) [Option A]
B) [Option B]
C) [Option C]
D) [Option D]
Correct: [Letter]
Explanation: [Brief explanation]

---
''';

  static const String imageExtractionPrompt = '''
Extract all text from this image. Preserve the structure including:
- Headings and subheadings
- Paragraphs
- Lists (numbered or bulleted)
- Tables (format as markdown)
- Mathematical equations (use LaTeX notation)

Return ONLY the extracted text, no commentary.
''';
}
```

---

## 9. Testing Strategy

### 9.1 Unit Tests
```
test/
├── domain/
│   ├── services/
│   │   ├── rag_engine_test.dart
│   │   ├── conversation_manager_test.dart
│   │   └── material_processor_test.dart
│   └── entities/
│       └── chunk_test.dart
├── infrastructure/
│   ├── chunking/
│   │   └── educational_chunking_strategy_test.dart
│   ├── input/
│   │   └── pdf_input_adapter_test.dart
│   └── database/
│       └── objectbox_vector_store_test.dart
└── fixtures/
    ├── sample_texts/
    │   ├── math_content.txt
    │   ├── science_content.txt
    │   └── history_content.txt
    └── sample_pdfs/
        └── test_textbook.pdf
```

### 9.2 Integration Tests
```
integration_test/
├── material_processing_test.dart
├── rag_pipeline_test.dart
└── conversation_flow_test.dart
```

### 9.3 Test Fixtures for Chunking

```dart
// ===========================================================
// FILE: test/fixtures/sample_texts/math_content.txt
// ===========================================================

/// Sample math content for testing chunking
/// 
/// EXPECTED CHUNKS:
/// 1. Introduction paragraph (type: paragraph)
/// 2. Definition of quadratic equation (type: definition)
/// 3. Formula section with equation (type: equation)
/// 4. Example problem with solution (type: example)
/// 5. Practice problems list (type: list)

const String sampleMathContent = '''
Chapter 5: Quadratic Equations

Introduction
A quadratic equation is a polynomial equation of degree 2. These equations appear in many real-world applications, from calculating projectile motion to finding the dimensions of a rectangle.

Definition: A quadratic equation is an equation of the form ax² + bx + c = 0, where a, b, and c are constants and a ≠ 0.

The Quadratic Formula
To solve any quadratic equation, we can use the quadratic formula:

x = (-b ± √(b² - 4ac)) / 2a

This formula gives us the two solutions (roots) of the equation.

Example 1:
Solve: x² + 5x + 6 = 0

Solution:
Step 1: Identify a = 1, b = 5, c = 6
Step 2: Calculate discriminant: b² - 4ac = 25 - 24 = 1
Step 3: Apply formula: x = (-5 ± 1) / 2
Step 4: Solutions: x = -2 or x = -3

Practice Problems:
1. Solve: x² - 4x + 4 = 0
2. Solve: 2x² + 7x + 3 = 0
3. Solve: x² - 9 = 0
''';
```

---

## 10. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Database & Storage
  objectbox: ^4.0.0
  objectbox_flutter_libs: ^4.0.0
  path_provider: ^2.1.0
  
  # AI/ML
  flutter_gemma: ^0.11.13
  
  # PDF Processing
  syncfusion_flutter_pdf: ^27.1.48
  
  # Image & Camera
  camera: ^0.10.5
  image: ^4.1.0
  image_picker: ^1.0.4
  
  # File Handling
  file_picker: ^6.1.1
  share_plus: ^7.2.1
  
  # UI Components
  flutter_markdown: ^0.6.18
  flutter_math_fork: ^0.7.1  # For LaTeX rendering
  
  # Utilities
  equatable: ^2.0.5
  json_annotation: ^4.8.1
  logger: ^2.0.2
  uuid: ^4.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.6
  objectbox_generator: ^4.0.0
  riverpod_generator: ^2.3.0
  json_serializable: ^6.7.1
  
  # Testing
  mocktail: ^1.0.1
  
  # Linting
  flutter_lints: ^3.0.1
```

---

## 11. AI Coding Tool Instructions

### 11.1 For Claude Code / Cursor

When implementing components, follow these guidelines:

1. **Start with interfaces**: Implement the interface first, then the concrete class
2. **One file at a time**: Complete and test each file before moving to the next
3. **Use TODO comments**: Mark areas needing attention with `// TODO: [description]`
4. **Error handling**: Always wrap async operations in try-catch
5. **Logging**: Use the Logger utility for debugging
6. **Test alongside**: Write unit tests as you implement

### 11.2 Implementation Order

```
1. lib/domain/entities/*.dart (all entity classes)
2. lib/infrastructure/database/objectbox.dart
3. lib/domain/interfaces/*.dart (all interfaces)
4. lib/infrastructure/database/objectbox_vector_store.dart
5. lib/infrastructure/ai/gemma_embedding_provider.dart
6. lib/infrastructure/ai/gemma_inference_provider.dart
7. lib/infrastructure/input/pdf_input_adapter.dart
8. lib/infrastructure/input/image_input_adapter.dart
9. lib/infrastructure/chunking/educational_chunking_strategy.dart
10. lib/domain/services/material_processor.dart
11. lib/domain/services/rag_engine.dart
12. lib/domain/services/conversation_manager.dart
13. lib/application/providers/*.dart
14. lib/presentation/screens/... (UI last)
```

### 11.3 Common Prompts for AI Tools

**For Entity Implementation:**
```
Implement the [EntityName] entity class for ObjectBox based on the specification in the design document. Include all annotations and ensure compatibility with HNSW vector index for embeddings.
```

**For Interface Implementation:**
```
Implement the [InterfaceName] interface as specified in the design document. Create a concrete implementation using [technology]. Include error handling and logging.
```

**For Service Implementation:**
```
Implement the [ServiceName] service based on the design document specification. Inject required dependencies via constructor. Return streams for long-running operations. Include unit tests.
```

---

## 12. Future Enhancements (V1.5+)

### V1.5: External Knowledge Integration
- Wikipedia API integration
- Wolfram Alpha for math/science
- Toggle for online enrichment
- Source attribution UI

### V2.0: Advanced Features
- Handwriting recognition input
- Audio transcription input
- Downloadable subject packs
- Study schedule recommendations
- Progress tracking dashboard
- Multi-language support

### V2.5: Social Features
- Share study materials
- Collaborative study sessions
- Teacher dashboard
- Class material distribution

---

## Appendix A: Sequence Diagrams

### A.1 Material Processing Flow

```
User                MaterialsScreen          MaterialProcessor          InputAdapter          ChunkingStrategy          EmbeddingProvider          VectorStore
  |                       |                        |                        |                        |                        |                        |
  |-- Select file ------->|                        |                        |                        |                        |                        |
  |                       |-- process(input) ----->|                        |                        |                        |                        |
  |                       |                        |-- extractContent() --->|                        |                        |                        |
  |                       |<-- progress(0.2) ------|<-- text chunks --------|                        |                        |                        |
  |                       |                        |-- chunk(text) -------->|                        |                        |                        |
  |                       |<-- progress(0.4) ------|<-- ChunkResults -------|                        |                        |                        |
  |                       |                        |-- embedBatch() ------->|                        |                        |                        |
  |                       |<-- progress(0.7) ------|<-- embeddings ---------|                        |                        |                        |
  |                       |                        |-- storeBatch() ------->|                        |                        |                        |
  |                       |<-- progress(1.0) ------|<-- chunk IDs ----------|                        |                        |                        |
  |<-- complete --------->|                        |                        |                        |                        |                        |
```

### A.2 RAG Query Flow

```
User                ChatScreen          ChatNotifier          RagEngine          EmbeddingProvider          VectorStore          InferenceProvider
  |                     |                    |                    |                      |                      |                      |
  |-- "What is X?" ---->|                    |                    |                      |                      |                      |
  |                     |-- answer(query) -->|                    |                      |                      |                      |
  |                     |                    |-- embed(query) --->|                      |                      |                      |
  |                     |                    |<-- queryVector ----|                      |                      |                      |
  |                     |                    |-- search(vector) ->|                      |                      |                      |
  |                     |                    |<-- ScoredChunks ---|                      |                      |                      |
  |                     |                    |-- generate(context, query) -------------->|                      |
  |<-- streaming -------|<-- tokens ---------|<---------------------- tokens ------------|                      |
  |<-- complete --------|<-- final response -|                    |                      |                      |
```

---

## Appendix B: ObjectBox HNSW Configuration

```dart
/// ObjectBox vector search configuration
/// 
/// HNSW Parameters:
/// - dimensions: 768 (EmbeddingGemma output)
/// - neighborsPerNode: 30 (higher = more accurate, slower)
/// - indexingSearchCount: 200 (higher = more accurate indexing)
/// 
/// For ~10K chunks:
/// - Expected search time: <50ms
/// - Index size: ~50MB additional
/// 
/// Query example:
/// ```dart
/// final query = box.query(
///   Chunk_.embedding.nearestNeighborsF32(queryVector, 10)
/// ).build();
/// final results = query.findWithScores();
/// for (final result in results) {
///   print('${result.object.content}: ${result.score}');
/// }
/// ```
```

---

**Document End**
