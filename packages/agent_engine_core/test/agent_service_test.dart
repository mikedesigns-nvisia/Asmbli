import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/services/agent_service.dart';
import 'package:agent_engine_core/services/implementations/service_provider.dart';
import 'package:test/test.dart';

void main() {
  late AgentService agentService;

  setUp(() {
    ServiceProvider.reset();
    agentService = ServiceProvider.getAgentService();
  });

  test('creates and retrieves an agent', () async {
    final agent = Agent(
      id: '1',
      name: 'Test Agent',
      description: 'A test agent',
      capabilities: ['test'],
    );

    final created = await agentService.createAgent(agent);
    expect(created, equals(agent));

    final retrieved = await agentService.getAgent('1');
    expect(retrieved, equals(agent));
  });

  test('lists all agents', () async {
    final agents = [
      Agent(
        id: '1',
        name: 'Agent 1',
        description: 'First agent',
        capabilities: ['test'],
      ),
      Agent(
        id: '2',
        name: 'Agent 2',
        description: 'Second agent',
        capabilities: ['test'],
      ),
    ];

    for (final agent in agents) {
      await agentService.createAgent(agent);
    }

    final list = await agentService.listAgents();
    expect(list, hasLength(2));
    expect(list, containsAll(agents));
  });

  test('updates agent status', () async {
    final agent = Agent(
      id: '1',
      name: 'Test Agent',
      description: 'A test agent',
      capabilities: ['test'],
    );

    await agentService.createAgent(agent);
    await agentService.setAgentStatus('1', AgentStatus.active);

    final updated = await agentService.getAgent('1');
    expect(updated.status, equals(AgentStatus.active));
  });

  test('deletes an agent', () async {
    final agent = Agent(
      id: '1',
      name: 'Test Agent',
      description: 'A test agent',
      capabilities: ['test'],
    );

    await agentService.createAgent(agent);
    await agentService.deleteAgent('1');

    expect(
      () => agentService.getAgent('1'),
      throwsException,
    );
  });
}
