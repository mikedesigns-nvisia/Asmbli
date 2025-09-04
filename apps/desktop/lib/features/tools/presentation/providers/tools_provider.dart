import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mcp_server.dart';
import '../../business/tools_service.dart';

class ToolsState {
  final List<MCPServer> installedServers;
  final List<MCPServer> availableServers;
  final List<AgentConnection> agentConnections;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const ToolsState({
    this.installedServers = const [],
    this.availableServers = const [],
    this.agentConnections = const [],
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  ToolsState copyWith({
    List<MCPServer>? installedServers,
    List<MCPServer>? availableServers,
    List<AgentConnection>? agentConnections,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return ToolsState(
      installedServers: installedServers ?? this.installedServers,
      availableServers: availableServers ?? this.availableServers,
      agentConnections: agentConnections ?? this.agentConnections,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
    );
  }
}

class ToolsNotifier extends StateNotifier<ToolsState> {
  ToolsNotifier(this._toolsService) : super(const ToolsState()) {
    _initialize();
  }

  final ToolsService _toolsService;

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _toolsService.initialize();
      
      // Listen to streams
      _toolsService.serversStream.listen((servers) {
        state = state.copyWith(installedServers: servers);
      });
      
      _toolsService.connectionsStream.listen((connections) {
        state = state.copyWith(agentConnections: connections);
      });

      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        availableServers: _toolsService.availableServers,
        installedServers: _toolsService.installedServers,
        agentConnections: _toolsService.agentConnections,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _initialize();
  }

  Future<void> installServer(String serverId) async {
    try {
      await _toolsService.installServer(serverId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> uninstallServer(String serverId) async {
    try {
      await _toolsService.uninstallServer(serverId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> startServer(String serverId) async {
    try {
      await _toolsService.startServer(serverId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopServer(String serverId) async {
    try {
      await _toolsService.stopServer(serverId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateServerConfig(MCPServer server) async {
    try {
      await _toolsService.updateServerConfig(server);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateAgentConnections(String agentId, List<String> serverIds) async {
    try {
      await _toolsService.updateAgentConnections(agentId, serverIds);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final toolsServiceProvider = Provider<ToolsService>((ref) => ToolsService());

final toolsProvider = StateNotifierProvider<ToolsNotifier, ToolsState>((ref) {
  return ToolsNotifier(ref.read(toolsServiceProvider));
});