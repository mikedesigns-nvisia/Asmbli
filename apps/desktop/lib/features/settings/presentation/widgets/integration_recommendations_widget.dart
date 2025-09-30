import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/integration_dependency_service.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'integration_dependency_dialog.dart';

class IntegrationRecommendationsWidget extends ConsumerWidget {
  const IntegrationRecommendationsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final dependencyService = ref.watch(integrationDependencyServiceProvider);
    final recommendations = dependencyService.getRecommendations();

    if (recommendations.isEmpty) {
      return _buildEmptyState(colors);
    }

    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          const SizedBox(height: SpacingTokens.lg),
          ...recommendations.take(5).map((rec) => _buildRecommendationItem(context, ref, rec, colors)),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Icon(
          Icons.lightbulb_outline,
          color: colors.primary,
          size: 18,
        ),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          'Recommended Integrations',
          style: TextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'SUGGESTIONS',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(
    BuildContext context,
    WidgetRef ref,
    IntegrationRecommendation recommendation,
    ThemeColors colors,
  ) {
    final integration = IntegrationRegistry.getById(recommendation.integrationId);
    if (integration == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIntegrationIcon(integration, colors),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          integration.name,
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.xs),
                        _buildPriorityBadge(recommendation.priority, colors),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      recommendation.reason,
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildInstallButton(context, ref, recommendation),
            ],
          ),
          if (recommendation.requiredFirst.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.sm),
            _buildRequirementsBanner(recommendation.requiredFirst, colors),
          ],
        ],
      ),
    );
  }

  Widget _buildIntegrationIcon(IntegrationDefinition integration, ThemeColors colors) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        _getIntegrationIcon(integration),
        color: colors.primary,
        size: 16,
      ),
    );
  }

  Widget _buildPriorityBadge(int priority, ThemeColors colors) {
    final color = priority >= 3
      ? colors.success
      : priority >= 2
        ? colors.primary
        : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        priority >= 3 ? 'HIGH' : priority >= 2 ? 'MED' : 'LOW',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInstallButton(
    BuildContext context, 
    WidgetRef ref, 
    IntegrationRecommendation recommendation,
  ) {
    return AsmblButton.primary(
      text: 'Install',
      onPressed: () => _handleInstall(context, ref, recommendation),
    );
  }

  Widget _buildRequirementsBanner(List<String> requiredFirst, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.xs),
      decoration: BoxDecoration(
        color: colors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: colors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: colors.warning,
            size: 12,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: Text(
              'Requires: ${requiredFirst.map((id) => IntegrationRegistry.getById(id)?.name ?? id).join(', ')}',
              style: TextStyle(
                fontSize: 10,
                color: colors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          Icon(
            Icons.done_all,
            color: colors.success,
            size: 32,
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'No Recommendations',
            style: TextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.success,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Your integration setup is optimized!',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleInstall(
    BuildContext context, 
    WidgetRef ref, 
    IntegrationRecommendation recommendation,
  ) async {
    // Show dependency dialog if there are requirements or conflicts
    final dependencyService = ref.read(integrationDependencyServiceProvider);
    final depCheck = dependencyService.checkDependencies(recommendation.integrationId);
    
    if (depCheck.missingRequired.isNotEmpty || depCheck.conflicts.isNotEmpty) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => IntegrationDependencyDialog(
          integrationId: recommendation.integrationId,
          isRemoving: false,
        ),
      );
      
      if (shouldProceed != true) return;
    }
    
    // TODO: Implement actual installation logic
    final colors = ThemeColors(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Installing ${recommendation.integrationId}...'),
        backgroundColor: colors.primary,
      ),
    );
  }

  IconData _getIntegrationIcon(IntegrationDefinition integration) {
    switch (integration.category) {
      case IntegrationCategory.local:
        return Icons.computer;
      case IntegrationCategory.cloudAPIs:
        return Icons.cloud;
      case IntegrationCategory.databases:
        return Icons.storage;
      case IntegrationCategory.aiML:
        return Icons.psychology;
      case IntegrationCategory.utilities:
        return Icons.build;
      case IntegrationCategory.devops:
        return Icons.settings;
    }
  }
}