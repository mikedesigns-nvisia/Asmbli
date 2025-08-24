/**
 * Simple database connectivity test
 * This file can be run to test the Neon database connection
 */

import { Database } from './database';

async function testDatabaseConnection() {
  // Console output removed for production
  
  try {
    // Test 1: Basic key-value store operations
    // Console output removed for production
    
    const testKey = 'test_connection';
    const testValue = { timestamp: new Date().toISOString(), message: 'Hello from asmbli!' };
    
    await Database.set(testKey, testValue);
    // Console output removed for production
    
    const retrievedValue = await Database.get(testKey);
    // Console output removed for production
    
    await Database.delete(testKey);
    // Console output removed for production
    
    // Test 2: User operations (if tables exist)
    try {
      // Console output removed for production
      
      const testUser = await Database.createUser(
        'test@asmbli.com',
        'Test User',
        'beginner'
      );
      // Console output removed for production
      
      const retrievedUser = await Database.getUserById(testUser.id);
      // Console output removed for production
      
      // Clean up test user
      // Note: You might want to add a delete user method for testing
      
    } catch (error) {
      // Console output removed for production
      // Console output removed for production
    }
    
    // Console output removed for production
    
  } catch (error) {
    // Console output removed for production
    // Console output removed for production
    // Console output removed for production
    // Console output removed for production
    // Console output removed for production
    throw error;
  }
}

// Run the test if this file is executed directly
if (process.argv[1].endsWith('test-db.ts') || process.argv[1].endsWith('test-db.js')) {
  testDatabaseConnection()
    .then(() => {
      // Console output removed for production
      process.exit(0);
    })
    .catch(() => {
      // Console output removed for production
      process.exit(1);
    });
}

export { testDatabaseConnection };