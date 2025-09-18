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
    final dependencyService = ref.watch(integrationDependencyServiceProvider);
    final recommendations = dependencyService.getRecommendations();
    
    if (recommendations.isEmpty) {
      return _buildEmptyState();
    }
    
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: SpacingTokens.lg),
          ...recommendations.take(5).map((rec) => _buildRecommendationItem(context, ref, rec)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.lightbulb_outline,
          color: SemanticColors.primary,
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
            color: SemanticColors.primary.withOpacity( 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'SUGGESTIONS',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: SemanticColors.primary,
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
  ) {
    final integration = IntegrationRegistry.getById(recommendation.integrationId);
    if (integration == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: SemanticColors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: SemanticColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIntegrationIcon(integration),
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
                        _buildPriorityBadge(recommendation.priority),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      recommendation.reason,
                      style: TextStyles.bodySmall.copyWith(
                        color: SemanticColors.onSurfaceVariant,
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
            _buildRequirementsBanner(recommendation.requiredFirst),
          ],
        ],
      ),
    );
  }

  Widget _buildIntegrationIcon(IntegrationDefinition integration) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: SemanticColors.primary.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        _getIntegrationIcon(integration),
        color: SemanticColors.primary,
        size: 16,
      ),
    );
  }

  Widget _buildPriorityBadge(int priority) {
    final color = priority >= 3 
      ? SemanticColors.success 
      : priority >= 2 
        ? SemanticColors.primary 
        : SemanticColors.onSurfaceVariant;
        
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
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

  Widget _buildRequirementsBanner(List<String> requiredFirst) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.xs),
      decoration: BoxDecoration(
        color: SemanticColors.warning.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: SemanticColors.warning.withOpacity( 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: SemanticColors.warning,
            size: 12,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: Text(
              'Requires: ${requiredFirst.map((id) => IntegrationRegistry.getById(id)?.name ?? id).join(', ')}',
              style: const TextStyle(
                fontSize: 10,
                color: SemanticColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          const Icon(
            Icons.done_all,
            color: SemanticColors.success,
            size: 32,
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'No Recommendations',
            style: TextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: SemanticColors.success,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Your integration setup is optimized!',
            style: TextStyles.bodySmall.copyWith(
              color: SemanticColors.onSurfaceVariant,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Installing ${recommendation.integrationId}...'),
        backgroundColor: SemanticColors.primary,
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