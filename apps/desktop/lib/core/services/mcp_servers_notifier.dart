import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mcp_registry.dart';

/// Async bridge between the in-memory MCPRegistry and the UI.
/// Exposes the current map of servers and updates when the registry changes.
final mcpServersProvider = AsyncNotifierProvider<MCPServersNotifier, Map<String, dynamic>>(
  () => MCPServersNotifier(),
);

class MCPServersNotifier extends AsyncNotifier<Map<String, dynamic>> {
  StreamSubscription<void>? _sub;

  @override
  Future<Map<String, dynamic>> build() async {
    final registry = ref.read(mcpRegistryProvider);
    // Set initial state synchronously from registry
    final initial = registry.all;
    // Listen for changes and update state
    _sub = registry.onChange.listen((_) {
      // Use AsyncValue.guard to ensure exceptions are captured
      try {
        state = AsyncData(registry.all);
      } catch (e, st) {
        state = AsyncError(e, st);
      }
    });
    ref.onDispose(() {
      _sub?.cancel();
    });
    return initial;
  }
}
