// Minimal MCP adapter contract used by the Settings features.
// This is a lightweight scaffold: adapters implement this interface and
// the rest of the app talks to adapters via a registry/provider.

import 'dart:async';

/// Represents a set of capabilities an MCP server exposes.
class MCPCapabilities {
  final List<String> capabilities; // e.g. ['files', 'search', 'db']
  final Map<String, dynamic>? metadata;

  MCPCapabilities(this.capabilities, {this.metadata});
}

/// Lightweight status model for connection/health reporting.
class MCPServerStatus {
  final bool healthy;
  final String? message;
  final DateTime timestamp;

  MCPServerStatus({required this.healthy, this.message}) : timestamp = DateTime.now();
}

/// Adapter contract for MCP servers.
abstract class MCPAdapter {
  /// Unique adapter id (e.g. 'stdio', 'sse', 'grpc', 'websocket')
  String get id;

  /// Human friendly name
  String get name;

  /// Called once to initialize any long-lived resources.
  Future<void> initialize();

  /// Dispose the adapter and free resources.
  Future<void> dispose();


  /// Test connectivity to a server described by [config].
  /// Returns a high-level status object.
  /// [config] is intentionally typed as dynamic in this scaffold to avoid
  /// coupling to a concrete config model in early refactors.
  Future<MCPServerStatus> testConnection(dynamic config);

  /// Ask the server for capabilities (if supported).
  Future<MCPCapabilities> getCapabilities(dynamic config);

  /// Stream of health updates for the given server id (adapter-specific key).
  Stream<MCPServerStatus> healthStream(String serverId);

  /// Apply (persist/activate) a configuration for the server.
  Future<void> applyConfig(String serverId, dynamic config);
}

// Note: concrete adapters should be placed under an "adapters/" folder and
// registered with the MCPRegistry (in mcp_registry.dart).
