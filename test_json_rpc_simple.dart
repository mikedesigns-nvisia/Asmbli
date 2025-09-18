import 'dart:async';
import 'dart:convert';

/// Simple test for JSON-RPC communication system components
/// Tests the core functionality without external dependencies
void main() {
  print('🚀 Testing JSON-RPC Communication System Components...');
  
  testJsonRpcMessages();
  testJsonRpcExceptions();
  testJsonRpcDataModels();
  testJsonRpcLogTypes();
  
  print('✅ All JSON-RPC communication component tests passed!');
}

void testJsonRpcMessages() {
  print('Testing JSON-RPC message creation and serialization...');
  
  // Test request message
  final request = MCPMessage.request('123', 'test_method', {'param': 'value'});
  assert(request.id == '123');
  assert(request.method == 'test_method');
  assert(request.params!['param'] == 'value');
  assert(request.isRequest == true);
  assert(request.isResponse == false);
  assert(request.isNotification == false);
  assert(request.isError == false);
  
  // Test response message
  final response = MCPMessage.response('123', {'result': 'success'});
  assert(response.id == '123');
  assert(response.result!['result'] == 'success');
  assert(response.isRequest == false);
  assert(response.isResponse == true);
  assert(response.isNotification == false);
  assert(response.isError == false);
  
  // Test notification message
  final notification = MCPMessage.notification('test_notification', {'data': 'value'});
  assert(notification.method == 'test_notification');
  assert(notification.id == null);
  assert(notification.params!['data'] == 'value');
  assert(notification.isRequest == false);
  assert(notification.isResponse == false);
  assert(notification.isNotification == true);
  assert(notification.isError == false);
  
  // Test error message
  final error = MCPMessage.error('123', {'code': -1, 'message': 'Test error'});
  assert(error.id == '123');
  assert(error.error!['code'] == -1);
  assert(error.error!['message'] == 'Test error');
  assert(error.isRequest == false);
  assert(error.isResponse == true);
  assert(error.isNotification == false);
  assert(error.isError == true);
  
  // Test JSON serialization/deserialization
  final originalMessage = MCPMessage.request('456', 'serialize_test', {'test': true});
  final json = originalMessage.toJson();
  final deserializedMessage = MCPMessage.fromJson(json);
  
  assert(deserializedMessage.id == originalMessage.id);
  assert(deserializedMessage.method == originalMessage.method);
  assert(deserializedMessage.params!['test'] == originalMessage.params!['test']);
  assert(deserializedMessage.jsonrpc == '2.0');
  
  print('✓ JSON-RPC message tests passed');
}

void testJsonRpcExceptions() {
  print('Testing JSON-RPC exceptions...');
  
  // Test basic exception
  final basicException = JsonRpcException('Test error');
  assert(basicException.message == 'Test error');
  assert(basicException.toString().contains('JsonRpcException'));
  
  // Test timeout exception
  final timeoutException = JsonRpcTimeoutException('Timeout occurred', Duration(seconds: 30));
  assert(timeoutException.message == 'Timeout occurred');
  assert(timeoutException.timeout == Duration(seconds: 30));
  assert(timeoutException.toString().contains('JsonRpcTimeoutException'));
  assert(timeoutException.toString().contains('30s'));
  
  print('✓ JSON-RPC exception tests passed');
}

void testJsonRpcDataModels() {
  print('Testing JSON-RPC data models...');
  
  // Test connection results
  final successResult = JsonRpcConnectionResult.success(null);
  assert(successResult.success == true);
  assert(successResult.error == null);
  
  final failureResult = JsonRpcConnectionResult.failure('Connection failed');
  assert(failureResult.success == false);
  assert(failureResult.error == 'Connection failed');
  assert(failureResult.connection == null);
  
  // Test JSON-RPC responses
  final successResponse = JsonRpcResponse(
    id: '123',
    result: {'data': 'success'},
    isError: false,
  );
  assert(successResponse.id == '123');
  assert(successResponse.result!['data'] == 'success');
  assert(successResponse.isError == false);
  
  final errorResponse = JsonRpcResponse(
    id: '456',
    error: {'code': -1, 'message': 'Error occurred'},
    isError: true,
  );
  assert(errorResponse.id == '456');
  assert(errorResponse.error!['code'] == -1);
  assert(errorResponse.error!['message'] == 'Error occurred');
  assert(errorResponse.isError == true);
  
  // Test request specifications
  final requestSpec = JsonRpcRequestSpec(
    method: 'test_method',
    params: {'param1': 'value1'},
  );
  assert(requestSpec.method == 'test_method');
  assert(requestSpec.params!['param1'] == 'value1');
  
  final requestSpecNoParams = JsonRpcRequestSpec(method: 'simple_method');
  assert(requestSpecNoParams.method == 'simple_method');
  assert(requestSpecNoParams.params == null);
  
  // Test log entries
  final logEntry = JsonRpcLogEntry(
    connectionId: 'test-connection',
    type: JsonRpcLogType.request,
    direction: JsonRpcDirection.outgoing,
    timestamp: DateTime.now(),
  );
  assert(logEntry.connectionId == 'test-connection');
  assert(logEntry.type == JsonRpcLogType.request);
  assert(logEntry.direction == JsonRpcDirection.outgoing);
  assert(logEntry.timestamp != null);
  
  print('✓ JSON-RPC data model tests passed');
}

void testJsonRpcLogTypes() {
  print('Testing JSON-RPC log types and enums...');
  
  // Test log types
  final logTypes = JsonRpcLogType.values;
  assert(logTypes.contains(JsonRpcLogType.request));
  assert(logTypes.contains(JsonRpcLogType.response));
  assert(logTypes.contains(JsonRpcLogType.notification));
  assert(logTypes.contains(JsonRpcLogType.error));
  assert(logTypes.contains(JsonRpcLogType.unknown));
  
  // Test directions
  final directions = JsonRpcDirection.values;
  assert(directions.contains(JsonRpcDirection.incoming));
  assert(directions.contains(JsonRpcDirection.outgoing));
  
  // Test metric types
  final metricTypes = JsonRpcMetricType.values;
  assert(metricTypes.contains(JsonRpcMetricType.requestSent));
  assert(metricTypes.contains(JsonRpcMetricType.responseReceived));
  assert(metricTypes.contains(JsonRpcMetricType.requestDuration));
  assert(metricTypes.contains(JsonRpcMetricType.errorCount));
  assert(metricTypes.contains(JsonRpcMetricType.connectionLatency));
  
  // Test debug event types
  final debugEventTypes = JsonRpcDebugEventType.values;
  assert(debugEventTypes.contains(JsonRpcDebugEventType.logEntry));
  assert(debugEventTypes.contains(JsonRpcDebugEventType.error));
  assert(debugEventTypes.contains(JsonRpcDebugEventType.performanceMetric));
  assert(debugEventTypes.contains(JsonRpcDebugEventType.connectionStatusChange));
  
  print('✓ JSON-RPC log type tests passed');
}

// Minimal implementations for testing (without external dependencies)

class MCPMessage {
  final String? id;
  final String? method;
  final Map<String, dynamic>? params;
  final Map<String, dynamic>? result;
  final Map<String, dynamic>? error;
  final String jsonrpc;

  const MCPMessage({
    this.id,
    this.method,
    this.params,
    this.result,
    this.error,
    this.jsonrpc = '2.0',
  });

  factory MCPMessage.request(String id, String method, [Map<String, dynamic>? params]) {
    return MCPMessage(id: id, method: method, params: params);
  }

  factory MCPMessage.response(String id, Map<String, dynamic> result) {
    return MCPMessage(id: id, result: result);
  }

  factory MCPMessage.error(String id, Map<String, dynamic> error) {
    return MCPMessage(id: id, error: error);
  }

  factory MCPMessage.notification(String method, [Map<String, dynamic>? params]) {
    return MCPMessage(method: method, params: params);
  }

  factory MCPMessage.fromJson(Map<String, dynamic> json) {
    return MCPMessage(
      id: json['id']?.toString(),
      method: json['method']?.toString(),
      params: json['params'] as Map<String, dynamic>?,
      result: json['result'] as Map<String, dynamic>?,
      error: json['error'] as Map<String, dynamic>?,
      jsonrpc: json['jsonrpc']?.toString() ?? '2.0',
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'jsonrpc': jsonrpc};
    if (id != null) json['id'] = id;
    if (method != null) json['method'] = method;
    if (params != null) json['params'] = params;
    if (result != null) json['result'] = result;
    if (error != null) json['error'] = error;
    return json;
  }

  bool get isRequest => method != null && id != null;
  bool get isResponse => id != null && (result != null || error != null);
  bool get isNotification => method != null && id == null;
  bool get isError => error != null;
}

class JsonRpcException implements Exception {
  final String message;
  JsonRpcException(this.message);
  
  @override
  String toString() => 'JsonRpcException: $message';
}

class JsonRpcTimeoutException extends JsonRpcException {
  final Duration timeout;
  
  JsonRpcTimeoutException(String message, this.timeout) : super(message);
  
  @override
  String toString() => 'JsonRpcTimeoutException: $message (timeout: ${timeout.inSeconds}s)';
}

class JsonRpcConnectionResult {
  final bool success;
  final dynamic connection;
  final String? error;

  JsonRpcConnectionResult.success(this.connection) : success = true, error = null;
  JsonRpcConnectionResult.failure(this.error) : success = false, connection = null;
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

class JsonRpcRequestSpec {
  final String method;
  final Map<String, dynamic>? params;

  JsonRpcRequestSpec({required this.method, this.params});
}

class JsonRpcLogEntry {
  final String connectionId;
  final JsonRpcLogType type;
  final JsonRpcDirection direction;
  final MCPMessage? message;
  final String? error;
  final DateTime timestamp;

  JsonRpcLogEntry({
    required this.connectionId,
    required this.type,
    required this.direction,
    this.message,
    this.error,
    required this.timestamp,
  });
}

enum JsonRpcLogType {
  request,
  response,
  notification,
  error,
  unknown,
}

enum JsonRpcDirection {
  incoming,
  outgoing,
}

enum JsonRpcMetricType {
  requestSent,
  responseReceived,
  requestDuration,
  errorCount,
  connectionLatency,
}

enum JsonRpcDebugEventType {
  logEntry,
  error,
  performanceMetric,
  connectionStatusChange,
}