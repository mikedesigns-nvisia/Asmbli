import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mcp_server_configs.dart';
import 'context_mcp_resource_service.dart';

/// Service for managing MCP server configurations and integration
/// This bridges the gap between detected integrations and MCP server configs
@Deprecated('Will be consolidated into MCPServerService. See docs/SERVICE_CONSOLIDATION_PLAN.md')
class MCPServerLibraryConfigurationService {
  
  /// Map detected integration to available MCP servers
  static List<MCPServerLibraryConfig> getServersForIntegration(String integrationId) {
    final servers = <MCPServerLibraryConfig>[];
    
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

      // NEW SERVERS - Developer & DevOps Tools
      case 'buildkite':
        final server = MCPServerLibrary.getServer('buildkite');
        if (server != null) servers.add(server);
        break;
      
      case 'buildable':
        final server = MCPServerLibrary.getServer('buildable');
        if (server != null) servers.add(server);
        break;
      
      case 'sentry':
        final server = MCPServerLibrary.getServer('sentry');
        if (server != null) servers.add(server);
        break;
      
      case 'circleci':
        final server = MCPServerLibrary.getServer('circleci');
        if (server != null) servers.add(server);
        break;
      
      case 'gitguardian':
        final server = MCPServerLibrary.getServer('gitguardian');
        if (server != null) servers.add(server);
        break;
      
      case 'browser':
      case 'browser-automation':
        final server = MCPServerLibrary.getServer('browser-automation');
        if (server != null) servers.add(server);
        break;
      
      case 'gremlin':
        final server = MCPServerLibrary.getServer('gremlin');
        if (server != null) servers.add(server);
        break;

      // Cloud & Infrastructure
      case 'aws':
      case 'aws-bedrock':
        final server = MCPServerLibrary.getServer('aws-bedrock');
        if (server != null) servers.add(server);
        break;
      
      case 'aws-cdk':
        final server = MCPServerLibrary.getServer('aws-cdk');
        if (server != null) servers.add(server);
        break;
      
      case 'aws-cost':
      case 'aws-cost-analysis':
        final server = MCPServerLibrary.getServer('aws-cost-analysis');
        if (server != null) servers.add(server);
        break;
      
      case 'cloudflare':
        final server = MCPServerLibrary.getServer('cloudflare');
        if (server != null) servers.add(server);
        break;
      
      case 'vercel':
        final server = MCPServerLibrary.getServer('vercel');
        if (server != null) servers.add(server);
        break;
      
      case 'netlify':
        final server = MCPServerLibrary.getServer('netlify');
        if (server != null) servers.add(server);
        break;
      
      case 'azure':
        final server = MCPServerLibrary.getServer('azure');
        if (server != null) servers.add(server);
        break;

      // Database & Data
      case 'supabase':
        final server = MCPServerLibrary.getServer('supabase');
        if (server != null) servers.add(server);
        break;
      
      case 'bigquery':
        final server = MCPServerLibrary.getServer('bigquery');
        if (server != null) servers.add(server);
        break;
      
      case 'clickhouse':
        final server = MCPServerLibrary.getServer('clickhouse');
        if (server != null) servers.add(server);
        break;
      
      case 'redis':
        final server = MCPServerLibrary.getServer('redis');
        if (server != null) servers.add(server);
        break;
      
      case 'caldav':
        final server = MCPServerLibrary.getServer('caldav');
        if (server != null) servers.add(server);
        break;

      // Business & Productivity
      case 'stripe':
        final server = MCPServerLibrary.getServer('stripe');
        if (server != null) servers.add(server);
        break;
      
      case 'twilio':
        final server = MCPServerLibrary.getServer('twilio');
        if (server != null) servers.add(server);
        break;
      
      case 'zapier':
        final server = MCPServerLibrary.getServer('zapier');
        if (server != null) servers.add(server);
        break;
      
      case 'box':
        final server = MCPServerLibrary.getServer('box');
        if (server != null) servers.add(server);
        break;
      
      case 'boost-space':
        final server = MCPServerLibrary.getServer('boost-space');
        if (server != null) servers.add(server);
        break;
      
      case 'glean':
        final server = MCPServerLibrary.getServer('glean');
        if (server != null) servers.add(server);
        break;

      // Data & Analytics
      case 'supadata':
        final server = MCPServerLibrary.getServer('supadata');
        if (server != null) servers.add(server);
        break;
      
      case 'tako':
        final server = MCPServerLibrary.getServer('tako');
        if (server != null) servers.add(server);
        break;

      // Special Integrations
      case '1mcpserver':
      case 'mcp-server':
        final server = MCPServerLibrary.getServer('1mcpserver');
        if (server != null) servers.add(server);
        break;
      
      case 'atlassian':
      case 'atlassian-remote':
        final server = MCPServerLibrary.getServer('atlassian-remote');
        if (server != null) servers.add(server);
        break;

      // Official Reference Servers
      case 'everything':
        final server = MCPServerLibrary.getServer('everything');
        if (server != null) servers.add(server);
        break;
      
      case 'sequential-thinking':
        final server = MCPServerLibrary.getServer('sequential-thinking');
        if (server != null) servers.add(server);
        break;
      
      case 'time':
        final server = MCPServerLibrary.getServer('time');
        if (server != null) servers.add(server);
        break;

      // Continue.dev integration
      case 'continue-dev':
      case 'continue':
        final server = MCPServerLibrary.getServer('continue-dev');
        if (server != null) servers.add(server);
        break;
    }
    
    return servers;
  }
  
  /// Get MCP server configuration ready for agent integration
  /// Following MCP standards from Hugging Face course documentation
  static Map<String, dynamic> generateAgentMCPConfig(
    MCPServerLibraryConfig server,
    Map<String, String> userEnvVars,
    {String? customPath}
  ) {
    final config = Map<String, dynamic>.from(server.configuration);
    
    // Handle special transport cases (HTTP+SSE)
    if (server.id == 'figma-official') {
      // Figma uses SSE transport as per MCP course standards
      return {
        server.id: {
          'transport': 'sse',
          'url': 'http://localhost:3845/mcp',
          'mcpVersion': '2024-11-05',
          'capabilities': {
            'tools': server.capabilities.contains('design_file_access'),
            'resources': server.capabilities.contains('component_data'),
            'prompts': false,
            'sampling': false,
          }
        }
      };
    }

    // Handle remote servers (Atlassian)
    if (server.id == 'atlassian-remote') {
      return {
        server.id: {
          'transport': 'sse',
          'url': 'https://mcp.atlassian.com',
          'mcpVersion': '2024-11-05',
          'env': userEnvVars,
          'capabilities': {
            'tools': true,
            'resources': true, 
            'prompts': true,
            'sampling': false,
          }
        }
      };
    }
    
    // Handle filesystem server with custom path (stdio transport)
    if (server.id == 'filesystem' && customPath != null) {
      config['args'] = ['-y', '@modelcontextprotocol/server-filesystem', customPath];
    }
    
    // Handle SQLite server with custom database path (stdio transport)
    if (server.id == 'sqlite' && customPath != null) {
      config['args'] = ['-y', '@modelcontextprotocol/server-sqlite', customPath];
    }
    
    // Add environment variables if provided
    if (userEnvVars.isNotEmpty) {
      config['env'] = userEnvVars;
    }

    // Add MCP protocol compliance metadata
    config['mcpVersion'] = '2024-11-05';
    config['transport'] = 'stdio'; // Default transport for most servers
    
    // Add capability mapping based on server capabilities
    config['capabilities'] = {
      'tools': server.capabilities.any((cap) => cap.contains('management') || cap.contains('operations') || cap.contains('tracking')),
      'resources': server.capabilities.any((cap) => cap.contains('data') || cap.contains('file') || cap.contains('search')),
      'prompts': server.capabilities.contains('prompts') || server.id == 'everything',
      'sampling': server.capabilities.contains('sampling') || server.id == 'sequential-thinking',
    };
    
    return {server.id: config};
  }

  /// Generate complete MCP configuration for an agent including context resources
  static Future<Map<String, dynamic>> generateCompleteAgentMCPConfig(
    String agentId,
    List<MCPServerLibraryConfig> servers,
    Map<String, String> userEnvVars,
    dynamic ref, // Accept both WidgetRef and Ref
  ) async {
    final config = <String, dynamic>{};
    
    // Add all configured MCP servers
    for (final server in servers) {
      final serverConfig = generateAgentMCPConfig(server, userEnvVars);
      config.addAll(serverConfig);
    }
    
    // Check if agent should have context resources
    final shouldAddContext = await ContextMCPResourceService.shouldEnableContextResources(agentId, ref);
    
    if (shouldAddContext) {
      // Add context resources server configuration
      final contextConfig = ContextMCPResourceService.generateContextResourceServerConfig(agentId);
      config.addAll(contextConfig);
    }
    
    return config;
  }
  
  /// Validate required environment variables are provided
  static ValidationResult validateServerConfig(
    MCPServerLibraryConfig server,
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
  static String getSetupInstructions(MCPServerLibraryConfig server) {
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
      
      // New server environment variables
      case 'BUILDKITE_API_TOKEN':
        return 'Buildkite API token with read access';
      case 'BUILDKITE_ORG_SLUG':
        return 'Your Buildkite organization slug';
      case 'BUILDABLE_API_KEY':
        return 'API key from Buildable platform';
      case 'SENTRY_AUTH_TOKEN':
        return 'Sentry auth token with project permissions';
      case 'SENTRY_ORG_SLUG':
        return 'Your Sentry organization slug';
      case 'CIRCLE_TOKEN':
        return 'CircleCI personal API token';
      case 'GITGUARDIAN_API_KEY':
        return 'GitGuardian API key from dashboard';
      case 'GREMLIN_API_KEY':
        return 'Gremlin API key from settings';
      case 'GREMLIN_TEAM_ID':
        return 'Your Gremlin team ID';
      
      // Cloud & Infrastructure
      case 'AWS_ACCESS_KEY_ID':
        return 'AWS access key ID with appropriate permissions';
      case 'AWS_SECRET_ACCESS_KEY':
        return 'AWS secret access key';
      case 'AWS_REGION':
        return 'AWS region (e.g., us-east-1)';
      case 'CLOUDFLARE_API_TOKEN':
        return 'Cloudflare API token with appropriate permissions';
      case 'VERCEL_API_TOKEN':
        return 'Vercel API token from account settings';
      case 'NETLIFY_API_TOKEN':
        return 'Netlify personal access token';
      case 'AZURE_CLIENT_ID':
        return 'Azure service principal client ID';
      case 'AZURE_CLIENT_SECRET':
        return 'Azure service principal client secret';
      case 'AZURE_TENANT_ID':
        return 'Azure tenant ID';
      
      // Database & Data
      case 'SUPABASE_URL':
        return 'Supabase project URL';
      case 'SUPABASE_ANON_KEY':
        return 'Supabase anon/public key';
      case 'GOOGLE_APPLICATION_CREDENTIALS':
        return 'Path to Google Cloud service account JSON file';
      case 'CLICKHOUSE_URL':
        return 'ClickHouse server URL';
      case 'CLICKHOUSE_USER':
        return 'ClickHouse username';
      case 'CLICKHOUSE_PASSWORD':
        return 'ClickHouse password';
      case 'REDIS_URL':
        return 'Redis connection URL';
      case 'CALDAV_URL':
        return 'CalDAV server URL';
      case 'CALDAV_USERNAME':
        return 'CalDAV username';
      case 'CALDAV_PASSWORD':
        return 'CalDAV password';
      
      // Business & Productivity
      case 'STRIPE_SECRET_KEY':
        return 'Stripe secret key from dashboard';
      case 'TWILIO_ACCOUNT_SID':
        return 'Twilio Account SID';
      case 'TWILIO_AUTH_TOKEN':
        return 'Twilio Auth Token';
      case 'ZAPIER_API_KEY':
        return 'Zapier API key from developer settings';
      case 'BOX_CLIENT_ID':
        return 'Box app client ID';
      case 'BOX_CLIENT_SECRET':
        return 'Box app client secret';
      case 'BOX_ACCESS_TOKEN':
        return 'Box access token';
      case 'BOOST_SPACE_API_KEY':
        return 'Boost.space API key';
      case 'GLEAN_API_TOKEN':
        return 'Glean API token from admin settings';
      case 'GLEAN_DOMAIN':
        return 'Your Glean domain';
      
      // Data & Analytics
      case 'SUPADATA_API_KEY':
        return 'Supadata API key';
      case 'TAKO_API_KEY':
        return 'Tako API key from platform';
      
      // Special Integrations
      case 'ATLASSIAN_API_TOKEN':
        return 'Atlassian API token with appropriate permissions';
      
      // Continue.dev environment variables
      case 'CONTINUE_API_PROVIDER':
        return 'AI provider (openai, claude, ollama, local)';
      case 'CONTINUE_API_KEY':
        return 'API key for chosen provider (not needed for Ollama/local)';
      case 'CONTINUE_MODEL_NAME':
        return 'Model name (e.g., gpt-4, claude-3, llama3)';
      case 'CONTINUE_CONTEXT_LENGTH':
        return 'Maximum context length for the model (default: 4096)';
      
      default:
        return 'Required for authentication';
    }
  }
  
  /// Get recommended servers for new users
  static List<MCPServerLibraryConfig> getRecommendedServers() {
    return [
      MCPServerLibrary.getServer('filesystem')!,
      MCPServerLibrary.getServer('git')!,
      MCPServerLibrary.getServer('memory')!,
      MCPServerLibrary.getServer('fetch')!,
    ].where((server) => server != null).cast<MCPServerLibraryConfig>().toList();
  }
  
  /// Search servers by name or capability
  static List<MCPServerLibraryConfig> searchServers(String query) {
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
final mcpServerConfigurationServiceProvider = Provider<MCPServerLibraryConfigurationService>((ref) {
  return MCPServerLibraryConfigurationService();
});

/// State management for MCP server configurations
class MCPServerLibraryConfigurationNotifier extends StateNotifier<List<MCPServerLibraryConfig>> {
  MCPServerLibraryConfigurationNotifier() : super(MCPServerLibrary.servers);
  
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
      state = MCPServerLibraryConfigurationService.searchServers(query);
    }
  }
  
  /// Reset to all servers
  void resetFilter() {
    state = MCPServerLibrary.servers;
  }
}

/// Provider for MCP server configuration state
final mcpServerConfigurationProvider = StateNotifierProvider<MCPServerLibraryConfigurationNotifier, List<MCPServerLibraryConfig>>((ref) {
  return MCPServerLibraryConfigurationNotifier();
});