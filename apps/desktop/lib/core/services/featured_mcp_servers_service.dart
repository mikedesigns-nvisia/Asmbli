import '../models/mcp_catalog_entry.dart';
import '../models/mcp_server_category.dart';
import 'github_mcp_registry_service.dart';

/// Service for managing featured and official MCP servers
/// Provides curated list of high-quality servers from official sources
@Deprecated('Will be consolidated into MCPCatalogService. See docs/SERVICE_CONSOLIDATION_PLAN.md')
class FeaturedMCPServersService {
  static const List<Map<String, dynamic>> _featuredServers = [
    // Official Microsoft Servers
    {
      'id': 'markitdown',
      'name': 'Markitdown',
      'description': 'Convert various file formats (PDF, Word, Excel, images, audio) to Markdown.',
      'command': 'uvx markitdown',
      'args': [],
      'repository': 'https://github.com/microsoft/markitdown',
      'category': 'productivity',
      'isOfficial': true,
      'tags': ['file-conversion', 'markdown', 'microsoft', 'productivity'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'playwright-mcp',
      'name': 'Playwright MCP',
      'description': 'Automate web browsers using accessibility trees for testing and data extraction.',
      'command': 'uvx playwright-mcp',
      'args': [],
      'repository': 'https://github.com/microsoft/playwright-mcp',
      'category': 'development',
      'isOfficial': true,
      'tags': ['browser-automation', 'testing', 'microsoft', 'web-scraping'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },

    // Official GitHub Server
    {
      'id': 'github-mcp-server',
      'name': 'GitHub MCP Server',
      'description': 'Official GitHub MCP Server that connects AI tools directly to GitHub\'s platform.',
      'command': 'uvx github-mcp-server',
      'args': [],
      'repository': 'https://github.com/github/github-mcp-server',
      'category': 'development',
      'isOfficial': true,
      'tags': ['github', 'version-control', 'official', 'development'],
      'capabilities': ['tools', 'resources'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'GITHUB_TOKEN': 'GitHub personal access token'
      },
    },

    // Official MCP Reference Servers
    {
      'id': 'mcp-server-fetch',
      'name': 'Fetch Server',
      'description': 'Web content fetching and conversion for efficient LLM usage.',
      'command': 'npx @modelcontextprotocol/server-fetch',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'webServices',
      'isOfficial': true,
      'tags': ['web-scraping', 'fetch', 'official', 'reference'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'mcp-server-filesystem',
      'name': 'Filesystem Server',
      'description': 'Secure file operations with configurable access controls.',
      'command': 'npx @modelcontextprotocol/server-filesystem',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'fileManagement',
      'isOfficial': true,
      'tags': ['filesystem', 'files', 'official', 'reference'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'mcp-server-git',
      'name': 'Git Server',
      'description': 'Tools to read, search, and manipulate Git repositories.',
      'command': 'npx @modelcontextprotocol/server-git',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'development',
      'isOfficial': true,
      'tags': ['git', 'version-control', 'official', 'reference'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'mcp-server-memory',
      'name': 'Memory Server',
      'description': 'Knowledge graph-based persistent memory system.',
      'command': 'npx @modelcontextprotocol/server-memory',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'dataAnalysis',
      'isOfficial': true,
      'tags': ['memory', 'knowledge-graph', 'official', 'reference'],
      'capabilities': ['tools', 'resources'],
      'transport': 'stdio',
    },

    // High-Quality Community Servers
    {
      'id': 'context7',
      'name': 'Context7',
      'description': 'Get up-to-date, version-specific documentation and code examples from any library or framework.',
      'command': 'uvx context7',
      'args': [],
      'repository': 'https://github.com/upstash/context7',
      'category': 'development',
      'isOfficial': false,
      'tags': ['documentation', 'upstash', 'development', 'library-docs'],
      'capabilities': ['tools', 'resources'],
      'transport': 'stdio',
    },
    {
      'id': 'serena',
      'name': 'Serena',
      'description': 'Semantic code retrieval & editing tools for coding agents.',
      'command': 'uvx serena',
      'args': [],
      'repository': 'https://github.com/oraios/serena',
      'category': 'development',
      'isOfficial': false,
      'tags': ['code-editing', 'semantic-search', 'development', 'ai-tools'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'firecrawl-mcp',
      'name': 'Firecrawl',
      'description': 'Extract web data with Firecrawl - comprehensive web scraping and data extraction.',
      'command': 'uvx firecrawl-mcp',
      'args': [],
      'repository': 'https://github.com/firecrawl/firecrawl-mcp-server',
      'category': 'webServices',
      'isOfficial': false,
      'tags': ['web-scraping', 'data-extraction', 'firecrawl', 'automation'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'FIRECRAWL_API_KEY': 'Firecrawl API key'
      },
    },

    // Database & Storage Servers
    {
      'id': 'mcp-server-postgres',
      'name': 'PostgreSQL Server',
      'description': 'Database operations for PostgreSQL with secure query execution.',
      'command': 'uvx mcp-server-postgres',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'database',
      'isOfficial': true,
      'tags': ['postgresql', 'database', 'sql', 'official'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'POSTGRES_CONNECTION_STRING': 'PostgreSQL connection string'
      },
    },
    {
      'id': 'mcp-server-sqlite',
      'name': 'SQLite Server',
      'description': 'Database operations for SQLite with secure query execution.',
      'command': 'uvx mcp-server-sqlite',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'database',
      'isOfficial': true,
      'tags': ['sqlite', 'database', 'sql', 'official'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },

    // Cloud Platform Servers
    {
      'id': 'mcp-server-aws-kb',
      'name': 'AWS Knowledge Base',
      'description': 'Interact with AWS Knowledge Base for retrieval and Q&A.',
      'command': 'uvx mcp-server-aws-kb',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'cloud',
      'isOfficial': true,
      'tags': ['aws', 'knowledge-base', 'cloud', 'official'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'AWS_ACCESS_KEY_ID': 'AWS access key',
        'AWS_SECRET_ACCESS_KEY': 'AWS secret key',
        'AWS_REGION': 'AWS region'
      },
    },
    {
      'id': 'mcp-server-gdrive',
      'name': 'Google Drive Server',
      'description': 'Access and manage Google Drive files and folders.',
      'command': 'uvx mcp-server-gdrive',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'cloud',
      'isOfficial': true,
      'tags': ['google-drive', 'cloud-storage', 'google', 'official'],
      'capabilities': ['tools', 'resources'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'GOOGLE_DRIVE_CREDENTIALS': 'Google Drive API credentials'
      },
    },

    // Communication & Productivity
    {
      'id': 'mcp-server-slack',
      'name': 'Slack Server',
      'description': 'Interact with Slack workspaces, send messages, and manage channels.',
      'command': 'uvx mcp-server-slack',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'communication',
      'isOfficial': true,
      'tags': ['slack', 'communication', 'team-collaboration', 'official'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'SLACK_BOT_TOKEN': 'Slack bot token'
      },
    },

    // Search & Discovery
    {
      'id': 'mcp-server-brave-search',
      'name': 'Brave Search',
      'description': 'Perform web searches using Brave Search API.',
      'command': 'uvx mcp-server-brave-search',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'webServices',
      'isOfficial': true,
      'tags': ['search', 'brave', 'web-search', 'official'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'BRAVE_SEARCH_API_KEY': 'Brave Search API key'
      },
    },

    // Development Tools
    {
      'id': 'mcp-server-gitlab',
      'name': 'GitLab Server',
      'description': 'Interact with GitLab repositories, issues, and merge requests.',
      'command': 'uvx mcp-server-gitlab',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'development',
      'isOfficial': true,
      'tags': ['gitlab', 'version-control', 'development', 'official'],
      'capabilities': ['tools', 'resources'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'GITLAB_TOKEN': 'GitLab personal access token'
      },
    },

    // Testing & Automation
    {
      'id': 'mcp-server-puppeteer',
      'name': 'Puppeteer Server',
      'description': 'Control headless Chrome for web automation and testing.',
      'command': 'uvx mcp-server-puppeteer',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'development',
      'isOfficial': true,
      'tags': ['puppeteer', 'browser-automation', 'testing', 'official'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },

    // Utilities
    {
      'id': 'mcp-server-time',
      'name': 'Time Server',
      'description': 'Time and timezone conversion capabilities.',
      'command': 'npx @modelcontextprotocol/server-time',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'productivity',
      'isOfficial': true,
      'tags': ['time', 'timezone', 'utilities', 'official'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },

    // Additional Official MCP Servers from GitHub Registry
    {
      'id': 'hugging-face-mcp',
      'name': 'Hugging Face',
      'description': 'Access Hugging Face models, datasets, Spaces, papers, collections via MCP.',
      'command': 'uvx hugging-face-mcp',
      'args': [],
      'repository': 'https://github.com/evanstate/hugging-face-mcp',
      'category': 'dataAnalysis',
      'isOfficial': false,
      'tags': ['hugging-face', 'ml', 'ai', 'datasets', 'models'],
      'capabilities': ['tools', 'resources'],
      'transport': 'stdio',
    },
    {
      'id': 'webflow-mcp',
      'name': 'Webflow',
      'description': 'Enable AI agents to interact with Webflow APIs.',
      'command': 'uvx webflow-mcp',
      'args': [],
      'repository': 'https://github.com/webflow/webflow-mcp',
      'category': 'webServices',
      'isOfficial': true,
      'tags': ['webflow', 'cms', 'web-design', 'api'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'fabric-realtime-intelligence',
      'name': 'Fabric Real-Time Intelligence',
      'description': 'Query Eventhouse/ADX with KQL and manage Eventstreams.',
      'command': 'uvx fabric-realtime-intelligence',
      'args': [],
      'repository': 'https://github.com/microsoft/fabric-realtime-intelligence-mcp',
      'category': 'dataAnalysis',
      'isOfficial': true,
      'tags': ['microsoft', 'fabric', 'kql', 'analytics', 'real-time'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'box-mcp',
      'name': 'Box',
      'description': 'Securely connect AI agents to your enterprise content in Box.',
      'command': 'uvx box-mcp',
      'args': [],
      'repository': 'https://github.com/box-community/box-mcp',
      'category': 'cloud',
      'isOfficial': true,
      'tags': ['box', 'enterprise', 'storage', 'content-management'],
      'capabilities': ['tools', 'resources'],
      'transport': 'stdio',
    },
    {
      'id': 'codacy-mcp',
      'name': 'Codacy',
      'description': 'MCP Server for the Codacy API, enabling access to repositories, files, quality, coverage, security and more.',
      'command': 'uvx codacy-mcp',
      'args': [],
      'repository': 'https://github.com/codacy/codacy-mcp',
      'category': 'development',
      'isOfficial': true,
      'tags': ['codacy', 'code-quality', 'security', 'coverage'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'clarity-mcp',
      'name': 'Clarity',
      'description': 'Fetch Clarity analytics via MCP clients.',
      'command': 'uvx clarity-mcp',
      'args': [],
      'repository': 'https://github.com/microsoft/clarity-mcp',
      'category': 'dataAnalysis',
      'isOfficial': true,
      'tags': ['microsoft', 'clarity', 'analytics', 'web-analytics'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'deepwiki-mcp',
      'name': 'DeepWiki',
      'description': 'Devin-generated docs for any public repo.',
      'command': 'uvx deepwiki-mcp',
      'args': [],
      'repository': 'https://github.com/CognitionAI/deepwiki-mcp',
      'category': 'development',
      'isOfficial': false,
      'tags': ['documentation', 'devin', 'ai-generated', 'repos'],
      'capabilities': ['tools', 'resources'],
      'transport': 'stdio',
    },
    {
      'id': 'postman-mcp',
      'name': 'Postman',
      'description': 'Postman\'s MCP server connects AI agents, assistants, and chatbots directly to your APIs on Postman. Use natural language to make API calls.',
      'command': 'uvx postman-mcp',
      'args': [],
      'repository': 'https://github.com/postmanlabs/postman-mcp',
      'category': 'development',
      'isOfficial': true,
      'tags': ['postman', 'api', 'testing', 'automation'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'launchdarkly-mcp',
      'name': 'LaunchDarkly',
      'description': 'Official LaunchDarkly MCP Server for feature flag management and experimentation. Enables AI agents to work with feature flags.',
      'command': 'uvx launchdarkly-mcp',
      'args': [],
      'repository': 'https://github.com/launchdarkly/launchdarkly-mcp',
      'category': 'development',
      'isOfficial': true,
      'tags': ['launchdarkly', 'feature-flags', 'experimentation', 'deployment'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'atlassian-mcp',
      'name': 'Atlassian',
      'description': 'Remote MCP Server that securely connects Jira and Confluence with your LLM, IDE, or agent platform of choice.',
      'command': 'uvx atlassian-mcp',
      'args': [],
      'repository': 'https://github.com/atlassian/atlassian-mcp',
      'category': 'productivity',
      'isOfficial': true,
      'tags': ['atlassian', 'jira', 'confluence', 'project-management'],
      'capabilities': ['tools', 'resources'],
      'transport': 'stdio',
    },
    {
      'id': 'figma-dev-mode',
      'name': 'Figma Dev Mode',
      'description': 'Expose design context to MCP clients.',
      'command': 'uvx figma-dev-mode',
      'args': [],
      'repository': 'https://github.com/figma/figma-dev-mode-mcp',
      'category': 'development',
      'isOfficial': true,
      'tags': ['figma', 'design', 'dev-mode', 'ui-ux'],
      'capabilities': ['tools', 'resources'],
      'transport': 'stdio',
    },
    {
      'id': 'jfrog-mcp',
      'name': 'JFrog',
      'description': 'JFrog MCP Server, providing your agents with direct access to JFrog Platform services.',
      'command': 'uvx jfrog-mcp',
      'args': [],
      'repository': 'https://github.com/jfrog/jfrog-mcp',
      'category': 'development',
      'isOfficial': true,
      'tags': ['jfrog', 'artifactory', 'devops', 'ci-cd'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'dev-box-mcp',
      'name': 'Dev Box',
      'description': 'This server enables natural language interactions for developer-focused operations like managing Dev Boxes, monitoring resources, and more.',
      'command': 'uvx dev-box-mcp',
      'args': [],
      'repository': 'https://github.com/microsoft/dev-box-mcp',
      'category': 'development',
      'isOfficial': true,
      'tags': ['microsoft', 'dev-box', 'development', 'cloud'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'zapier-mcp',
      'name': 'Zapier',
      'description': 'Zapier MCP is a remote MCP server that gives your AI direct access to 8,000+ apps and 30,000+ actions—no complex integrations.',
      'command': 'uvx zapier-mcp',
      'args': [],
      'repository': 'https://github.com/zapier/zapier-mcp',
      'category': 'automation',
      'isOfficial': true,
      'tags': ['zapier', 'automation', 'integrations', 'workflows'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'ZAPIER_API_KEY': 'Zapier API key'
      },
    },

    // Missing Verified Servers from GitHub MCP Registry
    {
      'id': 'notion-mcp',
      'name': 'Notion',
      'description': 'Official MCP server for Notion API and databases.',
      'command': 'uvx notion-mcp',
      'args': [],
      'repository': 'https://github.com/makenotion/notion-mcp',
      'category': 'productivity',
      'isOfficial': true,
      'tags': ['notion', 'notes', 'database', 'productivity'],
      'capabilities': ['tools', 'resources'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'NOTION_TOKEN': 'Notion API token'
      },
    },
    {
      'id': 'unity-mcp',
      'name': 'Unity',
      'description': 'Control the Unity Editor from MCP clients via a Unity bridge + local Python server.',
      'command': 'uvx unity-mcp',
      'args': [],
      'repository': 'https://github.com/CoplayDev/unity-mcp',
      'category': 'development',
      'isOfficial': false,
      'tags': ['unity', 'game-development', 'editor', 'automation'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'azure-mcp',
      'name': 'Azure',
      'description': 'The Azure MCP Server, bringing the power of Azure to your agents.',
      'command': 'uvx azure-mcp',
      'args': [],
      'repository': 'https://github.com/microsoft/mcp/tree/main/servers/Azure.Mcp.Server',
      'category': 'cloud',
      'isOfficial': true,
      'tags': ['microsoft', 'azure', 'cloud', 'devops'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'azure-devops-mcp',
      'name': 'Azure DevOps',
      'description': 'Interact with Azure DevOps services like repositories, work items, builds, releases, test plans, and code search.',
      'command': 'uvx azure-devops-mcp',
      'args': [],
      'repository': 'https://github.com/microsoft/azure-devops-mcp',
      'category': 'development',
      'isOfficial': true,
      'tags': ['microsoft', 'azure-devops', 'ci-cd', 'project-management'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'stripe-mcp',
      'name': 'Stripe',
      'description': 'Interact with Stripe API for payment processing, customer management, and financial operations.',
      'command': 'uvx stripe-mcp',
      'args': [],
      'repository': 'https://github.com/stripe/stripe-mcp',
      'category': 'automation',
      'isOfficial': true,
      'tags': ['stripe', 'payments', 'finance', 'api'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'STRIPE_API_KEY': 'Stripe API key'
      },
    },
    {
      'id': 'terraform-mcp',
      'name': 'Terraform',
      'description': 'Seamlessly integrate with Terraform ecosystem, enabling advanced automation and interaction capabilities for infrastructure management.',
      'command': 'uvx terraform-mcp',
      'args': [],
      'repository': 'https://github.com/hashicorp/terraform-mcp',
      'category': 'cloud',
      'isOfficial': true,
      'tags': ['hashicorp', 'terraform', 'infrastructure', 'iac'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'mongodb-mcp',
      'name': 'MongoDB',
      'description': 'A Model Context Protocol server to connect to MongoDB databases and MongoDB Atlas Clusters.',
      'command': 'uvx mongodb-mcp',
      'args': [],
      'repository': 'https://github.com/mongodb-js/mongodb-mcp',
      'category': 'database',
      'isOfficial': true,
      'tags': ['mongodb', 'database', 'nosql', 'atlas'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'MONGODB_CONNECTION_STRING': 'MongoDB connection string'
      },
    },
    {
      'id': 'elasticsearch-mcp',
      'name': 'Elasticsearch',
      'description': 'MCP server for connecting to Elasticsearch data and indices. Supports search queries, mappings, ESQL, and shared shard operations.',
      'command': 'uvx elasticsearch-mcp',
      'args': [],
      'repository': 'https://github.com/elastic/elasticsearch-mcp',
      'category': 'database',
      'isOfficial': true,
      'tags': ['elasticsearch', 'search', 'analytics', 'database'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'ELASTICSEARCH_URL': 'Elasticsearch cluster URL'
      },
    },
    {
      'id': 'neon-mcp',
      'name': 'Neon',
      'description': 'MCP server for interacting with Neon Management API and databases.',
      'command': 'uvx neon-mcp',
      'args': [],
      'repository': 'https://github.com/neondatabase/neon-mcp',
      'category': 'database',
      'isOfficial': true,
      'tags': ['neon', 'postgresql', 'serverless', 'database'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'NEON_API_KEY': 'Neon API key'
      },
    },
    {
      'id': 'chroma-mcp',
      'name': 'Chroma',
      'description': 'Provides data retrieval capabilities powered by Chroma, enabling AI models to create collections over generated content.',
      'command': 'uvx chroma-mcp',
      'args': [],
      'repository': 'https://github.com/chroma-core/chroma-mcp',
      'category': 'dataAnalysis',
      'isOfficial': true,
      'tags': ['chroma', 'vector-database', 'embeddings', 'ai'],
      'capabilities': ['tools'],
      'transport': 'stdio',
    },
    {
      'id': 'sentry-mcp',
      'name': 'Sentry',
      'description': 'Retrieve and analyze application errors and performance issues from Sentry projects.',
      'command': 'uvx sentry-mcp',
      'args': [],
      'repository': 'https://github.com/getsentry/sentry-mcp',
      'category': 'monitoring',
      'isOfficial': true,
      'tags': ['sentry', 'error-tracking', 'monitoring', 'performance'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'SENTRY_AUTH_TOKEN': 'Sentry authentication token'
      },
    },
    {
      'id': 'mcp-server-image-gen',
      'name': 'Image Generation Server',
      'description': 'Generate images using DALL-E or other providers via MCP.',
      'command': 'uvx mcp-server-image-gen',
      'args': [],
      'repository': 'https://github.com/modelcontextprotocol/servers',
      'category': 'productivity',
      'isOfficial': true,
      'tags': ['image-generation', 'dall-e', 'ai', 'media'],
      'capabilities': ['tools'],
      'transport': 'stdio',
      'requiredEnvVars': {
        'OPENAI_API_KEY': 'OpenAI API key for DALL-E'
      },
    },
  ];

  /// Get all featured servers as MCPCatalogEntry objects
  List<MCPCatalogEntry> getFeaturedServers() {
    return _featuredServers.map((serverData) => _createCatalogEntry(serverData)).toList();
  }

  /// Get featured servers enriched with GitHub star counts
  Future<List<MCPCatalogEntry>> getFeaturedServersWithStarCounts(GitHubMCPRegistryApi githubApi) async {
    final servers = getFeaturedServers();
    final enrichedServers = <MCPCatalogEntry>[];

    for (final server in servers) {
      if (server.repository != null) {
        final starCount = await githubApi.getGitHubStarCount(server.repository!);
        final enrichedServer = server.copyWith(starCount: starCount);
        enrichedServers.add(enrichedServer);
      } else {
        enrichedServers.add(server);
      }
    }

    return enrichedServers;
  }

  /// Get featured servers by category
  List<MCPCatalogEntry> getFeaturedServersByCategory(MCPServerCategory category) {
    return getFeaturedServers()
        .where((server) => server.category == category)
        .toList();
  }

  /// Get official servers only
  List<MCPCatalogEntry> getOfficialServers() {
    return getFeaturedServers()
        .where((server) => server.isOfficial)
        .toList();
  }

  /// Check if a server is featured
  bool isFeaturedServer(String serverId) {
    return _featuredServers.any((server) => server['id'] == serverId);
  }

  /// Get featured server by ID
  MCPCatalogEntry? getFeaturedServer(String serverId) {
    final serverData = _featuredServers.firstWhere(
      (server) => server['id'] == serverId,
      orElse: () => <String, dynamic>{},
    );

    if (serverData.isEmpty) return null;
    return _createCatalogEntry(serverData);
  }

  /// Convert server data map to MCPCatalogEntry
  MCPCatalogEntry _createCatalogEntry(Map<String, dynamic> data) {
    return MCPCatalogEntry(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      command: data['command'] as String,
      args: List<String>.from(data['args'] as List),
      transport: _parseTransportType(data['transport'] as String),
      capabilities: List<String>.from(data['capabilities'] as List),
      requiredEnvVars: Map<String, String>.from(data['requiredEnvVars'] as Map? ?? {}),
      optionalEnvVars: const {},
      defaultEnvVars: const {},
      tags: List<String>.from(data['tags'] as List),
      category: _parseCategory(data['category'] as String),
      isOfficial: data['isOfficial'] as bool? ?? false,
      isFeatured: true, // All servers in this service are featured
      repository: data['repository'] as String?,
      lastUpdated: DateTime.now(), // Default to current time
      createdAt: DateTime.now(),
    );
  }

  /// Parse transport type from string
  MCPTransportType _parseTransportType(String transport) {
    switch (transport.toLowerCase()) {
      case 'stdio':
        return MCPTransportType.stdio;
      case 'sse':
        return MCPTransportType.sse;
      case 'http':
        return MCPTransportType.http;
      default:
        return MCPTransportType.stdio;
    }
  }

  /// Parse category from string
  MCPServerCategory? _parseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'development':
        return MCPServerCategory.development;
      case 'productivity':
        return MCPServerCategory.productivity;
      case 'communication':
        return MCPServerCategory.communication;
      case 'dataanalysis':
      case 'data-analysis':
        return MCPServerCategory.dataAnalysis;
      case 'automation':
        return MCPServerCategory.automation;
      case 'filemanagement':
      case 'file-management':
        return MCPServerCategory.fileManagement;
      case 'webservices':
      case 'web-services':
        return MCPServerCategory.webServices;
      case 'cloud':
        return MCPServerCategory.cloud;
      case 'database':
        return MCPServerCategory.database;
      case 'security':
        return MCPServerCategory.security;
      case 'monitoring':
        return MCPServerCategory.monitoring;
      default:
        return null;
    }
  }

  /// Get installation difficulty for featured servers
  static const Map<String, String> _installationDifficulty = {
    'markitdown': 'beginner',
    'playwright-mcp': 'intermediate',
    'github-mcp-server': 'intermediate',
    'mcp-server-fetch': 'beginner',
    'mcp-server-filesystem': 'beginner',
    'mcp-server-git': 'beginner',
    'mcp-server-memory': 'intermediate',
    'context7': 'beginner',
    'serena': 'intermediate',
    'firecrawl-mcp': 'intermediate',
    'mcp-server-postgres': 'advanced',
    'mcp-server-sqlite': 'intermediate',
    'mcp-server-aws-kb': 'advanced',
    'mcp-server-gdrive': 'intermediate',
    'mcp-server-slack': 'intermediate',
    'mcp-server-brave-search': 'intermediate',
    'mcp-server-gitlab': 'intermediate',
    'mcp-server-puppeteer': 'advanced',
    'mcp-server-time': 'beginner',
    // New verified servers
    'notion-mcp': 'intermediate',
    'unity-mcp': 'advanced',
    'azure-mcp': 'advanced',
    'azure-devops-mcp': 'intermediate',
    'stripe-mcp': 'intermediate',
    'terraform-mcp': 'advanced',
    'mongodb-mcp': 'intermediate',
    'elasticsearch-mcp': 'intermediate',
    'neon-mcp': 'intermediate',
    'chroma-mcp': 'intermediate',
    'sentry-mcp': 'beginner',
  };

  /// Get difficulty level for a featured server
  String getServerDifficulty(String serverId) {
    return _installationDifficulty[serverId] ?? 'intermediate';
  }
}