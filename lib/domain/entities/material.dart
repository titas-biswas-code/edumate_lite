import 'package:objectbox/objectbox.dart';

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

