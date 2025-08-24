import { Handler } from '@netlify/functions';
import { Database } from '../../lib/database.js';

export const handler: Handler = async (event, context) => {
  const { httpMethod, body } = event;

  // Set CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
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

  if (httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
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

    if (!body) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Request body required' }),
      };
    }

    const { email } = JSON.parse(body);
    
    if (!email || !email.includes('@')) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Valid email address required' }),
      };
    }

    // Store beta signup in kv_store
    const signupData = {
      email,
      signupDate: new Date().toISOString(),
      source: 'beta_landing',
      status: 'pending'
    };

    await Database.set(`beta_signup:${email}`, signupData);

    // Also log this as a user action for analytics
    try {
      await Database.logUserAction(null, 'beta_signup', { email });
    } catch (error) {
      // Console output removed for production
      // Don't fail the request if logging fails
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        success: true,
        message: 'Beta signup successful',
        email
      }),
    };

  } catch (error) {
    // Console output removed for production
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: error instanceof Error ? error.message : 'Unknown error',
        message: 'Beta signup failed',
      }),
    };
  }
};