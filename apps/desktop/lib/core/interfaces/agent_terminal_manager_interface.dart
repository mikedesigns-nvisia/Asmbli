import 'dart:async';
import '../models/agent_terminal.dart';
import '../models/mcp_server_process.dart';
import '../services/resource_monitor.dart';
import '../services/process_cleanup_service.dart';
import '../services/graceful_shutdown_service.dart';

/// Abstract interface for managing agent terminal instances
abstract class AgentTerminalManagerInterface {
  /// Create a new terminal instance for an agent
  Future<AgentTerminal> createTerminal(String agentId, AgentTerminalConfig config);
  
  /// Get existing terminal for an agent
  AgentTerminal? getTerminal(String agentId);
  
  /// Execute command in agent's terminal with security validation
  Future<CommandResult> executeCommand(
    String agentId, 
    String command, {
    bool requiresApproval = false,
  });
  
  /// Execute API call through agent's secure context
  Future<APICallResult> executeAPICall(
    String agentId, 
    String provider, 
    String model, 
    Map<String, dynamic> request,
  );
  
  /// Stream terminal output
  Stream<TerminalOutput> streamOutput(String agentId);
  
  /// Validate command against security policies
  Future<SecurityValidationResult> validateCommand(String agentId, String command);
  
  /// Destroy terminal and cleanup resources
  Future<void> destroyTerminal(String agentId);
  
  /// Get all active terminals
  List<AgentTerminal> getActiveTerminals();
  
  /// Install MCP server for agent
  Future<MCPInstallResult> installMCPServer(String agentId, String serverId);
  
  /// Get installation progress for an agent
  Stream<MCPInstallationProgress>? getInstallationProgress(String agentId);
  
  /// Check if MCP server is installed for agent
  Future<bool> isMCPServerInstalled(String agentId, String serverId);
  
  /// Uninstall MCP server from agent
  Future<bool> uninstallMCPServer(String agentId, String serverId);
  
  /// Get terminal session state for persistence
  Map<String, dynamic> getTerminalState(String agentId);
  
  /// Restore terminal session from saved state
  Future<AgentTerminal> restoreTerminalState(String agentId, Map<String, dynamic> state);
  
  /// Get command history for an agent with filtering options
  List<CommandHistory> getCommandHistory(
    String agentId, {
    int? limit,
    DateTime? since,
    bool? successfulOnly,
  });
  
  /// Clear command history for an agent
  Future<void> clearCommandHistory(String agentId);
  
  /// Get real-time terminal metrics
  Map<String, dynamic> getTerminalMetrics(String agentId);
  
  /// Get resource usage for an agent
  Future<ResourceUsage> getResourceUsage(String agentId);
  
  /// Get cleanup status for an agent
  CleanupStatus getCleanupStatus(String agentId);
  
  /// Get shutdown status for an agent
  ShutdownStatus? getShutdownStatus(String agentId);
  
  /// Dispose all resources
  Future<void> dispose();
}