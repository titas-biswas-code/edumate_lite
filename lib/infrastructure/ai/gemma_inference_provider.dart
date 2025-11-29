import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/message.dart' as gemma_msg;
import '../../domain/interfaces/inference_provider.dart';
import '../../domain/entities/message.dart' as app_entities;
import '../../core/errors/exceptions.dart';

/// Gemma-based inference provider using Gemma 3 Nano E2B
class GemmaInferenceProvider implements InferenceProvider {
  bool _isReady = false;
  InferenceModel? _inferenceModel;
  InferenceModelSession? _currentSession;

  @override
  String get modelId => 'Gemma-3-Nano-E2B';

  @override
  bool get isReady => _isReady;

  @override
  bool get supportsVision => true;

  @override
  Future<void> initialize() async {
    try {
      // Check if active model exists
      if (!FlutterGemma.hasActiveModel()) {
        throw ModelException('No active inference model. Please download first.');
      }

      // Get the active inference model with GPU support if available
      try {
        _inferenceModel = await FlutterGemma.getActiveModel(
          maxTokens: 2048,
          supportImage: true,
          preferredBackend: PreferredBackend.gpu, // Use GPU if available
        );
        _isReady = true;
      } catch (e) {
        // Try fallback to CPU if GPU fails
        try {
          _inferenceModel = await FlutterGemma.getActiveModel(
            maxTokens: 2048,
            supportImage: true,
            preferredBackend: PreferredBackend.cpu,
          );
          _isReady = true;
        } catch (e2) {
          throw ModelException(
            'Failed to create model instance. '
            'Error: $e',
          );
        }
      }
    } catch (e) {
      _isReady = false;
      rethrow;
    }
  }

  @override
  Stream<String> generate({
    required String systemPrompt,
    required String context,
    required String query,
    List<app_entities.Message>? conversationHistory,
  }) async* {
    if (!_isReady || _inferenceModel == null) {
      throw ModelException('Inference provider not initialized');
    }

    try {
      // Create new session for this query
      final session = await _inferenceModel!.createSession();

      // Build the full prompt
      final fullPrompt = _buildPrompt(
        systemPrompt: systemPrompt,
        context: context,
        query: query,
        conversationHistory: conversationHistory,
      );

      // Add prompt as message
      await session.addQueryChunk(
        gemma_msg.Message.text(text: fullPrompt),
      );

      // Generate response stream
      final responseStream = session.getResponseAsync();

      await for (final chunk in responseStream) {
        if (chunk.isNotEmpty) {
          yield chunk;
        }
      }

      // Close session
      await session.close();
    } catch (e) {
      throw ModelException('Generation failed: $e');
    }
  }

  @override
  Stream<String> generateWithImage({
    required String systemPrompt,
    required Uint8List imageBytes,
    required String query,
  }) async* {
    if (!_isReady || _inferenceModel == null) {
      throw ModelException('Inference provider not initialized');
    }

    if (!supportsVision) {
      throw ModelException('Model does not support vision');
    }

    try {
      // Create session with vision enabled
      final session = await _inferenceModel!.createSession(
        enableVisionModality: true,
      );

      // Add message with image
      await session.addQueryChunk(
        gemma_msg.Message.withImage(
          text: '$systemPrompt\n\n$query',
          imageBytes: imageBytes,
        ),
      );

      // Generate response stream
      final responseStream = session.getResponseAsync();

      await for (final chunk in responseStream) {
        if (chunk.isNotEmpty) {
          yield chunk;
        }
      }

      // Close session
      await session.close();
    } catch (e) {
      throw ModelException('Image generation failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    if (_currentSession != null) {
      await _currentSession!.close();
      _currentSession = null;
    }
    _isReady = false;
    _inferenceModel = null;
  }

  /// Build prompt from components
  String _buildPrompt({
    required String systemPrompt,
    required String context,
    required String query,
    List<app_entities.Message>? conversationHistory,
  }) {
    final buffer = StringBuffer();
    
    // Add system prompt
    buffer.writeln(systemPrompt);
    buffer.writeln();

    // Add conversation history if available
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      buffer.writeln('CONVERSATION HISTORY:');
      for (final msg in conversationHistory) {
        buffer.writeln('${msg.role.toUpperCase()}: ${msg.content}');
      }
      buffer.writeln();
    }

    // Add context
    buffer.writeln('CONTEXT FROM STUDY MATERIALS:');
    buffer.writeln('---');
    buffer.writeln(context);
    buffer.writeln('---');
    buffer.writeln();

    // Add query
    buffer.writeln("STUDENT'S QUESTION: $query");
    buffer.writeln();
    buffer.writeln('YOUR RESPONSE:');

    return buffer.toString();
  }
}


