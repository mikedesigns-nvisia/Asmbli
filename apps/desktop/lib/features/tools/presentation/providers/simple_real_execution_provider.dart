import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mcp_server.dart';
// import '../../../../core/services/mcp_conversation_bridge_service.dart'; // Removed - deprecated
import '../../business/tools_service.dart';
import 'tools_provider.dart';

/// Simple state for real agent execution monitoring using existing models only
class SimpleExecutionState {
  final List<AgentConnection> agentConnections;
  final List<MCPServer> installedServers;
  // final List<MCPConversationSession> activeSessions; // Removed - deprecated
  final bool isLoading;
  final String? error;

  const SimpleExecutionState({
    required this.agentConnections,
    required this.installedServers,
    // required this.activeSessions, // Removed - deprecated
    required this.isLoading,
    this.error,
  });

  factory SimpleExecutionState.initial() {
    return const SimpleExecutionState(
      agentConnections: [],
      installedServers: [],
      // activeSessions: [], // Removed - deprecated
      isLoading: true,
    );
  }

  SimpleExecutionState copyWith({
    List<AgentConnection>? agentConnections,
    List<MCPServer>? installedServers,
    // List<MCPConversationSession>? activeSessions, // Removed - deprecated
    bool? isLoading,
    String? error,
  }) {
    return SimpleExecutionState(
      agentConnections: agentConnections ?? this.agentConnections,
      installedServers: installedServers ?? this.installedServers,
      // activeSessions: activeSessions ?? this.activeSessions, // Removed - deprecated
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Simple notifier that shows real MCP connections
class SimpleExecutionNotifier extends StateNotifier<SimpleExecutionState> {
  final ToolsService _toolsService;

  SimpleExecutionNotifier(this._toolsService) : super(SimpleExecutionState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize tools service (this loads real agents and servers)
      await _toolsService.initialize();
      
      // Listen to real data streams
      _toolsService.serversStream.listen((servers) {
        state = state.copyWith(installedServers: servers);
      });
      
      _toolsService.connectionsStream.listen((connections) {
        state = state.copyWith(agentConnections: connections);
      });
      
      // Set initial state with real data
      state = state.copyWith(
        isLoading: false,
        agentConnections: _toolsService.agentConnections,
        installedServers: _toolsService.installedServers,
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get agent connections with additional context
  List<AgentConnectionWithStatus> getAgentConnectionsWithStatus() {
    return state.agentConnections.map((connection) {
      // Get connected servers that are actually running
      final connectedRunningServers = state.installedServers
          .where((server) => 
            connection.connectedServerIds.contains(server.id) && 
            server.isRunning
          )
          .toList();
      
      return AgentConnectionWithStatus(
        connection: connection,
        connectedRunningServers: connectedRunningServers,
        totalConnectedServers: connection.connectedServerIds.length,
        hasActiveServers: connectedRunningServers.isNotEmpty,
      );
    }).toList();
  }

  /// Refresh all data
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _initialize();
  }
}

/// Agent connection with additional status info using existing models
class AgentConnectionWithStatus {
  final AgentConnection connection;
  final List<MCPServer> connectedRunningServers;
  final int totalConnectedServers;
  final bool hasActiveServers;

  const AgentConnectionWithStatus({
    required this.connection,
    required this.connectedRunningServers,
    required this.totalConnectedServers,
    required this.hasActiveServers,
  });
  
  int get availableToolsCount => connectedRunningServers.length * 2; // Rough estimate
}

/// Provider for simple execution state
final simpleExecutionProvider = StateNotifierProvider<SimpleExecutionNotifier, SimpleExecutionState>((ref) {
  final toolsService = ref.watch(toolsServiceProvider);
  return SimpleExecutionNotifier(toolsService);
});

/// Provider for agent connections with status
final agentConnectionsWithStatusProvider = Provider<List<AgentConnectionWithStatus>>((ref) {
  final notifier = ref.watch(simpleExecutionProvider.notifier);
  return notifier.getAgentConnectionsWithStatus();
});