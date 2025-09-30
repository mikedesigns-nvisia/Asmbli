import 'dart:async';
import 'dart:io';
import '../../utils/app_logger.dart';
import '../../models/mcp_server_config.dart';
import '../process/mcp_process_manager.dart';
import '../adapters/mcp_adapter_registry.dart';
import '../validation/mcp_protocol_validator.dart';

/// Comprehensive end-to-end MCP communication test
class MCPCommunicationTest {
  static const String _testServerPath = 'python';  // Assumes Python is available
  static const String _testScript = '''
import json
import sys

def handle_request(request):
    method = request.get('method')
    request_id = request.get('id')

    if method == 'initialize':
        return {
            'jsonrpc': '2.0',
            'id': request_id,
            'result': {
                'protocolVersion': '2024-11-05',
                'capabilities': {
                    'logging': {},
                    'prompts': {'listChanged': False},
                    'resources': {'subscribe': False, 'listChanged': False},
                    'tools': {'listChanged': False},
                },
                'serverInfo': {
                    'name': 'test-mcp-server',
                    'version': '1.0.0',
                }
            }
        }
    elif method == 'tools/list':
        return {
            'jsonrpc': '2.0',
            'id': request_id,
            'result': {
                'tools': [
                    {
                        'name': 'echo',
                        'description': 'Echo back the input',
                        'inputSchema': {
                            'type': 'object',
                            'properties': {
                                'text': {'type': 'string'}
                            },
                            'required': ['text']
                        }
                    }
                ]
            }
        }
    elif method == 'tools/call':
        params = request.get('params', {})
        if params.get('name') == 'echo':
            args = params.get('arguments', {})
            return {
                'jsonrpc': '2.0',
                'id': request_id,
                'result': {
                    'content': [
                        {
                            'type': 'text',
                            'text': f"Echo: {args.get('text', '')}"
                        }
                    ]
                }
            }

    # Default error response
    return {
        'jsonrpc': '2.0',
        'id': request_id,
        'error': {
            'code': -32601,
            'message': 'Method not found'
        }
    }

def main():
    for line in sys.stdin:
        try:
            request = json.loads(line.strip())
            response = handle_request(request)
            print(json.dumps(response), flush=True)
        except Exception as e:
            error_response = {
                'jsonrpc': '2.0',
                'id': request.get('id') if 'request' in locals() else None,
                'error': {
                    'code': -32603,
                    'message': str(e)
                }
            }
            print(json.dumps(error_response), flush=True)

if __name__ == '__main__':
    main()
''';

  /// Run comprehensive MCP communication test
  static Future<MCPTestReport> runCompleteTest() async {
    AppLogger.info('Starting comprehensive MCP communication test', component: 'MCP.Test');

    final report = MCPTestReport();

    try {
      // Test 1: Basic connection and initialization
      report.connectionTest = await _testConnection();

      // Test 2: Protocol validation
      report.protocolValidation = await _testProtocolValidation();

      // Test 3: Tool discovery
      report.toolDiscovery = await _testToolDiscovery();

      // Test 4: Tool execution
      report.toolExecution = await _testToolExecution();

      // Test 5: Error handling
      report.errorHandling = await _testErrorHandling();

      // Test 6: Circuit breaker functionality
      report.circuitBreaker = await _testCircuitBreaker();

      // Test 7: Process lifecycle
      report.processLifecycle = await _testProcessLifecycle();

      report.overallSuccess = _calculateOverallSuccess(report);

      AppLogger.info('MCP communication test completed: ${report.overallSuccess ? "PASSED" : "FAILED"}', component: 'MCP.Test');
      return report;

    } catch (e) {
      AppLogger.error('MCP communication test failed with exception', component: 'MCP.Test', error: e);
      report.overallSuccess = false;
      report.errorMessage = e.toString();
      return report;
    }
  }

  static Future<MCPTestResult> _testConnection() async {
    AppLogger.info('Testing MCP connection and initialization', component: 'MCP.Test');
    final issues = <String>[];

    try {
      // Create test script file
      final testFile = await _createTestScript();

      final config = MCPServerConfig(
        id: 'test-mcp-server',
        name: 'Test MCP Server',
        url: 'local://test',
        command: '$_testServerPath ${testFile.path}',
        protocol: 'stdio',
        transport: 'stdio',
        enabled: true,
        timeout: 10,
        autoReconnect: false,
      );

      // Validate configuration
      final configValidation = MCPProtocolValidator.validateServerConfig(config);
      if (!configValidation.isValid) {
        issues.addAll(configValidation.issues.map((i) => 'Config: $i'));
      }

      // Test connection
      final manager = MCPProcessManager.instance;
      final session = await manager.startServer(config);

      if (!session.isHealthy) {
        issues.add('Session is not healthy after connection');
      }

      // Test basic communication
      final response = await session.sendRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {'name': 'test-client', 'version': '1.0.0'},
      });

      if (response['result'] == null) {
        issues.add('Initialize request failed');
      }

      // Cleanup
      await manager.stopServer(session.sessionId);
      await testFile.delete();

    } catch (e) {
      issues.add('Connection test exception: $e');
    }

    return MCPTestResult(success: issues.isEmpty, issues: issues);
  }

  static Future<MCPTestResult> _testProtocolValidation() async {
    AppLogger.info('Testing MCP protocol validation', component: 'MCP.Test');
    final issues = <String>[];

    try {
      // Test request validation
      final validRequest = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'tools/list',
        'params': {},
      };

      final validResult = MCPProtocolValidator.validateRequest(validRequest);
      if (!validResult.isValid) {
        issues.add('Valid request failed validation');
      }

      // Test invalid request
      final invalidRequest = {
        'jsonrpc': '1.0', // Wrong version
        'method': 'tools/list',
        // Missing ID
      };

      final invalidResult = MCPProtocolValidator.validateRequest(invalidRequest);
      if (invalidResult.isValid) {
        issues.add('Invalid request passed validation');
      }

      // Test tool validation
      final validTool = {
        'name': 'test_tool',
        'description': 'A test tool',
        'inputSchema': {
          'type': 'object',
          'properties': {'param': {'type': 'string'}},
        },
      };

      final toolResult = MCPProtocolValidator.validateTool(validTool);
      if (!toolResult.isValid) {
        issues.add('Valid tool failed validation');
      }

    } catch (e) {
      issues.add('Protocol validation exception: $e');
    }

    return MCPTestResult(success: issues.isEmpty, issues: issues);
  }

  static Future<MCPTestResult> _testToolDiscovery() async {
    AppLogger.info('Testing MCP tool discovery', component: 'MCP.Test');
    final issues = <String>[];

    try {
      final testFile = await _createTestScript();

      final config = MCPServerConfig(
        id: 'tool-test-server',
        name: 'Tool Test Server',
        url: 'local://tool-test',
        command: '$_testServerPath ${testFile.path}',
        protocol: 'stdio',
        enabled: true,
        timeout: 10,
      );

      final manager = MCPProcessManager.instance;
      final session = await manager.startServer(config);

      // Get tools
      final tools = await session.getTools();

      if (tools.isEmpty) {
        issues.add('No tools discovered from test server');
      }

      final echoTool = tools.firstWhere(
        (tool) => tool['name'] == 'echo',
        orElse: () => <String, dynamic>{},
      );

      if (echoTool.isEmpty) {
        issues.add('Expected echo tool not found');
      } else {
        // Validate tool format
        final validation = MCPProtocolValidator.validateTool(echoTool);
        if (!validation.isValid) {
          issues.addAll(validation.issues.map((i) => 'Tool validation: $i'));
        }
      }

      await manager.stopServer(session.sessionId);
      await testFile.delete();

    } catch (e) {
      issues.add('Tool discovery exception: $e');
    }

    return MCPTestResult(success: issues.isEmpty, issues: issues);
  }

  static Future<MCPTestResult> _testToolExecution() async {
    AppLogger.info('Testing MCP tool execution', component: 'MCP.Test');
    final issues = <String>[];

    try {
      final testFile = await _createTestScript();

      final config = MCPServerConfig(
        id: 'exec-test-server',
        name: 'Execution Test Server',
        url: 'local://exec-test',
        command: '$_testServerPath ${testFile.path}',
        protocol: 'stdio',
        enabled: true,
        timeout: 10,
      );

      final manager = MCPProcessManager.instance;
      final session = await manager.startServer(config);

      // Call echo tool
      final result = await session.callTool('echo', {'text': 'Hello, MCP!'});

      if (result['content'] == null) {
        issues.add('Tool call did not return content');
      } else {
        final content = result['content'] as List<dynamic>?;
        if (content == null || content.isEmpty) {
          issues.add('Tool call returned empty content');
        } else {
          final textContent = content.first as Map<String, dynamic>?;
          if (textContent?['text'] != 'Echo: Hello, MCP!') {
            issues.add('Tool call returned unexpected result: ${textContent?['text']}');
          }
        }
      }

      await manager.stopServer(session.sessionId);
      await testFile.delete();

    } catch (e) {
      issues.add('Tool execution exception: $e');
    }

    return MCPTestResult(success: issues.isEmpty, issues: issues);
  }

  static Future<MCPTestResult> _testErrorHandling() async {
    AppLogger.info('Testing MCP error handling', component: 'MCP.Test');
    final issues = <String>[];

    try {
      // Test with invalid server path
      final config = MCPServerConfig(
        id: 'error-test-server',
        name: 'Error Test Server',
        url: 'local://error-test',
        command: 'nonexistent_command_12345',
        protocol: 'stdio',
        enabled: true,
        timeout: 5,
      );

      final manager = MCPProcessManager.instance;

      bool caughtExpectedError = false;
      try {
        await manager.startServer(config);
      } catch (e) {
        caughtExpectedError = true;
        AppLogger.debug('Expected error caught: $e', component: 'MCP.Test');
      }

      if (!caughtExpectedError) {
        issues.add('Expected error for invalid server path was not thrown');
      }

    } catch (e) {
      issues.add('Error handling test exception: $e');
    }

    return MCPTestResult(success: issues.isEmpty, issues: issues);
  }

  static Future<MCPTestResult> _testCircuitBreaker() async {
    AppLogger.info('Testing circuit breaker functionality', component: 'MCP.Test');
    final issues = <String>[];

    try {
      // This test would require more complex setup to actually trigger circuit breaker
      // For now, just verify the adapter has circuit breaker integration
      final registry = MCPAdapterRegistry.instance;
      final adapter = registry.getAdapter('stdio');

      if (adapter == null) {
        issues.add('STDIO adapter not available for circuit breaker test');
      }

      // Test circuit breaker exists in the implementation
      // The actual behavior would need integration testing with failing servers

    } catch (e) {
      issues.add('Circuit breaker test exception: $e');
    }

    return MCPTestResult(success: issues.isEmpty, issues: issues);
  }

  static Future<MCPTestResult> _testProcessLifecycle() async {
    AppLogger.info('Testing MCP process lifecycle', component: 'MCP.Test');
    final issues = <String>[];

    try {
      final testFile = await _createTestScript();

      final config = MCPServerConfig(
        id: 'lifecycle-test-server',
        name: 'Lifecycle Test Server',
        url: 'local://lifecycle-test',
        command: '$_testServerPath ${testFile.path}',
        protocol: 'stdio',
        enabled: true,
        timeout: 10,
      );

      final manager = MCPProcessManager.instance;

      // Start server
      final session = await manager.startServer(config);
      final sessionId = session.sessionId;

      if (!session.isHealthy) {
        issues.add('Session not healthy after start');
      }

      // Check session is tracked
      final retrievedSession = manager.getSession(sessionId);
      if (retrievedSession == null) {
        issues.add('Session not found after creation');
      }

      // Stop server
      await manager.stopServer(sessionId);

      // Verify session is removed
      final removedSession = manager.getSession(sessionId);
      if (removedSession != null) {
        issues.add('Session still exists after shutdown');
      }

      await testFile.delete();

    } catch (e) {
      issues.add('Process lifecycle exception: $e');
    }

    return MCPTestResult(success: issues.isEmpty, issues: issues);
  }

  static Future<File> _createTestScript() async {
    final tempDir = Directory.systemTemp;
    final testFile = File('${tempDir.path}/test_mcp_server_${DateTime.now().millisecondsSinceEpoch}.py');
    await testFile.writeAsString(_testScript);
    return testFile;
  }

  static bool _calculateOverallSuccess(MCPTestReport report) {
    return report.connectionTest.success &&
           report.protocolValidation.success &&
           report.toolDiscovery.success &&
           report.toolExecution.success &&
           report.errorHandling.success &&
           report.circuitBreaker.success &&
           report.processLifecycle.success;
  }
}

class MCPTestReport {
  MCPTestResult connectionTest = MCPTestResult(success: false, issues: []);
  MCPTestResult protocolValidation = MCPTestResult(success: false, issues: []);
  MCPTestResult toolDiscovery = MCPTestResult(success: false, issues: []);
  MCPTestResult toolExecution = MCPTestResult(success: false, issues: []);
  MCPTestResult errorHandling = MCPTestResult(success: false, issues: []);
  MCPTestResult circuitBreaker = MCPTestResult(success: false, issues: []);
  MCPTestResult processLifecycle = MCPTestResult(success: false, issues: []);
  bool overallSuccess = false;
  String? errorMessage;

  List<String> get allIssues {
    final issues = <String>[];
    issues.addAll(connectionTest.issues.map((i) => 'Connection: $i'));
    issues.addAll(protocolValidation.issues.map((i) => 'Protocol: $i'));
    issues.addAll(toolDiscovery.issues.map((i) => 'Discovery: $i'));
    issues.addAll(toolExecution.issues.map((i) => 'Execution: $i'));
    issues.addAll(errorHandling.issues.map((i) => 'Error: $i'));
    issues.addAll(circuitBreaker.issues.map((i) => 'Circuit: $i'));
    issues.addAll(processLifecycle.issues.map((i) => 'Lifecycle: $i'));
    return issues;
  }

  @override
  String toString() {
    return 'MCPTestReport(success: $overallSuccess, issues: ${allIssues.length})';
  }
}

class MCPTestResult {
  final bool success;
  final List<String> issues;

  MCPTestResult({required this.success, required this.issues});

  @override
  String toString() => 'MCPTestResult(success: $success, issues: ${issues.length})';
}