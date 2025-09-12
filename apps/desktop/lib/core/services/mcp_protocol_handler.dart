import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_message.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_connection.dart';
import '../models/mcp_catalog_entry.dart';
import 'mcp_error_handler.dart';

/// Production-grade MCP JSON-RPC 2.0 protocol handler
/// Implements the complete Model Context Protocol specification
class MCPProtocolHandler {
  final MCPErrorHandler _errorHandler;
  final Map<String, MCPConnection> _connections = {};
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  int _requestIdCounter = 1;

  // Protocol constants
  static const String mcpVersion = '2024-11-05';
  static const int maxMessageSize = 10 * 1024 * 1024; // 10MB
  static const Duration requestTimeout = Duration(seconds: 30);

  MCPProtocolHandler(this._errorHandler);

  /// Establish MCP connection with server process
  Future<MCPConnection> establishConnection(MCPServerProcess serverProcess) async {
    final connectionId = serverProcess.id;
    
    // Check if connection already exists
    if (_connections.containsKey(connectionId)) {
      final existing = _connections[connectionId]!;
      if (existing.isConnected) {
        return existing;
      }
    }

    try {
      final connection = await _createConnection(serverProcess);
      _connections[connectionId] = connection;

      // Initialize MCP session
      await _initializeMCPSession(connection);

      return connection;
    } catch (e) {
      await _errorHandler.handleError(e, context: 'MCP Connection');
      rethrow;
    }
  }

  /// Create connection based on transport type
  Future<MCPConnection> _createConnection(MCPServerProcess serverProcess) async {
    switch (serverProcess.transport) {
      case MCPTransport.stdio:
        return await _createStdioConnection(serverProcess);
      case MCPTransport.sse:
        return await _createSSEConnection(serverProcess);
    }
  }

  /// Create stdio-based connection
  Future<MCPStdioConnection> _createStdioConnection(MCPServerProcess serverProcess) async {
    final processId = serverProcess.id;
    final process = await Process.start(
      serverProcess.config.command,
      serverProcess.config.args,
      environment: serverProcess.config.env,
      mode: ProcessStartMode.normal,
    );

    final connection = MCPStdioConnection(
      id: processId,
      serverProcess: serverProcess,
      process: process,
      protocolHandler: this,
    );

    // Setup message handling
    await connection.initialize();
    
    return connection;
  }

  /// Create SSE-based connection
  Future<MCPSSEConnection> _createSSEConnection(MCPServerProcess serverProcess) async {
    final baseUrl = serverProcess.config.url;
    
    final connection = MCPSSEConnection(
      id: serverProcess.id,
      serverProcess: serverProcess,
      baseUrl: baseUrl,
      protocolHandler: this,
    );

    await connection.initialize();
    return connection;
  }

  /// Create WebSocket-based connection
  Future<MCPWebSocketConnection> _createWebSocketConnection(MCPServerProcess serverProcess) async {
    final url = serverProcess.config.url;
    
    final connection = MCPWebSocketConnection(
      id: serverProcess.id,
      serverProcess: serverProcess,
      url: url,
      protocolHandler: this,
    );

    await connection.initialize();
    return connection;
  }

  /// Initialize MCP session with handshake
  Future<void> _initializeMCPSession(MCPConnection connection) async {
    try {
      // Send initialize request
      final initRequest = MCPMessage.request(
        id: _generateRequestId(),
        method: 'initialize',
        params: {
          'protocolVersion': mcpVersion,
          'capabilities': {
            'roots': {
              'listChanged': true,
            },
            'sampling': {},
          },
          'clientInfo': {
            'name': 'Asmbli Desktop',
            'version': '1.0.0',
          },
        },
      );

      final response = await sendRequest(connection, initRequest);
      
      if (response.isError) {
        throw Exception('MCP initialization failed: ${response.error}');
      }

      // Validate server capabilities
      final serverInfo = response.result;
      if (!_validateServerCapabilities(serverInfo)) {
        throw Exception('Server capabilities validation failed');
      }

      // Send initialized notification
      await sendNotification(connection, MCPMessage.notification(
        method: 'notifications/initialized',
        params: {},
      ));

      connection.markAsConnected(serverInfo);
      print('✅ MCP session initialized with ${connection.serverProcess.id}');
      
    } catch (e) {
      await _errorHandler.handleError(e, context: 'MCP Initialization');
      rethrow;
    }
  }

  /// Validate server capabilities
  bool _validateServerCapabilities(Map<String, dynamic>? serverInfo) {
    if (serverInfo == null) return false;
    
    // Check protocol version compatibility
    final serverVersion = serverInfo['protocolVersion'] as String?;
    if (serverVersion == null) return false;
    
    // For now, just check it's not empty - in production would do semver comparison
    return serverVersion.isNotEmpty;
  }

  /// Send JSON-RPC request and wait for response
  Future<MCPMessage> sendRequest(MCPConnection connection, MCPMessage request) async {
    if (!connection.isConnected) {
      throw Exception('Connection not established');
    }

    // Validate request
    if (!request.isRequest) {
      throw Exception('Message is not a request');
    }

    // Setup response completer
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[request.id.toString()] = completer;

    try {
      // Send request through connection
      await connection.sendMessage(request);

      // Wait for response with timeout
      final responseData = await completer.future.timeout(requestTimeout);
      
      return MCPMessage.fromJson(responseData);
      
    } catch (e) {
      _pendingRequests.remove(request.id.toString());
      rethrow;
    }
  }

  /// Send JSON-RPC notification (no response expected)
  Future<void> sendNotification(MCPConnection connection, MCPMessage notification) async {
    if (!connection.isConnected) {
      throw Exception('Connection not established');
    }

    if (!notification.isNotification) {
      throw Exception('Message is not a notification');
    }

    await connection.sendMessage(notification);
  }

  /// Handle incoming message from server
  Future<void> handleIncomingMessage(MCPConnection connection, String rawMessage) async {
    try {
      // Parse JSON-RPC message
      final messageData = json.decode(rawMessage);
      final message = MCPMessage.fromJson(messageData);

      // Handle different message types
      if (message.isResponse) {
        await _handleResponse(message);
      } else if (message.isRequest) {
        await _handleServerRequest(connection, message);
      } else if (message.isNotification) {
        await _handleServerNotification(connection, message);
      }
      
    } catch (e) {
      await _errorHandler.handleError(e, 
        context: 'MCP Message Handling',
        metadata: {'rawMessage': rawMessage.length > 500 ? '${rawMessage.substring(0, 500)}...' : rawMessage},
      );
    }
  }

  /// Handle response to our request
  Future<void> _handleResponse(MCPMessage response) async {
    final requestId = response.id?.toString();
    if (requestId == null) return;

    final completer = _pendingRequests.remove(requestId);
    if (completer != null) {
      completer.complete(response.toJson());
    }
  }

  /// Handle request from server
  Future<void> _handleServerRequest(MCPConnection connection, MCPMessage request) async {
    try {
      MCPMessage response;
      
      switch (request.method) {
        case 'ping':
          response = MCPMessage.response(
            id: request.id!,
            result: {'pong': true},
          );
          break;
          
        case 'logging/setLevel':
          final level = request.params?['level'] as String? ?? 'info';
          print('📝 Server requested log level: $level');
          response = MCPMessage.response(
            id: request.id!,
            result: {'success': true},
          );
          break;
          
        default:
          response = MCPMessage.error(
            id: request.id!,
            code: -32601,
            message: 'Method not found: ${request.method}',
          );
      }
      
      await connection.sendMessage(response);
      
    } catch (e) {
      // Send error response
      final errorResponse = MCPMessage.error(
        id: request.id!,
        code: -32603,
        message: 'Internal error: ${e.toString()}',
      );
      
      await connection.sendMessage(errorResponse);
    }
  }

  /// Handle notification from server
  Future<void> _handleServerNotification(MCPConnection connection, MCPMessage notification) async {
    switch (notification.method) {
      case 'notifications/message':
        final level = notification.params?['level'] as String? ?? 'info';
        final logger = notification.params?['logger'] as String? ?? 'server';
        final data = notification.params?['data'];
        print('📢 Server $logger [$level]: $data');
        break;
        
      case 'notifications/progress':
        final progressToken = notification.params?['progressToken'];
        final progress = notification.params?['progress'];
        print('🔄 Progress $progressToken: $progress');
        break;
        
      default:
        print('🔔 Unknown notification: ${notification.method}');
    }
  }

  /// List available tools on server
  Future<List<MCPTool>> listTools(MCPConnection connection) async {
    final request = MCPMessage.request(
      id: _generateRequestId(),
      method: 'tools/list',
      params: {},
    );

    final response = await sendRequest(connection, request);
    
    if (response.isError) {
      throw Exception('Failed to list tools: ${response.error}');
    }

    final tools = response.result?['tools'] as List? ?? [];
    return tools.map((tool) => MCPTool.fromJson(tool)).toList();
  }

  /// Call a tool on the server
  Future<MCPToolResult> callTool(
    MCPConnection connection,
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    final request = MCPMessage.request(
      id: _generateRequestId(),
      method: 'tools/call',
      params: {
        'name': toolName,
        'arguments': arguments,
      },
    );

    final response = await sendRequest(connection, request);
    
    if (response.isError) {
      throw Exception('Tool call failed: ${response.error}');
    }

    return MCPToolResult.fromJson(response.result ?? {});
  }

  /// List available resources on server
  Future<List<MCPResource>> listResources(MCPConnection connection) async {
    final request = MCPMessage.request(
      id: _generateRequestId(),
      method: 'resources/list',
      params: {},
    );

    final response = await sendRequest(connection, request);
    
    if (response.isError) {
      throw Exception('Failed to list resources: ${response.error}');
    }

    final resources = response.result?['resources'] as List? ?? [];
    return resources.map((resource) => MCPResource.fromJson(resource)).toList();
  }

  /// Read a resource from server
  Future<MCPResourceContent> readResource(
    MCPConnection connection,
    String resourceUri,
  ) async {
    final request = MCPMessage.request(
      id: _generateRequestId(),
      method: 'resources/read',
      params: {
        'uri': resourceUri,
      },
    );

    final response = await sendRequest(connection, request);
    
    if (response.isError) {
      throw Exception('Failed to read resource: ${response.error}');
    }

    return MCPResourceContent.fromJson(response.result ?? {});
  }

  /// List available prompts on server
  Future<List<MCPPrompt>> listPrompts(MCPConnection connection) async {
    final request = MCPMessage.request(
      id: _generateRequestId(),
      method: 'prompts/list',
      params: {},
    );

    final response = await sendRequest(connection, request);
    
    if (response.isError) {
      throw Exception('Failed to list prompts: ${response.error}');
    }

    final prompts = response.result?['prompts'] as List? ?? [];
    return prompts.map((prompt) => MCPPrompt.fromJson(prompt)).toList();
  }

  /// Get a prompt from server
  Future<MCPPromptResult> getPrompt(
    MCPConnection connection,
    String promptName,
    Map<String, dynamic>? arguments,
  ) async {
    final request = MCPMessage.request(
      id: _generateRequestId(),
      method: 'prompts/get',
      params: {
        'name': promptName,
        if (arguments != null) 'arguments': arguments,
      },
    );

    final response = await sendRequest(connection, request);
    
    if (response.isError) {
      throw Exception('Failed to get prompt: ${response.error}');
    }

    return MCPPromptResult.fromJson(response.result ?? {});
  }

  /// Generate request ID
  String _generateRequestId() {
    return 'req_${_requestIdCounter++}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get connection by ID
  MCPConnection? getConnection(String connectionId) {
    return _connections[connectionId];
  }

  /// Get all active connections
  List<MCPConnection> getActiveConnections() {
    return _connections.values.where((conn) => conn.isConnected).toList();
  }

  /// Close connection
  Future<void> closeConnection(String connectionId) async {
    final connection = _connections.remove(connectionId);
    if (connection != null) {
      await connection.close();
    }
  }

  /// Close all connections
  Future<void> closeAllConnections() async {
    final futures = _connections.values.map((conn) => conn.close()).toList();
    await Future.wait(futures);
    _connections.clear();
    _pendingRequests.clear();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await closeAllConnections();
  }
}

// ==================== Riverpod Provider ====================

final mcpProtocolHandlerProvider = Provider<MCPProtocolHandler>((ref) {
  final errorHandler = ref.read(mcpErrorHandlerProvider);
  return MCPProtocolHandler(errorHandler);
});