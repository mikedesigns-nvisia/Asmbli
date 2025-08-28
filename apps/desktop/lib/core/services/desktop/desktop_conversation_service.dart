import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/services/conversation_service.dart';
import 'package:agent_engine_core/services/repository.dart';
import 'desktop_repository.dart';
import 'desktop_storage_service.dart';

/// Persistent conversation service that stores data using DesktopStorageService
class DesktopConversationService implements ConversationService {
  final Repository<Conversation> _repository;
  final DesktopStorageService _storage;

  DesktopConversationService()
      : _storage = DesktopStorageService.instance,
        _repository = DesktopRepository<Conversation>(
          boxName: 'conversations',
          getId: (conversation) => conversation.id,
          fromJson: Conversation.fromJson,
          toJson: (conversation) => conversation.toJson(),
        );

  @override
  Future<Conversation> createConversation(Conversation conversation) async {
    try {
      return await _repository.create(conversation);
    } catch (e) {
      print('⚠️ Failed to create conversation: $e');
      rethrow;
    }
  }

  @override
  Future<Conversation> getConversation(String id) async {
    try {
      final conversation = await _repository.read(id);
      if (conversation == null) {
        throw Exception('Conversation not found');
      }
      return conversation;
    } catch (e) {
      print('⚠️ Failed to get conversation $id: $e');
      rethrow;
    }
  }

  @override
  Future<List<Conversation>> listConversations() async {
    try {
      return await _repository.readAll();
    } catch (e) {
      print('⚠️ Failed to list conversations: $e');
      return []; // Return empty list on error
    }
  }

  @override
  Future<Conversation> updateConversation(Conversation conversation) async {
    try {
      return await _repository.update(conversation);
    } catch (e) {
      print('⚠️ Failed to update conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    try {
      await _repository.delete(id);
    } catch (e) {
      print('⚠️ Failed to delete conversation $id: $e');
      rethrow;
    }
  }

  @override
  Future<Message> addMessage(String conversationId, Message message) async {
    try {
      final conversation = await getConversation(conversationId);
      final updatedConversation = conversation.copyWith(
        messages: [...conversation.messages, message],
        lastModified: DateTime.now(),
      );
      await updateConversation(updatedConversation);
      return message;
    } catch (e) {
      print('⚠️ Failed to add message to conversation: $e');
      rethrow;
    }
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final conversation = await getConversation(conversationId);
      return conversation.messages;
    } catch (e) {
      print('⚠️ Failed to get messages for conversation: $e');
      return []; // Return empty list on error
    }
  }

  @override
  Future<void> setConversationStatus(String id, ConversationStatus status) async {
    try {
      final conversation = await getConversation(id);
      final updatedConversation = conversation.copyWith(status: status);
      await updateConversation(updatedConversation);
    } catch (e) {
      print('⚠️ Failed to set conversation status: $e');
      rethrow;
    }
  }

  Future<Conversation> updateLastModified(String conversationId) async {
    try {
      final conversation = await getConversation(conversationId);
      final updatedConversation = conversation.copyWith(
        lastModified: DateTime.now(),
      );
      return await updateConversation(updatedConversation);
    } catch (e) {
      print('⚠️ Failed to update conversation timestamp: $e');
      rethrow;
    }
  }

  /// Get count of conversations
  Future<int> getConversationCount() async {
    try {
      final conversations = await listConversations();
      return conversations.length;
    } catch (e) {
      print('⚠️ Failed to get conversation count: $e');
      return 0;
    }
  }

  /// Check if conversation exists
  Future<bool> conversationExists(String id) async {
    try {
      final conversation = await _repository.read(id);
      return conversation != null;
    } catch (e) {
      return false;
    }
  }

  /// Get recent conversations (sorted by last modified)
  Future<List<Conversation>> getRecentConversations({int limit = 10}) async {
    try {
      final allConversations = await listConversations();
      allConversations.sort((a, b) => (b.lastModified ?? DateTime.now()).compareTo(a.lastModified ?? DateTime.now()));
      return allConversations.take(limit).toList();
    } catch (e) {
      print('⚠️ Failed to get recent conversations: $e');
      return [];
    }
  }

  /// Get conversations for a specific agent
  Future<List<Conversation>> getConversationsForAgent(String agentId) async {
    try {
      final allConversations = await listConversations();
      return allConversations
          .where((conv) => conv.metadata?['agentId'] == agentId)
          .toList();
    } catch (e) {
      print('⚠️ Failed to get conversations for agent: $e');
      return [];
    }
  }

  /// Delete old messages from a conversation (keep only recent ones)
  Future<Conversation> pruneConversationMessages(String conversationId, {int keepCount = 50}) async {
    try {
      final conversation = await getConversation(conversationId);
      if (conversation.messages.length <= keepCount) {
        return conversation; // Nothing to prune
      }

      final prunedMessages = conversation.messages.skip(conversation.messages.length - keepCount).toList();
      final updatedConversation = conversation.copyWith(
        messages: prunedMessages,
        lastModified: DateTime.now(),
      );
      
      return await updateConversation(updatedConversation);
    } catch (e) {
      print('⚠️ Failed to prune conversation messages: $e');
      rethrow;
    }
  }
}