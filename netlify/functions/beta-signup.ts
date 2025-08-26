import { Handler } from '@netlify/functions';
import { Database } from '../../lib/database.js';

// Function to send notification email to admin
async function sendNotificationEmail(signupData: any) {
  const { email, firstName, lastName, useCase } = signupData;
  
  // Using Netlify's built-in form handling or external service
  const emailData = {
    to: 'mikejarce@icloud.com',
    subject: 'New Beta Signup - Asmbli',
    html: `
      <h2>New Beta Signup for Asmbli</h2>
      <p><strong>Name:</strong> ${firstName} ${lastName}</p>
      <p><strong>Email:</strong> ${email}</p>
      <p><strong>Use Case:</strong> ${useCase || 'Not provided'}</p>
      <p><strong>Signup Date:</strong> ${new Date().toLocaleString()}</p>
      <hr>
      <p>You can reach out to this person at: <a href="mailto:${email}">${email}</a></p>
    `,
    text: `
New Beta Signup for Asmbli

Name: ${firstName} ${lastName}
Email: ${email}
Use Case: ${useCase || 'Not provided'}
Signup Date: ${new Date().toLocaleString()}

You can reach out to this person at: ${email}
    `
  };

  // For now, we'll use a simple webhook approach or Netlify Forms
  // You can integrate with services like Resend, SendGrid, or Mailgun later
  if (process.env.EMAIL_WEBHOOK_URL) {
    const response = await fetch(process.env.EMAIL_WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(emailData)
    });
    
    if (!response.ok) {
      throw new Error(`Email webhook failed: ${response.statusText}`);
    }
  }
  
  // Alternative: Store email notifications in database for manual review
  await Database.set(`email_notification:${Date.now()}`, emailData);
}

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

    const { email, firstName, lastName, useCase } = JSON.parse(body);
    
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
      firstName,
      lastName,
      useCase,
      signupDate: new Date().toISOString(),
      source: 'beta_landing',
      status: 'pending'
    };

    await Database.set(`beta_signup:${email}`, signupData);

    // Send email notification to admin
    try {
      await sendNotificationEmail(signupData);
    } catch (error) {
      // Don't fail the request if email fails, just log it
      console.log('Email notification failed:', error);
    }

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