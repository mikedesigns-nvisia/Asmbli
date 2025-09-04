import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../models/mcp_server.dart';
import '../providers/tools_provider.dart';

class AgentConnectionsTab extends ConsumerWidget {
  const AgentConnectionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final state = ref.watch(toolsProvider);

    if (state.isLoading && !state.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.agentConnections.isEmpty) {
      return _buildEmptyState(colors);
    }

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agent MCP Connections',
            style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Manage which MCP servers are connected to each agent',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Expanded(
            child: ListView.builder(
              itemCount: state.agentConnections.length,
              itemBuilder: (context, index) {
                final connection = state.agentConnections[index];
                return _buildConnectionCard(context, ref, colors, connection, state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            ),
            child: Icon(
              Icons.hub_outlined,
              size: 40,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'No agent connections',
            style: TextStyles.headlineSmall.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Your agents will appear here when they connect to MCP servers',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    WidgetRef ref,
    ThemeColors colors,
    AgentConnection connection,
    ToolsState state,
  ) {
    final connectedServers = state.installedServers
        .where((server) => connection.connectedServerIds.contains(server.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.lg),
      child: AsmblCard(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      color: colors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connection.agentName,
                          style: TextStyles.bodyLarge.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          '${connection.connectedServerIds.length} MCP servers connected',
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (connection.lastUpdated != null) ...[
                          const SizedBox(height: SpacingTokens.xs),
                          Text(
                            'Last updated: ${_formatDateTime(connection.lastUpdated!)}',
                            style: TextStyles.caption.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AsmblButton.secondary(
                    text: 'Manage',
                    onPressed: () => _showConnectionDialog(context, ref, connection, state),
                  ),
                ],
              ),
              
              if (connectedServers.isNotEmpty) ...[
                const SizedBox(height: SpacingTokens.lg),
                Divider(color: colors.border.withValues(alpha: 0.3)),
                const SizedBox(height: SpacingTokens.lg),
                
                Text(
                  'Connected Servers',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                
                Wrap(
                  spacing: SpacingTokens.sm,
                  runSpacing: SpacingTokens.sm,
                  children: connectedServers.map((server) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm,
                        vertical: SpacingTokens.xs,
                      ),
                      decoration: BoxDecoration(
                        color: server.isRunning 
                            ? colors.success.withValues(alpha: 0.1)
                            : colors.onSurfaceVariant.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                        border: Border.all(
                          color: server.isRunning 
                              ? colors.success.withValues(alpha: 0.3)
                              : colors.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
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
                            server.name,
                            style: TextStyles.caption.copyWith(
                              color: server.isRunning ? colors.success : colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showConnectionDialog(
    BuildContext context,
    WidgetRef ref,
    AgentConnection connection,
    ToolsState state,
  ) {
    showDialog(
      context: context,
      builder: (context) => _ConnectionManagementDialog(
        connection: connection,
        availableServers: state.installedServers,
        onSave: (serverIds) {
          ref.read(toolsProvider.notifier)
              .updateAgentConnections(connection.agentId, serverIds);
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _ConnectionManagementDialog extends StatefulWidget {
  final AgentConnection connection;
  final List<MCPServer> availableServers;
  final Function(List<String>) onSave;

  const _ConnectionManagementDialog({
    required this.connection,
    required this.availableServers,
    required this.onSave,
  });

  @override
  State<_ConnectionManagementDialog> createState() => _ConnectionManagementDialogState();
}

class _ConnectionManagementDialogState extends State<_ConnectionManagementDialog> {
  late Set<String> selectedServerIds;

  @override
  void initState() {
    super.initState();
    selectedServerIds = Set<String>.from(widget.connection.connectedServerIds);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        'Manage ${widget.connection.agentName} Connections',
        style: TextStyle(color: colors.onSurface),
      ),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select which MCP servers this agent can access:',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: SpacingTokens.lg),
            
            if (widget.availableServers.isEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.dns_outlined,
                        size: 48,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: SpacingTokens.lg),
                      Text(
                        'No MCP servers installed',
                        style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        'Install servers from the marketplace first',
                        style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: widget.availableServers.length,
                  itemBuilder: (context, index) {
                    final server = widget.availableServers[index];
                    final isSelected = selectedServerIds.contains(server.id);
                    
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedServerIds.add(server.id);
                          } else {
                            selectedServerIds.remove(server.id);
                          }
                        });
                      },
                      title: Text(
                        server.name,
                        style: TextStyle(color: colors.onSurface),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            server.description,
                            style: TextStyle(color: colors.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: SpacingTokens.xs),
                          Row(
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
                                ),
                              ),
                              if (server.isOfficial) ...[
                                const SizedBox(width: SpacingTokens.sm),
                                Text(
                                  '• Official',
                                  style: TextStyles.caption.copyWith(
                                    color: colors.success,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      secondary: server.isRunning 
                          ? Icon(Icons.check_circle, color: colors.success)
                          : Icon(Icons.warning, color: colors.onSurfaceVariant),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colors.onSurfaceVariant)),
        ),
        AsmblButton.primary(
          text: 'Save Changes',
          onPressed: widget.availableServers.isEmpty ? null : () {
            widget.onSave(selectedServerIds.toList());
            Navigator.of(context).pop();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Updated connections for ${widget.connection.agentName}'),
                backgroundColor: colors.success,
              ),
            );
          },
        ),
      ],
    );
  }
}