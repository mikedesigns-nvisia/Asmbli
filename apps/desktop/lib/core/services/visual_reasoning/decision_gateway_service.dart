import 'dart:async';
import '../../di/service_locator.dart';
import '../mcp_penpot_server.dart';

/// Decision Gateway Service - Implements Procedural Intelligence Block #3
/// Prevents agent hallucinations by validating actions against current state
/// Connected to Penpot MCP Server for real-time canvas awareness.
class DecisionGatewayService {
  static DecisionGatewayService? _instance;
  static DecisionGatewayService get instance => _instance ??= DecisionGatewayService._();
  DecisionGatewayService._();

  MCPPenpotServer? _penpotServer;
  bool _isInitialized = false;
  bool _penpotAvailable = false;

  // Trace events for decision tracking
  final List<DecisionTrace> _decisionHistory = [];
  final StreamController<DecisionTrace> _traceController = StreamController.broadcast();

  Stream<DecisionTrace> get onDecisionTrace => _traceController.stream;
  List<DecisionTrace> get decisionHistory => List.unmodifiable(_decisionHistory);

  /// Initialize the service without requiring Penpot server
  /// Penpot connection is optional and established when available
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;
    print('🚦 Decision Gateway Service initialized (Penpot will connect when available)');
  }

  /// Connect to Penpot server when it becomes available
  void connectPenpotServer(MCPPenpotServer server) {
    _penpotServer = server;
    _penpotAvailable = true;
    print('🚦 Decision Gateway connected to Penpot server');
  }

  /// Disconnect from Penpot server
  void disconnectPenpotServer() {
    _penpotServer = null;
    _penpotAvailable = false;
    print('🚦 Decision Gateway disconnected from Penpot server');
  }

  /// Check if Penpot server is available
  bool get isPenpotAvailable => _penpotAvailable && _penpotServer != null;

  /// Core decision gateway - validates actions before execution
  Future<DecisionResult> evaluateAction({
    required String intent,
    required String actionType,
    required Map<String, dynamic> parameters,
    String? userId,
  }) async {
    if (!_isInitialized) await initialize();
    
    final startTime = DateTime.now();
    print('🚦 DECISION GATEWAY: Evaluating "$intent" -> $actionType');
    
    try {
      // Step 1: Context Filters - Get current canvas state
      final canvasState = await _getCanvasState();
      
      // Step 2: Decision Gateway Logic
      final decision = await _makeDecision(
        intent: intent,
        actionType: actionType,
        parameters: parameters,
        canvasState: canvasState,
      );
      
      // Step 3: Trace Events - Log the decision
      final trace = DecisionTrace(
        id: 'decision_${DateTime.now().millisecondsSinceEpoch}',
        intent: intent,
        actionType: actionType,
        parameters: parameters,
        canvasState: canvasState,
        decision: decision,
        timestamp: startTime,
        duration: DateTime.now().difference(startTime),
        userId: userId,
      );
      
      _decisionHistory.add(trace);
      _traceController.add(trace);
      
      print('✅ DECISION: ${decision.action} - ${decision.reasoning}');
      return decision;
      
    } catch (e) {
      final errorDecision = DecisionResult(
        action: DecisionAction.error,
        reasoning: 'Decision gateway error: $e',
        shouldExecute: false,
        confidence: 0.0,
      );
      
      final trace = DecisionTrace(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        intent: intent,
        actionType: actionType,
        parameters: parameters,
        canvasState: {},
        decision: errorDecision,
        timestamp: startTime,
        duration: DateTime.now().difference(startTime),
        userId: userId,
        error: e.toString(),
      );
      
      _decisionHistory.add(trace);
      _traceController.add(trace);
      
      return errorDecision;
    }
  }

  /// Get current canvas state for context filtering
  Future<Map<String, dynamic>> _getCanvasState() async {
    try {
      if (_penpotServer == null || !_penpotServer!.isReady) {
        return {'elementCount': 0, 'elements': []};
      }

      final result = await _penpotServer!.getCanvasStateDetailed();
      
      if (!result['success']) {
        return {'elementCount': 0, 'elements': []};
      }

      final state = result['state'] as Map<String, dynamic>;
      final elements = state['elements'] as List<dynamic>? ?? [];
      
      return {
        'elementCount': elements.length,
        'elements': elements,
        'lastModified': DateTime.now().toIso8601String(), // Penpot doesn't provide this yet
        'bounds': state['bounds'],
      };
    } catch (e) {
      print('⚠️ Could not get canvas state: $e');
      return {'elementCount': 0, 'elements': []};
    }
  }

  /// Core decision-making logic with anti-hallucination patterns
  Future<DecisionResult> _makeDecision({
    required String intent,
    required String actionType,
    required Map<String, dynamic> parameters,
    required Map<String, dynamic> canvasState,
  }) async {
    
    // Check for recent duplicate actions
    final recentDuplicates = _findRecentDuplicateActions(intent, actionType, parameters);
    if (recentDuplicates.isNotEmpty) {
      return DecisionResult(
        action: DecisionAction.skip,
        reasoning: 'Recently executed similar action (${recentDuplicates.length} times). Skipping to prevent loops.',
        shouldExecute: false,
        confidence: 0.95,
        relatedElements: recentDuplicates.map((t) => t.decision?.executedElementId).where((id) => id != null).cast<String>().toList(),
      );
    }

    // Check if desired element already exists on canvas
    final existingElement = _findSimilarElementOnCanvas(parameters, canvasState);
    if (existingElement != null) {
      return DecisionResult(
        action: DecisionAction.acknowledge,
        reasoning: 'Similar element already exists on canvas at position (${existingElement['x']}, ${existingElement['y']})',
        shouldExecute: false,
        confidence: 0.90,
        relatedElements: [existingElement['id']],
      );
    }

    // Check canvas capacity
    final elements = canvasState['elements'] as List<dynamic>? ?? [];
    if (elements.length > 50) {
      return DecisionResult(
        action: DecisionAction.suggest_alternative,
        reasoning: 'Canvas has many elements (${elements.length}). Consider clearing or organizing first.',
        shouldExecute: false,
        confidence: 0.75,
      );
    }

    // Decision: Proceed with action
    return DecisionResult(
      action: DecisionAction.execute,
      reasoning: 'Action is appropriate and not duplicated. Canvas state allows new element.',
      shouldExecute: true,
      confidence: 0.85,
    );
  }

  /// Find recent duplicate actions to prevent loops
  List<DecisionTrace> _findRecentDuplicateActions(
    String intent, 
    String actionType, 
    Map<String, dynamic> parameters
  ) {
    final recentWindow = DateTime.now().subtract(const Duration(minutes: 2));
    
    return _decisionHistory.where((trace) {
      if (trace.timestamp.isBefore(recentWindow)) return false;
      if (trace.actionType != actionType) return false;
      
      // Check intent similarity
      final intentSimilarity = _calculateIntentSimilarity(intent, trace.intent);
      if (intentSimilarity < 0.7) return false;
      
      // Check parameter similarity
      final paramSimilarity = _calculateParameterSimilarity(parameters, trace.parameters);
      return paramSimilarity > 0.8;
      
    }).toList();
  }

  /// Find similar element already on canvas
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

  /// Check if two shape types are equivalent (e.g., circle == ellipse)
  bool _areTypesEquivalent(String? type1, String? type2) {
    if (type1 == type2) return true;
    
    final circleTypes = ['circle', 'ellipse'];
    if (circleTypes.contains(type1) && circleTypes.contains(type2)) {
      return true;
    }
    
    return false;
  }

  /// Calculate similarity between two intent strings
  double _calculateIntentSimilarity(String intent1, String intent2) {
    final words1 = intent1.toLowerCase().split(' ').toSet();
    final words2 = intent2.toLowerCase().split(' ').toSet();
    
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    
    return union > 0 ? intersection / union : 0.0;
  }

  /// Calculate similarity between parameter maps
  double _calculateParameterSimilarity(
    Map<String, dynamic> params1,
    Map<String, dynamic> params2,
  ) {
    final keys1 = params1.keys.toSet();
    final keys2 = params2.keys.toSet();
    final commonKeys = keys1.intersection(keys2);
    
    if (commonKeys.isEmpty) return 0.0;
    
    int matches = 0;
    for (final key in commonKeys) {
      if (params1[key] == params2[key]) {
        matches++;
      }
    }
    
    return matches / commonKeys.length;
  }

  /// Clear decision history (for testing or reset)
  void clearHistory() {
    _decisionHistory.clear();
    print('🗑️ Decision history cleared');
  }

  void dispose() {
    _traceController.close();
    _isInitialized = false;
  }
}

/// Decision result from the gateway
class DecisionResult {
  final DecisionAction action;
  final String reasoning;
  final bool shouldExecute;
  final double confidence;
  final List<String> relatedElements;
  final String? executedElementId;

  const DecisionResult({
    required this.action,
    required this.reasoning,
    required this.shouldExecute,
    required this.confidence,
    this.relatedElements = const [],
    this.executedElementId,
  });
}

/// Types of decisions the gateway can make
enum DecisionAction {
  execute,              // Proceed with the action
  skip,                 // Skip due to recent duplicate
  acknowledge,          // Acknowledge existing similar element
  suggest_alternative,  // Suggest a different approach
  error,               // Error occurred
}

/// Trace event for decision logging
class DecisionTrace {
  final String id;
  final String intent;
  final String actionType;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> canvasState;
  final DecisionResult decision;
  final DateTime timestamp;
  final Duration duration;
  final String? userId;
  final String? error;

  const DecisionTrace({
    required this.id,
    required this.intent,
    required this.actionType,
    required this.parameters,
    required this.canvasState,
    required this.decision,
    required this.timestamp,
    required this.duration,
    this.userId,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'intent': intent,
    'actionType': actionType,
    'parameters': parameters,
    'canvasState': canvasState,
    'decision': {
      'action': decision.action.name,
      'reasoning': decision.reasoning,
      'shouldExecute': decision.shouldExecute,
      'confidence': decision.confidence,
      'relatedElements': decision.relatedElements,
    },
    'timestamp': timestamp.toIso8601String(),
    'duration': duration.inMilliseconds,
    'userId': userId,
    'error': error,
  };
}