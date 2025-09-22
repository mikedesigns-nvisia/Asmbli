import 'package:flutter/material.dart';
import '../design_system.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import '../../services/integration_service.dart';

/// Visual indicators for integration status and availability
class IntegrationStatusIndicators {
  
  /// Main status badge showing configuration and availability state
  static Widget statusBadge(IntegrationStatus status, {bool compact = false}) {
    final colors = _getStatusColors(status);
    final text = _getStatusText(status);
    final icon = _getStatusIcon(status);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: colors.foreground),
            const SizedBox(width: 2),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.foreground),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  /// Availability indicator for integrations not yet implemented
  static Widget availabilityIndicator(IntegrationDefinition definition) {
    if (definition.isAvailable) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 12,
            color: SemanticColors.success,
          ),
          SizedBox(width: 4),
          Text(
            'Available',
            style: TextStyle(
              color: SemanticColors.success,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule,
          size: 12,
          color: SemanticColors.warning,
        ),
        SizedBox(width: 4),
        Text(
          'Coming Soon',
          style: TextStyle(
            color: SemanticColors.warning,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Difficulty badge showing integration complexity
  static Widget difficultyBadge(String difficulty, {bool showIcon = true}) {
    final colors = _getDifficultyColors(difficulty);
    final icon = _getDifficultyIcon(difficulty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 10, color: colors.foreground),
            const SizedBox(width: 2),
          ],
          Text(
            difficulty,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  /// Prerequisites indicator showing setup requirements
  static Widget prerequisitesIndicator(List<String> prerequisites) {
    if (prerequisites.isEmpty) return const SizedBox.shrink();

    return Tooltip(
      message: 'Prerequisites:\n${prerequisites.map((p) => '• $p').join('\n')}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: SemanticColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: SemanticColors.warning.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              size: 10,
              color: SemanticColors.warning,
            ),
            const SizedBox(width: 2),
            Text(
              '${prerequisites.length} req',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: SemanticColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Capabilities tags showing what the integration can do
  static Widget capabilitiesPreview(List<String> capabilities, {int maxShow = 3}) {
    if (capabilities.isEmpty) return const SizedBox.shrink();

    final displayCapabilities = capabilities.take(maxShow).toList();
    final hasMore = capabilities.length > maxShow;

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        ...displayCapabilities.map((capability) => 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              capability,
              style: TextStyle(
                color: SemanticColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (hasMore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: SemanticColors.onSurfaceVariant.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '+${capabilities.length - maxShow}',
              style: TextStyle(
                color: SemanticColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  /// Health status indicator for configured integrations
  static Widget healthIndicator(IntegrationHealth health) {
    final colors = _getHealthColors(health.status);
    
    return Tooltip(
      message: health.message ?? _getHealthStatusText(health.status),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: colors.foreground,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.foreground.withOpacity(0.3),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  /// Combined status row with all relevant indicators
  static Widget statusRow(IntegrationStatus status) {
    return Row(
      children: [
        statusBadge(status, compact: true),
        const SizedBox(width: SpacingTokens.xs),
        availabilityIndicator(status.definition),
        const SizedBox(width: SpacingTokens.xs),
        difficultyBadge(status.definition.difficulty, showIcon: false),
        const SizedBox(width: SpacingTokens.xs),
        prerequisitesIndicator(status.definition.prerequisites),
        const Spacer(),
        if (status.isConfigured && status.mcpConfig != null)
          healthIndicator(IntegrationHealth(
            status: IntegrationHealthStatus.healthy,
            lastChecked: DateTime.now(),
          )),
      ],
    );
  }
}

/// Status colors for different states
class StatusColors {
  final Color background;
  final Color foreground;
  final Color border;

  const StatusColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
}

/// Integration health status
enum IntegrationHealthStatus {
  healthy,
  warning,
  error,
  unknown,
}

/// Integration health information
class IntegrationHealth {
  final IntegrationHealthStatus status;
  final DateTime lastChecked;
  final String? message;
  final Map<String, dynamic>? details;

  const IntegrationHealth({
    required this.status,
    required this.lastChecked,
    this.message,
    this.details,
  });
}

// Private helper methods
StatusColors _getStatusColors(IntegrationStatus status) {
  if (!status.definition.isAvailable) {
    return StatusColors(
      background: SemanticColors.onSurfaceVariant.withOpacity(0.1),
      foreground: SemanticColors.onSurfaceVariant,
      border: SemanticColors.onSurfaceVariant.withOpacity(0.2),
    );
  }

  if (!status.isConfigured) {
    return StatusColors(
      background: SemanticColors.primary.withOpacity(0.1),
      foreground: SemanticColors.primary,
      border: SemanticColors.primary.withOpacity(0.3),
    );
  }

  if (!status.isEnabled) {
    return StatusColors(
      background: SemanticColors.warning.withOpacity(0.1),
      foreground: SemanticColors.warning,
      border: SemanticColors.warning.withOpacity(0.3),
    );
  }

  return StatusColors(
    background: SemanticColors.success.withOpacity(0.1),
    foreground: SemanticColors.success,
    border: SemanticColors.success.withOpacity(0.3),
  );
}

String _getStatusText(IntegrationStatus status) {
  if (!status.definition.isAvailable) return 'Coming Soon';
  if (!status.isConfigured) return 'Available';
  if (!status.isEnabled) return 'Disabled';
  return 'Active';
}

IconData _getStatusIcon(IntegrationStatus status) {
  if (!status.definition.isAvailable) return Icons.schedule;
  if (!status.isConfigured) return Icons.download;
  if (!status.isEnabled) return Icons.pause_circle;
  return Icons.check_circle;
}

StatusColors _getDifficultyColors(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return StatusColors(
        background: SemanticColors.success.withOpacity(0.1),
        foreground: SemanticColors.success,
        border: SemanticColors.success.withOpacity(0.3),
      );
    case 'medium':
      return StatusColors(
        background: SemanticColors.warning.withOpacity(0.1),
        foreground: SemanticColors.warning,
        border: SemanticColors.warning.withOpacity(0.3),
      );
    case 'hard':
      return StatusColors(
        background: SemanticColors.error.withOpacity(0.1),
        foreground: SemanticColors.error,
        border: SemanticColors.error.withOpacity(0.3),
      );
    default:
      return StatusColors(
        background: SemanticColors.onSurfaceVariant.withOpacity(0.1),
        foreground: SemanticColors.onSurfaceVariant,
        border: SemanticColors.onSurfaceVariant.withOpacity(0.2),
      );
  }
}

IconData _getDifficultyIcon(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy': return Icons.sentiment_satisfied;
    case 'medium': return Icons.sentiment_neutral;
    case 'hard': return Icons.sentiment_dissatisfied;
    default: return Icons.help_outline;
  }
}

StatusColors _getHealthColors(IntegrationHealthStatus status) {
  switch (status) {
    case IntegrationHealthStatus.healthy:
      return StatusColors(
        background: SemanticColors.success.withOpacity(0.1),
        foreground: SemanticColors.success,
        border: SemanticColors.success.withOpacity(0.3),
      );
    case IntegrationHealthStatus.warning:
      return StatusColors(
        background: SemanticColors.warning.withOpacity(0.1),
        foreground: SemanticColors.warning,
        border: SemanticColors.warning.withOpacity(0.3),
      );
    case IntegrationHealthStatus.error:
      return StatusColors(
        background: SemanticColors.error.withOpacity(0.1),
        foreground: SemanticColors.error,
        border: SemanticColors.error.withOpacity(0.3),
      );
    case IntegrationHealthStatus.unknown:
      return StatusColors(
        background: SemanticColors.onSurfaceVariant.withOpacity(0.1),
        foreground: SemanticColors.onSurfaceVariant,
        border: SemanticColors.onSurfaceVariant.withOpacity(0.2),
      );
  }
}

String _getHealthStatusText(IntegrationHealthStatus status) {
  switch (status) {
    case IntegrationHealthStatus.healthy: return 'Integration is working properly';
    case IntegrationHealthStatus.warning: return 'Integration has minor issues';
    case IntegrationHealthStatus.error: return 'Integration has errors';
    case IntegrationHealthStatus.unknown: return 'Integration status unknown';
  }
}