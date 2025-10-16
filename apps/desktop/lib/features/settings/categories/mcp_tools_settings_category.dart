import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/models/mcp_server_config.dart';
import '../../../core/services/mcp_settings_service.dart';
import '../components/settings_field.dart';
import '../providers/settings_provider.dart';

/// MCP Tools settings category - comprehensive MCP server management
class McpToolsSettingsCategory extends ConsumerStatefulWidget {
  const McpToolsSettingsCategory({super.key});

  @override
  ConsumerState<McpToolsSettingsCategory> createState() => _McpToolsSettingsCategoryState();
}

class _McpToolsSettingsCategoryState extends ConsumerState<McpToolsSettingsCategory> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedProtocol = 'stdio';
  bool _showAddForm = false;
  bool _isLoading = false;
  String? _formError;
  
  final List<String> _availableProtocols = [
    'stdio',
    'sse',
    'http',
  ];

  final Map<String, String> _protocolDescriptions = {
    'stdio': 'Standard Input/Output - Direct process communication',
    'sse': 'Server-Sent Events - HTTP-based streaming',
    'http': 'HTTP REST - Request/response communication',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _commandController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final mcpToolsSettings = ref.watch(mcpToolsSettingsProvider);
    final mcpSettingsService = ref.watch(mcpSettingsServiceProvider);
    final allMcpServers = mcpSettingsService.getAllMCPServers();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview stats
              _buildOverviewStats(mcpToolsSettings, allMcpServers, colors),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Current MCP servers
              _buildMcpServersSection(allMcpServers, colors),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Add new server form or button
              if (_showAddForm) 
                _buildAddServerForm(colors)
              else
                _buildAddServerButton(colors),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Server health monitoring
              _buildServerHealthSection(allMcpServers, colors),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Global settings
              _buildGlobalSettingsSection(colors),
            ],
          ),
        ),
      ),
    );
  }

  /// Build overview statistics
  Widget _buildOverviewStats(dynamic mcpToolsSettings, List<MCPServerConfig> allServers, ThemeColors colors) {
    final totalCount = allServers.length;
    final enabledCount = allServers.where((server) => server.enabled).length;
    final configuredCount = allServers.where((server) => 
        server.enabled && (server.command.isNotEmpty || server.url.isNotEmpty)).length;

    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MCP Tools Overview',
              style: TextStyles.headingSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.md),
            Row(
              children: [
                _buildStatItem('Total Servers', totalCount.toString(), colors.primary, colors),
                const SizedBox(width: SpacingTokens.xl),
                _buildStatItem('Enabled', enabledCount.toString(), colors.accent, colors),
                const SizedBox(width: SpacingTokens.xl),
                _buildStatItem('Configured', configuredCount.toString(), Colors.green, colors),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(String label, String value, Color color, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyles.headingLarge.copyWith(color: color),
        ),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          label,
          style: TextStyles.labelMedium.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  /// Build MCP servers section
  Widget _buildMcpServersSection(List<MCPServerConfig> servers, ThemeColors colors) {
    return SettingsSection(
      title: 'MCP Servers',
      description: 'Manage your Model Context Protocol server configurations',
      children: [
        if (servers.isEmpty) 
          _buildEmptyState(colors)
        else
          ...servers.map((server) => _buildServerCard(server, colors)),
      ],
    );
  }

  /// Build empty state when no servers exist
  Widget _buildEmptyState(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xl),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.extension_outlined,
                size: 48,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: SpacingTokens.md),
              Text(
                'No MCP Servers Configured',
                style: TextStyles.headingSmall.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                'Add MCP servers to extend your AI agents with additional tools and capabilities.',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacingTokens.lg),
              AsmblButton.primary(
                text: 'Add MCP Server',
                icon: Icons.add,
                onPressed: () => setState(() => _showAddForm = true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual server card
  Widget _buildServerCard(MCPServerConfig server, ThemeColors colors) {
    // Get server status
    final mcpSettingsService = ref.read(mcpSettingsServiceProvider);
    final status = mcpSettingsService.getMCPServerStatus(server.id);

    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Server icon and info
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getServerStatusColor(status, colors).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Icon(
                    _getProtocolIcon(server.protocol),
                    color: _getServerStatusColor(status, colors),
                    size: 20,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                
                // Server details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            server.name,
                            style: TextStyles.labelLarge.copyWith(color: colors.onSurface),
                          ),
                          const SizedBox(width: SpacingTokens.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingTokens.sm,
                              vertical: SpacingTokens.xs,
                            ),
                            decoration: BoxDecoration(
                              color: server.enabled 
                                  ? colors.accent.withValues(alpha: 0.1)
                                  : colors.onSurfaceVariant.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                            ),
                            child: Text(
                              server.enabled ? 'Enabled' : 'Disabled',
                              style: TextStyles.captionMedium.copyWith(
                                color: server.enabled ? colors.accent : colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        '${server.protocol.toUpperCase()} • ${server.capabilities.isNotEmpty ? "${server.capabilities.length} capabilities" : "No capabilities"}',
                        style: TextStyles.captionMedium.copyWith(color: colors.onSurfaceVariant),
                      ),
                      if (server.description?.isNotEmpty == true) ...[
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          server.description!,
                          style: TextStyles.captionMedium.copyWith(color: colors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Status indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getServerStatusColor(status, colors),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: SpacingTokens.md),
            
            // Server status and details
            if (status != null) ...[
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: _getServerStatusColor(status, colors).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(
                    color: _getServerStatusColor(status, colors).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(status.status),
                      color: _getServerStatusColor(status, colors),
                      size: 16,
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    Expanded(
                      child: Text(
                        status.message ?? _getStatusMessage(status.status),
                        style: TextStyles.captionMedium.copyWith(
                          color: _getServerStatusColor(status, colors),
                        ),
                      ),
                    ),
                    Text(
                      'Last checked: ${_formatTime(status.lastChecked)}',
                      style: TextStyles.captionSmall.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SpacingTokens.md),
            ],
            
            // Action buttons
            Wrap(
              spacing: SpacingTokens.sm,
              runSpacing: SpacingTokens.sm,
              children: [
                AsmblButton.secondary(
                  text: server.enabled ? 'Disable' : 'Enable',
                  icon: server.enabled ? Icons.pause : Icons.play_arrow,
                  onPressed: () => _toggleServerEnabled(server),
                ),
                AsmblButton.outline(
                  text: 'Test',
                  icon: Icons.check_circle_outline,
                  onPressed: () => _testServer(server),
                ),
                AsmblButton.outline(
                  text: 'Edit',
                  icon: Icons.edit_outlined,
                  onPressed: () => _editServer(server),
                ),
                AsmblButton.danger(
                  text: 'Remove',
                  icon: Icons.delete_outline,
                  onPressed: () => _removeServer(server),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build add server button
  Widget _buildAddServerButton(ThemeColors colors) {
    return Center(
      child: AsmblButton.primary(
        text: 'Add MCP Server',
        icon: Icons.add,
        onPressed: () => setState(() {
          _showAddForm = true;
          _clearForm();
        }),
      ),
    );
  }

  /// Build add server form
  Widget _buildAddServerForm(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Add MCP Server',
                  style: TextStyles.headingSmall.copyWith(color: colors.onSurface),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() {
                    _showAddForm = false;
                    _clearForm();
                  }),
                  icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                ),
              ],
            ),
            
            if (_formError != null) ...[
              const SizedBox(height: SpacingTokens.md),
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(color: colors.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colors.error, size: 16),
                    const SizedBox(width: SpacingTokens.sm),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: TextStyles.captionMedium.copyWith(color: colors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: SpacingTokens.lg),
            
            // Form fields
            SettingsField(
              label: 'Server Name',
              hint: 'e.g., "File System", "Database Tools"',
              value: _nameController.text,
              required: true,
              onChanged: (value) => _nameController.text = value,
            ),
            
            const SizedBox(height: SpacingTokens.md),
            
            // Protocol dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protocol',
                  style: TextStyles.labelMedium.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    border: Border.all(color: colors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedProtocol,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
                      items: _availableProtocols.map((protocol) {
                        return DropdownMenuItem(
                          value: protocol,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getProtocolIcon(protocol),
                                    size: 16,
                                    color: colors.onSurface,
                                  ),
                                  const SizedBox(width: SpacingTokens.sm),
                                  Text(
                                    protocol.toUpperCase(),
                                    style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                                  ),
                                ],
                              ),
                              Text(
                                _protocolDescriptions[protocol] ?? '',
                                style: TextStyles.captionSmall.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedProtocol = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: SpacingTokens.md),
            
            if (_selectedProtocol != 'stdio') ...[
              SettingsField(
                label: 'Server URL',
                hint: _selectedProtocol == 'sse' 
                    ? 'e.g., "http://localhost:3000/sse"' 
                    : 'e.g., "http://localhost:8080/api"',
                value: _urlController.text,
                required: true,
                onChanged: (value) => _urlController.text = value,
              ),
              const SizedBox(height: SpacingTokens.md),
            ],
            
            if (_selectedProtocol == 'stdio') ...[
              SettingsField(
                label: 'Command',
                hint: 'e.g., "python", "node server.js"',
                value: _commandController.text,
                required: true,
                onChanged: (value) => _commandController.text = value,
              ),
              const SizedBox(height: SpacingTokens.md),
            ],
            
            SettingsField(
              label: 'Description',
              hint: 'Brief description of what this server provides',
              value: _descriptionController.text,
              maxLines: 2,
              onChanged: (value) => _descriptionController.text = value,
            ),
            
            const SizedBox(height: SpacingTokens.lg),
            
            // Form actions
            Row(
              children: [
                AsmblButton.primary(
                  text: 'Add Server',
                  icon: Icons.save,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _saveServer,
                ),
                const SizedBox(width: SpacingTokens.sm),
                AsmblButton.outline(
                  text: 'Cancel',
                  onPressed: _isLoading ? null : () => setState(() {
                    _showAddForm = false;
                    _clearForm();
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build server health section
  Widget _buildServerHealthSection(List<MCPServerConfig> servers, ThemeColors colors) {
    return SettingsSection(
      title: 'Server Health',
      description: 'Monitor and test your MCP server connections',
      children: [
        SettingsButton(
          text: 'Test All Servers',
          description: 'Check connectivity to all configured MCP servers',
          icon: Icons.network_check,
          onPressed: _testAllServers,
        ),
        const SizedBox(height: SpacingTokens.sm),
        SettingsButton(
          text: 'Refresh Status',
          description: 'Update connection status for all servers',
          icon: Icons.refresh,
          onPressed: _refreshAllStatuses,
        ),
      ],
    );
  }

  /// Build global settings section
  Widget _buildGlobalSettingsSection(ThemeColors colors) {
    return SettingsSection(
      title: 'Global Settings',
      description: 'Configure global MCP server settings',
      children: [
        SettingsToggle(
          label: 'Auto-reconnect',
          description: 'Automatically reconnect to servers when connections are lost',
          value: true, // This would come from actual settings
          onChanged: (value) {
            // Handle auto-reconnect setting
          },
        ),
        const SizedBox(height: SpacingTokens.sm),
        SettingsToggle(
          label: 'Enable Health Monitoring',
          description: 'Continuously monitor server health in the background',
          value: true, // This would come from actual settings
          onChanged: (value) {
            // Handle health monitoring setting
          },
        ),
      ],
    );
  }

  /// Get protocol icon
  IconData _getProtocolIcon(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'stdio':
        return Icons.terminal;
      case 'sse':
        return Icons.stream;
      case 'http':
        return Icons.http;
      default:
        return Icons.settings_ethernet;
    }
  }

  /// Get server status color
  Color _getServerStatusColor(MCPServerStatus? status, ThemeColors colors) {
    if (status == null) return colors.onSurfaceVariant;
    
    switch (status.status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.error:
        return colors.error;
      case ConnectionStatus.warning:
        return colors.warning;
      case ConnectionStatus.disconnected:
      default:
        return colors.onSurfaceVariant;
    }
  }

  /// Get status icon
  IconData _getStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.check_circle;
      case ConnectionStatus.connecting:
        return Icons.hourglass_empty;
      case ConnectionStatus.error:
        return Icons.error;
      case ConnectionStatus.warning:
        return Icons.warning;
      case ConnectionStatus.disconnected:
      default:
        return Icons.circle_outlined;
    }
  }

  /// Get status message
  String _getStatusMessage(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.error:
        return 'Connection error';
      case ConnectionStatus.warning:
        return 'Warning';
      case ConnectionStatus.disconnected:
      default:
        return 'Disconnected';
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Clear form fields
  void _clearForm() {
    _nameController.clear();
    _urlController.clear();
    _commandController.clear();
    _descriptionController.clear();
    _selectedProtocol = 'stdio';
    _formError = null;
  }

  /// Save new server
  Future<void> _saveServer() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _formError = null;
    });

    try {
      // Validate form
      if (_nameController.text.trim().isEmpty) {
        throw Exception('Server name is required');
      }
      
      if (_selectedProtocol == 'stdio' && _commandController.text.trim().isEmpty) {
        throw Exception('Command is required for stdio protocol');
      }
      
      if (_selectedProtocol != 'stdio' && _urlController.text.trim().isEmpty) {
        throw Exception('Server URL is required for ${_selectedProtocol.toUpperCase()} protocol');
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final server = MCPServerConfig(
        id: id,
        name: _nameController.text.trim(),
        url: _urlController.text.trim(),
        command: _commandController.text.trim(),
        protocol: _selectedProtocol,
        description: _descriptionController.text.trim(),
        enabled: true,
        createdAt: DateTime.now(),
      );

      final mcpService = ref.read(mcpSettingsServiceProvider);
      await mcpService.setMCPServer(id, server);

      if (mounted) {
        setState(() {
          _showAddForm = false;
          _isLoading = false;
        });
        _clearForm();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MCP server "${server.name}" added successfully'),
            backgroundColor: ThemeColors(context).accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _formError = e.toString();
        });
      }
    }
  }

  /// Toggle server enabled/disabled
  Future<void> _toggleServerEnabled(MCPServerConfig server) async {
    try {
      final mcpService = ref.read(mcpSettingsServiceProvider);
      final updatedServer = server.copyWith(enabled: !server.enabled);
      await mcpService.setMCPServer(server.id, updatedServer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server "${server.name}" ${server.enabled ? 'disabled' : 'enabled'}'),
            backgroundColor: ThemeColors(context).accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update server: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  /// Test individual server
  Future<void> _testServer(MCPServerConfig server) async {
    try {
      final mcpService = ref.read(mcpSettingsServiceProvider);
      final status = await mcpService.testMCPServerConnection(server.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${server.name}: ${status.message ?? _getStatusMessage(status.status)}'),
            backgroundColor: status.isConnected ? ThemeColors(context).accent : ThemeColors(context).error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed for ${server.name}: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  /// Edit server (placeholder - would open edit form)
  Future<void> _editServer(MCPServerConfig server) async {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  /// Remove server
  Future<void> _removeServer(MCPServerConfig server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Server'),
        content: Text('Are you sure you want to remove "${server.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final mcpService = ref.read(mcpSettingsServiceProvider);
        await mcpService.removeMCPServer(server.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server "${server.name}" removed successfully'),
              backgroundColor: ThemeColors(context).accent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove server: $e'),
              backgroundColor: ThemeColors(context).error,
            ),
          );
        }
      }
    }
  }

  /// Test all servers
  Future<void> _testAllServers() async {
    try {
      final result = await ref.read(settingsProvider.notifier).testConnection(SettingsCategory.mcpTools);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.isSuccess ? ThemeColors(context).accent : ThemeColors(context).error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  /// Refresh all server statuses
  Future<void> _refreshAllStatuses() async {
    final mcpService = ref.read(mcpSettingsServiceProvider);
    final allServers = mcpService.getAllMCPServers();
    
    // Test all servers to refresh their status
    for (final server in allServers) {
      if (server.enabled) {
        try {
          await mcpService.testMCPServerConnection(server.id);
        } catch (e) {
          // Continue with other servers if one fails
        }
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Server statuses refreshed'),
          backgroundColor: ThemeColors(context).accent,
        ),
      );
    }
  }
}