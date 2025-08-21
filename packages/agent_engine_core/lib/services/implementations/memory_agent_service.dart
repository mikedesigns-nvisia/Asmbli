import '../../models/agent.dart';
import '../agent_service.dart';
import '../repository.dart';
import 'memory_repository.dart';

class InMemoryAgentService implements AgentService {
  final Repository<Agent> _repository;

  InMemoryAgentService()
      : _repository = InMemoryRepository<Agent>((agent) => agent.id);

  @override
  Future<Agent> createAgent(Agent agent) async {
    return _repository.create(agent);
  }

  @override
  Future<Agent> getAgent(String id) async {
    final agent = await _repository.read(id);
    if (agent == null) {
      throw Exception('Agent not found');
    }
    return agent;
  }

  @override
  Future<List<Agent>> listAgents() async {
    return _repository.readAll();
  }

  @override
  Future<Agent> updateAgent(Agent agent) async {
    return _repository.update(agent);
  }

  @override
  Future<void> deleteAgent(String id) async {
    await _repository.delete(id);
  }

  @override
  Future<void> setAgentStatus(String id, AgentStatus status) async {
    final agent = await getAgent(id);
    final updatedAgent = agent.copyWith(status: status);
    await updateAgent(updatedAgent);
  }
}
