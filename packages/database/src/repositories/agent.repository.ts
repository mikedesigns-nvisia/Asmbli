import { connect } from '@netlify/neon'
import type { Agent, AgentConfig } from '@agentengine/shared-types'

export interface CreateAgentDto {
  name: string
  description: string
  config: AgentConfig
  templateId?: string
  userId: string
}

export interface UpdateAgentDto {
  name?: string
  description?: string
  config?: AgentConfig
}

export class AgentRepository {
  constructor(private databaseUrl: string) {}

  async findByUser(userId: string): Promise<Agent[]> {
    const conn = await connect(this.databaseUrl)
    const result = await conn.query(
      'SELECT * FROM agent_configs WHERE user_id = $1 ORDER BY updated_at DESC',
      [userId]
    )
    
    return result.rows.map(this.mapDbRowToAgent)
  }

  async findById(id: string, userId: string): Promise<Agent | null> {
    const conn = await connect(this.databaseUrl)
    const result = await conn.query(
      'SELECT * FROM agent_configs WHERE id = $1 AND user_id = $2',
      [id, userId]
    )
    
    if (result.rows.length === 0) {
      return null
    }
    
    return this.mapDbRowToAgent(result.rows[0])
  }

  async create(agent: CreateAgentDto): Promise<Agent> {
    const conn = await connect(this.databaseUrl)
    const result = await conn.query(`
      INSERT INTO agent_configs (
        name, description, config, template_id, user_id
      ) VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `, [
      agent.name,
      agent.description,
      JSON.stringify(agent.config),
      agent.templateId,
      agent.userId
    ])
    
    return this.mapDbRowToAgent(result.rows[0])
  }

  async update(id: string, updates: UpdateAgentDto, userId: string): Promise<Agent | null> {
    const conn = await connect(this.databaseUrl)
    
    const fields: string[] = []
    const params: any[] = []
    let paramIndex = 1
    
    if (updates.name !== undefined) {
      fields.push(`name = $${paramIndex++}`)
      params.push(updates.name)
    }
    
    if (updates.description !== undefined) {
      fields.push(`description = $${paramIndex++}`)
      params.push(updates.description)
    }
    
    if (updates.config !== undefined) {
      fields.push(`config = $${paramIndex++}`)
      params.push(JSON.stringify(updates.config))
    }
    
    if (fields.length === 0) {
      return this.findById(id, userId)
    }
    
    fields.push(`updated_at = NOW()`)
    
    const query = `
      UPDATE agent_configs 
      SET ${fields.join(', ')}
      WHERE id = $${paramIndex} AND user_id = $${paramIndex + 1}
      RETURNING *
    `
    params.push(id, userId)
    
    const result = await conn.query(query, params)
    
    if (result.rows.length === 0) {
      return null
    }
    
    return this.mapDbRowToAgent(result.rows[0])
  }

  async delete(id: string, userId: string): Promise<boolean> {
    const conn = await connect(this.databaseUrl)
    const result = await conn.query(
      'DELETE FROM agent_configs WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, userId]
    )
    return result.rows.length > 0
  }

  async forkFromTemplate(templateId: string, userId: string, overrides?: Partial<CreateAgentDto>): Promise<Agent | null> {
    const conn = await connect(this.databaseUrl)
    
    // First, get the template
    const templateResult = await conn.query(
      'SELECT * FROM templates WHERE id = $1 AND is_public = true',
      [templateId]
    )
    
    if (templateResult.rows.length === 0) {
      return null
    }
    
    const template = templateResult.rows[0]
    
    // Create agent from template
    const agentData: CreateAgentDto = {
      name: overrides?.name || `${template.name} (Copy)`,
      description: overrides?.description || template.description,
      config: overrides?.config || JSON.parse(template.config),
      templateId,
      userId
    }
    
    const agent = await this.create(agentData)
    
    // Increment template usage count
    await conn.query(
      'UPDATE templates SET usage_count = usage_count + 1 WHERE id = $1',
      [templateId]
    )
    
    return agent
  }

  async getUsageStats(userId: string): Promise<{ totalAgents: number; totalMessages: number }> {
    const conn = await connect(this.databaseUrl)
    
    // Get total agents
    const agentsResult = await conn.query(
      'SELECT COUNT(*) as count FROM agent_configs WHERE user_id = $1',
      [userId]
    )
    
    // Get total messages (would need chat_sessions table)
    const messagesResult = await conn.query(`
      SELECT COUNT(*) as count 
      FROM chat_sessions cs 
      JOIN agent_configs ac ON cs.agent_id = ac.id 
      WHERE ac.user_id = $1
    `, [userId])
    
    return {
      totalAgents: parseInt(agentsResult.rows[0].count),
      totalMessages: parseInt(messagesResult.rows[0]?.count || '0')
    }
  }

  private mapDbRowToAgent(row: any): Agent {
    return {
      id: row.id,
      name: row.name,
      description: row.description,
      config: typeof row.config === 'string' ? JSON.parse(row.config) : row.config,
      templateId: row.template_id,
      userId: row.user_id,
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at)
    }
  }
}