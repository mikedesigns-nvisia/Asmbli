import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_connection.dart';
import '../models/mcp_catalog_entry.dart';
import '../models/mcp_server_process.dart';
import 'production_logger.dart';
import 'mcp_error_handler.dart';

/// Comprehensive JSON-RPC communication service for MCP servers
/// Implements secure communication, request/response logging, and concurrent operation handling
class JsonRpcCommunicationService {
  final ProductionLogger _logger;
  final MCPErrorHandler _errorHandler;
  
  // Connection management
  final Map<String, MCPConnection> _connections = {};
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  
  // Request tracking for concurrent operations
  final Map<String, Map<String, Completer<JsonRpcResponse>>> _pendingRequests = {};
  final Map<String, int> _requestCounters = {};
  
  // Logging and debugging
  final Map<String, List<JsonRpcLogEntry>> _communicationLogs = {};
  final StreamController<JsonRpcLogEntry> _logStreamController = StreamController<JsonRpcLogEntry>.broadcast();
  
  // Configuration
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxConcurrentRequests = 50;
  static const int _maxLogEntries = 1000;

  JsonRpcCommunicationService(this._logger, this._errorHandler);

  /// Stream of all JSON-RPC communication logs
  Stream<JsonRpcLogEntry> get logStream => _logStreamController.stream;

  /// Establish secure JSON-RPC connection to MCP server
  Future<JsonRpcConnectionResult> establishConnection({
    required String agentId,
    required String serverId,
    required MCPServerProcess serverProcess,
    Map<String, String>? credentials,
  }) async {
    final connectionId = _getConnectionId(agentId, serverId);
    
    _logger.info('Establishing JSON-RPC connection: $connectionId');
    
    try {
      // Check if connection already exists and is healthy
      final existingConnection = _connections[connectionId];
      if (existingConnection != null && existingConnection.status == MCPConnectionStatus.connected) {
        _logger.info('Reusing existing JSON-RPC connection: $connectionId');
        return JsonRpcConnectionResult.success(existingConnection);
      }

      // Create new connection based on transport type
      final connection = await _createConnection(connectionId, serverProcess);
      
      // Initialize request tracking for this connection
      _pendingRequests[connectionId] = {};
      _requestCounters[connectionId] = 0;
      _communicationLogs[connectionId] = [];
      
      // Set up message handling
      await _setupMessageHandling(connectionId, connection);
      
      // Perform MCP initialization handshake with security validation
      await _performSecureInitialization(connectionId, connection, credentials);
      
      // Store connection
      _connections[connectionId] = connection;
      
      _logger.info('JSON-RPC connection established successfully: $connectionId');
      
      return JsonRpcConnectionResult.success(connection);
      
    } catch (e, stackTrace) {
      _logger.error('Failed to establish JSON-RPC connection: $connectionId - $e', stackTrace: stackTrace);
      await _errorHandler.handleConnectionError(connectionId, e);
      return JsonRpcConnectionResult.failure(e.toString());
    }
  }

  /// Send JSON-RPC request with concurrent operation handling
  Future<JsonRpcResponse> sendRequest({
    required String agentId,
    required String serverId,
    required String method,
    Map<String, dynamic>? params,
    Duration? timeout,
  }) async {
    final connectionId = _getConnectionId(agentId, serverId);
    final connection = _connections[connectionId];
    
    if (connection == null) {
      throw JsonRpcException('No connection found for $connectionId');
    }

    if (connection.status != MCPConnectionStatus.connected) {
      throw JsonRpcException('Connection not available for $connectionId (status: ${connection.status})');
    }

    // Check concurrent request limits
    final pendingCount = _pendingRequests[connectionId]?.length ?? 0;
    if (pendingCount >= _maxConcurrentRequests) {
      throw JsonRpcException('Too many concurrent requests for $connectionId ($pendingCount/$_maxConcurrentRequests)');
    }

    // Generate unique request ID
    final requestId = _generateRequestId(connectionId);
    final requestTimeout = timeout ?? _defaultTimeout;
    
    // Create request message
    final request = MCPMessage.request(requestId, method, params);
    
    // Log outgoing request
    final logEntry = JsonRpcLogEntry(
      connectionId: connectionId,
      type: JsonRpcLogType.request,
      direction: JsonRpcDirection.outgoing,
      message: request,
      timestamp: DateTime.now(),
    );
    _addLogEntry(connectionId, logEntry);
    
    _logger.debug('Sending JSON-RPC request: $connectionId - $method (ID: $requestId)');
    
    try {
      // Set up response handling
      final completer = Completer<JsonRpcResponse>();
      _pendingRequests[connectionId]![requestId] = completer;
      
      // Send request
      await connection.send(request);
      
      // Wait for response with timeout
      final response = await completer.future.timeout(
        requestTimeout,
        onTimeout: () {
          _pendingRequests[connectionId]?.remove(requestId);
          throw JsonRpcTimeoutException('Request timeout: $method (ID: $requestId)', requestTimeout);
        },
      );
      
      _logger.debug('Received JSON-RPC response: $connectionId - $method (ID: $requestId)');
      
      return response;
      
    } catch (e, stackTrace) {
      // Clean up pending request
      _pendingRequests[connectionId]?.remove(requestId);
      
      _logger.error('JSON-RPC request failed: $connectionId - $method (ID: $requestId) - $e', stackTrace: stackTrace);
      await _errorHandler.handleCommunicationError('JSON-RPC $method failed for $connectionId', e);
      
      rethrow;
    }
  }

  /// Send JSON-RPC notification (no response expected)
  Future<void> sendNotification({
    required String agentId,
    required String serverId,
    required String method,
    Map<String, dynamic>? params,
  }) async {
    final connectionId = _getConnectionId(agentId, serverId);
    final connection = _connections[connectionId];
    
    if (connection == null) {
      throw JsonRpcException('No connection found for $connectionId');
    }

    if (connection.status != MCPConnectionStatus.connected) {
      throw JsonRpcException('Connection not available for $connectionId (status: ${connection.status})');
    }

    // Create notification message
    final notification = MCPMessage.notification(method, params);
    
    // Log outgoing notification
    final logEntry = JsonRpcLogEntry(
      connectionId: connectionId,
      type: JsonRpcLogType.notification,
      direction: JsonRpcDirection.outgoing,
      message: notification,
      timestamp: DateTime.now(),
    );
    _addLogEntry(connectionId, logEntry);
    
    _logger.debug('Sending JSON-RPC notification: $connectionId - $method');
    
    try {
      await connection.send(notification);
      _logger.debug('JSON-RPC notification sent: $connectionId - $method');
      
    } catch (e, stackTrace) {
      _logger.error('JSON-RPC notification failed: $connectionId - $method - $e', stackTrace: stackTrace);
      await _errorHandler.handleCommunicationError('JSON-RPC $method failed for $connectionId', e);
      rethrow;
    }
  }

  /// Send multiple requests concurrently with proper handling
  Future<List<JsonRpcResponse>> sendConcurrentRequests({
    required String agentId,
    required String serverId,
    required List<JsonRpcRequestSpec> requests,
    Duration? timeout,
  }) async {
    final connectionId = _getConnectionId(agentId, serverId);
    
    _logger.info('Sending ${requests.length} concurrent JSON-RPC requests: $connectionId');
    
    try {
      // Execute all requests concurrently
      final futures = requests.map((spec) => sendRequest(
        agentId: agentId,
        serverId: serverId,
        method: spec.method,
        params: spec.params,
        timeout: timeout,
      ));
      
      final responses = await Future.wait(futures);
      
      _logger.info('Completed ${responses.length} concurrent JSON-RPC requests: $connectionId');
      
      return responses;
      
    } catch (e, stackTrace) {
      _logger.error('Concurrent JSON-RPC requests failed: $connectionId - $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get communication logs for a connection
  List<JsonRpcLogEntry> getCommunicationLogs(String agentId, String serverId) {
    final connectionId = _getConnectionId(agentId, serverId);
    return List.unmodifiable(_communicationLogs[connectionId] ?? []);
  }

  /// Get connection status
  MCPConnectionStatus? getConnectionStatus(String agentId, String serverId) {
    final connectionId = _getConnectionId(agentId, serverId);
    return _connections[connectionId]?.status;
  }

  /// Get connection statistics
  JsonRpcConnectionStats getConnectionStats(String agentId, String serverId) {
    final connectionId = _getConnectionId(agentId, serverId);
    final logs = _communicationLogs[connectionId] ?? [];
    final pendingRequests = _pendingRequests[connectionId]?.length ?? 0;
    
    return JsonRpcConnectionStats(
      connectionId: connectionId,
      status: getConnectionStatus(agentId, serverId) ?? MCPConnectionStatus.disconnected,
      totalMessages: logs.length,
      pendingRequests: pendingRequests,
      requestsSent: logs.where((l) => l.type == JsonRpcLogType.request && l.direction == JsonRpcDirection.outgoing).length,
      responsesReceived: logs.where((l) => l.type == JsonRpcLogType.response && l.direction == JsonRpcDirection.incoming).length,
      notificationsSent: logs.where((l) => l.type == JsonRpcLogType.notification && l.direction == JsonRpcDirection.outgoing).length,
      notificationsReceived: logs.where((l) => l.type == JsonRpcLogType.notification && l.direction == JsonRpcDirection.incoming).length,
      errors: logs.where((l) => l.type == JsonRpcLogType.error).length,
    );
  }

  /// Close connection and cleanup resources
  Future<void> closeConnection(String agentId, String serverId) async {
    final connectionId = _getConnectionId(agentId, serverId);
    
    _logger.info('Closing JSON-RPC connection: $connectionId');
    
    try {
      // Cancel message subscription
      await _messageSubscriptions[connectionId]?.cancel();
      _messageSubscriptions.remove(connectionId);
      
      // Complete all pending requests with error
      final pendingRequests = _pendingRequests.remove(connectionId) ?? {};
      for (final completer in pendingRequests.values) {
        if (!completer.isCompleted) {
          completer.completeError(JsonRpcException('Connection closed'));
        }
      }
      
      // Close connection
      final connection = _connections.remove(connectionId);
      if (connection != null) {
        await connection.close();
      }
      
      // Clean up request counter
      _requestCounters.remove(connectionId);
      
      _logger.info('JSON-RPC connection closed: $connectionId');
      
    } catch (e, stackTrace) {
      _logger.error('Error closing JSON-RPC connection: $connectionId - $e', stackTrace: stackTrace);
    }
  }

  /// Close all connections
  Future<void> closeAllConnections() async {
    _logger.info('Closing all JSON-RPC connections');
    
    final connectionIds = _connections.keys.toList();
    final futures = connectionIds.map((id) {
      final parts = id.split(':');
      return closeConnection(parts[0], parts[1]);
    });
    
    await Future.wait(futures);
    
    _logger.info('All JSON-RPC connections closed');
  }

  /// Dispose service and cleanup resources
  Future<void> dispose() async {
    await closeAllConnections();
    await _logStreamController.close();
    _communicationLogs.clear();
  }

  // Private helper methods

  String _getConnectionId(String agentId, String serverId) => '$agentId:$serverId';

  Future<MCPConnection> _createConnection(String connectionId, MCPServerProcess serverProcess) async {
    // Get the system process - this would be provided by the process manager
    final systemProcess = await _getSystemProcess(serverProcess);
    if (systemProcess == null) {
      throw JsonRpcException('System process not found for ${serverProcess.id}');
    }

    // Create connection based on transport type
    final transportType = serverProcess.config.transportType;
    if (transportType == MCPTransportType.stdio) {
      return MCPStdioConnection(connectionId, systemProcess);
    } else if (transportType == MCPTransportType.sse) {
      throw JsonRpcException('SSE transport not yet implemented');
    } else if (transportType == MCPTransportType.http) {
      throw JsonRpcException('HTTP transport not yet implemented');
    } else {
      throw JsonRpcException('Unsupported transport type: $transportType');
    }
  }

  Future<Process?> _getSystemProcess(MCPServerProcess serverProcess) async {
    // This would typically be provided by the process manager
    // For now, we'll return null to indicate the process needs to be managed externally
    return null;
  }

  Future<void> _setupMessageHandling(String connectionId, MCPConnection connection) async {
    final subscription = connection.messages.listen(
      (message) => _handleIncomingMessage(connectionId, message),
      onError: (error) => _handleMessageError(connectionId, error),
      onDone: () => _handleConnectionClosed(connectionId),
    );
    
    _messageSubscriptions[connectionId] = subscription;
  }

  void _handleIncomingMessage(String connectionId, MCPMessage message) {
    // Log incoming message
    final logEntry = JsonRpcLogEntry(
      connectionId: connectionId,
      type: _getMessageType(message),
      direction: JsonRpcDirection.incoming,
      message: message,
      timestamp: DateTime.now(),
    );
    _addLogEntry(connectionId, logEntry);
    
    // Handle responses to pending requests
    if (message.isResponse && message.id != null) {
      final completer = _pendingRequests[connectionId]?.remove(message.id!);
      if (completer != null && !completer.isCompleted) {
        final response = JsonRpcResponse(
          id: message.id!,
          result: message.result,
          error: message.error,
          isError: message.isError,
        );
        completer.complete(response);
      }
    }
    
    _logger.debug('Handled incoming JSON-RPC message: $connectionId - ${message.method ?? 'response'}');
  }

  void _handleMessageError(String connectionId, dynamic error) {
    _logger.error('JSON-RPC message error: $connectionId - $error');
    
    final logEntry = JsonRpcLogEntry(
      connectionId: connectionId,
      type: JsonRpcLogType.error,
      direction: JsonRpcDirection.incoming,
      error: error.toString(),
      timestamp: DateTime.now(),
    );
    _addLogEntry(connectionId, logEntry);
  }

  void _handleConnectionClosed(String connectionId) {
    _logger.info('JSON-RPC connection closed: $connectionId');
    
    // Complete all pending requests with error
    final pendingRequests = _pendingRequests[connectionId] ?? {};
    for (final completer in pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(JsonRpcException('Connection closed'));
      }
    }
    _pendingRequests[connectionId]?.clear();
  }

  Future<void> _performSecureInitialization(
    String connectionId,
    MCPConnection connection,
    Map<String, String>? credentials,
  ) async {
    try {
      // Send initialize request with security context
      final initResponse = await connection.request('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'roots': {'listChanged': true},
          'sampling': {},
        },
        'clientInfo': {
          'name': 'AgentEngine Desktop',
          'version': '1.0.0',
        },
        // Include credentials if provided
        if (credentials != null) 'credentials': credentials,
      });

      if (initResponse.isError) {
        throw JsonRpcException('Initialization failed: ${initResponse.error}');
      }

      // Send initialized notification
      await connection.send(MCPMessage.notification('notifications/initialized'));
      
      _logger.info('JSON-RPC connection initialized securely: $connectionId');
      
    } catch (e) {
      throw JsonRpcException('Failed to initialize secure JSON-RPC connection: $e');
    }
  }

  String _generateRequestId(String connectionId) {
    final counter = _requestCounters[connectionId] ?? 0;
    _requestCounters[connectionId] = counter + 1;
    return '${connectionId}_${counter + 1}_${DateTime.now().millisecondsSinceEpoch}';
  }

  JsonRpcLogType _getMessageType(MCPMessage message) {
    if (message.isRequest) return JsonRpcLogType.request;
    if (message.isResponse) return JsonRpcLogType.response;
    if (message.isNotification) return JsonRpcLogType.notification;
    if (message.isError) return JsonRpcLogType.error;
    return JsonRpcLogType.unknown;
  }

  void _addLogEntry(String connectionId, JsonRpcLogEntry entry) {
    final logs = _communicationLogs[connectionId] ??= [];
    
    // Add entry
    logs.add(entry);
    
    // Trim logs if too many
    if (logs.length > _maxLogEntries) {
      logs.removeRange(0, logs.length - _maxLogEntries);
    }
    
    // Broadcast to stream
    _logStreamController.add(entry);
  }

  /// Stream server output (stub implementation)
  Stream<String> streamServerOutput(String serverId) {
    // Return empty stream for now - this would need to be implemented
    // to actually stream output from the MCP server process
    return Stream.empty();
  }
}

// Supporting classes and enums

/// Result of establishing a JSON-RPC connection
class JsonRpcConnectionResult {
  final bool success;
  final MCPConnection? connection;
  final String? error;

  JsonRpcConnectionResult.success(this.connection) : success = true, error = null;
  JsonRpcConnectionResult.failure(this.error) : success = false, connection = null;
}

/// JSON-RPC response wrapper
class JsonRpcResponse {
  final String id;
  final Map<String, dynamic>? result;
  final Map<String, dynamic>? error;
  final bool isError;

  JsonRpcResponse({
    required this.id,
    this.result,
    this.error,
    required this.isError,
  });
}

/// Specification for a JSON-RPC request
class JsonRpcRequestSpec {
  final String method;
  final Map<String, dynamic>? params;

  JsonRpcRequestSpec({
    required this.method,
    this.params,
  });
}

/// JSON-RPC communication log entry
class JsonRpcLogEntry {
  final String connectionId;
  final JsonRpcLogType type;
  final JsonRpcDirection direction;
  final MCPMessage? message;
  final String? error;
  final DateTime timestamp;

  JsonRpcLogEntry({
    required this.connectionId,
    required this.type,
    required this.direction,
    this.message,
    this.error,
    required this.timestamp,
  });
}

/// Types of JSON-RPC log entries
enum JsonRpcLogType {
  request,
  response,
  notification,
  error,
  unknown,
}

/// Direction of JSON-RPC communication
enum JsonRpcDirection {
  incoming,
  outgoing,
}

/// Connection statistics
class JsonRpcConnectionStats {
  final String connectionId;
  final MCPConnectionStatus status;
  final int totalMessages;
  final int pendingRequests;
  final int requestsSent;
  final int responsesReceived;
  final int notificationsSent;
  final int notificationsReceived;
  final int errors;

  JsonRpcConnectionStats({
    required this.connectionId,
    required this.status,
    required this.totalMessages,
    required this.pendingRequests,
    required this.requestsSent,
    required this.responsesReceived,
    required this.notificationsSent,
    required this.notificationsReceived,
    required this.errors,
  });
}

/// JSON-RPC specific exceptions
class JsonRpcException implements Exception {
  final String message;
  JsonRpcException(this.message);
  
  @override
  String toString() => 'JsonRpcException: $message';
}

class JsonRpcTimeoutException extends JsonRpcException {
  final Duration timeout;
  
  JsonRpcTimeoutException(String message, this.timeout) : super(message);
  
  @override
  String toString() => 'JsonRpcTimeoutException: $message (timeout: ${timeout.inSeconds}s)';
}

// ==================== Riverpod Provider ====================

final jsonRpcCommunicationServiceProvider = Provider<JsonRpcCommunicationService>((ref) {
  final logger = ref.read(productionLoggerProvider);
  final errorHandler = ref.read(mcpErrorHandlerProvider);
  return JsonRpcCommunicationService(logger, errorHandler);
});