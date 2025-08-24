import type { Handler } from '@netlify/functions'
import { connect } from '@netlify/neon'

interface Agent {
  id: string
  name: string
  description: string
  config: object
  template_id?: string
  user_id: string
  created_at: string
  updated_at: string
}

export const handler: Handler = async (event, context) => {
  const { httpMethod, path, queryStringParameters, body } = event
  
  // CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
  }

  if (httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: ''
    }
  }

  try {
    // Extract user ID from auth token (simplified for now)
    const authHeader = event.headers.authorization
    if (!authHeader) {
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({ error: 'Authentication required' })
      }
    }
    
    const userId = 'user-1' // Would extract from JWT token
    const conn = await connect(process.env.DATABASE_URL)
    
    switch (httpMethod) {
      case 'GET':
        // Get user's saved agents
        const agentId = path?.split('/').pop()
        
        if (agentId && agentId !== 'agents') {
          // Get specific agent
          const result = await conn.query(
            'SELECT * FROM agent_configs WHERE id = $1 AND user_id = $2',
            [agentId, userId]
          )
          
          if (result.rows.length === 0) {
            return {
              statusCode: 404,
              headers,
              body: JSON.stringify({ error: 'Agent not found' })
            }
          }
          
          return {
            statusCode: 200,
            headers,
            body: JSON.stringify(result.rows[0])
          }
        } else {
          // Get all user agents
          const result = await conn.query(
            'SELECT * FROM agent_configs WHERE user_id = $1 ORDER BY updated_at DESC',
            [userId]
          )
          
          return {
            statusCode: 200,
            headers,
            body: JSON.stringify(result.rows)
          }
        }
        
      case 'POST':
        // Create new agent or fork from template
        const agentData = JSON.parse(body || '{}')
        const { name, description, config, template_id, action } = agentData
        
        if (!name || !description || !config) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Missing required fields' })
          }
        }
        
        if (action === 'fork' && template_id) {
          // Fork from template
          const templateResult = await conn.query(
            'SELECT * FROM templates WHERE id = $1 AND is_public = true',
            [template_id]
          )
          
          if (templateResult.rows.length === 0) {
            return {
              statusCode: 404,
              headers,
              body: JSON.stringify({ error: 'Template not found' })
            }
          }
          
          // Update template usage count
          await conn.query(
            'UPDATE templates SET usage_count = usage_count + 1 WHERE id = $1',
            [template_id]
          )
        }
        
        const insertResult = await conn.query(`
          INSERT INTO agent_configs (name, description, config, template_id, user_id)
          VALUES ($1, $2, $3, $4, $5)
          RETURNING *
        `, [name, description, JSON.stringify(config), template_id, userId])
        
        return {
          statusCode: 201,
          headers,
          body: JSON.stringify(insertResult.rows[0])
        }
        
      case 'PUT':
        // Update agent
        const updateAgentId = path?.split('/').pop()
        if (!updateAgentId) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Agent ID required' })
          }
        }
        
        const updateData = JSON.parse(body || '{}')
        
        const updateResult = await conn.query(`
          UPDATE agent_configs 
          SET name = COALESCE($1, name),
              description = COALESCE($2, description),
              config = COALESCE($3, config),
              updated_at = NOW()
          WHERE id = $4 AND user_id = $5
          RETURNING *
        `, [
          updateData.name,
          updateData.description,
          updateData.config ? JSON.stringify(updateData.config) : null,
          updateAgentId,
          userId
        ])
        
        if (updateResult.rows.length === 0) {
          return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Agent not found or permission denied' })
          }
        }
        
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify(updateResult.rows[0])
        }
        
      case 'DELETE':
        // Delete agent
        const deleteAgentId = path?.split('/').pop()
        if (!deleteAgentId) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Agent ID required' })
          }
        }
        
        const deleteResult = await conn.query(
          'DELETE FROM agent_configs WHERE id = $1 AND user_id = $2 RETURNING id',
          [deleteAgentId, userId]
        )
        
        if (deleteResult.rows.length === 0) {
          return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Agent not found or permission denied' })
          }
        }
        
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ message: 'Agent deleted successfully' })
        }
        
      default:
        return {
          statusCode: 405,
          headers,
          body: JSON.stringify({ error: 'Method not allowed' })
        }
    }
  } catch (error) {
    // Console output removed for production
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error' })
    }
  }
}