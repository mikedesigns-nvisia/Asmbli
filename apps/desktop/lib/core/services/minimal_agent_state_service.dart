import 'dart:async';
import '../di/service_locator.dart';

/// Minimal Agent State Service - MVP for Beta Launch
/// Solves Design Agent hallucination problem with simplest possible implementation
/// ⚠️ DEPRECATED: This service was designed for Excalidraw canvas system.
/// Will be removed or refactored for PenPOT plugin architecture.
class MinimalAgentStateService {
  static MinimalAgentStateService? _instance;
  static MinimalAgentStateService get instance => _instance ??= MinimalAgentStateService._();
  MinimalAgentStateService._();

  // late MCPExcalidrawBridgeService _mcpBridge; // Commented out - Excalidraw removed
  
  // Simple in-memory state for beta (will upgrade to persistence later)
  final Map<String, List<SimpleAction>> _sessionActions = {};
  final Map<String, List<ChatMessage>> _sessionHistory = {};
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // _mcpBridge = ServiceLocator.instance.get<MCPExcalidrawBridgeService>(); // Commented out - Excalidraw removed
    _isInitialized = true;

    print('🧠 Minimal Agent State Service initialized (Beta MVP - Excalidraw deprecated)');
  }

  /// Check if similar action was recently performed
  Future<ActionCheckResult> checkActionDuplication({
    required String sessionId,
    required String actionType,
    required Map<String, dynamic> parameters,
    Duration lookbackWindow = const Duration(minutes: 2),
  }) async {
    if (!_isInitialized) await initialize();
    
    // Check recent actions
    final recentActions = _getRecentActions(sessionId, lookbackWindow);
    
    for (final action in recentActions) {
      if (action.actionType == actionType && _areParametersSimilar(action.parameters, parameters)) {
        return ActionCheckResult(
          shouldSkip: true,
          reason: 'Similar ${actionType} action completed ${_formatTimeAgo(action.timestamp)}',
          previousAction: action,
        );
      }
    }
    
    // Check current canvas state
    final canvasState = await _getCurrentCanvasState();
    final existingElement = _findSimilarElementOnCanvas(parameters, canvasState);
    
    if (existingElement != null) {
      return ActionCheckResult(
        shouldSkip: true,
        reason: 'Similar element already exists on canvas at position (${existingElement['x']}, ${existingElement['y']})',
        existingElement: existingElement,
      );
    }
    
    return ActionCheckResult(
      shouldSkip: false,
      reason: 'No similar recent actions or existing elements found',
    );
  }

  /// Record action completion
  void recordAction({
    required String sessionId,
    required String actionType,
    required Map<String, dynamic> parameters,
    required String result,
  }) {
    final action = SimpleAction(
      actionType: actionType,
      parameters: parameters,
      result: result,
      timestamp: DateTime.now(),
    );
    
    _sessionActions.putIfAbsent(sessionId, () => []).add(action);
    
    // Keep only last 20 actions per session to prevent memory bloat
    if (_sessionActions[sessionId]!.length > 20) {
      _sessionActions[sessionId]!.removeAt(0);
    }
    
    print('✅ Recorded action: $actionType for session $sessionId');
  }

  /// Add conversation message
  void addConversationMessage({
    required String sessionId,
    required String message,
    required bool isAgent,
    Map<String, dynamic>? metadata,
  }) {
    final chatMessage = ChatMessage(
      message: message,
      isAgent: isAgent,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    _sessionHistory.putIfAbsent(sessionId, () => []).add(chatMessage);
    
    // Keep only last 50 messages per session
    if (_sessionHistory[sessionId]!.length > 50) {
      _sessionHistory[sessionId]!.removeAt(0);
    }
    
    print('💬 Added conversation message for session $sessionId');
  }

  /// Get conversation context for LLM prompts
  String getConversationContext(String sessionId, {int maxMessages = 10}) {
    final history = _sessionHistory[sessionId] ?? [];
    if (history.isEmpty) return 'No previous conversation.';
    
    final recentHistory = history.reversed.take(maxMessages).toList().reversed;
    
    final context = StringBuffer();
    context.writeln('=== Recent Conversation ===');
    for (final msg in recentHistory) {
      final speaker = msg.isAgent ? 'Agent' : 'User';
      context.writeln('$speaker: ${msg.message}');
    }
    context.writeln('===========================');
    
    return context.toString();
  }

  /// Get actions context for LLM prompts  
  String getActionsContext(String sessionId, {Duration timeWindow = const Duration(minutes: 5)}) {
    final recentActions = _getRecentActions(sessionId, timeWindow);
    if (recentActions.isEmpty) return 'No recent actions completed.';
    
    final context = StringBuffer();
    context.writeln('=== Recent Actions ===');
    for (final action in recentActions) {
      context.writeln('${_formatTimeAgo(action.timestamp)}: ${action.actionType}');
      context.writeln('  Result: ${action.result}');
    }
    context.writeln('======================');
    
    return context.toString();
  }

  /// Clear session (for testing or reset)
  void clearSession(String sessionId) {
    _sessionActions.remove(sessionId);
    _sessionHistory.remove(sessionId);
    print('🗑️ Cleared session: $sessionId');
  }

  /// Get current canvas state
  Future<Map<String, dynamic>> _getCurrentCanvasState() async {
    try {
      // final elements = _mcpBridge.getElements(); // Commented out - Excalidraw removed
      // final canvasInfo = await _mcpBridge.getCanvasInfo(); // Commented out - Excalidraw removed
      final elements = [];
      final canvasInfo = {};
      
      return {
        'elementCount': elements.length,
        'elements': elements,
        'lastModified': canvasInfo['lastModified'],
      };
    } catch (e) {
      print('⚠️ Could not get canvas state: $e');
      return {'elementCount': 0, 'elements': []};
    }
  }

  /// Find similar element on canvas
  Map<String, dynamic>? _findSimilarElementOnCanvas(
    Map<String, dynamic> requestedParams,
    Map<String, dynamic> canvasState,
  ) {
    final elements = canvasState['elements'] as List<dynamic>? ?? [];
    final requestedType = requestedParams['type'] ?? requestedParams['elementType'];
    
    for (final element in elements) {
      final elementMap = element as Map<String, dynamic>;
      
      // Type matching (handle circle/ellipse equivalence)
      if (_areTypesEquivalent(requestedType, elementMap['type'])) {
        // Position proximity check (within 100px)
        final deltaX = ((requestedParams['x'] ?? 0) - (elementMap['x'] ?? 0)).abs();
        final deltaY = ((requestedParams['y'] ?? 0) - (elementMap['y'] ?? 0)).abs();
        
        if (deltaX < 100 && deltaY < 100) {
          return elementMap;
        }
      }
    }
    
    return null;
  }

  /// Check if two shape types are equivalent
  bool _areTypesEquivalent(String? type1, String? type2) {
    if (type1 == type2) return true;
    
    final circleTypes = ['circle', 'ellipse'];
    if (circleTypes.contains(type1) && circleTypes.contains(type2)) {
      return true;
    }
    
    return false;
  }

  /// Get recent actions within time window
  List<SimpleAction> _getRecentActions(String sessionId, Duration timeWindow) {
    final actions = _sessionActions[sessionId] ?? [];
    final cutoff = DateTime.now().subtract(timeWindow);
    
    return actions.where((action) => action.timestamp.isAfter(cutoff)).toList();
  }

  /// Compare parameter similarity
  bool _areParametersSimilar(Map<String, dynamic> params1, Map<String, dynamic> params2) {
    // Simple similarity check for MVP
    final type1 = params1['type'] ?? params1['elementType'];
    final type2 = params2['type'] ?? params2['elementType'];
    
    if (!_areTypesEquivalent(type1, type2)) return false;
    
    // Position proximity (within 50 pixels)
    final x1 = params1['x'] ?? 0;
    final y1 = params1['y'] ?? 0;
    final x2 = params2['x'] ?? 0;
    final y2 = params2['y'] ?? 0;
    
    final distance = ((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
    return distance < 2500; // 50px squared
  }

  /// Format time ago for human readability
  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    
    if (diff.inMinutes < 1) return '${diff.inSeconds} seconds ago';
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    return '${diff.inHours} hours ago';
  }
}

/// Simple action record for MVP
class SimpleAction {
  final String actionType;
  final Map<String, dynamic> parameters;
  final String result;
  final DateTime timestamp;

  SimpleAction({
    required this.actionType,
    required this.parameters,
    required this.result,
    required this.timestamp,
  });
}

/// Simple chat message for MVP
class ChatMessage {
  final String message;
  final bool isAgent;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.message,
    required this.isAgent,
    required this.timestamp,
    this.metadata,
  });
}

/// Result of action duplication check
class ActionCheckResult {
  final bool shouldSkip;
  final String reason;
  final SimpleAction? previousAction;
  final Map<String, dynamic>? existingElement;

  ActionCheckResult({
    required this.shouldSkip,
    required this.reason,
    this.previousAction,
    this.existingElement,
  });
}