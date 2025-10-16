import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_health_monitor.dart';

/// Widget that displays the health status of MCP servers
class MCPHealthStatusWidget extends ConsumerWidget {
  final String? serverId; // If null, shows all servers
  final bool showDetails;
  final bool compact;

  const MCPHealthStatusWidget({
    super.key,
    this.serverId,
    this.showDetails = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(mcpServerHealthProvider);

    return healthAsync.when(
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, error),
      data: (healthMap) {
        if (serverId != null) {
          final health = healthMap[serverId];
          return health != null 
            ? _buildServerHealth(context, health)
            : _buildUnknownState(context, serverId!);
        } else {
          return _buildAllServersHealth(context, healthMap);
        }
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(ThemeColors(context).primary),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Text(
            'Checking health...',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: ThemeColors(context).error,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Text(
            'Health check failed',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownState(BuildContext context, String serverId) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline,
            size: 16,
            color: ThemeColors(context).onSurfaceVariant,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Text(
            'Unknown status',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerHealth(BuildContext context, MCPServerHealth health) {
    if (compact) {
      return _buildCompactHealth(context, health);
    }

    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              _buildStatusIndicator(context, health.status),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      health.serverId,
                      style: TextStyles.cardTitle,
                    ),
                    Text(
                      _getStatusText(health.status),
                      style: TextStyles.bodySmall.copyWith(
                        color: _getStatusColor(context, health.status),
                      ),
                    ),
                  ],
                ),
              ),
              if (showDetails) _buildHealthMetrics(context, health),
            ],
          ),
          
          if (showDetails) ...[
            const SizedBox(height: SpacingTokens.md),
            _buildDetailedMetrics(context, health),
          ],

          if (health.errorMessage != null) ...[
            const SizedBox(height: SpacingTokens.sm),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: ThemeColors(context).error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(
                  color: ThemeColors(context).error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: ThemeColors(context).error,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      health.errorMessage!,
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactHealth(BuildContext context, MCPServerHealth health) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIndicator(context, health.status),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          '${health.responseTimeMs}ms',
          style: TextStyles.bodySmall.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAllServersHealth(BuildContext context, Map<String, MCPServerHealth> healthMap) {
    if (healthMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Center(
          child: Text(
            'No MCP servers configured',
            style: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final sortedEntries = healthMap.entries.toList()
      ..sort((a, b) => _statusPriority(a.value.status).compareTo(_statusPriority(b.value.status)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary header
        _buildHealthSummary(context, healthMap.values.toList()),
        
        const SizedBox(height: SpacingTokens.lg),
        
        // Individual server health
        ...sortedEntries.map((entry) => 
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
            child: _buildServerHealth(context, entry.value),
          )
        ),
      ],
    );
  }

  Widget _buildHealthSummary(BuildContext context, List<MCPServerHealth> healthList) {
    final totalServers = healthList.length;
    final healthyServers = healthList.where((h) => h.isHealthy).length;
    final offlineServers = healthList.where((h) => !h.isConnected).length;
    final averageResponseTime = healthList.isNotEmpty
        ? healthList.map((h) => h.responseTimeMs).reduce((a, b) => a + b) ~/ healthList.length
        : 0;

    return AsmblCard(
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryMetric(
              context,
              'Total Servers',
              totalServers.toString(),
              Icons.dns,
              ThemeColors(context).primary,
            ),
          ),
          const SizedBox(width: SpacingTokens.lg),
          Expanded(
            child: _buildSummaryMetric(
              context,
              'Healthy',
              healthyServers.toString(),
              Icons.check_circle,
              ThemeColors(context).success,
            ),
          ),
          const SizedBox(width: SpacingTokens.lg),
          Expanded(
            child: _buildSummaryMetric(
              context,
              'Offline',
              offlineServers.toString(),
              Icons.error_outline,
              ThemeColors(context).error,
            ),
          ),
          const SizedBox(width: SpacingTokens.lg),
          Expanded(
            child: _buildSummaryMetric(
              context,
              'Avg Response',
              '${averageResponseTime}ms',
              Icons.speed,
              ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          value,
          style: TextStyles.cardTitle.copyWith(color: color),
        ),
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context, MCPServerHealthStatus status) {
    final color = _getStatusColor(context, status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Widget _buildHealthMetrics(BuildContext context, MCPServerHealth health) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${health.responseTimeMs}ms',
          style: TextStyles.bodySmall.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          _formatLastCheck(health.lastCheck),
          style: TextStyles.bodySmall.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetrics(BuildContext context, MCPServerHealth health) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricItem(context, 'Response Time', '${health.responseTimeMs}ms'),
        _buildMetricItem(context, 'Failures', health.consecutiveFailures.toString()),
        _buildMetricItem(context, 'Availability', '${health.metrics['availability']?.toStringAsFixed(1) ?? 'N/A'}%'),
        _buildMetricItem(context, 'Last Healthy', health.lastHealthy != null 
            ? _formatLastCheck(health.lastHealthy!) 
            : 'Never'),
      ],
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyles.bodySmall.copyWith(
            color: ThemeColors(context).onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BuildContext context, MCPServerHealthStatus status) {
    switch (status) {
      case MCPServerHealthStatus.healthy:
        return ThemeColors(context).success;
      case MCPServerHealthStatus.degraded:
        return ThemeColors(context).warning;
      case MCPServerHealthStatus.unhealthy:
        return ThemeColors(context).error;
      case MCPServerHealthStatus.offline:
        return ThemeColors(context).error;
      case MCPServerHealthStatus.reconnecting:
        return ThemeColors(context).info;
      case MCPServerHealthStatus.unknown:
        return ThemeColors(context).onSurfaceVariant;
    }
  }

  IconData _getStatusIcon(MCPServerHealthStatus status) {
    switch (status) {
      case MCPServerHealthStatus.healthy:
        return Icons.check_circle;
      case MCPServerHealthStatus.degraded:
        return Icons.warning;
      case MCPServerHealthStatus.unhealthy:
        return Icons.error;
      case MCPServerHealthStatus.offline:
        return Icons.cloud_off;
      case MCPServerHealthStatus.reconnecting:
        return Icons.refresh;
      case MCPServerHealthStatus.unknown:
        return Icons.help_outline;
    }
  }

  String _getStatusText(MCPServerHealthStatus status) {
    switch (status) {
      case MCPServerHealthStatus.healthy:
        return 'Healthy';
      case MCPServerHealthStatus.degraded:
        return 'Degraded';
      case MCPServerHealthStatus.unhealthy:
        return 'Unhealthy';
      case MCPServerHealthStatus.offline:
        return 'Offline';
      case MCPServerHealthStatus.reconnecting:
        return 'Reconnecting...';
      case MCPServerHealthStatus.unknown:
        return 'Unknown';
    }
  }

  int _statusPriority(MCPServerHealthStatus status) {
    switch (status) {
      case MCPServerHealthStatus.offline:
        return 0;
      case MCPServerHealthStatus.unhealthy:
        return 1;
      case MCPServerHealthStatus.reconnecting:
        return 2;
      case MCPServerHealthStatus.degraded:
        return 3;
      case MCPServerHealthStatus.unknown:
        return 4;
      case MCPServerHealthStatus.healthy:
        return 5;
    }
  }

  String _formatLastCheck(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}