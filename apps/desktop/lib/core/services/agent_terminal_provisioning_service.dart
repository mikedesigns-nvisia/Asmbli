import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_terminal.dart';
import '../models/mcp_server_process.dart';
import 'agent_terminal_manager.dart';
import 'context_aware_tool_discovery_service.dart';
import 'production_logger.dart';

/// Service responsible for automatic terminal provisioning when agents are created
class AgentTerminalProvisioningService {
  final AgentTerminalManager _terminalManager;
  final ContextAwareToolDiscoveryService? _toolDiscoveryService;
  final Map<String, AgentTerminalConfig> _agentConfigurations = {};
  final Map<String, DateTime> _lastProvisionAttempt = {};

  AgentTerminalProvisioningService(
    this._terminalManager, [
    this._toolDiscoveryService,
  ]);

  /// Automatically create terminal when agent is created
  Future<AgentTerminal> provisionTerminalForAgent(
    String agentId, {
    String? workingDirectory,
    Map<String, String>? environment,
    List<String>? requiredMCPServers,
    SecurityContext? customSecurityContext,
    ResourceLimits? customResourceLimits,
  }) async {
    try {
      ProductionLogger.instance.info(
        'Provisioning terminal for agent',
        data: {
          'agent_id': agentId,
          'working_directory': workingDirectory,
          'required_mcp_servers': requiredMCPServers,
        },
        category: 'terminal_provisioning',
      );

      // Check if terminal already exists
      final existingTerminal = _terminalManager.getTerminal(agentId);
      if (existingTerminal != null) {
        ProductionLogger.instance.info(
          'Terminal already exists for agent',
          data: {'agent_id': agentId},
          category: 'terminal_provisioning',
        );
        return existingTerminal;
      }

      // Discover recommended tools based on project context
      List<String>? discoveredTools;
      if (_toolDiscoveryService != null && workingDirectory != null) {
        try {
          final recommendations = await _toolDiscoveryService!.getToolRecommendationsForAgent(
            agentId,
            workingDirectory,
          );
          discoveredTools = recommendations.essentialIds;
          
          ProductionLogger.instance.info(
            'Discovered tools for agent based on project context',
            data: {
              'agent_id': agentId,
              'discovered_tools': discoveredTools,
              'project_types': recommendations.context.projectTypes.map((t) => t.name).toList(),
            },
            category: 'terminal_provisioning',
          );
        } catch (e) {
          ProductionLogger.instance.warning(
            'Failed to discover tools for agent, using defaults',
            data: {'agent_id': agentId, 'error': e.toString()},
            category: 'terminal_provisioning',
          );
        }
      }

      // Merge required and discovered tools
      final allRequiredTools = <String>{
        ...?requiredMCPServers,
        ...?discoveredTools,
      }.toList();

      // Create terminal configuration based on agent requirements
      final config = await _createTerminalConfiguration(
        agentId: agentId,
        workingDirectory: workingDirectory,
        environment: environment,
        requiredMCPServers: allRequiredTools,
        customSecurityContext: customSecurityContext,
        customResourceLimits: customResourceLimits,
      );

      // Store configuration for restoration
      _agentConfigurations[agentId] = config;

      // Create the terminal
      final terminal = await _terminalManager.createTerminal(agentId, config);

      // Record successful provisioning
      _lastProvisionAttempt[agentId] = DateTime.now();

      ProductionLogger.instance.info(
        'Terminal provisioned successfully for agent',
        data: {
          'agent_id': agentId,
          'working_directory': terminal.workingDirectory,
          'status': terminal.status.name,
        },
        category: 'terminal_provisioning',
      );

      return terminal;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to provision terminal for agent',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_provisioning',
      );
      
      // Record failed attempt
      _lastProvisionAttempt[agentId] = DateTime.now();
      rethrow;
    }
  }

  /// Configure terminal based on agent requirements
  Future<AgentTerminalConfig> _createTerminalConfiguration({
    required String agentId,
    String? workingDirectory,
    Map<String, String>? environment,
    List<String>? requiredMCPServers,
    SecurityContext? customSecurityContext,
    ResourceLimits? customResourceLimits,
  }) async {
    // Determine working directory
    final agentWorkingDir = workingDirectory ?? await _createAgentWorkingDirectory(agentId);

    // Create base environment
    final agentEnvironment = <String, String>{
      'AGENT_ID': agentId,
      'AGENT_WORKING_DIR': agentWorkingDir,
      'PATH': Platform.environment['PATH'] ?? '',
      ...?environment,
    };

    // Create security context based on agent requirements
    final securityContext = customSecurityContext ?? _createSecurityContextForAgent(
      agentId: agentId,
      requiredMCPServers: requiredMCPServers,
    );

    // Create resource limits
    final resourceLimits = customResourceLimits ?? _createResourceLimitsForAgent(agentId);

    return AgentTerminalConfig(
      agentId: agentId,
      workingDirectory: agentWorkingDir,
      environment: agentEnvironment,
      securityContext: securityContext,
      resourceLimits: resourceLimits,
      persistState: true,
      commandTimeout: const Duration(minutes: 5),
    );
  }

  /// Create agent-specific working directory
  Future<String> _createAgentWorkingDirectory(String agentId) async {
    final baseDir = _getAgentBaseDirectory();
    final agentDir = '$baseDir/$agentId';
    
    final directory = Directory(agentDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      
      // Create standard subdirectories
      await Directory('$agentDir/workspace').create();
      await Directory('$agentDir/temp').create();
      await Directory('$agentDir/logs').create();
      
      ProductionLogger.instance.info(
        'Created agent working directory',
        data: {'agent_id': agentId, 'directory': agentDir},
        category: 'terminal_provisioning',
      );
    }
    
    return agentDir;
  }

  /// Get base directory for all agents
  String _getAgentBaseDirectory() {
    final userHome = Platform.environment['USERPROFILE'] ?? 
                    Platform.environment['HOME'] ?? 
                    '.';
    return '$userHome/Asmbli/agents';
  }

  /// Create security context tailored for agent requirements
  SecurityContext _createSecurityContextForAgent({
    required String agentId,
    List<String>? requiredMCPServers,
  }) {
    // Base terminal permissions
    var terminalPermissions = const TerminalPermissions(
      canExecuteShellCommands: true,
      canInstallPackages: false, // Disabled by default for security
      canModifyEnvironment: true,
      canAccessNetwork: true,
      commandBlacklist: [
        'rm -rf',
        'del /f /s /q',
        'format',
        'fdisk',
        'mkfs',
        'dd if=',
        'sudo rm',
        'sudo del',
      ],
      requiresApprovalForAPIcalls: false,
    );

    // Adjust permissions based on required MCP servers
    if (requiredMCPServers != null && requiredMCPServers.isNotEmpty) {
      // If MCP servers are required, allow package installation for uvx/npx
      terminalPermissions = TerminalPermissions(
        canExecuteShellCommands: terminalPermissions.canExecuteShellCommands,
        canInstallPackages: true, // Enable for MCP server installation
        canModifyEnvironment: terminalPermissions.canModifyEnvironment,
        canAccessNetwork: terminalPermissions.canAccessNetwork,
        commandWhitelist: [
          'uvx',
          'npx',
          'pip install',
          'npm install',
          'git',
          'python',
          'node',
          'ls',
          'dir',
          'cd',
          'pwd',
          'echo',
          'cat',
          'type',
        ],
        commandBlacklist: terminalPermissions.commandBlacklist,
        secureEnvironmentVars: terminalPermissions.secureEnvironmentVars,
        requiresApprovalForAPIcalls: terminalPermissions.requiresApprovalForAPIcalls,
      );
    }

    // Create API permissions
    const apiPermissions = <String, APIPermission>{
      'anthropic': APIPermission(
        provider: 'anthropic',
        allowedModels: ['claude-3-5-sonnet-20241022', 'claude-3-haiku-20240307'],
        maxRequestsPerMinute: 60,
        maxTokensPerRequest: 4000,
        canMakeDirectCalls: true,
      ),
      'openai': APIPermission(
        provider: 'openai',
        allowedModels: ['gpt-4', 'gpt-3.5-turbo'],
        maxRequestsPerMinute: 60,
        maxTokensPerRequest: 4000,
        canMakeDirectCalls: true,
      ),
      'local': APIPermission(
        provider: 'local',
        allowedModels: ['gemma3:4b', 'llama3:8b'],
        maxRequestsPerMinute: 120,
        maxTokensPerRequest: 8000,
        canMakeDirectCalls: true,
      ),
    };

    return SecurityContext(
      agentId: agentId,
      resourceLimits: _createResourceLimitsForAgent(agentId),
      terminalPermissions: terminalPermissions,
      apiPermissions: apiPermissions,
      auditLogging: true,
    );
  }

  /// Create resource limits for agent
  ResourceLimits _createResourceLimitsForAgent(String agentId) {
    return const ResourceLimits(
      maxMemoryMB: 1024, // 1GB for agent operations
      maxCpuPercent: 50,
      maxProcesses: 15, // Allow more processes for MCP servers
      maxExecutionTime: Duration(minutes: 10),
      maxFileSize: 200 * 1024 * 1024, // 200MB
      maxNetworkConnections: 20, // Allow more connections for MCP servers
    );
  }

  /// Restore terminal on application restart
  Future<AgentTerminal> restoreTerminalForAgent(String agentId) async {
    try {
      ProductionLogger.instance.info(
        'Restoring terminal for agent on restart',
        data: {'agent_id': agentId},
        category: 'terminal_provisioning',
      );

      // Check if we have stored configuration
      final storedConfig = _agentConfigurations[agentId];
      if (storedConfig != null) {
        // Use stored configuration
        return await _terminalManager.createTerminal(agentId, storedConfig);
      }

      // Try to restore from persisted state
      final persistedState = await _loadPersistedTerminalState(agentId);
      if (persistedState != null) {
        return await _terminalManager.restoreTerminalState(agentId, persistedState);
      }

      // Fallback: create new terminal with default configuration
      ProductionLogger.instance.info(
        'No stored state found, creating new terminal for agent',
        data: {'agent_id': agentId},
        category: 'terminal_provisioning',
      );

      return await provisionTerminalForAgent(agentId);
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to restore terminal for agent',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_provisioning',
      );
      rethrow;
    }
  }

  /// Load persisted terminal state from disk
  Future<Map<String, dynamic>?> _loadPersistedTerminalState(String agentId) async {
    try {
      final stateFile = File('${_getAgentBaseDirectory()}/$agentId/terminal_state.json');
      if (await stateFile.exists()) {
        final stateJson = await stateFile.readAsString();
        return Map<String, dynamic>.from(
          // In a real implementation, this would use proper JSON parsing
          <String, dynamic>{}
        );
      }
    } catch (e) {
      ProductionLogger.instance.warning(
        'Failed to load persisted terminal state',
        data: {'agent_id': agentId, 'error': e.toString()},
        category: 'terminal_provisioning',
      );
    }
    return null;
  }

  /// Save terminal state to disk for persistence
  Future<void> saveTerminalState(String agentId) async {
    try {
      final terminal = _terminalManager.getTerminal(agentId);
      if (terminal == null) return;

      final state = _terminalManager.getTerminalState(agentId);
      final stateFile = File('${_getAgentBaseDirectory()}/$agentId/terminal_state.json');
      
      // Ensure directory exists
      await stateFile.parent.create(recursive: true);
      
      // In a real implementation, this would serialize the state to JSON
      await stateFile.writeAsString('{}'); // Placeholder
      
      ProductionLogger.instance.info(
        'Terminal state saved',
        data: {'agent_id': agentId},
        category: 'terminal_provisioning',
      );
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to save terminal state',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_provisioning',
      );
    }
  }

  /// Get terminal configuration for agent
  AgentTerminalConfig? getAgentConfiguration(String agentId) {
    return _agentConfigurations[agentId];
  }

  /// Update terminal configuration for agent
  Future<void> updateAgentConfiguration(String agentId, AgentTerminalConfig config) async {
    _agentConfigurations[agentId] = config;
    
    // If terminal exists, apply configuration changes
    final terminal = _terminalManager.getTerminal(agentId);
    if (terminal != null) {
      // In a real implementation, this would update the running terminal
      ProductionLogger.instance.info(
        'Terminal configuration updated',
        data: {'agent_id': agentId},
        category: 'terminal_provisioning',
      );
    }
  }

  /// Remove agent configuration and cleanup
  Future<void> removeAgentConfiguration(String agentId) async {
    _agentConfigurations.remove(agentId);
    _lastProvisionAttempt.remove(agentId);
    
    // Clean up agent directory
    try {
      final agentDir = Directory('${_getAgentBaseDirectory()}/$agentId');
      if (await agentDir.exists()) {
        await agentDir.delete(recursive: true);
        ProductionLogger.instance.info(
          'Agent directory cleaned up',
          data: {'agent_id': agentId},
          category: 'terminal_provisioning',
        );
      }
    } catch (e) {
      ProductionLogger.instance.warning(
        'Failed to clean up agent directory',
        data: {'agent_id': agentId, 'error': e.toString()},
        category: 'terminal_provisioning',
      );
    }
  }

  /// Get provisioning status for agent
  ProvisioningStatus getProvisioningStatus(String agentId) {
    final terminal = _terminalManager.getTerminal(agentId);
    final lastAttempt = _lastProvisionAttempt[agentId];
    final hasConfig = _agentConfigurations.containsKey(agentId);

    if (terminal != null) {
      return ProvisioningStatus(
        agentId: agentId,
        status: ProvisioningState.provisioned,
        terminal: terminal,
        lastAttempt: lastAttempt,
        hasConfiguration: hasConfig,
      );
    } else if (lastAttempt != null) {
      return ProvisioningStatus(
        agentId: agentId,
        status: ProvisioningState.failed,
        lastAttempt: lastAttempt,
        hasConfiguration: hasConfig,
      );
    } else {
      return ProvisioningStatus(
        agentId: agentId,
        status: ProvisioningState.notProvisioned,
        hasConfiguration: hasConfig,
      );
    }
  }

  /// Get all provisioned agents
  List<String> getProvisionedAgents() {
    return _terminalManager.getActiveTerminals().map((t) => t.agentId).toList();
  }

  /// Update tool recommendations for agent when context changes
  Future<ToolRecommendations?> updateToolRecommendations(String agentId) async {
    if (_toolDiscoveryService == null) return null;

    try {
      final terminal = _terminalManager.getTerminal(agentId);
      if (terminal == null) return null;

      ProductionLogger.instance.info(
        'Updating tool recommendations for agent',
        data: {'agent_id': agentId, 'working_directory': terminal.workingDirectory},
        category: 'terminal_provisioning',
      );

      // Get updated recommendations
      final recommendations = await _toolDiscoveryService!.updateRecommendations(
        agentId,
        terminal.workingDirectory,
      );

      // Log the updated recommendations
      ProductionLogger.instance.info(
        'Tool recommendations updated',
        data: {
          'agent_id': agentId,
          'recommended_tools': recommendations.essentialIds,
          'optional_tools': recommendations.optional.map((t) => t.id).toList(),
          'project_types': recommendations.context.projectTypes.map((t) => t.name).toList(),
        },
        category: 'terminal_provisioning',
      );

      return recommendations;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to update tool recommendations for agent',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_provisioning',
      );
      return null;
    }
  }

  /// Get current tool recommendations for agent
  Future<ToolRecommendations?> getToolRecommendations(String agentId) async {
    if (_toolDiscoveryService == null) return null;

    try {
      final terminal = _terminalManager.getTerminal(agentId);
      if (terminal == null) return null;

      return await _toolDiscoveryService!.getToolRecommendationsForAgent(
        agentId,
        terminal.workingDirectory,
      );
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to get tool recommendations for agent',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_provisioning',
      );
      return null;
    }
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    // Save all terminal states before disposing
    final futures = _agentConfigurations.keys.map((agentId) => saveTerminalState(agentId));
    await Future.wait(futures, eagerError: false);
    
    _agentConfigurations.clear();
    _lastProvisionAttempt.clear();
    
    ProductionLogger.instance.info(
      'Agent terminal provisioning service disposed',
      category: 'terminal_provisioning',
    );
  }
}

/// Provisioning status for an agent
class ProvisioningStatus {
  final String agentId;
  final ProvisioningState status;
  final AgentTerminal? terminal;
  final DateTime? lastAttempt;
  final bool hasConfiguration;

  const ProvisioningStatus({
    required this.agentId,
    required this.status,
    this.terminal,
    this.lastAttempt,
    required this.hasConfiguration,
  });
}

/// State of terminal provisioning
enum ProvisioningState {
  notProvisioned,
  provisioning,
  provisioned,
  failed,
  restoring,
}

/// Exception for provisioning errors
class TerminalProvisioningException implements Exception {
  final String message;
  final String agentId;
  
  TerminalProvisioningException(this.message, this.agentId);

  @override
  String toString() => 'TerminalProvisioningException for agent $agentId: $message';
}

// ==================== Riverpod Provider ====================

final agentTerminalProvisioningServiceProvider = Provider<AgentTerminalProvisioningService>((ref) {
  final terminalManager = ref.read(agentTerminalManagerProvider);
  final toolDiscoveryService = ref.read(contextAwareToolDiscoveryServiceProvider);
  return AgentTerminalProvisioningService(terminalManager, toolDiscoveryService);
});