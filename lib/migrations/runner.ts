import { sql } from '../database';
import fs from 'fs';
import path from 'path';

export class MigrationRunner {
  private static migrationPath = path.join(process.cwd(), 'lib', 'migrations');

  /**
   * Create the migrations tracking table if it doesn't exist
   */
  private static async ensureMigrationsTable() {
    await sql`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      )
    `;
  }

  /**
   * Get all executed migrations
   */
  private static async getExecutedMigrations(): Promise<string[]> {
    const result = await sql`
      SELECT name FROM migrations ORDER BY id ASC
    `;
    return result.map(row => row.name);
  }

  /**
   * Get all migration files from the filesystem
   */
  private static getMigrationFiles(): string[] {
    try {
      const files = fs.readdirSync(this.migrationPath)
        .filter(file => file.endsWith('.sql'))
        .sort();
      return files;
    } catch (error) {
      // Console output removed for production
      return [];
    }
  }

  /**
   * Execute a single migration file
   */
  private static async executeMigration(filename: string) {
    const filePath = path.join(this.migrationPath, filename);
    const migrationSQL = fs.readFileSync(filePath, 'utf-8');
    
    // Split by semicolons and execute each statement
    const statements = migrationSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0);

    for (const statement of statements) {
      try {
        await sql.unsafe(statement);
      } catch (error) {
        // Console output removed for production
        // Console output removed for production
        throw error;
      }
    }

    // Record the migration as executed
    await sql`
      INSERT INTO migrations (name) VALUES (${filename})
    `;

    // Console output removed for production
  }

  /**
   * Run all pending migrations
   */
  static async runMigrations() {
    try {
      // Console output removed for production
      
      // Ensure migrations table exists
      await this.ensureMigrationsTable();

      // Get executed migrations
      const executedMigrations = await this.getExecutedMigrations();
      
      // Get all migration files
      const migrationFiles = this.getMigrationFiles();

      if (migrationFiles.length === 0) {
        // Console output removed for production
        return;
      }

      // Find pending migrations
      const pendingMigrations = migrationFiles.filter(
        file => !executedMigrations.includes(file)
      );

      if (pendingMigrations.length === 0) {
        // Console output removed for production
        return;
      }

      // Console output removed for production

      // Execute pending migrations
      for (const migration of pendingMigrations) {
        await this.executeMigration(migration);
      }

      // Console output removed for production
    } catch (error) {
      // Console output removed for production
      throw error;
    }
  }

  /**
   * Get migration status
   */
  static async getStatus() {
    await this.ensureMigrationsTable();
    
    const executedMigrations = await this.getExecutedMigrations();
    const migrationFiles = this.getMigrationFiles();
    const pendingMigrations = migrationFiles.filter(
      file => !executedMigrations.includes(file)
    );

    return {
      total: migrationFiles.length,
      executed: executedMigrations.length,
      pending: pendingMigrations.length,
      executedMigrations,
      pendingMigrations
    };
  }

  /**
   * Create a new migration file
   */
  static createMigration(name: string): string {
    const timestamp = new Date().toISOString().replace(/[-:]/g, '').replace(/\..+/, '');
    const filename = `${timestamp}_${name}.sql`;
    const filepath = path.join(this.migrationPath, filename);

    const template = `-- ${name}
-- Created at: ${new Date().toISOString()}

-- Add your SQL statements here
`;

    try {
      fs.writeFileSync(filepath, template);
      // Console output removed for production
      return filename;
    } catch (error) {
      // Console output removed for production
      throw error;
    }
  }
}

// Export a simple function for running migrations
export async function runMigrations() {
  return MigrationRunner.runMigrations();
}

export async function getMigrationStatus() {
  return MigrationRunner.getStatus();
}

export function createMigration(name: string) {
  return MigrationRunner.createMigration(name);
}