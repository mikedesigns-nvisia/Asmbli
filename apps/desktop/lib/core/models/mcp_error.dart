import 'package:equatable/equatable.dart';

/// Comprehensive error model for MCP operations
class MCPError extends Equatable {
  final String id;
  final DateTime timestamp;
  final MCPErrorCategory category;
  final MCPErrorType type;
  final MCPErrorSeverity severity;
  final String message;
  final String? context;
  final String? stackTrace;
  final Map<String, dynamic> metadata;
  final bool isRecoverable;
  final String suggestedAction;

  const MCPError({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.type,
    required this.severity,
    required this.message,
    this.context,
    this.stackTrace,
    required this.metadata,
    required this.isRecoverable,
    required this.suggestedAction,
  });

  /// Create a copy with updated values
  MCPError copyWith({
    String? id,
    DateTime? timestamp,
    MCPErrorCategory? category,
    MCPErrorType? type,
    MCPErrorSeverity? severity,
    String? message,
    String? context,
    String? stackTrace,
    Map<String, dynamic>? metadata,
    bool? isRecoverable,
    String? suggestedAction,
  }) {
    return MCPError(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      context: context ?? this.context,
      stackTrace: stackTrace ?? this.stackTrace,
      metadata: metadata ?? this.metadata,
      isRecoverable: isRecoverable ?? this.isRecoverable,
      suggestedAction: suggestedAction ?? this.suggestedAction,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'category': category.name,
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'context': context,
      'stackTrace': stackTrace,
      'metadata': metadata,
      'isRecoverable': isRecoverable,
      'suggestedAction': suggestedAction,
    };
  }

  /// Create from JSON
  factory MCPError.fromJson(Map<String, dynamic> json) {
    return MCPError(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      category: MCPErrorCategory.values.firstWhere(
        (c) => c.name == json['category'],
      ),
      type: MCPErrorType.values.firstWhere(
        (t) => t.name == json['type'],
      ),
      severity: MCPErrorSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
      ),
      message: json['message'],
      context: json['context'],
      stackTrace: json['stackTrace'],
      metadata: Map<String, dynamic>.from(json['metadata']),
      isRecoverable: json['isRecoverable'],
      suggestedAction: json['suggestedAction'],
    );
  }

  /// Get formatted error message for display
  String get displayMessage {
    final buffer = StringBuffer();
    buffer.write('[${category.displayName}] ');
    buffer.write(message);
    
    if (context != null) {
      buffer.write(' (Context: $context)');
    }
    
    return buffer.toString();
  }

  /// Get user-friendly error description
  String get userFriendlyDescription {
    switch (category) {
      case MCPErrorCategory.network:
        return 'Network connection issue. Check your internet connection and try again.';
      case MCPErrorCategory.auth:
        return 'Authentication problem. Please check your credentials and permissions.';
      case MCPErrorCategory.process:
        return 'Server startup issue. The MCP server failed to start properly.';
      case MCPErrorCategory.protocol:
        return 'Communication error. There was a problem communicating with the server.';
      case MCPErrorCategory.filesystem:
        return 'File access issue. Check file paths and permissions.';
      case MCPErrorCategory.rateLimit:
        return 'Rate limit exceeded. Please wait before trying again.';
      case MCPErrorCategory.validation:
        return 'Input validation error. Please check your input and try again.';
      case MCPErrorCategory.configuration:
        return 'Configuration issue. Check your settings and try again.';
      case MCPErrorCategory.unknown:
        return 'An unexpected error occurred. Please try again or contact support.';
    }
  }

  /// Get age of error
  Duration get age => DateTime.now().difference(timestamp);

  /// Check if error is recent (within last 5 minutes)
  bool get isRecent => age < const Duration(minutes: 5);

  @override
  List<Object?> get props => [
    id,
    timestamp,
    category,
    type,
    severity,
    message,
    context,
    stackTrace,
    metadata,
    isRecoverable,
    suggestedAction,
  ];
}

/// Error categories for classification
enum MCPErrorCategory {
  network('Network', 'Network and connectivity issues'),
  auth('Authentication', 'Authentication and authorization issues'),
  process('Process', 'Process management issues'),
  protocol('Protocol', 'MCP protocol and communication issues'),
  filesystem('Filesystem', 'File system access issues'),
  rateLimit('Rate Limit', 'API rate limiting issues'),
  validation('Validation', 'Input validation and security issues'),
  configuration('Configuration', 'Configuration and setup issues'),
  unknown('Unknown', 'Unclassified errors');

  const MCPErrorCategory(this.displayName, this.description);

  final String displayName;
  final String description;
}

/// Specific error types within categories
enum MCPErrorType {
  // Network errors
  connectionFailed('Connection Failed'),
  connectionRefused('Connection Refused'),
  timeout('Timeout'),
  httpError('HTTP Error'),
  dnsResolutionFailed('DNS Resolution Failed'),
  
  // Auth errors
  authenticationFailed('Authentication Failed'),
  insufficientPermissions('Insufficient Permissions'),
  tokenExpired('Token Expired'),
  tokenInvalid('Token Invalid'),
  
  // Process errors
  processStartFailed('Process Start Failed'),
  processCrashed('Process Crashed'),
  processTimeout('Process Timeout'),
  processNotFound('Process Not Found'),
  
  // Protocol errors
  invalidJson('Invalid JSON'),
  protocolViolation('Protocol Violation'),
  unsupportedOperation('Unsupported Operation'),
  messageCorrupted('Message Corrupted'),
  
  // Filesystem errors
  fileNotFound('File Not Found'),
  accessDenied('Access Denied'),
  diskFull('Disk Full'),
  pathTooLong('Path Too Long'),
  
  // Rate limit errors
  rateLimitExceeded('Rate Limit Exceeded'),
  quotaExceeded('Quota Exceeded'),
  
  // Validation errors
  inputTooLong('Input Too Long'),
  invalidFormat('Invalid Format'),
  securityViolation('Security Violation'),
  injectionAttempt('Injection Attempt'),
  
  // Configuration errors
  missingConfiguration('Missing Configuration'),
  invalidConfiguration('Invalid Configuration'),
  dependencyMissing('Dependency Missing'),
  
  // Unknown errors
  unknownError('Unknown Error');

  const MCPErrorType(this.displayName);

  final String displayName;
}

/// Error severity levels
enum MCPErrorSeverity {
  low('Low', 'Minor issues that don\'t affect core functionality'),
  medium('Medium', 'Issues that may impact user experience'),
  high('High', 'Serious issues that affect functionality'),
  critical('Critical', 'Critical issues that prevent operation');

  const MCPErrorSeverity(this.displayName, this.description);

  final String displayName;
  final String description;

  /// Get color representation for UI
  String get colorHex {
    switch (this) {
      case MCPErrorSeverity.low:
        return '#4CAF50'; // Green
      case MCPErrorSeverity.medium:
        return '#FF9800'; // Orange
      case MCPErrorSeverity.high:
        return '#FF5722'; // Red-Orange
      case MCPErrorSeverity.critical:
        return '#F44336'; // Red
    }
  }

  /// Check if severity requires immediate attention
  bool get requiresImmediateAttention => 
      this == MCPErrorSeverity.critical || this == MCPErrorSeverity.high;
}

/// Error statistics for monitoring
class MCPErrorStatistics extends Equatable {
  final int totalErrors;
  final Map<MCPErrorCategory, int> errorsByCategory;
  final Map<MCPErrorSeverity, int> errorsBySeverity;
  final Map<MCPErrorType, int> errorsByType;
  final DateTime calculatedAt;
  final Duration timeWindow;

  const MCPErrorStatistics({
    required this.totalErrors,
    required this.errorsByCategory,
    required this.errorsBySeverity,
    required this.errorsByType,
    required this.calculatedAt,
    required this.timeWindow,
  });

  /// Get error rate per hour
  double get errorRatePerHour {
    if (timeWindow.inHours == 0) return totalErrors.toDouble();
    return totalErrors / timeWindow.inHours;
  }

  /// Get most common error category
  MCPErrorCategory? get mostCommonCategory {
    if (errorsByCategory.isEmpty) return null;
    return errorsByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get most common error type
  MCPErrorType? get mostCommonType {
    if (errorsByType.isEmpty) return null;
    return errorsByType.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get percentage of critical errors
  double get criticalErrorPercentage {
    if (totalErrors == 0) return 0.0;
    final critical = errorsBySeverity[MCPErrorSeverity.critical] ?? 0;
    return (critical / totalErrors) * 100;
  }

  /// Check if error pattern indicates system issues
  bool get indicatesSystemIssues {
    return criticalErrorPercentage > 20 || errorRatePerHour > 10;
  }

  @override
  List<Object?> get props => [
    totalErrors,
    errorsByCategory,
    errorsBySeverity,
    errorsByType,
    calculatedAt,
    timeWindow,
  ];
}

/// Error trend data for analytics
class MCPErrorTrend extends Equatable {
  final DateTime timestamp;
  final int errorCount;
  final MCPErrorSeverity averageSeverity;
  final List<MCPErrorCategory> topCategories;

  const MCPErrorTrend({
    required this.timestamp,
    required this.errorCount,
    required this.averageSeverity,
    required this.topCategories,
  });

  @override
  List<Object?> get props => [
    timestamp,
    errorCount,
    averageSeverity,
    topCategories,
  ];
}