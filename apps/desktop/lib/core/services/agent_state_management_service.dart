import 'dart:async';
import 'dart:convert';
import '../di/service_locator.dart';
import 'desktop/desktop_storage_service.dart';
import '../../features/agents/data/models/agent.dart';

/// Agent State Management Service - Core infrastructure for stateful agents
/// Provides conversation history, action tracking, and goal management for all agents
class AgentStateManagementService {
  static AgentStateManagementService? _instance;
  static AgentStateManagementService get instance => _instance ??= AgentStateManagementService._();
  AgentStateManagementService._();

  late DesktopStorageService _storage;
  final Map<String, AgentState> _activeStates = {};
  final StreamController<AgentStateUpdate> _stateUpdateController = StreamController.broadcast();
  bool _isInitialized = false;

  Stream<AgentStateUpdate> get onStateUpdate => _stateUpdateController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _storage = ServiceLocator.instance.get<DesktopStorageService>();
    await _loadPersistedStates();
    _isInitialized = true;
    
    print('🧠 Agent State Management Service initialized');
  }

  /// Get or create agent state for a specific agent session
  Future<AgentState> getAgentState(String agentId, String sessionId) async {
    if (!_isInitialized) await initialize();
    
    final stateKey = '${agentId}_$sessionId';
    
    if (_activeStates.containsKey(stateKey)) {
      return _activeStates[stateKey]!;
    }

    // Try to load from persistence
    AgentState? state = await _loadStateFromStorage(stateKey);
    
    if (state == null) {
      // Create new state
      state = AgentState(
        agentId: agentId,
        sessionId: sessionId,
        conversationHistory: [],
        actionsCompleted: [],
        currentContext: {},
        goalStatus: AgentGoalStatus.notStarted,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
    }
    
    _activeStates[stateKey] = state;
    return state;
  }

  /// Add conversation turn to agent state
  Future<void> addConversationTurn({
    required String agentId,
    required String sessionId,
    required String userMessage,
    required String agentResponse,
    Map<String, dynamic>? metadata,
  }) async {
    final state = await getAgentState(agentId, sessionId);
    
    final turn = ConversationTurn(
      id: 'turn_${DateTime.now().millisecondsSinceEpoch}',
      userMessage: userMessage,
      agentResponse: agentResponse,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    
    state.conversationHistory.add(turn);
    state.lastUpdated = DateTime.now();
    
    await _persistState(state);
    _notifyStateUpdate(state, AgentStateUpdateType.conversationAdded);
    
    print('💬 Added conversation turn to ${agentId}_$sessionId: "${userMessage.substring(0, 50)}..."');
  }

  /// Record action completion to prevent duplicates
  Future<void> recordActionCompleted({
    required String agentId,
    required String sessionId,
    required String actionType,
    required Map<String, dynamic> actionParams,
    required String actionResult,
    Map<String, dynamic>? metadata,
  }) async {
    final state = await getAgentState(agentId, sessionId);
    
    final action = CompletedAction(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}',
      actionType: actionType,
      parameters: actionParams,
      result: actionResult,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    
    state.actionsCompleted.add(action);
    state.lastUpdated = DateTime.now();
    
    await _persistState(state);
    _notifyStateUpdate(state, AgentStateUpdateType.actionCompleted);
    
    print('✅ Recorded completed action for ${agentId}_$sessionId: $actionType');
  }

  /// Check if similar action was recently completed
  bool wasActionRecentlyCompleted({
    required String agentId,
    required String sessionId,
    required String actionType,
    required Map<String, dynamic> actionParams,
    Duration timeWindow = const Duration(minutes: 5),
  }) {
    final stateKey = '${agentId}_$sessionId';
    final state = _activeStates[stateKey];
    
    if (state == null) return false;
    
    final cutoff = DateTime.now().subtract(timeWindow);
    
    for (final action in state.actionsCompleted) {
      if (action.timestamp.isBefore(cutoff)) continue;
      if (action.actionType != actionType) continue;
      
      // Check parameter similarity
      if (_areParametersSimilar(action.parameters, actionParams)) {
        print('🔄 Found recent similar action: ${action.id} at ${action.timestamp}');
        return true;
      }
    }
    
    return false;
  }

  /// Update agent context (canvas state, document state, etc.)
  Future<void> updateContext({
    required String agentId,
    required String sessionId,
    required Map<String, dynamic> contextUpdate,
    bool merge = true,
  }) async {
    final state = await getAgentState(agentId, sessionId);
    
    if (merge) {
      state.currentContext.addAll(contextUpdate);
    } else {
      state.currentContext = Map<String, dynamic>.from(contextUpdate);
    }
    
    state.lastUpdated = DateTime.now();
    await _persistState(state);
    _notifyStateUpdate(state, AgentStateUpdateType.contextUpdated);
    
    print('🎯 Updated context for ${agentId}_$sessionId: ${contextUpdate.keys}');
  }

  /// Update goal status
  Future<void> updateGoalStatus({
    required String agentId,
    required String sessionId,
    required AgentGoalStatus status,
    String? statusReason,
  }) async {
    final state = await getAgentState(agentId, sessionId);
    
    state.goalStatus = status;
    state.statusReason = statusReason;
    state.lastUpdated = DateTime.now();
    
    await _persistState(state);
    _notifyStateUpdate(state, AgentStateUpdateType.goalStatusChanged);
    
    print('🎯 Goal status updated for ${agentId}_$sessionId: ${status.name}');
  }

  /// Get conversation context for LLM
  String getConversationContext(String agentId, String sessionId, {int maxTurns = 10}) {
    final stateKey = '${agentId}_$sessionId';
    final state = _activeStates[stateKey];
    
    if (state == null || state.conversationHistory.isEmpty) {
      return 'No previous conversation history.';
    }
    
    final recentTurns = state.conversationHistory.reversed
        .take(maxTurns)
        .toList()
        .reversed;
        
    final contextBuffer = StringBuffer();
    contextBuffer.writeln('=== Conversation History ===');
    
    for (final turn in recentTurns) {
      contextBuffer.writeln('User: ${turn.userMessage}');
      contextBuffer.writeln('Agent: ${turn.agentResponse}');
      contextBuffer.writeln('---');
    }
    
    return contextBuffer.toString();
  }

  /// Get actions context for LLM
  String getActionsContext(String agentId, String sessionId, {Duration timeWindow = const Duration(hours: 1)}) {
    final stateKey = '${agentId}_$sessionId';
    final state = _activeStates[stateKey];
    
    if (state == null || state.actionsCompleted.isEmpty) {
      return 'No previous actions completed.';
    }
    
    final cutoff = DateTime.now().subtract(timeWindow);
    final recentActions = state.actionsCompleted
        .where((action) => action.timestamp.isAfter(cutoff))
        .toList();
    
    if (recentActions.isEmpty) {
      return 'No recent actions completed.';
    }
        
    final contextBuffer = StringBuffer();
    contextBuffer.writeln('=== Recently Completed Actions ===');
    
    for (final action in recentActions) {
      contextBuffer.writeln('${action.timestamp.toIso8601String()}: ${action.actionType}');
      contextBuffer.writeln('  Parameters: ${action.parameters}');
      contextBuffer.writeln('  Result: ${action.result}');
      contextBuffer.writeln('---');
    }
    
    return contextBuffer.toString();
  }

  /// Clear session state (for testing or reset)
  Future<void> clearSession(String agentId, String sessionId) async {
    final stateKey = '${agentId}_$sessionId';
    _activeStates.remove(stateKey);
    
    await _storage.removePreference('agent_state_$stateKey');
    
    print('🗑️ Cleared session state: $stateKey');
  }

  /// Compare parameter similarity for duplicate detection
  bool _areParametersSimilar(Map<String, dynamic> params1, Map<String, dynamic> params2) {
    final keys1 = params1.keys.toSet();
    final keys2 = params2.keys.toSet();
    
    // Must have similar key structure
    final commonKeys = keys1.intersection(keys2);
    if (commonKeys.length < keys1.length * 0.7) return false;
    
    // Check value similarity for common keys
    int similarValues = 0;
    for (final key in commonKeys) {
      if (params1[key] == params2[key]) {
        similarValues++;
      } else if (params1[key] is num && params2[key] is num) {
        // Numeric proximity check
        final diff = ((params1[key] as num) - (params2[key] as num)).abs();
        if (diff < 50) similarValues++; // Within 50 units (pixels, etc.)
      }
    }
    
    return similarValues >= commonKeys.length * 0.8;
  }

  /// Persist state to storage
  Future<void> _persistState(AgentState state) async {
    final stateKey = '${state.agentId}_${state.sessionId}';
    final stateJson = jsonEncode(state.toJson());
    
    await _storage.setPreference('agent_state_$stateKey', stateJson);
  }

  /// Load state from storage
  Future<AgentState?> _loadStateFromStorage(String stateKey) async {
    try {
      final stateJson = _storage.getPreference<String>('agent_state_$stateKey');
      if (stateJson == null) return null;
      
      final stateMap = jsonDecode(stateJson) as Map<String, dynamic>;
      return AgentState.fromJson(stateMap);
    } catch (e) {
      print('⚠️ Failed to load state for $stateKey: $e');
      return null;
    }
  }

  /// Load all persisted states on initialization
  Future<void> _loadPersistedStates() async {
    // This would scan all agent_state_* keys and load them
    // For now, states are loaded on-demand
  }

  /// Notify state update listeners
  void _notifyStateUpdate(AgentState state, AgentStateUpdateType type) {
    final update = AgentStateUpdate(
      agentId: state.agentId,
      sessionId: state.sessionId,
      updateType: type,
      timestamp: DateTime.now(),
      state: state,
    );
    
    _stateUpdateController.add(update);
  }

  void dispose() {
    _stateUpdateController.close();
    _activeStates.clear();
    _isInitialized = false;
  }
}

/// Agent state container
class AgentState {
  final String agentId;
  final String sessionId;
  final List<ConversationTurn> conversationHistory;
  final List<CompletedAction> actionsCompleted;
  Map<String, dynamic> currentContext;
  AgentGoalStatus goalStatus;
  String? statusReason;
  final DateTime createdAt;
  DateTime lastUpdated;

  AgentState({
    required this.agentId,
    required this.sessionId,
    required this.conversationHistory,
    required this.actionsCompleted,
    required this.currentContext,
    required this.goalStatus,
    this.statusReason,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'agentId': agentId,
    'sessionId': sessionId,
    'conversationHistory': conversationHistory.map((t) => t.toJson()).toList(),
    'actionsCompleted': actionsCompleted.map((a) => a.toJson()).toList(),
    'currentContext': currentContext,
    'goalStatus': goalStatus.name,
    'statusReason': statusReason,
    'createdAt': createdAt.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory AgentState.fromJson(Map<String, dynamic> json) => AgentState(
    agentId: json['agentId'] as String,
    sessionId: json['sessionId'] as String,
    conversationHistory: (json['conversationHistory'] as List<dynamic>)
        .map((t) => ConversationTurn.fromJson(t as Map<String, dynamic>))
        .toList(),
    actionsCompleted: (json['actionsCompleted'] as List<dynamic>)
        .map((a) => CompletedAction.fromJson(a as Map<String, dynamic>))
        .toList(),
    currentContext: Map<String, dynamic>.from(json['currentContext'] as Map),
    goalStatus: AgentGoalStatus.values.byName(json['goalStatus'] as String),
    statusReason: json['statusReason'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );
}

/// Conversation turn record
class ConversationTurn {
  final String id;
  final String userMessage;
  final String agentResponse;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const ConversationTurn({
    required this.id,
    required this.userMessage,
    required this.agentResponse,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userMessage': userMessage,
    'agentResponse': agentResponse,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory ConversationTurn.fromJson(Map<String, dynamic> json) => ConversationTurn(
    id: json['id'] as String,
    userMessage: json['userMessage'] as String,
    agentResponse: json['agentResponse'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    metadata: Map<String, dynamic>.from(json['metadata'] as Map),
  );
}

/// Completed action record
class CompletedAction {
  final String id;
  final String actionType;
  final Map<String, dynamic> parameters;
  final String result;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const CompletedAction({
    required this.id,
    required this.actionType,
    required this.parameters,
    required this.result,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'actionType': actionType,
    'parameters': parameters,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory CompletedAction.fromJson(Map<String, dynamic> json) => CompletedAction(
    id: json['id'] as String,
    actionType: json['actionType'] as String,
    parameters: Map<String, dynamic>.from(json['parameters'] as Map),
    result: json['result'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    metadata: Map<String, dynamic>.from(json['metadata'] as Map),
  );
}

/// Agent goal status tracking
enum AgentGoalStatus {
  notStarted,
  inProgress,
  completed,
  blocked,
  failed,
}

/// State update notification
class AgentStateUpdate {
  final String agentId;
  final String sessionId;
  final AgentStateUpdateType updateType;
  final DateTime timestamp;
  final AgentState state;

  const AgentStateUpdate({
    required this.agentId,
    required this.sessionId,
    required this.updateType,
    required this.timestamp,
    required this.state,
  });
}

enum AgentStateUpdateType {
  conversationAdded,
  actionCompleted,
  contextUpdated,
  goalStatusChanged,
}