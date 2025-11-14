import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Internal MCP Server for Excalidraw Canvas Integration
/// Provides a bridge between AI agents and the Excalidraw canvas
class MCPExcalidrawServer {
  static const String _serverName = 'excalidraw-canvas';
  static const String _version = '1.0.0';
  
  late HttpServer _server;
  int _port = 0;
  bool _isRunning = false;
  
  // Canvas state management
  final Map<String, dynamic> _canvasState = {};
  final List<Map<String, dynamic>> _elements = [];
  
  // Canvas manipulation callback
  Function(Map<String, dynamic>)? onCanvasElementAdded;
  Function(String)? onCanvasCleared;
  Function(Map<String, dynamic>)? onCanvasUpdated;

  /// Initialize and start the MCP server
  Future<void> start() async {
    try {
      _server = await HttpServer.bind('127.0.0.1', 0);
      _port = _server.port;
      _isRunning = true;
      
      print('🎨 MCP Excalidraw Server started on port $_port');
      
      _server.listen((HttpRequest request) {
        _handleRequest(request);
      });
      
    } catch (e) {
      print('❌ Failed to start MCP Excalidraw Server: $e');
      rethrow;
    }
  }

  /// Stop the MCP server
  Future<void> stop() async {
    if (_isRunning) {
      await _server.close();
      _isRunning = false;
      print('🛑 MCP Excalidraw Server stopped');
    }
  }

  /// Get server connection info
  Map<String, dynamic> getServerInfo() {
    return {
      'name': _serverName,
      'version': _version,
      'url': 'http://127.0.0.1:$_port',
      'port': _port,
      'running': _isRunning,
    };
  }

  /// Handle incoming MCP requests
  Future<void> _handleRequest(HttpRequest request) async {
    try {
      // Set CORS headers
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        return;
      }

      if (request.method == 'POST') {
        final body = await utf8.decoder.bind(request).join();
        final jsonBody = jsonDecode(body) as Map<String, dynamic>;
        
        final response = await processMCPRequest(jsonBody);
        
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(response));
        
      } else if (request.method == 'GET' && request.uri.path == '/capabilities') {
        final response = _getCapabilities();
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(response));
        
      } else {
        request.response.statusCode = 404;
        request.response.write('Not Found');
      }
      
      await request.response.close();
      
    } catch (e) {
      print('❌ Error handling MCP request: $e');
      request.response.statusCode = 500;
      request.response.write('Internal Server Error');
      await request.response.close();
    }
  }

  /// Process MCP request and return response
  Future<Map<String, dynamic>> processMCPRequest(Map<String, dynamic> request) async {
    final method = request['method'] as String?;
    final params = request['params'] as Map<String, dynamic>? ?? {};
    final id = request['id'];

    try {
      Map<String, dynamic> result;
      
      switch (method) {
        case 'tools/list':
          result = _listTools();
          break;
          
        case 'tools/call':
          result = await _callTool(params);
          break;
          
        case 'resources/list':
          result = _listResources();
          break;
          
        case 'resources/read':
          result = await _readResource(params);
          break;
          
        default:
          throw Exception('Unknown method: $method');
      }

      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': result,
      };
      
    } catch (e) {
      return {
        'jsonrpc': '2.0',
        'id': id,
        'error': {
          'code': -32603,
          'message': e.toString(),
        },
      };
    }
  }

  /// Get server capabilities
  Map<String, dynamic> _getCapabilities() {
    return {
      'name': _serverName,
      'version': _version,
      'capabilities': {
        'tools': true,
        'resources': true,
      },
      'tools': _getToolDefinitions(),
      'resources': _getResourceDefinitions(),
    };
  }

  /// List available tools
  Map<String, dynamic> _listTools() {
    return {
      'tools': _getToolDefinitions(),
    };
  }

  /// Get tool definitions
  List<Map<String, dynamic>> _getToolDefinitions() {
    return [
      {
        'name': 'create_element',
        'description': 'Create a new element on the canvas',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'type': {
              'type': 'string',
              'enum': ['rectangle', 'ellipse', 'arrow', 'line', 'freedraw', 'text'],
              'description': 'Type of element to create'
            },
            'x': {'type': 'number', 'description': 'X coordinate'},
            'y': {'type': 'number', 'description': 'Y coordinate'},
            'width': {'type': 'number', 'description': 'Width of the element'},
            'height': {'type': 'number', 'description': 'Height of the element'},
            'text': {'type': 'string', 'description': 'Text content for text elements'},
            'strokeColor': {'type': 'string', 'description': 'Stroke color (hex)'},
            'backgroundColor': {'type': 'string', 'description': 'Background color (hex)'},
            'strokeWidth': {'type': 'number', 'description': 'Stroke width'},
          },
          'required': ['type', 'x', 'y']
        }
      },
      {
        'name': 'update_element',
        'description': 'Update an existing element on the canvas',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'id': {'type': 'string', 'description': 'Element ID to update'},
            'x': {'type': 'number', 'description': 'New X coordinate'},
            'y': {'type': 'number', 'description': 'New Y coordinate'},
            'width': {'type': 'number', 'description': 'New width'},
            'height': {'type': 'number', 'description': 'New height'},
            'text': {'type': 'string', 'description': 'New text content'},
            'strokeColor': {'type': 'string', 'description': 'New stroke color'},
            'backgroundColor': {'type': 'string', 'description': 'New background color'},
          },
          'required': ['id']
        }
      },
      {
        'name': 'delete_element',
        'description': 'Delete an element from the canvas',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'id': {'type': 'string', 'description': 'Element ID to delete'}
          },
          'required': ['id']
        }
      },
      {
        'name': 'clear_canvas',
        'description': 'Clear all elements from the canvas',
        'inputSchema': {
          'type': 'object',
          'properties': {}
        }
      },
      {
        'name': 'get_canvas_info',
        'description': 'Get information about the current canvas state',
        'inputSchema': {
          'type': 'object',
          'properties': {}
        }
      },
      {
        'name': 'create_template',
        'description': 'Create a template layout (dashboard, form, etc.)',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'template': {
              'type': 'string',
              'enum': ['dashboard', 'form', 'wireframe', 'flowchart'],
              'description': 'Template type to create'
            },
            'x': {'type': 'number', 'description': 'Starting X coordinate', 'default': 50},
            'y': {'type': 'number', 'description': 'Starting Y coordinate', 'default': 50},
          },
          'required': ['template']
        }
      }
    ];
  }

  /// Call a tool
  Future<Map<String, dynamic>> _callTool(Map<String, dynamic> params) async {
    final name = params['name'] as String;
    final arguments = params['arguments'] as Map<String, dynamic>? ?? {};

    switch (name) {
      case 'create_element':
        return await _createElement(arguments);
        
      case 'update_element':
        return await _updateElement(arguments);
        
      case 'delete_element':
        return await _deleteElement(arguments);
        
      case 'clear_canvas':
        return await _clearCanvas();
        
      case 'get_canvas_info':
        return _getCanvasInfo();
        
      case 'create_template':
        return await _createTemplate(arguments);
        
      default:
        throw Exception('Unknown tool: $name');
    }
  }

  /// Create a new element on the canvas
  Future<Map<String, dynamic>> _createElement(Map<String, dynamic> args) async {
    final type = args['type'] as String;
    final x = (args['x'] as num).toDouble();
    final y = (args['y'] as num).toDouble();
    final width = (args['width'] as num?)?.toDouble() ?? 100.0;
    final height = (args['height'] as num?)?.toDouble() ?? 100.0;
    final text = args['text'] as String? ?? '';
    final strokeColor = args['strokeColor'] as String? ?? '#000000';
    final backgroundColor = args['backgroundColor'] as String? ?? 'transparent';
    final strokeWidth = (args['strokeWidth'] as num?)?.toDouble() ?? 1.0;

    final element = {
      'id': 'element_${DateTime.now().millisecondsSinceEpoch}',
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'text': text,
      'strokeColor': strokeColor,
      'backgroundColor': backgroundColor,
      'strokeWidth': strokeWidth,
      'created': DateTime.now().toIso8601String(),
    };

    _elements.add(element);
    
    // Notify the canvas to add the element
    if (onCanvasElementAdded != null) {
      onCanvasElementAdded!(element);
    }

    return {
      'content': [
        {
          'type': 'text',
          'text': 'Successfully created $type element at ($x, $y)'
        }
      ],
      'element': element,
    };
  }

  /// Update an existing element
  Future<Map<String, dynamic>> _updateElement(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final elementIndex = _elements.indexWhere((e) => e['id'] == id);
    
    if (elementIndex == -1) {
      throw Exception('Element not found: $id');
    }

    final element = _elements[elementIndex];
    
    // Update provided properties
    args.forEach((key, value) {
      if (key != 'id') {
        element[key] = value;
      }
    });
    
    element['updated'] = DateTime.now().toIso8601String();

    // Notify the canvas to update the element
    if (onCanvasUpdated != null) {
      onCanvasUpdated!(element);
    }

    return {
      'content': [
        {
          'type': 'text',
          'text': 'Successfully updated element $id'
        }
      ],
      'element': element,
    };
  }

  /// Delete an element
  Future<Map<String, dynamic>> _deleteElement(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final initialLength = _elements.length;
    _elements.removeWhere((e) => e['id'] == id);
    final removed = initialLength - _elements.length;
    
    if (removed == 0) {
      throw Exception('Element not found: $id');
    }

    return {
      'content': [
        {
          'type': 'text',
          'text': 'Successfully deleted element $id'
        }
      ]
    };
  }

  /// Clear the canvas
  Future<Map<String, dynamic>> _clearCanvas() async {
    _elements.clear();
    
    // Notify the canvas to clear
    if (onCanvasCleared != null) {
      onCanvasCleared!('all');
    }

    return {
      'content': [
        {
          'type': 'text',
          'text': 'Successfully cleared the canvas'
        }
      ]
    };
  }

  /// Get canvas information
  Map<String, dynamic> _getCanvasInfo() {
    return {
      'content': [
        {
          'type': 'text',
          'text': 'Canvas contains ${_elements.length} elements'
        }
      ],
      'elements': _elements,
      'elementCount': _elements.length,
      'canvasState': _canvasState,
    };
  }

  /// Create a template layout
  Future<Map<String, dynamic>> _createTemplate(Map<String, dynamic> args) async {
    final template = args['template'] as String;
    final startX = (args['x'] as num?)?.toDouble() ?? 50.0;
    final startY = (args['y'] as num?)?.toDouble() ?? 50.0;

    List<Map<String, dynamic>> templateElements = [];

    switch (template) {
      case 'dashboard':
        templateElements = _createDashboardTemplate(startX, startY);
        break;
      case 'form':
        templateElements = _createFormTemplate(startX, startY);
        break;
      case 'wireframe':
        templateElements = _createWireframeTemplate(startX, startY);
        break;
      case 'flowchart':
        templateElements = _createFlowchartTemplate(startX, startY);
        break;
      default:
        throw Exception('Unknown template: $template');
    }

    // Add all template elements
    for (final element in templateElements) {
      _elements.add(element);
      if (onCanvasElementAdded != null) {
        onCanvasElementAdded!(element);
      }
    }

    return {
      'content': [
        {
          'type': 'text',
          'text': 'Successfully created $template template with ${templateElements.length} elements'
        }
      ],
      'elements': templateElements,
    };
  }

  /// Create dashboard template elements
  List<Map<String, dynamic>> _createDashboardTemplate(double startX, double startY) {
    return [
      // Header
      {
        'id': 'dashboard_header_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'rectangle',
        'x': startX,
        'y': startY,
        'width': 400,
        'height': 60,
        'strokeColor': '#e1e5e9',
        'backgroundColor': '#f8f9fa',
        'strokeWidth': 1,
      },
      {
        'id': 'dashboard_title_${DateTime.now().millisecondsSinceEpoch + 1}',
        'type': 'text',
        'x': startX + 20,
        'y': startY + 35,
        'text': 'Dashboard',
        'strokeColor': '#495057',
        'fontSize': 18,
      },
      // Stats cards
      ...List.generate(3, (i) => {
        'id': 'dashboard_card_${DateTime.now().millisecondsSinceEpoch + 2 + i}',
        'type': 'rectangle',
        'x': startX + (i * 130),
        'y': startY + 80,
        'width': 120,
        'height': 80,
        'strokeColor': '#dee2e6',
        'backgroundColor': '#ffffff',
        'strokeWidth': 1,
      }),
      // Main content area
      {
        'id': 'dashboard_content_${DateTime.now().millisecondsSinceEpoch + 5}',
        'type': 'rectangle',
        'x': startX,
        'y': startY + 180,
        'width': 400,
        'height': 200,
        'strokeColor': '#dee2e6',
        'backgroundColor': '#ffffff',
        'strokeWidth': 1,
      }
    ];
  }

  /// Create form template elements
  List<Map<String, dynamic>> _createFormTemplate(double startX, double startY) {
    return [
      // Form container
      {
        'id': 'form_container_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'rectangle',
        'x': startX,
        'y': startY,
        'width': 320,
        'height': 400,
        'strokeColor': '#dee2e6',
        'backgroundColor': '#ffffff',
        'strokeWidth': 1,
      },
      // Form title
      {
        'id': 'form_title_${DateTime.now().millisecondsSinceEpoch + 1}',
        'type': 'text',
        'x': startX + 20,
        'y': startY + 30,
        'text': 'Contact Form',
        'strokeColor': '#495057',
        'fontSize': 16,
      },
      // Form fields
      ...List.generate(4, (i) => {
        'id': 'form_field_${DateTime.now().millisecondsSinceEpoch + 2 + i}',
        'type': 'rectangle',
        'x': startX + 20,
        'y': startY + 60 + (i * 70),
        'width': 280,
        'height': 40,
        'strokeColor': '#ced4da',
        'backgroundColor': '#ffffff',
        'strokeWidth': 1,
      }),
      // Submit button
      {
        'id': 'form_submit_${DateTime.now().millisecondsSinceEpoch + 6}',
        'type': 'rectangle',
        'x': startX + 20,
        'y': startY + 340,
        'width': 280,
        'height': 40,
        'strokeColor': '#0d6efd',
        'backgroundColor': '#0d6efd',
        'strokeWidth': 1,
      }
    ];
  }

  /// Create wireframe template elements
  List<Map<String, dynamic>> _createWireframeTemplate(double startX, double startY) {
    return [
      // Header
      {
        'id': 'wireframe_header_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'rectangle',
        'x': startX,
        'y': startY,
        'width': 600,
        'height': 80,
        'strokeColor': '#6c757d',
        'backgroundColor': 'transparent',
        'strokeWidth': 2,
      },
      // Navigation
      {
        'id': 'wireframe_nav_${DateTime.now().millisecondsSinceEpoch + 1}',
        'type': 'rectangle',
        'x': startX,
        'y': startY + 80,
        'width': 600,
        'height': 50,
        'strokeColor': '#6c757d',
        'backgroundColor': 'transparent',
        'strokeWidth': 1,
      },
      // Sidebar
      {
        'id': 'wireframe_sidebar_${DateTime.now().millisecondsSinceEpoch + 2}',
        'type': 'rectangle',
        'x': startX,
        'y': startY + 130,
        'width': 200,
        'height': 300,
        'strokeColor': '#6c757d',
        'backgroundColor': 'transparent',
        'strokeWidth': 1,
      },
      // Main content
      {
        'id': 'wireframe_content_${DateTime.now().millisecondsSinceEpoch + 3}',
        'type': 'rectangle',
        'x': startX + 200,
        'y': startY + 130,
        'width': 400,
        'height': 300,
        'strokeColor': '#6c757d',
        'backgroundColor': 'transparent',
        'strokeWidth': 1,
      }
    ];
  }

  /// Create flowchart template elements
  List<Map<String, dynamic>> _createFlowchartTemplate(double startX, double startY) {
    return [
      // Start node
      {
        'id': 'flow_start_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'ellipse',
        'x': startX + 100,
        'y': startY,
        'width': 100,
        'height': 60,
        'strokeColor': '#198754',
        'backgroundColor': '#d1e7dd',
        'strokeWidth': 2,
      },
      // Process node
      {
        'id': 'flow_process_${DateTime.now().millisecondsSinceEpoch + 1}',
        'type': 'rectangle',
        'x': startX + 100,
        'y': startY + 100,
        'width': 100,
        'height': 60,
        'strokeColor': '#0d6efd',
        'backgroundColor': '#cff4fc',
        'strokeWidth': 2,
      },
      // Decision node
      {
        'id': 'flow_decision_${DateTime.now().millisecondsSinceEpoch + 2}',
        'type': 'rectangle', // Diamond would be ideal but rectangle works
        'x': startX + 100,
        'y': startY + 200,
        'width': 100,
        'height': 60,
        'strokeColor': '#fd7e14',
        'backgroundColor': '#ffe8cc',
        'strokeWidth': 2,
      },
      // End node
      {
        'id': 'flow_end_${DateTime.now().millisecondsSinceEpoch + 3}',
        'type': 'ellipse',
        'x': startX + 100,
        'y': startY + 300,
        'width': 100,
        'height': 60,
        'strokeColor': '#dc3545',
        'backgroundColor': '#f8d7da',
        'strokeWidth': 2,
      },
      // Arrows
      {
        'id': 'flow_arrow1_${DateTime.now().millisecondsSinceEpoch + 4}',
        'type': 'arrow',
        'x': startX + 150,
        'y': startY + 60,
        'width': 0,
        'height': 40,
        'strokeColor': '#495057',
        'strokeWidth': 2,
      },
      {
        'id': 'flow_arrow2_${DateTime.now().millisecondsSinceEpoch + 5}',
        'type': 'arrow',
        'x': startX + 150,
        'y': startY + 160,
        'width': 0,
        'height': 40,
        'strokeColor': '#495057',
        'strokeWidth': 2,
      },
      {
        'id': 'flow_arrow3_${DateTime.now().millisecondsSinceEpoch + 6}',
        'type': 'arrow',
        'x': startX + 150,
        'y': startY + 260,
        'width': 0,
        'height': 40,
        'strokeColor': '#495057',
        'strokeWidth': 2,
      }
    ];
  }

  /// List available resources
  Map<String, dynamic> _listResources() {
    return {
      'resources': _getResourceDefinitions(),
    };
  }

  /// Get resource definitions
  List<Map<String, dynamic>> _getResourceDefinitions() {
    return [
      {
        'uri': 'canvas://elements',
        'name': 'Canvas Elements',
        'description': 'Current elements on the canvas',
        'mimeType': 'application/json'
      },
      {
        'uri': 'canvas://state',
        'name': 'Canvas State',
        'description': 'Current state of the canvas',
        'mimeType': 'application/json'
      }
    ];
  }

  /// Read a resource
  Future<Map<String, dynamic>> _readResource(Map<String, dynamic> params) async {
    final uri = params['uri'] as String;
    
    switch (uri) {
      case 'canvas://elements':
        return {
          'contents': [
            {
              'uri': uri,
              'mimeType': 'application/json',
              'text': jsonEncode(_elements)
            }
          ]
        };
        
      case 'canvas://state':
        return {
          'contents': [
            {
              'uri': uri,
              'mimeType': 'application/json',
              'text': jsonEncode({
                'elements': _elements,
                'elementCount': _elements.length,
                'canvasState': _canvasState,
                'lastUpdated': DateTime.now().toIso8601String(),
              })
            }
          ]
        };
        
      default:
        throw Exception('Resource not found: $uri');
    }
  }

  /// Get current elements
  List<Map<String, dynamic>> get elements => List.unmodifiable(_elements);
  
  /// Get server port
  int get port => _port;
  
  /// Check if server is running
  bool get isRunning => _isRunning;
}