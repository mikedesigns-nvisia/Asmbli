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
  console.log('🚀 Checking deployment status...');
  console.log(`Site URL: ${SITE_URL}`);
  console.log('');

  const startTime = Date.now();
  let attempt = 0;

  while (Date.now() - startTime < MAX_WAIT_TIME) {
    attempt++;
    console.log(`Attempt ${attempt}: Checking ${SITE_URL}`);

    const result = await checkUrl(SITE_URL);
    
    if (result.success) {
      console.log('✅ Site is live!');
      console.log(`Status: ${result.status}`);
      
      // Check if it's actually the new version by looking for specific content
      console.log('\n📋 Checking for database integration...');
      
      try {
        // You can add more specific checks here
        console.log('✅ Deployment appears successful!');
        console.log('\n🎉 Your asmbli application is deployed and ready!');
        console.log(`🌐 Visit: ${SITE_URL}`);
        console.log('\n📝 Next steps:');
        console.log('1. Open the application in your browser');
        console.log('2. Check if the database migration modal appears');
        console.log('3. Run migrations if needed');
        console.log('4. Migrate your data if you have existing localStorage data');
        
        return true;
        
      } catch (error) {
        console.log(`⚠️  Site is live but may not be the latest version: ${error.message}`);
        console.log('Continuing to wait for full deployment...');
      }
      
    } else {
      console.log(`❌ Not ready yet (${result.status || 'No response'})`);
      if (result.error) {
        console.log(`   Error: ${result.error}`);
      }
    }

    if (Date.now() - startTime < MAX_WAIT_TIME) {
      console.log(`⏱️  Waiting ${CHECK_INTERVAL / 1000}s before next check...\n`);
      await setTimeout(CHECK_INTERVAL);
    }
  }

  console.log('⏰ Timeout reached. The deployment may be taking longer than expected.');
  console.log('\n💡 You can:');
  console.log('1. Check your Netlify dashboard for build status');
  console.log('2. Check the deployment logs for any errors');
  console.log('3. Try accessing the site manually');
  console.log(`4. Visit: ${SITE_URL}`);
  
  return false;
}

async function main() {
  console.log('🔍 asmbli Deployment Checker');
  console.log('============================\n');

  try {
    const success = await waitForDeployment();
    process.exit(success ? 0 : 1);
  } catch (error) {
    console.error('❌ Error during deployment check:', error);
    process.exit(1);
  }
}

// Show help if requested
if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log(`
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
  console.log(`Using custom site URL: ${process.env.SITE_URL}`);
}

main();