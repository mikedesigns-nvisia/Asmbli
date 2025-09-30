import 'dart:async';
import 'package:meta/meta.dart';
import '../../models/mcp_server_config.dart';

/// Base class for all MCP protocol adapters
abstract class MCPAdapter {
  final StreamController<MCPEvent> _eventController = StreamController<MCPEvent>.broadcast();
  bool _isConnected = false;
  String? _connectionId;

  /// Protocol identifier (e.g., 'stdio', 'websocket', 'http', 'sse', 'grpc')
  String get protocol;

  /// Whether the adapter is currently connected
  bool get isConnected => _isConnected;

  /// Unique connection identifier
  String? get connectionId => _connectionId;

  /// Protected setter for connection state (for subclasses)
  @protected
  set isConnected(bool value) => _isConnected = value;

  /// Protected setter for connection ID (for subclasses)
  @protected
  set connectionId(String? value) => _connectionId = value;
  
  /// Stream of events from the MCP server
  Stream<MCPEvent> get eventStream => _eventController.stream;
  
  /// Connect to the MCP server using the provided configuration
  Future<void> connect(MCPServerConfig config);
  
  /// Disconnect from the MCP server
  Future<void> disconnect() async {
    _isConnected = false;
    _connectionId = null;
    await _eventController.close();
  }
  
  /// Send a request to the MCP server and await response
  Future<Map<String, dynamic>> sendRequest(
    String method,
    Map<String, dynamic> params,
  );
  
  /// Send a notification to the MCP server (no response expected)
  Future<void> sendNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    // Default implementation - can be overridden
    await sendRequest(method, params);
  }
  
  /// Handle incoming notifications from the server
  @protected
  void handleNotification(Map<String, dynamic> data) {
    final event = MCPEvent.fromJson(data);
    _eventController.add(event);
  }
  
  /// Get access to the event controller for subclasses
  @protected
  StreamController<MCPEvent> get eventController => _eventController;
  
  /// Mark the adapter as connected
  @protected
  void setConnected(String connectionId) {
    _isConnected = true;
    _connectionId = connectionId;
  }
  
  /// Get adapter capabilities
  Map<String, dynamic> getCapabilities() {
    return {
      'protocol': protocol,
      'version': '1.0',
      'features': getSupportedFeatures(),
    };
  }
  
  /// Get list of supported features for this adapter
  List<String> getSupportedFeatures() {
    return ['tools', 'resources', 'prompts'];
  }
  
  /// Validate server configuration for this adapter
  bool validateConfig(MCPServerConfig config) {
    return config.protocol == protocol && config.url.isNotEmpty;
  }
  
  /// Get connection health status
  Future<MCPHealthStatus> getHealthStatus() async {
    return MCPHealthStatus(
      isHealthy: _isConnected,
      protocol: protocol,
      connectionId: _connectionId,
      lastCheck: DateTime.now(),
    );
  }
  
  /// Dispose of adapter resources
  Future<void> dispose() async {
    await disconnect();
  }
}

/// MCP event types
enum MCPEventType {
  notification,
  toolCall,
  resourceUpdate,
  promptRequest,
  error,
  connectionStatus,
}

/// MCP event from server
class MCPEvent {
  final MCPEventType type;
  final String method;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? serverId;
  
  MCPEvent({
    required this.type,
    required this.method,
    required this.data,
    required this.timestamp,
    this.serverId,
  });
  
  factory MCPEvent.fromJson(Map<String, dynamic> json) {
    return MCPEvent(
      type: _parseEventType(json['type'] ?? json['method'] ?? 'notification'),
      method: json['method'] ?? 'unknown',
      data: json['params'] ?? json,
      timestamp: DateTime.now(),
      serverId: json['serverId'],
    );
  }
  
  static MCPEventType _parseEventType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'notification':
        return MCPEventType.notification;
      case 'tool_call':
      case 'toolcall':
        return MCPEventType.toolCall;
      case 'resource_update':
      case 'resourceupdate':
        return MCPEventType.resourceUpdate;
      case 'prompt_request':
      case 'promptrequest':
        return MCPEventType.promptRequest;
      case 'error':
        return MCPEventType.error;
      case 'connection_status':
      case 'connectionstatus':
        return MCPEventType.connectionStatus;
      default:
        return MCPEventType.notification;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'method': method,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'serverId': serverId,
    };
  }
}

/// MCP connection wrapper
class MCPConnection {
  final MCPAdapter adapter;
  final String version;
  final DateTime connectedAt;
  final Map<String, dynamic> serverInfo;
  
  MCPConnection(
    this.adapter,
    this.version, {
    this.serverInfo = const {},
  }) : connectedAt = DateTime.now();
  
  /// Send request through the adapter
  Future<Map<String, dynamic>> sendRequest(
    String method,
    Map<String, dynamic> params,
  ) async {
    return await adapter.sendRequest(method, params);
  }
  
  /// Send notification through the adapter
  Future<void> sendNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    await adapter.sendNotification(method, params);
  }
  
  /// Get connection status
  MCPConnectionStatus get status {
    return MCPConnectionStatus(
      isConnected: adapter.isConnected,
      protocol: adapter.protocol,
      version: version,
      connectedAt: connectedAt,
      connectionId: adapter.connectionId,
      serverInfo: serverInfo,
    );
  }
  
  /// Disconnect the connection
  Future<void> disconnect() async {
    await adapter.disconnect();
  }
}

/// MCP connection status
class MCPConnectionStatus {
  final bool isConnected;
  final String protocol;
  final String version;
  final DateTime connectedAt;
  final String? connectionId;
  final Map<String, dynamic> serverInfo;
  
  MCPConnectionStatus({
    required this.isConnected,
    required this.protocol,
    required this.version,
    required this.connectedAt,
    this.connectionId,
    this.serverInfo = const {},
  });
  
  Duration get uptime => DateTime.now().difference(connectedAt);
  
  Map<String, dynamic> toJson() {
    return {
      'isConnected': isConnected,
      'protocol': protocol,
      'version': version,
      'connectedAt': connectedAt.toIso8601String(),
      'connectionId': connectionId,
      'uptimeSeconds': uptime.inSeconds,
      'serverInfo': serverInfo,
    };
  }
}

/// MCP health status
class MCPHealthStatus {
  final bool isHealthy;
  final String protocol;
  final String? connectionId;
  final DateTime lastCheck;
  final String? errorMessage;
  final Map<String, dynamic> metrics;
  
  MCPHealthStatus({
    required this.isHealthy,
    required this.protocol,
    this.connectionId,
    required this.lastCheck,
    this.errorMessage,
    this.metrics = const {},
  });
  
  Map<String, dynamic> toJson() {
    return {
      'isHealthy': isHealthy,
      'protocol': protocol,
      'connectionId': connectionId,
      'lastCheck': lastCheck.toIso8601String(),
      'errorMessage': errorMessage,
      'metrics': metrics,
    };
  }
}

/// MCP adapter exception
class MCPAdapterException implements Exception {
  final String message;
  final String? protocol;
  final int? errorCode;
  final dynamic originalError;
  
  MCPAdapterException(
    this.message, {
    this.protocol,
    this.errorCode,
    this.originalError,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer('MCPAdapterException: $message');
    if (protocol != null) buffer.write(' (protocol: $protocol)');
    if (errorCode != null) buffer.write(' (code: $errorCode)');
    if (originalError != null) buffer.write(' (cause: $originalError)');
    return buffer.toString();
  }
}