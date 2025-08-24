#!/usr/bin/env node

/**
 * Verification script to ensure all MCP servers from the original project
 * are properly integrated in the refactored monorepo structure
 */

const fs = require('fs');
const path = require('path');

// Expected server counts by category
const EXPECTED_SERVERS = {
  core: 11,           // From lib/migrations/004_populate_extensions_data.sql
  design: 5,          // Figma, Sketch, Zeplin, Storybook, Design Tokens
  microsoft: 8,       // Microsoft 365 suite
  communication: 4,   // Slack, Discord, Telegram, Gmail
  ai: 2,             // OpenAI, Anthropic
  browser: 4,        // Brave, Chrome, Firefox, Safari
  cloud: 6,          // Google Drive, Dropbox, Supabase, Zapier, Make, IFTTT  
  productivity: 4,   // Notion, Linear, Google Analytics, Mixpanel
  enterprise: 4,     // AWS, GCP, Azure, Vercel
  security: 1        // HashiCorp Vault
};

const TOTAL_EXPECTED = Object.values(EXPECTED_SERVERS).reduce((sum, count) => sum + count, 0);

// Console output removed for production
// Console output removed for production

// Verify MCP Core Package Structure
function verifyMCPCorePackage() {
  const mcpCorePath = path.join(__dirname, '..', 'packages', 'mcp-core');
  const srcPath = path.join(mcpCorePath, 'src');
  const serversPath = path.join(srcPath, 'servers');
  
  // Console output removed for production
  
  const requiredFiles = [
    'src/index.ts',
    'src/servers/core.ts', 
    'src/servers/enterprise.ts',
    'package.json',
    'tsconfig.json'
  ];
  
  let structureValid = true;
  
  for (const file of requiredFiles) {
    const filePath = path.join(mcpCorePath, file);
    if (fs.existsSync(filePath)) {
      // Console output removed for production
    } else {
      // Console output removed for production
      structureValid = false;
    }
  }
  
  return structureValid;
}

// Verify Server Definitions
function verifyServerDefinitions() {
  // Console output removed for production
  
  try {
    // This would work in a Node.js environment with proper TypeScript compilation
    // For now, we'll do basic file content checks
    
    const coreServersFile = path.join(__dirname, '..', 'packages', 'mcp-core', 'src', 'servers', 'core.ts');
    const enterpriseServersFile = path.join(__dirname, '..', 'packages', 'mcp-core', 'src', 'servers', 'enterprise.ts');
    
    if (!fs.existsSync(coreServersFile)) {
      // Console output removed for production
      return false;
    }
    
    if (!fs.existsSync(enterpriseServersFile)) {
      // Console output removed for production
      return false;
    }
    
    const coreContent = fs.readFileSync(coreServersFile, 'utf8');
    const enterpriseContent = fs.readFileSync(enterpriseServersFile, 'utf8');
    
    // Check for key server IDs
    const coreServerIds = [
      'filesystem-mcp', 'git-mcp', 'github', 'postgres-mcp', 'memory-mcp',
      'search-mcp', 'http-mcp', 'calendar-mcp', 'sequential-thinking-mcp',
      'time-mcp', 'terminal-mcp'
    ];
    
    const enterpriseServerIds = [
      'figma-mcp', 'microsoft-graph', 'slack', 'openai-api', 'anthropic-api',
      'brave-browser', 'google-drive', 'notion-api', 'aws-mcp', 'hashicorp-vault'
    ];
    
    let coreFound = 0;
    let enterpriseFound = 0;
    
    for (const serverId of coreServerIds) {
      if (coreContent.includes(`id: '${serverId}'`)) {
        coreFound++;
        // Console output removed for production
      } else {
        // Console output removed for production
      }
    }
    
    for (const serverId of enterpriseServerIds) {
      if (enterpriseContent.includes(`id: '${serverId}'`)) {
        enterpriseFound++;
        // Console output removed for production
      } else {
        // Console output removed for production
      }
    }
    
    // Console output removed for production
    // Console output removed for production
    
    return coreFound === coreServerIds.length && enterpriseFound >= 8; // At least 8 enterprise servers
    
  } catch (error) {
    // Console output removed for production
    return false;
  }
}

// Verify Database Migration
function verifyDatabaseMigration() {
  // Console output removed for production
  
  const migrationFile = path.join(__dirname, '..', 'packages', 'database', 'migrations', 'refactor_001.sql');
  
  if (!fs.existsSync(migrationFile)) {
    // Console output removed for production
    return false;
  }
  
  const migrationContent = fs.readFileSync(migrationFile, 'utf8');
  
  // Check for key migration elements
  const requiredElements = [
    'ALTER TABLE templates',
    'CREATE TABLE IF NOT EXISTS chat_sessions',
    'CREATE TABLE IF NOT EXISTS api_keys',
    'CREATE TABLE IF NOT EXISTS template_ratings',
    'CREATE INDEX'
  ];
  
  let elementsFound = 0;
  
  for (const element of requiredElements) {
    if (migrationContent.includes(element)) {
      elementsFound++;
      // Console output removed for production
    } else {
      // Console output removed for production
    }
  }
  
  // Console output removed for production
  return elementsFound === requiredElements.length;
}

// Verify Web App Integration
function verifyWebAppIntegration() {
  // Console output removed for production
  
  const webAppPath = path.join(__dirname, '..', 'apps', 'web');
  const templatesPagePath = path.join(webAppPath, 'app', 'templates', 'page.tsx');
  
  if (!fs.existsSync(templatesPagePath)) {
    // Console output removed for production
    return false;
  }
  
  // Console output removed for production
  
  // Check if web app has proper package.json
  const webPackageJsonPath = path.join(webAppPath, 'package.json');
  if (fs.existsSync(webPackageJsonPath)) {
    const packageJson = JSON.parse(fs.readFileSync(webPackageJsonPath, 'utf8'));
    // Console output removed for production
    return true;
  }
  
  return false;
}

// Verify Desktop App Integration  
function verifyDesktopAppIntegration() {
  // Console output removed for production
  
  const desktopAppPath = path.join(__dirname, '..', 'apps', 'desktop');
  const pubspecPath = path.join(desktopAppPath, 'pubspec.yaml');
  const mainDartPath = path.join(desktopAppPath, 'lib', 'main.dart');
  
  let desktopValid = true;
  
  if (fs.existsSync(pubspecPath)) {
    // Console output removed for production
  } else {
    // Console output removed for production
    desktopValid = false;
  }
  
  if (fs.existsSync(mainDartPath)) {
    // Console output removed for production
  } else {
    // Console output removed for production
    desktopValid = false;
  }
  
  return desktopValid;
}

// Main verification
async function main() {
  // Console output removed for production
  // Console output removed for production
  
  const results = {
    structure: verifyMCPCorePackage(),
    servers: verifyServerDefinitions(),
    migration: verifyDatabaseMigration(),
    webApp: verifyWebAppIntegration(),
    desktopApp: verifyDesktopAppIntegration()
  };
  
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  
  Object.entries(results).forEach(([check, passed]) => {
    // Console output removed for production
  });
  
  const allPassed = Object.values(results).every(Boolean);
  
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  
  if (allPassed) {
    // Console output removed for production
    // Console output removed for production
  } else {
    // Console output removed for production
    // Console output removed for production
  }
  
  process.exit(allPassed ? 0 : 1);
}

// Run verification
main().catch(console.error);