import 'dart:async';
import '../models/mcp_server_process.dart';
import '../models/mcp_connection.dart';
import '../../features/agents/presentation/widgets/mcp_server_logs_widget.dart';

/// Abstract interface for managing MCP server processes
abstract class MCPServerManagerInterface {
  /// Install MCP server in agent's terminal
  Future<MCPInstallResult> installServer(String agentId, String serverId);
  
  /// Start MCP server for agent
  Future<MCPServerProcess> startServer({
    required String serverId,
    required String agentId,
    required Map<String, String> credentials,
    Map<String, String>? environment,
  });
  
  /// Stop MCP server
  Future<bool> stopServer(String processId);
  
  /// Get server status
  MCPServerStatus getServerStatus(String processId);
  
  /// Get running server process
  MCPServerProcess? getRunningServer(String processId);
  
  /// Get MCP connection for process
  MCPConnection? getConnection(String processId);
  
  /// List all servers for agent
  List<MCPServerProcess> getServersForAgent(String agentId);
  
  /// Get all running servers
  List<MCPServerProcess> getAllRunningServers();
  
  /// Stop all servers for an agent
  Future<void> stopAllServersForAgent(String agentId);
  
  /// Handle JSON-RPC communication
  Future<dynamic> sendMCPRequest(String processId, Map<String, dynamic> request);
  
  /// Emergency shutdown of all processes
  Future<void> emergencyShutdown();
  
  /// Get process statistics
  Map<String, dynamic> getProcessStatistics();
  
  /// Get server logs
  Future<List<MCPLogEntry>> getServerLogs(String serverId, {int limit = 100});

  /// Stream server logs in real-time
  Stream<MCPLogEntry> streamServerLogs(String serverId);

  /// Clear server logs
  Future<void> clearServerLogs(String serverId);

  /// Dispose all resources
  Future<void> dispose();
}