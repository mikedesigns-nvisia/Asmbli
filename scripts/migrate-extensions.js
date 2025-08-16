#!/usr/bin/env node

/**
 * Extensions Database Migration Script
 * Run this to migrate extensions from static files to Neon database
 */

const { execSync } = require('child_process');
const path = require('path');

console.log('🚀 Starting Extensions Database Migration...\n');

try {
  console.log('📊 Running all pending migrations (includes extensions schema and data)...');
  console.log('This will run:');
  console.log('- 003_comprehensive_extensions_schema.sql');
  console.log('- 004_populate_extensions_data.sql');
  console.log('- 005_populate_design_api_extensions.sql');
  console.log('');
  
  execSync('npm run migrate', {
    stdio: 'inherit',
    cwd: process.cwd()
  });
  console.log('✅ All extensions migrations completed\n');

  console.log('🎉 Extensions migration completed successfully!');
  console.log('\n📋 Summary:');
  console.log('- Extensions table created with comprehensive schema');
  console.log('- User extension preferences table created');
  console.log('- Extension usage analytics table created');
  console.log('- Extension reviews and ratings table created');
  console.log('- 20+ extensions populated from static library');
  console.log('- All database triggers and indexes created');
  console.log('\n🔄 Next steps:');
  console.log('1. Test the extension components');
  console.log('2. Verify data loading from database');
  console.log('3. Check extension analytics collection');
  console.log('4. Remove static extensions-library.ts when ready');

} catch (error) {
  console.error('❌ Migration failed:', error.message);
  console.error('\n🔧 Troubleshooting:');
  console.error('1. Check database connection (NETLIFY_DATABASE_URL)');
  console.error('2. Verify migration runner works: npm run migrate:status');
  console.error('3. Check for existing table conflicts');
  process.exit(1);
}