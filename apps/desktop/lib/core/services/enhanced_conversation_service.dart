import 'dart:async';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/models/agent.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'business/base_business_service.dart';
import 'llm/unified_llm_service.dart';
import 'llm/llm_provider.dart';
import 'agent_mcp_configuration_service.dart';
import 'dynamic_mcp_server_manager.dart';
import 'llm_tool_call_parser.dart';
import 'mcp_bridge_service.dart';
import 'context_mcp_resource_service.dart';
import 'agent_context_prompt_service.dart';
import '../utils/null_safety_utils.dart';

/// Enhanced conversation service with integrated MCP tool support
/// Provides seamless integration between agents, LLMs, and GitHub MCP registry tools
class EnhancedConversationService extends BaseBusinessService {
  final UnifiedLLMService _llmService;
  final AgentMCPConfigurationService _agentMCPService;
  final DynamicMCPServerManager _mcpServerManager;
  final LLMToolCallParser _toolCallParser;
  final MCPBridgeService _mcpBridge;
  final ContextMCPResourceService _contextService;
  final AgentContextPromptService _promptService;
  final BusinessEventBus _eventBus;

  EnhancedConversationService({
    required UnifiedLLMService llmService,
    required AgentMCPConfigurationService agentMCPService,
    required DynamicMCPServerManager mcpServerManager,
    required LLMToolCallParser toolCallParser,
    required MCPBridgeService mcpBridge,
    required ContextMCPResourceService contextService,
    required AgentContextPromptService promptService,
    BusinessEventBus? eventBus,
  })  : _llmService = llmService,
        _agentMCPService = agentMCPService,
        _mcpServerManager = mcpServerManager,
        _toolCallParser = toolCallParser,
        _mcpBridge = mcpBridge,
        _contextService = contextService,
        _promptService = promptService,
        _eventBus = eventBus ?? BusinessEventBus();

  /// Process message with integrated MCP tool support
  Future<BusinessResult<EnhancedMessage>> processMessageWithMCPTools({
    required String conversationId,
    required String content,
    required String modelId,
    required Agent agent,
    List<String> contextDocs = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    return handleBusinessOperation('processMessageWithMCPTools', () async {
      // 1. Start agent MCP servers
      await _ensureAgentMCPServersRunning(agent.id);

      // 2. Get agent's enabled MCP servers
      final enabledServerIds = await _agentMCPService.getEnabledMCPServerIds(agent.id);

      // 3. Build enhanced context with MCP capabilities
      final enhancedContext = await _buildEnhancedContext(
        conversationId: conversationId,
        userContent: content,
        agent: agent,
        enabledServerIds: enabledServerIds,
        contextDocs: contextDocs,
      );

      // 4. Generate initial LLM response
      final llmResponse = await _llmService.generate(
        prompt: enhancedContext.prompt,
        modelId: modelId,
        context: enhancedContext.context,
      );

      // 5. Parse response for tool calls
      final toolCalls = LLMToolCallParser.parseToolCalls(llmResponse.content);

      // 6. Execute tool calls if found
      final toolResults = <ToolExecutionResult>[];
      if (toolCalls.isNotEmpty) {
        for (final toolCall in toolCalls) {
          final result = await _executeMCPToolCall(
            agent.id,
            toolCall,
            enabledServerIds,
          );
          toolResults.add(result);
        }
      }

      // 7. Generate final response incorporating tool results
      final finalResponse = await _generateFinalResponse(
        originalResponse: llmResponse.content,
        toolResults: toolResults,
        modelId: modelId,
        agent: agent,
      );

      // 8. Create enhanced message
      final enhancedMessage = EnhancedMessage(
        id: const Uuid().v4(),
        content: finalResponse,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        metadata: {
          'conversationId': conversationId,
          'modelUsed': llmResponse.modelUsed,
          'agentId': agent.id,
          'mcpServersUsed': enabledServerIds,
          'toolCallsExecuted': toolCalls.length,
          'toolResults': toolResults.map((r) => r.toMap()).toList(),
          'hasGlobalContext': contextDocs.isNotEmpty,
          ...metadata,
        },
        toolCalls: toolCalls,
        toolResults: toolResults,
        agent: agent,
      );

      // 9. Mark MCP servers as used
      for (final serverId in enabledServerIds) {
        await _agentMCPService.markMCPServerUsed(agent.id, serverId);
      }

      return BusinessResult.success(enhancedMessage);
    });
  }

  /// Stream message processing with MCP tool integration
  Stream<EnhancedMessageChunk> processMessageStreamWithMCPTools({
    required String conversationId,
    required String content,
    required String modelId,
    required Agent agent,
    List<String> contextDocs = const [],
    Map<String, dynamic> metadata = const {},
  }) async* {
    try {
      // Start MCP servers
      await _ensureAgentMCPServersRunning(agent.id);
      final enabledServerIds = await _agentMCPService.getEnabledMCPServerIds(agent.id);

      yield EnhancedMessageChunk.info('MCP servers initialized');

      // Build context
      final enhancedContext = await _buildEnhancedContext(
        conversationId: conversationId,
        userContent: content,
        agent: agent,
        enabledServerIds: enabledServerIds,
        contextDocs: contextDocs,
      );

      yield EnhancedMessageChunk.info('Context prepared');

      // Stream LLM response
      final contentBuffer = StringBuffer();
      await for (final chunk in _llmService.chatStream(
        message: enhancedContext.prompt,
        modelId: modelId,
        context: ChatContext(metadata: enhancedContext.context),
      )) {
        contentBuffer.write(chunk);
        yield EnhancedMessageChunk.content(chunk);
      }

      final fullResponse = contentBuffer.toString();

      // Parse and execute tool calls
      final toolCalls = LLMToolCallParser.parseToolCalls(fullResponse);
      if (toolCalls.isNotEmpty) {
        yield EnhancedMessageChunk.info('Found ${toolCalls.length} tool calls');

        final toolResults = <ToolExecutionResult>[];
        for (final toolCall in toolCalls) {
          yield EnhancedMessageChunk.toolExecution(toolCall.name);

          final result = await _executeMCPToolCall(
            agent.id,
            toolCall,
            enabledServerIds,
          );
          toolResults.add(result);

          yield EnhancedMessageChunk.toolResult(result);
        }

        // Generate final response with tool results
        yield EnhancedMessageChunk.info('Integrating tool results');

        final finalResponse = await _generateFinalResponse(
          originalResponse: fullResponse,
          toolResults: toolResults,
          modelId: modelId,
          agent: agent,
        );

        yield EnhancedMessageChunk.finalContent(finalResponse);
      }

      yield EnhancedMessageChunk.complete();

    } catch (e) {
      yield EnhancedMessageChunk.error('Processing failed: $e');
    }
  }

  /// Get available MCP tools for agent
  Future<List<AvailableMCPTool>> getAvailableMCPTools(String agentId) async {
    final configs = await _agentMCPService.getAgentMCPConfigs(agentId);
    final tools = <AvailableMCPTool>[];

    for (final config in configs.where((c) => c.isEnabled)) {
      final serverProcess = _mcpServerManager.getAgentMCPServer(agentId, config.serverId);
      final isRunning = serverProcess?.isHealthy ?? false;

      tools.add(AvailableMCPTool(
        serverId: config.serverId,
        serverName: config.serverConfig.name,
        capabilities: config.serverConfig.capabilities ?? [],
        isRunning: isRunning,
        lastUsed: config.lastUsed,
        priority: config.priority,
      ));
    }

    // Sort by priority and running status
    tools.sort((a, b) {
      if (a.isRunning != b.isRunning) return b.isRunning ? 1 : -1;
      return b.priority.compareTo(a.priority);
    });

    return tools;
  }

  /// Enable GitHub MCP tool for agent
  Future<BusinessResult<void>> enableGitHubMCPToolForAgent(
    String agentId,
    String catalogEntryId, {
    Map<String, String> environmentVars = const {},
    List<String> requiredCapabilities = const [],
    int priority = 0,
  }) async {
    return handleBusinessOperation('enableGitHubMCPToolForAgent', () async {
      await _agentMCPService.enableGitHubMCPToolForAgent(
        agentId,
        catalogEntryId,
        environmentVars: environmentVars,
        requiredCapabilities: requiredCapabilities,
        priority: priority,
      );

      return BusinessResult.success(null);
    });
  }

  // Private methods

  Future<void> _ensureAgentMCPServersRunning(String agentId) async {
    try {
      await _mcpServerManager.startAgentMCPServers(agentId);
    } catch (e) {
      debugPrint('⚠️ Failed to start MCP servers for agent $agentId: $e');
    }
  }

  Future<EnhancedContext> _buildEnhancedContext({
    required String conversationId,
    required String userContent,
    required Agent agent,
    required List<String> enabledServerIds,
    List<String> contextDocs = const [],
  }) async {
    final contextBuilder = NullSafetyUtils.createMapBuilder();

    // Add agent information
    contextBuilder.putString('agentId', agent.id);
    contextBuilder.putString('agentName', agent.name);
    contextBuilder.putString('agentDescription', agent.description);

    // Add MCP tool capabilities
    if (enabledServerIds.isNotEmpty) {
      final availableTools = await getAvailableMCPTools(agent.id);
      final toolDescriptions = availableTools
          .where((tool) => tool.isRunning)
          .map((tool) => '${tool.serverName}: ${tool.capabilities.join(", ")}')
          .toList();

      contextBuilder.putString('availableMCPTools', toolDescriptions.join('\n'));

      // Add tool usage instructions
      contextBuilder.putString('toolUsageInstructions', '''
You have access to MCP tools. To use a tool, respond with a tool call in this format:
<tool_call>
{
  "name": "tool_name",
  "arguments": {
    "param1": "value1",
    "param2": "value2"
  }
}
</tool_call>

Available tools: ${toolDescriptions.join(', ')}
''');
    }

    // Add context documents
    if (contextDocs.isNotEmpty) {
      final contextContent = await _contextService.getContextForDocuments(contextDocs);
      contextBuilder.putString('contextDocuments', contextContent);
    }

    // Build system prompt
    final systemPrompt = await _buildAgentSystemPrompt(agent, enabledServerIds);

    return EnhancedContext(
      prompt: userContent,
      systemPrompt: systemPrompt,
      context: contextBuilder.build(),
      availableTools: enabledServerIds,
    );
  }

  Future<String> _buildAgentSystemPrompt(Agent agent, List<String> enabledServerIds) async {
    var systemPrompt = '''
You are ${agent.name}, an AI assistant with the following description: ${agent.description}

Your capabilities include: ${agent.capabilities.join(', ')}
''';

    if (enabledServerIds.isNotEmpty) {
      systemPrompt += '''

You have access to MCP (Model Context Protocol) tools that extend your capabilities.
When you need to perform actions that require these tools, use the tool call format.
Always explain what you're doing when using tools.
''';
    }

    return systemPrompt;
  }

  Future<ToolExecutionResult> _executeMCPToolCall(
    String agentId,
    ParsedToolCall toolCall,
    List<String> enabledServerIds,
  ) async {
    try {
      // Determine which server to use for this tool
      final serverId = toolCall.serverId ??
          await _findBestServerForTool(agentId, toolCall.name, enabledServerIds);

      if (serverId == null) {
        return ToolExecutionResult(
          toolName: toolCall.name,
          serverId: 'unknown',
          success: false,
          result: null,
          error: 'No server found for tool: ${toolCall.name}',
          executionTime: DateTime.now(),
        );
      }

      // Execute the tool call
      final result = await _mcpBridge.callTool(
        toolCall.name,
        toolCall.arguments,
        serverId: serverId,
      );

      return ToolExecutionResult(
        toolName: toolCall.name,
        serverId: serverId,
        success: !result.containsKey('error'),
        result: result['result'],
        error: result['error']?.toString(),
        executionTime: DateTime.now(),
      );

    } catch (e) {
      return ToolExecutionResult(
        toolName: toolCall.name,
        serverId: 'error',
        success: false,
        result: null,
        error: e.toString(),
        executionTime: DateTime.now(),
      );
    }
  }

  Future<String?> _findBestServerForTool(
    String agentId,
    String toolName,
    List<String> enabledServerIds,
  ) async {
    final configs = await _agentMCPService.getAgentMCPConfigs(agentId);

    // Find servers that might have this tool
    for (final config in configs) {
      if (enabledServerIds.contains(config.serverId)) {
        final capabilities = config.serverConfig.capabilities ?? [];
        if (capabilities.contains(toolName) ||
            config.serverConfig.name.toLowerCase().contains(toolName.toLowerCase())) {
          return config.serverId;
        }
      }
    }

    // Fall back to first enabled server
    return enabledServerIds.isNotEmpty ? enabledServerIds.first : null;
  }

  Future<String> _generateFinalResponse(
    {
    required String originalResponse,
    required List<ToolExecutionResult> toolResults,
    required String modelId,
    required Agent agent,
  }) async {
    if (toolResults.isEmpty) {
      return originalResponse;
    }

    // If tool calls were executed, generate an enhanced response
    final toolSummary = toolResults.map((result) {
      if (result.success) {
        return '✅ ${result.toolName}: ${result.result}';
      } else {
        return '❌ ${result.toolName}: ${result.error}';
      }
    }).join('\n');

    final enhancedPrompt = '''
Original response: $originalResponse

Tool execution results:
$toolSummary

Please provide a comprehensive response that incorporates the tool results naturally into your answer.
Be helpful and explain what the tools accomplished.
''';

    try {
      final enhancedResponse = await _llmService.generate(
        prompt: enhancedPrompt,
        modelId: modelId,
        context: {
          'agentId': agent.id,
          'isToolResultIntegration': true,
        },
      );

      return enhancedResponse.content;
    } catch (e) {
      // Fall back to original response with tool summary
      return '$originalResponse\n\nTool Results:\n$toolSummary';
    }
  }
}

// Supporting classes

class EnhancedContext {
  final String prompt;
  final String systemPrompt;
  final Map<String, dynamic> context;
  final List<String> availableTools;

  const EnhancedContext({
    required this.prompt,
    required this.systemPrompt,
    required this.context,
    required this.availableTools,
  });
}

class EnhancedMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final List<ParsedToolCall> toolCalls;
  final List<ToolExecutionResult> toolResults;
  final Agent agent;

  const EnhancedMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    required this.metadata,
    required this.toolCalls,
    required this.toolResults,
    required this.agent,
  });
}

class EnhancedMessageChunk {
  final String type;
  final String? content;
  final String? info;
  final String? toolName;
  final ToolExecutionResult? toolResult;
  final String? error;

  const EnhancedMessageChunk._({
    required this.type,
    this.content,
    this.info,
    this.toolName,
    this.toolResult,
    this.error,
  });

  factory EnhancedMessageChunk.content(String content) =>
      EnhancedMessageChunk._(type: 'content', content: content);

  factory EnhancedMessageChunk.info(String info) =>
      EnhancedMessageChunk._(type: 'info', info: info);

  factory EnhancedMessageChunk.toolExecution(String toolName) =>
      EnhancedMessageChunk._(type: 'tool_execution', toolName: toolName);

  factory EnhancedMessageChunk.toolResult(ToolExecutionResult result) =>
      EnhancedMessageChunk._(type: 'tool_result', toolResult: result);

  factory EnhancedMessageChunk.finalContent(String content) =>
      EnhancedMessageChunk._(type: 'final_content', content: content);

  factory EnhancedMessageChunk.complete() =>
      EnhancedMessageChunk._(type: 'complete');

  factory EnhancedMessageChunk.error(String error) =>
      EnhancedMessageChunk._(type: 'error', error: error);

  bool get isContent => type == 'content';
  bool get isInfo => type == 'info';
  bool get isToolExecution => type == 'tool_execution';
  bool get isToolResult => type == 'tool_result';
  bool get isFinalContent => type == 'final_content';
  bool get isComplete => type == 'complete';
  bool get isError => type == 'error';
}

class ToolExecutionResult {
  final String toolName;
  final String serverId;
  final bool success;
  final dynamic result;
  final String? error;
  final DateTime executionTime;

  const ToolExecutionResult({
    required this.toolName,
    required this.serverId,
    required this.success,
    required this.result,
    this.error,
    required this.executionTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'toolName': toolName,
      'serverId': serverId,
      'success': success,
      'result': result,
      'error': error,
      'executionTime': executionTime.toIso8601String(),
    };
  }
}

class AvailableMCPTool {
  final String serverId;
  final String serverName;
  final List<String> capabilities;
  final bool isRunning;
  final DateTime? lastUsed;
  final int priority;

  const AvailableMCPTool({
    required this.serverId,
    required this.serverName,
    required this.capabilities,
    required this.isRunning,
    this.lastUsed,
    required this.priority,
  });
}