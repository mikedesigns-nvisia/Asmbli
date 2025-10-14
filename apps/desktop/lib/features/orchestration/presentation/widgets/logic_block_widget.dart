import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/logic_block.dart';

/// Individual logic block widget following research design recommendations
/// 120-200px wide, 40-60px tall, rounded rectangles with category colors
class LogicBlockWidget extends ConsumerWidget {
  final LogicBlock block;
  final bool isSelected;
  final bool isActive;
  final bool isHovered;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final Function(String pin, ConnectionType type) onConnectionStart;

  const LogicBlockWidget({
    super.key,
    required this.block,
    required this.isSelected,
    required this.isActive,
    required this.isHovered,
    required this.onTap,
    required this.onDoubleTap,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onConnectionStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        width: block.defaultWidth,
        height: block.defaultHeight,
        decoration: BoxDecoration(
          color: _getBlockColor(colors),
          border: Border.all(
            color: _getBorderColor(colors),
            width: isSelected ? 2.5 : (isHovered ? 2.0 : 1.5),
          ),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          boxShadow: [
            if (isSelected || isActive || isHovered)
              BoxShadow(
                color: _getBlockAccentColor().withOpacity(0.3),
                blurRadius: isActive ? 12 : 8,
                spreadRadius: isActive ? 2 : 1,
              ),
          ],
        ),
        child: Stack(
          children: [
            // Main block content
            _buildBlockContent(colors),
            
            // Connection pins
            ..._buildConnectionPins(colors),
            
            // Status indicators
            if (block.mcpToolIds.isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.extension,
                  size: 12,
                  color: colors.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockContent(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              // Block icon
              Icon(
                _getBlockIcon(),
                size: 16,
                color: colors.onSurface,
              ),
              const SizedBox(width: SpacingTokens.xs),
              
              // Block label
              Expanded(
                child: Text(
                  block.label,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          // Block type indicator for small blocks
          if (block.defaultHeight <= 50)
            Text(
              _getTypeLabel(),
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          
          // Additional content for larger blocks
          if (block.defaultHeight > 50)
            ..._buildExtendedContent(colors),
        ],
      ),
    );
  }

  List<Widget> _buildExtendedContent(ThemeColors colors) {
    switch (block.type) {
      case LogicBlockType.reasoning:
        return [
          const SizedBox(height: SpacingTokens.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Text(
              'CoT/ReAct',
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
          ),
        ];
      
      case LogicBlockType.gateway:
        final confidence = block.properties['confidence'] as double? ?? 0.8;
        return [
          const SizedBox(height: SpacingTokens.xs),
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 10,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 2),
              Text(
                '${(confidence * 100).round()}%',
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ];
      
      default:
        return [];
    }
  }

  List<Widget> _buildConnectionPins(ThemeColors colors) {
    final pins = <Widget>[];
    
    // Input pins (left side)
    if (_hasInputs()) {
      pins.add(
        Positioned(
          left: -6,
          top: block.defaultHeight / 2 - 6,
          child: _buildConnectionPin(
            'input',
            ConnectionType.execution,
            colors,
            isInput: true,
          ),
        ),
      );
      
      // Data input pin (slightly below execution)
      if (block.type != LogicBlockType.goal) {
        pins.add(
          Positioned(
            left: -6,
            top: block.defaultHeight / 2 + 4,
            child: _buildConnectionPin(
              'data_input',
              ConnectionType.data,
              colors,
              isInput: true,
            ),
          ),
        );
      }
    }
    
    // Output pins (right side)
    if (_hasOutputs()) {
      pins.add(
        Positioned(
          right: -6,
          top: block.defaultHeight / 2 - 6,
          child: _buildConnectionPin(
            'output',
            ConnectionType.execution,
            colors,
            isInput: false,
          ),
        ),
      );
      
      // Data output pin
      if (block.type != LogicBlockType.exit) {
        pins.add(
          Positioned(
            right: -6,
            top: block.defaultHeight / 2 + 4,
            child: _buildConnectionPin(
              'data_output',
              ConnectionType.data,
              colors,
              isInput: false,
            ),
          ),
        );
      }
    }
    
    return pins;
  }

  Widget _buildConnectionPin(
    String pin,
    ConnectionType type,
    ThemeColors colors, {
    required bool isInput,
  }) {
    return GestureDetector(
      onTapDown: isInput ? null : (details) {
        onConnectionStart(pin, type);
      },
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: type == ConnectionType.execution 
              ? colors.onSurface 
              : _getDataPinColor(pin, colors),
          shape: type == ConnectionType.execution 
              ? BoxShape.rectangle 
              : BoxShape.circle,
          border: Border.all(
            color: colors.background,
            width: 2,
          ),
        ),
        child: type == ConnectionType.execution && !isInput
            ? Icon(
                Icons.play_arrow,
                size: 6,
                color: colors.background,
              )
            : null,
      ),
    );
  }

  Color _getBlockColor(ThemeColors colors) {
    if (isActive) {
      return _getBlockAccentColor().withOpacity(0.15);
    }
    if (isSelected) {
      return colors.surface;
    }
    if (isHovered) {
      return colors.surface.withOpacity(0.8);
    }
    return colors.background;
  }

  Color _getBorderColor(ThemeColors colors) {
    if (isActive) {
      return _getBlockAccentColor();
    }
    if (isSelected) {
      return colors.primary;
    }
    if (isHovered) {
      return _getBlockAccentColor().withOpacity(0.6);
    }
    return _getBlockAccentColor().withOpacity(0.4);
  }

  Color _getBlockAccentColor() {
    // Convert hex color to Color object
    final hexColor = block.displayColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  Color _getDataPinColor(String pin, ThemeColors colors) {
    // Color-code data pins by type
    if (pin.contains('context')) return colors.accent;
    if (pin.contains('goal')) return colors.success;
    if (pin.contains('result')) return colors.primary;
    return colors.onSurfaceVariant;
  }

  IconData _getBlockIcon() {
    switch (block.type) {
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

  String _getTypeLabel() {
    switch (block.type) {
      case LogicBlockType.goal:
        return 'GOAL';
      case LogicBlockType.context:
        return 'CONTEXT';
      case LogicBlockType.gateway:
        return 'GATEWAY';
      case LogicBlockType.reasoning:
        return 'REASON';
      case LogicBlockType.fallback:
        return 'FALLBACK';
      case LogicBlockType.trace:
        return 'TRACE';
      case LogicBlockType.exit:
        return 'EXIT';
    }
  }

  bool _hasInputs() {
    // Goal blocks don't have inputs (they're starting points)
    return block.type != LogicBlockType.goal;
  }

  bool _hasOutputs() {
    // Exit blocks don't have outputs (they're ending points)
    return block.type != LogicBlockType.exit;
  }
}