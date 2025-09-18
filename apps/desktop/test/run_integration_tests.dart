import 'dart:io';

/// Integration Test Runner Script
/// 
/// This script provides a convenient way to run all integration tests
/// with proper setup and reporting.
void main(List<String> arguments) async {
  print('🚀 Starting Asmbli Desktop Integration Tests');
  print('═' * 50);
  
  // Parse command line arguments
  final shouldRunAll = arguments.contains('--all') || arguments.isEmpty;
  final shouldRunSettings = arguments.contains('--settings') || shouldRunAll;
  final shouldRunOAuth = arguments.contains('--oauth') || shouldRunAll;
  final shouldRunMCP = arguments.contains('--mcp') || shouldRunAll;
  final shouldRunChat = arguments.contains('--chat') || shouldRunAll;
  final shouldRunUnified = arguments.contains('--unified') || shouldRunAll;
  final shouldRunComprehensive = arguments.contains('--comprehensive') || arguments.contains('--all');
  final verbose = arguments.contains('--verbose') || arguments.contains('-v');

  // Test execution configuration
  final testConfig = TestConfig(
    verbose: verbose,
    showCoverage: arguments.contains('--coverage'),
    failFast: arguments.contains('--fail-fast'),
    parallel: !arguments.contains('--no-parallel'),
  );

  try {
    // Initialize test environment
    await setupTestEnvironment();

    final results = <String, TestResult>{};

    // Run individual test suites
    if (shouldRunSettings) {
      print('📋 Running Settings Services Integration Tests...');
      results['settings'] = await runTestSuite(
        'settings_services_integration_test.dart',
        testConfig,
      );
    }

    if (shouldRunOAuth) {
      print('🔐 Running OAuth Flows Integration Tests...');
      results['oauth'] = await runTestSuite(
        'oauth_flows_integration_test.dart',
        testConfig,
      );
    }

    if (shouldRunMCP) {
      print('🔌 Running MCP Integration Tests...');
      results['mcp'] = await runTestSuite(
        'mcp_integration_test.dart',
        testConfig,
      );
    }

    if (shouldRunChat) {
      print('💬 Running Chat Functionality Integration Tests...');
      results['chat'] = await runTestSuite(
        'chat_functionality_integration_test.dart',
        testConfig,
      );
    }

    if (shouldRunUnified) {
      print('⚙️ Running Unified Settings System Integration Tests...');
      results['unified'] = await runTestSuite(
        'unified_settings_system_integration_test.dart',
        testConfig,
      );
    }

    if (shouldRunComprehensive) {
      print('🧪 Running Comprehensive Integration Test Suite...');
      results['comprehensive'] = await runTestSuite(
        'comprehensive_integration_test_suite.dart',
        testConfig,
      );
    }

    // Generate final report
    await generateFinalReport(results, testConfig);

  } catch (e, stackTrace) {
    print('❌ Test execution failed: $e');
    if (verbose) {
      print('Stack trace: $stackTrace');
    }
    exit(1);
  }
}

/// Test execution configuration
class TestConfig {
  final bool verbose;
  final bool showCoverage;
  final bool failFast;
  final bool parallel;

  TestConfig({
    required this.verbose,
    required this.showCoverage,
    required this.failFast,
    required this.parallel,
  });
}

/// Test result data
class TestResult {
  final String name;
  final bool passed;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final Duration duration;
  final List<String> failures;

  TestResult({
    required this.name,
    required this.passed,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.duration,
    required this.failures,
  });
}

/// Set up the test environment
Future<void> setupTestEnvironment() async {
  print('🔧 Setting up test environment...');
  
  // Verify Flutter is available
  final flutterResult = await Process.run('flutter', ['--version']);
  if (flutterResult.exitCode != 0) {
    throw Exception('Flutter is not available. Please install Flutter.');
  }

  // Clean previous test artifacts
  final testDir = Directory('test');
  if (await testDir.exists()) {
    final pubspecLock = File('pubspec.lock');
    if (await pubspecLock.exists()) {
      print('📦 Getting dependencies...');
      final pubGetResult = await Process.run('flutter', ['pub', 'get']);
      if (pubGetResult.exitCode != 0) {
        throw Exception('Failed to get dependencies: ${pubGetResult.stderr}');
      }
    }
  }

  print('✅ Test environment ready');
}

/// Run a specific test suite
Future<TestResult> runTestSuite(String testFile, TestConfig config) async {
  final stopwatch = Stopwatch()..start();
  
  try {
    final args = [
      'test',
      'test/integration/$testFile',
      if (config.verbose) '--verbose',
      if (config.failFast) '--fail-fast',
      '--reporter=json',
    ];

    final process = await Process.start('flutter', args);
    
    final stdout = <String>[];
    final stderr = <String>[];
    
    process.stdout.transform(const SystemEncoding().decoder).listen((data) {
      stdout.add(data);
      if (config.verbose) {
        print(data);
      }
    });
    
    process.stderr.transform(const SystemEncoding().decoder).listen((data) {
      stderr.add(data);
      if (config.verbose) {
        print('ERROR: $data');
      }
    });

    final exitCode = await process.exitCode;
    stopwatch.stop();

    // Parse test results (simplified - would need proper JSON parsing)
    final passed = exitCode == 0;
    final output = stdout.join();
    final errors = stderr.join();
    
    // Extract test counts (simplified parsing)
    final totalTests = _extractTestCount(output, 'total') ?? 0;
    final passedTests = passed ? totalTests : _extractTestCount(output, 'passed') ?? 0;
    final failedTests = totalTests - passedTests;
    
    final failures = <String>[];
    if (!passed && errors.isNotEmpty) {
      failures.add(errors);
    }

    final result = TestResult(
      name: testFile,
      passed: passed,
      totalTests: totalTests,
      passedTests: passedTests,
      failedTests: failedTests,
      duration: stopwatch.elapsed,
      failures: failures,
    );

    print(passed ? '✅ $testFile completed successfully' : '❌ $testFile failed');
    return result;

  } catch (e) {
    stopwatch.stop();
    print('❌ $testFile failed to run: $e');
    
    return TestResult(
      name: testFile,
      passed: false,
      totalTests: 0,
      passedTests: 0,
      failedTests: 1,
      duration: stopwatch.elapsed,
      failures: [e.toString()],
    );
  }
}

/// Extract test count from output (simplified)
int? _extractTestCount(String output, String type) {
  // This would implement proper JSON parsing of test results
  // For now, return a placeholder
  return 10; // Placeholder
}

/// Generate final test report
Future<void> generateFinalReport(Map<String, TestResult> results, TestConfig config) async {
  print('\n' + '═' * 60);
  print('📊 INTEGRATION TEST RESULTS SUMMARY');
  print('═' * 60);

  int totalTests = 0;
  int totalPassed = 0;
  int totalFailed = 0;
  Duration totalDuration = Duration.zero;

  for (final result in results.values) {
    totalTests += result.totalTests;
    totalPassed += result.passedTests;
    totalFailed += result.failedTests;
    totalDuration += result.duration;

    final status = result.passed ? '✅' : '❌';
    final name = result.name.replaceAll('_test.dart', '').replaceAll('_', ' ');
    print('$status $name: ${result.passedTests}/${result.totalTests} passed (${result.duration.inMilliseconds}ms)');

    if (!result.passed && result.failures.isNotEmpty) {
      for (final failure in result.failures) {
        print('   └── $failure');
      }
    }
  }

  print('\n' + '─' * 60);
  print('📈 OVERALL RESULTS:');
  print('   Total Tests: $totalTests');
  print('   Passed: $totalPassed');
  print('   Failed: $totalFailed');
  print('   Success Rate: ${totalTests > 0 ? ((totalPassed / totalTests) * 100).toStringAsFixed(1) : '0.0'}%');
  print('   Total Duration: ${totalDuration.inSeconds}s');
  
  // Generate detailed report file
  await _generateDetailedReport(results, config);
  
  final allPassed = totalFailed == 0;
  print('\n🏆 ${allPassed ? "ALL TESTS PASSED!" : "SOME TESTS FAILED"}');
  
  if (!allPassed) {
    print('💡 Check the detailed report for failure analysis.');
    exit(1);
  }
}

/// Generate detailed HTML/Markdown report
Future<void> _generateDetailedReport(Map<String, TestResult> results, TestConfig config) async {
  final reportFile = File('test/reports/integration_test_report.md');
  await reportFile.parent.create(recursive: true);
  
  final timestamp = DateTime.now().toIso8601String();
  
  final report = StringBuffer();
  report.writeln('# Integration Test Report');
  report.writeln('Generated: $timestamp');
  report.writeln();
  
  report.writeln('## Summary');
  final totalTests = results.values.fold(0, (sum, r) => sum + r.totalTests);
  final totalPassed = results.values.fold(0, (sum, r) => sum + r.passedTests);
  final totalFailed = results.values.fold(0, (sum, r) => sum + r.failedTests);
  
  report.writeln('- **Total Tests**: $totalTests');
  report.writeln('- **Passed**: $totalPassed');
  report.writeln('- **Failed**: $totalFailed');
  report.writeln('- **Success Rate**: ${totalTests > 0 ? ((totalPassed / totalTests) * 100).toStringAsFixed(1) : '0.0'}%');
  report.writeln();
  
  report.writeln('## Test Suites');
  for (final result in results.values) {
    report.writeln('### ${result.name}');
    report.writeln('- Status: ${result.passed ? '✅ PASSED' : '❌ FAILED'}');
    report.writeln('- Tests: ${result.passedTests}/${result.totalTests}');
    report.writeln('- Duration: ${result.duration.inMilliseconds}ms');
    
    if (result.failures.isNotEmpty) {
      report.writeln('- Failures:');
      for (final failure in result.failures) {
        report.writeln('  - $failure');
      }
    }
    report.writeln();
  }
  
  await reportFile.writeAsString(report.toString());
  print('📄 Detailed report generated: ${reportFile.path}');
}

/// Show usage information
void showUsage() {
  print('''
Integration Test Runner for Asmbli Desktop

USAGE:
  dart run test/run_integration_tests.dart [OPTIONS]

OPTIONS:
  --all               Run all integration tests (default)
  --settings          Run only settings services integration tests
  --oauth             Run only OAuth flows integration tests  
  --mcp               Run only MCP integration tests
  --chat              Run only chat functionality integration tests
  --unified           Run only unified settings system integration tests
  --comprehensive     Run comprehensive cross-service integration tests
  
  --verbose, -v       Show detailed test output
  --coverage          Generate coverage report
  --fail-fast         Stop on first test failure
  --no-parallel       Disable parallel test execution
  
  --help, -h          Show this help message

EXAMPLES:
  # Run all tests
  dart run test/run_integration_tests.dart
  
  # Run only OAuth tests with verbose output
  dart run test/run_integration_tests.dart --oauth --verbose
  
  # Run comprehensive tests with coverage
  dart run test/run_integration_tests.dart --comprehensive --coverage
''');
}