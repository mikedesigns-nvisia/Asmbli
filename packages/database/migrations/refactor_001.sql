-- Migration: Refactor to two-tier architecture
-- Description: Add new columns and tables for the refactored system

-- Add new columns to templates table for better categorization
ALTER TABLE templates 
ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'General',
ADD COLUMN IF NOT EXISTS usage_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS tags JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT false;

-- Create index on category for faster filtering
CREATE INDEX IF NOT EXISTS idx_templates_category ON templates(category);
CREATE INDEX IF NOT EXISTS idx_templates_public ON templates(is_public);
CREATE INDEX IF NOT EXISTS idx_templates_usage ON templates(usage_count DESC);

-- Create chat_sessions table for tracking conversations
CREATE TABLE IF NOT EXISTS chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES agent_configs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  messages JSONB DEFAULT '[]'::jsonb,
  context JSONB DEFAULT '[]'::jsonb,
  started_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  ended_at TIMESTAMP NULL
);

-- Create indexes for chat_sessions
CREATE INDEX IF NOT EXISTS idx_chat_sessions_agent ON chat_sessions(agent_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user ON chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_started ON chat_sessions(started_at DESC);

-- Create api_keys table for secure API key management
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  provider VARCHAR(50) NOT NULL,
  key_id VARCHAR(100) NOT NULL,
  encrypted_key TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_used TIMESTAMP NULL,
  is_active BOOLEAN DEFAULT true
);

-- Create indexes for api_keys
CREATE INDEX IF NOT EXISTS idx_api_keys_user ON api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_provider ON api_keys(provider);

-- Create user_settings table for storing user preferences
CREATE TABLE IF NOT EXISTS user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  theme VARCHAR(20) DEFAULT 'system',
  default_model VARCHAR(50) DEFAULT 'gpt-4',
  notifications JSONB DEFAULT '{
    "email": true,
    "inApp": true,
    "chatUpdates": true
  }'::jsonb,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create template_ratings table for user ratings
CREATE TABLE IF NOT EXISTS template_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID REFERENCES templates(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(template_id, user_id)
);

-- Create indexes for template_ratings
CREATE INDEX IF NOT EXISTS idx_template_ratings_template ON template_ratings(template_id);
CREATE INDEX IF NOT EXISTS idx_template_ratings_user ON template_ratings(user_id);

-- Update existing data to fit new schema
UPDATE templates SET category = 'General' WHERE category IS NULL;
UPDATE templates SET is_public = false WHERE is_public IS NULL;
UPDATE templates SET usage_count = 0 WHERE usage_count IS NULL;
UPDATE templates SET rating = 0.0 WHERE rating IS NULL;
UPDATE templates SET tags = '[]'::jsonb WHERE tags IS NULL;

-- Create function to update template ratings automatically
CREATE OR REPLACE FUNCTION update_template_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE templates 
  SET rating = (
    SELECT ROUND(AVG(rating)::numeric, 2)
    FROM template_ratings 
    WHERE template_id = NEW.template_id
  )
  WHERE id = NEW.template_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update template ratings
DROP TRIGGER IF EXISTS trigger_update_template_rating ON template_ratings;
CREATE TRIGGER trigger_update_template_rating
  AFTER INSERT OR UPDATE OR DELETE ON template_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_template_rating();

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers to relevant tables
DROP TRIGGER IF EXISTS trigger_chat_sessions_updated_at ON chat_sessions;
CREATE TRIGGER trigger_chat_sessions_updated_at
  BEFORE UPDATE ON chat_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_api_keys_updated_at ON api_keys;
CREATE TRIGGER trigger_api_keys_updated_at
  BEFORE UPDATE ON api_keys
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_user_settings_updated_at ON user_settings;
CREATE TRIGGER trigger_user_settings_updated_at
  BEFORE UPDATE ON user_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert some default template categories if needed
INSERT INTO templates (name, description, category, config, author, is_public, usage_count, rating)
VALUES 
  ('Research Assistant', 'Academic research agent with citation management', 'Research', '{"role": "research_assistant", "tools": ["web-search", "database"]}', 'Asmbli Team', true, 1523, 4.8),
  ('Code Reviewer', 'Automated code review with best practices', 'Development', '{"role": "code_reviewer", "tools": ["github", "filesystem"]}', 'Asmbli Team', true, 2341, 4.9),
  ('Content Writer', 'SEO-optimized content generation', 'Writing', '{"role": "content_writer", "tools": ["web-search", "api-client"]}', 'Asmbli Team', true, 987, 4.7)
ON CONFLICT (name) DO NOTHING;