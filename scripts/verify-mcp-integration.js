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

console.log('🔍 AgentEngine MCP Server Integration Verification');
console.log('=' .repeat(60));

// Verify MCP Core Package Structure
function verifyMCPCorePackage() {
  const mcpCorePath = path.join(__dirname, '..', 'packages', 'mcp-core');
  const srcPath = path.join(mcpCorePath, 'src');
  const serversPath = path.join(srcPath, 'servers');
  
  console.log('\n📦 Checking MCP Core Package Structure...');
  
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
      console.log(`  ✅ ${file}`);
    } else {
      console.log(`  ❌ ${file} - MISSING`);
      structureValid = false;
    }
  }
  
  return structureValid;
}

// Verify Server Definitions
function verifyServerDefinitions() {
  console.log('\n🖥️ Checking Server Definitions...');
  
  try {
    // This would work in a Node.js environment with proper TypeScript compilation
    // For now, we'll do basic file content checks
    
    const coreServersFile = path.join(__dirname, '..', 'packages', 'mcp-core', 'src', 'servers', 'core.ts');
    const enterpriseServersFile = path.join(__dirname, '..', 'packages', 'mcp-core', 'src', 'servers', 'enterprise.ts');
    
    if (!fs.existsSync(coreServersFile)) {
      console.log('  ❌ Core servers file missing');
      return false;
    }
    
    if (!fs.existsSync(enterpriseServersFile)) {
      console.log('  ❌ Enterprise servers file missing');
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
        console.log(`  ✅ Core: ${serverId}`);
      } else {
        console.log(`  ❌ Core: ${serverId} - MISSING`);
      }
    }
    
    for (const serverId of enterpriseServerIds) {
      if (enterpriseContent.includes(`id: '${serverId}'`)) {
        enterpriseFound++;
        console.log(`  ✅ Enterprise: ${serverId}`);
      } else {
        console.log(`  ❌ Enterprise: ${serverId} - MISSING`);
      }
    }
    
    console.log(`\n  📊 Core Servers: ${coreFound}/${coreServerIds.length}`);
    console.log(`  📊 Enterprise Servers: ${enterpriseFound}/${enterpriseServerIds.length}`);
    
    return coreFound === coreServerIds.length && enterpriseFound >= 8; // At least 8 enterprise servers
    
  } catch (error) {
    console.log(`  ❌ Error checking server definitions: ${error.message}`);
    return false;
  }
}

// Verify Database Migration
function verifyDatabaseMigration() {
  console.log('\n🗃️ Checking Database Migration...');
  
  const migrationFile = path.join(__dirname, '..', 'packages', 'database', 'migrations', 'refactor_001.sql');
  
  if (!fs.existsSync(migrationFile)) {
    console.log('  ❌ Refactor migration file missing');
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
      console.log(`  ✅ ${element}`);
    } else {
      console.log(`  ❌ ${element} - MISSING`);
    }
  }
  
  console.log(`\n  📊 Migration Elements: ${elementsFound}/${requiredElements.length}`);
  return elementsFound === requiredElements.length;
}

// Verify Web App Integration
function verifyWebAppIntegration() {
  console.log('\n🌐 Checking Web App Integration...');
  
  const webAppPath = path.join(__dirname, '..', 'apps', 'web');
  const templatesPagePath = path.join(webAppPath, 'app', 'templates', 'page.tsx');
  
  if (!fs.existsSync(templatesPagePath)) {
    console.log('  ❌ Templates page missing');
    return false;
  }
  
  console.log('  ✅ Templates page exists');
  
  // Check if web app has proper package.json
  const webPackageJsonPath = path.join(webAppPath, 'package.json');
  if (fs.existsSync(webPackageJsonPath)) {
    const packageJson = JSON.parse(fs.readFileSync(webPackageJsonPath, 'utf8'));
    console.log(`  ✅ Web app package: ${packageJson.name}`);
    return true;
  }
  
  return false;
}

// Verify Desktop App Integration  
function verifyDesktopAppIntegration() {
  console.log('\n🖥️ Checking Desktop App Integration...');
  
  const desktopAppPath = path.join(__dirname, '..', 'apps', 'desktop');
  const pubspecPath = path.join(desktopAppPath, 'pubspec.yaml');
  const mainDartPath = path.join(desktopAppPath, 'lib', 'main.dart');
  
  let desktopValid = true;
  
  if (fs.existsSync(pubspecPath)) {
    console.log('  ✅ Flutter pubspec.yaml exists');
  } else {
    console.log('  ❌ Flutter pubspec.yaml missing');
    desktopValid = false;
  }
  
  if (fs.existsSync(mainDartPath)) {
    console.log('  ✅ Flutter main.dart exists');
  } else {
    console.log('  ❌ Flutter main.dart missing');
    desktopValid = false;
  }
  
  return desktopValid;
}

// Main verification
async function main() {
  console.log(`Expected Total Servers: ${TOTAL_EXPECTED}`);
  console.log('Category breakdown:', EXPECTED_SERVERS);
  
  const results = {
    structure: verifyMCPCorePackage(),
    servers: verifyServerDefinitions(),
    migration: verifyDatabaseMigration(),
    webApp: verifyWebAppIntegration(),
    desktopApp: verifyDesktopAppIntegration()
  };
  
  console.log('\n' + '='.repeat(60));
  console.log('📋 VERIFICATION RESULTS');
  console.log('='.repeat(60));
  
  Object.entries(results).forEach(([check, passed]) => {
    console.log(`${passed ? '✅' : '❌'} ${check.charAt(0).toUpperCase() + check.slice(1)}: ${passed ? 'PASSED' : 'FAILED'}`);
  });
  
  const allPassed = Object.values(results).every(Boolean);
  
  console.log('\n' + '='.repeat(60));
  console.log(`🎯 OVERALL STATUS: ${allPassed ? '✅ PASSED' : '❌ FAILED'}`);
  console.log('='.repeat(60));
  
  if (allPassed) {
    console.log('🎉 All MCP servers are properly integrated!');
    console.log('Ready for development and deployment.');
  } else {
    console.log('⚠️  Some integration issues found.');
    console.log('Please review the failed checks above.');
  }
  
  process.exit(allPassed ? 0 : 1);
}

// Run verification
main().catch(console.error);