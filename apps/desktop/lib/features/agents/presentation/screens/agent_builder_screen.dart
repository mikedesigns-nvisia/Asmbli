import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../providers/agent_provider.dart';
import '../../models/agent_builder_state.dart';
import '../widgets/builder_components/basic_info_component.dart';
import '../widgets/builder_components/master_prompt_editor_component.dart';
import '../widgets/builder_components/tool_selector_component.dart';
import '../widgets/builder_components/context_library_component.dart';
import '../widgets/builder_components/model_config_component.dart';
import '../widgets/builder_components/testing_panel_component.dart';
import '../widgets/builder_components/review_component.dart';

/// Provider for the agent builder state
final agentBuilderStateProvider = ChangeNotifierProvider<AgentBuilderState>((ref) {
  return AgentBuilderState();
});

/// Dynamic Agent Builder Screen - The main coordinator for agent creation/editing
class AgentBuilderScreen extends ConsumerStatefulWidget {
  final String? agentId;
  final AgentBuilderMode? initialMode;

  const AgentBuilderScreen({
    super.key,
    this.agentId,
    this.initialMode,
  });

  @override
  ConsumerState<AgentBuilderScreen> createState() => _AgentBuilderScreenState();
}

class _AgentBuilderScreenState extends ConsumerState<AgentBuilderScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBuilder();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeBuilder() async {
    final builderState = ref.read(agentBuilderStateProvider);

    if (widget.agentId != null) {
      // Editing existing agent
      try {
        final agentService = ref.read(agentServiceProvider);
        final agent = await agentService.getAgent(widget.agentId!);
        if (agent != null) {
          builderState.startEditing(widget.agentId!, agent);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load agent: $e')),
          );
        }
      }
    } else {
      // Creating new agent
      builderState.startNewAgent();
    }

    // Set initial mode
    if (widget.initialMode != null) {
      builderState.setMode(widget.initialMode!);
    }

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final builderState = ref.watch(agentBuilderStateProvider);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.backgroundGradientStart,
                  colors.backgroundGradientMiddle,
                  colors.backgroundGradientEnd,
                ],
              ),
            ),
            child: Column(
              children: [
                // Header with mode selection and navigation
                _buildHeader(builderState, colors),

                // Main content area
                Expanded(
                  child: _buildContent(builderState, colors),
                ),

                // Footer with navigation and actions
                _buildFooter(builderState, colors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AgentBuilderState builderState, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.headerPadding),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity( 0.8),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
            onPressed: () => _handleBack(),
          ),

          const SizedBox(width: SpacingTokens.md),

          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                builderState.isEditing ? 'Edit Agent' : 'Create New Agent',
                style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
              ),
              if (builderState.name.isNotEmpty)
                Text(
                  builderState.name,
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
            ],
          ),

          const Spacer(),

          // Mode selector
          _buildModeSelector(builderState, colors),

          const SizedBox(width: SpacingTokens.lg),

          // Action buttons
          Row(
            children: [
              if (builderState.hasUnsavedChanges)
                AsmblButton.secondary(
                  text: 'Save Draft',
                  icon: Icons.save,
                  onPressed: () => _saveDraft(),
                ),

              const SizedBox(width: SpacingTokens.md),

              AsmblButton.primary(
                text: builderState.isEditing ? 'Update Agent' : 'Create Agent',
                icon: Icons.check,
                onPressed: builderState.isConfigurationValid
                    ? () => _createOrUpdateAgent()
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(AgentBuilderState builderState, ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AgentBuilderMode.values.map((mode) {
          final isSelected = builderState.mode == mode;
          return InkWell(
            onTap: () => builderState.setMode(mode),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary.withOpacity( 0.1) : null,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getModeIcon(mode),
                    size: 16,
                    color: isSelected ? colors.primary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    _getModeLabel(mode),
                    style: TextStyles.bodySmall.copyWith(
                      color: isSelected ? colors.primary : colors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(AgentBuilderState builderState, ThemeColors colors) {
    switch (builderState.mode) {
      case AgentBuilderMode.wizard:
        return _buildWizardMode(builderState, colors);
      case AgentBuilderMode.dashboard:
        return _buildDashboardMode(builderState, colors);
      case AgentBuilderMode.template:
        return _buildTemplateMode(builderState, colors);
    }
  }

  Widget _buildWizardMode(AgentBuilderState builderState, ThemeColors colors) {
    return Column(
      children: [
        // Step indicator
        _buildStepIndicator(builderState, colors),

        // Step content
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              builderState.setCurrentStep(AgentBuilderStep.values[index]);
              _tabController.animateTo(index);
            },
            children: [
              BasicInfoComponent(),
              MasterPromptEditorComponent(),
              ToolSelectorComponent(),
              ContextLibraryComponent(),
              ModelConfigComponent(),
              TestingPanelComponent(),
              ReviewComponent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardMode(AgentBuilderState builderState, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Row(
        children: [
          // Left column
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: BasicInfoComponent()),
                const SizedBox(height: SpacingTokens.lg),
                Expanded(child: MasterPromptEditorComponent()),
              ],
            ),
          ),

          const SizedBox(width: SpacingTokens.lg),

          // Middle column
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: ToolSelectorComponent()),
                const SizedBox(height: SpacingTokens.lg),
                Expanded(child: ContextLibraryComponent()),
              ],
            ),
          ),

          const SizedBox(width: SpacingTokens.lg),

          // Right column
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: ModelConfigComponent()),
                const SizedBox(height: SpacingTokens.lg),
                Expanded(child: TestingPanelComponent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateMode(AgentBuilderState builderState, ThemeColors colors) {
    // TODO: Implement template selection mode
    return Center(
      child: Text(
        'Template Mode - Coming Soon',
        style: TextStyles.titleLarge.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }

  Widget _buildStepIndicator(AgentBuilderState builderState, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Row(
        children: AgentBuilderStep.values.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isActive = builderState.currentStep == step;
          final isCompleted = index < AgentBuilderStep.values.indexOf(builderState.currentStep);
          final isValid = builderState.isStepValid(step);

          return Expanded(
            child: InkWell(
              onTap: () => _goToStep(step),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primary.withOpacity( 0.1)
                      : isCompleted
                          ? colors.accent.withOpacity( 0.1)
                          : colors.surface.withOpacity( 0.5),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  border: Border.all(
                    color: isActive
                        ? colors.primary
                        : isCompleted
                            ? colors.accent
                            : !isValid
                                ? colors.error
                                : colors.border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStepIcon(step),
                      size: 16,
                      color: isActive
                          ? colors.primary
                          : isCompleted
                              ? colors.accent
                              : !isValid
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      _getStepLabel(step),
                      style: TextStyles.caption.copyWith(
                        color: isActive
                            ? colors.primary
                            : isCompleted
                                ? colors.accent
                                : !isValid
                                    ? colors.error
                                    : colors.onSurfaceVariant,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(AgentBuilderState builderState, ThemeColors colors) {
    if (builderState.mode != AgentBuilderMode.wizard) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity( 0.8),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Step info
          Text(
            'Step ${AgentBuilderStep.values.indexOf(builderState.currentStep) + 1} of ${AgentBuilderStep.values.length}',
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),

          const Spacer(),

          // Navigation buttons
          if (builderState.currentStep != AgentBuilderStep.basicInfo)
            AsmblButton.secondary(
              text: 'Previous',
              icon: Icons.arrow_back,
              onPressed: () => _previousStep(),
            ),

          const SizedBox(width: SpacingTokens.md),

          if (builderState.currentStep != AgentBuilderStep.review)
            AsmblButton.primary(
              text: 'Next',
              icon: Icons.arrow_forward,
              onPressed: builderState.isStepValid(builderState.currentStep)
                  ? () => _nextStep()
                  : null,
            ),
        ],
      ),
    );
  }

  // Helper Methods
  IconData _getModeIcon(AgentBuilderMode mode) {
    switch (mode) {
      case AgentBuilderMode.wizard: return Icons.assistant;
      case AgentBuilderMode.dashboard: return Icons.dashboard;
      case AgentBuilderMode.template: return Icons.library_books;
    }
  }

  String _getModeLabel(AgentBuilderMode mode) {
    switch (mode) {
      case AgentBuilderMode.wizard: return 'Wizard';
      case AgentBuilderMode.dashboard: return 'Dashboard';
      case AgentBuilderMode.template: return 'Template';
    }
  }

  IconData _getStepIcon(AgentBuilderStep step) {
    switch (step) {
      case AgentBuilderStep.basicInfo: return Icons.info;
      case AgentBuilderStep.masterPrompt: return Icons.edit_note;
      case AgentBuilderStep.tools: return Icons.extension;
      case AgentBuilderStep.context: return Icons.library_books;
      case AgentBuilderStep.modelConfig: return Icons.settings;
      case AgentBuilderStep.testing: return Icons.science;
      case AgentBuilderStep.review: return Icons.preview;
    }
  }

  String _getStepLabel(AgentBuilderStep step) {
    switch (step) {
      case AgentBuilderStep.basicInfo: return 'Basic Info';
      case AgentBuilderStep.masterPrompt: return 'Prompt';
      case AgentBuilderStep.tools: return 'Tools';
      case AgentBuilderStep.context: return 'Context';
      case AgentBuilderStep.modelConfig: return 'Model';
      case AgentBuilderStep.testing: return 'Testing';
      case AgentBuilderStep.review: return 'Review';
    }
  }

  // Navigation Methods
  void _goToStep(AgentBuilderStep step) {
    final builderState = ref.read(agentBuilderStateProvider);
    builderState.setCurrentStep(step);
    _pageController.animateToPage(
      AgentBuilderStep.values.indexOf(step),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    final builderState = ref.read(agentBuilderStateProvider);
    builderState.nextStep();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    final builderState = ref.read(agentBuilderStateProvider);
    builderState.previousStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Action Methods
  void _handleBack() async {
    final builderState = ref.read(agentBuilderStateProvider);

    if (builderState.hasUnsavedChanges) {
      final shouldDiscard = await _showUnsavedChangesDialog();
      if (shouldDiscard != true) return;
    }

    if (mounted) {
      context.go(AppRoutes.agents);
    }
  }

  Future<bool?> _showUnsavedChangesDialog() {
    final colors = ThemeColors(context);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unsaved Changes'),
        content: Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          AsmblButton.secondary(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AsmblButton.primary(
            text: 'Discard',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft() async {
    // TODO: Implement draft saving
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved successfully')),
    );
  }

  Future<void> _createOrUpdateAgent() async {
    final builderState = ref.read(agentBuilderStateProvider);
    final agentNotifier = ref.read(agentNotifierProvider.notifier);

    try {
      final agent = builderState.toAgent();

      if (builderState.isEditing) {
        await agentNotifier.updateAgent(agent);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agent updated successfully')),
          );
        }
      } else {
        await agentNotifier.createAgent(agent);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agent created successfully')),
          );
        }
      }

      builderState.markSaved();

      if (mounted) {
        context.go(AppRoutes.agents);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save agent: $e')),
        );
      }
    }
  }
}