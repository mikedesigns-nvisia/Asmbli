import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'desktop/desktop_storage_service.dart';
import 'desktop/desktop_service_provider.dart';

/// Global MCP (Model Context Protocol) settings service
/// Manages server configurations, API assignments, and runtime status
class MCPSettingsService {
  final DesktopStorageService _storageService;
  
  // Global MCP server configurations
  final Map<String, MCPServerConfig> _globalMCPConfigs = {};
  
  // Direct API configurations (for services like Anthropic, OpenAI)
  final Map<String, DirectAPIConfig> _directAPIConfigs = {};
  
  // Agent-specific API assignments (agent_id -> api_config_id)
  final Map<String, String> _agentApiMappings = {};
  
  // Runtime server connection status
  final Map<String, MCPServerStatus> _serverStatuses = {};
  
  // Global context documents available to all agents
  final List<String> _globalContextDocuments = [];
  
  // Settings updates stream
  final StreamController<Map<String, dynamic>> _settingsUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();

  MCPSettingsService(this._storageService) {
    _loadSettings();
  }

  /// Load all MCP settings from storage
  Future<void> _loadSettings() async {
    await _loadMCPConfigs();
    await _loadDirectAPIConfigs();
    await _loadAgentApiMappings();
    await _loadGlobalContext();
    await _initializeServerStatuses();
  }

  /// Save all settings to storage
  Future<void> saveSettings() async {
    await _saveMCPConfigs();
    await _saveDirectAPIConfigs();
    await _saveAgentApiMappings();
    await _saveGlobalContext();
  }

  // ==================== MCP Server Configuration ====================

  /// Get all configured MCP servers
  Map<String, MCPServerConfig> get allMCPServers => Map.from(_globalMCPConfigs);

  /// Get all MCP server configs (alias for health monitoring)
  List<MCPServerConfig> getAllMCPServers() {
    return _globalMCPConfigs.values.toList();
  }

  /// Stream of settings changes for health monitoring
  Stream<Map<String, dynamic>> get settingsUpdates => _settingsUpdatesController.stream;

  /// Get MCP server configuration by ID
  MCPServerConfig? getMCPServer(String serverId) => _globalMCPConfigs[serverId];

  /// Add or update MCP server configuration
  Future<void> setMCPServer(String serverId, MCPServerConfig config) async {
    _globalMCPConfigs[serverId] = config;
    await _saveMCPConfigs();
    
    // Initialize status for new server
    _serverStatuses[serverId] = MCPServerStatus(
      serverId: serverId,
      isConnected: false,
      lastChecked: DateTime.now(),
      status: ConnectionStatus.disconnected,
    );
  }

  /// Remove MCP server configuration
  Future<void> removeMCPServer(String serverId) async {
    _globalMCPConfigs.remove(serverId);
    _serverStatuses.remove(serverId);
    await _saveMCPConfigs();
  }

  /// Test connection to MCP server
  Future<MCPServerStatus> testMCPServerConnection(String serverId) async {
    final config = _globalMCPConfigs[serverId];
    if (config == null) {
      throw Exception('MCP server $serverId not found');
    }

    _serverStatuses[serverId] = MCPServerStatus(
      serverId: serverId,
      isConnected: false,
      lastChecked: DateTime.now(),
      status: ConnectionStatus.connecting,
      message: 'Testing connection...',
    );

    try {
      // TODO: Implement actual MCP connection test via bridge service
      await Future.delayed(Duration(seconds: 2)); // Simulate connection test
      
      // Mock validation based on server type
      bool isValid = await _validateServerCredentials(config);
      
      _serverStatuses[serverId] = MCPServerStatus(
        serverId: serverId,
        isConnected: isValid,
        lastChecked: DateTime.now(),
        status: isValid ? ConnectionStatus.connected : ConnectionStatus.error,
        message: isValid ? 'Connected successfully' : 'Authentication failed',
      );
      
      return _serverStatuses[serverId]!;
    } catch (e) {
      _serverStatuses[serverId] = MCPServerStatus(
        serverId: serverId,
        isConnected: false,
        lastChecked: DateTime.now(),
        status: ConnectionStatus.error,
        message: 'Connection failed: $e',
      );
      
      return _serverStatuses[serverId]!;
    }
  }

  /// Get current status of MCP server
  MCPServerStatus? getMCPServerStatus(String serverId) => _serverStatuses[serverId];

  /// Get status of multiple MCP servers
  Map<String, MCPServerStatus> getMCPServerStatuses(List<String> serverIds) {
    return Map.fromEntries(
      serverIds.where((id) => _serverStatuses.containsKey(id))
              .map((id) => MapEntry(id, _serverStatuses[id]!))
    );
  }

  // ==================== Direct API Configuration ====================

  /// Get all direct API configurations
  Map<String, DirectAPIConfig> get allDirectAPIConfigs => Map.from(_directAPIConfigs);

  /// Get direct API configuration by ID
  DirectAPIConfig? getDirectAPIConfig(String id) => _directAPIConfigs[id];

  /// Get the default direct API configuration
  DirectAPIConfig? get defaultDirectAPIConfig {
    return _directAPIConfigs.values.where((config) => config.isDefault).firstOrNull;
  }

  /// Add or update direct API configuration
  Future<void> setDirectAPIConfig(String id, DirectAPIConfig config) async {
    // If this is being set as default, remove default from others
    if (config.isDefault) {
      for (final existingConfig in _directAPIConfigs.values) {
        if (existingConfig.id != id && existingConfig.isDefault) {
          _directAPIConfigs[existingConfig.id] = existingConfig.copyWith(isDefault: false);
        }
      }
    }

    _directAPIConfigs[id] = config;
    await _saveDirectAPIConfigs();
    _settingsUpdatesController.add({'directAPIConfigs': _directAPIConfigs});
  }

  /// Remove direct API configuration
  Future<void> removeDirectAPIConfig(String id) async {
    final removed = _directAPIConfigs.remove(id);
    if (removed != null) {
      // If we removed the default, set another as default
      if (removed.isDefault && _directAPIConfigs.isNotEmpty) {
        final newDefault = _directAPIConfigs.values.first;
        _directAPIConfigs[newDefault.id] = newDefault.copyWith(isDefault: true);
      }
      await _saveDirectAPIConfigs();
      _settingsUpdatesController.add({'directAPIConfigs': _directAPIConfigs});
    }
  }

  /// Set default direct API configuration
  Future<void> setDefaultDirectAPIConfig(String id) async {
    if (_directAPIConfigs.containsKey(id)) {
      // Remove default from all configs
      for (final config in _directAPIConfigs.values) {
        if (config.isDefault) {
          _directAPIConfigs[config.id] = config.copyWith(isDefault: false);
        }
      }
      // Set new default
      final config = _directAPIConfigs[id]!;
      _directAPIConfigs[id] = config.copyWith(isDefault: true);
      await _saveDirectAPIConfigs();
      _settingsUpdatesController.add({'directAPIConfigs': _directAPIConfigs});
    }
  }

  /// Load direct API configurations from storage
  Future<void> _loadDirectAPIConfigs() async {
    try {
      final data = _storageService.getPreference<String>('direct_api_configs');
      if (data != null) {
        final Map<String, dynamic> configsJson = Map<String, dynamic>.from(json.decode(data));
        for (final entry in configsJson.entries) {
          _directAPIConfigs[entry.key] = DirectAPIConfig.fromJson(entry.value);
        }
      }

      // Create default configuration if none exists
      if (_directAPIConfigs.isEmpty) {
        await _createDefaultDirectAPIConfig();
      }
    } catch (e) {
      print('Error loading direct API configs: $e');
      await _createDefaultDirectAPIConfig();
    }
  }

  /// Save direct API configurations to storage
  Future<void> _saveDirectAPIConfigs() async {
    try {
      final Map<String, dynamic> configsJson = {};
      for (final entry in _directAPIConfigs.entries) {
        configsJson[entry.key] = entry.value.toJson();
      }
      await _storageService.setPreference('direct_api_configs', json.encode(configsJson));
    } catch (e) {
      print('Error saving direct API configs: $e');
    }
  }

  /// Create default direct API configuration
  Future<void> _createDefaultDirectAPIConfig() async {
    final defaultConfig = DirectAPIConfig(
      id: 'anthropic-default',
      name: 'Default API Model',
      provider: 'Anthropic',
      model: 'claude-3-5-sonnet-20241022',
      apiKey: '',
      baseUrl: 'https://api.anthropic.com',
      isDefault: true,
      enabled: true,
      createdAt: DateTime.now(),
    );

    _directAPIConfigs[defaultConfig.id] = defaultConfig;
    await _saveDirectAPIConfigs();
  }

  // ==================== Agent API Assignments ====================

  /// Get API configuration ID for agent
  String? getAgentApiMapping(String agentId) => _agentApiMappings[agentId];

  /// Set API configuration for agent
  Future<void> setAgentApiMapping(String agentId, String apiConfigId) async {
    _agentApiMappings[agentId] = apiConfigId;
    await _saveAgentApiMappings();
  }

  /// Get all agent API assignments
  Map<String, String> get allAgentApiMappings => Map.from(_agentApiMappings);

  // ==================== Global Context Management ====================

  /// Get global context documents
  List<String> get globalContextDocuments => List.from(_globalContextDocuments);

  /// Add global context document
  Future<void> addGlobalContextDocument(String documentPath) async {
    if (!_globalContextDocuments.contains(documentPath)) {
      _globalContextDocuments.add(documentPath);
      await _saveGlobalContext();
    }
  }

  /// Remove global context document
  Future<void> removeGlobalContextDocument(String documentPath) async {
    _globalContextDocuments.remove(documentPath);
    await _saveGlobalContext();
  }

  // ==================== Agent Configuration Assembly ====================

  /// Get complete agent configuration for deployment
  Future<AgentDeploymentConfig> getAgentDeploymentConfig(String agentId) async {
    // Get agent's assigned API config
    final apiConfigId = _agentApiMappings[agentId];
    
    // Get agent's MCP servers (from agent definition)
    // This would normally come from the agent's metadata
    final agentMCPServers = <String>[]; // TODO: Get from agent definition
    
    // Build MCP server configs with global settings
    final mcpConfigs = <String, Map<String, dynamic>>{};
    for (final serverId in agentMCPServers) {
      final config = _globalMCPConfigs[serverId];
      if (config != null) {
        mcpConfigs[serverId] = config.toJson();
      }
    }
    
    // Combine agent-specific and global context
    final contextDocs = <String>[
      ...globalContextDocuments,
      // TODO: Add agent-specific context documents
    ];
    
    return AgentDeploymentConfig(
      agentId: agentId,
      apiConfigId: apiConfigId,
      mcpServerConfigs: mcpConfigs,
      contextDocuments: contextDocs,
      timestamp: DateTime.now(),
    );
  }

  // ==================== Private Methods ====================

  Future<void> _loadMCPConfigs() async {
    try {
      final data = _storageService.getAllHiveData('mcp_servers');
      final Map<String, dynamic> configs = Map<String, dynamic>.from(data);
      _globalMCPConfigs.clear();
      configs.forEach((key, value) {
        _globalMCPConfigs[key] = MCPServerConfig.fromJson(value);
      });
    } catch (e) {
      // Handle loading error, use defaults
    }
  }

  Future<void> _saveMCPConfigs() async {
    final data = <String, dynamic>{};
    _globalMCPConfigs.forEach((key, value) {
      data[key] = value.toJson();
    });
    for (final entry in data.entries) {
      await _storageService.setHiveData('mcp_servers', entry.key, entry.value);
    }
  }

  Future<void> _loadAgentApiMappings() async {
    try {
  final data = _storageService.getAllHiveData('settings');
  _agentApiMappings.clear();
  _agentApiMappings.addAll(Map<String, String>.from(data));
    } catch (e) {
      // Handle loading error, use defaults
    }
  }

  Future<void> _saveAgentApiMappings() async {
    await _storageService.setHiveData('settings', 'agent_api_mappings', _agentApiMappings);
  }

  Future<void> _loadGlobalContext() async {
    try {
      final data = _storageService.getHiveData('settings', 'global_context_documents');
      if (data != null) {
        _globalContextDocuments.clear();
        _globalContextDocuments.addAll(List<String>.from(data));
      }
    } catch (e) {
      // Handle loading error, use defaults
    }
  }

  Future<void> _saveGlobalContext() async {
    await _storageService.setHiveData('settings', 'global_context_documents', _globalContextDocuments);
  }

  Future<void> _initializeServerStatuses() async {
    for (final serverId in _globalMCPConfigs.keys) {
      _serverStatuses[serverId] = MCPServerStatus(
        serverId: serverId,
        isConnected: false,
        lastChecked: DateTime.now().subtract(Duration(hours: 1)),
        status: ConnectionStatus.disconnected,
        message: 'Not tested',
      );
    }
  }

  Future<bool> _validateServerCredentials(MCPServerConfig config) async {
    // TODO: Implement actual credential validation
    // For now, simulate based on whether auth is configured
    if (config.env?.isNotEmpty == true) {
      // Check if required environment variables are present
      return config.env!.values.every((value) => 
        value.isNotEmpty && !value.startsWith('\${')
      );
    }
    return true; // No auth required
  }
}

// ==================== Data Models ====================

/// MCP Server configuration
class MCPServerConfig {
  final String id;
  final String name;
  final String command;
  final List<String> args;
  final Map<String, String>? env;
  final String description;
  final bool enabled;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final String? transport; // 'stdio' or 'sse'
  final String? url; // For SSE transport

  const MCPServerConfig({
    required this.id,
    required this.name,
    required this.command,
    required this.args,
    this.env,
    required this.description,
    this.enabled = true,
    required this.createdAt,
    this.lastUpdated,
    this.transport,
    this.url,
  });

  factory MCPServerConfig.fromJson(Map<String, dynamic> json) {
    return MCPServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      command: json['command'] as String,
      args: List<String>.from(json['args'] as List),
      env: json['env'] != null ? Map<String, String>.from(json['env']) : null,
      description: json['description'] as String,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: json['lastUpdated'] != null 
        ? DateTime.parse(json['lastUpdated'] as String) 
        : null,
      transport: json['transport'] as String?,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'args': args,
      if (env != null) 'env': env,
      'description': description,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
      if (transport != null) 'transport': transport,
      if (url != null) 'url': url,
    };
  }

  MCPServerConfig copyWith({
    String? id,
    String? name,
    String? command,
    List<String>? args,
    Map<String, String>? env,
    String? description,
    bool? enabled,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? transport,
    String? url,
  }) {
    return MCPServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      args: args ?? this.args,
      env: env ?? this.env,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      transport: transport ?? this.transport,
      url: url ?? this.url,
    );
  }
}

/// MCP Server runtime status
class MCPServerStatus {
  final String serverId;
  final bool isConnected;
  final DateTime lastChecked;
  final ConnectionStatus status;
  final String? message;
  final Map<String, dynamic>? metadata;
  final int? latencyMs;
  final String? errorMessage;

  const MCPServerStatus({
    required this.serverId,
    required this.isConnected,
    required this.lastChecked,
    required this.status,
    this.message,
    this.metadata,
    this.latencyMs,
    this.errorMessage,
  });
}

/// Connection status enumeration
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
  warning
}

/// Agent deployment configuration
class AgentDeploymentConfig {
  final String agentId;
  final String? apiConfigId;
  final Map<String, Map<String, dynamic>> mcpServerConfigs;
  final List<String> contextDocuments;
  final DateTime timestamp;

  const AgentDeploymentConfig({
    required this.agentId,
    this.apiConfigId,
    required this.mcpServerConfigs,
    required this.contextDocuments,
    required this.timestamp,
  });
}

/// Direct API configuration for services like Anthropic, OpenAI
class DirectAPIConfig {
  final String id;
  final String name;
  final String provider;
  final String model;
  final String apiKey;
  final String baseUrl;
  final bool isDefault;
  final bool enabled;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  const DirectAPIConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.model,
    required this.apiKey,
    required this.baseUrl,
    this.isDefault = false,
    this.enabled = true,
    required this.createdAt,
    this.lastUpdated,
  });

  bool get isConfigured => apiKey.isNotEmpty;

  factory DirectAPIConfig.fromJson(Map<String, dynamic> json) {
    return DirectAPIConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String,
      model: json['model'] as String,
      apiKey: json['apiKey'] as String,
      baseUrl: json['baseUrl'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: json['lastUpdated'] != null 
        ? DateTime.parse(json['lastUpdated'] as String) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'model': model,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'isDefault': isDefault,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }

  DirectAPIConfig copyWith({
    String? id,
    String? name,
    String? provider,
    String? model,
    String? apiKey,
    String? baseUrl,
    bool? isDefault,
    bool? enabled,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return DirectAPIConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      isDefault: isDefault ?? this.isDefault,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ==================== Riverpod Providers ====================

final mcpSettingsServiceProvider = Provider<MCPSettingsService>((ref) {
  final storageService = ref.read(desktopStorageServiceProvider);
  return MCPSettingsService(storageService);
});

/// Provider for MCP server statuses
final mcpServerStatusesProvider = StreamProvider.family<Map<String, MCPServerStatus>, List<String>>((ref, serverIds) async* {
  final service = ref.read(mcpSettingsServiceProvider);
  
  while (true) {
    yield service.getMCPServerStatuses(serverIds);
    await Future.delayed(const Duration(seconds: 5)); // Poll every 5 seconds
  }
});

/// Provider for single MCP server status
final mcpServerStatusProvider = StreamProvider.family<MCPServerStatus?, String>((ref, serverId) async* {
  final service = ref.read(mcpSettingsServiceProvider);
  
  while (true) {
    yield service.getMCPServerStatus(serverId);
    await Future.delayed(const Duration(seconds: 5)); // Poll every 5 seconds
  }
});