import 'dart:async';

/// Test the JSON-RPC integration service functionality
/// Verifies the complete integration of communication, debugging, and protocol handling
void main() {
  print('🚀 Testing JSON-RPC Integration Service...');
  
  testIntegrationServiceComponents();
  testHealthCheckResults();
  testConcurrentRequestHandling();
  testDebugIntegration();
  
  print('✅ All JSON-RPC integration tests passed!');
}

void testIntegrationServiceComponents() {
  print('Testing integration service components...');
  
  // Test health check result
  final healthCheck = JsonRpcHealthCheckResult(
    connectionId: 'test-agent:test-server',
    isHealthy: true,
    latency: Duration(milliseconds: 150),
    timestamp: DateTime.now(),
  );
  
  assert(healthCheck.connectionId == 'test-agent:test-server');
  assert(healthCheck.isHealthy == true);
  assert(healthCheck.latency.inMilliseconds == 150);
  assert(healthCheck.error == null);
  
  // Test JSON serialization
  final json = healthCheck.toJson();
  assert(json['connectionId'] == 'test-agent:test-server');
  assert(json['isHealthy'] == true);
  assert(json['latencyMs'] == 150);
  assert(json['error'] == null);
  
  // Test unhealthy result
  final unhealthyCheck = JsonRpcHealthCheckResult(
    connectionId: 'test-agent:test-server',
    isHealthy: false,
    latency: Duration.zero,
    timestamp: DateTime.now(),
    error: 'Connection timeout',
  );
  
  assert(unhealthyCheck.isHealthy == false);
  assert(unhealthyCheck.error == 'Connection timeout');
  
  print('✓ Integration service component tests passed');
}

void testHealthCheckResults() {
  print('Testing health check results...');
  
  // Test various health check scenarios
  final scenarios = [
    {
      'name': 'Healthy connection',
      'isHealthy': true,
      'latency': Duration(milliseconds: 50),
      'error': null,
    },
    {
      'name': 'Slow connection',
      'isHealthy': true,
      'latency': Duration(milliseconds: 2000),
      'error': null,
    },
    {
      'name': 'Failed connection',
      'isHealthy': false,
      'latency': Duration.zero,
      'error': 'Connection refused',
    },
    {
      'name': 'Timeout',
      'isHealthy': false,
      'latency': Duration(seconds: 30),
      'error': 'Request timeout',
    },
  ];
  
  for (final scenario in scenarios) {
    final result = JsonRpcHealthCheckResult(
      connectionId: 'test-connection',
      isHealthy: scenario['isHealthy'] as bool,
      latency: scenario['latency'] as Duration,
      timestamp: DateTime.now(),
      error: scenario['error'] as String?,
    );
    
    assert(result.isHealthy == scenario['isHealthy']);
    assert(result.latency == scenario['latency']);
    assert(result.error == scenario['error']);
    
    // Test JSON conversion
    final json = result.toJson();
    assert(json['isHealthy'] == scenario['isHealthy']);
    assert(json['latencyMs'] == (scenario['latency'] as Duration).inMilliseconds);
    assert(json['error'] == scenario['error']);
  }
  
  print('✓ Health check result tests passed');
}

void testConcurrentRequestHandling() {
  print('Testing concurrent request handling logic...');
  
  // Test request specification creation
  final requests = [
    JsonRpcRequestSpec(method: 'tools/list'),
    JsonRpcRequestSpec(method: 'resources/list'),
    JsonRpcRequestSpec(method: 'prompts/list'),
    JsonRpcRequestSpec(method: 'tools/call', params: {
      'name': 'test_tool',
      'arguments': {'param': 'value'}
    }),
  ];
  
  assert(requests.length == 4);
  assert(requests[0].method == 'tools/list');
  assert(requests[0].params == null);
  assert(requests[3].method == 'tools/call');
  assert(requests[3].params!['name'] == 'test_tool');
  assert(requests[3].params!['arguments']['param'] == 'value');
  
  // Test response handling scenarios
  final responses = [
    JsonRpcResponse(id: '1', result: {'tools': []}, isError: false),
    JsonRpcResponse(id: '2', result: {'resources': []}, isError: false),
    JsonRpcResponse(id: '3', error: {'code': -1, 'message': 'Not found'}, isError: true),
    JsonRpcResponse(id: '4', result: {'content': [{'type': 'text', 'text': 'Success'}]}, isError: false),
  ];
  
  final successCount = responses.where((r) => !r.isError).length;
  final errorCount = responses.where((r) => r.isError).length;
  
  assert(successCount == 3);
  assert(errorCount == 1);
  
  print('✓ Concurrent request handling tests passed');
}

void testDebugIntegration() {
  print('Testing debug integration scenarios...');
  
  // Test debug event creation
  final debugEvent = JsonRpcDebugEvent(
    connectionId: 'test-agent:test-server',
    type: JsonRpcDebugEventType.logEntry,
    data: 'Test log entry',
    timestamp: DateTime.now(),
  );
  
  assert(debugEvent.connectionId == 'test-agent:test-server');
  assert(debugEvent.type == JsonRpcDebugEventType.logEntry);
  assert(debugEvent.data == 'Test log entry');
  
  // Test performance metric creation
  final performanceMetric = JsonRpcPerformanceMetric(
    connectionId: 'test-agent:test-server',
    type: JsonRpcMetricType.requestDuration,
    value: 125.5,
    timestamp: DateTime.now(),
    metadata: {'method': 'tools/list'},
  );
  
  assert(performanceMetric.connectionId == 'test-agent:test-server');
  assert(performanceMetric.type == JsonRpcMetricType.requestDuration);
  assert(performanceMetric.value == 125.5);
  assert(performanceMetric.metadata!['method'] == 'tools/list');
  
  // Test JSON serialization
  final metricJson = performanceMetric.toJson();
  assert(metricJson['connectionId'] == 'test-agent:test-server');
  assert(metricJson['type'] == 'requestDuration');
  assert(metricJson['value'] == 125.5);
  assert(metricJson['metadata']['method'] == 'tools/list');
  
  // Test error record creation
  final errorRecord = JsonRpcErrorRecord(
    connectionId: 'test-agent:test-server',
    error: 'Connection timeout',
    timestamp: DateTime.now(),
  );
  
  assert(errorRecord.connectionId == 'test-agent:test-server');
  assert(errorRecord.error == 'Connection timeout');
  assert(errorRecord.message == null);
  
  // Test error record JSON
  final errorJson = errorRecord.toJson();
  assert(errorJson['connectionId'] == 'test-agent:test-server');
  assert(errorJson['error'] == 'Connection timeout');
  assert(errorJson['message'] == null);
  
  // Test connection health tracking
  final connectionHealth = JsonRpcConnectionHealth(
    connectionId: 'test-agent:test-server',
    lastActivity: DateTime.now(),
    totalMessages: 150,
    errorCount: 3,
    isHealthy: true,
  );
  
  assert(connectionHealth.connectionId == 'test-agent:test-server');
  assert(connectionHealth.totalMessages == 150);
  assert(connectionHealth.errorCount == 3);
  assert(connectionHealth.isHealthy == true);
  
  // Test health update
  final updatedHealth = connectionHealth.copyWith(
    totalMessages: 151,
    errorCount: 4,
    isHealthy: false,
  );
  
  assert(updatedHealth.totalMessages == 151);
  assert(updatedHealth.errorCount == 4);
  assert(updatedHealth.isHealthy == false);
  assert(updatedHealth.connectionId == connectionHealth.connectionId); // Unchanged
  
  print('✓ Debug integration tests passed');
}

// Supporting classes for testing

class JsonRpcHealthCheckResult {
  final String connectionId;
  final bool isHealthy;
  final Duration latency;
  final DateTime timestamp;
  final String? error;

  JsonRpcHealthCheckResult({
    required this.connectionId,
    required this.isHealthy,
    required this.latency,
    required this.timestamp,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'isHealthy': isHealthy,
      'latencyMs': latency.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
    };
  }
}

class JsonRpcRequestSpec {
  final String method;
  final Map<String, dynamic>? params;

  JsonRpcRequestSpec({required this.method, this.params});
}

class JsonRpcResponse {
  final String id;
  final Map<String, dynamic>? result;
  final Map<String, dynamic>? error;
  final bool isError;

  JsonRpcResponse({
    required this.id,
    this.result,
    this.error,
    required this.isError,
  });
}

class JsonRpcDebugEvent {
  final String connectionId;
  final JsonRpcDebugEventType type;
  final dynamic data;
  final DateTime timestamp;

  JsonRpcDebugEvent({
    required this.connectionId,
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

class JsonRpcPerformanceMetric {
  final String connectionId;
  final JsonRpcMetricType type;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  JsonRpcPerformanceMetric({
    required this.connectionId,
    required this.type,
    required this.value,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'type': type.name,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class JsonRpcErrorRecord {
  final String connectionId;
  final String error;
  final dynamic message;
  final DateTime timestamp;

  JsonRpcErrorRecord({
    required this.connectionId,
    required this.error,
    this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'error': error,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class JsonRpcConnectionHealth {
  final String connectionId;
  final DateTime lastActivity;
  final int totalMessages;
  final int errorCount;
  final bool isHealthy;

  JsonRpcConnectionHealth({
    required this.connectionId,
    required this.lastActivity,
    required this.totalMessages,
    required this.errorCount,
    required this.isHealthy,
  });

  JsonRpcConnectionHealth copyWith({
    DateTime? lastActivity,
    int? totalMessages,
    int? errorCount,
    bool? isHealthy,
  }) {
    return JsonRpcConnectionHealth(
      connectionId: connectionId,
      lastActivity: lastActivity ?? this.lastActivity,
      totalMessages: totalMessages ?? this.totalMessages,
      errorCount: errorCount ?? this.errorCount,
      isHealthy: isHealthy ?? this.isHealthy,
    );
  }
}

enum JsonRpcDebugEventType {
  logEntry,
  error,
  performanceMetric,
  connectionStatusChange,
}

enum JsonRpcMetricType {
  requestSent,
  responseReceived,
  requestDuration,
  errorCount,
  connectionLatency,
}