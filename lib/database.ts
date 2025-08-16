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

  // Extensions management
  static async getAllExtensions(userRole?: string) {
    let extensions;

    // Filter by user role if specified
    if (userRole === 'beginner') {
      extensions = await sql`
        SELECT 
          id, name, description, category, provider, icon, complexity, enabled,
          connection_type, auth_method, pricing, features, capabilities, requirements,
          documentation, setup_complexity, configuration, supported_connection_types,
          security_level, version, is_official, is_featured, is_verified, usage_count, rating,
          created_at, updated_at
        FROM extensions 
        WHERE enabled = true 
          AND (is_featured = true OR complexity = 'low')
          AND pricing IN ('free', 'freemium')
        ORDER BY is_featured DESC, usage_count DESC
        LIMIT 20
      `;
    } else {
      extensions = await sql`
        SELECT 
          id, name, description, category, provider, icon, complexity, enabled,
          connection_type, auth_method, pricing, features, capabilities, requirements,
          documentation, setup_complexity, configuration, supported_connection_types,
          security_level, version, is_official, is_featured, is_verified, usage_count, rating,
          created_at, updated_at
        FROM extensions 
        WHERE enabled = true
        ORDER BY is_featured DESC, usage_count DESC
      `;
    }
    return extensions.map(ext => ({
      ...ext,
      features: Array.isArray(ext.features) ? ext.features : [],
      capabilities: Array.isArray(ext.capabilities) ? ext.capabilities : [],
      requirements: Array.isArray(ext.requirements) ? ext.requirements : [],
      supported_connection_types: Array.isArray(ext.supported_connection_types) ? ext.supported_connection_types : [],
      configuration: typeof ext.configuration === 'string' ? JSON.parse(ext.configuration) : ext.configuration
    }));
  }

  static async getExtensionsByCategory(category: string, userRole?: string) {
    let extensions;

    if (userRole === 'beginner') {
      extensions = await sql`
        SELECT 
          id, name, description, category, provider, icon, complexity, enabled,
          connection_type, auth_method, pricing, features, capabilities, requirements,
          documentation, setup_complexity, configuration, supported_connection_types,
          security_level, version, is_official, is_featured, is_verified, usage_count, rating,
          created_at, updated_at
        FROM extensions 
        WHERE enabled = true 
          AND category = ${category}
          AND complexity IN ('low', 'medium')
          AND pricing IN ('free', 'freemium')
        ORDER BY is_featured DESC, usage_count DESC
      `;
    } else {
      extensions = await sql`
        SELECT 
          id, name, description, category, provider, icon, complexity, enabled,
          connection_type, auth_method, pricing, features, capabilities, requirements,
          documentation, setup_complexity, configuration, supported_connection_types,
          security_level, version, is_official, is_featured, is_verified, usage_count, rating,
          created_at, updated_at
        FROM extensions 
        WHERE enabled = true AND category = ${category}
        ORDER BY is_featured DESC, usage_count DESC
      `;
    }
    return extensions.map(ext => ({
      ...ext,
      features: Array.isArray(ext.features) ? ext.features : [],
      capabilities: Array.isArray(ext.capabilities) ? ext.capabilities : [],
      requirements: Array.isArray(ext.requirements) ? ext.requirements : [],
      supported_connection_types: Array.isArray(ext.supported_connection_types) ? ext.supported_connection_types : [],
      configuration: typeof ext.configuration === 'string' ? JSON.parse(ext.configuration) : ext.configuration
    }));
  }

  static async getExtensionById(extensionId: string) {
    const [extension] = await sql`
      SELECT 
        id, name, description, category, provider, icon, complexity, enabled,
        connection_type, auth_method, pricing, features, capabilities, requirements,
        documentation, setup_complexity, configuration, supported_connection_types,
        security_level, version, is_official, is_featured, is_verified, usage_count, rating,
        created_at, updated_at
      FROM extensions 
      WHERE id = ${extensionId}
    `;
    
    if (!extension) return null;
    
    return {
      ...extension,
      features: Array.isArray(extension.features) ? extension.features : [],
      capabilities: Array.isArray(extension.capabilities) ? extension.capabilities : [],
      requirements: Array.isArray(extension.requirements) ? extension.requirements : [],
      supported_connection_types: Array.isArray(extension.supported_connection_types) ? extension.supported_connection_types : [],
      configuration: typeof extension.configuration === 'string' ? JSON.parse(extension.configuration) : extension.configuration
    };
  }

  static async getFeaturedExtensions(limit = 10) {
    const extensions = await sql`
      SELECT 
        id, name, description, category, provider, icon, complexity, enabled,
        connection_type, auth_method, pricing, features, capabilities, requirements,
        documentation, setup_complexity, configuration, supported_connection_types,
        security_level, version, is_official, is_featured, is_verified, usage_count, rating,
        created_at, updated_at
      FROM extensions 
      WHERE enabled = true AND is_featured = true
      ORDER BY usage_count DESC, rating DESC
      LIMIT ${limit}
    `;
    
    return extensions.map(ext => ({
      ...ext,
      features: Array.isArray(ext.features) ? ext.features : [],
      capabilities: Array.isArray(ext.capabilities) ? ext.capabilities : [],
      requirements: Array.isArray(ext.requirements) ? ext.requirements : [],
      supported_connection_types: Array.isArray(ext.supported_connection_types) ? ext.supported_connection_types : [],
      configuration: typeof ext.configuration === 'string' ? JSON.parse(ext.configuration) : ext.configuration
    }));
  }

  // User extension preferences
  static async getUserExtensions(userId: string) {
    const userExtensions = await sql`
      SELECT 
        ue.id, ue.is_enabled, ue.selected_platforms, ue.configuration as user_config,
        ue.status, ue.config_progress, ue.created_at as user_created_at,
        e.id as extension_id, e.name, e.description, e.category, e.provider, e.icon, 
        e.complexity, e.connection_type, e.auth_method, e.pricing, e.features, 
        e.capabilities, e.requirements, e.documentation, e.setup_complexity, 
        e.configuration as default_config, e.supported_connection_types,
        e.security_level, e.version, e.is_official, e.is_featured, e.is_verified
      FROM user_extensions ue
      JOIN extensions e ON ue.extension_id = e.id
      WHERE ue.user_id = ${userId}
      ORDER BY ue.created_at DESC
    `;
    
    return userExtensions.map(ue => ({
      id: ue.extension_id,
      name: ue.name,
      description: ue.description,
      category: ue.category,
      provider: ue.provider,
      icon: ue.icon,
      complexity: ue.complexity,
      enabled: ue.is_enabled,
      connectionType: ue.connection_type,
      authMethod: ue.auth_method,
      pricing: ue.pricing,
      features: Array.isArray(ue.features) ? ue.features : [],
      capabilities: Array.isArray(ue.capabilities) ? ue.capabilities : [],
      requirements: Array.isArray(ue.requirements) ? ue.requirements : [],
      documentation: ue.documentation,
      setupComplexity: ue.setup_complexity,
      configuration: typeof ue.default_config === 'string' ? JSON.parse(ue.default_config) : ue.default_config,
      supportedConnectionTypes: Array.isArray(ue.supported_connection_types) ? ue.supported_connection_types : [],
      securityLevel: ue.security_level,
      version: ue.version,
      isOfficial: ue.is_official,
      isFeatured: ue.is_featured,
      isVerified: ue.is_verified,
      selectedPlatforms: Array.isArray(ue.selected_platforms) ? ue.selected_platforms : [],
      status: ue.status,
      configProgress: ue.config_progress,
      userConfig: typeof ue.user_config === 'string' ? JSON.parse(ue.user_config) : ue.user_config
    }));
  }

  static async saveUserExtension(userId: string, extensionId: string, config: {
    isEnabled?: boolean;
    selectedPlatforms?: string[];
    configuration?: any;
    status?: string;
    configProgress?: number;
  }) {
    const [userExtension] = await sql`
      INSERT INTO user_extensions (
        user_id, extension_id, is_enabled, selected_platforms, configuration, 
        status, config_progress, created_at, updated_at
      )
      VALUES (
        ${userId}, ${extensionId}, ${config.isEnabled ?? true}, 
        ${JSON.stringify(config.selectedPlatforms || [])}, 
        ${JSON.stringify(config.configuration || {})},
        ${config.status || 'configuring'}, ${config.configProgress || 25},
        NOW(), NOW()
      )
      ON CONFLICT (user_id, extension_id)
      DO UPDATE SET
        is_enabled = ${config.isEnabled ?? true},
        selected_platforms = ${JSON.stringify(config.selectedPlatforms || [])},
        configuration = ${JSON.stringify(config.configuration || {})},
        status = ${config.status || 'configuring'},
        config_progress = ${config.configProgress || 25},
        updated_at = NOW()
      RETURNING id, user_id, extension_id, is_enabled, selected_platforms, 
                configuration, status, config_progress, created_at, updated_at
    `;
    
    return {
      ...userExtension,
      selected_platforms: Array.isArray(userExtension.selected_platforms) ? userExtension.selected_platforms : [],
      configuration: typeof userExtension.configuration === 'string' ? JSON.parse(userExtension.configuration) : userExtension.configuration
    };
  }

  static async removeUserExtension(userId: string, extensionId: string) {
    await sql`
      DELETE FROM user_extensions 
      WHERE user_id = ${userId} AND extension_id = ${extensionId}
    `;
  }

  // Extension analytics and usage tracking
  static async logExtensionUsage(userId: string, extensionId: string, action: string, metadata?: any, sessionId?: string) {
    await sql`
      INSERT INTO extension_usage (user_id, extension_id, action, metadata, session_id, created_at)
      VALUES (${userId}, ${extensionId}, ${action}, ${metadata ? JSON.stringify(metadata) : null}, ${sessionId}, NOW())
    `;
  }

  static async getExtensionUsageStats(extensionId: string, days = 30) {
    const stats = await sql`
      SELECT 
        action,
        COUNT(*) as count,
        COUNT(DISTINCT user_id) as unique_users
      FROM extension_usage 
      WHERE extension_id = ${extensionId} 
        AND created_at > NOW() - INTERVAL '${days} days'
      GROUP BY action
      ORDER BY count DESC
    `;
    return stats;
  }

  static async getUserExtensionUsage(userId: string, days = 30) {
    const usage = await sql`
      SELECT 
        eu.extension_id,
        e.name as extension_name,
        eu.action,
        COUNT(*) as count,
        MAX(eu.created_at) as last_used
      FROM extension_usage eu
      JOIN extensions e ON eu.extension_id = e.id
      WHERE eu.user_id = ${userId} 
        AND eu.created_at > NOW() - INTERVAL '${days} days'
      GROUP BY eu.extension_id, e.name, eu.action
      ORDER BY count DESC, last_used DESC
    `;
    return usage;
  }

  // Extension reviews and ratings
  static async saveExtensionReview(userId: string, extensionId: string, rating: number, reviewText?: string) {
    const [review] = await sql`
      INSERT INTO extension_reviews (user_id, extension_id, rating, review_text, created_at, updated_at)
      VALUES (${userId}, ${extensionId}, ${rating}, ${reviewText}, NOW(), NOW())
      ON CONFLICT (user_id, extension_id)
      DO UPDATE SET
        rating = ${rating},
        review_text = ${reviewText},
        updated_at = NOW()
      RETURNING id, user_id, extension_id, rating, review_text, is_public, created_at, updated_at
    `;
    return review;
  }

  static async getExtensionReviews(extensionId: string, limit = 10) {
    const reviews = await sql`
      SELECT 
        er.rating, er.review_text, er.created_at,
        u.name as user_name
      FROM extension_reviews er
      JOIN users u ON er.user_id = u.id
      WHERE er.extension_id = ${extensionId} 
        AND er.is_public = true
        AND er.review_text IS NOT NULL
      ORDER BY er.created_at DESC
      LIMIT ${limit}
    `;
    return reviews;
  }
}