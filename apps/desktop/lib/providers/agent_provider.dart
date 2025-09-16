import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/services/agent_service.dart';
import '../core/services/desktop/desktop_agent_service.dart';
import '../core/services/mcp_installation_service.dart';
import '../core/services/context_mcp_resource_service.dart';
import '../core/services/mcp_conversation_bridge_service.dart';
import '../core/services/business/agent_business_service.dart';
import '../core/di/service_locator.dart';

/// Provider for the agent service (legacy support)
final agentServiceProvider = Provider<AgentService>((ref) {
  return DesktopAgentService();
});

/// Provider for the agent business service (contains business logic)
final agentBusinessServiceProvider = Provider<AgentBusinessService>((ref) {
  return ServiceLocator.instance.get<AgentBusinessService>();
});

/// Provider for the list of all agents
final agentsProvider = FutureProvider<List<Agent>>((ref) async {
  final agentService = ref.watch(agentServiceProvider);
  return await agentService.listAgents();
});

/// Provider for the currently active/selected agent
final activeAgentProvider = StateProvider<Agent?>((ref) => null);

/// Provider for a specific agent by ID
final agentProvider = FutureProvider.family<Agent, String>((ref, id) async {
  final agentService = ref.watch(agentServiceProvider);
  return await agentService.getAgent(id);
});

// Sample agents provider removed - using real agent data only

/// Notifier class for managing agent operations
class AgentNotifier extends StateNotifier<AsyncValue<List<Agent>>> {
  final AgentBusinessService _agentBusinessService;
  final Ref _ref;

  AgentNotifier(this._agentBusinessService, this._ref) : super(const AsyncValue.loading()) {
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      // Load all agents using business service
      final result = await _agentBusinessService.getAgents();
      
      if (result.isSuccess) {
        final agents = result.data!;
        state = AsyncValue.data(agents);
        
        // Set first agent as active if none selected
        if (agents.isNotEmpty && _ref.read(activeAgentProvider) == null) {
          _ref.read(activeAgentProvider.notifier).state = agents.first;
        }
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createAgent(Agent agent) async {
    try {
      // Use business service for agent creation with full validation
      final result = await _agentBusinessService.createAgent(
        name: agent.name,
        description: agent.description,
        capabilities: [], // capabilities: agent.capabilities, // Not available in base Agent class
        modelId: '', // modelId: agent.modelId, // Not available in base Agent class
        mcpServers: _getMCPServersFromMetadata(agent),
        contextDocs: _getContextDocsFromMetadata(agent),
        configuration: {}, // agent.metadata not available in base Agent class
      );
      
      if (result.isSuccess) {
        await _loadAgents();
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateAgent(Agent agent) async {
    try {
      // Use business service for agent updates with validation
      final result = await _agentBusinessService.updateAgent(
        agent: agent,
        name: agent.name,
        description: agent.description,
        capabilities: [], // capabilities: agent.capabilities, // Not available in base Agent class
        modelId: '', // modelId: agent.modelId, // Not available in base Agent class
        mcpServers: _getMCPServersFromMetadata(agent),
        contextDocs: _getContextDocsFromMetadata(agent),
        configuration: {}, // agent.metadata not available in base Agent class
      );
      
      if (result.isSuccess) {
        await _loadAgents();
        
        // Update active agent if it was the one being updated
        final activeAgent = _ref.read(activeAgentProvider);
        if (activeAgent?.id == agent.id) {
          _ref.read(activeAgentProvider.notifier).state = result.data!;
        }
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAgent(String id) async {
    try {
      // Use business service for safe deletion
      final result = await _agentBusinessService.deleteAgent(id);
      
      if (result.isSuccess) {
        await _loadAgents();
        
        // Clear active agent if it was deleted
        final activeAgent = _ref.read(activeAgentProvider);
        if (activeAgent?.id == id) {
          final agents = state.value ?? [];
          _ref.read(activeAgentProvider.notifier).state = 
              agents.isNotEmpty ? agents.first : null;
        }
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setAgentStatus(String id, AgentStatus status) async {
    try {
      // Use business service for status changes with proper validation
      if (status == AgentStatus.active) {
        final result = await _agentBusinessService.activateAgent(id);
        if (!result.isSuccess) {
          state = AsyncValue.error(result.error!, StackTrace.current);
          return;
        }
      }
      // } else if (status == AgentStatus.inactive) { // AgentStatus.inactive not available
        // final result = await _agentBusinessService.deactivateAgent(id);
        // if (!result.isSuccess) {
        //   state = AsyncValue.error(result.error!, StackTrace.current);
        //   return;
        // }
      // }
      
      await _loadAgents();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Helper methods to extract metadata
  List<String> _getMCPServersFromMetadata(Agent agent) {
    // agent.metadata not available in base Agent class
    final mcpServers = null; // agent.metadata?['mcpServers'];
    if (mcpServers is List) {
      return List<String>.from(mcpServers);
    }
    return [];
  }

  List<String> _getContextDocsFromMetadata(Agent agent) {
    // agent.metadata not available in base Agent class
    final contextDocs = null; // agent.metadata?['contextDocuments'];
    if (contextDocs is List) {
      return List<String>.from(contextDocs);
    }
    return [];
  }

  void setActiveAgent(Agent? agent) {
    _ref.read(activeAgentProvider.notifier).state = agent;
  }

  /// Load agent for conversation with MCP installation check and context resources
  Future<void> loadAgentForConversation(Agent agent, String conversationId) async {
    try {
      // Get MCP installation service
      final mcpInstallationService = _ref.read(mcpInstallationServiceProvider);

      // Check if MCP servers need installation
      final shouldInstall = mcpInstallationService.shouldInstallMCPOnAgentLoad(agent.id);

      if (shouldInstall) {
        // Get installation requirements
        final requirements = await mcpInstallationService.checkAgentMCPRequirements(agent.id);

        if (requirements.isNotEmpty) {
          // Install required MCP servers
          await mcpInstallationService.installMCPServers(agent.id, requirements);
        }

        // Mark agent as used in this conversation
        mcpInstallationService.markAgentUsedInConversation(agent.id);
      }
      
      // Setup context resources for the agent
      await _setupContextResourcesForAgent(agent);
      
      // Initialize MCP servers for the conversation
      await _initializeMCPForConversation(agent, conversationId);
      
      // Set as active agent
      setActiveAgent(agent);
      
    } catch (error) {
      // Don't fail agent loading due to MCP installation issues
      print('MCP installation check failed for agent ${agent.id}: $error');
      setActiveAgent(agent);
    }
  }

  /// Initialize MCP servers for conversation
  Future<void> _initializeMCPForConversation(Agent agent, String conversationId) async {
    try {
      final mcpBridge = _ref.read(mcpConversationBridgeServiceProvider);
      
      // Get environment variables for MCP servers (from settings or default)
      final environmentVars = await _getAgentEnvironmentVars(agent);
      
      // Initialize MCP session for the conversation
      final session = await mcpBridge.initializeConversationMCP(
        conversationId,
        agent,
        environmentVars,
      );
      
      print('✅ MCP session initialized for agent ${agent.id} in conversation $conversationId');
      print('   - ${session.serverProcesses.length} servers started');
      print('   - Server IDs: ${session.serverIds.join(', ')}');
      
      // Setup health monitoring
      _monitorMCPSession(session);
      
    } catch (e) {
      print('⚠️ Failed to initialize MCP for conversation: $e');
      // Don't block agent loading for MCP issues
    }
  }

  /// Get environment variables for agent MCP servers
  Future<Map<String, String>> _getAgentEnvironmentVars(Agent agent) async {
    final environmentVars = <String, String>{};
    
    // Get basic system environment variables
    // TODO: Add secure storage for sensitive API keys/tokens
    environmentVars.addAll({
      'USER': Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'user',
      'HOME': Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '',
      'PATH': Platform.environment['PATH'] ?? '',
    });
    
    return environmentVars;
  }

  /// Monitor MCP session health
  void _monitorMCPSession(MCPConversationSession session) {
    // Listen to server messages for debugging
    session.messageStream.listen(
      (message) {
        print('📢 MCP Message from ${message.serverId}: ${message.message}');
      },
      onError: (error) {
        print('❌ MCP Message stream error: $error');
      },
    );
    
    // Setup periodic health checks
    Timer.periodic(const Duration(minutes: 1), (timer) {
      final status = _ref.read(mcpConversationBridgeServiceProvider)
          .getSessionStatus(session.conversationId);
      
      if (!status.isActive) {
        print('⚠️ MCP session ${session.conversationId} is no longer active');
        timer.cancel();
      } else if (status.healthyServerCount < status.serverCount) {
        print('⚠️ MCP session ${session.conversationId}: ${status.healthyServerCount}/${status.serverCount} servers healthy');
      }
    });
  }

  /// Setup context resources as MCP resources for the agent
  Future<void> _setupContextResourcesForAgent(Agent agent) async {
    try {
      // Check if agent has context assigned
      final hasContextResources = await ContextMCPResourceService.shouldEnableContextResources(agent.id, _ref);
      
      if (hasContextResources) {
        // Get context resources for the agent
        final contextResources = await ContextMCPResourceService.getAgentContextResources(agent.id, _ref);
        
        print('Setting up ${contextResources.length} context resources for agent ${agent.id}');
        
        // Update agent configuration to include context resource server
        final updatedConfig = Map<String, dynamic>.from(agent.configuration);
        
        // Add context resource server to MCP servers list
        final mcpServers = List<dynamic>.from(updatedConfig['mcpServers'] ?? []);
        
        // Add context resource server reference
        final contextServerRef = {
          'id': 'context-resources-${agent.id}',
          'type': 'resources',
          'resourceCount': contextResources.length,
        };
        
        if (!mcpServers.any((server) => server is Map && server['id'] == contextServerRef['id'])) {
          mcpServers.add(contextServerRef);
          updatedConfig['mcpServers'] = mcpServers;
        }
        
        // Update the agent with new configuration
        final updatedAgent = Agent(
          id: agent.id,
          name: agent.name,
          description: agent.description,
          capabilities: agent.capabilities,
          configuration: updatedConfig,
          status: agent.status,
        );
        
        // Update in service
        // await _agentService.updateAgent(updatedAgent); // Use business service instead
        final updateResult = await _agentBusinessService.updateAgent(
          agent: updatedAgent,
          name: updatedAgent.name,
          description: updatedAgent.description,
          capabilities: [],
          modelId: '',
          configuration: updatedConfig ?? {},
        );
        if (!updateResult.isSuccess) {
          print('Failed to update agent: ${updateResult.error}');
        }
      }
    } catch (e) {
      print('Failed to setup context resources for agent ${agent.id}: $e');
    }
  }
}

/// Provider for the agent notifier
final agentNotifierProvider = StateNotifierProvider<AgentNotifier, AsyncValue<List<Agent>>>((ref) {
  final agentBusinessService = ref.watch(agentBusinessServiceProvider);
  return AgentNotifier(agentBusinessService, ref);
});