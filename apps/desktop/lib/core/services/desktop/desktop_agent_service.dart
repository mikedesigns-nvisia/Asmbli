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
}