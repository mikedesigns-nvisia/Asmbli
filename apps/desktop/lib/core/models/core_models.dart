// Core Models Export File
// This file exports all the core data models and interfaces for the agent-terminal architecture

// Core Models
export 'agent_terminal.dart';
export 'mcp_server_process.dart';
export 'mcp_catalog_entry.dart';
export 'mcp_connection.dart';

// Interfaces
export '../interfaces/agent_terminal_manager_interface.dart';
export '../interfaces/mcp_server_manager_interface.dart';

// Re-export commonly used types for convenience
export 'agent_terminal.dart' show 
  TerminalStatus,
  TerminalOutputType,
  SecurityAction,
  ValidationResult,
  AgentTerminalConfig,
  SecurityContext,
  APIPermission,
  TerminalPermissions,
  ResourceLimits,
  CommandResult,
  CommandHistory,
  TerminalOutput,
  APICallResult,
  SecurityValidationResult,
  AgentTerminal;

export 'mcp_server_process.dart' show
  MCPServerStatus,
  MCPServerConfig,
  MCPServerProcess,
  MCPInstallResult,
  MCPTransportConfig;

export 'mcp_catalog_entry.dart' show
  MCPTransportType,
  MCPCatalogEntry;

export 'mcp_connection.dart' show
  MCPConnectionStatus,
  MCPMessage,
  MCPConnection,
  MCPStdioConnection;