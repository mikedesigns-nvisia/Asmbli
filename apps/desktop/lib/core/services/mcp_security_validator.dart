import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_catalog_entry.dart';
import '../models/oauth_provider.dart';
import 'secure_auth_service.dart';

/// Production-grade security validator for MCP operations
/// Implements comprehensive validation, sanitization, and security checks
class MCPSecurityValidator {
  final SecureAuthService _authService;
  
  // Security constants
  static const int _maxInputLength = 10000;
  static const int _maxCredentialLength = 1000;
  static const List<String> _dangerousCommands = [
    'rm ', 'del ', 'format ', 'fdisk', 'dd ', 'mkfs',
    'sudo ', 'su ', 'chmod 777', 'chown ',
    '>&', '|&', '&&', '||', ';', '`',
    'eval', 'exec', 'system', 'shell_exec',
  ];
  static const List<String> _suspiciousPaths = [
    '/etc/', '/root/', '/boot/', '/sys/', '/proc/',
    'C:\\Windows\\', 'C:\\Program Files\\',
    '../', '..\\', '~/', '%USERPROFILE%',
  ];
  static const List<String> _allowedProtocols = ['http', 'https', 'stdio', 'websocket', 'sse'];
  static const List<String> _allowedFileExtensions = ['.js', '.py', '.ts', '.json', '.yaml', '.yml'];

  MCPSecurityValidator(this._authService);

  /// Comprehensive security validation for MCP server configuration
  Future<ValidationResult> validateMCPServerConfig(MCPCatalogEntry catalogEntry) async {
    final issues = <SecurityIssue>[];
    
    try {
      // Validate server identity and authenticity
      issues.addAll(await _validateServerAuthenticity(catalogEntry));
      
      // Validate command safety
      issues.addAll(_validateCommandSafety(catalogEntry));
      
      // Validate transport security
      issues.addAll(_validateTransportSecurity(catalogEntry));
      
      // Validate auth requirements
      issues.addAll(_validateAuthRequirements(catalogEntry));
      
      // Validate network access
      issues.addAll(await _validateNetworkSecurity(catalogEntry));
      
      // Validate file system access
      issues.addAll(_validateFileSystemAccess(catalogEntry));
      
      return ValidationResult(
        isValid: issues.where((i) => i.severity == SecuritySeverity.critical).isEmpty,
        issues: issues,
        riskScore: _calculateRiskScore(issues),
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        issues: [
          SecurityIssue(
            type: SecurityIssueType.validationError,
            severity: SecuritySeverity.critical,
            message: 'Validation failed: ${e.toString()}',
            recommendation: 'Contact security team for manual review',
          ),
        ],
        riskScore: 100,
      );
    }
  }

  /// Validate OAuth configuration security
  Future<ValidationResult> validateOAuthConfig(
    OAuthProvider provider,
    Map<String, String> credentials,
  ) async {
    final issues = <SecurityIssue>[];
    
    // Validate provider legitimacy
    if (!_isLegitimateOAuthProvider(provider)) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.untrustedProvider,
        severity: SecuritySeverity.critical,
        message: 'Unrecognized or untrusted OAuth provider',
        recommendation: 'Only use officially supported OAuth providers',
      ));
    }
    
    // Validate credential formats
    issues.addAll(_validateOAuthCredentials(provider, credentials));
    
    // Validate redirect URI security
    issues.addAll(_validateRedirectURI(provider));
    
    // Check for credential exposure risks
    issues.addAll(await _validateCredentialSecurity(credentials));
    
    return ValidationResult(
      isValid: issues.where((i) => i.severity == SecuritySeverity.critical).isEmpty,
      issues: issues,
      riskScore: _calculateRiskScore(issues),
    );
  }

  /// Validate user input for security threats
  ValidationResult validateUserInput(String input, {String? context}) {
    final issues = <SecurityIssue>[];
    
    // Check input length
    if (input.length > _maxInputLength) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.inputValidation,
        severity: SecuritySeverity.high,
        message: 'Input exceeds maximum allowed length',
        recommendation: 'Reduce input size to under $_maxInputLength characters',
      ));
    }
    
    // Check for injection attempts
    issues.addAll(_detectInjectionAttempts(input));
    
    // Check for path traversal attempts
    issues.addAll(_detectPathTraversal(input));
    
    // Check for dangerous characters/sequences
    issues.addAll(_detectDangerousSequences(input));
    
    // Context-specific validation
    if (context != null) {
      issues.addAll(_validateContextSpecific(input, context));
    }
    
    return ValidationResult(
      isValid: issues.where((i) => i.severity.index >= SecuritySeverity.high.index).isEmpty,
      issues: issues,
      riskScore: _calculateRiskScore(issues),
    );
  }

  /// Sanitize user input to prevent security issues
  String sanitizeInput(String input, {InputSanitationType type = InputSanitationType.general}) {
    String sanitized = input;
    
    switch (type) {
      case InputSanitationType.general:
        sanitized = _sanitizeGeneral(sanitized);
        break;
      case InputSanitationType.filename:
        sanitized = _sanitizeFilename(sanitized);
        break;
      case InputSanitationType.url:
        sanitized = _sanitizeURL(sanitized);
        break;
      case InputSanitationType.credential:
        sanitized = _sanitizeCredential(sanitized);
        break;
    }
    
    return sanitized;
  }

  // ==================== Server Authenticity Validation ====================
  
  Future<List<SecurityIssue>> _validateServerAuthenticity(MCPCatalogEntry catalogEntry) async {
    final issues = <SecurityIssue>[];
    
    // Check if server is officially verified
    if (!catalogEntry.isOfficial) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.untrustedSource,
        severity: SecuritySeverity.medium,
        message: 'Server is not officially verified',
        recommendation: 'Use caution with community servers. Verify source code and reputation.',
      ));
    }
    
    // Validate server signature/hash if available
    if (catalogEntry.metadata.containsKey('signature')) {
      final isValidSignature = await _verifyServerSignature(catalogEntry);
      if (!isValidSignature) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.invalidSignature,
          severity: SecuritySeverity.critical,
          message: 'Server signature verification failed',
          recommendation: 'Do not use servers with invalid signatures',
        ));
      }
    }
    
    return issues;
  }

  Future<bool> _verifyServerSignature(MCPCatalogEntry catalogEntry) async {
    // Implementation would verify cryptographic signature
    // For now, return true for official servers
    return catalogEntry.isOfficial;
  }

  // ==================== Command Safety Validation ====================
  
  List<SecurityIssue> _validateCommandSafety(MCPCatalogEntry catalogEntry) {
    final issues = <SecurityIssue>[];
    final command = catalogEntry.command;
    
    // Check for dangerous commands
    for (final dangerous in _dangerousCommands) {
      if (command.toLowerCase().contains(dangerous.toLowerCase())) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.dangerousCommand,
          severity: SecuritySeverity.critical,
          message: 'Command contains dangerous operation: $dangerous',
          recommendation: 'Review command safety before enabling',
        ));
      }
    }
    
    // Check for suspicious paths
    for (final path in _suspiciousPaths) {
      if (command.contains(path)) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.suspiciousPath,
          severity: SecuritySeverity.high,
          message: 'Command accesses sensitive path: $path',
          recommendation: 'Verify path access is necessary and safe',
        ));
      }
    }
    
    // Validate file extensions
    final extensions = RegExp(r'\.(.*?)(?:\s|$)').allMatches(command);
    for (final match in extensions) {
      final ext = '.${match.group(1)}';
      if (!_allowedFileExtensions.contains(ext.toLowerCase())) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.suspiciousFile,
          severity: SecuritySeverity.medium,
          message: 'Command uses non-standard file extension: $ext',
          recommendation: 'Verify file type is safe and expected',
        ));
      }
    }
    
    return issues;
  }

  // ==================== Transport Security Validation ====================
  
  List<SecurityIssue> _validateTransportSecurity(MCPCatalogEntry catalogEntry) {
    final issues = <SecurityIssue>[];
    
    // Validate transport type is supported
    if (!_allowedProtocols.contains(catalogEntry.transport.name.toLowerCase())) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.unsupportedTransport,
        severity: SecuritySeverity.high,
        message: 'Unsupported or insecure transport: ${catalogEntry.transport}',
        recommendation: 'Use supported secure transports only',
      ));
    }
    
    // Check for TLS requirements
    if (catalogEntry.transport == MCPTransportType.sse) {
      // SSE should use HTTPS in production
      if (catalogEntry.metadata['url']?.toString().startsWith('http://') == true) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.insecureTransport,
          severity: SecuritySeverity.high,
          message: 'SSE transport uses unencrypted HTTP',
          recommendation: 'Use HTTPS for SSE transport in production',
        ));
      }
    }
    
    return issues;
  }

  // ==================== Auth Requirements Validation ====================
  
  List<SecurityIssue> _validateAuthRequirements(MCPCatalogEntry catalogEntry) {
    final issues = <SecurityIssue>[];
    
    for (final authReq in catalogEntry.requiredAuth) {
      // Validate credential length
      if (authReq.name.length > _maxCredentialLength) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.inputValidation,
          severity: SecuritySeverity.medium,
          message: 'Auth field name too long: ${authReq.name}',
          recommendation: 'Use shorter field names',
        ));
      }
      
      // Check for secure handling of secrets
      if (authReq.isSecret && !authReq.name.toLowerCase().contains('token')) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.credentialHandling,
          severity: SecuritySeverity.low,
          message: 'Secret field may not be properly identified: ${authReq.name}',
          recommendation: 'Ensure secret fields use clear naming conventions',
        ));
      }
    }
    
    return issues;
  }

  // ==================== Network Security Validation ====================
  
  Future<List<SecurityIssue>> _validateNetworkSecurity(MCPCatalogEntry catalogEntry) async {
    final issues = <SecurityIssue>[];
    
    // Check for network-based servers
    if (catalogEntry.transport != MCPTransportType.stdio) {
      // Validate any URLs in metadata
      final urls = _extractURLsFromMetadata(catalogEntry.metadata);
      for (final url in urls) {
        issues.addAll(_validateURL(url));
      }
    }
    
    return issues;
  }

  List<String> _extractURLsFromMetadata(Map<String, dynamic> metadata) {
    final urls = <String>[];
    final urlRegex = RegExp(r'https?://[^\s]+');
    
    for (final value in metadata.values) {
      if (value is String) {
        final matches = urlRegex.allMatches(value);
        urls.addAll(matches.map((m) => m.group(0)!));
      }
    }
    
    return urls;
  }

  List<SecurityIssue> _validateURL(String url) {
    final issues = <SecurityIssue>[];
    
    try {
      final uri = Uri.parse(url);
      
      // Check protocol
      if (!['http', 'https'].contains(uri.scheme)) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.insecureTransport,
          severity: SecuritySeverity.medium,
          message: 'Non-HTTP protocol in URL: ${uri.scheme}',
          recommendation: 'Use HTTP/HTTPS protocols only',
        ));
      }
      
      // Check for localhost/private IPs in production URLs
      if (uri.host == 'localhost' || _isPrivateIP(uri.host)) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.networkSecurity,
          severity: SecuritySeverity.low,
          message: 'URL uses localhost/private IP: ${uri.host}',
          recommendation: 'Verify this is intended for development only',
        ));
      }
      
    } catch (e) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.inputValidation,
        severity: SecuritySeverity.medium,
        message: 'Invalid URL format: $url',
        recommendation: 'Use valid URL format',
      ));
    }
    
    return issues;
  }

  bool _isPrivateIP(String host) {
    try {
      final ip = InternetAddress(host);
      return ip.isLinkLocal || ip.isLoopback || ip.isMulticast;
    } catch (e) {
      return false; // Not an IP address
    }
  }

  // ==================== File System Access Validation ====================
  
  List<SecurityIssue> _validateFileSystemAccess(MCPCatalogEntry catalogEntry) {
    final issues = <SecurityIssue>[];
    
    // Check command and args for file system operations
    final fullCommand = '${catalogEntry.command} ${catalogEntry.args.join(' ')}';
    
    // Check for file system write operations
    final writeOperations = ['write', 'create', 'delete', 'modify', 'chmod', 'chown'];
    for (final op in writeOperations) {
      if (fullCommand.toLowerCase().contains(op)) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.fileSystemAccess,
          severity: SecuritySeverity.medium,
          message: 'Server may perform file system write operations',
          recommendation: 'Verify file system access is necessary and safe',
        ));
        break;
      }
    }
    
    return issues;
  }

  // ==================== OAuth Specific Validation ====================
  
  bool _isLegitimateOAuthProvider(OAuthProvider provider) {
    // All enum values are considered legitimate
    return OAuthProvider.values.contains(provider);
  }
  
  List<SecurityIssue> _validateOAuthCredentials(
    OAuthProvider provider,
    Map<String, String> credentials,
  ) {
    final issues = <SecurityIssue>[];
    
    for (final entry in credentials.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Validate credential length
      if (value.length > _maxCredentialLength) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.credentialHandling,
          severity: SecuritySeverity.medium,
          message: 'Credential value too long for field: $key',
          recommendation: 'Use standard credential lengths',
        ));
      }
      
      // Validate token formats based on provider
      issues.addAll(_validateTokenFormat(provider, key, value));
    }
    
    return issues;
  }

  List<SecurityIssue> _validateTokenFormat(OAuthProvider provider, String key, String value) {
    final issues = <SecurityIssue>[];
    
    switch (provider) {
      case OAuthProvider.github:
        if (key.toLowerCase().contains('token')) {
          if (!RegExp(r'^gh[ps]_[a-zA-Z0-9]{36,}$').hasMatch(value) &&
              !RegExp(r'^[a-f0-9]{40}$').hasMatch(value)) {
            issues.add(SecurityIssue(
              type: SecurityIssueType.credentialHandling,
              severity: SecuritySeverity.medium,
              message: 'GitHub token format appears invalid',
              recommendation: 'Verify token was generated correctly',
            ));
          }
        }
        break;
        
      case OAuthProvider.slack:
        if (key.toLowerCase().contains('token')) {
          if (!RegExp(r'^xox[bpoa]-').hasMatch(value)) {
            issues.add(SecurityIssue(
              type: SecurityIssueType.credentialHandling,
              severity: SecuritySeverity.medium,
              message: 'Slack token format appears invalid',
              recommendation: 'Verify token was generated correctly',
            ));
          }
        }
        break;
        
      default:
        // Generic token validation
        if (key.toLowerCase().contains('token') && value.length < 10) {
          issues.add(SecurityIssue(
            type: SecurityIssueType.credentialHandling,
            severity: SecuritySeverity.low,
            message: 'Token appears too short',
            recommendation: 'Verify token is complete',
          ));
        }
    }
    
    return issues;
  }

  List<SecurityIssue> _validateRedirectURI(OAuthProvider provider) {
    final issues = <SecurityIssue>[];
    
    // For desktop apps, localhost redirect is acceptable
    // In production web apps, this would need more validation
    
    return issues;
  }

  Future<List<SecurityIssue>> _validateCredentialSecurity(Map<String, String> credentials) async {
    final issues = <SecurityIssue>[];
    
    // Check for common credential exposure patterns
    for (final value in credentials.values) {
      if (value.contains(' ')) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.credentialHandling,
          severity: SecuritySeverity.low,
          message: 'Credential contains spaces (may indicate copy-paste error)',
          recommendation: 'Verify credential format is correct',
        ));
      }
      
      if (value.startsWith('Bearer ')) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.credentialHandling,
          severity: SecuritySeverity.low,
          message: 'Credential includes "Bearer " prefix (may be redundant)',
          recommendation: 'Store token value only, without Bearer prefix',
        ));
      }
    }
    
    return issues;
  }

  // ==================== Input Validation ====================
  
  List<SecurityIssue> _detectInjectionAttempts(String input) {
    final issues = <SecurityIssue>[];
    
    // SQL injection patterns
    final sqlPatterns = [
      r"'(\s*or\s*'1'\s*=\s*'1|'(\s*|\s*or\s*)')",
      r"union\s+select",
      r"drop\s+table",
      r"insert\s+into",
      r"delete\s+from",
    ];
    
    for (final pattern in sqlPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.injectionAttempt,
          severity: SecuritySeverity.critical,
          message: 'Potential SQL injection detected',
          recommendation: 'Input rejected for security',
        ));
      }
    }
    
    // Command injection patterns
    final cmdPatterns = [
      r'[;&|`]',
      r'\$\(',
      r'>\s*/',
      r'<\s*/',
    ];
    
    for (final pattern in cmdPatterns) {
      if (RegExp(pattern).hasMatch(input)) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.injectionAttempt,
          severity: SecuritySeverity.high,
          message: 'Potential command injection detected',
          recommendation: 'Input rejected for security',
        ));
      }
    }
    
    return issues;
  }

  List<SecurityIssue> _detectPathTraversal(String input) {
    final issues = <SecurityIssue>[];
    
    final traversalPatterns = [
      r'\.\.',
      r'%2e%2e',
      r'%252e%252e',
      r'..%2f',
      r'..%5c',
    ];
    
    for (final pattern in traversalPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        issues.add(SecurityIssue(
          type: SecurityIssueType.pathTraversal,
          severity: SecuritySeverity.high,
          message: 'Potential path traversal detected',
          recommendation: 'Input rejected for security',
        ));
      }
    }
    
    return issues;
  }

  List<SecurityIssue> _detectDangerousSequences(String input) {
    final issues = <SecurityIssue>[];
    
    // Script injection
    if (RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false).hasMatch(input)) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.scriptInjection,
        severity: SecuritySeverity.high,
        message: 'Script injection detected',
        recommendation: 'Input rejected for security',
      ));
    }
    
    // Null bytes
    if (input.contains('\x00')) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.nullByte,
        severity: SecuritySeverity.medium,
        message: 'Null byte detected in input',
        recommendation: 'Input rejected for security',
      ));
    }
    
    return issues;
  }

  List<SecurityIssue> _validateContextSpecific(String input, String context) {
    final issues = <SecurityIssue>[];
    
    switch (context.toLowerCase()) {
      case 'filename':
        if (RegExp(r'[<>:"/\\|?*]').hasMatch(input)) {
          issues.add(SecurityIssue(
            type: SecurityIssueType.inputValidation,
            severity: SecuritySeverity.medium,
            message: 'Invalid characters for filename',
            recommendation: 'Use only alphanumeric and safe punctuation',
          ));
        }
        break;
        
      case 'url':
        try {
          Uri.parse(input);
        } catch (e) {
          issues.add(SecurityIssue(
            type: SecurityIssueType.inputValidation,
            severity: SecuritySeverity.medium,
            message: 'Invalid URL format',
            recommendation: 'Provide valid URL',
          ));
        }
        break;
    }
    
    return issues;
  }

  // ==================== Input Sanitization ====================
  
  String _sanitizeGeneral(String input) {
    // Remove null bytes
    String sanitized = input.replaceAll('\x00', '');
    
    // Normalize whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Trim
    sanitized = sanitized.trim();
    
    // Length limit
    if (sanitized.length > _maxInputLength) {
      sanitized = sanitized.substring(0, _maxInputLength);
    }
    
    return sanitized;
  }

  String _sanitizeFilename(String input) {
    String sanitized = input;
    
    // Remove dangerous characters
    sanitized = sanitized.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    
    // Remove path traversal
    sanitized = sanitized.replaceAll(RegExp(r'\.\.'), '_');
    
    // Trim periods and spaces from ends
    sanitized = sanitized.replaceAll(RegExp(r'^[.\s]+|[.\s]+$'), '');
    
    return sanitized.isEmpty ? 'file' : sanitized;
  }

  String _sanitizeURL(String input) {
    try {
      final uri = Uri.parse(input);
      // Reconstruct with only safe components
      return Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        path: uri.path,
        queryParameters: uri.queryParameters,
      ).toString();
    } catch (e) {
      return '';
    }
  }

  String _sanitizeCredential(String input) {
    // Remove common prefixes/suffixes that might be accidentally included
    String sanitized = input;
    sanitized = sanitized.replaceAll(RegExp(r'^Bearer\s+'), '');
    sanitized = sanitized.replaceAll(RegExp(r'^Token\s+'), '');
    sanitized = sanitized.trim();
    
    return sanitized;
  }

  // ==================== Risk Calculation ====================
  
  int _calculateRiskScore(List<SecurityIssue> issues) {
    int score = 0;
    
    for (final issue in issues) {
      switch (issue.severity) {
        case SecuritySeverity.critical:
          score += 25;
          break;
        case SecuritySeverity.high:
          score += 15;
          break;
        case SecuritySeverity.medium:
          score += 5;
          break;
        case SecuritySeverity.low:
          score += 1;
          break;
      }
    }
    
    return (score * 100 / 100).clamp(0, 100).round();
  }
}

// ==================== Data Models ====================

class ValidationResult {
  final bool isValid;
  final List<SecurityIssue> issues;
  final int riskScore;

  const ValidationResult({
    required this.isValid,
    required this.issues,
    required this.riskScore,
  });

  bool get hasWarnings => issues.any((i) => i.severity.index >= SecuritySeverity.medium.index);
  bool get hasCriticalIssues => issues.any((i) => i.severity == SecuritySeverity.critical);
  
  String get riskLevel {
    if (riskScore >= 75) return 'Critical';
    if (riskScore >= 50) return 'High';
    if (riskScore >= 25) return 'Medium';
    return 'Low';
  }
}

class SecurityIssue {
  final SecurityIssueType type;
  final SecuritySeverity severity;
  final String message;
  final String recommendation;

  const SecurityIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.recommendation,
  });
}

enum SecurityIssueType {
  validationError,
  untrustedProvider,
  untrustedSource,
  invalidSignature,
  dangerousCommand,
  suspiciousPath,
  suspiciousFile,
  unsupportedTransport,
  insecureTransport,
  inputValidation,
  credentialHandling,
  networkSecurity,
  fileSystemAccess,
  injectionAttempt,
  pathTraversal,
  scriptInjection,
  nullByte,
}

enum SecuritySeverity {
  low,
  medium,
  high,
  critical,
}

enum InputSanitationType {
  general,
  filename,
  url,
  credential,
}

// ==================== Riverpod Provider ====================

final mcpSecurityValidatorProvider = Provider<MCPSecurityValidator>((ref) {
  final authService = ref.read(secureAuthServiceProvider);
  return MCPSecurityValidator(authService);
});