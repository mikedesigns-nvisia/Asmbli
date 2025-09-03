import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../core/services/mcp_health_monitor.dart';
import '../../../settings/presentation/widgets/mcp_health_status_widget.dart';
import '../../../settings/presentation/widgets/mcp_server_dialog.dart';
import '../../models/agent_wizard_state.dart';


import '../../../../core/models/mcp_server_config.dart';

/// Third step of the agent wizard - MCP server selection with health monitoring
class MCPSelectionStep extends ConsumerStatefulWidget {
  final AgentWizardState wizardState;
  final VoidCallback onChanged;

  const MCPSelectionStep({
    super.key,
    required this.wizardState,
    required this.onChanged,
  });

  @override
  ConsumerState<MCPSelectionStep> createState() => _MCPSelectionStepState();
}

class _MCPSelectionStepState extends ConsumerState<MCPSelectionStep> {
  bool _showRecommendations = true;
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final mcpSettingsService = ref.watch(mcpSettingsServiceProvider);
    final healthData = ref.watch(mcpServerHealthProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step title and description
              _buildStepHeader(context),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Smart recommendations based on agent type
              if (_showRecommendations) ...[
                _buildRecommendationsSection(context),
                const SizedBox(height: SpacingTokens.xxl),
              ],
              
              // Selected MCP servers overview
              _buildSelectedServersSection(context, healthData),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Available MCP servers with health status
              _buildAvailableServersSection(context, mcpSettingsService, healthData),
              
              const SizedBox(height: SpacingTokens.lg),
              
              // Add new MCP server section
              _buildAddServerSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MCP Server Selection',
          style: TextStyles.pageTitle,
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Choose MCP servers to give your agent additional capabilities like file access, web search, or integration with external services.',
          style: TextStyles.bodyMedium.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(BuildContext context) {
    final recommendations = _getRecommendationsForAgent();
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Recommended for Your Agent',
                style: TextStyles.cardTitle,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showRecommendations = false;
                  });
                },
                icon: const Icon(Icons.close, size: 18),
                style: IconButton.styleFrom(
                  foregroundColor: ThemeColors(context).onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Based on your agent type, we recommend these MCP servers:',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          Wrap(
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.sm,
            children: recommendations.map((serverId) {
              final isSelected = widget.wizardState.selectedMCPServers.contains(serverId);
              
              return GestureDetector(
                onTap: () => _toggleServerSelection(serverId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.md,
                    vertical: SpacingTokens.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? ThemeColors(context).primary.withValues(alpha: 0.1)
                        : ThemeColors(context).surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    border: Border.all(
                      color: isSelected 
                          ? ThemeColors(context).primary
                          : ThemeColors(context).border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.add_circle_outline,
                        size: 16,
                        color: isSelected 
                            ? ThemeColors(context).primary
                            : ThemeColors(context).onSurfaceVariant,
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        _getServerDisplayName(serverId),
                        style: TextStyles.bodySmall.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected 
                              ? ThemeColors(context).primary
                              : ThemeColors(context).onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          if (recommendations.any((id) => !widget.wizardState.selectedMCPServers.contains(id))) ...[
            const SizedBox(height: SpacingTokens.lg),
            AsmblButton.secondary(
              text: 'Add All Recommended',
              icon: Icons.add,
              onPressed: () {
                for (final serverId in recommendations) {
                  if (!widget.wizardState.selectedMCPServers.contains(serverId)) {
                    widget.wizardState.addMCPServer(serverId);
                  }
                }
                widget.onChanged();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedServersSection(BuildContext context, AsyncValue<Map<String, MCPServerHealth>> healthData) {
    final selectedServers = widget.wizardState.selectedMCPServers;
    
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: ThemeColors(context).success,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Selected MCP Servers',
                style: TextStyles.cardTitle,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedServers.length} selected',
                  style: TextStyles.bodySmall.copyWith(
                    color: ThemeColors(context).primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          if (selectedServers.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.storage,
                    size: 48,
                    color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    'No MCP servers selected',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Your agent will work without MCP servers, but won\'t have access to external tools.',
                    style: TextStyles.bodySmall.copyWith(
                      color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            // List of selected servers with health status
            Column(
              children: selectedServers.map((serverId) {
                return Container(
                  margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: _buildSelectedServerCard(context, serverId, healthData),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedServerCard(BuildContext context, String serverId, AsyncValue<Map<String, MCPServerHealth>> healthData) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: ThemeColors(context).border),
      ),
      child: Row(
        children: [
          // Server icon and name
          Expanded(
            child: Row(
              children: [
                Icon(
                  _getServerIcon(serverId),
                  color: ThemeColors(context).primary,
                  size: 20,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getServerDisplayName(serverId),
                        style: TextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getServerDescription(serverId),
                        style: TextStyles.bodySmall.copyWith(
                          color: ThemeColors(context).onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Health status
          healthData.when(
            data: (healthMap) {
              final health = healthMap[serverId];
              return MCPHealthStatusWidget(
                serverId: serverId,
                compact: true,
              );
            },
            loading: () => SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(ThemeColors(context).primary),
              ),
            ),
            error: (_, __) => Icon(
              Icons.help_outline,
              size: 16,
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          const SizedBox(width: SpacingTokens.sm),
          
          // Remove button
          IconButton(
            onPressed: () => _toggleServerSelection(serverId),
            icon: const Icon(Icons.remove_circle_outline),
            style: IconButton.styleFrom(
              foregroundColor: ThemeColors(context).error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableServersSection(BuildContext context, MCPSettingsService mcpService, AsyncValue<Map<String, MCPServerHealth>> healthData) {
    final allServers = mcpService.allMCPServers;
    final availableServers = allServers.entries
        .where((entry) => !widget.wizardState.selectedMCPServers.contains(entry.key))
        .toList();

    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Available MCP Servers',
                style: TextStyles.cardTitle,
              ),
              const Spacer(),
              // Category filter
              _buildCategoryFilter(context, availableServers),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          if (availableServers.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: ThemeColors(context).success.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    'All configured servers selected',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Configure more servers in Settings or add new ones below.',
                    style: TextStyles.bodySmall.copyWith(
                      color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Grid of available servers
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3.0,
              ),
              itemCount: availableServers.length,
              itemBuilder: (context, index) {
                final entry = availableServers[index];
                return _buildAvailableServerCard(context, entry.key, entry.value, healthData);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailableServerCard(BuildContext context, String serverId, MCPServerConfig config, AsyncValue<Map<String, MCPServerHealth>> healthData) {
    return GestureDetector(
      onTap: () => _toggleServerSelection(serverId),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: ThemeColors(context).surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          border: Border.all(color: ThemeColors(context).border),
        ),
        child: Row(
          children: [
            // Add button
            Icon(
              Icons.add_circle_outline,
              color: ThemeColors(context).primary,
              size: 20,
            ),
            
            const SizedBox(width: SpacingTokens.sm),
            
            // Server info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    config.name ?? serverId,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ...[
                  Text(
                    config.description ?? '',
                    style: TextStyles.bodySmall.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                ],
              ),
            ),
            
            // Health status
            healthData.when(
              data: (healthMap) {
                final health = healthMap[serverId];
                return MCPHealthStatusWidget(
                  serverId: serverId,
                  compact: true,
                );
              },
              loading: () => SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(ThemeColors(context).primary),
                ),
              ),
              error: (_, __) => Icon(
                Icons.help_outline,
                size: 16,
                color: ThemeColors(context).onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, List<MapEntry<String, MCPServerConfig>> servers) {
    final categories = ['All', 'Development', 'Productivity', 'Integration', 'Other'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeColors(context).surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                style: TextStyles.bodySmall,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildAddServerSection(BuildContext context) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_circle,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Add New MCP Server',
                style: TextStyles.cardTitle,
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Don\'t see the server you need? Add a new MCP server configuration.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          Row(
            children: [
              AsmblButton.primary(
                text: 'Add MCP Server',
                icon: Icons.add,
                onPressed: () => _showAddServerDialog(),
              ),
              const SizedBox(width: SpacingTokens.sm),
              AsmblButton.secondary(
                text: 'Browse Templates',
                icon: Icons.dashboard_outlined,
                onPressed: () => _showServerTemplates(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleServerSelection(String serverId) {
    if (widget.wizardState.selectedMCPServers.contains(serverId)) {
      widget.wizardState.removeMCPServer(serverId);
    } else {
      widget.wizardState.addMCPServer(serverId);
    }
    widget.onChanged();
  }

  List<String> _getRecommendationsForAgent() {
    final agentRole = widget.wizardState.agentRole.toLowerCase();
    final agentName = widget.wizardState.agentName.toLowerCase();
    final systemPrompt = widget.wizardState.systemPrompt.toLowerCase();
    
    final recommendations = <String>[];
    
    // Development-related recommendations
    if (agentRole.contains('developer') || agentRole.contains('engineer') || 
        systemPrompt.contains('code') || systemPrompt.contains('programming')) {
      recommendations.addAll(['filesystem', 'git', 'memory']);
    }
    
    // Product management recommendations
    if (agentRole.contains('product') || agentRole.contains('manager') ||
        systemPrompt.contains('project') || systemPrompt.contains('planning')) {
      recommendations.addAll(['memory', 'http']);
    }
    
    // Research and analysis recommendations
    if (agentRole.contains('research') || agentRole.contains('analyst') ||
        systemPrompt.contains('research') || systemPrompt.contains('analysis')) {
      recommendations.addAll(['memory', 'http']);
    }
    
    // Creative writing recommendations
    if (agentRole.contains('writer') || agentRole.contains('creative') ||
        systemPrompt.contains('writing') || systemPrompt.contains('content')) {
      recommendations.addAll(['filesystem', 'memory']);
    }
    
    // Always recommend memory for persistent context
    if (!recommendations.contains('memory')) {
      recommendations.add('memory');
    }
    
    return recommendations.toSet().toList();
  }

  String _getServerDisplayName(String serverId) {
    switch (serverId) {
      case 'filesystem': return 'File System';
      case 'git': return 'Git Version Control';
      case 'memory': return 'Memory & Context';
      case 'http': return 'HTTP & Web API';
      case 'github': return 'GitHub Integration';
      case 'postgres': return 'PostgreSQL Database';
      case 'slack': return 'Slack Integration';
      case 'notion': return 'Notion Workspace';
      default: return serverId.split('-').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  String _getServerDescription(String serverId) {
    switch (serverId) {
      case 'filesystem': return 'Read, write, and manage files and directories';
      case 'git': return 'Version control operations and repository management';
      case 'memory': return 'Persistent context and conversation memory';
      case 'http': return 'Make HTTP requests and API calls';
      case 'github': return 'GitHub repositories, issues, and pull requests';
      case 'postgres': return 'PostgreSQL database queries and operations';
      case 'slack': return 'Send messages and interact with Slack';
      case 'notion': return 'Read and write Notion pages and databases';
      default: return 'MCP server providing additional capabilities';
    }
  }

  IconData _getServerIcon(String serverId) {
    switch (serverId) {
      case 'filesystem': return Icons.folder;
      case 'git': return Icons.source;
      case 'memory': return Icons.memory;
      case 'http': return Icons.http;
      case 'github': return Icons.code;
      case 'postgres': return Icons.storage;
      case 'slack': return Icons.chat;
      case 'notion': return Icons.note;
      default: return Icons.extension;
    }
  }

  void _showAddServerDialog() {
    showDialog(
      context: context,
      builder: (context) => const MCPServerDialog(),
    );
  }

  void _showServerTemplates() {
    // Navigate to server templates or show template selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Templates'),
        content: const Text('Server template browser would go here'),
        actions: [
          AsmblButton.secondary(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}