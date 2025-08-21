import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/services/conversation_service.dart';
import 'package:agent_engine_core/services/implementations/service_provider.dart';
import 'package:agent_engine_core/models/conversation.dart';

final conversationServiceProvider = Provider<ConversationService>((ref) {
  return ServiceProvider.getConversationService();
});

final conversationsProvider = StreamProvider<List<Conversation>>((ref) async* {
  final service = ref.read(conversationServiceProvider);
  
  while (true) {
    try {
      final allConversations = await service.listConversations();
      yield allConversations.where((c) => c.status == ConversationStatus.active).toList();
      await Future.delayed(const Duration(seconds: 5)); 
    } catch (e) {
      yield* Stream.error(e);
    }
  }
});

final conversationProvider = StreamProvider.family<Conversation, String>((ref, conversationId) async* {
  final service = ref.read(conversationServiceProvider);
  
  while (true) {
    try {
      yield await service.getConversation(conversationId);
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      yield* Stream.error(e);
    }
  }
});

final messagesProvider = StreamProvider.family<List<Message>, String>((ref, conversationId) async* {
  final service = ref.read(conversationServiceProvider);
  
  while (true) {
    try {
      yield await service.getMessages(conversationId);
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      yield* Stream.error(e);
    }
  }
});

final createConversationProvider = Provider.autoDispose((ref) {
  final service = ref.read(conversationServiceProvider);
  
  return ({required String title}) async {
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      messages: [],
      createdAt: DateTime.now(),
    );
    
    return await service.createConversation(conversation);
  };
});

final sendMessageProvider = Provider.autoDispose((ref) {
  final service = ref.read(conversationServiceProvider);
  
  return ({required String conversationId, required String content}) async {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    
    return await service.addMessage(conversationId, message);
  };
});

final isLoadingProvider = StateProvider<bool>((ref) => false);

final selectedConversationIdProvider = StateProvider<String?>((ref) => null);

// Archive/Unarchive conversation
final archiveConversationProvider = Provider.autoDispose((ref) {
  final service = ref.read(conversationServiceProvider);
  
  return (String conversationId, bool archive) async {
    final status = archive ? ConversationStatus.archived : ConversationStatus.active;
    await service.setConversationStatus(conversationId, status);
    
    // Refresh conversations list
    ref.invalidate(conversationsProvider);
  };
});

// Permanently delete conversation
final deleteConversationProvider = Provider.autoDispose((ref) {
  final service = ref.read(conversationServiceProvider);
  
  return (String conversationId) async {
    await service.deleteConversation(conversationId);
    
    // Clear selection if deleting selected conversation
    final selectedId = ref.read(selectedConversationIdProvider);
    if (selectedId == conversationId) {
      ref.read(selectedConversationIdProvider.notifier).state = null;
    }
    
    // Refresh conversations list
    ref.invalidate(conversationsProvider);
  };
});

// Get archived conversations
final archivedConversationsProvider = StreamProvider<List<Conversation>>((ref) async* {
  final service = ref.read(conversationServiceProvider);
  
  while (true) {
    try {
      final allConversations = await service.listConversations();
      yield allConversations.where((c) => c.status == ConversationStatus.archived).toList();
      await Future.delayed(const Duration(seconds: 5)); 
    } catch (e) {
      yield* Stream.error(e);
    }
  }
});