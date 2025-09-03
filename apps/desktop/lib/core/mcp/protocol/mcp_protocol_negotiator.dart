import 'dart:async';
import 'dart:math';
import '../adapters/base_mcp_adapter.dart';
import '../adapters/mcp_adapter_registry.dart';
import '../../models/mcp_server_config.dart';

/// Handles MCP protocol negotiation and fallback strategies
class MCPProtocolNegotiator {
  final MCPAdapterRegistry _registry;
  
  static const List<String> _supportedVersions = ['1.0', '0.9', '0.8'];
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _fallbackDelay = Duration(seconds: 2);
  
  MCPProtocolNegotiator([MCPAdapterRegistry? registry])
      : _registry = registry ?? MCPAdapterRegistry.instance;
  
  /// Negotiate the best protocol and establish connection
  Future<MCPConnection> negotiate(MCPServerConfig config) async {
    print('🤝 Starting MCP protocol negotiation for ${config.name}');
    
    try {
      // Phase 1: Try primary protocol
      if (config.protocol.isNotEmpty) {
        final connection = await _tryProtocol(config, config.protocol);
        if (connection != null) {
          print('✅ Connected using primary protocol: ${config.protocol}');
          return connection;
        }
      }
      
      // Phase 2: Try auto-detection
      final connection = await _tryAutoDetection(config);
      if (connection != null) {
        print('✅ Connected using auto-detected protocol');
        return connection;
      }
      
      // Phase 3: Try fallback protocols
      final fallbackConnection = await _tryFallbackProtocols(config);
      if (fallbackConnection != null) {
        print('✅ Connected using fallback protocol');
        return fallbackConnection;
      }
      
      throw MCPAdapterException(
        'Failed to negotiate any protocol for ${config.name}',
      );
      
    } catch (e) {
      throw MCPAdapterException(
        'Protocol negotiation failed for ${config.name}: $e',
        originalError: e,
      );
    }
  }
  
  /// Try to connect using a specific protocol
  Future<MCPConnection?> _tryProtocol(
    MCPServerConfig config,
    String protocol,
  ) async {
    try {
      print('🔄 Trying protocol: $protocol for ${config.url}');
      
      final adapter = _registry.getAdapter(protocol);
      if (adapter == null) {
        print('❌ Adapter not found for protocol: $protocol');
        return null;
      }
      
      // Validate configuration
      if (!adapter.validateConfig(config)) {
        print('❌ Invalid configuration for protocol: $protocol');
        return null;
      }
      
      // Attempt connection with timeout
      await adapter.connect(config).timeout(_connectionTimeout);
      
      // Perform version negotiation
      final version = await _negotiateVersion(adapter, config);
      
      // Get server information
      final serverInfo = await _getServerInfo(adapter);
      
      final connection = MCPConnection(
        adapter,
        version,
        serverInfo: serverInfo,
      );
      
      print('✅ Protocol $protocol connected successfully');
      return connection;
      
    } catch (e) {
      print('❌ Protocol $protocol failed: $e');
      return null;
    }
  }
  
  /// Try auto-detection of the best protocol
  Future<MCPConnection?> _tryAutoDetection(MCPServerConfig config) async {
    try {
      print('🔍 Attempting auto-detection for ${config.url}');
      
      final adapter = await _registry.autoDetectAdapter(config.url);
      
      // Create config for detected adapter
      final detectedConfig = config.copyWith(
        protocol: adapter.protocol,
      );
      
      return await _tryProtocol(detectedConfig, adapter.protocol);
      
    } catch (e) {
      print('❌ Auto-detection failed: $e');
      return null;
    }
  }
  
  /// Try fallback protocols in priority order
  Future<MCPConnection?> _tryFallbackProtocols(MCPServerConfig config) async {
    final fallbackProtocols = config.fallbackProtocols ??
        _getDefaultFallbackProtocols(config);
    
    if (fallbackProtocols.isEmpty) {
      print('⚠️ No fallback protocols configured');
      return null;
    }
    
    print('🔄 Trying ${fallbackProtocols.length} fallback protocols');
    
    for (int i = 0; i < fallbackProtocols.length; i++) {
      final protocol = fallbackProtocols[i];
      
      try {
        // Add delay between attempts to avoid overwhelming the server
        if (i > 0) {
          await Future.delayed(_fallbackDelay);
        }
        
        final fallbackConfig = config.copyWith(protocol: protocol);
        final connection = await _tryProtocol(fallbackConfig, protocol);
        
        if (connection != null) {
          print('✅ Fallback protocol $protocol succeeded');
          return connection;
        }
        
      } catch (e) {
        print('❌ Fallback protocol $protocol failed: $e');
        continue;
      }
    }
    
    print('❌ All fallback protocols exhausted');
    return null;
  }
  
  /// Negotiate protocol version with the server
  Future<String> _negotiateVersion(
    MCPAdapter adapter,
    MCPServerConfig config,
  ) async {
    try {
      // Get server capabilities and supported versions
      final response = await adapter.sendRequest('capabilities', {});
      
      final serverVersions = _extractSupportedVersions(response);
      
      // Find best compatible version
      final bestVersion = _selectCompatibleVersion(serverVersions);
      
      if (bestVersion != null) {
        // Notify server of selected version
        await adapter.sendNotification('version', {'version': bestVersion});
        print('🤝 Negotiated version: $bestVersion');
        return bestVersion;
      }
      
      throw MCPAdapterException(
        'No compatible version found. Server: $serverVersions, Client: $_supportedVersions',
      );
      
    } catch (e) {
      // Fallback to default version
      print('⚠️ Version negotiation failed, using default: ${_supportedVersions.first}');
      return _supportedVersions.first;
    }
  }
  
  /// Extract supported versions from server response
  List<String> _extractSupportedVersions(Map<String, dynamic> response) {
    final versions = <String>[];
    
    // Try different response formats
    if (response['versions'] is List) {
      versions.addAll(List<String>.from(response['versions']));
    } else if (response['protocolVersion'] is String) {
      versions.add(response['protocolVersion']);
    } else if (response['version'] is String) {
      versions.add(response['version']);
    } else if (response['capabilities']?['versions'] is List) {
      versions.addAll(List<String>.from(response['capabilities']['versions']));
    }
    
    // Default if no versions found
    if (versions.isEmpty) {
      versions.add('1.0');
    }
    
    return versions;
  }
  
  /// Select the best compatible version
  String? _selectCompatibleVersion(List<String> serverVersions) {
    // Find the highest version that both client and server support
    for (final clientVersion in _supportedVersions) {
      if (serverVersions.contains(clientVersion)) {
        return clientVersion;
      }
    }
    
    // If no exact match, try semantic version compatibility
    for (final clientVersion in _supportedVersions) {
      for (final serverVersion in serverVersions) {
        if (_isVersionCompatible(clientVersion, serverVersion)) {
          return clientVersion; // Use client version as base
        }
      }
    }
    
    return null;
  }
  
  /// Check if two versions are compatible
  bool _isVersionCompatible(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.tryParse).toList();
    final v2Parts = version2.split('.').map(int.tryParse).toList();
    
    // Ensure we have valid version numbers
    if (v1Parts.any((v) => v == null) || v2Parts.any((v) => v == null)) {
      return false;
    }
    
    final v1Major = v1Parts[0]!;
    final v1Minor = v1Parts.length > 1 ? v1Parts[1]! : 0;
    
    final v2Major = v2Parts[0]!;
    final v2Minor = v2Parts.length > 1 ? v2Parts[1]! : 0;
    
    // Same major version is compatible
    if (v1Major == v2Major) {
      return true;
    }
    
    // Minor version differences within same major are compatible
    if (v1Major == v2Major && (v1Minor - v2Minor).abs() <= 1) {
      return true;
    }
    
    return false;
  }
  
  /// Get server information for connection metadata
  Future<Map<String, dynamic>> _getServerInfo(MCPAdapter adapter) async {
    try {
      final info = await adapter.sendRequest('info', {});
      return Map<String, dynamic>.from(info);
    } catch (e) {
      print('⚠️ Failed to get server info: $e');
      return {
        'name': 'Unknown',
        'version': 'Unknown',
        'error': 'Failed to retrieve server info',
      };
    }
  }
  
  /// Get default fallback protocols based on URL scheme
  List<String> _getDefaultFallbackProtocols(MCPServerConfig config) {
    final uri = Uri.tryParse(config.url);
    if (uri == null) return [];
    
    switch (uri.scheme) {
      case 'ws':
      case 'wss':
        return ['websocket', 'http', 'sse'];
      
      case 'http':
      case 'https':
        return ['http', 'sse', 'websocket'];
      
      case 'grpc':
      case 'grpcs':
        return ['grpc', 'http'];
      
      default:
        // For file paths or commands
        if (_isLocalResource(config.url)) {
          return ['stdio'];
        }
        return ['http', 'websocket', 'sse'];
    }
  }
  
  /// Check if URL represents a local resource
  bool _isLocalResource(String url) {
    return url.startsWith('/') ||
           url.startsWith('file:') ||
           url.contains(r'\') ||
           !url.contains('://');
  }
  
  /// Create negotiation strategy based on configuration
  MCPNegotiationStrategy createStrategy(MCPServerConfig config) {
    return MCPNegotiationStrategy(
      preferredProtocol: config.protocol,
      fallbackProtocols: config.fallbackProtocols ?? 
          _getDefaultFallbackProtocols(config),
      supportedVersions: _supportedVersions,
      connectionTimeout: Duration(seconds: config.timeout ?? 30),
      maxRetries: config.maxRetries ?? 3,
      retryDelay: Duration(seconds: config.retryDelay ?? 5),
      enableAutoDetection: config.enableAutoDetection ?? true,
    );
  }
  
  /// Batch negotiate multiple connections
  Future<List<MCPConnectionResult>> batchNegotiate(
    List<MCPServerConfig> configs,
  ) async {
    print('🔄 Batch negotiating ${configs.length} connections');
    
    final results = <MCPConnectionResult>[];
    final futures = <Future<MCPConnectionResult>>[];
    
    // Start all negotiations concurrently
    for (final config in configs) {
      futures.add(_negotiateWithResult(config));
    }
    
    // Wait for all to complete
    final completedResults = await Future.wait(futures);
    results.addAll(completedResults);
    
    final successful = results.where((r) => r.isSuccess).length;
    print('✅ Batch negotiation completed: $successful/${configs.length} successful');
    
    return results;
  }
  
  /// Negotiate with result wrapper
  Future<MCPConnectionResult> _negotiateWithResult(MCPServerConfig config) async {
    try {
      final connection = await negotiate(config);
      return MCPConnectionResult.success(config, connection);
    } catch (e) {
      return MCPConnectionResult.failure(config, e.toString());
    }
  }
}

/// Negotiation strategy configuration
class MCPNegotiationStrategy {
  final String preferredProtocol;
  final List<String> fallbackProtocols;
  final List<String> supportedVersions;
  final Duration connectionTimeout;
  final int maxRetries;
  final Duration retryDelay;
  final bool enableAutoDetection;
  
  const MCPNegotiationStrategy({
    required this.preferredProtocol,
    required this.fallbackProtocols,
    required this.supportedVersions,
    required this.connectionTimeout,
    required this.maxRetries,
    required this.retryDelay,
    required this.enableAutoDetection,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'preferredProtocol': preferredProtocol,
      'fallbackProtocols': fallbackProtocols,
      'supportedVersions': supportedVersions,
      'connectionTimeoutMs': connectionTimeout.inMilliseconds,
      'maxRetries': maxRetries,
      'retryDelayMs': retryDelay.inMilliseconds,
      'enableAutoDetection': enableAutoDetection,
    };
  }
}

/// Result of connection negotiation
class MCPConnectionResult {
  final MCPServerConfig config;
  final MCPConnection? connection;
  final String? error;
  final bool isSuccess;
  final Duration negotiationTime;
  
  MCPConnectionResult._({
    required this.config,
    this.connection,
    this.error,
    required this.isSuccess,
    required this.negotiationTime,
  });
  
  factory MCPConnectionResult.success(
    MCPServerConfig config,
    MCPConnection connection,
  ) {
    return MCPConnectionResult._(
      config: config,
      connection: connection,
      isSuccess: true,
      negotiationTime: DateTime.now().difference(DateTime.now()),
    );
  }
  
  factory MCPConnectionResult.failure(
    MCPServerConfig config,
    String error,
  ) {
    return MCPConnectionResult._(
      config: config,
      error: error,
      isSuccess: false,
      negotiationTime: DateTime.now().difference(DateTime.now()),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'configId': config.id,
      'configName': config.name,
      'isSuccess': isSuccess,
      'error': error,
      'protocol': connection?.adapter.protocol,
      'version': connection?.version,
      'negotiationTimeMs': negotiationTime.inMilliseconds,
    };
  }
}

/// Extension for server config with negotiation properties
extension MCPServerConfigNegotiation on MCPServerConfig {
  MCPServerConfig copyWith({
    String? protocol,
    List<String>? fallbackProtocols,
    bool? enableAutoDetection,
    int? maxRetries,
    int? retryDelay,
  }) {
    return MCPServerConfig(
      id: id,
      name: name,
      url: url,
      protocol: protocol ?? this.protocol,
      enabled: enabled,
      authToken: authToken,
      headers: headers,
      capabilities: capabilities,
      timeout: timeout,
      autoReconnect: autoReconnect,
      fallbackProtocols: fallbackProtocols ?? this.fallbackProtocols,
      enableAutoDetection: enableAutoDetection ?? this.enableAutoDetection,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      enablePolling: enablePolling,
    );
  }
}