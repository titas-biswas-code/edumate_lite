import 'package:objectbox/objectbox.dart';
import 'material.dart';

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
  }) : wordCount = wordCount ?? content.split(' ').where((w) => w.isNotEmpty).length;
}

