import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../validation/input_validator.dart';
import '../error/app_error_handler.dart';

/// Security validation and sanitization utilities
class SecurityValidator {
  /// Validate OAuth state parameter for CSRF protection
  static ValidationResult validateOAuthState(String? state, String expectedState) {
    if (state == null || state.isEmpty) {
      return ValidationResult.invalid('OAuth state parameter is missing');
    }

    if (state != expectedState) {
      return ValidationResult.invalid('OAuth state parameter mismatch - possible CSRF attack');
    }

    // State should be cryptographically random
    if (state.length < 32) {
      return ValidationResult.invalid('OAuth state parameter too short');
    }

    return ValidationResult.valid();
  }

  /// Validate OAuth authorization code
  static ValidationResult validateAuthCode(String? code) {
    if (code == null || code.isEmpty) {
      return ValidationResult.invalid('Authorization code is missing');
    }

    // Basic length validation
    if (code.length < 10 || code.length > 512) {
      return ValidationResult.invalid('Authorization code has invalid length');
    }

    // Check for suspicious characters
    if (code.contains(' ') || code.contains('\n') || code.contains('\r')) {
      return ValidationResult.invalid('Authorization code contains invalid characters');
    }

    return ValidationResult.valid();
  }

  /// Validate and sanitize client credentials
  static Map<String, String> validateClientCredentials({
    required String clientId,
    required String clientSecret,
  }) {
    final clientIdResult = InputValidator.validateRequired(clientId, fieldName: 'Client ID');
    clientIdResult.throwIfInvalid('client_id');

    final clientSecretResult = InputValidator.validateRequired(clientSecret, fieldName: 'Client Secret');
    clientSecretResult.throwIfInvalid('client_secret');

    // Validate format
    if (clientId.length < 3 || clientId.length > 256) {
      throw InputValidator.createValidationException(
        'client_id',
        'Client ID must be between 3 and 256 characters',
      );
    }

    if (clientSecret.length < 8 || clientSecret.length > 512) {
      throw InputValidator.createValidationException(
        'client_secret',
        'Client Secret must be between 8 and 512 characters',
      );
    }

    return {
      'client_id': clientId.trim(),
      'client_secret': clientSecret.trim(),
    };
  }

  /// Validate access token format
  static ValidationResult validateAccessToken(String? token) {
    if (token == null || token.isEmpty) {
      return ValidationResult.invalid('Access token is required');
    }

    // Basic format validation
    if (token.length < 16 || token.length > 4096) {
      return ValidationResult.invalid('Access token has invalid length');
    }

    // Check for suspicious patterns
    if (token.contains(' ') || token.contains('\n')) {
      return ValidationResult.invalid('Access token contains invalid characters');
    }

    return ValidationResult.valid();
  }

  /// Validate encryption key strength
  static ValidationResult validateEncryptionKey(String? key) {
    if (key == null || key.isEmpty) {
      return ValidationResult.invalid('Encryption key is required');
    }

    // Minimum length for security
    if (key.length < 32) {
      return ValidationResult.invalid('Encryption key must be at least 32 characters');
    }

    // Check entropy (simplified)
    final uniqueChars = key.split('').toSet().length;
    if (uniqueChars < 8) {
      return ValidationResult.invalid('Encryption key has insufficient entropy');
    }

    return ValidationResult.valid();
  }

  /// Validate server configuration for security
  static Map<String, dynamic> validateServerConfig(Map<String, dynamic> config) {
    final validated = <String, dynamic>{};

    // Validate required fields
    final requiredFields = ['serverId', 'executable', 'transport'];
    for (final field in requiredFields) {
      if (!config.containsKey(field) || config[field] == null) {
        throw InputValidator.createValidationException(
          field,
          '$field is required in server configuration',
        );
      }
    }

    // Validate server ID
    final serverIdResult = InputValidator.validateMcpServerId(config['serverId']);
    serverIdResult.throwIfInvalid('serverId');
    validated['serverId'] = config['serverId'];

    // Validate executable path
    final executableResult = InputValidator.validateFilePath(
      config['executable'],
      mustExist: true,
      mustBeFile: true,
    );
    executableResult.throwIfInvalid('executable');
    validated['executable'] = config['executable'];

    // Validate transport
    const validTransports = ['stdio', 'sse', 'http'];
    final transport = config['transport'] as String?;
    if (transport == null || !validTransports.contains(transport.toLowerCase())) {
      throw InputValidator.createValidationException(
        'transport',
        'Transport must be one of: ${validTransports.join(', ')}',
      );
    }
    validated['transport'] = transport.toLowerCase();

    // Validate optional fields
    if (config.containsKey('args') && config['args'] != null) {
      final args = config['args'];
      if (args is! List) {
        throw InputValidator.createValidationException(
          'args',
          'Server arguments must be a list',
        );
      }
      validated['args'] = _sanitizeCommandArgs(args.cast<String>());
    }

    if (config.containsKey('env') && config['env'] != null) {
      final env = config['env'];
      if (env is! Map) {
        throw InputValidator.createValidationException(
          'env',
          'Server environment must be a map',
        );
      }
      validated['env'] = _sanitizeEnvironmentVariables(env.cast<String, String>());
    }

    // Validate URL for HTTP transport
    if (transport == 'http') {
      final urlResult = InputValidator.validateUrl(
        config['url'],
        requireHttps: true,
      );
      urlResult.throwIfInvalid('url');
      validated['url'] = config['url'];
    }

    return validated;
  }

  /// Sanitize command line arguments
  static List<String> _sanitizeCommandArgs(List<String> args) {
    final sanitized = <String>[];
    
    for (final arg in args) {
      // Remove dangerous characters and patterns
      String cleaned = arg.trim();
      
      // Block command injection attempts
      if (cleaned.contains(';') || 
          cleaned.contains('|') || 
          cleaned.contains('&') ||
          cleaned.contains('\n') ||
          cleaned.contains('\r')) {
        throw InputValidator.createValidationException(
          'args',
          'Command arguments contain invalid characters: $cleaned',
        );
      }

      // Block file system traversal
      if (cleaned.contains('../') || cleaned.contains('..\\')) {
        throw InputValidator.createValidationException(
          'args',
          'Command arguments contain path traversal: $cleaned',
        );
      }

      sanitized.add(cleaned);
    }

    return sanitized;
  }

  /// Sanitize environment variables
  static Map<String, String> _sanitizeEnvironmentVariables(Map<String, String> env) {
    final sanitized = <String, String>{};

    for (final entry in env.entries) {
      // Validate environment variable name
      final keyResult = InputValidator.validateEnvironmentKey(entry.key);
      keyResult.throwIfInvalid('env.${entry.key}');

      // Sanitize value
      String value = entry.value.trim();
      
      // Block dangerous values
      if (value.contains('\n') || value.contains('\r') || value.contains('\x00')) {
        throw InputValidator.createValidationException(
          'env.${entry.key}',
          'Environment variable contains invalid characters',
        );
      }

      sanitized[entry.key] = value;
    }

    return sanitized;
  }

  /// Generate secure random state for OAuth
  static String generateSecureState() {
    final random = List<int>.generate(32, (_) => DateTime.now().millisecondsSinceEpoch % 256);
    return base64Url.encode(random);
  }

  /// Validate request rate limiting
  static bool isRateLimited(String identifier, {
    int maxRequests = 100,
    Duration window = const Duration(minutes: 1),
    Map<String, List<DateTime>>? requestHistory,
  }) {
    requestHistory ??= <String, List<DateTime>>{};
    
    final now = DateTime.now();
    final windowStart = now.subtract(window);
    
    // Clean old requests
    final requests = requestHistory[identifier] ?? <DateTime>[];
    requests.removeWhere((time) => time.isBefore(windowStart));
    
    // Check limit
    if (requests.length >= maxRequests) {
      return true;
    }
    
    // Add current request
    requests.add(now);
    requestHistory[identifier] = requests;
    
    return false;
  }

  /// Validate JWT token format (basic validation)
  static ValidationResult validateJwtFormat(String? token) {
    if (token == null || token.isEmpty) {
      return ValidationResult.invalid('JWT token is required');
    }

    final parts = token.split('.');
    if (parts.length != 3) {
      return ValidationResult.invalid('JWT token must have 3 parts');
    }

    // Basic base64 validation for each part
    for (int i = 0; i < parts.length; i++) {
      try {
        base64Url.decode(parts[i]);
      } catch (e) {
        return ValidationResult.invalid('JWT part ${i + 1} is not valid base64');
      }
    }

    return ValidationResult.valid();
  }

  /// Create content security policy headers
  static Map<String, String> getSecurityHeaders() {
    return {
      'Content-Security-Policy': "default-src 'self'; script-src 'none'; object-src 'none'",
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
      'Referrer-Policy': 'no-referrer',
    };
  }

  /// Hash sensitive data for logging
  static String hashForLogging(String sensitiveData) {
    final bytes = utf8.encode(sensitiveData);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8); // First 8 chars for identification
  }

  /// Validate webhook signature
  static bool validateWebhookSignature({
    required String payload,
    required String signature,
    required String secret,
    String algorithm = 'sha256',
  }) {
    try {
      final key = utf8.encode(secret);
      final payloadBytes = utf8.encode(payload);
      
      late Digest expectedDigest;
      switch (algorithm) {
        case 'sha1':
          expectedDigest = Hmac(sha1, key).convert(payloadBytes);
          break;
        case 'sha256':
          expectedDigest = Hmac(sha256, key).convert(payloadBytes);
          break;
        default:
          throw ArgumentError('Unsupported algorithm: $algorithm');
      }

      final expectedSignature = expectedDigest.toString();
      final providedSignature = signature.startsWith('sha256=') 
          ? signature.substring(7)
          : signature;

      return expectedSignature == providedSignature;
    } catch (e) {
      return false;
    }
  }

  /// Sanitize file upload
  static ValidationResult validateFileUpload({
    required String filePath,
    required List<String> allowedExtensions,
    int maxSizeBytes = 10 * 1024 * 1024, // 10MB default
  }) {
    final file = File(filePath);
    
    if (!file.existsSync()) {
      return ValidationResult.invalid('File does not exist');
    }

    // Check file size
    final size = file.lengthSync();
    if (size > maxSizeBytes) {
      return ValidationResult.invalid('File is too large (max ${maxSizeBytes ~/ (1024 * 1024)}MB)');
    }

    // Check extension
    final extension = filePath.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return ValidationResult.invalid('File type not allowed. Allowed: ${allowedExtensions.join(', ')}');
    }

    // Basic content validation
    try {
      final bytes = file.readAsBytesSync();
      
      // Check for null bytes (potential binary in text file)
      if (extension == 'txt' || extension == 'json' || extension == 'yaml') {
        if (bytes.contains(0)) {
          return ValidationResult.invalid('Text file contains binary data');
        }
      }

      // Check for script tags in uploads
      final content = String.fromCharCodes(bytes);
      if (content.toLowerCase().contains('<script')) {
        return ValidationResult.invalid('File contains potentially dangerous script content');
      }

    } catch (e) {
      return ValidationResult.invalid('Unable to read file content');
    }

    return ValidationResult.valid();
  }
}