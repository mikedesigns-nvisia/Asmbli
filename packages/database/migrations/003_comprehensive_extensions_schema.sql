-- Comprehensive Extensions Schema Migration
-- This migration enhances the extensions table to support the full Extension interface
-- and adds extension usage analytics, user preferences, and versioning

-- Drop existing basic extensions table to recreate with full schema
DROP TABLE IF EXISTS template_extensions CASCADE;
DROP TABLE IF EXISTS extensions CASCADE;

-- Create comprehensive extensions table
CREATE TABLE extensions (
  id VARCHAR(100) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  provider VARCHAR(100) NOT NULL,
  icon VARCHAR(50),
  complexity VARCHAR(20) NOT NULL CHECK (complexity IN ('low', 'medium', 'high')),
  enabled BOOLEAN DEFAULT true,
  connection_type VARCHAR(20) NOT NULL CHECK (connection_type IN ('mcp', 'api', 'extension', 'webhook')),
  auth_method VARCHAR(50) NOT NULL,
  pricing VARCHAR(20) NOT NULL CHECK (pricing IN ('free', 'freemium', 'paid')),
  features TEXT[] DEFAULT '{}',
  capabilities TEXT[] DEFAULT '{}',
  requirements TEXT[] DEFAULT '{}',
  documentation TEXT,
  setup_complexity INTEGER DEFAULT 1 CHECK (setup_complexity BETWEEN 1 AND 5),
  configuration JSONB DEFAULT '{}',
  supported_connection_types TEXT[] DEFAULT '{}',
  security_level VARCHAR(20) DEFAULT 'medium' CHECK (security_level IN ('low', 'medium', 'high')),
  version VARCHAR(20) DEFAULT '1.0.0',
  is_official BOOLEAN DEFAULT false,
  is_featured BOOLEAN DEFAULT false,
  is_verified BOOLEAN DEFAULT false,
  usage_count INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 0.00 CHECK (rating >= 0.00 AND rating <= 5.00),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Extension categories for filtering and organization
CREATE TABLE extension_categories (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  color VARCHAR(50),
  sort_order INTEGER DEFAULT 0
);

-- Insert extension categories
INSERT INTO extension_categories (id, name, description, icon, color, sort_order) VALUES
  ('design-prototyping', 'Design & Prototyping', 'Tools for design workflows, prototyping, and design system management', 'Figma', '#8B5CF6', 1),
  ('development-code', 'Development & Code', 'Code repositories, version control, and development tools', 'Code2', '#3B82F6', 2),
  ('communication-collaboration', 'Communication & Collaboration', 'Team communication and collaboration platforms', 'MessageSquare', '#10B981', 3),
  ('documentation-knowledge', 'Documentation & Knowledge', 'Documentation systems and knowledge management', 'BookOpen', '#F59E0B', 4),
  ('project-management', 'Project Management', 'Project tracking and task management tools', 'Calendar', '#6366F1', 5),
  ('ai-machine-learning', 'AI & Machine Learning', 'AI models and machine learning services', 'Brain', '#EF4444', 6),
  ('analytics-data', 'Analytics & Data', 'Data analysis and business intelligence tools', 'BarChart3', '#059669', 7),
  ('file-asset-management', 'File & Asset Management', 'File storage and digital asset management', 'FolderOpen', '#DC2626', 8),
  ('browser-web-tools', 'Browser & Web Tools', 'Browser extensions and web automation tools', 'Globe', '#7C3AED', 9),
  ('automation-productivity', 'Automation & Productivity', 'Workflow automation and productivity tools', 'Zap', '#0891B2', 10),
  ('email-communication', 'Email & Communication', 'Email and messaging services', 'Mail', '#DB2777', 11)
ON CONFLICT (id) DO NOTHING;

-- User extension preferences and selections
CREATE TABLE user_extensions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  extension_id VARCHAR(100) NOT NULL REFERENCES extensions(id) ON DELETE CASCADE,
  is_enabled BOOLEAN DEFAULT true,
  selected_platforms TEXT[] DEFAULT '{}',
  configuration JSONB DEFAULT '{}',
  status VARCHAR(20) DEFAULT 'configuring' CHECK (status IN ('configuring', 'configured', 'error')),
  config_progress INTEGER DEFAULT 25 CHECK (config_progress BETWEEN 0 AND 100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, extension_id)
);

-- Extension usage analytics
CREATE TABLE extension_usage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  extension_id VARCHAR(100) NOT NULL REFERENCES extensions(id) ON DELETE CASCADE,
  action VARCHAR(50) NOT NULL, -- 'selected', 'configured', 'deployed', 'removed'
  metadata JSONB DEFAULT '{}',
  session_id VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Extension ratings and reviews
CREATE TABLE extension_reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  extension_id VARCHAR(100) NOT NULL REFERENCES extensions(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, extension_id)
);

-- Template-extension relationships (recreate)
CREATE TABLE template_extensions (
  template_id UUID NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
  extension_id VARCHAR(100) NOT NULL REFERENCES extensions(id) ON DELETE CASCADE,
  is_required BOOLEAN DEFAULT true,
  configuration JSONB DEFAULT '{}',
  sort_order INTEGER DEFAULT 0,
  PRIMARY KEY (template_id, extension_id)
);

-- Add comprehensive indexes for performance
CREATE INDEX idx_extensions_category ON extensions(category);
CREATE INDEX idx_extensions_connection_type ON extensions(connection_type);
CREATE INDEX idx_extensions_pricing ON extensions(pricing);
CREATE INDEX idx_extensions_complexity ON extensions(complexity);
CREATE INDEX idx_extensions_enabled ON extensions(enabled);
CREATE INDEX idx_extensions_featured ON extensions(is_featured, usage_count DESC);
CREATE INDEX idx_extensions_official ON extensions(is_official, is_verified);
CREATE INDEX idx_extensions_usage_count ON extensions(usage_count DESC);
CREATE INDEX idx_extensions_rating ON extensions(rating DESC);
CREATE INDEX idx_extensions_updated_at ON extensions(updated_at DESC);

CREATE INDEX idx_user_extensions_user ON user_extensions(user_id);
CREATE INDEX idx_user_extensions_extension ON user_extensions(extension_id);
CREATE INDEX idx_user_extensions_enabled ON user_extensions(user_id, is_enabled);
CREATE INDEX idx_user_extensions_status ON user_extensions(status);

CREATE INDEX idx_extension_usage_user ON extension_usage(user_id);
CREATE INDEX idx_extension_usage_extension ON extension_usage(extension_id);
CREATE INDEX idx_extension_usage_action ON extension_usage(action);
CREATE INDEX idx_extension_usage_created_at ON extension_usage(created_at DESC);
CREATE INDEX idx_extension_usage_session ON extension_usage(session_id);

CREATE INDEX idx_extension_reviews_extension ON extension_reviews(extension_id);
CREATE INDEX idx_extension_reviews_rating ON extension_reviews(extension_id, rating DESC);
CREATE INDEX idx_extension_reviews_public ON extension_reviews(is_public, created_at DESC);

CREATE INDEX idx_template_extensions_template ON template_extensions(template_id);
CREATE INDEX idx_template_extensions_extension ON template_extensions(extension_id);
CREATE INDEX idx_template_extensions_required ON template_extensions(template_id, is_required);

-- Add triggers for updated_at columns
CREATE TRIGGER update_extensions_updated_at 
  BEFORE UPDATE ON extensions 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_extensions_updated_at 
  BEFORE UPDATE ON user_extensions 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_extension_reviews_updated_at 
  BEFORE UPDATE ON extension_reviews 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update extension usage_count when extension_usage is inserted
CREATE OR REPLACE FUNCTION update_extension_usage_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.action = 'selected' OR NEW.action = 'deployed' THEN
    UPDATE extensions 
    SET usage_count = usage_count + 1,
        updated_at = NOW()
    WHERE id = NEW.extension_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_extension_usage_count
  AFTER INSERT ON extension_usage
  FOR EACH ROW EXECUTE FUNCTION update_extension_usage_count();

-- Trigger to update extension rating when reviews are added/updated
CREATE OR REPLACE FUNCTION update_extension_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE extensions 
  SET rating = (
    SELECT ROUND(AVG(rating)::numeric, 2)
    FROM extension_reviews 
    WHERE extension_id = COALESCE(NEW.extension_id, OLD.extension_id)
      AND rating IS NOT NULL
  ),
  updated_at = NOW()
  WHERE id = COALESCE(NEW.extension_id, OLD.extension_id);
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_extension_rating
  AFTER INSERT OR UPDATE OR DELETE ON extension_reviews
  FOR EACH ROW EXECUTE FUNCTION update_extension_rating();