import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/integration_dependency_service.dart';
import 'package:agent_engine_core/agent_engine_core.dart';

class IntegrationDependencyDialog extends ConsumerWidget {
  final String integrationId;
  final bool isRemoving;

  const IntegrationDependencyDialog({
    super.key,
    required this.integrationId,
    this.isRemoving = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dependencyService = ref.watch(integrationDependencyServiceProvider);
    
    return Dialog(
      backgroundColor: const Color(0xFFFCFAF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: SpacingTokens.lg),
            if (isRemoving) 
              _buildRemovalContent(dependencyService)
            else
              _buildInstallationContent(dependencyService),
            const SizedBox(height: SpacingTokens.xxl),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final integration = IntegrationRegistry.getById(integrationId);
    final action = isRemoving ? 'Remove' : 'Install';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$action ${integration?.name ?? integrationId}',
          style: TextStyles.cardTitle,
        ),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          isRemoving 
            ? 'Review dependencies that will be affected'
            : 'Review integration requirements and dependencies',
          style: TextStyles.bodyMedium.copyWith(
            color: const Color(0xFF736B5F),
          ),
        ),
      ],
    );
  }

  Widget _buildInstallationContent(IntegrationDependencyService service) {
    final depCheck = service.checkDependencies(integrationId);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (depCheck.missingRequired.isNotEmpty) ...[
          _buildDependencySection(
            'Required Dependencies',
            depCheck.missingRequired,
            const Color(0xFFD32F2F),
            'These integrations must be installed first:',
          ),
          const SizedBox(height: SpacingTokens.lg),
        ],
        if (depCheck.conflicts.isNotEmpty) ...[
          _buildDependencySection(
            'Conflicts',
            depCheck.conflicts,
            const Color(0xFFFF9800),
            'These integrations conflict and should be disabled:',
          ),
          const SizedBox(height: SpacingTokens.lg),
        ],
        if (depCheck.missingOptional.isNotEmpty) ...[
          _buildDependencySection(
            'Recommended',
            depCheck.missingOptional,
            const Color(0xFF3D3328),
            'These integrations would enhance functionality:',
          ),
          const SizedBox(height: SpacingTokens.lg),
        ],
        if (depCheck.canInstall && depCheck.missingRequired.isEmpty && depCheck.conflicts.isEmpty)
          _buildSuccessMessage(),
      ],
    );
  }

  Widget _buildRemovalContent(IntegrationDependencyService service) {
    final affected = service.getAffectedByRemoval(integrationId);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (affected.directDependents.isNotEmpty) ...[
          _buildDependencySection(
            'Direct Dependencies',
            affected.directDependents,
            const Color(0xFFD32F2F),
            'These integrations directly depend on this one:',
          ),
          const SizedBox(height: SpacingTokens.lg),
        ],
        if (affected.allAffected.length > affected.directDependents.length) ...[
          _buildDependencySection(
            'Indirectly Affected',
            affected.allAffected.where((id) => !affected.directDependents.contains(id)).toList(),
            const Color(0xFFD32F2F), // Error color
            'These integrations may also be affected:',
          ),
          const SizedBox(height: SpacingTokens.lg),
        ],
        if (affected.directDependents.isEmpty)
          _buildSuccessMessage(isRemoval: true),
      ],
    );
  }

  Widget _buildDependencySection(
    String title,
    List<String> integrationIds,
    Color color,
    String description,
  ) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForSeverity(color),
                color: color,
                size: 16,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                title,
                style: TextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            description,
            style: TextStyles.bodyMedium,
          ),
          const SizedBox(height: SpacingTokens.sm),
          ...integrationIds.map((id) => _buildIntegrationItem(id)),
        ],
      ),
    );
  }

  Widget _buildIntegrationItem(String integrationId) {
    final integration = IntegrationRegistry.getById(integrationId);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(
        children: [
          const Icon(
            Icons.integration_instructions,
            size: 14,
            color: Color(0xFF736B5F),
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            integration?.name ?? integrationId,
            style: TextStyles.bodyMedium,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF736B5F).withOpacity( 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              integration?.category.name.toUpperCase() ?? 'UNKNOWN',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Color(0xFF736B5F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage({bool isRemoval = false}) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF4CAF50),
            size: 16,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              isRemoval 
                ? 'This integration can be safely removed without affecting other integrations.'
                : 'All requirements are met. This integration is ready to install.',
              style: TextStyles.bodyMedium.copyWith(
                color: const Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AsmblButton.secondary(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: SpacingTokens.sm),
        AsmblButton.primary(
          text: isRemoving ? 'Remove' : 'Install',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  IconData _getIconForSeverity(Color color) {
    if (color == const Color(0xFFD32F2F)) return Icons.error_outline;
    if (color == const Color(0xFFFF9800)) return Icons.warning_amber;
    return Icons.info_outline;
  }
}