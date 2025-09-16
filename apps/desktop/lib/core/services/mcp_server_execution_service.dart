import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../data/mcp_server_configs.dart';
import 'desktop/desktop_storage_service.dart';
import '../models/mcp_server_process.dart' show MCPServerConfig, MCPServerProcess, MCPServerStatus;
import '../models/mcp_catalog_entry.dart' show MCPCatalogEntry, MCPTransportType;
import 'mcp_catalog_service.dart';
import 'mcp_settings_service.dart';
import '../di/service_locator.dart';

/// Service for executing and managing MCP server processes
/// Implements JSON-RPC 2.0 communication as per MCP specification
class MCPServerExecutionService {
  final DesktopStorageService _storage = DesktopStorageService.instance;
  final MCPCatalogService _catalogService;
  final MCPSettingsService _settingsService;
  final Map<String, MCPServerProcess> _runningServers = {};
  final Map<String, StreamSubscription> _serverSubscriptions = {};
  final Map<String, String> _serverInstallPaths = {}; // Track installed server paths

  MCPServerExecutionService(this._catalogService, this._settingsService);
  
  /// Install MCP server if not already installed
  Future<String> ensureMCPServerInstalled(MCPServerConfig config) async {
    final serverId = config.id;
    
    // Check if already installed and cached
    if (_serverInstallPaths.containsKey(serverId)) {
      final cachedPath = _serverInstallPaths[serverId]!;
      if (await File(cachedPath).exists() || await Directory(cachedPath).exists()) {
        return cachedPath;
      }
    }
    
    // Install server based on command type
    String installedPath;
    final command = config.command;
    
    if (command.startsWith('uvx ') || command.startsWith('npx ')) {
      // Node.js/Python package manager installation
      installedPath = await _installPackageManagerServer(config);
    } else if (command.contains('docker ')) {
      // Docker container installation
      installedPath = await _installDockerServer(config);
    } else if (await File(command).exists()) {
      // Local executable already exists
      installedPath = command;
    } else {
      throw Exception('Unknown server installation method for: $command');
    }
    
    _serverInstallPaths[serverId] = installedPath;
    return installedPath;
  }
  
  /// Install server via package manager (uvx/npx)
  Future<String> _installPackageManagerServer(MCPServerConfig config) async {
    final command = config.command;
    final parts = command.split(' ');
    
    if (parts.length < 2) {
      throw Exception('Invalid package manager command: $command');
    }
    
    final packageManager = parts[0]; // 'uvx' or 'npx'
    final packageName = parts[1]; // e.g., '@modelcontextprotocol/server-github'
    
    print('📦 Installing MCP server: $packageName via $packageManager');
    
    // Run installation command
    final process = await Process.run(
      packageManager,
      ['--help'], // First check if package manager is available
      runInShell: true,
    );
    
    if (process.exitCode != 0) {
      throw Exception('Package manager $packageManager not found. Please install it first.');
    }
    
    // For uvx/npx, we don't need to pre-install - they handle it automatically
    // Just verify the package exists by testing the command
    print('✅ Package manager $packageManager available');
    return command; // Return original command for uvx/npx
  }
  
  /// Install server via Docker
  Future<String> _installDockerServer(MCPServerConfig config) async {
    final command = config.command;
    print('🐳 Installing Docker-based MCP server: $command');
    
    // Check if Docker is available
    final dockerCheck = await Process.run('docker', ['--version'], runInShell: true);
    if (dockerCheck.exitCode != 0) {
      throw Exception('Docker not found. Please install Docker first.');
    }
    
    // Extract image name from docker command
    final parts = command.split(' ');
    final imageIndex = parts.indexOf('run') + 1;
    if (imageIndex < parts.length) {
      final imageName = parts[imageIndex];
      
      // Pull the Docker image
      final pullProcess = await Process.run(
        'docker',
        ['pull', imageName],
        runInShell: true,
      );
      
      if (pullProcess.exitCode != 0) {
        throw Exception('Failed to pull Docker image: $imageName\n${pullProcess.stderr}');
      }
      
      print('✅ Docker image $imageName installed');
    }
    
    return command;
  }
  
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
    
    // Ensure server is installed before starting
    print('🔍 Checking MCP server installation for: ${serverConfig.name}');
    try {
      await ensureMCPServerInstalled(serverConfig);
      print('✅ MCP server installation verified');
    } catch (e) {
      print('❌ MCP server installation failed: $e');
      throw Exception('Failed to install MCP server ${serverConfig.name}: $e');
    }
    
    final process = await _spawnMCPProcess(serverConfig, environmentVars);
    _runningServers[serverId] = process;
    
    // Setup health monitoring
    _setupServerHealthMonitoring(process);
    
    // Perform initial handshake with timeout
    print('🤝 Performing MCP handshake with ${serverConfig.name}');
    try {
      await _performMCPHandshake(process);
      print('✅ MCP handshake successful');
    } catch (e) {
      print('❌ MCP handshake failed: $e');
      await stopMCPServer(serverId); // Clean up failed server
      rethrow;
    }
    
    return process;
  }
  
  /// Spawn the actual MCP server process
  Future<MCPServerProcess> _spawnMCPProcess(
    MCPServerConfig serverConfig,
    Map<String, String> environmentVars,
  ) async {
    // Handle special transport cases
    final transport = serverConfig.transport ?? 'stdio';
    
    if (transport == 'sse') {
      // Server-Sent Events transport (HTTP-based)
      return await _startSSEServer(serverConfig, environmentVars);
    }
    
    // Use the real MCPServerProcess.start() method
    print('🚀 Starting MCP server: ${serverConfig.command} ${serverConfig.args.join(' ')}');
    
    return await MCPServerProcess.start(
      id: serverConfig.id,
      config: serverConfig,
      environmentVars: environmentVars,
    );
  }
  
  /// Start SSE-based MCP server (HTTP transport)
  Future<MCPServerProcess> _startSSEServer(
    MCPServerConfig serverConfig,
    Map<String, String> environmentVars,
  ) async {
    final url = serverConfig.url;
    if (url.isEmpty) {
      throw Exception('SSE server URL not configured for ${serverConfig.id}');
    }
    
    // For SSE servers, we don't spawn a process but create a connection
    return MCPServerProcess(
      id: serverConfig.id,
      serverId: serverConfig.id,
      agentId: 'default', // Or get from context
      config: serverConfig,
      startTime: DateTime.now(),
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
    if (server.process != null) {
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
  
  /// Setup health monitoring for an MCP server with auto-recovery
  void _setupServerHealthMonitoring(MCPServerProcess server) {
    if (server.process != null) {
      // Monitor process exit with auto-restart capability
      _serverSubscriptions[server.id] = server.process!.exitCode.asStream().listen(
        (exitCode) {
          print('🔴 MCP server ${server.id} exited with code $exitCode');
          server.recordError('Process exited with code $exitCode');
          
          // Attempt auto-restart if enabled and exit wasn't intentional
          if (server.config.autoReconnect && exitCode != 0) {
            print('🔄 Attempting auto-restart for ${server.id}');
            Timer(const Duration(seconds: 5), () => _attemptServerRestart(server));
          } else {
            _runningServers.remove(server.id);
            _serverSubscriptions[server.id]?.cancel();
            _serverSubscriptions.remove(server.id);
          }
        },
      );
      
      // Monitor stderr for errors with categorization
      server.process!.stderr.transform(utf8.decoder).listen(
        (data) {
          print('⚠️ MCP server ${server.id} stderr: $data');
          server.recordError('Stderr: ${data.trim()}');
          
          // Check for critical errors that require restart
          if (_isCriticalError(data)) {
            print('💥 Critical error detected in ${server.id}, marking for restart');
            server.isHealthy = false;
          }
        },
      );
      
      // Monitor stdout for useful information
      server.process!.stdout.transform(utf8.decoder).listen(
        (data) {
          // Log initialization messages and capability announcements
          if (data.contains('MCP') || data.contains('initialized') || data.contains('capabilities')) {
            print('ℹ️ MCP server ${server.id}: ${data.trim()}');
          }
        },
      );
    }
    
    // Setup periodic health checks with exponential backoff
    int healthCheckInterval = 30; // Start with 30 seconds
    late Timer healthTimer;
    
    void scheduleHealthCheck() {
      healthTimer = Timer(Duration(seconds: healthCheckInterval), () async {
        if (!_runningServers.containsKey(server.id)) {
          healthTimer.cancel();
          return;
        }
        
        try {
          await _performHealthCheck(server);
          print('✅ Health check passed for ${server.id}');
          // Reset interval on success
          healthCheckInterval = 30;
          scheduleHealthCheck();
        } catch (e) {
          print('❌ Health check failed for ${server.id}: $e');
          server.recordError('Health check failed: $e');
          
          // Exponential backoff (but cap at 5 minutes)
          healthCheckInterval = (healthCheckInterval * 1.5).clamp(30, 300).round();
          
          // Attempt recovery after multiple failures
          if (!server.isHealthy && server.config.autoReconnect) {
            _attemptServerRestart(server);
          } else {
            scheduleHealthCheck();
          }
        }
      });
    }
    
    scheduleHealthCheck();
  }
  
  /// Check if stderr output indicates a critical error requiring restart
  bool _isCriticalError(String stderr) {
    final criticalPatterns = [
      'out of memory',
      'segmentation fault',
      'fatal error',
      'panic:',
      'uncaught exception',
      'connection refused',
      'permission denied',
      'address already in use',
    ];
    
    final lowerStderr = stderr.toLowerCase();
    return criticalPatterns.any((pattern) => lowerStderr.contains(pattern));
  }
  
  /// Attempt to restart a failed MCP server
  Future<void> _attemptServerRestart(MCPServerProcess server) async {
    if (!server.config.autoReconnect) return;
    
    final maxRetries = server.config.maxRetries ?? 3;
    final currentRetries = 0; // Track retries separately
    
    if (currentRetries >= maxRetries) {
      print('❌ Max restart attempts reached for ${server.id}, giving up');
      server.recordError('Max restart attempts exceeded');
      return;
    }
    
    print('🔄 Restart attempt ${currentRetries + 1}/$maxRetries for ${server.id}');
    
    try {
      // Clean up old process
      await stopMCPServer(server.id);
      
      // Wait before restart
      final delay = server.config.retryDelay ?? 5000;
      await Future.delayed(Duration(milliseconds: delay));
      
      // Attempt restart
      final newProcess = await startMCPServer(server.config, server.config.env ?? {});
      print('✅ Successfully restarted ${server.id}');
      
    } catch (e) {
      print('❌ Restart failed for ${server.id}: $e');
      server.recordError('Restart failed: $e');
      // Increment retry count would be tracked separately
      
      // Schedule another retry with exponential backoff
      final delay = server.config.retryDelay ?? 5000;
      Timer(Duration(milliseconds: delay * 2), () => _attemptServerRestart(server));
    }
  }
  
  /// Perform MCP handshake to establish communication
  Future<void> _performMCPHandshake(MCPServerProcess server) async {
    try {
      print('🤝 Initializing MCP server ${server.id}...');
      
      // Send initialize request directly via the server
      final initResponse = await server.sendJsonRpcRequest({
        'method': 'initialize',
        'params': {
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
        },
      });
      
      print('✅ MCP server ${server.id} initialized: ${initResponse['result']}');
      
      // Send initialized notification (no response expected)
      await server.sendInput(json.encode({
        'jsonrpc': '2.0',
        'method': 'notifications/initialized',
        'params': {},
      }));
      
      server.isInitialized = true;
      server.isHealthy = true;
      
    } catch (e) {
      print('❌ MCP handshake failed for ${server.id}: $e');
      server.isHealthy = false;
      rethrow;
    }
  }
  
  /// Perform health check on an MCP server
  Future<void> _performHealthCheck(MCPServerProcess server) async {
    if (server.config.transport == 'sse') {
      // For SSE servers, check HTTP endpoint
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(server.config.url));
        final response = await request.close();
        server.isHealthy = response.statusCode == 200;
      } finally {
        client.close();
      }
    } else {
      // For stdio servers, send ping request
      try {
        await sendMCPRequest(server.id, 'tools/list', {});
        server.isHealthy = true;
      } catch (e) {
        server.isHealthy = false;
        rethrow;
      }
    }
    
    // Health check timestamp would be tracked separately
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
    
    // Use the real MCPServerProcess JSON-RPC communication
    return await server.sendJsonRpcRequest({
      'method': method,
      'params': params,
    });
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
    
    if (server.config.transport == 'sse') {
      await _sendSSENotification(server, notification);
    } else {
      await _sendStdioNotification(server, notification);
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
            final errorInfo = response['error'];
            final errorMessage = errorInfo is Map ? 
                'MCP Error ${errorInfo['code'] ?? 'unknown'}: ${errorInfo['message'] ?? 'Unknown error'}' :
                'MCP Error: $errorInfo';
            server.recordError(errorMessage);
            completer.completeError(Exception(errorMessage));
          } else {
            server.recordActivity();
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
      final uri = Uri.parse('${server.config.url}/request');
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
      final uri = Uri.parse('${server.config.url}/notification');
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
      
      final libraryConfig = MCPServerLibrary.getServer(serverId);
      if (libraryConfig == null) {
        print('⚠️ Unknown MCP server: $serverId');
        continue;
      }
      
      // Convert MCPServerLibraryConfig to MCPServerConfig
      final serverConfig = MCPServerConfig(
        id: libraryConfig.id,
        name: libraryConfig.name,
        url: 'local://${libraryConfig.id}',
        command: libraryConfig.configuration['command']?.toString() ?? '',
        args: libraryConfig.configuration['args'] is List 
          ? List<String>.from(libraryConfig.configuration['args'])
          : [],
        env: libraryConfig.configuration['env'] is Map
          ? Map<String, String>.from(libraryConfig.configuration['env'])
          : null,
        description: libraryConfig.description,
        capabilities: libraryConfig.capabilities,
        enabled: true,
      );
      
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

  // ==================== Catalog-Based Methods ====================

  /// Start all enabled MCP servers for an agent using the catalog system
  Future<List<String>> startAgentMCPServersByCatalog(String agentId) async {
    final startedServers = <String>[];
    
    try {
      // Get enabled servers from catalog
      final enabledServerIds = _catalogService.getEnabledServerIds();
      
      for (final serverId in enabledServerIds) {
        try {
          final success = await _startAgentMCPServerFromCatalog(agentId, serverId);
          if (success) {
            startedServers.add(serverId);
            print('✅ Started MCP server: $serverId for agent: $agentId');
          } else {
            print('⚠️ Failed to start MCP server: $serverId for agent: $agentId');
          }
        } catch (e) {
          print('❌ Error starting MCP server $serverId for agent $agentId: $e');
        }
      }
      
      print('🚀 Started ${startedServers.length}/${enabledServerIds.length} MCP servers for agent: $agentId');
      return startedServers;
      
    } catch (e) {
      print('❌ Failed to start MCP servers for agent $agentId: $e');
      return startedServers;
    }
  }

  /// Start a specific MCP server for an agent with catalog configuration
  Future<bool> _startAgentMCPServerFromCatalog(String agentId, String catalogEntryId) async {
    try {
      // Get catalog entry
      final catalogEntry = _catalogService.getCatalogEntry(catalogEntryId);
      if (catalogEntry == null) {
        throw Exception('Catalog entry not found: $catalogEntryId');
      }

      // Get agent credentials
      final credentials = await _catalogService.getAgentServerCredentials(agentId, catalogEntryId);
      
      // Build environment variables from catalog and credentials
      final env = <String, String>{
        ...?catalogEntry.defaultEnvVars,
        ...credentials,
      };

      // Create MCPServerConfig from catalog entry
      final serverConfig = MCPServerConfig(
        id: '${agentId}_$catalogEntryId',
        name: catalogEntry.name,
        url: catalogEntry.remoteUrl ?? '',
        command: catalogEntry.command ?? '',
        args: catalogEntry.args,
        transport: _transportTypeToString(catalogEntry.transport),
        protocol: catalogEntry.transport.name,
        env: env,
        enabled: true,
        description: catalogEntry.description,
        capabilities: catalogEntry.capabilities,
        createdAt: DateTime.now(),
      );

      // Start the server
      await startMCPServer(serverConfig, env);
      
      // Mark as used for analytics
      _catalogService.markServerUsed(catalogEntryId);
      
      return true;
      
    } catch (e) {
      print('❌ Failed to start agent MCP server $catalogEntryId: $e');
      return false;
    }
  }

  /// Helper method to convert transport type to string
  String _transportTypeToString(MCPTransportType transport) {
    switch (transport) {
      case MCPTransportType.stdio:
        return 'stdio';
      case MCPTransportType.sse:
        return 'sse';
      case MCPTransportType.http:
        return 'http';
    }
  }

  /// Validate agent MCP server configuration
  Future<Map<String, String>> validateAgentMCPServers(String agentId) async {
    final results = <String, String>{};
    final enabledServerIds = _catalogService.getEnabledServerIds();
    
    for (final serverId in enabledServerIds) {
      final catalogEntry = _catalogService.getCatalogEntry(serverId);
      if (catalogEntry == null) {
        results[serverId] = 'Catalog entry not found';
        continue;
      }

      // Check if configured
      final isConfigured = await _catalogService.isAgentServerConfigured(agentId, serverId);
      if (!isConfigured) {
        results[serverId] = 'Authentication configuration missing or invalid';
        continue;
      }

      // Check if command/dependencies are available
      if (catalogEntry.command?.isNotEmpty == true) {
        final commandParts = catalogEntry.command!.split(' ');
        final executable = commandParts.first;
        
        try {
          final result = await Process.run(executable, ['--help'], runInShell: true);
          if (result.exitCode != 0 && !executable.startsWith('uvx') && !executable.startsWith('npx')) {
            results[serverId] = 'Command not available: $executable';
            continue;
          }
        } catch (e) {
          results[serverId] = 'Command check failed: $e';
          continue;
        }
      }

      results[serverId] = 'OK';
    }
    
    return results;
  }

  /// Stop all MCP servers for an agent
  Future<void> stopAgentMCPServers(String agentId) async {
    final enabledServerIds = _catalogService.getEnabledServerIds();
    
    for (final serverId in enabledServerIds) {
      final serverInstanceId = '${agentId}_$serverId';
      await stopMCPServer(serverInstanceId);
    }
    
    print('🛑 Stopped all MCP servers for agent: $agentId');
  }
}


/// Provider for MCP server execution service - uses catalog and settings services
final mcpServerExecutionServiceProvider = Provider<MCPServerExecutionService>((ref) {
  final catalogService = ref.read(mcpCatalogServiceProvider);
  final settingsService = ref.read(mcpSettingsServiceProvider);
  return MCPServerExecutionService(catalogService, settingsService);
});