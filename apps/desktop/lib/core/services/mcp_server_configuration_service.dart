import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mcp_server_configs.dart';

/// Service for managing MCP server configurations and integration
/// This bridges the gap between detected integrations and MCP server configs
class MCPServerConfigurationService {
  
  /// Map detected integration to available MCP servers
  static List<MCPServerConfig> getServersForIntegration(String integrationId) {
    final servers = <MCPServerConfig>[];
    
    switch (integrationId.toLowerCase()) {
      case 'figma':
        final figmaServer = MCPServerLibrary.getServer('figma-official');
        if (figmaServer != null) servers.add(figmaServer);
        break;
        
      case 'github':
      case 'git':
        final githubServer = MCPServerLibrary.getServer('github');
        final gitServer = MCPServerLibrary.getServer('git');
        if (githubServer != null) servers.add(githubServer);
        if (gitServer != null) servers.add(gitServer);
        break;
        
      case 'postgresql':
      case 'postgres':
        final pgServer = MCPServerLibrary.getServer('postgresql');
        if (pgServer != null) servers.add(pgServer);
        break;
        
      case 'sqlite':
        final sqliteServer = MCPServerLibrary.getServer('sqlite');
        if (sqliteServer != null) servers.add(sqliteServer);
        break;
        
      case 'slack':
        final slackServer = MCPServerLibrary.getServer('slack');
        if (slackServer != null) servers.add(slackServer);
        break;
        
      case 'googledrive':
      case 'google-drive':
        final driveServer = MCPServerLibrary.getServer('google-drive');
        if (driveServer != null) servers.add(driveServer);
        break;
        
      case 'notion':
        final notionServer = MCPServerLibrary.getServer('notion');
        if (notionServer != null) servers.add(notionServer);
        break;
        
      case 'linear':
        final linearServer = MCPServerLibrary.getServer('linear');
        if (linearServer != null) servers.add(linearServer);
        break;
        
      case 'jira':
        final jiraServer = MCPServerLibrary.getServer('jira');
        if (jiraServer != null) servers.add(jiraServer);
        break;
        
      case 'discord':
        final discordServer = MCPServerLibrary.getServer('discord');
        if (discordServer != null) servers.add(discordServer);
        break;
        
      case 'docker':
        final dockerServer = MCPServerLibrary.getServer('docker');
        if (dockerServer != null) servers.add(dockerServer);
        break;
        
      case 'airtable':
        final airtableServer = MCPServerLibrary.getServer('airtable');
        if (airtableServer != null) servers.add(airtableServer);
        break;
    }
    
    return servers;
  }
  
  /// Get MCP server configuration ready for agent integration
  static Map<String, dynamic> generateAgentMCPConfig(
    MCPServerConfig server,
    Map<String, String> userEnvVars,
    {String? customPath}
  ) {
    final config = Map<String, dynamic>.from(server.configuration);
    
    // Handle special cases
    if (server.id == 'figma-official') {
      // Figma uses SSE transport
      return {
        server.id: {
          'transport': 'sse',
          'url': 'http://localhost:3845/mcp',
        }
      };
    }
    
    // Handle filesystem server with custom path
    if (server.id == 'filesystem' && customPath != null) {
      config['args'] = ['-y', '@modelcontextprotocol/server-filesystem', customPath];
    }
    
    // Handle SQLite server with custom database path
    if (server.id == 'sqlite' && customPath != null) {
      config['args'] = ['-y', '@modelcontextprotocol/server-sqlite', customPath];
    }
    
    // Add environment variables if provided
    if (userEnvVars.isNotEmpty) {
      config['env'] = userEnvVars;
    }
    
    return {server.id: config};
  }
  
  /// Validate required environment variables are provided
  static ValidationResult validateServerConfig(
    MCPServerConfig server,
    Map<String, String> providedEnvVars
  ) {
    final missingVars = <String>[];
    
    for (final requiredVar in server.requiredEnvVars) {
      if (!providedEnvVars.containsKey(requiredVar) || 
          providedEnvVars[requiredVar]?.isEmpty == true) {
        missingVars.add(requiredVar);
      }
    }
    
    return ValidationResult(
      isValid: missingVars.isEmpty,
      missingEnvVars: missingVars,
      message: missingVars.isEmpty 
        ? 'Configuration is valid'
        : 'Missing required environment variables: ${missingVars.join(', ')}',
    );
  }
  
  /// Get setup instructions with placeholders filled
  static String getSetupInstructions(MCPServerConfig server) {
    var instructions = server.setupInstructions ?? 'No additional setup required.';
    
    // Add environment variable instructions if needed
    if (server.requiredEnvVars.isNotEmpty) {
      instructions += '\n\nRequired environment variables:\n';
      for (final envVar in server.requiredEnvVars) {
        instructions += '• $envVar: ${_getEnvVarDescription(envVar)}\n';
      }
    }
    
    if (server.optionalEnvVars.isNotEmpty) {
      instructions += '\nOptional environment variables:\n';
      for (final envVar in server.optionalEnvVars) {
        instructions += '• $envVar: ${_getEnvVarDescription(envVar)}\n';
      }
    }
    
    return instructions;
  }
  
  /// Get human-readable description for environment variables
  static String _getEnvVarDescription(String envVar) {
    switch (envVar) {
      case 'GITHUB_PERSONAL_ACCESS_TOKEN':
        return 'GitHub Personal Access Token with repo permissions';
      case 'SLACK_BOT_TOKEN':
        return 'Slack Bot User OAuth Token (starts with xoxb-)';
      case 'NOTION_API_KEY':
        return 'Notion Integration API Key';
      case 'NOTION_DATABASE_ID':
        return 'ID of the Notion database to access';
      case 'LINEAR_API_KEY':
        return 'Linear API key from account settings';
      case 'POSTGRES_CONNECTION_STRING':
        return 'PostgreSQL connection string (postgresql://user:pass@host:port/db)';
      case 'BRAVE_API_KEY':
        return 'Brave Search API key';
      case 'GOOGLE_DRIVE_CREDENTIALS_JSON':
        return 'Path to Google Drive API credentials JSON file';
      case 'JIRA_URL':
        return 'Your Jira instance URL (e.g., https://yourcompany.atlassian.net)';
      case 'JIRA_EMAIL':
        return 'Your Jira account email';
      case 'JIRA_API_TOKEN':
        return 'Jira API token from account settings';
      case 'DISCORD_BOT_TOKEN':
        return 'Discord bot token from Developer Portal';
      case 'AIRTABLE_API_KEY':
        return 'Airtable API key from account settings';
      case 'AIRTABLE_BASE_ID':
        return 'ID of the Airtable base to access';
      default:
        return 'Required for authentication';
    }
  }
  
  /// Get recommended servers for new users
  static List<MCPServerConfig> getRecommendedServers() {
    return [
      MCPServerLibrary.getServer('filesystem')!,
      MCPServerLibrary.getServer('git')!,
      MCPServerLibrary.getServer('memory')!,
      MCPServerLibrary.getServer('fetch')!,
    ].where((server) => server != null).cast<MCPServerConfig>().toList();
  }
  
  /// Search servers by name or capability
  static List<MCPServerConfig> searchServers(String query) {
    final lowerQuery = query.toLowerCase();
    return MCPServerLibrary.servers.where((server) =>
      server.name.toLowerCase().contains(lowerQuery) ||
      server.description.toLowerCase().contains(lowerQuery) ||
      server.capabilities.any((cap) => cap.toLowerCase().contains(lowerQuery))
    ).toList();
  }
}

/// Result of server configuration validation
class ValidationResult {
  final bool isValid;
  final List<String> missingEnvVars;
  final String message;
  
  const ValidationResult({
    required this.isValid,
    required this.missingEnvVars,
    required this.message,
  });
}

/// Provider for MCP server configuration service
final mcpServerConfigurationServiceProvider = Provider<MCPServerConfigurationService>((ref) {
  return MCPServerConfigurationService();
});

/// State management for MCP server configurations
class MCPServerConfigurationNotifier extends StateNotifier<List<MCPServerConfig>> {
  MCPServerConfigurationNotifier() : super(MCPServerLibrary.servers);
  
  /// Filter servers by type
  void filterByType(MCPServerType? type) {
    if (type == null) {
      state = MCPServerLibrary.servers;
    } else {
      state = MCPServerLibrary.getServersByType(type);
    }
  }
  
  /// Filter servers by status
  void filterByStatus(MCPServerStatus? status) {
    if (status == null) {
      state = MCPServerLibrary.servers;
    } else {
      state = MCPServerLibrary.getServersByStatus(status);
    }
  }
  
  /// Search servers
  void searchServers(String query) {
    if (query.isEmpty) {
      state = MCPServerLibrary.servers;
    } else {
      state = MCPServerConfigurationService.searchServers(query);
    }
  }
  
  /// Reset to all servers
  void resetFilter() {
    state = MCPServerLibrary.servers;
  }
}

/// Provider for MCP server configuration state
final mcpServerConfigurationProvider = StateNotifierProvider<MCPServerConfigurationNotifier, List<MCPServerConfig>>((ref) {
  return MCPServerConfigurationNotifier();
});