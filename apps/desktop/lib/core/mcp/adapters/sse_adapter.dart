import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'base_mcp_adapter.dart';
import '../../models/mcp_server_config.dart';

/// Server-Sent Events (SSE) MCP adapter for real-time notifications
class SSEMCPAdapter extends MCPAdapter {
  Dio? _client;
  Stream<String>? _sseStream;
  StreamSubscription<String>? _sseSubscription;
  MCPServerConfig? _config;
  String? _sessionId;
  final Map<String, Completer<Map<String, dynamic>>> _responseCompleter = {};
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 10);
  static const Duration _requestTimeout = Duration(seconds: 30);
  
  @override
  String get protocol => 'sse';
  
  @override
  List<String> getSupportedFeatures() {
    return [
      'tools',
      'resources',
      'prompts',
      'notifications',
      'streaming',
      'events',
      'reconnection',
    ];
  }
  
  @override
  Future<void> connect(MCPServerConfig config) async {
    _config = config;
    
    try {
      _setupHttpClient(config);
      await _performHandshake(config);
      await _establishSSEConnection(config);
      _setConnected(const Uuid().v4());
      
      print('✅ SSE MCP adapter connected to ${config.url}');
    } catch (e) {
      throw MCPAdapterException(
        'Failed to connect SSE MCP adapter: $e',
        protocol: protocol,
        originalError: e,
      );
    }
  }
  
  /// Setup HTTP client for SSE requests
  void _setupHttpClient(MCPServerConfig config) {
    final baseOptions = BaseOptions(
      baseUrl: config.url,
      connectTimeout: Duration(seconds: config.timeout ?? 30),
      receiveTimeout: _requestTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'User-Agent': 'AgentEngine-MCP-Client/1.0',
        ...config.headers ?? {},
      },
    );
    
    if (config.authToken != null) {
      baseOptions.headers['Authorization'] = 'Bearer ${config.authToken}';
    }
    
    _client = Dio(baseOptions);
    _client!.interceptors.add(_createLoggingInterceptor());
  }
  
  /// Perform MCP handshake
  Future<void> _performHandshake(MCPServerConfig config) async {
    try {
      final initResponse = await _client!.post(
        '/mcp/initialize',
        data: {
          'protocolVersion': '1.0',
          'capabilities': config.capabilities ?? getCapabilities(),
          'clientInfo': {
            'name': 'AgentEngine',
            'version': '1.0.0',
          },
          'transport': 'sse',
        },
      );
      
      if (initResponse.statusCode != 200) {
        throw MCPAdapterException(
          'SSE initialization failed with status: ${initResponse.statusCode}',
          protocol: protocol,
        );
      }
      
      final data = initResponse.data;
      if (data['error'] != null) {
        throw MCPAdapterException(
          'Server initialization error: ${data['error']['message']}',
          protocol: protocol,
          errorCode: data['error']['code'],
        );
      }
      
      _sessionId = data['sessionId'] ?? data['result']?['sessionId'];
      
      // Confirm initialization
      await _client!.post(
        '/mcp/initialized',
        data: {'sessionId': _sessionId},
      );
      
      print('✅ SSE MCP handshake completed');
    } catch (e) {
      throw MCPAdapterException(
        'SSE handshake failed: $e',
        protocol: protocol,
        originalError: e,
      );
    }
  }
  
  /// Establish SSE connection for real-time events
  Future<void> _establishSSEConnection(MCPServerConfig config) async {
    try {
      final sseUrl = '${config.url}/mcp/events';
      final queryParams = <String, dynamic>{};
      
      if (_sessionId != null) {
        queryParams['sessionId'] = _sessionId;
      }
      
      // Create SSE stream
      _sseStream = _createSSEStream(sseUrl, queryParams);
      
      // Listen to SSE events
      _sseSubscription = _sseStream!.listen(
        _handleSSEEvent,
        onError: _handleSSEError,
        onDone: _handleSSEDisconnect,
      );
      
      print('✅ SSE event stream established');
    } catch (e) {
      throw MCPAdapterException(
        'Failed to establish SSE connection: $e',
        protocol: protocol,
        originalError: e,
      );
    }
  }
  
  /// Create SSE stream from HTTP endpoint
  Stream<String> _createSSEStream(String url, Map<String, dynamic> queryParams) {
    final controller = StreamController<String>();
    
    () async {
      try {
        final response = await _client!.get<ResponseBody>(
          url,
          queryParameters: queryParams,
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              'Accept': 'text/event-stream',
              'Cache-Control': 'no-cache',
            },
          ),
        );
        
        if (response.statusCode != 200) {
          controller.addError(MCPAdapterException(
            'SSE stream failed with status: ${response.statusCode}',
            protocol: protocol,
          ));
          return;
        }
        
        final stream = response.data!.stream;
        String buffer = '';
        
        await for (final chunk in stream.transform(utf8.decoder)) {
          buffer += chunk;
          
          // Process complete SSE events
          while (buffer.contains('\n\n')) {
            final eventEndIndex = buffer.indexOf('\n\n');
            final eventData = buffer.substring(0, eventEndIndex);
            buffer = buffer.substring(eventEndIndex + 2);
            
            if (eventData.isNotEmpty) {
              controller.add(eventData);
            }
          }
        }
      } catch (e) {
        controller.addError(e);
      } finally {
        await controller.close();
      }
    }();
    
    return controller.stream;
  }
  
  /// Handle SSE event data
  void _handleSSEEvent(String eventData) {
    try {
      final lines = eventData.split('\n');
      String? eventType;
      String? data;
      String? id;
      
      // Parse SSE event format
      for (final line in lines) {
        if (line.startsWith('event:')) {
          eventType = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          data = line.substring(5).trim();
        } else if (line.startsWith('id:')) {
          id = line.substring(3).trim();
        }
      }
      
      if (data == null) return;
      
      // Handle different event types
      switch (eventType) {
        case 'message':
        case 'response':
          _handleMessageEvent(data, id);
          break;
        case 'notification':
          _handleNotificationEvent(data);
          break;
        case 'error':
          _handleErrorEvent(data);
          break;
        case 'ping':
          _handlePingEvent();
          break;
        default:
          print('🔔 Unknown SSE event type: $eventType');
          _handleGenericEvent(data, eventType);
      }
      
    } catch (e) {
      print('❌ Error parsing SSE event: $e');
    }
  }
  
  /// Handle message/response events
  void _handleMessageEvent(String data, String? id) {
    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      
      // Check if this is a response to a pending request
      final responseId = jsonData['id']?.toString() ?? id;
      if (responseId != null && _responseCompleter.containsKey(responseId)) {
        final completer = _responseCompleter.remove(responseId)!;
        
        if (jsonData['error'] != null) {
          completer.completeError(MCPAdapterException(
            'Server error: ${jsonData['error']['message'] ?? 'Unknown error'}',
            protocol: protocol,
            errorCode: jsonData['error']['code'],
          ));
        } else {
          completer.complete(jsonData['result'] ?? jsonData);
        }
      } else {
        // Handle as notification
        _handleNotification(jsonData);
      }
    } catch (e) {
      print('❌ Error handling SSE message: $e');
    }
  }
  
  /// Handle notification events
  void _handleNotificationEvent(String data) {
    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      _handleNotification(jsonData);
    } catch (e) {
      print('❌ Error handling SSE notification: $e');
    }
  }
  
  /// Handle error events
  void _handleErrorEvent(String data) {
    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      
      final event = MCPEvent(
        type: MCPEventType.error,
        method: 'sse_error',
        data: jsonData,
        timestamp: DateTime.now(),
        serverId: connectionId,
      );
      
      _eventController.add(event);
    } catch (e) {
      print('❌ Error handling SSE error event: $e');
    }
  }
  
  /// Handle ping events for keepalive
  void _handlePingEvent() {
    print('🔄 SSE ping received');
    // Send pong response
    _sendPong();
  }
  
  /// Handle generic events
  void _handleGenericEvent(String data, String? eventType) {
    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      
      final event = MCPEvent(
        type: MCPEventType.notification,
        method: eventType ?? 'generic_event',
        data: jsonData,
        timestamp: DateTime.now(),
        serverId: connectionId,
      );
      
      _eventController.add(event);
    } catch (e) {
      print('❌ Error handling generic SSE event: $e');
    }
  }
  
  /// Send pong response for keepalive
  Future<void> _sendPong() async {
    try {
      await _client!.post(
        '/mcp/pong',
        data: {
          'sessionId': _sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('❌ Error sending SSE pong: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>> sendRequest(
    String method,
    Map<String, dynamic> params,
  ) async {
    if (!isConnected) {
      throw MCPAdapterException(
        'SSE adapter not connected',
        protocol: protocol,
      );
    }
    
    try {
      final requestId = const Uuid().v4();
      final completer = Completer<Map<String, dynamic>>();
      _responseCompleter[requestId] = completer;
      
      final requestData = {
        'jsonrpc': '2.0',
        'id': requestId,
        'method': method,
        'params': {
          ...params,
          if (_sessionId != null) 'sessionId': _sessionId,
        },
      };
      
      // Send request via HTTP POST
      final endpoint = _getEndpointForMethod(method);
      await _client!.post(endpoint, data: requestData);
      
      // Wait for response via SSE
      final response = await completer.future.timeout(
        _requestTimeout,
        onTimeout: () {
          _responseCompleter.remove(requestId);
          throw TimeoutException(
            'SSE request timed out for method: $method',
            _requestTimeout,
          );
        },
      );
      
      return response;
      
    } catch (e) {
      if (e is MCPAdapterException) rethrow;
      
      throw MCPAdapterException(
        'SSE request failed: $e',
        protocol: protocol,
        originalError: e,
      );
    }
  }
  
  @override
  Future<void> sendNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    if (!isConnected) {
      throw MCPAdapterException(
        'SSE adapter not connected',
        protocol: protocol,
      );
    }
    
    try {
      final requestData = {
        'jsonrpc': '2.0',
        'method': method,
        'params': {
          ...params,
          if (_sessionId != null) 'sessionId': _sessionId,
        },
      };
      
      final endpoint = _getEndpointForMethod(method);
      await _client!.post(endpoint, data: requestData);
      
    } catch (e) {
      throw MCPAdapterException(
        'SSE notification failed: $e',
        protocol: protocol,
        originalError: e,
      );
    }
  }
  
  /// Get HTTP endpoint for MCP method
  String _getEndpointForMethod(String method) {
    switch (method) {
      case 'tools/list':
        return '/mcp/tools';
      case 'tools/call':
        return '/mcp/tools/call';
      case 'resources/list':
        return '/mcp/resources';
      case 'resources/read':
        return '/mcp/resources/read';
      case 'prompts/list':
        return '/mcp/prompts';
      case 'prompts/get':
        return '/mcp/prompts/get';
      default:
        return '/mcp/request';
    }
  }
  
  /// Handle SSE connection errors
  void _handleSSEError(dynamic error) {
    print('❌ SSE connection error: $error');
    
    final event = MCPEvent(
      type: MCPEventType.error,
      method: 'sse_connection_error',
      data: {'error': error.toString()},
      timestamp: DateTime.now(),
      serverId: connectionId,
    );
    
    _eventController.add(event);
    
    // Attempt reconnection
    if (_config?.autoReconnect == true && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }
  
  /// Handle SSE connection disconnect
  void _handleSSEDisconnect() {
    print('🔌 SSE connection disconnected');
    
    final event = MCPEvent(
      type: MCPEventType.connectionStatus,
      method: 'disconnected',
      data: {'reason': 'SSE stream ended'},
      timestamp: DateTime.now(),
      serverId: connectionId,
    );
    
    _eventController.add(event);
    
    // Complete pending requests with error
    for (final completer in _responseCompleter.values) {
      if (!completer.isCompleted) {
        completer.completeError(MCPAdapterException(
          'SSE connection lost',
          protocol: protocol,
        ));
      }
    }
    _responseCompleter.clear();
    
    // Attempt reconnection
    if (_config?.autoReconnect == true && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }
  
  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;
    
    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;
    
    print('🔄 Scheduling SSE reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s');
    
    _reconnectTimer = Timer(delay, () async {
      if (_config != null) {
        try {
          await connect(_config!);
          _reconnectAttempts = 0;
          print('✅ SSE reconnection successful');
        } catch (e) {
          print('❌ SSE reconnection failed: $e');
          if (_reconnectAttempts < _maxReconnectAttempts) {
            _scheduleReconnect();
          }
        }
      }
    });
  }
  
  /// Create logging interceptor
  Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🌐 SSE HTTP Request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ SSE HTTP Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ SSE HTTP Error: ${error.response?.statusCode} ${error.requestOptions.path}');
        handler.next(error);
      },
    );
  }
  
  @override
  Future<MCPHealthStatus> getHealthStatus() async {
    final metrics = <String, dynamic>{
      'sessionId': _sessionId,
      'hasSSEStream': _sseStream != null,
      'reconnectAttempts': _reconnectAttempts,
      'pendingRequests': _responseCompleter.length,
    };
    
    return MCPHealthStatus(
      isHealthy: isConnected && _sseSubscription != null,
      protocol: protocol,
      connectionId: connectionId,
      lastCheck: DateTime.now(),
      metrics: metrics,
    );
  }
  
  @override
  bool validateConfig(MCPServerConfig config) {
    if (!super.validateConfig(config)) return false;
    
    final uri = Uri.tryParse(config.url);
    if (uri == null) return false;
    
    return ['http', 'https'].contains(uri.scheme);
  }
  
  @override
  Future<void> disconnect() async {
    print('🔌 Disconnecting SSE MCP adapter');
    
    _reconnectTimer?.cancel();
    
    // Complete pending requests
    for (final completer in _responseCompleter.values) {
      if (!completer.isCompleted) {
        completer.completeError(MCPAdapterException(
          'Adapter disconnected',
          protocol: protocol,
        ));
      }
    }
    _responseCompleter.clear();
    
    // Close SSE connection
    await _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseStream = null;
    
    // Send disconnect notification
    if (_sessionId != null && _client != null) {
      try {
        await _client!.post(
          '/mcp/disconnect',
          data: {'sessionId': _sessionId},
        );
      } catch (e) {
        print('❌ Error sending SSE disconnect notification: $e');
      }
    }
    
    _client?.close();
    _client = null;
    _sessionId = null;
    
    await super.disconnect();
  }
  
  @override
  Future<void> dispose() async {
    await disconnect();
    _reconnectTimer?.cancel();
  }
}