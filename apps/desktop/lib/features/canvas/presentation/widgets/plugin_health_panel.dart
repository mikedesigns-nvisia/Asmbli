import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/plugin_bridge_server.dart';

/// Plugin Health Panel
/// Displays diagnostic information about the browser plugin connection
class PluginHealthPanel extends StatefulWidget {
  final PluginBridgeServer pluginBridge;

  const PluginHealthPanel({
    super.key,
    required this.pluginBridge,
  });

  @override
  State<PluginHealthPanel> createState() => _PluginHealthPanelState();
}

class _PluginHealthPanelState extends State<PluginHealthPanel> {
  bool _isExpanded = false;
  Map<String, dynamic>? _healthData;

  @override
  void initState() {
    super.initState();
    _updateHealth();

    // Listen to health updates
    widget.pluginBridge.connectionStatusStream.listen((status) {
      if (status['type'] == 'health-update' ||
          status['type'] == 'websocket' ||
          status['connected'] == false) {
        _updateHealth();
      }
    });

    // Update health every 5 seconds
    Future.delayed(const Duration(seconds: 5), _periodicUpdate);
  }

  void _periodicUpdate() {
    if (mounted) {
      _updateHealth();
      Future.delayed(const Duration(seconds: 5), _periodicUpdate);
    }
  }

  void _updateHealth() {
    if (mounted) {
      setState(() {
        _healthData = widget.pluginBridge.getHealthSummary();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final health = _healthData ?? {};
    final isHealthy = health['healthy'] as bool? ?? false;
    final pluginHealth = health['pluginHealth'] as Map<String, dynamic>?;

    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Row(
                children: [
                  // Health indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHealthy
                          ? colors.success
                          : (health['connected'] as bool? ?? false)
                              ? colors.warning
                              : colors.onSurfaceVariant.withValues(alpha: 0.3),
                      boxShadow: isHealthy ? [
                        BoxShadow(
                          color: colors.success.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    'Browser Plugin Health',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (_isExpanded) ...[
            Divider(color: colors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  _buildInfoRow(
                    context,
                    'Status',
                    isHealthy ? 'Healthy' :
                      (health['connected'] as bool? ?? false) ? 'Connected (Stale)' : 'Disconnected',
                    isHealthy ? colors.success :
                      (health['connected'] as bool? ?? false) ? colors.warning : colors.error,
                  ),
                  const SizedBox(height: SpacingTokens.sm),

                  // Version
                  if (pluginHealth != null) ...[
                    _buildInfoRow(
                      context,
                      'Version',
                      pluginHealth['version']?.toString() ?? 'Unknown',
                      colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: SpacingTokens.sm),

                    // Tool Count
                    _buildInfoRow(
                      context,
                      'Tool Count',
                      '${pluginHealth['toolCount'] ?? 0} tools',
                      colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: SpacingTokens.sm),

                    // Capabilities
                    Text(
                      'Capabilities:',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Wrap(
                      spacing: SpacingTokens.xs,
                      runSpacing: SpacingTokens.xs,
                      children: (pluginHealth['capabilities'] as List<dynamic>? ?? [])
                          .map((cap) => _buildCapabilityChip(context, cap.toString()))
                          .toList(),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                  ],

                  // Last Heartbeat
                  if (health['lastHeartbeat'] != null) ...[
                    _buildInfoRow(
                      context,
                      'Last Heartbeat',
                      _formatHeartbeat(health['secondsSinceHeartbeat'] as int?),
                      colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                  ],

                  // WebSocket Status
                  _buildInfoRow(
                    context,
                    'WebSocket',
                    health['websocketActive'] as bool? ?? false ? 'Active' : 'Inactive',
                    health['websocketActive'] as bool? ?? false ? colors.success : colors.error,
                  ),
                  const SizedBox(height: SpacingTokens.md),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: AsmblButton.secondary(
                          text: 'Refresh',
                          icon: Icons.refresh,
                          size: AsmblButtonSize.small,
                          onPressed: () {
                            widget.pluginBridge.requestHealthStatus();
                            _updateHealth();
                          },
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: AsmblButton.outline(
                          text: 'Copy Info',
                          icon: Icons.copy,
                          size: AsmblButtonSize.small,
                          onPressed: () {
                            final info = '''
Plugin Health Report
===================
Status: ${isHealthy ? 'Healthy' : 'Unhealthy'}
Version: ${pluginHealth?['version'] ?? 'Unknown'}
Tool Count: ${pluginHealth?['toolCount'] ?? 0}
Capabilities: ${(pluginHealth?['capabilities'] as List<dynamic>? ?? []).join(', ')}
Last Heartbeat: ${_formatHeartbeat(health['secondsSinceHeartbeat'] as int?)}
WebSocket: ${health['websocketActive'] as bool? ?? false ? 'Active' : 'Inactive'}
''';
                            Clipboard.setData(ClipboardData(text: info));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Health info copied to clipboard'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, Color valueColor) {
    final colors = ThemeColors(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyles.bodySmall.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilityChip(BuildContext context, String capability) {
    final colors = ThemeColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        capability,
        style: TextStyles.bodySmall.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatHeartbeat(int? secondsAgo) {
    if (secondsAgo == null) return 'Never';
    if (secondsAgo < 60) return '$secondsAgo seconds ago';
    final minutes = secondsAgo ~/ 60;
    if (minutes < 60) return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    final hours = minutes ~/ 60;
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  }
}
