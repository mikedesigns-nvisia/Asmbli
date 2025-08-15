import { neon } from '@netlify/neon';

// Initialize the Neon connection
// Uses DATABASE_URL or NETLIFY_DATABASE_URL environment variable
export const sql = neon(process.env.DATABASE_URL || process.env.NETLIFY_DATABASE_URL);

// Database utility functions
export class Database {
  // User management
  static async createUser(email: string, name: string, role: 'beginner' | 'power_user' | 'enterprise') {
    const [user] = await sql`
      INSERT INTO users (email, name, role, created_at)
      VALUES (${email}, ${name}, ${role}, NOW())
      RETURNING id, email, name, role, created_at
    `;
    return user;
  }

  static async getUserById(userId: string) {
    const [user] = await sql`
      SELECT id, email, name, role, created_at, updated_at
      FROM users 
      WHERE id = ${userId}
    `;
    return user;
  }

  static async getUserByEmail(email: string) {
    const [user] = await sql`
      SELECT id, email, name, role, created_at, updated_at
      FROM users 
      WHERE email = ${email}
    `;
    return user;
  }

  static async updateUser(userId: string, updates: Partial<{ name: string; role: string }>) {
    const setClauses = Object.entries(updates)
      .map(([key]) => `${key} = $${key}`)
      .join(', ');

    const [user] = await sql`
      UPDATE users 
      SET ${sql.unsafe(setClauses)}, updated_at = NOW()
      WHERE id = ${userId}
      RETURNING id, email, name, role, updated_at
    `;
    return user;
  }

  // Agent configuration management
  static async saveAgentConfig(userId: string, config: any) {
    const [agentConfig] = await sql`
      INSERT INTO agent_configs (user_id, config, created_at)
      VALUES (${userId}, ${JSON.stringify(config)}, NOW())
      RETURNING id, user_id, config, created_at
    `;
    return agentConfig;
  }

  static async getAgentConfigs(userId: string) {
    const configs = await sql`
      SELECT id, config, created_at, updated_at
      FROM agent_configs 
      WHERE user_id = ${userId}
      ORDER BY created_at DESC
    `;
    return configs.map(config => ({
      ...config,
      config: typeof config.config === 'string' ? JSON.parse(config.config) : config.config
    }));
  }

  static async updateAgentConfig(configId: string, config: any) {
    const [agentConfig] = await sql`
      UPDATE agent_configs 
      SET config = ${JSON.stringify(config)}, updated_at = NOW()
      WHERE id = ${configId}
      RETURNING id, user_id, config, updated_at
    `;
    return {
      ...agentConfig,
      config: typeof agentConfig.config === 'string' ? JSON.parse(agentConfig.config) : agentConfig.config
    };
  }

  static async deleteAgentConfig(configId: string) {
    await sql`
      DELETE FROM agent_configs 
      WHERE id = ${configId}
    `;
  }

  // Template management
  static async saveTemplate(name: string, description: string, config: any, isPublic = false, createdBy?: string) {
    const [template] = await sql`
      INSERT INTO templates (name, description, config, is_public, created_by, created_at)
      VALUES (${name}, ${description}, ${JSON.stringify(config)}, ${isPublic}, ${createdBy}, NOW())
      RETURNING id, name, description, config, is_public, created_by, created_at
    `;
    return {
      ...template,
      config: typeof template.config === 'string' ? JSON.parse(template.config) : template.config
    };
  }

  static async getPublicTemplates() {
    const templates = await sql`
      SELECT t.id, t.name, t.description, t.config, t.created_at, u.name as creator_name
      FROM templates t
      LEFT JOIN users u ON t.created_by = u.id
      WHERE t.is_public = true
      ORDER BY t.created_at DESC
    `;
    return templates.map(template => ({
      ...template,
      config: typeof template.config === 'string' ? JSON.parse(template.config) : template.config
    }));
  }

  static async getUserTemplates(userId: string) {
    const templates = await sql`
      SELECT id, name, description, config, is_public, created_at
      FROM templates 
      WHERE created_by = ${userId}
      ORDER BY created_at DESC
    `;
    return templates.map(template => ({
      ...template,
      config: typeof template.config === 'string' ? JSON.parse(template.config) : template.config
    }));
  }

  static async getTemplateById(templateId: string) {
    const [template] = await sql`
      SELECT t.id, t.name, t.description, t.config, t.is_public, t.created_at, u.name as creator_name
      FROM templates t
      LEFT JOIN users u ON t.created_by = u.id
      WHERE t.id = ${templateId}
    `;
    if (!template) return null;
    return {
      ...template,
      config: typeof template.config === 'string' ? JSON.parse(template.config) : template.config
    };
  }

  // Analytics and usage tracking
  static async logUserAction(userId: string, action: string, metadata?: any) {
    await sql`
      INSERT INTO user_actions (user_id, action, metadata, created_at)
      VALUES (${userId}, ${action}, ${metadata ? JSON.stringify(metadata) : null}, NOW())
    `;
  }

  static async getUserActionStats(userId: string, days = 30) {
    const stats = await sql`
      SELECT action, COUNT(*) as count
      FROM user_actions 
      WHERE user_id = ${userId} 
        AND created_at > NOW() - INTERVAL '${days} days'
      GROUP BY action
      ORDER BY count DESC
    `;
    return stats;
  }

  // Key-value store (compatible with existing Supabase implementation)
  static async set(key: string, value: any) {
    await sql`
      INSERT INTO kv_store (key, value, created_at, updated_at)
      VALUES (${key}, ${JSON.stringify(value)}, NOW(), NOW())
      ON CONFLICT (key)
      DO UPDATE SET value = ${JSON.stringify(value)}, updated_at = NOW()
    `;
  }

  static async get(key: string) {
    const [result] = await sql`
      SELECT value FROM kv_store WHERE key = ${key}
    `;
    if (!result) return null;
    return typeof result.value === 'string' ? JSON.parse(result.value) : result.value;
  }

  static async delete(key: string) {
    await sql`
      DELETE FROM kv_store WHERE key = ${key}
    `;
  }

  static async getByPrefix(prefix: string) {
    const results = await sql`
      SELECT key, value FROM kv_store WHERE key LIKE ${prefix + '%'}
    `;
    return results.map(result => ({
      key: result.key,
      value: typeof result.value === 'string' ? JSON.parse(result.value) : result.value
    }));
  }
}