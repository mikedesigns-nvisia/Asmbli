import 'package:flutter_test/flutter_test.dart';

// Import the simplified tests
import 'integration/basic_user_flow_test.dart' as basic_tests;
import 'widget_test.dart' as widget_tests;

/// Simplified test runner for basic functionality
/// 
/// This runner focuses on testing core app functionality without
/// complex service mocking. It verifies:
/// - App launches without crashing
/// - Basic UI structure is present  
/// - Navigation elements exist
/// - Theme system works
/// - Responsive layout
/// 
/// Run with: flutter test test/simple_test_runner.dart
void main() {
  group('Asmbli Desktop App - Basic Functionality Tests', () {
    
    group('📱 Core App Tests', () {
      widget_tests.main();
    });
    
    group('🎯 Basic User Flow Tests', () {
      basic_tests.main();
    });
  });
}