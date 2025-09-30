import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_terminal.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_catalog_entry.dart';
import 'agent_terminal_manager.dart';
import 'mcp_installation_service.dart';
import 'mcp_process_manager.dart';
import 'mcp_catalog_service.dart';
import 'production_logger.dart';

/// Service that integrates agents with MCP servers through terminals
@Deprecated('Will be consolidated into AgentMCPService. See docs/SERVICE_CONSOLIDATION_PLAN.md')
class AgentMCPIntegrationService {
  final AgentTerminalManager _terminalManager;
  final MCPInstallationService _installationService;
  final MCPProcessManager _processManager;
  final MCPCatalogService _catalogService;

  AgentMCPIntegrationService(
    this._terminalManager,
    this._installationService,
    this._processManager,
    this._catalogService,
  );

  /// Create agent with terminal and install default MCP tools
  Future<AgentTerminal> createAgentWithTerminal(
    String agentId, {
    String? workingDirectory,
    List<String>? defaultMCPServers,
  }) async {
    try {
      ProductionLogger.instance.info(
        'Creating agent with terminal and MCP integration',
        data: {
          'agent_id': agentId,
          'working_directory': workingDirectory,
          'default_servers': defaultMCPServers,
        },
        category: 'agent_integration',
      );

      // Create default security context
      final securityContext = _createDefaultSecurityContext(agentId);
      
      // Create terminal configuration
      final terminalConfig = AgentTerminalConfig(
        agentId: agentId,
        workingDirectory: workingDirectory ?? _getDefaultWorkingDirectory(),
        securityContext: securityContext,
        resourceLimits: const ResourceLimits(),
      );

      // Create terminal
      final terminal = await _terminalManager.createTerminal(agentId, terminalConfig);

      // Install default MCP servers
      if (defaultMCPServers != null && defaultMCPServers.isNotEmpty) {
        await _installDefaultMCPServers(agentId, defaultMCPServers);
      } else {
        // Install basic filesystem and git servers by default
        await _installDefaultMCPServers(agentId, ['filesystem', 'git']);
      }

      ProductionLogger.instance.info(
        'Agent with terminal created successfully',
        data: {'agent_id': agentId},
        category: 'agent_integration',
      );

      return terminal;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to create agent with terminal',
        error: e,
        data: {'agent_id': agentId},
        category: 'agent_integration',
      );
      rethrow;
    }
  }

  /// Install MCP server for agent
  Future<void> installMCPServerForAgent(String agentId, String serverId) async {
    try {
      ProductionLogger.instance.info(
        'Installing MCP server for agent',
        data: {'agent_id': agentId, 'server_id': serverId},
        category: 'mcp_integration',
      );

      // Get catalog entry
      final catalogEntry = await _catalogService.getCatalogEntry(serverId);
      if (catalogEntry == null) {
        throw MCPIntegrationException('MCP server not found in catalog: $serverId');
      }

      // Install the server
      final installResult = await _installationService.installServer(serverId, catalogEntry);
      
      if (!installResult.success) {
        throw MCPIntegrationException('Installation failed: ${installResult.error}');
      }

      // Start the server process
      final serverProcess = await _processManager.startServer(
        serverId: serverId,
        agentId: agentId,
        credentials: _getServerCredentials(catalogEntry),
      );

      // Add server to agent's terminal
      final terminal = _terminalManager.getTerminal(agentId);
      if (terminal != null) {
        await terminal.addMCPServer(serverProcess);
      }

      ProductionLogger.instance.info(
        'MCP server installed and started successfully',
        data: {
          'agent_id': agentId,
          'server_id': serverId,
          'process_id': serverProcess.id,
        },
        category: 'mcp_integration',
      );
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to install MCP server for agent',
        error: e,
        data: {'agent_id': agentId, 'server_id': serverId},
        category: 'mcp_integration',
      );
      rethrow;
    }
  }

  /// Remove MCP server from agent
  Future<void> removeMCPServerFromAgent(String agentId, String serverId) async {
    try {
      ProductionLogger.instance.info(
        'Removing MCP server from agent',
        data: {'agent_id': agentId, 'server_id': serverId},
        category: 'mcp_integration',
      );

      // Stop the server process
      final processId = '$agentId:$serverId';
      await _processManager.stopServer(processId);

      // Remove from agent's terminal
      final terminal = _terminalManager.getTerminal(agentId);
      if (terminal != null) {
        await terminal.removeMCPServer(serverId);
      }

      ProductionLogger.instance.info(
        'MCP server removed successfully',
        data: {'agent_id': agentId, 'server_id': serverId},
        category: 'mcp_integration',
      );
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to remove MCP server from agent',
        error: e,
        data: {'agent_id': agentId, 'server_id': serverId},
        category: 'mcp_integration',
      );
      rethrow;
    }
  }

  /// Get agent's MCP servers
  List<MCPServerProcess> getAgentMCPServers(String agentId) {
    final terminal = _terminalManager.getTerminal(agentId);
    return terminal?.mcpServers ?? [];
  }

  /// Execute command in agent's terminal
  Future<CommandResult> executeAgentCommand(String agentId, String command) async {
    return await _terminalManager.executeCommand(agentId, command);
  }

  /// Stream agent terminal output
  Stream<TerminalOutput> streamAgentOutput(String agentId) {
    return _terminalManager.streamOutput(agentId);
  }

  /// Destroy agent and cleanup all resources
  Future<void> destroyAgent(String agentId) async {
    try {
      ProductionLogger.instance.info(
        'Destroying agent and cleaning up resources',
        data: {'agent_id': agentId},
        category: 'agent_integration',
      );

      // Stop all MCP servers for this agent
      await _processManager.stopAllServersForAgent(agentId);

      // Destroy terminal
      await _terminalManager.destroyTerminal(agentId);

      ProductionLogger.instance.info(
        'Agent destroyed successfully',
        data: {'agent_id': agentId},
        category: 'agent_integration',
      );
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to destroy agent',
        error: e,
        data: {'agent_id': agentId},
        category: 'agent_integration',
      );
      rethrow;
    }
  }

  /// Install default MCP servers for agent
  Future<void> _installDefaultMCPServers(String agentId, List<String> serverIds) async {
    for (final serverId in serverIds) {
      try {
        await installMCPServerForAgent(agentId, serverId);
      } catch (e) {
        ProductionLogger.instance.info(
          'Failed to install default MCP server',
          data: {'agent_id': agentId, 'server_id': serverId, 'error': e.toString()},
          category: 'mcp_integration',
        );
        // Continue with other servers even if one fails
      }
    }
  }

  /// Create default security context for agent
  SecurityContext _createDefaultSecurityContext(String agentId) {
    return SecurityContext(
      agentId: agentId,
      resourceLimits: const ResourceLimits(
        maxMemoryMB: 512,
        maxCpuPercent: 50,
        maxProcesses: 10,
      ),
      terminalPermissions: const TerminalPermissions(
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
        ],
        requiresApprovalForAPIcalls: false,
      ),
      apiPermissions: {
        'anthropic': const APIPermission(
          provider: 'anthropic',
          allowedModels: ['claude-3-5-sonnet-20241022'],
          maxRequestsPerMinute: 60,
          maxTokensPerRequest: 4000,
          canMakeDirectCalls: true,
        ),
        'local': const APIPermission(
          provider: 'local',
          allowedModels: ['gemma3:4b'],
          maxRequestsPerMinute: 120,
          maxTokensPerRequest: 8000,
          canMakeDirectCalls: true,
        ),
      },
    );
  }

  /// Get default working directory for agent
  String _getDefaultWorkingDirectory() {
    // Create agent-specific directory
    final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
    return '$userHome/AgentEngine/agents';
  }

  /// Get server credentials from catalog entry
  Map<String, String> _getServerCredentials(MCPCatalogEntry catalogEntry) {
    final credentials = <String, String>{};
    
    // Add required authentication credentials
    for (final authReq in catalogEntry.requiredAuth) {
      // In a real implementation, these would come from secure storage
      // For now, we'll use environment variables
      final authName = authReq['name'] as String? ?? authReq['displayName'] as String?;
      if (authName != null) {
        final envValue = Platform.environment[authName];
        if (envValue != null) {
          credentials[authName] = envValue;
        }
      }
    }
    
    return credentials;
  }
}

/// Exception for MCP integration errors
class MCPIntegrationException implements Exception {
  final String message;
  MCPIntegrationException(this.message);

  @override
  String toString() => 'MCPIntegrationException: $message';
}

// ==================== Riverpod Provider ====================

final agentMCPIntegrationServiceProvider = Provider<AgentMCPIntegrationService>((ref) {
  final terminalManager = ref.read(agentTerminalManagerProvider);
  final installationService = ref.read(mcpInstallationServiceProvider);
  final processManager = ref.read(mcpProcessManagerProvider);
  final catalogService = ref.read(mcpCatalogServiceProvider);
  
  return AgentMCPIntegrationService(
    terminalManager,
    installationService,
    processManager,
    catalogService,
  );
});