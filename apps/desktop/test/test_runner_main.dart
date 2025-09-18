import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'integration/onboarding_flow_test.dart' as onboarding_tests;
import 'integration/chat_conversation_flow_test.dart' as chat_tests;
import 'integration/agent_creation_flow_test.dart' as agent_tests;
import 'integration/settings_configuration_flow_test.dart' as settings_tests;
import 'integration/navigation_routing_flow_test.dart' as navigation_tests;

/// Comprehensive test runner for all user flow tests
/// 
/// This file runs all major user flow tests for the AgentEngine desktop app:
/// - Onboarding flow
/// - Chat conversation flows
/// - Agent creation flows  
/// - Settings and configuration flows
/// - Navigation and routing flows
/// 
/// Run with: flutter test test/test_runner_main.dart
void main() {
  group('AgentEngine Desktop App - Complete User Flow Tests', () {
    
    // Run all test suites
    group('🎯 Onboarding Flow Tests', () {
      onboarding_tests.main();
    });
    
    group('💬 Chat Conversation Flow Tests', () {
      chat_tests.main();
    });
    
    group('🤖 Agent Creation Flow Tests', () {
      agent_tests.main();
    });
    
    group('⚙️ Settings Configuration Flow Tests', () {
      settings_tests.main();
    });
    
    group('🧭 Navigation & Routing Flow Tests', () {
      navigation_tests.main();
    });
  });
}

/// Run specific test suite
/// Usage examples:
/// - flutter test test/integration/onboarding_flow_test.dart
/// - flutter test test/integration/chat_conversation_flow_test.dart
/// - flutter test test/integration/agent_creation_flow_test.dart
/// - flutter test test/integration/settings_configuration_flow_test.dart
/// - flutter test test/integration/navigation_routing_flow_test.dart
/// 
/// Run all tests:
/// - flutter test test/test_runner_main.dart
/// 
/// Run with coverage:
/// - flutter test --coverage test/test_runner_main.dart
/// - genhtml coverage/lcov.info -o coverage/html
/// - open coverage/html/index.html