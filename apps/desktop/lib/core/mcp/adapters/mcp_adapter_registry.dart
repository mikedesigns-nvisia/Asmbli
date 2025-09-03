import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'base_mcp_adapter.dart';
import 'websocket_adapter.dart';
import 'http_adapter.dart';
import 'sse_adapter.dart';
import '../../models/mcp_server_config.dart';

/// Registry for managing and auto-detecting MCP protocol adapters
class MCPAdapterRegistry {
  final Map<String, MCPAdapter Function()> _adapterFactories = {};
  final Map<String, List<String>> _protocolSchemes = {};
  final Map<String, int> _protocolPriority = {};
  
  static MCPAdapterRegistry? _instance;
  static MCPAdapterRegistry get instance => _instance ??= MCPAdapterRegistry._();
  
  MCPAdapterRegistry._() {
    _registerBuiltInAdapters();
  }
  
  /// Register built-in adapters with their protocol schemes and priorities
  void _registerBuiltInAdapters() {
    // WebSocket adapter (highest priority for real-time)
    registerAdapter(
      'websocket',
      () => WebSocketMCPAdapter(),
      schemes: ['ws', 'wss'],
      priority: 100,
    );
    
    // SSE adapter (high priority for real-time notifications)
    registerAdapter(
      'sse',
      () => SSEMCPAdapter(),
      schemes: ['http', 'https'],
      priority: 90,
    );
    
    // HTTP adapter (medium priority for REST APIs)
    registerAdapter(
      'http',
      () => HTTPMCPAdapter(),
      schemes: ['http', 'https'],
      priority: 80,
    );
    
    // STDIO adapter (for local processes)
    registerAdapter(
      'stdio',
      () => StdioMCPAdapter(),
      schemes: ['file', 'command'],
      priority: 70,
    );
    
    // gRPC adapter placeholder (future implementation)
    registerAdapter(
      'grpc',
      () => GRPCMCPAdapter(),
      schemes: ['grpc', 'grpcs'],
      priority: 60,
    );
    
    print('✅ Registered ${_adapterFactories.length} MCP adapters');
  }
  
  /// Register a new adapter with the registry
  void registerAdapter(
    String protocol,
    MCPAdapter Function() factory, {
    List<String> schemes = const [],
    int priority = 50,
  }) {
    _adapterFactories[protocol] = factory;
    _protocolSchemes[protocol] = schemes;
    _protocolPriority[protocol] = priority;
    
    print('📝 Registered MCP adapter: $protocol (priority: $priority)');
  }
  
  /// Get adapter by protocol name
  MCPAdapter? getAdapter(String protocol) {
    final factory = _adapterFactories[protocol];
    return factory?.call();
  }
  
  /// Get all available protocols
  List<String> getAvailableProtocols() {
    return _adapterFactories.keys.toList();
  }
  
  /// Auto-detect the best adapter for a given URL
  Future<MCPAdapter> autoDetectAdapter(String url) async {
    print('🔍 Auto-detecting MCP adapter for: $url');
    
    try {
      final uri = Uri.parse(url);
      
      // Get all matching adapters for the URL scheme
      final candidates = _getAdapterCandidates(uri);
      
      if (candidates.isEmpty) {
        throw MCPAdapterException(
          'No suitable adapter found for URL: $url',
        );
      }
      
      // Sort by priority (highest first)
      candidates.sort((a, b) => b.priority.compareTo(a.priority));
      
      // Try each candidate adapter
      for (final candidate in candidates) {
        try {
          final adapter = await _testAdapter(candidate.protocol, url);
          if (adapter != null) {
            print('✅ Auto-detected adapter: ${candidate.protocol} for $url');
            return adapter;
          }
        } catch (e) {
          print('⚠️ Adapter ${candidate.protocol} failed for $url: $e');
          continue;
        }
      }
      
      throw MCPAdapterException(
        'All candidate adapters failed for URL: $url',
      );
      
    } catch (e) {
      throw MCPAdapterException(
        'Auto-detection failed for URL $url: $e',
        originalError: e,
      );
    }
  }
  
  /// Get adapter candidates based on URL scheme and content detection
  List<_AdapterCandidate> _getAdapterCandidates(Uri uri) {
    final candidates = <_AdapterCandidate>[];
    
    // Check each registered adapter
    for (final entry in _adapterFactories.entries) {
      final protocol = entry.key;
      final schemes = _protocolSchemes[protocol] ?? [];
      final priority = _protocolPriority[protocol] ?? 50;
      
      // Check if scheme matches
      if (schemes.contains(uri.scheme)) {
        candidates.add(_AdapterCandidate(
          protocol: protocol,
          priority: priority,
          reason: 'scheme_match',
        ));
      }
      
      // Special cases for detection
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        // Check for WebSocket upgrade possibilities
        if (uri.path.contains('ws') || uri.queryParameters.containsKey('upgrade')) {
          candidates.add(_AdapterCandidate(
            protocol: 'websocket',
            priority: _protocolPriority['websocket']! + 10, // Boost priority
            reason: 'websocket_hint',
          ));
        }
        
        // Check for SSE endpoints
        if (uri.path.contains('events') || uri.path.contains('stream')) {
          candidates.add(_AdapterCandidate(
            protocol: 'sse',
            priority: _protocolPriority['sse']! + 5,
            reason: 'sse_hint',
          ));
        }
      }
      
      // Local file/command detection
      if (uri.scheme == 'file' || _isLocalCommand(uri.toString())) {
        candidates.add(_AdapterCandidate(
          protocol: 'stdio',
          priority: _protocolPriority['stdio']! + 20,
          reason: 'local_command',
        ));
      }
    }
    
    return candidates;
  }
  
  /// Test if an adapter can handle a specific URL
  Future<MCPAdapter?> _testAdapter(String protocol, String url) async {
    final adapter = getAdapter(protocol);
    if (adapter == null) return null;
    
    try {
      // Create a minimal test configuration
      final testConfig = MCPServerConfig(
        id: 'test-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Connection',
        url: url,
        protocol: protocol,
        enabled: true,
        timeout: 5, // Short timeout for testing
        autoReconnect: false,
      );
      
      // Validate configuration first
      if (!adapter.validateConfig(testConfig)) {
        return null;
      }
      
      // For WebSocket and SSE, do additional checks
      if (protocol == 'websocket') {
        if (!await _isWebSocketEndpoint(url)) {
          return null;
        }
      } else if (protocol == 'sse') {
        if (!await _isSSEEndpoint(url)) {
          return null;
        }
      } else if (protocol == 'stdio') {
        if (!await _isValidCommand(url)) {
          return null;
        }
      }
      
      return adapter;
      
    } catch (e) {
      print('❌ Adapter test failed for $protocol: $e');
      return null;
    }
  }
  
  /// Check if URL supports WebSocket connections
  Future<bool> _isWebSocketEndpoint(String url) async {
    try {
      final uri = Uri.parse(url);
      
      // Direct WebSocket URLs
      if (uri.scheme == 'ws' || uri.scheme == 'wss') {
        return true;
      }
      
      // Check for WebSocket upgrade support
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        final client = Dio();
        final response = await client.options(
          url,
          options: Options(
            headers: {
              'Connection': 'Upgrade',
              'Upgrade': 'websocket',
            },
            validateStatus: (status) => true,
          ),
        );
        
        // Check response headers for WebSocket support
        final upgrade = response.headers.value('upgrade')?.toLowerCase();
        return upgrade == 'websocket' || response.statusCode == 101;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if URL supports Server-Sent Events
  Future<bool> _isSSEEndpoint(String url) async {
    try {
      final client = Dio();
      final response = await client.options(
        url,
        options: Options(
          headers: {'Accept': 'text/event-stream'},
          validateStatus: (status) => true,
        ),
      );
      
      final contentType = response.headers.value('content-type');
      return contentType?.contains('text/event-stream') == true ||
             response.headers.value('accept')?.contains('text/event-stream') == true;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if URL represents a valid local command
  Future<bool> _isValidCommand(String url) async {
    try {
      // Check if it's a file path
      if (await File(url).exists()) {
        return true;
      }
      
      // Check if it's an executable command
      if (_isLocalCommand(url)) {
        final result = await Process.run('which', [url.split(' ').first]);
        return result.exitCode == 0;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if string represents a local command
  bool _isLocalCommand(String input) {
    // Contains path separators
    if (input.contains('/') || input.contains(r'\')) {
      return true;
    }
    
    // Looks like a command with arguments
    if (input.contains(' ')) {
      return true;
    }
    
    // Common executable extensions
    final extensions = ['.exe', '.sh', '.bat', '.cmd', '.py', '.js', '.ts'];
    return extensions.any((ext) => input.toLowerCase().endsWith(ext));
  }
  
  /// Get detailed adapter information
  Map<String, dynamic> getAdapterInfo(String protocol) {
    final adapter = getAdapter(protocol);
    if (adapter == null) return {};
    
    return {
      'protocol': protocol,
      'schemes': _protocolSchemes[protocol] ?? [],
      'priority': _protocolPriority[protocol] ?? 50,
      'features': adapter.getSupportedFeatures(),
      'capabilities': adapter.getCapabilities(),
    };
  }
  
  /// Get registry statistics
  Map<String, dynamic> getRegistryStats() {
    final stats = <String, dynamic>{
      'totalAdapters': _adapterFactories.length,
      'protocols': getAvailableProtocols(),
      'schemeMapping': _protocolSchemes,
      'priorityRanking': _protocolPriority,
    };
    
    return stats;
  }
  
  /// Clear all registered adapters (mainly for testing)
  void clear() {
    _adapterFactories.clear();
    _protocolSchemes.clear();
    _protocolPriority.clear();
  }
  
  /// Reset to built-in adapters only
  void reset() {
    clear();
    _registerBuiltInAdapters();
  }
}

/// Adapter candidate for auto-detection
class _AdapterCandidate {
  final String protocol;
  final int priority;
  final String reason;
  
  _AdapterCandidate({
    required this.protocol,
    required this.priority,
    required this.reason,
  });
  
  @override
  String toString() => '$protocol (priority: $priority, reason: $reason)';
}

/// Stub implementation for STDIO adapter (to be implemented)
class StdioMCPAdapter extends MCPAdapter {
  @override
  String get protocol => 'stdio';
  
  @override
  Future<void> connect(MCPServerConfig config) async {
    throw UnimplementedError('STDIO adapter not yet implemented');
  }
  
  @override
  Future<Map<String, dynamic>> sendRequest(
    String method,
    Map<String, dynamic> params,
  ) async {
    throw UnimplementedError('STDIO adapter not yet implemented');
  }
}

/// Stub implementation for gRPC adapter (to be implemented)
class GRPCMCPAdapter extends MCPAdapter {
  @override
  String get protocol => 'grpc';
  
  @override
  Future<void> connect(MCPServerConfig config) async {
    throw UnimplementedError('gRPC adapter coming soon');
  }
  
  @override
  Future<Map<String, dynamic>> sendRequest(
    String method,
    Map<String, dynamic> params,
  ) async {
    throw UnimplementedError('gRPC adapter coming soon');
  }
}