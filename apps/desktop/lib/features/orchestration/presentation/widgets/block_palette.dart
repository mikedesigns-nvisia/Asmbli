import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/logic_block.dart';
import '../../providers/canvas_provider.dart';

/// Searchable palette of logic blocks for drag-and-drop creation
/// Implements research recommendations for search functionality and discoverability
class BlockPalette extends ConsumerStatefulWidget {
  const BlockPalette({super.key});

  @override
  ConsumerState<BlockPalette> createState() => _BlockPaletteState();
}

class _BlockPaletteState extends ConsumerState<BlockPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isExpanded = true;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AsmblCard(
      child: SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colors),
            if (_isExpanded) ...[
              const SizedBox(height: SpacingTokens.sm),
              _buildSearchBar(colors),
              const SizedBox(height: SpacingTokens.sm),
              _buildBlockList(colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Icon(
          Icons.widgets,
          size: 16,
          color: colors.primary,
        ),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          'Logic Blocks',
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeColors colors) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search blocks...',
        hintStyle: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, size: 16, color: colors.onSurfaceVariant),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: Icon(Icons.clear, size: 16, color: colors.onSurfaceVariant),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: EdgeInsets.zero,
              )
            : null,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        isDense: true,
      ),
      style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
    );
  }

  Widget _buildBlockList(ThemeColors colors) {
    final filteredBlocks = _getFilteredBlocks();
    
    if (filteredBlocks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Text(
          'No blocks found',
          style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return Column(
      children: [
        // Core blocks section
        _buildBlockSection(
          'Core Reasoning',
          filteredBlocks.where((block) => _isCoreBlock(block.type)).toList(),
          colors,
        ),
        
        // Support blocks section
        if (filteredBlocks.any((block) => !_isCoreBlock(block.type)))
          _buildBlockSection(
            'Support',
            filteredBlocks.where((block) => !_isCoreBlock(block.type)).toList(),
            colors,
          ),
      ],
    );
  }

  Widget _buildBlockSection(
    String title,
    List<LogicBlockTemplate> blocks,
    ThemeColors colors,
  ) {
    if (blocks.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
          child: Text(
            title,
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...blocks.map((template) => _buildBlockItem(template, colors)),
        const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }

  Widget _buildBlockItem(LogicBlockTemplate template, ThemeColors colors) {
    return Draggable<LogicBlockTemplate>(
      data: template,
      onDragStarted: () => print('🚀 Started dragging: ${template.label}'),
      onDragEnd: (details) => print('🏁 Drag ended: ${template.label}, wasAccepted: ${details.wasAccepted}'),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 120,
          height: 50,
          decoration: BoxDecoration(
            color: _getBlockColor(template.type).withValues(alpha: 0.9),
            border: Border.all(color: _getBlockColor(template.type), width: 2),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              template.label,
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildBlockItemContent(template, colors),
      ),
      child: _buildBlockItemContent(template, colors),
    );
  }

  Widget _buildBlockItemContent(LogicBlockTemplate template, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: _getBlockColor(template.type).withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Row(
        children: [
          // Block type indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getBlockColor(template.type),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              _getBlockIcon(template.type),
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          
          // Block info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.label,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  template.description,
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<LogicBlockTemplate> _getFilteredBlocks() {
    final allBlocks = _getAllBlockTemplates();
    
    if (_searchQuery.isEmpty) return allBlocks;
    
    return allBlocks.where((block) {
      return block.label.toLowerCase().contains(_searchQuery) ||
             block.description.toLowerCase().contains(_searchQuery) ||
             block.keywords.any((keyword) => keyword.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  List<LogicBlockTemplate> _getAllBlockTemplates() {
    return [
      // Core reasoning blocks
      LogicBlockTemplate(
        type: LogicBlockType.goal,
        label: 'Goal Declaration',
        description: 'Define the objective and success criteria',
        keywords: ['start', 'objective', 'target', 'purpose'],
      ),
      LogicBlockTemplate(
        type: LogicBlockType.context,
        label: 'Context Filter',
        description: 'Retrieve and filter relevant info',
        keywords: ['data', 'filter', 'context', 'information', 'rag'],
      ),
      LogicBlockTemplate(
        type: LogicBlockType.gateway,
        label: 'Decision Gateway',
        description: 'Route execution based on confidence',
        keywords: ['decision', 'route', 'confidence', 'branch'],
      ),
      LogicBlockTemplate(
        type: LogicBlockType.reasoning,
        label: 'Reasoning Layer',
        description: 'Multi-step thinking and analysis',
        keywords: ['think', 'reason', 'analyze', 'cot', 'react'],
      ),
      LogicBlockTemplate(
        type: LogicBlockType.exit,
        label: 'Exit Condition',
        description: 'Evaluate completion and quality',
        keywords: ['end', 'finish', 'complete', 'exit', 'done'],
      ),
      
      // Support blocks
      LogicBlockTemplate(
        type: LogicBlockType.fallback,
        label: 'Fallback Strategy',
        description: 'Handle errors and edge cases',
        keywords: ['error', 'fallback', 'recovery', 'retry'],
      ),
      LogicBlockTemplate(
        type: LogicBlockType.trace,
        label: 'Trace Events',
        description: 'Log execution for debug',
        keywords: ['log', 'trace', 'debug', 'monitor'],
      ),
    ];
  }

  bool _isCoreBlock(LogicBlockType type) {
    return [
      LogicBlockType.goal,
      LogicBlockType.context,
      LogicBlockType.gateway,
      LogicBlockType.reasoning,
      LogicBlockType.exit,
    ].contains(type);
  }

  Color _getBlockColor(LogicBlockType type) {
    // Convert hex to Color
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
}

/// Template for creating new logic blocks
class LogicBlockTemplate {
  final LogicBlockType type;
  final String label;
  final String description;
  final List<String> keywords;

  const LogicBlockTemplate({
    required this.type,
    required this.label,
    required this.description,
    required this.keywords,
  });
}