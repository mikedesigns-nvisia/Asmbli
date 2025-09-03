import 'dart:math';
import '../models/vector_models.dart';

/// Advanced document chunking system that intelligently splits text while preserving context
class DocumentChunker {
  final ChunkingConfig config;
  
  const DocumentChunker({
    this.config = const ChunkingConfig(),
  });

  /// Chunk a document into smaller pieces suitable for vector embedding
  List<VectorChunk> chunkDocument(VectorDocument document) {
    print('🔧 Chunking document: ${document.title} (${document.content.length} chars)');
    
    // Pre-process the content to handle special cases
    final processedContent = _preprocessContent(document.content);
    
    // Split into chunks using recursive splitting
    final textChunks = _recursiveTextSplit(processedContent);
    
    // Convert to VectorChunk objects with metadata
    final chunks = <VectorChunk>[];
    int currentPos = 0;
    
    for (int i = 0; i < textChunks.length; i++) {
      final text = textChunks[i];
      final startChar = _findTextPosition(document.content, text, currentPos);
      final endChar = startChar + text.length;
      
      final chunk = VectorChunk(
        id: '${document.id}_chunk_$i',
        documentId: document.id,
        text: text,
        chunkIndex: i,
        totalChunks: textChunks.length,
        startChar: startChar,
        endChar: endChar,
        metadata: {
          'document_title': document.title,
          'document_type': document.contentType,
          'document_source': document.source,
          'chunk_size': text.length,
          'chunk_word_count': _countWords(text),
          'has_code': _containsCode(text),
          'has_table': _containsTable(text),
          'section_type': _identifySectionType(text),
          ...document.metadata,
        },
      );
      
      chunks.add(chunk);
      currentPos = endChar;
    }
    
    print('✅ Created ${chunks.length} chunks from ${document.title}');
    return chunks;
  }

  /// Pre-process content to handle special cases
  String _preprocessContent(String content) {
    String processed = content;
    
    // Normalize line endings
    processed = processed.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    
    // Handle code blocks if preservation is enabled
    if (config.preserveCodeBlocks) {
      processed = _preserveCodeBlocks(processed);
    }
    
    // Handle tables if preservation is enabled
    if (config.preserveTables) {
      processed = _preserveTables(processed);
    }
    
    // Clean up extra whitespace while preserving structure
    processed = _normalizeWhitespace(processed);
    
    return processed;
  }

  /// Preserve code blocks during chunking
  String _preserveCodeBlocks(String content) {
    final codeBlockRegex = RegExp(r'```[\s\S]*?```', multiLine: true);
    final matches = codeBlockRegex.allMatches(content);
    
    String result = content;
    int offset = 0;
    
    for (final match in matches) {
      final codeBlock = match.group(0)!;
      
      // Replace newlines in code blocks with special markers
      final preservedBlock = codeBlock.replaceAll('\n', '§NEWLINE§');
      
      result = result.replaceRange(
        match.start + offset,
        match.end + offset,
        preservedBlock,
      );
      
      offset += preservedBlock.length - codeBlock.length;
    }
    
    return result;
  }

  /// Preserve table structures during chunking
  String _preserveTables(String content) {
    final tableRegex = RegExp(r'\|.*\|[\s]*\n\|[-\s\|]*\|[\s]*\n(?:\|.*\|[\s]*\n)*', multiLine: true);
    final matches = tableRegex.allMatches(content);
    
    String result = content;
    int offset = 0;
    
    for (final match in matches) {
      final table = match.group(0)!;
      
      // Replace newlines in tables with special markers
      final preservedTable = table.replaceAll('\n', '§TABLENEWLINE§');
      
      result = result.replaceRange(
        match.start + offset,
        match.end + offset,
        preservedTable,
      );
      
      offset += preservedTable.length - table.length;
    }
    
    return result;
  }

  /// Normalize whitespace while preserving document structure
  String _normalizeWhitespace(String content) {
    return content
        // Remove excessive blank lines (more than 2)
        .replaceAll(RegExp(r'\n\s*\n\s*\n\s*\n+'), '\n\n\n')
        // Remove trailing whitespace from lines
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        // Remove leading/trailing whitespace from the whole content
        .trim();
  }

  /// Recursively split text using different separators
  List<String> _recursiveTextSplit(String text) {
    return _splitTextRecursive(text, config.separators);
  }

  List<String> _splitTextRecursive(String text, List<String> separators) {
    if (text.length <= config.chunkSize) {
      return [text];
    }

    if (separators.isEmpty) {
      return _splitByLength(text);
    }

    final separator = separators.first;
    final remainingSeparators = separators.skip(1).toList();
    
    final splits = text.split(separator);
    
    if (splits.length == 1) {
      // Separator not found, try next separator
      return _splitTextRecursive(text, remainingSeparators);
    }

    // Merge splits to create optimal chunks
    final chunks = <String>[];
    String currentChunk = '';

    for (final split in splits) {
      final potentialChunk = currentChunk.isEmpty 
          ? split 
          : '$currentChunk$separator$split';

      if (potentialChunk.length <= config.chunkSize) {
        currentChunk = potentialChunk;
      } else {
        // Current chunk would be too large
        if (currentChunk.isNotEmpty) {
          chunks.add(_restoreSpecialMarkers(currentChunk));
          currentChunk = '';
        }

        // If this split is still too large, split it recursively
        if (split.length > config.chunkSize) {
          chunks.addAll(_splitTextRecursive(split, remainingSeparators));
        } else {
          currentChunk = split;
        }
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(_restoreSpecialMarkers(currentChunk));
    }

    // Apply overlap if configured
    if (config.chunkOverlap > 0 && chunks.length > 1) {
      return _applyOverlap(chunks);
    }

    return chunks.where((chunk) => chunk.trim().length >= config.minChunkSize).toList();
  }

  /// Split text by fixed length when no separators work
  List<String> _splitByLength(String text) {
    final chunks = <String>[];
    
    for (int i = 0; i < text.length; i += config.chunkSize) {
      final end = min(i + config.chunkSize, text.length);
      chunks.add(_restoreSpecialMarkers(text.substring(i, end)));
    }
    
    return chunks;
  }

  /// Apply overlap between chunks to maintain context
  List<String> _applyOverlap(List<String> chunks) {
    if (chunks.length <= 1) return chunks;

    final overlappedChunks = <String>[];
    
    for (int i = 0; i < chunks.length; i++) {
      String chunk = chunks[i];
      
      // Add overlap from previous chunk
      if (i > 0 && config.chunkOverlap > 0) {
        final prevChunk = chunks[i - 1];
        final overlapText = _getOverlapText(prevChunk, config.chunkOverlap);
        if (overlapText.isNotEmpty) {
          chunk = '$overlapText\n\n$chunk';
        }
      }
      
      overlappedChunks.add(chunk);
    }
    
    return overlappedChunks;
  }

  /// Get overlap text from the end of a chunk
  String _getOverlapText(String text, int overlapSize) {
    if (text.length <= overlapSize) return text;
    
    // Try to find a natural break point near the overlap size
    final startPos = text.length - overlapSize;
    final searchText = text.substring(startPos);
    
    // Look for sentence boundaries
    final sentenceEnd = RegExp(r'[.!?]\s+').firstMatch(searchText);
    if (sentenceEnd != null) {
      return text.substring(startPos + sentenceEnd.end);
    }
    
    // Look for paragraph boundaries
    final paragraphEnd = searchText.indexOf('\n\n');
    if (paragraphEnd != -1) {
      return text.substring(startPos + paragraphEnd + 2);
    }
    
    // Fallback to character-based overlap
    return text.substring(startPos);
  }

  /// Restore special markers used to preserve structure
  String _restoreSpecialMarkers(String text) {
    return text
        .replaceAll('§NEWLINE§', '\n')
        .replaceAll('§TABLENEWLINE§', '\n');
  }

  /// Find the position of text within the original document
  int _findTextPosition(String document, String searchText, int startPos) {
    // Remove special markers for search
    final cleanSearchText = _restoreSpecialMarkers(searchText).trim();
    final cleanDocument = document.substring(startPos);
    
    final pos = cleanDocument.indexOf(cleanSearchText);
    return pos == -1 ? startPos : startPos + pos;
  }

  /// Count words in text
  int _countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Check if text contains code
  bool _containsCode(String text) {
    // Look for common code patterns
    final codePatterns = [
      RegExp(r'```[\s\S]*?```'), // Code blocks
      RegExp(r'`[^`]+`'), // Inline code
      RegExp(r'^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\([^)]*\)\s*{', multiLine: true), // Function definitions
      RegExp(r'^\s*(class|interface|enum|function|def|var|let|const)\s+', multiLine: true), // Keywords
      RegExp(r'[{}();]'), // Common code symbols
    ];

    return codePatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Check if text contains table structures
  bool _containsTable(String text) {
    // Look for markdown tables or similar structures
    final tablePatterns = [
      RegExp(r'\|.*\|'), // Markdown table rows
      RegExp(r'^\s*[-\|]+\s*$', multiLine: true), // Table separators
    ];

    return tablePatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Identify the type of content section
  String _identifySectionType(String text) {
    final cleanText = text.trim().toLowerCase();
    
    if (_containsCode(text)) return 'code';
    if (_containsTable(text)) return 'table';
    
    // Look for headings
    if (RegExp(r'^#+\s+').hasMatch(text)) return 'heading';
    if (RegExp(r'^[A-Z][^.!?]*:?\s*$', multiLine: true).hasMatch(text)) return 'heading';
    
    // Look for lists
    if (RegExp(r'^\s*[-*+]\s+', multiLine: true).hasMatch(text) ||
        RegExp(r'^\s*\d+\.\s+', multiLine: true).hasMatch(text)) {
      return 'list';
    }
    
    // Look for quotes
    if (RegExp(r'^\s*>', multiLine: true).hasMatch(text)) return 'quote';
    
    // Default to paragraph
    return 'paragraph';
  }

  /// Get chunking statistics for analysis
  Map<String, dynamic> getChunkingStats(List<VectorChunk> chunks) {
    if (chunks.isEmpty) {
      return {
        'total_chunks': 0,
        'avg_chunk_size': 0,
        'min_chunk_size': 0,
        'max_chunk_size': 0,
        'section_types': {},
      };
    }

    final sizes = chunks.map((c) => c.text.length).toList();
    final sectionTypes = <String, int>{};

    for (final chunk in chunks) {
      final sectionType = chunk.metadata['section_type']?.toString() ?? 'unknown';
      sectionTypes[sectionType] = (sectionTypes[sectionType] ?? 0) + 1;
    }

    return {
      'total_chunks': chunks.length,
      'avg_chunk_size': sizes.reduce((a, b) => a + b) / sizes.length,
      'min_chunk_size': sizes.reduce(min),
      'max_chunk_size': sizes.reduce(max),
      'section_types': sectionTypes,
      'total_characters': sizes.reduce((a, b) => a + b),
      'avg_words_per_chunk': chunks
          .map((c) => _countWords(c.text))
          .reduce((a, b) => a + b) / chunks.length,
    };
  }
}