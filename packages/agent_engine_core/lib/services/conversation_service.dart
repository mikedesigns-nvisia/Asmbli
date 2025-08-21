import '../models/conversation.dart';

abstract class ConversationService {
  Future<Conversation> createConversation(Conversation conversation);
  Future<Conversation> getConversation(String id);
  Future<List<Conversation>> listConversations();
  Future<Conversation> updateConversation(Conversation conversation);
  Future<void> deleteConversation(String id);
  Future<Message> addMessage(String conversationId, Message message);
  Future<List<Message>> getMessages(String conversationId);
  Future<void> setConversationStatus(String id, ConversationStatus status);
}
