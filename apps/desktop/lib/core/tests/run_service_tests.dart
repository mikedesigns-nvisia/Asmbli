import 'dart:io';
import 'service_layer_test.dart';

/// Simple test runner for service layer validation
void main() async {
  print('🚀 Starting Service Layer Isolation Tests\n');
  
  try {
    // Run all service layer tests
    final results = await ServiceLayerTest.runAllTests();
    
    // Calculate overall success
    final passedTests = results.where((test) => test.passed).length;
    final totalTests = results.length;
    final allPassed = passedTests == totalTests;
    
    print('\n' + '='*60);
    print('🏁 SERVICE LAYER TEST RESULTS');
    print('='*60);
    print('Total Tests: $totalTests');
    print('Passed: $passedTests');
    print('Failed: ${totalTests - passedTests}');
    print('Success Rate: ${((passedTests / totalTests) * 100).toStringAsFixed(1)}%');
    
    if (allPassed) {
      print('\n🎉 ALL TESTS PASSED!');
      print('✅ Business logic is properly separated from UI');
      print('✅ Services can operate independently');
      print('✅ Error handling is comprehensive');
      print('✅ Input validation is working correctly');
      
      // Print the service layer checklist
      print('\n');
      ServiceLayerChecklist.printChecklist();
      
      exit(0);
    } else {
      print('\n⚠️  SOME TESTS FAILED');
      print('❌ Service layer separation needs attention');
      
      // Print failed test details
      final failedTests = results.where((test) => !test.passed);
      for (final test in failedTests) {
        print('\n❌ FAILED: ${test.testName}');
        for (final error in test.errors) {
          print('   • $error');
        }
      }
      
      exit(1);
    }
    
  } catch (e, stackTrace) {
    print('💥 TEST RUNNER FAILED: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}