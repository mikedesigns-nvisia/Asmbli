/// MCP Server Configuration Library
/// 
/// This file contains curated MCP server configurations from official and
/// community sources. Each configuration includes setup instructions,
/// authentication requirements, and JSON config examples.

class MCPServerConfig {
  final String id;
  final String name;
  final String description;
  final MCPServerType type;
  final Map<String, dynamic> configuration;
  final List<String> requiredEnvVars;
  final List<String> optionalEnvVars;
  final String? setupInstructions;
  final List<String> capabilities;
  final MCPServerStatus status;
  final String? repositoryUrl;
  final String? documentationUrl;

  const MCPServerConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.configuration,
    this.requiredEnvVars = const [],
    this.optionalEnvVars = const [],
    this.setupInstructions,
    this.capabilities = const [],
    this.status = MCPServerStatus.stable,
    this.repositoryUrl,
    this.documentationUrl,
  });

  /// Convert to JSON format for agent configuration
  Map<String, dynamic> toAgentConfig(Map<String, String> envVars) {
    final config = Map<String, dynamic>.from(configuration);
    
    // Add environment variables if provided
    if (envVars.isNotEmpty) {
      config['env'] = envVars;
    }
    
    return {id: config};
  }
}

enum MCPServerType {
  official,      // Anthropic official servers
  community,     // Community maintained
  experimental,  // Early stage/beta
}

enum MCPServerStatus {
  stable,        // Production ready
  beta,          // Public beta
  alpha,         // Early testing
  deprecated,    // No longer maintained
}

/// Curated library of MCP server configurations
class MCPServerLibrary {
  static const List<MCPServerConfig> servers = [
    
    // OFFICIAL ANTHROPIC SERVERS
    
    MCPServerConfig(
      id: 'filesystem',
      name: 'Filesystem',
      description: 'Secure file operations with configurable access controls',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-filesystem', '/path/to/allowed/files'],
      },
      capabilities: ['file_read', 'file_write', 'directory_list', 'file_search'],
      setupInstructions: 'Replace /path/to/allowed/files with the directory you want to grant access to',
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'git',
      name: 'Git',
      description: 'Tools to read, search, and manipulate Git repositories',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-git'],
      },
      capabilities: ['git_log', 'git_diff', 'git_status', 'git_branch', 'repository_search'],
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'memory',
      name: 'Memory',
      description: 'Knowledge graph-based persistent memory system',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-memory'],
      },
      capabilities: ['knowledge_storage', 'semantic_search', 'context_management'],
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'github',
      name: 'GitHub',
      description: 'GitHub API integration for repositories, issues, and pull requests',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-github'],
      },
      requiredEnvVars: ['GITHUB_PERSONAL_ACCESS_TOKEN'],
      capabilities: ['repo_management', 'issue_tracking', 'pull_requests', 'code_review'],
      setupInstructions: 'Create a GitHub Personal Access Token with repo permissions',
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'brave-search',
      name: 'Brave Search',
      description: 'Web search capabilities using Brave Search API',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-brave-search'],
      },
      requiredEnvVars: ['BRAVE_API_KEY'],
      capabilities: ['web_search', 'real_time_data'],
      setupInstructions: 'Get API key from Brave Search API',
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'postgresql',
      name: 'PostgreSQL',
      description: 'PostgreSQL database operations and queries',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-postgres'],
      },
      requiredEnvVars: ['POSTGRES_CONNECTION_STRING'],
      capabilities: ['database_queries', 'schema_inspection', 'data_analysis'],
      setupInstructions: 'Set POSTGRES_CONNECTION_STRING to your database URL',
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'sqlite',
      name: 'SQLite',
      description: 'SQLite database operations and queries',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-sqlite', '/path/to/database.db'],
      },
      capabilities: ['database_queries', 'schema_inspection', 'local_data_analysis'],
      setupInstructions: 'Replace /path/to/database.db with your SQLite file path',
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'slack',
      name: 'Slack',
      description: 'Slack workspace integration for channels and messaging',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-slack'],
      },
      requiredEnvVars: ['SLACK_BOT_TOKEN'],
      capabilities: ['channel_management', 'messaging', 'file_sharing', 'user_management'],
      setupInstructions: 'Create Slack App and get Bot User OAuth Token',
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'google-drive',
      name: 'Google Drive',
      description: 'Google Drive file operations and management',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-gdrive'],
      },
      requiredEnvVars: ['GOOGLE_DRIVE_CREDENTIALS_JSON'],
      capabilities: ['file_management', 'document_access', 'folder_operations'],
      setupInstructions: 'Set up Google Drive API credentials and download JSON key file',
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'puppeteer',
      name: 'Puppeteer',
      description: 'Browser automation and web scraping',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-puppeteer'],
      },
      capabilities: ['web_automation', 'screenshot_capture', 'pdf_generation', 'web_scraping'],
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'fetch',
      name: 'Fetch',
      description: 'Web content fetching and conversion for efficient LLM usage',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-fetch'],
      },
      capabilities: ['web_fetching', 'content_conversion', 'html_processing'],
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    // SPECIAL SERVERS
    
    MCPServerConfig(
      id: 'figma-official',
      name: 'Figma Dev Mode MCP Server',
      description: 'Official Figma MCP server for design file access',
      type: MCPServerType.official,
      configuration: {
        'transport': 'sse',
        'url': 'http://localhost:3845/mcp',
      },
      capabilities: ['design_file_access', 'component_data', 'dev_mode_integration'],
      setupInstructions: 'Open Figma Desktop → Preferences → Enable "Dev Mode MCP Server"',
      documentationUrl: 'https://www.figma.com/developers/docs',
      status: MCPServerStatus.beta,
    ),

    // COMMUNITY SERVERS

    MCPServerConfig(
      id: 'notion',
      name: 'Notion',
      description: 'Notion workspace integration for pages and databases',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'notion-mcp-server'],
      },
      requiredEnvVars: ['NOTION_API_KEY', 'NOTION_DATABASE_ID'],
      capabilities: ['page_management', 'database_operations', 'content_search'],
      setupInstructions: 'Create Notion integration and get API key',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'linear',
      name: 'Linear',
      description: 'Linear issue tracking and project management',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'linear-mcp-server'],
      },
      requiredEnvVars: ['LINEAR_API_KEY'],
      capabilities: ['issue_management', 'project_tracking', 'team_collaboration'],
      setupInstructions: 'Get API key from Linear settings',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'docker',
      name: 'Docker',
      description: 'Docker container management and operations',
      type: MCPServerType.community,
      configuration: {
        'command': 'python',
        'args': ['-m', 'docker_mcp_server'],
      },
      capabilities: ['container_management', 'image_operations', 'docker_compose'],
      setupInstructions: 'Ensure Docker is installed and running',
      repositoryUrl: 'https://github.com/docker/docker-mcp-server',
      status: MCPServerStatus.beta,
    ),

    MCPServerConfig(
      id: 'jira',
      name: 'Jira',
      description: 'Atlassian Jira project management and issue tracking',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'jira-mcp-server'],
      },
      requiredEnvVars: ['JIRA_URL', 'JIRA_EMAIL', 'JIRA_API_TOKEN'],
      capabilities: ['issue_management', 'project_tracking', 'sprint_planning'],
      setupInstructions: 'Create Jira API token in account settings',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'airtable',
      name: 'Airtable',
      description: 'Airtable database operations and base management',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'airtable-mcp-server'],
      },
      requiredEnvVars: ['AIRTABLE_API_KEY', 'AIRTABLE_BASE_ID'],
      capabilities: ['database_operations', 'record_management', 'view_access'],
      setupInstructions: 'Get API key from Airtable account settings',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'discord',
      name: 'Discord',
      description: 'Discord server management and messaging',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'discord-mcp-server'],
      },
      requiredEnvVars: ['DISCORD_BOT_TOKEN'],
      capabilities: ['server_management', 'channel_operations', 'message_handling'],
      setupInstructions: 'Create Discord bot and get token from Discord Developer Portal',
      status: MCPServerStatus.beta,
    ),

  ];

  /// Get server by ID
  static MCPServerConfig? getServer(String id) {
    try {
      return servers.firstWhere((server) => server.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get servers by type
  static List<MCPServerConfig> getServersByType(MCPServerType type) {
    return servers.where((server) => server.type == type).toList();
  }

  /// Get servers by status
  static List<MCPServerConfig> getServersByStatus(MCPServerStatus status) {
    return servers.where((server) => server.status == status).toList();
  }

  /// Get all official stable servers
  static List<MCPServerConfig> getOfficialStableServers() {
    return servers.where((server) => 
      server.type == MCPServerType.official && 
      server.status == MCPServerStatus.stable
    ).toList();
  }

  /// Search servers by capability
  static List<MCPServerConfig> searchByCapability(String capability) {
    return servers.where((server) => 
      server.capabilities.any((cap) => 
        cap.toLowerCase().contains(capability.toLowerCase())
      )
    ).toList();
  }

  /// Get servers that require authentication
  static List<MCPServerConfig> getServersRequiringAuth() {
    return servers.where((server) => server.requiredEnvVars.isNotEmpty).toList();
  }

  /// Get servers that work without authentication  
  static List<MCPServerConfig> getServersWithoutAuth() {
    return servers.where((server) => server.requiredEnvVars.isEmpty).toList();
  }
}