import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_connection.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_catalog_entry.dart';
import 'mcp_error_handler.dart';
import 'json_rpc_communication_service.dart';

/// Handles MCP protocol communication and connection management
/// Enhanced with JSON-RPC communication service for secure, logged, and concurrent operations
@Deprecated('Use MCPProtocolService instead. Will be consolidated in v2.0. See docs/SERVICE_CONSOLIDATION_PLAN.md')
class MCPProtocolHandler {
  final MCPErrorHandler _errorHandler;
  final JsonRpcCommunicationService _jsonRpcService;
  final Map<String, MCPConnection> _connections = {};

  MCPProtocolHandler(this._errorHandler, this._jsonRpcService);

  /// Establish MCP connection to a server process using JSON-RPC communication service
  Future<MCPConnection> establishConnection(
    MCPServerProcess serverProcess, {
    Map<String, String>? credentials,
  }) async {
    final connectionId = '${serverProcess.agentId}:${serverProcess.serverId}';
    
    // Check if connection already exists
    final existingConnection = _connections[connectionId];
    if (existingConnection != null && existingConnection.status == MCPConnectionStatus.connected) {
      return existingConnection;
    }

    try {
      // Use JSON-RPC communication service for secure connection establishment
      final result = await _jsonRpcService.establishConnection(
        agentId: serverProcess.agentId,
        serverId: serverProcess.serverId,
        serverProcess: serverProcess,
        credentials: credentials,
      );
      
      if (!result.success || result.connection == null) {
        throw MCPProtocolException('Failed to establish connection: ${result.error}');
      }
      
      final connection = result.connection!;
      _connections[connectionId] = connection;
      
      return connection;
    } catch (e) {
      await _errorHandler.handleConnectionError(serverProcess.id, e);
      rethrow;
    }
  }

  /// Send multiple requests concurrently with proper handling
  Future<List<dynamic>> sendConcurrentRequests(
    String agentId,
    String serverId,
    List<JsonRpcRequestSpec> requests, {
    Duration? timeout,
  }) async {
    try {
      final responses = await _jsonRpcService.sendConcurrentRequests(
        agentId: agentId,
        serverId: serverId,
        requests: requests,
        timeout: timeout,
      );
      
      // Extract results and handle errors
      final results = <dynamic>[];
      for (final response in responses) {
        if (response.isError) {
          throw MCPProtocolException('Concurrent request failed: ${response.error}');
        }
        results.add(response.result);
      }
      
      return results;
    } catch (e) {
      await _errorHandler.handleCommunicationError('Concurrent requests failed for $agentId:$serverId', e);
      rethrow;
    }
  }

  /// Get communication logs for debugging
  List<JsonRpcLogEntry> getCommunicationLogs(String agentId, String serverId) {
    return _jsonRpcService.getCommunicationLogs(agentId, serverId);
  }

  /// Get connection statistics
  JsonRpcConnectionStats getConnectionStats(String agentId, String serverId) {
    return _jsonRpcService.getConnectionStats(agentId, serverId);
  }

  /// Stream of communication logs for real-time monitoring
  Stream<JsonRpcLogEntry> get logStream => _jsonRpcService.logStream;

  /// Send request to MCP server using JSON-RPC communication service
  Future<dynamic> sendRequest(
    String agentId,
    String serverId,
    String method,
    Map<String, dynamic>? params, {
    Duration? timeout,
  }) async {
    try {
      final response = await _jsonRpcService.sendRequest(
        agentId: agentId,
        serverId: serverId,
        method: method,
        params: params,
        timeout: timeout,
      );
      
      if (response.isError) {
        throw MCPProtocolException('MCP request failed: ${response.error}');
      }
      
      return response.result;
    } catch (e) {
      await _errorHandler.handleCommunicationError('Request failed for $agentId:$serverId method: $method', e);
      rethrow;
    }
  }

  /// Send notification to MCP server using JSON-RPC communication service
  Future<void> sendNotification(
    String agentId,
    String serverId,
    String method,
    Map<String, dynamic>? params,
  ) async {
    try {
      await _jsonRpcService.sendNotification(
        agentId: agentId,
        serverId: serverId,
        method: method,
        params: params,
      );
    } catch (e) {
      await _errorHandler.handleCommunicationError('Request failed for $agentId:$serverId method: $method', e);
      rethrow;
    }
  }

  /// Close connection to MCP server using JSON-RPC communication service
  Future<void> closeConnection(String agentId, String serverId) async {
    final connectionId = '$agentId:$serverId';
    
    // Remove from local tracking
    _connections.remove(connectionId);
    
    // Use JSON-RPC service for proper cleanup
    await _jsonRpcService.closeConnection(agentId, serverId);
  }

  /// Get connection status using JSON-RPC communication service
  MCPConnectionStatus? getConnectionStatus(String agentId, String serverId) {
    return _jsonRpcService.getConnectionStatus(agentId, serverId);
  }

  /// Get all active connections
  Map<String, MCPConnectionStatus> getAllConnectionStatuses() {
    return _connections.map((key, connection) => MapEntry(key, connection.status));
  }

  /// Close all connections using JSON-RPC communication service
  Future<void> closeAllConnections() async {
    _connections.clear();
    await _jsonRpcService.closeAllConnections();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await closeAllConnections();
    await _jsonRpcService.dispose();
  }
}

/// MCP protocol exception
class MCPProtocolException implements Exception {
  final String message;
  MCPProtocolException(this.message);

  @override
  String toString() => 'MCPProtocolException: $message';
}

// ==================== Riverpod Provider ====================

final mcpProtocolHandlerProvider = Provider<MCPProtocolHandler>((ref) {
  final errorHandler = ref.read(mcpErrorHandlerProvider);
  final jsonRpcService = ref.read(jsonRpcCommunicationServiceProvider);
  return MCPProtocolHandler(errorHandler, jsonRpcService);
});