import 'mcp_settings_service.dart';

import '../models/mcp_server_config.dart';

/// Default MCP server setup (removed fake defaults)
class DefaultMCPSetup {
  static Future<void> setupDefaultServers(MCPSettingsService settingsService) async {
    // No default servers - users must install MCP servers manually
    print('ℹ️  No default MCP servers configured.');
    print('   Install MCP servers manually using npm or the marketplace.');
    print('   Example: npm install -g @modelcontextprotocol/server-filesystem');
  }
}