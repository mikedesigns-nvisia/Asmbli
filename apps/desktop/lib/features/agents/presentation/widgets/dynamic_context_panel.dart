import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import 'design_context_dropdown.dart';

/// Dynamic panel for adding and managing design context
class DynamicContextPanel extends ConsumerStatefulWidget {
  final Function(List<ContextItem>) onContextUpdate;
  final List<ContextItem> existingContext;
  
  const DynamicContextPanel({
    super.key,
    required this.onContextUpdate,
    this.existingContext = const [],
  });

  @override
  ConsumerState<DynamicContextPanel> createState() => _DynamicContextPanelState();
}

class _DynamicContextPanelState extends ConsumerState<DynamicContextPanel>
    with TickerProviderStateMixin {
  late List<ContextItem> _contextItems;
  late TabController _tabController;
  
  final List<ContextCategory> _categories = [
    ContextCategory(
      id: 'brand_guidelines',
      name: 'Brand Guidelines',
      icon: Icons.business,
      description: 'Brand identity, voice, and visual guidelines',
      color: Color(0xFF6366F1),
    ),
    ContextCategory(
      id: 'design_system',
      name: 'Design System',
      icon: Icons.dashboard,
      description: 'Components, patterns, and design tokens',
      color: Color(0xFF8B5CF6),
    ),
    ContextCategory(
      id: 'user_research',
      name: 'User Research',
      icon: Icons.people,
      description: 'Personas, user journeys, and research insights',
      color: Color(0xFF06B6D4),
    ),
    ContextCategory(
      id: 'competitive_analysis',
      name: 'Competitive Analysis',
      icon: Icons.compare,
      description: 'Competitor research and market analysis',
      color: Color(0xFFEF4444),
    ),
    ContextCategory(
      id: 'technical_constraints',
      name: 'Constraints',
      icon: Icons.engineering,
      description: 'Technical limitations and requirements',
      color: Color(0xFFF59E0B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contextItems = List.from(widget.existingContext);
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _buildHeader(colors),
          _buildTabBar(colors),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return _buildCategoryContent(category, colors);
              }).toList(),
            ),
          ),
          _buildFooter(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              Icons.add_to_photos,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Design Context',
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Provide context for more accurate design assistance',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: colors.primary,
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelStyle: TextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyles.caption,
        tabs: _categories.map((category) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 16),
                const SizedBox(width: SpacingTokens.xs),
                Text(category.name),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryContent(ContextCategory category, ThemeColors colors) {
    final categoryItems = _contextItems
        .where((item) => item.type.startsWith(category.id))
        .toList();
    
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category description
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            child: Row(
              children: [
                Icon(category.icon, color: category.color, size: 20),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    category.description,
                    style: TextStyles.bodySmall.copyWith(
                      color: category.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          // Context type options
          Text(
            'Add Context',
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _getContextTypesForCategory(category).map((type) {
                  return _buildContextTypeCard(type, category, colors);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextTypeCard(ContextType type, ContextCategory category, ThemeColors colors) {
    final hasItems = _contextItems.any((item) => item.type == type.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        elevation: 0,
        child: InkWell(
          onTap: () => _showContextInput(type),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          child: Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasItems ? category.color.withOpacity(0.5) : colors.border,
              ),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: (hasItems ? category.color : colors.onSurfaceVariant)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(
                    type.icon,
                    size: 20,
                    color: hasItems ? category.color : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            type.name,
                            style: TextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                              color: hasItems ? category.color : colors.onSurface,
                            ),
                          ),
                          if (hasItems) ...[
                            const SizedBox(width: SpacingTokens.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: category.color,
                                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                              ),
                              child: Text(
                                '${_contextItems.where((item) => item.type == type.id).length}',
                                style: TextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        type.description,
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  hasItems ? Icons.edit : Icons.add_circle_outline,
                  color: hasItems ? category.color : colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_contextItems.length} context items added',
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _clearAll,
                child: Text('Clear All'),
              ),
              const SizedBox(width: SpacingTokens.sm),
              ElevatedButton(
                onPressed: _saveAndClose,
                child: Text('Apply Context'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<ContextType> _getContextTypesForCategory(ContextCategory category) {
    switch (category.id) {
      case 'brand_guidelines':
        return [
          ContextType('brand_logo', 'Logo & Symbols', Icons.logo_dev,
              'Logo files, variations, and usage guidelines'),
          ContextType('brand_colors', 'Color Palette', Icons.palette,
              'Brand colors, gradients, and color combinations'),
          ContextType('brand_typography', 'Typography', Icons.text_fields,
              'Font families, weights, and typographic hierarchy'),
          ContextType('brand_voice', 'Voice & Tone', Icons.record_voice_over,
              'Brand personality, writing style, and tone of voice'),
        ];
      case 'design_system':
        return [
          ContextType('components', 'Components', Icons.widgets,
              'UI components, patterns, and design elements'),
          ContextType('spacing', 'Spacing & Layout', Icons.straighten,
              'Grid systems, spacing rules, and layout principles'),
          ContextType('icons', 'Icon Library', Icons.apps,
              'Icon sets, styles, and usage guidelines'),
          ContextType('interactions', 'Interactions', Icons.touch_app,
              'Animation principles, micro-interactions, and transitions'),
        ];
      case 'user_research':
        return [
          ContextType('personas', 'User Personas', Icons.person,
              'Target user profiles, demographics, and characteristics'),
          ContextType('journeys', 'User Journeys', Icons.timeline,
              'User experience flows, touchpoints, and interactions'),
          ContextType('pain_points', 'Pain Points', Icons.warning_amber,
              'User frustrations, obstacles, and improvement opportunities'),
          ContextType('requirements', 'User Requirements', Icons.assignment,
              'Feature requirements, user stories, and acceptance criteria'),
        ];
      case 'competitive_analysis':
        return [
          ContextType('competitors', 'Competitors', Icons.business,
              'Direct and indirect competitors, market analysis'),
          ContextType('features', 'Feature Comparison', Icons.compare_arrows,
              'Feature sets, capabilities, and competitive advantages'),
          ContextType('designs', 'Design Benchmarks', Icons.image,
              'Visual design examples, UI patterns, and trends'),
          ContextType('gaps', 'Market Gaps', Icons.lightbulb,
              'Opportunities, unmet needs, and innovation areas'),
        ];
      case 'technical_constraints':
        return [
          ContextType('platform', 'Platform Limits', Icons.devices,
              'Technical platform constraints and capabilities'),
          ContextType('performance', 'Performance', Icons.speed,
              'Performance requirements, optimization needs'),
          ContextType('accessibility', 'Accessibility', Icons.accessibility,
              'A11y requirements, WCAG compliance, inclusive design'),
          ContextType('integration', 'Integration', Icons.extension,
              'Third-party systems, APIs, and technical dependencies'),
        ];
      default:
        return [];
    }
  }

  void _showContextInput(ContextType type) {
    showDialog(
      context: context,
      builder: (context) {
        return ContextInputDialog(
          contextType: type,
          onSave: (item) => _addContextItem(item),
        );
      },
    );
  }

  void _addContextItem(ContextItem item) {
    setState(() {
      _contextItems.add(item);
    });
  }

  void _clearAll() {
    setState(() {
      _contextItems.clear();
    });
  }

  void _saveAndClose() {
    widget.onContextUpdate(_contextItems);
    Navigator.of(context).pop();
  }
}

/// Dialog for inputting context details
class ContextInputDialog extends StatefulWidget {
  final ContextType contextType;
  final Function(ContextItem) onSave;
  
  const ContextInputDialog({
    super.key,
    required this.contextType,
    required this.onSave,
  });

  @override
  State<ContextInputDialog> createState() => _ContextInputDialogState();
}

class _ContextInputDialogState extends State<ContextInputDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _nameController.text = widget.contextType.name;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(widget.contextType.icon, color: colors.primary),
          const SizedBox(width: SpacingTokens.sm),
          Text('Add ${widget.contextType.name}'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., Primary Logo Usage',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of this context',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Content',
                hintText: 'Detailed context information, guidelines, or requirements',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text('Add Context'),
        ),
      ],
    );
  }

  void _save() {
    if (_nameController.text.isNotEmpty) {
      final item = ContextItem(
        name: _nameController.text,
        type: widget.contextType.id,
        description: _descriptionController.text,
        content: _contentController.text,
      );
      
      widget.onSave(item);
      Navigator.pop(context);
    }
  }
}

/// Model for context categories
class ContextCategory {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final Color color;

  ContextCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
  });
}

/// Model for context types
class ContextType {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  ContextType(this.id, this.name, this.icon, this.description);
}