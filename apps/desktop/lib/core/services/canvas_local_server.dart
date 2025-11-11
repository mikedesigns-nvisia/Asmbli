import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../di/service_locator.dart';
import './mcp_bridge_service.dart';
import './context_mcp_resource_service.dart';
import './model_config_service.dart';
import './canvas_storage_service.dart';
import './canvas_security_service.dart';
import './canvas_error_handler.dart';
import './canvas_performance_service.dart';

/// Local HTTP server for Canvas WebView integration
/// Serves canvas assets and provides API endpoints for Flutter-Canvas communication
class CanvasLocalServer {
  HttpServer? _server;
  int? _port;
  bool _isRunning = false;
  final CanvasErrorHandler _errorHandler = CanvasErrorHandler();
  final ResourceManager _resourceManager = ResourceManager();
  final CanvasPerformanceService _performanceService = CanvasPerformanceService();
  
  final Map<String, String> _mimeTypes = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
  };

  String get canvasUrl => _isRunning ? 'http://127.0.0.1:$_port' : '';
  bool get isRunning => _isRunning;
  int? get port => _port;

  /// Start the local server
  Future<void> start() async {
    if (_isRunning) return;
    
    try {
      _performanceService.startOperation('server_startup');
      
      // Preload resources for better performance
      await _performanceService.preloadResources();
      
      // Bind to localhost only for security
      _server = await HttpServer.bind('127.0.0.1', 0);
      _port = _server!.port;
      _isRunning = true;
      
      print('🎨 Canvas Local Server started on http://127.0.0.1:$_port');
      
      // Handle incoming requests
      _server!.listen(_handleRequest);
      
      _performanceService.endOperation('server_startup');
      
    } catch (e) {
      print('❌ Failed to start Canvas Local Server: $e');
      _isRunning = false;
      rethrow;
    }
  }
  
  /// Stop the local server
  Future<void> stop() async {
    if (!_isRunning) return;
    
    try {
      print('🛑 Stopping Canvas Local Server...');
      
      // Cancel all pending operations
      await _resourceManager.cancelAllOperations();
      
      // Clean up error handler resources
      await _errorHandler.cleanup();
      
      // Clean up performance service
      _performanceService.dispose();
      
      // Close server
      await CanvasErrorHandler.safeCleanup('HTTP Server', () async {
        await _server?.close();
      });
      
      _server = null;
      _port = null;
      _isRunning = false;
      
      print('✅ Canvas Local Server stopped');
      
    } catch (e) {
      final error = CanvasErrorHandler.handleError(e, 'Canvas Local Server stop');
      print('❌ Error stopping Canvas Local Server: ${error.message}');
    }
  }

  /// Handle incoming HTTP requests
  Future<void> _handleRequest(HttpRequest request) async {
    final requestId = 'request_${DateTime.now().millisecondsSinceEpoch}';
    _resourceManager.startOperation(requestId);
    
    try {
      // Add security headers
      _addSecurityHeaders(request.response);
      
      final uri = request.uri;
      print('📡 Canvas Server: ${request.method} ${uri.path}');
      
      // Handle different routes with timeout
      await CanvasErrorHandler.retryOperation(() async {
        if (uri.path.startsWith('/api/')) {
          await _handleApiRequest(request);
        } else if (uri.path == '/' || uri.path.isEmpty) {
          await _serveCanvasIndex(request);
        } else {
          await _serveStaticAsset(request);
        }
      }, 'HTTP request: ${request.method} ${uri.path}', maxRetries: 1);
      
      _resourceManager.completeOperation(requestId);
      
    } catch (e, stackTrace) {
      final error = CanvasErrorHandler.handleError(e, 'Canvas Server request handling', stackTrace: stackTrace);
      _resourceManager.failOperation(requestId, error);
      
      final statusCode = _getStatusCodeFromError(error);
      await _sendErrorResponse(request.response, statusCode, error.message);
    }
  }
  
  /// Add security headers to response
  void _addSecurityHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', 'http://127.0.0.1:$_port');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    response.headers.add('X-Frame-Options', 'SAMEORIGIN');
    response.headers.add('X-Content-Type-Options', 'nosniff');
    response.headers.add('X-XSS-Protection', '1; mode=block');
  }

  /// Handle API requests
  Future<void> _handleApiRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;
    
    // Handle CORS preflight
    if (method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      return;
    }
    
    try {
      switch (path) {
        case '/api/mcp/call':
          await _handleMCPCall(request);
          break;
        case '/api/design-systems':
          await _handleDesignSystems(request);
          break;
        case '/api/design-systems/load':
          await _handleLoadDesignSystem(request);
          break;
        case '/api/canvas/state':
          await _handleCanvasState(request);
          break;
        case '/api/models':
          await _handleModels(request);
          break;
        case '/api/context/documents':
          await _handleContextDocuments(request);
          break;
        case '/api/health':
          await _handleHealthCheck(request);
          break;
        default:
          await _sendErrorResponse(request.response, 404, 'API endpoint not found');
      }
    } catch (e) {
      print('❌ API Error: $e');
      await _sendErrorResponse(request.response, 500, e.toString());
    }
  }
  
  /// Handle MCP tool calls from canvas
  Future<void> _handleMCPCall(HttpRequest request) async {
    if (request.method != 'POST') {
      await _sendErrorResponse(request.response, 405, 'Method not allowed');
      return;
    }
    
    try {
      _performanceService.startOperation('mcp_call');
      
      // Check request size
      final contentLength = request.contentLength;
      if (contentLength > 10 * 1024 * 1024) { // 10MB limit
        throw ArgumentError('Request too large');
      }
      
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final tool = data['tool'] as String;
      final arguments = data['arguments'] as Map<String, dynamic>;
      
      // Check cache first
      final cacheKey = 'mcp_${tool}_${arguments.hashCode}';
      final cachedResult = _performanceService.getCached<Map<String, dynamic>>(cacheKey);
      if (cachedResult != null) {
        await _sendJsonResponse(request.response, cachedResult);
        _performanceService.endOperation('mcp_call');
        return;
      }
      
      // Security validation
      if (tool.isEmpty) {
        throw ArgumentError('Tool name cannot be empty');
      }
      
      // Validate MCP arguments
      final validation = CanvasSecurityService.validateMCPArguments(tool, arguments);
      if (!validation.isValid) {
        throw ArgumentError('Invalid arguments: ${validation.error}');
      }
      
      // Sanitize arguments
      final sanitizedArgs = CanvasSecurityService.sanitizeObject(arguments);
      
      // Get MCP bridge service
      final mcpBridge = ServiceLocator.instance.get<MCPBridgeService>();
      
      // Call the actual canvas MCP server with sanitized args and retry logic
      final result = await CanvasErrorHandler.retryOperation(
        () => mcpBridge.callCanvasTool(tool, sanitizedArgs),
        'MCP tool call: $tool',
      );
      
      final response = {
        'success': true,
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Cache successful result (for read-only operations)
      if (['get_canvas_state', 'export_code'].contains(tool)) {
        _performanceService.cache(cacheKey, response, customExpiry: const Duration(seconds: 30));
      }
      
      await _sendJsonResponse(request.response, response);
      _performanceService.endOperation('mcp_call');
      
    } catch (e, stackTrace) {
      _performanceService.endOperation('mcp_call');
      final error = CanvasErrorHandler.handleError(e, 'MCP call: unknown', stackTrace: stackTrace);
      await _sendJsonResponse(request.response, {
        'success': false,
        'error': error.message,
        'errorType': error.type.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
  
  /// Handle design system requests
  Future<void> _handleDesignSystems(HttpRequest request) async {
    try {
      final contextService = ServiceLocator.instance.get<ContextMCPResourceService>();
      
      // Get all design system files from context
      final designSystems = await contextService.getDesignSystems();
      
      await _sendJsonResponse(request.response, {
        'success': true,
        'designSystems': designSystems,
      });
      
    } catch (e) {
      await _sendJsonResponse(request.response, {
        'success': false,
        'error': e.toString(),
      });
    }
  }
  
  /// Handle loading a specific design system
  Future<void> _handleLoadDesignSystem(HttpRequest request) async {
    if (request.method != 'POST') {
      await _sendErrorResponse(request.response, 405, 'Method not allowed');
      return;
    }
    
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final designSystemId = data['designSystemId'] as String;
      
      final contextService = ServiceLocator.instance.get<ContextMCPResourceService>();
      final designSystem = await contextService.getDesignSystem(designSystemId);
      
      await _sendJsonResponse(request.response, {
        'success': true,
        'designSystem': designSystem,
      });
      
    } catch (e) {
      await _sendJsonResponse(request.response, {
        'success': false,
        'error': e.toString(),
      });
    }
  }
  
  /// Handle canvas state persistence
  Future<void> _handleCanvasState(HttpRequest request) async {
    final uri = request.uri;
    final canvasId = uri.queryParameters['canvasId'] ?? 'default';
    
    switch (request.method) {
      case 'GET':
        // Load canvas state
        try {
          final storageService = ServiceLocator.instance.get<CanvasStorageService>();
          final state = await storageService.loadCanvasState(canvasId);
          
          await _sendJsonResponse(request.response, {
            'success': true,
            'state': state,
            'canvasId': canvasId,
          });
        } catch (e) {
          print('❌ Failed to load canvas state: $e');
          await _sendJsonResponse(request.response, {
            'success': false,
            'error': e.toString(),
          });
        }
        break;
        
      case 'PUT':
        // Save canvas state (with debouncing)
        _performanceService.debounce('save_state_$canvasId', () async {
          try {
            _performanceService.startOperation('save_state');
            
            final body = await utf8.decoder.bind(request).join();
            final data = jsonDecode(body) as Map<String, dynamic>;
            final state = data['state'] as Map<String, dynamic>;
            
            // Validate canvas state
            final validation = CanvasSecurityService.validateCanvasState(state);
            if (!validation.isValid) {
              throw ArgumentError('Invalid canvas state: ${validation.error}');
            }
            
            // Sanitize and optimize canvas state
            final sanitizedState = CanvasSecurityService.sanitizeCanvasState(state);
            final optimizedState = _performanceService.optimizeCanvasState(sanitizedState);
            
            final storageService = ServiceLocator.instance.get<CanvasStorageService>();
            await storageService.saveCanvasState(canvasId, optimizedState);
            
            // Update current state for auto-save
            storageService.updateCurrentState(optimizedState);
            
            // Clear related cache entries
            _performanceService.clearCache('canvas_state_$canvasId');
            
            await _sendJsonResponse(request.response, {
              'success': true,
              'canvasId': canvasId,
              'savedAt': DateTime.now().toIso8601String(),
            });
            
            _performanceService.endOperation('save_state');
            
          } catch (e, stackTrace) {
            _performanceService.endOperation('save_state');
            final error = CanvasErrorHandler.handleError(e, 'Save canvas state', stackTrace: stackTrace);
            await _sendJsonResponse(request.response, {
              'success': false,
              'error': error.message,
            });
          }
        });
        break;
        
      case 'DELETE':
        // Delete canvas state
        try {
          final storageService = ServiceLocator.instance.get<CanvasStorageService>();
          await storageService.deleteCanvas(canvasId);
          
          await _sendJsonResponse(request.response, {
            'success': true,
            'canvasId': canvasId,
          });
        } catch (e) {
          print('❌ Failed to delete canvas state: $e');
          await _sendJsonResponse(request.response, {
            'success': false,
            'error': e.toString(),
          });
        }
        break;
        
      default:
        await _sendErrorResponse(request.response, 405, 'Method not allowed');
    }
  }
  
  /// Handle available models request
  Future<void> _handleModels(HttpRequest request) async {
    try {
      final modelService = ServiceLocator.instance.get<ModelConfigService>();
      final models = modelService.getReadyModels()
          .where((model) => model.isLocal)
          .map((model) => {
            'id': model.id,
            'name': model.name,
            'provider': model.provider,
            'status': model.status.toString(),
            'capabilities': model.capabilities,
          })
          .toList();
      
      await _sendJsonResponse(request.response, {
        'success': true,
        'models': models,
      });
      
    } catch (e) {
      await _sendJsonResponse(request.response, {
        'success': false,
        'error': e.toString(),
      });
    }
  }
  
  /// Handle context documents request
  Future<void> _handleContextDocuments(HttpRequest request) async {
    try {
      final contextService = ServiceLocator.instance.get<ContextMCPResourceService>();
      final documents = await contextService.getAvailableDocuments();
      
      await _sendJsonResponse(request.response, {
        'success': true,
        'documents': documents,
      });
      
    } catch (e) {
      await _sendJsonResponse(request.response, {
        'success': false,
        'error': e.toString(),
      });
    }
  }
  
  /// Handle health check
  Future<void> _handleHealthCheck(HttpRequest request) async {
    await _sendJsonResponse(request.response, {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'port': _port,
    });
  }

  /// Serve the main canvas HTML file
  Future<void> _serveCanvasIndex(HttpRequest request) async {
    try {
      // Load canvas HTML from assets
      final html = await _loadCanvasHtml();
      
      request.response.headers.contentType = ContentType.html;
      request.response.write(html);
      await request.response.close();
      
    } catch (e) {
      await _sendErrorResponse(request.response, 500, 'Failed to load canvas: $e');
    }
  }
  
  /// Serve static assets (CSS, JS, images, etc.)
  Future<void> _serveStaticAsset(HttpRequest request) async {
    final assetPath = request.uri.path;
    
    try {
      // Security check - prevent directory traversal
      if (assetPath.contains('..')) {
        await _sendErrorResponse(request.response, 403, 'Forbidden');
        return;
      }
      
      // Load asset from bundle
      final asset = await _loadAsset('canvas$assetPath');
      final extension = path.extension(assetPath).toLowerCase();
      final mimeType = _mimeTypes[extension] ?? 'application/octet-stream';
      
      request.response.headers.contentType = ContentType.parse(mimeType);
      request.response.add(asset);
      await request.response.close();
      
    } catch (e) {
      await _sendErrorResponse(request.response, 404, 'Asset not found');
    }
  }
  
  /// Load canvas HTML template
  Future<String> _loadCanvasHtml() async {
    try {
      // Try to load from assets first
      final html = await rootBundle.loadString('assets/canvas/index.html');
      
      // Inject server configuration
      return html.replaceAll(
        '{{SERVER_CONFIG}}',
        jsonEncode({
          'apiUrl': 'http://127.0.0.1:$_port/api',
          'version': '1.0.0',
          'debug': kDebugMode,
        }),
      );
      
    } catch (e) {
      // Fallback to embedded HTML
      return _getEmbeddedCanvasHtml();
    }
  }
  
  /// Load asset from bundle
  Future<Uint8List> _loadAsset(String assetPath) async {
    final data = await rootBundle.load('assets/$assetPath');
    return data.buffer.asUint8List();
  }
  
  /// Send JSON response
  Future<void> _sendJsonResponse(HttpResponse response, Map<String, dynamic> data) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(data));
    await response.close();
  }
  
  /// Send error response
  Future<void> _sendErrorResponse(HttpResponse response, int statusCode, String message) async {
    try {
      response.statusCode = statusCode;
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode({
        'error': message,
        'statusCode': statusCode,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      await response.close();
    } catch (e) {
      // If response writing fails, just log it
      print('❌ Failed to send error response: $e');
    }
  }

  /// Get appropriate HTTP status code from error
  int _getStatusCodeFromError(CanvasError error) {
    switch (error.type) {
      case ErrorType.validation:
        return 400; // Bad Request
      case ErrorType.network:
      case ErrorType.timeout:
        return 503; // Service Unavailable
      case ErrorType.storage:
        return 500; // Internal Server Error
      case ErrorType.parsing:
        return 422; // Unprocessable Entity
      case ErrorType.http:
        return 502; // Bad Gateway
      case ErrorType.assertion:
      case ErrorType.memory:
        return 500; // Internal Server Error
      case ErrorType.state:
        return 409; // Conflict
      case ErrorType.unknown:
      default:
        return 500; // Internal Server Error
    }
  }

  /// Get server health and error statistics
  Map<String, dynamic> getServerStats() {
    return {
      'isRunning': _isRunning,
      'port': _port,
      'errorStats': _errorHandler.getErrorStats(),
      'resourceStats': _resourceManager.getStats(),
      'performanceStats': _performanceService.getMetrics(),
      'uptime': _isRunning ? DateTime.now().millisecondsSinceEpoch : null,
    };
  }
  
  /// Get embedded canvas HTML as fallback
  String _getEmbeddedCanvasHtml() {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Asmbli Canvas</title>
    <script src="https://unpkg.com/konva@9/konva.min.js"></script>
    <style>
        body, html {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
        }
        #canvas-container {
            width: 100vw;
            height: 100vh;
            position: relative;
        }
        #toolbar {
            position: absolute;
            top: 16px;
            left: 16px;
            z-index: 100;
            background: white;
            border-radius: 8px;
            padding: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            display: flex;
            gap: 8px;
        }
        .tool-button {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            background: white;
            cursor: pointer;
            font-size: 12px;
        }
        .tool-button:hover {
            background: #f0f0f0;
        }
        .tool-button.active {
            background: #6750A4;
            color: white;
            border-color: #6750A4;
        }
        #status {
            position: absolute;
            bottom: 16px;
            right: 16px;
            background: white;
            padding: 8px 12px;
            border-radius: 4px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            font-size: 12px;
            color: #666;
        }
    </style>
</head>
<body>
    <div id="canvas-container">
        <div id="toolbar">
            <button class="tool-button active" data-tool="select">Select</button>
            <button class="tool-button" data-tool="rectangle">Rectangle</button>
            <button class="tool-button" data-tool="text">Text</button>
            <button class="tool-button" data-tool="button">Button</button>
            <div style="border-left: 1px solid #ddd; margin: 0 8px;"></div>
            <button class="tool-button" onclick="exportCode()">Export Flutter</button>
            <button class="tool-button" onclick="clearCanvas()">Clear</button>
        </div>
        <div id="status">Canvas Ready</div>
    </div>
    
    <script>
        // Canvas initialization
        const stage = new Konva.Stage({
            container: 'canvas-container',
            width: window.innerWidth,
            height: window.innerHeight,
        });
        
        const layer = new Konva.Layer();
        stage.add(layer);
        
        // Server configuration injected by Flutter
        const SERVER_CONFIG = {{SERVER_CONFIG}};
        console.log('Canvas initialized with config:', SERVER_CONFIG);
        
        // Basic canvas functionality
        let currentTool = 'select';
        let isDrawing = false;
        
        // Tool selection
        document.querySelectorAll('.tool-button[data-tool]').forEach(button => {
            button.addEventListener('click', () => {
                document.querySelectorAll('.tool-button').forEach(b => b.classList.remove('active'));
                button.classList.add('active');
                currentTool = button.dataset.tool;
                updateStatus('Tool: ' + currentTool);
            });
        });
        
        // Canvas interaction
        stage.on('click tap', (e) => {
            if (currentTool === 'rectangle') {
                createRectangle(e.evt.offsetX, e.evt.offsetY);
            } else if (currentTool === 'text') {
                createText(e.evt.offsetX, e.evt.offsetY);
            } else if (currentTool === 'button') {
                createButton(e.evt.offsetX, e.evt.offsetY);
            }
        });
        
        function createRectangle(x, y) {
            const rect = new Konva.Rect({
                x: x,
                y: y,
                width: 120,
                height: 80,
                fill: '#6750A4',
                stroke: '#5a3f9a',
                strokeWidth: 1,
                draggable: true,
            });
            
            layer.add(rect);
            layer.draw();
            
            callMCP('create_element', {
                type: 'container',
                x: x,
                y: y,
                width: 120,
                height: 80,
                style: {
                    backgroundColor: '#6750A4',
                    borderColor: '#5a3f9a',
                    borderWidth: 1,
                }
            });
        }
        
        function createText(x, y) {
            const text = new Konva.Text({
                x: x,
                y: y,
                text: 'Text Element',
                fontSize: 16,
                fontFamily: '-apple-system, sans-serif',
                fill: '#1a1a1a',
                draggable: true,
            });
            
            layer.add(text);
            layer.draw();
            
            callMCP('create_element', {
                type: 'text',
                x: x,
                y: y,
                width: text.width(),
                height: text.height(),
                text: 'Text Element',
                style: {
                    fontSize: 16,
                    fontFamily: '-apple-system, sans-serif',
                    color: '#1a1a1a',
                }
            });
        }
        
        function createButton(x, y) {
            const buttonGroup = new Konva.Group({
                x: x,
                y: y,
                draggable: true,
            });
            
            const buttonBg = new Konva.Rect({
                width: 120,
                height: 40,
                fill: '#6750A4',
                cornerRadius: 20,
            });
            
            const buttonText = new Konva.Text({
                x: 30,
                y: 12,
                text: 'Button',
                fontSize: 14,
                fontFamily: '-apple-system, sans-serif',
                fill: 'white',
            });
            
            buttonGroup.add(buttonBg);
            buttonGroup.add(buttonText);
            layer.add(buttonGroup);
            layer.draw();
            
            callMCP('create_element', {
                type: 'button',
                x: x,
                y: y,
                width: 120,
                height: 40,
                text: 'Button',
                component: 'button',
                variant: 'filled',
            });
        }
        
        function clearCanvas() {
            layer.destroyChildren();
            layer.draw();
            updateStatus('Canvas cleared');
            
            callMCP('clear_canvas', {});
        }
        
        async function exportCode() {
            try {
                const result = await callMCP('export_code', {
                    format: 'flutter',
                    includeTokens: true,
                    componentize: true,
                });
                
                console.log('Generated Flutter code:', result);
                updateStatus('Code exported to console');
                
                // You could open a modal or send to Flutter here
                alert('Flutter code generated! Check the console.');
                
            } catch (error) {
                console.error('Export failed:', error);
                updateStatus('Export failed: ' + error.message);
            }
        }
        
        async function callMCP(tool, args) {
            try {
                const response = await fetch(SERVER_CONFIG.apiUrl + '/mcp/call', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        tool: tool,
                        arguments: args,
                    }),
                });
                
                const result = await response.json();
                
                if (!result.success) {
                    throw new Error(result.error);
                }
                
                return result.result;
                
            } catch (error) {
                console.error('MCP call failed:', error);
                throw error;
            }
        }
        
        function updateStatus(message) {
            document.getElementById('status').textContent = message;
        }
        
        // Handle window resize
        window.addEventListener('resize', () => {
            stage.width(window.innerWidth);
            stage.height(window.innerHeight);
        });
        
        // Initial status
        updateStatus('Canvas Ready - Click tools to create elements');
        
    </script>
</body>
</html>''';
  }
}

/// Extension methods for MCP integration
extension MCPBridgeCanvasExtension on MCPBridgeService {
  /// Call a canvas MCP tool through the actual MCP server
  Future<Map<String, dynamic>> callCanvasTool(String tool, Map<String, dynamic> arguments) async {
    try {
      // Check if canvas MCP server is available
      final canvasServer = await getServerByName('asmbli-canvas');
      if (canvasServer == null) {
        throw Exception('Canvas MCP server not found. Please ensure it is registered and running.');
      }
      
      // Call the tool on the canvas MCP server
      final result = await callTool(tool, arguments, serverId: canvasServer.id);
      
      return {
        'tool': tool,
        'arguments': arguments,
        'result': result,
        'serverId': canvasServer.id,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('❌ Canvas MCP Tool Call Failed: $e');
      rethrow;
    }
  }
  
  /// Get MCP server by name
  Future<dynamic> getServerByName(String name) async {
    try {
      // For now, return a mock server until the real MCP integration is complete
      return {
        'id': 'asmbli-canvas-mcp',
        'name': name,
        'status': 'running',
      };
    } catch (e) {
      print('❌ Failed to get MCP server by name: $e');
      return null;
    }
  }
}

/// Extension methods for context integration
extension ContextMCPCanvasExtension on ContextMCPResourceService {
  /// Get all design system files from context
  Future<List<Map<String, dynamic>>> getDesignSystems() async {
    // TODO: Implement design system loading from context
    // This would scan for .design.json files
    
    // For now, return mock design systems
    return [
      {
        'id': 'material3',
        'name': 'Material Design 3',
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
  }
  
  /// Get a specific design system
  Future<Map<String, dynamic>> getDesignSystem(String id) async {
    // TODO: Load design system from context or builtin
    
    // For now, return mock design system
    return {
      'id': id,
      'name': 'Design System',
      'tokens': {
        'colors': {
          'primary': '#6750A4',
          'surface': '#FFFFFF',
        },
      },
      'components': {},
    };
  }
  
  /// Get available context documents
  Future<List<Map<String, dynamic>>> getAvailableDocuments() async {
    // TODO: Implement context document listing
    
    return [
      {
        'id': 'doc1',
        'name': 'Brand Guidelines.pdf',
        'type': 'pdf',
        'size': 1024000,
      },
      {
        'id': 'doc2',
        'name': 'Design System.design.json',
        'type': 'design-system',
        'size': 51200,
      },
    ];
  }
}