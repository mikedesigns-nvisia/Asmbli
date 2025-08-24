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
 
 return ({required String title, Map<String, dynamic>? metadata}) async {
 final conversation = Conversation(
 id: DateTime.now().millisecondsSinceEpoch.toString(),
 title: title,
 messages: [],
 createdAt: DateTime.now(),
 metadata: metadata,
 );
 
 return await service.createConversation(conversation);
 };
});

// Create agent conversation with full agent configuration
final createAgentConversationProvider = Provider.autoDispose((ref) {
 final service = ref.read(conversationServiceProvider);
 
 return ({
 required String agentId,
 required String agentName,
 required String systemPrompt,
 required String apiProvider,
 required List<String> mcpServers,
 required Map<String, dynamic> mcpServerConfigs,
 required List<String> contextDocuments,
 }) async {
 final agentMetadata = {
 'type': 'agent',
 'agentId': agentId,
 'agentName': agentName,
 'systemPrompt': systemPrompt,
 'apiProvider': apiProvider,
 'mcpServers': mcpServers,
 'mcpServerConfigs': mcpServerConfigs,
 'contextDocuments': contextDocuments,
 'createdAt': DateTime.now().toIso8601String(),
 'version': '1.0.0',
 'generator': 'AgentEngine ChatMCP',
 };
 
 final conversation = Conversation(
 id: DateTime.now().millisecondsSinceEpoch.toString(),
 title: agentName,
 messages: [],
 createdAt: DateTime.now(),
 metadata: agentMetadata,
 );
 
 return await service.createConversation(conversation);
 };
});

// Create or get default API conversation
final getOrCreateDefaultConversationProvider = Provider.autoDispose((ref) {
 final service = ref.read(conversationServiceProvider);
 
 return () async {
 try {
 // Look for existing default API conversation
 final conversations = await service.listConversations();
 final defaultConversation = conversations.firstWhere(
 (c) => c.metadata?['type'] == 'default_api' && c.status == ConversationStatus.active,
 orElse: () => throw Exception('No default conversation found'),
 );
 
 return defaultConversation;
 } catch (e) {
 // Create new default API conversation if none exists
 final defaultMetadata = {
 'type': 'default_api',
 'apiProvider': 'Claude 3.5 Sonnet',
 'description': 'Direct API chat without agent',
 'createdAt': DateTime.now().toIso8601String(),
 };
 
 final conversation = Conversation(
 id: DateTime.now().millisecondsSinceEpoch.toString(),
 title: 'Direct API Chat',
 messages: [],
 createdAt: DateTime.now(),
 metadata: defaultMetadata,
 );
 
 return await service.createConversation(conversation);
 }
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

// Global provider for selected agent in preview
final selectedAgentPreviewProvider = StateProvider<String?>((ref) => null);

// Global provider for loaded agent IDs
final loadedAgentIdsProvider = StateProvider<Set<String>>((ref) => {});