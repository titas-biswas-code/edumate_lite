import '../../domain/interfaces/chunking_strategy.dart';
import '../../core/utils/token_estimator.dart';
import '../../core/constants/app_constants.dart';

/// Educational content chunking strategy
/// Optimized for textbooks, notes, and educational materials
class EducationalChunkingStrategy implements ChunkingStrategy {
  @override
  String get strategyId => 'educational_v1';

  @override
  int get targetChunkSize => AppConstants.targetChunkSizeTokens;

  @override
  int get chunkOverlap => AppConstants.chunkOverlapTokens;

  @override
  Future<List<ChunkResult>> chunk(
    String text,
    Map<String, dynamic> metadata,
  ) async {
    if (text.isEmpty) {
      return [];
    }

    final results = <ChunkResult>[];
    final pageNumber = metadata['pageNumber'] as int?;
    
    // Split into sections by double newlines
    final sections = _splitIntoSections(text);
    
    var sequenceIndex = 0;
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      
      // Detect chunk type
      final chunkType = _detectChunkType(section);
      
      // Check if section needs splitting
      final tokens = TokenEstimator.estimate(section);
      
      if (tokens <= AppConstants.maxChunkSizeTokens) {
        // Section fits in one chunk
        results.add(ChunkResult(
          content: section.trim(),
          chunkType: chunkType,
          pageNumber: pageNumber,
          sectionIndex: sequenceIndex++,
          metadata: {'original_length': section.length},
        ));
      } else {
        // Split large section into smaller chunks with overlap
        final subChunks = _splitLargeSection(
          section,
          chunkType,
          pageNumber,
          sequenceIndex,
        );
        results.addAll(subChunks);
        sequenceIndex += subChunks.length;
      }
    }
    
    return results;
  }

  /// Split text into sections by double newlines
  List<String> _splitIntoSections(String text) {
    return text
        .split(RegExp(r'\n\s*\n'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  /// Detect the type of chunk based on content patterns
  /// Check more specific types first before general patterns
  String _detectChunkType(String content) {
    final trimmed = content.trim();
    final lines = trimmed.split('\n');

    // Example/Problem detection (check first - very specific)
    if (_isExample(trimmed)) {
      return 'example';
    }

    // Definition detection (specific pattern)
    if (_isDefinition(trimmed)) {
      return 'definition';
    }

    // Table detection (specific structure)
    if (_isTable(lines)) {
      return 'table';
    }

    // List detection (specific markers)
    if (_isList(lines)) {
      return 'list';
    }

    // Equation detection (specific symbols)
    if (_hasEquation(trimmed)) {
      return 'equation';
    }

    // Heading detection (more general pattern)
    final firstLine = lines.first.trim();
    if (_isHeading(firstLine, trimmed)) {
      return 'heading';
    }

    return 'paragraph';
  }

  /// Check if text is a heading
  bool _isHeading(String firstLine, String fullContent) {
    // Skip if contains special math or table characters
    if (firstLine.contains('|') || firstLine.contains('±') || firstLine.contains('√')) {
      return false;
    }
    
    // All caps or very short lines (< 60 chars)
    if (firstLine.length < 60 && firstLine.length > 3 && firstLine == firstLine.toUpperCase()) {
      return true;
    }
    
    // Starts with numbers (1., 1.1, Chapter 1, etc.) but not a list item
    if (RegExp(r'^(Chapter|Section|Part)\s+\d+', caseSensitive: false)
        .hasMatch(firstLine)) {
      return true;
    }
    
    // Title case with no ending punctuation and only one line
    if (fullContent.split('\n').length == 1 &&
        firstLine.length < 60 &&
        firstLine.length > 5 &&
        !firstLine.endsWith('.') && 
        !firstLine.endsWith('?') &&
        !firstLine.endsWith('!') &&
        !firstLine.contains('=')) {
      final words = firstLine.split(' ');
      if (words.length >= 2 && words.length < 10) {
        return true;
      }
    }
    
    return false;
  }

  /// Check if lines form a list
  bool _isList(List<String> lines) {
    if (lines.isEmpty) return false;
    
    var listItemCount = 0;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      // Numbered list: 1. or 1)
      if (RegExp(r'^\d+[\.\)]\s+').hasMatch(trimmed)) {
        listItemCount++;
      }
      // Bulleted list: - or • or *
      else if (RegExp(r'^[\-\•\*]\s+').hasMatch(trimmed)) {
        listItemCount++;
      }
    }
    
    // If at least 2 list items
    return listItemCount >= 2;
  }

  /// Check if content contains equations
  bool _hasEquation(String text) {
    // LaTeX style: $...$ or \[...\]
    if (RegExp(r'\$.*\$|\\\[.*\\\]').hasMatch(text)) {
      return true;
    }
    
    // Common math symbols and patterns
    if (RegExp(r'[±√∞≈≠≤≥∑∏∫]').hasMatch(text)) {
      return true;
    }
    
    // Math operators with variables (more specific)
    if (RegExp(r'[a-z]\s*[²³⁴+\-*/=^]\s*[a-z0-9(]', caseSensitive: false).hasMatch(text)) {
      return true;
    }
    
    // Fractions like a/b or (a+b)/c
    if (RegExp(r'\([^)]+\)\s*/\s*\(?[a-z0-9]', caseSensitive: false).hasMatch(text)) {
      return true;
    }
    
    return false;
  }

  /// Check if content is a definition
  bool _isDefinition(String text) {
    // Pattern: "Term: definition" or "Term - definition"
    final defPattern = RegExp(
      r'^[A-Z][a-zA-Z\s]+[:|\-]\s+',
      multiLine: false,
    );
    return defPattern.hasMatch(text);
  }

  /// Check if content is an example or problem
  bool _isExample(String text) {
    final examplePattern = RegExp(
      r'(Example|Problem|Exercise|Question|Solution)\s*\d*\s*:',
      caseSensitive: false,
    );
    return examplePattern.hasMatch(text);
  }

  /// Check if lines form a table
  bool _isTable(List<String> lines) {
    if (lines.length < 2) return false;
    
    var pipeCount = 0;
    var nonEmptyLines = 0;
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      nonEmptyLines++;
      if (line.contains('|')) {
        pipeCount++;
      }
    }
    
    // If at least 2 lines have pipes and they're consistent
    return pipeCount >= 2 && pipeCount >= nonEmptyLines * 0.5;
  }

  /// Split large section into smaller chunks with overlap
  List<ChunkResult> _splitLargeSection(
    String section,
    String chunkType,
    int? pageNumber,
    int startSequence,
  ) {
    final results = <ChunkResult>[];
    final sentences = _splitIntoSentences(section);
    
    var currentChunk = StringBuffer();
    var currentTokens = 0;
    var sequenceIndex = startSequence;
    
    for (var i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final sentenceTokens = TokenEstimator.estimate(sentence);
      
      // If adding this sentence would exceed limit, save current chunk
      if (currentTokens + sentenceTokens > targetChunkSize && 
          currentChunk.isNotEmpty) {
        results.add(ChunkResult(
          content: currentChunk.toString().trim(),
          chunkType: chunkType,
          pageNumber: pageNumber,
          sectionIndex: sequenceIndex++,
        ));
        
        // Start new chunk with overlap (last few sentences)
        currentChunk = StringBuffer();
        currentTokens = 0;
        
        // Add overlap from previous sentences
        final overlapStart = (i - 2).clamp(0, sentences.length);
        for (var j = overlapStart; j < i; j++) {
          currentChunk.write(sentences[j]);
          currentChunk.write(' ');
          currentTokens += TokenEstimator.estimate(sentences[j]);
        }
      }
      
      currentChunk.write(sentence);
      currentChunk.write(' ');
      currentTokens += sentenceTokens;
    }
    
    // Add remaining content
    if (currentChunk.isNotEmpty) {
      results.add(ChunkResult(
        content: currentChunk.toString().trim(),
        chunkType: chunkType,
        pageNumber: pageNumber,
        sectionIndex: sequenceIndex,
      ));
    }
    
    return results;
  }

  /// Split text into sentences
  List<String> _splitIntoSentences(String text) {
    // Simple sentence split on .!? followed by space
    return text
        .split(RegExp(r'[.!?]\s+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => '$s.')
        .toList();
  }
}

