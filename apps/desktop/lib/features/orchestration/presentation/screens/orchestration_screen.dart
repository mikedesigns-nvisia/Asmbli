import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../widgets/reasoning_canvas.dart';
import '../widgets/properties_panel.dart';
import '../widgets/execution_overlay.dart';
import '../../providers/canvas_provider.dart';

/// Main orchestration screen for visual reasoning workflows
/// This will be integrated as a tab in the agent builder
class OrchestrationScreen extends ConsumerStatefulWidget {
  const OrchestrationScreen({super.key});

  @override
  ConsumerState<OrchestrationScreen> createState() => _OrchestrationScreenState();
}

class _OrchestrationScreenState extends ConsumerState<OrchestrationScreen> {
  String _selectedModelId = 'claude-3-sonnet'; // Default model
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
              // Header with navigation  
              Container(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                child: Row(
                  children: [
                    Text(
                      'Visual Reasoning Studio',
                      style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                    ),
                    const Spacer(),
                    AsmblButton.secondary(
                      text: 'Back to Agents',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icons.arrow_back,
                    ),
                  ],
                ),
              ),
              
              // Main content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  child: Row(
                    children: [
                      // Main canvas area
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCanvasHeader(colors),
                            const SizedBox(height: SpacingTokens.md),
                            const Expanded(child: ReasoningCanvas()),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: SpacingTokens.lg),
                      
                      // Properties panel with execution trace
                      SizedBox(
                        width: 320,
                        child: Column(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: PropertiesPanel(),
                            ),
                            const SizedBox(height: SpacingTokens.md),
                            Expanded(
                              flex: 1,
                              child: ExecutionTraceViewer(
                                executionEvents: ref.watch(canvasProvider.notifier).executionEvents,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasHeader(ThemeColors colors) {
    final canvasState = ref.watch(canvasProvider);
    
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Row(
          children: [
            // Workflow info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canvasState.workflow.name,
                  style: TextStyles.sectionTitle.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Visual Reasoning Workflow',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Workflow actions
            Row(
              children: [
                AsmblButton.outline(
                  text: 'New',
                  onPressed: _createNewWorkflow,
                  icon: Icons.add,
                ),
                const SizedBox(width: SpacingTokens.sm),
                AsmblButton.outline(
                  text: 'Save',
                  onPressed: _saveWorkflow,
                  icon: Icons.save,
                ),
                const SizedBox(width: SpacingTokens.sm),
                AsmblButton.outline(
                  text: 'Export',
                  onPressed: _exportWorkflow,
                  icon: Icons.download,
                ),
                const SizedBox(width: SpacingTokens.md),
                
                // Model selector
                Container(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: _selectedModelId,
                    decoration: InputDecoration(
                      labelText: 'Model',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm,
                        vertical: SpacingTokens.xs,
                      ),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(value: 'claude-3-sonnet', child: Text('Claude 3 Sonnet')),
                      DropdownMenuItem(value: 'gpt-4', child: Text('GPT-4')),
                      DropdownMenuItem(value: 'llama3.1:8b', child: Text('Llama 3.1 8B')),
                      DropdownMenuItem(value: 'qwen2.5:7b', child: Text('Qwen 2.5 7B')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedModelId = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                
                // Execution controls
                if (canvasState.workflow.isValid) ...[
                  AsmblButton.primary(
                    text: ref.watch(canvasProvider.notifier).isExecuting ? 'Executing...' : 'Execute',
                    onPressed: ref.watch(canvasProvider.notifier).isExecuting ? null : _executeWorkflow,
                    icon: ref.watch(canvasProvider.notifier).isExecuting ? Icons.hourglass_empty : Icons.play_arrow,
                  ),
                ] else ...[
                  AsmblButton.secondary(
                    text: 'Invalid Workflow',
                    onPressed: null,
                    icon: Icons.error_outline,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createNewWorkflow() {
    ref.read(canvasProvider.notifier).createNewWorkflow();
  }

  void _saveWorkflow() {
    // In Phase 1, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Workflow saved locally',
          style: TextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: ThemeColors(context).success,
      ),
    );
  }

  void _exportWorkflow() {
    // In Phase 1, show export options
    _showExportDialog();
  }

  void _showExportDialog() {
    final colors = ThemeColors(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Export Workflow',
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose export format:',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.md),
            
            ListTile(
              leading: Icon(Icons.code, color: colors.primary),
              title: Text(
                'JSON Configuration',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
              ),
              subtitle: Text(
                'Raw workflow data',
                style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _exportAsJson();
              },
            ),
            
            ListTile(
              leading: Icon(Icons.image, color: colors.primary),
              title: Text(
                'Visual Diagram',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
              ),
              subtitle: Text(
                'PNG image of the workflow',
                style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _exportAsImage();
              },
            ),
            
            ListTile(
              leading: Icon(Icons.description, color: colors.primary),
              title: Text(
                'Documentation',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
              ),
              subtitle: Text(
                'Markdown description',
                style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _exportAsMarkdown();
              },
            ),
          ],
        ),
        actions: [
          AsmblButton.secondary(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _exportAsJson() {
    final workflow = ref.read(canvasProvider).workflow;
    final json = workflow.toJson();
    
    // In Phase 1, just show the JSON (later we'll implement file export)
    _showExportResult('JSON Export', json.toString());
  }

  void _exportAsImage() {
    _showExportResult('Image Export', 'Image export will be available in Phase 2');
  }

  void _exportAsMarkdown() {
    final workflow = ref.read(canvasProvider).workflow;
    final markdown = _generateMarkdownDocumentation(workflow);
    _showExportResult('Markdown Export', markdown);
  }

  Future<void> _executeWorkflow() async {
    try {
      await ref.read(canvasProvider.notifier).executeWorkflow(
        modelId: _selectedModelId,
        initialContext: {
          'context_data': 'Example context for testing the reasoning workflow',
          'user_input': 'This is a test execution of the visual reasoning flow',
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Workflow execution completed',
              style: TextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Execution failed: $e',
              style: TextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  String _generateMarkdownDocumentation(workflow) {
    final buffer = StringBuffer();
    
    buffer.writeln('# ${workflow.name}');
    buffer.writeln();
    
    if (workflow.description?.isNotEmpty == true) {
      buffer.writeln(workflow.description);
      buffer.writeln();
    }
    
    buffer.writeln('## Workflow Overview');
    buffer.writeln('- **Blocks**: ${workflow.blocks.length}');
    buffer.writeln('- **Connections**: ${workflow.connections.length}');
    buffer.writeln('- **Created**: ${workflow.createdAt.toIso8601String()}');
    buffer.writeln('- **Updated**: ${workflow.updatedAt.toIso8601String()}');
    buffer.writeln();
    
    buffer.writeln('## Logic Blocks');
    for (final block in workflow.blocks) {
      buffer.writeln('### ${block.label}');
      buffer.writeln('- **Type**: ${block.type.name}');
      buffer.writeln('- **ID**: ${block.id}');
      if (block.properties.isNotEmpty) {
        buffer.writeln('- **Properties**: ${block.properties}');
      }
      buffer.writeln();
    }
    
    if (workflow.connections.isNotEmpty) {
      buffer.writeln('## Connections');
      for (final connection in workflow.connections) {
        final sourceBlock = workflow.blocks.firstWhere((b) => b.id == connection.sourceBlockId);
        final targetBlock = workflow.blocks.firstWhere((b) => b.id == connection.targetBlockId);
        buffer.writeln('- ${sourceBlock.label} → ${targetBlock.label} (${connection.type.name})');
      }
    }
    
    return buffer.toString();
  }

  void _showExportResult(String title, String content) {
    final colors = ThemeColors(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          title,
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurface,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        actions: [
          AsmblButton.secondary(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}