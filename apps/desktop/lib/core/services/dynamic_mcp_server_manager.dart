import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_catalog_entry.dart';
import '../models/mcp_server_process.dart';
import '../models/agent_mcp_server_config.dart';
import 'agent_mcp_configuration_service.dart';
import 'mcp_server_execution_service.dart';

/// Manages dynamic installation and execution of MCP servers from GitHub registry
/// Handles runtime installation using uvx, npx, docker, etc.
class DynamicMCPServerManager {
  final AgentMCPConfigurationService _configService;
  final MCPServerExecutionService _executionService;

  // Track running processes for GitHub registry tools
  final Map<String, MCPServerProcess> _runningServers = {};
  final Map<String, DateTime> _installationCache = {};
  static const Duration _installationCacheExpiry = Duration(hours: 24);

  DynamicMCPServerManager(
    this._configService,
    this._executionService,
  );

  /// Install and start MCP servers for an agent from GitHub registry
  Future<List<MCPServerProcess>> startAgentMCPServers(
    String agentId, {
    Map<String, String> additionalEnv = const {},
  }) async {
    final configs = await _configService.getAgentMCPConfigs(agentId);
    final enabledConfigs = configs.where((config) =>
      config.isEnabled && config.autoStart
    ).toList();

    final runningServers = <MCPServerProcess>[];

    for (final config in enabledConfigs) {
      try {
        final serverProcess = await _startMCPServer(config, additionalEnv);
        if (serverProcess != null) {
          runningServers.add(serverProcess);
          _runningServers[serverProcess.id] = serverProcess;
        }
      } catch (e) {
        print('⚠️ Failed to start MCP server ${config.serverId} for agent $agentId: $e');
      }
    }

    return runningServers;
  }

  /// Install and start a specific MCP server from GitHub registry
  Future<MCPServerProcess?> installAndStartMCPServer(
    MCPCatalogEntry catalogEntry, {
    Map<String, String> environment = const {},
    String? agentId,
  }) async {
    try {
      // Check if already running
      final existingServer = _runningServers[catalogEntry.id];
      if (existingServer != null && existingServer.isHealthy) {
        return existingServer;
      }

      // Install if needed
      final isInstalled = await _ensureMCPToolInstalled(catalogEntry);
      if (!isInstalled) {
        throw Exception('Failed to install MCP tool: ${catalogEntry.name}');
      }

      // Create server configuration
      final serverConfig = MCPServerConfig(
        id: catalogEntry.id,
        name: catalogEntry.name,
        url: catalogEntry.remoteUrl ?? 'github://registry/${catalogEntry.id}',
        command: catalogEntry.command,
        args: catalogEntry.args,
        env: {
          ...catalogEntry.defaultEnvVars,
          ...environment,
        },
        workingDirectory: await _getWorkingDirectory(catalogEntry),
        type: 'github_registry',
        enabled: true,
        transportType: catalogEntry.transport,
        requiredEnvVars: catalogEntry.requiredEnvVars,
        optionalEnvVars: catalogEntry.optionalEnvVars,
        setupInstructions: catalogEntry.setupInstructions,
        capabilities: catalogEntry.capabilities,
        description: catalogEntry.description,
      );

      // Start the server
      final serverProcess = await _executionService.startMCPServer(serverConfig, environment);
      _runningServers[serverProcess.id] = serverProcess;

      // Mark as used if associated with agent
      if (agentId != null) {
        await _configService.markMCPServerUsed(agentId, catalogEntry.id);
      }

      return serverProcess;

    } catch (e) {
      print('❌ Failed to install and start MCP server ${catalogEntry.name}: $e');
      return null;
    }
  }

  /// Stop MCP server
  Future<void> stopMCPServer(String serverId) async {
    final server = _runningServers[serverId];
    if (server != null) {
      await _executionService.stopMCPServer(server.id);
      _runningServers.remove(serverId);
    }
  }

  /// Stop all MCP servers for an agent
  Future<void> stopAgentMCPServers(String agentId) async {
    final configs = await _configService.getAgentMCPConfigs(agentId);

    for (final config in configs) {
      await stopMCPServer(config.serverId);
    }
  }

  /// Get status of all running servers
  List<MCPServerProcess> getRunningServers() {
    return _runningServers.values.toList();
  }

  /// Get status of server for agent
  MCPServerProcess? getAgentMCPServer(String agentId, String serverId) {
    return _runningServers[serverId];
  }

  /// Check if MCP tool needs installation
  Future<bool> needsInstallation(MCPCatalogEntry catalogEntry) async {
    // Check installation cache first
    final cacheKey = '${catalogEntry.command}_${catalogEntry.args.join('_')}';
    final cachedInstall = _installationCache[cacheKey];
    if (cachedInstall != null &&
        DateTime.now().difference(cachedInstall) < _installationCacheExpiry) {
      return false;
    }

    // Check if command exists
    switch (catalogEntry.command) {
      case 'uvx':
        return !(await _commandExists('uvx')) || !(await _checkUvxPackage(catalogEntry));
      case 'npx':
        return !(await _commandExists('npx')) || !(await _checkNpmPackage(catalogEntry));
      case 'docker':
        return !(await _commandExists('docker')) || !(await _checkDockerImage(catalogEntry));
      case 'python':
        return !(await _commandExists('python')) || !(await _checkPythonPackage(catalogEntry));
      default:
        return !(await _commandExists(catalogEntry.command));
    }
  }

  /// Install MCP tool if needed
  Future<bool> installMCPTool(MCPCatalogEntry catalogEntry) async {
    if (!(await needsInstallation(catalogEntry))) {
      return true;
    }

    print('📦 Installing MCP tool: ${catalogEntry.name}');

    try {
      switch (catalogEntry.command) {
        case 'uvx':
          return await _installUvxPackage(catalogEntry);
        case 'npx':
          return await _installNpmPackage(catalogEntry);
        case 'docker':
          return await _pullDockerImage(catalogEntry);
        case 'python':
          return await _installPythonPackage(catalogEntry);
        default:
          print('⚠️ Unknown installation method for command: ${catalogEntry.command}');
          return false;
      }
    } catch (e) {
      print('❌ Installation failed for ${catalogEntry.name}: $e');
      return false;
    }
  }

  /// Get installation status for multiple tools
  Future<Map<String, bool>> getInstallationStatus(List<MCPCatalogEntry> catalogEntries) async {
    final status = <String, bool>{};

    for (final entry in catalogEntries) {
      status[entry.id] = !(await needsInstallation(entry));
    }

    return status;
  }

  /// Cleanup stopped servers
  void cleanup() {
    _runningServers.removeWhere((id, server) => !server.isHealthy);
  }

  // Private methods

  Future<MCPServerProcess?> _startMCPServer(
    AgentMCPServerConfig config,
    Map<String, String> additionalEnv,
  ) async {
    // Check if already running
    final existingServer = _runningServers[config.serverId];
    if (existingServer != null && existingServer.isHealthy) {
      return existingServer;
    }

    // Ensure tool is installed
    final catalogEntry = MCPCatalogEntry(
      id: config.serverConfig.id,
      name: config.serverConfig.name,
      description: config.serverConfig.description ?? '',
      command: config.serverConfig.command,
      args: config.serverConfig.args,
      transport: config.serverConfig.transportType,
      capabilities: config.serverConfig.capabilities ?? [],
      requiredEnvVars: config.serverConfig.requiredEnvVars ?? {},
      optionalEnvVars: config.serverConfig.optionalEnvVars ?? {},
      defaultEnvVars: {},
      tags: const [],
      version: null,
      remoteUrl: config.serverConfig.url,
      author: null,
    );

    final isInstalled = await _ensureMCPToolInstalled(catalogEntry);
    if (!isInstalled) {
      throw Exception('Failed to install MCP tool: ${config.serverConfig.name}');
    }

    // Update environment
    final mergedConfig = config.copyWith(
      serverConfig: config.serverConfig.copyWith(
        env: {
          ...config.serverConfig.env ?? {},
          ...config.agentSpecificEnv,
          ...additionalEnv,
        },
      ),
    );

    // Start the server
    final serverProcess = await _executionService.startMCPServer(
      mergedConfig.serverConfig,
      {
        ...mergedConfig.serverConfig.env ?? {},
        ...mergedConfig.agentSpecificEnv,
        ...additionalEnv,
      }
    );
    return serverProcess;
  }

  Future<bool> _ensureMCPToolInstalled(MCPCatalogEntry catalogEntry) async {
    if (await needsInstallation(catalogEntry)) {
      return await installMCPTool(catalogEntry);
    }
    return true;
  }

  Future<bool> _commandExists(String command) async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('where', [command]);
        return result.exitCode == 0;
      } else {
        final result = await Process.run('which', [command]);
        return result.exitCode == 0;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkUvxPackage(MCPCatalogEntry catalogEntry) async {
    if (catalogEntry.args.isEmpty) return false;

    try {
      final packageName = catalogEntry.args.first;
      final result = await Process.run('uvx', ['--help', packageName]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _installUvxPackage(MCPCatalogEntry catalogEntry) async {
    if (catalogEntry.args.isEmpty) return false;

    final packageName = catalogEntry.args.first;
    print('📦 Installing uvx package: $packageName');

    try {
      final result = await Process.run('uv', ['tool', 'install', packageName]);
      final success = result.exitCode == 0;

      if (success) {
        final cacheKey = '${catalogEntry.command}_${catalogEntry.args.join('_')}';
        _installationCache[cacheKey] = DateTime.now();
      }

      return success;
    } catch (e) {
      print('❌ uvx installation failed: $e');
      return false;
    }
  }

  Future<bool> _checkNpmPackage(MCPCatalogEntry catalogEntry) async {
    if (catalogEntry.args.isEmpty) return false;

    try {
      final packageName = catalogEntry.args.first;
      final result = await Process.run('npm', ['list', '-g', packageName]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _installNpmPackage(MCPCatalogEntry catalogEntry) async {
    if (catalogEntry.args.isEmpty) return false;

    final packageName = catalogEntry.args.first;
    print('📦 Installing npm package: $packageName');

    try {
      final result = await Process.run('npm', ['install', '-g', packageName]);
      final success = result.exitCode == 0;

      if (success) {
        final cacheKey = '${catalogEntry.command}_${catalogEntry.args.join('_')}';
        _installationCache[cacheKey] = DateTime.now();
      }

      return success;
    } catch (e) {
      print('❌ npm installation failed: $e');
      return false;
    }
  }

  Future<bool> _checkDockerImage(MCPCatalogEntry catalogEntry) async {
    if (catalogEntry.args.length < 2) return false;

    try {
      final imageName = catalogEntry.args[1]; // args[0] is usually 'run'
      final result = await Process.run('docker', ['images', '-q', imageName]);
      return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _pullDockerImage(MCPCatalogEntry catalogEntry) async {
    if (catalogEntry.args.length < 2) return false;

    final imageName = catalogEntry.args[1];
    print('📦 Pulling Docker image: $imageName');

    try {
      final result = await Process.run('docker', ['pull', imageName]);
      final success = result.exitCode == 0;

      if (success) {
        final cacheKey = '${catalogEntry.command}_${catalogEntry.args.join('_')}';
        _installationCache[cacheKey] = DateTime.now();
      }

      return success;
    } catch (e) {
      print('❌ Docker pull failed: $e');
      return false;
    }
  }

  Future<bool> _checkPythonPackage(MCPCatalogEntry catalogEntry) async {
    if (catalogEntry.args.isEmpty) return false;

    try {
      final packageName = catalogEntry.args.first;
      final result = await Process.run('python', ['-c', 'import $packageName']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _installPythonPackage(MCPCatalogEntry catalogEntry) async {
    if (catalogEntry.args.isEmpty) return false;

    final packageName = catalogEntry.args.first;
    print('📦 Installing Python package: $packageName');

    try {
      final result = await Process.run('pip', ['install', packageName]);
      final success = result.exitCode == 0;

      if (success) {
        final cacheKey = '${catalogEntry.command}_${catalogEntry.args.join('_')}';
        _installationCache[cacheKey] = DateTime.now();
      }

      return success;
    } catch (e) {
      print('❌ pip installation failed: $e');
      return false;
    }
  }

  Future<String?> _getWorkingDirectory(MCPCatalogEntry catalogEntry) async {
    // For most GitHub registry tools, use system temp directory
    if (catalogEntry.command == 'docker') {
      return null; // Docker doesn't need working directory
    }

    try {
      return Directory.systemTemp.path;
    } catch (e) {
      return null;
    }
  }
}

/// Provider for Dynamic MCP Server Manager
final dynamicMCPServerManagerProvider = Provider<DynamicMCPServerManager>((ref) {
  final configService = ref.read(agentMCPConfigurationServiceProvider);
  final executionService = ref.read(mcpServerExecutionServiceProvider);
  return DynamicMCPServerManager(configService, executionService);
});

/// Provider for installation status of MCP tools
final mcpToolInstallationStatusProvider = FutureProvider.family<Map<String, bool>, List<MCPCatalogEntry>>((ref, catalogEntries) async {
  final manager = ref.read(dynamicMCPServerManagerProvider);
  return manager.getInstallationStatus(catalogEntries);
});

/// Provider for running MCP servers
final runningMCPServersProvider = Provider<List<MCPServerProcess>>((ref) {
  final manager = ref.read(dynamicMCPServerManagerProvider);
  return manager.getRunningServers();
});