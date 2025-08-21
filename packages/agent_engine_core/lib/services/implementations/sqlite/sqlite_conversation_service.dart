import '../../../models/conversation.dart';
import '../../conversation_service.dart';
import 'concrete_sqlite_repository.dart';
import 'sqlite_repository.dart';

class SqliteConversationService implements ConversationService {
  late final SqliteRepository<Conversation> _repository;

  SqliteConversationService() {
    _repository = ConcreteSqliteRepository<Conversation>(
      'conversations',
      (conversation) => conversation.id,
      (json) => Conversation.fromJson(json as Map<String, dynamic>),
      (conversation) => conversation.toJson(),
    );
  }

  Future<void> initialize() async {
    await _repository.initialize();
  }

  @override
  Future<Conversation> createConversation(Conversation conversation) => 
      _repository.create(conversation);

  @override
  Future<Conversation> getConversation(String id) async {
    final conversation = await _repository.read(id);
    if (conversation == null) {
      throw Exception('Conversation not found');
    }
    return conversation;
  }

  @override
  Future<List<Conversation>> listConversations() => _repository.readAll();

  @override
  Future<Conversation> updateConversation(Conversation conversation) => 
      _repository.update(conversation);

  @override
  Future<void> deleteConversation(String id) => _repository.delete(id);

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
  Future<void> setConversationStatus(
    String id, 
    ConversationStatus status,
  ) async {
    final conversation = await getConversation(id);
    final updatedConversation = conversation.copyWith(
      status: status,
      lastModified: DateTime.now(),
    );
    await updateConversation(updatedConversation);
  }

  Future<void> close() => _repository.close();
}
