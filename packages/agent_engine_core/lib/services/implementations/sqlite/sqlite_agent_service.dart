import '../../../models/agent.dart';
import '../../agent_service.dart';
import 'concrete_sqlite_repository.dart';
import 'sqlite_repository.dart';

class SqliteAgentService implements AgentService {
  late final SqliteRepository<Agent> _repository;

  SqliteAgentService() {
    _repository = ConcreteSqliteRepository<Agent>(
      'agents',
      (agent) => agent.id,
      (json) => Agent.fromJson(json),
      (agent) => agent.toJson(),
    );
  }

  Future<void> initialize() async {
    await _repository.initialize();
  }

  @override
  Future<Agent> createAgent(Agent agent) => _repository.create(agent);

  @override
  Future<Agent> getAgent(String id) async {
    final agent = await _repository.read(id);
    if (agent == null) {
      throw Exception('Agent not found');
    }
    return agent;
  }

  @override
  Future<List<Agent>> listAgents() => _repository.readAll();

  @override
  Future<Agent> updateAgent(Agent agent) => _repository.update(agent);

  @override
  Future<void> deleteAgent(String id) => _repository.delete(id);

  @override
  Future<void> setAgentStatus(String id, AgentStatus status) async {
    final agent = await getAgent(id);
    final updatedAgent = agent.copyWith(status: status);
    await updateAgent(updatedAgent);
  }

  Future<void> close() => _repository.close();

  Future<void> deleteAll() => _repository.deleteAll();
}
