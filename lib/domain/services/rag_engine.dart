import 'package:dartz/dartz.dart';
import '../interfaces/embedding_provider.dart';
import '../interfaces/vector_store.dart';
import '../interfaces/inference_provider.dart';
import '../entities/message.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/token_estimator.dart';

/// RAG (Retrieval-Augmented Generation) Engine
/// Orchestrates retrieval and generation for Q&A
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
    this.retrievalTopK = AppConstants.retrievalTopK,
    this.similarityThreshold = AppConstants.similarityThreshold,
    this.maxContextTokens = AppConstants.maxContextTokens,
  });

  /// Answer a question using RAG
  ///
  /// Returns Either Failure or Stream RagResponse
  Future<Either<Failure, Stream<RagResponse>>> answer(
    String query, {
    List<int>? materialIds,
    List<Message>? conversationHistory,
  }) async {
    try {
      // Validate inputs
      if (query.trim().isEmpty) {
        return Left(ProcessingFailure('Query cannot be empty'));
      }

      if (!embeddingProvider.isReady) {
        return Left(ModelFailure('Embedding provider not ready'));
      }

      if (!inferenceProvider.isReady) {
        return Left(ModelFailure('Inference provider not ready'));
      }

      // Generate query embedding (optimized for retrieval)
      final queryEmbedding = await embeddingProvider.embedQuery(query);

      // Retrieve relevant chunks
      final retrievedChunks = await vectorStore.search(
        queryEmbedding,
        topK: retrievalTopK,
        threshold: similarityThreshold,
        materialIds: materialIds,
      );

      // Handle no relevant context
      if (retrievedChunks.isEmpty) {
        return Right(_noContextFoundStream(query));
      }

      // Build context from retrieved chunks
      final context = _buildContext(retrievedChunks);

      // Calculate confidence score (average of chunk scores)
      final confidenceScore = retrievedChunks.isEmpty
          ? 0.0
          : retrievedChunks.map((c) => c.score).reduce((a, b) => a + b) /
              retrievedChunks.length;

      // Generate response stream
      final responseStream = _generateResponseStream(
        query: query,
        context: context,
        conversationHistory: conversationHistory,
        retrievedChunks: retrievedChunks,
        confidenceScore: confidenceScore,
      );

      return Right(responseStream);
    } catch (e) {
      return Left(ProcessingFailure('RAG pipeline failed: $e'));
    }
  }

  /// Generate a quiz from materials
  Future<Either<Failure, Stream<RagResponse>>> generateQuiz(
    List<int> materialIds, {
    int questionCount = 5,
    String? topic,
  }) async {
    try {
      if (materialIds.isEmpty) {
        return Left(ProcessingFailure('No materials specified'));
      }

      if (!inferenceProvider.isReady) {
        return Left(ModelFailure('Inference provider not ready'));
      }

      // Retrieve sample chunks from materials
      final allChunks = <ScoredChunk>[];
      for (final materialId in materialIds) {
        final chunks = await vectorStore.getByMaterial(materialId);
        // Add with default score for quiz generation
        allChunks.addAll(chunks.map((c) => ScoredChunk(chunk: c, score: 1.0)));
      }

      if (allChunks.isEmpty) {
        return Left(ProcessingFailure('No content found in materials'));
      }

      // Build context from chunks
      final context = _buildContext(allChunks.take(10).toList());

      // Generate quiz
      final quizPrompt = _buildQuizPrompt(
        context: context,
        questionCount: questionCount,
        topic: topic,
      );

      final responseStream = inferenceProvider.generate(
        systemPrompt: _getSystemPrompt(),
        context: context,
        query: quizPrompt,
      );

      return Right(_wrapInRagResponse(responseStream, allChunks.take(10).toList()));
    } catch (e) {
      return Left(ProcessingFailure('Quiz generation failed: $e'));
    }
  }

  /// Build context string from retrieved chunks
  String _buildContext(List<ScoredChunk> chunks) {
    final buffer = StringBuffer();
    var currentTokens = 0;

    for (final scoredChunk in chunks) {
      final chunk = scoredChunk.chunk;
      final chunkTokens = TokenEstimator.estimate(chunk.content);

      // Stop if adding this chunk would exceed limit
      if (currentTokens + chunkTokens > maxContextTokens) {
        break;
      }

      // Add chunk with metadata
      buffer.writeln('[Source: ${chunk.chunkType}]');
      if (chunk.pageNumber != null) {
        buffer.writeln('[Page: ${chunk.pageNumber}]');
      }
      buffer.writeln(chunk.content);
      buffer.writeln();

      currentTokens += chunkTokens;
    }

    return buffer.toString();
  }

  /// Generate response stream with RAG metadata
  Stream<RagResponse> _generateResponseStream({
    required String query,
    required String context,
    List<Message>? conversationHistory,
    required List<ScoredChunk> retrievedChunks,
    required double confidenceScore,
  }) async* {
    // Add confidence warning if low
    if (confidenceScore < 0.7) {
      yield RagResponse(
        content: '⚠️ Low confidence - the answer may not be fully accurate.\n\n',
        isComplete: false,
        retrievedChunks: retrievedChunks,
        confidenceScore: confidenceScore,
      );
    }

    // Stream the actual response
    final responseStream = inferenceProvider.generate(
      systemPrompt: _getSystemPrompt(),
      context: context,
      query: query,
      conversationHistory: conversationHistory,
    );

    await for (final chunk in responseStream) {
      yield RagResponse(
        content: chunk,
        isComplete: false,
        retrievedChunks: retrievedChunks,
        confidenceScore: confidenceScore,
      );
    }

    // Final marker
    yield RagResponse(
      content: '',
      isComplete: true,
      retrievedChunks: retrievedChunks,
      confidenceScore: confidenceScore,
    );
  }

  /// Handle no context found scenario
  Stream<RagResponse> _noContextFoundStream(String query) async* {
    const message = '''I don't have enough information in your study materials to answer this question accurately.

Possible reasons:
• This topic hasn't been uploaded yet
• Try rephrasing your question
• Upload relevant materials for this topic

Would you like to:
1. Upload materials about this topic
2. Try a different question
3. Browse your existing materials''';

    yield RagResponse(
      content: message,
      isComplete: true,
      retrievedChunks: [],
      confidenceScore: 0.0,
    );
  }

  /// Wrap inference stream in RagResponse
  Stream<RagResponse> _wrapInRagResponse(
    Stream<String> stream,
    List<ScoredChunk> chunks,
  ) async* {
    await for (final chunk in stream) {
      yield RagResponse(
        content: chunk,
        isComplete: false,
        retrievedChunks: chunks,
        confidenceScore: 1.0,
      );
    }

    yield RagResponse(
      content: '',
      isComplete: true,
      retrievedChunks: chunks,
      confidenceScore: 1.0,
    );
  }

  /// Get system prompt
  String _getSystemPrompt() {
    return '''You are EduMate, a helpful educational assistant for students in grades 5-10.

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
- Be concise but thorough''';
  }

  /// Build quiz generation prompt
  String _buildQuizPrompt({
    required String context,
    required int questionCount,
    String? topic,
  }) {
    final topicText = topic != null ? 'focusing on: $topic' : '';
    return '''Create a quiz with $questionCount questions based on the material above $topicText.

Format each question as:
Q1: [Question]
A) [Option A]
B) [Option B]
C) [Option C]
D) [Option D]
Correct: [Letter]
Explanation: [Brief explanation]

Make questions appropriate for middle school students.''';
  }
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

