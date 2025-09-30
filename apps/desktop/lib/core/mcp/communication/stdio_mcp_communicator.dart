import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../utils/app_logger.dart';
import '../../utils/circuit_breaker.dart';
import '../../models/mcp_server_config.dart';
import '../validation/mcp_protocol_validator.dart';

/// Production-ready STDIO MCP communicator
/// Implements actual JSON-RPC 2.0 communication over STDIO with MCP servers
class StdioMCPCommunicator {
  Process? _process;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  final StreamController<Map<String, dynamic>> _responseController = StreamController.broadcast();
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final CircuitBreaker _circuitBreaker;

  int _requestId = 0;
  bool _isConnected = false;
  String? _connectionId;
  MCPServerConfig? _config;

  StdioMCPCommunicator({required CircuitBreaker circuitBreaker})
      : _circuitBreaker = circuitBreaker;

  /// Connect to MCP server via STDIO
  Future<bool> connect(MCPServerConfig config) async {
    if (_isConnected) {
      AppLogger.warning('Already connected to MCP server ${config.name}', component: 'MCP.STDIO');
      return true;
    }

    _config = config;
    _connectionId = 'stdio-${config.id}-${DateTime.now().millisecondsSinceEpoch}';

    return await _circuitBreaker.execute(
      () => _establishStdioConnection(config),
      false,
      operationName: 'connect-mcp-server',
    );
  }

  Future<bool> _establishStdioConnection(MCPServerConfig config) async {
    try {
      AppLogger.info('Starting MCP server: ${config.command}', component: 'MCP.STDIO');

      // Parse command and arguments
      final commandParts = _parseCommand(config.command);
      if (commandParts.isEmpty) {
        throw Exception('Invalid server command: ${config.command}');
      }

      final command = commandParts.first;
      final args = commandParts.length > 1 ? commandParts.sublist(1) : <String>[];

      // Start the MCP server process
      _process = await Process.start(
        command,
        args,
        workingDirectory: config.workingDirectory,
        environment: _buildEnvironment(config),
        runInShell: Platform.isWindows,
      );

      if (_process == null) {
        throw Exception('Failed to start MCP server process');
      }

      AppLogger.info('MCP server process started (PID: ${_process!.pid})', component: 'MCP.STDIO');

      // Set up STDIO communication
      await _setupStdioCommunication();

      // Send initialization request
      final initSuccess = await _sendInitializeRequest();
      if (!initSuccess) {
        throw Exception('MCP server initialization failed');
      }

      _isConnected = true;
      AppLogger.info('Successfully connected to MCP server ${config.name}', component: 'MCP.STDIO');
      return true;

    } catch (e) {
      AppLogger.error('Failed to connect to MCP server ${config.name}', component: 'MCP.STDIO', error: e);
      await _cleanup();
      return false;
    }
  }

  List<String> _parseCommand(String command) {
    // Handle quoted arguments properly
    final List<String> parts = [];
    bool inQuotes = false;
    String current = '';

    for (int i = 0; i < command.length; i++) {
      final char = command[i];

      if (char == '"' || char == "'") {
        inQuotes = !inQuotes;
      } else if (char == ' ' && !inQuotes) {
        if (current.isNotEmpty) {
          parts.add(current);
          current = '';
        }
      } else {
        current += char;
      }
    }

    if (current.isNotEmpty) {
      parts.add(current);
    }

    return parts;
  }

  Map<String, String> _buildEnvironment(MCPServerConfig config) {
    final env = Map<String, String>.from(Platform.environment);

    // Add config-specific environment variables
    if (config.environment != null) {
      env.addAll(config.environment!);
    }

    return env;
  }

  Future<void> _setupStdioCommunication() async {
    if (_process == null) {
      throw Exception('Process not started');
    }

    // Set up stdout listener for responses
    _stdoutSubscription = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _handleStdoutLine,
          onError: (error) {
            AppLogger.error('STDOUT error from MCP server', component: 'MCP.STDIO', error: error);
          },
        );

    // Set up stderr listener for debugging
    _stderrSubscription = _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.trim().isNotEmpty) {
              AppLogger.debug('MCP server stderr: $line', component: 'MCP.STDIO');
            }
          },
          onError: (error) {
            AppLogger.error('STDERR error from MCP server', component: 'MCP.STDIO', error: error);
          },
        );

    // Monitor process exit
    _process!.exitCode.then((exitCode) {
      AppLogger.warning('MCP server process exited with code: $exitCode', component: 'MCP.STDIO');
      _isConnected = false;
    });
  }

  void _handleStdoutLine(String line) {
    line = line.trim();
    if (line.isEmpty) return;

    // Parse and validate incoming message
    final parseResult = MCPProtocolValidator.parseMessage(line);
    if (!parseResult.isValid) {
      AppLogger.warning('Invalid JSON from MCP server: ${parseResult.error}', component: 'MCP.STDIO');
      return;
    }

    final message = parseResult.message!;

    // Validate message format
    ValidationResult validation;
    if (MCPProtocolValidator.isNotification(message)) {
      validation = MCPProtocolValidator.validateNotification(message);
    } else {
      validation = MCPProtocolValidator.validateResponse(message, null);
    }

    if (!validation.isValid) {
      AppLogger.warning('Invalid message format from MCP server: ${validation.issues.join(', ')}', component: 'MCP.STDIO');
      return;
    }

    _processJsonRpcMessage(message);
  }

  void _processJsonRpcMessage(Map<String, dynamic> message) {
    // Handle JSON-RPC response
    if (message.containsKey('id') && message.containsKey('result')) {
      final id = message['id'] as int?;
      if (id != null && _pendingRequests.containsKey(id)) {
        _pendingRequests[id]!.complete(message);
        _pendingRequests.remove(id);
      }
      return;
    }

    // Handle JSON-RPC error response
    if (message.containsKey('id') && message.containsKey('error')) {
      final id = message['id'] as int?;
      if (id != null && _pendingRequests.containsKey(id)) {
        _pendingRequests[id]!.complete(message);
        _pendingRequests.remove(id);
      }
      return;
    }

    // Handle notification
    if (message.containsKey('method') && !message.containsKey('id')) {
      _responseController.add(message);
      return;
    }

    AppLogger.debug('Received unexpected message from MCP server: $message', component: 'MCP.STDIO');
  }

  Future<bool> _sendInitializeRequest() async {
    final initRequest = {
      'jsonrpc': '2.0',
      'id': _getNextRequestId(),
      'method': 'initialize',
      'params': {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'logging': {},
          'prompts': {'listChanged': false},
          'resources': {'subscribe': false, 'listChanged': false},
          'tools': {'listChanged': false},
        },
        'clientInfo': {
          'name': 'AgentEngine',
          'version': '1.0.0',
        },
      },
    };

    final response = await sendRequest(initRequest);

    if (response['error'] != null) {
      AppLogger.error('MCP initialization failed: ${response['error']}', component: 'MCP.STDIO');
      return false;
    }

    if (response['result'] != null) {
      AppLogger.info('MCP server initialized successfully', component: 'MCP.STDIO');
      return true;
    }

    return false;
  }

  /// Send JSON-RPC request to MCP server
  Future<Map<String, dynamic>> sendRequest(Map<String, dynamic> request) async {
    if (!_isConnected || _process == null) {
      throw Exception('Not connected to MCP server');
    }

    return await _circuitBreaker.execute(
      () => _sendJsonRpcRequest(request),
      {'error': 'Circuit breaker open - MCP server unavailable'},
      operationName: 'mcp-request',
    );
  }

  Future<Map<String, dynamic>> _sendJsonRpcRequest(Map<String, dynamic> request) async {
    // Validate request before sending
    final validation = MCPProtocolValidator.validateRequest(request);
    if (!validation.isValid) {
      throw Exception('Invalid request format: ${validation.issues.join(', ')}');
    }

    final requestId = request['id'] as int?;
    if (requestId == null) {
      throw Exception('Request must have an ID');
    }

    // Set up response awaiter
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    try {
      // Send request via STDIN
      final requestJson = jsonEncode(request);
      _process!.stdin.writeln(requestJson);
      await _process!.stdin.flush();

      AppLogger.debug('Sent MCP request: ${request['method']}', component: 'MCP.STDIO');

      // Wait for response with timeout
      final response = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _pendingRequests.remove(requestId);
          throw TimeoutException('MCP request timeout', const Duration(seconds: 30));
        },
      );

      // Validate response format
      final responseValidation = MCPProtocolValidator.validateResponse(response, request['method'] as String?);
      if (!responseValidation.isValid) {
        AppLogger.warning('Invalid response format: ${responseValidation.issues.join(', ')}', component: 'MCP.STDIO');
      }

      return response;

    } catch (e) {
      _pendingRequests.remove(requestId);
      rethrow;
    }
  }

  /// Send notification (no response expected)
  Future<void> sendNotification(Map<String, dynamic> notification) async {
    if (!_isConnected || _process == null) {
      throw Exception('Not connected to MCP server');
    }

    // Validate notification format
    final validation = MCPProtocolValidator.validateNotification(notification);
    if (!validation.isValid) {
      throw Exception('Invalid notification format: ${validation.issues.join(', ')}');
    }

    final notificationJson = jsonEncode(notification);
    _process!.stdin.writeln(notificationJson);
    await _process!.stdin.flush();

    AppLogger.debug('Sent MCP notification: ${notification['method']}', component: 'MCP.STDIO');
  }

  /// Get list of available tools from MCP server
  Future<List<Map<String, dynamic>>> getTools() async {
    final request = {
      'jsonrpc': '2.0',
      'id': _getNextRequestId(),
      'method': 'tools/list',
      'params': {},
    };

    final response = await sendRequest(request);

    if (response['error'] != null) {
      throw Exception('Failed to get tools: ${response['error']}');
    }

    final result = response['result'] as Map<String, dynamic>?;
    final tools = List<Map<String, dynamic>>.from(result?['tools'] ?? []);

    // Validate each tool definition
    for (final tool in tools) {
      final validation = MCPProtocolValidator.validateTool(tool);
      if (!validation.isValid) {
        AppLogger.warning('Invalid tool definition for ${tool['name']}: ${validation.issues.join(', ')}', component: 'MCP.STDIO');
      }
    }

    return tools;
  }

  /// Call a tool on the MCP server
  Future<Map<String, dynamic>> callTool(String toolName, Map<String, dynamic> arguments) async {
    final request = {
      'jsonrpc': '2.0',
      'id': _getNextRequestId(),
      'method': 'tools/call',
      'params': {
        'name': toolName,
        'arguments': arguments,
      },
    };

    final response = await sendRequest(request);

    if (response['error'] != null) {
      throw Exception('Tool call failed: ${response['error']}');
    }

    return response['result'] as Map<String, dynamic>? ?? {};
  }

  int _getNextRequestId() => ++_requestId;

  /// Disconnect from MCP server
  Future<void> disconnect() async {
    if (!_isConnected) return;

    AppLogger.info('Disconnecting from MCP server', component: 'MCP.STDIO');

    // Send shutdown notification if connected
    if (_isConnected && _process != null) {
      try {
        await sendNotification({
          'jsonrpc': '2.0',
          'method': 'notifications/shutdown',
          'params': {},
        });
      } catch (e) {
        AppLogger.debug('Failed to send shutdown notification: $e', component: 'MCP.STDIO');
      }
    }

    await _cleanup();
  }

  Future<void> _cleanup() async {
    _isConnected = false;

    // Cancel subscriptions
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;

    // Complete any pending requests with error
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.complete({'error': 'Connection closed'});
      }
    }
    _pendingRequests.clear();

    // Terminate process
    if (_process != null) {
      try {
        _process!.kill();
        await _process!.exitCode.timeout(const Duration(seconds: 5));
      } catch (e) {
        AppLogger.debug('Error terminating MCP process: $e', component: 'MCP.STDIO');
      }
      _process = null;
    }

    AppLogger.info('MCP server disconnected and cleaned up', component: 'MCP.STDIO');
  }

  /// Check if currently connected
  bool get isConnected => _isConnected;

  /// Get connection ID
  String? get connectionId => _connectionId;

  /// Get server config
  MCPServerConfig? get config => _config;

  /// Stream of notifications from server
  Stream<Map<String, dynamic>> get notifications => _responseController.stream;

  /// Dispose resources
  void dispose() {
    disconnect();
    _responseController.close();
  }
}