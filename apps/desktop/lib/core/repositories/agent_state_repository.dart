import 'dart:async';
import 'dart:convert';
import '../models/agent_state.dart';
import '../di/service_locator.dart';
import '../services/desktop/desktop_storage_service.dart';

/// Agent State Repository - Handles persistence of agent state
/// Uses DesktopStorageService for cross-platform local storage
class AgentStateRepository {
  static const String _storageKey = 'agent_states';
  static const String _indexKey = 'agent_state_index';
  
  late DesktopStorageService _storage;
  bool _isInitialized = false;

  /// Initialize the repository
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _storage = ServiceLocator.instance.get<DesktopStorageService>();
    _isInitialized = true;
    
    print('💾 Agent State Repository initialized');
  }

  /// Save state to persistent storage
  Future<void> saveState(AgentState state) async {
    if (!_isInitialized) await initialize();
    
    try {
      final stateKey = '${_storageKey}_${state.sessionId}';
      final stateJson = jsonEncode(state.toJson());
      
      // Save the state
      await _storage.setPreference(stateKey, stateJson);
      
      // Update the index
      await _updateStateIndex(state.sessionId, state.agentId, state.lastUpdated);
      
      print('💾 State saved: ${state.sessionId} (${state.actionsCompleted.length} actions)');
    } catch (e) {
      print('❌ Failed to save state: $e');
      rethrow;
    }
  }

  /// Load state by session ID
  Future<AgentState?> loadState(String sessionId) async {
    if (!_isInitialized) await initialize();
    
    try {
      final stateKey = '${_storageKey}_$sessionId';
      final stateJson = _storage.getPreference<String>(stateKey);
      
      if (stateJson == null) {
        print('💾 No state found for session: $sessionId');
        return null;
      }
      
      final stateMap = jsonDecode(stateJson) as Map<String, dynamic>;
      final state = AgentState.fromJson(stateMap);
      
      print('💾 State loaded: $sessionId (${state.actionsCompleted.length} actions, ${state.conversationHistory.length} messages)');
      return state;
    } catch (e) {
      print('❌ Failed to load state for $sessionId: $e');
      return null;
    }
  }

  /// Create new state for agent
  AgentState createNewState({required String agentId, String? customSessionId}) {
    final sessionId = customSessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    
    final state = AgentState(
      agentId: agentId,
      sessionId: sessionId,
      createdAt: now,
      lastUpdated: now,
    );
    
    print('🆕 Created new state: $sessionId for agent: $agentId');
    return state;
  }

  /// Get all states for a specific agent
  Future<List<AgentState>> getStatesForAgent(String agentId) async {
    if (!_isInitialized) await initialize();
    
    try {
      final index = await _getStateIndex();
      final sessionIds = index
          .where((entry) => entry['agentId'] == agentId)
          .map((entry) => entry['sessionId'] as String)
          .toList();
      
      final states = <AgentState>[];
      for (final sessionId in sessionIds) {
        final state = await loadState(sessionId);
        if (state != null) {
          states.add(state);
        }
      }
      
      // Sort by last updated (newest first)
      states.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      
      print('💾 Found ${states.length} states for agent: $agentId');
      return states;
    } catch (e) {
      print('❌ Failed to get states for agent $agentId: $e');
      return [];
    }
  }

  /// Get most recent state for an agent
  Future<AgentState?> getMostRecentState(String agentId) async {
    final states = await getStatesForAgent(agentId);
    return states.isNotEmpty ? states.first : null;
  }

  /// Delete state by session ID
  Future<void> deleteState(String sessionId) async {
    if (!_isInitialized) await initialize();
    
    try {
      final stateKey = '${_storageKey}_$sessionId';
      await _storage.removePreference(stateKey);
      await _removeFromIndex(sessionId);
      
      print('🗑️ State deleted: $sessionId');
    } catch (e) {
      print('❌ Failed to delete state $sessionId: $e');
    }
  }

  /// Delete all states for an agent
  Future<void> deleteStatesForAgent(String agentId) async {
    final states = await getStatesForAgent(agentId);
    
    for (final state in states) {
      await deleteState(state.sessionId);
    }
    
    print('🗑️ Deleted ${states.length} states for agent: $agentId');
  }

  /// Clean up old states (older than specified duration)
  Future<int> cleanupOldStates({Duration maxAge = const Duration(days: 30)}) async {
    if (!_isInitialized) await initialize();
    
    try {
      final cutoffDate = DateTime.now().subtract(maxAge);
      final index = await _getStateIndex();
      
      int deletedCount = 0;
      for (final entry in index) {
        final lastUpdated = DateTime.parse(entry['lastUpdated'] as String);
        if (lastUpdated.isBefore(cutoffDate)) {
          await deleteState(entry['sessionId'] as String);
          deletedCount++;
        }
      }
      
      print('🧹 Cleaned up $deletedCount old states');
      return deletedCount;
    } catch (e) {
      print('❌ Failed to cleanup old states: $e');
      return 0;
    }
  }

  /// Get statistics about stored states
  Future<Map<String, dynamic>> getStorageStats() async {
    if (!_isInitialized) await initialize();
    
    try {
      final index = await _getStateIndex();
      final agentCounts = <String, int>{};
      var totalActions = 0;
      var totalMessages = 0;
      
      for (final entry in index) {
        final agentId = entry['agentId'] as String;
        agentCounts[agentId] = (agentCounts[agentId] ?? 0) + 1;
        
        // Load state to get detailed stats
        final state = await loadState(entry['sessionId'] as String);
        if (state != null) {
          totalActions += state.actionsCompleted.length;
          totalMessages += state.conversationHistory.length;
        }
      }
      
      return {
        'totalSessions': index.length,
        'totalActions': totalActions,
        'totalMessages': totalMessages,
        'agentCounts': agentCounts,
        'oldestState': index.isEmpty ? null : index
            .map((e) => DateTime.parse(e['lastUpdated'] as String))
            .reduce((a, b) => a.isBefore(b) ? a : b)
            .toIso8601String(),
        'newestState': index.isEmpty ? null : index
            .map((e) => DateTime.parse(e['lastUpdated'] as String))
            .reduce((a, b) => a.isAfter(b) ? a : b)
            .toIso8601String(),
      };
    } catch (e) {
      print('❌ Failed to get storage stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Update the state index for efficient querying
  Future<void> _updateStateIndex(String sessionId, String agentId, DateTime lastUpdated) async {
    try {
      final index = await _getStateIndex();
      
      // Remove existing entry if it exists
      index.removeWhere((entry) => entry['sessionId'] == sessionId);
      
      // Add new entry
      index.add({
        'sessionId': sessionId,
        'agentId': agentId,
        'lastUpdated': lastUpdated.toIso8601String(),
      });
      
      // Sort by last updated (newest first)
      index.sort((a, b) => 
          DateTime.parse(b['lastUpdated'] as String)
              .compareTo(DateTime.parse(a['lastUpdated'] as String)));
      
      await _storage.setPreference(_indexKey, jsonEncode(index));
    } catch (e) {
      print('⚠️ Failed to update state index: $e');
    }
  }

  /// Get the state index
  Future<List<Map<String, dynamic>>> _getStateIndex() async {
    try {
      final indexJson = _storage.getPreference<String>(_indexKey);
      if (indexJson == null) return [];
      
      final indexList = jsonDecode(indexJson) as List<dynamic>;
      return indexList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('⚠️ Failed to load state index: $e');
      return [];
    }
  }

  /// Remove session from index
  Future<void> _removeFromIndex(String sessionId) async {
    try {
      final index = await _getStateIndex();
      index.removeWhere((entry) => entry['sessionId'] == sessionId);
      await _storage.setPreference(_indexKey, jsonEncode(index));
    } catch (e) {
      print('⚠️ Failed to remove from index: $e');
    }
  }
}