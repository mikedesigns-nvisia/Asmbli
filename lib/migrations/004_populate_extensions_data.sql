-- Populate Extensions Data Migration
-- This migration populates the extensions table with data from the current extensions library

-- Insert all extensions from the current library
INSERT INTO extensions (
  id, name, description, category, provider, icon, complexity, enabled, 
  connection_type, auth_method, pricing, features, capabilities, requirements, 
  documentation, setup_complexity, configuration, supported_connection_types,
  is_official, is_featured, is_verified
) VALUES

-- Core MCP Server Extensions
('filesystem-mcp', 'Filesystem MCP Server', 'Access and manage local files and directories through Model Context Protocol', 'development-code', 'MCP Core', 'HardDrive', 'low', true, 'mcp', 'none', 'free', 
ARRAY['Read and write local files', 'Directory traversal and listing', 'File search and pattern matching', 'File metadata access', 'Permission management', 'Batch operations', 'File watching and monitoring', 'Safe sandbox operations'],
ARRAY['File operations', 'Directory access', 'Search functionality', 'Metadata extraction', 'Permission control', 'Batch processing', 'File monitoring', 'Sandbox security'],
ARRAY['Local filesystem access permissions', 'MCP server runtime', 'Directory permissions configuration'],
'https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem', 1, 
'{"allowedPaths": [], "readOnly": false, "maxFileSize": "10MB", "allowedExtensions": ["*"]}', 
ARRAY[]::TEXT[], true, true, true),

('git-mcp', 'Git MCP Server', 'Git repository operations and version control through Model Context Protocol (Early Development)', 'development-code', 'MCP Core', 'GitBranch', 'medium', true, 'mcp', 'none', 'free',
ARRAY['Repository cloning and initialization', 'Branch management and switching', 'Commit history and diff analysis', 'File staging and committing', 'Remote repository operations', 'Merge conflict resolution', 'Tag and release management', 'Submodule support'],
ARRAY['Repository operations', 'Branch management', 'Version history', 'File tracking', 'Remote sync', 'Conflict resolution', 'Release management', 'Submodule handling'],
ARRAY['Git installed locally', 'Repository access permissions', 'MCP client configuration'],
'https://github.com/modelcontextprotocol/servers/tree/main/src/git', 2,
'{"repository": "/path/to/git/repo", "defaultBranch": "main", "readOnly": false, "author": {"name": "", "email": ""}}',
ARRAY[]::TEXT[], true, true, true),

('postgres-mcp', 'PostgreSQL MCP Server', 'PostgreSQL database operations and queries through Model Context Protocol (Official + Community versions available)', 'analytics-data', 'MCP Core', 'Database', 'high', true, 'mcp', 'database-credentials', 'free',
ARRAY['SQL query execution (read-only in official version)', 'Database schema introspection', 'Table and view operations', 'Connection to PostgreSQL databases', 'Enhanced features in community versions', 'Performance analysis (community versions)', 'Read/write access (community versions)', 'Multiple database connections'],
ARRAY['SQL read operations', 'Schema inspection', 'Database connectivity', 'Query execution', 'Connection management', 'Community enhancements', 'Performance monitoring', 'Security controls'],
ARRAY['PostgreSQL database access', 'Database credentials', 'Network connectivity to database', 'MCP client configuration'],
'https://modelcontextprotocol.io/examples', 4,
'{"connectionString": "postgresql://localhost/mydb", "readOnly": true, "timeout": 30, "ssl": true, "communityVersion": false}',
ARRAY[]::TEXT[], true, true, true),

('memory-mcp', 'Memory MCP Server', 'Persistent memory and knowledge base management for AI agents', 'ai-machine-learning', 'MCP Core', 'Brain', 'medium', true, 'mcp', 'none', 'free',
ARRAY['Persistent knowledge storage', 'Semantic search and retrieval', 'Context-aware memory management', 'Entity relationship tracking', 'Memory consolidation', 'Fact verification and updates', 'Memory expiration policies', 'Cross-session continuity'],
ARRAY['Knowledge storage', 'Semantic search', 'Context management', 'Relationship tracking', 'Memory consolidation', 'Fact management', 'Policy enforcement', 'Session continuity'],
ARRAY['Vector database or embedding storage', 'Memory persistence layer', 'Embedding model access'],
'https://github.com/modelcontextprotocol/servers/tree/main/src/memory', 3,
'{"storageBackend": "sqlite", "embeddingModel": "text-embedding-3-small", "maxMemories": 10000, "retentionDays": 30}',
ARRAY[]::TEXT[], true, true, true),

('search-mcp', 'Search MCP Server', 'Web search and information retrieval through Model Context Protocol', 'browser-web-tools', 'MCP Core', 'Search', 'low', true, 'mcp', 'api-key', 'freemium',
ARRAY['Web search with multiple engines', 'Real-time information retrieval', 'Search result ranking and filtering', 'Domain-specific searches', 'Image and video search', 'News and recent content', 'Safe search filtering', 'Multi-language support'],
ARRAY['Web search', 'Information retrieval', 'Result filtering', 'Domain searches', 'Media search', 'News retrieval', 'Content filtering', 'Language support'],
ARRAY['Search API keys (Google, Bing, etc.)', 'Rate limiting configuration', 'Content filtering policies'],
'https://github.com/modelcontextprotocol/servers/tree/main/src/search', 2,
'{"searchEngine": "google", "apiKey": "", "maxResults": 10, "safeSearch": "moderate"}',
ARRAY[]::TEXT[], true, true, true),

('terminal-mcp', 'Terminal MCP Server', 'Execute shell commands and terminal operations through Model Context Protocol', 'development-code', 'MCP Core', 'Terminal', 'high', true, 'mcp', 'none', 'free',
ARRAY['Shell command execution', 'Environment variable management', 'Process monitoring and control', 'File system operations', 'Package manager integration', 'Build tool automation', 'System information queries', 'Security sandboxing'],
ARRAY['Command execution', 'Environment control', 'Process management', 'File operations', 'Package management', 'Build automation', 'System queries', 'Security controls'],
ARRAY['Terminal/shell access', 'Execution permissions', 'Security policy configuration'],
'https://github.com/modelcontextprotocol/servers/tree/main/src/terminal', 4,
'{"allowedCommands": [], "workingDirectory": "/tmp", "timeout": 30, "sandboxed": true}',
ARRAY[]::TEXT[], true, false, true),

('http-mcp', 'HTTP MCP Server', 'HTTP client for API requests and web service integration', 'development-code', 'MCP Core', 'Link', 'medium', true, 'mcp', 'api-key', 'free',
ARRAY['HTTP GET, POST, PUT, DELETE requests', 'Request header and body customization', 'Authentication handling', 'Response parsing and formatting', 'Error handling and retries', 'Rate limiting and throttling', 'SSL/TLS certificate validation', 'Proxy and middleware support'],
ARRAY['HTTP operations', 'Request customization', 'Authentication', 'Response handling', 'Error management', 'Rate limiting', 'SSL validation', 'Proxy support'],
ARRAY['Network connectivity', 'API endpoints and credentials', 'SSL certificates if required'],
'https://github.com/modelcontextprotocol/servers/tree/main/src/http', 2,
'{"baseUrl": "", "defaultHeaders": {}, "timeout": 10000, "retries": 3}',
ARRAY[]::TEXT[], true, true, true),

('calendar-mcp', 'Calendar MCP Server', 'Calendar and scheduling operations through Model Context Protocol', 'automation-productivity', 'MCP Core', 'Calendar', 'medium', true, 'mcp', 'oauth', 'free',
ARRAY['Event creation and management', 'Calendar synchronization', 'Meeting scheduling', 'Availability checking', 'Reminder and notification setup', 'Recurring event handling', 'Multi-calendar support', 'Time zone management'],
ARRAY['Event management', 'Calendar sync', 'Scheduling', 'Availability', 'Notifications', 'Recurring events', 'Multi-calendar', 'Time zones'],
ARRAY['Calendar service access (Google, Outlook, etc.)', 'OAuth credentials', 'Calendar permissions'],
'https://github.com/modelcontextprotocol/servers/tree/main/src/calendar', 3,
'{"calendarProvider": "google", "defaultCalendar": "", "reminderMinutes": 15, "timeZone": "UTC"}',
ARRAY[]::TEXT[], true, true, true),

('sequential-thinking-mcp', 'Sequential Thinking MCP Server', 'Dynamic problem-solving through thought sequences and structured reasoning for AI agents', 'ai-machine-learning', 'MCP Core', 'Cpu', 'medium', true, 'mcp', 'none', 'free',
ARRAY['Sequential thought generation', 'Problem decomposition', 'Multi-step reasoning chains', 'Dynamic thinking sequences', 'Reasoning pattern recognition', 'Logical flow management', 'Thought process tracking', 'Cognitive workflow optimization'],
ARRAY['Sequential reasoning', 'Problem solving', 'Thought chains', 'Logic flow', 'Pattern recognition', 'Workflow optimization', 'Process tracking', 'Cognitive enhancement'],
ARRAY['MCP server runtime', 'Sequential processing capability', 'Reasoning model access'],
'https://modelcontextprotocol.io/examples', 2,
'{"maxSequenceLength": 50, "reasoningDepth": 5, "thoughtPersistence": true, "patternTracking": true}',
ARRAY[]::TEXT[], true, false, true),

('time-mcp', 'Time MCP Server', 'Time and timezone conversion capabilities with scheduling and temporal operations', 'automation-productivity', 'MCP Core', 'Clock', 'low', true, 'mcp', 'none', 'free',
ARRAY['Timezone conversion and management', 'Time format standardization', 'Schedule calculation', 'Date arithmetic operations', 'World clock functionality', 'Time-based calculations', 'Calendar integration support', 'Temporal query processing'],
ARRAY['Timezone handling', 'Time conversion', 'Date operations', 'Schedule management', 'World time', 'Temporal calculations', 'Calendar support', 'Time queries'],
ARRAY['MCP server runtime', 'Timezone database access', 'System time synchronization'],
'https://modelcontextprotocol.io/examples', 1,
'{"defaultTimezone": "UTC", "timezoneData": "auto", "dateFormat": "ISO8601", "calendarSupport": true}',
ARRAY[]::TEXT[], true, false, true)

ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  provider = EXCLUDED.provider,
  icon = EXCLUDED.icon,
  complexity = EXCLUDED.complexity,
  enabled = EXCLUDED.enabled,
  connection_type = EXCLUDED.connection_type,
  auth_method = EXCLUDED.auth_method,
  pricing = EXCLUDED.pricing,
  features = EXCLUDED.features,
  capabilities = EXCLUDED.capabilities,
  requirements = EXCLUDED.requirements,
  documentation = EXCLUDED.documentation,
  setup_complexity = EXCLUDED.setup_complexity,
  configuration = EXCLUDED.configuration,
  supported_connection_types = EXCLUDED.supported_connection_types,
  is_official = EXCLUDED.is_official,
  is_featured = EXCLUDED.is_featured,
  is_verified = EXCLUDED.is_verified,
  updated_at = NOW();