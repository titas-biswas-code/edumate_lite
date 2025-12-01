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
    
    // Split into paragraphs first (single newline = paragraph boundary)
    final paragraphs = _splitIntoParagraphs(text);
    
    var currentChunkParagraphs = <String>[];
    var currentWords = 0;
    var sequenceIndex = 0;
    
    for (var i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      final paragraphWords = paragraph.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      
      // Case 1: Single paragraph exceeds hard limit - must split by sentences
      if (paragraphWords > AppConstants.maxChunkWords) {
        // Save current chunk if any
        if (currentChunkParagraphs.isNotEmpty) {
          final chunkContent = currentChunkParagraphs.join('\n\n').trim();
          results.add(_createChunkResult(chunkContent, pageNumber, sequenceIndex++));
          currentChunkParagraphs.clear();
          currentWords = 0;
        }
        
        // Split this paragraph by sentences (never split a sentence)
        final sentenceChunks = _splitParagraphBySentences(paragraph, pageNumber, sequenceIndex);
        results.addAll(sentenceChunks);
        sequenceIndex += sentenceChunks.length;
        continue;
      }
      
      // Case 2: Adding this paragraph would exceed target - save current chunk
      if (currentWords + paragraphWords > AppConstants.targetChunkWords && currentChunkParagraphs.isNotEmpty) {
        final chunkContent = currentChunkParagraphs.join('\n\n').trim();
        results.add(_createChunkResult(chunkContent, pageNumber, sequenceIndex++));
        
        // Start new chunk with overlap (last paragraph if within overlap limit)
        currentChunkParagraphs.clear();
        currentWords = 0;
        
        if (i > 0) {
          final prevPara = paragraphs[i - 1];
          final prevWords = prevPara.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          if (prevWords <= AppConstants.chunkOverlapWords) {
            currentChunkParagraphs.add(prevPara);
            currentWords = prevWords;
          }
        }
      }
      
      // Case 3: Adding would exceed hard limit - save without this paragraph
      if (currentWords + paragraphWords > AppConstants.maxChunkWords && currentChunkParagraphs.isNotEmpty) {
        final chunkContent = currentChunkParagraphs.join('\n\n').trim();
        results.add(_createChunkResult(chunkContent, pageNumber, sequenceIndex++));
        currentChunkParagraphs.clear();
        currentWords = 0;
      }
      
      // Add paragraph to current chunk
      currentChunkParagraphs.add(paragraph);
      currentWords += paragraphWords;
    }
    
    // Add remaining paragraphs
    if (currentChunkParagraphs.isNotEmpty) {
      final chunkContent = currentChunkParagraphs.join('\n\n').trim();
      results.add(_createChunkResult(chunkContent, pageNumber, sequenceIndex));
    }
    
    return results;
  }
  
  ChunkResult _createChunkResult(String content, int? pageNumber, int sequenceIndex) {
    final chunkType = _detectChunkType(content);
    final tokens = TokenEstimator.estimate(content);
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    
    return ChunkResult(
      content: content,
      chunkType: chunkType,
      pageNumber: pageNumber,
      sectionIndex: sequenceIndex,
      metadata: {
        'words': words,
        'estimated_tokens': tokens,
      },
    );
  }
  
  /// Split into paragraphs (preserve paragraph structure)
  List<String> _splitIntoParagraphs(String text) {
    return text
        .split(RegExp(r'\n+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
  }

  /// Split a single paragraph into sentence-based chunks (never split sentences)
  /// Uses WORD COUNT instead of token estimation for reliability
  List<ChunkResult> _splitParagraphBySentences(
    String paragraph,
    int? pageNumber,
    int startSequence,
  ) {
    final results = <ChunkResult>[];
    var sentences = _splitIntoSentences(paragraph);
    
    // Edge case: no proper sentences - split by word count
    final paragraphWords = paragraph.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (sentences.length <= 1 && paragraphWords > AppConstants.targetChunkWords) {
      return _splitByWordCount(paragraph, pageNumber, startSequence);
    }
    
    var currentSentences = <String>[];
    var currentWords = 0;
    var sequenceIndex = startSequence;
    
    for (var i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final sentenceWords = sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      
      // If single sentence exceeds hard limit, truncate by words (last resort)
      if (sentenceWords > AppConstants.maxChunkWords) {
        if (currentSentences.isNotEmpty) {
          final chunkContent = currentSentences.join(' ').trim();
          results.add(_createChunkResult(chunkContent, pageNumber, sequenceIndex++));
          currentSentences.clear();
          currentWords = 0;
        }
        
        // Truncate sentence to max word count
        final words = sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        final truncated = words.take(AppConstants.maxChunkWords).join(' ');
        results.add(_createChunkResult(truncated, pageNumber, sequenceIndex++));
        continue;
      }
      
      // Would exceed target - save current chunk
      if (currentWords + sentenceWords > AppConstants.targetChunkWords && currentSentences.isNotEmpty) {
        final chunkContent = currentSentences.join(' ').trim();
        results.add(_createChunkResult(chunkContent, pageNumber, sequenceIndex++));
        
        // Start new with overlap (last sentence if fits in overlap limit)
        currentSentences.clear();
        currentWords = 0;
        
        if (i > 0) {
          final prevWords = sentences[i - 1].split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          if (prevWords <= AppConstants.chunkOverlapWords) {
            currentSentences.add(sentences[i - 1]);
            currentWords = prevWords;
          }
        }
      }
      
      // Would exceed hard limit - save without overlap
      if (currentWords + sentenceWords > AppConstants.maxChunkWords && currentSentences.isNotEmpty) {
        final chunkContent = currentSentences.join(' ').trim();
        results.add(_createChunkResult(chunkContent, pageNumber, sequenceIndex++));
        currentSentences.clear();
        currentWords = 0;
      }
      
      currentSentences.add(sentence);
      currentWords += sentenceWords;
    }
    
    // Add remaining
    if (currentSentences.isNotEmpty) {
      final chunkContent = currentSentences.join(' ').trim();
      results.add(_createChunkResult(chunkContent, pageNumber, sequenceIndex));
    }
    
    return results;
  }
  
  /// Fallback: Split by word count when no sentence boundaries (never split words)
  List<ChunkResult> _splitByWordCount(String text, int? pageNumber, int startSequence) {
    final results = <ChunkResult>[];
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    final wordsPerChunk = AppConstants.targetChunkWords;
    final overlapWords = AppConstants.chunkOverlapWords;
    
    var sequenceIndex = startSequence;
    
    for (int i = 0; i < words.length; i += (wordsPerChunk - overlapWords)) {
      final end = (i + wordsPerChunk < words.length) ? i + wordsPerChunk : words.length;
      final chunkWords = words.sublist(i, end);
      final chunkContent = chunkWords.join(' ');
      
      results.add(_createChunkResult(chunkContent, pageNumber, sequenceIndex++));
      
      if (end >= words.length) break;
    }
    
    return results;
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

