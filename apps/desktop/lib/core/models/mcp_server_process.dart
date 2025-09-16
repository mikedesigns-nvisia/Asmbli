import 'package:equatable/equatable.dart';
import 'mcp_catalog_entry.dart' show MCPTransportType;
import 'agent_terminal.dart' show ValidationResult;

/// Status of an MCP server process
enum MCPServerStatus {
  starting,
  running,
  stopping,
  stopped,
  crashed,
  error,
  failed,
}

/// Configuration for MCP server process (compatible with existing system)
class MCPServerConfig extends Equatable {
  final String id;
  final String name;
  final String? type;
  final String command;
  final List<String> args;
  final String? workingDirectory;
  final Map<String, String>? env;
  final bool enabled;
  final DateTime? lastUsed;
  final String? description;
  final List<String> capabilities;
  final List<Map<String, dynamic>> requiredAuth;
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  final String? transport;
  final String url;
  final String protocol;
  final String? authToken;
  final Map<String, String>? headers;
  final int? timeout;
  final bool autoReconnect;
  final List<String>? fallbackProtocols;
  final bool? enableAutoDetection;
  final int? maxRetries;
  final int? retryDelay;
  final bool enablePolling;
  final Map<String, String>? requiredEnvVars;
  final Map<String, String>? optionalEnvVars;
  final String? status;
  final String? setupInstructions;
  
  // New properties for agent-terminal architecture
  final MCPTransportType transportType;
  final Map<String, String> environment;
  final Map<String, String> credentials;
  final Duration startupTimeout;
  final Duration healthCheckInterval;

  const MCPServerConfig({
    required this.id,
    required this.name,
    required this.url,
    this.type = 'mcp',
    this.command = '',
    this.args = const [],
    this.workingDirectory,
    this.env,
    this.enabled = true,
    this.lastUsed,
    this.description,
    this.capabilities = const [],
    this.requiredAuth = const [],
    this.createdAt,
    this.lastUpdated,
    this.transport,
    this.protocol = 'stdio',
    this.authToken,
    this.headers,
    this.timeout,
    this.autoReconnect = false,
    this.fallbackProtocols,
    this.enableAutoDetection,
    this.maxRetries,
    this.retryDelay,
    this.enablePolling = false,
    this.requiredEnvVars,
    this.optionalEnvVars,
    this.status,
    this.setupInstructions,
    // New properties
    this.transportType = MCPTransportType.stdio,
    this.environment = const {},
    this.credentials = const {},
    this.startupTimeout = const Duration(seconds: 30),
    this.healthCheckInterval = const Duration(seconds: 30),
  });

  MCPServerConfig copyWith({
    String? id,
    String? name,
    String? url,
    String? type,
    String? command,
    List<String>? args,
    String? workingDirectory,
    Map<String, String>? env,
    bool? enabled,
    DateTime? lastUsed,
    String? description,
    List<String>? capabilities,
    List<Map<String, dynamic>>? requiredAuth,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? transport,
    String? protocol,
    String? authToken,
    Map<String, String>? headers,
    int? timeout,
    bool? autoReconnect,
    List<String>? fallbackProtocols,
    bool? enableAutoDetection,
    int? maxRetries,
    int? retryDelay,
    bool? enablePolling,
    Map<String, String>? requiredEnvVars,
    Map<String, String>? optionalEnvVars,
    String? status,
    String? setupInstructions,
    MCPTransportType? transportType,
    Map<String, String>? environment,
    Map<String, String>? credentials,
    Duration? startupTimeout,
    Duration? healthCheckInterval,
  }) {
    return MCPServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      command: command ?? this.command,
      args: args ?? this.args,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      env: env ?? this.env,
      enabled: enabled ?? this.enabled,
      lastUsed: lastUsed ?? this.lastUsed,
      description: description ?? this.description,
      capabilities: capabilities ?? this.capabilities,
      requiredAuth: requiredAuth ?? this.requiredAuth,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      transport: transport ?? this.transport,
      protocol: protocol ?? this.protocol,
      authToken: authToken ?? this.authToken,
      headers: headers ?? this.headers,
      timeout: timeout ?? this.timeout,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      fallbackProtocols: fallbackProtocols ?? this.fallbackProtocols,
      enableAutoDetection: enableAutoDetection ?? this.enableAutoDetection,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      enablePolling: enablePolling ?? this.enablePolling,
      requiredEnvVars: requiredEnvVars ?? this.requiredEnvVars,
      optionalEnvVars: optionalEnvVars ?? this.optionalEnvVars,
      status: status ?? this.status,
      setupInstructions: setupInstructions ?? this.setupInstructions,
      transportType: transportType ?? this.transportType,
      environment: environment ?? this.environment,
      credentials: credentials ?? this.credentials,
      startupTimeout: startupTimeout ?? this.startupTimeout,
      healthCheckInterval: healthCheckInterval ?? this.healthCheckInterval,
    );
  }

  /// Validate the server configuration
  ValidationResult validate() {
    final errors = <String>[];
    
    if (id.isEmpty) {
      errors.add('Server ID cannot be empty');
    }
    
    if (name.isEmpty) {
      errors.add('Server name cannot be empty');
    }
    
    if (url.isEmpty) {
      errors.add('Server URL cannot be empty');
    }
    
    if (startupTimeout.inSeconds <= 0) {
      errors.add('Startup timeout must be positive');
    }
    
    if (healthCheckInterval.inSeconds <= 0) {
      errors.add('Health check interval must be positive');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Create from JSON
  factory MCPServerConfig.fromJson(Map<String, dynamic> json) {
    return MCPServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      type: json['type'] as String? ?? 'mcp',
      command: json['command'] as String? ?? '',
      args: (json['args'] as List<dynamic>?)?.cast<String>() ?? [],
      workingDirectory: json['workingDirectory'] as String?,
      env: json['env'] != null ? Map<String, String>.from(json['env'] as Map) : null,
      enabled: json['enabled'] as bool? ?? true,
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed'] as String) : null,
      description: json['description'] as String?,
      capabilities: (json['capabilities'] as List<dynamic>?)?.cast<String>() ?? [],
      requiredAuth: (json['requiredAuth'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated'] as String) : null,
      transport: json['transport'] as String?,
      protocol: json['protocol'] as String? ?? 'stdio',
      authToken: json['authToken'] as String?,
      headers: json['headers'] != null ? Map<String, String>.from(json['headers'] as Map) : null,
      timeout: json['timeout'] as int?,
      autoReconnect: json['autoReconnect'] as bool? ?? false,
      fallbackProtocols: (json['fallbackProtocols'] as List<dynamic>?)?.cast<String>(),
      enableAutoDetection: json['enableAutoDetection'] as bool?,
      maxRetries: json['maxRetries'] as int?,
      retryDelay: json['retryDelay'] as int?,
      enablePolling: json['enablePolling'] as bool? ?? false,
      requiredEnvVars: json['requiredEnvVars'] != null ? Map<String, String>.from(json['requiredEnvVars'] as Map) : null,
      optionalEnvVars: json['optionalEnvVars'] != null ? Map<String, String>.from(json['optionalEnvVars'] as Map) : null,
      status: json['status'] as String?,
      setupInstructions: json['setupInstructions'] as String?,
      transportType: MCPTransportType.values.firstWhere(
        (t) => t.name == json['transportType'],
        orElse: () => MCPTransportType.stdio,
      ),
      environment: Map<String, String>.from(json['environment'] as Map? ?? {}),
      credentials: Map<String, String>.from(json['credentials'] as Map? ?? {}),
      startupTimeout: Duration(milliseconds: json['startupTimeoutMs'] as int? ?? 30000),
      healthCheckInterval: Duration(milliseconds: json['healthCheckIntervalMs'] as int? ?? 30000),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'command': command,
      'args': args,
      'workingDirectory': workingDirectory,
      'env': env,
      'enabled': enabled,
      'lastUsed': lastUsed?.toIso8601String(),
      'description': description,
      'capabilities': capabilities,
      'requiredAuth': requiredAuth,
      'createdAt': createdAt?.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'transport': transport,
      'protocol': protocol,
      'authToken': authToken,
      'headers': headers,
      'timeout': timeout,
      'autoReconnect': autoReconnect,
      'fallbackProtocols': fallbackProtocols,
      'enableAutoDetection': enableAutoDetection,
      'maxRetries': maxRetries,
      'retryDelay': retryDelay,
      'enablePolling': enablePolling,
      'requiredEnvVars': requiredEnvVars,
      'optionalEnvVars': optionalEnvVars,
      'status': status,
      'setupInstructions': setupInstructions,
      'transportType': transportType.name,
      'environment': environment,
      'credentials': credentials,
      'startupTimeoutMs': startupTimeout.inMilliseconds,
      'healthCheckIntervalMs': healthCheckInterval.inMilliseconds,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        command,
        args,
        workingDirectory,
        env,
        enabled,
        lastUsed,
        description,
        capabilities,
        requiredAuth,
        createdAt,
        lastUpdated,
        transport,
        url,
        protocol,
        authToken,
        headers,
        timeout,
        autoReconnect,
        fallbackProtocols,
        enableAutoDetection,
        maxRetries,
        retryDelay,
        enablePolling,
        requiredEnvVars,
        optionalEnvVars,
        status,
        setupInstructions,
        transportType,
        environment,
        credentials,
        startupTimeout,
        healthCheckInterval,
      ];
}

/// Represents a running MCP server process
class MCPServerProcess extends Equatable {
  final String id;
  final String serverId;
  final String agentId;
  final MCPServerConfig config;
  final int? pid;
  final MCPServerStatus status;
  final DateTime startTime;
  final DateTime? stopTime;
  
  // Compatibility properties
  DateTime get startedAt => startTime;
  final DateTime? lastHealthCheck;
  final DateTime? lastOutput;
  final DateTime? lastError;
  final List<String> logs;
  final String? error;
  final int exitCode;
  final int restartCount;
  final Map<String, dynamic> metrics;

  const MCPServerProcess({
    required this.id,
    required this.serverId,
    required this.agentId,
    required this.config,
    required this.startTime,
    this.pid,
    this.status = MCPServerStatus.starting,
    this.stopTime,
    this.lastHealthCheck,
    this.lastOutput,
    this.lastError,
    this.logs = const [],
    this.error,
    this.exitCode = 0,
    this.restartCount = 0,
    this.metrics = const {},
  });

  MCPServerProcess copyWith({
    String? id,
    String? serverId,
    String? agentId,
    MCPServerConfig? config,
    int? pid,
    MCPServerStatus? status,
    DateTime? startTime,
    DateTime? stopTime,
    DateTime? lastHealthCheck,
    DateTime? lastOutput,
    DateTime? lastError,
    List<String>? logs,
    String? error,
    int? exitCode,
    int? restartCount,
    Map<String, dynamic>? metrics,
  }) {
    return MCPServerProcess(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      agentId: agentId ?? this.agentId,
      config: config ?? this.config,
      pid: pid ?? this.pid,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      stopTime: stopTime ?? this.stopTime,
      lastHealthCheck: lastHealthCheck ?? this.lastHealthCheck,
      lastOutput: lastOutput ?? this.lastOutput,
      lastError: lastError ?? this.lastError,
      logs: logs ?? this.logs,
      error: error ?? this.error,
      exitCode: exitCode ?? this.exitCode,
      restartCount: restartCount ?? this.restartCount,
      metrics: metrics ?? this.metrics,
    );
  }

  /// Check if the process is currently running
  bool get isRunning => status == MCPServerStatus.running;

  /// Check if the process has failed
  bool get hasFailed => status == MCPServerStatus.failed || status == MCPServerStatus.crashed;

  /// Get uptime duration
  Duration get uptime {
    if (stopTime != null) {
      return stopTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  /// Get process name for display
  String get displayName => config.name.isNotEmpty ? config.name : serverId;

  /// Check if the server is healthy (compatibility with existing code)
  bool get isHealthy => status == MCPServerStatus.running && error == null;

  /// Record an error (compatibility method)
  MCPServerProcess recordError(String errorMessage) {
    return copyWith(
      status: MCPServerStatus.error,
      error: errorMessage,
      lastError: DateTime.now(),
    );
  }

  /// Record activity (compatibility method)
  MCPServerProcess recordActivity() {
    return copyWith(
      lastOutput: DateTime.now(),
    );
  }

  /// Get process reference (compatibility - returns null since we manage processes differently)
  dynamic get process => null;

  /// Send JSON-RPC request (compatibility method)
  Future<Map<String, dynamic>> sendJsonRpcRequest(Map<String, dynamic> request) async {
    throw UnimplementedError('Use MCPProtocolHandler.sendRequest instead');
  }

  /// Send input (compatibility method)
  Future<void> sendInput(String input) async {
    throw UnimplementedError('Use MCPProtocolHandler.sendNotification instead');
  }

  /// Set initialization status (compatibility)
  set isInitialized(bool value) {
    // This is handled by the status field in the new architecture
  }

  /// Set healthy status (compatibility)
  set isHealthy(bool value) {
    // This is handled by the status field in the new architecture
  }

  /// Start a new MCP server process
  static Future<MCPServerProcess> start({
    required String id,
    required MCPServerConfig config,
    required Map<String, String> environmentVars,
    String? agentId,
  }) async {
    return MCPServerProcess(
      id: id,
      serverId: config.id,
      agentId: agentId ?? 'default',
      config: config,
      startTime: DateTime.now(),
      status: MCPServerStatus.starting,
    );
  }

  /// Create from JSON
  factory MCPServerProcess.fromJson(Map<String, dynamic> json) {
    return MCPServerProcess(
      id: json['id'] as String,
      serverId: json['serverId'] as String,
      agentId: json['agentId'] as String,
      config: MCPServerConfig.fromJson(json['config'] as Map<String, dynamic>),
      pid: json['pid'] as int?,
      status: MCPServerStatus.values.firstWhere((s) => s.name == json['status']),
      startTime: DateTime.parse(json['startTime'] as String),
      stopTime: json['stopTime'] != null ? DateTime.parse(json['stopTime'] as String) : null,
      lastHealthCheck: json['lastHealthCheck'] != null ? DateTime.parse(json['lastHealthCheck'] as String) : null,
      lastOutput: json['lastOutput'] != null ? DateTime.parse(json['lastOutput'] as String) : null,
      lastError: json['lastError'] != null ? DateTime.parse(json['lastError'] as String) : null,
      logs: (json['logs'] as List<dynamic>?)?.cast<String>() ?? [],
      error: json['error'] as String?,
      exitCode: json['exitCode'] as int? ?? 0,
      restartCount: json['restartCount'] as int? ?? 0,
      metrics: Map<String, dynamic>.from(json['metrics'] as Map? ?? {}),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serverId': serverId,
      'agentId': agentId,
      'config': config.toJson(),
      'pid': pid,
      'status': status.name,
      'startTime': startTime.toIso8601String(),
      'stopTime': stopTime?.toIso8601String(),
      'lastHealthCheck': lastHealthCheck?.toIso8601String(),
      'lastOutput': lastOutput?.toIso8601String(),
      'lastError': lastError?.toIso8601String(),
      'logs': logs,
      'error': error,
      'exitCode': exitCode,
      'restartCount': restartCount,
      'metrics': metrics,
    };
  }

  @override
  List<Object?> get props => [
        id,
        serverId,
        agentId,
        config,
        pid,
        status,
        startTime,
        stopTime,
        lastHealthCheck,
        lastOutput,
        lastError,
        logs,
        error,
        exitCode,
        restartCount,
        metrics,
      ];
}

/// Result of MCP server installation
class MCPInstallResult extends Equatable {
  final bool success;
  final String serverId;
  final String? error;
  final Duration installationTime;
  final List<String> installationLogs;

  const MCPInstallResult({
    required this.success,
    required this.serverId,
    this.error,
    required this.installationTime,
    this.installationLogs = const [],
  });

  /// Create from JSON
  factory MCPInstallResult.fromJson(Map<String, dynamic> json) {
    return MCPInstallResult(
      success: json['success'] as bool,
      serverId: json['serverId'] as String,
      error: json['error'] as String?,
      installationTime: Duration(milliseconds: json['installationTimeMs'] as int),
      installationLogs: (json['installationLogs'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'serverId': serverId,
      'error': error,
      'installationTimeMs': installationTime.inMilliseconds,
      'installationLogs': installationLogs,
    };
  }

  @override
  List<Object?> get props => [success, serverId, error, installationTime, installationLogs];
}

/// Progress tracking for MCP server installation
class MCPInstallationProgress extends Equatable {
  final String agentId;
  final String serverId;
  final MCPInstallationStage stage;
  final double progress; // 0.0 to 1.0
  final String message;
  final String? error;
  final DateTime timestamp;

  MCPInstallationProgress({
    required this.agentId,
    required this.serverId,
    required this.stage,
    required this.progress,
    required this.message,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create from JSON
  factory MCPInstallationProgress.fromJson(Map<String, dynamic> json) {
    return MCPInstallationProgress(
      agentId: json['agentId'] as String,
      serverId: json['serverId'] as String,
      stage: MCPInstallationStage.values.byName(json['stage'] as String),
      progress: (json['progress'] as num).toDouble(),
      message: json['message'] as String,
      error: json['error'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'serverId': serverId,
      'stage': stage.name,
      'progress': progress,
      'message': message,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [agentId, serverId, stage, progress, message, error, timestamp];
}

/// Stages of MCP server installation
enum MCPInstallationStage {
  starting,
  checkingDependencies,
  installing,
  verifying,
  completed,
  failed,
}

// MCPTransportType is imported from mcp_catalog_entry.dart

/// Transport configuration for MCP servers
class MCPTransportConfig extends Equatable {
  final MCPTransportType type;
  final String? host;
  final int? port;
  final String? path;
  final Map<String, String> headers;

  const MCPTransportConfig({
    required this.type,
    this.host,
    this.port,
    this.path,
    this.headers = const {},
  });

  /// Create from JSON
  factory MCPTransportConfig.fromJson(Map<String, dynamic> json) {
    return MCPTransportConfig(
      type: MCPTransportType.values.firstWhere((t) => t.name == json['type']),
      host: json['host'] as String?,
      port: json['port'] as int?,
      path: json['path'] as String?,
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'host': host,
      'port': port,
      'path': path,
      'headers': headers,
    };
  }

  @override
  List<Object?> get props => [type, host, port, path, headers];
}