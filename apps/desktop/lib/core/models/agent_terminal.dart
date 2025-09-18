import 'dart:async';
import 'package:equatable/equatable.dart';
import 'mcp_server_process.dart';

/// Status of an agent terminal
enum TerminalStatus {
  creating,
  ready,
  busy,
  error,
  terminated,
}

/// Configuration for agent terminal
class AgentTerminalConfig extends Equatable {
  final String agentId;
  final String workingDirectory;
  final Map<String, String> environment;
  final SecurityContext securityContext;
  final ResourceLimits resourceLimits;
  final bool persistState;
  final Duration commandTimeout;

  const AgentTerminalConfig({
    required this.agentId,
    required this.workingDirectory,
    this.environment = const {},
    required this.securityContext,
    required this.resourceLimits,
    this.persistState = true,
    this.commandTimeout = const Duration(minutes: 5),
  });

  /// Validate the configuration
  ValidationResult validate() {
    final errors = <String>[];
    
    if (agentId.isEmpty) {
      errors.add('Agent ID cannot be empty');
    }
    
    if (workingDirectory.isEmpty) {
      errors.add('Working directory cannot be empty');
    }
    
    if (commandTimeout.inSeconds <= 0) {
      errors.add('Command timeout must be positive');
    }
    
    // Validate security context
    final securityValidation = securityContext.validate();
    if (!securityValidation.isValid) {
      errors.addAll(securityValidation.errors);
    }
    
    // Validate resource limits
    final resourceValidation = resourceLimits.validate();
    if (!resourceValidation.isValid) {
      errors.addAll(resourceValidation.errors);
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Create from JSON
  factory AgentTerminalConfig.fromJson(Map<String, dynamic> json) {
    return AgentTerminalConfig(
      agentId: json['agentId'] as String,
      workingDirectory: json['workingDirectory'] as String,
      environment: Map<String, String>.from(json['environment'] as Map? ?? {}),
      securityContext: SecurityContext.fromJson(json['securityContext'] as Map<String, dynamic>),
      resourceLimits: ResourceLimits.fromJson(json['resourceLimits'] as Map<String, dynamic>),
      persistState: json['persistState'] as bool? ?? true,
      commandTimeout: Duration(milliseconds: json['commandTimeoutMs'] as int? ?? 300000),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'workingDirectory': workingDirectory,
      'environment': environment,
      'securityContext': securityContext.toJson(),
      'resourceLimits': resourceLimits.toJson(),
      'persistState': persistState,
      'commandTimeoutMs': commandTimeout.inMilliseconds,
    };
  }

  @override
  List<Object?> get props => [
        agentId,
        workingDirectory,
        environment,
        securityContext,
        resourceLimits,
        persistState,
        commandTimeout,
      ];
}

/// Security context for agent operations
class SecurityContext extends Equatable {
  final String agentId;
  final List<String> allowedCommands;
  final List<String> blockedCommands;
  final Map<String, String> allowedPaths;
  final List<String> allowedNetworkHosts;
  final Map<String, APIPermission> apiPermissions;
  final ResourceLimits resourceLimits;
  final bool auditLogging;
  final TerminalPermissions terminalPermissions;

  const SecurityContext({
    required this.agentId,
    this.allowedCommands = const [],
    this.blockedCommands = const [],
    this.allowedPaths = const {},
    this.allowedNetworkHosts = const [],
    this.apiPermissions = const {},
    required this.resourceLimits,
    this.auditLogging = true,
    required this.terminalPermissions,
  });

  /// Validate the security context
  ValidationResult validate() {
    final errors = <String>[];
    
    if (agentId.isEmpty) {
      errors.add('Security context agent ID cannot be empty');
    }
    
    // Validate API permissions
    for (final entry in apiPermissions.entries) {
      final validation = entry.value.validate();
      if (!validation.isValid) {
        errors.addAll(validation.errors.map((e) => 'API permission ${entry.key}: $e'));
      }
    }
    
    // Validate terminal permissions
    final terminalValidation = terminalPermissions.validate();
    if (!terminalValidation.isValid) {
      errors.addAll(terminalValidation.errors);
    }
    
    // Validate resource limits
    final resourceValidation = resourceLimits.validate();
    if (!resourceValidation.isValid) {
      errors.addAll(resourceValidation.errors);
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Create from JSON
  factory SecurityContext.fromJson(Map<String, dynamic> json) {
    return SecurityContext(
      agentId: json['agentId'] as String,
      allowedCommands: (json['allowedCommands'] as List<dynamic>?)?.cast<String>() ?? [],
      blockedCommands: (json['blockedCommands'] as List<dynamic>?)?.cast<String>() ?? [],
      allowedPaths: Map<String, String>.from(json['allowedPaths'] as Map? ?? {}),
      allowedNetworkHosts: (json['allowedNetworkHosts'] as List<dynamic>?)?.cast<String>() ?? [],
      apiPermissions: (json['apiPermissions'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, APIPermission.fromJson(value as Map<String, dynamic>)),
      ) ?? {},
      resourceLimits: ResourceLimits.fromJson(json['resourceLimits'] as Map<String, dynamic>),
      auditLogging: json['auditLogging'] as bool? ?? true,
      terminalPermissions: TerminalPermissions.fromJson(json['terminalPermissions'] as Map<String, dynamic>),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'allowedCommands': allowedCommands,
      'blockedCommands': blockedCommands,
      'allowedPaths': allowedPaths,
      'allowedNetworkHosts': allowedNetworkHosts,
      'apiPermissions': apiPermissions.map((key, value) => MapEntry(key, value.toJson())),
      'resourceLimits': resourceLimits.toJson(),
      'auditLogging': auditLogging,
      'terminalPermissions': terminalPermissions.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        agentId,
        allowedCommands,
        blockedCommands,
        allowedPaths,
        allowedNetworkHosts,
        apiPermissions,
        resourceLimits,
        auditLogging,
        terminalPermissions,
      ];
}

/// API permission configuration
class APIPermission extends Equatable {
  final String provider; // 'anthropic', 'openai', 'local'
  final List<String> allowedModels;
  final int maxRequestsPerMinute;
  final int maxTokensPerRequest;
  final bool canMakeDirectCalls;
  final Map<String, String> requiredHeaders;
  final Map<String, String> secureCredentials;

  const APIPermission({
    required this.provider,
    this.allowedModels = const [],
    this.maxRequestsPerMinute = 60,
    this.maxTokensPerRequest = 4000,
    this.canMakeDirectCalls = false,
    this.requiredHeaders = const {},
    this.secureCredentials = const {},
  });

  /// Validate the API permission
  ValidationResult validate() {
    final errors = <String>[];
    
    if (provider.isEmpty) {
      errors.add('Provider cannot be empty');
    }
    
    if (maxRequestsPerMinute <= 0) {
      errors.add('Max requests per minute must be positive');
    }
    
    if (maxTokensPerRequest <= 0) {
      errors.add('Max tokens per request must be positive');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Create from JSON
  factory APIPermission.fromJson(Map<String, dynamic> json) {
    return APIPermission(
      provider: json['provider'] as String,
      allowedModels: (json['allowedModels'] as List<dynamic>?)?.cast<String>() ?? [],
      maxRequestsPerMinute: json['maxRequestsPerMinute'] as int? ?? 60,
      maxTokensPerRequest: json['maxTokensPerRequest'] as int? ?? 4000,
      canMakeDirectCalls: json['canMakeDirectCalls'] as bool? ?? false,
      requiredHeaders: Map<String, String>.from(json['requiredHeaders'] as Map? ?? {}),
      secureCredentials: Map<String, String>.from(json['secureCredentials'] as Map? ?? {}),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'allowedModels': allowedModels,
      'maxRequestsPerMinute': maxRequestsPerMinute,
      'maxTokensPerRequest': maxTokensPerRequest,
      'canMakeDirectCalls': canMakeDirectCalls,
      'requiredHeaders': requiredHeaders,
      'secureCredentials': secureCredentials,
    };
  }

  @override
  List<Object?> get props => [
        provider,
        allowedModels,
        maxRequestsPerMinute,
        maxTokensPerRequest,
        canMakeDirectCalls,
        requiredHeaders,
        secureCredentials,
      ];
}

/// Terminal permissions configuration
class TerminalPermissions extends Equatable {
  final bool canExecuteShellCommands;
  final bool canInstallPackages;
  final bool canModifyEnvironment;
  final bool canAccessNetwork;
  final List<String> commandWhitelist;
  final List<String> commandBlacklist;
  final Map<String, String> secureEnvironmentVars;
  final bool requiresApprovalForAPIcalls;

  const TerminalPermissions({
    this.canExecuteShellCommands = true,
    this.canInstallPackages = false,
    this.canModifyEnvironment = true,
    this.canAccessNetwork = true,
    this.commandWhitelist = const [],
    this.commandBlacklist = const [],
    this.secureEnvironmentVars = const {},
    this.requiresApprovalForAPIcalls = false,
  });

  /// Validate the terminal permissions
  ValidationResult validate() {
    final errors = <String>[];
    
    // Check for conflicting whitelist/blacklist entries
    for (final whitelistCmd in commandWhitelist) {
      for (final blacklistCmd in commandBlacklist) {
        if (whitelistCmd.toLowerCase().contains(blacklistCmd.toLowerCase()) ||
            blacklistCmd.toLowerCase().contains(whitelistCmd.toLowerCase())) {
          errors.add('Conflicting command in whitelist and blacklist: $whitelistCmd vs $blacklistCmd');
        }
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Create from JSON
  factory TerminalPermissions.fromJson(Map<String, dynamic> json) {
    return TerminalPermissions(
      canExecuteShellCommands: json['canExecuteShellCommands'] as bool? ?? true,
      canInstallPackages: json['canInstallPackages'] as bool? ?? false,
      canModifyEnvironment: json['canModifyEnvironment'] as bool? ?? true,
      canAccessNetwork: json['canAccessNetwork'] as bool? ?? true,
      commandWhitelist: (json['commandWhitelist'] as List<dynamic>?)?.cast<String>() ?? [],
      commandBlacklist: (json['commandBlacklist'] as List<dynamic>?)?.cast<String>() ?? [],
      secureEnvironmentVars: Map<String, String>.from(json['secureEnvironmentVars'] as Map? ?? {}),
      requiresApprovalForAPIcalls: json['requiresApprovalForAPIcalls'] as bool? ?? false,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'canExecuteShellCommands': canExecuteShellCommands,
      'canInstallPackages': canInstallPackages,
      'canModifyEnvironment': canModifyEnvironment,
      'canAccessNetwork': canAccessNetwork,
      'commandWhitelist': commandWhitelist,
      'commandBlacklist': commandBlacklist,
      'secureEnvironmentVars': secureEnvironmentVars,
      'requiresApprovalForAPIcalls': requiresApprovalForAPIcalls,
    };
  }

  @override
  List<Object?> get props => [
        canExecuteShellCommands,
        canInstallPackages,
        canModifyEnvironment,
        canAccessNetwork,
        commandWhitelist,
        commandBlacklist,
        secureEnvironmentVars,
        requiresApprovalForAPIcalls,
      ];
}

/// Resource limits for agent operations
class ResourceLimits extends Equatable {
  final int maxMemoryMB;
  final int maxCpuPercent;
  final int maxProcesses;
  final Duration maxExecutionTime;
  final int maxFileSize;
  final int maxNetworkConnections;

  const ResourceLimits({
    this.maxMemoryMB = 512,
    this.maxCpuPercent = 50,
    this.maxProcesses = 10,
    this.maxExecutionTime = const Duration(minutes: 10),
    this.maxFileSize = 100 * 1024 * 1024, // 100MB
    this.maxNetworkConnections = 10,
  });

  /// Validate the resource limits
  ValidationResult validate() {
    final errors = <String>[];
    
    if (maxMemoryMB <= 0) {
      errors.add('Max memory must be positive');
    }
    
    if (maxCpuPercent <= 0 || maxCpuPercent > 100) {
      errors.add('Max CPU percent must be between 1 and 100');
    }
    
    if (maxProcesses <= 0) {
      errors.add('Max processes must be positive');
    }
    
    if (maxExecutionTime.inSeconds <= 0) {
      errors.add('Max execution time must be positive');
    }
    
    if (maxFileSize <= 0) {
      errors.add('Max file size must be positive');
    }
    
    if (maxNetworkConnections <= 0) {
      errors.add('Max network connections must be positive');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Create from JSON
  factory ResourceLimits.fromJson(Map<String, dynamic> json) {
    return ResourceLimits(
      maxMemoryMB: json['maxMemoryMB'] as int? ?? 512,
      maxCpuPercent: json['maxCpuPercent'] as int? ?? 50,
      maxProcesses: json['maxProcesses'] as int? ?? 10,
      maxExecutionTime: Duration(milliseconds: json['maxExecutionTimeMs'] as int? ?? 600000),
      maxFileSize: json['maxFileSize'] as int? ?? 100 * 1024 * 1024,
      maxNetworkConnections: json['maxNetworkConnections'] as int? ?? 10,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'maxMemoryMB': maxMemoryMB,
      'maxCpuPercent': maxCpuPercent,
      'maxProcesses': maxProcesses,
      'maxExecutionTimeMs': maxExecutionTime.inMilliseconds,
      'maxFileSize': maxFileSize,
      'maxNetworkConnections': maxNetworkConnections,
    };
  }

  @override
  List<Object?> get props => [
        maxMemoryMB,
        maxCpuPercent,
        maxProcesses,
        maxExecutionTime,
        maxFileSize,
        maxNetworkConnections,
      ];
}

/// Command execution result
class CommandResult extends Equatable {
  final String command;
  final int exitCode;
  final String stdout;
  final String stderr;
  final Duration executionTime;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const CommandResult({
    required this.command,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.executionTime,
    required this.timestamp,
    this.metadata = const {},
  });

  bool get isSuccess => exitCode == 0;
  bool get hasError => exitCode != 0 || stderr.isNotEmpty;
  
  /// Create from JSON
  factory CommandResult.fromJson(Map<String, dynamic> json) {
    return CommandResult(
      command: json['command'] as String,
      exitCode: json['exitCode'] as int,
      stdout: json['stdout'] as String,
      stderr: json['stderr'] as String,
      executionTime: Duration(milliseconds: json['executionTimeMs'] as int),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'exitCode': exitCode,
      'stdout': stdout,
      'stderr': stderr,
      'executionTimeMs': executionTime.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        command,
        exitCode,
        stdout,
        stderr,
        executionTime,
        timestamp,
        metadata,
      ];
}

/// Command history entry
class CommandHistory extends Equatable {
  final String command;
  final DateTime timestamp;
  final CommandResult? result;
  final bool wasSuccessful;

  const CommandHistory({
    required this.command,
    required this.timestamp,
    this.result,
    required this.wasSuccessful,
  });

  /// Create from JSON
  factory CommandHistory.fromJson(Map<String, dynamic> json) {
    return CommandHistory(
      command: json['command'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      result: json['result'] != null ? CommandResult.fromJson(json['result'] as Map<String, dynamic>) : null,
      wasSuccessful: json['wasSuccessful'] as bool,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'timestamp': timestamp.toIso8601String(),
      'result': result?.toJson(),
      'wasSuccessful': wasSuccessful,
    };
  }

  @override
  List<Object?> get props => [command, timestamp, result, wasSuccessful];
}

/// Terminal output for streaming
class TerminalOutput extends Equatable {
  final String agentId;
  final String content;
  final TerminalOutputType type;
  final DateTime timestamp;

  const TerminalOutput({
    required this.agentId,
    required this.content,
    required this.type,
    required this.timestamp,
  });

  /// Create from JSON
  factory TerminalOutput.fromJson(Map<String, dynamic> json) {
    return TerminalOutput(
      agentId: json['agentId'] as String,
      content: json['content'] as String,
      type: TerminalOutputType.values.firstWhere((t) => t.name == json['type']),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [agentId, content, type, timestamp];
}

/// Type of terminal output
enum TerminalOutputType {
  stdout,
  stderr,
  command,
  system,
  error,
}

/// API call result
class APICallResult extends Equatable {
  final String provider;
  final String model;
  final bool success;
  final Map<String, dynamic>? response;
  final String? error;
  final Duration executionTime;
  final DateTime timestamp;
  final int tokensUsed;

  const APICallResult({
    required this.provider,
    required this.model,
    required this.success,
    this.response,
    this.error,
    required this.executionTime,
    required this.timestamp,
    this.tokensUsed = 0,
  });

  /// Create from JSON
  factory APICallResult.fromJson(Map<String, dynamic> json) {
    return APICallResult(
      provider: json['provider'] as String,
      model: json['model'] as String,
      success: json['success'] as bool,
      response: json['response'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      executionTime: Duration(milliseconds: json['executionTimeMs'] as int),
      timestamp: DateTime.parse(json['timestamp'] as String),
      tokensUsed: json['tokensUsed'] as int? ?? 0,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'model': model,
      'success': success,
      'response': response,
      'error': error,
      'executionTimeMs': executionTime.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'tokensUsed': tokensUsed,
    };
  }

  @override
  List<Object?> get props => [
        provider,
        model,
        success,
        response,
        error,
        executionTime,
        timestamp,
        tokensUsed,
      ];
}

/// Security validation result
class SecurityValidationResult extends Equatable {
  final bool isAllowed;
  final String? reason;
  final List<String> violations;
  final SecurityAction recommendedAction;

  const SecurityValidationResult({
    required this.isAllowed,
    this.reason,
    this.violations = const [],
    required this.recommendedAction,
  });

  /// Create from JSON
  factory SecurityValidationResult.fromJson(Map<String, dynamic> json) {
    return SecurityValidationResult(
      isAllowed: json['isAllowed'] as bool,
      reason: json['reason'] as String?,
      violations: (json['violations'] as List<dynamic>?)?.cast<String>() ?? [],
      recommendedAction: SecurityAction.values.firstWhere((a) => a.name == json['recommendedAction']),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isAllowed': isAllowed,
      'reason': reason,
      'violations': violations,
      'recommendedAction': recommendedAction.name,
    };
  }

  @override
  List<Object?> get props => [isAllowed, reason, violations, recommendedAction];
}

/// Security action recommendations
enum SecurityAction {
  allow,
  deny,
  requireApproval,
  sanitize,
  log,
}

/// Agent terminal interface
abstract class AgentTerminal {
  String get agentId;
  String get workingDirectory;
  Map<String, String> get environment;
  TerminalStatus get status;
  DateTime get createdAt;
  DateTime get lastActivity;
  List<MCPServerProcess> get mcpServers;
  List<CommandHistory> get history;

  /// Execute command and return result
  Future<CommandResult> execute(String command);

  /// Execute command and stream output
  Stream<String> executeStream(String command);

  /// Change working directory
  Future<void> changeDirectory(String path);

  /// Set environment variable
  Future<void> setEnvironment(String key, String value);

  /// Get terminal history
  List<CommandHistory> getHistory();

  /// Add MCP server to this terminal
  Future<void> addMCPServer(MCPServerProcess server);

  /// Remove MCP server from this terminal
  Future<void> removeMCPServer(String serverId);

  /// Kill all processes and cleanup
  Future<void> terminate();
}

/// Validation result for model validation
class ValidationResult extends Equatable {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  @override
  List<Object?> get props => [isValid, errors];
}