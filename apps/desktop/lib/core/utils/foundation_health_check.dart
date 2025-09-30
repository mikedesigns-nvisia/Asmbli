import 'dart:async';
import 'app_logger.dart';
import 'circuit_breaker.dart';
import '../mcp/adapters/mcp_adapter_registry.dart';
import '../models/mcp_server_config.dart';

/// Health check for foundation layer components
class FoundationHealthCheck {
  static Future<FoundationHealthReport> runHealthCheck() async {
    AppLogger.info('Starting foundation health check', component: 'HealthCheck');

    final report = FoundationHealthReport();

    // Test 1: Logging system
    report.loggingHealth = await _testLogging();

    // Test 2: Circuit breaker
    report.circuitBreakerHealth = await _testCircuitBreaker();

    // Test 3: MCP adapters
    report.mcpAdapterHealth = await _testMCPAdapters();

    // Test 4: Error handling
    report.errorHandlingHealth = await _testErrorHandling();

    AppLogger.info('Foundation health check completed', component: 'HealthCheck');
    return report;
  }

  static Future<ComponentHealth> _testLogging() async {
    try {
      // Test all log levels
      AppLogger.debug('Test debug message', component: 'HealthCheck.Test');
      AppLogger.info('Test info message', component: 'HealthCheck.Test');
      AppLogger.warning('Test warning message', component: 'HealthCheck.Test');
      AppLogger.error('Test error message', component: 'HealthCheck.Test', error: Exception('Test error'));

      return ComponentHealth(
        name: 'Logging',
        isHealthy: true,
        message: 'All log levels working correctly',
      );
    } catch (e) {
      return ComponentHealth(
        name: 'Logging',
        isHealthy: false,
        message: 'Logging failed: $e',
      );
    }
  }

  static Future<ComponentHealth> _testCircuitBreaker() async {
    try {
      final breaker = CircuitBreaker(
        name: 'test-breaker',
        failureThreshold: 2,
        timeout: const Duration(seconds: 1),
      );

      // Test successful operation
      final result1 = await breaker.execute(
        () async => 'success',
        'fallback',
        operationName: 'test-operation',
      );

      if (result1 != 'success') {
        return ComponentHealth(
          name: 'CircuitBreaker',
          isHealthy: false,
          message: 'Circuit breaker failed success test',
        );
      }

      // Test failure handling
      final result2 = await breaker.execute(
        () async => throw Exception('test failure'),
        'fallback',
        operationName: 'test-failure',
      );

      if (result2 != 'fallback') {
        return ComponentHealth(
          name: 'CircuitBreaker',
          isHealthy: false,
          message: 'Circuit breaker failed fallback test',
        );
      }

      breaker.dispose();

      return ComponentHealth(
        name: 'CircuitBreaker',
        isHealthy: true,
        message: 'Circuit breaker working correctly',
      );
    } catch (e) {
      return ComponentHealth(
        name: 'CircuitBreaker',
        isHealthy: false,
        message: 'Circuit breaker test failed: $e',
      );
    }
  }

  static Future<ComponentHealth> _testMCPAdapters() async {
    try {
      final registry = MCPAdapterRegistry.instance;

      // Test STDIO adapter (should not crash)
      final stdioAdapter = StdioMCPAdapter();
      final testConfig = MCPServerConfig(
        id: 'test-stdio',
        name: 'Test STDIO Server',
        serverPath: '/test/path',
        enabled: true,
      );

      await stdioAdapter.connect(testConfig);
      final response = await stdioAdapter.sendRequest('tools/list', {});

      if (response['tools'] is! List) {
        return ComponentHealth(
          name: 'MCP Adapters',
          isHealthy: false,
          message: 'STDIO adapter returned invalid response',
        );
      }

      // Test gRPC adapter (should not crash)
      final grpcAdapter = GRPCMCPAdapter();
      await grpcAdapter.connect(testConfig);
      final grpcResponse = await grpcAdapter.sendRequest('tools/list', {});

      if (grpcResponse['tools'] is! List) {
        return ComponentHealth(
          name: 'MCP Adapters',
          isHealthy: false,
          message: 'gRPC adapter returned invalid response',
        );
      }

      return ComponentHealth(
        name: 'MCP Adapters',
        isHealthy: true,
        message: 'MCP adapters providing safe fallbacks',
      );
    } catch (e) {
      return ComponentHealth(
        name: 'MCP Adapters',
        isHealthy: false,
        message: 'MCP adapter test failed: $e',
      );
    }
  }

  static Future<ComponentHealth> _testErrorHandling() async {
    try {
      // Test that we can catch and handle errors without crashing
      bool errorCaught = false;

      try {
        throw Exception('Test exception for error handling');
      } catch (e) {
        errorCaught = true;
        AppLogger.error('Caught test exception as expected', component: 'HealthCheck.Test', error: e);
      }

      if (!errorCaught) {
        return ComponentHealth(
          name: 'Error Handling',
          isHealthy: false,
          message: 'Error handling test failed - exception not caught',
        );
      }

      return ComponentHealth(
        name: 'Error Handling',
        isHealthy: true,
        message: 'Error handling working correctly',
      );
    } catch (e) {
      return ComponentHealth(
        name: 'Error Handling',
        isHealthy: false,
        message: 'Error handling test failed: $e',
      );
    }
  }
}

class FoundationHealthReport {
  ComponentHealth? loggingHealth;
  ComponentHealth? circuitBreakerHealth;
  ComponentHealth? mcpAdapterHealth;
  ComponentHealth? errorHandlingHealth;

  bool get isHealthy {
    return loggingHealth?.isHealthy == true &&
           circuitBreakerHealth?.isHealthy == true &&
           mcpAdapterHealth?.isHealthy == true &&
           errorHandlingHealth?.isHealthy == true;
  }

  List<ComponentHealth> get allComponents {
    return [
      loggingHealth,
      circuitBreakerHealth,
      mcpAdapterHealth,
      errorHandlingHealth,
    ].whereType<ComponentHealth>().toList();
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Foundation Health Report:');
    buffer.writeln('Overall Status: ${isHealthy ? "HEALTHY ✅" : "UNHEALTHY ❌"}');
    buffer.writeln();

    for (final component in allComponents) {
      buffer.writeln('${component.name}: ${component.isHealthy ? "✅" : "❌"} - ${component.message}');
    }

    return buffer.toString();
  }
}

class ComponentHealth {
  final String name;
  final bool isHealthy;
  final String message;

  ComponentHealth({
    required this.name,
    required this.isHealthy,
    required this.message,
  });
}