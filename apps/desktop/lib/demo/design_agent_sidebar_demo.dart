import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system/design_system.dart';
import '../features/agents/presentation/widgets/design_agent_sidebar.dart';
import '../features/agents/presentation/widgets/design_context_dropdown.dart';
import '../features/agents/presentation/widgets/dynamic_context_panel.dart';
import 'package:agent_engine_core/models/agent.dart';

/// Demo screen showcasing the complete design agent sidebar system
class DesignAgentSidebarDemo extends ConsumerStatefulWidget {
  const DesignAgentSidebarDemo({super.key});

  @override
  ConsumerState<DesignAgentSidebarDemo> createState() => _DesignAgentSidebarDemoState();
}

class _DesignAgentSidebarDemoState extends ConsumerState<DesignAgentSidebarDemo> {
  Map<String, dynamic> _currentSpec = {};
  List<String> _currentContext = [];
  List<ContextItem> _contextItems = [];
  bool _showDynamicPanel = false;

  // Mock design agent
  late Agent _designAgent;

  @override
  void initState() {
    super.initState();
    _designAgent = Agent(
      id: 'design-agent-demo',
      name: 'UI/UX Design Assistant',
      description: 'Expert design agent with dual-model configuration for planning and vision analysis',
      capabilities: ['ui_design', 'user_research', 'prototyping', 'design_systems'],
      status: AgentStatus.idle,
      configuration: {
        'type': 'design_agent',
        'modelConfiguration': {
          'primaryModelId': 'local_deepseek-r1_32b',
          'visionModelId': 'local_llava_13b',
        },
      },
    );

    // Initialize with default empty specs to trigger generation prompt
    _currentSpec = {};
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Row(
          children: [
            // Main content area
            Expanded(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(SpacingTokens.md),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                          ),
                          child: Icon(
                            Icons.design_services,
                            color: colors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Design Agent Sidebar Demo',
                                style: TextStyles.pageTitle,
                              ),
                              const SizedBox(height: SpacingTokens.xs),
                              Text(
                                'AI-generated specifications required before design work begins',
                                style: TextStyles.bodyMedium.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Workflow status indicator
                  _buildWorkflowStatus(colors),

                  // Demo content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(SpacingTokens.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - Context dropdowns
                          Expanded(
                            flex: 2,
                            child: _buildDemoContent(colors),
                          ),
                          
                          const SizedBox(width: SpacingTokens.lg),
                          
                          // Right column - Dynamic context panel (when shown)
                          if (_showDynamicPanel)
                            Expanded(
                              flex: 2,
                              child: DynamicContextPanel(
                                onContextUpdate: (items) {
                                  setState(() {
                                    _contextItems.addAll(items);
                                    _showDynamicPanel = false;
                                  });
                                },
                                existingContext: _contextItems,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Footer with current state
                  _buildFooter(colors),
                ],
              ),
            ),

            // Sidebar
            DesignAgentSidebar(
              agent: _designAgent,
              onSpecUpdate: (spec) {
                setState(() {
                  _currentSpec = spec;
                });
              },
              onContextUpdate: (context) {
                setState(() {
                  _currentContext = context;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowStatus(ThemeColors colors) {
    final hasSpecs = _currentSpec.isNotEmpty && _currentSpec['projectType'] != 'web_app';
    final hasContext = _contextItems.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatusStep(
            'Generate Specs',
            hasSpecs,
            Icons.assignment,
            colors,
            isFirst: true,
          ),
          _buildStatusConnector(colors),
          _buildStatusStep(
            'Add Context',
            hasContext,
            Icons.folder_open,
            colors,
          ),
          _buildStatusConnector(colors),
          _buildStatusStep(
            'Design Ready',
            hasSpecs && hasContext,
            Icons.rocket_launch,
            colors,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(
    String title,
    bool isComplete,
    IconData icon,
    ThemeColors colors, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: isComplete 
                ? colors.success 
                : colors.onSurfaceVariant.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          ),
          child: Icon(
            isComplete ? Icons.check : icon,
            color: isComplete ? Colors.white : colors.onSurfaceVariant,
            size: 20,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          title,
          style: TextStyles.caption.copyWith(
            color: isComplete ? colors.success : colors.onSurfaceVariant,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusConnector(ThemeColors colors) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: colors.border,
    );
  }

  Widget _buildDemoContent(ThemeColors colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AsmblCard(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette, color: colors.accent, size: 24),
                      const SizedBox(width: SpacingTokens.sm),
                      Text(
                        'Context Dropdowns Demo',
                        style: TextStyles.sectionTitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  
                  Text(
                    'These dropdowns allow designers to quickly add various types of context with templates and file uploads.',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xl),

                  // Brand Guidelines Dropdown
                  DesignContextDropdown(
                    label: 'Brand Guidelines',
                    contextType: 'brand_guidelines',
                    items: _getContextItemsForType('brand_guidelines'),
                    onItemSelected: (item) {
                      _showSnackBar('Selected: ${item.name}', colors);
                    },
                    onItemAdded: (item) {
                      setState(() {
                        _contextItems.add(item);
                      });
                      _showSnackBar('Added: ${item.name}', colors);
                    },
                  ),
                  const SizedBox(height: SpacingTokens.lg),

                  // Design System Dropdown
                  DesignContextDropdown(
                    label: 'Design System',
                    contextType: 'design_system',
                    items: _getContextItemsForType('design_system'),
                    onItemSelected: (item) {
                      _showSnackBar('Selected: ${item.name}', colors);
                    },
                    onItemAdded: (item) {
                      setState(() {
                        _contextItems.add(item);
                      });
                      _showSnackBar('Added: ${item.name}', colors);
                    },
                  ),
                  const SizedBox(width: SpacingTokens.lg),

                  // User Personas Dropdown
                  DesignContextDropdown(
                    label: 'User Personas',
                    contextType: 'user_personas',
                    items: _getContextItemsForType('user_personas'),
                    onItemSelected: (item) {
                      _showSnackBar('Selected: ${item.name}', colors);
                    },
                    onItemAdded: (item) {
                      setState(() {
                        _contextItems.add(item);
                      });
                      _showSnackBar('Added: ${item.name}', colors);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.xl),

          // Dynamic Context Panel Demo
          AsmblCard(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dynamic_form, color: colors.primary, size: 24),
                      const SizedBox(width: SpacingTokens.sm),
                      Text(
                        'Dynamic Context Panel',
                        style: TextStyles.sectionTitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  
                  Text(
                    'The dynamic panel organizes context types into categories and provides guided context addition.',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),

                  Center(
                    child: AsmblButton.primary(
                      text: _showDynamicPanel ? 'Hide Context Panel' : 'Show Context Panel',
                      onPressed: () {
                        setState(() {
                          _showDynamicPanel = !_showDynamicPanel;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: SpacingTokens.xl),

          // Added Context Items
          if (_contextItems.isNotEmpty) ...[
            AsmblCard(
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder, color: colors.success, size: 24),
                        const SizedBox(width: SpacingTokens.sm),
                        Text(
                          'Added Context Items (${_contextItems.length})',
                          style: TextStyles.sectionTitle,
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.lg),
                    
                    ..._contextItems.map((item) => _buildContextItemDisplay(item, colors)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContextItemDisplay(ContextItem item, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.xs),
            decoration: BoxDecoration(
              color: _getTypeColor(item.type, colors).withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              _getTypeIcon(item.type),
              size: 16,
              color: _getTypeColor(item.type, colors),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (item.isTemplate)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Text(
                'Template',
                style: TextStyles.caption.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (item.isFile)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Text(
                'File',
                style: TextStyles.caption.copyWith(
                  color: colors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            onPressed: () {
              setState(() {
                _contextItems.remove(item);
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.9),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Current Spec Summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Specification',
                  style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: SpacingTokens.xs),
                if (_currentSpec.isNotEmpty)
                  Text(
                    'Project: ${_currentSpec['projectType'] ?? 'Not set'} • '
                    'Phase: ${_currentSpec['designPhase'] ?? 'Not set'} • '
                    'Platforms: ${(_currentSpec['platforms'] as List?)?.join(', ') ?? 'Not set'}',
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  )
                else
                  Text(
                    'Configure specifications in the sidebar →',
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: SpacingTokens.lg),
          
          // Context Summary
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Context Items: ${_contextItems.length}',
                style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                'Ready for design workflow',
                style: TextStyles.caption.copyWith(
                  color: _contextItems.isNotEmpty ? colors.success : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<ContextItem> _getContextItemsForType(String type) {
    // Return sample items for demo
    switch (type) {
      case 'brand_guidelines':
        return [
          ContextItem(
            name: 'Logo Usage Guidelines',
            type: type,
            description: 'Official logo specifications and usage rules',
          ),
          ContextItem(
            name: 'Brand Color Palette',
            type: type,
            description: 'Primary and secondary colors with hex codes',
          ),
        ];
      case 'design_system':
        return [
          ContextItem(
            name: 'Component Library',
            type: type,
            description: 'UI component specifications and patterns',
          ),
          ContextItem(
            name: 'Typography Scale',
            type: type,
            description: 'Font families, sizes, and hierarchy',
          ),
        ];
      case 'user_personas':
        return [
          ContextItem(
            name: 'Primary User Persona',
            type: type,
            description: 'Target user demographics and behavior',
          ),
          ContextItem(
            name: 'Secondary User Group',
            type: type,
            description: 'Alternative user segment analysis',
          ),
        ];
      default:
        return [];
    }
  }

  IconData _getTypeIcon(String type) {
    final icons = {
      'brand_guidelines': Icons.business,
      'design_system': Icons.dashboard,
      'user_personas': Icons.person,
      'competitor_analysis': Icons.compare,
      'constraints': Icons.warning,
    };
    return icons[type] ?? Icons.folder;
  }

  Color _getTypeColor(String type, ThemeColors colors) {
    final colorMap = {
      'brand_guidelines': colors.primary,
      'design_system': colors.accent,
      'user_personas': colors.success,
      'competitor_analysis': colors.warning,
      'constraints': colors.error,
    };
    return colorMap[type] ?? colors.onSurfaceVariant;
  }

  void _showSnackBar(String message, ThemeColors colors) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.primary,
      ),
    );
  }
}