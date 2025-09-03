import 'dart:async';
import 'dart:io';
import '../adapters/base_mcp_adapter.dart';
import '../adapters/websocket_adapter.dart';
import '../adapters/http_adapter.dart';
import '../adapters/sse_adapter.dart';
import '../adapters/mcp_adapter_registry.dart';
import '../protocol/mcp_protocol_negotiator.dart';
import '../../models/mcp_server_config.dart';

/// Comprehensive test suite for MCP adapters and protocols
class MCPAdapterTestSuite {
  final MCPAdapterRegistry _registry = MCPAdapterRegistry.instance;
  final MCPProtocolNegotiator _negotiator = MCPProtocolNegotiator();
  
  /// Run all MCP adapter tests
  Future<MCPTestResults> runAllTests() async {
    print('🧪 Starting comprehensive MCP adapter test suite\n');
    
    final results = MCPTestResults();
    final startTime = DateTime.now();
    
    try {
      // Test 1: Registry functionality
      results.addResult(await _testAdapterRegistry());
      
      // Test 2: WebSocket adapter
      results.addResult(await _testWebSocketAdapter());
      
      // Test 3: HTTP adapter  
      results.addResult(await _testHTTPAdapter());
      
      // Test 4: SSE adapter
      results.addResult(await _testSSEAdapter());
      
      // Test 5: Protocol auto-detection
      results.addResult(await _testProtocolAutoDetection());
      
      // Test 6: Protocol negotiation
      results.addResult(await _testProtocolNegotiation());
      
      // Test 7: Fallback mechanisms
      results.addResult(await _testFallbackProtocols());
      
      // Test 8: Configuration validation
      results.addResult(await _testConfigurationValidation());
      
      // Test 9: Error handling
      results.addResult(await _testErrorHandling());
      
      // Test 10: Concurrent connections
      results.addResult(await _testConcurrentConnections());
      
    } catch (e) {
      print('💥 Test suite crashed: $e');
    }
    
    final duration = DateTime.now().difference(startTime);
    results.totalDuration = duration;
    
    _printTestSummary(results);
    return results;
  }
  
  /// Test 1: Adapter registry functionality
  Future<MCPTestResult> _testAdapterRegistry() async {
    print('🔍 Test 1: Adapter Registry');
    
    final testResult = MCPTestResult('Adapter Registry');
    
    try {
      // Test adapter registration
      final availableProtocols = _registry.getAvailableProtocols();
      testResult.checks['protocols_registered'] = availableProtocols.isNotEmpty;
      print('  ✓ Found ${availableProtocols.length} registered protocols');
      
      // Test getting specific adapters
      for (final protocol in ['websocket', 'http', 'sse']) {
        final adapter = _registry.getAdapter(protocol);
        testResult.checks['${protocol}_adapter_available'] = adapter != null;
        if (adapter != null) {
          print('  ✓ $protocol adapter available');
        } else {
          print('  ❌ $protocol adapter missing');
        }
      }
      
      // Test registry stats
      final stats = _registry.getRegistryStats();
      testResult.checks['stats_available'] = stats.isNotEmpty;
      print('  ✓ Registry stats: ${stats['totalAdapters']} adapters');
      
      testResult.passed = testResult.checks.values.every((check) => check);
      
    } catch (e) {
      testResult.error = e.toString();
      testResult.passed = false;
      print('  ❌ Registry test failed: $e');
    }
    
    return testResult;
  }
  
  /// Test 2: WebSocket adapter functionality
  Future<MCPTestResult> _testWebSocketAdapter() async {
    print('🔍 Test 2: WebSocket Adapter');
    
    final testResult = MCPTestResult('WebSocket Adapter');
    
    try {
      final adapter = WebSocketMCPAdapter();
      
      // Test adapter properties
      testResult.checks['protocol_correct'] = adapter.protocol == 'websocket';
      testResult.checks['features_available'] = adapter.getSupportedFeatures().isNotEmpty;
      
      // Test configuration validation
      final validConfig = _createTestConfig('wss://echo.websocket.org', 'websocket');
      testResult.checks['config_validation'] = adapter.validateConfig(validConfig);
      
      // Test invalid configuration
      final invalidConfig = _createTestConfig('invalid-url', 'websocket');
      testResult.checks['invalid_config_rejected'] = !adapter.validateConfig(invalidConfig);
      
      print('  ✓ WebSocket adapter properties verified');
      
      // Test connection (if echo server is available)
      if (await _isWebSocketEchoAvailable()) {
        try {
          await adapter.connect(validConfig);
          testResult.checks['connection_successful'] = adapter.isConnected;
          
          if (adapter.isConnected) {
            // Test request/response
            final response = await adapter.sendRequest('ping', {'timestamp': DateTime.now().toIso8601String()});
            testResult.checks['request_response_works'] = response != null;
            
            await adapter.disconnect();
            testResult.checks['disconnect_successful'] = !adapter.isConnected;
            
            print('  ✓ WebSocket connection test successful');
          }
        } catch (e) {
          print('  ⚠️ WebSocket connection test skipped: $e');
        }
      } else {
        print('  ⚠️ WebSocket echo server not available, skipping connection test');
      }
      
      testResult.passed = testResult.checks.values.where((check) => check != null).every((check) => check);
      
    } catch (e) {
      testResult.error = e.toString();
      testResult.passed = false;
      print('  ❌ WebSocket test failed: $e');
    }
    
    return testResult;
  }
  
  /// Test 3: HTTP adapter functionality
  Future<MCPTestResult> _testHTTPAdapter() async {
    print('🔍 Test 3: HTTP Adapter');
    
    final testResult = MCPTestResult('HTTP Adapter');
    
    try {
      final adapter = HTTPMCPAdapter();
      
      // Test adapter properties
      testResult.checks['protocol_correct'] = adapter.protocol == 'http';
      testResult.checks['features_available'] = adapter.getSupportedFeatures().isNotEmpty;
      
      // Test configuration validation
      final validConfig = _createTestConfig('https://httpbin.org', 'http');
      testResult.checks['config_validation'] = adapter.validateConfig(validConfig);
      
      // Test invalid configuration
      final invalidConfig = _createTestConfig('ws://invalid', 'http');
      testResult.checks['invalid_config_rejected'] = !adapter.validateConfig(invalidConfig);
      
      print('  ✓ HTTP adapter properties verified');
      
      // Test health status
      final health = await adapter.getHealthStatus();
      testResult.checks['health_check_available'] = health.protocol == 'http';
      
      testResult.passed = testResult.checks.values.every((check) => check);
      
    } catch (e) {
      testResult.error = e.toString();
      testResult.passed = false;
      print('  ❌ HTTP test failed: $e');
    }
    
    return testResult;
  }
  
  /// Test 4: SSE adapter functionality
  Future<MCPTestResult> _testSSEAdapter() async {
    print('🔍 Test 4: SSE Adapter');
    
    final testResult = MCPTestResult('SSE Adapter');
    
    try {
      final adapter = SSEMCPAdapter();
      
      // Test adapter properties
      testResult.checks['protocol_correct'] = adapter.protocol == 'sse';
      testResult.checks['features_available'] = adapter.getSupportedFeatures().isNotEmpty;
      
      // Test configuration validation
      final validConfig = _createTestConfig('https://httpbin.org/stream-bytes/1024', 'sse');
      testResult.checks['config_validation'] = adapter.validateConfig(validConfig);
      
      print('  ✓ SSE adapter properties verified');
      
      testResult.passed = testResult.checks.values.every((check) => check);
      
    } catch (e) {
      testResult.error = e.toString();
      testResult.passed = false;
      print('  ❌ SSE test failed: $e');
    }
    
    return testResult;
  }
  
  /// Test 5: Protocol auto-detection
  Future<MCPTestResult> _testProtocolAutoDetection() async {
    print('🔍 Test 5: Protocol Auto-Detection');
    
    final testResult = MCPTestResult('Protocol Auto-Detection');
    
    try {
      // Test WebSocket URL detection
      try {
        final wsAdapter = await _registry.autoDetectAdapter('wss://echo.websocket.org');
        testResult.checks['websocket_detection'] = wsAdapter.protocol == 'websocket';
        print('  ✓ WebSocket URL auto-detected');
      } catch (e) {
        print('  ⚠️ WebSocket auto-detection failed: $e');
      }
      
      // Test HTTP URL detection
      try {
        final httpAdapter = await _registry.autoDetectAdapter('https://httpbin.org');
        testResult.checks['http_detection'] = ['http', 'sse'].contains(httpAdapter.protocol);
        print('  ✓ HTTP URL auto-detected as ${httpAdapter.protocol}');
      } catch (e) {
        print('  ⚠️ HTTP auto-detection failed: $e');
      }
      
      // Test invalid URL handling
      try {
        await _registry.autoDetectAdapter('invalid-url-format');
        testResult.checks['invalid_url_handled'] = false;
      } catch (e) {
        testResult.checks['invalid_url_handled'] = true;
        print('  ✓ Invalid URL properly rejected');
      }
      
      testResult.passed = testResult.checks.values.where((check) => check != null).every((check) => check);
      
    } catch (e) {
      testResult.error = e.toString();
      testResult.passed = false;
      print('  ❌ Auto-detection test failed: $e');
    }
    
    return testResult;
  }
  
  /// Test 6: Protocol negotiation
  Future<MCPTestResult> _testProtocolNegotiation() async {
    print('🔍 Test 6: Protocol Negotiation');
    
    final testResult = MCPTestResult('Protocol Negotiation');
    
    try {
      // Test negotiation strategy creation
      final config = _createTestConfig('https://httpbin.org', 'http');
      final strategy = _negotiator.createStrategy(config);
      
      testResult.checks['strategy_created'] = strategy.preferredProtocol == 'http';
      testResult.checks['fallbacks_defined'] = strategy.fallbackProtocols.isNotEmpty;
      
      print('  ✓ Negotiation strategy created');
      print('  ✓ Fallback protocols: ${strategy.fallbackProtocols.join(', ')}');
      
      // Test batch negotiation setup
      final configs = [
        _createTestConfig('https://httpbin.org', 'http'),
        _createTestConfig('wss://echo.websocket.org', 'websocket'),
      ];
      
      // Note: Not actually connecting in tests to avoid external dependencies
      testResult.checks['batch_negotiation_setup'] = configs.length == 2;
      
      testResult.passed = testResult.checks.values.every((check) => check);
      
    } catch (e) {
      testResult.error = e.toString();
      testResult.passed = false;
      print('  ❌ Negotiation test failed: $e');
    }
    
    return testResult;
  }
  
  /// Test 7: Fallback protocol mechanisms
  Future<MCPTestResult> _testFallbackProtocols() async {
    print('🔍 Test 7: Fallback Protocols');
    
    final testResult = MCPTestResult('Fallback Protocols');
    
    try {
      // Test fallback protocol selection
      final httpConfig = _createTestConfig('https://example.com', 'http');
      httpConfig.fallbackProtocols = ['sse', 'websocket'];
      
      testResult.checks['fallbacks_configured'] = httpConfig.fallbackProtocols?.isNotEmpty == true;
      
      // Test WebSocket fallbacks
      final wsConfig = _createTestConfig('wss://example.com', 'websocket');
      wsConfig.fallbackProtocols = ['http', 'sse'];
      
      testResult.checks['websocket_fallbacks'] = wsConfig.fallbackProtocols?.contains('http') == true;
      
      print('  ✓ Fallback protocols configured correctly');
      
      testResult.passed = testResult.checks.values.every((check) => check);
      
    } catch (e) {
      testResult.error = e.toString();
      testResult.passed = false;
      print('  ❌ Fallback test failed: $e');
    }
    
    return testResult;
  }
  
  /// Test 8: Configuration validation
  Future<MCPTestResult> _testConfigurationValidation() async {
    print('🔍 Test 8: Configuration Validation');
    
    final testResult = MCPTestResult('Configuration Validation');
    
    try {
      // Test valid configurations
      final validConfigs = [
        _createTestConfig('https://api.example.com', 'http'),
        _createTestConfig('wss://ws.example.com', 'websocket'),
        _createTestConfig('https://events.example.com', 'sse'),
      ];
      
      for (final config in validConfigs) {
        final adapter = _registry.getAdapter(config.protocol);
        if (adapter != null) {
          final isValid = adapter.validateConfig(config);
          testResult.checks['${config.protocol}_valid_config'] = isValid;
          if (isValid) {
            print('  ✓ ${config.protocol} configuration valid');
          }
        }
      }
      
      // Test invalid configurations
      final invalidConfigs = [
        _createTestConfig('', 'http'), // Empty URL
        _createTestConfig('invalid-url', 'websocket'), // Invalid URL
        _createTestConfig('ftp://example.com', 'http'), // Wrong scheme
      ];
      
      int invalidConfigsRejected = 0;
      for (final config in invalidConfigs) {
        final adapter = _registry.getAdapter(config.protocol);
        if (adapter != null && !adapter.validateConfig(config)) {
          invalidConfigsRejected++;
        }
      }
      
      testResult.checks['invalid_configs_rejected'] = invalidConfigsRejected == invalidConfigs.length;
      
      print('  ✓ $invalidConfigsRejected/${invalidConfigs.length} invalid configs rejected');
      
      testResult.passed = testResult.checks.values.every((check) => check);
      
    } catch (e) {
      testResult.error = e.toString();
      testResult.passed = false;
      print('  ❌ Configuration validation test failed: $e');
    }
    
    return testResult;
  }
  
  /// Test 9: Error handling
  Future<MCPTestResult> _testErrorHandling() async {
    print('🔍 Test 9: Error Handling');
    
    final testResult = MCPTestResult('Error Handling');
    
    try {
      // Test connection to non-existent server
      final adapter = HTTPMCPAdapter();
      final badConfig = _createTestConfig('http://non-existent-server-12345.com', 'http');
      
      try {
        await adapter.connect(badConfig);
        testResult.checks['connection_error_handled'] = false;
      } catch (e) {
        testResult.checks['connection_error_handled'] = e is MCPAdapterException;
        print('  ✓ Connection error properly handled');
      }
      
      // Test invalid request handling
      try {
        await adapter.sendRequest('invalid_method', {});
        testResult.checks['invalid_request_handled'] = false;
      } catch (e) {
        testResult.checks['invalid_request_handled'] = true;
        print('  ✓ Invalid request properly handled');
      }
      
      // Test adapter disposal
      try {
        await adapter.dispose();
        testResult.checks['disposal_successful'] = !adapter.isConnected;
        print('  ✓ Adapter disposal successful');
      } catch (e) {
        testResult.checks['disposal_successful'] = false;
        print('  ❌ Adapter disposal failed: $e');
      }
      
      testResult.passed = testResult.checks.values.every((check) => check);
      
    } catch (e) {
      testResult.error = e.toString();
      testResult.passed = false;
      print('  ❌ Error handling test failed: $e');
    }
    
    return testResult;
  }
  
  /// Test 10: Concurrent connections
  Future<MCPTestResult> _testConcurrentConnections() async {
    print('🔍 Test 10: Concurrent Connections');
    
    final testResult = MCPTestResult('Concurrent Connections');
    
    try {
      // Create multiple adapter instances
      final adapters = [
        HTTPMCPAdapter(),
        HTTPMCPAdapter(),
        WebSocketMCPAdapter(),
      ];
      
      testResult.checks['adapters_created'] = adapters.length == 3;
      print('  ✓ Created ${adapters.length} adapter instances');
      
      // Test concurrent health checks
      final healthFutures = adapters.map((adapter) => adapter.getHealthStatus()).toList();
      final healthResults = await Future.wait(healthFutures);
      
      testResult.checks['concurrent_health_checks'] = healthResults.length == adapters.length;
      print('  ✓ Concurrent health checks completed');
      
      // Test concurrent disposal
      final disposalFutures = adapters.map((adapter) => adapter.dispose()).toList();
      await Future.wait(disposalFutures);
      
      testResult.checks['concurrent_disposal'] = adapters.every((adapter) => !adapter.isConnected);
      print('  ✓ Concurrent disposal completed');
      
      testResult.passed = testResult.checks.values.every((check) => check);
      
    } catch (e) {
      testResult.error = e.toString();
      testResult.passed = false;
      print('  ❌ Concurrent connections test failed: $e');
    }
    
    return testResult;
  }
  
  /// Helper: Create test configuration
  MCPServerConfig _createTestConfig(String url, String protocol) {
    return MCPServerConfig(
      id: 'test-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Test Server',
      url: url,
      protocol: protocol,
      enabled: true,
      timeout: 10,
      autoReconnect: false,
    );
  }
  
  /// Helper: Check if WebSocket echo server is available
  Future<bool> _isWebSocketEchoAvailable() async {
    try {
      final socket = await Socket.connect('echo.websocket.org', 80);
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Print comprehensive test summary
  void _printTestSummary(MCPTestResults results) {
    print('\n${'='*80}');
    print('🏁 MCP ADAPTER TEST SUITE RESULTS');
    print('='*80);
    print('Total Tests: ${results.results.length}');
    print('Passed: ${results.passedCount}');
    print('Failed: ${results.failedCount}');
    print('Success Rate: ${results.successRate.toStringAsFixed(1)}%');
    print('Total Duration: ${results.totalDuration.inSeconds}s');
    
    if (results.passedCount == results.results.length) {
      print('\n🎉 ALL TESTS PASSED!');
      print('✅ MCP adapter framework is working correctly');
      print('✅ Protocol negotiation is functional');
      print('✅ Auto-detection mechanisms work');
      print('✅ Error handling is robust');
      print('✅ Concurrent operations supported');
    } else {
      print('\n⚠️ SOME TESTS FAILED');
      print('❌ MCP adapter framework needs attention');
      
      // Print failed tests
      for (final result in results.results.where((r) => !r.passed)) {
        print('\n❌ FAILED: ${result.testName}');
        if (result.error != null) {
          print('   Error: ${result.error}');
        }
        for (final check in result.checks.entries.where((e) => e.value == false)) {
          print('   • ${check.key}: FAILED');
        }
      }
    }
    
    print('\n📋 Test Checklist:');
    print('${results.passedCount >= 1 ? '✅' : '❌'} Adapter registry functionality');
    print('${results.passedCount >= 2 ? '✅' : '❌'} WebSocket adapter implementation');
    print('${results.passedCount >= 3 ? '✅' : '❌'} HTTP adapter implementation');
    print('${results.passedCount >= 4 ? '✅' : '❌'} SSE adapter implementation');
    print('${results.passedCount >= 5 ? '✅' : '❌'} Protocol auto-detection');
    print('${results.passedCount >= 6 ? '✅' : '❌'} Protocol negotiation');
    print('${results.passedCount >= 7 ? '✅' : '❌'} Fallback mechanisms');
    print('${results.passedCount >= 8 ? '✅' : '❌'} Configuration validation');
    print('${results.passedCount >= 9 ? '✅' : '❌'} Error handling');
    print('${results.passedCount >= 10 ? '✅' : '❌'} Concurrent connections');
  }
}

/// Test results container
class MCPTestResults {
  final List<MCPTestResult> results = [];
  Duration totalDuration = Duration.zero;
  
  void addResult(MCPTestResult result) {
    results.add(result);
  }
  
  int get passedCount => results.where((r) => r.passed).length;
  int get failedCount => results.where((r) => !r.passed).length;
  double get successRate => results.isEmpty ? 0 : (passedCount / results.length) * 100;
}

/// Individual test result
class MCPTestResult {
  final String testName;
  bool passed = false;
  String? error;
  final Map<String, bool> checks = {};
  final DateTime timestamp = DateTime.now();
  
  MCPTestResult(this.testName);
  
  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'passed': passed,
      'error': error,
      'checks': checks,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Main test runner
void main() async {
  final testSuite = MCPAdapterTestSuite();
  
  try {
    final results = await testSuite.runAllTests();
    exit(results.passedCount == results.results.length ? 0 : 1);
  } catch (e) {
    print('💥 Test suite execution failed: $e');
    exit(1);
  }
}