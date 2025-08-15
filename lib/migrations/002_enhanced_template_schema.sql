-- Enhanced template schema for asmbli
-- This migration adds support for template categories, tags, usage tracking, and extensions

-- Template categories table
CREATE TABLE IF NOT EXISTS template_categories (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  color VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories
INSERT INTO template_categories (id, name, description, icon, color) VALUES
  ('development', 'Development', 'Code generation, API development, and software engineering', '💻', '#3B82F6'),
  ('design', 'Design & Creative', 'UI/UX design, creative content, and visual assets', '🎨', '#8B5CF6'),
  ('data', 'Data & Analytics', 'Data processing, analysis, and reporting', '📊', '#10B981'),
  ('marketing', 'Marketing & Content', 'Content creation, SEO, and digital marketing', '📢', '#F59E0B'),
  ('productivity', 'Productivity', 'Task automation, organization, and workflows', '⚡', '#6366F1'),
  ('education', 'Education & Training', 'Learning resources, tutorials, and educational content', '📚', '#EF4444'),
  ('business', 'Business & Finance', 'Business analysis, financial planning, and strategy', '💼', '#059669'),
  ('security', 'Security & Compliance', 'Security analysis, compliance, and risk management', '🔒', '#DC2626')
ON CONFLICT (id) DO NOTHING;

-- Enhanced templates table (add more fields)
ALTER TABLE templates ADD COLUMN IF NOT EXISTS category VARCHAR(50) REFERENCES template_categories(id);
ALTER TABLE templates ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
ALTER TABLE templates ADD COLUMN IF NOT EXISTS usage_count INTEGER DEFAULT 0;
ALTER TABLE templates ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE templates ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;
ALTER TABLE templates ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
ALTER TABLE templates ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT false;
ALTER TABLE templates ADD COLUMN IF NOT EXISTS pricing_tier VARCHAR(20) DEFAULT 'free' CHECK (pricing_tier IN ('free', 'premium', 'enterprise'));

-- Template usage tracking table
CREATE TABLE IF NOT EXISTS template_usage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  template_id UUID NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB
);

-- Extensions/MCPs registry table
CREATE TABLE IF NOT EXISTS extensions (
  id VARCHAR(100) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(50),
  provider VARCHAR(100),
  pricing VARCHAR(20) DEFAULT 'free' CHECK (pricing IN ('free', 'premium', 'enterprise')),
  connection_type VARCHAR(20) DEFAULT 'mcp' CHECK (connection_type IN ('mcp', 'api', 'webhook')),
  config_schema JSONB,
  documentation_url TEXT,
  is_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Template-extension relationships
CREATE TABLE IF NOT EXISTS template_extensions (
  template_id UUID NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
  extension_id VARCHAR(100) NOT NULL REFERENCES extensions(id) ON DELETE CASCADE,
  is_required BOOLEAN DEFAULT true,
  configuration JSONB,
  PRIMARY KEY (template_id, extension_id)
);

-- User favorites/bookmarks
CREATE TABLE IF NOT EXISTS user_template_favorites (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  template_id UUID NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, template_id)
);

-- Insert default extensions/MCPs
INSERT INTO extensions (id, name, description, category, provider, pricing, connection_type) VALUES
  ('postgres-mcp', 'PostgreSQL MCP', 'Database operations and queries', 'database', 'official', 'free', 'mcp'),
  ('file-manager-mcp', 'File Manager MCP', 'File system operations', 'utility', 'official', 'free', 'mcp'),
  ('terminal-mcp', 'Terminal MCP', 'Command line interface', 'utility', 'official', 'free', 'mcp'),
  ('git-mcp', 'Git MCP', 'Version control operations', 'development', 'official', 'free', 'mcp'),
  ('http-mcp', 'HTTP Client MCP', 'HTTP requests and API calls', 'api', 'official', 'free', 'mcp'),
  ('search-mcp', 'Search MCP', 'Web search capabilities', 'utility', 'official', 'free', 'mcp'),
  ('calendar-mcp', 'Calendar MCP', 'Calendar and scheduling', 'productivity', 'official', 'free', 'mcp'),
  ('memory-mcp', 'Memory MCP', 'Persistent memory and context', 'utility', 'official', 'free', 'mcp'),
  ('figma-mcp', 'Figma MCP', 'Design file access and manipulation', 'design', 'community', 'premium', 'mcp'),
  ('slack-mcp', 'Slack MCP', 'Team communication integration', 'productivity', 'community', 'premium', 'mcp')
ON CONFLICT (id) DO NOTHING;

-- Update existing templates to have default category
UPDATE templates SET category = 'development' WHERE category IS NULL;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_templates_category ON templates(category);
CREATE INDEX IF NOT EXISTS idx_templates_tags ON templates USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_templates_usage_count ON templates(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_templates_featured ON templates(is_featured, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_templates_pricing ON templates(pricing_tier, is_public);
CREATE INDEX IF NOT EXISTS idx_template_usage_template_id ON template_usage(template_id);
CREATE INDEX IF NOT EXISTS idx_template_usage_user_id ON template_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_template_usage_used_at ON template_usage(used_at DESC);
CREATE INDEX IF NOT EXISTS idx_extensions_category ON extensions(category);
CREATE INDEX IF NOT EXISTS idx_extensions_pricing ON extensions(pricing);
CREATE INDEX IF NOT EXISTS idx_template_extensions_template ON template_extensions(template_id);
CREATE INDEX IF NOT EXISTS idx_template_extensions_extension ON template_extensions(extension_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user ON user_template_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_template ON user_template_favorites(template_id);

-- Add updated_at trigger for new tables
CREATE TRIGGER update_extensions_updated_at 
  BEFORE UPDATE ON extensions 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();