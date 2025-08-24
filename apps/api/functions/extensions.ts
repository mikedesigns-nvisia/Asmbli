import { Handler } from '@netlify/functions';
import { Database } from '../../lib/database';

// CORS headers for browser requests
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
};

export const handler: Handler = async (event, context) => {
  // Handle CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: ''
    };
  }

  try {
    const { httpMethod, path, queryStringParameters, body } = event;
    const userRole = queryStringParameters?.role as string;
    const category = queryStringParameters?.category as string;
    const extensionId = queryStringParameters?.id as string;
    const limit = queryStringParameters?.limit ? parseInt(queryStringParameters.limit) : undefined;

    // Console output removed for production

    switch (httpMethod) {
      case 'GET':
        if (path?.includes('/featured')) {
          // Get featured extensions
          const extensions = await Database.getFeaturedExtensions(limit);
          return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify({ extensions })
          };
        } else if (path?.includes('/category')) {
          // Get extensions by category
          if (!category) {
            return {
              statusCode: 400,
              headers: corsHeaders,
              body: JSON.stringify({ error: 'Category parameter required' })
            };
          }
          const extensions = await Database.getExtensionsByCategory(category, userRole);
          return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify({ extensions })
          };
        } else if (extensionId) {
          // Get specific extension
          const extension = await Database.getExtensionById(extensionId);
          if (!extension) {
            return {
              statusCode: 404,
              headers: corsHeaders,
              body: JSON.stringify({ error: 'Extension not found' })
            };
          }
          return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify({ extension })
          };
        } else {
          // Get all extensions
          const extensions = await Database.getAllExtensions(userRole);
          return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify({ extensions })
          };
        }

      case 'POST':
        // Save user extension preference
        const requestBody = JSON.parse(body || '{}');
        const { userId, extensionId: reqExtensionId, config } = requestBody;
        
        if (!userId || !reqExtensionId || !config) {
          return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'userId, extensionId, and config are required' })
          };
        }

        const result = await Database.saveUserExtension(userId, reqExtensionId, config);
        return {
          statusCode: 200,
          headers: corsHeaders,
          body: JSON.stringify({ result })
        };

      case 'DELETE':
        // Remove user extension
        const deleteBody = JSON.parse(body || '{}');
        const { userId: delUserId, extensionId: delExtensionId } = deleteBody;
        
        if (!delUserId || !delExtensionId) {
          return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'userId and extensionId are required' })
          };
        }

        await Database.removeUserExtension(delUserId, delExtensionId);
        return {
          statusCode: 200,
          headers: corsHeaders,
          body: JSON.stringify({ success: true })
        };

      default:
        return {
          statusCode: 405,
          headers: corsHeaders,
          body: JSON.stringify({ error: 'Method not allowed' })
        };
    }
  } catch (error) {
    // Console output removed for production
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({ 
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};