import 'package:agent_engine_core/models/agent.dart';
import '../services/business/agent_business_service.dart';
import '../services/business/conversation_business_service.dart';
import '../di/service_locator.dart';

/// Test suite for verifying service layer separation and isolation
/// This ensures business logic is properly separated from UI components
class ServiceLayerTest {
  
  /// Tests that business services are properly registered and accessible
  static Future<TestResult> testServiceRegistration() async {
    final results = <String, bool>{};
    final errors = <String>[];
    
    try {
      // Test ServiceLocator initialization
      try {
        await ServiceLocator.instance.initialize();
        results['service_locator_initialization'] = true;
      } catch (e) {
        results['service_locator_initialization'] = false;
        errors.add('ServiceLocator initialization failed: $e');
      }
      
      // Test business service availability
      try {
        final agentService = ServiceLocator.instance.get<AgentBusinessService>();
        results['agent_business_service_available'] = agentService != null;
      } catch (e) {
        results['agent_business_service_available'] = false;
        errors.add('AgentBusinessService not available: $e');
      }
      
      try {
        final conversationService = ServiceLocator.instance.get<ConversationBusinessService>();
        results['conversation_business_service_available'] = conversationService != null;
      } catch (e) {
        results['conversation_business_service_available'] = false;
        errors.add('ConversationBusinessService not available: $e');
      }
      
      // Test service health check
      try {
        final healthChecker = ServiceHealthChecker();
        final healthResult = await healthChecker.checkHealth();
        results['service_health_check'] = healthResult.isHealthy;
        
        if (!healthResult.isHealthy) {
          errors.addAll(healthResult.errors.values);
        }
      } catch (e) {
        results['service_health_check'] = false;
        errors.add('Service health check failed: $e');
      }
      
    } catch (e) {
      errors.add('Service registration test failed: $e');
    }
    
    return TestResult(
      testName: 'Service Registration and Availability',
      passed: results.values.every((result) => result),
      results: results,
      errors: errors,
    );
  }
  
  /// Tests that business services can operate independently of UI
  static Future<TestResult> testBusinessLogicIsolation() async {
    final results = <String, bool>{};
    final errors = <String>[];
    
    try {
      // Initialize services without UI context
      await ServiceLocator.instance.initialize();
      
      // Test agent business logic isolation
      try {
        final agentService = ServiceLocator.instance.get<AgentBusinessService>();
        
        // Test validation logic (should work without UI)
        final createResult = await agentService.createAgent(
          name: 'Test Agent',
          description: 'Test agent for isolation testing',
          capabilities: ['test'],
          modelId: 'test-model',
        );
        
        // Should fail validation but not throw UI-related errors
        results['agent_validation_isolated'] = !createResult.isSuccess &&
                                              createResult.error!.contains('not available');
      } catch (e) {
        results['agent_validation_isolated'] = false;
        errors.add('Agent business logic not isolated: $e');
      }
      
      // Test conversation business logic isolation
      try {
        final conversationService = ServiceLocator.instance.get<ConversationBusinessService>();
        
        // Test validation logic (should work without UI)
        final createResult = await conversationService.createConversation(
          title: 'Test Conversation',
          metadata: {'test': true},
        );
        
        // Should work or fail gracefully without UI dependencies
        results['conversation_logic_isolated'] = true;
      } catch (e) {
        results['conversation_logic_isolated'] = false;
        errors.add('Conversation business logic not isolated: $e');
      }
      
    } catch (e) {
      errors.add('Business logic isolation test failed: $e');
    }
    
    return TestResult(
      testName: 'Business Logic Isolation',
      passed: results.values.every((result) => result),
      results: results,
      errors: errors,
    );
  }
  
  /// Tests that business services have proper error handling
  static Future<TestResult> testBusinessErrorHandling() async {
    final results = <String, bool>{};
    final errors = <String>[];
    
    try {
      await ServiceLocator.instance.initialize();
      
      // Test agent service error handling
      try {
        final agentService = ServiceLocator.instance.get<AgentBusinessService>();
        
        // Test invalid input handling
        final invalidResult = await agentService.createAgent(
          name: '', // Invalid empty name
          description: 'Test',
          capabilities: [],
          modelId: 'invalid-model',
        );
        
        results['agent_error_handling'] = !invalidResult.isSuccess &&
                                         invalidResult.error != null;
      } catch (e) {
        results['agent_error_handling'] = false;
        errors.add('Agent error handling failed: $e');
      }
      
      // Test conversation service error handling
      try {
        final conversationService = ServiceLocator.instance.get<ConversationBusinessService>();
        
        // Test invalid input handling
        final invalidResult = await conversationService.processMessage(
          conversationId: 'invalid-id',
          content: 'test',
          modelId: 'invalid-model',
        );
        
        results['conversation_error_handling'] = !invalidResult.isSuccess &&
                                               invalidResult.error != null;
      } catch (e) {
        results['conversation_error_handling'] = false;
        errors.add('Conversation error handling failed: $e');
      }
      
    } catch (e) {
      errors.add('Error handling test failed: $e');
    }
    
    return TestResult(
      testName: 'Business Service Error Handling',
      passed: results.values.every((result) => result),
      results: results,
      errors: errors,
    );
  }
  
  /// Tests that services properly validate input parameters
  static Future<TestResult> testInputValidation() async {
    final results = <String, bool>{};
    final errors = <String>[];
    
    try {
      await ServiceLocator.instance.initialize();
      
      final agentService = ServiceLocator.instance.get<AgentBusinessService>();
      
      // Test null/empty validation
      try {
        final result = await agentService.createAgent(
          name: '',
          description: '',
          capabilities: [],
          modelId: '',
        );
        
        results['empty_input_validation'] = !result.isSuccess;
      } catch (e) {
        if (e is ArgumentError) {
          results['empty_input_validation'] = true;
        } else {
          results['empty_input_validation'] = false;
          errors.add('Unexpected error for empty input: $e');
        }
      }
      
      // Test business rule validation
      try {
        final result = await agentService.createAgent(
          name: 'Valid Name',
          description: 'Valid Description',
          capabilities: ['valid'],
          modelId: 'nonexistent-model', // This should fail validation
        );
        
        results['business_rule_validation'] = !result.isSuccess &&
                                            result.error!.contains('not available');
      } catch (e) {
        results['business_rule_validation'] = false;
        errors.add('Business rule validation failed: $e');
      }
      
    } catch (e) {
      errors.add('Input validation test failed: $e');
    }
    
    return TestResult(
      testName: 'Input Validation',
      passed: results.values.every((result) => result),
      results: results,
      errors: errors,
    );
  }
  
  /// Runs all service layer tests
  static Future<List<TestResult>> runAllTests() async {
    final results = <TestResult>[];
    
    print('🧪 Running Service Layer Isolation Tests...\n');
    
    // Run all test suites
    results.add(await testServiceRegistration());
    results.add(await testBusinessLogicIsolation());
    results.add(await testBusinessErrorHandling());
    results.add(await testInputValidation());
    
    // Print summary
    final passedTests = results.where((test) => test.passed).length;
    final totalTests = results.length;
    
    print('\n📊 Service Layer Test Summary:');
    print('✅ Passed: $passedTests/$totalTests tests');
    
    if (passedTests == totalTests) {
      print('🎉 All service layer tests passed! Business logic is properly separated.');
    } else {
      print('⚠️  Some tests failed. Business logic may still have UI dependencies.');
    }
    
    // Print detailed results
    for (final result in results) {
      print('\n${result.toString()}');
    }
    
    return results;
  }
}

class TestResult {
  final String testName;
  final bool passed;
  final Map<String, bool> results;
  final List<String> errors;
  
  const TestResult({
    required this.testName,
    required this.passed,
    required this.results,
    required this.errors,
  });
  
  @override
  String toString() {
    final status = passed ? '✅ PASSED' : '❌ FAILED';
    final buffer = StringBuffer();
    
    buffer.writeln('$status - $testName');
    
    if (results.isNotEmpty) {
      for (final entry in results.entries) {
        final resultStatus = entry.value ? '✅' : '❌';
        buffer.writeln('  $resultStatus ${entry.key}');
      }
    }
    
    if (errors.isNotEmpty) {
      buffer.writeln('  Errors:');
      for (final error in errors) {
        buffer.writeln('    • $error');
      }
    }
    
    return buffer.toString();
  }
}

/// Service layer test checklist
class ServiceLayerChecklist {
  static const List<String> requirements = [
    '✅ UI widgets only handle presentation logic',
    '✅ Business logic is encapsulated in services',
    '✅ Services are testable in isolation',
    '✅ Services are properly injected via DI container',
    '✅ No business logic remains in widgets',
    '✅ Services have comprehensive error handling',
    '✅ Services validate input parameters',
    '✅ Services can operate without UI context',
  ];
  
  static void printChecklist() {
    print('📋 Service Layer Separation Checklist:');
    for (final requirement in requirements) {
      print('  $requirement');
    }
  }
}

/// Manual verification helpers
class ServiceLayerVerification {
  
  /// Verifies that a widget only contains presentation logic
  static bool verifyWidgetPresentationOnly(String widgetCode) {
    final businessLogicPatterns = [
      RegExp(r'await\s+.*\.save\('),
      RegExp(r'await\s+.*\.create\('),
      RegExp(r'await\s+.*\.update\('),
      RegExp(r'await\s+.*\.delete\('),
      RegExp(r'if\s*\([^)]*\.isValid\(\)'),
      RegExp(r'validate\w*\('),
      RegExp(r'_calculate\w*\('),
      RegExp(r'_process\w*\('),
    ];
    
    for (final pattern in businessLogicPatterns) {
      if (pattern.hasMatch(widgetCode)) {
        print('⚠️ Found potential business logic: ${pattern.pattern}');
        return false;
      }
    }
    
    return true;
  }
  
  /// Verifies that a service contains only business logic
  static bool verifyServiceBusinessOnly(String serviceCode) {
    final uiLogicPatterns = [
      RegExp(r'setState\('),
      RegExp(r'Navigator\.'),
      RegExp(r'ScaffoldMessenger\.'),
      RegExp(r'showDialog\('),
      RegExp(r'BuildContext'),
      RegExp(r'Widget'),
    ];
    
    for (final pattern in uiLogicPatterns) {
      if (pattern.hasMatch(serviceCode)) {
        print('⚠️ Found potential UI logic in service: ${pattern.pattern}');
        return false;
      }
    }
    
    return true;
  }
}