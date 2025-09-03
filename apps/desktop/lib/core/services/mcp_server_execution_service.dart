import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../data/mcp_server_configs.dart';
import 'desktop/desktop_storage_service.dart';


import '../models/mcp_server_config.dart';

/// Service for executing and managing MCP server processes
/// Implements JSON-RPC 2.0 communication as per MCP specification
class MCPServerExecutionService {
  final DesktopStorageService _storage = DesktopStorageService.instance;
  final Map<String, MCPServerProcess> _runningServers = {};
  final Map<String, StreamSubscription> _serverSubscriptions = {};
  
  /// Start an MCP server process for the given configuration
  Future<MCPServerProcess> startMCPServer(
    MCPServerConfig serverConfig,
    Map<String, String> environmentVars,
  ) async {
    final serverId = serverConfig.id;
    
    // Check if server is already running
    if (_runningServers.containsKey(serverId)) {
      final existing = _runningServers[serverId]!;
      if (existing.isHealthy) {
        return existing;
      } else {
        // Clean up unhealthy server
        await stopMCPServer(serverId);
      }
    }
    
    final process = await _spawnMCPProcess(serverConfig, environmentVars);
    _runningServers[serverId] = process;
    
    // Setup health monitoring
    _setupServerHealthMonitoring(process);
    
    // Perform initial handshake
    await _performMCPHandshake(process);
    
    return process;
  }
  
  /// Spawn the actual MCP server process
  Future<MCPServerProcess> _spawnMCPProcess(
    MCPServerConfig serverConfig,
    Map<String, String> environmentVars,
  ) async {
    final command = serverConfig.configuration['command'] as String? ?? 'npx';
    final args = List<String>.from(serverConfig.configuration['args'] as List? ?? []);
    
    // Handle special transport cases
    final transport = serverConfig.configuration['transport'] as String? ?? 'stdio';
    
    if (transport == 'sse') {
      // Server-Sent Events transport (HTTP-based)
      return await _startSSEServer(serverConfig, environmentVars);
    }
    
    // Default stdio transport
    final mergedEnv = Map<String, String>.from(Platform.environment);
    mergedEnv.addAll(environmentVars);
    
    final process = await Process.start(
      command,
      args,
      environment: mergedEnv,
      runInShell: true,
    );
    
    return MCPServerProcess(
      id: serverConfig.id,
      config: serverConfig,
      process: process,
      transport: MCPTransport.stdio,
      startTime: DateTime.now(),
    );
  }
  
  /// Start SSE-based MCP server (HTTP transport)
  Future<MCPServerProcess> _startSSEServer(
    MCPServerConfig serverConfig,
    Map<String, String> environmentVars,
  ) async {
    final url = serverConfig.configuration['url'] as String?;
    if (url == null) {
      throw Exception('SSE server URL not configured for ${serverConfig.id}');
    }
    
    // For SSE servers, we don't spawn a process but create a connection
    return MCPServerProcess(
      id: serverConfig.id,
      config: serverConfig,
      process: null, // No local process for remote servers
      transport: MCPTransport.sse,
      startTime: DateTime.now(),
      sseUrl: url,
    );
  }
  
  /// Stop an MCP server process
  Future<void> stopMCPServer(String serverId) async {
    final server = _runningServers[serverId];
    if (server == null) return;
    
    // Cancel health monitoring
    _serverSubscriptions[serverId]?.cancel();
    _serverSubscriptions.remove(serverId);
    
    // Send shutdown signal
    if (server.transport == MCPTransport.stdio && server.process != null) {
      try {
        // Send shutdown request per MCP spec
        await sendMCPRequest(serverId, 'shutdown', {});
        
        // Wait briefly for graceful shutdown
        await Future.delayed(const Duration(seconds: 2));
        
        // Force kill if still running
        if (!server.process!.kill()) {
          server.process!.kill(ProcessSignal.sigkill);
        }
      } catch (e) {
        // Force kill on error
        server.process?.kill(ProcessSignal.sigkill);
      }
    }
    
    _runningServers.remove(serverId);
  }
  
  /// Setup health monitoring for an MCP server
  void _setupServerHealthMonitoring(MCPServerProcess server) {
    if (server.transport == MCPTransport.stdio && server.process != null) {
      // Monitor process exit
      _serverSubscriptions[server.id] = server.process!.exitCode.asStream().listen(
        (exitCode) {
          print('🔴 MCP server ${server.id} exited with code $exitCode');
          _runningServers.remove(server.id);
          _serverSubscriptions[server.id]?.cancel();
          _serverSubscriptions.remove(server.id);
        },
      );
      
      // Monitor stderr for errors
      server.process!.stderr.transform(utf8.decoder).listen(
        (data) {
          print('⚠️ MCP server ${server.id} error: $data');
        },
      );
    }
    
    // Setup periodic health checks
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_runningServers.containsKey(server.id)) {
        timer.cancel();
        return;
      }
      
      try {
        await _performHealthCheck(server);
      } catch (e) {
        print('❌ Health check failed for ${server.id}: $e');
        // Mark as unhealthy but don't kill immediately
        server.lastHealthCheck = DateTime.now();
        server.isHealthy = false;
      }
    });
  }
  
  /// Perform MCP handshake to establish communication
  Future<void> _performMCPHandshake(MCPServerProcess server) async {
    try {
      // Initialize the MCP session
      final initResponse = await sendMCPRequest(server.id, 'initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'tools': {},
          'resources': {},
          'prompts': {},
          'sampling': {},
        },
        'clientInfo': {
          'name': 'AgentEngine',
          'version': '1.0.0',
        },
      });
      
      print('✅ MCP server ${server.id} initialized: $initResponse');
      
      // Send initialized notification
      await sendMCPNotification(server.id, 'notifications/initialized', {});
      
      server.isInitialized = true;
      server.isHealthy = true;
      server.lastHealthCheck = DateTime.now();
      
    } catch (e) {
      print('❌ MCP handshake failed for ${server.id}: $e');
      server.isHealthy = false;
      rethrow;
    }
  }
  
  /// Perform health check on an MCP server
  Future<void> _performHealthCheck(MCPServerProcess server) async {
    if (server.transport == MCPTransport.sse) {
      // For SSE servers, check HTTP endpoint
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(server.sseUrl!));
        final response = await request.close();
        server.isHealthy = response.statusCode == 200;
      } finally {
        client.close();
      }
    } else {
      // For stdio servers, send ping request
      try {
        await sendMCPRequest(server.id, 'ping', {});
        server.isHealthy = true;
      } catch (e) {
        server.isHealthy = false;
        rethrow;
      }
    }
    
    server.lastHealthCheck = DateTime.now();
  }
  
  /// Send JSON-RPC 2.0 request to MCP server
  Future<Map<String, dynamic>> sendMCPRequest(
    String serverId,
    String method,
    Map<String, dynamic> params,
  ) async {
    final server = _runningServers[serverId];
    if (server == null || !server.isHealthy) {
      throw Exception('MCP server $serverId not available');
    }
    
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final request = {
      'jsonrpc': '2.0',
      'id': requestId,
      'method': method,
      'params': params,
    };
    
    if (server.transport == MCPTransport.stdio) {
      return await _sendStdioRequest(server, request, requestId);
    } else {
      return await _sendSSERequest(server, request, requestId);
    }
  }
  
  /// Send notification (no response expected)
  Future<void> sendMCPNotification(
    String serverId,
    String method,
    Map<String, dynamic> params,
  ) async {
    final server = _runningServers[serverId];
    if (server == null || !server.isHealthy) {
      throw Exception('MCP server $serverId not available');
    }
    
    final notification = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    };
    
    if (server.transport == MCPTransport.stdio) {
      await _sendStdioNotification(server, notification);
    } else {
      await _sendSSENotification(server, notification);
    }
  }
  
  /// Send stdio request and wait for response
  Future<Map<String, dynamic>> _sendStdioRequest(
    MCPServerProcess server,
    Map<String, dynamic> request,
    String requestId,
  ) async {
    if (server.process == null) {
      throw Exception('No process for stdio server ${server.id}');
    }
    
    final completer = Completer<Map<String, dynamic>>();
    StreamSubscription? subscription;
    
    // Listen for response
    subscription = server.process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.trim().isEmpty) return;
      
      try {
        final response = json.decode(line) as Map<String, dynamic>;
        if (response['id'] == requestId) {
          subscription?.cancel();
          
          if (response.containsKey('error')) {
            completer.completeError(Exception('MCP Error: ${response['error']}'));
          } else {
            completer.complete(response);
          }
        }
      } catch (e) {
        // Ignore non-JSON lines or responses for different requests
      }
    });
    
    // Send request
    final requestJson = json.encode(request);
    server.process!.stdin.writeln(requestJson);
    
    // Set timeout
    Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.completeError(TimeoutException('Request timeout', const Duration(seconds: 30)));
      }
    });
    
    return await completer.future;
  }
  
  /// Send stdio notification (no response expected)
  Future<void> _sendStdioNotification(
    MCPServerProcess server,
    Map<String, dynamic> notification,
  ) async {
    if (server.process == null) {
      throw Exception('No process for stdio server ${server.id}');
    }
    
    final notificationJson = json.encode(notification);
    server.process!.stdin.writeln(notificationJson);
  }
  
  /// Send SSE request via HTTP
  Future<Map<String, dynamic>> _sendSSERequest(
    MCPServerProcess server,
    Map<String, dynamic> request,
    String requestId,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('${server.sseUrl}/request');
      final httpRequest = await client.postUrl(uri);
      httpRequest.headers.contentType = ContentType.json;
      
      final requestJson = json.encode(request);
      httpRequest.add(utf8.encode(requestJson));
      
      final response = await httpRequest.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      
      final responseBody = await response.transform(utf8.decoder).join();
      return json.decode(responseBody) as Map<String, dynamic>;
      
    } finally {
      client.close();
    }
  }
  
  /// Send SSE notification via HTTP
  Future<void> _sendSSENotification(
    MCPServerProcess server,
    Map<String, dynamic> notification,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('${server.sseUrl}/notification');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      
      final notificationJson = json.encode(notification);
      request.add(utf8.encode(notificationJson));
      
      await request.close();
    } finally {
      client.close();
    }
  }
  
  /// Get list of running MCP servers
  List<MCPServerProcess> getRunningServers() {
    return _runningServers.values.toList();
  }
  
  /// Get specific running server
  MCPServerProcess? getRunningServer(String serverId) {
    return _runningServers[serverId];
  }
  
  /// Check if server is running and healthy
  bool isServerHealthy(String serverId) {
    final server = _runningServers[serverId];
    return server?.isHealthy ?? false;
  }
  
  /// Restart an MCP server
  Future<MCPServerProcess> restartMCPServer(
    String serverId,
    Map<String, String> environmentVars,
  ) async {
    final server = _runningServers[serverId];
    if (server == null) {
      throw Exception('Server $serverId not found');
    }
    
    final config = server.config;
    await stopMCPServer(serverId);
    
    // Wait a moment before restarting
    await Future.delayed(const Duration(seconds: 1));
    
    return await startMCPServer(config, environmentVars);
  }
  
  /// Shutdown all MCP servers
  Future<void> shutdownAllServers() async {
    final serverIds = List<String>.from(_runningServers.keys);
    await Future.wait(
      serverIds.map((id) => stopMCPServer(id)),
    );
  }
  
  /// Start MCP servers for an agent
  Future<List<MCPServerProcess>> startAgentMCPServers(
    Agent agent,
    Map<String, String> environmentVars,
  ) async {
    final mcpServers = agent.configuration['mcpServers'] as List<dynamic>? ?? [];
    final startedServers = <MCPServerProcess>[];
    
    for (final serverRef in mcpServers) {
      final serverId = serverRef is String ? serverRef : serverRef['id'] as String?;
      if (serverId == null) continue;
      
      final serverConfig = MCPServerLibrary.getServer(serverId);
      if (serverConfig == null) {
        print('⚠️ Unknown MCP server: $serverId');
        continue;
      }
      
      try {
        final serverProcess = await startMCPServer(serverConfig, environmentVars);
        startedServers.add(serverProcess);
        print('✅ Started MCP server: $serverId');
      } catch (e) {
        print('❌ Failed to start MCP server $serverId: $e');
      }
    }
    
    return startedServers;
  }
}

/// Represents a running MCP server process
class MCPServerProcess {
  final String id;
  final MCPServerConfig config;
  final Process? process;
  final MCPTransport transport;
  final DateTime startTime;
  final String? sseUrl;
  
  bool isInitialized = false;
  bool isHealthy = false;
  DateTime? lastHealthCheck;
  
  MCPServerProcess({
    required this.id,
    required this.config,
    required this.process,
    required this.transport,
    required this.startTime,
    this.sseUrl,
  });
  
  /// Get server uptime
  Duration get uptime => DateTime.now().difference(startTime);
  
  /// Check if process is alive
  bool get isAlive {
    if (transport == MCPTransport.sse) {
      return isHealthy; // For SSE, rely on health check
    }
    return process != null && process!.pid > 0;
  }
}

/// MCP transport protocols
enum MCPTransport {
  stdio,  // Standard input/output (default)
  sse,    // Server-Sent Events (HTTP-based)
}

/// Provider for MCP server execution service
final mcpServerExecutionServiceProvider = Provider<MCPServerExecutionService>((ref) {
  return MCPServerExecutionService();
});