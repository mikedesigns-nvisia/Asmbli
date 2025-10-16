import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_settings_service.dart';

/// MCP status indicator - connects to real MCPSettingsService
class MCPStatusIndicator extends ConsumerWidget {
  const MCPStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch real MCP service - no hardcoding
    final mcpService = ref.watch(mcpSettingsServiceProvider);
    final allServers = mcpService.getAllMCPServers();
    final enabledServers = allServers.where((server) => server.enabled).toList();
    
    // Watch server statuses from real service
    final serverIds = enabledServers.map((s) => s.id).toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: enabledServers.isNotEmpty 
            ? ThemeColors(context).primary.withValues(alpha: 0.1)
            : ThemeColors(context).surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: enabledServers.isNotEmpty 
              ? ThemeColors(context).primary.withValues(alpha: 0.3)
              : ThemeColors(context).border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.extension,
            size: 16,
            color: enabledServers.isNotEmpty 
                ? ThemeColors(context).primary
                : ThemeColors(context).onSurfaceVariant,
          ),
          
          const SizedBox(width: SpacingTokens.xs),
          
          Text(
            'MCP: ${enabledServers.length}',
            style: TextStyles.bodySmall.copyWith(
              color: enabledServers.isNotEmpty 
                  ? ThemeColors(context).primary
                  : ThemeColors(context).onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          if (enabledServers.isNotEmpty) ...[
            const SizedBox(width: SpacingTokens.xs),
            
            PopupMenuButton<String>(
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: ThemeColors(context).primary,
              ),
              offset: const Offset(0, 30),
              itemBuilder: (context) {
                return [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      'MCP Servers (${enabledServers.length})',
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  ...enabledServers.map((server) {
                    // Get real server status from service
                    final status = mcpService.getMCPServerStatus(server.id);
                    final isConnected = status?.isConnected ?? false;
                    
                    return PopupMenuItem<String>(
                      value: server.id,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isConnected 
                                  ? Colors.green
                                  : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          
                          const SizedBox(width: SpacingTokens.sm),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  server.name,
                                  style: TextStyles.bodyMedium,
                                ),
                                Text(
                                  isConnected ? 'Connected' : 'Disconnected',
                                  style: TextStyles.bodySmall.copyWith(
                                    color: isConnected 
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Icon(
                            isConnected 
                                ? Icons.check_circle
                                : Icons.warning_amber,
                            size: 16,
                            color: isConnected 
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ],
                      ),
                    );
                  }),
                ];
              },
              onSelected: (serverId) {
                // Could add server-specific actions here
              },
            ),
          ],
        ],
      ),
    );
  }
}