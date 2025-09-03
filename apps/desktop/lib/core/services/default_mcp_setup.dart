import 'mcp_settings_service.dart';

import '../core/models/mcp_server_config.dart';

/// Initialize default MCP servers for testing
class DefaultMCPSetup {
  static Future<void> setupDefaultServers(MCPSettingsService settingsService) async {
    // Only add defaults if no servers exist
    if (settingsService.allMCPServers.isNotEmpty) {
      return;
    }

    print('🔧 Setting up default MCP servers...');

    // Memory MCP Server (no auth needed)
    final memoryServer = MCPServerConfig(
      id: 'memory-mcp',
      name: 'Memory',
      type: 'memory',
      enabled: true,
      command: 'npx', // Use npx instead of uvx for Windows compatibility
      args: ['@modelcontextprotocol/server-memory'],
      workingDirectory: null,
      env: {},
      description: 'Persistent memory and knowledge storage',
      capabilities: ['store_memory', 'recall_memory', 'search_memories'],
      requiredAuth: [],
    );

    // Filesystem MCP Server (no auth needed, safe directory)
    final filesystemServer = MCPServerConfig(
      id: 'filesystem-mcp',
      name: 'File System',
      type: 'filesystem',
      enabled: false, // Disabled by default for security
      command: 'npx',
      args: ['@modelcontextprotocol/server-filesystem', r'C:\Users\Public\Documents'],
      workingDirectory: null,
      env: {},
      description: 'Access and manage local files and directories (Public Documents only)',
      capabilities: ['read_file', 'write_file', 'list_files', 'create_directory'],
      requiredAuth: [],
    );

    // Git MCP Server (no auth needed)
    final gitServer = MCPServerConfig(
      id: 'git-mcp',
      name: 'Git',
      type: 'git',
      enabled: false, // Disabled by default
      command: 'npx',
      args: ['@modelcontextprotocol/server-git'],
      workingDirectory: null,
      env: {},
      description: 'Git repository operations and version control',
      capabilities: ['git_log', 'git_diff', 'git_status', 'git_branch'],
      requiredAuth: [],
    );

    // Time MCP Server (no auth needed)
    final timeServer = MCPServerConfig(
      id: 'time-mcp',
      name: 'Time',
      type: 'time',
      enabled: true,
      command: 'npx',
      args: ['@modelcontextprotocol/server-time'],
      workingDirectory: null,
      env: {},
      description: 'Time and timezone conversion capabilities',
      capabilities: ['time_conversion', 'timezone_handling', 'date_operations'],
      requiredAuth: [],
    );

    // Add servers to settings
    settingsService.addMCPServer(memoryServer);
    settingsService.addMCPServer(filesystemServer);
    settingsService.addMCPServer(gitServer);
    settingsService.addMCPServer(timeServer);

    await settingsService.saveSettings();
    
    print('✅ Default MCP servers added:');
    print('  - Memory MCP (enabled)');
    print('  - Time MCP (enabled)');
    print('  - Filesystem MCP (disabled for security)');
    print('  - Git MCP (disabled by default)');
    print('');
    print('You can enable additional servers in Settings > MCP Servers');
  }
}