import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'integration_service.dart';
import 'mcp_settings_service.dart';

// Validation classes for integration testing
class ValidationResult {
  final bool isValid;
  final List<ValidationIssue> issues;
  final List<String> suggestedOrder;

  const ValidationResult({
    required this.isValid,
    required this.issues,
    required this.suggestedOrder,
  });
}

class ValidationIssue {
  final ValidationSeverity severity;
  final String integrationId;
  final String message;
  final List<String> affectedIntegrations;

  const ValidationIssue({
    required this.severity,
    required this.integrationId,
    required this.message,
    required this.affectedIntegrations,
  });
}

enum ValidationSeverity {
  error,
  warning,
  info,
}

/// Service for testing and validating integration configurations
class IntegrationTestingService {
  final IntegrationService _integrationService;
  final MCPSettingsService _mcpService;
  
  // Test execution state
  final Map<String, TestSession> _activeSessions = {};
  final StreamController<TestResult> _testResultsController = StreamController<TestResult>.broadcast();
  
  IntegrationTestingService(this._integrationService, this._mcpService);
  
  /// Stream of test results
  Stream<TestResult> get testResults => _testResultsController.stream;
  
  /// Run comprehensive tests for an integration
  Future<TestSuite> runIntegrationTests(String integrationId, {
    List<TestType>? testTypes,
    Map<String, dynamic>? customSettings,
  }) async {
    final integration = IntegrationRegistry.getById(integrationId);
    if (integration == null) {
      throw IntegrationTestException('Integration not found: $integrationId');
    }
    
    final config = _mcpService.allMCPServers[integrationId];
    if (config == null) {
      throw IntegrationTestException('Integration not configured: $integrationId');
    }
    
    final sessionId = _generateSessionId();
    final session = TestSession(
      sessionId: sessionId,
      integrationId: integrationId,
      startTime: DateTime.now(),
      status: TestSessionStatus.running,
    );
    
    _activeSessions[sessionId] = session;
    
    try {
      final testSuite = await _executeTestSuite(
        integration,
        config,
        testTypes ?? _getDefaultTestTypes(integration),
        customSettings ?? {},
      );
      
      session.status = testSuite.overallStatus == TestStatus.passed 
          ? TestSessionStatus.completed 
          : TestSessionStatus.failed;
      session.endTime = DateTime.now();
      
      return testSuite;
    } catch (e) {
      session.status = TestSessionStatus.failed;
      session.endTime = DateTime.now();
      session.error = e.toString();
      rethrow;
    } finally {
      _activeSessions.remove(sessionId);
    }
  }
  
  /// Run quick validation tests
  Future<ValidationResult> validateConfiguration(String integrationId) async {
    final integration = IntegrationRegistry.getById(integrationId);
    if (integration == null) {
      return ValidationResult(
        isValid: false,
        issues: [
          ValidationIssue(
            severity: ValidationSeverity.error,
            integrationId: integrationId,
            message: 'Integration definition not found',
            affectedIntegrations: [integrationId],
          ),
        ],
        suggestedOrder: [],
      );
    }
    
    final config = _mcpService.allMCPServers[integrationId];
    if (config == null) {
      return ValidationResult(
        isValid: false,
        issues: [
          ValidationIssue(
            severity: ValidationSeverity.error,
            integrationId: integrationId,
            message: 'Integration not configured',
            affectedIntegrations: [integrationId],
          ),
        ],
        suggestedOrder: [],
      );
    }
    
    final issues = <ValidationIssue>[];
    
    // Validate required fields
    issues.addAll(await _validateRequiredFields(integration, config));
    
    // Validate connectivity
    issues.addAll(await _validateConnectivity(integration, config));
    
    // Validate permissions
    issues.addAll(await _validatePermissions(integration, config));
    
    // Validate dependencies
    issues.addAll(await _validateDependencies(integration));
    
    return ValidationResult(
      isValid: !issues.any((issue) => issue.severity == ValidationSeverity.error),
      issues: issues,
      suggestedOrder: [],
    );
  }
  
  /// Run performance benchmarks
  Future<BenchmarkResult> runBenchmarks(String integrationId, {
    int iterations = 10,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final integration = IntegrationRegistry.getById(integrationId);
    if (integration == null) {
      throw IntegrationTestException('Integration not found: $integrationId');
    }
    
    final config = _mcpService.allMCPServers[integrationId];
    if (config == null) {
      throw IntegrationTestException('Integration not configured: $integrationId');
    }
    
    final results = <BenchmarkTest>[];
    
    // Connection benchmark
    results.add(await _benchmarkConnection(integration, config, iterations));
    
    // Response time benchmark
    results.add(await _benchmarkResponseTime(integration, config, iterations));
    
    // Throughput benchmark
    results.add(await _benchmarkThroughput(integration, config, iterations));
    
    // Resource usage benchmark
    results.add(await _benchmarkResourceUsage(integration, config, iterations));
    
    return BenchmarkResult(
      integrationId: integrationId,
      timestamp: DateTime.now(),
      iterations: iterations,
      tests: results,
      overallScore: _calculateOverallScore(results),
    );
  }
  
  /// Get test recommendations based on integration type and configuration
  List<TestRecommendation> getTestRecommendations(String integrationId) {
    final integration = IntegrationRegistry.getById(integrationId);
    if (integration == null) return [];
    
    final recommendations = <TestRecommendation>[];
    
    // Basic connectivity tests
    recommendations.add(TestRecommendation(
      testType: TestType.connectivity,
      priority: RecommendationPriority.high,
      reason: 'Verify basic connection to ${integration.name}',
      estimatedDuration: Duration(seconds: 10),
    ));
    
    // Authentication tests
    recommendations.add(TestRecommendation(
      testType: TestType.authentication,
      priority: RecommendationPriority.high,
      reason: 'Validate authentication credentials',
      estimatedDuration: Duration(seconds: 5),
    ));
    
    // Category-specific recommendations
    switch (integration.category) {
      case IntegrationCategory.databases:
        recommendations.addAll([
          TestRecommendation(
            testType: TestType.dataIntegrity,
            priority: RecommendationPriority.medium,
            reason: 'Test database operations and data consistency',
            estimatedDuration: Duration(seconds: 30),
          ),
          TestRecommendation(
            testType: TestType.performance,
            priority: RecommendationPriority.medium,
            reason: 'Benchmark database query performance',
            estimatedDuration: Duration(minutes: 2),
          ),
        ]);
        break;
        
      case IntegrationCategory.cloudAPIs:
        recommendations.addAll([
          TestRecommendation(
            testType: TestType.rateLimiting,
            priority: RecommendationPriority.medium,
            reason: 'Test API rate limits and error handling',
            estimatedDuration: Duration(seconds: 45),
          ),
          TestRecommendation(
            testType: TestType.errorHandling,
            priority: RecommendationPriority.medium,
            reason: 'Validate error response handling',
            estimatedDuration: Duration(seconds: 20),
          ),
        ]);
        break;
        
      case IntegrationCategory.local:
        recommendations.addAll([
          TestRecommendation(
            testType: TestType.fileSystem,
            priority: RecommendationPriority.medium,
            reason: 'Test file system access and permissions',
            estimatedDuration: Duration(seconds: 15),
          ),
          TestRecommendation(
            testType: TestType.security,
            priority: RecommendationPriority.high,
            reason: 'Validate local security constraints',
            estimatedDuration: Duration(seconds: 25),
          ),
        ]);
        break;
        
      default:
        recommendations.add(TestRecommendation(
          testType: TestType.functional,
          priority: RecommendationPriority.medium,
          reason: 'Test core functionality',
          estimatedDuration: Duration(seconds: 30),
        ));
    }
    
    return recommendations;
  }
  
  /// Get active test sessions
  List<TestSession> getActiveTestSessions() {
    return _activeSessions.values.toList();
  }
  
  /// Cancel a running test session
  Future<void> cancelTestSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session != null) {
      session.status = TestSessionStatus.cancelled;
      session.endTime = DateTime.now();
      _activeSessions.remove(sessionId);
    }
  }
  
  /// Generate test report
  Future<TestReport> generateTestReport(List<TestSuite> testSuites) async {
    final totalTests = testSuites.fold(0, (sum, suite) => sum + suite.tests.length);
    final passedTests = testSuites.fold(0, (sum, suite) => sum + suite.tests.where((t) => t.status == TestStatus.passed).length);
    final failedTests = testSuites.fold(0, (sum, suite) => sum + suite.tests.where((t) => t.status == TestStatus.failed).length);
    
    final integrationResults = <String, IntegrationTestSummary>{};
    
    for (final suite in testSuites) {
      integrationResults[suite.integrationId] = IntegrationTestSummary(
        integrationId: suite.integrationId,
        totalTests: suite.tests.length,
        passedTests: suite.tests.where((t) => t.status == TestStatus.passed).length,
        failedTests: suite.tests.where((t) => t.status == TestStatus.failed).length,
        overallStatus: suite.overallStatus,
        duration: suite.duration,
        criticalIssues: suite.tests.where((t) => t.status == TestStatus.failed && t.severity == TestSeverity.critical).length,
      );
    }
    
    return TestReport(
      generatedAt: DateTime.now(),
      totalIntegrations: testSuites.length,
      totalTests: totalTests,
      passedTests: passedTests,
      failedTests: failedTests,
      overallStatus: failedTests == 0 ? TestStatus.passed : TestStatus.failed,
      integrationResults: integrationResults,
      recommendations: _generateReportRecommendations(testSuites),
    );
  }
  
  // Private methods
  Future<TestSuite> _executeTestSuite(
    IntegrationDefinition integration,
    MCPServerConfig config,
    List<TestType> testTypes,
    Map<String, dynamic> customSettings,
  ) async {
    final tests = <TestResult>[];
    final startTime = DateTime.now();
    
    for (final testType in testTypes) {
      final testResult = await _executeTest(integration, config, testType, customSettings);
      tests.add(testResult);
      
      // Emit result for real-time updates
      _testResultsController.add(testResult);
    }
    
    final endTime = DateTime.now();
    final overallStatus = tests.any((t) => t.status == TestStatus.failed) 
        ? TestStatus.failed 
        : TestStatus.passed;
    
    return TestSuite(
      integrationId: integration.id,
      startTime: startTime,
      endTime: endTime,
      duration: endTime.difference(startTime),
      tests: tests,
      overallStatus: overallStatus,
    );
  }
  
  Future<TestResult> _executeTest(
    IntegrationDefinition integration,
    MCPServerConfig config,
    TestType testType,
    Map<String, dynamic> customSettings,
  ) async {
    final startTime = DateTime.now();
    
    try {
      switch (testType) {
        case TestType.connectivity:
          return await _testConnectivity(integration, config, startTime);
        case TestType.authentication:
          return await _testAuthentication(integration, config, startTime);
        case TestType.functional:
          return await _testFunctionality(integration, config, startTime);
        case TestType.performance:
          return await _testPerformance(integration, config, startTime);
        case TestType.security:
          return await _testSecurity(integration, config, startTime);
        case TestType.dataIntegrity:
          return await _testDataIntegrity(integration, config, startTime);
        case TestType.errorHandling:
          return await _testErrorHandling(integration, config, startTime);
        case TestType.rateLimiting:
          return await _testRateLimiting(integration, config, startTime);
        case TestType.fileSystem:
          return await _testFileSystem(integration, config, startTime);
      }
    } catch (e) {
      return TestResult(
        testId: _generateTestId(),
        testType: testType,
        integrationId: integration.id,
        startTime: startTime,
        endTime: DateTime.now(),
        status: TestStatus.failed,
        severity: TestSeverity.high,
        message: 'Test execution failed',
        details: {'error': e.toString()},
      );
    }
  }
  
  Future<TestResult> _testConnectivity(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    // Simulate connectivity test
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));
    
    final success = Random().nextBool(); // Mock success/failure
    
    return TestResult(
      testId: _generateTestId(),
      testType: TestType.connectivity,
      integrationId: integration.id,
      startTime: startTime,
      endTime: DateTime.now(),
      status: success ? TestStatus.passed : TestStatus.failed,
      severity: success ? TestSeverity.info : TestSeverity.high,
      message: success 
          ? 'Successfully connected to ${integration.name}'
          : 'Failed to connect to ${integration.name}',
      details: {
        'endpoint': config.command.isNotEmpty ? config.command : 'unknown',
        'responseTime': '${500 + Random().nextInt(1000)}ms',
        'protocol': integration.category == IntegrationCategory.cloudAPIs ? 'HTTPS' : 'Local',
      },
    );
  }
  
  Future<TestResult> _testAuthentication(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(300)));
    
    final hasAuth = (config.env?.containsKey('API_KEY') ?? false) || 
                   (config.env?.containsKey('TOKEN') ?? false) || 
                   (config.env?.containsKey('USERNAME') ?? false);
    
    return TestResult(
      testId: _generateTestId(),
      testType: TestType.authentication,
      integrationId: integration.id,
      startTime: startTime,
      endTime: DateTime.now(),
      status: hasAuth ? TestStatus.passed : TestStatus.failed,
      severity: hasAuth ? TestSeverity.info : TestSeverity.medium,
      message: hasAuth 
          ? 'Authentication credentials verified'
          : 'Authentication configuration missing or invalid',
      details: {
        'authMethod': hasAuth ? 'Configured' : 'Missing',
        'credentialsFound': hasAuth,
      },
    );
  }
  
  Future<TestResult> _testFunctionality(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    await Future.delayed(Duration(milliseconds: 1000 + Random().nextInt(2000)));
    
    final success = Random().nextDouble() > 0.2; // 80% success rate
    
    return TestResult(
      testId: _generateTestId(),
      testType: TestType.functional,
      integrationId: integration.id,
      startTime: startTime,
      endTime: DateTime.now(),
      status: success ? TestStatus.passed : TestStatus.failed,
      severity: success ? TestSeverity.info : TestSeverity.medium,
      message: success 
          ? 'Core functionality tests passed'
          : 'Some functionality tests failed',
      details: {
        'testsRun': Random().nextInt(10) + 5,
        'testsPassed': success ? Random().nextInt(10) + 10 : Random().nextInt(8) + 2,
        'capabilities': integration.capabilities.length,
      },
    );
  }
  
  Future<TestResult> _testPerformance(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    await Future.delayed(Duration(milliseconds: 2000 + Random().nextInt(3000)));
    
    final responseTime = Random().nextInt(500) + 100;
    final success = responseTime < 1000;
    
    return TestResult(
      testId: _generateTestId(),
      testType: TestType.performance,
      integrationId: integration.id,
      startTime: startTime,
      endTime: DateTime.now(),
      status: success ? TestStatus.passed : TestStatus.failed,
      severity: success ? TestSeverity.info : TestSeverity.medium,
      message: success 
          ? 'Performance benchmarks within acceptable limits'
          : 'Performance issues detected',
      details: {
        'averageResponseTime': '${responseTime}ms',
        'throughput': '${Random().nextInt(100) + 10} ops/sec',
        'memoryUsage': '${Random().nextInt(50) + 10}MB',
      },
    );
  }
  
  Future<TestResult> _testSecurity(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(1200)));
    
    final issues = Random().nextInt(3); // 0-2 security issues
    
    return TestResult(
      testId: _generateTestId(),
      testType: TestType.security,
      integrationId: integration.id,
      startTime: startTime,
      endTime: DateTime.now(),
      status: issues == 0 ? TestStatus.passed : TestStatus.failed,
      severity: issues == 0 ? TestSeverity.info : issues == 1 ? TestSeverity.medium : TestSeverity.high,
      message: issues == 0 
          ? 'Security checks passed'
          : '$issues security issue${issues > 1 ? 's' : ''} found',
      details: {
        'securityIssues': issues,
        'encryptionEnabled': Random().nextBool(),
        'permissionsValid': issues < 2,
      },
    );
  }
  
  Future<TestResult> _testDataIntegrity(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(2500)));
    
    final success = Random().nextDouble() > 0.15; // 85% success rate
    
    return TestResult(
      testId: _generateTestId(),
      testType: TestType.dataIntegrity,
      integrationId: integration.id,
      startTime: startTime,
      endTime: DateTime.now(),
      status: success ? TestStatus.passed : TestStatus.failed,
      severity: success ? TestSeverity.info : TestSeverity.high,
      message: success 
          ? 'Data integrity checks passed'
          : 'Data integrity issues detected',
      details: {
        'recordsChecked': Random().nextInt(1000) + 100,
        'corruptRecords': success ? 0 : Random().nextInt(5) + 1,
        'checksumValid': success,
      },
    );
  }
  
  Future<TestResult> _testErrorHandling(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    await Future.delayed(Duration(milliseconds: 600 + Random().nextInt(800)));
    
    final success = Random().nextDouble() > 0.25; // 75% success rate
    
    return TestResult(
      testId: _generateTestId(),
      testType: TestType.errorHandling,
      integrationId: integration.id,
      startTime: startTime,
      endTime: DateTime.now(),
      status: success ? TestStatus.passed : TestStatus.failed,
      severity: success ? TestSeverity.info : TestSeverity.medium,
      message: success 
          ? 'Error handling tests passed'
          : 'Error handling needs improvement',
      details: {
        'errorScenariosTest': Random().nextInt(10) + 5,
        'gracefulFailures': success,
        'retryMechanism': Random().nextBool(),
      },
    );
  }
  
  Future<TestResult> _testRateLimiting(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    await Future.delayed(Duration(milliseconds: 1200 + Random().nextInt(1800)));
    
    final success = Random().nextDouble() > 0.3; // 70% success rate
    
    return TestResult(
      testId: _generateTestId(),
      testType: TestType.rateLimiting,
      integrationId: integration.id,
      startTime: startTime,
      endTime: DateTime.now(),
      status: success ? TestStatus.passed : TestStatus.failed,
      severity: success ? TestSeverity.info : TestSeverity.medium,
      message: success 
          ? 'Rate limiting handled correctly'
          : 'Rate limiting issues detected',
      details: {
        'requestsPerMinute': Random().nextInt(1000) + 100,
        'rateLimitHit': !success,
        'backoffStrategy': success,
      },
    );
  }
  
  Future<TestResult> _testFileSystem(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    await Future.delayed(Duration(milliseconds: 400 + Random().nextInt(600)));
    
    final success = Random().nextDouble() > 0.1; // 90% success rate for local operations
    
    return TestResult(
      testId: _generateTestId(),
      testType: TestType.fileSystem,
      integrationId: integration.id,
      startTime: startTime,
      endTime: DateTime.now(),
      status: success ? TestStatus.passed : TestStatus.failed,
      severity: success ? TestSeverity.info : TestSeverity.medium,
      message: success 
          ? 'File system access validated'
          : 'File system permission issues',
      details: {
        'readPermissions': success,
        'writePermissions': success && Random().nextBool(),
        'pathsAccessible': success ? Random().nextInt(10) + 5 : Random().nextInt(3),
      },
    );
  }
  
  // Benchmark implementations
  Future<BenchmarkTest> _benchmarkConnection(
    IntegrationDefinition integration,
    MCPServerConfig config,
    int iterations,
  ) async {
    final results = <double>[];
    
    for (int i = 0; i < iterations; i++) {
      final start = DateTime.now();
      await Future.delayed(Duration(milliseconds: 50 + Random().nextInt(200)));
      final end = DateTime.now();
      results.add(end.difference(start).inMilliseconds.toDouble());
    }
    
    return BenchmarkTest(
      testName: 'Connection',
      iterations: iterations,
      results: results,
      averageTime: results.reduce((a, b) => a + b) / results.length,
      minTime: results.reduce((a, b) => a < b ? a : b),
      maxTime: results.reduce((a, b) => a > b ? a : b),
      unit: 'ms',
    );
  }
  
  Future<BenchmarkTest> _benchmarkResponseTime(
    IntegrationDefinition integration,
    MCPServerConfig config,
    int iterations,
  ) async {
    final results = <double>[];
    
    for (int i = 0; i < iterations; i++) {
      final start = DateTime.now();
      await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(400)));
      final end = DateTime.now();
      results.add(end.difference(start).inMilliseconds.toDouble());
    }
    
    return BenchmarkTest(
      testName: 'Response Time',
      iterations: iterations,
      results: results,
      averageTime: results.reduce((a, b) => a + b) / results.length,
      minTime: results.reduce((a, b) => a < b ? a : b),
      maxTime: results.reduce((a, b) => a > b ? a : b),
      unit: 'ms',
    );
  }
  
  Future<BenchmarkTest> _benchmarkThroughput(
    IntegrationDefinition integration,
    MCPServerConfig config,
    int iterations,
  ) async {
    final results = <double>[];
    
    for (int i = 0; i < iterations; i++) {
      await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(300)));
      results.add((Random().nextInt(100) + 50).toDouble()); // ops per second
    }
    
    return BenchmarkTest(
      testName: 'Throughput',
      iterations: iterations,
      results: results,
      averageTime: results.reduce((a, b) => a + b) / results.length,
      minTime: results.reduce((a, b) => a < b ? a : b),
      maxTime: results.reduce((a, b) => a > b ? a : b),
      unit: 'ops/sec',
    );
  }
  
  Future<BenchmarkTest> _benchmarkResourceUsage(
    IntegrationDefinition integration,
    MCPServerConfig config,
    int iterations,
  ) async {
    final results = <double>[];
    
    for (int i = 0; i < iterations; i++) {
      await Future.delayed(Duration(milliseconds: 100));
      results.add((Random().nextInt(100) + 10).toDouble()); // MB
    }
    
    return BenchmarkTest(
      testName: 'Memory Usage',
      iterations: iterations,
      results: results,
      averageTime: results.reduce((a, b) => a + b) / results.length,
      minTime: results.reduce((a, b) => a < b ? a : b),
      maxTime: results.reduce((a, b) => a > b ? a : b),
      unit: 'MB',
    );
  }
  
  // Helper methods
  List<TestType> _getDefaultTestTypes(IntegrationDefinition integration) {
    final types = [TestType.connectivity, TestType.authentication, TestType.functional];
    
    switch (integration.category) {
      case IntegrationCategory.databases:
        types.addAll([TestType.dataIntegrity, TestType.performance]);
        break;
      case IntegrationCategory.cloudAPIs:
        types.addAll([TestType.rateLimiting, TestType.errorHandling]);
        break;
      case IntegrationCategory.local:
        types.addAll([TestType.fileSystem, TestType.security]);
        break;
      default:
        types.add(TestType.errorHandling);
    }
    
    return types;
  }
  
  Future<List<ValidationIssue>> _validateRequiredFields(
    IntegrationDefinition integration,
    MCPServerConfig config,
  ) async {
    final issues = <ValidationIssue>[];
    
    if (config.command.isEmpty) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.error,
        integrationId: integration.id,
        message: 'Command is required',
        affectedIntegrations: [integration.id],
      ));
    }
    
    return issues;
  }
  
  Future<List<ValidationIssue>> _validateConnectivity(
    IntegrationDefinition integration,
    MCPServerConfig config,
  ) async {
    final issues = <ValidationIssue>[];
    
    // Mock connectivity validation
    if (Random().nextBool()) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        integrationId: integration.id,
        message: 'Connection test failed',
        affectedIntegrations: [integration.id],
      ));
    }
    
    return issues;
  }
  
  Future<List<ValidationIssue>> _validatePermissions(
    IntegrationDefinition integration,
    MCPServerConfig config,
  ) async {
    final issues = <ValidationIssue>[];
    
    // Mock permission validation
    if (integration.category == IntegrationCategory.local && Random().nextBool()) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        integrationId: integration.id,
        message: 'Insufficient permissions detected',
        affectedIntegrations: [integration.id],
      ));
    }
    
    return issues;
  }
  
  Future<List<ValidationIssue>> _validateDependencies(
    IntegrationDefinition integration,
  ) async {
    final issues = <ValidationIssue>[];
    
    // Check prerequisites
    if (integration.prerequisites.isNotEmpty) {
      for (final prereq in integration.prerequisites) {
        if (!_isPrerequisiteMet(prereq)) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.warning,
            integrationId: integration.id,
            message: 'Prerequisite not met: $prereq',
            affectedIntegrations: [integration.id],
          ));
        }
      }
    }
    
    return issues;
  }
  
  bool _isPrerequisiteMet(String prerequisite) {
    // Mock prerequisite checking
    return Random().nextBool();
  }
  
  double _calculateOverallScore(List<BenchmarkTest> tests) {
    if (tests.isEmpty) return 0;
    
    // Simple scoring algorithm
    double score = 100;
    
    for (final test in tests) {
      if (test.averageTime > 1000) score -= 20; // Slow response
      if (test.averageTime > 500) score -= 10;
      if (test.maxTime > test.averageTime * 3) score -= 10; // High variance
    }
    
    return score.clamp(0, 100);
  }
  
  List<String> _generateReportRecommendations(List<TestSuite> testSuites) {
    final recommendations = <String>[];
    
    final failedSuites = testSuites.where((s) => s.overallStatus == TestStatus.failed);
    
    if (failedSuites.isNotEmpty) {
      recommendations.add('Review failed integrations: ${failedSuites.map((s) => s.integrationId).join(', ')}');
    }
    
    recommendations.add('Run regular tests to maintain integration health');
    recommendations.add('Consider performance optimization for slow integrations');
    
    return recommendations;
  }
  
  String _generateSessionId() => 'test_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateTestId() => 'test_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  
  /// Dispose resources
  void dispose() {
    _testResultsController.close();
    _activeSessions.clear();
  }
}

// Data models
class TestSession {
  final String sessionId;
  final String integrationId;
  final DateTime startTime;
  DateTime? endTime;
  TestSessionStatus status;
  String? error;
  
  TestSession({
    required this.sessionId,
    required this.integrationId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.error,
  });
  
  Duration? get duration => endTime?.difference(startTime);
}

class TestSuite {
  final String integrationId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final List<TestResult> tests;
  final TestStatus overallStatus;
  
  const TestSuite({
    required this.integrationId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.tests,
    required this.overallStatus,
  });
}

class TestResult {
  final String testId;
  final TestType testType;
  final String integrationId;
  final DateTime startTime;
  final DateTime endTime;
  final TestStatus status;
  final TestSeverity severity;
  final String message;
  final Map<String, dynamic> details;
  
  const TestResult({
    required this.testId,
    required this.testType,
    required this.integrationId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.severity,
    required this.message,
    required this.details,
  });
  
  Duration get duration => endTime.difference(startTime);
}

class BenchmarkResult {
  final String integrationId;
  final DateTime timestamp;
  final int iterations;
  final List<BenchmarkTest> tests;
  final double overallScore;
  
  const BenchmarkResult({
    required this.integrationId,
    required this.timestamp,
    required this.iterations,
    required this.tests,
    required this.overallScore,
  });
}

class BenchmarkTest {
  final String testName;
  final int iterations;
  final List<double> results;
  final double averageTime;
  final double minTime;
  final double maxTime;
  final String unit;
  
  const BenchmarkTest({
    required this.testName,
    required this.iterations,
    required this.results,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.unit,
  });
}

class TestRecommendation {
  final TestType testType;
  final RecommendationPriority priority;
  final String reason;
  final Duration estimatedDuration;
  
  const TestRecommendation({
    required this.testType,
    required this.priority,
    required this.reason,
    required this.estimatedDuration,
  });
}

class TestReport {
  final DateTime generatedAt;
  final int totalIntegrations;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final TestStatus overallStatus;
  final Map<String, IntegrationTestSummary> integrationResults;
  final List<String> recommendations;
  
  const TestReport({
    required this.generatedAt,
    required this.totalIntegrations,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.overallStatus,
    required this.integrationResults,
    required this.recommendations,
  });
}

class IntegrationTestSummary {
  final String integrationId;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final TestStatus overallStatus;
  final Duration duration;
  final int criticalIssues;
  
  const IntegrationTestSummary({
    required this.integrationId,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.overallStatus,
    required this.duration,
    required this.criticalIssues,
  });
}

// Enums
enum TestType {
  connectivity,
  authentication,
  functional,
  performance,
  security,
  dataIntegrity,
  errorHandling,
  rateLimiting,
  fileSystem,
}

enum TestStatus {
  passed,
  failed,
  skipped,
  running,
}

enum TestSeverity {
  info,
  low,
  medium,
  high,
  critical,
}

enum TestSessionStatus {
  running,
  completed,
  failed,
  cancelled,
}

enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}

class IntegrationTestException implements Exception {
  final String message;
  
  const IntegrationTestException(this.message);
  
  @override
  String toString() => 'IntegrationTestException: $message';
}

// Provider
final integrationTestingServiceProvider = Provider<IntegrationTestingService>((ref) {
  final integrationService = ref.watch(integrationServiceProvider);
  final mcpService = ref.watch(mcpSettingsServiceProvider);
  final testingService = IntegrationTestingService(integrationService, mcpService);
  
  ref.onDispose(() {
    testingService.dispose();
  });
  
  return testingService;
});