import { Handler } from '@netlify/functions';
import { testDatabaseConnection } from '../../lib/test-db.js';

export const handler: Handler = async (event, context) => {
  // Set CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Content-Type': 'application/json',
  };

  // Handle preflight requests
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: '',
    };
  }

  if (event.httpMethod !== 'GET') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }

  try {
    // Check if database URL is configured
    if (!process.env.DATABASE_URL && !process.env.NETLIFY_DATABASE_URL) {
      return {
        statusCode: 503,
        headers,
        body: JSON.stringify({
          success: false,
          error: 'Database not configured',
          message: 'DATABASE_URL or NETLIFY_DATABASE_URL environment variable is missing',
          setup: 'Configure database connection in Netlify environment variables',
          docs: 'https://github.com/WereNext/AgentEngine/blob/main/DEPLOYMENT_GUIDE.md'
        }),
      };
    }

    // Run database connectivity test
    await testDatabaseConnection();
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        success: true,
        message: 'Database connection successful',
        timestamp: new Date().toISOString(),
        database: {
          connected: true,
          url: process.env.NETLIFY_DATABASE_URL ? 'configured' : 'missing'
        }
      }),
    };

  } catch (error) {
    // Console output removed for production
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        message: 'Database connection failed',
        timestamp: new Date().toISOString(),
        troubleshooting: {
          checkUrl: 'Verify NETLIFY_DATABASE_URL is correct',
          checkNetwork: 'Ensure database is accessible',
          checkPermissions: 'Verify database user permissions',
          runMigrations: 'Try running migrations first'
        }
      }),
    };
  }
};