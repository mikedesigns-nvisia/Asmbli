import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/mcp_protocol_handler.dart';
import 'mcp_server_process.dart';
import 'mcp_message.dart';

/// Abstract base class for MCP connections
abstract class MCPConnection extends Equatable {
  final String id;
  final MCPServerProcess serverProcess;
  final MCPProtocolHandler protocolHandler;
  bool _isConnected = false;
  Map<String, dynamic>? _serverCapabilities;

  MCPConnection({
    required this.id,
    required this.serverProcess,
    required this.protocolHandler,
  });

  /// Initialize the connection
  Future<void> initialize();

  /// Send a message through the connection
  Future<void> sendMessage(MCPMessage message);

  /// Close the connection
  Future<void> close();

  /// Check if connection is active
  bool get isConnected => _isConnected;

  /// Get server capabilities
  Map<String, dynamic>? get serverCapabilities => _serverCapabilities;

  /// Mark connection as connected
  void markAsConnected(Map<String, dynamic>? capabilities) {
    _isConnected = true;
    _serverCapabilities = capabilities;
  }

  /// Mark connection as disconnected
  void markAsDisconnected() {
    _isConnected = false;
    _serverCapabilities = null;
  }

  @override
  List<Object?> get props => [id, serverProcess, _isConnected];
}

/// Stdio-based MCP connection
class MCPStdioConnection extends MCPConnection {
  final Process process;
  StreamSubscription<String>? _outputSubscription;
  StreamSubscription<String>? _errorSubscription;
  final StreamController<String> _messageController = StreamController.broadcast();

  MCPStdioConnection({
    required super.id,
    required super.serverProcess,
    required super.protocolHandler,
    required this.process,
  });

  @override
  Future<void> initialize() async {
    // Setup stdout listener for incoming messages
    _outputSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) async {
        if (line.trim().isNotEmpty) {
          await protocolHandler.handleIncomingMessage(this, line);
        }
      },
      onError: (error) {
        print('❌ Stdio connection error: $error');
        markAsDisconnected();
      },
    );

    // Setup stderr listener for error messages
    _errorSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (line.trim().isNotEmpty) {
          print('🚨 MCP Server stderr: $line');
        }
      },
    );

    // Monitor process exit
    process.exitCode.then((exitCode) {
      print('📤 MCP process exited with code: $exitCode');
      markAsDisconnected();
    });
  }

  @override
  Future<void> sendMessage(MCPMessage message) async {
    if (!isConnected && message.method != 'initialize') {
      throw Exception('Connection not established');
    }

    final jsonString = message.toJsonString();
    print('📤 Sending to ${serverProcess.id}: $jsonString');
    
    process.stdin.writeln(jsonString);
    await process.stdin.flush();
  }

  @override
  Future<void> close() async {
    markAsDisconnected();
    
    await _outputSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _messageController.close();
    
    // Send graceful shutdown if process is still alive
    try {
      if (!process.kill(ProcessSignal.sigterm)) {
        // Process already dead
        return;
      }
      
      // Wait for graceful shutdown
      await process.exitCode.timeout(const Duration(seconds: 5), onTimeout: () {
        // Force kill if graceful shutdown failed
        process.kill(ProcessSignal.sigkill);
        return -1;
      });
    } catch (e) {
      print('⚠️ Error during connection cleanup: $e');
    }
  }
}

/// Server-Sent Events (SSE) based MCP connection
class MCPSSEConnection extends MCPConnection {
  final String baseUrl;
  HttpClient? _httpClient;
  HttpClientRequest? _sseRequest;
  StreamSubscription<String>? _sseSubscription;

  MCPSSEConnection({
    required super.id,
    required super.serverProcess,
    required super.protocolHandler,
    required this.baseUrl,
  });

  @override
  Future<void> initialize() async {
    _httpClient = HttpClient();
    
    // Connect to SSE endpoint
    await _connectSSE();
  }

  Future<void> _connectSSE() async {
    try {
      final uri = Uri.parse('$baseUrl/sse');
      _sseRequest = await _httpClient!.getUrl(uri);
      _sseRequest!.headers.set('Accept', 'text/event-stream');
      _sseRequest!.headers.set('Cache-Control', 'no-cache');
      
      final response = await _sseRequest!.close();
      
      if (response.statusCode != 200) {
        throw Exception('SSE connection failed: ${response.statusCode}');
      }

      _sseSubscription = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((line) => line.startsWith('data: '))
          .map((line) => line.substring(6)) // Remove 'data: ' prefix
          .listen(
        (data) async {
          if (data.trim().isNotEmpty && data != '[DONE]') {
            await protocolHandler.handleIncomingMessage(this, data);
          }
        },
        onError: (error) {
          print('❌ SSE connection error: $error');
          markAsDisconnected();
        },
        onDone: () {
          print('📤 SSE connection closed');
          markAsDisconnected();
        },
      );
      
    } catch (e) {
      print('❌ Failed to connect SSE: $e');
      markAsDisconnected();
      rethrow;
    }
  }

  @override
  Future<void> sendMessage(MCPMessage message) async {
    if (!isConnected && message.method != 'initialize') {
      throw Exception('Connection not established');
    }

    try {
      final uri = Uri.parse('$baseUrl/message');
      final request = await _httpClient!.postUrl(uri);
      
      request.headers.set('Content-Type', 'application/json');
      
      final jsonString = message.toJsonString();
      print('📤 Sending to ${serverProcess.id}: $jsonString');
      
      request.write(jsonString);
      
      final response = await request.close();
      
      if (response.statusCode != 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        throw Exception('HTTP ${response.statusCode}: $responseBody');
      }
      
    } catch (e) {
      print('❌ Failed to send message via SSE: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    markAsDisconnected();
    
    await _sseSubscription?.cancel();
    _httpClient?.close();
    
    _sseSubscription = null;
    _httpClient = null;
    _sseRequest = null;
  }
}

/// WebSocket-based MCP connection
class MCPWebSocketConnection extends MCPConnection {
  final String url;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _messageSubscription;

  MCPWebSocketConnection({
    required super.id,
    required super.serverProcess,
    required super.protocolHandler,
    required this.url,
  });

  @override
  Future<void> initialize() async {
    try {
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);
      
      await _channel!.ready;
      
      _messageSubscription = _channel!.stream.listen(
        (data) async {
          final message = data.toString();
          if (message.trim().isNotEmpty) {
            await protocolHandler.handleIncomingMessage(this, message);
          }
        },
        onError: (error) {
          print('❌ WebSocket connection error: $error');
          markAsDisconnected();
        },
        onDone: () {
          print('📤 WebSocket connection closed');
          markAsDisconnected();
        },
      );
      
    } catch (e) {
      print('❌ Failed to connect WebSocket: $e');
      markAsDisconnected();
      rethrow;
    }
  }

  @override
  Future<void> sendMessage(MCPMessage message) async {
    if (_channel == null) {
      throw Exception('WebSocket not connected');
    }

    if (!isConnected && message.method != 'initialize') {
      throw Exception('Connection not established');
    }

    final jsonString = message.toJsonString();
    print('📤 Sending to ${serverProcess.id}: $jsonString');
    
    _channel!.sink.add(jsonString);
  }

  @override
  Future<void> close() async {
    markAsDisconnected();
    
    await _messageSubscription?.cancel();
    await _channel?.sink.close();
    
    _messageSubscription = null;
    _channel = null;
  }
}

/// Connection status enumeration
enum MCPConnectionStatus {
  disconnected('Disconnected'),
  connecting('Connecting'),
  connected('Connected'),
  error('Error'),
  closed('Closed');

  const MCPConnectionStatus(this.displayName);

  final String displayName;
}

/// Connection statistics
class MCPConnectionStats extends Equatable {
  final int messagesSent;
  final int messagesReceived;
  final int errorsCount;
  final DateTime connectedAt;
  final Duration uptime;

  const MCPConnectionStats({
    required this.messagesSent,
    required this.messagesReceived,
    required this.errorsCount,
    required this.connectedAt,
    required this.uptime,
  });

  @override
  List<Object?> get props => [
    messagesSent,
    messagesReceived,
    errorsCount,
    connectedAt,
    uptime,
  ];
}