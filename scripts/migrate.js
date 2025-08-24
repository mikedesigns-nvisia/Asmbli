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
        // Console output removed for production
        // Console output removed for production
        // Console output removed for production
        // Console output removed for production
        
        if (status.executedMigrations.length > 0) {
          // Console output removed for production
          status.executedMigrations.forEach(migration => {
            // Console output removed for production
          });
        }
        
        if (status.pendingMigrations.length > 0) {
          // Console output removed for production
          status.pendingMigrations.forEach(migration => {
            // Console output removed for production
          });
        }
        break;

      case 'create':
        if (!args[0]) {
          // Console output removed for production
          // Console output removed for production
          process.exit(1);
        }
        const filename = createMigration(args[0]);
        // Console output removed for production
        break;

      case 'run':
      case undefined:
        // Default action: run migrations
        await runMigrations();
        break;

      default:
        // Console output removed for production
        // Console output removed for production
        process.exit(1);
    }
  } catch (error) {
    // Console output removed for production
    process.exit(1);
  }
}

main();