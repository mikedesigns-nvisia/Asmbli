import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'mcp_server_config.dart';

/// Transport type for MCP server communication
enum MCPTransport {
  stdio,
  sse,
}

/// Real MCP server process implementation with actual process management
class MCPServerProcess {
  final String id;
  final MCPServerConfig config;
  Process? _process;
  final DateTime startTime;
  
  bool isInitialized = false;
  bool isHealthy = false;
  DateTime? lastActivity;
  final List<String> _errors = [];
  
  // Stream controllers for process output
  final StreamController<String> _stdoutController = StreamController<String>.broadcast();
  final StreamController<String> _stderrController = StreamController<String>.broadcast();
  
  MCPServerProcess({
    required this.id,
    required this.config,
    Process? process,
    required this.startTime,
  }) : _process = process {
    lastActivity = startTime;
    if (_process != null) {
      _setupProcessListeners();
    }
  }
  
  /// Get the underlying process (for backwards compatibility)
  Process? get process => _process;
  
  /// Transport type determined from config
  MCPTransport get transport {
    if (config.transport == 'sse') {
      return MCPTransport.sse;
    }
    return MCPTransport.stdio;
  }
  
  /// Stream of stdout output
  Stream<String> get stdout => _stdoutController.stream;
  
  /// Stream of stderr output  
  Stream<String> get stderr => _stderrController.stream;
  
  /// List of recorded errors
  List<String> get errors => List.unmodifiable(_errors);
  
  /// Start the MCP server process
  static Future<MCPServerProcess> start({
    required String id,
    required MCPServerConfig config,
    Map<String, String> environmentVars = const {},
  }) async {
    final mergedEnv = Map<String, String>.from(Platform.environment);
    mergedEnv.addAll(environmentVars);
    
    final process = await Process.start(
      config.command,
      config.args,
      environment: mergedEnv,
      runInShell: true,
      workingDirectory: config.workingDirectory,
    );
    
    final mcpProcess = MCPServerProcess(
      id: id,
      config: config,
      process: process,
      startTime: DateTime.now(),
    );
    
    // Initially healthy until proven otherwise
    mcpProcess.isHealthy = true;
    
    return mcpProcess;
  }
  
  /// Setup listeners for process stdout/stderr
  void _setupProcessListeners() {
    if (_process == null) return;
    
    // Listen to stdout
    _process!.stdout.transform(utf8.decoder).listen(
      (data) {
        _stdoutController.add(data);
        recordActivity();
      },
      onError: (error) {
        recordError('Stdout error: $error');
      },
    );
    
    // Listen to stderr  
    _process!.stderr.transform(utf8.decoder).listen(
      (data) {
        _stderrController.add(data);
        // Don't treat all stderr as errors - some servers use it for info
        if (data.toLowerCase().contains('error') || 
            data.toLowerCase().contains('fatal') ||
            data.toLowerCase().contains('exception')) {
          recordError('Stderr: ${data.trim()}');
        }
      },
      onError: (error) {
        recordError('Stderr error: $error');
      },
    );
    
    // Listen to process exit
    _process!.exitCode.then((exitCode) {
      isHealthy = false;
      if (exitCode != 0) {
        recordError('Process exited with code $exitCode');
      }
    });
  }
  
  /// Send data to process stdin
  Future<void> sendInput(String data) async {
    if (_process == null) {
      throw StateError('Process not started');
    }
    _process!.stdin.writeln(data);
    await _process!.stdin.flush();
  }
  
  /// Send JSON-RPC request and return response
  Future<Map<String, dynamic>> sendJsonRpcRequest(String method, Map<String, dynamic> params, {String? id}) async {
    final requestId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final request = {
      'jsonrpc': '2.0',
      'id': requestId,
      'method': method,
      'params': params,
    };
    
    final completer = Completer<Map<String, dynamic>>();
    StreamSubscription? subscription;
    
    // Listen for response with matching ID
    subscription = stdout.listen((data) {
      final lines = data.split('\n').where((line) => line.trim().isNotEmpty);
      for (final line in lines) {
        try {
          final response = json.decode(line) as Map<String, dynamic>;
          if (response['id'] == requestId) {
            subscription?.cancel();
            if (response.containsKey('error')) {
              completer.completeError(Exception('MCP Error: ${response['error']}'));
            } else {
              completer.complete(response);
            }
            return;
          }
        } catch (e) {
          // Ignore non-JSON lines or responses for different requests
        }
      }
    });
    
    // Send the request
    await sendInput(json.encode(request));
    
    // Set timeout
    Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.completeError(TimeoutException('Request timeout', const Duration(seconds: 30)));
      }
    });
    
    return completer.future;
  }
  
  /// Kill the process
  Future<void> kill([ProcessSignal signal = ProcessSignal.sigterm]) async {
    if (_process != null) {
      _process!.kill(signal);
      await _process!.exitCode;
    }
    await _cleanup();
  }
  
  /// Record an error
  void recordError(String error) {
    _errors.add('${DateTime.now().toIso8601String()}: $error');
    print('MCP Error [$id]: $error');
    isHealthy = false;
  }
  
  /// Record activity
  void recordActivity() {
    lastActivity = DateTime.now();
  }
  
  /// Cleanup resources
  Future<void> _cleanup() async {
    await _stdoutController.close();
    await _stderrController.close();
  }
}