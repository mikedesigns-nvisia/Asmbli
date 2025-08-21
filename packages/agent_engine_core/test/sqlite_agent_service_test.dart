import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/services/agent_service.dart';
import 'package:agent_engine_core/services/implementations/service_provider.dart';
import 'package:agent_engine_core/services/implementations/sqlite/sqlite_agent_service.dart';
import 'package:test/test.dart';

void main() {
  late AgentService agentService;

  setUp(() async {
    ServiceProvider.configure(useInMemory: false);
    await ServiceProvider.initialize();
    agentService = ServiceProvider.getAgentService();
    await (agentService as SqliteAgentService).deleteAll();
  });

  tearDown(() async {
    await ServiceProvider.reset();
  });

  test('persists agents across service instances', () async {
    final agent = Agent(
      id: '1',
      name: 'Test Agent',
      description: 'A test agent',
      capabilities: ['test'],
    );

    await agentService.createAgent(agent);

    // Create a new service instance
    await ServiceProvider.reset();
    ServiceProvider.configure(useInMemory: false);
    final newAgentService = ServiceProvider.getAgentService();
    await ServiceProvider.initialize();

    final retrieved = await newAgentService.getAgent('1');
    expect(retrieved, equals(agent));
  });

  test('handles concurrent operations', () async {
    final futures = List.generate(10, (index) {
      return agentService.createAgent(Agent(
        id: 'agent_$index',
        name: 'Agent $index',
        description: 'Test agent $index',
        capabilities: ['test'],
      ));
    });

    await Future.wait(futures);

    final agents = await agentService.listAgents();
    expect(agents.length, equals(10));
  });
}
