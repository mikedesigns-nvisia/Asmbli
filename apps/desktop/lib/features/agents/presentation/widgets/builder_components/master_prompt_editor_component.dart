import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_system/design_system.dart';
import '../../../models/agent_builder_state.dart';
import '../../screens/agent_builder_screen.dart';

/// Master Prompt Editor Component - Advanced prompt crafting with templates
class MasterPromptEditorComponent extends ConsumerStatefulWidget {
  const MasterPromptEditorComponent({super.key});

  @override
  ConsumerState<MasterPromptEditorComponent> createState() => _MasterPromptEditorComponentState();
}

class _MasterPromptEditorComponentState extends ConsumerState<MasterPromptEditorComponent> {
  final _systemPromptController = TextEditingController();
  final _personalityController = TextEditingController();
  final _toneController = TextEditingController();
  final _expertiseController = TextEditingController();

  String _selectedTemplate = 'custom';

  final Map<String, String> _promptTemplates = {
    'custom': 'Start from scratch with a custom prompt',
    'research_assistant': '''You are a highly capable research assistant specialized in gathering, analyzing, and synthesizing information from various sources.

Your core capabilities include:
- Conducting thorough research using available tools
- Analyzing data and identifying key insights
- Synthesizing complex information into clear summaries
- Fact-checking and verifying information accuracy
- Providing well-structured, evidence-based responses

Always cite your sources and be transparent about the limitations of your research.''',
    'code_reviewer': '''You are an expert code reviewer with deep knowledge of software engineering best practices.

Your responsibilities include:
- Reviewing code for bugs, security issues, and performance problems
- Ensuring adherence to coding standards and conventions
- Suggesting improvements for maintainability and readability
- Providing constructive feedback with specific examples
- Identifying potential edge cases and error conditions

Focus on being thorough but constructive in your reviews.''',
    'data_analyst': '''You are a skilled data analyst who excels at extracting insights from complex datasets.

Your expertise covers:
- Data cleaning and preprocessing
- Statistical analysis and visualization
- Pattern recognition and trend identification
- Hypothesis testing and validation
- Clear communication of findings to stakeholders

Always explain your methodology and the reasoning behind your conclusions.''',
    'content_creator': '''You are a creative content specialist who produces engaging, high-quality content across various formats.

Your skills include:
- Writing compelling copy for different audiences
- Creating structured content outlines and strategies
- Adapting tone and style to match brand guidelines
- Optimizing content for specific platforms and purposes
- Ensuring accuracy and fact-checking all claims

Focus on creating valuable, original content that resonates with the target audience.''',
  };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final builderState = ref.read(agentBuilderStateProvider);
      _systemPromptController.text = builderState.systemPrompt;
      _personalityController.text = builderState.personality;
      _toneController.text = builderState.tone;
      _expertiseController.text = builderState.expertise;
    });
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    _personalityController.dispose();
    _toneController.dispose();
    _expertiseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                // Left side - Template selection and personality
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildTemplateSelector(colors),
                      const SizedBox(height: SpacingTokens.lg),
                      _buildPersonalitySettings(builderState, colors),
                    ],
                  ),
                ),

                const SizedBox(width: SpacingTokens.lg),

                // Right side - Main prompt editor
                Expanded(
                  flex: 2,
                  child: _buildPromptEditor(builderState, colors),
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
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          ),
          child: Icon(
            Icons.edit_note,
            color: colors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Master Prompt Configuration',
              style: TextStyles.titleLarge.copyWith(color: colors.onSurface),
            ),
            Text(
              'Define your agent\'s behavior and personality',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateSelector(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_snippet_outlined, color: colors.accent, size: 20),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Prompt Templates',
                  style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            ..._promptTemplates.entries.map((entry) {
              final isSelected = _selectedTemplate == entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTemplate = entry.key;
                      if (entry.key != 'custom') {
                        _systemPromptController.text = entry.value;
                        ref.read(agentBuilderStateProvider).updateSystemPrompt(entry.value);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withOpacity(0.1)
                          : colors.surface,
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : colors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTemplateDisplayName(entry.key),
                          style: TextStyles.bodyMedium.copyWith(
                            color: isSelected ? colors.primary : colors.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (entry.key == 'custom')
                          Text(
                            entry.value,
                            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalitySettings(AgentBuilderState builderState, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: colors.accent, size: 20),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Personality Traits',
                  style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            _buildPersonalityField(
              'Personality',
              _personalityController,
              'e.g., Professional, Friendly, Analytical',
              builderState.updatePersonality,
              colors,
            ),

            const SizedBox(height: SpacingTokens.md),

            _buildPersonalityField(
              'Tone',
              _toneController,
              'e.g., Conversational, Formal, Enthusiastic',
              builderState.updateTone,
              colors,
            ),

            const SizedBox(height: SpacingTokens.md),

            _buildPersonalityField(
              'Expertise Level',
              _expertiseController,
              'e.g., Expert, Beginner-friendly, Academic',
              builderState.updateExpertise,
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityField(
    String label,
    TextEditingController controller,
    String hint,
    Function(String) onChanged,
    ThemeColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
          ),
          style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPromptEditor(AgentBuilderState builderState, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: colors.primary, size: 20),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'System Prompt',
                  style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                ),
                const Spacer(),
                Text(
                  '${_systemPromptController.text.length} characters',
                  style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            Container(
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: TextField(
                controller: _systemPromptController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: 'Define your agent\'s core behavior, capabilities, and instructions...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(SpacingTokens.md),
                ),
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontFamily: 'monospace',
                ),
                onChanged: (value) {
                  builderState.updateSystemPrompt(value);
                  setState(() {}); // Update character count
                },
              ),
            ),

            const SizedBox(height: SpacingTokens.md),

            // Prompt tips
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.accent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: colors.accent, size: 16),
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        'Prompt Writing Tips',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    '• Be specific about the agent\'s role and capabilities\n'
                    '• Include examples of desired behavior\n'
                    '• Define how the agent should handle edge cases\n'
                    '• Specify the format and style of responses',
                    style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            if (builderState.validationErrors[AgentBuilderStep.masterPrompt]?.isNotEmpty == true)
              _buildValidationErrors(builderState, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationErrors(AgentBuilderState builderState, ThemeColors colors) {
    final errors = builderState.validationErrors[AgentBuilderStep.masterPrompt] ?? [];

    return Container(
      margin: const EdgeInsets.only(top: SpacingTokens.md),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 20),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Please fix the following:',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          ...errors.map((error) => Padding(
            padding: const EdgeInsets.only(left: SpacingTokens.lg),
            child: Text(
              '• $error',
              style: TextStyles.bodySmall.copyWith(color: colors.error),
            ),
          )).toList(),
        ],
      ),
    );
  }

  String _getTemplateDisplayName(String key) {
    switch (key) {
      case 'custom': return 'Custom Prompt';
      case 'research_assistant': return 'Research Assistant';
      case 'code_reviewer': return 'Code Reviewer';
      case 'data_analyst': return 'Data Analyst';
      case 'content_creator': return 'Content Creator';
      default: return key;
    }
  }
}