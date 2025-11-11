import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Canvas state model
class CanvasState {
  final String? serverUrl;
  final bool isReady;
  final double loadingProgress;
  final String? selectedDesignSystem;
  final List<Map<String, dynamic>> availableDesignSystems;
  final Map<String, dynamic>? currentCanvasState;
  final List<String> selectedElements;
  final String currentTool;
  final bool hasUnsavedChanges;
  final String? errorMessage;

  const CanvasState({
    this.serverUrl,
    this.isReady = false,
    this.loadingProgress = 0.0,
    this.selectedDesignSystem,
    this.availableDesignSystems = const [],
    this.currentCanvasState,
    this.selectedElements = const [],
    this.currentTool = 'select',
    this.hasUnsavedChanges = false,
    this.errorMessage,
  });

  CanvasState copyWith({
    String? serverUrl,
    bool? isReady,
    double? loadingProgress,
    String? selectedDesignSystem,
    List<Map<String, dynamic>>? availableDesignSystems,
    Map<String, dynamic>? currentCanvasState,
    List<String>? selectedElements,
    String? currentTool,
    bool? hasUnsavedChanges,
    String? errorMessage,
  }) {
    return CanvasState(
      serverUrl: serverUrl ?? this.serverUrl,
      isReady: isReady ?? this.isReady,
      loadingProgress: loadingProgress ?? this.loadingProgress,
      selectedDesignSystem: selectedDesignSystem ?? this.selectedDesignSystem,
      availableDesignSystems: availableDesignSystems ?? this.availableDesignSystems,
      currentCanvasState: currentCanvasState ?? this.currentCanvasState,
      selectedElements: selectedElements ?? this.selectedElements,
      currentTool: currentTool ?? this.currentTool,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      errorMessage: errorMessage,
    );
  }
}

/// Canvas state notifier
class CanvasNotifier extends StateNotifier<CanvasState> {
  CanvasNotifier() : super(const CanvasState()) {
    _loadDesignSystems();
  }

  /// Initialize canvas with server URL
  void initialize(String serverUrl) {
    state = state.copyWith(
      serverUrl: serverUrl,
      errorMessage: null,
    );
  }

  /// Set canvas ready state
  void setReady(bool isReady) {
    state = state.copyWith(isReady: isReady);
  }

  /// Update loading progress
  void updateProgress(double progress) {
    state = state.copyWith(loadingProgress: progress);
  }

  /// Load available design systems
  Future<void> _loadDesignSystems() async {
    try {
      // Mock design systems for now
      // In real implementation, this would call the API
      final designSystems = [
        {
          'id': 'material3',
          'name': 'Material Design 3',
          'version': '1.0.0',
          'source': 'builtin',
        },
        {
          'id': 'asmbli',
          'name': 'Asmbli Design System',
          'version': '1.0.0',
          'source': 'builtin',
        },
        {
          'id': 'company-brand',
          'name': 'Company Brand',
          'version': '2.1.0',
          'source': 'context',
        },
      ];
      
      state = state.copyWith(
        availableDesignSystems: designSystems,
        selectedDesignSystem: designSystems.first['id'],
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load design systems: $e',
      );
    }
  }

  /// Load a specific design system
  Future<void> loadDesignSystem(String designSystemId) async {
    try {
      state = state.copyWith(selectedDesignSystem: designSystemId);
      
      // In real implementation, this would:
      // 1. Call the API to load the design system
      // 2. Notify the canvas to update
      // 3. Update all existing elements
      
      print('🎨 Loading design system: $designSystemId');
      
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load design system: $e',
      );
    }
  }

  /// Handle messages from canvas
  void handleCanvasMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String;
      
      switch (type) {
        case 'element_selected':
          _handleElementSelection(data);
          break;
        case 'element_created':
          _handleElementCreated(data);
          break;
        case 'element_modified':
          _handleElementModified(data);
          break;
        case 'tool_changed':
          _handleToolChanged(data);
          break;
        case 'canvas_state_changed':
          _handleCanvasStateChanged(data);
          break;
        case 'design_system_loaded':
          _handleDesignSystemLoaded(data);
          break;
        default:
          print('🤷 Unknown canvas message type: $type');
      }
    } catch (e) {
      print('❌ Failed to parse canvas message: $e');
    }
  }

  void _handleElementSelection(Map<String, dynamic> data) {
    final elementIds = (data['elementIds'] as List<dynamic>?)?.cast<String>() ?? [];
    state = state.copyWith(selectedElements: elementIds);
  }

  void _handleElementCreated(Map<String, dynamic> data) {
    state = state.copyWith(hasUnsavedChanges: true);
  }

  void _handleElementModified(Map<String, dynamic> data) {
    state = state.copyWith(hasUnsavedChanges: true);
  }

  void _handleToolChanged(Map<String, dynamic> data) {
    final tool = data['tool'] as String?;
    if (tool != null) {
      state = state.copyWith(currentTool: tool);
    }
  }

  void _handleCanvasStateChanged(Map<String, dynamic> data) {
    state = state.copyWith(
      currentCanvasState: data['state'] as Map<String, dynamic>?,
      hasUnsavedChanges: true,
    );
  }

  void _handleDesignSystemLoaded(Map<String, dynamic> data) {
    final designSystemId = data['designSystemId'] as String?;
    if (designSystemId != null) {
      print('✅ Design system loaded successfully: $designSystemId');
      state = state.copyWith(selectedDesignSystem: designSystemId);
    }
  }

  /// Set current tool
  void setCurrentTool(String tool) {
    state = state.copyWith(currentTool: tool);
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(selectedElements: []);
  }

  /// Set error message
  void setError(String error) {
    state = state.copyWith(errorMessage: error);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Mark as saved
  void markSaved() {
    state = state.copyWith(hasUnsavedChanges: false);
  }

  /// Create element programmatically
  Future<void> createElement({
    required String type,
    required double x,
    required double y,
    required double width,
    required double height,
    String? text,
    Map<String, dynamic>? style,
    String? component,
    String? variant,
  }) async {
    try {
      // This would call the canvas API to create an element
      print('🎨 Creating element: $type at ($x, $y)');
      
      state = state.copyWith(hasUnsavedChanges: true);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  /// Delete selected elements
  Future<void> deleteSelectedElements() async {
    try {
      if (state.selectedElements.isEmpty) return;
      
      // This would call the canvas API to delete elements
      print('🗑️ Deleting elements: ${state.selectedElements}');
      
      state = state.copyWith(
        selectedElements: [],
        hasUnsavedChanges: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete elements: $e');
    }
  }

  /// Align selected elements
  Future<void> alignElements(String alignment) async {
    try {
      if (state.selectedElements.length < 2) return;
      
      // This would call the canvas API to align elements
      print('📐 Aligning elements: $alignment');
      
      state = state.copyWith(hasUnsavedChanges: true);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to align elements: $e');
    }
  }

  /// Export canvas to code
  Future<String?> exportCode({
    required String format,
    bool includeTokens = true,
    bool componentize = true,
  }) async {
    try {
      // This would call the canvas MCP server to export code
      print('📤 Exporting code as $format');
      
      // Mock generated code for now
      if (format == 'flutter') {
        return '''import 'package:flutter/material.dart';

class GeneratedScreen extends StatelessWidget {
  const GeneratedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Generated elements would go here
          Positioned(
            left: 100,
            top: 200,
            width: 120,
            height: 40,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Generated Button'),
            ),
          ),
        ],
      ),
    );
  }
}''';
      }
      
      return 'Code generation for $format not implemented yet';
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to export code: $e');
      return null;
    }
  }

  /// Clear canvas
  Future<void> clearCanvas() async {
    try {
      // This would call the canvas API to clear all elements
      print('🧹 Clearing canvas');
      
      state = state.copyWith(
        selectedElements: [],
        currentCanvasState: null,
        hasUnsavedChanges: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to clear canvas: $e');
    }
  }

  /// Save canvas state
  Future<void> saveCanvas() async {
    try {
      // This would call the API to save canvas state
      print('💾 Saving canvas');
      
      state = state.copyWith(hasUnsavedChanges: false);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save canvas: $e');
    }
  }

  /// Load canvas state
  Future<void> loadCanvas(String canvasId) async {
    try {
      // This would call the API to load canvas state
      print('📂 Loading canvas: $canvasId');
      
      state = state.copyWith(hasUnsavedChanges: false);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load canvas: $e');
    }
  }

  /// Undo last action
  Future<void> undo() async {
    try {
      // This would call the canvas API to undo
      print('↶ Undoing last action');
      
      state = state.copyWith(hasUnsavedChanges: true);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to undo: $e');
    }
  }

  /// Redo last undone action
  Future<void> redo() async {
    try {
      // This would call the canvas API to redo
      print('↷ Redoing last action');
      
      state = state.copyWith(hasUnsavedChanges: true);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to redo: $e');
    }
  }
}

/// Canvas provider
final canvasProvider = StateNotifierProvider<CanvasNotifier, CanvasState>((ref) {
  return CanvasNotifier();
});

/// Selected elements provider
final selectedElementsProvider = Provider<List<String>>((ref) {
  return ref.watch(canvasProvider).selectedElements;
});

/// Current tool provider
final currentToolProvider = Provider<String>((ref) {
  return ref.watch(canvasProvider).currentTool;
});

/// Has unsaved changes provider
final hasUnsavedChangesProvider = Provider<bool>((ref) {
  return ref.watch(canvasProvider).hasUnsavedChanges;
});

/// Available design systems provider
final availableDesignSystemsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(canvasProvider).availableDesignSystems;
});

/// Selected design system provider
final selectedDesignSystemProvider = Provider<String?>((ref) {
  return ref.watch(canvasProvider).selectedDesignSystem;
});

/// Canvas ready state provider
final canvasReadyProvider = Provider<bool>((ref) {
  return ref.watch(canvasProvider).isReady;
});

/// Canvas error provider
final canvasErrorProvider = Provider<String?>((ref) {
  return ref.watch(canvasProvider).errorMessage;
});