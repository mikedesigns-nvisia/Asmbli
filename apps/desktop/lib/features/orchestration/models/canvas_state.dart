import 'package:json_annotation/json_annotation.dart';
import 'logic_block.dart';
import 'reasoning_workflow.dart';

part 'canvas_state.g.dart';

/// Canvas viewport and interaction state
@JsonSerializable()
class CanvasViewport {
  final double zoom;
  final Position offset;
  
  const CanvasViewport({
    this.zoom = 1.0,
    this.offset = const Position(x: 0, y: 0),
  });
  
  factory CanvasViewport.fromJson(Map<String, dynamic> json) => _$CanvasViewportFromJson(json);
  Map<String, dynamic> toJson() => _$CanvasViewportToJson(this);
  
  CanvasViewport copyWith({double? zoom, Position? offset}) {
    return CanvasViewport(
      zoom: zoom ?? this.zoom,
      offset: offset ?? this.offset,
    );
  }
}

/// Selection state for canvas interactions
@JsonSerializable()
class SelectionState {
  final Set<String> selectedBlockIds;
  final String? activeBlockId; // Currently being configured
  final String? hoveredBlockId;
  
  const SelectionState({
    this.selectedBlockIds = const {},
    this.activeBlockId,
    this.hoveredBlockId,
  });
  
  factory SelectionState.fromJson(Map<String, dynamic> json) => _$SelectionStateFromJson(json);
  Map<String, dynamic> toJson() => _$SelectionStateToJson(this);
  
  SelectionState copyWith({
    Set<String>? selectedBlockIds,
    String? activeBlockId,
    String? hoveredBlockId,
  }) {
    return SelectionState(
      selectedBlockIds: selectedBlockIds ?? this.selectedBlockIds,
      activeBlockId: activeBlockId,
      hoveredBlockId: hoveredBlockId,
    );
  }
  
  bool get hasSelection => selectedBlockIds.isNotEmpty;
  bool get hasMultipleSelected => selectedBlockIds.length > 1;
  
  bool isSelected(String blockId) => selectedBlockIds.contains(blockId);
  bool isActive(String blockId) => activeBlockId == blockId;
  bool isHovered(String blockId) => hoveredBlockId == blockId;
}

/// Drag operation state
@JsonSerializable()
class DragState {
  final bool isDragging;
  final String? draggedBlockId;
  final Position? dragStartPosition;
  final Position? currentDragPosition;
  final DragType? dragType;
  
  const DragState({
    this.isDragging = false,
    this.draggedBlockId,
    this.dragStartPosition,
    this.currentDragPosition,
    this.dragType,
  });
  
  factory DragState.fromJson(Map<String, dynamic> json) => _$DragStateFromJson(json);
  Map<String, dynamic> toJson() => _$DragStateToJson(this);
  
  DragState copyWith({
    bool? isDragging,
    String? draggedBlockId,
    Position? dragStartPosition,
    Position? currentDragPosition,
    DragType? dragType,
  }) {
    return DragState(
      isDragging: isDragging ?? this.isDragging,
      draggedBlockId: draggedBlockId,
      dragStartPosition: dragStartPosition,
      currentDragPosition: currentDragPosition,
      dragType: dragType,
    );
  }
}

enum DragType {
  @JsonValue('block')
  block,
  
  @JsonValue('connection')
  connection,
  
  @JsonValue('canvas')
  canvas,
}

/// Connection being created
@JsonSerializable()
class PendingConnection {
  final String sourceBlockId;
  final String sourcePin;
  final Position currentPosition;
  final ConnectionType type;
  
  const PendingConnection({
    required this.sourceBlockId,
    required this.sourcePin,
    required this.currentPosition,
    required this.type,
  });
  
  factory PendingConnection.fromJson(Map<String, dynamic> json) => _$PendingConnectionFromJson(json);
  Map<String, dynamic> toJson() => _$PendingConnectionToJson(this);
}

/// Complete canvas state including workflow and UI state
@JsonSerializable()
class CanvasState {
  final ReasoningWorkflow workflow;
  final CanvasViewport viewport;
  final SelectionState selection;
  final DragState dragState;
  final PendingConnection? pendingConnection;
  final bool isGridVisible;
  final bool isMinimapVisible;
  final Map<String, dynamic> uiState; // Additional UI preferences
  
  const CanvasState({
    required this.workflow,
    this.viewport = const CanvasViewport(),
    this.selection = const SelectionState(),
    this.dragState = const DragState(),
    this.pendingConnection,
    this.isGridVisible = true,
    this.isMinimapVisible = false,
    this.uiState = const {},
  });
  
  factory CanvasState.fromJson(Map<String, dynamic> json) => _$CanvasStateFromJson(json);
  Map<String, dynamic> toJson() => _$CanvasStateToJson(this);
  
  CanvasState copyWith({
    ReasoningWorkflow? workflow,
    CanvasViewport? viewport,
    SelectionState? selection,
    DragState? dragState,
    PendingConnection? pendingConnection,
    bool? isGridVisible,
    bool? isMinimapVisible,
    Map<String, dynamic>? uiState,
  }) {
    return CanvasState(
      workflow: workflow ?? this.workflow,
      viewport: viewport ?? this.viewport,
      selection: selection ?? this.selection,
      dragState: dragState ?? this.dragState,
      pendingConnection: pendingConnection,
      isGridVisible: isGridVisible ?? this.isGridVisible,
      isMinimapVisible: isMinimapVisible ?? this.isMinimapVisible,
      uiState: uiState ?? this.uiState,
    );
  }
  
  /// Create empty canvas state
  factory CanvasState.empty() {
    return CanvasState(
      workflow: ReasoningWorkflow.empty(),
    );
  }
  
  /// Get currently selected blocks
  List<LogicBlock> get selectedBlocks {
    return workflow.blocks
        .where((block) => selection.selectedBlockIds.contains(block.id))
        .toList();
  }
  
  /// Get currently active block
  LogicBlock? get activeBlock {
    if (selection.activeBlockId == null) return null;
    
    try {
      return workflow.blocks.firstWhere((block) => block.id == selection.activeBlockId);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if canvas has unsaved changes
  bool get hasUnsavedChanges {
    // In Phase 1, we'll implement basic change tracking
    // In later phases, this will be more sophisticated
    return workflow.blocks.isNotEmpty;
  }
  
  /// Get canvas bounds for all blocks
  ({Position topLeft, Position bottomRight}) get canvasBounds {
    if (workflow.blocks.isEmpty) {
      return (topLeft: const Position(x: 0, y: 0), bottomRight: const Position(x: 1000, y: 1000));
    }
    
    double minX = workflow.blocks.first.position.x;
    double minY = workflow.blocks.first.position.y;
    double maxX = workflow.blocks.first.position.x + workflow.blocks.first.defaultWidth;
    double maxY = workflow.blocks.first.position.y + workflow.blocks.first.defaultHeight;
    
    for (final block in workflow.blocks) {
      minX = minX < block.position.x ? minX : block.position.x;
      minY = minY < block.position.y ? minY : block.position.y;
      maxX = maxX > (block.position.x + block.defaultWidth) ? maxX : (block.position.x + block.defaultWidth);
      maxY = maxY > (block.position.y + block.defaultHeight) ? maxY : (block.position.y + block.defaultHeight);
    }
    
    // Add padding
    const padding = 100.0;
    return (
      topLeft: Position(x: minX - padding, y: minY - padding),
      bottomRight: Position(x: maxX + padding, y: maxY + padding),
    );
  }
}