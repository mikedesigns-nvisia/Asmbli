import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/design_system/design_system.dart';
import '../../../../../core/constants/routes.dart';
import '../../../../orchestration/models/reasoning_workflow.dart';
import '../../../../orchestration/models/workflow_templates.dart';
import '../../../../orchestration/providers/canvas_provider.dart';
import '../../screens/agent_builder_screen.dart';

/// Component for managing reasoning workflows in the agent builder
class ReasoningFlowsComponent extends ConsumerStatefulWidget {
  const ReasoningFlowsComponent({super.key});

  @override
  ConsumerState<ReasoningFlowsComponent> createState() => _ReasoningFlowsComponentState();
}

class _ReasoningFlowsComponentState extends ConsumerState<ReasoningFlowsComponent> {
  final List<ReasoningWorkflow> _availableWorkflows = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableWorkflows();
  }

  void _loadAvailableWorkflows() {
    // Load template workflows as available options
    final templates = WorkflowTemplates.getAllTemplates();
    _availableWorkflows.clear();
    _availableWorkflows.addAll(templates.map((template) => template.workflow));
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final builderState = ref.watch(agentBuilderStateProvider);

    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.account_tree,
                  color: colors.primary,
                  size: 24,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Reasoning Flows',
                  style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Open Visual Reasoning Studio',
                  child: IconButton(
                    onPressed: _openReasoningStudio,
                    icon: Icon(Icons.launch, color: colors.primary),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: SpacingTokens.sm),
            
            Text(
              'Add visual reasoning workflows to enhance your agent\'s problem-solving capabilities.',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),

            const SizedBox(height: SpacingTokens.lg),

            // Enable reasoning flows toggle
            _buildReasoningFlowsToggle(builderState, colors),

            if (builderState.enableReasoningFlows) ...[
              const SizedBox(height: SpacingTokens.lg),
              
              // Enhanced reasoning flow selector
              _buildReasoningFlowSelector(builderState, colors),
              
              const SizedBox(height: SpacingTokens.lg),
              
              // Quick templates section
              _buildQuickTemplatesSection(builderState, colors),
              
              const SizedBox(height: SpacingTokens.lg),
              
              // Attached workflows section
              _buildAttachedWorkflowsSection(builderState, colors),
              
              const SizedBox(height: SpacingTokens.lg),
              
              // Default workflow selection
              _buildDefaultWorkflowSection(builderState, colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReasoningFlowsToggle(builderState, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Switch(
            value: builderState.enableReasoningFlows,
            onChanged: (value) {
              ref.read(agentBuilderStateProvider).updateEnableReasoningFlows(value);
            },
            activeColor: colors.primary,
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Reasoning Flows',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Allow this agent to use visual reasoning workflows for complex tasks',
                  style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasoningFlowSelector(builderState, ThemeColors colors) {
    final availableFlows = [
      {
        'id': 'simple_reasoning',
        'name': 'Simple Reasoning',
        'description': 'Basic goal → context → reasoning flow',
        'icon': Icons.linear_scale,
        'complexity': 'Beginner',
        'useCases': ['Quick decisions', 'Basic analysis'],
      },
      {
        'id': 'decision_gateway',
        'name': 'Decision Gateway',
        'description': 'Multi-path decision making with conditional logic',
        'icon': Icons.device_hub,
        'complexity': 'Intermediate',
        'useCases': ['Complex decisions', 'Branching logic'],
      },
      {
        'id': 'research_analysis',
        'name': 'Research & Analysis',
        'description': 'Deep research with iterative analysis and validation',
        'icon': Icons.search,
        'complexity': 'Advanced',
        'useCases': ['Research tasks', 'Data analysis'],
      },
      {
        'id': 'problem_solving',
        'name': 'Problem Solving',
        'description': 'Systematic problem breakdown and solution generation',
        'icon': Icons.engineering,
        'complexity': 'Advanced',
        'useCases': ['Complex problems', 'Technical issues'],
      },
      {
        'id': 'conversation_design',
        'name': 'Conversation Design',
        'description': 'Interactive dialogue management with context awareness',
        'icon': Icons.chat_bubble_outline,
        'complexity': 'Intermediate',
        'useCases': ['Chat flows', 'User interaction'],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Reasoning Flow',
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Choose the main reasoning pattern for your agent. You can add additional flows below.',
          style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: SpacingTokens.md),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
          child: DropdownButtonFormField<String>(
            value: builderState.defaultReasoningWorkflowId,
            decoration: const InputDecoration(
              labelText: 'Select Reasoning Flow',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(SpacingTokens.md),
            ),
            isExpanded: true,
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'None - Agent will respond directly',
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
              ...availableFlows.map((flow) {
                return DropdownMenuItem<String>(
                  value: flow['id'] as String,
                  child: _buildFlowDropdownItem(flow, colors),
                );
              }),
            ],
            onChanged: (value) {
              ref.read(agentBuilderStateProvider).setDefaultReasoningWorkflow(value);
              if (value != null) {
                // Also add to the workflow list if not already present
                ref.read(agentBuilderStateProvider).addReasoningWorkflow(value);
              }
            },
          ),
        ),
        
        if (builderState.defaultReasoningWorkflowId != null) ...[
          const SizedBox(height: SpacingTokens.md),
          _buildSelectedFlowInfo(builderState.defaultReasoningWorkflowId!, availableFlows, colors),
        ],
      ],
    );
  }

  Widget _buildFlowDropdownItem(Map<String, dynamic> flow, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(
        children: [
          Icon(
            flow['icon'] as IconData,
            size: 20,
            color: colors.primary,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flow['name'] as String,
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  flow['description'] as String,
                  style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.xs,
              vertical: SpacingTokens.xxs,
            ),
            decoration: BoxDecoration(
              color: _getComplexityColor(flow['complexity'] as String, colors),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
            ),
            child: Text(
              flow['complexity'] as String,
              style: TextStyles.caption.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFlowInfo(String flowId, List<Map<String, dynamic>> availableFlows, ThemeColors colors) {
    final flow = availableFlows.firstWhere(
      (f) => f['id'] == flowId,
      orElse: () => {'name': 'Unknown Flow', 'description': '', 'useCases': []},
    );

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: colors.primary,
                size: 16,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Selected: ${flow['name']}',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            flow['description'] as String,
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          ),
          if ((flow['useCases'] as List).isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.xs),
            Wrap(
              spacing: SpacingTokens.xs,
              children: (flow['useCases'] as List<String>).map((useCase) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.xs,
                    vertical: SpacingTokens.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    useCase,
                    style: TextStyles.caption.copyWith(color: colors.onSurface),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getComplexityColor(String complexity, ThemeColors colors) {
    switch (complexity) {
      case 'Beginner':
        return colors.success.withValues(alpha: 0.2);
      case 'Intermediate':
        return colors.warning.withValues(alpha: 0.2);
      case 'Advanced':
        return colors.error.withValues(alpha: 0.2);
      default:
        return colors.surfaceVariant;
    }
  }

  Widget _buildQuickTemplatesSection(builderState, ThemeColors colors) {
    final templates = WorkflowTemplates.getAllTemplates();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Add pre-built reasoning workflows',
          style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: SpacingTokens.md),
        
        Wrap(
          spacing: SpacingTokens.sm,
          runSpacing: SpacingTokens.sm,
          children: templates.map((template) {
            final isAdded = builderState.reasoningWorkflowIds.contains(template.id);
            
            return InkWell(
              onTap: isAdded ? null : () => _addTemplateWorkflow(template),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.sm,
                ),
                decoration: BoxDecoration(
                  color: isAdded 
                      ? colors.success.withValues(alpha: 0.1)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(
                    color: isAdded ? colors.success : colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdded ? Icons.check : Icons.add,
                      size: 16,
                      color: isAdded ? colors.success : colors.primary,
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Text(
                      template.name,
                      style: TextStyles.caption.copyWith(
                        color: isAdded ? colors.success : colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttachedWorkflowsSection(builderState, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attached Workflows',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            const Spacer(),
            AsmblButton.outline(
              text: 'Create New',
              icon: Icons.add,
              onPressed: _createNewWorkflow,
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        if (builderState.reasoningWorkflowIds.isEmpty)
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.border, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 48,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: SpacingTokens.md),
                Text(
                  'No reasoning workflows attached',
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  'Add templates above or create custom workflows',
                  style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          ...builderState.reasoningWorkflowIds.map((workflowId) {
            final workflow = _findWorkflowById(workflowId);
            final isDefault = builderState.defaultReasoningWorkflowId == workflowId;
            
            return Container(
              margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: isDefault 
                    ? colors.primary.withValues(alpha: 0.05)
                    : colors.surface,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(
                  color: isDefault ? colors.primary : colors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_tree,
                    color: isDefault ? colors.primary : colors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workflow?.name ?? workflowId,
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurface,
                            fontWeight: isDefault ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (workflow?.description != null)
                          Text(
                            workflow!.description!,
                            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                      ),
                      child: Text(
                        'DEFAULT',
                        style: TextStyles.caption.copyWith(
                          color: colors.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: SpacingTokens.sm),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      if (!isDefault)
                        PopupMenuItem(
                          value: 'set_default',
                          child: ListTile(
                            leading: Icon(Icons.star, size: 16),
                            title: Text('Set as Default'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 16),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          leading: Icon(Icons.remove, size: 16, color: colors.error),
                          title: Text('Remove', style: TextStyle(color: colors.error)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleWorkflowAction(workflowId, value as String),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildDefaultWorkflowSection(builderState, ThemeColors colors) {
    if (builderState.reasoningWorkflowIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default Workflow',
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Choose which workflow runs automatically for complex queries',
          style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: SpacingTokens.md),
        
        DropdownButtonFormField<String>(
          value: builderState.defaultReasoningWorkflowId,
          decoration: InputDecoration(
            labelText: 'Default Workflow',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'None (manual selection)',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            ...builderState.reasoningWorkflowIds.map((workflowId) {
              final workflow = _findWorkflowById(workflowId);
              return DropdownMenuItem<String>(
                value: workflowId,
                child: Text(
                  workflow?.name ?? workflowId,
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                ),
              );
            }),
          ],
          onChanged: (value) {
            ref.read(agentBuilderStateProvider).setDefaultReasoningWorkflow(value);
          },
        ),
      ],
    );
  }

  ReasoningWorkflow? _findWorkflowById(String workflowId) {
    try {
      return _availableWorkflows.firstWhere((w) => w.id == workflowId);
    } catch (e) {
      return null;
    }
  }

  void _addTemplateWorkflow(WorkflowTemplate template) {
    ref.read(agentBuilderStateProvider).addReasoningWorkflow(template.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${template.name} added to agent',
          style: TextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: ThemeColors(context).success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _createNewWorkflow() {
    // Navigate to reasoning studio to create new workflow
    context.push('${AppRoutes.orchestration}?mode=create');
  }

  void _openReasoningStudio() {
    // Navigate to reasoning studio
    context.push(AppRoutes.orchestration);
  }

  void _handleWorkflowAction(String workflowId, String action) {
    final builderState = ref.read(agentBuilderStateProvider);
    
    switch (action) {
      case 'set_default':
        builderState.setDefaultReasoningWorkflow(workflowId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Default workflow updated'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
        break;
      case 'edit':
        context.push('${AppRoutes.orchestration}?edit=$workflowId');
        break;
      case 'remove':
        builderState.removeReasoningWorkflow(workflowId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow removed from agent'),
            backgroundColor: ThemeColors(context).warning,
          ),
        );
        break;
    }
  }
}