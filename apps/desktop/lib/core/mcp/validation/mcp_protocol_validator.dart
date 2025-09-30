import 'dart:convert';
import '../../models/mcp_server_config.dart';
import '../../utils/app_logger.dart';

/// MCP Protocol validation and error handling
class MCPProtocolValidator {
  static const String mcpVersion = '2024-11-05';

  static const Map<String, List<String>> _methodParameterRequirements = {
    'initialize': ['protocolVersion', 'capabilities', 'clientInfo'],
    'tools/list': [],
    'tools/call': ['name', 'arguments'],
    'resources/list': [],
    'resources/read': ['uri'],
    'prompts/list': [],
    'prompts/get': ['name'],
    'completion/complete': ['ref', 'argument'],
    'logging/setLevel': ['level'],
  };

  static const Map<String, List<String>> _responseFields = {
    'initialize': ['protocolVersion', 'capabilities', 'serverInfo'],
    'tools/list': ['tools'],
    'tools/call': ['content'],
    'resources/list': ['resources'],
    'resources/read': ['contents'],
    'prompts/list': ['prompts'],
    'prompts/get': ['messages'],
  };

  /// Validate JSON-RPC request format
  static ValidationResult validateRequest(Map<String, dynamic> request) {
    final issues = <String>[];

    // Check JSON-RPC 2.0 format
    if (request['jsonrpc'] != '2.0') {
      issues.add('Invalid or missing jsonrpc version (expected 2.0)');
    }

    if (request['method'] == null || !(request['method'] is String)) {
      issues.add('Missing or invalid method field');
    }

    // ID is required for requests (not notifications)
    if (!request.containsKey('id')) {
      AppLogger.debug('No ID field - treating as notification', component: 'MCP.Validator');
    } else if (request['id'] is! int && request['id'] is! String) {
      issues.add('Invalid ID field - must be string or number');
    }

    // Validate method-specific parameters
    final method = request['method'] as String?;
    if (method != null && _methodParameterRequirements.containsKey(method)) {
      final params = request['params'] as Map<String, dynamic>?;
      final requiredParams = _methodParameterRequirements[method]!;

      for (final param in requiredParams) {
        if (params == null || !params.containsKey(param)) {
          issues.add('Missing required parameter: $param for method $method');
        }
      }
    }

    return ValidationResult(isValid: issues.isEmpty, issues: issues);
  }

  /// Validate JSON-RPC response format
  static ValidationResult validateResponse(Map<String, dynamic> response, String? expectedMethod) {
    final issues = <String>[];

    // Check JSON-RPC 2.0 format
    if (response['jsonrpc'] != '2.0') {
      issues.add('Invalid or missing jsonrpc version in response');
    }

    if (!response.containsKey('id')) {
      issues.add('Missing ID field in response');
    }

    // Must have either result or error, not both
    final hasResult = response.containsKey('result');
    final hasError = response.containsKey('error');

    if (!hasResult && !hasError) {
      issues.add('Response must contain either result or error field');
    }

    if (hasResult && hasError) {
      issues.add('Response cannot contain both result and error fields');
    }

    // Validate error format if present
    if (hasError) {
      final error = response['error'];
      if (error is! Map<String, dynamic>) {
        issues.add('Error field must be an object');
      } else {
        if (!error.containsKey('code') || error['code'] is! int) {
          issues.add('Error must have integer code field');
        }
        if (!error.containsKey('message') || error['message'] is! String) {
          issues.add('Error must have string message field');
        }
      }
    }

    // Validate method-specific response fields
    if (hasResult && expectedMethod != null && _responseFields.containsKey(expectedMethod)) {
      final result = response['result'] as Map<String, dynamic>?;
      final expectedFields = _responseFields[expectedMethod]!;

      for (final field in expectedFields) {
        if (result == null || !result.containsKey(field)) {
          issues.add('Missing expected response field: $field for method $expectedMethod');
        }
      }
    }

    return ValidationResult(isValid: issues.isEmpty, issues: issues);
  }

  /// Validate MCP server configuration
  static ValidationResult validateServerConfig(MCPServerConfig config) {
    final issues = <String>[];

    if (config.name.isEmpty) {
      issues.add('Server name cannot be empty');
    }

    if (config.command.isEmpty && config.url.isEmpty) {
      issues.add('Either command or url must be provided');
    }

    if (config.protocol != 'stdio' && config.transport != 'stdio') {
      if (config.url.isEmpty) {
        issues.add('URL is required for non-STDIO protocols');
      } else {
        try {
          final uri = Uri.parse(config.url);
          if (!uri.hasScheme) {
            issues.add('Invalid URL format - missing scheme');
          }
        } catch (e) {
          issues.add('Invalid URL format: $e');
        }
      }
    }

    if (config.timeout != null && config.timeout! <= 0) {
      issues.add('Timeout must be positive');
    }

    return ValidationResult(isValid: issues.isEmpty, issues: issues);
  }

  /// Validate tool definition
  static ValidationResult validateTool(Map<String, dynamic> tool) {
    final issues = <String>[];

    if (!tool.containsKey('name') || tool['name'] is! String) {
      issues.add('Tool must have string name field');
    }

    if (!tool.containsKey('description') || tool['description'] is! String) {
      issues.add('Tool must have string description field');
    }

    if (tool.containsKey('inputSchema')) {
      final schema = tool['inputSchema'];
      if (schema is! Map<String, dynamic>) {
        issues.add('Tool inputSchema must be an object');
      } else {
        // Basic JSON Schema validation
        if (!schema.containsKey('type')) {
          issues.add('Tool inputSchema must have type field');
        }
      }
    }

    return ValidationResult(isValid: issues.isEmpty, issues: issues);
  }

  /// Validate notification format
  static ValidationResult validateNotification(Map<String, dynamic> notification) {
    final issues = <String>[];

    if (notification['jsonrpc'] != '2.0') {
      issues.add('Invalid or missing jsonrpc version in notification');
    }

    if (notification['method'] == null || !(notification['method'] is String)) {
      issues.add('Missing or invalid method field in notification');
    }

    // Notifications must NOT have an ID
    if (notification.containsKey('id')) {
      issues.add('Notifications must not have ID field');
    }

    return ValidationResult(isValid: issues.isEmpty, issues: issues);
  }

  /// Create standardized error response
  static Map<String, dynamic> createErrorResponse(int id, MCPError error, [String? additionalInfo]) {
    final errorObj = {
      'code': error.code,
      'message': error.message,
    };

    if (additionalInfo != null) {
      errorObj['data'] = additionalInfo;
    }

    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': errorObj,
    };
  }

  /// Parse and validate incoming JSON message
  static ParseResult parseMessage(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return ParseResult(
          isValid: false,
          error: 'Message must be JSON object',
        );
      }

      return ParseResult(
        isValid: true,
        message: decoded,
      );
    } catch (e) {
      return ParseResult(
        isValid: false,
        error: 'Invalid JSON: $e',
      );
    }
  }

  /// Check if message is a notification (no ID field)
  static bool isNotification(Map<String, dynamic> message) {
    return !message.containsKey('id');
  }

  /// Extract method name from message
  static String? getMethod(Map<String, dynamic> message) {
    return message['method'] as String?;
  }

  /// Extract request ID from message
  static dynamic getId(Map<String, dynamic> message) {
    return message['id'];
  }
}

/// Standard MCP error codes and messages
enum MCPError {
  parseError(-32700, 'Parse error'),
  invalidRequest(-32600, 'Invalid Request'),
  methodNotFound(-32601, 'Method not found'),
  invalidParams(-32602, 'Invalid params'),
  internalError(-32603, 'Internal error'),
  serverError(-32000, 'Server error'),
  requestTimeout(-32001, 'Request timeout'),
  connectionError(-32002, 'Connection error'),
  protocolError(-32003, 'Protocol error');

  const MCPError(this.code, this.message);
  final int code;
  final String message;
}

class ValidationResult {
  final bool isValid;
  final List<String> issues;

  ValidationResult({required this.isValid, required this.issues});

  @override
  String toString() => 'ValidationResult(valid: $isValid, issues: ${issues.length})';
}

class ParseResult {
  final bool isValid;
  final Map<String, dynamic>? message;
  final String? error;

  ParseResult({required this.isValid, this.message, this.error});

  @override
  String toString() => 'ParseResult(valid: $isValid, error: $error)';
}