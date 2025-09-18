import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:equatable/equatable.dart';

/// Status of MCP connection
enum MCPConnectionStatus {
  connecting,
  connected,
  disconnected,
  error,
  closed,
}

/// MCP JSON-RPC message
class MCPMessage extends Equatable {
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
    return MCPMessage(
      id: id,
      method: method,
      params: params,
    );
  }

  factory MCPMessage.response(String id, Map<String, dynamic> result) {
    return MCPMessage(
      id: id,
      result: result,
    );
  }

  factory MCPMessage.error(String id, Map<String, dynamic> error) {
    return MCPMessage(
      id: id,
      error: error,
    );
  }

  factory MCPMessage.notification(String method, [Map<String, dynamic>? params]) {
    return MCPMessage(
      method: method,
      params: params,
    );
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
    final json = <String, dynamic>{
      'jsonrpc': jsonrpc,
    };

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

  @override
  List<Object?> get props => [id, method, params, result, error, jsonrpc];
}

/// MCP connection for JSON-RPC communication
abstract class MCPConnection {
  String get id;
  MCPConnectionStatus get status;
  Stream<MCPMessage> get messages;
  
  Future<void> connect();
  Future<void> close();
  Future<void> send(MCPMessage message);
  Future<MCPMessage> request(String method, [Map<String, dynamic>? params]);
}

/// Stdio-based MCP connection
class MCPStdioConnection implements MCPConnection {
  @override
  final String id;
  
  final Process _process;
  final StreamController<MCPMessage> _messageController = StreamController<MCPMessage>.broadcast();
  final Map<String, Completer<MCPMessage>> _pendingRequests = {};
  
  MCPConnectionStatus _status = MCPConnectionStatus.connecting;
  int _requestId = 0;
  
  MCPStdioConnection(this.id, this._process) {
    _setupStreams();
  }

  @override
  MCPConnectionStatus get status => _status;

  @override
  Stream<MCPMessage> get messages => _messageController.stream;

  void _setupStreams() {
    // Listen to stdout for JSON-RPC messages
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      _handleStdoutLine,
      onError: _handleError,
      onDone: _handleDisconnect,
    );

    // Listen to stderr for errors
    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      _handleStderrLine,
      onError: _handleError,
    );

    // Listen to process exit
    _process.exitCode.then(_handleProcessExit);
  }

  void _handleStdoutLine(String line) {
    if (line.trim().isEmpty) return;

    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      final message = MCPMessage.fromJson(json);
      
      // Handle responses to pending requests
      if (message.isResponse && message.id != null) {
        final completer = _pendingRequests.remove(message.id);
        if (completer != null) {
          completer.complete(message);
          return;
        }
      }
      
      // Broadcast other messages
      _messageController.add(message);
      
      // Update status on successful communication
      if (_status == MCPConnectionStatus.connecting) {
        _status = MCPConnectionStatus.connected;
      }
    } catch (e) {
      print('Failed to parse MCP message: $line - Error: $e');
    }
  }

  void _handleStderrLine(String line) {
    print('MCP Server stderr: $line');
  }

  void _handleError(dynamic error) {
    print('MCP Connection error: $error');
    _status = MCPConnectionStatus.error;
  }

  void _handleDisconnect() {
    _status = MCPConnectionStatus.disconnected;
    _completeAllPendingRequests();
  }

  void _handleProcessExit(int exitCode) {
    print('MCP Process exited with code: $exitCode');
    _status = MCPConnectionStatus.closed;
    _completeAllPendingRequests();
  }

  void _completeAllPendingRequests() {
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Connection closed'));
      }
    }
    _pendingRequests.clear();
  }

  @override
  Future<void> connect() async {
    // Connection is established when process starts
    _status = MCPConnectionStatus.connecting;
  }

  @override
  Future<void> close() async {
    _status = MCPConnectionStatus.closed;
    _process.kill();
    await _messageController.close();
  }

  @override
  Future<void> send(MCPMessage message) async {
    if (_status != MCPConnectionStatus.connected && _status != MCPConnectionStatus.connecting) {
      throw Exception('Connection not available');
    }

    final json = jsonEncode(message.toJson());
    _process.stdin.writeln(json);
    await _process.stdin.flush();
  }

  @override
  Future<MCPMessage> request(String method, [Map<String, dynamic>? params]) async {
    final id = (_requestId++).toString();
    final message = MCPMessage.request(id, method, params);
    
    final completer = Completer<MCPMessage>();
    _pendingRequests[id] = completer;
    
    await send(message);
    
    // Add timeout
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException('MCP request timeout', const Duration(seconds: 30));
      },
    );
  }
}