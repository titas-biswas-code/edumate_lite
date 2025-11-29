import 'package:objectbox/objectbox.dart';
import 'material.dart';

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
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

