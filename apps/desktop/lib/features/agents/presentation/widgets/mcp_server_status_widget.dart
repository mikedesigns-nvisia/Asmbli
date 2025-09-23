import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/mcp_server_process.dart';
import '../../../../core/services/agent_mcp_integration_service.dart';
import '../../../../core/di/service_locator.dart';

/// Widget that displays MCP server status for an agent
class MCPServerStatusWidget extends ConsumerStatefulWidget {
  final String agentId;
  final bool showInstallButton;

  const MCPServerStatusWidget({
    super.key,
    required this.agentId,
    this.showInstallButton = true,
  });

  @override
  ConsumerState<MCPServerStatusWidget> createState() => _MCPServerStatusWidgetState();
}

class _MCPServerStatusWidgetState extends ConsumerState<MCPServerStatusWidget> {
  AgentMCPIntegrationService? _integrationService;
  List<MCPServerProcess> _servers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadServers();
  }

  void _initializeService() {
    try {
      _integrationService = ServiceLocator.instance.get<AgentMCPIntegrationService>();
    } catch (e) {
      print('Failed to initialize integration service: $e');
    }
  }

  void _loadServers() {
    if (_integrationService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final servers = _integrationService!.getAgentMCPServers(widget.agentId);
      setState(() {
        _servers = servers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Failed to load MCP servers: $e');
    }
  }

  Future<void> _installServer(String serverId) async {
    if (_integrationService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _integrationService!.installMCPServerForAgent(widget.agentId, serverId);
      _loadServers(); // Reload to show new server
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MCP server "$serverId" installed successfully'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to install MCP server: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  Future<void> _removeServer(String serverId) async {
    if (_integrationService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _integrationService!.removeMCPServerFromAgent(widget.agentId, serverId);
      _loadServers(); // Reload to remove server from list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MCP server "$serverId" removed successfully'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove MCP server: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BorderRadiusTokens.md),
                topRight: Radius.circular(BorderRadiusTokens.md),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.extension,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  'MCP Servers',
                  style: TextStyles.labelLarge.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                else
                  IconButton(
                    onPressed: _loadServers,
                    icon: Icon(
                      Icons.refresh,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    tooltip: 'Refresh',
                  ),
              ],
            ),
          ),

          // Server list
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: _servers.isEmpty
                ? _buildEmptyState(colors)
                : Column(
                    children: _servers.map((server) => _buildServerItem(server, colors)).toList(),
                  ),
          ),

          // Install button
          if (widget.showInstallButton)
            Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: AsmblButton.outline(
                text: 'Install MCP Server',
                icon: Icons.add,
                onPressed: _isLoading ? null : () => _showInstallDialog(context),
                size: AsmblButtonSize.small,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.extension_off,
            size: 32,
            color: colors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'No MCP servers installed',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Install MCP servers to give your agent access to tools',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServerItem(MCPServerProcess server, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: _getStatusColor(server.status, colors).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(server.status, colors),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          
          // Server info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server.displayName,
                  style: TextStyles.labelMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs_precise),
                Text(
                  _getStatusText(server.status),
                  style: TextStyles.bodySmall.copyWith(
                    color: _getStatusColor(server.status, colors),
                  ),
                ),
                if (server.uptime.inSeconds > 0)
                  Text(
                    'Uptime: ${_formatDuration(server.uptime)}',
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          
          // Actions
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              size: 16,
              color: colors.onSurfaceVariant,
            ),
            onSelected: (action) {
              switch (action) {
                case 'remove':
                  _removeServer(server.serverId);
                  break;
                case 'restart':
                  // TODO: Implement restart functionality
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'restart',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, size: 16),
                    SizedBox(width: 8),
                    Text('Restart'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16),
                    SizedBox(width: 8),
                    Text('Remove'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MCPServerStatus status, ThemeColors colors) {
    switch (status) {
      case MCPServerStatus.running:
        return colors.success;
      case MCPServerStatus.starting:
        return colors.warning;
      case MCPServerStatus.stopped:
      case MCPServerStatus.stopping:
        return colors.onSurfaceVariant;
      case MCPServerStatus.error:
      case MCPServerStatus.crashed:
      case MCPServerStatus.failed:
        return colors.error;
    }
  }

  String _getStatusText(MCPServerStatus status) {
    switch (status) {
      case MCPServerStatus.running:
        return 'Running';
      case MCPServerStatus.starting:
        return 'Starting...';
      case MCPServerStatus.stopping:
        return 'Stopping...';
      case MCPServerStatus.stopped:
        return 'Stopped';
      case MCPServerStatus.error:
        return 'Error';
      case MCPServerStatus.crashed:
        return 'Crashed';
      case MCPServerStatus.failed:
        return 'Failed';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  void _showInstallDialog(BuildContext context) {
    final availableServers = [
      'filesystem',
      'git',
      'github',
      'postgres',
      'sqlite',
      'brave-search',
      'memory',
      'fetch',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Install MCP Server'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableServers.map((serverId) {
              return ListTile(
                title: Text(serverId),
                subtitle: Text(_getServerDescription(serverId)),
                onTap: () {
                  Navigator.of(context).pop();
                  _installServer(serverId);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getServerDescription(String serverId) {
    switch (serverId) {
      case 'filesystem':
        return 'File system access and management';
      case 'git':
        return 'Git repository operations';
      case 'github':
        return 'GitHub API integration';
      case 'postgres':
        return 'PostgreSQL database access';
      case 'sqlite':
        return 'SQLite database operations';
      case 'brave-search':
        return 'Web search with Brave Search';
      case 'memory':
        return 'Persistent memory and knowledge base';
      case 'fetch':
        return 'HTTP requests and web scraping';
      default:
        return 'MCP server integration';
    }
  }
}