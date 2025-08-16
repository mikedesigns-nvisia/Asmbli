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
    const { httpMethod, queryStringParameters, body } = event;
    const userId = queryStringParameters?.userId as string;

    if (!userId) {
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({ error: 'userId parameter required' })
      };
    }

    console.log('User Extensions API called:', { httpMethod, userId });

    switch (httpMethod) {
      case 'GET':
        // Get user's extensions
        const userExtensions = await Database.getUserExtensions(userId);
        return {
          statusCode: 200,
          headers: corsHeaders,
          body: JSON.stringify({ userExtensions })
        };

      case 'POST':
        // Log extension usage
        const requestBody = JSON.parse(body || '{}');
        const { extensionId, action, metadata, sessionId } = requestBody;
        
        if (!extensionId || !action) {
          return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'extensionId and action are required' })
          };
        }

        await Database.logExtensionUsage(userId, extensionId, action, metadata, sessionId);
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
    console.error('User Extensions API error:', error);
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