import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/services/agent_service.dart';
import 'package:uuid/uuid.dart';
import 'base_business_service.dart';
import '../mcp_bridge_service.dart';
import '../llm/unified_llm_service.dart';
import '../context_mcp_resource_service.dart';
import '../agent_context_prompt_service.dart';

/// Business service for agent management
/// Encapsulates all business logic related to agents
class AgentBusinessService extends BaseBusinessService {
  final AgentService _agentRepository;
  final MCPBridgeService _mcpService;
  final UnifiedLLMService _modelService;
  final ContextMCPResourceService _contextService;
  final AgentContextPromptService _promptService;
  final BusinessEventBus _eventBus;

  AgentBusinessService({
    required AgentService agentRepository,
    required MCPBridgeService mcpService,
    required UnifiedLLMService modelService,
    required ContextMCPResourceService contextService,
    required AgentContextPromptService promptService,
    BusinessEventBus? eventBus,
  })  : _agentRepository = agentRepository,
        _mcpService = mcpService,
        _modelService = modelService,
        _contextService = contextService,
        _promptService = promptService,
        _eventBus = eventBus ?? BusinessEventBus();

  /// Creates a new agent with full validation and configuration
  Future<BusinessResult<Agent>> createAgent({
    required String name,
    required String description,
    required List<String> capabilities,
    required String modelId,
    List<String> mcpServers = const [],
    List<String> contextDocs = const [],
    Map<String, dynamic> configuration = const {},
  }) async {
    return handleBusinessOperation('createAgent', () async {
      // Validate input parameters
      validateRequired({
        'name': name,
        'description': description,
        'capabilities': capabilities,
        'modelId': modelId,
      });

      // Additional business validation
      final validationResult = await _validateAgentCreation(
        name: name,
        modelId: modelId,
        mcpServers: mcpServers,
      );

      if (!validationResult.isValid) {
        return BusinessResult.failure(validationResult.error!);
      }

      // Create the agent entity
      final agent = Agent(
        id: const Uuid().v4(),
        name: name.trim(),
        description: description.trim(),
        capabilities: capabilities,
        modelId: modelId,
        status: AgentStatus.inactive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {
          'version': '1.0',
          'creator': 'agent_business_service',
          'mcpServers': mcpServers,
          'contextDocuments': contextDocs,
          'configuration': configuration,
        },
      );

      // Generate context-aware system prompt
      final systemPrompt = await _generateSystemPrompt(
        agent: agent,
        contextDocs: contextDocs,
        mcpServers: mcpServers,
      );

      // Update agent with generated prompt
      final agentWithPrompt = agent.copyWith(
        metadata: {
          ...agent.metadata,
          'systemPrompt': systemPrompt,
          'promptGenerated': true,
        },
      );

      // Configure MCP servers for the agent
      await _configureMCPServers(agentWithPrompt, mcpServers);

      // Set up context resources
      await _setupContextResources(agentWithPrompt, contextDocs);

      // Persist the agent
      final createdAgent = await _agentRepository.createAgent(agentWithPrompt);

      // Publish event
      _eventBus.publish(EntityCreatedEvent(createdAgent));

      return BusinessResult.success(createdAgent);
    });
  }

  /// Updates an existing agent
  Future<BusinessResult<Agent>> updateAgent({
    required Agent agent,
    String? name,
    String? description,
    List<String>? capabilities,
    String? modelId,
    List<String>? mcpServers,
    List<String>? contextDocs,
    Map<String, dynamic>? configuration,
  }) async {
    return handleBusinessOperation('updateAgent', () async {
      validateRequired({'agent': agent});

      // Create updated agent
      final updatedAgent = agent.copyWith(
        name: name?.trim(),
        description: description?.trim(),
        capabilities: capabilities,
        modelId: modelId,
        updatedAt: DateTime.now(),
        metadata: configuration != null
            ? {...agent.metadata, 'configuration': configuration}
            : agent.metadata,
      );

      // Validate the update
      final validationResult = await _validateAgentUpdate(updatedAgent);
      if (!validationResult.isValid) {
        return BusinessResult.failure(validationResult.error!);
      }

      // Update MCP configuration if changed
      if (mcpServers != null) {
        await _configureMCPServers(updatedAgent, mcpServers);
      }

      // Update context resources if changed
      if (contextDocs != null) {
        await _setupContextResources(updatedAgent, contextDocs);
      }

      // Regenerate system prompt if significant changes
      if (_requiresPromptRegeneration(agent, updatedAgent)) {
        final newPrompt = await _generateSystemPrompt(
          agent: updatedAgent,
          contextDocs: contextDocs ?? _getContextDocsFromMetadata(agent),
          mcpServers: mcpServers ?? _getMCPServersFromMetadata(agent),
        );

        final agentWithNewPrompt = updatedAgent.copyWith(
          metadata: {
            ...updatedAgent.metadata,
            'systemPrompt': newPrompt,
            'promptRegenerated': DateTime.now().toIso8601String(),
          },
        );

        final result = await _agentRepository.updateAgent(agentWithNewPrompt);
        _eventBus.publish(EntityUpdatedEvent(result));
        return BusinessResult.success(result);
      } else {
        final result = await _agentRepository.updateAgent(updatedAgent);
        _eventBus.publish(EntityUpdatedEvent(result));
        return BusinessResult.success(result);
      }
    });
  }

  /// Activates an agent and ensures all dependencies are ready
  Future<BusinessResult<Agent>> activateAgent(String agentId) async {
    return handleBusinessOperation('activateAgent', () async {
      validateRequired({'agentId': agentId});

      final agent = await _agentRepository.getAgent(agentId);
      if (agent == null) {
        return BusinessResult.failure('Agent not found: $agentId');
      }

      // Validate agent can be activated
      final validationResult = await _validateAgentActivation(agent);
      if (!validationResult.isValid) {
        return BusinessResult.failure(validationResult.error!);
      }

      // Ensure model is ready
      await _ensureModelReady(agent.modelId);

      // Ensure MCP servers are running
      final mcpServers = _getMCPServersFromMetadata(agent);
      await _ensureMCPServersReady(mcpServers);

      // Activate the agent
      final activatedAgent = agent.copyWith(
        status: AgentStatus.active,
        updatedAt: DateTime.now(),
        metadata: {
          ...agent.metadata,
          'activatedAt': DateTime.now().toIso8601String(),
        },
      );

      final result = await _agentRepository.updateAgent(activatedAgent);
      _eventBus.publish(EntityUpdatedEvent(result));

      return BusinessResult.success(result);
    });
  }

  /// Deactivates an agent and cleans up resources
  Future<BusinessResult<Agent>> deactivateAgent(String agentId) async {
    return handleBusinessOperation('deactivateAgent', () async {
      validateRequired({'agentId': agentId});

      final agent = await _agentRepository.getAgent(agentId);
      if (agent == null) {
        return BusinessResult.failure('Agent not found: $agentId');
      }

      // Clean up agent resources
      await _cleanupAgentResources(agent);

      // Deactivate the agent
      final deactivatedAgent = agent.copyWith(
        status: AgentStatus.inactive,
        updatedAt: DateTime.now(),
        metadata: {
          ...agent.metadata,
          'deactivatedAt': DateTime.now().toIso8601String(),
        },
      );

      final result = await _agentRepository.updateAgent(deactivatedAgent);
      _eventBus.publish(EntityUpdatedEvent(result));

      return BusinessResult.success(result);
    });
  }

  /// Deletes an agent and all associated resources
  Future<BusinessResult<void>> deleteAgent(String agentId) async {
    return handleBusinessOperation('deleteAgent', () async {
      validateRequired({'agentId': agentId});

      final agent = await _agentRepository.getAgent(agentId);
      if (agent == null) {
        return BusinessResult.failure('Agent not found: $agentId');
      }

      // Validate agent can be deleted
      final validationResult = await _validateAgentDeletion(agent);
      if (!validationResult.isValid) {
        return BusinessResult.failure(validationResult.error!);
      }

      // Clean up all agent resources
      await _cleanupAgentResources(agent);

      // Delete the agent
      await _agentRepository.deleteAgent(agentId);

      // Publish event
      _eventBus.publish(EntityDeletedEvent<Agent>(agentId));

      return BusinessResult.success(null);
    });
  }

  /// Gets all agents with optional filtering
  Future<BusinessResult<List<Agent>>> getAgents({
    AgentStatus? status,
    String? modelId,
    List<String>? capabilities,
  }) async {
    return handleBusinessOperation('getAgents', () async {
      final allAgents = await _agentRepository.listAgents();

      // Apply filters
      var filteredAgents = allAgents;

      if (status != null) {
        filteredAgents = filteredAgents.where((a) => a.status == status).toList();
      }

      if (modelId != null) {
        filteredAgents = filteredAgents.where((a) => a.modelId == modelId).toList();
      }

      if (capabilities != null && capabilities.isNotEmpty) {
        filteredAgents = filteredAgents
            .where((a) => capabilities.every((cap) => a.capabilities.contains(cap)))
            .toList();
      }

      return BusinessResult.success(filteredAgents);
    });
  }

  /// Gets a specific agent by ID with full details
  Future<BusinessResult<Agent>> getAgentDetails(String agentId) async {
    return handleBusinessOperation('getAgentDetails', () async {
      validateRequired({'agentId': agentId});

      final agent = await _agentRepository.getAgent(agentId);
      if (agent == null) {
        return BusinessResult.failure('Agent not found: $agentId');
      }

      return BusinessResult.success(agent);
    });
  }

  // Private helper methods

  Future<ValidationResult> _validateAgentCreation({
    required String name,
    required String modelId,
    required List<String> mcpServers,
  }) async {
    // Check if agent name is unique
    final existingAgents = await _agentRepository.listAgents();
    if (existingAgents.any((a) => a.name.toLowerCase() == name.toLowerCase())) {
      return ValidationResult(
        isValid: false,
        error: 'Agent name "$name" already exists',
      );
    }

    // Validate model exists and is configured
    if (!await _modelService.isModelAvailable(modelId)) {
      return ValidationResult(
        isValid: false,
        error: 'Model "$modelId" is not available',
      );
    }

    // Validate MCP servers exist
    for (final serverId in mcpServers) {
      if (!await _mcpService.isServerConfigured(serverId)) {
        return ValidationResult(
          isValid: false,
          error: 'MCP server "$serverId" is not configured',
        );
      }
    }

    return ValidationResult(isValid: true);
  }

  Future<ValidationResult> _validateAgentUpdate(Agent agent) async {
    // Basic validation - agent exists
    if (agent.id.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Agent ID cannot be empty',
      );
    }

    return ValidationResult(isValid: true);
  }

  Future<ValidationResult> _validateAgentActivation(Agent agent) async {
    if (agent.status == AgentStatus.active) {
      return ValidationResult(
        isValid: false,
        error: 'Agent is already active',
      );
    }

    return ValidationResult(isValid: true);
  }

  Future<ValidationResult> _validateAgentDeletion(Agent agent) async {
    if (agent.status == AgentStatus.active) {
      return ValidationResult(
        isValid: false,
        error: 'Cannot delete active agent. Deactivate first.',
      );
    }

    return ValidationResult(isValid: true);
  }

  Future<String> _generateSystemPrompt({
    required Agent agent,
    required List<String> contextDocs,
    required List<String> mcpServers,
  }) async {
    return await _promptService.createContextAwarePrompt(
      agentName: agent.name,
      agentDescription: agent.description,
      personality: 'Professional',
      expertise: agent.capabilities.join(', '),
      capabilities: agent.capabilities,
      mcpServers: mcpServers,
      contextDocs: contextDocs,
    );
  }

  Future<void> _configureMCPServers(Agent agent, List<String> mcpServers) async {
    for (final serverId in mcpServers) {
      await _mcpService.configureServerForAgent(agent.id, serverId);
    }
  }

  Future<void> _setupContextResources(Agent agent, List<String> contextDocs) async {
    await _contextService.assignContextToAgent(agent.id, contextDocs);
  }

  Future<void> _ensureModelReady(String modelId) async {
    await _modelService.initializeModel(modelId);
  }

  Future<void> _ensureMCPServersReady(List<String> mcpServers) async {
    for (final serverId in mcpServers) {
      await _mcpService.startServer(serverId);
    }
  }

  Future<void> _cleanupAgentResources(Agent agent) async {
    final mcpServers = _getMCPServersFromMetadata(agent);
    for (final serverId in mcpServers) {
      await _mcpService.stopServerForAgent(agent.id, serverId);
    }

    await _contextService.unassignContextFromAgent(agent.id);
  }

  bool _requiresPromptRegeneration(Agent oldAgent, Agent newAgent) {
    return oldAgent.name != newAgent.name ||
           oldAgent.description != newAgent.description ||
           !_listEquals(oldAgent.capabilities, newAgent.capabilities);
  }

  List<String> _getMCPServersFromMetadata(Agent agent) {
    final mcpServers = agent.metadata['mcpServers'];
    if (mcpServers is List) {
      return List<String>.from(mcpServers);
    }
    return [];
  }

  List<String> _getContextDocsFromMetadata(Agent agent) {
    final contextDocs = agent.metadata['contextDocuments'];
    if (contextDocs is List) {
      return List<String>.from(contextDocs);
    }
    return [];
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult({
    required this.isValid,
    this.error,
  });
}