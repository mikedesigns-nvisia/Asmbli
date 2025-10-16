import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/logic_block.dart';
import '../models/canvas_state.dart';
import '../models/reasoning_workflow.dart';
import '../models/reasoning_capabilities.dart';
import '../presentation/widgets/block_palette.dart';
import '../services/reasoning_llm_service.dart';
import '../services/workflow_execution_engine.dart';
import '../services/workflow_persistence_service.dart';
import '../../../core/services/llm/unified_llm_service.dart';
import '../../../core/di/service_locator.dart';

/// State notifier for canvas interactions and workflow management
class CanvasNotifier extends StateNotifier<CanvasState> {
  late final ReasoningLLMService _reasoningService;
  late final WorkflowExecutionEngine _executionEngine;
  late final WorkflowPersistenceService _persistenceService;
  WorkflowExecutionResult? _lastExecutionResult;
  bool _isExecuting = false;
  String? _currentExecutingBlockId;

  CanvasNotifier() : super(CanvasState.empty()) {
    _initializeServices();
  }

  static const _uuid = Uuid();

  void _initializeServices() {
    try {
      final unifiedLLMService = ServiceLocator.instance.get<UnifiedLLMService>();
      _reasoningService = ReasoningLLMService(unifiedLLMService);
      _executionEngine = WorkflowExecutionEngine(_reasoningService);
      _persistenceService = ServiceLocator.instance.get<WorkflowPersistenceService>();
      
      // Listen to execution events
      _executionEngine.executionEvents.listen((event) {
        _handleExecutionEvent(event);
      });
    } catch (e) {
      print('Warning: Could not initialize reasoning services: $e');
      // Continue without reasoning capabilities for now
    }
  }

  void _handleExecutionEvent(ExecutionEvent event) {
    if (event is BlockStarted) {
      _currentExecutingBlockId = event.blockId;
    } else if (event is BlockCompleted) {
      _currentExecutingBlockId = null;
    } else if (event is ExecutionCompleted || event is ExecutionFailed) {
      _isExecuting = false;
      _currentExecutingBlockId = null;
    }
    
    // Update state to trigger UI refresh
    state = state.copyWith(
      uiState: {
        ...state.uiState,
        'is_executing': _isExecuting,
        'current_executing_block': _currentExecutingBlockId,
        'last_execution_result': _lastExecutionResult,
      },
    );
  }

  // Workflow management
  void createNewWorkflow({String? name}) {
    final workflow = ReasoningWorkflow.empty().copyWith(
      name: name ?? 'New Reasoning Flow',
    );
    state = state.copyWith(
      workflow: workflow,
      selection: const SelectionState(),
      dragState: const DragState(),
      pendingConnection: null,
    );
  }

  void loadWorkflow(ReasoningWorkflow workflow) {
    state = state.copyWith(
      workflow: workflow,
      selection: const SelectionState(),
      dragState: const DragState(),
      pendingConnection: null,
    );
  }

  void updateWorkflowName(String name) {
    final updatedWorkflow = state.workflow.copyWith(
      name: name,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(workflow: updatedWorkflow);
    markAsModified();
  }

  // Block management
  void addBlock(LogicBlockTemplate template, Position position) {
    final block = LogicBlock(
      id: _uuid.v4(),
      type: template.type,
      label: template.label,
      position: position,
      properties: _getDefaultProperties(template.type),
    );

    final updatedBlocks = [...state.workflow.blocks, block];
    final updatedWorkflow = state.workflow.copyWith(
      blocks: updatedBlocks,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(workflow: updatedWorkflow);
    markAsModified();
  }

  void removeBlock(String blockId) {
    final updatedBlocks = state.workflow.blocks
        .where((block) => block.id != blockId)
        .toList();
    
    // Remove connections involving this block
    final updatedConnections = state.workflow.connections
        .where((conn) => 
            conn.sourceBlockId != blockId && 
            conn.targetBlockId != blockId)
        .toList();

    final updatedWorkflow = state.workflow.copyWith(
      blocks: updatedBlocks,
      connections: updatedConnections,
      updatedAt: DateTime.now(),
    );

    // Clear selection if removed block was selected
    var updatedSelection = state.selection;
    if (updatedSelection.selectedBlockIds.contains(blockId)) {
      updatedSelection = updatedSelection.copyWith(
        selectedBlockIds: updatedSelection.selectedBlockIds
            .where((id) => id != blockId)
            .toSet(),
      );
    }
    if (updatedSelection.activeBlockId == blockId) {
      updatedSelection = updatedSelection.copyWith(activeBlockId: null);
    }

    state = state.copyWith(
      workflow: updatedWorkflow,
      selection: updatedSelection,
    );
  }

  void updateBlockPosition(String blockId, Position newPosition) {
    final updatedBlocks = state.workflow.blocks.map((block) {
      if (block.id == blockId) {
        return block.copyWith(position: newPosition);
      }
      return block;
    }).toList();

    final updatedWorkflow = state.workflow.copyWith(
      blocks: updatedBlocks,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(workflow: updatedWorkflow);
    markAsModified();
  }

  void updateBlockProperties(String blockId, Map<String, dynamic> properties) {
    final updatedBlocks = state.workflow.blocks.map((block) {
      if (block.id == blockId) {
        return block.copyWith(properties: properties);
      }
      return block;
    }).toList();

    final updatedWorkflow = state.workflow.copyWith(
      blocks: updatedBlocks,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(workflow: updatedWorkflow);
    markAsModified();
  }

  // Connection management
  void addConnection(
    String sourceBlockId,
    String targetBlockId,
    String sourcePin,
    String targetPin,
    ConnectionType type,
  ) {
    // Check if connection already exists
    final existingConnection = state.workflow.connections.where((conn) =>
        conn.sourceBlockId == sourceBlockId &&
        conn.targetBlockId == targetBlockId &&
        conn.sourcePin == sourcePin &&
        conn.targetPin == targetPin).firstOrNull;

    if (existingConnection != null) return;

    final connection = BlockConnection(
      id: _uuid.v4(),
      sourceBlockId: sourceBlockId,
      targetBlockId: targetBlockId,
      sourcePin: sourcePin,
      targetPin: targetPin,
      type: type,
    );

    final updatedConnections = [...state.workflow.connections, connection];
    final updatedWorkflow = state.workflow.copyWith(
      connections: updatedConnections,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(workflow: updatedWorkflow);
    markAsModified();
  }

  void removeConnection(String connectionId) {
    final updatedConnections = state.workflow.connections
        .where((conn) => conn.id != connectionId)
        .toList();

    final updatedWorkflow = state.workflow.copyWith(
      connections: updatedConnections,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(workflow: updatedWorkflow);
    markAsModified();
  }

  // Selection management
  void selectBlock(String blockId) {
    state = state.copyWith(
      selection: state.selection.copyWith(
        selectedBlockIds: {blockId},
        activeBlockId: null,
      ),
    );
  }

  void toggleBlockSelection(String blockId) {
    final currentSelection = state.selection.selectedBlockIds;
    final newSelection = currentSelection.contains(blockId)
        ? currentSelection.where((id) => id != blockId).toSet()
        : {...currentSelection, blockId};

    state = state.copyWith(
      selection: state.selection.copyWith(
        selectedBlockIds: newSelection,
      ),
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selection: const SelectionState(),
    );
  }

  void setActiveBlock(String? blockId) {
    state = state.copyWith(
      selection: state.selection.copyWith(
        activeBlockId: blockId,
      ),
    );
  }

  void setHoveredBlock(String? blockId) {
    state = state.copyWith(
      selection: state.selection.copyWith(
        hoveredBlockId: blockId,
      ),
    );
  }

  // Drag operations
  void startBlockDrag(String blockId, Position startPosition) {
    state = state.copyWith(
      dragState: DragState(
        isDragging: true,
        draggedBlockId: blockId,
        dragStartPosition: startPosition,
        currentDragPosition: startPosition,
        dragType: DragType.block,
      ),
    );
  }

  void updateBlockDrag(String blockId, Position currentPosition) {
    if (state.dragState.draggedBlockId != blockId) return;

    final delta = Position(
      x: currentPosition.x - state.dragState.dragStartPosition!.x,
      y: currentPosition.y - state.dragState.dragStartPosition!.y,
    );

    // Update position of dragged block(s)
    final blocksToMove = state.selection.selectedBlockIds.contains(blockId)
        ? state.selection.selectedBlockIds
        : {blockId};

    final updatedBlocks = state.workflow.blocks.map((block) {
      if (blocksToMove.contains(block.id)) {
        final originalPosition = _getOriginalPosition(block.id);
        return block.copyWith(
          position: Position(
            x: originalPosition.x + delta.x,
            y: originalPosition.y + delta.y,
          ),
        );
      }
      return block;
    }).toList();

    final updatedWorkflow = state.workflow.copyWith(blocks: updatedBlocks);

    state = state.copyWith(
      workflow: updatedWorkflow,
      dragState: state.dragState.copyWith(
        currentDragPosition: currentPosition,
      ),
    );
  }

  void endBlockDrag(String blockId) {
    state = state.copyWith(
      dragState: const DragState(),
    );
  }

  void startCanvasDrag(Position startPosition) {
    state = state.copyWith(
      dragState: DragState(
        isDragging: true,
        dragStartPosition: startPosition,
        currentDragPosition: startPosition,
        dragType: DragType.canvas,
      ),
    );
  }

  void updateCanvasDrag(Position currentPosition) {
    state = state.copyWith(
      dragState: state.dragState.copyWith(
        currentDragPosition: currentPosition,
      ),
    );
  }

  void endCanvasDrag() {
    // Select blocks within the selection rectangle
    if (state.dragState.dragStartPosition != null &&
        state.dragState.currentDragPosition != null) {
      final selectedBlocks = _getBlocksInRectangle(
        state.dragState.dragStartPosition!,
        state.dragState.currentDragPosition!,
      );

      state = state.copyWith(
        selection: state.selection.copyWith(
          selectedBlockIds: selectedBlocks.map((b) => b.id).toSet(),
        ),
        dragState: const DragState(),
      );
    } else {
      state = state.copyWith(dragState: const DragState());
    }
  }

  // Connection creation
  void startConnection(
    String blockId,
    String pin,
    Position position,
    ConnectionType type,
  ) {
    state = state.copyWith(
      pendingConnection: PendingConnection(
        sourceBlockId: blockId,
        sourcePin: pin,
        currentPosition: position,
        type: type,
      ),
    );
  }

  void updateConnectionPosition(Position position) {
    if (state.pendingConnection != null) {
      state = state.copyWith(
        pendingConnection: state.pendingConnection!.copyWith(
          currentPosition: position,
        ),
      );
    }
  }

  void completeConnection(String targetBlockId, String targetPin) {
    if (state.pendingConnection != null) {
      addConnection(
        state.pendingConnection!.sourceBlockId,
        targetBlockId,
        state.pendingConnection!.sourcePin,
        targetPin,
        state.pendingConnection!.type,
      );
    }
    state = state.copyWith(pendingConnection: null);
  }

  void cancelConnection() {
    state = state.copyWith(pendingConnection: null);
  }

  // Viewport management
  void updateViewport({double? zoom, Position? offset}) {
    state = state.copyWith(
      viewport: state.viewport.copyWith(
        zoom: zoom,
        offset: offset,
      ),
    );
  }

  void toggleGrid() {
    state = state.copyWith(
      isGridVisible: !state.isGridVisible,
    );
  }

  void toggleMinimap() {
    state = state.copyWith(
      isMinimapVisible: !state.isMinimapVisible,
    );
  }

  // Workflow execution methods
  Future<void> executeWorkflow({
    required String modelId,
    Map<String, dynamic>? initialContext,
  }) async {
    if (_isExecuting) {
      throw Exception('Workflow is already executing');
    }

    final validation = state.workflow.validate();
    if (!validation.isValid) {
      throw Exception('Workflow validation failed: ${validation.errors.join(', ')}');
    }

    _isExecuting = true;
    _currentExecutingBlockId = null;
    _lastExecutionResult = null;

    try {
      final result = await _executionEngine.executeWorkflow(
        state.workflow,
        modelId,
        initialContext: initialContext ?? {
          'context_data': 'Test context for reasoning workflow',
        },
      );

      _lastExecutionResult = result;
    } catch (e) {
      _isExecuting = false;
      rethrow;
    }
  }

  Future<ReasoningCapabilities> getModelCapabilities(String modelId) async {
    return await _reasoningService.getModelCapabilities(modelId);
  }

  Stream<ExecutionEvent> get executionEvents => _executionEngine.executionEvents;

  WorkflowExecutionResult? get lastExecutionResult => _lastExecutionResult;
  bool get isExecuting => _isExecuting;
  String? get currentExecutingBlockId => _currentExecutingBlockId;

  @override
  void dispose() {
    _executionEngine.dispose();
    super.dispose();
  }

  // Utility methods
  Map<String, dynamic> _getDefaultProperties(LogicBlockType type) {
    switch (type) {
      case LogicBlockType.goal:
        return {
          'description': '',
          'constraints': <String>[],
          'successCriteria': '',
        };
      case LogicBlockType.context:
        return {
          'sources': <String>[],
          'filters': <String>[],
          'maxResults': 10,
        };
      case LogicBlockType.gateway:
        return {
          'confidence': 0.8,
          'strategy': 'llm_decision',
        };
      case LogicBlockType.reasoning:
        return {
          'pattern': 'react',
          'maxIterations': 3,
        };
      case LogicBlockType.fallback:
        return {
          'retryCount': 2,
          'escalationPath': 'human',
        };
      case LogicBlockType.trace:
        return {
          'level': 'info',
          'includeState': true,
        };
      case LogicBlockType.exit:
        return {
          'validationChecks': <String>[],
          'partialResults': true,
        };
    }
  }

  Position _getOriginalPosition(String blockId) {
    // In a real implementation, we'd store original positions when drag starts
    // For now, just use current position
    return state.workflow.blocks
        .firstWhere((b) => b.id == blockId)
        .position;
  }

  List<LogicBlock> _getBlocksInRectangle(Position start, Position end) {
    final left = start.x < end.x ? start.x : end.x;
    final right = start.x > end.x ? start.x : end.x;
    final top = start.y < end.y ? start.y : end.y;
    final bottom = start.y > end.y ? start.y : end.y;

    return state.workflow.blocks.where((block) {
      final blockLeft = block.position.x;
      final blockRight = block.position.x + block.defaultWidth;
      final blockTop = block.position.y;
      final blockBottom = block.position.y + block.defaultHeight;

      return blockLeft < right &&
             blockRight > left &&
             blockTop < bottom &&
             blockBottom > top;
    }).toList();
  }

  // Persistence methods
  
  /// Save the current workflow to database
  Future<void> saveWorkflow() async {
    try {
      await _persistenceService.saveWorkflow(state.workflow);
      
      // Update state to reflect saved status
      state = state.copyWith(
        uiState: {
          ...state.uiState,
          'lastSaved': DateTime.now().toIso8601String(),
          'hasUnsavedChanges': false,
        },
      );
    } catch (e) {
      print('Error saving workflow: $e');
      rethrow;
    }
  }

  /// Load a workflow by ID
  Future<void> loadWorkflowById(String workflowId) async {
    try {
      final workflow = await _persistenceService.loadWorkflow(workflowId);
      if (workflow != null) {
        loadWorkflow(workflow);
      }
    } catch (e) {
      print('Error loading workflow: $e');
      rethrow;
    }
  }

  /// Export workflow as JSON
  Future<String> exportWorkflowAsJson() async {
    try {
      return await _persistenceService.exportWorkflowAsJson(state.workflow.id);
    } catch (e) {
      print('Error exporting workflow: $e');
      rethrow;
    }
  }

  /// Import workflow from JSON
  Future<void> importWorkflowFromJson(String jsonData) async {
    try {
      final workflow = await _persistenceService.importWorkflowFromJson(jsonData);
      loadWorkflow(workflow);
    } catch (e) {
      print('Error importing workflow: $e');
      rethrow;
    }
  }

  /// Duplicate current workflow
  Future<void> duplicateWorkflow({String? newName}) async {
    try {
      final duplicate = await _persistenceService.duplicateWorkflow(
        state.workflow.id,
        newName: newName,
      );
      loadWorkflow(duplicate);
    } catch (e) {
      print('Error duplicating workflow: $e');
      rethrow;
    }
  }

  /// Delete workflow
  Future<void> deleteWorkflow(String workflowId) async {
    try {
      await _persistenceService.deleteWorkflow(workflowId);
      
      // If deleting current workflow, create new empty one
      if (state.workflow.id == workflowId) {
        createNewWorkflow();
      }
    } catch (e) {
      print('Error deleting workflow: $e');
      rethrow;
    }
  }

  /// Get all workflows
  Future<List<ReasoningWorkflow>> getAllWorkflows({
    bool includeTemplates = true,
    String? searchQuery,
  }) async {
    try {
      return await _persistenceService.loadAllWorkflows(
        includeTemplates: includeTemplates,
        searchQuery: searchQuery,
      );
    } catch (e) {
      print('Error loading workflows: $e');
      return [];
    }
  }

  /// Mark workflow as having unsaved changes
  void markAsModified() {
    state = state.copyWith(
      uiState: {
        ...state.uiState,
        'hasUnsavedChanges': true,
      },
    );
  }
}

/// Canvas provider for state management
final canvasProvider = StateNotifierProvider<CanvasNotifier, CanvasState>((ref) {
  return CanvasNotifier();
});

/// Provider for workflow validation
final workflowValidationProvider = Provider<ValidationResult>((ref) {
  final canvasState = ref.watch(canvasProvider);
  return canvasState.workflow.validate();
});