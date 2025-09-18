import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/security_context.dart';

/// Security policy engine for command and operation validation
class SecurityPolicyEngine {
  final Map<String, SecurityContext> _agentContexts = {};
  final Map<String, List<SecurityAuditEvent>> _auditLog = {};
  final Map<String, RateLimitTracker> _rateLimiters = {};

  /// Register a security context for an agent
  void registerAgent(String agentId, SecurityContext context) {
    _agentContexts[agentId] = context;
    _auditLog[agentId] = [];
    _rateLimiters[agentId] = RateLimitTracker();
    
    _logSecurityEvent(agentId, SecurityEventType.contextRegistered, 
        'Security context registered for agent');
  }

  /// Update security context for an agent
  void updateAgentContext(String agentId, SecurityContext context) {
    _agentContexts[agentId] = context;
    _logSecurityEvent(agentId, SecurityEventType.contextUpdated,
        'Security context updated for agent');
  }

  /// Remove agent from security tracking
  void unregisterAgent(String agentId) {
    _agentContexts.remove(agentId);
    _rateLimiters.remove(agentId);
    _logSecurityEvent(agentId, SecurityEventType.contextRemoved,
        'Security context removed for agent');
  }

  /// Validate a command against security policies
  Future<SecurityValidationResult> validateCommand(
    String agentId,
    String command, {
    Map<String, String> environment = const {},
    String? workingDirectory,
  }) async {
    final context = _agentContexts[agentId];
    if (context == null) {
      return SecurityValidationResult.denied(
        reason: 'No security context found for agent',
        riskLevel: RiskLevel.high,
      );
    }

    try {
      // Parse command to extract executable and arguments
      final parsedCommand = _parseCommand(command);
      
      // Step 1: Basic command validation
      final commandValidation = _validateCommandBasics(context, parsedCommand);
      if (!commandValidation.isAllowed) {
        _logSecurityEvent(agentId, SecurityEventType.commandBlocked,
            'Command blocked: ${commandValidation.reason}');
        return commandValidation;
      }

      // Step 2: Argument validation
      final argumentValidation = await _validateCommandArguments(
          context, parsedCommand, workingDirectory);
      if (!argumentValidation.isAllowed) {
        _logSecurityEvent(agentId, SecurityEventType.commandBlocked,
            'Command blocked due to arguments: ${argumentValidation.reason}');
        return argumentValidation;
      }

      // Step 3: Resource limit validation
      final resourceValidation = await _validateResourceLimits(context, parsedCommand);
      if (!resourceValidation.isAllowed) {
        _logSecurityEvent(agentId, SecurityEventType.resourceLimitExceeded,
            'Command blocked due to resource limits: ${resourceValidation.reason}');
        return resourceValidation;
      }

      // Step 4: Network access validation
      final networkValidation = _validateNetworkAccess(context, parsedCommand);
      if (!networkValidation.isAllowed) {
        _logSecurityEvent(agentId, SecurityEventType.networkAccessDenied,
            'Command blocked due to network restrictions: ${networkValidation.reason}');
        return networkValidation;
      }

      // Step 5: Environment variable validation
      final envValidation = _validateEnvironmentAccess(context, environment);
      if (!envValidation.isAllowed) {
        _logSecurityEvent(agentId, SecurityEventType.environmentAccessDenied,
            'Command blocked due to environment restrictions: ${envValidation.reason}');
        return envValidation;
      }

      // Command is allowed
      _logSecurityEvent(agentId, SecurityEventType.commandAllowed,
          'Command allowed: $command');
      
      return SecurityValidationResult.allowed(
        riskLevel: _calculateRiskLevel(parsedCommand),
        requiresApproval: _requiresApproval(context, parsedCommand),
        monitoringLevel: _getMonitoringLevel(parsedCommand),
      );

    } catch (e) {
      _logSecurityEvent(agentId, SecurityEventType.validationError,
          'Security validation error: $e');
      
      return SecurityValidationResult.denied(
        reason: 'Security validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Validate file system access
  Future<SecurityValidationResult> validateFileAccess(
    String agentId,
    String filePath, {
    required bool isWrite,
    required bool isExecute,
  }) async {
    final context = _agentContexts[agentId];
    if (context == null) {
      return SecurityValidationResult.denied(
        reason: 'No security context found for agent',
        riskLevel: RiskLevel.high,
      );
    }

    try {
      // Normalize path
      final normalizedPath = _normalizePath(filePath);
      
      // Check if path is allowed
      if (!context.isPathAllowed(normalizedPath, isWrite: isWrite)) {
        _logSecurityEvent(agentId, SecurityEventType.fileAccessDenied,
            'File access denied: $normalizedPath (write: $isWrite)');
        
        return SecurityValidationResult.denied(
          reason: 'File access not permitted: $normalizedPath',
          riskLevel: isWrite ? RiskLevel.high : RiskLevel.medium,
        );
      }

      // Additional checks for sensitive files
      if (_isSensitiveFile(normalizedPath)) {
        _logSecurityEvent(agentId, SecurityEventType.sensitiveFileAccess,
            'Sensitive file access: $normalizedPath');
        
        return SecurityValidationResult.allowed(
          riskLevel: RiskLevel.high,
          requiresApproval: true,
          monitoringLevel: MonitoringLevel.comprehensive,
        );
      }

      _logSecurityEvent(agentId, SecurityEventType.fileAccessAllowed,
          'File access allowed: $normalizedPath');
      
      return SecurityValidationResult.allowed(
        riskLevel: RiskLevel.low,
        requiresApproval: false,
        monitoringLevel: MonitoringLevel.basic,
      );

    } catch (e) {
      _logSecurityEvent(agentId, SecurityEventType.validationError,
          'File access validation error: $e');
      
      return SecurityValidationResult.denied(
        reason: 'File access validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Validate network access
  Future<SecurityValidationResult> validateNetworkAccess(
    String agentId,
    String host,
    int port, {
    String protocol = 'tcp',
  }) async {
    final context = _agentContexts[agentId];
    if (context == null) {
      return SecurityValidationResult.denied(
        reason: 'No security context found for agent',
        riskLevel: RiskLevel.high,
      );
    }

    try {
      // Check if network access is allowed at all
      if (!context.terminalPermissions.canAccessNetwork) {
        _logSecurityEvent(agentId, SecurityEventType.networkAccessDenied,
            'Network access disabled for agent');
        
        return SecurityValidationResult.denied(
          reason: 'Network access is disabled for this agent',
          riskLevel: RiskLevel.medium,
        );
      }

      // Check if specific host is allowed
      if (!context.isNetworkHostAllowed(host)) {
        _logSecurityEvent(agentId, SecurityEventType.networkAccessDenied,
            'Network access denied to host: $host');
        
        return SecurityValidationResult.denied(
          reason: 'Network access not permitted to host: $host',
          riskLevel: RiskLevel.medium,
        );
      }

      // Check for suspicious ports
      if (_isSuspiciousPort(port)) {
        _logSecurityEvent(agentId, SecurityEventType.suspiciousNetworkAccess,
            'Suspicious network access: $host:$port');
        
        return SecurityValidationResult.allowed(
          riskLevel: RiskLevel.high,
          requiresApproval: true,
          monitoringLevel: MonitoringLevel.comprehensive,
        );
      }

      _logSecurityEvent(agentId, SecurityEventType.networkAccessAllowed,
          'Network access allowed: $host:$port');
      
      return SecurityValidationResult.allowed(
        riskLevel: RiskLevel.low,
        requiresApproval: false,
        monitoringLevel: MonitoringLevel.basic,
      );

    } catch (e) {
      _logSecurityEvent(agentId, SecurityEventType.validationError,
          'Network access validation error: $e');
      
      return SecurityValidationResult.denied(
        reason: 'Network access validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Validate API access and rate limiting
  Future<SecurityValidationResult> validateAPIAccess(
    String agentId,
    String provider,
    String model, {
    int tokenCount = 0,
  }) async {
    final context = _agentContexts[agentId];
    if (context == null) {
      return SecurityValidationResult.denied(
        reason: 'No security context found for agent',
        riskLevel: RiskLevel.high,
      );
    }

    try {
      // Check if API access is allowed
      if (!context.isAPIAccessAllowed(provider, model)) {
        _logSecurityEvent(agentId, SecurityEventType.apiAccessDenied,
            'API access denied: $provider/$model');
        
        return SecurityValidationResult.denied(
          reason: 'API access not permitted for $provider/$model',
          riskLevel: RiskLevel.medium,
        );
      }

      // Check rate limits
      final rateLimiter = _rateLimiters[agentId]!;
      final permission = context.apiPermissions[provider]!;
      
      if (!rateLimiter.checkRateLimit(provider, permission.maxRequestsPerMinute)) {
        _logSecurityEvent(agentId, SecurityEventType.rateLimitExceeded,
            'Rate limit exceeded for $provider');
        
        return SecurityValidationResult.denied(
          reason: 'Rate limit exceeded for $provider',
          riskLevel: RiskLevel.medium,
        );
      }

      // Check token limits
      if (tokenCount > permission.maxTokensPerRequest) {
        _logSecurityEvent(agentId, SecurityEventType.tokenLimitExceeded,
            'Token limit exceeded: $tokenCount > ${permission.maxTokensPerRequest}');
        
        return SecurityValidationResult.denied(
          reason: 'Token limit exceeded',
          riskLevel: RiskLevel.medium,
        );
      }

      // Check if approval is required
      final requiresApproval = context.terminalPermissions.requiresApprovalForAPICalls;
      
      _logSecurityEvent(agentId, SecurityEventType.apiAccessAllowed,
          'API access allowed: $provider/$model');
      
      return SecurityValidationResult.allowed(
        riskLevel: RiskLevel.low,
        requiresApproval: requiresApproval,
        monitoringLevel: MonitoringLevel.enhanced,
      );

    } catch (e) {
      _logSecurityEvent(agentId, SecurityEventType.validationError,
          'API access validation error: $e');
      
      return SecurityValidationResult.denied(
        reason: 'API access validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Get security audit log for an agent
  List<SecurityAuditEvent> getAuditLog(String agentId) {
    return _auditLog[agentId] ?? [];
  }

  /// Get all security contexts
  Map<String, SecurityContext> getAllContexts() {
    return Map.unmodifiable(_agentContexts);
  }

  /// Parse command into components
  ParsedCommand _parseCommand(String command) {
    final parts = command.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      throw ArgumentError('Empty command');
    }

    return ParsedCommand(
      executable: parts.first,
      arguments: parts.skip(1).toList(),
      fullCommand: command,
    );
  }

  /// Validate basic command properties
  SecurityValidationResult _validateCommandBasics(
      SecurityContext context, ParsedCommand command) {
    
    // Check if command is allowed
    if (!context.isCommandAllowed(command.fullCommand)) {
      return SecurityValidationResult.denied(
        reason: 'Command not permitted: ${command.executable}',
        riskLevel: RiskLevel.medium,
      );
    }

    // Check for dangerous patterns
    if (_hasDangerousPatterns(command.fullCommand)) {
      return SecurityValidationResult.denied(
        reason: 'Command contains dangerous patterns',
        riskLevel: RiskLevel.high,
      );
    }

    return SecurityValidationResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
    );
  }

  /// Validate command arguments for security issues
  Future<SecurityValidationResult> _validateCommandArguments(
      SecurityContext context, ParsedCommand command, String? workingDirectory) async {
    
    for (final arg in command.arguments) {
      // Check for path traversal
      if (arg.contains('../') || arg.contains('..\\')) {
        return SecurityValidationResult.denied(
          reason: 'Path traversal detected in arguments',
          riskLevel: RiskLevel.high,
        );
      }

      // Check for command injection
      if (_hasCommandInjection(arg)) {
        return SecurityValidationResult.denied(
          reason: 'Command injection detected in arguments',
          riskLevel: RiskLevel.high,
        );
      }

      // Validate file paths in arguments
      if (_looksLikeFilePath(arg)) {
        final fullPath = _resolveFilePath(arg, workingDirectory);
        if (!context.isPathAllowed(fullPath, isWrite: _isWriteOperation(command.executable))) {
          return SecurityValidationResult.denied(
            reason: 'File path not permitted: $fullPath',
            riskLevel: RiskLevel.medium,
          );
        }
      }
    }

    return SecurityValidationResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
    );
  }

  /// Validate resource limits
  Future<SecurityValidationResult> _validateResourceLimits(
      SecurityContext context, ParsedCommand command) async {
    
    // This would integrate with actual resource monitoring
    // For now, just check if the command is known to be resource-intensive
    final resourceIntensiveCommands = [
      'find', 'grep', 'tar', 'zip', 'unzip', 'git', 'npm', 'pip'
    ];

    if (resourceIntensiveCommands.contains(command.executable)) {
      return SecurityValidationResult.allowed(
        riskLevel: RiskLevel.medium,
        requiresApproval: false,
        monitoringLevel: MonitoringLevel.enhanced,
      );
    }

    return SecurityValidationResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
    );
  }

  /// Validate network access in command
  SecurityValidationResult _validateNetworkAccess(
      SecurityContext context, ParsedCommand command) {
    
    final networkCommands = ['curl', 'wget', 'ssh', 'scp', 'ftp', 'nc', 'netcat'];
    
    if (networkCommands.contains(command.executable)) {
      if (!context.terminalPermissions.canAccessNetwork) {
        return SecurityValidationResult.denied(
          reason: 'Network access is disabled',
          riskLevel: RiskLevel.medium,
        );
      }

      // Extract hosts from arguments and validate
      final hosts = _extractHostsFromArguments(command.arguments);
      for (final host in hosts) {
        if (!context.isNetworkHostAllowed(host)) {
          return SecurityValidationResult.denied(
            reason: 'Network access not permitted to host: $host',
            riskLevel: RiskLevel.medium,
          );
        }
      }

      return SecurityValidationResult.allowed(
        riskLevel: RiskLevel.medium,
        requiresApproval: true,
        monitoringLevel: MonitoringLevel.enhanced,
      );
    }

    return SecurityValidationResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
    );
  }

  /// Validate environment variable access
  SecurityValidationResult _validateEnvironmentAccess(
      SecurityContext context, Map<String, String> environment) {
    
    // Check for sensitive environment variables
    final sensitiveVars = ['API_KEY', 'SECRET', 'TOKEN', 'PASSWORD', 'PRIVATE_KEY'];
    
    for (final key in environment.keys) {
      if (sensitiveVars.any((sensitive) => key.toUpperCase().contains(sensitive))) {
        return SecurityValidationResult.allowed(
          riskLevel: RiskLevel.high,
          requiresApproval: true,
          monitoringLevel: MonitoringLevel.comprehensive,
        );
      }
    }

    return SecurityValidationResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
    );
  }

  /// Log security event
  void _logSecurityEvent(String agentId, SecurityEventType type, String message) {
    final event = SecurityAuditEvent(
      agentId: agentId,
      type: type,
      message: message,
      timestamp: DateTime.now(),
    );

    _auditLog[agentId]?.add(event);
    
    // Keep only last 1000 events per agent
    final log = _auditLog[agentId];
    if (log != null && log.length > 1000) {
      log.removeRange(0, log.length - 1000);
    }

    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('Security Event [$agentId]: ${type.name} - $message');
    }
  }

  /// Helper methods
  RiskLevel _calculateRiskLevel(ParsedCommand command) {
    final highRiskCommands = ['rm', 'del', 'sudo', 'su', 'chmod', 'chown'];
    final mediumRiskCommands = ['curl', 'wget', 'ssh', 'git', 'npm', 'pip'];

    if (highRiskCommands.contains(command.executable)) {
      return RiskLevel.high;
    } else if (mediumRiskCommands.contains(command.executable)) {
      return RiskLevel.medium;
    }
    return RiskLevel.low;
  }

  bool _requiresApproval(SecurityContext context, ParsedCommand command) {
    final approvalCommands = ['sudo', 'su', 'curl', 'wget', 'ssh', 'npm install', 'pip install'];
    return approvalCommands.any((cmd) => command.fullCommand.startsWith(cmd));
  }

  MonitoringLevel _getMonitoringLevel(ParsedCommand command) {
    final highMonitoringCommands = ['sudo', 'su', 'rm', 'del'];
    final enhancedMonitoringCommands = ['curl', 'wget', 'ssh', 'git'];

    if (highMonitoringCommands.contains(command.executable)) {
      return MonitoringLevel.comprehensive;
    } else if (enhancedMonitoringCommands.contains(command.executable)) {
      return MonitoringLevel.enhanced;
    }
    return MonitoringLevel.basic;
  }

  String _normalizePath(String path) {
    // Basic path normalization
    return path.replaceAll('\\', '/').replaceAll('//', '/');
  }

  bool _isSensitiveFile(String path) {
    final sensitivePatterns = [
      '/etc/passwd', '/etc/shadow', '/etc/sudoers',
      '.ssh/', '.aws/', '.env', 'id_rsa', 'id_dsa',
      'C:\\Windows\\System32\\', 'C:\\Users\\',
    ];

    return sensitivePatterns.any((pattern) => path.contains(pattern));
  }

  bool _isSuspiciousPort(int port) {
    final suspiciousPorts = [22, 23, 135, 139, 445, 1433, 3389, 5432];
    return suspiciousPorts.contains(port);
  }

  bool _hasDangerousPatterns(String command) {
    final dangerousPatterns = [
      r'\$\([^)]*\)', // Command substitution
      r'`[^`]*`',     // Backticks
      r';.*rm\s',     // Chained deletion
      r'\|\s*sh',     // Pipe to shell
      r'eval\s',      // Eval usage
      r'>\s*/dev/',   // Writing to device files
    ];

    return dangerousPatterns.any((pattern) => 
        RegExp(pattern, caseSensitive: false).hasMatch(command));
  }

  bool _hasCommandInjection(String arg) {
    final injectionPatterns = [';', '|', '&', '`', '\$', '>', '<'];
    return injectionPatterns.any((pattern) => arg.contains(pattern));
  }

  bool _looksLikeFilePath(String arg) {
    return arg.contains('/') || arg.contains('\\') || arg.startsWith('./') || arg.startsWith('../');
  }

  String _resolveFilePath(String path, String? workingDirectory) {
    if (path.startsWith('/') || path.contains(':\\')) {
      return path; // Absolute path
    }
    
    final baseDir = workingDirectory ?? Directory.current.path;
    return '$baseDir/$path';
  }

  bool _isWriteOperation(String executable) {
    final writeCommands = ['cp', 'copy', 'mv', 'move', 'rm', 'del', 'mkdir', 'touch'];
    return writeCommands.contains(executable);
  }

  List<String> _extractHostsFromArguments(List<String> arguments) {
    final hosts = <String>[];
    final urlPattern = RegExp(r'https?://([^/\s]+)');
    
    for (final arg in arguments) {
      final match = urlPattern.firstMatch(arg);
      if (match != null) {
        hosts.add(match.group(1)!);
      }
    }
    
    return hosts;
  }
}

/// Parsed command structure
class ParsedCommand {
  final String executable;
  final List<String> arguments;
  final String fullCommand;

  const ParsedCommand({
    required this.executable,
    required this.arguments,
    required this.fullCommand,
  });
}

/// Security validation result
class SecurityValidationResult {
  final bool isAllowed;
  final String reason;
  final RiskLevel riskLevel;
  final bool requiresApproval;
  final MonitoringLevel monitoringLevel;
  final List<String> recommendations;

  const SecurityValidationResult._({
    required this.isAllowed,
    required this.reason,
    required this.riskLevel,
    this.requiresApproval = false,
    this.monitoringLevel = MonitoringLevel.basic,
    this.recommendations = const [],
  });

  factory SecurityValidationResult.allowed({
    required RiskLevel riskLevel,
    bool requiresApproval = false,
    MonitoringLevel monitoringLevel = MonitoringLevel.basic,
    List<String> recommendations = const [],
  }) {
    return SecurityValidationResult._(
      isAllowed: true,
      reason: 'Operation allowed',
      riskLevel: riskLevel,
      requiresApproval: requiresApproval,
      monitoringLevel: monitoringLevel,
      recommendations: recommendations,
    );
  }

  factory SecurityValidationResult.denied({
    required String reason,
    required RiskLevel riskLevel,
    List<String> recommendations = const [],
  }) {
    return SecurityValidationResult._(
      isAllowed: false,
      reason: reason,
      riskLevel: riskLevel,
      recommendations: recommendations,
    );
  }
}

/// Risk levels for operations
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Monitoring levels for operations
enum MonitoringLevel {
  basic,
  enhanced,
  comprehensive,
}

/// Security event types for audit logging
enum SecurityEventType {
  contextRegistered,
  contextUpdated,
  contextRemoved,
  commandAllowed,
  commandBlocked,
  fileAccessAllowed,
  fileAccessDenied,
  networkAccessAllowed,
  networkAccessDenied,
  apiAccessAllowed,
  apiAccessDenied,
  resourceLimitExceeded,
  rateLimitExceeded,
  tokenLimitExceeded,
  sensitiveFileAccess,
  suspiciousNetworkAccess,
  environmentAccessDenied,
  validationError,
}

/// Security audit event
class SecurityAuditEvent {
  final String agentId;
  final SecurityEventType type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const SecurityAuditEvent({
    required this.agentId,
    required this.type,
    required this.message,
    required this.timestamp,
    this.metadata = const {},
  });
}

/// Rate limiting tracker
class RateLimitTracker {
  final Map<String, List<DateTime>> _requestHistory = {};

  bool checkRateLimit(String key, int maxRequests, {Duration window = const Duration(minutes: 1)}) {
    final now = DateTime.now();
    final windowStart = now.subtract(window);
    
    // Clean old requests
    final requests = _requestHistory[key] ?? <DateTime>[];
    requests.removeWhere((time) => time.isBefore(windowStart));
    
    // Check limit
    if (requests.length >= maxRequests) {
      return false;
    }
    
    // Add current request
    requests.add(now);
    _requestHistory[key] = requests;
    
    return true;
  }

  void reset(String key) {
    _requestHistory.remove(key);
  }

  void resetAll() {
    _requestHistory.clear();
  }
}