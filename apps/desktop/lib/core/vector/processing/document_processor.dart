import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../models/vector_models.dart';

/// Document processor that extracts text from various file formats
class DocumentProcessor {
  static const Map<String, String> _supportedExtensions = {
    '.txt': 'text/plain',
    '.md': 'text/markdown',
    '.json': 'application/json',
    '.csv': 'text/csv',
    '.html': 'text/html',
    '.xml': 'text/xml',
    '.log': 'text/plain',
    '.yaml': 'text/yaml',
    '.yml': 'text/yaml',
  };

  /// Check if a file type is supported
  static bool isSupported(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return _supportedExtensions.containsKey(extension);
  }

  /// Get all supported file extensions
  static List<String> getSupportedExtensions() {
    return _supportedExtensions.keys.toList();
  }

  /// Process a file and create a VectorDocument
  static Future<VectorDocument> processFile(File file, {
    Map<String, dynamic>? additionalMetadata,
  }) async {
    if (!await file.exists()) {
      throw DocumentProcessorException('File does not exist: ${file.path}');
    }

    final extension = path.extension(file.path).toLowerCase();
    if (!_supportedExtensions.containsKey(extension)) {
      throw DocumentProcessorException('Unsupported file type: $extension');
    }

    print('📄 Processing file: ${file.path}');

    try {
      // Extract text content based on file type
      final content = await _extractContent(file, extension);
      
      // Get file stats
      final stats = await file.stat();
      
      // Create document metadata
      final metadata = {
        'file_path': file.absolute.path,
        'file_name': path.basename(file.path),
        'file_extension': extension,
        'file_size': stats.size,
        'modified': stats.modified.toIso8601String(),
        'processed_at': DateTime.now().toIso8601String(),
        'word_count': _countWords(content),
        'char_count': content.length,
        'line_count': content.split('\n').length,
        ...additionalMetadata ?? {},
      };

      // Generate document ID from file path hash
      final documentId = _generateDocumentId(file.path);
      
      // Extract title from filename or content
      final title = _extractTitle(file, content);

      return VectorDocument(
        id: documentId,
        title: title,
        content: content,
        metadata: metadata,
        createdAt: stats.modified,
        updatedAt: DateTime.now(),
        source: file.absolute.path,
        contentType: _supportedExtensions[extension]!,
      );

    } catch (e) {
      throw DocumentProcessorException('Failed to process file ${file.path}: $e');
    }
  }

  /// Extract content based on file type
  static Future<String> _extractContent(File file, String extension) async {
    switch (extension) {
      case '.txt':
      case '.md':
      case '.log':
      case '.yaml':
      case '.yml':
        return await _extractPlainText(file);
      
      case '.json':
        return await _extractJSON(file);
      
      case '.csv':
        return await _extractCSV(file);
      
      case '.html':
        return await _extractHTML(file);
      
      case '.xml':
        return await _extractXML(file);
      
      default:
        return await _extractPlainText(file);
    }
  }

  /// Extract plain text content
  static Future<String> _extractPlainText(File file) async {
    final content = await file.readAsString(encoding: utf8);
    return _cleanText(content);
  }

  /// Extract and format JSON content
  static Future<String> _extractJSON(File file) async {
    final content = await file.readAsString(encoding: utf8);
    
    try {
      // Parse JSON to validate and pretty-print
      final jsonData = jsonDecode(content);
      
      // Convert to readable format
      final buffer = StringBuffer();
      _jsonToText(jsonData, buffer, 0);
      
      return buffer.toString();
    } catch (e) {
      // Fallback to raw content if JSON parsing fails
      return content;
    }
  }

  /// Convert JSON data to readable text format
  static void _jsonToText(dynamic data, StringBuffer buffer, int indent) {
    final indentStr = '  ' * indent;
    
    if (data is Map<String, dynamic>) {
      for (final entry in data.entries) {
        buffer.writeln('$indentStr${entry.key}:');
        _jsonToText(entry.value, buffer, indent + 1);
      }
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        buffer.writeln('$indentStr[$i]:');
        _jsonToText(data[i], buffer, indent + 1);
      }
    } else {
      buffer.writeln('$indentStr$data');
    }
  }

  /// Extract and format CSV content
  static Future<String> _extractCSV(File file) async {
    final content = await file.readAsString(encoding: utf8);
    final lines = content.split('\n');
    
    if (lines.isEmpty) return '';
    
    final buffer = StringBuffer();
    
    // Process header
    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    buffer.writeln('CSV Data with columns: ${headers.join(', ')}');
    buffer.writeln();
    
    // Process data rows
    for (int i = 1; i < lines.length && i <= 100; i++) { // Limit to first 100 rows
      final row = lines[i].split(',').map((cell) => cell.trim()).toList();
      if (row.length == headers.length) {
        for (int j = 0; j < headers.length; j++) {
          buffer.writeln('${headers[j]}: ${row[j]}');
        }
        buffer.writeln('---');
      }
    }
    
    if (lines.length > 101) {
      buffer.writeln('... (${lines.length - 101} more rows)');
    }
    
    return buffer.toString();
  }

  /// Extract text from HTML (basic implementation)
  static Future<String> _extractHTML(File file) async {
    final content = await file.readAsString(encoding: utf8);
    
    // Basic HTML tag removal (not perfect, but functional)
    String text = content
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&\w+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    
    return _cleanText(text);
  }

  /// Extract text from XML (basic implementation)
  static Future<String> _extractXML(File file) async {
    final content = await file.readAsString(encoding: utf8);
    
    // Basic XML tag removal
    String text = content
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    
    return _cleanText(text);
  }

  /// Clean and normalize text
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\r'), '\n')
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // Reduce excessive line breaks
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Normalize spaces
        .trim();
  }

  /// Generate a consistent document ID from file path
  static String _generateDocumentId(String filePath) {
    return 'doc_${filePath.hashCode.abs()}';
  }

  /// Extract title from file or content
  static String _extractTitle(File file, String content) {
    final fileName = path.basenameWithoutExtension(file.path);
    
    // Try to extract title from content (for markdown files)
    final extension = path.extension(file.path).toLowerCase();
    if (extension == '.md') {
      final firstLine = content.split('\n').first.trim();
      if (firstLine.startsWith('#')) {
        return firstLine.replaceFirst(RegExp(r'^#+\s*'), '').trim();
      }
    }
    
    // Try to extract title from HTML
    if (extension == '.html') {
      final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false).firstMatch(content);
      if (titleMatch != null) {
        return titleMatch.group(1)!.trim();
      }
    }
    
    // Fallback to filename
    return fileName.replaceAll(RegExp(r'[_-]'), ' ');
  }

  /// Count words in text
  static int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Process multiple files in a directory
  static Future<List<VectorDocument>> processDirectory(
    Directory directory, {
    bool recursive = false,
    List<String>? includeExtensions,
    List<String>? excludeExtensions,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    if (!await directory.exists()) {
      throw DocumentProcessorException('Directory does not exist: ${directory.path}');
    }

    print('📁 Processing directory: ${directory.path}');

    final documents = <VectorDocument>[];
    final files = directory.listSync(recursive: recursive)
        .whereType<File>()
        .where((file) => _shouldProcessFile(file, includeExtensions, excludeExtensions));

    for (final file in files) {
      try {
        final document = await processFile(file, additionalMetadata: {
          'directory': directory.path,
          'relative_path': path.relative(file.path, from: directory.path),
          ...additionalMetadata ?? {},
        });
        documents.add(document);
      } catch (e) {
        print('⚠️ Failed to process file ${file.path}: $e');
        // Continue processing other files
      }
    }

    print('✅ Processed ${documents.length} files from ${directory.path}');
    return documents;
  }

  /// Check if a file should be processed based on filters
  static bool _shouldProcessFile(
    File file,
    List<String>? includeExtensions,
    List<String>? excludeExtensions,
  ) {
    final extension = path.extension(file.path).toLowerCase();
    
    // Check if supported
    if (!isSupported(file.path)) return false;
    
    // Check include filter
    if (includeExtensions != null && !includeExtensions.contains(extension)) {
      return false;
    }
    
    // Check exclude filter
    if (excludeExtensions != null && excludeExtensions.contains(extension)) {
      return false;
    }
    
    return true;
  }

  /// Get document processing statistics
  static Future<DocumentProcessingStats> getProcessingStats(List<VectorDocument> documents) async {
    final stats = DocumentProcessingStats();
    
    for (final doc in documents) {
      stats.totalDocuments++;
      stats.totalCharacters += doc.content.length;
      stats.totalWords += doc.metadata['word_count'] as int? ?? 0;
      
      final contentType = doc.contentType;
      stats.documentsByType[contentType] = (stats.documentsByType[contentType] ?? 0) + 1;
      
      final fileSize = doc.metadata['file_size'] as int? ?? 0;
      stats.totalFileSize += fileSize;
    }
    
    stats.averageWordsPerDocument = stats.totalDocuments > 0 
        ? stats.totalWords / stats.totalDocuments
        : 0;
    
    stats.averageCharsPerDocument = stats.totalDocuments > 0
        ? stats.totalCharacters / stats.totalDocuments
        : 0;
    
    return stats;
  }
}

/// Statistics for document processing
class DocumentProcessingStats {
  int totalDocuments = 0;
  int totalWords = 0;
  int totalCharacters = 0;
  int totalFileSize = 0;
  double averageWordsPerDocument = 0;
  double averageCharsPerDocument = 0;
  Map<String, int> documentsByType = {};

  Map<String, dynamic> toJson() {
    return {
      'totalDocuments': totalDocuments,
      'totalWords': totalWords,
      'totalCharacters': totalCharacters,
      'totalFileSize': totalFileSize,
      'averageWordsPerDocument': averageWordsPerDocument,
      'averageCharsPerDocument': averageCharsPerDocument,
      'documentsByType': documentsByType,
    };
  }

  @override
  String toString() {
    return '''DocumentProcessingStats:
- Total documents: $totalDocuments
- Total words: $totalWords
- Total characters: $totalCharacters
- Total file size: ${(totalFileSize / 1024 / 1024).toStringAsFixed(2)} MB
- Average words per document: ${averageWordsPerDocument.toStringAsFixed(1)}
- Average characters per document: ${averageCharsPerDocument.toStringAsFixed(1)}
- Documents by type: $documentsByType''';
  }
}

/// Exception for document processing errors
class DocumentProcessorException implements Exception {
  final String message;
  final dynamic originalError;

  const DocumentProcessorException(this.message, [this.originalError]);

  @override
  String toString() {
    final buffer = StringBuffer('DocumentProcessorException: $message');
    if (originalError != null) {
      buffer.write(' (caused by: $originalError)');
    }
    return buffer.toString();
  }
}