import 'dart:convert';
import 'dart:io';
import '../error/app_error_handler.dart';

/// Production-grade input validation system
class InputValidator {
  /// Validate email address
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ValidationResult.invalid('Email is required');
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
    );

    if (!emailRegex.hasMatch(email)) {
      return ValidationResult.invalid('Please enter a valid email address');
    }

    if (email.length > 254) {
      return ValidationResult.invalid('Email address is too long');
    }

    return ValidationResult.valid();
  }

  /// Validate URL
  static ValidationResult validateUrl(String? url, {bool requireHttps = false}) {
    if (url == null || url.isEmpty) {
      return ValidationResult.invalid('URL is required');
    }

    try {
      final uri = Uri.parse(url);
      
      if (!uri.hasScheme) {
        return ValidationResult.invalid('URL must include protocol (http:// or https://)');
      }

      if (requireHttps && uri.scheme != 'https') {
        return ValidationResult.invalid('URL must use HTTPS protocol');
      }

      if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
        return ValidationResult.invalid('URL must use HTTP or HTTPS protocol');
      }

      if (uri.host.isEmpty) {
        return ValidationResult.invalid('URL must include a valid host');
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Please enter a valid URL');
    }
  }

  /// Validate file path
  static ValidationResult validateFilePath(String? path, {
    bool mustExist = false,
    bool mustBeFile = false,
    bool mustBeDirectory = false,
    List<String>? allowedExtensions,
  }) {
    if (path == null || path.isEmpty) {
      return ValidationResult.invalid('File path is required');
    }

    // Check for path traversal attempts
    if (path.contains('..')) {
      return ValidationResult.invalid('Path traversal is not allowed');
    }

    // Check for null bytes
    if (path.contains('\x00')) {
      return ValidationResult.invalid('Path contains invalid characters');
    }

    try {
      final file = File(path);
      final directory = Directory(path);

      if (mustExist) {
        if (mustBeFile && !file.existsSync()) {
          return ValidationResult.invalid('File does not exist: $path');
        }
        if (mustBeDirectory && !directory.existsSync()) {
          return ValidationResult.invalid('Directory does not exist: $path');
        }
        if (!mustBeFile && !mustBeDirectory && !file.existsSync() && !directory.existsSync()) {
          return ValidationResult.invalid('Path does not exist: $path');
        }
      }

      if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
        final extension = path.split('.').last.toLowerCase();
        if (!allowedExtensions.contains(extension)) {
          return ValidationResult.invalid(
            'File must have one of these extensions: ${allowedExtensions.join(', ')}'
          );
        }
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Invalid file path: ${e.toString()}');
    }
  }

  /// Validate JSON string
  static ValidationResult validateJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return ValidationResult.invalid('JSON is required');
    }

    try {
      json.decode(jsonString);
      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Invalid JSON format: ${e.toString()}');
    }
  }

  /// Validate port number
  static ValidationResult validatePort(int? port) {
    if (port == null) {
      return ValidationResult.invalid('Port number is required');
    }

    if (port < 1 || port > 65535) {
      return ValidationResult.invalid('Port must be between 1 and 65535');
    }

    // Check for commonly restricted ports
    const restrictedPorts = [22, 25, 110, 143, 993, 995];
    if (restrictedPorts.contains(port)) {
      return ValidationResult.invalid('Port $port is restricted for security reasons');
    }

    return ValidationResult.valid();
  }

  /// Validate string length
  static ValidationResult validateLength(
    String? value, {
    int? min,
    int? max,
    String fieldName = 'Field',
  }) {
    if (value == null) {
      if (min != null && min > 0) {
        return ValidationResult.invalid('$fieldName is required');
      }
      return ValidationResult.valid();
    }

    if (min != null && value.length < min) {
      return ValidationResult.invalid(
        '$fieldName must be at least $min characters long'
      );
    }

    if (max != null && value.length > max) {
      return ValidationResult.invalid(
        '$fieldName must be no more than $max characters long'
      );
    }

    return ValidationResult.valid();
  }

  /// Validate required field
  static ValidationResult validateRequired(
    dynamic value, {
    String fieldName = 'Field',
  }) {
    if (value == null || 
        (value is String && value.trim().isEmpty) ||
        (value is List && value.isEmpty) ||
        (value is Map && value.isEmpty)) {
      return ValidationResult.invalid('$fieldName is required');
    }

    return ValidationResult.valid();
  }

  /// Validate numeric range
  static ValidationResult validateNumericRange(
    num? value, {
    num? min,
    num? max,
    String fieldName = 'Value',
  }) {
    if (value == null) {
      return ValidationResult.invalid('$fieldName is required');
    }

    if (min != null && value < min) {
      return ValidationResult.invalid('$fieldName must be at least $min');
    }

    if (max != null && value > max) {
      return ValidationResult.invalid('$fieldName must be no more than $max');
    }

    return ValidationResult.valid();
  }

  /// Validate against regex pattern
  static ValidationResult validatePattern(
    String? value,
    RegExp pattern, {
    required String errorMessage,
    String fieldName = 'Field',
  }) {
    if (value == null || value.isEmpty) {
      return ValidationResult.invalid('$fieldName is required');
    }

    if (!pattern.hasMatch(value)) {
      return ValidationResult.invalid(errorMessage);
    }

    return ValidationResult.valid();
  }

  /// Validate OAuth provider name
  static ValidationResult validateOAuthProvider(String? provider) {
    if (provider == null || provider.isEmpty) {
      return ValidationResult.invalid('OAuth provider is required');
    }

    const validProviders = ['github', 'slack', 'linear', 'microsoft'];
    if (!validProviders.contains(provider.toLowerCase())) {
      return ValidationResult.invalid(
        'Provider must be one of: ${validProviders.join(', ')}'
      );
    }

    return ValidationResult.valid();
  }

  /// Validate MCP server ID
  static ValidationResult validateMcpServerId(String? serverId) {
    if (serverId == null || serverId.isEmpty) {
      return ValidationResult.invalid('Server ID is required');
    }

    // Server ID must be alphanumeric with dashes and underscores
    final serverIdRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!serverIdRegex.hasMatch(serverId)) {
      return ValidationResult.invalid(
        'Server ID can only contain letters, numbers, dashes, and underscores'
      );
    }

    if (serverId.length < 3 || serverId.length > 50) {
      return ValidationResult.invalid('Server ID must be between 3 and 50 characters');
    }

    return ValidationResult.valid();
  }

  /// Validate environment variables
  static ValidationResult validateEnvironmentKey(String? key) {
    if (key == null || key.isEmpty) {
      return ValidationResult.invalid('Environment key is required');
    }

    // Environment keys should be UPPER_CASE with underscores
    final envKeyRegex = RegExp(r'^[A-Z][A-Z0-9_]*[A-Z0-9]$');
    if (!envKeyRegex.hasMatch(key)) {
      return ValidationResult.invalid(
        'Environment key must be in UPPER_CASE format with underscores'
      );
    }

    if (key.length > 100) {
      return ValidationResult.invalid('Environment key is too long (max 100 characters)');
    }

    return ValidationResult.valid();
  }

  /// Sanitize string input
  static String sanitizeString(String? input, {
    bool removeHtml = true,
    bool removeScripts = true,
    bool trimWhitespace = true,
  }) {
    if (input == null) return '';

    String sanitized = input;

    if (trimWhitespace) {
      sanitized = sanitized.trim();
    }

    if (removeHtml) {
      // Remove HTML tags
      sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    }

    if (removeScripts) {
      // Remove potentially dangerous content
      sanitized = sanitized.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, multiLine: true), '');
      sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
      sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
    }

    return sanitized;
  }

  /// Validate multiple fields at once
  static ValidationResultCollection validateFields(Map<String, ValidationResult Function()> validators) {
    final results = <String, ValidationResult>{};
    bool hasErrors = false;

    for (final entry in validators.entries) {
      final result = entry.value();
      results[entry.key] = result;
      if (!result.isValid) {
        hasErrors = true;
      }
    }

    return ValidationResultCollection(results, !hasErrors);
  }

  /// Create validation exception for invalid input
  static ValidationException createValidationException(
    String field,
    String message, {
    dynamic value,
    Map<String, dynamic>? context,
  }) {
    return AppErrorHandler.handleValidationError(
      field,
      message,
      value: value,
      context: context,
    );
  }
}

/// Validation result for a single field
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._(this.isValid, this.errorMessage);

  factory ValidationResult.valid() => const ValidationResult._(true, null);
  factory ValidationResult.invalid(String message) => ValidationResult._(false, message);

  /// Throw validation exception if invalid
  void throwIfInvalid(String field, {dynamic value, Map<String, dynamic>? context}) {
    if (!isValid) {
      throw InputValidator.createValidationException(
        field,
        errorMessage!,
        value: value,
        context: context,
      );
    }
  }
}

/// Collection of validation results
class ValidationResultCollection {
  final Map<String, ValidationResult> results;
  final bool isValid;

  const ValidationResultCollection(this.results, this.isValid);

  /// Get first error message
  String? get firstError {
    for (final result in results.values) {
      if (!result.isValid) {
        return result.errorMessage;
      }
    }
    return null;
  }

  /// Get all error messages
  List<String> get allErrors {
    return results.values
        .where((result) => !result.isValid)
        .map((result) => result.errorMessage!)
        .toList();
  }

  /// Get errors by field name
  Map<String, String> get errorsByField {
    return results.entries
        .where((entry) => !entry.value.isValid)
        .fold<Map<String, String>>({}, (map, entry) {
      map[entry.key] = entry.value.errorMessage!;
      return map;
    });
  }

  /// Throw validation exception with all errors if invalid
  void throwIfInvalid({Map<String, dynamic>? context}) {
    if (!isValid) {
      final firstError = results.entries.firstWhere((entry) => !entry.value.isValid);
      throw InputValidator.createValidationException(
        firstError.key,
        firstError.value.errorMessage!,
        context: {
          'all_errors': errorsByField,
          ...?context,
        },
      );
    }
  }
}

/// Common validation patterns
class ValidationPatterns {
  static final RegExp alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
  static final RegExp alphanumericWithSpaces = RegExp(r'^[a-zA-Z0-9\s]+$');
  static final RegExp username = RegExp(r'^[a-zA-Z0-9_-]{3,30}$');
  static final RegExp strongPassword = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
  static final RegExp hexColor = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
  static final RegExp ipAddress = RegExp(r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
  static final RegExp semver = RegExp(r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$');
}