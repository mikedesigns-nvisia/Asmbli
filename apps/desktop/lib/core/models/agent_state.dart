import 'dart:convert';

/// Agent State - Core model for stateful agent interactions
/// Tracks conversation, actions, and context to prevent hallucinations
class AgentState {
  final String agentId;
  final String sessionId;
  final List<ConversationTurn> conversationHistory;
  final List<ActionRecord> actionsCompleted;
  final Map<String, dynamic> currentContext;
  final GoalStatus goalStatus;
  final DateTime createdAt;
  final DateTime lastUpdated;

  const AgentState({
    required this.agentId,
    required this.sessionId,
    this.conversationHistory = const [],
    this.actionsCompleted = const [],
    this.currentContext = const {},
    this.goalStatus = GoalStatus.pending,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Post-modern agent state: Check for creative intent vs blocking completion
  /// Inspired by Motiff, Figma, and Lovable patterns - amplify momentum vs block repetition
  bool hasCompletedAction(String actionType, Map<String, dynamic> params) {
    // CREATIVE MOMENTUM PATTERNS - Never block these creative workflows
    
    // 1. Iterative element creation (user wants 100 circles, variations, patterns)
    if (_isCreativeIteration(actionType, params)) {
      print('🎨 CREATIVE ITERATION detected - allowing action to amplify momentum');
      return false; // Allow creative repetition
    }
    
    // 2. Spatial distribution patterns (different positions = different intent)
    if (_isDifferentSpatialIntent(actionType, params)) {
      print('📍 SPATIAL VARIATION detected - allowing positional creativity');
      return false; // Allow spatial creativity
    }
    
    // 3. Only block TRUE duplicates (exact same params within 1 second)
    return _isTrueDuplicate(actionType, params);
  }
  
  /// Detect creative iteration patterns (inspired by Motiff's creative workflow engine)
  bool _isCreativeIteration(String actionType, Map<String, dynamic> params) {
    // Creating elements is inherently creative - don't block unless truly identical
    if (actionType == 'create_element') {
      final recentCreations = actionsCompleted
          .where((r) => r.actionType == 'create_element')
          .where((r) => DateTime.now().difference(r.timestamp).inMinutes < 5)
          .toList();
      
      // If user is actively creating multiple elements, they're in creative flow
      if (recentCreations.length >= 2) {
        print('🔥 USER IN CREATIVE FLOW - ${recentCreations.length} recent elements');
        return true;
      }
    }
    
    return false;
  }
  
  /// Detect different spatial intent (different positions = different creative intent)
  bool _isDifferentSpatialIntent(String actionType, Map<String, dynamic> params) {
    if (!params.containsKey('x') || !params.containsKey('y')) return false;
    
    final newX = params['x'] as num?;
    final newY = params['y'] as num?;
    if (newX == null || newY == null) return false;
    
    // Check recent actions of same type
    final recentSimilar = actionsCompleted
        .where((r) => r.actionType == actionType)
        .where((r) => DateTime.now().difference(r.timestamp).inMinutes < 10)
        .toList();
    
    for (final record in recentSimilar) {
      final oldX = record.params['x'] as num?;
      final oldY = record.params['y'] as num?;
      
      if (oldX != null && oldY != null) {
        // If positions are significantly different (>50px), it's different intent
        final distance = ((newX - oldX) * (newX - oldX) + (newY - oldY) * (newY - oldY));
        if (distance > 2500) { // ~50px distance
          print('📍 SPATIAL CREATIVITY: distance ${distance.round()}px from previous element');
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Only block true duplicates (exact params within very short timeframe)
  bool _isTrueDuplicate(String actionType, Map<String, dynamic> params) {
    return actionsCompleted.any((record) =>
        record.actionType == actionType && 
        _isExactDuplicate(record.params, params) &&
        DateTime.now().difference(record.timestamp).inSeconds < 2);
  }
  
  /// Check for exact duplicates (not fuzzy like old _paramsMatch)
  bool _isExactDuplicate(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      
      final valA = a[key];
      final valB = b[key];
      
      // Exact match required for true duplicates
      if (valA is num && valB is num) {
        if ((valA - valB).abs() > 0.1) return false; // Allow tiny floating point differences
      } else if (valA != valB) {
        return false;
      }
    }
    
    return true;
  }

  /// Get the last observation for context
  String? getLastObservation() {
    if (actionsCompleted.isEmpty) return null;
    return actionsCompleted.last.observation;
  }

  /// Update context with new information
  AgentState updateContext(String key, dynamic value) {
    final newContext = Map<String, dynamic>.from(currentContext);
    newContext[key] = value;
    return copyWith(
      currentContext: newContext,
      lastUpdated: DateTime.now(),
    );
  }

  /// Add a completed action
  AgentState recordAction(ActionRecord action) {
    return copyWith(
      actionsCompleted: [...actionsCompleted, action],
      currentContext: {
        ...currentContext,
        'lastAction': action.actionType,
        'lastActionTime': action.timestamp.toIso8601String(),
        '${action.actionType}_count': (currentContext['${action.actionType}_count'] ?? 0) + 1,
      },
      lastUpdated: DateTime.now(),
    );
  }

  /// Add conversation turn
  AgentState addConversation(ConversationTurn turn) {
    return copyWith(
      conversationHistory: [...conversationHistory, turn],
      lastUpdated: DateTime.now(),
    );
  }

  /// Update goal status
  AgentState updateGoalStatus(GoalStatus status) {
    return copyWith(
      goalStatus: status,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get conversation context for LLM prompts
  String getConversationContext({int maxTurns = 10}) {
    if (conversationHistory.isEmpty) return 'No previous conversation.';

    final recentHistory = conversationHistory.length > maxTurns
        ? conversationHistory.sublist(conversationHistory.length - maxTurns)
        : conversationHistory;

    final buffer = StringBuffer();
    buffer.writeln('=== Recent Conversation ===');
    for (final turn in recentHistory) {
      buffer.writeln('${turn.role}: ${turn.content}');
    }
    buffer.writeln('==========================');

    return buffer.toString();
  }

  /// Get actions context for LLM prompts
  String getActionsContext() {
    if (actionsCompleted.isEmpty) return 'No actions completed yet.';

    final buffer = StringBuffer();
    buffer.writeln('=== Actions Already Completed ===');
    for (final action in actionsCompleted) {
      final timeAgo = _formatTimeAgo(action.timestamp);
      buffer.writeln('- $timeAgo: ${action.actionType}');
      buffer.writeln('  Result: ${action.observation}');
      if (action.params.isNotEmpty) {
        buffer.writeln('  Parameters: ${action.params}');
      }
    }
    buffer.writeln('=================================');

    return buffer.toString();
  }

  /// Get full state summary for LLM context
  String getStateSummary() {
    final buffer = StringBuffer();

    // Conversation context
    buffer.writeln(getConversationContext());
    buffer.writeln();

    // Actions context
    buffer.writeln(getActionsContext());
    buffer.writeln();

    // Current state
    buffer.writeln('=== Current State ===');
    if (currentContext.isEmpty) {
      buffer.writeln('No specific context recorded.');
    } else {
      currentContext.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
    }
    buffer.writeln('====================');
    buffer.writeln();

    // Goal status
    buffer.writeln('=== Goal Status ===');
    buffer.writeln('Status: ${goalStatus.displayName}');
    buffer.writeln('==================');

    return buffer.toString();
  }

  // Removed old _paramsMatch - replaced with post-modern creative intent detection

  /// Format time ago for human readability
  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  AgentState copyWith({
    String? agentId,
    String? sessionId,
    List<ConversationTurn>? conversationHistory,
    List<ActionRecord>? actionsCompleted,
    Map<String, dynamic>? currentContext,
    GoalStatus? goalStatus,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return AgentState(
      agentId: agentId ?? this.agentId,
      sessionId: sessionId ?? this.sessionId,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      actionsCompleted: actionsCompleted ?? this.actionsCompleted,
      currentContext: currentContext ?? this.currentContext,
      goalStatus: goalStatus ?? this.goalStatus,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Serialize for persistence
  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'sessionId': sessionId,
        'conversationHistory': conversationHistory.map((t) => t.toJson()).toList(),
        'actionsCompleted': actionsCompleted.map((a) => a.toJson()).toList(),
        'currentContext': currentContext,
        'goalStatus': goalStatus.name,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory AgentState.fromJson(Map<String, dynamic> json) {
    return AgentState(
      agentId: json['agentId'],
      sessionId: json['sessionId'],
      conversationHistory: (json['conversationHistory'] as List)
          .map((t) => ConversationTurn.fromJson(t))
          .toList(),
      actionsCompleted: (json['actionsCompleted'] as List)
          .map((a) => ActionRecord.fromJson(a))
          .toList(),
      currentContext: Map<String, dynamic>.from(json['currentContext']),
      goalStatus: GoalStatus.values.byName(json['goalStatus']),
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  @override
  String toString() => 'AgentState(${agentId}_$sessionId, ${actionsCompleted.length} actions, ${goalStatus.name})';
}

/// Conversation turn record
class ConversationTurn {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ConversationTurn({
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory ConversationTurn.fromJson(Map<String, dynamic> json) {
    return ConversationTurn(
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
    );
  }

  @override
  String toString() => 'ConversationTurn($role: ${content.substring(0, content.length.clamp(0, 50))})';
}

/// Action record for tracking completed actions
class ActionRecord {
  final String actionType; // 'create_circle', 'create_rectangle', etc.
  final Map<String, dynamic> params;
  final ActionResult result;
  final String observation; // What happened
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ActionRecord({
    required this.actionType,
    required this.params,
    required this.result,
    required this.observation,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'actionType': actionType,
        'params': params,
        'result': result.name,
        'observation': observation,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory ActionRecord.fromJson(Map<String, dynamic> json) {
    return ActionRecord(
      actionType: json['actionType'],
      params: Map<String, dynamic>.from(json['params']),
      result: ActionResult.values.byName(json['result']),
      observation: json['observation'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
    );
  }

  @override
  String toString() => 'ActionRecord($actionType: ${result.name} - $observation)';
}

/// Goal status tracking
enum GoalStatus {
  pending('Pending'),
  inProgress('In Progress'),
  complete('Complete'),
  blocked('Blocked'),
  failed('Failed');

  const GoalStatus(this.displayName);
  final String displayName;
}

/// Action result tracking
enum ActionResult {
  success('Success'),
  failed('Failed'),
  skipped('Skipped'),
  blocked('Blocked');

  const ActionResult(this.displayName);
  final String displayName;
}