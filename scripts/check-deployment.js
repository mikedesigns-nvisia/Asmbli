#!/usr/bin/env node

/**
 * Deployment verification script
 * Checks if the application is deployed and ready
 */

import https from 'https';
import { setTimeout } from 'timers/promises';

const SITE_URL = 'https://asmbli.netlify.app'; // Update with your actual Netlify URL
const MAX_WAIT_TIME = 10 * 60 * 1000; // 10 minutes
const CHECK_INTERVAL = 30 * 1000; // 30 seconds

function checkUrl(url) {
  return new Promise((resolve) => {
    const request = https.get(url, (response) => {
      resolve({
        status: response.statusCode,
        success: response.statusCode >= 200 && response.statusCode < 400
      });
    });

    request.on('error', (error) => {
      resolve({
        status: 0,
        success: false,
        error: error.message
      });
    });

    request.setTimeout(10000, () => {
      request.destroy();
      resolve({
        status: 0,
        success: false,
        error: 'Request timeout'
      });
    });
  });
}

async function waitForDeployment() {
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production

  const startTime = Date.now();
  let attempt = 0;

  while (Date.now() - startTime < MAX_WAIT_TIME) {
    attempt++;
    // Console output removed for production

    const result = await checkUrl(SITE_URL);
    
    if (result.success) {
      // Console output removed for production
      // Console output removed for production
      
      // Check if it's actually the new version by looking for specific content
      // Console output removed for production
      
      try {
        // You can add more specific checks here
        // Console output removed for production
        // Console output removed for production
        // Console output removed for production
        // Console output removed for production
        // Console output removed for production
        // Console output removed for production
        // Console output removed for production
        // Console output removed for production
        
        return true;
        
      } catch (error) {
        // Console output removed for production
        // Console output removed for production
      }
      
    } else {
      // Console output removed for production
      if (result.error) {
        // Console output removed for production
      }
    }

    if (Date.now() - startTime < MAX_WAIT_TIME) {
      // Console output removed for production
      await setTimeout(CHECK_INTERVAL);
    }
  }

  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  
  return false;
}

async function main() {
  // Console output removed for production
  // Console output removed for production

  try {
    const success = await waitForDeployment();
    process.exit(success ? 0 : 1);
  } catch (error) {
    // Console output removed for production
    process.exit(1);
  }
}

// Show help if requested
if (process.argv.includes('--help') || process.argv.includes('-h')) {
  // Console output removed for production
asmbli Deployment Checker

Usage: npm run check-deployment

This script will:
1. Check if your site is deployed and accessible
2. Wait for the deployment to complete (up to 10 minutes)
3. Provide next steps for database setup

Environment variables:
- SITE_URL: Override the default site URL to check

Example:
  SITE_URL=https://your-custom-url.netlify.app npm run check-deployment
`);
  process.exit(0);
}

// Allow overriding the site URL via environment variable
if (process.env.SITE_URL) {
  // Update the SITE_URL if provided via environment
  // Console output removed for production
}

main();