import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/services/conversation_service.dart';
import 'package:agent_engine_core/services/implementations/service_provider.dart';
import 'package:test/test.dart';

void main() {
  late ConversationService conversationService;

  setUp(() {
    ServiceProvider.reset();
    conversationService = ServiceProvider.getConversationService();
  });

  test('creates and retrieves a conversation', () async {
    final conversation = Conversation(
      id: '1',
      title: 'Test Conversation',
      messages: [],
      createdAt: DateTime.now(),
    );

    final created = await conversationService.createConversation(conversation);
    expect(created, equals(conversation));

    final retrieved = await conversationService.getConversation('1');
    expect(retrieved, equals(conversation));
  });

  test('lists all conversations', () async {
    final conversations = [
      Conversation(
        id: '1',
        title: 'First Conversation',
        messages: [],
        createdAt: DateTime.now(),
      ),
      Conversation(
        id: '2',
        title: 'Second Conversation',
        messages: [],
        createdAt: DateTime.now(),
      ),
    ];

    for (final conversation in conversations) {
      await conversationService.createConversation(conversation);
    }

    final list = await conversationService.listConversations();
    expect(list, hasLength(2));
    expect(list, containsAll(conversations));
  });

  test('adds messages to conversation', () async {
    final conversation = Conversation(
      id: '1',
      title: 'Test Conversation',
      messages: [],
      createdAt: DateTime.now(),
    );

    await conversationService.createConversation(conversation);

    final message = Message(
      id: 'm1',
      content: 'Hello, world!',
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    await conversationService.addMessage('1', message);

    final messages = await conversationService.getMessages('1');
    expect(messages, hasLength(1));
    expect(messages.first, equals(message));

    final updatedConversation = await conversationService.getConversation('1');
    expect(updatedConversation.messages, hasLength(1));
    expect(updatedConversation.messages.first, equals(message));
    expect(updatedConversation.lastModified, isNotNull);
  });

  test('updates conversation status', () async {
    final conversation = Conversation(
      id: '1',
      title: 'Test Conversation',
      messages: [],
      createdAt: DateTime.now(),
    );

    await conversationService.createConversation(conversation);
    await conversationService.setConversationStatus('1', ConversationStatus.archived);

    final updated = await conversationService.getConversation('1');
    expect(updated.status, equals(ConversationStatus.archived));
    expect(updated.lastModified, isNotNull);
  });

  test('deletes a conversation', () async {
    final conversation = Conversation(
      id: '1',
      title: 'Test Conversation',
      messages: [],
      createdAt: DateTime.now(),
    );

    await conversationService.createConversation(conversation);
    await conversationService.deleteConversation('1');

    expect(
      () => conversationService.getConversation('1'),
      throwsException,
    );
  });

  test('handles multiple messages in order', () async {
    final conversation = Conversation(
      id: '1',
      title: 'Test Conversation',
      messages: [],
      createdAt: DateTime.now(),
    );

    await conversationService.createConversation(conversation);

    final messages = [
      Message(
        id: 'm1',
        content: 'First message',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
      Message(
        id: 'm2',
        content: 'Second message',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
      Message(
        id: 'm3',
        content: 'Third message',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
    ];

    for (final message in messages) {
      await conversationService.addMessage('1', message);
    }

    final retrievedMessages = await conversationService.getMessages('1');
    expect(retrievedMessages, hasLength(3));
    expect(retrievedMessages, equals(messages));
    
    // Verify messages are in the correct order
    for (var i = 0; i < messages.length; i++) {
      expect(retrievedMessages[i], equals(messages[i]));
    }
  });
}
