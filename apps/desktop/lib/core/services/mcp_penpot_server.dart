import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../widgets/penpot_canvas.dart';
import '../models/design_tokens.dart';
import '../models/canvas_state.dart';
import '../models/design_history.dart';
import '../models/canvas_update_event.dart';
import 'design_tokens_service.dart';
import 'design_history_service.dart';

/// MCP Server for Penpot canvas operations
///
/// Provides MCP tools for AI agents to create and manipulate designs in Penpot.
/// This server acts as a bridge between LLM-generated design specs and the Penpot canvas.
///
/// Week 1: Basic element creation (rectangles, text, frames)
/// Week 2: Advanced features (components, styles, auto-layout)
/// Week 3: Context library integration, design tokens, history/undo
/// Week 4: Element manipulation, real-time streaming, Watch Mode
class MCPPenpotServer {
  final GlobalKey<PenpotCanvasState> canvasKey;
  final DesignTokensService? designTokensService;
  final DesignHistoryService? historyService;

  /// Stream controller for canvas update events (Watch Mode)
  final _updateController = StreamController<CanvasUpdateEvent>.broadcast();

  MCPPenpotServer({
    required this.canvasKey,
    this.designTokensService,
    this.historyService,
  });

  PenpotCanvasState? get _canvas => canvasKey.currentState;

  /// Check if canvas is ready for commands
  bool get isReady => _canvas?.isPluginLoaded ?? false;

  /// Stream of canvas update events for Watch Mode
  Stream<CanvasUpdateEvent> get updateStream => _updateController.stream;

  /// Emit a canvas update event
  void _emitUpdate(CanvasUpdateEvent event) {
    _updateController.add(event);
    debugPrint('📡 Canvas update: ${event.type.displayName} ${event.description ?? ""}');
  }

  /// Dispose resources
  void dispose() {
    _updateController.close();
  }

  // ========== MCP TOOL HANDLERS ==========

  /// Create a rectangle element
  ///
  /// Tool: penpot_create_rectangle
  /// Description: Creates a rectangle with specified properties
  Future<Map<String, dynamic>> createRectangle({
    double? x,
    double? y,
    double? width,
    double? height,
    String? fill,
    String? stroke,
    double? strokeWidth,
    double? borderRadius,
    String? name,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'create_rectangle',
        params: {
          if (x != null) 'x': x,
          if (y != null) 'y': y,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
          if (fill != null) 'fill': fill,
          if (stroke != null) 'stroke': stroke,
          if (strokeWidth != null) 'strokeWidth': strokeWidth,
          if (borderRadius != null) 'borderRadius': borderRadius,
          if (name != null) 'name': name,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error creating rectangle');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementCreated,
        timestamp: DateTime.now(),
        data: data,
        elementId: data['id'] as String?,
        toolName: 'penpot_create_rectangle',
        description: 'Created rectangle${name != null ? " '$name'" : ""}',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error creating rectangle: $e');
      rethrow;
    }
  }

  /// Create a text element
  ///
  /// Tool: penpot_create_text
  /// Description: Creates a text element with specified content and styling
  Future<Map<String, dynamic>> createText({
    required String content,
    double? x,
    double? y,
    double? fontSize,
    String? fontFamily,
    int? fontWeight,
    String? color,
    String? name,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'create_text',
        params: {
          'content': content,
          if (x != null) 'x': x,
          if (y != null) 'y': y,
          if (fontSize != null) 'fontSize': fontSize,
          if (fontFamily != null) 'fontFamily': fontFamily,
          if (fontWeight != null) 'fontWeight': fontWeight,
          if (color != null) 'color': color,
          if (name != null) 'name': name,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error creating text');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      final contentPreview = content.length > 20 ? '${content.substring(0, 20)}...' : content;
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementCreated,
        timestamp: DateTime.now(),
        data: data,
        elementId: data['id'] as String?,
        toolName: 'penpot_create_text',
        description: 'Created text "$contentPreview"',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error creating text: $e');
      rethrow;
    }
  }

  /// Create a frame (container) element
  ///
  /// Tool: penpot_create_frame
  /// Description: Creates a frame that can contain other elements
  Future<Map<String, dynamic>> createFrame({
    double? x,
    double? y,
    double? width,
    double? height,
    String? name,
    List<Map<String, dynamic>>? children,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'create_frame',
        params: {
          if (x != null) 'x': x,
          if (y != null) 'y': y,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
          if (name != null) 'name': name,
          if (children != null) 'children': children,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error creating frame');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementCreated,
        timestamp: DateTime.now(),
        data: data,
        elementId: data['id'] as String?,
        toolName: 'penpot_create_frame',
        description: 'Created frame${name != null ? " '$name'" : ""}',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error creating frame: $e');
      rethrow;
    }
  }

  /// Get current canvas state
  ///
  /// Tool: penpot_get_canvas_state
  /// Description: Returns information about current page and all elements
  Future<Map<String, dynamic>> getCanvasState() async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'get_canvas_state',
        params: {},
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error getting canvas state');
      }

      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error getting canvas state: $e');
      rethrow;
    }
  }

  /// Clear all elements from canvas
  ///
  /// Tool: penpot_clear_canvas
  /// Description: Removes all elements from the current page
  Future<Map<String, dynamic>> clearCanvas() async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'clear_canvas',
        params: {},
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error clearing canvas');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.canvasCleared,
        timestamp: DateTime.now(),
        data: data,
        toolName: 'penpot_clear_canvas',
        description: 'Cleared canvas',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error clearing canvas: $e');
      rethrow;
    }
  }

  // ========== WEEK 2: ADVANCED ELEMENT TYPES ==========

  /// Create an ellipse element
  ///
  /// Tool: penpot_create_ellipse
  /// Description: Creates an ellipse/circle with specified properties
  Future<Map<String, dynamic>> createEllipse({
    double? x,
    double? y,
    double? width,
    double? height,
    String? fill,
    String? stroke,
    double? strokeWidth,
    String? name,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'create_ellipse',
        params: {
          if (x != null) 'x': x,
          if (y != null) 'y': y,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
          if (fill != null) 'fill': fill,
          if (stroke != null) 'stroke': stroke,
          if (strokeWidth != null) 'strokeWidth': strokeWidth,
          if (name != null) 'name': name,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error creating ellipse');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementCreated,
        timestamp: DateTime.now(),
        data: data,
        elementId: data['id'] as String?,
        toolName: 'penpot_create_ellipse',
        description: 'Created ellipse${name != null ? " '$name'" : ""}',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error creating ellipse: $e');
      rethrow;
    }
  }

  /// Create a custom path element
  ///
  /// Tool: penpot_create_path
  /// Description: Creates a custom path using SVG path data
  Future<Map<String, dynamic>> createPath({
    required String pathData,
    double? x,
    double? y,
    String? fill,
    String? stroke,
    double? strokeWidth,
    String? name,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'create_path',
        params: {
          'pathData': pathData,
          if (x != null) 'x': x,
          if (y != null) 'y': y,
          if (fill != null) 'fill': fill,
          if (stroke != null) 'stroke': stroke,
          if (strokeWidth != null) 'strokeWidth': strokeWidth,
          if (name != null) 'name': name,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error creating path');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementCreated,
        timestamp: DateTime.now(),
        data: data,
        elementId: data['id'] as String?,
        toolName: 'penpot_create_path',
        description: 'Created path${name != null ? " '$name'" : ""}',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error creating path: $e');
      rethrow;
    }
  }

  /// Create an image element
  ///
  /// Tool: penpot_create_image
  /// Description: Creates an image from base64 data URL
  Future<Map<String, dynamic>> createImage({
    required String dataUrl,
    double? x,
    double? y,
    double? width,
    double? height,
    String? name,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'create_image',
        params: {
          'dataUrl': dataUrl,
          if (x != null) 'x': x,
          if (y != null) 'y': y,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
          if (name != null) 'name': name,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error creating image');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementCreated,
        timestamp: DateTime.now(),
        data: data,
        elementId: data['id'] as String?,
        toolName: 'penpot_create_image',
        description: 'Created image${name != null ? " '$name'" : ""}',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error creating image: $e');
      rethrow;
    }
  }

  // ========== COMPONENT SYSTEM ==========

  /// Create a component from existing elements
  ///
  /// Tool: penpot_create_component
  /// Description: Converts elements into a reusable component
  Future<Map<String, dynamic>> createComponent({
    required List<String> elementIds,
    required String name,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'create_component',
        params: {
          'elementIds': elementIds,
          'name': name,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error creating component');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementCreated,
        timestamp: DateTime.now(),
        data: data,
        elementId: data['id'] as String?,
        toolName: 'penpot_create_component',
        description: 'Created component "$name" from ${elementIds.length} elements',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error creating component: $e');
      rethrow;
    }
  }

  // ========== STYLE MANAGEMENT ==========

  /// Create a color style
  ///
  /// Tool: penpot_create_color_style
  /// Description: Creates a named color style for brand consistency
  Future<Map<String, dynamic>> createColorStyle({
    required String name,
    required String color,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'create_color_style',
        params: {
          'name': name,
          'color': color,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error creating color style');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.styleApplied,
        timestamp: DateTime.now(),
        data: data,
        toolName: 'penpot_create_color_style',
        description: 'Created color style "$name" ($color)',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error creating color style: $e');
      rethrow;
    }
  }

  /// Create a typography style
  ///
  /// Tool: penpot_create_typography_style
  /// Description: Creates a named typography style
  Future<Map<String, dynamic>> createTypographyStyle({
    required String name,
    String? fontFamily,
    double? fontSize,
    int? fontWeight,
    double? lineHeight,
    double? letterSpacing,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'create_typography_style',
        params: {
          'name': name,
          if (fontFamily != null) 'fontFamily': fontFamily,
          if (fontSize != null) 'fontSize': fontSize,
          if (fontWeight != null) 'fontWeight': fontWeight,
          if (lineHeight != null) 'lineHeight': lineHeight,
          if (letterSpacing != null) 'letterSpacing': letterSpacing,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error creating typography style');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.styleApplied,
        timestamp: DateTime.now(),
        data: data,
        toolName: 'penpot_create_typography_style',
        description: 'Created typography style "$name"',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error creating typography style: $e');
      rethrow;
    }
  }

  /// Apply layout constraints to an element
  ///
  /// Tool: penpot_apply_layout_constraints
  /// Description: Applies responsive constraints and auto-layout (flexbox)
  Future<Map<String, dynamic>> applyLayoutConstraints({
    required String elementId,
    Map<String, String>? constraints,
    Map<String, dynamic>? layout,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'apply_layout_constraints',
        params: {
          'elementId': elementId,
          if (constraints != null) 'constraints': constraints,
          if (layout != null) 'layout': layout,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error applying layout constraints');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementUpdated,
        timestamp: DateTime.now(),
        data: data,
        elementId: elementId,
        toolName: 'penpot_apply_layout_constraints',
        description: 'Applied layout constraints to element $elementId',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error applying layout constraints: $e');
      rethrow;
    }
  }

  // ========== WEEK 3: CONTEXT & TOKENS ==========

  /// Get design tokens from context library
  ///
  /// Tool: penpot_get_design_tokens
  /// Description: Retrieves design tokens for brand-consistent designs
  Future<Map<String, dynamic>> getDesignTokens() async {
    try {
      if (designTokensService != null) {
        final tokens = await designTokensService!.getDesignTokens();
        return {
          'success': true,
          'tokens': tokens.toJson(),
        };
      } else {
        // Return default tokens if service not available
        final tokens = DesignTokens.defaultTokens();
        return {
          'success': true,
          'tokens': tokens.toJson(),
          'note': 'Using default tokens - DesignTokensService not configured',
        };
      }
    } catch (e) {
      debugPrint('❌ Error getting design tokens: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get enhanced canvas state with detailed information
  ///
  /// Tool: penpot_get_canvas_state_detailed
  /// Description: Returns detailed canvas state including statistics and element tree
  Future<Map<String, dynamic>> getCanvasStateDetailed() async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      // Get basic canvas state from plugin
      final response = await _canvas!.executeCommand(
        type: 'get_canvas_state',
        params: {},
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error getting canvas state');
      }

      final rawData = response['data'] as Map<String, dynamic>;

      // Parse into enhanced CanvasState model
      final canvasState = CanvasState.fromJson(rawData);

      return {
        'success': true,
        'state': canvasState.toJson(),
      };
    } catch (e) {
      debugPrint('❌ Error getting detailed canvas state: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get canvas statistics
  ///
  /// Tool: penpot_get_canvas_statistics
  /// Description: Returns statistics about canvas elements (counts by type, style usage, etc.)
  Future<Map<String, dynamic>> getCanvasStatistics() async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      // Get canvas state first
      final stateResponse = await getCanvasStateDetailed();

      if (!stateResponse['success']) {
        return stateResponse;
      }

      final state = CanvasState.fromJson(stateResponse['state']);

      return {
        'success': true,
        'statistics': state.statistics.toJson(),
      };
    } catch (e) {
      debugPrint('❌ Error getting canvas statistics: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Query elements by type
  ///
  /// Tool: penpot_query_elements_by_type
  /// Description: Filter and return elements of a specific type
  Future<Map<String, dynamic>> queryElementsByType({
    required String elementType,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      // Get detailed canvas state
      final stateResponse = await getCanvasStateDetailed();

      if (!stateResponse['success']) {
        return stateResponse;
      }

      final state = CanvasState.fromJson(stateResponse['state']);

      // Parse element type
      final targetType = _parseElementTypeString(elementType);

      // Filter elements by type
      final matchingElements = state.elements
          .where((element) => element.type == targetType)
          .toList();

      return {
        'success': true,
        'elementType': targetType.name,
        'count': matchingElements.length,
        'elements': matchingElements.map((e) => e.toJson()).toList(),
      };
    } catch (e) {
      debugPrint('❌ Error querying elements by type: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Helper to parse element type string
  ElementType _parseElementTypeString(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'rectangle':
      case 'rect':
        return ElementType.rectangle;
      case 'text':
        return ElementType.text;
      case 'frame':
      case 'group':
        return ElementType.frame;
      case 'ellipse':
      case 'circle':
        return ElementType.ellipse;
      case 'path':
        return ElementType.path;
      case 'image':
        return ElementType.image;
      default:
        return ElementType.unknown;
    }
  }

  /// Undo last action
  ///
  /// Tool: penpot_undo
  /// Description: Undo the last design action
  Future<Map<String, dynamic>> undo() async {
    try {
      if (historyService == null) {
        return {
          'success': false,
          'error': 'History service not configured',
        };
      }

      if (!historyService!.canUndo) {
        return {
          'success': false,
          'error': 'Nothing to undo',
        };
      }

      final entry = historyService!.undo();

      if (entry == null) {
        return {
          'success': false,
          'error': 'Failed to undo',
        };
      }

      // Note: Actual undo implementation would revert the canvas state
      // For now, we just track the history movement

      return {
        'success': true,
        'undone': entry.toJson(),
        'canUndo': historyService!.canUndo,
        'canRedo': historyService!.canRedo,
      };
    } catch (e) {
      debugPrint('❌ Error undoing: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Redo last undone action
  ///
  /// Tool: penpot_redo
  /// Description: Redo the last undone action
  Future<Map<String, dynamic>> redo() async {
    try {
      if (historyService == null) {
        return {
          'success': false,
          'error': 'History service not configured',
        };
      }

      if (!historyService!.canRedo) {
        return {
          'success': false,
          'error': 'Nothing to redo',
        };
      }

      final entry = historyService!.redo();

      if (entry == null) {
        return {
          'success': false,
          'error': 'Failed to redo',
        };
      }

      // Note: Actual redo implementation would reapply the canvas state
      // For now, we just track the history movement

      return {
        'success': true,
        'redone': entry.toJson(),
        'canUndo': historyService!.canUndo,
        'canRedo': historyService!.canRedo,
      };
    } catch (e) {
      debugPrint('❌ Error redoing: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get design history
  ///
  /// Tool: penpot_get_history
  /// Description: Get the design history with recent entries
  Future<Map<String, dynamic>> getHistory({int limit = 10}) async {
    try {
      if (historyService == null) {
        return {
          'success': false,
          'error': 'History service not configured',
        };
      }

      final summary = historyService!.getHistorySummary();
      final recentEntries = historyService!.getRecentEntries(limit: limit);

      return {
        'success': true,
        'summary': summary,
        'recentEntries': recentEntries.map((e) => e.toJson()).toList(),
      };
    } catch (e) {
      debugPrint('❌ Error getting history: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ========== EXPORT CAPABILITIES ==========

  /// Export canvas as PNG
  ///
  /// Tool: penpot_export_png
  /// Description: Export the current canvas as PNG image
  Future<Map<String, dynamic>> exportPng({
    double? scale,
    String? elementId,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'export_png',
        params: {
          if (scale != null) 'scale': scale,
          if (elementId != null) 'elementId': elementId,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error exporting PNG');
      }

      final result = {
        'success': true,
        'format': 'png',
        'dataUrl': response['data']['dataUrl'],
        'width': response['data']['width'],
        'height': response['data']['height'],
      };

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.exportCompleted,
        timestamp: DateTime.now(),
        data: result,
        elementId: elementId,
        toolName: 'penpot_export_png',
        description: 'Exported as PNG${elementId != null ? " (element $elementId)" : " (full canvas)"}',
      ));

      return result;
    } catch (e) {
      debugPrint('❌ Error exporting PNG: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Export canvas as SVG
  ///
  /// Tool: penpot_export_svg
  /// Description: Export the current canvas as SVG vector
  Future<Map<String, dynamic>> exportSvg({
    String? elementId,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'export_svg',
        params: {
          if (elementId != null) 'elementId': elementId,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error exporting SVG');
      }

      final result = {
        'success': true,
        'format': 'svg',
        'svgData': response['data']['svgData'],
        'width': response['data']['width'],
        'height': response['data']['height'],
      };

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.exportCompleted,
        timestamp: DateTime.now(),
        data: result,
        elementId: elementId,
        toolName: 'penpot_export_svg',
        description: 'Exported as SVG${elementId != null ? " (element $elementId)" : " (full canvas)"}',
      ));

      return result;
    } catch (e) {
      debugPrint('❌ Error exporting SVG: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Export canvas as PDF
  ///
  /// Tool: penpot_export_pdf
  /// Description: Export the current canvas as PDF document
  Future<Map<String, dynamic>> exportPdf({
    String? elementId,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'export_pdf',
        params: {
          if (elementId != null) 'elementId': elementId,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error exporting PDF');
      }

      final result = {
        'success': true,
        'format': 'pdf',
        'dataUrl': response['data']['dataUrl'],
        'width': response['data']['width'],
        'height': response['data']['height'],
      };

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.exportCompleted,
        timestamp: DateTime.now(),
        data: result,
        elementId: elementId,
        toolName: 'penpot_export_pdf',
        description: 'Exported as PDF${elementId != null ? " (element $elementId)" : " (full canvas)"}',
      ));

      return result;
    } catch (e) {
      debugPrint('❌ Error exporting PDF: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ========== WEEK 4: ELEMENT MANIPULATION & UPDATES ==========

  /// Update existing element properties
  ///
  /// Tool: penpot_update_element
  /// Description: Modify properties of existing canvas elements
  Future<Map<String, dynamic>> updateElement({
    required String elementId,
    double? x,
    double? y,
    double? width,
    double? height,
    String? fill,
    String? stroke,
    double? strokeWidth,
    String? content,
    Map<String, dynamic>? customProperties,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'update_element',
        params: {
          'elementId': elementId,
          if (x != null) 'x': x,
          if (y != null) 'y': y,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
          if (fill != null) 'fill': fill,
          if (stroke != null) 'stroke': stroke,
          if (strokeWidth != null) 'strokeWidth': strokeWidth,
          if (content != null) 'content': content,
          if (customProperties != null) ...customProperties,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error updating element');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementUpdated,
        timestamp: DateTime.now(),
        data: data,
        elementId: elementId,
        toolName: 'penpot_update_element',
        description: 'Updated element $elementId',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error updating element: $e');
      rethrow;
    }
  }

  /// Transform element with rotation, scale, skew
  ///
  /// Tool: penpot_transform_element
  /// Description: Apply transformations to canvas elements
  Future<Map<String, dynamic>> transformElement({
    required String elementId,
    double? rotation,
    double? scaleX,
    double? scaleY,
    double? skewX,
    double? skewY,
    bool? flipHorizontal,
    bool? flipVertical,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'transform_element',
        params: {
          'elementId': elementId,
          if (rotation != null) 'rotation': rotation,
          if (scaleX != null) 'scaleX': scaleX,
          if (scaleY != null) 'scaleY': scaleY,
          if (skewX != null) 'skewX': skewX,
          if (skewY != null) 'skewY': skewY,
          if (flipHorizontal != null) 'flipHorizontal': flipHorizontal,
          if (flipVertical != null) 'flipVertical': flipVertical,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error transforming element');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementTransformed,
        timestamp: DateTime.now(),
        data: data,
        elementId: elementId,
        toolName: 'penpot_transform_element',
        description: 'Transformed element $elementId',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error transforming element: $e');
      rethrow;
    }
  }

  /// Delete element from canvas
  ///
  /// Tool: penpot_delete_element
  /// Description: Remove elements from the canvas
  Future<Map<String, dynamic>> deleteElement({
    required String elementId,
    bool permanent = false,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'delete_element',
        params: {
          'elementId': elementId,
          'permanent': permanent,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error deleting element');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementDeleted,
        timestamp: DateTime.now(),
        data: data,
        elementId: elementId,
        toolName: 'penpot_delete_element',
        description: 'Deleted element $elementId${permanent ? " (permanent)" : ""}',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error deleting element: $e');
      rethrow;
    }
  }

  /// Duplicate element
  ///
  /// Tool: penpot_duplicate_element
  /// Description: Clone existing elements with optional offset
  Future<Map<String, dynamic>> duplicateElement({
    required String elementId,
    double offsetX = 10,
    double offsetY = 10,
    bool deepClone = true,
    bool preserveComponentLink = false,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'duplicate_element',
        params: {
          'elementId': elementId,
          'offsetX': offsetX,
          'offsetY': offsetY,
          'deepClone': deepClone,
          'preserveComponentLink': preserveComponentLink,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error duplicating element');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementDuplicated,
        timestamp: DateTime.now(),
        data: data,
        elementId: data['id'] as String?,
        toolName: 'penpot_duplicate_element',
        description: 'Duplicated element $elementId',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error duplicating element: $e');
      rethrow;
    }
  }

  /// Group elements together
  ///
  /// Tool: penpot_group_elements
  /// Description: Create a group from multiple elements
  Future<Map<String, dynamic>> groupElements({
    required List<String> elementIds,
    String? groupName,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'group_elements',
        params: {
          'elementIds': elementIds,
          if (groupName != null) 'groupName': groupName,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error grouping elements');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementsGrouped,
        timestamp: DateTime.now(),
        data: data,
        elementId: data['id'] as String?,
        toolName: 'penpot_group_elements',
        description: 'Grouped ${elementIds.length} elements${groupName != null ? " as '$groupName'" : ""}',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error grouping elements: $e');
      rethrow;
    }
  }

  /// Ungroup elements
  ///
  /// Tool: penpot_ungroup_elements
  /// Description: Dissolve a group and release its elements
  Future<Map<String, dynamic>> ungroupElements({
    required String groupId,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'ungroup_elements',
        params: {
          'groupId': groupId,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error ungrouping elements');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementsUngrouped,
        timestamp: DateTime.now(),
        data: data,
        toolName: 'penpot_ungroup_elements',
        description: 'Ungrouped elements from group $groupId',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error ungrouping elements: $e');
      rethrow;
    }
  }

  /// Reorder elements (change layer order)
  ///
  /// Tool: penpot_reorder_elements
  /// Description: Change the z-index/layer order of elements
  Future<Map<String, dynamic>> reorderElements({
    required String elementId,
    String? operation, // 'front', 'back', 'forward', 'backward'
    int? zIndex,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    try {
      final response = await _canvas!.executeCommand(
        type: 'reorder_element',
        params: {
          'elementId': elementId,
          if (operation != null) 'operation': operation,
          if (zIndex != null) 'zIndex': zIndex,
        },
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Unknown error reordering element');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Emit update event for Watch Mode
      final operationDesc = operation != null ? operation : 'z-index $zIndex';
      _emitUpdate(CanvasUpdateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: CanvasUpdateType.elementReordered,
        timestamp: DateTime.now(),
        data: data,
        elementId: elementId,
        toolName: 'penpot_reorder_elements',
        description: 'Reordered element $elementId ($operationDesc)',
      ));

      return data;
    } catch (e) {
      debugPrint('❌ Error reordering element: $e');
      rethrow;
    }
  }

  // ========== AGENT INTELLIGENCE LAYER ==========
  // Week 1: Placeholder methods for Week 2+ implementation

  /// Apply 8px grid spacing to a value
  double applyGridSnapping(double value, {int gridSize = 8}) {
    return (value / gridSize).round() * gridSize.toDouble();
  }

  /// Calculate visual hierarchy sizing based on importance
  double calculateFontSize({
    required String importance, // 'primary', 'secondary', 'tertiary'
    double baseSize = 16,
  }) {
    const goldenRatio = 1.618;

    switch (importance) {
      case 'primary':
        return baseSize * goldenRatio;
      case 'secondary':
        return baseSize;
      case 'tertiary':
        return baseSize / goldenRatio;
      default:
        return baseSize;
    }
  }

  /// Calculate appropriate spacing based on context
  double calculateSpacing({
    required String context, // 'tight', 'normal', 'loose'
    int baseUnit = 8,
  }) {
    switch (context) {
      case 'tight':
        return baseUnit.toDouble();
      case 'normal':
        return (baseUnit * 2).toDouble();
      case 'loose':
        return (baseUnit * 3).toDouble();
      default:
        return (baseUnit * 2).toDouble();
    }
  }

  /// Validate contrast ratio for accessibility
  ///
  /// Returns true if contrast meets WCAG AAA (7:1 ratio)
  /// TODO Week 2: Implement actual contrast calculation
  bool validateContrast(String textColor, String backgroundColor) {
    // Placeholder - Week 2 will implement proper contrast checking
    debugPrint('⚠️ Contrast validation not yet implemented');
    return true;
  }

  /// Build a complete design from LLM-generated spec
  ///
  /// This is the main entry point for agent-driven design creation.
  /// Week 1: Basic implementation for simple designs
  /// Week 2+: Full intelligent layout, hierarchy, and styling
  Future<Map<String, dynamic>> buildDesignFromSpec({
    required Map<String, dynamic> designSpec,
  }) async {
    if (!isReady) {
      throw Exception('Canvas not ready - plugin not loaded');
    }

    debugPrint('🎨 Building design from spec...');

    try {
      // Clear canvas first
      await clearCanvas();

      // Parse design spec and create elements
      final elements = designSpec['elements'] as List<dynamic>? ?? [];
      final createdElements = <Map<String, dynamic>>[];

      for (final elementSpec in elements) {
        final element = elementSpec as Map<String, dynamic>;
        final type = element['type'] as String;

        Map<String, dynamic>? created;

        switch (type) {
          case 'rectangle':
            created = await createRectangle(
              x: element['x'] as double?,
              y: element['y'] as double?,
              width: element['width'] as double?,
              height: element['height'] as double?,
              fill: element['fill'] as String?,
              stroke: element['stroke'] as String?,
              strokeWidth: element['strokeWidth'] as double?,
              borderRadius: element['borderRadius'] as double?,
              name: element['name'] as String?,
            );
            break;

          case 'text':
            created = await createText(
              content: element['content'] as String,
              x: element['x'] as double?,
              y: element['y'] as double?,
              fontSize: element['fontSize'] as double?,
              fontFamily: element['fontFamily'] as String?,
              fontWeight: element['fontWeight'] as int?,
              color: element['color'] as String?,
              name: element['name'] as String?,
            );
            break;

          case 'frame':
            created = await createFrame(
              x: element['x'] as double?,
              y: element['y'] as double?,
              width: element['width'] as double?,
              height: element['height'] as double?,
              name: element['name'] as String?,
            );
            break;

          default:
            debugPrint('⚠️ Unknown element type: $type');
        }

        if (created != null) {
          createdElements.add(created);
        }
      }

      debugPrint('✅ Design built successfully: ${createdElements.length} elements created');

      return {
        'success': true,
        'elementsCreated': createdElements.length,
        'elements': createdElements,
      };
    } catch (e) {
      debugPrint('❌ Error building design: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ========== MCP TOOL REGISTRATION ==========

  /// Get MCP tool definitions for this server
  ///
  /// These are the tools that agents can call via MCP protocol.
  /// Week 1: Basic CRUD operations
  /// Week 2+: Advanced tools (components, styles, layouts)
  List<Map<String, dynamic>> getToolDefinitions() {
    return [
      {
        'name': 'penpot_create_rectangle',
        'description': 'Create a rectangle element on the Penpot canvas',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'x': {'type': 'number', 'description': 'X position in pixels'},
            'y': {'type': 'number', 'description': 'Y position in pixels'},
            'width': {'type': 'number', 'description': 'Width in pixels'},
            'height': {'type': 'number', 'description': 'Height in pixels'},
            'fill': {'type': 'string', 'description': 'Fill color (hex)'},
            'stroke': {'type': 'string', 'description': 'Stroke color (hex)'},
            'strokeWidth': {'type': 'number', 'description': 'Stroke width'},
            'borderRadius': {'type': 'number', 'description': 'Border radius'},
            'name': {'type': 'string', 'description': 'Element name'},
          },
        },
      },
      {
        'name': 'penpot_create_text',
        'description': 'Create a text element on the Penpot canvas',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'content': {'type': 'string', 'description': 'Text content'},
            'x': {'type': 'number', 'description': 'X position in pixels'},
            'y': {'type': 'number', 'description': 'Y position in pixels'},
            'fontSize': {'type': 'number', 'description': 'Font size'},
            'fontFamily': {'type': 'string', 'description': 'Font family'},
            'fontWeight': {'type': 'number', 'description': 'Font weight'},
            'color': {'type': 'string', 'description': 'Text color (hex)'},
            'name': {'type': 'string', 'description': 'Element name'},
          },
          'required': ['content'],
        },
      },
      {
        'name': 'penpot_create_frame',
        'description': 'Create a frame (container) on the Penpot canvas',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'x': {'type': 'number', 'description': 'X position in pixels'},
            'y': {'type': 'number', 'description': 'Y position in pixels'},
            'width': {'type': 'number', 'description': 'Width in pixels'},
            'height': {'type': 'number', 'description': 'Height in pixels'},
            'name': {'type': 'string', 'description': 'Frame name'},
          },
        },
      },
      {
        'name': 'penpot_get_canvas_state',
        'description': 'Get current canvas state (page info, elements)',
        'inputSchema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'penpot_clear_canvas',
        'description': 'Clear all elements from the current canvas page',
        'inputSchema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'penpot_build_design',
        'description': 'Build a complete design from a structured spec',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'designSpec': {
              'type': 'object',
              'description': 'Design specification with elements array',
            },
          },
          'required': ['designSpec'],
        },
      },
      // Week 2: Advanced element types
      {
        'name': 'penpot_create_ellipse',
        'description': 'Create an ellipse or circle element',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'x': {'type': 'number'},
            'y': {'type': 'number'},
            'width': {'type': 'number'},
            'height': {'type': 'number'},
            'fill': {'type': 'string'},
            'stroke': {'type': 'string'},
            'strokeWidth': {'type': 'number'},
            'name': {'type': 'string'},
          },
        },
      },
      {
        'name': 'penpot_create_path',
        'description': 'Create a custom path using SVG path data',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'pathData': {'type': 'string', 'description': 'SVG path data'},
            'x': {'type': 'number'},
            'y': {'type': 'number'},
            'fill': {'type': 'string'},
            'stroke': {'type': 'string'},
            'strokeWidth': {'type': 'number'},
            'name': {'type': 'string'},
          },
          'required': ['pathData'],
        },
      },
      {
        'name': 'penpot_create_image',
        'description': 'Create an image from base64 data URL',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'dataUrl': {'type': 'string', 'description': 'Base64 data URL'},
            'x': {'type': 'number'},
            'y': {'type': 'number'},
            'width': {'type': 'number'},
            'height': {'type': 'number'},
            'name': {'type': 'string'},
          },
          'required': ['dataUrl'],
        },
      },
      // Week 2: Component system
      {
        'name': 'penpot_create_component',
        'description': 'Create a reusable component from elements',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'elementIds': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'IDs of elements to convert',
            },
            'name': {'type': 'string'},
          },
          'required': ['elementIds', 'name'],
        },
      },
      // Week 2: Style management
      {
        'name': 'penpot_create_color_style',
        'description': 'Create a named color style',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'color': {'type': 'string', 'description': 'Hex color'},
          },
          'required': ['name', 'color'],
        },
      },
      {
        'name': 'penpot_create_typography_style',
        'description': 'Create a named typography style',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'fontFamily': {'type': 'string'},
            'fontSize': {'type': 'number'},
            'fontWeight': {'type': 'number'},
            'lineHeight': {'type': 'number'},
            'letterSpacing': {'type': 'number'},
          },
          'required': ['name'],
        },
      },
      // Week 2: Layout constraints
      {
        'name': 'penpot_apply_layout_constraints',
        'description': 'Apply responsive constraints and auto-layout',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'elementId': {'type': 'string'},
            'constraints': {
              'type': 'object',
              'properties': {
                'horizontal': {'type': 'string'},
                'vertical': {'type': 'string'},
              },
            },
            'layout': {
              'type': 'object',
              'properties': {
                'type': {'type': 'string'},
                'direction': {'type': 'string'},
                'align': {'type': 'string'},
                'justify': {'type': 'string'},
                'gap': {'type': 'number'},
                'padding': {'type': 'number'},
              },
            },
          },
          'required': ['elementId'],
        },
      },
      // Week 3: Design tokens
      {
        'name': 'penpot_get_design_tokens',
        'description': 'Get design tokens from context library for brand-consistent designs',
        'inputSchema': {
          'type': 'object',
          'properties': {},
        },
      },
      // Week 3: Enhanced canvas state
      {
        'name': 'penpot_get_canvas_state_detailed',
        'description': 'Get detailed canvas state with statistics and element tree',
        'inputSchema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'penpot_get_canvas_statistics',
        'description': 'Get statistics about canvas elements (counts by type, style usage, etc.)',
        'inputSchema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'penpot_query_elements_by_type',
        'description': 'Query and filter elements by type (rectangle, text, frame, etc.)',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'elementType': {
              'type': 'string',
              'description': 'Element type to query (rectangle, text, frame, ellipse, path, image)',
            },
          },
          'required': ['elementType'],
        },
      },
      // Week 3: Design history
      {
        'name': 'penpot_undo',
        'description': 'Undo the last design action',
        'inputSchema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'penpot_redo',
        'description': 'Redo the last undone action',
        'inputSchema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'penpot_get_history',
        'description': 'Get the design history with recent entries',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'limit': {
              'type': 'number',
              'description': 'Number of recent entries to return (default: 10)',
            },
          },
        },
      },
      // Week 3: Export capabilities
      {
        'name': 'penpot_export_png',
        'description': 'Export canvas as PNG image',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'scale': {
              'type': 'number',
              'description': 'Export scale (1.0 = 100%, 2.0 = 200%, default: 1.0)',
            },
            'elementId': {
              'type': 'string',
              'description': 'Optional element ID to export (exports entire canvas if not specified)',
            },
          },
        },
      },
      {
        'name': 'penpot_export_svg',
        'description': 'Export canvas as SVG vector',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'elementId': {
              'type': 'string',
              'description': 'Optional element ID to export (exports entire canvas if not specified)',
            },
          },
        },
      },
      {
        'name': 'penpot_export_pdf',
        'description': 'Export canvas as PDF document',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'elementId': {
              'type': 'string',
              'description': 'Optional element ID to export (exports entire canvas if not specified)',
            },
          },
        },
      },
      // Week 4: Element manipulation & updates
      {
        'name': 'penpot_update_element',
        'description': 'Update properties of existing canvas elements (position, size, styles, content)',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'elementId': {'type': 'string', 'description': 'ID of element to update'},
            'x': {'type': 'number', 'description': 'New x position'},
            'y': {'type': 'number', 'description': 'New y position'},
            'width': {'type': 'number', 'description': 'New width'},
            'height': {'type': 'number', 'description': 'New height'},
            'fill': {'type': 'string', 'description': 'Fill color (hex)'},
            'stroke': {'type': 'string', 'description': 'Stroke color (hex)'},
            'strokeWidth': {'type': 'number', 'description': 'Stroke width'},
            'content': {'type': 'string', 'description': 'Text content (for text elements)'},
            'customProperties': {'type': 'object', 'description': 'Additional custom properties'},
          },
          'required': ['elementId'],
        },
      },
      {
        'name': 'penpot_transform_element',
        'description': 'Apply transformations (rotate, scale, skew, flip) to canvas elements',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'elementId': {'type': 'string', 'description': 'ID of element to transform'},
            'rotation': {'type': 'number', 'description': 'Rotation angle in degrees'},
            'scaleX': {'type': 'number', 'description': 'Horizontal scale factor'},
            'scaleY': {'type': 'number', 'description': 'Vertical scale factor'},
            'skewX': {'type': 'number', 'description': 'Horizontal skew angle'},
            'skewY': {'type': 'number', 'description': 'Vertical skew angle'},
            'flipHorizontal': {'type': 'boolean', 'description': 'Flip horizontally'},
            'flipVertical': {'type': 'boolean', 'description': 'Flip vertically'},
          },
          'required': ['elementId'],
        },
      },
      {
        'name': 'penpot_delete_element',
        'description': 'Remove elements from the canvas',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'elementId': {'type': 'string', 'description': 'ID of element to delete'},
            'permanent': {'type': 'boolean', 'description': 'Permanently delete (true) or move to trash (false)'},
          },
          'required': ['elementId'],
        },
      },
      {
        'name': 'penpot_duplicate_element',
        'description': 'Clone existing elements with optional offset and component link preservation',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'elementId': {'type': 'string', 'description': 'ID of element to duplicate'},
            'offsetX': {'type': 'number', 'description': 'Horizontal offset for duplicate (default: 10)'},
            'offsetY': {'type': 'number', 'description': 'Vertical offset for duplicate (default: 10)'},
            'deepClone': {'type': 'boolean', 'description': 'Clone children recursively (default: true)'},
            'preserveComponentLink': {'type': 'boolean', 'description': 'Keep component instance link (default: false)'},
          },
          'required': ['elementId'],
        },
      },
      {
        'name': 'penpot_group_elements',
        'description': 'Create a group from multiple elements',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'elementIds': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'IDs of elements to group',
            },
            'groupName': {'type': 'string', 'description': 'Optional name for the group'},
          },
          'required': ['elementIds'],
        },
      },
      {
        'name': 'penpot_ungroup_elements',
        'description': 'Dissolve a group and release its elements',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'groupId': {'type': 'string', 'description': 'ID of group to ungroup'},
          },
          'required': ['groupId'],
        },
      },
      {
        'name': 'penpot_reorder_elements',
        'description': 'Change the z-index/layer order of elements (bring to front, send to back, etc.)',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'elementId': {'type': 'string', 'description': 'ID of element to reorder'},
            'operation': {
              'type': 'string',
              'description': "Reorder operation: 'front', 'back', 'forward', 'backward'",
            },
            'zIndex': {'type': 'number', 'description': 'Specific z-index to set (alternative to operation)'},
          },
          'required': ['elementId'],
        },
      },
    ];
  }

  /// Handle MCP tool call
  ///
  /// Routes tool calls to appropriate handler methods
  Future<Map<String, dynamic>> handleToolCall({
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    try {
      switch (toolName) {
        case 'penpot_create_rectangle':
          return await createRectangle(
            x: arguments['x'] as double?,
            y: arguments['y'] as double?,
            width: arguments['width'] as double?,
            height: arguments['height'] as double?,
            fill: arguments['fill'] as String?,
            stroke: arguments['stroke'] as String?,
            strokeWidth: arguments['strokeWidth'] as double?,
            borderRadius: arguments['borderRadius'] as double?,
            name: arguments['name'] as String?,
          );

        case 'penpot_create_text':
          return await createText(
            content: arguments['content'] as String,
            x: arguments['x'] as double?,
            y: arguments['y'] as double?,
            fontSize: arguments['fontSize'] as double?,
            fontFamily: arguments['fontFamily'] as String?,
            fontWeight: arguments['fontWeight'] as int?,
            color: arguments['color'] as String?,
            name: arguments['name'] as String?,
          );

        case 'penpot_create_frame':
          return await createFrame(
            x: arguments['x'] as double?,
            y: arguments['y'] as double?,
            width: arguments['width'] as double?,
            height: arguments['height'] as double?,
            name: arguments['name'] as String?,
          );

        case 'penpot_get_canvas_state':
          return await getCanvasState();

        case 'penpot_clear_canvas':
          return await clearCanvas();

        case 'penpot_build_design':
          return await buildDesignFromSpec(
            designSpec: arguments['designSpec'] as Map<String, dynamic>,
          );

        // ========== WEEK 2: ADVANCED FEATURES ==========

        case 'penpot_create_ellipse':
          return await createEllipse(
            x: arguments['x'] as double?,
            y: arguments['y'] as double?,
            width: arguments['width'] as double?,
            height: arguments['height'] as double?,
            fill: arguments['fill'] as String?,
            stroke: arguments['stroke'] as String?,
            strokeWidth: arguments['strokeWidth'] as double?,
            name: arguments['name'] as String?,
          );

        case 'penpot_create_path':
          return await createPath(
            pathData: arguments['pathData'] as String,
            x: arguments['x'] as double?,
            y: arguments['y'] as double?,
            fill: arguments['fill'] as String?,
            stroke: arguments['stroke'] as String?,
            strokeWidth: arguments['strokeWidth'] as double?,
            name: arguments['name'] as String?,
          );

        case 'penpot_create_image':
          return await createImage(
            dataUrl: arguments['dataUrl'] as String,
            x: arguments['x'] as double?,
            y: arguments['y'] as double?,
            width: arguments['width'] as double?,
            height: arguments['height'] as double?,
            name: arguments['name'] as String?,
          );

        case 'penpot_create_component':
          final elementIds = (arguments['elementIds'] as List).cast<String>();
          return await createComponent(
            elementIds: elementIds,
            name: arguments['name'] as String,
          );

        case 'penpot_create_color_style':
          return await createColorStyle(
            name: arguments['name'] as String,
            color: arguments['color'] as String,
          );

        case 'penpot_create_typography_style':
          return await createTypographyStyle(
            name: arguments['name'] as String,
            fontFamily: arguments['fontFamily'] as String?,
            fontSize: arguments['fontSize'] as double?,
            fontWeight: arguments['fontWeight'] as int?,
            lineHeight: arguments['lineHeight'] as double?,
            letterSpacing: arguments['letterSpacing'] as double?,
          );

        case 'penpot_apply_layout_constraints':
          return await applyLayoutConstraints(
            elementId: arguments['elementId'] as String,
            constraints: arguments['constraints'] as Map<String, String>?,
            layout: arguments['layout'] as Map<String, dynamic>?,
          );

        // ========== WEEK 3: CONTEXT & TOKENS ==========

        case 'penpot_get_design_tokens':
          return await getDesignTokens();

        case 'penpot_get_canvas_state_detailed':
          return await getCanvasStateDetailed();

        case 'penpot_get_canvas_statistics':
          return await getCanvasStatistics();

        case 'penpot_query_elements_by_type':
          return await queryElementsByType(
            elementType: arguments['elementType'] as String,
          );

        case 'penpot_undo':
          return await undo();

        case 'penpot_redo':
          return await redo();

        case 'penpot_get_history':
          return await getHistory(
            limit: arguments['limit'] as int? ?? 10,
          );

        case 'penpot_export_png':
          return await exportPng(
            scale: arguments['scale'] as double?,
            elementId: arguments['elementId'] as String?,
          );

        case 'penpot_export_svg':
          return await exportSvg(
            elementId: arguments['elementId'] as String?,
          );

        case 'penpot_export_pdf':
          return await exportPdf(
            elementId: arguments['elementId'] as String?,
          );

        // ========== WEEK 4: ELEMENT MANIPULATION ==========

        case 'penpot_update_element':
          return await updateElement(
            elementId: arguments['elementId'] as String,
            x: arguments['x'] as double?,
            y: arguments['y'] as double?,
            width: arguments['width'] as double?,
            height: arguments['height'] as double?,
            fill: arguments['fill'] as String?,
            stroke: arguments['stroke'] as String?,
            strokeWidth: arguments['strokeWidth'] as double?,
            content: arguments['content'] as String?,
            customProperties: arguments['customProperties'] as Map<String, dynamic>?,
          );

        case 'penpot_transform_element':
          return await transformElement(
            elementId: arguments['elementId'] as String,
            rotation: arguments['rotation'] as double?,
            scaleX: arguments['scaleX'] as double?,
            scaleY: arguments['scaleY'] as double?,
            skewX: arguments['skewX'] as double?,
            skewY: arguments['skewY'] as double?,
            flipHorizontal: arguments['flipHorizontal'] as bool?,
            flipVertical: arguments['flipVertical'] as bool?,
          );

        case 'penpot_delete_element':
          return await deleteElement(
            elementId: arguments['elementId'] as String,
            permanent: arguments['permanent'] as bool? ?? false,
          );

        case 'penpot_duplicate_element':
          return await duplicateElement(
            elementId: arguments['elementId'] as String,
            offsetX: arguments['offsetX'] as double? ?? 10,
            offsetY: arguments['offsetY'] as double? ?? 10,
            deepClone: arguments['deepClone'] as bool? ?? true,
            preserveComponentLink: arguments['preserveComponentLink'] as bool? ?? false,
          );

        case 'penpot_group_elements':
          final elementIds = (arguments['elementIds'] as List).cast<String>();
          return await groupElements(
            elementIds: elementIds,
            groupName: arguments['groupName'] as String?,
          );

        case 'penpot_ungroup_elements':
          return await ungroupElements(
            groupId: arguments['groupId'] as String,
          );

        case 'penpot_reorder_elements':
          return await reorderElements(
            elementId: arguments['elementId'] as String,
            operation: arguments['operation'] as String?,
            zIndex: arguments['zIndex'] as int?,
          );

        default:
          throw Exception('Unknown tool: $toolName');
      }
    } catch (e) {
      debugPrint('❌ Error handling tool call $toolName: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get list of available MCP tools for AI agents
  List<MCPToolDefinition> getAvailableTools() {
    return [
      // CREATE tools
      MCPToolDefinition(
        name: 'penpot_create_rectangle',
        description: 'Create a rectangle element with specified properties',
      ),
      MCPToolDefinition(
        name: 'penpot_create_text',
        description: 'Create a text element with content and styling',
      ),
      MCPToolDefinition(
        name: 'penpot_create_frame',
        description: 'Create a frame container for organizing elements',
      ),
      MCPToolDefinition(
        name: 'penpot_create_ellipse',
        description: 'Create an ellipse or circle element',
      ),
      MCPToolDefinition(
        name: 'penpot_create_path',
        description: 'Create a custom path/vector element',
      ),
      MCPToolDefinition(
        name: 'penpot_create_image',
        description: 'Create an image element from URL',
      ),

      // STYLE tools
      MCPToolDefinition(
        name: 'penpot_apply_gradient',
        description: 'Apply gradient fill to an element',
      ),
      MCPToolDefinition(
        name: 'penpot_apply_shadow',
        description: 'Apply shadow effect to an element',
      ),
      MCPToolDefinition(
        name: 'penpot_set_typography',
        description: 'Set typography properties for text elements',
      ),

      // COMPONENT tools
      MCPToolDefinition(
        name: 'penpot_create_component',
        description: 'Create a reusable component from elements',
      ),
      MCPToolDefinition(
        name: 'penpot_instantiate_component',
        description: 'Create an instance of a component',
      ),

      // DESIGN TOKENS
      MCPToolDefinition(
        name: 'penpot_fetch_design_tokens',
        description: 'Fetch design tokens (colors, spacing, typography)',
      ),

      // MANIPULATION tools
      MCPToolDefinition(
        name: 'penpot_update_element',
        description: 'Update properties of an existing element',
      ),
      MCPToolDefinition(
        name: 'penpot_transform_element',
        description: 'Transform element (rotate, scale, flip)',
      ),
      MCPToolDefinition(
        name: 'penpot_delete_element',
        description: 'Delete an element from the canvas',
      ),
      MCPToolDefinition(
        name: 'penpot_duplicate_element',
        description: 'Duplicate an existing element',
      ),
      MCPToolDefinition(
        name: 'penpot_group_elements',
        description: 'Group multiple elements together',
      ),
      MCPToolDefinition(
        name: 'penpot_ungroup_elements',
        description: 'Ungroup grouped elements',
      ),
      MCPToolDefinition(
        name: 'penpot_reorder_elements',
        description: 'Change the layer order of elements',
      ),

      // QUERY tools
      MCPToolDefinition(
        name: 'penpot_get_canvas_state',
        description: 'Get current canvas state and all elements',
      ),
      MCPToolDefinition(
        name: 'penpot_query_elements',
        description: 'Search and filter elements by type or properties',
      ),

      // HISTORY tools
      MCPToolDefinition(
        name: 'penpot_undo',
        description: 'Undo the last action',
      ),
      MCPToolDefinition(
        name: 'penpot_redo',
        description: 'Redo the last undone action',
      ),

      // EXPORT tools
      MCPToolDefinition(
        name: 'penpot_export_element',
        description: 'Export element as PNG, SVG, or PDF',
      ),
    ];
  }

  /// Execute a tool by name with arguments
  /// Routes to WebView's injected plugin via JavaScript channels
  Future<Map<String, dynamic>> executeTool(String toolName, Map<String, dynamic> arguments) async {
    debugPrint('🛠️ Executing tool: $toolName with args: $arguments');

    // Execute via local handlers which use _canvas!.executeCommand()
    // This sends commands to the WebView's injected plugin via JavaScript channels
    return await handleToolCall(
      toolName: toolName,
      arguments: arguments,
    );
  }
}

/// MCP Tool Definition
class MCPToolDefinition {
  final String name;
  final String description;

  MCPToolDefinition({
    required this.name,
    required this.description,
  });
}
