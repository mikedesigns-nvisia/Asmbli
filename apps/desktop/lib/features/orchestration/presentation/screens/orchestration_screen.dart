import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../widgets/reasoning_canvas.dart';
import '../widgets/properties_panel.dart';
import '../../providers/canvas_provider.dart';

/// Main orchestration screen for visual reasoning workflows
/// This will be integrated as a tab in the agent builder
class OrchestrationScreen extends ConsumerStatefulWidget {
  const OrchestrationScreen({super.key});

  @override
  ConsumerState<OrchestrationScreen> createState() => _OrchestrationScreenState();
}

class _OrchestrationScreenState extends ConsumerState<OrchestrationScreen> {
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
                      
                      // Properties panel
                      const SizedBox(
                        width: 320,
                        child: PropertiesPanel(),
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