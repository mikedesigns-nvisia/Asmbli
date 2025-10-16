import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/logic_block.dart';
import '../../models/workflow_templates.dart';
import '../../providers/canvas_provider.dart';

/// Dialog for selecting and loading workflow templates
class WorkflowTemplateDialog extends ConsumerStatefulWidget {
  const WorkflowTemplateDialog({super.key});

  @override
  ConsumerState<WorkflowTemplateDialog> createState() => _WorkflowTemplateDialogState();
}

class _WorkflowTemplateDialogState extends ConsumerState<WorkflowTemplateDialog> {
  WorkflowCategory? _selectedCategory;
  WorkflowTemplate? _selectedTemplate;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final templates = WorkflowTemplates.getAllTemplates();
    final filteredTemplates = _filterTemplates(templates);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
      ),
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            const SizedBox(height: SpacingTokens.lg),
            _buildSearchAndFilters(colors),
            const SizedBox(height: SpacingTokens.lg),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template list
                  Expanded(
                    flex: 2,
                    child: _buildTemplateList(filteredTemplates, colors),
                  ),
                  const SizedBox(width: SpacingTokens.lg),
                  // Template preview
                  Expanded(
                    flex: 3,
                    child: _buildTemplatePreview(colors),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            _buildActions(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Icon(
          Icons.account_tree,
          size: 28,
          color: colors.primary,
        ),
        const SizedBox(width: SpacingTokens.sm),
        Text(
          'Choose Workflow Template',
          style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(ThemeColors colors) {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search templates...',
            prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
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
        ),
        const SizedBox(height: SpacingTokens.md),
        // Category filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('All', null, colors),
              const SizedBox(width: SpacingTokens.sm),
              ...WorkflowCategory.values.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: SpacingTokens.sm),
                  child: _buildCategoryChip(category.displayName, category, colors),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, WorkflowCategory? category, ThemeColors colors) {
    final isSelected = _selectedCategory == category;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyles.bodySmall.copyWith(
          color: isSelected ? colors.onPrimary : colors.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedCategory = category),
      backgroundColor: colors.surface,
      selectedColor: colors.primary,
      checkmarkColor: colors.onPrimary,
      side: BorderSide(color: colors.border),
    );
  }

  Widget _buildTemplateList(List<WorkflowTemplate> templates, ThemeColors colors) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              'No templates found',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            Text(
              'Try adjusting your search or filters',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isSelected = _selectedTemplate?.id == template.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
          child: AsmblCard(
            child: InkWell(
              onTap: () => setState(() => _selectedTemplate = template),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              child: Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: isSelected
                    ? BoxDecoration(
                        border: Border.all(color: colors.primary, width: 2),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.sm,
                            vertical: SpacingTokens.xs,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(template.category).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                          ),
                          child: Text(
                            template.category.displayName,
                            style: TextStyles.caption.copyWith(
                              color: _getCategoryColor(template.category),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: colors.primary,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Text(
                      template.name,
                      style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      template.description,
                      style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Wrap(
                      spacing: SpacingTokens.xs,
                      children: template.tags.take(3).map((tag) => Chip(
                        label: Text(
                          tag,
                          style: TextStyles.caption.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        backgroundColor: colors.surface,
                        side: BorderSide(color: colors.border, width: 1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemplatePreview(ThemeColors colors) {
    if (_selectedTemplate == null) {
      return AsmblCard(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.preview,
                size: 64,
                color: colors.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: SpacingTokens.md),
              Text(
                'Select a template to preview',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final template = _selectedTemplate!;
    final workflow = template.workflow;

    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  template.name,
                  style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.sm,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(template.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Text(
                    template.category.displayName,
                    style: TextStyles.caption.copyWith(
                      color: _getCategoryColor(template.category),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              template.description,
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: SpacingTokens.lg),
            
            // Workflow overview
            Text(
              'Workflow Overview',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.sm),
            _buildWorkflowStats(workflow, colors),
            const SizedBox(height: SpacingTokens.lg),
            
            // Block types used
            Text(
              'Logic Blocks',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.sm),
            _buildBlockTypesList(workflow, colors),
            const SizedBox(height: SpacingTokens.lg),
            
            // Tags
            Text(
              'Tags',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Wrap(
              spacing: SpacingTokens.xs,
              runSpacing: SpacingTokens.xs,
              children: template.tags.map((tag) => Chip(
                label: Text(
                  tag,
                  style: TextStyles.caption.copyWith(color: colors.onSurface),
                ),
                backgroundColor: colors.background,
                side: BorderSide(color: colors.border, width: 1),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowStats(workflow, ThemeColors colors) {
    return Row(
      children: [
        _buildStatItem('Blocks', workflow.blocks.length.toString(), Icons.widgets, colors),
        const SizedBox(width: SpacingTokens.lg),
        _buildStatItem('Connections', workflow.connections.length.toString(), Icons.timeline, colors),
        const SizedBox(width: SpacingTokens.lg),
        _buildStatItem('Complexity', _getComplexityLevel(workflow), Icons.analytics, colors),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ThemeColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: SpacingTokens.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlockTypesList(workflow, ThemeColors colors) {
    final blockTypes = <String, int>{};
    for (final block in workflow.blocks) {
      final typeName = _getBlockTypeName(block.type);
      blockTypes[typeName] = (blockTypes[typeName] ?? 0) + 1;
    }

    return Wrap(
      spacing: SpacingTokens.sm,
      runSpacing: SpacingTokens.xs,
      children: blockTypes.entries.map((entry) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          '${entry.key} (${entry.value})',
          style: TextStyles.caption.copyWith(color: colors.onSurface),
        ),
      )).toList(),
    );
  }

  Widget _buildActions(ThemeColors colors) {
    return Row(
      children: [
        const Spacer(),
        AsmblButton.secondary(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: SpacingTokens.sm),
        AsmblButton.primary(
          text: 'Load Template',
          onPressed: _selectedTemplate != null ? _loadTemplate : null,
          icon: Icons.download,
        ),
      ],
    );
  }

  List<WorkflowTemplate> _filterTemplates(List<WorkflowTemplate> templates) {
    var filtered = templates;

    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered.where((t) => t.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
        t.name.toLowerCase().contains(query) ||
        t.description.toLowerCase().contains(query) ||
        t.tags.any((tag) => tag.toLowerCase().contains(query))
      ).toList();
    }

    return filtered;
  }

  Color _getCategoryColor(WorkflowCategory category) {
    final colors = ThemeColors(context);
    switch (category) {
      case WorkflowCategory.basic:
        return colors.success;
      case WorkflowCategory.advanced:
        return colors.primary;
      case WorkflowCategory.research:
        return colors.accent;
      case WorkflowCategory.problemSolving:
        return colors.warning;
      case WorkflowCategory.conversation:
        return colors.error;
    }
  }

  String _getComplexityLevel(workflow) {
    final blockCount = workflow.blocks.length;
    final connectionCount = workflow.connections.length;
    final complexity = blockCount + (connectionCount * 0.5);

    if (complexity <= 5) return 'Simple';
    if (complexity <= 10) return 'Medium';
    return 'Complex';
  }

  void _loadTemplate() {
    if (_selectedTemplate == null) return;

    // Load the template workflow into the canvas
    ref.read(canvasProvider.notifier).loadWorkflow(_selectedTemplate!.workflow);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Template "${_selectedTemplate!.name}" loaded successfully',
          style: TextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: ThemeColors(context).success,
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.of(context).pop();
  }

  String _getBlockTypeName(LogicBlockType type) {
    switch (type) {
      case LogicBlockType.goal:
        return 'Goal';
      case LogicBlockType.context:
        return 'Context';
      case LogicBlockType.gateway:
        return 'Gateway';
      case LogicBlockType.reasoning:
        return 'Reasoning';
      case LogicBlockType.fallback:
        return 'Fallback';
      case LogicBlockType.trace:
        return 'Trace';
      case LogicBlockType.exit:
        return 'Exit';
    }
  }
}