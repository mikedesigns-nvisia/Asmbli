import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/services/conversation_service.dart';
import 'package:uuid/uuid.dart';
import 'base_business_service.dart';
import '../llm/unified_llm_service.dart';
import '../mcp_bridge_service.dart';
import '../context_mcp_resource_service.dart';
import '../agent_context_prompt_service.dart';
import '../../utils/null_safety_utils.dart';

/// Business service for conversation and message processing
/// Handles all business logic related to conversations and message flow
class ConversationBusinessService extends BaseBusinessService {
  final ConversationService _conversationRepository;
  final UnifiedLLMService _llmService;
  final MCPBridgeService _mcpService;
  final ContextMCPResourceService _contextService;
  final AgentContextPromptService _promptService;
  final BusinessEventBus _eventBus;

  ConversationBusinessService({
    required ConversationService conversationRepository,
    required UnifiedLLMService llmService,
    required MCPBridgeService mcpService,
    required ContextMCPResourceService contextService,
    required AgentContextPromptService promptService,
    BusinessEventBus? eventBus,
  })  : _conversationRepository = conversationRepository,
        _llmService = llmService,
        _mcpService = mcpService,
        _contextService = contextService,
        _promptService = promptService,
        _eventBus = eventBus ?? BusinessEventBus();

  /// Processes a user message and generates an AI response
  Future<BusinessResult<Message>> processMessage({
    required String conversationId,
    required String content,
    required String modelId,
    String? agentId,
    List<String> contextDocs = const [],
    List<String> mcpServers = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    return handleBusinessOperation('processMessage', () async {
      validateRequired({
        'conversationId': conversationId,
        'content': content,
        'modelId': modelId,
      });

      // Validate conversation exists
      final conversation = await _conversationRepository.getConversation(conversationId);
      if (conversation == null) {
        return BusinessResult.failure('Conversation not found: $conversationId');
      }

      // Create and save user message
      final userMessage = Message(
        id: const Uuid().v4(),
        conversationId: conversationId,
        content: content.trim(),
        role: MessageRole.user,
        timestamp: DateTime.now(),
        metadata: {
          'messageType': 'user_input',
          'length': content.length,
          ...metadata,
        },
      );

      await _conversationRepository.addMessage(conversationId, userMessage);

      // Process the message with business logic
      final processingResult = await _processUserMessage(
        conversation: conversation,
        userMessage: userMessage,
        modelId: modelId,
        agentId: agentId,
        contextDocs: contextDocs,
        mcpServers: mcpServers,
      );

      if (!processingResult.isSuccess) {
        return BusinessResult.failure(processingResult.error!);
      }

      final assistantMessage = processingResult.data!;

      // Save assistant message
      await _conversationRepository.addMessage(conversationId, assistantMessage);

      // Update conversation metadata
      await _updateConversationAfterMessage(conversation, assistantMessage);

      // Publish events
      _eventBus.publish(EntityUpdatedEvent(userMessage));
      _eventBus.publish(EntityUpdatedEvent(assistantMessage));

      return BusinessResult.success(assistantMessage);
    });
  }

  /// Processes a message with streaming response
  Stream<MessageChunk> processMessageStream({
    required String conversationId,
    required String content,
    required String modelId,
    String? agentId,
    List<String> contextDocs = const [],
    List<String> mcpServers = const [],
    Map<String, dynamic> metadata = const {},
  }) async* {
    try {
      validateRequired({
        'conversationId': conversationId,
        'content': content,
        'modelId': modelId,
      });

      // Validate conversation exists
      final conversation = await _conversationRepository.getConversation(conversationId);
      if (conversation == null) {
        yield MessageChunk.error('Conversation not found: $conversationId');
        return;
      }

      // Create and save user message
      final userMessage = Message(
        id: const Uuid().v4(),
        conversationId: conversationId,
        content: content.trim(),
        role: MessageRole.user,
        timestamp: DateTime.now(),
        metadata: {
          'messageType': 'user_input',
          'streaming': true,
          ...metadata,
        },
      );

      await _conversationRepository.addMessage(conversationId, userMessage);
      yield MessageChunk.userMessage(userMessage);

      // Process with streaming
      final messageId = const Uuid().v4();
      final fullContent = StringBuffer();
      final mcpResults = <MCPToolResult>[];
      final resourceData = <MCPResourceData>[];

      // Build context and prepare for streaming
      final enrichedContext = await _buildContextForMessage(
        conversation: conversation,
        userMessage: userMessage,
        contextDocs: contextDocs,
        mcpServers: mcpServers,
        agentId: agentId,
      );

      // Start streaming from LLM
      await for (final chunk in _llmService.generateStream(
        prompt: enrichedContext.prompt,
        modelId: modelId,
        context: enrichedContext.context,
      )) {
        if (chunk.isContent) {
          fullContent.write(chunk.content);
          yield MessageChunk.content(messageId, chunk.content!);
        } else if (chunk.isTool) {
          // Handle MCP tool calls during streaming
          final toolResult = await _handleMCPToolCall(
            toolCall: chunk.toolCall!,
            mcpServers: mcpServers,
          );
          mcpResults.add(toolResult);
          yield MessageChunk.toolResult(messageId, toolResult);
        } else if (chunk.isResource) {
          // Handle resource access during streaming
          final resource = await _handleResourceAccess(
            resourceRequest: chunk.resourceRequest!,
            contextDocs: contextDocs,
          );
          resourceData.add(resource);
          yield MessageChunk.resourceData(messageId, resource);
        }
      }

      // Create final assistant message
      final assistantMessage = Message(
        id: messageId,
        conversationId: conversationId,
        content: fullContent.toString(),
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        metadata: {
          'modelUsed': modelId,
          'streaming': true,
          'mcpToolsUsed': mcpResults.length,
          'resourcesAccessed': resourceData.length,
          'processingTime': DateTime.now().millisecondsSinceEpoch - userMessage.timestamp.millisecondsSinceEpoch,
          'mcpServersUsed': mcpServers,
          'hasGlobalContext': contextDocs.isNotEmpty,
          'toolResults': mcpResults.map((r) => r.toMap()).toList(),
          'resourceData': resourceData.map((r) => r.toMap()).toList(),
        },
      );

      // Save the final message
      await _conversationRepository.addMessage(conversationId, assistantMessage);

      // Update conversation
      await _updateConversationAfterMessage(conversation, assistantMessage);

      // Signal completion
      yield MessageChunk.complete(messageId, assistantMessage);

    } catch (error, stackTrace) {
      yield MessageChunk.error('Processing failed: $error');
      debugPrint('❌ Message processing error: $error\n$stackTrace');
    }
  }

  /// Creates a new conversation with initial configuration
  Future<BusinessResult<Conversation>> createConversation({
    required String title,
    String? agentId,
    String? modelId,
    Map<String, dynamic> metadata = const {},
  }) async {
    return handleBusinessOperation('createConversation', () async {
      validateRequired({'title': title});

      final conversation = Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ConversationStatus.active,
        metadata: {
          'version': '2.0',
          'creator': 'conversation_business_service',
          'agentId': agentId,
          'modelId': modelId,
          'messageCount': 0,
          'lastActivity': DateTime.now().toIso8601String(),
          ...metadata,
        },
      );

      final createdConversation = await _conversationRepository.createConversation(conversation);
      _eventBus.publish(EntityCreatedEvent(createdConversation));

      return BusinessResult.success(createdConversation);
    });
  }

  /// Updates conversation metadata and settings
  Future<BusinessResult<Conversation>> updateConversation({
    required String conversationId,
    String? title,
    ConversationStatus? status,
    Map<String, dynamic>? metadata,
  }) async {
    return handleBusinessOperation('updateConversation', () async {
      validateRequired({'conversationId': conversationId});

      final conversation = await _conversationRepository.getConversation(conversationId);
      if (conversation == null) {
        return BusinessResult.failure('Conversation not found: $conversationId');
      }

      final updatedConversation = conversation.copyWith(
        title: title?.trim(),
        status: status,
        updatedAt: DateTime.now(),
        metadata: metadata != null ? {...conversation.metadata, ...metadata} : null,
      );

      final result = await _conversationRepository.updateConversation(updatedConversation);
      _eventBus.publish(EntityUpdatedEvent(result));

      return BusinessResult.success(result);
    });
  }

  /// Archives a conversation (soft delete)
  Future<BusinessResult<void>> archiveConversation(String conversationId) async {
    return handleBusinessOperation('archiveConversation', () async {
      validateRequired({'conversationId': conversationId});

      await updateConversation(
        conversationId: conversationId,
        status: ConversationStatus.archived,
        metadata: {
          'archivedAt': DateTime.now().toIso8601String(),
        },
      );

      return BusinessResult.success(null);
    });
  }

  /// Permanently deletes a conversation and all messages
  Future<BusinessResult<void>> deleteConversation(String conversationId) async {
    return handleBusinessOperation('deleteConversation', () async {
      validateRequired({'conversationId': conversationId});

      final conversation = await _conversationRepository.getConversation(conversationId);
      if (conversation == null) {
        return BusinessResult.failure('Conversation not found: $conversationId');
      }

      // Clean up conversation resources
      await _cleanupConversationResources(conversation);

      // Delete the conversation
      await _conversationRepository.deleteConversation(conversationId);

      _eventBus.publish(EntityDeletedEvent<Conversation>(conversationId));

      return BusinessResult.success(null);
    });
  }

  /// Gets conversations with filtering and pagination
  Future<BusinessResult<List<Conversation>>> getConversations({
    ConversationStatus? status,
    String? agentId,
    int? limit,
    int? offset,
  }) async {
    return handleBusinessOperation('getConversations', () async {
      final allConversations = await _conversationRepository.listConversations();

      var filteredConversations = allConversations;

      // Apply filters
      if (status != null) {
        filteredConversations = filteredConversations
            .where((c) => c.status == status)
            .toList();
      }

      if (agentId != null) {
        filteredConversations = filteredConversations
            .where((c) => c.metadata['agentId'] == agentId)
            .toList();
      }

      // Sort by last activity
      filteredConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Apply pagination
      if (offset != null && offset > 0) {
        if (offset >= filteredConversations.length) {
          filteredConversations = [];
        } else {
          filteredConversations = filteredConversations.skip(offset).toList();
        }
      }

      if (limit != null && limit > 0) {
        filteredConversations = filteredConversations.take(limit).toList();
      }

      return BusinessResult.success(filteredConversations);
    });
  }

  // Private helper methods

  Future<BusinessResult<Message>> _processUserMessage({
    required Conversation conversation,
    required Message userMessage,
    required String modelId,
    String? agentId,
    List<String> contextDocs = const [],
    List<String> mcpServers = const [],
  }) async {
    try {
      // Build enriched context
      final enrichedContext = await _buildContextForMessage(
        conversation: conversation,
        userMessage: userMessage,
        contextDocs: contextDocs,
        mcpServers: mcpServers,
        agentId: agentId,
      );

      // Generate response using LLM
      final response = await _llmService.generate(
        prompt: enrichedContext.prompt,
        modelId: modelId,
        context: enrichedContext.context,
      );

      // Create assistant message
      final assistantMessage = Message(
        id: const Uuid().v4(),
        conversationId: conversation.id,
        content: response.content,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        metadata: {
          'modelUsed': modelId,
          'processingTime': response.processingTime,
          'tokenCount': response.tokenCount,
          'mcpServersUsed': mcpServers,
          'hasGlobalContext': contextDocs.isNotEmpty,
          'agentId': agentId,
        },
      );

      return BusinessResult.success(assistantMessage);
    } catch (e) {
      return BusinessResult.failure('Failed to process message: $e');
    }
  }

  Future<EnrichedContext> _buildContextForMessage({
    required Conversation conversation,
    required Message userMessage,
    List<String> contextDocs = const [],
    List<String> mcpServers = const [],
    String? agentId,
  }) async {
    final contextBuilder = NullSafetyUtils.createMapBuilder();

    // Add conversation history
    final recentMessages = conversation.messages
        .take(10) // Last 10 messages for context
        .map((m) => {
              'role': m.role.name,
              'content': m.content,
              'timestamp': m.timestamp.toIso8601String(),
            })
        .toList();

    contextBuilder.putList('conversationHistory', recentMessages);

    // Add context documents
    if (contextDocs.isNotEmpty) {
      final contextContent = await _contextService.getContextForDocuments(contextDocs);
      contextBuilder.putString('contextDocuments', contextContent);
    }

    // Add MCP capabilities
    if (mcpServers.isNotEmpty) {
      final mcpCapabilities = await _mcpService.getCapabilitiesForServers(mcpServers);
      contextBuilder.putList('mcpCapabilities', mcpCapabilities);
    }

    // Build system prompt
    String systemPrompt = 'You are a helpful AI assistant.';
    if (agentId != null) {
      // Get agent-specific prompt
      systemPrompt = await _getAgentSystemPrompt(agentId) ?? systemPrompt;
    }

    return EnrichedContext(
      prompt: userMessage.content,
      systemPrompt: systemPrompt,
      context: contextBuilder.build(),
    );
  }

  Future<String?> _getAgentSystemPrompt(String agentId) async {
    try {
      // This would typically fetch from agent service
      // For now, return a default prompt
      return 'You are a helpful AI assistant with enhanced capabilities.';
    } catch (e) {
      return null;
    }
  }

  Future<MCPToolResult> _handleMCPToolCall({
    required ToolCall toolCall,
    required List<String> mcpServers,
  }) async {
    try {
      final result = await _mcpService.callTool(
        serverId: toolCall.serverId,
        toolName: toolCall.name,
        arguments: toolCall.arguments,
      );

      return MCPToolResult(
        serverId: toolCall.serverId,
        toolName: toolCall.name,
        arguments: toolCall.arguments,
        result: result,
        success: true,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return MCPToolResult(
        serverId: toolCall.serverId,
        toolName: toolCall.name,
        arguments: toolCall.arguments,
        result: null,
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  Future<MCPResourceData> _handleResourceAccess({
    required ResourceRequest resourceRequest,
    required List<String> contextDocs,
  }) async {
    try {
      final content = await _contextService.getResourceContent(
        resourceRequest.uri,
        contextDocs,
      );

      return MCPResourceData(
        serverId: resourceRequest.serverId,
        resourceUri: resourceRequest.uri,
        content: content,
        success: true,
      );
    } catch (e) {
      return MCPResourceData(
        serverId: resourceRequest.serverId,
        resourceUri: resourceRequest.uri,
        content: '',
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _updateConversationAfterMessage(
    Conversation conversation,
    Message message,
  ) async {
    final messageCount = (conversation.metadata['messageCount'] as int? ?? 0) + 1;
    
    await _conversationRepository.updateConversation(
      conversation.copyWith(
        updatedAt: DateTime.now(),
        metadata: {
          ...conversation.metadata,
          'messageCount': messageCount,
          'lastActivity': DateTime.now().toIso8601String(),
          'lastMessageRole': message.role.name,
        },
      ),
    );
  }

  Future<void> _cleanupConversationResources(Conversation conversation) async {
    // Clean up any conversation-specific resources
    // This could include temporary files, cache entries, etc.
  }
}

// Supporting classes

class EnrichedContext {
  final String prompt;
  final String systemPrompt;
  final Map<String, dynamic> context;

  const EnrichedContext({
    required this.prompt,
    required this.systemPrompt,
    required this.context,
  });
}

class MessageChunk {
  final String type;
  final String messageId;
  final String? content;
  final MCPToolResult? toolResult;
  final MCPResourceData? resourceData;
  final Message? userMessage;
  final Message? completeMessage;
  final String? error;

  const MessageChunk._({
    required this.type,
    required this.messageId,
    this.content,
    this.toolResult,
    this.resourceData,
    this.userMessage,
    this.completeMessage,
    this.error,
  });

  factory MessageChunk.content(String messageId, String content) =>
      MessageChunk._(type: 'content', messageId: messageId, content: content);

  factory MessageChunk.toolResult(String messageId, MCPToolResult result) =>
      MessageChunk._(type: 'tool_result', messageId: messageId, toolResult: result);

  factory MessageChunk.resourceData(String messageId, MCPResourceData data) =>
      MessageChunk._(type: 'resource_data', messageId: messageId, resourceData: data);

  factory MessageChunk.userMessage(Message message) =>
      MessageChunk._(type: 'user_message', messageId: message.id, userMessage: message);

  factory MessageChunk.complete(String messageId, Message message) =>
      MessageChunk._(type: 'complete', messageId: messageId, completeMessage: message);

  factory MessageChunk.error(String error) =>
      MessageChunk._(type: 'error', messageId: '', error: error);

  bool get isContent => type == 'content';
  bool get isTool => type == 'tool_result';
  bool get isResource => type == 'resource_data';
  bool get isComplete => type == 'complete';
  bool get isError => type == 'error';
}

// Mock classes for compilation (would be defined elsewhere)
class ToolCall {
  final String serverId;
  final String name;
  final Map<String, dynamic> arguments;

  const ToolCall({
    required this.serverId,
    required this.name,
    required this.arguments,
  });
}

class ResourceRequest {
  final String serverId;
  final String uri;

  const ResourceRequest({
    required this.serverId,
    required this.uri,
  });
}

class MCPToolResult {
  final String serverId;
  final String toolName;
  final Map<String, dynamic> arguments;
  final dynamic result;
  final bool success;
  final String? error;
  final DateTime timestamp;

  const MCPToolResult({
    required this.serverId,
    required this.toolName,
    required this.arguments,
    required this.result,
    required this.success,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'serverId': serverId,
      'toolName': toolName,
      'arguments': arguments,
      'result': result,
      'success': success,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class MCPResourceData {
  final String serverId;
  final String resourceUri;
  final String content;
  final bool success;
  final String? error;

  const MCPResourceData({
    required this.serverId,
    required this.resourceUri,
    required this.content,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'serverId': serverId,
      'resourceUri': resourceUri,
      'content': content,
      'success': success,
      'error': error,
    };
  }
}