import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import 'base_mcp_adapter.dart';
import '../../models/mcp_server_config.dart';

/// WebSocket-based MCP adapter for real-time communication
class WebSocketMCPAdapter extends MCPAdapter {
  WebSocketChannel? _channel;
  final Map<String, Completer<Map<String, dynamic>>> _responseCompleter = {};
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  MCPServerConfig? _config;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  
  @override
  String get protocol => 'websocket';
  
  @override
  List<String> getSupportedFeatures() {
    return [
      'tools',
      'resources', 
      'prompts',
      'notifications',
      'streaming',
      'heartbeat',
      'reconnection'
    ];
  }
  
  @override
  Future<void> connect(MCPServerConfig config) async {
    _config = config;
    
    try {
      await _establishConnection(config);
      await _performHandshake(config);
      _startHeartbeat();
      _reconnectAttempts = 0;
      setConnected(const Uuid().v4());
      
      print('✅ WebSocket MCP adapter connected to ${config.url}');
    } catch (e) {
      throw MCPAdapterException(
        'Failed to connect WebSocket MCP adapter: $e',
        protocol: protocol,
        originalError: e,
      );
    }
  }
  
  /// Establish WebSocket connection
  Future<void> _establishConnection(MCPServerConfig config) async {
    final uri = Uri.parse(config.url);
    
    // Build headers
    final headers = <String, dynamic>{
      'User-Agent': 'Asmbli-MCP-Client/1.0',
      ...config.headers ?? {},
    };
    
    // Handle authentication
    if (config.authToken != null) {
      headers['Authorization'] = 'Bearer ${config.authToken}';
    }
    
    try {
      if (uri.scheme == 'wss' || uri.scheme == 'ws') {
        _channel = WebSocketChannel.connect(
          uri,
          protocols: ['mcp-v1', 'mcp'],
        );
      } else {
        // Convert HTTP URLs to WebSocket URLs
        final wsUri = uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');
        _channel = WebSocketChannel.connect(
          wsUri,
          protocols: ['mcp-v1', 'mcp'],
        );
      }
      
      // Set up message listener
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );
      
      // Wait for connection to be established
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      throw MCPAdapterException(
        'Failed to establish WebSocket connection',
        protocol: protocol,
        originalError: e,
      );
    }
  }
  
  /// Perform MCP handshake
  Future<void> _performHandshake(MCPServerConfig config) async {
    try {
      // Send initialization request
      final initResponse = await sendRequest('initialize', {
        'protocolVersion': '1.0',
        'capabilities': config.capabilities ?? getCapabilities(),
        'clientInfo': {
          'name': 'Asmbli',
          'version': '1.0.0',
        },
      });
      
      // Validate server response
      if (initResponse['error'] != null) {
        throw MCPAdapterException(
          'Server initialization failed: ${initResponse['error']}',
          protocol: protocol,
        );
      }
      
      // Send initialized notification
      await sendNotification('initialized', {});
      
      print('✅ MCP handshake completed with server');
      
    } catch (e) {
      throw MCPAdapterException(
        'MCP handshake failed: $e',
        protocol: protocol,
        originalError: e,
      );
    }
  }
  
  @override
  Future<Map<String, dynamic>> sendRequest(
    String method,
    Map<String, dynamic> params,
  ) async {
    if (!isConnected) {
      throw MCPAdapterException(
        'WebSocket adapter not connected',
        protocol: protocol,
      );
    }
    
    final id = const Uuid().v4();
    final completer = Completer<Map<String, dynamic>>();
    _responseCompleter[id] = completer;
    
    final message = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };
    
    try {
      _channel!.sink.add(jsonEncode(message));
      
      // Set timeout for response
      final response = await completer.future.timeout(
        Duration(seconds: _config?.timeout ?? 30),
        onTimeout: () {
          _responseCompleter.remove(id);
          throw TimeoutException(
            'MCP request timed out for method: $method',
            Duration(seconds: _config?.timeout ?? 30),
          );
        },
      );
      
      return response;
      
    } catch (e) {
      _responseCompleter.remove(id);
      throw MCPAdapterException(
        'Failed to send WebSocket request: $e',
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
        'WebSocket adapter not connected',
        protocol: protocol,
      );
    }
    
    final message = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    };
    
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      throw MCPAdapterException(
        'Failed to send WebSocket notification: $e',
        protocol: protocol,
        originalError: e,
      );
    }
  }
  
  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic rawMessage) {
    try {
      final String messageStr = rawMessage.toString();
      final Map<String, dynamic> data = jsonDecode(messageStr);
      
      // Handle JSON-RPC responses
      if (data.containsKey('id')) {
        final id = data['id'].toString();
        if (_responseCompleter.containsKey(id)) {
          final completer = _responseCompleter.remove(id)!;
          
          if (data['error'] != null) {
            completer.completeError(MCPAdapterException(
              'Server error: ${data['error']['message'] ?? 'Unknown error'}',
              protocol: protocol,
              errorCode: data['error']['code'],
            ));
          } else {
            completer.complete(data['result'] ?? data);
          }
        }
      }
      
      // Handle server-initiated messages (notifications)
      else if (data.containsKey('method')) {
        handleNotification(data);
      }
      
      // Handle heartbeat responses
      else if (data['type'] == 'pong') {
        print('🔄 WebSocket heartbeat response received');
      }
      
    } catch (e) {
      print('❌ Error handling WebSocket message: $e');
      _handleError(e);
    }
  }
  
  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('❌ WebSocket error: $error');
    
    final event = MCPEvent(
      type: MCPEventType.error,
      method: 'websocket_error',
      data: {'error': error.toString()},
      timestamp: DateTime.now(),
      serverId: connectionId,
    );
    
    eventController.add(event);
    
    // Attempt reconnection if enabled
    if (_config?.autoReconnect == true && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }
  
  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    print('🔌 WebSocket disconnected');
    // Connection status is managed by base class
    _stopHeartbeat();
    
    final event = MCPEvent(
      type: MCPEventType.connectionStatus,
      method: 'disconnected',
      data: {'reason': 'WebSocket connection closed'},
      timestamp: DateTime.now(),
      serverId: connectionId,
    );
    
    eventController.add(event);
    
    // Complete all pending requests with error
    for (final completer in _responseCompleter.values) {
      if (!completer.isCompleted) {
        completer.completeError(MCPAdapterException(
          'Connection lost',
          protocol: protocol,
        ));
      }
    }
    _responseCompleter.clear();
    
    // Attempt reconnection if enabled
    if (_config?.autoReconnect == true && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }
  
  /// Start heartbeat mechanism
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (!isConnected) {
        timer.cancel();
        return;
      }
      
      try {
        _channel!.sink.add(jsonEncode({
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      } catch (e) {
        print('❌ Heartbeat failed: $e');
        timer.cancel();
      }
    });
  }
  
  /// Stop heartbeat mechanism
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return; // Already scheduled
    }
    
    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;
    
    print('🔄 Scheduling WebSocket reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s');
    
    _reconnectTimer = Timer(delay, () async {
      if (_config != null) {
        try {
          await connect(_config!);
          print('✅ WebSocket reconnection successful');
        } catch (e) {
          print('❌ WebSocket reconnection failed: $e');
          if (_reconnectAttempts < _maxReconnectAttempts) {
            _scheduleReconnect();
          }
        }
      }
    });
  }
  
  @override
  Future<MCPHealthStatus> getHealthStatus() async {
    final metrics = <String, dynamic>{
      'reconnectAttempts': _reconnectAttempts,
      'hasHeartbeat': _heartbeatTimer?.isActive == true,
      'pendingRequests': _responseCompleter.length,
    };
    
    return MCPHealthStatus(
      isHealthy: isConnected,
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
    
    final validSchemes = ['ws', 'wss', 'http', 'https'];
    return validSchemes.contains(uri.scheme);
  }
  
  @override
  Future<void> disconnect() async {
    print('🔌 Disconnecting WebSocket MCP adapter');
    
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    
    // Complete all pending requests
    for (final completer in _responseCompleter.values) {
      if (!completer.isCompleted) {
        completer.completeError(MCPAdapterException(
          'Adapter disconnected',
          protocol: protocol,
        ));
      }
    }
    _responseCompleter.clear();
    
    // Close WebSocket connection
    try {
      await _channel?.sink.close(WebSocketStatus.normalClosure);
    } catch (e) {
      print('❌ Error closing WebSocket: $e');
    }
    
    await super.disconnect();
  }
  
  @override
  Future<void> dispose() async {
    await disconnect();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
  }
}