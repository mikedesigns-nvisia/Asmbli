import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/services/agent_service.dart';
import '../models/mcp_catalog_entry.dart';
import '../models/agent_mcp_server_config.dart';
import 'mcp_installation_service.dart';
import 'agent_mcp_configuration_service.dart';
import 'desktop/desktop_agent_service.dart';
import 'production_logger.dart';
import '../di/service_locator.dart';

/// Provider for the agent-aware MCP installer
final agentAwareMCPInstallerProvider = Provider<AgentAwareMCPInstaller>((ref) {
  final mcpInstallationService = ref.read(mcpInstallationServiceProvider);
  final agentMCPConfigService = ref.read(agentMCPConfigurationServiceProvider);
  final agentService = ref.read(agentServiceProvider);

  return AgentAwareMCPInstaller(
    mcpInstallationService,
    agentMCPConfigService,
    agentService,
  );
});

/// Result of an agent-aware MCP installation
class AgentMCPInstallationResult {
  final bool success;
  final String message;
  final List<String> affectedAgentIds;
  final String? errorDetails;
  final MCPCatalogEntry? installedServer;

  const AgentMCPInstallationResult({
    required this.success,
    required this.message,
    this.affectedAgentIds = const [],
    this.errorDetails,
    this.installedServer,
  });

  factory AgentMCPInstallationResult.success({
    required String message,
    required List<String> affectedAgentIds,
    MCPCatalogEntry? installedServer,
  }) {
    return AgentMCPInstallationResult(
      success: true,
      message: message,
      affectedAgentIds: affectedAgentIds,
      installedServer: installedServer,
    );
  }

  factory AgentMCPInstallationResult.failure({
    required String message,
    String? errorDetails,
  }) {
    return AgentMCPInstallationResult(
      success: false,
      message: message,
      errorDetails: errorDetails,
    );
  }
}

/// Configuration for agent-specific MCP installation
class AgentMCPInstallationConfig {
  final List<String> selectedAgentIds;
  final Map<String, String> environmentVariables;
  final bool autoStart;
  final int priority;
  final List<String> requiredCapabilities;

  const AgentMCPInstallationConfig({
    required this.selectedAgentIds,
    this.environmentVariables = const {},
    this.autoStart = true,
    this.priority = 0,
    this.requiredCapabilities = const [],
  });
}

/// Service for installing MCP servers and linking them to specific agents
class AgentAwareMCPInstaller {
  final MCPInstallationService _installationService;
  final AgentMCPConfigurationService _configurationService;
  final DesktopAgentService _agentService;

  // Stream controllers for real-time progress updates
  final Map<String, StreamController<String>> _progressStreams = {};

  AgentAwareMCPInstaller(
    this._installationService,
    this._configurationService,
    this._agentService,
  );

  /// Install MCP server and configure it for selected agents
  Future<AgentMCPInstallationResult> installForAgents(
    MCPCatalogEntry catalogEntry,
    AgentMCPInstallationConfig config,
  ) async {
    final installationId = '${catalogEntry.id}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      ProductionLogger.instance.info(
        'Starting agent-aware MCP installation',
        data: {
          'server_id': catalogEntry.id,
          'server_name': catalogEntry.name,
          'target_agents': config.selectedAgentIds,
          'installation_id': installationId,
        },
        category: 'agent_mcp_installation',
      );

      // Step 1: Validate agents exist
      await _validateAgents(config.selectedAgentIds);
      _emitProgress(installationId, 'Validating target agents...');

      // Step 2: Install the MCP server globally
      _emitProgress(installationId, 'Installing MCP server: ${catalogEntry.name}...');
      final installResult = await _installationService.installServer(
        catalogEntry.id,
        catalogEntry,
        environment: config.environmentVariables,
      );

      if (!installResult.success) {
        throw Exception('MCP server installation failed: ${installResult.error}');
      }

      _emitProgress(installationId, 'MCP server installed successfully');

      // Step 3: Configure each selected agent
      final configuredAgents = <String>[];
      for (final agentId in config.selectedAgentIds) {
        try {
          _emitProgress(installationId, 'Configuring agent: $agentId...');

          await _configurationService.enableGitHubMCPToolForAgent(
            agentId,
            catalogEntry.id,
            environmentVars: config.environmentVariables,
            requiredCapabilities: config.requiredCapabilities,
            priority: config.priority,
            autoStart: config.autoStart,
          );

          configuredAgents.add(agentId);
          _emitProgress(installationId, 'Agent $agentId configured successfully');

        } catch (e) {
          ProductionLogger.instance.warning(
            'Failed to configure agent for MCP server',
            data: {
              'agent_id': agentId,
              'server_id': catalogEntry.id,
              'error': e.toString(),
            },
            category: 'agent_mcp_installation',
          );
          // Continue with other agents even if one fails
        }
      }

      // Step 4: Restart configured agents to load new MCP servers
      if (configuredAgents.isNotEmpty && config.autoStart) {
        _emitProgress(installationId, 'Restarting agents to load MCP server...');
        await _restartAgentsForMCPReload(configuredAgents);
      }

      _emitProgress(installationId, 'Installation completed successfully!');

      ProductionLogger.instance.info(
        'Agent-aware MCP installation completed',
        data: {
          'server_id': catalogEntry.id,
          'configured_agents': configuredAgents.length,
          'installation_id': installationId,
        },
        category: 'agent_mcp_installation',
      );

      return AgentMCPInstallationResult.success(
        message: 'Successfully installed ${catalogEntry.name} for ${configuredAgents.length} agent(s)',
        affectedAgentIds: configuredAgents,
        installedServer: catalogEntry,
      );

    } catch (e, stackTrace) {
      ProductionLogger.instance.error(
        'Agent-aware MCP installation failed',
        data: {
          'server_id': catalogEntry.id,
          'error': e.toString(),
          'installation_id': installationId,
        },
        category: 'agent_mcp_installation',
        stackTrace: stackTrace,
      );

      _emitProgress(installationId, 'Installation failed: $e');

      return AgentMCPInstallationResult.failure(
        message: 'Failed to install ${catalogEntry.name}',
        errorDetails: e.toString(),
      );
    } finally {
      _closeProgressStream(installationId);
    }
  }

  /// Get a stream of installation progress updates
  Stream<String> getInstallationProgress(String installationId) {
    if (!_progressStreams.containsKey(installationId)) {
      _progressStreams[installationId] = StreamController<String>.broadcast();
    }
    return _progressStreams[installationId]!.stream;
  }

  /// Get list of available agents for installation target selection
  Future<List<Agent>> getAvailableAgents() async {
    try {
      return await _agentService.listAgents();
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to get available agents',
        data: {'error': e.toString()},
        category: 'agent_mcp_installation',
      );
      return [];
    }
  }

  /// Check if an MCP server is already installed for a specific agent
  Future<bool> isMCPServerInstalledForAgent(String agentId, String serverId) async {
    try {
      final agentConfigs = await _configurationService.getAgentMCPConfigs(agentId);
      return agentConfigs.any((config) => config.serverId == serverId);
    } catch (e) {
      return false;
    }
  }

  /// Get suggested environment variables for an MCP server
  Map<String, String> getSuggestedEnvironmentVars(MCPCatalogEntry catalogEntry) {
    final suggestions = <String, String>{};

    // Add required environment variables with placeholder values
    for (final envVar in catalogEntry.requiredEnvVars.keys) {
      suggestions[envVar] = catalogEntry.requiredEnvVars[envVar] ?? '';
    }

    // Add common environment variables based on server type
    if (catalogEntry.name.toLowerCase().contains('github')) {
      suggestions['GITHUB_PERSONAL_ACCESS_TOKEN'] = '';
    }
    if (catalogEntry.name.toLowerCase().contains('slack')) {
      suggestions['SLACK_BOT_TOKEN'] = '';
    }
    if (catalogEntry.name.toLowerCase().contains('notion')) {
      suggestions['NOTION_API_TOKEN'] = '';
    }

    return suggestions;
  }

  /// Validate that all specified agents exist
  Future<void> _validateAgents(List<String> agentIds) async {
    final agents = await _agentService.listAgents();
    final existingAgentIds = agents.map((a) => a.id).toSet();

    for (final agentId in agentIds) {
      if (!existingAgentIds.contains(agentId)) {
        throw Exception('Agent not found: $agentId');
      }
    }
  }

  /// Restart agents to reload their MCP server configurations
  Future<void> _restartAgentsForMCPReload(List<String> agentIds) async {
    for (final agentId in agentIds) {
      try {
        // Get the agent
        final agent = await _agentService.getAgent(agentId);

        // Update agent status to trigger MCP server reload
        // This will cause it to reload its MCP server configurations
        await _agentService.setAgentStatus(agentId, AgentStatus.idle);
        await Future.delayed(const Duration(milliseconds: 500));
        await _agentService.setAgentStatus(agentId, AgentStatus.active);

      } catch (e) {
        ProductionLogger.instance.warning(
          'Failed to restart agent for MCP reload',
          data: {
            'agent_id': agentId,
            'error': e.toString(),
          },
          category: 'agent_mcp_installation',
        );
      }
    }
  }

  /// Emit progress update for installation
  void _emitProgress(String installationId, String message) {
    if (_progressStreams.containsKey(installationId)) {
      _progressStreams[installationId]!.add(message);
    }
  }

  /// Close progress stream when installation completes
  void _closeProgressStream(String installationId) {
    if (_progressStreams.containsKey(installationId)) {
      _progressStreams[installationId]!.close();
      _progressStreams.remove(installationId);
    }
  }

  /// Clean up resources
  void dispose() {
    for (final controller in _progressStreams.values) {
      controller.close();
    }
    _progressStreams.clear();
  }
}

/// Provider dependencies using ServiceLocator
final mcpInstallationServiceProvider = Provider<MCPInstallationService>((ref) {
  return ServiceLocator.instance.get<MCPInstallationService>();
});

final agentMCPConfigurationServiceProvider = Provider<AgentMCPConfigurationService>((ref) {
  return ServiceLocator.instance.get<AgentMCPConfigurationService>();
});

final agentServiceProvider = Provider<DesktopAgentService>((ref) {
  return ServiceLocator.instance.get<AgentService>() as DesktopAgentService;
});