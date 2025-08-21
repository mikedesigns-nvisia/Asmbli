import '../../models/conversation.dart';
import '../conversation_service.dart';
import '../repository.dart';
import 'memory_repository.dart';

class InMemoryConversationService implements ConversationService {
  final Repository<Conversation> _repository;

  InMemoryConversationService()
      : _repository = InMemoryRepository<Conversation>((conv) => conv.id);

  @override
  Future<Conversation> createConversation(Conversation conversation) async {
    return _repository.create(conversation);
  }

  @override
  Future<Conversation> getConversation(String id) async {
    final conversation = await _repository.read(id);
    if (conversation == null) {
      throw Exception('Conversation not found');
    }
    return conversation;
  }

  @override
  Future<List<Conversation>> listConversations() async {
    return _repository.readAll();
  }

  @override
  Future<Conversation> updateConversation(Conversation conversation) async {
    return _repository.update(conversation);
  }

  @override
  Future<void> deleteConversation(String id) async {
    await _repository.delete(id);
  }

  @override
  Future<Message> addMessage(String conversationId, Message message) async {
    final conversation = await getConversation(conversationId);
    final updatedConversation = conversation.copyWith(
      messages: [...conversation.messages, message],
      lastModified: DateTime.now(),
    );
    await updateConversation(updatedConversation);
    return message;
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final conversation = await getConversation(conversationId);
    return conversation.messages;
  }

  @override
  Future<void> setConversationStatus(String id, ConversationStatus status) async {
    final conversation = await getConversation(id);
    final updatedConversation = conversation.copyWith(
      status: status,
      lastModified: DateTime.now(),
    );
    await updateConversation(updatedConversation);
  }
}
