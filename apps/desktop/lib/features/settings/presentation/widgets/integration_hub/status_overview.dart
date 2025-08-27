import 'package:flutter/material.dart';
import '../../../../../core/design_system/design_system.dart';

/// Status Overview - Temporary placeholder to avoid compilation errors
class StatusOverview extends StatelessWidget {
  final Function(String)? onStatusClicked;
  final bool showDetailed;

  const StatusOverview({
    super.key,
    this.onStatusClicked,
    this.showDetailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            'Status Overview',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: 8),
          Text(
            'Integration status monitoring temporarily disabled',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Mock integration stats
class IntegrationStats {
  final int totalIntegrations;
  final int configuredIntegrations;
  final int healthyIntegrations;
  final int errorIntegrations;

  const IntegrationStats({
    required this.totalIntegrations,
    required this.configuredIntegrations,
    required this.healthyIntegrations,
    required this.errorIntegrations,
  });
}

/// Mock health status enum
enum HealthStatus { excellent, good, warning, critical }

/// Mock health statistics
class HealthStatistics {
  final HealthStatus overallHealth;
  final double averageResponseTime;
  final int totalRequestsToday;
  final double errorRate;
  final double uptime;
  final DateTime lastUpdated;
  final bool hasRecentIssues;

  const HealthStatistics({
    required this.overallHealth,
    required this.averageResponseTime,
    required this.totalRequestsToday,
    required this.errorRate,
    required this.uptime,
    required this.lastUpdated,
    required this.hasRecentIssues,
  });
}