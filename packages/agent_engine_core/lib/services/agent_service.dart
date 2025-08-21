import '../models/agent.dart';

abstract class AgentService {
  Future<Agent> createAgent(Agent agent);
  Future<Agent> getAgent(String id);
  Future<List<Agent>> listAgents();
  Future<Agent> updateAgent(Agent agent);
  Future<void> deleteAgent(String id);
  Future<void> setAgentStatus(String id, AgentStatus status);
}
