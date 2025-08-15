#!/usr/bin/env node

/**
 * Database migration CLI tool
 * Usage:
 *   npm run migrate            - Run all pending migrations
 *   npm run migrate status     - Show migration status
 *   npm run migrate create <name> - Create a new migration file
 */

import { runMigrations, getMigrationStatus, createMigration } from '../lib/migrations/runner.js';

const command = process.argv[2];
const args = process.argv.slice(3);

async function main() {
  try {
    switch (command) {
      case 'status':
        const status = await getMigrationStatus();
        console.log('\nMigration Status:');
        console.log(`Total migrations: ${status.total}`);
        console.log(`Executed: ${status.executed}`);
        console.log(`Pending: ${status.pending}`);
        
        if (status.executedMigrations.length > 0) {
          console.log('\nExecuted migrations:');
          status.executedMigrations.forEach(migration => {
            console.log(`  ✓ ${migration}`);
          });
        }
        
        if (status.pendingMigrations.length > 0) {
          console.log('\nPending migrations:');
          status.pendingMigrations.forEach(migration => {
            console.log(`  • ${migration}`);
          });
        }
        break;

      case 'create':
        if (!args[0]) {
          console.error('Please provide a migration name');
          console.error('Usage: npm run migrate create <migration_name>');
          process.exit(1);
        }
        const filename = createMigration(args[0]);
        console.log(`Created migration: ${filename}`);
        break;

      case 'run':
      case undefined:
        // Default action: run migrations
        await runMigrations();
        break;

      default:
        console.error(`Unknown command: ${command}`);
        console.error('Available commands: run (default), status, create');
        process.exit(1);
    }
  } catch (error) {
    console.error('Migration error:', error);
    process.exit(1);
  }
}

main();