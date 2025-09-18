import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_system/design_system.dart';
import '../../../models/agent_builder_state.dart';
import '../../screens/agent_builder_screen.dart';

/// Review Component for final agent configuration review
class ReviewComponent extends ConsumerWidget {
  const ReviewComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final builderState = ref.watch(agentBuilderStateProvider);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(colors),
            const SizedBox(height: SpacingTokens.sectionSpacing),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Configuration summary
                Expanded(
                  flex: 2,
                  child: _buildConfigurationSummary(builderState, colors),
                ),

                const SizedBox(width: SpacingTokens.lg),

                // Right side - Actions and final steps
                Expanded(
                  flex: 1,
                  child: _buildFinalActions(builderState, colors),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          ),
          child: Icon(
            Icons.preview,
            color: colors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review & Create Agent',
              style: TextStyles.titleLarge.copyWith(color: colors.onSurface),
            ),
            Text(
              'Review your configuration and create your agent',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfigurationSummary(AgentBuilderState builderState, ThemeColors colors) {
    return Column(
      children: [
        // Basic Information
        _buildSummarySection(
          'Basic Information',
          Icons.info,
          colors,
          [
            _buildSummaryItem('Name', builderState.name.isEmpty ? 'Not set' : builderState.name, colors),
            _buildSummaryItem('Category', builderState.category, colors),
            _buildSummaryItem('Description', builderState.description.isEmpty ? 'Not set' : builderState.description, colors, maxLines: 2),
          ],
        ),

        const SizedBox(height: SpacingTokens.lg),

        // Prompt Configuration
        _buildSummarySection(
          'Prompt Configuration',
          Icons.edit_note,
          colors,
          [
            _buildSummaryItem('Personality', builderState.personality.isEmpty ? 'Not set' : builderState.personality, colors),
            _buildSummaryItem('Tone', builderState.tone.isEmpty ? 'Not set' : builderState.tone, colors),
            _buildSummaryItem('Expertise', builderState.expertise.isEmpty ? 'Not set' : builderState.expertise, colors),
            _buildSummaryItem('System Prompt',
              builderState.systemPrompt.isEmpty
                ? 'Not set'
                : '${builderState.systemPrompt.length} characters',
              colors
            ),
          ],
        ),

        const SizedBox(height: SpacingTokens.lg),

        // Model Configuration
        _buildSummarySection(
          'Model Configuration',
          Icons.psychology,
          colors,
          [
            _buildSummaryItem('Provider', builderState.modelProvider, colors),
            _buildSummaryItem('Model', builderState.modelName, colors),
            _buildSummaryItem('Performance Tier', builderState.performanceTier, colors),
            _buildSummaryItem('Temperature', builderState.temperature.toStringAsFixed(2), colors),
            _buildSummaryItem('Max Tokens', builderState.maxTokens.toString(), colors),
          ],
        ),

        const SizedBox(height: SpacingTokens.lg),

        // Tools & Context
        _buildSummarySection(
          'Tools & Context',
          Icons.extension,
          colors,
          [
            _buildSummaryItem('Selected Tools', '${builderState.selectedTools.length} tools', colors),
            _buildSummaryItem('Context Documents', '${builderState.contextDocuments.length} files', colors),
            _buildSummaryItem('Knowledge Files', '${builderState.knowledgeFiles.length} files', colors),
          ],
        ),
      ],
    );
  }

  Widget _buildFinalActions(AgentBuilderState builderState, ThemeColors colors) {
    return Column(
      children: [
        // Validation status
        _buildValidationStatus(builderState, colors),

        const SizedBox(height: SpacingTokens.lg),

        // Creation options
        AsmblCard(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rocket_launch, color: colors.primary, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Create Agent',
                      style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),

                Text(
                  'Choose how to create your agent:',
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: SpacingTokens.md),

                SizedBox(
                  width: double.infinity,
                  child: AsmblButton.primary(
                    text: 'Create & Deploy',
                    onPressed: builderState.isValid ? () => _createAgent(builderState, deploy: true) : null,
                    icon: Icons.cloud_upload,
                  ),
                ),

                const SizedBox(height: SpacingTokens.sm),

                SizedBox(
                  width: double.infinity,
                  child: AsmblButton.secondary(
                    text: 'Save as Draft',
                    onPressed: () => _createAgent(builderState, deploy: false),
                    icon: Icons.save,
                  ),
                ),

                const SizedBox(height: SpacingTokens.md),

                Container(
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.accent, size: 16),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: Text(
                          'Deployed agents are immediately available for use',
                          style: TextStyles.caption.copyWith(color: colors.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: SpacingTokens.lg),

        // Export options
        AsmblCard(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.download, color: colors.accent, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Export Configuration',
                      style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),

                SizedBox(
                  width: double.infinity,
                  child: AsmblButton.secondary(
                    text: 'Export as JSON',
                    onPressed: () => _exportConfiguration(builderState, 'json'),
                    icon: Icons.code,
                  ),
                ),

                const SizedBox(height: SpacingTokens.sm),

                SizedBox(
                  width: double.infinity,
                  child: AsmblButton.secondary(
                    text: 'Export as Template',
                    onPressed: () => _exportConfiguration(builderState, 'template'),
                    icon: Icons.file_copy,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: SpacingTokens.lg),

        // Cost estimate
        AsmblCard(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.monetization_on, color: colors.accent, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Cost Estimate',
                      style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),

                _buildCostItem('Setup Cost', 'Free', colors),
                const SizedBox(height: SpacingTokens.sm),
                _buildCostItem('Monthly Usage', '\$15-30', colors),
                const SizedBox(height: SpacingTokens.sm),
                _buildCostItem('Per Message', '\$0.02', colors),

                const SizedBox(height: SpacingTokens.md),

                Container(
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Text(
                    'Costs may vary based on usage and model selection',
                    style: TextStyles.caption.copyWith(color: colors.primary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidationStatus(AgentBuilderState builderState, ThemeColors colors) {
    final isValid = builderState.isValid;
    final errors = builderState.getAllValidationErrors();

    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error_outline,
                  color: isValid ? colors.primary : colors.error,
                  size: 20,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Validation Status',
                  style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            if (isValid)
              Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: colors.primary, size: 24),
                    const SizedBox(width: SpacingTokens.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to Create',
                            style: TextStyles.bodyMedium.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'All required fields are completed',
                            style: TextStyles.bodySmall.copyWith(color: colors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: colors.error, size: 20),
                        const SizedBox(width: SpacingTokens.sm),
                        Text(
                          'Validation Issues',
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    ...errors.map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                      child: Text(
                        '• $error',
                        style: TextStyles.bodySmall.copyWith(color: colors.error),
                      ),
                    )).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(String title, IconData icon, ThemeColors colors, List<Widget> items) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.accent, size: 20),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  title,
                  style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, ThemeColors colors, {int maxLines = 1}) {
    final isEmpty = value == 'Not set';

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyles.bodySmall.copyWith(
                color: isEmpty ? colors.error : colors.onSurface,
                fontWeight: isEmpty ? FontWeight.normal : FontWeight.w600,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostItem(String label, String cost, ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
        ),
        Text(
          cost,
          style: TextStyles.bodySmall.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _createAgent(AgentBuilderState builderState, {required bool deploy}) {
    // TODO: Implement actual agent creation logic
    print('Creating agent: ${builderState.name}');
    print('Deploy: $deploy');
    print('Configuration: ${builderState.toJson()}');
  }

  void _exportConfiguration(AgentBuilderState builderState, String format) {
    // TODO: Implement configuration export
    print('Exporting configuration as $format');
    print('Configuration: ${builderState.toJson()}');
  }
}