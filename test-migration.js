// Test script to manually run the enhanced template schema migration
import { neon } from '@netlify/neon';

// Read the migration file
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const migrationPath = path.join(__dirname, 'lib', 'migrations', '002_enhanced_template_schema.sql');
const migrationSQL = fs.readFileSync(migrationPath, 'utf-8');

async function runMigration() {
  const sql = neon(process.env.NETLIFY_DATABASE_URL || 'postgresql://neondb_owner:o4cPQqjGpGKN@ep-wandering-dew-a2g4onzb-pooler.eu-central-1.aws.neon.tech/neondb?sslmode=require');
  
  console.log('Running enhanced template schema migration...');
  
  try {
    // Split by semicolons and execute each statement
    const statements = migrationSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0);

    console.log(`Executing ${statements.length} statements...`);

    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      console.log(`Executing statement ${i + 1}...`);
      try {
        await sql(statement);
        console.log(`✓ Statement ${i + 1} executed successfully`);
      } catch (error) {
        console.error(`Error executing statement ${i + 1}:`, error);
        console.error('Statement:', statement);
        throw error;
      }
    }

    console.log('✓ Migration completed successfully!');
    
    // Test the new tables
    console.log('\nTesting new tables...');
    const categories = await sql`SELECT * FROM template_categories LIMIT 5`;
    console.log(`✓ Found ${categories.length} template categories`);
    
    const extensions = await sql`SELECT * FROM extensions LIMIT 5`;  
    console.log(`✓ Found ${extensions.length} extensions`);
    
    console.log('\n✅ Database schema enhanced successfully!');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

runMigration();