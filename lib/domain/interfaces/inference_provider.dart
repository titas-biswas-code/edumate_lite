import 'dart:typed_data';
import '../entities/message.dart';

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

