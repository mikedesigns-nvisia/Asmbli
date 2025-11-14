import 'dart:async';
import '../models/agent_state.dart';
import '../repositories/agent_state_repository.dart';

/// Stateful Agent Executor - Prevents hallucinations through state management
/// Provides action deduplication, context awareness, and conversation memory
class StatefulAgentExecutor {
  AgentState _state;
  final AgentStateRepository _stateRepo;
  
  StatefulAgentExecutor({
    required AgentState initialState,
    required AgentStateRepository stateRepo,
  })  : _state = initialState,
        _stateRepo = stateRepo;

  /// Execute an action with state awareness and deduplication
  Future<AgentResponse> executeAction({
    required String actionType,
    required Map<String, dynamic> params,
    required Future<Map<String, dynamic>> Function(Map<String, dynamic>) executeFunction,
  }) async {
    print('🔄 StatefulAgentExecutor: Executing $actionType with params: $params');

    // 1. Check if action already completed (deduplication)
    if (_state.hasCompletedAction(actionType, params)) {
      final observation = 'Action already completed: $actionType with similar parameters';
      print('🛑 Action skipped: $observation');

      final actionRecord = ActionRecord(
        actionType: actionType,
        params: params,
        result: ActionResult.skipped,
        observation: observation,
        timestamp: DateTime.now(),
      );

      _state = _state.recordAction(actionRecord);
      await _stateRepo.saveState(_state);

      return AgentResponse(
        success: false,
        message: observation,
        shouldSkip: true,
        actionRecord: actionRecord,
      );
    }

    // 2. Execute the action
    try {
      print('✅ Executing action: $actionType');
      final result = await executeFunction(params);

      // 3. Record successful action
      final observation = result['observation'] ?? 
          result['message'] ?? 
          'Action completed successfully: $actionType';
          
      final actionRecord = ActionRecord(
        actionType: actionType,
        params: params,
        result: ActionResult.success,
        observation: observation,
        timestamp: DateTime.now(),
        metadata: {
          'executionResult': result,
        },
      );

      _state = _state.recordAction(actionRecord);

      // 4. Update context with result
      _state = _state.updateContext('totalActions', _state.actionsCompleted.length);
      
      if (result.containsKey('elementId')) {
        _state = _state.updateContext('lastElementId', result['elementId']);
      }

      // 5. Persist state
      await _stateRepo.saveState(_state);

      print('✅ Action completed successfully: $observation');
      return AgentResponse(
        success: true,
        message: observation,
        shouldSkip: false,
        actionRecord: actionRecord,
      );

    } catch (e) {
      print('❌ Action failed: $e');
      
      // Record failed action
      final actionRecord = ActionRecord(
        actionType: actionType,
        params: params,
        result: ActionResult.failed,
        observation: 'Action failed: $e',
        timestamp: DateTime.now(),
        metadata: {
          'error': e.toString(),
        },
      );

      _state = _state.recordAction(actionRecord);
      await _stateRepo.saveState(_state);

      return AgentResponse(
        success: false,
        message: 'Action failed: $e',
        shouldSkip: false,
        actionRecord: actionRecord,
      );
    }
  }

  /// Add user message to conversation history
  Future<void> addUserMessage(String message, {Map<String, dynamic>? metadata}) async {
    final turn = ConversationTurn(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    _state = _state.addConversation(turn);
    await _stateRepo.saveState(_state);
    
    print('💬 User message added: "${message.substring(0, message.length.clamp(0, 50))}"');
  }

  /// Add assistant message to conversation history
  Future<void> addAssistantMessage(String message, {Map<String, dynamic>? metadata}) async {
    final turn = ConversationTurn(
      role: 'assistant',
      content: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    _state = _state.addConversation(turn);
    await _stateRepo.saveState(_state);
    
    print('🤖 Assistant message added: "${message.substring(0, message.length.clamp(0, 50))}"');
  }

  /// Add system message to conversation history
  Future<void> addSystemMessage(String message, {Map<String, dynamic>? metadata}) async {
    final turn = ConversationTurn(
      role: 'system',
      content: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    _state = _state.addConversation(turn);
    await _stateRepo.saveState(_state);
    
    print('🔧 System message added: "${message.substring(0, message.length.clamp(0, 50))}"');
  }

  /// Update agent goal status
  Future<void> updateGoalStatus(GoalStatus status) async {
    _state = _state.updateGoalStatus(status);
    await _stateRepo.saveState(_state);
    
    print('🎯 Goal status updated: ${status.displayName}');
  }

  /// Update agent context
  Future<void> updateContext(String key, dynamic value) async {
    _state = _state.updateContext(key, value);
    await _stateRepo.saveState(_state);
    
    print('🎯 Context updated: $key = $value');
  }

  /// Get state summary formatted for LLM context
  String getStateSummary() {
    return _state.getStateSummary();
  }

  /// Get conversation context only
  String getConversationContext({int maxTurns = 10}) {
    return _state.getConversationContext(maxTurns: maxTurns);
  }

  /// Get actions context only
  String getActionsContext() {
    return _state.getActionsContext();
  }

  /// Get recent actions of a specific type
  List<ActionRecord> getRecentActions(String actionType, {Duration? timeWindow}) {
    final cutoff = timeWindow != null 
        ? DateTime.now().subtract(timeWindow)
        : DateTime.now().subtract(const Duration(hours: 1));

    return _state.actionsCompleted
        .where((action) => 
            action.actionType == actionType && 
            action.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Check if goal is complete based on actions
  bool isGoalComplete() {
    return _state.goalStatus == GoalStatus.complete;
  }

  /// Get completion percentage based on actions vs expected actions
  double getCompletionPercentage({int? expectedActions}) {
    if (expectedActions == null || expectedActions == 0) return 0.0;
    
    final completed = _state.actionsCompleted
        .where((action) => action.result == ActionResult.success)
        .length;
        
    return (completed / expectedActions).clamp(0.0, 1.0);
  }

  /// Clear conversation history (keep actions)
  Future<void> clearConversation() async {
    _state = _state.copyWith(
      conversationHistory: [],
      lastUpdated: DateTime.now(),
    );
    await _stateRepo.saveState(_state);
    
    print('🗑️ Conversation history cleared');
  }

  /// Reset all state (for testing or new session)
  Future<void> resetState() async {
    _state = AgentState(
      agentId: _state.agentId,
      sessionId: _state.sessionId,
      createdAt: _state.createdAt,
      lastUpdated: DateTime.now(),
    );
    await _stateRepo.saveState(_state);
    
    print('🔄 State reset completely');
  }

  /// Current state getter
  AgentState get currentState => _state;

  /// Session ID getter
  String get sessionId => _state.sessionId;

  /// Agent ID getter  
  String get agentId => _state.agentId;
}

/// Response from agent action execution
class AgentResponse {
  final bool success;
  final String message;
  final bool shouldSkip;
  final ActionRecord? actionRecord;

  const AgentResponse({
    required this.success,
    required this.message,
    required this.shouldSkip,
    this.actionRecord,
  });

  @override
  String toString() => 'AgentResponse(success: $success, skip: $shouldSkip, message: "$message")';
}