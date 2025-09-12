import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// Import the services we need to test
import 'package:agentengine_desktop/core/config/environment_config.dart';

/// Simple App Startup Test
/// 
/// This test validates basic configuration loading without singleton conflicts.
void main() {
  group('🚀 Simple App Startup Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      print('🧪 Starting Simple App Startup Tests');
    });

    tearDownAll(() {
      print('✅ Simple App Startup Tests Complete');
    });

    test('EnvironmentConfig can load without errors', () async {
      // Test that EnvironmentConfig can initialize without errors
      final env = EnvironmentConfig.instance;
      
      // This should not throw an exception
      await env.initialize();
      
      // After initialization, environment should be accessible
      expect(env.environment, isNotNull);
      expect(env.environment.name, isNotEmpty);
      expect(env.environment.name, isIn(['development', 'staging', 'production']));
      
      // Test that feature flags are accessible without type errors
      final featureFlags = env.featureFlags;
      expect(featureFlags, isA<Map<String, bool>>());
      expect(featureFlags.keys, isNotEmpty);
      
      // Test that configuration methods don't throw
      expect(() => env.databaseConfig, returnsNormally);
      expect(() => env.apiConfig, returnsNormally);
      expect(() => env.loggingConfig, returnsNormally);
      
      print('✅ EnvironmentConfig validated successfully');
      print('   Environment: ${env.environment.name}');
      print('   Feature flags: ${featureFlags.keys.length} loaded');
    });

    test('Configuration values have correct types', () async {
      final env = EnvironmentConfig.instance;
      await env.initialize();
      
      // Test database config
      final dbConfig = env.databaseConfig;
      expect(dbConfig['name'], isA<String>());
      expect(dbConfig['backup_enabled'], isA<bool>());
      expect(dbConfig['backup_interval_hours'], isA<int>());
      
      // Test API config
      final apiConfig = env.apiConfig;
      expect(apiConfig['base_url'], isA<String>());
      expect(apiConfig['timeout_seconds'], isA<int>());
      expect(apiConfig['retry_attempts'], isA<int>());
      
      // Test logging config
      final logConfig = env.loggingConfig;
      expect(logConfig['level'], isA<String>());
      expect(logConfig['file_enabled'], isA<bool>());
      expect(logConfig['console_enabled'], isA<bool>());
      
      print('✅ All configuration types validated');
    });
  });
}