import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_connection.dart';
import '../interfaces/mcp_server_manager_interface.dart';
import 'mcp_process_manager.dart';
import 'mcp_server_lifecycle_manager.dart';
import 'production_logger.dart';

/// Enhanced MCP manager that combines process management with lifecycle management
/// Implements comprehensive server startup, health monitoring, automatic restart, and clean shutdown
@Deprecated('Will be consolidated into MCPServerService. See docs/SERVICE_CONSOLIDATION_PLAN.md')
class EnhancedMCPManager implements MCPServerManagerInterface {
  final MCPProcessManager _processManager;
  final MCPServerLifecycleManager _lifecycleManager;
  final ProductionLogger _logger;
  
  // Track which servers are under lifecycle management
  final Set<String> _managedServers = {};
  
  EnhancedMCPManager(
    this._processManager,
    this._lifecycleManager,
    this._logger,
  );

  /// Install MCP server in agent's terminal
  @override
  Future<MCPInstallResult> installServer(String agentId, String serverId) async {
    _logger.info('Installing MCP server $serverId for agent $agentId');
    return await _processManager.installServer(agentId, serverId);
  }

  /// Start MCP server with comprehensive lifecycle management
  @override
  Future<MCPServerProcess> startServer({
    required String serverId,
    required String agentId,
    required Map<String, String> credentials,
    Map<String, String>? environment,
  }) async {
    final processId = '$agentId:$serverId';
    
    _logger.info('Starting MCP server with lifecycle management: $processId');
    
    try {
      // Start server with lifecycle management
      final serverProcess = await _lifecycleManager.startServerWithLifecycleManagement(
        serverId: serverId,
        agentId: agentId,
        credentials: credentials,
        environment: environment,
      );
      
      // Track as managed server
      _managedServers.add(processId);
      
      _logger.info('Successfully started MCP server with lifecycle management: $processId');
      return serverProcess;
      
    } catch (e) {
      _logger.error('Failed to start MCP server with lifecycle management: $processId - $e');
      rethrow;
    }
  }

  /// Stop MCP server with clean shutdown procedure
  @override
  Future<bool> stopServer(String processId) async {
    _logger.info('Stopping MCP server with clean shutdown: $processId');
    
    try {
      bool success;
      
      if (_managedServers.contains(processId)) {
        // Use lifecycle manager for clean shutdown
        success = await _lifecycleManager.cleanShutdownServer(processId);
        _managedServers.remove(processId);
      } else {
        // Use basic process manager
        success = await _processManager.stopServer(processId);
      }
      
      _logger.info('MCP server stop completed: $processId (success: $success)');
      return success;
      
    } catch (e) {
      _logger.error('Error stopping MCP server: $processId - $e');
      return false;
    }
  }

  /// Get server status
  @override
  MCPServerStatus getServerStatus(String processId) {
    return _processManager.getServerStatus(processId);
  }

  /// Get running server process
  @override
  MCPServerProcess? getRunningServer(String processId) {
    return _processManager.getRunningServer(processId);
  }

  /// Get MCP connection for process
  @override
  MCPConnection? getConnection(String processId) {
    return _processManager.getConnection(processId);
  }

  /// List all servers for agent
  @override
  List<MCPServerProcess> getServersForAgent(String agentId) {
    return _processManager.getServersForAgent(agentId);
  }

  /// Get all running servers
  @override
  List<MCPServerProcess> getAllRunningServers() {
    return _processManager.getAllRunningServers();
  }

  /// Stop all servers for an agent with clean shutdown
  @override
  Future<void> stopAllServersForAgent(String agentId) async {
    _logger.info('Stopping all servers for agent: $agentId');
    
    final agentServers = getServersForAgent(agentId);
    
    // Stop servers with clean shutdown
    final stopFutures = agentServers.map((server) => stopServer(server.id));
    await Future.wait(stopFutures);
    
    _logger.info('All servers stopped for agent: $agentId');
  }

  /// Handle JSON-RPC communication
  @override
  Future<dynamic> sendMCPRequest(String processId, Map<String, dynamic> request) async {
    return await _processManager.sendMCPRequest(processId, request);
  }

  /// Emergency shutdown of all processes
  @override
  Future<void> emergencyShutdown() async {
    _logger.warning('Performing emergency shutdown of all MCP servers');
    
    // Use lifecycle manager to shutdown managed servers
    await _lifecycleManager.shutdownAllServers();
    
    // Use process manager for any remaining servers
    await _processManager.emergencyShutdown();
    
    _managedServers.clear();
    
    _logger.info('Emergency shutdown completed');
  }

  /// Get comprehensive process statistics
  @override
  Map<String, dynamic> getProcessStatistics() {
    final processStats = _processManager.getProcessStatistics();
    final lifecycleStats = _lifecycleManager.getLifecycleStatistics();
    
    return {
      'process_manager': processStats,
      'lifecycle_manager': lifecycleStats,
      'managed_servers': _managedServers.length,
      'total_servers': processStats['total_processes'] ?? 0,
    };
  }

  /// Get health status stream for a server
  Stream<MCPServerHealthStatus> getHealthStatusStream(String processId) {
    return _lifecycleManager.getHealthStatusStream(processId);
  }

  /// Get current health status for a server
  MCPServerHealthStatus? getCurrentHealthStatus(String processId) {
    return _lifecycleManager.getCurrentHealthStatus(processId);
  }

  /// Check if server is under lifecycle management
  bool isServerManaged(String processId) {
    return _managedServers.contains(processId);
  }

  /// Get list of managed servers
  List<String> getManagedServers() {
    return _managedServers.toList();
  }

  /// Dispose all resources
  @override
  Future<void> dispose() async {
    _logger.info('Disposing enhanced MCP manager');
    
    await _lifecycleManager.dispose();
    await _processManager.dispose();
    
    _managedServers.clear();
    
    _logger.info('Enhanced MCP manager disposed');
  }
}

// ==================== Riverpod Provider ====================

final enhancedMCPManagerProvider = Provider<EnhancedMCPManager>((ref) {
  final processManager = ref.read(mcpProcessManagerProvider);
  final lifecycleManager = ref.read(mcpServerLifecycleManagerProvider);
  final logger = ref.read(productionLoggerProvider);
  
  return EnhancedMCPManager(processManager, lifecycleManager, logger);
});