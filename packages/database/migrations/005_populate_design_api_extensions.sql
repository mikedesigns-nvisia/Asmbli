-- Populate Design & API Extensions Data Migration
-- This migration adds design tools, API integrations, and other extensions

INSERT INTO extensions (
  id, name, description, category, provider, icon, complexity, enabled, 
  connection_type, auth_method, pricing, features, capabilities, requirements, 
  documentation, setup_complexity, configuration, supported_connection_types,
  is_official, is_featured, is_verified
) VALUES

-- Design & Prototyping Extensions
('figma-mcp', 'Figma MCP Server', 'Connect to Figma files, components, and design systems through Model Context Protocol with current platform features', 'design-prototyping', 'Figma', 'Figma', 'medium', true, 'mcp', 'oauth', 'freemium',
ARRAY['Access Figma files and projects', 'Read and modify design components', 'Extract design tokens and styles', 'Manage design system libraries', 'Code Connect integration', 'Library Analytics API access', 'Dev Mode component inspection', 'Collaborate on design reviews', 'Export assets and specifications', 'Typography and gradient variables', 'Component playground access'],
ARRAY['Design file access', 'Component management', 'Style extraction', 'Asset export', 'Code Connect integration', 'Library Analytics', 'Dev Mode features', 'Collaboration', 'Version control', 'Variable management'],
ARRAY['Figma account with API access', 'Team or organization workspace', 'Design system or component library setup', 'Dev Mode access (for enhanced features)', 'Enterprise license (for Library Analytics)'],
'https://www.figma.com/developers/api', 3,
'{"apiKey": "", "teamId": "", "projectIds": [], "permissions": ["read", "write", "comment"], "syncInterval": "5m", "codeConnect": true, "devMode": true, "libraryAnalytics": false}',
ARRAY[]::TEXT[], false, true, true),

('supabase-api', 'Supabase Database API', 'Full-stack database and API platform for storing design data, user feedback, and collaboration', 'design-prototyping', 'Supabase', 'Database', 'medium', true, 'api', 'api-key', 'freemium',
ARRAY['PostgreSQL database for design data', 'Real-time collaboration features', 'File storage for design assets', 'User authentication and permissions', 'API endpoints for custom integrations', 'Analytics and usage tracking'],
ARRAY['Database operations', 'Real-time subscriptions', 'File storage', 'Authentication', 'API generation', 'Edge functions'],
ARRAY['Supabase project setup', 'Database schema for design data', 'API key and security configuration'],
'https://supabase.com/docs', 4,
'{"projectUrl": "", "apiKey": "", "tables": ["designs", "components", "feedback", "versions"], "policies": "row_level_security", "storage": "design_assets"}',
ARRAY[]::TEXT[], false, true, true),

('storybook-api', 'Storybook Integration', 'Connect to Storybook for component documentation, testing, and design system management', 'design-prototyping', 'Storybook', 'BookOpen', 'medium', true, 'api', 'none', 'free',
ARRAY['Component story management', 'Visual testing integration', 'Documentation generation', 'Design system showcase', 'Accessibility testing', 'Cross-browser compatibility'],
ARRAY['Story management', 'Visual testing', 'Documentation', 'Accessibility', 'Testing', 'Deployment'],
ARRAY['Storybook project setup', 'Component library', 'Build and deployment pipeline'],
'https://storybook.js.org/docs', 3,
'{"storybookUrl": "", "stories": [], "addons": ["docs", "controls", "viewport", "a11y"], "buildCommand": "build-storybook"}',
ARRAY[]::TEXT[], false, true, true),

-- GitHub Integration (Multi-platform)
('github', 'GitHub Integration', 'Access GitHub repositories for code analysis, pull requests, issues, and collaborative development via API or MCP', 'development-code', 'GitHub', 'Github', 'medium', true, 'api', 'oauth', 'freemium',
ARRAY['Repository and file access', 'Pull request management', 'Issue tracking and creation', 'Code review and comments', 'Branch and commit operations', 'GitHub Actions integration', 'Design system repository management', 'Component library maintenance', 'MCP server protocol support', 'Webhook handling', 'Team and permission management'],
ARRAY['Repository access', 'Code operations', 'Pull requests', 'Issue management', 'Collaboration', 'CI/CD integration', 'Design system ops', 'Documentation', 'MCP protocol', 'Event handling', 'Access control'],
ARRAY['GitHub account and repository access', 'Personal access token, OAuth, or GitHub App setup', 'Repository permissions for intended operations'],
'https://docs.github.com/en/rest', 3,
'{"connectionType": "api", "owner": "", "repositories": [], "permissions": ["read", "write", "admin"], "webhooks": true, "actions": true, "token": "", "organization": "", "webhookSecret": ""}',
ARRAY['api', 'mcp'], false, true, true),

-- Slack Integration (Multi-platform)
('slack', 'Slack Integration', 'Integrate with Slack for team communication, notifications, and design collaboration workflows via API or MCP', 'communication-collaboration', 'Slack', 'MessageSquare', 'medium', true, 'api', 'oauth', 'freemium',
ARRAY['Channel and DM messaging', 'File and image sharing', 'Design review notifications', 'Automated status updates', 'Team collaboration workflows', 'Integration with design tools', 'Feedback collection and routing', 'Design system announcements', 'MCP server protocol support', 'User and workspace management', 'Bot interactions', 'Event handling'],
ARRAY['Messaging', 'File sharing', 'Notifications', 'Workflows', 'Integrations', 'Collaboration', 'Feedback', 'Broadcasting', 'MCP protocol', 'User management', 'Bot management', 'Event processing'],
ARRAY['Slack workspace with app permissions', 'Bot token, OAuth credentials, or MCP setup', 'Channel access for intended operations'],
'https://api.slack.com/', 3,
'{"connectionType": "api", "workspaceId": "", "channels": ["#design", "#frontend", "#design-system"], "botToken": "", "appToken": "", "signingSecret": "", "permissions": ["chat:write", "files:read", "channels:read"]}',
ARRAY['api', 'mcp'], false, true, true),

-- AI Services
('openai-api', 'OpenAI GPT Models', 'Access OpenAI GPT models for design content generation, code assistance, and creative ideation', 'ai-machine-learning', 'OpenAI', 'Brain', 'low', true, 'api', 'api-key', 'paid',
ARRAY['Text generation and editing', 'Code generation and review', 'Design content creation', 'Component documentation', 'Design system guidelines', 'Accessibility recommendations', 'UX copy and microcopy', 'Design critique and feedback'],
ARRAY['Text generation', 'Code assistance', 'Content creation', 'Documentation', 'Guidelines', 'Accessibility', 'Copywriting', 'Analysis'],
ARRAY['OpenAI API key with sufficient credits', 'Model access permissions', 'Usage monitoring and rate limiting'],
'https://platform.openai.com/docs', 1,
'{"apiKey": "", "model": "gpt-4", "maxTokens": 4096, "temperature": 0.7}',
ARRAY[]::TEXT[], false, true, true),

('anthropic-api', 'Anthropic Claude', 'Integrate Claude for safe AI assistance in design workflows, documentation, and analysis', 'ai-machine-learning', 'Anthropic', 'Bot', 'low', true, 'api', 'api-key', 'paid',
ARRAY['Safe and helpful AI responses', 'Long-context understanding', 'Design analysis and critique', 'Accessibility auditing', 'Design system consistency checks', 'Code review and suggestions', 'Documentation improvement', 'Design process optimization'],
ARRAY['AI assistance', 'Long context', 'Analysis', 'Auditing', 'Consistency', 'Code review', 'Documentation', 'Optimization'],
ARRAY['Anthropic API key', 'Model access and usage limits', 'Safety and content guidelines'],
'https://docs.anthropic.com/', 1,
'{"apiKey": "", "model": "claude-3-sonnet", "maxTokens": 4096, "temperature": 0.3}',
ARRAY[]::TEXT[], false, true, true),

-- Browser Tools
('brave-browser', 'Brave Browser Extension', 'Privacy-focused browser extension for web scraping, bookmarks, and tab management with ad-blocking capabilities', 'browser-web-tools', 'Brave Software', 'Shield', 'low', true, 'extension', 'none', 'free',
ARRAY['Privacy-focused web browsing', 'Built-in ad and tracker blocking', 'Tab and bookmark management', 'Web scraping capabilities', 'Page content extraction', 'Form automation', 'Screenshot capture', 'Web API interactions'],
ARRAY['Web navigation', 'Content extraction', 'Privacy protection', 'Ad blocking', 'Tab management', 'Bookmark sync', 'Form filling', 'Screen capture'],
ARRAY['Brave browser installed', 'Extension permissions granted', 'Browser automation setup'],
'https://brave.com/developers/', 1,
'{"autoBlock": true, "shieldsUp": true, "cookieBlocking": "strict", "fingerprintBlocking": "aggressive"}',
ARRAY[]::TEXT[], false, false, true),

-- Email & Communication
('gmail-api', 'Gmail Integration', 'Full Gmail API access for email automation, management, and communication workflows', 'email-communication', 'Google Gmail', 'Mail', 'medium', true, 'api', 'oauth', 'free',
ARRAY['Email sending and receiving', 'Advanced search and filtering', 'Label and folder management', 'Attachment processing', 'Draft management', 'Signature and template support', 'Bulk email operations', 'Threading and conversation tracking'],
ARRAY['Email automation', 'Message processing', 'Search and filter', 'Label management', 'Attachment handling', 'Template system', 'Bulk operations', 'Conversation tracking'],
ARRAY['Gmail account with API access', 'Google Cloud Project setup', 'OAuth 2.0 credentials'],
'https://developers.google.com/gmail/api', 3,
'{"clientId": "", "clientSecret": "", "scopes": ["gmail.readonly", "gmail.send"], "labels": []}',
ARRAY[]::TEXT[], false, true, true),

-- Automation
('zapier-webhooks', 'Zapier Automation', 'Connect to 5000+ apps through Zapier workflows and automation triggers', 'automation-productivity', 'Zapier', 'Zap', 'medium', true, 'webhook', 'api-key', 'freemium',
ARRAY['Multi-app workflow automation', 'Trigger-based task execution', 'Data transformation and routing', 'Conditional logic and filters', 'Scheduled and real-time automation', 'Error handling and retries', 'Webhook and API integrations', 'Custom app connections'],
ARRAY['Workflow automation', 'Multi-app integration', 'Data transformation', 'Conditional logic', 'Scheduling', 'Error handling', 'Webhook processing', 'Custom integrations'],
ARRAY['Zapier account with automation access', 'Connected app accounts', 'Webhook endpoints configured'],
'https://zapier.com/developer', 3,
'{"webhookUrl": "", "triggerApps": [], "actionApps": [], "filters": true}',
ARRAY[]::TEXT[], false, true, true)

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