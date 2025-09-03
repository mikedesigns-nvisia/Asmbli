/// MCP Server Configuration Model
class MCPServerConfig {
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
  // Additional properties from settings service
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  final String? transport; // 'stdio' or 'sse'
  final String url; // URL is now required for adapter framework
  
  // New properties for MCP adapter framework
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
  
  // Missing properties that are referenced in the UI
  final Map<String, String>? requiredEnvVars;
  final Map<String, String>? optionalEnvVars;
  final String? status;
  final String? setupInstructions;

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
    // New adapter framework properties
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
    // Missing properties
    this.requiredEnvVars,
    this.optionalEnvVars,
    this.status,
    this.setupInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
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
      'url': url,
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
    };
  }

  factory MCPServerConfig.fromJson(Map<String, dynamic> json) {
    return MCPServerConfig(
      id: json['id'],
      name: json['name'],
      url: json['url'] ?? '',
      type: json['type'] ?? 'mcp',
      command: json['command'] ?? '',
      args: json['args'] != null ? List<String>.from(json['args']) : [],
      workingDirectory: json['workingDirectory'],
      env: json['env']?.cast<String, String>(),
      enabled: json['enabled'] ?? true,
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      description: json['description'],
      capabilities: List<String>.from(json['capabilities'] ?? []),
      requiredAuth: List<Map<String, dynamic>>.from(json['requiredAuth'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : null,
      transport: json['transport'],
      protocol: json['protocol'] ?? 'stdio',
      authToken: json['authToken'],
      headers: json['headers']?.cast<String, String>(),
      timeout: json['timeout'],
      autoReconnect: json['autoReconnect'] ?? false,
      fallbackProtocols: json['fallbackProtocols'] != null ? List<String>.from(json['fallbackProtocols']) : null,
      enableAutoDetection: json['enableAutoDetection'],
      maxRetries: json['maxRetries'],
      retryDelay: json['retryDelay'],
      enablePolling: json['enablePolling'] ?? false,
      requiredEnvVars: json['requiredEnvVars'] != null ? Map<String, String>.from(json['requiredEnvVars']) : null,
      optionalEnvVars: json['optionalEnvVars'] != null ? Map<String, String>.from(json['optionalEnvVars']) : null,
      status: json['status'],
      setupInstructions: json['setupInstructions'],
    );
  }
  
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
    );
  }
}