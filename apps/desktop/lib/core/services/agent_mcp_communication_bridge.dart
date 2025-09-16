import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_terminal.dart';
import '../models/mcp_server_process.dart';
import '../models/mcp_connection.dart';
import 'agent_terminal_manager.dart';
import 'mcp_process_manager.dart';
import 'json_rpc_communication_service.dart';
import 'production_logger.dart';

/// Bridge service for seamless communication between agents and MCP tools
class AgentMCPCommunicationBridge {
  final AgentTerminalManager _terminalManager;
  final MCPProcessManager _processManager;
  final JsonRpcCommunicationService _rpcService;
  final Map<String, Map<String, String>> _agentCredentials = {};
  final Map<String, StreamSubscription> _outputSubscriptions = {};

  AgentMCPCommunicationBridge(
    this._terminalManager,
    this._processManager,
    this._rpcService,
  );

  /// Execute MCP tool call through agent's terminal
  Future<MCPToolResult> executeMCPTool(
    String agentId,
    String serverId,
    String toolName,
    Map<String, dynamic> parameters, {
    Duration? timeout,
  }) async {
    try {
      ProductionLogger.instance.info(
        'Executing MCP tool through agent',
        data: {
          'agent_id': agentId,
          'server_id': serverId,
          'tool_name': toolName,
          'parameters': parameters,
        },
        category: 'mcp_communication',
      );

      // Validate agent terminal exists
      final terminal = _terminalManager.getTerminal(agentId);
      if (terminal == null) {
        throw MCPCommunicationException('No terminal found for agent $agentId');
      }

      // Find MCP server process
      final serverProcess = terminal.mcpServers
          .where((s) => s.serverId == serverId)
          .firstOrNull;
      
      if (serverProcess == null) {
        throw MCPCommunicationException('MCP server $serverId not found for agent $agentId');
      }

      // Ensure server is running
      if (serverProcess.status != MCPServerStatus.running) {
        throw MCPCommunicationException('MCP server $serverId is not running (status: ${serverProcess.status})');
      }

      // Execute tool call via JSON-RPC
      final result = await _executeToolCall(
        agentId: agentId,
        serverProcess: serverProcess,
        toolName: toolName,
        parameters: parameters,
        timeout: timeout ?? const Duration(minutes: 2),
      );

      // Format result for conversation integration
      final formattedResult = await _formatResultForConversation(
        agentId: agentId,
        serverId: serverId,
        toolName: toolName,
        result: result,
      );

      ProductionLogger.instance.info(
        'MCP tool execution completed',
        data: {
          'agent_id': agentId,
          'server_id': serverId,
          'tool_name': toolName,
          'success': formattedResult.success,
          'execution_time_ms': formattedResult.executionTime.inMilliseconds,
        },
        category: 'mcp_communication',
      );

      return formattedResult;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to execute MCP tool',
        error: e,
        data: {
          'agent_id': agentId,
          'server_id': serverId,
          'tool_name': toolName,
        },
        category: 'mcp_communication',
      );
      rethrow;
    }
  }

  /// Set up secure credential management for MCP server authentication
  Future<void> setupCredentialsForAgent(
    String agentId,
    String serverId,
    Map<String, String> credentials,
  ) async {
    try {
      ProductionLogger.instance.info(
        'Setting up credentials for agent MCP server',
        data: {
          'agent_id': agentId,
          'server_id': serverId,
          'credential_keys': credentials.keys.toList(),
        },
        category: 'mcp_communication',
      );

      // Store credentials securely (in production, this would use secure storage)
      _agentCredentials[agentId] ??= {};
      _agentCredentials[agentId]![serverId] = jsonEncode(credentials);

      // Inject credentials into agent's terminal environment
      final terminal = _terminalManager.getTerminal(agentId);
      if (terminal != null) {
        for (final entry in credentials.entries) {
          await terminal.setEnvironment(entry.key, entry.value);
        }
      }

      ProductionLogger.instance.info(
        'Credentials set up successfully',
        data: {'agent_id': agentId, 'server_id': serverId},
        category: 'mcp_communication',
      );
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to setup credentials for agent',
        error: e,
        data: {'agent_id': agentId, 'server_id': serverId},
        category: 'mcp_communication',
      );
      rethrow;
    }
  }

  /// Get available tools for agent's MCP servers
  Future<List<MCPToolInfo>> getAvailableToolsForAgent(String agentId) async {
    try {
      final terminal = _terminalManager.getTerminal(agentId);
      if (terminal == null) {
        return [];
      }

      final allTools = <MCPToolInfo>[];

      for (final serverProcess in terminal.mcpServers) {
        if (serverProcess.status == MCPServerStatus.running) {
          try {
            final tools = await _getServerTools(agentId, serverProcess);
            allTools.addAll(tools);
          } catch (e) {
            ProductionLogger.instance.warning(
              'Failed to get tools from MCP server',
              data: {
                'agent_id': agentId,
                'server_id': serverProcess.serverId,
                'error': e.toString(),
              },
              category: 'mcp_communication',
            );
          }
        }
      }

      ProductionLogger.instance.info(
        'Retrieved available tools for agent',
        data: {
          'agent_id': agentId,
          'tool_count': allTools.length,
          'tools': allTools.map((t) => '${t.serverId}:${t.name}').toList(),
        },
        category: 'mcp_communication',
      );

      return allTools;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to get available tools for agent',
        error: e,
        data: {'agent_id': agentId},
        category: 'mcp_communication',
      );
      return [];
    }
  }

  /// Stream MCP server outputs for agent
  Stream<MCPServerOutput> streamMCPOutputForAgent(String agentId) async* {
    final terminal = _terminalManager.getTerminal(agentId);
    if (terminal == null) return;

    final controller = StreamController<MCPServerOutput>();

    // Subscribe to each MCP server's output
    for (final serverProcess in terminal.mcpServers) {
      try {
        final outputStream = _rpcService.streamServerOutput(serverProcess.id);
        final subscription = outputStream.listen(
          (output) {
            controller.add(MCPServerOutput(
              agentId: agentId,
              serverId: serverProcess.serverId,
              content: output,
              timestamp: DateTime.now(),
              type: MCPOutputType.stdout,
            ));
          },
          onError: (error) {
            controller.add(MCPServerOutput(
              agentId: agentId,
              serverId: serverProcess.serverId,
              content: 'Error: $error',
              timestamp: DateTime.now(),
              type: MCPOutputType.error,
            ));
          },
        );

        _outputSubscriptions['${agentId}:${serverProcess.serverId}'] = subscription;
      } catch (e) {
        ProductionLogger.instance.warning(
          'Failed to stream output from MCP server',
          data: {
            'agent_id': agentId,
            'server_id': serverProcess.serverId,
            'error': e.toString(),
          },
          category: 'mcp_communication',
        );
      }
    }

    yield* controller.stream;
  }

  /// Execute tool call via JSON-RPC
  Future<Map<String, dynamic>> _executeToolCall({
    required String agentId,
    required MCPServerProcess serverProcess,
    required String toolName,
    required Map<String, dynamic> parameters,
    required Duration timeout,
  }) async {
    final startTime = DateTime.now();

    try {
      // Prepare JSON-RPC request
      final request = {
        'jsonrpc': '2.0',
        'id': '${agentId}_${DateTime.now().millisecondsSinceEpoch}',
        'method': 'tools/call',
        'params': {
          'name': toolName,
          'arguments': parameters,
        },
      };

      // Send request to MCP server
      final response = await _rpcService.sendRequest(
        agentId: serverProcess.agentId,
        serverId: serverProcess.serverId,
        method: 'tools/call',
        params: {
          'name': toolName,
          'arguments': parameters,
        },
        timeout: timeout,
      );

      // Validate response
      if (response.isError) {
        throw MCPCommunicationException(
          'MCP server returned error: ${response.error}',
        );
      }

      return response.result ?? {};
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime);
      
      ProductionLogger.instance.error(
        'Tool call execution failed',
        error: e,
        data: {
          'agent_id': agentId,
          'server_id': serverProcess.serverId,
          'tool_name': toolName,
          'execution_time_ms': executionTime.inMilliseconds,
        },
        category: 'mcp_communication',
      );
      
      rethrow;
    }
  }

  /// Format MCP result for conversation integration
  Future<MCPToolResult> _formatResultForConversation({
    required String agentId,
    required String serverId,
    required String toolName,
    required Map<String, dynamic> result,
  }) async {
    final executionTime = DateTime.now().difference(DateTime.now());
    
    try {
      // Extract content from result
      String content = '';
      bool success = true;
      String? error;

      if (result.containsKey('content')) {
        final contentList = result['content'] as List?;
        if (contentList != null && contentList.isNotEmpty) {
          // Handle different content types
          final contentItems = <String>[];
          for (final item in contentList) {
            if (item is Map<String, dynamic>) {
              if (item['type'] == 'text' && item['text'] != null) {
                contentItems.add(item['text'] as String);
              } else if (item['type'] == 'image' && item['data'] != null) {
                contentItems.add('[Image data: ${item['data'].toString().length} bytes]');
              } else {
                contentItems.add(item.toString());
              }
            } else {
              contentItems.add(item.toString());
            }
          }
          content = contentItems.join('\n');
        }
      } else if (result.containsKey('text')) {
        content = result['text'] as String;
      } else {
        content = jsonEncode(result);
      }

      // Check for errors
      if (result.containsKey('isError') && result['isError'] == true) {
        success = false;
        error = result['error']?.toString() ?? 'Unknown error';
      }

      return MCPToolResult(
        agentId: agentId,
        serverId: serverId,
        toolName: toolName,
        success: success,
        content: content,
        rawResult: result,
        error: error,
        executionTime: executionTime,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return MCPToolResult(
        agentId: agentId,
        serverId: serverId,
        toolName: toolName,
        success: false,
        content: '',
        rawResult: result,
        error: 'Failed to format result: $e',
        executionTime: executionTime,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get available tools from MCP server
  Future<List<MCPToolInfo>> _getServerTools(
    String agentId,
    MCPServerProcess serverProcess,
  ) async {
    try {
      final request = {
        'jsonrpc': '2.0',
        'id': '${agentId}_tools_${DateTime.now().millisecondsSinceEpoch}',
        'method': 'tools/list',
        'params': {},
      };

      final response = await _rpcService.sendRequest(
        agentId: serverProcess.agentId,
        serverId: serverProcess.serverId,
        method: 'tools/list',
        timeout: const Duration(seconds: 10),
      );

      if (response.isError) {
        throw MCPCommunicationException(
          'Failed to list tools: ${response.error}',
        );
      }

      final result = response.result;
      final tools = result?['tools'] as List?;

      if (tools == null) return [];

      return tools.map((tool) {
        final toolMap = tool as Map<String, dynamic>;
        return MCPToolInfo(
          serverId: serverProcess.serverId,
          name: toolMap['name'] as String,
          description: toolMap['description'] as String? ?? '',
          parameters: toolMap['inputSchema'] as Map<String, dynamic>? ?? {},
        );
      }).toList();
    } catch (e) {
      ProductionLogger.instance.warning(
        'Failed to get tools from server',
        data: {
          'agent_id': agentId,
          'server_id': serverProcess.serverId,
          'error': e.toString(),
        },
        category: 'mcp_communication',
      );
      return [];
    }
  }

  /// Clean up resources for agent
  Future<void> cleanupAgent(String agentId) async {
    try {
      ProductionLogger.instance.info(
        'Cleaning up MCP communication resources for agent',
        data: {'agent_id': agentId},
        category: 'mcp_communication',
      );

      // Cancel output subscriptions
      final subscriptionsToCancel = _outputSubscriptions.entries
          .where((entry) => entry.key.startsWith('$agentId:'))
          .toList();

      for (final entry in subscriptionsToCancel) {
        await entry.value.cancel();
        _outputSubscriptions.remove(entry.key);
      }

      // Clear credentials
      _agentCredentials.remove(agentId);

      ProductionLogger.instance.info(
        'MCP communication cleanup completed',
        data: {
          'agent_id': agentId,
          'cancelled_subscriptions': subscriptionsToCancel.length,
        },
        category: 'mcp_communication',
      );
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to cleanup MCP communication for agent',
        error: e,
        data: {'agent_id': agentId},
        category: 'mcp_communication',
      );
    }
  }

  /// Get credentials for agent's MCP server
  Map<String, String>? getCredentialsForAgent(String agentId, String serverId) {
    final agentCreds = _agentCredentials[agentId];
    if (agentCreds == null) return null;

    final credentialsJson = agentCreds[serverId];
    if (credentialsJson == null) return null;

    try {
      final decoded = jsonDecode(credentialsJson) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      ProductionLogger.instance.warning(
        'Failed to decode credentials for agent',
        data: {'agent_id': agentId, 'server_id': serverId, 'error': e.toString()},
        category: 'mcp_communication',
      );
      return null;
    }
  }

  /// Dispose and cleanup all resources
  Future<void> dispose() async {
    // Cancel all subscriptions
    final futures = _outputSubscriptions.values.map((sub) => sub.cancel());
    await Future.wait(futures, eagerError: false);
    
    _outputSubscriptions.clear();
    _agentCredentials.clear();
    
    ProductionLogger.instance.info(
      'Agent MCP communication bridge disposed',
      category: 'mcp_communication',
    );
  }
}

/// Result of MCP tool execution
class MCPToolResult {
  final String agentId;
  final String serverId;
  final String toolName;
  final bool success;
  final String content;
  final Map<String, dynamic> rawResult;
  final String? error;
  final Duration executionTime;
  final DateTime timestamp;

  const MCPToolResult({
    required this.agentId,
    required this.serverId,
    required this.toolName,
    required this.success,
    required this.content,
    required this.rawResult,
    this.error,
    required this.executionTime,
    required this.timestamp,
  });

  /// Convert to conversation-friendly format
  String toConversationFormat() {
    if (!success) {
      return 'Error executing $toolName: ${error ?? 'Unknown error'}';
    }

    if (content.isEmpty) {
      return '$toolName executed successfully (no output)';
    }

    return content;
  }

  /// Convert to JSON for logging/storage
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'serverId': serverId,
      'toolName': toolName,
      'success': success,
      'content': content,
      'rawResult': rawResult,
      'error': error,
      'executionTimeMs': executionTime.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Information about available MCP tool
class MCPToolInfo {
  final String serverId;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const MCPToolInfo({
    required this.serverId,
    required this.name,
    required this.description,
    required this.parameters,
  });

  /// Get full tool identifier
  String get fullName => '$serverId:$name';
}

/// MCP server output for streaming
class MCPServerOutput {
  final String agentId;
  final String serverId;
  final String content;
  final DateTime timestamp;
  final MCPOutputType type;

  const MCPServerOutput({
    required this.agentId,
    required this.serverId,
    required this.content,
    required this.timestamp,
    required this.type,
  });
}

/// Type of MCP server output
enum MCPOutputType {
  stdout,
  stderr,
  error,
  system,
}

/// Exception for MCP communication errors
class MCPCommunicationException implements Exception {
  final String message;
  
  MCPCommunicationException(this.message);

  @override
  String toString() => 'MCPCommunicationException: $message';
}

// ==================== Riverpod Provider ====================

final agentMCPCommunicationBridgeProvider = Provider<AgentMCPCommunicationBridge>((ref) {
  final terminalManager = ref.read(agentTerminalManagerProvider);
  final processManager = ref.read(mcpProcessManagerProvider);
  final rpcService = ref.read(jsonRpcCommunicationServiceProvider);
  
  return AgentMCPCommunicationBridge(
    terminalManager,
    processManager,
    rpcService,
  );
});