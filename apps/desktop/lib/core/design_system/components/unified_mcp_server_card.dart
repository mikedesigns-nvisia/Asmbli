import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system.dart';
import '../../services/mcp_settings_service.dart';
import '../../services/mcp_health_monitor.dart';
import '../../../features/settings/presentation/widgets/mcp_health_status_widget.dart';
import '../../constants/app_constants.dart';


import '../../models/mcp_server_config.dart';

/// Unified MCP server representation used across all screens
/// Provides consistent styling and information display
class UnifiedMCPServerCard extends ConsumerWidget {
  final String serverId;
  final MCPServerConfig? config;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final bool showHealth;
  final bool showDescription;
  final Widget? trailing;

  const UnifiedMCPServerCard({
    super.key,
    required this.serverId,
    this.config,
    this.isSelected = false,
    this.isCompact = false,
    this.onTap,
    this.onToggle,
    this.showHealth = true,
    this.showDescription = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverConfig = config ?? ref.watch(mcpSettingsServiceProvider).allMCPServers[serverId];
    final healthData = ref.watch(mcpServerHealthProvider);
    
    return GestureDetector(
      onTap: onTap ?? onToggle,
      child: Container(
        padding: EdgeInsets.all(isCompact ? SpacingTokens.sm : SpacingTokens.md),
        decoration: BoxDecoration(
          color: isSelected 
            ? ThemeColors(context).primary.withValues(alpha: 0.1) 
            : ThemeColors(context).surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          border: Border.all(
            color: isSelected 
              ? ThemeColors(context).primary 
              : ThemeColors(context).border.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isCompact ? _buildCompactLayout(context, serverConfig, healthData) 
                        : _buildFullLayout(context, serverConfig, healthData),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, MCPServerConfig? serverConfig, AsyncValue<Map<String, MCPServerHealth>> healthData) {
    return Row(
      children: [
        // Selection indicator
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isSelected 
              ? ThemeColors(context).primary 
              : ThemeColors(context).border,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: SpacingTokens.xs),
        
        // Server icon
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _getServerColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Icon(
            _getServerIcon(),
            size: 12,
            color: _getServerColor(),
          ),
        ),
        
        const SizedBox(width: SpacingTokens.xs),
        
        // Server name and status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                serverConfig?.name ?? serverId,
                style: TextStyle(
                  color: isSelected 
                    ? ThemeColors(context).primary 
                    : ThemeColors(context).onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showDescription && isSelected && serverConfig?.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  serverConfig!.description ?? 'No description',
                  style: TextStyle(
                    color: ThemeColors(context).onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        // Health status or trailing widget
        if (trailing != null) 
          trailing!
        else if (showHealth)
          _buildHealthStatus(context, healthData),
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context, MCPServerConfig? serverConfig, AsyncValue<Map<String, MCPServerHealth>> healthData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Server icon and primary info
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getServerColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: Icon(
                _getServerIcon(),
                size: 20,
                color: _getServerColor(),
              ),
            ),
            
            const SizedBox(width: SpacingTokens.md),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          serverConfig?.name ?? serverId,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                              ? ThemeColors(context).primary 
                              : ThemeColors(context).onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ThemeColors(context).primary,
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                          ),
                          child: Text(
                            'SELECTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getServerCategory(),
                    style: TextStyle(
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Health status or trailing widget
            if (trailing != null) 
              trailing!
            else if (showHealth)
              _buildHealthStatus(context, healthData),
          ],
        ),
        
        // Description
        if (showDescription && serverConfig?.description != null) ...[
          const SizedBox(height: SpacingTokens.sm),
          Text(
            serverConfig!.description!,
            style: TextStyle(
              color: ThemeColors(context).onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        // Configuration status
        if (serverConfig != null) ...[
          const SizedBox(height: SpacingTokens.sm),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 14,
                color: SemanticColors.success,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                serverConfig.enabled ? 'Configured and enabled' : 'Configured but disabled',
                style: TextStyle(
                  color: serverConfig.enabled ? SemanticColors.success : ThemeColors(context).warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: SpacingTokens.sm),
          Row(
            children: [
              Icon(
                Icons.warning_outlined,
                size: 14,
                color: ThemeColors(context).warning,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Not configured',
                style: TextStyle(
                  color: ThemeColors(context).warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHealthStatus(BuildContext context, AsyncValue<Map<String, MCPServerHealth>> healthData) {
    return healthData.when(
      data: (healthMap) => MCPHealthStatusWidget(
        serverId: serverId,
        compact: true,
      ),
      loading: () => SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1,
          valueColor: AlwaysStoppedAnimation<Color>(
            ThemeColors(context).primary.withValues(alpha: 0.6),
          ),
        ),
      ),
      error: (_, __) => Icon(
        Icons.help_outline,
        size: 14,
        color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }

  Color _getServerColor() {
    switch (serverId.toLowerCase()) {
      case 'github':
      case 'git':
        return const Color(BrandColors.github);
      case 'postgres':
      case 'database':
        return const Color(BrandColors.database);
      case 'files':
      case 'filesystem':
        return const Color(BrandColors.api);
      case 'memory':
        return const Color(BrandColors.storage);
      case 'brave-search':
      case 'search':
        return const Color(BrandColors.notification);
      case 'slack':
        return const Color(0xFF4A154B);
      case 'notion':
        return const Color(0xFF000000);
      case 'linear':
        return const Color(0xFF5E6AD2);
      case 'figma':
        return const Color(0xFFF24E1E);
      case 'time':
      case 'scheduler':
        return const Color(0xFF2196F3);
      default:
        return SemanticColors.primary;
    }
  }

  IconData _getServerIcon() {
    switch (serverId.toLowerCase()) {
      case 'github':
      case 'git':
        return Icons.code;
      case 'postgres':
      case 'database':
        return Icons.storage;
      case 'files':
      case 'filesystem':
        return Icons.folder;
      case 'memory':
        return Icons.memory;
      case 'brave-search':
      case 'search':
        return Icons.search;
      case 'slack':
        return Icons.chat;
      case 'notion':
        return Icons.note;
      case 'linear':
        return Icons.assignment;
      case 'figma':
        return Icons.design_services;
      case 'time':
      case 'scheduler':
        return Icons.schedule;
      default:
        return Icons.extension;
    }
  }

  String _getServerCategory() {
    switch (serverId.toLowerCase()) {
      case 'github':
      case 'git':
        return 'Development';
      case 'postgres':
      case 'database':
        return 'Database';
      case 'files':
      case 'filesystem':
        return 'File System';
      case 'memory':
        return 'Data Storage';
      case 'brave-search':
      case 'search':
        return 'Web Services';
      case 'slack':
        return 'Communication';
      case 'notion':
        return 'Productivity';
      case 'linear':
        return 'Project Management';
      case 'figma':
        return 'Design';
      case 'time':
      case 'scheduler':
        return 'Utilities';
      default:
        return 'Integration';
    }
  }
}

/// Factory methods for common use cases
extension UnifiedMCPServerCardFactory on UnifiedMCPServerCard {
  /// Create a compact card for lists and tight spaces
  static Widget compact({
    required String serverId,
    MCPServerConfig? config,
    bool isSelected = false,
    VoidCallback? onToggle,
    bool showHealth = true,
    Widget? trailing,
  }) {
    return UnifiedMCPServerCard(
      serverId: serverId,
      config: config,
      isSelected: isSelected,
      isCompact: true,
      onToggle: onToggle,
      showHealth: showHealth,
      showDescription: false,
      trailing: trailing,
    );
  }

  /// Create a full card for selection screens
  static Widget selectable({
    required String serverId,
    MCPServerConfig? config,
    bool isSelected = false,
    VoidCallback? onTap,
    bool showHealth = true,
  }) {
    return UnifiedMCPServerCard(
      serverId: serverId,
      config: config,
      isSelected: isSelected,
      isCompact: false,
      onTap: onTap,
      showHealth: showHealth,
      showDescription: true,
    );
  }

  /// Create an informational card for status displays
  static Widget info({
    required String serverId,
    MCPServerConfig? config,
    bool showHealth = true,
    Widget? trailing,
  }) {
    return UnifiedMCPServerCard(
      serverId: serverId,
      config: config,
      isSelected: false,
      isCompact: false,
      showHealth: showHealth,
      showDescription: true,
      trailing: trailing,
    );
  }
}