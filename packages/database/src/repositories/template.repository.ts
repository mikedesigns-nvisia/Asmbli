import { connect } from '@netlify/neon'
import type { Template, TemplateCategory, PaginatedResponse } from '@agentengine/shared-types'

export interface TemplateFilters {
  category?: TemplateCategory
  search?: string
  author?: string
  isPublic?: boolean
}

export interface CreateTemplateDto {
  name: string
  description: string
  category: TemplateCategory
  config: object
  isPublic: boolean
  author: string
  userId: string
  tags?: string[]
}

export interface UpdateTemplateDto {
  name?: string
  description?: string
  category?: TemplateCategory
  config?: object
  isPublic?: boolean
  tags?: string[]
}

export class TemplateRepository {
  constructor(private databaseUrl: string) {}

  async findAll(
    filters?: TemplateFilters,
    limit: number = 50,
    offset: number = 0
  ): Promise<PaginatedResponse<Template>> {
    const conn = await connect(this.databaseUrl)
    
    let query = 'SELECT * FROM templates WHERE 1=1'
    const params: any[] = []
    
    if (filters?.category) {
      query += ' AND category = $' + (params.length + 1)
      params.push(filters.category)
    }
    
    if (filters?.search) {
      query += ' AND (name ILIKE $' + (params.length + 1) + ' OR description ILIKE $' + (params.length + 2) + ')'
      params.push(`%${filters.search}%`, `%${filters.search}%`)
    }
    
    if (filters?.author) {
      query += ' AND author = $' + (params.length + 1)
      params.push(filters.author)
    }
    
    if (filters?.isPublic !== undefined) {
      query += ' AND is_public = $' + (params.length + 1)
      params.push(filters.isPublic)
    }
    
    // Get total count
    const countQuery = query.replace('SELECT *', 'SELECT COUNT(*)')
    const countResult = await conn.query(countQuery, params)
    const total = parseInt(countResult.rows[0].count)
    
    // Add pagination and ordering
    query += ' ORDER BY usage_count DESC, created_at DESC'
    query += ' LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2)
    params.push(limit, offset)
    
    const result = await conn.query(query, params)
    
    return {
      data: result.rows,
      total,
      page: Math.floor(offset / limit) + 1,
      limit,
      hasMore: offset + result.rows.length < total
    }
  }

  async findById(id: string): Promise<Template | null> {
    const conn = await connect(this.databaseUrl)
    const result = await conn.query('SELECT * FROM templates WHERE id = $1', [id])
    return result.rows[0] || null
  }

  async create(template: CreateTemplateDto): Promise<Template> {
    const conn = await connect(this.databaseUrl)
    const result = await conn.query(`
      INSERT INTO templates (
        name, description, category, config, is_public, author, user_id, tags
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `, [
      template.name,
      template.description,
      template.category,
      JSON.stringify(template.config),
      template.isPublic,
      template.author,
      template.userId,
      JSON.stringify(template.tags || [])
    ])
    
    return result.rows[0]
  }

  async update(id: string, updates: UpdateTemplateDto, userId: string): Promise<Template | null> {
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
    
    if (updates.category !== undefined) {
      fields.push(`category = $${paramIndex++}`)
      params.push(updates.category)
    }
    
    if (updates.config !== undefined) {
      fields.push(`config = $${paramIndex++}`)
      params.push(JSON.stringify(updates.config))
    }
    
    if (updates.isPublic !== undefined) {
      fields.push(`is_public = $${paramIndex++}`)
      params.push(updates.isPublic)
    }
    
    if (updates.tags !== undefined) {
      fields.push(`tags = $${paramIndex++}`)
      params.push(JSON.stringify(updates.tags))
    }
    
    if (fields.length === 0) {
      return this.findById(id)
    }
    
    fields.push(`updated_at = NOW()`)
    
    const query = `
      UPDATE templates 
      SET ${fields.join(', ')}
      WHERE id = $${paramIndex} AND user_id = $${paramIndex + 1}
      RETURNING *
    `
    params.push(id, userId)
    
    const result = await conn.query(query, params)
    return result.rows[0] || null
  }

  async delete(id: string, userId: string): Promise<boolean> {
    const conn = await connect(this.databaseUrl)
    const result = await conn.query(
      'DELETE FROM templates WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, userId]
    )
    return result.rows.length > 0
  }

  async findByUser(userId: string): Promise<Template[]> {
    const conn = await connect(this.databaseUrl)
    const result = await conn.query(
      'SELECT * FROM templates WHERE user_id = $1 ORDER BY updated_at DESC',
      [userId]
    )
    return result.rows
  }

  async markAsPublic(id: string, userId: string): Promise<Template | null> {
    const conn = await connect(this.databaseUrl)
    const result = await conn.query(`
      UPDATE templates 
      SET is_public = true, updated_at = NOW()
      WHERE id = $1 AND user_id = $2
      RETURNING *
    `, [id, userId])
    
    return result.rows[0] || null
  }

  async incrementUsageCount(id: string): Promise<void> {
    const conn = await connect(this.databaseUrl)
    await conn.query(
      'UPDATE templates SET usage_count = usage_count + 1 WHERE id = $1',
      [id]
    )
  }

  async updateRating(id: string, rating: number): Promise<void> {
    const conn = await connect(this.databaseUrl)
    await conn.query(
      'UPDATE templates SET rating = $1 WHERE id = $2',
      [rating, id]
    )
  }
}