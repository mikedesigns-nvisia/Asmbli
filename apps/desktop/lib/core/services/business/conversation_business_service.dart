import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/services/conversation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'base_business_service.dart';
import '../llm/unified_llm_service.dart';
import '../llm/llm_provider.dart';
import '../agent_mcp_service.dart';
import '../context_mcp_resource_service.dart';
import '../agent_context_prompt_service.dart';
import '../llm_tool_call_parser.dart';
import '../../models/mcp_tool_result.dart';
import '../../utils/null_safety_utils.dart';

/// Business service for conversation and message processing
/// Handles all business logic related to conversations and message flow
class ConversationBusinessService extends BaseBusinessService {
  final ConversationService _conversationRepository;
  final UnifiedLLMService _llmService;
  final AgentMCPService _mcpService;
  final ContextMCPResourceService _contextService;
  final AgentContextPromptService _promptService;
  final BusinessEventBus _eventBus;

  ConversationBusinessService({
    required ConversationService conversationRepository,
    required UnifiedLLMService llmService,
    required AgentMCPService mcpService,
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

      // Create and save user message
      final userMessage = Message(
        id: const Uuid().v4(),
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

      // Create and save user message
      final userMessage = Message(
        id: const Uuid().v4(),
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
      
      // Track conversation history for the loop
      var currentHistory = conversation.messages.toList();
      
      String currentPrompt = userMessage.content;
      bool isFinished = false;
      int loopCount = 0;
      const maxLoops = 10;

      while (!isFinished && loopCount < maxLoops) {
        loopCount++;
        final currentResponseBuffer = StringBuffer();
        
        // Build context
        final enrichedContext = await _buildContextForMessage(
          conversation: conversation.copyWith(messages: currentHistory),
          userMessage: userMessage, // Used for system prompt logic
          contextDocs: contextDocs,
          mcpServers: mcpServers,
          agentId: agentId,
        );
        
        // Prepare context map for provider
        final contextMap = Map<String, dynamic>.from(enrichedContext.context);
        final recentMessages = currentHistory
            .take(20)
            .map((m) => {
                  'role': m.role.name,
                  'content': m.content,
                  'timestamp': m.timestamp.toIso8601String(),
                })
            .toList();
        contextMap['conversationHistory'] = recentMessages;

        // Start streaming from LLM
        await for (final chunk in _llmService.chatStream(
          message: currentPrompt,
          modelId: modelId,
          context: ChatContext(metadata: {
            ..._buildChatContext(conversationId, null) ?? {},
            ...contextMap,
          }),
        )) {
          currentResponseBuffer.write(chunk);
          fullContent.write(chunk);
          yield MessageChunk.content(messageId, chunk);
        }
        
        final responseText = currentResponseBuffer.toString();
        
        // Check for tool calls
        final toolCalls = LLMToolCallParser.parseToolCalls(responseText);
        
        if (toolCalls.isNotEmpty) {
          // Execute tools
          final toolOutputs = StringBuffer();
          toolOutputs.writeln("Tool Execution Results:");
          
          for (final call in toolCalls) {
            yield MessageChunk.toolStatus(messageId, 'Executing ${call.name}...');
            
            try {
              String? targetServerId = call.serverId;
              if (targetServerId == null && mcpServers.isNotEmpty) {
                 targetServerId = mcpServers.first;
              }

              final result = await _mcpService.executeTool(
                call.name,
                call.arguments,
                serverId: targetServerId,
              );
              
              final mcpResult = MCPToolResult(
                serverId: result.serverId,
                toolName: result.toolName,
                arguments: result.arguments,
                result: result.result,
                success: result.success,
                error: result.error,
                timestamp: DateTime.now(),
              );
              
              mcpResults.add(mcpResult);
              yield MessageChunk.toolResult(messageId, mcpResult);
              
              toolOutputs.writeln("Tool '${call.name}' Output: ${result.result}");
              
            } catch (e) {
              toolOutputs.writeln("Tool '${call.name}' Error: $e");
              yield MessageChunk.error('Tool execution failed: $e');
            }
          }
          
          // Update history for next loop
          if (loopCount == 1) {
            currentHistory.add(userMessage);
          } else {
            // Add the previous tool output prompt to history
            currentHistory.add(Message(
              id: const Uuid().v4(),
              content: currentPrompt,
              role: MessageRole.user,
              timestamp: DateTime.now(),
              metadata: {'isToolOutput': true},
            ));
          }
          
          // Add assistant response to history
          currentHistory.add(Message(
            id: const Uuid().v4(),
            content: responseText,
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          ));
          
          // Set prompt for next loop
          currentPrompt = toolOutputs.toString();
          
        } else {
          isFinished = true;
        }
      }

      // Create final assistant message
      final assistantMessage = Message(
        id: messageId,
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
    bool autoPrime = true,
  }) async {
    return handleBusinessOperation('createConversation', () async {
      validateRequired({'title': title});

      final conversation = Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
        messages: [],
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        status: ConversationStatus.active,
        metadata: {
          'version': '2.0',
          'creator': 'conversation_business_service',
          'agentId': agentId,
          'modelId': modelId,
          'messageCount': 0,
          'lastActivity': DateTime.now().toIso8601String(),
          'isPrimed': false,
          'primingAttempted': false,
          ...metadata,
        },
      );

      final createdConversation = await _conversationRepository.createConversation(conversation);
      _eventBus.publish(EntityCreatedEvent(createdConversation));

      // Auto-prime the conversation if requested and modelId is provided
      if (autoPrime && modelId != null) {
        final primingResult = await _primeConversation(createdConversation, modelId);
        if (primingResult.isSuccess) {
          // Update conversation with priming success
          final primedConversation = await _conversationRepository.updateConversation(
            createdConversation.copyWith(
              metadata: {
                ...createdConversation.metadata!,
                'isPrimed': true,
                'primingAttempted': true,
                'primedAt': DateTime.now().toIso8601String(),
                'primingResult': primingResult.data,
              },
            ),
          );
          return BusinessResult.success(primedConversation);
        }
      }

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

      final updatedConversation = conversation.copyWith(
        title: title?.trim() ?? conversation.title,
        status: status ?? conversation.status,
        lastModified: DateTime.now(),
        metadata: metadata != null ? {
          ...?conversation.metadata,
          ...metadata,
        } : conversation.metadata,
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
            .where((c) => c.metadata?['agentId'] == agentId)
            .toList();
      }

      // Sort by last activity
      filteredConversations.sort((a, b) => (b.lastModified ?? b.createdAt).compareTo(a.lastModified ?? a.createdAt));

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

  /// Primes a conversation for optimal first-message performance
  Future<BusinessResult<Map<String, dynamic>>> primeConversation({
    required String conversationId,
    required String modelId,
  }) async {
    return handleBusinessOperation('primeConversation', () async {
      final conversation = await _conversationRepository.getConversation(conversationId);
      final result = await _primeConversation(conversation, modelId);
      return result;
    });
  }

  /// Checks if a conversation needs priming and attempts it
  Future<BusinessResult<bool>> ensureConversationPrimed({
    required String conversationId,
    required String modelId,
  }) async {
    return handleBusinessOperation('ensureConversationPrimed', () async {
      final conversation = await _conversationRepository.getConversation(conversationId);
      
      // Check if already primed
      final isPrimed = conversation.metadata?['isPrimed'] as bool? ?? false;
      final primingAttempted = conversation.metadata?['primingAttempted'] as bool? ?? false;
      
      if (isPrimed) {
        return BusinessResult.success(true);
      }
      
      if (!primingAttempted) {
        final primingResult = await _primeConversation(conversation, modelId);
        
        // Update metadata regardless of success
        await _conversationRepository.updateConversation(
          conversation.copyWith(
            metadata: {
              ...conversation.metadata ?? {},
              'isPrimed': primingResult.isSuccess,
              'primingAttempted': true,
              'primedAt': DateTime.now().toIso8601String(),
              'primingResult': primingResult.data,
              'primingError': primingResult.isSuccess ? null : primingResult.error,
            },
          ),
        );
        
        return BusinessResult.success(primingResult.isSuccess);
      }
      
      return BusinessResult.success(false);
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
        content: response.content,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        metadata: {
          'conversationId': conversation.id,
          'modelUsed': response.modelUsed,
          'tokenCount': (response.usage?.inputTokens ?? 0) + (response.usage?.outputTokens ?? 0),
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
    if (mcpServers.isNotEmpty && agentId != null) {
      try {
        final tools = await _mcpService.getAvailableTools(agentId: agentId);
        contextBuilder.putString('mcpCapabilities', tools.toString());
      } catch (e) {
        // Ignore errors for now
      }
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





  Future<void> _updateConversationAfterMessage(
    Conversation conversation,
    Message message,
  ) async {
    final messageCount = (conversation.metadata?['messageCount'] as int? ?? 0) + 1;
    
    await _conversationRepository.updateConversation(
      conversation.copyWith(
        lastModified: DateTime.now(),
        metadata: {
          ...?conversation.metadata,
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

  /// Core priming implementation for different conversation types
  Future<BusinessResult<Map<String, dynamic>>> _primeConversation(
    Conversation conversation,
    String modelId,
  ) async {
    try {
      final conversationType = conversation.metadata?['type'] as String?;
      final startTime = DateTime.now();

      switch (conversationType) {
        case 'agent':
          return await _primeAgentConversation(conversation, modelId);
        case 'default_api':
        case 'direct_chat':
        default:
          return await _primeRegularConversation(conversation, modelId);
      }
    } catch (e) {
      return BusinessResult.failure('Failed to prime conversation: $e');
    }
  }

  /// Prime agent conversation with MCP tools and context validation
  Future<BusinessResult<Map<String, dynamic>>> _primeAgentConversation(
    Conversation conversation,
    String modelId,
  ) async {
    final startTime = DateTime.now();
    final results = <String, dynamic>{};

    try {
      // 1. Validate MCP servers
      final mcpServers = (conversation.metadata?['mcpServers'] as List<dynamic>?)
          ?.map((s) => s.toString())
          .toList() ?? [];
      
      // 1. Validate MCP servers - Simplified
      /*
      final mcpValidation = <String, dynamic>{};
      for (final serverId in mcpServers) {
         // Validation logic removed as it relied on bridge
      }
      results['mcpValidation'] = mcpValidation;
      */

      // 2. Validate context documents
      final contextDocs = (conversation.metadata?['contextDocuments'] as List<dynamic>?)
          ?.map((d) => d.toString())
          .toList() ?? [];
      
      if (contextDocs.isNotEmpty) {
        try {
          final contextContent = await _contextService.getContextForDocuments(contextDocs);
          results['contextValidation'] = {
            'status': 'available',
            'documentCount': contextDocs.length,
            'contentLength': contextContent.length,
          };
        } catch (e) {
          results['contextValidation'] = {
            'status': 'error',
            'error': e.toString(),
          };
        }
      }

      // 3. Send lightweight priming message through MCP bridge - Skipped
      /*
      final primingMessage = 'System initialization check. Confirm all agent capabilities are ready.';
      try {
        final mcpResponse = await _mcpService.callTool(
          'system_check',
          {'message': primingMessage},
          serverId: mcpServers.isNotEmpty ? mcpServers.first : null,
        );
        results['mcpConnectionTest'] = {
          'status': 'success',
          'response': mcpResponse.toString().length > 0,
        };
      } catch (e) {
        // MCP test failed, but don't fail the entire priming
        results['mcpConnectionTest'] = {
          'status': 'skipped',
          'reason': 'No MCP test tool available',
        };
      }
      */

      // 4. Test basic LLM connectivity with agent system prompt
      final systemPrompt = conversation.metadata?['systemPrompt'] as String? ??
          'You are a helpful AI assistant with enhanced capabilities.';
      
      try {
        final testResponse = await _llmService.generate(
          prompt: 'System ready check - respond with "READY" if all systems operational.',
          modelId: modelId,
          context: {
            'systemPrompt': systemPrompt,
            'isPrimingCheck': true,
            'maxTokens': 10,
          },
        );
        
        results['llmConnectionTest'] = {
          'status': 'success',
          'modelUsed': testResponse.modelUsed,
          'responseReceived': testResponse.content.isNotEmpty,
        };
      } catch (e) {
        results['llmConnectionTest'] = {
          'status': 'error',
          'error': e.toString(),
        };
        // LLM failure is critical for agents
        return BusinessResult.failure('Agent LLM connection test failed: $e');
      }

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      results['primingDuration'] = duration;
      results['primingType'] = 'agent';
      results['timestamp'] = DateTime.now().toIso8601String();

      return BusinessResult.success(results);
    } catch (e) {
      return BusinessResult.failure('Agent priming failed: $e');
    }
  }

  /// Prime regular conversation with basic model validation
  Future<BusinessResult<Map<String, dynamic>>> _primeRegularConversation(
    Conversation conversation,
    String modelId,
  ) async {
    final startTime = DateTime.now();
    final results = <String, dynamic>{};

    try {
      // 1. Test basic LLM connectivity
      final systemPrompt = conversation.metadata?['systemPrompt'] as String? ??
          'You are a helpful AI assistant.';
      
      try {
        final testResponse = await _llmService.generate(
          prompt: 'System ready check - respond with "READY" if operational.',
          modelId: modelId,
          context: {
            'systemPrompt': systemPrompt,
            'isPrimingCheck': true,
            'maxTokens': 10,
          },
        );
        
        results['llmConnectionTest'] = {
          'status': 'success',
          'modelUsed': testResponse.modelUsed,
          'responseReceived': testResponse.content.isNotEmpty,
          'isLocalModel': testResponse.metadata?['isLocal'] ?? false,
        };
      } catch (e) {
        results['llmConnectionTest'] = {
          'status': 'error',
          'error': e.toString(),
        };
        return BusinessResult.failure('LLM connection test failed: $e');
      }

      // 2. Check for global context documents (non-agent conversations can still use global context)
      try {
        // This would check global context from settings - simplified for now
        results['globalContextCheck'] = {
          'status': 'available',
          'hasGlobalContext': await _hasGlobalContext(),
        };
      } catch (e) {
        results['globalContextCheck'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      results['primingDuration'] = duration;
      results['primingType'] = 'regular';
      results['timestamp'] = DateTime.now().toIso8601String();

      return BusinessResult.success(results);
    } catch (e) {
      return BusinessResult.failure('Regular conversation priming failed: $e');
    }
  }

  /// Build chat context for LLM requests
  Map<String, dynamic>? _buildChatContext(String conversationId, Agent? agent) {
    return {
      'conversationId': conversationId,
      'agentId': agent?.id,
      'agentName': agent?.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Check if global context is available
  Future<bool> _hasGlobalContext() async {
    try {
      // Check if context service has global documents available
      // TODO: Fix when context service is properly injected
      return false;
    } catch (e) {
      return false;
    }
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

  factory MessageChunk.toolStatus(String messageId, String status) =>
      MessageChunk._(type: 'tool_status', messageId: messageId, content: status);

  factory MessageChunk.userMessage(Message message) =>
      MessageChunk._(type: 'user_message', messageId: message.id, userMessage: message);

  factory MessageChunk.complete(String messageId, Message message) =>
      MessageChunk._(type: 'complete', messageId: messageId, completeMessage: message);

  factory MessageChunk.error(String error) =>
      MessageChunk._(type: 'error', messageId: '', error: error);

  bool get isContent => type == 'content';
  bool get isTool => type == 'tool_result';
  bool get isToolStatus => type == 'tool_status';
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