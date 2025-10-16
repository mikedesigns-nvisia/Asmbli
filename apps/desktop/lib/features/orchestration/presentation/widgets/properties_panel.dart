import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/logic_block.dart';
import '../../providers/canvas_provider.dart';

/// Properties panel for configuring selected logic blocks
class PropertiesPanel extends ConsumerStatefulWidget {
  const PropertiesPanel({super.key});

  @override
  ConsumerState<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends ConsumerState<PropertiesPanel> {
  final Map<String, TextEditingController> _controllers = {};
  
  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final canvasState = ref.watch(canvasProvider);
    final selectedBlocks = canvasState.selectedBlocks;
    final activeBlock = canvasState.activeBlock;
    
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            const SizedBox(height: SpacingTokens.md),
            
            Expanded(
              child: _buildContent(colors, selectedBlocks, activeBlock),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Icon(
          Icons.settings,
          size: 16,
          color: colors.primary,
        ),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          'Properties',
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }

  Widget _buildContent(
    ThemeColors colors,
    List<LogicBlock> selectedBlocks,
    LogicBlock? activeBlock,
  ) {
    if (activeBlock != null) {
      return _buildBlockProperties(colors, activeBlock);
    }
    
    if (selectedBlocks.length == 1) {
      return _buildBlockProperties(colors, selectedBlocks.first);
    }
    
    if (selectedBlocks.length > 1) {
      return _buildMultiSelectionInfo(colors, selectedBlocks);
    }
    
    return _buildEmptyState(colors);
  }

  Widget _buildBlockProperties(ThemeColors colors, LogicBlock block) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Block header
          _buildBlockHeader(colors, block),
          const SizedBox(height: SpacingTokens.md),
          
          // Basic properties
          _buildBasicProperties(colors, block),
          const SizedBox(height: SpacingTokens.md),
          
          // Type-specific properties
          _buildTypeSpecificProperties(colors, block),
          const SizedBox(height: SpacingTokens.md),
          
          // MCP Tools section
          _buildMcpToolsSection(colors, block),
          const SizedBox(height: SpacingTokens.md),
          
          // Evaluation & Quality Gates section
          _buildEvaluationSection(colors, block),
        ],
      ),
    );
  }

  Widget _buildBlockHeader(ThemeColors colors, LogicBlock block) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: _getBlockColor(block.type).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: _getBlockColor(block.type).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getBlockIcon(block.type),
            color: _getBlockColor(block.type),
            size: 20,
          ),
          const SizedBox(width: SpacingTokens.sm),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.label,
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getBlockTypeDescription(block.type),
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicProperties(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Properties',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        // Label
        _buildTextField(
          label: 'Label',
          value: block.label,
          onChanged: (value) => _updateBlockProperty(block.id, 'label', value),
          colors: colors,
        ),
        
        // Position (read-only for now)
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'X Position',
                value: block.position.x.round().toString(),
                onChanged: (_) {}, // Read-only, no action needed
                readOnly: true,
                colors: colors,
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: _buildTextField(
                label: 'Y Position',
                value: block.position.y.round().toString(),
                onChanged: (_) {}, // Read-only, no action needed
                readOnly: true,
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeSpecificProperties(ThemeColors colors, LogicBlock block) {
    switch (block.type) {
      case LogicBlockType.goal:
        return _buildGoalProperties(colors, block);
      case LogicBlockType.context:
        return _buildContextProperties(colors, block);
      case LogicBlockType.gateway:
        return _buildGatewayProperties(colors, block);
      case LogicBlockType.reasoning:
        return _buildReasoningProperties(colors, block);
      case LogicBlockType.fallback:
        return _buildFallbackProperties(colors, block);
      case LogicBlockType.trace:
        return _buildTraceProperties(colors, block);
      case LogicBlockType.exit:
        return _buildExitProperties(colors, block);
    }
  }

  Widget _buildGoalProperties(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Configuration',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        _buildTextField(
          label: 'Description',
          value: block.properties['description'] as String? ?? '',
          onChanged: (value) => _updateBlockProperty(block.id, 'description', value),
          colors: colors,
          maxLines: 3,
        ),
        
        _buildTextField(
          label: 'Success Criteria',
          value: block.properties['successCriteria'] as String? ?? '',
          onChanged: (value) => _updateBlockProperty(block.id, 'successCriteria', value),
          colors: colors,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildGatewayProperties(ThemeColors colors, LogicBlock block) {
    final confidence = block.properties['confidence'] as double? ?? 0.8;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Decision Gateway',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        // Confidence threshold slider
        Text(
          'Confidence Threshold: ${(confidence * 100).round()}%',
          style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
        ),
        Slider(
          value: confidence,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: (value) => _updateBlockProperty(block.id, 'confidence', value),
        ),
        
        // Strategy dropdown
        _buildDropdownField(
          label: 'Decision Strategy',
          value: block.properties['strategy'] as String? ?? 'llm_decision',
          options: const [
            ('llm_decision', 'LLM Decision'),
            ('rule_based', 'Rule Based'),
            ('hybrid', 'Hybrid'),
          ],
          onChanged: (value) => _updateBlockProperty(block.id, 'strategy', value),
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildReasoningProperties(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reasoning Configuration',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        _buildDropdownField(
          label: 'Reasoning Pattern',
          value: block.properties['pattern'] as String? ?? 'react',
          options: const [
            ('react', 'ReAct (Reason-Act-Observe)'),
            ('cot', 'Chain of Thought'),
            ('tot', 'Tree of Thought'),
            ('self_consistency', 'Self Consistency'),
          ],
          onChanged: (value) => _updateBlockProperty(block.id, 'pattern', value),
          colors: colors,
        ),
        
        _buildTextField(
          label: 'Max Iterations',
          value: (block.properties['maxIterations'] as int? ?? 3).toString(),
          onChanged: (value) => _updateBlockProperty(
            block.id, 
            'maxIterations', 
            int.tryParse(value) ?? 3,
          ),
          colors: colors,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildContextProperties(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Context Configuration',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        _buildTextField(
          label: 'Max Results',
          value: (block.properties['maxResults'] as int? ?? 10).toString(),
          onChanged: (value) => _updateBlockProperty(
            block.id, 
            'maxResults', 
            int.tryParse(value) ?? 10,
          ),
          colors: colors,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildFallbackProperties(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fallback Strategy',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        _buildTextField(
          label: 'Retry Count',
          value: (block.properties['retryCount'] as int? ?? 2).toString(),
          onChanged: (value) => _updateBlockProperty(
            block.id, 
            'retryCount', 
            int.tryParse(value) ?? 2,
          ),
          colors: colors,
          keyboardType: TextInputType.number,
        ),
        
        _buildDropdownField(
          label: 'Escalation Path',
          value: block.properties['escalationPath'] as String? ?? 'human',
          options: const [
            ('human', 'Escalate to Human'),
            ('retry', 'Retry with Changes'),
            ('abort', 'Abort Workflow'),
          ],
          onChanged: (value) => _updateBlockProperty(block.id, 'escalationPath', value),
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildTraceProperties(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trace Configuration',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        _buildDropdownField(
          label: 'Log Level',
          value: block.properties['level'] as String? ?? 'info',
          options: const [
            ('debug', 'Debug'),
            ('info', 'Info'),
            ('warn', 'Warning'),
            ('error', 'Error'),
          ],
          onChanged: (value) => _updateBlockProperty(block.id, 'level', value),
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildExitProperties(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exit Configuration',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        SwitchListTile(
          title: Text(
            'Allow Partial Results',
            style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
          ),
          value: block.properties['partialResults'] as bool? ?? true,
          onChanged: (value) => _updateBlockProperty(block.id, 'partialResults', value),
          activeColor: colors.primary,
        ),
      ],
    );
  }

  Widget _buildMcpToolsSection(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'MCP Tools',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            AsmblButton.outline(
              text: 'Add Tool',
              onPressed: () => _showMcpToolPicker(block),
              icon: Icons.add,
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        if (block.mcpToolIds.isEmpty)
          Text(
            'No MCP tools connected',
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          )
        else
          ...block.mcpToolIds.map((toolId) => _buildMcpToolItem(toolId, colors)),
      ],
    );
  }

  Widget _buildMcpToolItem(String toolId, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.extension, size: 16, color: colors.accent),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: Text(
              toolId, // In real implementation, resolve tool name
              style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
            ),
          ),
          IconButton(
            onPressed: () => _removeMcpTool(toolId),
            icon: Icon(Icons.close, size: 16, color: colors.error),
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required ThemeColors colors,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final controllerId = '${label}_$value';
    if (!_controllers.containsKey(controllerId)) {
      _controllers[controllerId] = TextEditingController(text: value);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: TextField(
        controller: _controllers[controllerId],
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.all(SpacingTokens.sm),
          isDense: true,
        ),
        style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<(String, String)> options,
    required Function(String) onChanged,
    required ThemeColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.all(SpacingTokens.sm),
          isDense: true,
        ),
        items: options.map((option) => DropdownMenuItem(
          value: option.$1,
          child: Text(
            option.$2,
            style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
          ),
        )).toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
        dropdownColor: colors.surface,
      ),
    );
  }

  Widget _buildMultiSelectionInfo(ThemeColors colors, List<LogicBlock> selectedBlocks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Multiple Selection',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        Text(
          '${selectedBlocks.length} blocks selected',
          style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.md),
        
        // Group actions
        AsmblButton.outline(
          text: 'Delete Selected',
          onPressed: _deleteSelectedBlocks,
          icon: Icons.delete,
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 48,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Select a block to edit properties',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Double-click a block to configure it',
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _updateBlockProperty(String blockId, String key, dynamic value) {
    final block = ref.read(canvasProvider).workflow.blocks
        .firstWhere((b) => b.id == blockId);
    
    if (key == 'label') {
      // Update block label directly
      final updatedBlocks = ref.read(canvasProvider).workflow.blocks.map((b) {
        if (b.id == blockId) {
          return b.copyWith(label: value as String);
        }
        return b;
      }).toList();
      
      final updatedWorkflow = ref.read(canvasProvider).workflow.copyWith(
        blocks: updatedBlocks,
        updatedAt: DateTime.now(),
      );
      
      ref.read(canvasProvider.notifier).loadWorkflow(updatedWorkflow);
    } else {
      // Update block properties
      final updatedProperties = Map<String, dynamic>.from(block.properties);
      updatedProperties[key] = value;
      ref.read(canvasProvider.notifier).updateBlockProperties(blockId, updatedProperties);
    }
  }

  void _showMcpToolPicker(LogicBlock block) {
    // In Phase 1, show placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('MCP tool picker will be available in Phase 4'),
      ),
    );
  }

  void _removeMcpTool(String toolId) {
    // Implementation for removing MCP tool
  }

  void _deleteSelectedBlocks() {
    final selectedIds = ref.read(canvasProvider).selection.selectedBlockIds;
    for (final blockId in selectedIds) {
      ref.read(canvasProvider.notifier).removeBlock(blockId);
    }
  }

  Color _getBlockColor(LogicBlockType type) {
    final block = LogicBlock(
      id: 'temp',
      type: type,
      label: 'temp',
      position: const Position(x: 0, y: 0),
    );
    final hexColor = block.displayColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  IconData _getBlockIcon(LogicBlockType type) {
    switch (type) {
      case LogicBlockType.goal:
        return Icons.flag;
      case LogicBlockType.context:
        return Icons.filter_alt;
      case LogicBlockType.gateway:
        return Icons.alt_route;
      case LogicBlockType.reasoning:
        return Icons.psychology;
      case LogicBlockType.fallback:
        return Icons.error_outline;
      case LogicBlockType.trace:
        return Icons.timeline;
      case LogicBlockType.exit:
        return Icons.check_circle;
    }
  }

  String _getBlockTypeDescription(LogicBlockType type) {
    switch (type) {
      case LogicBlockType.goal:
        return 'Define objectives and success criteria';
      case LogicBlockType.context:
        return 'Retrieve and filter information';
      case LogicBlockType.gateway:
        return 'Route execution based on confidence';
      case LogicBlockType.reasoning:
        return 'Multi-step thinking and analysis';
      case LogicBlockType.fallback:
        return 'Handle errors and edge cases';
      case LogicBlockType.trace:
        return 'Log execution for debugging';
      case LogicBlockType.exit:
        return 'Evaluate completion and quality';
    }
  }

  Widget _buildEvaluationSection(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified, size: 16, color: colors.primary),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              'Quality & Evaluation',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        // Confidence Threshold
        _buildSliderField(
          label: 'Confidence Threshold',
          value: 0.8, // Default value, would come from block properties
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: (value) => _updateBlockProperty(block.id, 'confidenceThreshold', value),
          colors: colors,
        ),
        
        // Quality Gates
        _buildQualityGatesConfig(colors, block),
        
        // Validation Rules
        _buildValidationRulesConfig(colors, block),
        
        // Recovery Strategy
        _buildRecoveryStrategyConfig(colors, block),
      ],
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required ThemeColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: TextStyles.bodySmall.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.xs),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: colors.primary,
          inactiveColor: colors.primary.withValues(alpha: 0.3),
        ),
        const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }

  Widget _buildQualityGatesConfig(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quality Gates',
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        
        _buildCheckboxOption(
          'Validate output format',
          true, // Would come from block properties
          (value) => _updateBlockProperty(block.id, 'validateFormat', value),
          colors,
        ),
        
        _buildCheckboxOption(
          'Check for hallucinations',
          true,
          (value) => _updateBlockProperty(block.id, 'checkHallucinations', value),
          colors,
        ),
        
        _buildCheckboxOption(
          'Verify citations',
          false,
          (value) => _updateBlockProperty(block.id, 'verifyCitations', value),
          colors,
        ),
        
        _buildCheckboxOption(
          'Toxicity filter',
          true,
          (value) => _updateBlockProperty(block.id, 'toxicityFilter', value),
          colors,
        ),
        
        const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }

  Widget _buildValidationRulesConfig(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Validation Rules',
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        
        _buildTextField(
          label: 'Custom Validation Script',
          value: '', // Would come from block properties
          onChanged: (value) => _updateBlockProperty(block.id, 'validationScript', value),
          colors: colors,
          maxLines: 3,
        ),
        
        const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }

  Widget _buildRecoveryStrategyConfig(ThemeColors colors, LogicBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recovery Strategy',
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        
        _buildDropdownField(
          label: 'On Failure',
          value: 'retry', // Would come from block properties
          options: const [
            ('retry', 'Retry with backoff'),
            ('fallback', 'Use fallback block'),
            ('degrade', 'Degrade gracefully'),
            ('escalate', 'Escalate to user'),
            ('fail', 'Fail immediately'),
          ],
          onChanged: (value) => _updateBlockProperty(block.id, 'recoveryStrategy', value),
          colors: colors,
        ),
        
        _buildTextField(
          label: 'Max Retry Attempts',
          value: '3',
          onChanged: (value) => _updateBlockProperty(block.id, 'maxRetries', int.tryParse(value) ?? 3),
          colors: colors,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildCheckboxOption(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    ThemeColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            activeColor: colors.primary,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: Text(
              label,
              style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

}