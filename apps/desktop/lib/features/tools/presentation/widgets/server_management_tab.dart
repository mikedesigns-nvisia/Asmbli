import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../models/mcp_server.dart';
import '../providers/tools_provider.dart';
import 'mcp_script_terminal.dart';

class ServerManagementTab extends ConsumerWidget {
  const ServerManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final state = ref.watch(toolsProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.installedServers.isEmpty) {
      return _buildEmptyState(colors, ref);
    }

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My MCP Servers',
                style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
              ),
              const Spacer(),
              AsmblButton.secondary(
                text: 'Refresh',
                icon: Icons.refresh,
                onPressed: () => ref.read(toolsProvider.notifier).refresh(),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          Expanded(
            child: ListView(
              children: [
                // MCP Script Terminal
                const MCPScriptTerminal(),
                const SizedBox(height: SpacingTokens.lg),
                
                // Server cards
                ...state.installedServers.map((server) => 
                  _buildServerCard(context, ref, colors, server)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'My MCP Servers',
                style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
              ),
              const Spacer(),
              AsmblButton.secondary(
                text: 'Refresh',
                icon: Icons.refresh,
                onPressed: () => ref.read(toolsProvider.notifier).refresh(),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          Expanded(
            child: ListView(
              children: [
                // MCP Script Terminal
                const MCPScriptTerminal(),
                
                const SizedBox(height: SpacingTokens.xxl),
                
                // Empty state content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                    ),
                    child: Icon(
                      Icons.dns_outlined,
                      size: 40,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  Text(
                    'No MCP servers installed',
                    style: TextStyles.headlineSmall.copyWith(color: colors.onSurface),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    'Browse the marketplace or use the terminal above to create your first MCP server',
                    style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(
    BuildContext context,
    WidgetRef ref,
    ThemeColors colors,
    MCPServer server,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.lg),
      child: AsmblCard(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Row(
            children: [
              _buildServerIcon(colors, server),
              const SizedBox(width: SpacingTokens.lg),
              Expanded(
                child: _buildServerInfo(colors, server),
              ),
              const SizedBox(width: SpacingTokens.lg),
              _buildServerActions(context, ref, server),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerIcon(ThemeColors colors, MCPServer server) {
    final isRunning = server.isRunning;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: (isRunning ? colors.success : colors.onSurfaceVariant)
            .withOpacity( 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: (isRunning ? colors.success : colors.onSurfaceVariant)
              .withOpacity( 0.2),
        ),
      ),
      child: Icon(
        Icons.dns,
        color: isRunning ? colors.success : colors.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  Widget _buildServerInfo(ThemeColors colors, MCPServer server) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                server.name,
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (server.isOfficial)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  'OFFICIAL',
                  style: TextStyles.caption.copyWith(
                    color: colors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          server.description,
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: SpacingTokens.sm),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: (server.isRunning ? colors.success : colors.onSurfaceVariant)
                    .withOpacity( 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: server.isRunning ? colors.success : colors.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    server.isRunning ? 'Running' : 'Stopped',
                    style: TextStyles.caption.copyWith(
                      color: server.isRunning ? colors.success : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (server.autoStart) ...[
              const SizedBox(width: SpacingTokens.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  'Auto-start',
                  style: TextStyles.caption.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildServerActions(BuildContext context, WidgetRef ref, MCPServer server) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            if (server.isRunning) {
              ref.read(toolsProvider.notifier).stopServer(server.id);
            } else {
              ref.read(toolsProvider.notifier).startServer(server.id);
            }
          },
          icon: Icon(server.isRunning ? Icons.stop : Icons.play_arrow),
          tooltip: server.isRunning ? 'Stop' : 'Start',
        ),
        IconButton(
          onPressed: () => _showConfigDialog(context, ref, server),
          icon: const Icon(Icons.settings),
          tooltip: 'Configure',
        ),
        PopupMenuButton<String>(
          onSelected: (action) => _handleServerAction(context, ref, server, action),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restart',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: SpacingTokens.sm),
                  Text('Restart'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'uninstall',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: SpacingTokens.sm),
                  Text('Uninstall', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  void _showConfigDialog(BuildContext context, WidgetRef ref, MCPServer server) {
    showDialog(
      context: context,
      builder: (context) => _ServerConfigDialog(
        server: server,
        onSave: (updatedServer) {
          ref.read(toolsProvider.notifier).updateServerConfig(updatedServer);
        },
      ),
    );
  }

  void _handleServerAction(
    BuildContext context,
    WidgetRef ref,
    MCPServer server,
    String action,
  ) {
    switch (action) {
      case 'restart':
        ref.read(toolsProvider.notifier).stopServer(server.id).then((_) {
          Future.delayed(const Duration(seconds: 1), () {
            ref.read(toolsProvider.notifier).startServer(server.id);
          });
        });
        break;
      case 'uninstall':
        _showUninstallDialog(context, ref, server);
        break;
    }
  }

  void _showUninstallDialog(BuildContext context, WidgetRef ref, MCPServer server) {
    final colors = ThemeColors(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Uninstall Server',
          style: TextStyle(color: colors.onSurface),
        ),
        content: Text(
          'Are you sure you want to uninstall "${server.name}"? This will also disconnect it from all agents.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          AsmblButton.primary(
            text: 'Uninstall',
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(toolsProvider.notifier).uninstallServer(server.id);
            },
          ),
        ],
      ),
    );
  }
}

class _ServerConfigDialog extends StatefulWidget {
  final MCPServer server;
  final Function(MCPServer) onSave;

  const _ServerConfigDialog({
    required this.server,
    required this.onSave,
  });

  @override
  State<_ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<_ServerConfigDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _commandController;
  late final TextEditingController _argsController;
  late bool _autoStart;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server.name);
    _commandController = TextEditingController(text: widget.server.command);
    _argsController = TextEditingController(text: widget.server.args.join(' '));
    _autoStart = widget.server.autoStart;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        'Configure ${widget.server.name}',
        style: TextStyle(color: colors.onSurface),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: colors.onSurface),
              decoration: InputDecoration(
                labelText: 'Server Name',
                labelStyle: TextStyle(color: colors.onSurfaceVariant),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            TextField(
              controller: _commandController,
              style: TextStyle(color: colors.onSurface),
              decoration: InputDecoration(
                labelText: 'Command',
                labelStyle: TextStyle(color: colors.onSurfaceVariant),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            TextField(
              controller: _argsController,
              style: TextStyle(color: colors.onSurface),
              decoration: InputDecoration(
                labelText: 'Arguments',
                labelStyle: TextStyle(color: colors.onSurfaceVariant),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            SwitchListTile(
              title: Text(
                'Auto-start with application',
                style: TextStyle(color: colors.onSurface),
              ),
              value: _autoStart,
              onChanged: (value) => setState(() => _autoStart = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colors.onSurfaceVariant)),
        ),
        AsmblButton.primary(
          text: 'Save',
          onPressed: _saveConfig,
        ),
      ],
    );
  }

  void _saveConfig() {
    final updatedServer = widget.server.copyWith(
      name: _nameController.text,
      command: _commandController.text,
      args: _argsController.text
          .split(' ')
          .where((arg) => arg.isNotEmpty)
          .toList(),
      autoStart: _autoStart,
    );

    widget.onSave(updatedServer);
    Navigator.of(context).pop();
  }
}