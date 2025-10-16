import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_system/design_system.dart';
import '../../../../../core/services/agent_tool_recommendation_service.dart';
import '../../../models/agent_builder_state.dart';
import '../../screens/agent_builder_screen.dart';
import '../recommended_tools_widget.dart';

/// Basic Information Component for Agent Builder
/// Handles name, description, category selection with live tool recommendations
class BasicInfoComponent extends ConsumerStatefulWidget {
  const BasicInfoComponent({super.key});

  @override
  ConsumerState<BasicInfoComponent> createState() => _BasicInfoComponentState();
}

class _BasicInfoComponentState extends ConsumerState<BasicInfoComponent> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final builderState = ref.read(agentBuilderStateProvider);
      _nameController.text = builderState.name;
      _descriptionController.text = builderState.description;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
            // Header
            _buildSectionHeader(colors),

            const SizedBox(height: SpacingTokens.sectionSpacing),

            // Main content in cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Basic info form
                Expanded(
                  flex: 2,
                  child: _buildBasicInfoForm(builderState, colors),
                ),

                const SizedBox(width: SpacingTokens.lg),

                // Right side - Category preview and recommendations
                Expanded(
                  flex: 1,
                  child: _buildCategoryPreview(builderState, colors),
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
            Icons.info_outline,
            color: colors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agent Basic Information',
              style: TextStyles.titleLarge.copyWith(color: colors.onSurface),
            ),
            Text(
              'Define your agent\'s identity and specialization',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicInfoForm(AgentBuilderState builderState, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agent Name
            Text(
              'Agent Name *',
              style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.sm),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Research Assistant, Code Reviewer, Data Analyst',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
                filled: true,
                fillColor: colors.surface,
              ),
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
              onChanged: (value) {
                builderState.updateName(value);
              },
            ),

            const SizedBox(height: SpacingTokens.lg),

            // Agent Description
            Text(
              'Description *',
              style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.sm),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe what your agent does and how it helps users...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
                filled: true,
                fillColor: colors.surface,
              ),
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
              onChanged: (value) {
                builderState.updateDescription(value);
              },
            ),

            const SizedBox(height: SpacingTokens.lg),

            // Category Selection
            Text(
              'Category *',
              style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.sm),
            _buildCategorySelector(builderState, colors),

            const SizedBox(height: SpacingTokens.lg),

            // Validation Errors
            if (builderState.validationErrors[AgentBuilderStep.basicInfo]?.isNotEmpty == true)
              _buildValidationErrors(builderState, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(AgentBuilderState builderState, ThemeColors colors) {
    final toolRecommendationService = ref.read(toolRecommendationServiceProvider);
    final availableCategories = toolRecommendationService.getAvailableCategories();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: availableCategories.length,
        itemBuilder: (context, index) {
          final category = availableCategories[index];
          final isSelected = builderState.category == category;
          final toolCount = toolRecommendationService.getRecommendedToolCount(category);

          return InkWell(
            onTap: () => builderState.updateCategory(category),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.1)
                    : colors.surface,
                border: isSelected
                    ? Border.all(color: colors.primary, width: 2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: isSelected ? colors.primary : colors.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      category,
                      style: TextStyles.bodySmall.copyWith(
                        color: isSelected ? colors.primary : colors.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (toolCount > 0)
                      Text(
                        '$toolCount tools',
                        style: TextStyles.caption.copyWith(
                          color: isSelected ? colors.primary : colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryPreview(AgentBuilderState builderState, ThemeColors colors) {
    return Column(
      children: [
        // Category overview card
        AsmblCard(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(builderState.category),
                      color: colors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      builderState.category,
                      style: TextStyles.titleMedium.copyWith(color: colors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),
                Text(
                  ref.read(toolRecommendationServiceProvider).getCategoryDescription(builderState.category),
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: SpacingTokens.md),

        // Recommended tools preview
        _buildToolsPreview(builderState, colors),
      ],
    );
  }

  Widget _buildToolsPreview(AgentBuilderState builderState, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.extension,
                  color: colors.accent,
                  size: 20,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Recommended Tools',
                  style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            // Show first few recommended tools
            Consumer(
              builder: (context, ref, child) {
                final toolService = ref.read(toolRecommendationServiceProvider);
                return FutureBuilder(
                  future: toolService.getRecommendedToolsForCategory(builderState.category),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Text(
                        'No recommendations available',
                        style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                      );
                    }

                    final tools = snapshot.data!.take(3).toList();

                    return Column(
                      children: tools.map((tool) => Padding(
                        padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: SpacingTokens.sm),
                            Expanded(
                              child: Text(
                                tool.name,
                                style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: SpacingTokens.md),

            Text(
              'Configure tools in the next step',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationErrors(AgentBuilderState builderState, ThemeColors colors) {
    final errors = builderState.validationErrors[AgentBuilderStep.basicInfo] ?? [];

    return Container(
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Research': return Icons.search;
      case 'Development': return Icons.code;
      case 'Data Analysis': return Icons.analytics;
      case 'Writing': return Icons.edit;
      case 'Automation': return Icons.smart_toy;
      case 'DevOps': return Icons.cloud;
      case 'Business': return Icons.business;
      case 'Education': return Icons.school;
      case 'Content Creation': return Icons.create;
      case 'Customer Support': return Icons.support_agent;
      default: return Icons.category;
    }
  }
}