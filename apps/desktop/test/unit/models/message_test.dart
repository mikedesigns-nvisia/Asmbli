import 'package:flutter_test/flutter_test.dart';
import 'package:agent_engine_core/models/conversation.dart';
import '../../helpers/test_data.dart';

void main() {
  group('Message Model', () {
    test('creates user message', () {
      final message = TestData.createMessage(
        content: 'Hello, AI!',
        role: MessageRole.user,
      );

      expect(message.id, isNotEmpty);
      expect(message.content, 'Hello, AI!');
      expect(message.role, MessageRole.user);
      expect(message.timestamp, isNotNull);
    });

    test('creates assistant message', () {
      final message = TestData.createMessage(
        content: 'Hello, human!',
        role: MessageRole.assistant,
      );

      expect(message.role, MessageRole.assistant);
      expect(message.content, 'Hello, human!');
    });

    test('copyWith creates new instance with updated fields', () {
      final message = TestData.createMessage(content: 'Original');

      final updated = message.copyWith(content: 'Updated');

      expect(message.content, 'Original');
      expect(updated.content, 'Updated');
      expect(updated.id, message.id);
      expect(updated.role, message.role);
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final message = TestData.createMessage(
        content: 'Serializable message',
        role: MessageRole.user,
        metadata: {'key': 'value'},
      );

      final json = message.toJson();
      final restored = Message.fromJson(json);

      expect(restored.id, message.id);
      expect(restored.content, message.content);
      expect(restored.role, message.role);
      expect(restored.metadata, message.metadata);
    });

    test('supports metadata', () {
      final message = TestData.createMessage(
        metadata: {
          'toolCalls': ['github', 'slack'],
          'confidence': 0.95,
        },
      );

      expect(message.metadata, isNotNull);
      expect(message.metadata!['toolCalls'], isA<List>());
      expect(message.metadata!['confidence'], 0.95);
    });

    test('creates batch of alternating user/assistant messages', () {
      final messages = TestData.createMessages(4);

      expect(messages.length, 4);
      expect(messages[0].role, MessageRole.user);
      expect(messages[1].role, MessageRole.assistant);
      expect(messages[2].role, MessageRole.user);
      expect(messages[3].role, MessageRole.assistant);
    });
  });
}