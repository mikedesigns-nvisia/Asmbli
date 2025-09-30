import 'package:flutter_test/flutter_test.dart';
import '../../helpers/mock_services.dart';
import '../../helpers/test_data.dart';

void main() {
  group('AgentService', () {
    late MockAgentService service;

    setUp(() {
      service = MockAgentService();
    });

    tearDown(() {
      service.clear();
    });

    test('creates agent successfully', () async {
      final agent = TestData.createAgent(name: 'My Test Agent');

      final created = await service.createAgent(agent);

      expect(created.id, isNotEmpty);
      expect(created.name, 'My Test Agent');
      expect(created.description, 'You are a helpful assistant');
    });

    test('retrieves all agents', () async {
      await service.createAgent(TestData.createAgent(name: 'Agent 1'));
      await service.createAgent(TestData.createAgent(name: 'Agent 2'));
      await service.createAgent(TestData.createAgent(name: 'Agent 3'));

      final agents = await service.listAgents();

      expect(agents.length, 3);
      expect(agents[0].name, 'Agent 1');
      expect(agents[1].name, 'Agent 2');
      expect(agents[2].name, 'Agent 3');
    });

    test('retrieves agent by ID', () async {
      final agent = await service.createAgent(
        TestData.createAgent(name: 'Findable Agent'),
      );

      final found = await service.getAgent(agent.id);

      expect(found.id, agent.id);
      expect(found.name, 'Findable Agent');
    });

    test('throws for non-existent agent', () async {
      expect(
        () => service.getAgent('non-existent-id'),
        throwsA(isA<Exception>()),
      );
    });

    test('updates agent successfully', () async {
      final agent = await service.createAgent(
        TestData.createAgent(name: 'Original Name'),
      );

      final updated = agent.copyWith(name: 'Updated Name');
      await service.updateAgent(updated);

      final retrieved = await service.getAgent(agent.id);
      expect(retrieved.name, 'Updated Name');
    });

    test('deletes agent successfully', () async {
      final agent = await service.createAgent(TestData.createAgent());

      await service.deleteAgent(agent.id);

      final agents = await service.listAgents();
      expect(agents.isEmpty, true);
    });

    test('handles errors gracefully', () async {
      service.setThrowError(true);

      expect(
        () => service.listAgents(),
        throwsA(isA<Exception>()),
      );
    });
  });
}