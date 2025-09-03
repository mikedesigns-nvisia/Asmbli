import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../data/mcp_server_configs.dart';


import '../models/mcp_server_config.dart';

/// Service for managing MCP server installation lifecycle
/// Based on Model Context Protocol documentation and best practices
class MCPInstallationService {
  
  /// Check if MCP servers for an agent need installation
  static Future<List<MCPServerInstallation>> checkAgentMCPRequirements(Agent agent) async {
    final requiredInstallations = <MCPServerInstallation>[];
    
    // Extract MCP servers from agent configuration
    final mcpServers = agent.configuration['mcpServers'] as List<dynamic>? ?? [];
    
    for (final serverRef in mcpServers) {
      final serverId = serverRef is String ? serverRef : serverRef['id'] as String?;
      if (serverId == null) continue;
      
      final serverConfig = MCPServerLibrary.getServer(serverId);
      if (serverConfig == null) continue;
      
      // Check if server needs installation
      final installationStatus = await _checkServerInstallationStatus(serverConfig);
      if (installationStatus.requiresInstallation) {
        requiredInstallations.add(installationStatus);
      }
    }
    
    return requiredInstallations;
  }
  
  /// Check installation status of a specific MCP server
  static Future<MCPServerInstallation> _checkServerInstallationStatus(MCPServerLibraryConfig server) async {
    try {
      // Handle different server types
      switch (server.type) {
        case MCPServerType.official:
          return await _checkOfficialServerStatus(server);
        case MCPServerType.community:
          return await _checkCommunityServerStatus(server);
        case MCPServerType.experimental:
          return await _checkExperimentalServerStatus(server);
        default:
          return MCPServerInstallation(
            server: server,
            requiresInstallation: true,
            installationMethod: MCPInstallationMethod.npm,
            reason: 'Unknown server type: ${server.type}',
          );
      }
    } catch (e) {
      return MCPServerInstallation(
        server: server,
        requiresInstallation: true,
        installationMethod: MCPInstallationMethod.npm,
        reason: 'Failed to check installation status: $e',
      );
    }
  }
  
  /// Check official Anthropic MCP server status
  static Future<MCPServerInstallation> _checkOfficialServerStatus(MCPServerLibraryConfig server) async {
    // Official servers use npx with @modelcontextprotocol packages
    final args = server.configuration['args'] as List?;
    final packageName = args != null && args.length > 1 ? args[1] : null;
    if (packageName == null) {
      return MCPServerInstallation(
        server: server,
        requiresInstallation: true,
        installationMethod: MCPInstallationMethod.npm,
        reason: 'Package name not found in configuration',
      );
    }
    
    // Check if npx can resolve the package
    final result = await Process.run('npx', ['--dry-run', packageName], runInShell: true);
    
    return MCPServerInstallation(
      server: server,
      requiresInstallation: result.exitCode != 0,
      installationMethod: MCPInstallationMethod.npm,
      reason: result.exitCode != 0 ? 'Package not available via npx' : 'Already available',
      installCommand: ['npx', '-y', packageName],
    );
  }
  
  /// Check community MCP server status
  static Future<MCPServerInstallation> _checkCommunityServerStatus(MCPServerLibraryConfig server) async {
    // Community servers may use different package managers
    final command = server.configuration['command'] as String? ?? '';
    final args = server.configuration['args'] as List? ?? [];
    
    if (command.isEmpty || args.isEmpty) {
      return MCPServerInstallation(
        server: server,
        requiresInstallation: true,
        installationMethod: MCPInstallationMethod.npm,
        reason: 'Invalid server configuration',
      );
    }
    
    // Check if command is available
    final result = await Process.run('where', [command], runInShell: true);
    if (result.exitCode != 0) {
      return MCPServerInstallation(
        server: server,
        requiresInstallation: true,
        installationMethod: _getInstallationMethod(command),
        reason: 'Command not found: $command',
      );
    }
    
    // For npx packages, check if package exists
    if (command == 'npx' && args.length > 1) {
      final packageName = args[1];
      final packageResult = await Process.run('npx', ['--dry-run', packageName], runInShell: true);
      
      return MCPServerInstallation(
        server: server,
        requiresInstallation: packageResult.exitCode != 0,
        installationMethod: MCPInstallationMethod.npm,
        reason: packageResult.exitCode != 0 ? 'Package not available: $packageName' : 'Already available',
        installCommand: ['npx', '-y', packageName],
      );
    }
    
    return MCPServerInstallation(
      server: server,
      requiresInstallation: false,
      installationMethod: _getInstallationMethod(command),
      reason: 'Command available',
    );
  }
  
  /// Check experimental MCP server status
  static Future<MCPServerInstallation> _checkExperimentalServerStatus(MCPServerLibraryConfig server) async {
    // Experimental servers may require special handling
    return MCPServerInstallation(
      server: server,
      requiresInstallation: true,
      installationMethod: MCPInstallationMethod.manual,
      reason: 'Experimental server - manual installation required',
    );
  }
  
  /// Install required MCP servers
  static Future<MCPInstallationResult> installMCPServers(List<MCPServerInstallation> installations) async {
    final results = <String, bool>{};
    final errors = <String, String>{};
    
    for (final installation in installations) {
      try {
        final success = await _installSingleServer(installation);
        results[installation.server.id] = success;
        
        if (!success) {
          errors[installation.server.id] = 'Installation failed';
        }
      } catch (e) {
        results[installation.server.id] = false;
        errors[installation.server.id] = e.toString();
      }
    }
    
    return MCPInstallationResult(
      success: errors.isEmpty,
      installedServers: results.keys.where((id) => results[id] == true).toList(),
      failedServers: errors,
    );
  }
  
  /// Install a single MCP server
  static Future<bool> _installSingleServer(MCPServerInstallation installation) async {
    switch (installation.installationMethod) {
      case MCPInstallationMethod.npm:
        return await _installNpmServer(installation);
      case MCPInstallationMethod.pip:
        return await _installPipServer(installation);
      case MCPInstallationMethod.manual:
        // Manual installation requires user intervention
        return false;
      case MCPInstallationMethod.git:
        return await _installGitServer(installation);
    }
  }
  
  /// Install NPM-based MCP server
  static Future<bool> _installNpmServer(MCPServerInstallation installation) async {
    final command = installation.installCommand ?? ['npm', 'install', '-g'];
    
    // For npx packages, we don't need to pre-install them
    // npx will install on demand
    if (command[0] == 'npx') {
      return true; // npx handles installation automatically
    }
    
    final result = await Process.run(
      command[0], 
      command.sublist(1),
      runInShell: true,
    );
    
    return result.exitCode == 0;
  }
  
  /// Install Python-based MCP server
  static Future<bool> _installPipServer(MCPServerInstallation installation) async {
    final command = installation.installCommand ?? ['pip', 'install'];
    
    final result = await Process.run(
      command[0],
      command.sublist(1),
      runInShell: true,
    );
    
    return result.exitCode == 0;
  }
  
  /// Install Git-based MCP server
  static Future<bool> _installGitServer(MCPServerInstallation installation) async {
    // Implementation for git-based installations
    // This would clone repositories and set up the server
    return false; // Placeholder
  }
  
  /// Determine installation method based on command
  static MCPInstallationMethod _getInstallationMethod(String command) {
    switch (command.toLowerCase()) {
      case 'npx':
      case 'npm':
      case 'node':
        return MCPInstallationMethod.npm;
      case 'python':
      case 'python3':
      case 'pip':
        return MCPInstallationMethod.pip;
      case 'git':
        return MCPInstallationMethod.git;
      default:
        return MCPInstallationMethod.manual;
    }
  }
  
  /// Check if agent should trigger MCP installation on load
  static Future<bool> shouldInstallMCPOnAgentLoad(Agent agent, String conversationId) async {
    // Check if this is the first time this agent is used in this conversation
    final isFirstUse = await _isFirstAgentUseInConversation(agent.id, conversationId);
    
    if (!isFirstUse) {
      return false; // Don't install if agent was already used
    }
    
    // Check if agent has MCP servers configured
    final mcpServers = agent.configuration['mcpServers'] as List<dynamic>? ?? [];
    if (mcpServers.isEmpty) {
      return false; // No MCP servers to install
    }
    
    // Check if any servers need installation
    final requirements = await checkAgentMCPRequirements(agent);
    return requirements.any((req) => req.requiresInstallation);
  }
  
  /// Track agent usage in conversations
  static Future<bool> _isFirstAgentUseInConversation(String agentId, String conversationId) async {
    // This would typically check a database or cache
    // For now, return true (always install on first conversation load)
    // TODO: Implement proper tracking
    return true;
  }
  
  /// Mark agent as used in conversation
  static Future<void> markAgentUsedInConversation(String agentId, String conversationId) async {
    // TODO: Implement usage tracking
  }
}

/// Represents an MCP server installation requirement
class MCPServerInstallation {
  final MCPServerLibraryConfig server;
  final bool requiresInstallation;
  final MCPInstallationMethod installationMethod;
  final String reason;
  final List<String>? installCommand;
  
  const MCPServerInstallation({
    required this.server,
    required this.requiresInstallation,
    required this.installationMethod,
    required this.reason,
    this.installCommand,
  });
}

/// Installation methods for MCP servers
enum MCPInstallationMethod {
  npm,    // Node.js package manager
  pip,    // Python package manager
  git,    // Git repository
  manual, // Manual installation required
}

/// Result of MCP server installations
class MCPInstallationResult {
  final bool success;
  final List<String> installedServers;
  final Map<String, String> failedServers;
  
  const MCPInstallationResult({
    required this.success,
    required this.installedServers,
    required this.failedServers,
  });
}

/// Provider for MCP installation service
final mcpInstallationServiceProvider = Provider<MCPInstallationService>((ref) {
  return MCPInstallationService();
});