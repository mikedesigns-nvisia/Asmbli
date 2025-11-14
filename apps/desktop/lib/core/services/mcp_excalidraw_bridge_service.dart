import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'mcp_excalidraw_server.dart';
import '../di/service_locator.dart';
import 'mcp_bridge_service.dart';

/// Bridge service that connects AI agents to the Excalidraw canvas via MCP
/// Manages the internal MCP server and provides a seamless interface for canvas manipulation
class MCPExcalidrawBridgeService {
  static MCPExcalidrawBridgeService? _instance;
  static MCPExcalidrawBridgeService get instance => _instance ??= MCPExcalidrawBridgeService._();
  MCPExcalidrawBridgeService._();

  late MCPExcalidrawServer _mcpServer;
  late MCPBridgeService _mcpBridge;
  bool _isInitialized = false;
  
  // Canvas manipulation callbacks
  final StreamController<Map<String, dynamic>> _elementAddedController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _elementUpdatedController = StreamController.broadcast();
  final StreamController<String> _canvasClearedController = StreamController.broadcast();
  
  // Streams for listening to canvas changes
  Stream<Map<String, dynamic>> get onElementAdded => _elementAddedController.stream;
  Stream<Map<String, dynamic>> get onElementUpdated => _elementUpdatedController.stream;
  Stream<String> get onCanvasCleared => _canvasClearedController.stream;

  /// Initialize the MCP Excalidraw bridge
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🌉 Initializing MCP Excalidraw Bridge...');
      
      // Initialize the internal MCP server
      _mcpServer = MCPExcalidrawServer();
      
      // Set up canvas manipulation callbacks
      _mcpServer.onCanvasElementAdded = (element) {
        _elementAddedController.add(element);
        print('🎨 Element added to canvas: ${element['type']} at (${element['x']}, ${element['y']})');
      };
      
      _mcpServer.onCanvasUpdated = (element) {
        _elementUpdatedController.add(element);
        print('🔄 Element updated on canvas: ${element['id']}');
      };
      
      _mcpServer.onCanvasCleared = (reason) {
        _canvasClearedController.add(reason);
        print('🗑️ Canvas cleared: $reason');
      };
      
      // Start the MCP server
      await _mcpServer.start();
      
      // Get the MCP bridge service
      _mcpBridge = ServiceLocator.instance.get<MCPBridgeService>();
      
      // Register the Excalidraw MCP server with the bridge
      final serverInfo = _mcpServer.getServerInfo();
      await _registerWithBridge(serverInfo);
      
      _isInitialized = true;
      print('✅ MCP Excalidraw Bridge initialized successfully');
      
    } catch (e) {
      print('❌ Failed to initialize MCP Excalidraw Bridge: $e');
      rethrow;
    }
  }

  /// Register the Excalidraw MCP server with the main MCP bridge
  Future<void> _registerWithBridge(Map<String, dynamic> serverInfo) async {
    try {
      // Create a mock server configuration for the MCP bridge
      final serverConfig = {
        'id': 'excalidraw-canvas',
        'name': 'Excalidraw Canvas',
        'description': 'Internal MCP server for Excalidraw canvas manipulation',
        'url': serverInfo['url'],
        'port': serverInfo['port'],
        'type': 'internal',
        'capabilities': ['tools', 'resources'],
        'tools': [
          'create_element',
          'update_element', 
          'delete_element',
          'clear_canvas',
          'get_canvas_info',
          'create_template'
        ],
        'resources': [
          'canvas://elements',
          'canvas://state'
        ],
      };
      
      print('📡 Registering Excalidraw MCP server with bridge: ${serverConfig['name']}');
      
    } catch (e) {
      print('❌ Failed to register with MCP bridge: $e');
    }
  }

  /// Execute a canvas command via MCP
  Future<Map<String, dynamic>> executeCanvasCommand(String command, Map<String, dynamic> args) async {
    if (!_isInitialized) {
      throw Exception('MCP Excalidraw Bridge not initialized');
    }
    
    try {
      print('🎯 EXECUTING CANVAS COMMAND: $command with args: $args');
      
      final request = {
        'jsonrpc': '2.0',
        'method': 'tools/call',
        'params': {
          'name': command,
          'arguments': args,
        },
        'id': DateTime.now().millisecondsSinceEpoch,
      };
      
      final response = await _mcpServer.processMCPRequest(request);
      
      if (response.containsKey('error')) {
        throw Exception('MCP Error: ${response['error']['message']}');
      }
      
      final result = response['result'] as Map<String, dynamic>;
      print('✅ MCP COMMAND SUCCESS: $result');
      
      // Manually trigger the appropriate event stream since executeCanvasCommand 
      // bypasses the automatic callback system in processMCPRequest
      if (command == 'create_element' && result.containsKey('element')) {
        final element = result['element'] as Map<String, dynamic>;
        print('📤 TRIGGERING onElementAdded event: $element');
        _elementAddedController.add(element);
      } else if (command == 'create_template' && result.containsKey('elements')) {
        final elements = result['elements'] as List<dynamic>;
        print('📤 TRIGGERING onElementAdded events for ${elements.length} template elements');
        for (final element in elements) {
          _elementAddedController.add(element as Map<String, dynamic>);
        }
      } else if (command == 'clear_canvas') {
        print('📤 TRIGGERING onCanvasCleared event');
        _canvasClearedController.add('user_request');
      }
      
      return result;
      
    } catch (e) {
      print('❌ Failed to execute canvas command: $e');
      rethrow;
    }
  }

  /// Create an element on the canvas
  Future<Map<String, dynamic>> createElement({
    required String type,
    required double x,
    required double y,
    double? width,
    double? height,
    String? text,
    String? strokeColor,
    String? backgroundColor,
    double? strokeWidth,
  }) async {
    final args = <String, dynamic>{
      'type': type,
      'x': x,
      'y': y,
    };
    
    if (width != null) args['width'] = width;
    if (height != null) args['height'] = height;
    if (text != null) args['text'] = text;
    if (strokeColor != null) args['strokeColor'] = strokeColor;
    if (backgroundColor != null) args['backgroundColor'] = backgroundColor;
    if (strokeWidth != null) args['strokeWidth'] = strokeWidth;
    
    return executeCanvasCommand('create_element', args);
  }

  /// Update an element on the canvas
  Future<Map<String, dynamic>> updateElement(String id, Map<String, dynamic> changes) async {
    final args = Map<String, dynamic>.from(changes);
    args['id'] = id;
    
    return executeCanvasCommand('update_element', args);
  }

  /// Delete an element from the canvas
  Future<Map<String, dynamic>> deleteElement(String id) async {
    return executeCanvasCommand('delete_element', {'id': id});
  }

  /// Clear the canvas
  Future<Map<String, dynamic>> clearCanvas() async {
    return executeCanvasCommand('clear_canvas', {});
  }

  /// Get canvas information
  Future<Map<String, dynamic>> getCanvasInfo() async {
    return executeCanvasCommand('get_canvas_info', {});
  }

  /// Create a template on the canvas
  Future<Map<String, dynamic>> createTemplate({
    required String template,
    double? x,
    double? y,
  }) async {
    final args = <String, dynamic>{
      'template': template,
    };
    
    if (x != null) args['x'] = x;
    if (y != null) args['y'] = y;
    
    return executeCanvasCommand('create_template', args);
  }

  /// Process AI agent request and convert to canvas actions
  Future<Map<String, dynamic>> processAgentRequest(String prompt) async {
    try {
      // Parse the prompt to understand what the agent wants to do
      final action = _parsePromptToAction(prompt);
      
      switch (action['type']) {
        case 'create_element':
          return await createElement(
            type: action['elementType'] ?? 'rectangle',
            x: action['x']?.toDouble() ?? 100.0,
            y: action['y']?.toDouble() ?? 100.0,
            width: action['width']?.toDouble(),
            height: action['height']?.toDouble(),
            text: action['text'],
            strokeColor: action['strokeColor'],
            backgroundColor: action['backgroundColor'],
          );
          
        case 'create_template':
          return await createTemplate(
            template: action['template'] ?? 'dashboard',
            x: action['x']?.toDouble(),
            y: action['y']?.toDouble(),
          );
          
        case 'clear_canvas':
          return await clearCanvas();
          
        default:
          // Default to creating a rectangle
          return await createElement(
            type: 'rectangle',
            x: 100,
            y: 100,
            width: 150,
            height: 100,
            text: prompt.length > 50 ? prompt.substring(0, 47) + '...' : prompt,
          );
      }
      
    } catch (e) {
      print('❌ Failed to process agent request: $e');
      rethrow;
    }
  }

  /// Parse natural language prompt to determine canvas action
  Map<String, dynamic> _parsePromptToAction(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    
    // Template detection
    if (lowerPrompt.contains('dashboard') || lowerPrompt.contains('stats') || lowerPrompt.contains('metrics')) {
      return {'type': 'create_template', 'template': 'dashboard'};
    }
    
    if (lowerPrompt.contains('form') || lowerPrompt.contains('input') || lowerPrompt.contains('field')) {
      return {'type': 'create_template', 'template': 'form'};
    }
    
    if (lowerPrompt.contains('wireframe') || lowerPrompt.contains('layout') || lowerPrompt.contains('mockup')) {
      return {'type': 'create_template', 'template': 'wireframe'};
    }
    
    if (lowerPrompt.contains('flowchart') || lowerPrompt.contains('flow') || lowerPrompt.contains('process')) {
      return {'type': 'create_template', 'template': 'flowchart'};
    }
    
    // Clear canvas
    if (lowerPrompt.contains('clear') || lowerPrompt.contains('clean') || lowerPrompt.contains('empty')) {
      return {'type': 'clear_canvas'};
    }
    
    // Element type detection
    String elementType = 'rectangle'; // default
    if (lowerPrompt.contains('circle') || lowerPrompt.contains('oval') || lowerPrompt.contains('ellipse')) {
      elementType = 'ellipse';
    } else if (lowerPrompt.contains('arrow') || lowerPrompt.contains('line')) {
      elementType = 'arrow';
    } else if (lowerPrompt.contains('text') || lowerPrompt.contains('label') || lowerPrompt.contains('title')) {
      elementType = 'text';
    }
    
    // Position detection (basic)
    double x = 100.0;
    double y = 100.0;
    
    // Look for position hints
    if (lowerPrompt.contains('top')) y = 50.0;
    if (lowerPrompt.contains('bottom')) y = 300.0;
    if (lowerPrompt.contains('left')) x = 50.0;
    if (lowerPrompt.contains('right')) x = 300.0;
    if (lowerPrompt.contains('center')) {
      x = 200.0;
      y = 200.0;
    }
    
    // Size detection (basic)
    double width = 150.0;
    double height = 100.0;
    
    if (lowerPrompt.contains('small')) {
      width = 80.0;
      height = 60.0;
    } else if (lowerPrompt.contains('large') || lowerPrompt.contains('big')) {
      width = 250.0;
      height = 180.0;
    }
    
    // Color detection
    String? strokeColor;
    String? backgroundColor;
    
    if (lowerPrompt.contains('red')) {
      strokeColor = '#dc3545';
      backgroundColor = '#f8d7da';
    } else if (lowerPrompt.contains('blue')) {
      strokeColor = '#0d6efd';
      backgroundColor = '#cff4fc';
    } else if (lowerPrompt.contains('green')) {
      strokeColor = '#198754';
      backgroundColor = '#d1e7dd';
    } else if (lowerPrompt.contains('yellow') || lowerPrompt.contains('orange')) {
      strokeColor = '#fd7e14';
      backgroundColor = '#ffe8cc';
    }
    
    return {
      'type': 'create_element',
      'elementType': elementType,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'text': elementType == 'text' ? _extractTextFromPrompt(prompt) : null,
      'strokeColor': strokeColor,
      'backgroundColor': backgroundColor,
    };
  }

  /// Extract text content from prompt
  String _extractTextFromPrompt(String prompt) {
    // Look for quoted text first
    final quotedMatch = RegExp(r'"([^"]*)"').firstMatch(prompt);
    if (quotedMatch != null) {
      return quotedMatch.group(1) ?? 'Text';
    }
    
    // Look for common text indicators
    final textMarkers = ['text', 'title', 'label', 'heading', 'button'];
    for (final marker in textMarkers) {
      final pattern = RegExp('$marker[:\\s]+([^,.!?]+)', caseSensitive: false);
      final match = pattern.firstMatch(prompt);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Text';
      }
    }
    
    // Default to a portion of the prompt
    final words = prompt.split(' ');
    if (words.length > 3) {
      return words.take(3).join(' ');
    }
    
    return words.isNotEmpty ? words.first : 'Text';
  }

  /// Get server information
  Map<String, dynamic> getServerInfo() {
    return _mcpServer.getServerInfo();
  }

  /// Get current canvas elements
  List<Map<String, dynamic>> getElements() {
    return _mcpServer.elements;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _mcpServer.stop();
    await _elementAddedController.close();
    await _elementUpdatedController.close();
    await _canvasClearedController.close();
    _isInitialized = false;
    print('🛑 MCP Excalidraw Bridge disposed');
  }

  /// Check if bridge is initialized
  bool get isInitialized => _isInitialized;
}