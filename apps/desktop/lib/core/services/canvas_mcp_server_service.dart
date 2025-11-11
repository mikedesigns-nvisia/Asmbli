import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../di/service_locator.dart';
import './mcp_bridge_service.dart';
import './mcp_catalog_service.dart';

/// Service to manage the Canvas MCP Server lifecycle
/// Handles starting, stopping, and monitoring the TypeScript MCP server
class CanvasMCPServerService {
  Process? _serverProcess;
  bool _isRunning = false;
  final Completer<void> _serverReady = Completer<void>();
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;
  
  /// Canvas MCP server configuration
  static const String serverName = 'asmbli-canvas';
  static const String serverVersion = '0.1.0';
  static const String serverDescription = 'Visual design canvas with design system support';
  
  bool get isRunning => _isRunning;
  Future<void> get serverReady => _serverReady.future;

  /// Start the Canvas MCP Server
  Future<void> startServer() async {
    if (_isRunning) {
      print('🎨 Canvas MCP Server is already running');
      return;
    }

    try {
      print('🚀 Starting Canvas MCP Server...');
      
      // Find the server executable
      final serverPath = await _findServerExecutable();
      if (serverPath == null) {
        throw Exception('Canvas MCP Server executable not found. Please run: npm run build in packages/asmbli-canvas-mcp');
      }

      // Start the MCP server process
      _serverProcess = await Process.start(
        'node',
        [serverPath],
        mode: ProcessStartMode.normal,
      );

      if (_serverProcess == null) {
        throw Exception('Failed to start Canvas MCP Server process');
      }

      _isRunning = true;
      print('✅ Canvas MCP Server process started (PID: ${_serverProcess!.pid})');

      // Monitor server output
      _stdoutSubscription = _serverProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleServerOutput);

      _stderrSubscription = _serverProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleServerError);

      // Monitor process exit
      _serverProcess!.exitCode.then(_handleServerExit);

      // Wait for server to be ready
      await serverReady.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Canvas MCP Server failed to start within 10 seconds');
        },
      );

      // Register with MCP catalog
      await _registerWithCatalog();

    } catch (e) {
      print('❌ Failed to start Canvas MCP Server: $e');
      await stopServer();
      rethrow;
    }
  }

  /// Stop the Canvas MCP Server
  Future<void> stopServer() async {
    if (!_isRunning) return;

    try {
      print('🛑 Stopping Canvas MCP Server...');

      // Cancel subscriptions
      await _stdoutSubscription?.cancel();
      await _stderrSubscription?.cancel();
      _stdoutSubscription = null;
      _stderrSubscription = null;

      // Kill the process
      if (_serverProcess != null) {
        _serverProcess!.kill(ProcessSignal.sigterm);
        
        // Wait for graceful shutdown, then force kill if needed
        await Future.any([
          _serverProcess!.exitCode,
          Future.delayed(const Duration(seconds: 5)),
        ]);

        if (!_serverProcess!.exitCode.isCompleted) {
          _serverProcess!.kill(ProcessSignal.sigkill);
        }
      }

      _serverProcess = null;
      _isRunning = false;
      
      // Unregister from MCP catalog
      await _unregisterFromCatalog();

      print('✅ Canvas MCP Server stopped');

    } catch (e) {
      print('❌ Error stopping Canvas MCP Server: $e');
    }
  }

  /// Restart the Canvas MCP Server
  Future<void> restartServer() async {
    await stopServer();
    await Future.delayed(const Duration(milliseconds: 500));
    await startServer();
  }

  /// Find the Canvas MCP Server executable
  Future<String?> _findServerExecutable() async {
    // Look for the built server in packages/asmbli-canvas-mcp/dist/
    final candidates = [
      'packages/asmbli-canvas-mcp/dist/server.js',
      '../packages/asmbli-canvas-mcp/dist/server.js',
      '../../packages/asmbli-canvas-mcp/dist/server.js',
    ];

    for (final candidate in candidates) {
      final file = File(path.normalize(candidate));
      if (await file.exists()) {
        return file.absolute.path;
      }
    }

    // Try to find from current working directory
    final cwd = Directory.current.path;
    final cwdCandidate = path.join(cwd, 'packages', 'asmbli-canvas-mcp', 'dist', 'server.js');
    if (await File(cwdCandidate).exists()) {
      return cwdCandidate;
    }

    return null;
  }

  /// Handle server stdout output
  void _handleServerOutput(String line) {
    if (kDebugMode) {
      print('🎨 Canvas MCP: $line');
    }

    // Check if server is ready
    if (line.contains('Canvas MCP Server running') && !_serverReady.isCompleted) {
      _serverReady.complete();
    }
  }

  /// Handle server stderr output
  void _handleServerError(String line) {
    print('❌ Canvas MCP Error: $line');
    
    // If we get an error before server is ready, fail the startup
    if (!_serverReady.isCompleted) {
      _serverReady.completeError(Exception('Canvas MCP Server startup failed: $line'));
    }
  }

  /// Handle server process exit
  void _handleServerExit(int exitCode) {
    print('🛑 Canvas MCP Server exited with code: $exitCode');
    _isRunning = false;
    
    if (!_serverReady.isCompleted) {
      _serverReady.completeError(Exception('Canvas MCP Server exited unexpectedly with code: $exitCode'));
    }
  }

  /// Register server with MCP catalog
  Future<void> _registerWithCatalog() async {
    try {
      final catalog = ServiceLocator.instance.get<MCPCatalogService>();
      
      await catalog.registerServer({
        'id': 'asmbli-canvas-mcp',
        'name': serverName,
        'version': serverVersion,
        'description': serverDescription,
        'type': 'builtin',
        'status': 'running',
        'capabilities': [
          'canvas_design',
          'ui_generation', 
          'code_export',
          'design_systems'
        ],
        'tools': [
          'create_element',
          'modify_element', 
          'delete_element',
          'render_design',
          'export_code',
          'clear_canvas',
          'get_canvas_state',
          'undo',
          'redo',
          'load_design_system',
          'align_elements',
        ],
        'pid': _serverProcess?.pid,
      });

      print('✅ Canvas MCP Server registered with catalog');

    } catch (e) {
      print('❌ Failed to register Canvas MCP Server with catalog: $e');
    }
  }

  /// Unregister server from MCP catalog
  Future<void> _unregisterFromCatalog() async {
    try {
      final catalog = ServiceLocator.instance.get<MCPCatalogService>();
      await catalog.unregisterServer('asmbli-canvas-mcp');
      print('✅ Canvas MCP Server unregistered from catalog');
    } catch (e) {
      print('❌ Failed to unregister Canvas MCP Server from catalog: $e');
    }
  }

  /// Get server health status
  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'isRunning': _isRunning,
      'pid': _serverProcess?.pid,
      'serverName': serverName,
      'version': serverVersion,
      'uptime': _isRunning ? DateTime.now().millisecondsSinceEpoch : null,
    };
  }

  /// Check if server is responsive
  Future<bool> checkServerHealth() async {
    if (!_isRunning) return false;

    try {
      final mcpBridge = ServiceLocator.instance.get<MCPBridgeService>();
      final result = await mcpBridge.callCanvasTool('get_canvas_state', {});
      return result['success'] == true;
    } catch (e) {
      print('❌ Canvas MCP Server health check failed: $e');
      return false;
    }
  }
}