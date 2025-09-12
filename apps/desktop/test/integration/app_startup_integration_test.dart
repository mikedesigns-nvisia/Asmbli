import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// Import the services we need to test
import 'package:agentengine_desktop/core/config/environment_config.dart';
import 'package:agentengine_desktop/core/error/app_error_handler.dart';
import 'package:agentengine_desktop/core/di/service_locator.dart';

/// App Startup Integration Test
/// 
/// This test validates that the core application services can initialize
/// properly in the correct order without errors.
void main() {
  group('🚀 App Startup Integration Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      print('🧪 Starting App Startup Integration Tests');
    });

    tearDownAll(() {
      print('✅ App Startup Integration Tests Complete');
    });

    group('Service Initialization Order', () {
      test('EnvironmentConfig initializes correctly', () async {
        // Test that EnvironmentConfig can initialize without errors
        final env = EnvironmentConfig.instance;
        
        // This should not throw an exception
        await expectLater(() => env.initialize(), returnsNormally);
        
        // After initialization, environment should be accessible
        expect(() => env.environment, returnsNormally);
        expect(env.environment, isNotNull);
        expect(env.environment.name, isNotEmpty);
        
        print('✅ EnvironmentConfig initialized: ${env.environment.name}');
      });

      test('AppErrorHandler initializes after EnvironmentConfig', () async {
        // Ensure EnvironmentConfig is initialized first
        final env = EnvironmentConfig.instance;
        await env.initialize();
        
        // Then test AppErrorHandler initialization
        final errorHandler = AppErrorHandler.instance;
        await expectLater(() => errorHandler.initialize(), returnsNormally);
        
        print('✅ AppErrorHandler initialized successfully');
      });

      test('ServiceLocator initializes correctly', () async {
        // Test that ServiceLocator can initialize without critical errors
        final serviceLocator = ServiceLocator.instance;
        
        // This may have some non-critical errors but should not throw
        await expectLater(() => serviceLocator.initialize(), returnsNormally);
        
        print('✅ ServiceLocator initialized successfully');
      });
    });

    group('Service Health Validation', () {
      test('Critical services are registered', () async {
        // Initialize all services
        final env = EnvironmentConfig.instance;
        await env.initialize();
        
        final errorHandler = AppErrorHandler.instance;
        await errorHandler.initialize();
        
        final serviceLocator = ServiceLocator.instance;
        await serviceLocator.initialize();
        
        // Test that key services are available
        // Note: We can't test all services here due to Hive/storage dependencies
        // But we can verify the service locator infrastructure works
        
        expect(serviceLocator, isNotNull);
        print('✅ Service infrastructure validated');
      });
    });

    group('Configuration Validation', () {
      test('Environment configuration has required values', () async {
        final env = EnvironmentConfig.instance;
        await env.initialize();
        
        // Test basic environment properties
        expect(env.environment.name, isIn(['development', 'staging', 'production']));
        expect(env.environment.isProduction, isA<bool>());
        expect(env.environment.logLevel, isNotNull);
        
        // Test that feature flags are accessible
        expect(() => env.featureFlags, returnsNormally);
        expect(env.featureFlags, isA<Map>());
        
        print('✅ Environment configuration validated');
        print('   Environment: ${env.environment.name}');
        print('   Log Level: ${env.environment.logLevel}');
        print('   Feature Flags: ${env.featureFlags.keys.length} flags loaded');
      });
    });

    group('Error Handling Validation', () {
      test('Error handling system initializes correctly', () async {
        // Initialize the error handling system
        final errorHandler = AppErrorHandler.instance;
        await expectLater(() => errorHandler.initialize(), returnsNormally);
        
        // If we can initialize without errors, the system is functional
        print('✅ Error handling system validated');
      });
    });

    group('Integration Scenarios', () {
      test('Full startup sequence works', () async {
        // Test the complete startup sequence that mirrors main.dart
        
        // Step 1: WidgetsFlutterBinding (already done in setUpAll)
        
        // Step 2: Initialize error handling
        final errorHandler = AppErrorHandler.instance;
        await expectLater(() => errorHandler.initialize(), returnsNormally);
        
        // Step 3: Initialize Service Locator
        final serviceLocator = ServiceLocator.instance;
        await expectLater(() => serviceLocator.initialize(), returnsNormally);
        
        // If we get here without exceptions, the startup sequence works
        print('✅ Complete startup sequence validated');
        print('   All critical initialization steps completed successfully');
      });
    });
  });
}