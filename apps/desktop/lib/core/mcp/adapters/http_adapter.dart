import 'dart:async';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'base_mcp_adapter.dart';
import '../../models/mcp_server_config.dart';

/// HTTP-based MCP adapter for REST API communication
class HTTPMCPAdapter extends MCPAdapter {
  Dio? _client;
  Timer? _pollTimer;
  MCPServerConfig? _config;
  String? _sessionId;
  final Map<String, Timer> _longRunningOperations = {};
  
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _pollInterval = Duration(seconds: 5);
  static const Duration _longPollTimeout = Duration(minutes: 2);
  
  @override
  String get protocol => 'http';
  
  @override
  List<String> getSupportedFeatures() {
    return [
      'tools',
      'resources',
      'prompts',
      'polling',
      'longpolling',
      'batching',
      'streaming'
    ];
  }
  
  @override
  Future<void> connect(MCPServerConfig config) async {
    _config = config;
    
    try {
      _setupHttpClient(config);
      await _performHandshake(config);
      _startPolling(config);
      setConnected(const Uuid().v4());
      
      print('✅ HTTP MCP adapter connected to ${config.url}');
    } catch (e) {
      throw MCPAdapterException(
        'Failed to connect HTTP MCP adapter: $e',
        protocol: protocol,
        originalError: e,
      );
    }
  }
  
  /// Setup HTTP client with configuration
  void _setupHttpClient(MCPServerConfig config) {
    final baseOptions = BaseOptions(
      baseUrl: config.url,
      connectTimeout: Duration(seconds: config.timeout ?? 30),
      receiveTimeout: _defaultTimeout,
      sendTimeout: _defaultTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'AgentEngine-MCP-Client/1.0',
        ...config.headers ?? {},
      },
    );
    
    // Add authentication headers
    if (config.authToken != null) {
      baseOptions.headers['Authorization'] = 'Bearer ${config.authToken}';
    }
    
    _client = Dio(baseOptions);
    
    // Add interceptors
    _client!.interceptors.add(_createLoggingInterceptor());
    _client!.interceptors.add(_createRetryInterceptor());
    _client!.interceptors.add(_createSessionInterceptor());
  }
  
  /// Perform MCP handshake over HTTP
  Future<void> _performHandshake(MCPServerConfig config) async {
    try {
      // Initialize session
      final initResponse = await _client!.post(
        '/mcp/initialize',
        data: {
          'protocolVersion': '1.0',
          'capabilities': config.capabilities ?? getCapabilities(),
          'clientInfo': {
            'name': 'AgentEngine',
            'version': '1.0.0',
          },
        },
      );
      
      if (initResponse.statusCode != 200) {
        throw MCPAdapterException(
          'HTTP initialization failed with status: ${initResponse.statusCode}',
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
      
      // Store session ID if provided
      _sessionId = data['sessionId'] ?? data['result']?['sessionId'];
      
      // Send initialized notification
      await _client!.post(
        '/mcp/initialized',
        data: {
          'sessionId': _sessionId,
        },
      );
      
      print('✅ HTTP MCP handshake completed');
      
    } catch (e) {
      throw MCPAdapterException(
        'HTTP handshake failed: $e',
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
        'HTTP adapter not connected',
        protocol: protocol,
      );
    }
    
    try {
      final requestId = const Uuid().v4();
      final requestData = {
        'jsonrpc': '2.0',
        'id': requestId,
        'method': method,
        'params': {
          ...params,
          if (_sessionId != null) 'sessionId': _sessionId,
        },
      };
      
      // Determine endpoint based on method
      final endpoint = _getEndpointForMethod(method);
      
      // Send request
      final response = await _client!.post(endpoint, data: requestData);
      
      if (response.statusCode != 200) {
        throw MCPAdapterException(
          'HTTP request failed with status: ${response.statusCode}',
          protocol: protocol,
        );
      }
      
      final responseData = response.data;
      
      // Handle JSON-RPC error responses
      if (responseData['error'] != null) {
        throw MCPAdapterException(
          'Server error: ${responseData['error']['message'] ?? 'Unknown error'}',
          protocol: protocol,
          errorCode: responseData['error']['code'],
        );
      }
      
      // Check if this is a long-running operation
      if (responseData['async'] == true) {
        return await _handleLongRunningOperation(
          responseData['operationId'],
          method,
        );
      }
      
      return responseData['result'] ?? responseData;
      
    } catch (e) {
      if (e is MCPAdapterException) rethrow;
      
      throw MCPAdapterException(
        'HTTP request failed: $e',
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
        'HTTP adapter not connected',
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
        'HTTP notification failed: $e',
        protocol: protocol,
        originalError: e,
      );
    }
  }
  
  /// Get HTTP endpoint for MCP method
  String _getEndpointForMethod(String method) {
    switch (method) {
      case 'initialize':
        return '/mcp/initialize';
      case 'initialized':
        return '/mcp/initialized';
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
  
  /// Handle long-running operations with polling
  Future<Map<String, dynamic>> _handleLongRunningOperation(
    String operationId,
    String originalMethod,
  ) async {
    final completer = Completer<Map<String, dynamic>>();
    
    // Set up polling timer
    final pollTimer = Timer.periodic(_pollInterval, (timer) async {
      try {
        final response = await _client!.get(
          '/mcp/operations/$operationId',
          queryParameters: {'sessionId': _sessionId},
        );
        
        final data = response.data;
        
        if (data['status'] == 'completed') {
          timer.cancel();
          _longRunningOperations.remove(operationId);
          completer.complete(data['result']);
        } else if (data['status'] == 'failed') {
          timer.cancel();
          _longRunningOperations.remove(operationId);
          completer.completeError(MCPAdapterException(
            'Long-running operation failed: ${data['error']}',
            protocol: protocol,
          ));
        }
        // Continue polling if status is 'running' or 'pending'
        
      } catch (e) {
        timer.cancel();
        _longRunningOperations.remove(operationId);
        completer.completeError(MCPAdapterException(
          'Error polling long-running operation: $e',
          protocol: protocol,
          originalError: e,
        ));
      }
    });
    
    _longRunningOperations[operationId] = pollTimer;
    
    // Set timeout for the entire operation
    Timer(_longPollTimeout, () {
      if (!completer.isCompleted) {
        pollTimer.cancel();
        _longRunningOperations.remove(operationId);
        completer.completeError(MCPAdapterException(
          'Long-running operation timed out',
          protocol: protocol,
        ));
      }
    });
    
    return await completer.future;
  }
  
  /// Start polling for server-sent notifications
  void _startPolling(MCPServerConfig config) {
    if (!config.enablePolling) return;
    
    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      if (!isConnected) {
        timer.cancel();
        return;
      }
      
      try {
        await _pollForUpdates();
      } catch (e) {
        print('❌ Polling error: $e');
      }
    });
  }
  
  /// Poll for server updates and notifications
  Future<void> _pollForUpdates() async {
    try {
      final response = await _client!.get(
        '/mcp/notifications',
        queryParameters: {
          'sessionId': _sessionId,
          'timeout': '5', // 5-second long poll
        },
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final notifications = response.data;
        
        if (notifications is List) {
          for (final notification in notifications) {
            handleNotification(notification);
          }
        } else if (notifications is Map<String, dynamic>) {
          handleNotification(notifications);
        }
      }
      
    } catch (e) {
      // Ignore timeout errors during polling
      if (e is DioException && e.type == DioExceptionType.receiveTimeout) {
        return;
      }
      rethrow;
    }
  }
  
  /// Create logging interceptor
  Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🌐 HTTP MCP Request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ HTTP MCP Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ HTTP MCP Error: ${error.response?.statusCode} ${error.requestOptions.path}');
        handler.next(error);
      },
    );
  }
  
  /// Create retry interceptor
  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            (error.response?.statusCode ?? 0) >= 500) {
          
          final requestOptions = error.requestOptions;
          final retryCount = requestOptions.extra['retryCount'] ?? 0;
          
          if (retryCount < 3) {
            requestOptions.extra['retryCount'] = retryCount + 1;
            
            // Wait before retry
            await Future.delayed(Duration(seconds: retryCount + 1));
            
            try {
              final response = await _client!.fetch(requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              // Continue with original error
            }
          }
        }
        
        handler.next(error);
      },
    );
  }
  
  /// Create session management interceptor
  Interceptor _createSessionInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add session ID to headers if available
        if (_sessionId != null) {
          options.headers['X-Session-ID'] = _sessionId;
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Update session ID if provided in response
        final newSessionId = response.headers.value('X-Session-ID') ??
                           response.data?['sessionId'];
        if (newSessionId != null) {
          _sessionId = newSessionId;
        }
        handler.next(response);
      },
    );
  }
  
  @override
  Future<MCPHealthStatus> getHealthStatus() async {
    final metrics = <String, dynamic>{
      'sessionId': _sessionId,
      'hasPolling': _pollTimer?.isActive == true,
      'longRunningOperations': _longRunningOperations.length,
    };
    
    // Test connection with ping
    bool isHealthy = isConnected;
    String? errorMessage;
    
    try {
      if (_client != null) {
        final response = await _client!.get(
          '/mcp/ping',
          queryParameters: {'sessionId': _sessionId},
        );
        isHealthy = response.statusCode == 200;
      }
    } catch (e) {
      isHealthy = false;
      errorMessage = 'Health check failed: $e';
    }
    
    return MCPHealthStatus(
      isHealthy: isHealthy,
      protocol: protocol,
      connectionId: connectionId,
      lastCheck: DateTime.now(),
      errorMessage: errorMessage,
      metrics: metrics,
    );
  }
  
  @override
  bool validateConfig(MCPServerConfig config) {
    if (!super.validateConfig(config)) return false;
    
    final uri = Uri.tryParse(config.url);
    if (uri == null) return false;
    
    final validSchemes = ['http', 'https'];
    return validSchemes.contains(uri.scheme);
  }
  
  @override
  Future<void> disconnect() async {
    print('🔌 Disconnecting HTTP MCP adapter');
    
    // Cancel polling
    _pollTimer?.cancel();
    _pollTimer = null;
    
    // Cancel all long-running operations
    for (final timer in _longRunningOperations.values) {
      timer.cancel();
    }
    _longRunningOperations.clear();
    
    // Send disconnect notification if session exists
    if (_sessionId != null && _client != null) {
      try {
        await _client!.post(
          '/mcp/disconnect',
          data: {'sessionId': _sessionId},
        );
      } catch (e) {
        print('❌ Error sending disconnect notification: $e');
      }
    }
    
    // Close HTTP client
    _client?.close();
    _client = null;
    _sessionId = null;
    
    await super.disconnect();
  }
  
  @override
  Future<void> dispose() async {
    await disconnect();
  }
}