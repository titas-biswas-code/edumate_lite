import 'package:objectbox/objectbox.dart';
import 'conversation.dart';

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

