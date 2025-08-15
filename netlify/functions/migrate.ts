import { Handler } from '@netlify/functions';
import { runMigrations, getMigrationStatus } from '../../lib/migrations/runner.js';

export const handler: Handler = async (event, context) => {
  const { httpMethod, queryStringParameters } = event;

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
    // Check if DATABASE_URL is available
    if (!process.env.DATABASE_URL && !process.env.NETLIFY_DATABASE_URL) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          error: 'Database not configured',
          message: 'DATABASE_URL or NETLIFY_DATABASE_URL environment variable is not set. Please configure database connection.',
          docs: 'https://github.com/WereNext/AgentEngine/blob/main/DEPLOYMENT_GUIDE.md'
        }),
      };
    }

    const action = queryStringParameters?.action || 'run';

    switch (action) {
      case 'status':
        const status = await getMigrationStatus();
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            status,
            message: `${status.pending} pending migrations, ${status.executed} completed`
          }),
        };

      case 'run':
      default:
        await runMigrations();
        const newStatus = await getMigrationStatus();
        
        return {
          statusCode: 200,
          headers,
          body: JSON.stringify({
            success: true,
            message: 'Migrations completed successfully',
            status: newStatus
          }),
        };
    }

  } catch (error) {
    console.error('Migration error:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        message: 'Migration failed. Check the logs for more details.',
        troubleshooting: {
          checkDatabase: 'Verify NETLIFY_DATABASE_URL is set',
          checkPermissions: 'Ensure database user has CREATE/ALTER permissions',
          checkConnectivity: 'Verify database is accessible from Netlify'
        }
      }),
    };
  }
};