import { Handler } from '@netlify/functions';
import { sql } from '../../lib/database.js';

export const handler: Handler = async (event, context) => {
  const { httpMethod } = event;

  // Set CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Content-Type': 'application/json',
  };

  // Handle preflight requests
  if (httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: '',
    };
  }

  try {
    // Check if NETLIFY_DATABASE_URL is available
    if (!process.env.NETLIFY_DATABASE_URL) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          error: 'Database not configured',
          message: 'NETLIFY_DATABASE_URL environment variable is not set',
        }),
      };
    }

    console.log('Setting up database schema...');

    // Create migrations table first
    await sql`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      )
    `;

    // Check if initial schema has been run
    const [initialMigration] = await sql`
      SELECT name FROM migrations WHERE name = '001_initial_schema.sql'
    `;

    if (!initialMigration) {
      console.log('Running initial schema migration...');
      
      // Initial schema
      await sql`
        CREATE TABLE IF NOT EXISTS users (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          email VARCHAR(255) UNIQUE NOT NULL,
          name VARCHAR(255) NOT NULL,
          role VARCHAR(50) NOT NULL CHECK (role IN ('beginner', 'power_user', 'enterprise')),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      `;

      await sql`
        CREATE TABLE IF NOT EXISTS agent_configs (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          config JSONB NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      `;

      await sql`
        CREATE TABLE IF NOT EXISTS templates (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          description TEXT,
          config JSONB NOT NULL,
          is_public BOOLEAN DEFAULT false,
          created_by UUID REFERENCES users(id) ON DELETE SET NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      `;

      await sql`
        CREATE TABLE IF NOT EXISTS user_actions (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          action VARCHAR(100) NOT NULL,
          metadata JSONB,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      `;

      await sql`
        CREATE TABLE IF NOT EXISTS kv_store (
          key TEXT PRIMARY KEY,
          value JSONB NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      `;

      // Create indexes
      await sql`CREATE INDEX IF NOT EXISTS idx_agent_configs_user_id ON agent_configs(user_id)`;
      await sql`CREATE INDEX IF NOT EXISTS idx_templates_public ON templates(is_public, created_at DESC)`;
      await sql`CREATE INDEX IF NOT EXISTS idx_user_actions_user_id ON user_actions(user_id)`;

      // Record migration
      await sql`INSERT INTO migrations (name) VALUES ('001_initial_schema.sql')`;
      console.log('✓ Initial schema migration completed');
    }

    // Check if enhanced schema has been run
    const [enhancedMigration] = await sql`
      SELECT name FROM migrations WHERE name = '002_enhanced_template_schema.sql'
    `;

    if (!enhancedMigration) {
      console.log('Running enhanced template schema migration...');
      
      // Enhanced template schema
      await sql`
        CREATE TABLE IF NOT EXISTS template_categories (
          id VARCHAR(50) PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          description TEXT,
          icon VARCHAR(50),
          color VARCHAR(50),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      `;

      // Insert default categories
      const categories = [
        ['development', 'Development', 'Code generation, API development, and software engineering', '💻', '#3B82F6'],
        ['design', 'Design & Creative', 'UI/UX design, creative content, and visual assets', '🎨', '#8B5CF6'],
        ['data', 'Data & Analytics', 'Data processing, analysis, and reporting', '📊', '#10B981'],
        ['marketing', 'Marketing & Content', 'Content creation, SEO, and digital marketing', '📢', '#F59E0B'],
        ['productivity', 'Productivity', 'Task automation, organization, and workflows', '⚡', '#6366F1'],
        ['education', 'Education & Training', 'Learning resources, tutorials, and educational content', '📚', '#EF4444'],
        ['business', 'Business & Finance', 'Business analysis, financial planning, and strategy', '💼', '#059669'],
        ['security', 'Security & Compliance', 'Security analysis, compliance, and risk management', '🔒', '#DC2626']
      ];

      for (const [id, name, description, icon, color] of categories) {
        await sql`
          INSERT INTO template_categories (id, name, description, icon, color) 
          VALUES (${id}, ${name}, ${description}, ${icon}, ${color})
          ON CONFLICT (id) DO NOTHING
        `;
      }

      // Add new columns to templates table
      await sql`ALTER TABLE templates ADD COLUMN IF NOT EXISTS category VARCHAR(50) REFERENCES template_categories(id)`;
      await sql`ALTER TABLE templates ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}'`;
      await sql`ALTER TABLE templates ADD COLUMN IF NOT EXISTS usage_count INTEGER DEFAULT 0`;
      await sql`ALTER TABLE templates ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMP WITH TIME ZONE`;
      await sql`ALTER TABLE templates ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1`;

      // Create extensions table
      await sql`
        CREATE TABLE IF NOT EXISTS extensions (
          id VARCHAR(100) PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          description TEXT,
          category VARCHAR(50),
          provider VARCHAR(100),
          pricing VARCHAR(20) DEFAULT 'free',
          connection_type VARCHAR(20) DEFAULT 'mcp',
          is_enabled BOOLEAN DEFAULT true,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      `;

      // Insert default extensions
      const extensions = [
        ['postgres-mcp', 'PostgreSQL MCP', 'Database operations and queries', 'database', 'official', 'free', 'mcp'],
        ['file-manager-mcp', 'File Manager MCP', 'File system operations', 'utility', 'official', 'free', 'mcp'],
        ['terminal-mcp', 'Terminal MCP', 'Command line interface', 'utility', 'official', 'free', 'mcp'],
        ['git-mcp', 'Git MCP', 'Version control operations', 'development', 'official', 'free', 'mcp'],
        ['http-mcp', 'HTTP Client MCP', 'HTTP requests and API calls', 'api', 'official', 'free', 'mcp']
      ];

      for (const [id, name, description, category, provider, pricing, connection_type] of extensions) {
        await sql`
          INSERT INTO extensions (id, name, description, category, provider, pricing, connection_type) 
          VALUES (${id}, ${name}, ${description}, ${category}, ${provider}, ${pricing}, ${connection_type})
          ON CONFLICT (id) DO NOTHING
        `;
      }

      // Update existing templates to have default category
      await sql`UPDATE templates SET category = 'development' WHERE category IS NULL`;

      // Record migration
      await sql`INSERT INTO migrations (name) VALUES ('002_enhanced_template_schema.sql')`;
      console.log('✓ Enhanced template schema migration completed');
    }

    // Get final status
    const migrations = await sql`SELECT name FROM migrations ORDER BY id`;
    const categories = await sql`SELECT COUNT(*) as count FROM template_categories`;
    const extensions = await sql`SELECT COUNT(*) as count FROM extensions`;

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        success: true,
        message: 'Database setup completed successfully',
        migrations: migrations.map(m => m.name),
        tables: {
          categories: categories[0].count,
          extensions: extensions[0].count
        }
      }),
    };

  } catch (error) {
    console.error('Database setup error:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        message: 'Database setup failed',
      }),
    };
  }
};