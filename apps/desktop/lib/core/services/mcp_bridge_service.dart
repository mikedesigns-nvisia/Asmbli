import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mcp_settings_service.dart';
import 'integration_health_monitoring_service.dart';

/// Bridge service that connects Flutter to the TypeScript MCP core
/// Handles message processing with MCP server integration
class MCPBridgeService {
  static const MethodChannel _methodChannel = MethodChannel('agentengine.mcp');
  static const EventChannel _eventChannel = EventChannel('agentengine.mcp.events');
  
  final MCPSettingsService _settingsService;
  final IntegrationHealthMonitoringService? _healthService;
  StreamSubscription? _eventSubscription;
  
  // Internal state
  bool _isInitialized = false;
  final Map<String, StreamController<String>> _responseStreams = {};
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};

  MCPBridgeService(this._settingsService, [this._healthService]);

  /// Initialize the MCP bridge
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the native/JS MCP manager
      final config = await _buildMCPConfig();
      await _methodChannel.invokeMethod('initialize', config);
      
      // Set up event listening for streaming responses
      _setupEventListening();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('MCP Bridge Service initialization failed: $e');
      throw MCPBridgeException('Failed to initialize MCP bridge: $e');
    }
  }

  /// Process a message through the MCP system
  Future<MCPResponse> processMessage({
    required String conversationId,
    required String message,
    required List<String> enabledServerIds,
    Map<String, dynamic>? conversationMetadata,
  }) async {
    if (!_isInitialized) {
      throw const MCPBridgeException('MCP bridge not initialized');
    }

    try {
      final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
      final completer = Completer<Map<String, dynamic>>();
      _pendingRequests[requestId] = completer;

      // Prepare request data
      final requestData = {
        'requestId': requestId,
        'conversationId': conversationId,
        'message': message,
        'enabledServerIds': enabledServerIds,
        'metadata': conversationMetadata ?? {},
        'serverConfigs': await _getServerConfigs(enabledServerIds),
        'contextDocuments': (conversationMetadata?['contextDocuments'] as List<dynamic>?)?.cast<String>() ?? _settingsService.globalContextDocuments,
      };

      // Send to native/JS layer
      await _methodChannel.invokeMethod('processMessage', requestData);

      // Wait for response
      final response = await completer.future;
      
      // Update health monitoring for used servers after successful processing
      if (_healthService != null && response['success'] == true) {
        for (final serverId in enabledServerIds) {
          _healthService!.forceHealthCheck(serverId).catchError((e) {
            debugPrint('Health check failed for $serverId: $e');
          });
        }
      }
      
      return MCPResponse.fromJson(response);
    } catch (e) {
      debugPrint('MCP Bridge error: $e');
      throw MCPBridgeException('Failed to process message: $e');
    }
  }

  /// Stream a message response through MCP
  Stream<String> streamMessage({
    required String conversationId,
    required String message,
    required List<String> enabledServerIds,
    Map<String, dynamic>? conversationMetadata,
  }) async* {
    if (!_isInitialized) {
      throw const MCPBridgeException('MCP bridge not initialized');
    }

    final streamId = 'stream_${DateTime.now().millisecondsSinceEpoch}';
    final controller = StreamController<String>();
    _responseStreams[streamId] = controller;

    try {
      // Prepare request data
      final requestData = {
        'streamId': streamId,
        'conversationId': conversationId,
        'message': message,
        'enabledServerIds': enabledServerIds,
        'metadata': conversationMetadata ?? {},
        'serverConfigs': await _getServerConfigs(enabledServerIds),
        'contextDocuments': (conversationMetadata?['contextDocuments'] as List<dynamic>?)?.cast<String>() ?? _settingsService.globalContextDocuments,
      };

      // Start streaming
      await _methodChannel.invokeMethod('streamMessage', requestData);

      // Yield from the stream
      await for (final chunk in controller.stream) {
        yield chunk;
      }
    } catch (e) {
      yield* Stream.error(MCPBridgeException('Failed to stream message: $e'));
    } finally {
      _responseStreams.remove(streamId);
      controller.close();
    }
  }

  /// Test connection to MCP server (alias for health monitoring)
  Future<MCPServerConnectionResult> testConnection(String serverId) async {
    return await testServerConnection(serverId);
  }

  /// Reinitialize a specific MCP server connection
  Future<void> reinitializeServer(String serverId) async {
    if (!_isInitialized) {
      throw const MCPBridgeException('MCP bridge not initialized');
    }

    try {
      final serverConfig = _settingsService.getMCPServer(serverId);
      if (serverConfig == null) {
        throw MCPBridgeException('Server configuration not found: $serverId');
      }

      await _methodChannel.invokeMethod('reinitializeServer', {
        'serverId': serverId,
        'config': serverConfig.toJson(),
      });

    } catch (e) {
      throw MCPBridgeException('Failed to reinitialize server $serverId: $e');
    }
  }

  /// Test connection to MCP server
  Future<MCPServerConnectionResult> testServerConnection(String serverId) async {
    if (!_isInitialized) {
      throw const MCPBridgeException('MCP bridge not initialized');
    }

    try {
      final serverConfig = _settingsService.getMCPServer(serverId);
      if (serverConfig == null) {
        return MCPServerConnectionResult(
          serverId: serverId,
          isConnected: false,
          error: 'Server configuration not found',
          latency: 0,
        );
      }

      final startTime = DateTime.now();
      final result = await _methodChannel.invokeMethod('testConnection', {
        'serverId': serverId,
        'config': serverConfig.toJson(),
      });

      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds;

      return MCPServerConnectionResult(
        serverId: serverId,
        isConnected: result['connected'] as bool? ?? false,
        error: result['error'] as String?,
        latency: latency,
        metadata: result['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return MCPServerConnectionResult(
        serverId: serverId,
        isConnected: false,
        error: 'Connection test failed: $e',
        latency: 0,
      );
    }
  }

  /// Inject context documents into MCP session
  Future<void> injectContext({
    required String conversationId,
    required List<ContextDocument> documents,
  }) async {
    if (!_isInitialized) {
      throw const MCPBridgeException('MCP bridge not initialized');
    }

    try {
      final contextData = {
        'conversationId': conversationId,
        'documents': documents.map((doc) => doc.toJson()).toList(),
      };

      await _methodChannel.invokeMethod('injectContext', contextData);
    } catch (e) {
      throw MCPBridgeException('Failed to inject context: $e');
    }
  }

  /// Get MCP server capabilities
  Future<Map<String, MCPServerCapabilities>> getServerCapabilities(
    List<String> serverIds,
  ) async {
    if (!_isInitialized) {
      throw const MCPBridgeException('MCP bridge not initialized');
    }

    try {
      final result = await _methodChannel.invokeMethod('getCapabilities', {
        'serverIds': serverIds,
        'serverConfigs': await _getServerConfigs(serverIds),
      });

      final capabilities = <String, MCPServerCapabilities>{};
      for (final entry in (result as Map<String, dynamic>).entries) {
        capabilities[entry.key] = MCPServerCapabilities.fromJson(entry.value);
      }

      return capabilities;
    } catch (e) {
      throw MCPBridgeException('Failed to get server capabilities: $e');
    }
  }

  /// Dispose of the bridge service
  void dispose() {
    _eventSubscription?.cancel();
    
    for (final controller in _responseStreams.values) {
      controller.close();
    }
    _responseStreams.clear();
    
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(const MCPBridgeException('Service disposed'));
      }
    }
    _pendingRequests.clear();
    
    if (_isInitialized) {
      _methodChannel.invokeMethod('dispose').catchError((_) {});
      _isInitialized = false;
    }
  }

  // ==================== Private Methods ====================

  Future<Map<String, dynamic>> _buildMCPConfig() async {
    final allServers = _settingsService.allMCPServers;
    final enabledServers = <String, dynamic>{};
    
    // Convert server configs to the format expected by the JavaScript bridge
    for (final entry in allServers.entries.where((e) => e.value.enabled)) {
      final server = entry.value;
      enabledServers[server.id] = {
        'command': server.command,
        'args': server.args,
        'env': server.env ?? {},
        'cwd': server.workingDirectory,
        'name': server.name,
        'type': server.type,
        'enabled': server.enabled,
      };
    }

    return {
      'mcpServers': enabledServers, // Changed from 'servers' to match JS bridge format
      'globalConfig': {
        'globalTimeout': 30000,
        'maxConcurrentConnections': 5,
        'retryAttempts': 3,
        'isDesktop': true,
        'globalContext': _settingsService.globalContextDocuments,
      }
    };
  }

  Future<Map<String, dynamic>> _getServerConfigs(List<String> serverIds) async {
    final configs = <String, dynamic>{};
    
    for (final serverId in serverIds) {
      final serverConfig = _settingsService.getMCPServer(serverId);
      if (serverConfig != null) {
        configs[serverId] = serverConfig.toJson();
      }
    }
    
    return configs;
  }

  void _setupEventListening() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) => _handleEvent(event as Map<String, dynamic>),
      onError: (error) => debugPrint('MCP Bridge event error: $error'),
    );
  }

  void _handleEvent(Map<String, dynamic> event) {
    try {
      final type = event['type'] as String?;
      final data = event['data'] as Map<String, dynamic>?;

      if (type == null || data == null) return;

    switch (type) {
      case 'messageResponse':
        final requestId = data['requestId'] as String?;
        if (requestId != null && _pendingRequests.containsKey(requestId)) {
          _pendingRequests[requestId]!.complete(data);
          _pendingRequests.remove(requestId);
        }
        break;

      case 'streamChunk':
        final streamId = data['streamId'] as String?;
        final chunk = data['chunk'] as String?;
        if (streamId != null && chunk != null && _responseStreams.containsKey(streamId)) {
          _responseStreams[streamId]!.add(chunk);
        }
        break;

      case 'streamEnd':
        final streamId = data['streamId'] as String?;
        if (streamId != null && _responseStreams.containsKey(streamId)) {
          _responseStreams[streamId]!.close();
          _responseStreams.remove(streamId);
        }
        break;

      case 'streamError':
        final streamId = data['streamId'] as String?;
        final error = data['error'] as String? ?? 'Unknown error';
        if (streamId != null && _responseStreams.containsKey(streamId)) {
          _responseStreams[streamId]!.addError(MCPBridgeException(error));
          _responseStreams[streamId]!.close();
          _responseStreams.remove(streamId);
        }
        break;

      default:
        debugPrint('Unknown MCP bridge event type: $type');
    }
    } catch (e) {
      debugPrint('MCP response error: $e');
    }
  }

  /// Get capabilities for servers (business service compatibility)
  Future<Map<String, dynamic>> getCapabilitiesForServers(List<String> serverIds) async {
    final capabilities = <String, dynamic>{};
    for (final serverId in serverIds) {
      try {
        final serverCapsMap = await getServerCapabilities([serverId]);
        final serverCaps = serverCapsMap[serverId];
        capabilities[serverId] = serverCaps?.toJson() ?? {'error': 'No capabilities found'};
      } catch (e) {
        capabilities[serverId] = {'error': e.toString()};
      }
    }
    return capabilities;
  }

  /// Call tool on MCP server (business service compatibility)
  Future<Map<String, dynamic>> callTool(String toolName, Map<String, dynamic> params, {String? serverId}) async {
    try {
      return await _methodChannel.invokeMethod('callTool', {
        'toolName': toolName,
        'params': params,
        'serverId': serverId,
      });
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Check if server is configured (business service compatibility)
  Future<bool> isServerConfigured(String serverId) async {
    try {
      final result = await testServerConnection(serverId);
      return result.isConnected;
    } catch (e) {
      return false;
    }
  }

  /// Configure server for agent (business service compatibility)
  Future<void> configureServerForAgent(String agentId, String serverId) async {
    // Placeholder implementation
  }

  /// Start server (business service compatibility)
  Future<void> startServer(String serverId) async {
    // Placeholder implementation
  }

  /// Stop server for agent (business service compatibility)
  Future<void> stopServerForAgent(String agentId, String serverId) async {
    // Placeholder implementation
  }
}

// ==================== Data Models ====================

/// MCP response from processed message
class MCPResponse {
  final String response;
  final List<String> usedServers;
  final Map<String, dynamic> metadata;
  final int? latency;
  final bool success;

  const MCPResponse({
    required this.response,
    required this.usedServers,
    required this.metadata,
    this.latency,
    this.success = true,
  });

  factory MCPResponse.fromJson(Map<String, dynamic> json) {
    return MCPResponse(
      response: json['response'] as String,
      usedServers: List<String>.from(json['usedServers'] as List),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      latency: json['latency'] as int?,
      success: json['success'] as bool? ?? true,
    );
  }
}

/// MCP server connection test result
class MCPServerConnectionResult {
  final String serverId;
  final bool isConnected;
  final String? error;
  final int latency;
  final Map<String, dynamic>? metadata;

  const MCPServerConnectionResult({
    required this.serverId,
    required this.isConnected,
    this.error,
    required this.latency,
    this.metadata,
  });
}

/// Context document for injection
class ContextDocument {
  final String filename;
  final String content;
  final String? mimeType;
  final Map<String, dynamic>? metadata;

  const ContextDocument({
    required this.filename,
    required this.content,
    this.mimeType,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'content': content,
      if (mimeType != null) 'mimeType': mimeType,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// MCP server capabilities
class MCPServerCapabilities {
  final List<String> tools;
  final List<String> resources;
  final bool supportsProgress;
  final bool supportsCancel;
  final Map<String, dynamic>? extensions;

  const MCPServerCapabilities({
    required this.tools,
    required this.resources,
    required this.supportsProgress,
    required this.supportsCancel,
    this.extensions,
  });

  factory MCPServerCapabilities.fromJson(Map<String, dynamic> json) {
    return MCPServerCapabilities(
      tools: List<String>.from(json['tools'] as List? ?? []),
      resources: List<String>.from(json['resources'] as List? ?? []),
      supportsProgress: json['supportsProgress'] as bool? ?? false,
      supportsCancel: json['supportsCancel'] as bool? ?? false,
      extensions: json['extensions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tools': tools,
      'resources': resources,
      'supportsProgress': supportsProgress,
      'supportsCancel': supportsCancel,
      if (extensions != null) 'extensions': extensions,
    };
  }
}

/// MCP bridge exception
class MCPBridgeException implements Exception {
  final String message;
  const MCPBridgeException(this.message);
  
  @override
  String toString() => 'MCPBridgeException: $message';
}

// ==================== Riverpod Providers ====================

final mcpBridgeServiceProvider = Provider<MCPBridgeService>((ref) {
  final settingsService = ref.read(mcpSettingsServiceProvider);
  final healthService = ref.read(integrationHealthMonitoringServiceProvider);
  final bridge = MCPBridgeService(settingsService, healthService);
  
  // Initialize on first access
  bridge.initialize().catchError((error) {
    debugPrint('Failed to initialize MCP bridge: $error');
  });
  
  // Dispose when provider is disposed
  ref.onDispose(() => bridge.dispose());
  
  return bridge;
});

/// Provider for MCP server capabilities
final mcpServerCapabilitiesProvider = FutureProvider.family<Map<String, MCPServerCapabilities>, List<String>>((ref, serverIds) async {
  final bridge = ref.read(mcpBridgeServiceProvider);
  return await bridge.getServerCapabilities(serverIds);
});

/// Provider for testing MCP server connection
final testMCPConnectionProvider = FutureProvider.family<MCPServerConnectionResult, String>((ref, serverId) async {
  final bridge = ref.read(mcpBridgeServiceProvider);
  return await bridge.testServerConnection(serverId);
});