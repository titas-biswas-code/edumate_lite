import 'package:dartz/dartz.dart';
import '../../objectbox.g.dart' as obx;
import '../entities/conversation.dart';
import '../entities/message.dart';
import '../entities/material.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/app_constants.dart';

/// Conversation Manager
/// Handles multi-turn conversations with context preservation
class ConversationManager {
  final obx.Box<Conversation> conversationBox;
  final obx.Box<Message> messageBox;

  /// Maximum messages to include in context
  final int maxContextMessages;

  ConversationManager({
    required this.conversationBox,
    required this.messageBox,
    this.maxContextMessages = AppConstants.maxContextMessages,
  });

  /// Create a new conversation
  Future<Either<Failure, Conversation>> createConversation({
    required String title,
    int? materialId,
  }) async {
    try {
      final conversation = Conversation(
        title: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Link to material if provided
      if (materialId != null) {
        final material = Material(
          title: '',
          sourceType: '',
        );
        material.id = materialId;
        conversation.material.target = material;
      }

      final id = conversationBox.put(conversation);
      conversation.id = id;

      return Right(conversation);
    } catch (e) {
      return Left(StorageFailure('Failed to create conversation: $e'));
    }
  }

  /// Add a message to conversation
  Future<Either<Failure, Message>> addMessage(
    int conversationId, {
    required String role,
    required String content,
    List<int>? retrievedChunkIds,
    double? confidenceScore,
  }) async {
    try {
      // Validate role
      if (!['user', 'assistant', 'system'].contains(role)) {
        return Left(ProcessingFailure('Invalid message role: $role'));
      }

      // Get conversation
      final conversation = conversationBox.get(conversationId);
      if (conversation == null) {
        return Left(StorageFailure('Conversation not found'));
      }

      // Create message
      final message = Message(
        role: role,
        content: content,
        retrievedChunkIds: retrievedChunkIds?.join(','),
        confidenceScore: confidenceScore,
        timestamp: DateTime.now(),
        sequenceIndex: conversation.messageCount,
      );

      // Link to conversation
      message.conversation.target = conversation;

      // Save message
      final id = messageBox.put(message);
      message.id = id;

      // Update conversation
      conversation.messageCount++;
      conversation.updatedAt = DateTime.now();
      conversationBox.put(conversation);

      return Right(message);
    } catch (e) {
      return Left(StorageFailure('Failed to add message: $e'));
    }
  }

  /// Get conversation history for context
  Future<Either<Failure, List<Message>>> getContextHistory(
    int conversationId,
  ) async {
    try {
      final query = messageBox
          .query(obx.Message_.conversation.equals(conversationId))
          .order(obx.Message_.sequenceIndex, flags: obx.Order.descending)
          .build();

      // Get last N messages
      final allMessages = query.find();
      query.close();

      // Take last maxContextMessages and reverse to chronological order
      final contextMessages = allMessages
          .take(maxContextMessages)
          .toList()
          .reversed
          .toList();

      return Right(contextMessages);
    } catch (e) {
      return Left(StorageFailure('Failed to get conversation history: $e'));
    }
  }

  /// Detect if query is a follow-up question
  bool isFollowUp(String query, List<Message> history) {
    if (history.isEmpty) return false;

    final queryLower = query.toLowerCase();

    // Check for pronouns without clear antecedents
    final pronounPatterns = [
      'it',
      'this',
      'that',
      'these',
      'those',
      'them',
      'they',
    ];
    if (pronounPatterns.any((p) => queryLower.contains(p))) {
      return true;
    }

    // Check for continuation phrases
    final continuationPhrases = [
      'also',
      'and what about',
      'what about',
      'how about',
      'more about',
      'tell me more',
      'explain more',
      'similarly',
      'likewise',
    ];
    if (continuationPhrases.any((p) => queryLower.contains(p))) {
      return true;
    }

    // Check for comparative questions
    final comparativePatterns = [
      "what's the difference",
      'how is',
      'compared to',
      'similar to',
      'different from',
    ];
    if (comparativePatterns.any((p) => queryLower.contains(p))) {
      return true;
    }

    // Check for clarification requests
    final clarificationPatterns = [
      'can you explain',
      'what do you mean',
      'i don\'t understand',
      'clarify',
      'could you',
    ];
    if (clarificationPatterns.any((p) => queryLower.contains(p))) {
      return true;
    }

    return false;
  }

  /// Get all conversations
  Future<Either<Failure, List<Conversation>>> getAllConversations() async {
    try {
      final query = conversationBox
          .query()
          .order(obx.Conversation_.updatedAt, flags: obx.Order.descending)
          .build();

      final conversations = query.find();
      query.close();

      return Right(conversations);
    } catch (e) {
      return Left(StorageFailure('Failed to get conversations: $e'));
    }
  }

  /// Get conversation by ID
  Future<Either<Failure, Conversation>> getConversation(int id) async {
    try {
      final conversation = conversationBox.get(id);
      if (conversation == null) {
        return Left(StorageFailure('Conversation not found'));
      }
      return Right(conversation);
    } catch (e) {
      return Left(StorageFailure('Failed to get conversation: $e'));
    }
  }

  /// Delete a conversation and all its messages
  Future<Either<Failure, Unit>> deleteConversation(int conversationId) async {
    try {
      // Delete all messages first
      final query = messageBox
          .query(obx.Message_.conversation.equals(conversationId))
          .build();

      query.remove();
      query.close();

      // Delete conversation
      final removed = conversationBox.remove(conversationId);
      if (!removed) {
        return Left(StorageFailure('Conversation not found'));
      }

      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure('Failed to delete conversation: $e'));
    }
  }

  /// Update conversation title
  Future<Either<Failure, Conversation>> updateTitle(
    int conversationId,
    String newTitle,
  ) async {
    try {
      final conversation = conversationBox.get(conversationId);
      if (conversation == null) {
        return Left(StorageFailure('Conversation not found'));
      }

      conversation.title = newTitle;
      conversation.updatedAt = DateTime.now();
      conversationBox.put(conversation);

      return Right(conversation);
    } catch (e) {
      return Left(StorageFailure('Failed to update conversation: $e'));
    }
  }

  /// Delete a single message by ID
  Future<Either<Failure, Unit>> deleteMessage(int messageId) async {
    try {
      final removed = messageBox.remove(messageId);
      if (!removed) {
        return Left(StorageFailure('Message not found'));
      }
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure('Failed to delete message: $e'));
    }
  }
}

