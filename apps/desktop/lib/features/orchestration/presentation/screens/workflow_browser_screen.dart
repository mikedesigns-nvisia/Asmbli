import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reasoning_workflow.dart';
import '../../providers/canvas_provider.dart';
import '../widgets/workflow_card.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';

/// Screen for browsing and managing saved workflows
class WorkflowBrowserScreen extends ConsumerStatefulWidget {
  const WorkflowBrowserScreen({super.key});

  @override
  ConsumerState<WorkflowBrowserScreen> createState() => _WorkflowBrowserScreenState();
}

class _WorkflowBrowserScreenState extends ConsumerState<WorkflowBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ReasoningWorkflow> _workflows = [];
  List<ReasoningWorkflow> _filteredWorkflows = [];
  bool _isLoading = true;
  bool _includeTemplates = true;
  String _sortBy = 'updated'; // 'updated', 'created', 'name'

  @override
  void initState() {
    super.initState();
    _loadWorkflows();
    _searchController.addListener(_filterWorkflows);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkflows() async {
    setState(() => _isLoading = true);
    
    try {
      final workflows = await ref.read(canvasProvider.notifier).getAllWorkflows(
        includeTemplates: _includeTemplates,
      );
      
      setState(() {
        _workflows = workflows;
        _filteredWorkflows = workflows;
        _isLoading = false;
      });
      
      _sortWorkflows();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workflows: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  void _filterWorkflows() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredWorkflows = _workflows.where((workflow) {
        return workflow.name.toLowerCase().contains(query) ||
               (workflow.description?.toLowerCase().contains(query) ?? false) ||
               workflow.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    });
    _sortWorkflows();
  }

  void _sortWorkflows() {
    setState(() {
      switch (_sortBy) {
        case 'updated':
          _filteredWorkflows.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          break;
        case 'created':
          _filteredWorkflows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'name':
          _filteredWorkflows.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
    });
  }

  Future<void> _loadWorkflow(ReasoningWorkflow workflow) async {
    try {
      ref.read(canvasProvider.notifier).loadWorkflow(workflow);
      Navigator.of(context).pushReplacementNamed(AppRoutes.orchestration);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workflow: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  Future<void> _duplicateWorkflow(ReasoningWorkflow workflow) async {
    try {
      await ref.read(canvasProvider.notifier).duplicateWorkflow(
        newName: '${workflow.name} (Copy)',
      );
      _loadWorkflows(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow duplicated successfully'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error duplicating workflow: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  Future<void> _deleteWorkflow(ReasoningWorkflow workflow) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors(context).surface,
        title: Text(
          'Delete Workflow',
          style: TextStyles.cardTitle.copyWith(
            color: ThemeColors(context).onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${workflow.name}"? This action cannot be undone.',
          style: TextStyles.bodyMedium.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        actions: [
          AsmblButton.secondary(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AsmblButton.destructive(
            text: 'Delete',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(canvasProvider.notifier).deleteWorkflow(workflow.id);
        _loadWorkflows(); // Refresh the list
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workflow deleted successfully'),
              backgroundColor: ThemeColors(context).success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting workflow: $e'),
              backgroundColor: ThemeColors(context).error,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportWorkflow(ReasoningWorkflow workflow) async {
    try {
      await ref.read(canvasProvider.notifier).exportWorkflowAsJson();
      
      // In a real app, you'd use file_picker to save the file
      // For now, we'll just show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow exported successfully'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting workflow: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: colors.onSurface),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: SpacingTokens.md),
                        Expanded(
                          child: Text(
                            'Workflow Library',
                            style: TextStyles.pageTitle.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        AsmblButton.accent(
                          text: 'Marketplace',
                          icon: Icons.store,
                          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.workflowMarketplace),
                        ),
                        const SizedBox(width: SpacingTokens.md),
                        AsmblButton.primary(
                          text: 'New Workflow',
                          onPressed: () {
                            ref.read(canvasProvider.notifier).createNewWorkflow();
                            Navigator.of(context).pushReplacementNamed(AppRoutes.orchestration);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.lg),
                    
                    // Search and filters
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search workflows...',
                              hintStyle: TextStyles.bodyMedium.copyWith(
                                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
                              filled: true,
                              fillColor: colors.surface,
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
                                borderSide: BorderSide(color: colors.primary),
                              ),
                            ),
                            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.lg),
                        
                        // Sort dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                            border: Border.all(color: colors.border),
                          ),
                          child: DropdownButton<String>(
                            value: _sortBy,
                            items: const [
                              DropdownMenuItem(value: 'updated', child: Text('Last Updated')),
                              DropdownMenuItem(value: 'created', child: Text('Date Created')),
                              DropdownMenuItem(value: 'name', child: Text('Name')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _sortBy = value);
                                _sortWorkflows();
                              }
                            },
                            underline: const SizedBox(),
                            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                            dropdownColor: colors.surface,
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.lg),
                        
                        // Include templates toggle
                        Row(
                          children: [
                            Switch(
                              value: _includeTemplates,
                              onChanged: (value) {
                                setState(() => _includeTemplates = value);
                                _loadWorkflows();
                              },
                              activeColor: colors.primary,
                            ),
                            const SizedBox(width: SpacingTokens.sm),
                            Text(
                              'Templates',
                              style: TextStyles.bodyMedium.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: colors.primary),
                      )
                    : _filteredWorkflows.isEmpty
                        ? _buildEmptyState()
                        : _buildWorkflowGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = ThemeColors(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            _workflows.isEmpty ? 'No workflows yet' : 'No workflows found',
            style: TextStyles.sectionTitle.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            _workflows.isEmpty
                ? 'Create your first reasoning workflow to get started'
                : 'Try adjusting your search or filters',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          if (_workflows.isEmpty) ...[
            const SizedBox(height: SpacingTokens.xl),
            AsmblButton.primary(
              text: 'Create Workflow',
              onPressed: () {
                ref.read(canvasProvider.notifier).createNewWorkflow();
                Navigator.of(context).pushReplacementNamed(AppRoutes.orchestration);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkflowGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: SpacingTokens.lg,
          mainAxisSpacing: SpacingTokens.lg,
          childAspectRatio: 1.2,
        ),
        itemCount: _filteredWorkflows.length,
        itemBuilder: (context, index) {
          final workflow = _filteredWorkflows[index];
          return WorkflowCard(
            workflow: workflow,
            onTap: () => _loadWorkflow(workflow),
            onDuplicate: () => _duplicateWorkflow(workflow),
            onDelete: () => _deleteWorkflow(workflow),
            onExport: () => _exportWorkflow(workflow),
          );
        },
      ),
    );
  }
}