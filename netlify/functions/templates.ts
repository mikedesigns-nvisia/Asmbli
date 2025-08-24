import { Handler } from '@netlify/functions';
import { Database } from '../../lib/database.js';

export const handler: Handler = async (event, context) => {
  const { httpMethod, queryStringParameters, body } = event;

  // Set CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
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
    // Check if database is configured
    if (!process.env.DATABASE_URL && !process.env.NETLIFY_DATABASE_URL) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          error: 'Database not configured',
          message: 'DATABASE_URL environment variable is not set',
        }),
      };
    }

    switch (httpMethod) {
      case 'GET':
        const action = queryStringParameters?.action || 'list';
        
        switch (action) {
          case 'list':
            // Get all templates for user
            const userRole = queryStringParameters?.role || 'beginner';
            const userId = queryStringParameters?.userId;
            
            try {
              // Get user templates if userId provided
              let userTemplates: any[] = [];
              if (userId) {
                userTemplates = await Database.getUserTemplates(userId);
              }

              // Get public templates
              const publicTemplates = await Database.getPublicTemplates();

              // Convert to frontend format
              const allTemplates = [
                ...userTemplates.map((t: any) => ({
                  id: t.id,
                  name: t.name,
                  description: t.description,
                  category: t.config?.category || 'custom',
                  tags: t.config?.tags || [],
                  createdAt: t.created_at,
                  updatedAt: t.updated_at || t.created_at,
                  isPublic: t.is_public,
                  usageCount: 0,
                  wizardData: t.config?.wizardData
                })),
                ...publicTemplates.map((t: any) => ({
                  id: t.id,
                  name: t.name,
                  description: t.description,
                  category: t.config?.category || 'custom',
                  tags: t.config?.tags || [],
                  createdAt: t.created_at,
                  updatedAt: t.updated_at || t.created_at,
                  isPublic: t.is_public,
                  usageCount: 0,
                  wizardData: t.config?.wizardData
                }))
              ];

              return {
                statusCode: 200,
                headers,
                body: JSON.stringify({ templates: allTemplates }),
              };
            } catch (error) {
              // Console output removed for production
              return {
                statusCode: 200,
                headers,
                body: JSON.stringify({ templates: [] }),
              };
            }

          case 'categories':
            // Return default categories (these could come from database later)
            const categories = [
              {
                id: 'design',
                name: 'Design',
                description: 'Design tools, prototyping, and creative workflow agents',
                icon: '🎨',
                color: '#F59E0B'
              },
              {
                id: 'code',
                name: 'Development',
                description: 'Code review, development, and engineering workflow agents',
                icon: '💻',
                color: '#6366F1'
              },
              {
                id: 'content',
                name: 'Content Creation',
                description: 'Writing, editing, and content generation assistants',
                icon: '✍️',
                color: '#10B981'
              },
              {
                id: 'analysis',
                name: 'Research & Analysis',
                description: 'Data analysis, research, and information gathering agents',
                icon: '📊',
                color: '#8B5CF6'
              }
            ];

            return {
              statusCode: 200,
              headers,
              body: JSON.stringify({ categories }),
            };

          case 'get':
            const templateId = queryStringParameters?.id;
            if (!templateId) {
              return {
                statusCode: 400,
                headers,
                body: JSON.stringify({ error: 'Template ID required' }),
              };
            }

            const template = await Database.getTemplateById(templateId);
            if (!template) {
              return {
                statusCode: 404,
                headers,
                body: JSON.stringify({ error: 'Template not found' }),
              };
            }

            return {
              statusCode: 200,
              headers,
              body: JSON.stringify({
                template: {
                  id: template.id,
                  name: template.name,
                  description: template.description,
                  category: template.config?.category || 'custom',
                  tags: template.config?.tags || [],
                  createdAt: template.created_at,
                  updatedAt: template.updated_at || template.created_at,
                  isPublic: template.is_public,
                  usageCount: 0,
                  wizardData: template.config?.wizardData
                }
              }),
            };

          default:
            return {
              statusCode: 400,
              headers,
              body: JSON.stringify({ error: 'Invalid action' }),
            };
        }

      case 'POST':
        // Save new template
        if (!body) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Request body required' }),
          };
        }

        const { wizardData, templateInfo, userId, isPublic = false } = JSON.parse(body);
        
        if (!wizardData || !templateInfo) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'wizardData and templateInfo required' }),
          };
        }

        const savedTemplate = await Database.saveTemplate(
          templateInfo.name,
          templateInfo.description,
          {
            wizardData,
            category: templateInfo.category,
            tags: templateInfo.tags
          },
          isPublic,
          userId
        );

        if (userId) {
          await Database.logUserAction(userId, 'template_saved', { templateId: savedTemplate.id });
        }

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            template: {
              id: savedTemplate.id,
              name: savedTemplate.name,
              description: savedTemplate.description,
              category: templateInfo.category,
              tags: templateInfo.tags,
              createdAt: savedTemplate.created_at,
              updatedAt: savedTemplate.updated_at,
              isPublic: savedTemplate.is_public,
              usageCount: 0,
              wizardData
            }
          }),
        };

      case 'PUT':
        // Update template usage count
        const updateBody = JSON.parse(body || '{}');
        const { templateId: updateId, userId: updateUserId } = updateBody;
        
        if (!updateId) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Template ID required' }),
          };
        }

        if (updateUserId) {
          await Database.logUserAction(updateUserId, 'template_used', { templateId: updateId });
        }

        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({ success: true }),
        };

      default:
        return {
          statusCode: 405,
          headers,
          body: JSON.stringify({ error: 'Method not allowed' }),
        };
    }

  } catch (error) {
    // Console output removed for production
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: error instanceof Error ? error.message : 'Unknown error',
        message: 'Templates API request failed',
      }),
    };
  }
};