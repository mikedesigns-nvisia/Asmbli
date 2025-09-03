import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mcp_settings_service.dart';


import '../models/mcp_server_config.dart';

// If the real MCPServerConfig type is provided by another package, import it
// there instead. We reference agent_engine_core above which may provide it.
// This file assumes a compatible MCPServerConfig exists. If not, add a
// thin wrapper type in your service layer.

/// In-memory registry used as a single source of truth for MCP servers.
class MCPRegistry {
  final Map<String, MCPServerConfig> _servers = {};
  final StreamController<void> _onChange = StreamController.broadcast();

  Stream<void> get onChange => _onChange.stream;

  Map<String, MCPServerConfig> get all => Map.unmodifiable(_servers);

  /// In-memory set (local only) — use [setServerAsync] to persist via service.
  void setServer(String id, MCPServerConfig config) {
    _servers[id] = config;
    _onChange.add(null);
  }

  /// In-memory remove (local only) — use [removeServerAsync] to persist via service.
  void removeServer(String id) {
    _servers.remove(id);
    _onChange.add(null);
  }

  MCPServerConfig? getServer(String id) => _servers[id];

  /// Persistently add/update a server via the settings service and update registry.
  Future<void> setServerAsync(WidgetRef ref, String id, MCPServerConfig config) async {
    final svc = ref.read(mcpSettingsServiceProvider);
    await svc.setMCPServer(id, config);
    setServer(id, config);
  }

  /// Persistently remove a server via the settings service and update registry.
  Future<void> removeServerAsync(WidgetRef ref, String id) async {
    final svc = ref.read(mcpSettingsServiceProvider);
    await svc.removeMCPServer(id);
    removeServer(id);
  }
}

final mcpRegistryProvider = Provider<MCPRegistry>((ref) {
  final registry = MCPRegistry();
  final svc = ref.read(mcpSettingsServiceProvider);

  // Hydrate existing servers synchronously from the service
  try {
    final existing = svc.allMCPServers; // Map<String, MCPServerConfig>
    existing.forEach((k, v) => registry.setServer(k, v));
  } catch (_) {
    // Ignore hydrate errors; registry will start empty.
  }

  // No automatic persistence loop here: UI should call setServerAsync/removeServerAsync
  // to perform service-backed operations. We keep onChange for listeners.

  return registry;
});
