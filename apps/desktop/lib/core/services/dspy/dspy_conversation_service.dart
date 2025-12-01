/// DSPy-Powered Conversation Service
///
/// This replaces the complex conversation processing with direct DSPy calls.
/// All AI reasoning happens in the DSPy backend - Flutter just handles UI.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/services/conversation_service.dart';
import 'package:uuid/uuid.dart';

import 'dspy_service.dart';
import 'dspy_client.dart';

/// Simplified conversation service that delegates AI to DSPy
class DspyConversationService {
  final ConversationService _repository;
  final DspyService _dspy;

  DspyConversationService({
    required ConversationService repository,
    required DspyService dspy,
  })  : _repository = repository,
        _dspy = dspy;

  /// Process a user message and get AI response
  ///
  /// This is the main entry point. It:
  /// 1. Saves user message locally
  /// 2. Calls DSPy backend for AI response
  /// 3. Saves AI response locally
  /// 4. Returns the response
  Future<Message> processMessage({
    required String conversationId,
    required String content,
    String? agentId,
    bool useRag = false,
    List<String>? documentIds,
    String? reasoningPattern,
  }) async {
    // 1. Get conversation
    final conversation = await _repository.getConversation(conversationId);

    // 2. Save user message
    final userMessage = Message(
      id: const Uuid().v4(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    await _repository.addMessage(conversationId, userMessage);

    // 3. Build context from conversation history
    final history = conversation.messages.map((m) => {
      'role': m.role == MessageRole.user ? 'user' : 'assistant',
      'content': m.content,
    }).toList();

    // 4. Call DSPy backend
    String responseContent;
    Map<String, dynamic> metadata = {};

    try {
      if (useRag && documentIds != null && documentIds.isNotEmpty) {
        // Use RAG for document-grounded responses
        final ragResponse = await _dspy.queryDocuments(
          content,
          documentIds: documentIds,
          includeCitations: true,
        );
        responseContent = ragResponse.answer;
        metadata = {
          'type': 'rag',
          'sources': ragResponse.sources.map((s) => s.title).toList(),
          'confidence': ragResponse.confidence,
          'passages_used': ragResponse.passagesUsed,
        };
      } else if (reasoningPattern != null) {
        // Use structured reasoning
        final pattern = _parseReasoningPattern(reasoningPattern);
        final reasoningResponse = await _dspy.reason(content, pattern: pattern);
        responseContent = reasoningResponse.answer;
        metadata = {
          'type': 'reasoning',
          'pattern': reasoningResponse.patternUsed,
          'confidence': reasoningResponse.confidence,
          'reasoning': reasoningResponse.reasoning,
        };
      } else {
        // Simple chat
        final chatResponse = await _dspy.chat(content);
        responseContent = chatResponse.response;
        metadata = {
          'type': 'chat',
          'model': chatResponse.model,
          'confidence': chatResponse.confidence,
        };
      }
    } catch (e) {
      // Fallback error message
      responseContent = 'Sorry, I encountered an error processing your request. Please try again.';
      metadata = {'type': 'error', 'error': e.toString()};
    }

    // 5. Save assistant message
    final assistantMessage = Message(
      id: const Uuid().v4(),
      content: responseContent,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    await _repository.addMessage(conversationId, assistantMessage);

    return assistantMessage;
  }

  /// Execute an agent task using DSPy ReAct
  Future<DspyAgentResponse> executeAgentTask({
    required String conversationId,
    required String task,
    List<Map<String, String>>? tools,
    int maxIterations = 5,
  }) async {
    // Save task as user message
    final userMessage = Message(
      id: const Uuid().v4(),
      content: task,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      metadata: {'type': 'agent_task'},
    );
    await _repository.addMessage(conversationId, userMessage);

    // Execute via DSPy
    final response = await _dspy.executeAgent(
      task,
      tools: tools,
      maxIterations: maxIterations,
    );

    // Save response
    final assistantMessage = Message(
      id: const Uuid().v4(),
      content: response.answer,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      metadata: {
        'type': 'agent_response',
        'success': response.success,
        'iterations': response.iterationsUsed,
        'steps': response.steps.map((s) => {
          'thought': s.thought,
          'action': s.action,
          'observation': s.observation,
        }).toList(),
      },
    );
    await _repository.addMessage(conversationId, assistantMessage);

    return response;
  }

  /// Stream a response (for real-time UI updates)
  Stream<String> streamResponse({
    required String conversationId,
    required String content,
  }) async* {
    // For now, DSPy doesn't support streaming, so we simulate it
    // In production, you'd implement SSE in the DSPy backend

    yield 'Thinking';
    await Future.delayed(const Duration(milliseconds: 300));
    yield 'Thinking.';
    await Future.delayed(const Duration(milliseconds: 300));
    yield 'Thinking..';
    await Future.delayed(const Duration(milliseconds: 300));

    final response = await processMessage(
      conversationId: conversationId,
      content: content,
    );

    // Stream the response word by word for nice UX
    final words = response.content.split(' ');
    final buffer = StringBuffer();

    for (final word in words) {
      buffer.write(word);
      buffer.write(' ');
      yield buffer.toString();
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  /// Create a new conversation
  Future<Conversation> createConversation({
    String? title,
    String? agentId,
  }) async {
    final conversation = Conversation(
      id: const Uuid().v4(),
      title: title ?? 'New Conversation',
      messages: [],
      createdAt: DateTime.now(),
      metadata: {
        if (agentId != null) 'agentId': agentId,
        'backend': 'dspy',
      },
    );
    await _repository.createConversation(conversation);
    return conversation;
  }

  /// Get all conversations
  Future<List<Conversation>> getConversations() => _repository.listConversations();

  /// Get a specific conversation
  Future<Conversation> getConversation(String id) => _repository.getConversation(id);

  /// Delete a conversation
  Future<void> deleteConversation(String id) => _repository.deleteConversation(id);

  DspyReasoningPattern _parseReasoningPattern(String pattern) {
    switch (pattern.toLowerCase()) {
      case 'cot':
      case 'chain_of_thought':
        return DspyReasoningPattern.chainOfThought;
      case 'tot':
      case 'tree_of_thought':
        return DspyReasoningPattern.treeOfThought;
      case 'react':
        return DspyReasoningPattern.react;
      default:
        return DspyReasoningPattern.chainOfThought;
    }
  }
}

// ============== Riverpod Providers ==============

/// Provider for the conversation repository (local storage)
/// Uses DesktopConversationService for persistence
final conversationRepositoryProvider = Provider<ConversationService>((ref) {
  // Import DesktopConversationService at the top of main.dart
  // and override this provider if needed
  return _defaultConversationService;
});

// Lazy initialization to avoid import issues
ConversationService? _conversationServiceInstance;
ConversationService get _defaultConversationService {
  return _conversationServiceInstance ??= _createConversationService();
}

ConversationService _createConversationService() {
  // This will be replaced with the actual service in main.dart provider overrides
  throw UnimplementedError(
    'Provide conversationRepositoryProvider override in ProviderScope'
  );
}

/// Provider for DSPy conversation service
final dspyConversationServiceProvider = Provider<DspyConversationService>((ref) {
  final dspy = ref.watch(dspyServiceProvider);
  final repository = ref.watch(conversationRepositoryProvider);

  return DspyConversationService(
    repository: repository,
    dspy: dspy,
  );
});
