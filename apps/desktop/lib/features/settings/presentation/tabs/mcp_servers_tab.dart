import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../../../../core/services/mcp_servers_notifier.dart';
import '../../../../core/services/adapters/mcp_adapter_registry.dart';
import '../../../../core/services/mcp_registry.dart';
import '../../../../core/services/mcp_adapter.dart' as adapter;
import '../../../../core/models/mcp_server_config.dart';

class MCPServersTab extends ConsumerWidget {
  const MCPServersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final asyncServers = ref.watch(mcpServersProvider);
  final adapterRegistry = ref.watch(mcpAdapterRegistryProvider);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('MCP Servers', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 12),
                Expanded(child: Text('Manage and test your MCP servers', style: Theme.of(context).textTheme.bodyMedium)),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Server'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: asyncServers.when(
                data: (servers) {
                  if (servers.isEmpty) {
                    return const Center(child: Text('No MCP servers configured. Add one to get started.'));
                  }
                  return ListView.separated(
                    itemCount: servers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final key = servers.keys.elementAt(idx);
                      final cfg = servers[key];
                      final adapterImpl = _selectAdapterForConfig(adapterRegistry, cfg);
                      return _ServerCard(
                        id: key,
                        rawConfig: cfg,
                        adapterImpl: adapterImpl,
                        onRemove: () => ref.read(mcpRegistryProvider).removeServerAsync(ref, key),
                        onEdit: () => _showEditDialog(context, ref, key, cfg, adapterRegistry),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Failed to load MCP servers: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  adapter.MCPAdapter? _selectAdapterForConfig(MCPAdapterRegistry registry, dynamic cfg) {
    try {
      if (cfg is String) {
        try {
          final decoded = json.decode(cfg);
          if (decoded is Map && decoded['adapter'] != null) {
            return registry.byId(decoded['adapter'].toString());
          }
        } catch (_) {}
      } else if (cfg is Map && cfg['adapter'] != null) {
        return registry.byId(cfg['adapter'].toString());
      }
    } catch (_) {}
    // fallback to first available adapter
  return registry.all.isNotEmpty ? registry.all.first : null;
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        final idCtrl = TextEditingController();
        final cfgCtrl = TextEditingController();
        final adapterRegistry = ref.read(mcpAdapterRegistryProvider);
        String selectedAdapter = adapterRegistry.all.isNotEmpty ? adapterRegistry.all.first.id : '';

        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Add MCP Server'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Server id')),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Adapter'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedAdapter.isEmpty ? null : selectedAdapter,
                      items: adapterRegistry.all.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                      onChanged: (v) => setState(() => selectedAdapter = v ?? ''),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(controller: cfgCtrl, decoration: const InputDecoration(labelText: 'Config (JSON string)'), maxLines: 4),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final id = idCtrl.text.trim();
                  final raw = cfgCtrl.text.trim();
                  if (id.isEmpty || raw.isEmpty) return;
                  final registry = ref.read(mcpRegistryProvider);
                  MCPServerConfig config;
                  try {
                    final parsed = json.decode(raw);
                    if (parsed is Map<String, dynamic>) {
                      if (selectedAdapter.isNotEmpty) parsed['transport'] = selectedAdapter;
                      config = MCPServerConfig.fromJson(parsed);
                    } else {
                      config = MCPServerConfig(
                        id: id,
                        name: id,
                        url: raw.startsWith('http') ? raw : 'stdio://localhost',
                        command: raw.startsWith('http') ? '' : raw,
                        args: [],
                        description: id,
                        createdAt: DateTime.now(),
                        transport: selectedAdapter.isNotEmpty ? selectedAdapter : null,
                      );
                    }
                  } catch (_) {
                    config = MCPServerConfig(
                      id: id,
                      name: id,
                      url: raw.startsWith('http') ? raw : 'stdio://localhost',
                      command: raw.startsWith('http') ? '' : raw,
                      args: [],
                      description: id,
                      createdAt: DateTime.now(),
                      transport: selectedAdapter.isNotEmpty ? selectedAdapter : null,
                    );
                  }
                  await registry.setServerAsync(ref, id, config);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }
}


class _ServerCard extends StatefulWidget {
  final String id;
  final dynamic rawConfig;
  final adapter.MCPAdapter? adapterImpl;
  final VoidCallback onRemove;
  final VoidCallback? onEdit;

  const _ServerCard({required this.id, required this.rawConfig, required this.adapterImpl, required this.onRemove, this.onEdit});

  @override
  State<_ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<_ServerCard> {
  late Future<adapter.MCPServerStatus?> _statusFut;
  late Future<adapter.MCPCapabilities?> _capsFut;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadStatusAndCapabilities();
  }

  void _loadStatusAndCapabilities() {
    final adapterImpl = widget.adapterImpl;
    if (adapterImpl != null) {
      _statusFut = (() async {
        try {
          return await adapterImpl.testConnection(widget.rawConfig);
        } catch (_) {
          return null;
        }
      })();

      _capsFut = (() async {
        try {
          return await adapterImpl.getCapabilities(widget.rawConfig);
        } catch (_) {
          return null;
        }
      })();
    } else {
      _statusFut = Future.value(null);
      _capsFut = Future.value(null);
    }
  }

  String _prettyConfig(dynamic raw) {
    if (raw is String) {
      try {
        final decoded = json.decode(raw);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return raw.length > 200 ? '${raw.substring(0, 200)}…' : raw;
      }
    } else {
      try {
        return const JsonEncoder.withIndent('  ').convert(raw);
      } catch (_) {
        return raw.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfgPreview = _prettyConfig(widget.rawConfig);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            FutureBuilder<adapter.MCPServerStatus?>(
              future: _statusFut,
              builder: (context, snap) {
                final status = snap.data;
                final healthy = status?.healthy ?? false;
                final color = snap.connectionState == ConnectionState.waiting ? Colors.grey : (healthy ? Colors.green : Colors.red);
                return CircleAvatar(radius: 18, backgroundColor: color, child: const Icon(Icons.storage, color: Colors.white, size: 18));
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(widget.id, style: Theme.of(context).textTheme.titleMedium)),
                      FutureBuilder<adapter.MCPCapabilities?>(
                        future: _capsFut,
                        builder: (context, snap) {
                          final caps = snap.data?.capabilities ?? [];
                          if (snap.connectionState == ConnectionState.waiting) return const SizedBox();
                          return Wrap(
                            spacing: 6,
                            children: caps.map((c) => Chip(label: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(cfgPreview, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<adapter.MCPServerStatus?>(
                    future: _statusFut,
                    builder: (context, snap) {
                      final status = snap.data;
                      final text = status?.message ?? 'Not tested';
                      return Text(text, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant));
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: cfgPreview));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Config copied to clipboard')));
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          setState(() => _isTesting = true);
                          try {
                            // re-run status and show result
                            setState(() {
                              _loadStatusAndCapabilities();
                            });
                            final status = await _statusFut;
                            final msg = status?.message ?? (status?.healthy == true ? 'OK' : 'No response');
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test result: $msg')));
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test failed')));
                          } finally {
                            setState(() => _isTesting = false);
                          }
                        },
                        icon: _isTesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow),
                        label: _isTesting ? const Text('Testing...') : const Text('Test'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(88, 36)),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                            title: const Text('Remove server?'),
                            content: Text('Remove "${widget.id}" from MCP servers?'),
                            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove'))],
                          ));
                          if (confirm == true) widget.onRemove();
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  void _showEditDialog(BuildContext context, WidgetRef ref, String id, dynamic cfg, MCPAdapterRegistry registry) {
    showDialog(
      context: context,
      builder: (ctx) {
        final idCtrl = TextEditingController(text: id);
        final cfgCtrl = TextEditingController(text: cfg is String ? cfg : json.encode(cfg));
        String selectedAdapter = registry.all.isNotEmpty ? registry.all.first.id : '';

        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Edit MCP Server'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Server id')),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Adapter'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedAdapter.isEmpty ? null : selectedAdapter,
                      items: registry.all.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                      onChanged: (v) => setState(() => selectedAdapter = v ?? ''),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cfgCtrl,
                  decoration: const InputDecoration(labelText: 'Config (JSON)'),
                  maxLines: 6,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final newId = idCtrl.text.trim();
                  final raw = cfgCtrl.text.trim();
                  if (newId.isEmpty || raw.isEmpty) return;

                  MCPServerConfig config;
                  try {
                    final parsed = json.decode(raw);
                    if (parsed is Map<String, dynamic>) {
                      // ensure adapter field is present when user selected one
                      if (selectedAdapter.isNotEmpty) parsed['transport'] = selectedAdapter;
                      config = MCPServerConfig.fromJson(parsed);
                    } else {
                      config = MCPServerConfig(
                        id: newId,
                        name: newId,
                        url: raw.startsWith('http') ? raw : 'stdio://localhost',
                        command: raw.startsWith('http') ? '' : raw,
                        args: [],
                        description: newId,
                        createdAt: DateTime.now(),
                        transport: selectedAdapter.isNotEmpty ? selectedAdapter : null,
                      );
                    }
                  } catch (_) {
                    config = MCPServerConfig(
                      id: newId,
                      name: newId,
                      url: raw.startsWith('http') ? raw : 'stdio://localhost',
                      command: raw.startsWith('http') ? '' : raw,
                      args: [],
                      description: newId,
                      createdAt: DateTime.now(),
                      transport: selectedAdapter.isNotEmpty ? selectedAdapter : null,
                    );
                  }

                  await ref.read(mcpRegistryProvider).setServerAsync(ref, newId, config);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }
