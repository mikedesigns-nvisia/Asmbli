import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/services/agent_service.dart';
import 'package:agent_engine_core/services/repository.dart';
import 'desktop_repository.dart';
import 'desktop_storage_service.dart';

/// Persistent agent service that stores data using DesktopStorageService
class DesktopAgentService implements AgentService {
  final Repository<Agent> _repository;
  final DesktopStorageService _storage;

  DesktopAgentService()
      : _storage = DesktopStorageService.instance,
        _repository = DesktopRepository<Agent>(
          boxName: 'agents',
          getId: (agent) => agent.id,
          fromJson: Agent.fromJson,
          toJson: (agent) => agent.toJson(),
        );

  @override
  Future<Agent> createAgent(Agent agent) async {
    try {
      return await _repository.create(agent);
    } catch (e) {
      print('⚠️ Failed to create agent: $e');
      rethrow;
    }
  }

  @override
  Future<Agent> getAgent(String id) async {
    try {
      final agent = await _repository.read(id);
      if (agent == null) {
        throw Exception('Agent not found');
      }
      return agent;
    } catch (e) {
      print('⚠️ Failed to get agent $id: $e');
      rethrow;
    }
  }

  @override
  Future<List<Agent>> listAgents() async {
    try {
      return await _repository.readAll();
    } catch (e) {
      print('⚠️ Failed to list agents: $e');
      return []; // Return empty list on error
    }
  }

  @override
  Future<Agent> updateAgent(Agent agent) async {
    try {
      return await _repository.update(agent);
    } catch (e) {
      print('⚠️ Failed to update agent: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAgent(String id) async {
    try {
      await _repository.delete(id);
    } catch (e) {
      print('⚠️ Failed to delete agent $id: $e');
      rethrow;
    }
  }

  @override
  Future<void> setAgentStatus(String id, AgentStatus status) async {
    try {
      final agent = await getAgent(id);
      final updatedAgent = agent.copyWith(status: status);
      await updateAgent(updatedAgent);
    } catch (e) {
      print('⚠️ Failed to set agent status: $e');
      rethrow;
    }
  }

  /// Get count of agents
  Future<int> getAgentCount() async {
    try {
      final agents = await listAgents();
      return agents.length;
    } catch (e) {
      print('⚠️ Failed to get agent count: $e');
      return 0;
    }
  }

  /// Check if agent exists
  Future<bool> agentExists(String id) async {
    try {
      final agent = await _repository.read(id);
      return agent != null;
    } catch (e) {
      return false;
    }
  }

  /// Get agents by status
  Future<List<Agent>> getAgentsByStatus(AgentStatus status) async {
    try {
      final allAgents = await listAgents();
      return allAgents.where((agent) => agent.status == status).toList();
    } catch (e) {
      print('⚠️ Failed to get agents by status: $e');
      return [];
    }
  }

  /// Seed default agents if they don't exist
  /// Called during app initialization to ensure core agents are available
  Future<void> seedDefaultAgents() async {
    try {
      // Check if Design Agent already exists
      const designAgentId = 'design-agent-default';
      final exists = await agentExists(designAgentId);

      if (!exists) {
        final designAgent = Agent(
          id: designAgentId,
          name: 'Design Agent',
          description: 'Visual design assistant with interactive canvas, Material Design components, and prototyping capabilities',
          capabilities: [
            'material-design',
            'ui-ux',
            'canvas',
            'prototyping',
            'components',
            'wireframes',
          ],
          configuration: {
            'modelId': 'llava:13b',
            'modelName': 'LLaVA 13B',
            'modelProvider': 'ollama',
            'selectedTools': ['figma', 'github', 'canvas-mcp', 'filesystem', 'memory'],
            'enableReasoningFlows': true,
            'reasoningFlow': 'iterative',
            'taskOutline': [
              'Analyze design requirements and user needs',
              'Create wireframes and mockups on interactive canvas',
              'Apply Material Design 3 principles and guidelines',
              'Generate responsive component structures',
              'Iterate based on feedback and design principles',
              'Export design assets and component code',
            ],
            'category': 'Design',
            'isDefaultAgent': true,
          },
          status: AgentStatus.active,
        );

        await createAgent(designAgent);
        print('✅ Seeded default Design Agent');
      }
    } catch (e) {
      print('⚠️ Failed to seed default agents: $e');
    }
  }
}