import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/services/conversation_service.dart';
import '../core/services/desktop/desktop_conversation_service.dart';
import 'package:agent_engine_core/models/conversation.dart';
import '../core/services/mcp_settings_service.dart';
import '../core/services/agent_system_prompt_service.dart';
import '../core/services/model_config_service.dart';
import '../core/services/desktop/hive_cleanup_service.dart';
import '../core/models/model_config.dart';

final conversationServiceProvider = Provider<ConversationService>((ref) {
 return DesktopConversationService();
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
 // Get the default model configuration to store with conversation
 final defaultModel = ref.read(defaultModelConfigProvider);
 
 // Get global MCP and context settings
 final mcpService = ref.read(mcpSettingsServiceProvider);
 final globalContextDocs = mcpService.globalContextDocuments;
 final globalMcpServers = mcpService.getAllMCPServers()
     .where((server) => server.enabled)
     .map((server) => server.id)
     .toList();
 
 // Merge provided metadata with default model information
 final conversationMetadata = {
   'type': 'direct_chat',
   'createdAt': DateTime.now().toIso8601String(),
   'version': '1.0.0',
   'generator': 'AgentEngine Direct Chat',
   'hasGlobalMCP': globalMcpServers.isNotEmpty,
   'hasGlobalContext': globalContextDocs.isNotEmpty,
   'globalMcpServers': globalMcpServers,
   'globalContextDocuments': globalContextDocs,
   'mcpEnabled': globalMcpServers.isNotEmpty,
   'contextEnabled': globalContextDocs.isNotEmpty,
   ...?metadata, // Spread provided metadata (can override above values)
 };
 
 // Add default model info if available
 if (defaultModel != null) {
   conversationMetadata.addAll({
     'defaultModelId': defaultModel.id,
     'defaultModelName': defaultModel.name,
     'defaultModelProvider': defaultModel.provider,
     'modelType': defaultModel.isLocal ? 'local' : 'api',
     'modelConfigured': defaultModel.isConfigured,
   });
 }
 
 final conversation = Conversation(
 id: DateTime.now().millisecondsSinceEpoch.toString(),
 title: title,
 messages: [],
 createdAt: DateTime.now(),
 metadata: conversationMetadata,
 );
 
 return await service.createConversation(conversation);
 };
});

// Create agent conversation with full agent configuration using settings service
final createAgentConversationProvider = Provider.autoDispose((ref) {
 final service = ref.read(conversationServiceProvider);
 final mcpService = ref.read(mcpSettingsServiceProvider);
 
 return ({
 required String agentId,
 required String agentName,
 required String systemPrompt,
 required String apiProvider,
 required List<String> mcpServers,
 required Map<String, dynamic> mcpServerConfigs,
 required List<String> contextDocuments,
 }) async {
 // Get enhanced configuration from settings service
 final deploymentConfig = await mcpService.getAgentDeploymentConfig(agentId);
 
 // Use global MCP settings if available, fallback to provided configs
 final enhancedMcpConfigs = <String, dynamic>{};
 for (final serverId in mcpServers) {
 final globalConfig = mcpService.getMCPServer(serverId);
 if (globalConfig != null) {
 final configJson = globalConfig.toJson();
 enhancedMcpConfigs[serverId] = Map<String, dynamic>.from(configJson);
 } else {
 // Fallback to provided config
 final fallbackConfig = mcpServerConfigs[serverId] ?? <String, dynamic>{};
 enhancedMcpConfigs[serverId] = Map<String, dynamic>.from(fallbackConfig);
 }
 }
 
 // Get API assignment from settings if available
 final assignedApiConfigId = mcpService.getAgentApiMapping(agentId);
 
 // Combine agent-specific and global context documents
 final allContextDocuments = <String>[
 ...contextDocuments, // Agent-specific contexts
 ...mcpService.globalContextDocuments, // Global contexts from settings
 ];
 
 // Generate complete system prompt with real-time MCP integration context
 final completeSystemPrompt = AgentSystemPromptService.getCompleteSystemPrompt(
   baseSystemPrompt: systemPrompt,
   agentId: agentId,
   mcpServers: mcpServers,
   mcpServerConfigs: enhancedMcpConfigs,
   contextDocuments: allContextDocuments,
   environmentTokens: <String, String>{}, // TODO: Add environment tokens to AgentDeploymentConfig
 );

 final agentMetadata = {
 'type': 'agent',
 'agentId': agentId,
 'agentName': agentName,
 'systemPrompt': completeSystemPrompt, // Using enhanced system prompt
 'baseSystemPrompt': systemPrompt, // Keep original for reference
 'apiProvider': apiProvider,
 'assignedApiConfigId': assignedApiConfigId, // From settings
 'mcpServers': mcpServers,
 'mcpServerConfigs': enhancedMcpConfigs, // Enhanced with global settings
 'contextDocuments': allContextDocuments, // Combined contexts
 'globalContextUsed': mcpService.globalContextDocuments.length, // Tracking
 'createdAt': DateTime.now().toIso8601String(),
 'version': '1.0.0',
 'generator': 'AgentEngine ChatMCP',
 'settingsVersion': deploymentConfig.timestamp.toIso8601String(),
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
 
 // Check if existing conversation needs modelType metadata update
 final selectedModel = ref.read(selectedModelProvider) ?? ref.read(defaultModelConfigProvider);
 final expectedModelType = selectedModel?.isLocal == true ? 'local' : 'api';
 
 if (defaultConversation.metadata?['modelType'] != expectedModelType) {
 // Update the conversation with proper modelType metadata
 final updatedMetadata = Map<String, dynamic>.from(defaultConversation.metadata ?? {});
 updatedMetadata['modelType'] = expectedModelType;
 
 final updatedConversation = Conversation(
 id: defaultConversation.id,
 title: defaultConversation.title,
 messages: defaultConversation.messages,
 createdAt: defaultConversation.createdAt,
 status: defaultConversation.status,
 lastModified: DateTime.now(),
 metadata: updatedMetadata,
 );
 
 await service.updateConversation(updatedConversation);
 return updatedConversation;
 }
 
 return defaultConversation;
 } catch (e) {
 // Create new default API conversation if none exists with global MCP/context support
 final mcpService = ref.read(mcpSettingsServiceProvider);
 final globalContextDocs = mcpService.globalContextDocuments;
 final globalMcpServers = mcpService.getAllMCPServers()
     .where((server) => server.enabled)
     .map((server) => server.id)
     .toList();
 
 // Get currently selected model to set proper metadata
 final selectedModel = ref.read(selectedModelProvider) ?? ref.read(defaultModelConfigProvider);
 final modelType = selectedModel?.isLocal == true ? 'local' : 'api';
 
 final defaultMetadata = {
 'type': 'default_api',
 'modelType': modelType,
 'apiProvider': _getProviderName(ref),
 'description': 'LLM chat without agent',
 'createdAt': DateTime.now().toIso8601String(),
 'hasGlobalMCP': globalMcpServers.isNotEmpty,
 'hasGlobalContext': globalContextDocs.isNotEmpty,
 'globalMcpServers': globalMcpServers,
 'globalContextDocuments': globalContextDocs,
 'mcpEnabled': globalMcpServers.isNotEmpty,
 'contextEnabled': globalContextDocs.isNotEmpty,
 };
 
 final conversation = Conversation(
 id: DateTime.now().millisecondsSinceEpoch.toString(),
 title: 'Let\'s Talk',
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

// Provider to get the model configuration for a conversation
final conversationModelConfigProvider = Provider.family<ModelConfig?, String>((ref, conversationId) {
  final conversationAsync = ref.watch(conversationProvider(conversationId));
  final modelConfigService = ref.read(modelConfigServiceProvider);
  
  return conversationAsync.maybeWhen(
    data: (conversation) {
      final metadata = conversation.metadata;
      
      // Try to get stored model from conversation metadata
      final storedModelId = metadata?['defaultModelId'] as String?;
      if (storedModelId != null) {
        final storedModel = modelConfigService.getModelConfig(storedModelId);
        if (storedModel != null && storedModel.isConfigured) {
          return storedModel;
        }
      }
      
      // Fallback to current default model
      return modelConfigService.defaultModelConfig;
    },
    orElse: () => null,
  );
});

// Provider for currently selected conversation ID
final selectedConversationIdProvider = StateProvider<String?>((ref) => null);

// Provider to check if we need to run database cleanup
final databaseHealthProvider = FutureProvider<bool>((ref) async {
  try {
    final health = await HiveCleanupService.checkBoxHealth();
    return health['isHealthy'] as bool? ?? false;
  } catch (e) {
    // If we can't check health, assume it needs cleanup
    return false;
  }
});

// Provider to run database cleanup
final runDatabaseCleanupProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    try {
      return await HiveCleanupService.cleanupConversationsBox();
    } catch (e) {
      print('Failed to run database cleanup: $e');
      return false;
    }
  };
});

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

// Update conversation provider
final updateConversationProvider = Provider.autoDispose((ref) {
  final service = ref.read(conversationServiceProvider);
  
  return (String conversationId, Conversation updatedConversation) async {
    return await service.updateConversation(updatedConversation);
  };
});

// Provider for conversation-specific model selection
final conversationModelProvider = StateProvider.family<ModelConfig?, String>((ref, conversationId) {
  // Get the conversation and check its stored model
  final conversationAsync = ref.watch(conversationProvider(conversationId));
  
  return conversationAsync.maybeWhen(
    data: (conversation) {
      final metadata = conversation.metadata;
      final modelConfigService = ref.read(modelConfigServiceProvider);
      
      // Check if conversation has a stored selected model
      final selectedModelId = metadata?['selectedModelId'] as String?;
      if (selectedModelId != null) {
        final storedModel = modelConfigService.getModelConfig(selectedModelId);
        if (storedModel != null && storedModel.isConfigured) {
          return storedModel;
        }
      }
      
      // Check for default model stored at conversation creation
      final defaultModelId = metadata?['defaultModelId'] as String?;
      if (defaultModelId != null) {
        final defaultModel = modelConfigService.getModelConfig(defaultModelId);
        if (defaultModel != null && defaultModel.isConfigured) {
          return defaultModel;
        }
      }
      
      // Fallback to system default
      return modelConfigService.defaultModelConfig;
    },
    orElse: () => ref.read(defaultModelConfigProvider),
  );
});

// Provider to update conversation's selected model
final setConversationModelProvider = Provider.autoDispose((ref) {
  final service = ref.read(conversationServiceProvider);
  
  return (String conversationId, ModelConfig model) async {
    try {
      final conversation = await service.getConversation(conversationId);
      final updatedMetadata = Map<String, dynamic>.from(conversation.metadata ?? {});
      
      // Store the selected model ID
      updatedMetadata['selectedModelId'] = model.id;
      updatedMetadata['selectedModelName'] = model.name;
      updatedMetadata['selectedModelProvider'] = model.provider;
      updatedMetadata['modelSelectionTimestamp'] = DateTime.now().toIso8601String();
      
      final updatedConversation = conversation.copyWith(
        metadata: updatedMetadata,
        lastModified: DateTime.now(),
      );
      
      await service.updateConversation(updatedConversation);
      
      // Update the conversation-specific provider
      ref.read(conversationModelProvider(conversationId).notifier).state = model;
      
    } catch (e) {
      print('Failed to update conversation model: $e');
      rethrow;
    }
  };
});

/// Helper function to get provider name for conversation metadata
String _getProviderName(Ref ref) {
  final defaultModel = ref.read(defaultModelConfigProvider);
  if (defaultModel != null) {
    if (defaultModel.isLocal) {
      return 'Local ${defaultModel.name}';
    } else {
      return defaultModel.provider;
    }
  }
  return 'LLM';
}