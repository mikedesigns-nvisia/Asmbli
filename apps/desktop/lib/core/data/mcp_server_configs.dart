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

    MCPServerConfig(
      id: 'everything',
      name: 'Everything',
      description: 'Reference/test server with prompts, resources, and tools',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-everything'],
      },
      capabilities: ['testing', 'prompts', 'resources', 'tools'],
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'sequential-thinking',
      name: 'Sequential Thinking',
      description: 'Dynamic problem-solving through thought sequences',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-sequential-thinking'],
      },
      capabilities: ['problem_solving', 'thought_sequences', 'reasoning'],
      repositoryUrl: 'https://github.com/modelcontextprotocol/servers',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'time',
      name: 'Time',
      description: 'Time and timezone conversion capabilities',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-time'],
      },
      capabilities: ['time_conversion', 'timezone_handling', 'date_operations'],
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

    // DEVELOPER & DEVOPS TOOLS

    MCPServerConfig(
      id: 'buildkite',
      name: 'Buildkite',
      description: 'Exposing Buildkite data (pipelines, builds, jobs, tests) to AI tooling',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'buildkite-mcp-server'],
      },
      requiredEnvVars: ['BUILDKITE_API_TOKEN', 'BUILDKITE_ORG_SLUG'],
      capabilities: ['pipeline_management', 'build_monitoring', 'job_tracking', 'test_results'],
      setupInstructions: 'Create Buildkite API token with read access',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'buildable',
      name: 'Buildable',
      description: 'Official MCP server for Buildable AI-powered development platform',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'buildable-mcp-server'],
      },
      requiredEnvVars: ['BUILDABLE_API_KEY'],
      capabilities: ['task_management', 'progress_tracking', 'project_context', 'collaboration'],
      setupInstructions: 'Get API key from Buildable platform',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'sentry',
      name: 'Sentry',
      description: 'Error tracking and debugging integration',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'sentry-mcp-server'],
      },
      requiredEnvVars: ['SENTRY_AUTH_TOKEN', 'SENTRY_ORG_SLUG'],
      capabilities: ['error_tracking', 'performance_monitoring', 'release_tracking', 'issue_management'],
      setupInstructions: 'Create Sentry auth token with project permissions',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'circleci',
      name: 'CircleCI',
      description: 'Enable AI Agents to fix build failures from CircleCI',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'circleci-mcp-server'],
      },
      requiredEnvVars: ['CIRCLE_TOKEN'],
      capabilities: ['build_monitoring', 'failure_analysis', 'pipeline_management'],
      setupInstructions: 'Create CircleCI personal API token',
      status: MCPServerStatus.beta,
    ),

    MCPServerConfig(
      id: 'gitguardian',
      name: 'GitGuardian',
      description: 'Scan projects using GitGuardian\'s API with 500+ secret detectors',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'gitguardian-mcp-server'],
      },
      requiredEnvVars: ['GITGUARDIAN_API_KEY'],
      capabilities: ['secret_detection', 'security_scanning', 'vulnerability_analysis', 'remediation'],
      setupInstructions: 'Get API key from GitGuardian dashboard',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'browser-automation',
      name: 'Browser MCP',
      description: 'Automate your local browser',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'browser-mcp-server'],
      },
      capabilities: ['browser_automation', 'web_testing', 'screenshot_capture', 'form_filling'],
      setupInstructions: 'Ensure Chrome or Chromium browser is installed',
      status: MCPServerStatus.beta,
    ),

    MCPServerConfig(
      id: 'gremlin',
      name: 'Gremlin',
      description: 'Official Gremlin MCP server for reliability and chaos engineering',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'gremlin-mcp-server'],
      },
      requiredEnvVars: ['GREMLIN_API_KEY', 'GREMLIN_TEAM_ID'],
      capabilities: ['chaos_engineering', 'reliability_testing', 'experiment_management', 'reporting'],
      setupInstructions: 'Get API key from Gremlin settings',
      status: MCPServerStatus.stable,
    ),

    // CLOUD & INFRASTRUCTURE

    MCPServerConfig(
      id: 'aws-bedrock',
      name: 'AWS Bedrock KB Retrieval',
      description: 'AWS Bedrock Knowledge Base retrieval integration',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'aws-bedrock-mcp-server'],
      },
      requiredEnvVars: ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_REGION'],
      capabilities: ['knowledge_retrieval', 'document_search', 'semantic_search'],
      setupInstructions: 'Configure AWS credentials with Bedrock permissions',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'aws-cdk',
      name: 'AWS CDK',
      description: 'AWS Cloud Development Kit integration',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'aws-cdk-mcp-server'],
      },
      requiredEnvVars: ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_REGION'],
      capabilities: ['infrastructure_as_code', 'stack_management', 'resource_deployment'],
      setupInstructions: 'Configure AWS credentials with CDK permissions',
      status: MCPServerStatus.beta,
    ),

    MCPServerConfig(
      id: 'aws-cost-analysis',
      name: 'AWS Cost Analysis',
      description: 'AWS cost monitoring and analysis',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'aws-cost-mcp-server'],
      },
      requiredEnvVars: ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_REGION'],
      capabilities: ['cost_analysis', 'billing_monitoring', 'usage_tracking'],
      setupInstructions: 'Configure AWS credentials with Cost Explorer permissions',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'cloudflare',
      name: 'Cloudflare',
      description: 'Traffic analysis, performance monitoring, and security management',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'cloudflare-mcp-server'],
      },
      requiredEnvVars: ['CLOUDFLARE_API_TOKEN'],
      capabilities: ['dns_management', 'traffic_analysis', 'security_settings', 'performance_monitoring'],
      setupInstructions: 'Create Cloudflare API token with appropriate permissions',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'vercel',
      name: 'Vercel',
      description: 'Official Vercel MCP server for project and deployment management',
      type: MCPServerType.official,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'vercel-mcp-server'],
      },
      requiredEnvVars: ['VERCEL_API_TOKEN'],
      capabilities: ['project_management', 'deployment_tracking', 'log_analysis', 'domain_management'],
      setupInstructions: 'Create Vercel API token from account settings',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'netlify',
      name: 'Netlify',
      description: 'Create, deploy, and manage websites on Netlify',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'netlify-mcp-server'],
      },
      requiredEnvVars: ['NETLIFY_API_TOKEN'],
      capabilities: ['site_management', 'deployment_tracking', 'form_handling', 'function_management'],
      setupInstructions: 'Create Netlify personal access token',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'azure',
      name: 'Azure MCP Server',
      description: 'Connect AI agents to Azure services like storage, databases, and log analytics',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'azure-mcp-server'],
      },
      requiredEnvVars: ['AZURE_CLIENT_ID', 'AZURE_CLIENT_SECRET', 'AZURE_TENANT_ID'],
      capabilities: ['storage_management', 'database_access', 'log_analytics', 'resource_management'],
      setupInstructions: 'Create Azure service principal with appropriate permissions',
      status: MCPServerStatus.beta,
    ),

    // DATABASE & DATA

    MCPServerConfig(
      id: 'supabase',
      name: 'Supabase',
      description: 'Interact with Supabase: Create tables, query data, deploy edge functions',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'supabase-mcp-server'],
      },
      requiredEnvVars: ['SUPABASE_URL', 'SUPABASE_ANON_KEY'],
      capabilities: ['database_operations', 'table_management', 'edge_functions', 'real_time_subscriptions'],
      setupInstructions: 'Get URL and anon key from Supabase project settings',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'bigquery',
      name: 'BigQuery',
      description: 'Database integration with schema inspection',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'bigquery-mcp-server'],
      },
      requiredEnvVars: ['GOOGLE_APPLICATION_CREDENTIALS'],
      capabilities: ['data_querying', 'schema_inspection', 'dataset_management', 'analytics'],
      setupInstructions: 'Set up Google Cloud service account with BigQuery permissions',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'clickhouse',
      name: 'ClickHouse',
      description: 'Query your ClickHouse database server',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'clickhouse-mcp-server'],
      },
      requiredEnvVars: ['CLICKHOUSE_URL', 'CLICKHOUSE_USER', 'CLICKHOUSE_PASSWORD'],
      capabilities: ['analytical_queries', 'data_aggregation', 'real_time_analytics'],
      setupInstructions: 'Configure ClickHouse connection credentials',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'redis',
      name: 'Redis',
      description: 'Access to Redis databases for key-value operations',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'redis-mcp-server'],
      },
      requiredEnvVars: ['REDIS_URL'],
      capabilities: ['key_value_operations', 'caching', 'pub_sub', 'data_structures'],
      setupInstructions: 'Configure Redis connection URL',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'caldav',
      name: 'CalDAV',
      description: 'Expose calendar operations as tools for AI assistants',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'caldav-mcp-server'],
      },
      requiredEnvVars: ['CALDAV_URL', 'CALDAV_USERNAME', 'CALDAV_PASSWORD'],
      capabilities: ['calendar_management', 'event_creation', 'scheduling', 'availability_checking'],
      setupInstructions: 'Configure CalDAV server credentials',
      status: MCPServerStatus.beta,
    ),

    // BUSINESS & PRODUCTIVITY

    MCPServerConfig(
      id: 'stripe',
      name: 'Stripe',
      description: 'Interact with Stripe API for payment processing',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'stripe-mcp-server'],
      },
      requiredEnvVars: ['STRIPE_SECRET_KEY'],
      capabilities: ['payment_processing', 'customer_management', 'subscription_handling', 'invoice_management'],
      setupInstructions: 'Get secret key from Stripe dashboard',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'twilio',
      name: 'Twilio',
      description: 'Interact with Twilio APIs to send messages',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'twilio-mcp-server'],
      },
      requiredEnvVars: ['TWILIO_ACCOUNT_SID', 'TWILIO_AUTH_TOKEN'],
      capabilities: ['sms_messaging', 'voice_calls', 'whatsapp_messaging', 'email_sending'],
      setupInstructions: 'Get credentials from Twilio console',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'zapier',
      name: 'Zapier',
      description: 'Automate cross-app workflows',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'zapier-mcp-server'],
      },
      requiredEnvVars: ['ZAPIER_API_KEY'],
      capabilities: ['workflow_automation', 'app_integration', 'trigger_management', 'action_execution'],
      setupInstructions: 'Create Zapier API key from developer settings',
      status: MCPServerStatus.beta,
    ),

    MCPServerConfig(
      id: 'box',
      name: 'Box',
      description: 'Interact with the Intelligent Content Management platform through Box AI',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'box-mcp-server'],
      },
      requiredEnvVars: ['BOX_CLIENT_ID', 'BOX_CLIENT_SECRET', 'BOX_ACCESS_TOKEN'],
      capabilities: ['content_management', 'file_operations', 'collaboration', 'ai_insights'],
      setupInstructions: 'Create Box app and get OAuth credentials',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'boost-space',
      name: 'Boost.space',
      description: 'Centralized, automated business data from 2000+ sources',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'boost-space-mcp-server'],
      },
      requiredEnvVars: ['BOOST_SPACE_API_KEY'],
      capabilities: ['data_integration', 'business_analytics', 'automated_workflows', 'multi_source_sync'],
      setupInstructions: 'Get API key from Boost.space platform',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'glean',
      name: 'Glean',
      description: 'Enterprise search and chat using Glean\'s API',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'glean-mcp-server'],
      },
      requiredEnvVars: ['GLEAN_API_TOKEN', 'GLEAN_DOMAIN'],
      capabilities: ['enterprise_search', 'knowledge_discovery', 'contextual_chat', 'document_indexing'],
      setupInstructions: 'Get API token from Glean admin settings',
      status: MCPServerStatus.stable,
    ),

    // DATA & ANALYTICS

    MCPServerConfig(
      id: 'supadata',
      name: 'Supadata',
      description: 'YouTube, TikTok, X and Web data for makers',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'supadata-mcp-server'],
      },
      requiredEnvVars: ['SUPADATA_API_KEY'],
      capabilities: ['social_media_analytics', 'content_tracking', 'trend_analysis', 'engagement_metrics'],
      setupInstructions: 'Register for Supadata API access',
      status: MCPServerStatus.stable,
    ),

    MCPServerConfig(
      id: 'tako',
      name: 'Tako',
      description: 'Real-time financial, sports, weather, and public data with visualization',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', 'tako-mcp-server'],
      },
      requiredEnvVars: ['TAKO_API_KEY'],
      capabilities: ['financial_data', 'sports_data', 'weather_data', 'data_visualization', 'real_time_feeds'],
      setupInstructions: 'Get API key from Tako platform',
      status: MCPServerStatus.beta,
    ),

    // SPECIAL INTEGRATIONS

    MCPServerConfig(
      id: '1mcpserver',
      name: '1mcpserver',
      description: 'MCP of MCPs - Automatically discover and configure MCP servers',
      type: MCPServerType.community,
      configuration: {
        'command': 'npx',
        'args': ['-y', '1mcpserver'],
      },
      capabilities: ['server_discovery', 'auto_configuration', 'mcp_management', 'registry_access'],
      setupInstructions: 'Install to automatically discover other MCP servers on your system',
      status: MCPServerStatus.alpha,
    ),

    MCPServerConfig(
      id: 'atlassian-remote',
      name: 'Atlassian Remote MCP',
      description: 'Official Atlassian remote MCP server for Jira and Confluence Cloud',
      type: MCPServerType.official,
      configuration: {
        'transport': 'sse',
        'url': 'https://mcp.atlassian.com',
      },
      requiredEnvVars: ['ATLASSIAN_API_TOKEN'],
      capabilities: ['jira_integration', 'confluence_access', 'cloud_data_access', 'secure_remote_access'],
      setupInstructions: 'Create Atlassian API token with appropriate permissions',
      documentationUrl: 'https://www.atlassian.com/blog/announcements/remote-mcp-server',
      status: MCPServerStatus.stable,
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