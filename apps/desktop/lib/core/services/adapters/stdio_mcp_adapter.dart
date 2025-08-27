import 'dart:async';

import '../mcp_adapter.dart';

/// Simple scaffold adapter that simulates a local stdio-based MCP server.
/// This is a safe, non-production stub intended to be used for UI wiring
/// and local testing while real adapters are implemented.
class StdIOAdapter implements MCPAdapter {
  @override
  String get id => 'stdio';

  @override
  String get name => 'StdIO Adapter (stub)';

  Timer? _timer;

  @override
  Future<void> initialize() async {
    // No-op for stub
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
  }

  @override
  Future<MCPServerStatus> testConnection(dynamic config) async {
    // Simulate a small delay and return a healthy status for simple configs.
    await Future.delayed(const Duration(milliseconds: 250));
    return MCPServerStatus(healthy: true, message: 'StdIO stub connected');
  }

  @override
  Future<MCPCapabilities> getCapabilities(dynamic config) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return MCPCapabilities(['files', 'search'], metadata: {'adapter': id});
  }

  @override
  Stream<MCPServerStatus> healthStream(String serverId) {
    // Emit a periodic healthy status. Consumers can stop listening to cancel.
    return Stream.periodic(const Duration(seconds: 5), (_) {
      return MCPServerStatus(healthy: true, message: 'heartbeat');
    });
  }

  @override
  Future<void> applyConfig(String serverId, dynamic config) async {
    // No persistence in stub. Short delay to simulate work.
    await Future.delayed(const Duration(milliseconds: 150));
  }
}
