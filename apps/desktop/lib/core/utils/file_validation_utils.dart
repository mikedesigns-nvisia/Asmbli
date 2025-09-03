import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class FileValidationResult {
  final bool isValid;
  final String? error;
  final String? warning;
  final int fileSize;
  final String formattedSize;
  
  const FileValidationResult({
    required this.isValid,
    this.error,
    this.warning,
    required this.fileSize,
    required this.formattedSize,
  });
}

class ContextValidationResult {
  final bool isValid;
  final String? error;
  final int totalSize;
  final String formattedTotalSize;
  final List<FileValidationResult> fileResults;
  
  const ContextValidationResult({
    required this.isValid,
    this.error,
    required this.totalSize,
    required this.formattedTotalSize,
    required this.fileResults,
  });
}

/// Comprehensive file validation utility for context documents
class FileValidationUtils {
  // File size limits
  static const int MAX_INDIVIDUAL_FILE_SIZE = 10 * 1024 * 1024; // 10MB
  static const int MAX_TOTAL_CONTEXT_SIZE = 100 * 1024 * 1024; // 100MB
  static const int CHUNK_SIZE = 1024 * 1024; // 1MB chunks
  static const int WARNING_FILE_SIZE = 5 * 1024 * 1024; // 5MB warning threshold
  
  // Allowed file types and their MIME types
  static const Map<String, List<String>> ALLOWED_TYPES = {
    '.txt': ['text/plain'],
    '.md': ['text/markdown', 'text/plain'],
    '.pdf': ['application/pdf'],
    '.json': ['application/json', 'text/plain'],
    '.csv': ['text/csv', 'application/csv'],
    '.docx': ['application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
    '.doc': ['application/msword'],
    '.rtf': ['application/rtf', 'text/rtf'],
    '.xml': ['application/xml', 'text/xml'],
  };
  
  // File type detection by content (magic numbers)
  static const Map<String, List<int>> FILE_SIGNATURES = {
    'pdf': [0x25, 0x50, 0x44, 0x46], // %PDF
    'docx': [0x50, 0x4B, 0x03, 0x04], // ZIP-based formats
    'doc': [0xD0, 0xCF, 0x11, 0xE0], // MS Office legacy
    'rtf': [0x7B, 0x5C, 0x72, 0x74], // {\rt
  };
  
  /// Validates a single PlatformFile
  static FileValidationResult validatePlatformFile(PlatformFile file) {
    final size = file.size;
    final formattedSize = formatBytes(size);
    final extension = path.extension(file.name).toLowerCase();
    
    // Check if file type is allowed
    if (!ALLOWED_TYPES.containsKey(extension)) {
      return FileValidationResult(
        isValid: false,
        error: 'File type "$extension" is not supported. Allowed types: ${ALLOWED_TYPES.keys.join(', ')}',
        fileSize: size,
        formattedSize: formattedSize,
      );
    }
    
    // Check file size limits
    if (size > MAX_INDIVIDUAL_FILE_SIZE) {
      return FileValidationResult(
        isValid: false,
        error: 'File size ($formattedSize) exceeds the ${formatBytes(MAX_INDIVIDUAL_FILE_SIZE)} limit',
        fileSize: size,
        formattedSize: formattedSize,
      );
    }
    
    // Check for empty files
    if (size == 0) {
      return FileValidationResult(
        isValid: false,
        error: 'File is empty',
        fileSize: size,
        formattedSize: formattedSize,
      );
    }
    
    // Add warning for large files
    String? warning;
    if (size > WARNING_FILE_SIZE) {
      warning = 'Large file ($formattedSize) may take longer to process';
    }
    
    return FileValidationResult(
      isValid: true,
      warning: warning,
      fileSize: size,
      formattedSize: formattedSize,
    );
  }
  
  /// Validates a File object
  static FileValidationResult validateFile(File file) {
    try {
      final size = file.lengthSync();
      final formattedSize = formatBytes(size);
      final extension = path.extension(file.path).toLowerCase();
      
      // Check if file exists
      if (!file.existsSync()) {
        return const FileValidationResult(
          isValid: false,
          error: 'File does not exist',
          fileSize: 0,
          formattedSize: '0 B',
        );
      }
      
      // Check if file type is allowed
      if (!ALLOWED_TYPES.containsKey(extension)) {
        return FileValidationResult(
          isValid: false,
          error: 'File type "$extension" is not supported. Allowed types: ${ALLOWED_TYPES.keys.join(', ')}',
          fileSize: size,
          formattedSize: formattedSize,
        );
      }
      
      // Check file size limits
      if (size > MAX_INDIVIDUAL_FILE_SIZE) {
        return FileValidationResult(
          isValid: false,
          error: 'File size ($formattedSize) exceeds the ${formatBytes(MAX_INDIVIDUAL_FILE_SIZE)} limit',
          fileSize: size,
          formattedSize: formattedSize,
        );
      }
      
      // Check for empty files
      if (size == 0) {
        return FileValidationResult(
          isValid: false,
          error: 'File is empty',
          fileSize: size,
          formattedSize: formattedSize,
        );
      }
      
      // Validate file content type by reading first few bytes
      if (!_validateFileSignature(file, extension)) {
        return FileValidationResult(
          isValid: false,
          error: 'File content does not match the expected file type',
          fileSize: size,
          formattedSize: formattedSize,
        );
      }
      
      // Add warning for large files
      String? warning;
      if (size > WARNING_FILE_SIZE) {
        warning = 'Large file ($formattedSize) may take longer to process';
      }
      
      return FileValidationResult(
        isValid: true,
        warning: warning,
        fileSize: size,
        formattedSize: formattedSize,
      );
    } catch (e) {
      return FileValidationResult(
        isValid: false,
        error: 'Error reading file: $e',
        fileSize: 0,
        formattedSize: '0 B',
      );
    }
  }
  
  /// Validates multiple files as a context collection
  static ContextValidationResult validateContextFiles(List<PlatformFile> files) {
    final fileResults = <FileValidationResult>[];
    int totalSize = 0;
    bool hasInvalidFiles = false;
    
    // Validate each file
    for (final file in files) {
      final result = validatePlatformFile(file);
      fileResults.add(result);
      
      if (result.isValid) {
        totalSize += result.fileSize;
      } else {
        hasInvalidFiles = true;
      }
    }
    
    final formattedTotalSize = formatBytes(totalSize);
    
    // Check total size limit
    if (totalSize > MAX_TOTAL_CONTEXT_SIZE) {
      return ContextValidationResult(
        isValid: false,
        error: 'Total context size ($formattedTotalSize) exceeds the ${formatBytes(MAX_TOTAL_CONTEXT_SIZE)} limit',
        totalSize: totalSize,
        formattedTotalSize: formattedTotalSize,
        fileResults: fileResults,
      );
    }
    
    // Check if any individual files are invalid
    if (hasInvalidFiles) {
      return ContextValidationResult(
        isValid: false,
        error: 'Some files are invalid',
        totalSize: totalSize,
        formattedTotalSize: formattedTotalSize,
        fileResults: fileResults,
      );
    }
    
    // Check for no files
    if (files.isEmpty) {
      return const ContextValidationResult(
        isValid: false,
        error: 'No files selected',
        totalSize: 0,
        formattedTotalSize: '0 B',
        fileResults: [],
      );
    }
    
    return ContextValidationResult(
      isValid: true,
      totalSize: totalSize,
      formattedTotalSize: formattedTotalSize,
      fileResults: fileResults,
    );
  }
  
  /// Validates file signature (magic numbers) against expected type
  static bool _validateFileSignature(File file, String extension) {
    try {
      // Skip signature validation for text-based files
      if (['.txt', '.md', '.csv', '.json', '.xml', '.rtf'].contains(extension)) {
        return true;
      }
      
      // Read first 8 bytes for signature validation
      final bytes = file.openSync(mode: FileMode.read);
      final buffer = Uint8List(8);
      final bytesRead = bytes.readIntoSync(buffer);
      bytes.closeSync();
      
      if (bytesRead == 0) return false;
      
      // Check against known signatures
      final expectedSignatures = {
        '.pdf': FILE_SIGNATURES['pdf']!,
        '.docx': FILE_SIGNATURES['docx']!,
        '.doc': FILE_SIGNATURES['doc']!,
      };
      
      final expectedSignature = expectedSignatures[extension];
      if (expectedSignature != null) {
        if (bytesRead < expectedSignature.length) return false;
        
        for (int i = 0; i < expectedSignature.length; i++) {
          if (buffer[i] != expectedSignature[i]) {
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      // If we can't validate signature, allow the file
      return true;
    }
  }
  
  /// Chunks large file content for processing
  static Future<List<String>> chunkFileContent(File file) async {
    try {
      final chunks = <String>[];
      final size = file.lengthSync();
      
      if (size <= CHUNK_SIZE) {
        // Small file, read entire content
        final content = await file.readAsString();
        chunks.add(content);
        return chunks;
      }
      
      // Large file, chunk it
      final stream = file.openRead();
      final buffer = StringBuffer();
      int bytesRead = 0;
      
      await for (final data in stream) {
        buffer.write(utf8.decode(data));
        bytesRead += data.length;
        
        // When buffer reaches chunk size or we've read the entire file
        if (buffer.length >= CHUNK_SIZE || bytesRead >= size) {
          chunks.add(buffer.toString());
          buffer.clear();
        }
      }
      
      // Add any remaining content
      if (buffer.isNotEmpty) {
        chunks.add(buffer.toString());
      }
      
      return chunks;
    } catch (e) {
      throw Exception('Failed to chunk file content: $e');
    }
  }
  
  /// Formats bytes into human-readable format
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Gets user-friendly error messages
  static String getValidationSummary(ContextValidationResult result) {
    if (result.isValid) {
      final warnings = result.fileResults
          .where((r) => r.warning != null)
          .map((r) => r.warning!)
          .toList();
      
      if (warnings.isNotEmpty) {
        return 'Validation successful with warnings: ${warnings.join(', ')}';
      }
      
      return 'All files validated successfully (${result.formattedTotalSize} total)';
    }
    
    final errors = result.fileResults
        .where((r) => !r.isValid)
        .map((r) => r.error!)
        .toSet()
        .toList();
    
    if (result.error != null) {
      errors.insert(0, result.error!);
    }
    
    return errors.join('\n');
  }
}