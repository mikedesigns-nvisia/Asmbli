import { connect } from '@netlify/neon'
import { readFileSync } from 'fs'
import { join } from 'path'

export class MigrationRunner {
  constructor(private databaseUrl: string) {}

  async runMigration(migrationName: string): Promise<void> {
    const conn = await connect(this.databaseUrl)
    
    // Create migrations table if it doesn't exist
    await conn.query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMP DEFAULT NOW()
      )
    `)
    
    // Check if migration has already been run
    const existingMigration = await conn.query(
      'SELECT name FROM migrations WHERE name = $1',
      [migrationName]
    )
    
    if (existingMigration.rows.length > 0) {
      console.log(`Migration ${migrationName} already executed`)
      return
    }
    
    // Read migration file
    const migrationPath = join(__dirname, '../migrations', `${migrationName}.sql`)
    let migrationSql: string
    
    try {
      migrationSql = readFileSync(migrationPath, 'utf-8')
    } catch (error) {
      throw new Error(`Migration file not found: ${migrationPath}`)
    }
    
    console.log(`Running migration: ${migrationName}`)
    
    try {
      // Execute migration in a transaction
      await conn.query('BEGIN')
      
      // Split by semicolon and execute each statement
      const statements = migrationSql
        .split(';')
        .map(stmt => stmt.trim())
        .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'))
      
      for (const statement of statements) {
        if (statement.trim()) {
          await conn.query(statement)
        }
      }
      
      // Record migration as completed
      await conn.query(
        'INSERT INTO migrations (name) VALUES ($1)',
        [migrationName]
      )
      
      await conn.query('COMMIT')
      console.log(`Migration ${migrationName} completed successfully`)
      
    } catch (error) {
      await conn.query('ROLLBACK')
      console.error(`Migration ${migrationName} failed:`, error)
      throw error
    }
  }
  
  async runAllMigrations(): Promise<void> {
    // List of migrations in order
    const migrations = [
      'refactor_001'
    ]
    
    for (const migration of migrations) {
      await this.runMigration(migration)
    }
  }
  
  async getAppliedMigrations(): Promise<string[]> {
    const conn = await connect(this.databaseUrl)
    
    try {
      const result = await conn.query(
        'SELECT name FROM migrations ORDER BY executed_at'
      )
      return result.rows.map(row => row.name)
    } catch (error) {
      // Migrations table doesn't exist yet
      return []
    }
  }
  
  async rollbackMigration(migrationName: string): Promise<void> {
    console.warn('Rollback functionality not implemented yet')
    console.warn(`To rollback ${migrationName}, please manually reverse the changes`)
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2)
  const command = args[0]
  const migrationName = args[1]
  
  const databaseUrl = process.env.DATABASE_URL || process.env.NETLIFY_DATABASE_URL
  if (!databaseUrl) {
    console.error('DATABASE_URL environment variable not set')
    process.exit(1)
  }
  
  const runner = new MigrationRunner(databaseUrl)
  
  async function runCLI() {
    try {
      switch (command) {
        case 'run':
          if (migrationName) {
            await runner.runMigration(migrationName)
          } else {
            await runner.runAllMigrations()
          }
          break
          
        case 'status':
          const applied = await runner.getAppliedMigrations()
          console.log('Applied migrations:')
          applied.forEach(name => console.log(`  ✓ ${name}`))
          break
          
        case 'rollback':
          if (!migrationName) {
            console.error('Migration name required for rollback')
            process.exit(1)
          }
          await runner.rollbackMigration(migrationName)
          break
          
        default:
          console.log('Usage: node migrate.js <command> [migration-name]')
          console.log('Commands:')
          console.log('  run [migration-name]  - Run all migrations or specific migration')
          console.log('  status               - Show applied migrations')
          console.log('  rollback <migration-name> - Rollback specific migration')
          break
      }
    } catch (error) {
      console.error('Migration failed:', error)
      process.exit(1)
    }
  }
  
  runCLI()
}