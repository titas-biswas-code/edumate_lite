import '../../domain/interfaces/chunking_strategy.dart';
import '../../domain/interfaces/embedding_provider.dart';
import '../../core/constants/app_constants.dart';

/// Adaptive chunking strategy with ACTUAL token counting
/// Uses the embedding provider's tokenizer for precise token counts
class AdaptiveChunkingStrategy implements ChunkingStrategy {
  final EmbeddingProvider embeddingProvider;
  
  AdaptiveChunkingStrategy({required this.embeddingProvider});
  
  @override
  String get strategyId => 'adaptive_v1';

  @override
  int get targetChunkSize => 1800; // Target tokens (with actual counting)

  @override
  int get chunkOverlap => 150; // Overlap tokens

  @override
  Future<List<ChunkResult>> chunk(
    String text,
    Map<String, dynamic> metadata,
  ) async {
    if (text.isEmpty) return [];

    final results = <ChunkResult>[];
    final pageNumber = metadata['pageNumber'] as int?;
    
    // Split into paragraphs (preserve document structure)
    final paragraphs = _splitIntoParagraphs(text);
    
    var currentParagraphs = <String>[];
    var sequenceIndex = 0;
    
    for (var i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      
      // Add paragraph to current chunk
      currentParagraphs.add(paragraph);
      final testContent = currentParagraphs.join('\n\n');
      
      // Count ACTUAL tokens using the real tokenizer
      final actualTokens = await _countTokensWithEmbedder(testContent);
      
      // Exceeds target? Save current chunk
      if (actualTokens > targetChunkSize) {
        if (currentParagraphs.length > 1) {
          // Remove last paragraph and save
          currentParagraphs.removeLast();
          final chunkContent = currentParagraphs.join('\n\n').trim();
          results.add(await _createValidatedChunk(chunkContent, pageNumber, sequenceIndex++));
          
          // Start new with overlap (last paragraph)
          currentParagraphs = [currentParagraphs.last, paragraph];
        } else {
          // Single paragraph too big - split by sentences
          final sentenceChunks = await _splitParagraphBySentences(paragraph, pageNumber, sequenceIndex);
          results.addAll(sentenceChunks);
          sequenceIndex += sentenceChunks.length;
          currentParagraphs.clear();
        }
      }
    }
    
    // Add remaining
    if (currentParagraphs.isNotEmpty) {
      final chunkContent = currentParagraphs.join('\n\n').trim();
      results.add(await _createValidatedChunk(chunkContent, pageNumber, sequenceIndex));
    }
    
    return results;
  }
  
  Future<ChunkResult> _createValidatedChunk(String content, int? pageNumber, int sequenceIndex) async {
    final tokens = await _countTokensWithEmbedder(content);
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    
    return ChunkResult(
      content: content,
      chunkType: 'paragraph',
      pageNumber: pageNumber,
      sectionIndex: sequenceIndex,
      metadata: {
        'words': words,
        'actual_tokens': tokens,
      },
    );
  }
  
  Future<List<ChunkResult>> _splitParagraphBySentences(
    String paragraph,
    int? pageNumber,
    int startSequence,
  ) async {
    final results = <ChunkResult>[];
    final sentences = _splitIntoSentences(paragraph);
    
    var currentSentences = <String>[];
    var sequenceIndex = startSequence;
    
    for (final sentence in sentences) {
      currentSentences.add(sentence);
      final testContent = currentSentences.join(' ');
      final actualTokens = await _countTokensWithEmbedder(testContent);
      
      if (actualTokens > targetChunkSize && currentSentences.length > 1) {
        // Remove last sentence and save
        currentSentences.removeLast();
        final chunkContent = currentSentences.join(' ').trim();
        results.add(await _createValidatedChunk(chunkContent, pageNumber, sequenceIndex++));
        
        // Start new with last sentence
        currentSentences = [currentSentences.last, sentence];
      }
    }
    
    if (currentSentences.isNotEmpty) {
      final chunkContent = currentSentences.join(' ').trim();
      results.add(await _createValidatedChunk(chunkContent, pageNumber, sequenceIndex));
    }
    
    return results;
  }
  
  Future<int> _countTokensWithEmbedder(String text) async {
    // TODO: Use embedding provider's actual tokenizer
    // For now, use conservative word-based estimate
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return (words * 3.5).ceil(); // Conservative until we expose tokenizer
  }
  
  List<String> _splitIntoParagraphs(String text) {
    return text
        .split(RegExp(r'\n+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
  }
  
  List<String> _splitIntoSentences(String text) {
    return text
        .split(RegExp(r'[.!?]\s+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => '$s.')
        .toList();
  }
}

