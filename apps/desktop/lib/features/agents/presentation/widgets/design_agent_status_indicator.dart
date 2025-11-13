import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../../../../core/design_system/design_system.dart';

/// Widget that shows the dual-model status for design agents
class DesignAgentStatusIndicator extends ConsumerWidget {
  final Agent agent;
  final bool isExpanded;
  
  const DesignAgentStatusIndicator({
    super.key,
    required this.agent,
    this.isExpanded = false,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    
    // Check if this is a design agent
    final config = agent.configuration ?? {};
    final isDesignAgent = config['type'] == 'design_agent';
    
    if (!isDesignAgent) {
      return const SizedBox.shrink();
    }
    
    final models = config['models'] as Map<String, dynamic>?;
    if (models == null) {
      return const SizedBox.shrink();
    }
    
    final planningModel = models['planning'] as String?;
    final visionModel = models['vision'] as String?;
    
    if (isExpanded) {
      return Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  'Design Agent (Dual Model)',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            _buildModelRow(
              context,
              icon: Icons.psychology,
              label: 'Planning',
              model: _formatModelName(planningModel),
              color: colors.accent,
            ),
            const SizedBox(height: SpacingTokens.xs),
            _buildModelRow(
              context,
              icon: Icons.visibility,
              label: 'Vision',
              model: _formatModelName(visionModel),
              color: colors.success,
            ),
          ],
        ),
      );
    }
    
    // Compact view
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 12,
            color: colors.primary,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            'Design Agent',
            style: TextStyles.caption.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: SpacingTokens.xs),
          Icon(
            Icons.psychology,
            size: 12,
            color: colors.accent,
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.visibility,
            size: 12,
            color: colors.success,
          ),
        ],
      ),
    );
  }
  
  Widget _buildModelRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String model,
    required Color color,
  }) {
    final colors = ThemeColors(context);
    
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          '$label:',
          style: TextStyles.caption.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: SpacingTokens.xs),
        Expanded(
          child: Text(
            model,
            style: TextStyles.caption.copyWith(
              color: colors.onSurface,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  String _formatModelName(String? model) {
    if (model == null) return 'Not configured';
    
    // Remove 'local_' prefix and clean up the name
    String cleaned = model.replaceFirst('local_', '');
    cleaned = cleaned.replaceAll('_', ':');
    
    // Make it more readable
    if (cleaned.contains('deepseek')) {
      return 'DeepSeek-R1';
    } else if (cleaned.contains('llava')) {
      return 'LLaVA';
    }
    
    return cleaned;
  }
}