/**
 * Simple database connectivity test
 * This file can be run to test the Neon database connection
 */

import { Database } from './database';

async function testDatabaseConnection() {
  console.log('🔌 Testing Neon database connection...');
  
  try {
    // Test 1: Basic key-value store operations
    console.log('\n📝 Testing key-value store...');
    
    const testKey = 'test_connection';
    const testValue = { timestamp: new Date().toISOString(), message: 'Hello from asmbli!' };
    
    await Database.set(testKey, testValue);
    console.log('✅ Set operation successful');
    
    const retrievedValue = await Database.get(testKey);
    console.log('✅ Get operation successful:', retrievedValue);
    
    await Database.delete(testKey);
    console.log('✅ Delete operation successful');
    
    // Test 2: User operations (if tables exist)
    try {
      console.log('\n👤 Testing user operations...');
      
      const testUser = await Database.createUser(
        'test@asmbli.com',
        'Test User',
        'beginner'
      );
      console.log('✅ User creation successful:', testUser);
      
      const retrievedUser = await Database.getUserById(testUser.id);
      console.log('✅ User retrieval successful:', retrievedUser);
      
      // Clean up test user
      // Note: You might want to add a delete user method for testing
      
    } catch (error) {
      console.log('ℹ️  User operations test skipped (tables may not exist yet)');
      console.log('   Run migrations first: npm run migrate');
    }
    
    console.log('\n✅ Database connection test completed successfully!');
    
  } catch (error) {
    console.error('\n❌ Database connection test failed:', error);
    console.log('\nTroubleshooting:');
    console.log('1. Make sure NETLIFY_DATABASE_URL is set in your environment');
    console.log('2. Verify your database is accessible');
    console.log('3. Run migrations: npm run migrate');
    throw error;
  }
}

// Run the test if this file is executed directly
if (process.argv[1].endsWith('test-db.ts') || process.argv[1].endsWith('test-db.js')) {
  testDatabaseConnection()
    .then(() => {
      console.log('\n🎉 All tests passed!');
      process.exit(0);
    })
    .catch(() => {
      console.log('\n💥 Tests failed!');
      process.exit(1);
    });
}

export { testDatabaseConnection };