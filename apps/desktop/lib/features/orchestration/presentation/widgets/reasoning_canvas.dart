import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/logic_block.dart';
import '../../models/canvas_state.dart';
import '../../providers/canvas_provider.dart';
import 'logic_block_widget.dart';
import 'connection_painter.dart';
import 'canvas_grid.dart';
import 'block_palette.dart';

/// Main visual reasoning canvas implementing dual-flow architecture
class ReasoningCanvas extends ConsumerStatefulWidget {
  const ReasoningCanvas({super.key});

  @override
  ConsumerState<ReasoningCanvas> createState() => _ReasoningCanvasState();
}

class _ReasoningCanvasState extends ConsumerState<ReasoningCanvas> {
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();
  
  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final canvasState = ref.watch(canvasProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border, width: 1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        child: Stack(
          children: [
            // Main canvas area with pan/zoom
            _buildMainCanvas(canvasState, colors),
            
            // Block palette (left side)
            const Positioned(
              left: SpacingTokens.md,
              top: SpacingTokens.md,
              child: BlockPalette(),
            ),
            
            // Canvas controls (top right)
            Positioned(
              right: SpacingTokens.md,
              top: SpacingTokens.md,
              child: _buildCanvasControls(colors),
            ),
            
            // Status bar (bottom)
            Positioned(
              left: SpacingTokens.md,
              right: SpacingTokens.md,
              bottom: SpacingTokens.md,
              child: _buildStatusBar(canvasState, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCanvas(CanvasState canvasState, ThemeColors colors) {
    return InteractiveViewer(
      key: _canvasKey,
      transformationController: _transformationController,
      minScale: 0.25,
      maxScale: 4.0,
      boundaryMargin: const EdgeInsets.all(200),
      constrained: false,
      onInteractionStart: _handleInteractionStart,
      onInteractionUpdate: _handleInteractionUpdate,
      onInteractionEnd: _handleInteractionEnd,
      child: SizedBox(
        width: 5000, // Large canvas area
        height: 5000,
        child: CustomPaint(
          painter: canvasState.isGridVisible 
              ? CanvasGridPainter(colors: colors, zoom: canvasState.viewport.zoom)
              : null,
          child: Stack(
            children: [
              // Background for interactions
              GestureDetector(
                onTapDown: _handleCanvasTapDown,
                onTapUp: _handleCanvasTapUp,
                onPanStart: _handleCanvasPanStart,
                onPanUpdate: _handleCanvasPanUpdate,
                onPanEnd: _handleCanvasPanEnd,
                child: Container(
                  width: 5000,
                  height: 5000,
                  color: Colors.transparent,
                ),
              ),
              
              // Connections layer
              CustomPaint(
                painter: ConnectionPainter(
                  connections: canvasState.workflow.connections,
                  blocks: canvasState.workflow.blocks,
                  pendingConnection: canvasState.pendingConnection,
                  colors: colors,
                ),
                size: const Size(5000, 5000),
              ),
              
              // Logic blocks layer
              ...canvasState.workflow.blocks.map((block) => Positioned(
                left: block.position.x,
                top: block.position.y,
                child: LogicBlockWidget(
                  block: block,
                  isSelected: canvasState.selection.isSelected(block.id),
                  isActive: canvasState.selection.isActive(block.id),
                  isHovered: canvasState.selection.isHovered(block.id),
                  onTap: () => _handleBlockTap(block.id),
                  onDoubleTap: () => _handleBlockDoubleTap(block.id),
                  onPanStart: (details) => _handleBlockPanStart(block.id, details),
                  onPanUpdate: (details) => _handleBlockPanUpdate(block.id, details),
                  onPanEnd: (details) => _handleBlockPanEnd(block.id, details),
                  onConnectionStart: (pin, type) => _handleConnectionStart(block.id, pin, type),
                ),
              )),
              
              // Selection rectangle (for multi-select)
              if (canvasState.dragState.dragType == DragType.canvas && canvasState.dragState.isDragging)
                _buildSelectionRectangle(canvasState, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasControls(ThemeColors colors) {
    return AsmblCard(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _zoomIn,
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom In',
          ),
          IconButton(
            onPressed: _zoomOut,
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom Out',
          ),
          IconButton(
            onPressed: _resetZoom,
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Reset View',
          ),
          const SizedBox(width: SpacingTokens.sm),
          IconButton(
            onPressed: _toggleGrid,
            icon: Icon(
              ref.watch(canvasProvider).isGridVisible 
                  ? Icons.grid_on 
                  : Icons.grid_off
            ),
            tooltip: 'Toggle Grid',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(CanvasState canvasState, ThemeColors colors) {
    final validation = canvasState.workflow.validate();
    
    return AsmblCard(
      child: Row(
        children: [
          // Workflow stats
          Text(
            '${canvasState.workflow.blocks.length} blocks, ${canvasState.workflow.connections.length} connections',
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: SpacingTokens.md),
          
          // Validation status
          Icon(
            validation.isValid ? Icons.check_circle : Icons.error,
            size: 16,
            color: validation.isValid ? colors.success : colors.error,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            validation.isValid ? 'Valid' : '${validation.errors.length} errors',
            style: TextStyles.caption.copyWith(
              color: validation.isValid ? colors.success : colors.error,
            ),
          ),
          
          const Spacer(),
          
          // Zoom level
          Text(
            '${(canvasState.viewport.zoom * 100).round()}%',
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionRectangle(CanvasState canvasState, ThemeColors colors) {
    if (canvasState.dragState.dragStartPosition == null || 
        canvasState.dragState.currentDragPosition == null) {
      return const SizedBox.shrink();
    }
    
    final start = canvasState.dragState.dragStartPosition!;
    final current = canvasState.dragState.currentDragPosition!;
    
    final left = start.x < current.x ? start.x : current.x;
    final top = start.y < current.y ? start.y : current.y;
    final width = (start.x - current.x).abs();
    final height = (start.y - current.y).abs();
    
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: colors.primary, width: 2),
          color: colors.primary.withOpacity(0.1),
        ),
      ),
    );
  }

  // Interaction handlers
  void _handleInteractionStart(ScaleStartDetails details) {
    // Handle zoom/pan start
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    // Update viewport state
    final currentTransform = _transformationController.value;
    ref.read(canvasProvider.notifier).updateViewport(
      zoom: currentTransform.getMaxScaleOnAxis(),
      offset: Position(
        x: currentTransform.getTranslation().x,
        y: currentTransform.getTranslation().y,
      ),
    );
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    // Handle zoom/pan end
  }

  void _handleCanvasTapDown(TapDownDetails details) {
    // Clear selection if clicking on empty canvas
    ref.read(canvasProvider.notifier).clearSelection();
  }

  void _handleCanvasTapUp(TapUpDetails details) {
    // Handle canvas tap
  }

  void _handleCanvasPanStart(DragStartDetails details) {
    // Start selection rectangle drag
    final localPosition = _getLocalPosition(details.globalPosition);
    ref.read(canvasProvider.notifier).startCanvasDrag(localPosition);
  }

  void _handleCanvasPanUpdate(DragUpdateDetails details) {
    // Update selection rectangle
    final localPosition = _getLocalPosition(details.globalPosition);
    ref.read(canvasProvider.notifier).updateCanvasDrag(localPosition);
  }

  void _handleCanvasPanEnd(DragEndDetails details) {
    // End selection rectangle and select blocks within
    ref.read(canvasProvider.notifier).endCanvasDrag();
  }

  void _handleBlockTap(String blockId) {
    if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.metaLeft) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft)) {
      // Multi-select
      ref.read(canvasProvider.notifier).toggleBlockSelection(blockId);
    } else {
      // Single select
      ref.read(canvasProvider.notifier).selectBlock(blockId);
    }
  }

  void _handleBlockDoubleTap(String blockId) {
    // Open block configuration
    ref.read(canvasProvider.notifier).setActiveBlock(blockId);
  }

  void _handleBlockPanStart(String blockId, DragStartDetails details) {
    // Start block drag
    final localPosition = _getLocalPosition(details.globalPosition);
    ref.read(canvasProvider.notifier).startBlockDrag(blockId, localPosition);
  }

  void _handleBlockPanUpdate(String blockId, DragUpdateDetails details) {
    // Update block position
    final localPosition = _getLocalPosition(details.globalPosition);
    ref.read(canvasProvider.notifier).updateBlockDrag(blockId, localPosition);
  }

  void _handleBlockPanEnd(String blockId, DragEndDetails details) {
    // End block drag
    ref.read(canvasProvider.notifier).endBlockDrag(blockId);
  }

  void _handleConnectionStart(String blockId, String pin, ConnectionType type) {
    // Start creating a connection
    final block = ref.read(canvasProvider).workflow.blocks.firstWhere((b) => b.id == blockId);
    final position = Position(
      x: block.position.x + block.defaultWidth / 2,
      y: block.position.y + block.defaultHeight / 2,
    );
    ref.read(canvasProvider.notifier).startConnection(blockId, pin, position, type);
  }

  // Utility methods
  Position _getLocalPosition(Offset globalPosition) {
    final RenderBox renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final localOffset = renderBox.globalToLocal(globalPosition);
    final transform = _transformationController.value;
    
    // Apply inverse transform to get canvas coordinates
    final canvasOffset = transform.getTranslation();
    final scale = transform.getMaxScaleOnAxis();
    
    return Position(
      x: (localOffset.dx - canvasOffset.x) / scale,
      y: (localOffset.dy - canvasOffset.y) / scale,
    );
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.25).clamp(0.25, 4.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 0.8).clamp(0.25, 4.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _toggleGrid() {
    ref.read(canvasProvider.notifier).toggleGrid();
  }
}