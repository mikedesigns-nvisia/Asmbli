import 'dart:async';
import '../models/mcp_server.dart';
import '../../../core/services/mcp_settings_service.dart';
import '../../../core/services/mcp_server_execution_service.dart';
import '../../../core/models/mcp_server_config.dart';
import '../../../core/models/mcp_server_process.dart';
import '../../../core/data/mcp_server_configs.dart';
import '../../../core/di/service_locator.dart';
import 'package:agent_engine_core/services/agent_service.dart';

class ToolsService {
  static final ToolsService _instance = ToolsService._internal();
  factory ToolsService() => _instance;
  ToolsService._internal();

  // Real service instances
  late final MCPSettingsService _settingsService;
  late final MCPServerExecutionService _executionService;
  late final AgentService _agentService;

  final StreamController<List<MCPServer>> _serversController = 
      StreamController<List<MCPServer>>.broadcast();
  final StreamController<List<AgentConnection>> _connectionsController =
      StreamController<List<AgentConnection>>.broadcast();

  Stream<List<MCPServer>> get serversStream => _serversController.stream;
  Stream<List<AgentConnection>> get connectionsStream => _connectionsController.stream;

  List<MCPServer> _installedServers = [];
  List<AgentConnection> _agentConnections = [];

  Future<void> initialize() async {
    // Initialize real services - USE SINGLETONS FROM SERVICE LOCATOR
    _settingsService = ServiceLocator.instance.get<MCPSettingsService>();
    _executionService = ServiceLocator.instance.get<MCPServerExecutionService>();
    _agentService = ServiceLocator.instance.get<AgentService>();
    
    // Load installed servers from real settings service
    await _loadInstalledServers();
    
    // Load REAL agent connections from agent service
    await _loadAgentConnections();
    
    _serversController.add(_installedServers);
    _connectionsController.add(_agentConnections);
  }
  
  Future<void> _loadInstalledServers() async {
    final configs = _settingsService.getAllMCPServers();
    final runningProcesses = _executionService.getRunningServers();
    
    // Create a map of running processes by ID for quick lookup
    final processMap = <String, MCPServerProcess>{};
    for (final process in runningProcesses) {
      processMap[process.id] = process;
    }
    
    _installedServers = configs.map((config) {
      final process = processMap[config.id];
      return MCPServer(
        id: config.id,
        name: config.name,
        description: config.description ?? 'MCP Server',
        command: config.command,
        args: config.args,
        isRunning: process?.isHealthy ?? false,
        autoStart: config.enabled,
        category: _getCategoryFromConfig(config),
        isOfficial: _isOfficialServer(config.id),
        capabilities: config.capabilities,
        lastStarted: process?.startTime,
        installedAt: config.createdAt,
      );
    }).toList();
  }
  
  Future<void> _loadAgentConnections() async {
    try {
      // Load REAL agents from agent service
      final agents = await _agentService.listAgents();
      
      _agentConnections = agents.map((agent) {
        // Get MCP servers configured for this agent
        final agentMcpServers = agent.configuration['mcpServers'] as List<dynamic>? ?? [];
        final connectedServerIds = agentMcpServers
            .map((server) => server is String ? server : server['id'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toList();
            
        // Get the actual last updated timestamp from agent configuration
        final lastUpdatedString = agent.configuration['mcpServersLastUpdated'] as String?;
        final lastUpdated = lastUpdatedString != null 
            ? DateTime.tryParse(lastUpdatedString) ?? DateTime(2025, 1, 1) // Default to start of year
            : DateTime(2025, 1, 1); // Default for agents never configured
            
        return AgentConnection(
          agentId: agent.id,
          agentName: agent.name,
          connectedServerIds: connectedServerIds,
          lastUpdated: lastUpdated,
        );
      }).toList();
      
    } catch (e) {
      print('Error loading agent connections: $e');
      // If agent service fails, show empty list (don't show fake data)
      _agentConnections = [];
    }
  }
  
  String _getCategoryFromConfig(MCPServerConfig config) {
    if (config.type == 'official') return 'official';
    return 'custom';
  }
  
  bool _isOfficialServer(String serverId) {
    const officialServers = [
      'filesystem', 'github', 'sqlite', 'web-search',
      'brave-search', 'google-maps', 'slack'
    ];
    return officialServers.contains(serverId);
  }

  List<MCPServer> get availableServers => _getAvailableServers();
  List<MCPServer> get installedServers => _installedServers;
  List<AgentConnection> get agentConnections => _agentConnections;
  
  List<MCPServer> _getAvailableServers() {
    // Get available servers from the real MCP server library
    final allServers = MCPServerLibrary.servers;
    final installedIds = _installedServers.map((s) => s.id).toSet();
    
    return allServers
        .where((config) => !installedIds.contains(config.id))
        .map((config) => MCPServer(
          id: config.id,
          name: config.name,
          description: config.description,
          command: config.configuration['command'] as String,
          args: List<String>.from(config.configuration['args'] as List),
          isRunning: false,
          autoStart: false,
          category: config.type == MCPServerType.official ? 'official' : 'community',
          isOfficial: config.type == MCPServerType.official,
          capabilities: config.capabilities,
        ))
        .toList();
  }

  Future<void> installServer(String serverId) async {
    try {
      // Get server config from library
      final libraryConfig = MCPServerLibrary.getServer(serverId);
      if (libraryConfig == null) {
        throw Exception('Server $serverId not found in library');
      }
      
      // Convert library config to MCPServerConfig
      final serverConfig = MCPServerConfig(
        id: libraryConfig.id,
        name: libraryConfig.name,
        description: libraryConfig.description,
        command: libraryConfig.configuration['command'] as String,
        args: List<String>.from(libraryConfig.configuration['args'] as List),
        enabled: true,
        url: '', // Required but may be empty for stdio servers
        protocol: 'stdio',
        autoReconnect: false,
        enablePolling: false,
        capabilities: libraryConfig.capabilities,
        requiredAuth: [],
        requiredEnvVars: Map<String, String>.fromEntries(
          libraryConfig.requiredEnvVars.map((key) => MapEntry(key, ''))
        ),
        optionalEnvVars: Map<String, String>.fromEntries(
          libraryConfig.optionalEnvVars.map((key) => MapEntry(key, ''))
        ),
        setupInstructions: libraryConfig.setupInstructions,
      );
      
      // Install server using real installation service (if needed)
      try {
        await _executionService.ensureMCPServerInstalled(serverConfig);
      } catch (e) {
        // Installation might fail if dependencies aren't available, that's ok
        print('Installation check failed (this may be normal): $e');
      }
      
      // Add to settings service
      await _settingsService.setMCPServer(serverId, serverConfig);
      
      // Reload installed servers
      await _loadInstalledServers();
      _serversController.add(_installedServers);
      
    } catch (e) {
      print('Error installing server $serverId: $e');
      rethrow;
    }
  }

  Future<void> uninstallServer(String serverId) async {
    try {
      // Stop server if running
      await stopServer(serverId);
      
      // Remove from settings service
      await _settingsService.removeMCPServer(serverId);
      
      // Reload installed servers
      await _loadInstalledServers();
      await _loadAgentConnections();
      
      _serversController.add(_installedServers);
      _connectionsController.add(_agentConnections);
      
    } catch (e) {
      print('Error uninstalling server $serverId: $e');
      rethrow;
    }
  }

  Future<void> startServer(String serverId) async {
    try {
      // Get server config
      final serverConfig = _settingsService.getMCPServer(serverId);
      if (serverConfig == null) {
        throw Exception('Server $serverId not found in settings');
      }
      
      // Start server using real execution service
      final process = await _executionService.startMCPServer(
        serverConfig,
        {}, // environment vars
      );
      
      print('Started MCP server $serverId with PID ${process.process?.pid}');
      
      // Reload installed servers to update running status
      await _loadInstalledServers();
      _serversController.add(_installedServers);
      
    } catch (e) {
      print('Error starting server $serverId: $e');
      rethrow;
    }
  }

  Future<void> stopServer(String serverId) async {
    try {
      // Stop server using real execution service
      await _executionService.stopMCPServer(serverId);
      
      print('Stopped MCP server $serverId');
      
      // Reload installed servers to update running status
      await _loadInstalledServers();
      _serversController.add(_installedServers);
      
    } catch (e) {
      print('Error stopping server $serverId: $e');
      rethrow;
    }
  }

  Future<void> updateServerConfig(MCPServer server) async {
    try {
      // Convert MCPServer back to MCPServerConfig
      final config = MCPServerConfig(
        id: server.id,
        name: server.name,
        description: server.description,
        command: server.command,
        args: server.args,
        enabled: server.autoStart,
        url: '', // Required but may be empty for stdio servers
        protocol: 'stdio',
        autoReconnect: false,
        enablePolling: false,
        capabilities: server.capabilities,
        requiredAuth: [],
      );
      
      // Update in settings service  
      await _settingsService.setMCPServer(server.id, config);
      
      // Reload installed servers
      await _loadInstalledServers();
      _serversController.add(_installedServers);
      
    } catch (e) {
      print('Error updating server config ${server.id}: $e');
      rethrow;
    }
  }

  Future<void> addCustomServer(MCPServer server) async {
    try {
      // Convert MCPServer to MCPServerConfig
      final config = MCPServerConfig(
        id: server.id,
        name: server.name,
        description: server.description,
        command: server.command,
        args: server.args,
        enabled: server.autoStart,
        url: '', // Required but may be empty for stdio servers
        protocol: 'stdio',
        autoReconnect: false,
        enablePolling: false,
        capabilities: server.capabilities,
        requiredAuth: [],
        type: 'custom', // Mark as custom server
      );
      
      // Add to settings service
      await _settingsService.setMCPServer(server.id, config);
      
      // Auto-connect this server to all available agents (as requested by user)
      try {
        final agents = await _agentService.listAgents();
        for (final agent in agents) {
          final agentMcpServers = List<String>.from(
            agent.configuration['mcpServers'] as List<dynamic>? ?? []
          );
          
          // Add this server if not already connected
          if (!agentMcpServers.contains(server.id)) {
            agentMcpServers.add(server.id);
            await updateAgentConnections(agent.id, agentMcpServers);
          }
        }
        print('Auto-connected MCP server "${server.name}" to ${agents.length} agents');
      } catch (e) {
        print('Warning: Failed to auto-connect server to agents: $e');
        // Don't fail the entire operation if auto-connection fails
      }
      
      // Reload installed servers and agent connections
      await _loadInstalledServers();
      await _loadAgentConnections();
      _serversController.add(_installedServers);
      _connectionsController.add(_agentConnections);
      
    } catch (e) {
      print('Error adding custom server ${server.id}: $e');
      rethrow;
    }
  }

  Future<void> updateAgentConnections(String agentId, List<String> serverIds) async {
    try {
      // Get the real agent from agent service
      final agent = await _agentService.getAgent(agentId);
      
      // Update the agent's MCP server configuration
      final updatedConfiguration = Map<String, dynamic>.from(agent.configuration);
      updatedConfiguration['mcpServers'] = serverIds;
      updatedConfiguration['mcpServersLastUpdated'] = DateTime.now().toIso8601String();
      
      final updatedAgent = agent.copyWith(configuration: updatedConfiguration);
      
      // Save the updated agent back to agent service
      await _agentService.updateAgent(updatedAgent);
      
      // Reload agent connections to reflect the change
      await _loadAgentConnections();
      _connectionsController.add(_agentConnections);
      
    } catch (e) {
      print('Error updating agent connections for $agentId: $e');
      rethrow;
    }
  }

  void dispose() {
    _serversController.close();
    _connectionsController.close();
  }
}