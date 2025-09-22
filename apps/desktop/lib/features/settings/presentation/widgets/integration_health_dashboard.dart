import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/integration_health_monitoring_service.dart' as monitoring;
import 'package:agent_engine_core/agent_engine_core.dart';

/// Comprehensive health monitoring dashboard for integrations
class IntegrationHealthDashboard extends ConsumerStatefulWidget {
  const IntegrationHealthDashboard({super.key});

  @override
  ConsumerState<IntegrationHealthDashboard> createState() => _IntegrationHealthDashboardState();
}

class _IntegrationHealthDashboardState extends ConsumerState<IntegrationHealthDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Using monitoring service instead of removed healthService
    final healthMonitoringService = ref.watch(monitoring.integrationHealthMonitoringServiceProvider);
    final statistics = healthMonitoringService.getHealthStatistics();
    final currentHealth = healthMonitoringService.currentHealth;
    final integrationsNeedingAttention = healthMonitoringService.getIntegrationsNeedingAttention();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SemanticColors.background,
            SemanticColors.background.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, statistics),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Health Overview Cards
          _buildHealthOverview(context, statistics),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Integrations Needing Attention
          if (integrationsNeedingAttention.isNotEmpty)
            _buildAttentionSection(context, integrationsNeedingAttention),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Integration Health Grid
          _buildHealthGrid(context, currentHealth),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, monitoring.HealthStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: SemanticColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated health indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: stats.error > 0 ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getOverallHealthColor(stats).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getOverallHealthIcon(stats),
                    color: _getOverallHealthColor(stats),
                    size: 24,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(width: SpacingTokens.lg),
          
          // Title and summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Integration Health Monitor',
                  style: TextStyles.pageTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  stats.overallStatus,
                  style: TextStyles.bodyMedium.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Health percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stats.healthPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _getOverallHealthColor(stats),
                ),
              ),
              Text(
                'Healthy',
                style: TextStyles.caption.copyWith(
                  color: SemanticColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildHealthOverview(BuildContext context, monitoring.HealthStatistics stats) {
    return Row(
      children: [
        Expanded(
          child: _buildHealthCard(
            'Healthy',
            stats.healthy,
            Icons.check_circle,
            SemanticColors.success,
            stats.total,
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Expanded(
          child: _buildHealthCard(
            'Unhealthy',
            stats.unhealthy,
            Icons.warning,
            SemanticColors.warning,
            stats.total,
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Expanded(
          child: _buildHealthCard(
            'Error',
            stats.error,
            Icons.error,
            SemanticColors.error,
            stats.total,
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Expanded(
          child: _buildHealthCard(
            'Disabled',
            stats.disabled,
            Icons.power_settings_new,
            SemanticColors.onSurfaceVariant,
            stats.total,
          ),
        ),
      ],
    );
  }
  
  Widget _buildHealthCard(
    String label,
    int count,
    IconData icon,
    Color color,
    int total,
  ) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: SemanticColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                label,
                style: TextStyles.bodySmall.copyWith(
                  color: SemanticColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            '${percentage.toStringAsFixed(0)}% of total',
            style: TextStyles.caption.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttentionSection(BuildContext context, List<monitoring.IntegrationHealth> integrationsNeedingAttention) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: SemanticColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: SemanticColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning,
                color: SemanticColors.warning,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Integrations Needing Attention (${integrationsNeedingAttention.length})',
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: SemanticColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          ...integrationsNeedingAttention.take(3).map((health) {
            return Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
              child: Row(
                children: [
                  Icon(
                    _getStatusIconFromHealthStatus(health.status),
                    size: 16,
                    color: _getStatusColorFromHealthStatus(health.status),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      '${health.integrationId}: ${health.message}',
                      style: TextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _getTimeDifference(health.lastChecked),
                    style: TextStyles.caption.copyWith(
                      color: SemanticColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildHealthGrid(BuildContext context, Map<String, monitoring.IntegrationHealth> allHealth) {    
    if (allHealth.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_heart,
              size: 64,
              color: SemanticColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'No integrations being monitored',
              style: TextStyles.bodyLarge.copyWith(
                color: SemanticColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              'Configure integrations to start monitoring their health',
              style: TextStyles.bodyMedium.copyWith(
                color: SemanticColors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(SpacingTokens.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: SpacingTokens.md,
        mainAxisSpacing: SpacingTokens.md,
        childAspectRatio: 1.5,
      ),
      itemCount: allHealth.length,
      itemBuilder: (context, index) {
        final entry = allHealth.entries.elementAt(index);
        final integrationId = entry.key;
        final health = entry.value;
        final integration = IntegrationRegistry.getById(integrationId);
        
        if (integration == null) return const SizedBox.shrink();
        
        return _buildHealthMonitorCard(integration, health);
      },
    );
  }
  
  Widget _buildHealthMonitorCard(
    IntegrationDefinition integration,
    monitoring.IntegrationHealth health,
  ) {
    return AsmblCard(
      child: InkWell(
        onTap: () => _showHealthDetails(integration, health),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and status
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (integration.brandColor ?? SemanticColors.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Icon(
                      integration.icon,
                      size: 16,
                      color: integration.brandColor ?? SemanticColors.primary,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      integration.name,
                      style: TextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColorFromHealthStatus(health.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: SpacingTokens.sm),
              
              // Status message
              Text(
                health.message ?? 'Status unknown',
                style: TextStyles.caption.copyWith(
                  color: SemanticColors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Details row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (health.latencyMs != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.speed,
                          size: 12,
                          color: SemanticColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${health.latencyMs}ms',
                          style: TextStyles.caption.copyWith(
                            fontSize: 10,
                            color: SemanticColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  Text(
                    'Last: ${_getTimeDifference(health.lastChecked)}',
                    style: TextStyles.caption.copyWith(
                      fontSize: 10,
                      color: SemanticColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showHealthDetails(
    IntegrationDefinition integration,
    monitoring.IntegrationHealth health,
  ) {
    showDialog(
      context: context,
      builder: (context) => IntegrationHealthDetailsDialog(
        integration: integration,
        health: health,
      ),
    );
  }
  
  Color _getOverallHealthColor(monitoring.HealthStatistics stats) {
    if (stats.error > 0) return SemanticColors.error;
    if (stats.unhealthy > 0) return SemanticColors.warning;
    if (stats.healthy == stats.total && stats.total > 0) {
      return SemanticColors.success;
    }
    return SemanticColors.onSurfaceVariant;
  }
  
  IconData _getOverallHealthIcon(monitoring.HealthStatistics stats) {
    if (stats.error > 0) return Icons.error;
    if (stats.unhealthy > 0) return Icons.warning;
    if (stats.healthy == stats.total && stats.total > 0) {
      return Icons.check_circle;
    }
    return Icons.help_outline;
  }
  
  Color _getStatusColor(monitoring.IntegrationHealthStatus status) {
    switch (status) {
      case monitoring.IntegrationHealthStatus.healthy:
        return SemanticColors.success;
      case monitoring.IntegrationHealthStatus.unhealthy:
        return SemanticColors.warning;
      case monitoring.IntegrationHealthStatus.error:
        return SemanticColors.error;
      case monitoring.IntegrationHealthStatus.disabled:
        return SemanticColors.onSurfaceVariant;
      case monitoring.IntegrationHealthStatus.notFound:
        return SemanticColors.onSurfaceVariant;
    }
  }
  
  IconData _getStatusIcon(monitoring.IntegrationHealthStatus status) {
    switch (status) {
      case monitoring.IntegrationHealthStatus.healthy:
        return Icons.check_circle;
      case monitoring.IntegrationHealthStatus.unhealthy:
        return Icons.warning;
      case monitoring.IntegrationHealthStatus.error:
        return Icons.error;
      case monitoring.IntegrationHealthStatus.disabled:
        return Icons.help;
      case monitoring.IntegrationHealthStatus.notFound:
        return Icons.help_outline;
    }
  }
  
  String _getStatusText(monitoring.IntegrationHealthStatus? status) {
    if (status == null) return 'Unknown';
    switch (status) {
      case monitoring.IntegrationHealthStatus.healthy:
        return 'Healthy';
      case monitoring.IntegrationHealthStatus.unhealthy:
        return 'Warning';
      case monitoring.IntegrationHealthStatus.error:
        return 'Error';
      case monitoring.IntegrationHealthStatus.disabled:
        return 'Disabled';
      case monitoring.IntegrationHealthStatus.notFound:
        return 'Not Found';
    }
  }
  
  String _getTimeDifference(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _getStatusColorFromHealthStatus(monitoring.IntegrationHealthStatus status) {
    switch (status) {
      case monitoring.IntegrationHealthStatus.healthy:
        return SemanticColors.success;
      case monitoring.IntegrationHealthStatus.unhealthy:
        return SemanticColors.warning;
      case monitoring.IntegrationHealthStatus.error:
        return SemanticColors.error;
      case monitoring.IntegrationHealthStatus.disabled:
        return SemanticColors.onSurfaceVariant;
      case monitoring.IntegrationHealthStatus.notFound:
        return SemanticColors.onSurfaceVariant;
    }
  }

  IconData _getStatusIconFromHealthStatus(monitoring.IntegrationHealthStatus status) {
    switch (status) {
      case monitoring.IntegrationHealthStatus.healthy:
        return Icons.check_circle;
      case monitoring.IntegrationHealthStatus.unhealthy:
        return Icons.warning;
      case monitoring.IntegrationHealthStatus.error:
        return Icons.error;
      case monitoring.IntegrationHealthStatus.disabled:
        return Icons.help;
      case monitoring.IntegrationHealthStatus.notFound:
        return Icons.help_outline;
    }
  }
}

/// Dialog showing detailed health information for an integration
class IntegrationHealthDetailsDialog extends StatelessWidget {
  final IntegrationDefinition integration;
  final monitoring.IntegrationHealth health;
  
  const IntegrationHealthDetailsDialog({
    super.key,
    required this.integration,
    required this.health,
  });
  
  @override
  Widget build(BuildContext context) {    
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (integration.brandColor ?? SemanticColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(
                    integration.icon,
                    color: integration.brandColor ?? SemanticColors.primary,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        integration.name,
                        style: TextStyles.cardTitle,
                      ),
                      Text(
                        'Health Details',
                        style: TextStyles.bodyMedium.copyWith(
                          color: SemanticColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: SpacingTokens.lg),
            
            // Current Status
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: _getStatusColor(health.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(
                  color: _getStatusColor(health.status).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(health.status),
                    color: _getStatusColor(health.status),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(health.status),
                          style: TextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(health.status),
                          ),
                        ),
                        Text(
                          health.message,
                          style: TextStyles.bodyMedium.copyWith(
                            color: SemanticColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: SpacingTokens.lg),
            
            // Details
            if (health.details != null) ...[
              Text(
                'Details',
                style: TextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              ...health.details!.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                child: Row(
                  children: [
                    Text(
                      '${entry.key}:',
                      style: TextStyles.bodyMedium.copyWith(
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      entry.value.toString(),
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
              
              const SizedBox(height: SpacingTokens.lg),
            ],
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AsmblButton.primary(
                  text: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(monitoring.IntegrationHealthStatus status) {
    switch (status) {
      case monitoring.IntegrationHealthStatus.healthy:
        return SemanticColors.success;
      case monitoring.IntegrationHealthStatus.unhealthy:
        return SemanticColors.warning;
      case monitoring.IntegrationHealthStatus.error:
        return SemanticColors.error;
      case monitoring.IntegrationHealthStatus.disabled:
        return SemanticColors.onSurfaceVariant;
      case monitoring.IntegrationHealthStatus.notFound:
        return SemanticColors.onSurfaceVariant;
    }
  }
  
  IconData _getStatusIcon(monitoring.IntegrationHealthStatus status) {
    switch (status) {
      case monitoring.IntegrationHealthStatus.healthy:
        return Icons.check_circle;
      case monitoring.IntegrationHealthStatus.unhealthy:
        return Icons.warning;
      case monitoring.IntegrationHealthStatus.error:
        return Icons.error;
      case monitoring.IntegrationHealthStatus.disabled:
        return Icons.help;
      case monitoring.IntegrationHealthStatus.notFound:
        return Icons.help_outline;
    }
  }
  
  String _getStatusText(monitoring.IntegrationHealthStatus status) {
    switch (status) {
      case monitoring.IntegrationHealthStatus.healthy:
        return 'Healthy';
      case monitoring.IntegrationHealthStatus.unhealthy:
        return 'Warning';
      case monitoring.IntegrationHealthStatus.error:
        return 'Error';
      case monitoring.IntegrationHealthStatus.disabled:
        return 'Disabled';
      case monitoring.IntegrationHealthStatus.notFound:
        return 'Not Found';
    }
  }
}