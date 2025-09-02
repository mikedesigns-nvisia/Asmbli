import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import 'mcp_server_execution_service.dart';
import 'context_resource_server.dart';

/// Service that bridges MCP server execution with conversation flow
/// Handles resource serving, tool execution, and context integration
class MCPConversationBridgeService {
  final MCPServerExecutionService _executionService;
  final Map<String, StreamController<MCPServerMessage>> _messageStreams = {};
  final Map<String, ContextResourceServer> _contextServers = {};
  
  MCPConversationBridgeService(this._executionService);
  
  /// Initialize MCP servers for a conversation with an agent
  Future<MCPConversationSession> initializeConversationMCP(
    String conversationId,
    Agent agent,
    Map<String, String> environmentVars,
  ) async {
    try {
      // Start MCP servers for the agent
      final serverProcesses = await _executionService.startAgentMCPServers(
        agent,
        environmentVars,
      );
      
      // Setup context resource server if agent has context documents
      await _setupContextResourceServer(agent, conversationId);
      
      // Create message stream for this conversation
      final messageStream = StreamController<MCPServerMessage>.broadcast();
      _messageStreams[conversationId] = messageStream;
      
      // Setup server message forwarding
      for (final server in serverProcesses) {
        _setupServerMessageForwarding(server, conversationId);
      }
      
      return MCPConversationSession(
        conversationId: conversationId,
        agentId: agent.id,
        serverProcesses: serverProcesses,
        messageStream: messageStream.stream,
        startTime: DateTime.now(),
      );
      
    } catch (e) {
      print('❌ Failed to initialize MCP for conversation $conversationId: $e');
      rethrow;
    }
  }
  
  /// Setup context resource server for agent context documents
  Future<void> _setupContextResourceServer(Agent agent, String conversationId) async {
    try {
      // For now, we'll create a placeholder context server setup
      // In a full implementation, this would create an actual server instance
      print('📋 Context resources configured for agent ${agent.id} in conversation $conversationId');
    } catch (e) {
      print('⚠️ Failed to setup context resources: $e');
      // Don't fail the entire initialization for context issues
    }
  }
  
  /// Setup message forwarding from server to conversation
  void _setupServerMessageForwarding(MCPServerProcess server, String conversationId) {
    if (server.transport == MCPTransport.stdio && server.process != null) {
      // Listen for server messages/notifications
      server.process!.stdout
          .transform(utf8.decoder)
          .listen((data) {
        _handleServerOutput(server.id, conversationId, data);
      });
    }
  }
  
  /// Handle output from MCP server
  void _handleServerOutput(String serverId, String conversationId, String data) {
    try {
      final lines = data.split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final message = json.decode(line) as Map<String, dynamic>;
          
          // Check if it's a notification or unsolicited message
          if (!message.containsKey('id') || message['id'] == null) {
            _forwardServerMessage(serverId, conversationId, message);
          }
        } catch (e) {
          // Ignore non-JSON output
        }
      }
    } catch (e) {
      print('⚠️ Error handling server output from $serverId: $e');
    }
  }
  
  /// Forward server message to conversation stream
  void _forwardServerMessage(
    String serverId, 
    String conversationId, 
    Map<String, dynamic> message,
  ) {
    final messageStream = _messageStreams[conversationId];
    if (messageStream != null && !messageStream.isClosed) {
      final serverMessage = MCPServerMessage(
        serverId: serverId,
        conversationId: conversationId,
        message: message,
        timestamp: DateTime.now(),
      );
      
      messageStream.add(serverMessage);
    }
  }
  
  /// Execute MCP tool on behalf of the agent
  Future<MCPToolResult> executeMCPTool(
    String conversationId,
    String serverId,
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      // Send tool execution request to MCP server
      final response = await _executionService.sendMCPRequest(
        serverId,
        'tools/call',
        {
          'name': toolName,
          'arguments': arguments,
        },
      );
      
      // Log tool execution
      _logToolExecution(conversationId, serverId, toolName, arguments, response);
      
      return MCPToolResult(
        toolName: toolName,
        serverId: serverId,
        success: !response.containsKey('error'),
        result: response['result'],
        error: response['error'],
        executionTime: DateTime.now(),
      );
      
    } catch (e) {
      print('❌ Tool execution failed: $toolName on $serverId: $e');
      
      return MCPToolResult(
        toolName: toolName,
        serverId: serverId,
        success: false,
        result: null,
        error: {'message': e.toString()},
        executionTime: DateTime.now(),
      );
    }
  }
  
  /// Get available tools from MCP servers
  Future<List<MCPToolDefinition>> getAvailableTools(String conversationId) async {
    final tools = <MCPToolDefinition>[];
    
    // Get all running servers for this conversation
    final runningServers = _executionService.getRunningServers();
    
    for (final server in runningServers) {
      try {
        final response = await _executionService.sendMCPRequest(
          server.id,
          'tools/list',
          {},
        );
        
        final serverTools = response['result']?['tools'] as List<dynamic>? ?? [];
        
        for (final toolData in serverTools) {
          final tool = toolData as Map<String, dynamic>;
          tools.add(MCPToolDefinition(
            name: tool['name'] as String,
            description: tool['description'] as String,
            serverId: server.id,
            serverName: server.config.name,
            inputSchema: tool['inputSchema'] as Map<String, dynamic>? ?? {},
          ));
        }
      } catch (e) {
        print('⚠️ Failed to get tools from server ${server.id}: $e');
      }
    }
    
    return tools;
  }
  
  /// Get available resources from MCP servers
  Future<List<MCPResourceDefinition>> getAvailableResources(String conversationId) async {
    final resources = <MCPResourceDefinition>[];
    
    // Get all running servers for this conversation
    final runningServers = _executionService.getRunningServers();
    
    for (final server in runningServers) {
      try {
        final response = await _executionService.sendMCPRequest(
          server.id,
          'resources/list',
          {},
        );
        
        final serverResources = response['result']?['resources'] as List<dynamic>? ?? [];
        
        for (final resourceData in serverResources) {
          final resource = resourceData as Map<String, dynamic>;
          resources.add(MCPResourceDefinition(
            uri: resource['uri'] as String,
            name: resource['name'] as String? ?? resource['uri'],
            description: resource['description'] as String?,
            mimeType: resource['mimeType'] as String?,
            serverId: server.id,
            serverName: server.config.name,
          ));
        }
      } catch (e) {
        print('⚠️ Failed to get resources from server ${server.id}: $e');
      }
    }
    
    // Context resources would be added here in a full implementation
    // For now, we'll log that context resources are available
    print('📋 Context resources would be listed here for conversation $conversationId');
    
    return resources;
  }
  
  /// Read resource content from MCP server
  Future<MCPResourceContent> readMCPResource(
    String conversationId,
    String serverId,
    String resourceUri,
  ) async {
    try {
      final response = await _executionService.sendMCPRequest(
        serverId,
        'resources/read',
        {
          'uri': resourceUri,
        },
      );
      
      final contents = response['result']?['contents'] as List<dynamic>? ?? [];
      if (contents.isEmpty) {
        throw Exception('No content returned for resource $resourceUri');
      }
      
      final content = contents.first as Map<String, dynamic>;
      
      return MCPResourceContent(
        uri: resourceUri,
        mimeType: content['mimeType'] as String?,
        text: content['text'] as String?,
        blob: content['blob'] as String?, // Base64 encoded
        serverId: serverId,
        readTime: DateTime.now(),
      );
      
    } catch (e) {
      print('❌ Resource read failed: $resourceUri from $serverId: $e');
      rethrow;
    }
  }
  
  /// Log tool execution for debugging and monitoring
  void _logToolExecution(
    String conversationId,
    String serverId,
    String toolName,
    Map<String, dynamic> arguments,
    Map<String, dynamic> response,
  ) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'conversationId': conversationId,
      'serverId': serverId,
      'toolName': toolName,
      'arguments': arguments,
      'response': response,
      'success': !response.containsKey('error'),
    };
    
    print('🔧 Tool executed: ${json.encode(logEntry)}');
  }
  
  /// Cleanup conversation MCP session
  Future<void> cleanupConversationMCP(String conversationId) async {
    try {
      // Close message stream
      final messageStream = _messageStreams[conversationId];
      if (messageStream != null) {
        await messageStream.close();
        _messageStreams.remove(conversationId);
      }
      
      // Context server cleanup would be done here
      print('🧹 Context server cleanup for conversation $conversationId');
      
      // Note: We don't stop the main MCP servers here as they may be used
      // by other conversations. Server lifecycle is managed separately.
      
      print('✅ Cleaned up MCP session for conversation $conversationId');
    } catch (e) {
      print('⚠️ Error cleaning up MCP session: $e');
    }
  }
  
  /// Get conversation session status
  MCPConversationSessionStatus getSessionStatus(String conversationId) {
    final messageStream = _messageStreams[conversationId];
    final hasActiveStream = messageStream != null && !messageStream.isClosed;
    
    final runningServers = _executionService.getRunningServers();
    final healthyServers = runningServers.where((s) => s.isHealthy).length;
    
    return MCPConversationSessionStatus(
      conversationId: conversationId,
      isActive: hasActiveStream,
      serverCount: runningServers.length,
      healthyServerCount: healthyServers,
      hasContextResources: false, // Placeholder - would check actual context server status
    );
  }
}

/// MCP conversation session
class MCPConversationSession {
  final String conversationId;
  final String agentId;
  final List<MCPServerProcess> serverProcesses;
  final Stream<MCPServerMessage> messageStream;
  final DateTime startTime;
  
  MCPConversationSession({
    required this.conversationId,
    required this.agentId,
    required this.serverProcesses,
    required this.messageStream,
    required this.startTime,
  });
  
  Duration get duration => DateTime.now().difference(startTime);
  
  bool get isActive => serverProcesses.any((s) => s.isHealthy);
  
  List<String> get serverIds => serverProcesses.map((s) => s.id).toList();
}

/// Message from MCP server
class MCPServerMessage {
  final String serverId;
  final String conversationId;
  final Map<String, dynamic> message;
  final DateTime timestamp;
  
  MCPServerMessage({
    required this.serverId,
    required this.conversationId,
    required this.message,
    required this.timestamp,
  });
}

/// Tool execution result
class MCPToolResult {
  final String toolName;
  final String serverId;
  final bool success;
  final dynamic result;
  final dynamic error;
  final DateTime executionTime;
  
  MCPToolResult({
    required this.toolName,
    required this.serverId,
    required this.success,
    required this.result,
    required this.error,
    required this.executionTime,
  });
}

/// Tool definition from MCP server
class MCPToolDefinition {
  final String name;
  final String description;
  final String serverId;
  final String serverName;
  final Map<String, dynamic> inputSchema;
  
  MCPToolDefinition({
    required this.name,
    required this.description,
    required this.serverId,
    required this.serverName,
    required this.inputSchema,
  });
}

/// Resource definition from MCP server
class MCPResourceDefinition {
  final String uri;
  final String name;
  final String? description;
  final String? mimeType;
  final String serverId;
  final String serverName;
  
  MCPResourceDefinition({
    required this.uri,
    required this.name,
    required this.description,
    required this.mimeType,
    required this.serverId,
    required this.serverName,
  });
}

/// Resource content from MCP server
class MCPResourceContent {
  final String uri;
  final String? mimeType;
  final String? text;
  final String? blob; // Base64 encoded
  final String serverId;
  final DateTime readTime;
  
  MCPResourceContent({
    required this.uri,
    required this.mimeType,
    required this.text,
    required this.blob,
    required this.serverId,
    required this.readTime,
  });
}

/// Conversation session status
class MCPConversationSessionStatus {
  final String conversationId;
  final bool isActive;
  final int serverCount;
  final int healthyServerCount;
  final bool hasContextResources;
  
  MCPConversationSessionStatus({
    required this.conversationId,
    required this.isActive,
    required this.serverCount,
    required this.healthyServerCount,
    required this.hasContextResources,
  });
}

/// Provider for MCP conversation bridge service
final mcpConversationBridgeServiceProvider = Provider<MCPConversationBridgeService>((ref) {
  final executionService = ref.watch(mcpServerExecutionServiceProvider);
  return MCPConversationBridgeService(executionService);
});