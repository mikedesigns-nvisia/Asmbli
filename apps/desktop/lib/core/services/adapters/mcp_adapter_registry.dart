import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mcp_adapter.dart';
import 'stdio_mcp_adapter.dart';

/// Simple in-memory registry of available adapter implementations.
class MCPAdapterRegistry {
  final Map<String, MCPAdapter> _adapters = {};

  void register(MCPAdapter adapter) {
    _adapters[adapter.id] = adapter;
  }

  MCPAdapter? byId(String id) => _adapters[id];

  List<MCPAdapter> get all => _adapters.values.toList(growable: false);
}

final mcpAdapterRegistryProvider = Provider<MCPAdapterRegistry>((ref) {
  final registry = MCPAdapterRegistry();
  // Register built-in adapters here. In production these could be
  // registered dynamically by feature modules.
  final stdio = StdIOAdapter();
  registry.register(stdio);
  // Initialize adapters that need it (non-blocking)
  for (final a in registry.all) {
    a.initialize();
  }
  // Note: adapters should be disposed by the app lifecycle if needed.
  return registry;
});
