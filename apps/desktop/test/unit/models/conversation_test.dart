import 'package:flutter_test/flutter_test.dart';
import 'package:agent_engine_core/models/conversation.dart';
import '../../helpers/test_data.dart';

void main() {
  group('Conversation Model', () {
    test('creates conversation with required fields', () {
      final conversation = TestData.createConversation(
        title: 'My Chat',
      );

      expect(conversation.id, isNotEmpty);
      expect(conversation.title, 'My Chat');
      expect(conversation.status, ConversationStatus.active);
    });

    test('copyWith creates new instance with updated fields', () {
      final conversation = TestData.createConversation(title: 'Original');

      final updated = conversation.copyWith(title: 'Updated');

      expect(conversation.title, 'Original');
      expect(updated.title, 'Updated');
      expect(updated.id, conversation.id);
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final conversation = TestData.createConversation(
        title: 'Serializable',
        status: ConversationStatus.archived,
      );

      final json = conversation.toJson();
      final restored = Conversation.fromJson(json);

      expect(restored.id, conversation.id);
      expect(restored.title, conversation.title);
      expect(restored.status, conversation.status);
    });

    test('handles empty messages list', () {
      final conversation = TestData.createConversation(messages: []);

      expect(conversation.messages, isEmpty);
    });

    test('supports different conversation statuses', () {
      final active = TestData.createConversation(
        status: ConversationStatus.active,
      );
      final archived = TestData.createConversation(
        status: ConversationStatus.archived,
      );

      expect(active.status, ConversationStatus.active);
      expect(archived.status, ConversationStatus.archived);
    });
  });
}