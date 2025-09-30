import 'package:flutter_test/flutter_test.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../../helpers/test_data.dart';

void main() {
  group('Agent Model', () {
    test('creates agent with required fields', () {
      final agent = TestData.createAgent(
        name: 'Test Agent',
        description: 'You are helpful',
        configuration: {'model': 'claude-3-sonnet'},
      );

      expect(agent.id, isNotEmpty);
      expect(agent.name, 'Test Agent');
      expect(agent.description, 'You are helpful');
      expect(agent.configuration['model'], 'claude-3-sonnet');
    });

    test('copyWith creates new instance with updated fields', () {
      final agent = TestData.createAgent(name: 'Original');

      final updated = agent.copyWith(name: 'Updated');

      expect(agent.name, 'Original'); // Original unchanged
      expect(updated.name, 'Updated'); // New instance updated
      expect(updated.id, agent.id); // Same ID
      expect(updated.description, agent.description); // Other fields unchanged
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final agent = TestData.createAgent(
        name: 'Serializable',
        description: 'Test prompt',
        capabilities: ['github', 'slack'],
        configuration: {
          'temperature': 0.8,
          'maxTokens': 2000,
        },
      );

      final json = agent.toJson();
      final restored = Agent.fromJson(json);

      expect(restored.id, agent.id);
      expect(restored.name, agent.name);
      expect(restored.description, agent.description);
      expect(restored.capabilities, agent.capabilities);
      expect(restored.configuration['temperature'], agent.configuration['temperature']);
      expect(restored.configuration['maxTokens'], agent.configuration['maxTokens']);
    });

    test('handles empty capabilities list', () {
      final agent = TestData.createAgent(capabilities: []);

      expect(agent.capabilities, isEmpty);
    });

    test('creates multiple unique agents', () {
      final agents = TestData.createAgents(3);

      expect(agents.length, 3);
      // All IDs should be unique
      final ids = agents.map((a) => a.id).toSet();
      expect(ids.length, 3);
    });
  });
}