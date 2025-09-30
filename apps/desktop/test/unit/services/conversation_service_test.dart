import 'package:flutter_test/flutter_test.dart';
import '../../helpers/mock_services.dart';
import '../../helpers/test_data.dart';

void main() {
  group('ConversationService', () {
    late MockConversationService service;

    setUp(() {
      service = MockConversationService();
    });

    tearDown(() {
      service.clear();
    });

    test('creates conversation successfully', () async {
      final conversation = TestData.createConversation(
        title: 'My Conversation',
      );

      final created = await service.createConversation(conversation);

      expect(created.id, isNotEmpty);
      expect(created.title, 'My Conversation');
    });

    test('retrieves all conversations', () async {
      final conv1 = await service.createConversation(
        TestData.createConversation(title: 'Conv 1'),
      );
      final conv2 = await service.createConversation(
        TestData.createConversation(title: 'Conv 2'),
      );

      final conversations = await service.listConversations();

      expect(conversations.length, 2);
      expect(conversations.map((c) => c.id), contains(conv1.id));
      expect(conversations.map((c) => c.id), contains(conv2.id));
    });

    test('adds message to conversation', () async {
      final conversation = await service.createConversation(
        TestData.createConversation(),
      );
      final message = TestData.createMessage(
        content: 'Hello!',
      );

      await service.addMessage(conversation.id, message);

      final messages = await service.getMessages(conversation.id);
      expect(messages.length, 1);
      expect(messages[0].content, 'Hello!');
    });

    test('retrieves conversation by ID', () async {
      final conversation = await service.createConversation(
        TestData.createConversation(title: 'Findable'),
      );

      final found = await service.getConversation(conversation.id);

      expect(found.title, 'Findable');
    });

    test('deletes conversation and messages', () async {
      final conversation = await service.createConversation(
        TestData.createConversation(),
      );
      await service.addMessage(
        conversation.id,
        TestData.createMessage(),
      );

      await service.deleteConversation(conversation.id);

      final conversations = await service.listConversations();
      final messages = await service.getMessages(conversation.id);
      expect(conversations.isEmpty, true);
      expect(messages.isEmpty, true);
    });
  });
}