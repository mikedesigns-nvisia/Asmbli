import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'desktop/desktop_storage_service.dart';
import 'desktop/desktop_service_provider.dart';

/// Global MCP (Model Context Protocol) settings service
/// Manages server configurations, API assignments, and runtime status
class MCPSettingsService {
  final DesktopStorageService _storageService;
  
  // Global MCP server configurations
  final Map<String, MCPServerConfig> _globalMCPConfigs = {};
  
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
    await _loadAgentApiMappings();
    await _loadGlobalContext();
    await _initializeServerStatuses();
  }

  /// Save all settings to storage
  Future<void> saveSettings() async {
    await _saveMCPConfigs();
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
      if (data != null) {
        final Map<String, dynamic> configs = Map<String, dynamic>.from(data);
        _globalMCPConfigs.clear();
        configs.forEach((key, value) {
          _globalMCPConfigs[key] = MCPServerConfig.fromJson(value);
        });
      }
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
      if (data != null) {
        _agentApiMappings.clear();
        _agentApiMappings.addAll(Map<String, String>.from(data));
      }
    } catch (e) {
      // Handle loading error, use defaults
    }
  }

  Future<void> _saveAgentApiMappings() async {
    await _storageService.setHiveData('settings', 'agent_api_mappings', _agentApiMappings);
  }

  Future<void> _loadGlobalContext() async {
    try {
      final contextData = _storageService.getHiveData('settings', 'global_context_documents');
      final data = contextData;
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

  const MCPServerStatus({
    required this.serverId,
    required this.isConnected,
    required this.lastChecked,
    required this.status,
    this.message,
    this.metadata,
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