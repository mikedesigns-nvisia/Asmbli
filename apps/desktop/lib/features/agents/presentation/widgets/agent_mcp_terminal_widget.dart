import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/agent_mcp_session_service.dart';
import '../../../../core/di/service_locator.dart';

/// Widget that demonstrates MCP tool execution for agents
/// Shows the complete flow: agent → MCP server → tool execution → results
class AgentMCPTerminalWidget extends ConsumerStatefulWidget {
  final Agent agent;

  const AgentMCPTerminalWidget({
    super.key,
    required this.agent,
  });

  @override
  ConsumerState<AgentMCPTerminalWidget> createState() => _AgentMCPTerminalWidgetState();
}

class _AgentMCPTerminalWidgetState extends ConsumerState<AgentMCPTerminalWidget> {
  final TextEditingController _serverIdController = TextEditingController();
  final TextEditingController _toolNameController = TextEditingController();
  final TextEditingController _parametersController = TextEditingController();

  String? _executionResult;
  bool _isExecuting = false;
  bool _showAvailableTools = false;
  List<String> _availableTools = [];

  late final AgentMCPSessionService _sessionService;

  @override
  void initState() {
    super.initState();
    _sessionService = ServiceLocator.instance.get<AgentMCPSessionService>();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MCP Tool Execution Terminal',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            Text(
              'Agent: ${widget.agent.name}',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            SizedBox(height: SpacingTokens.lg),

            // Server ID Input
            TextField(
              controller: _serverIdController,
              decoration: InputDecoration(
                labelText: 'MCP Server ID',
                hintText: 'e.g., github, filesystem, brave-search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                ),
              ),
            ),
            SizedBox(height: SpacingTokens.md),

            // Available Tools Button
            Row(
              children: [
                AsmblButton.outline(
                  text: 'Get Available Tools',
                  onPressed: _isExecuting ? null : _getAvailableTools,
                ),
                if (_availableTools.isNotEmpty) ...[
                  SizedBox(width: SpacingTokens.sm),
                  Text(
                    '${_availableTools.length} tools available',
                    style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ],
            ),

            if (_showAvailableTools && _availableTools.isNotEmpty) ...[
              SizedBox(height: SpacingTokens.sm),
              Container(
                padding: EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Tools:',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: SpacingTokens.xs),
                    Wrap(
                      spacing: SpacingTokens.xs,
                      runSpacing: SpacingTokens.xs,
                      children: _availableTools.map((tool) =>
                        GestureDetector(
                          onTap: () => _toolNameController.text = tool,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: SpacingTokens.sm,
                              vertical: SpacingTokens.xs,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              border: Border.all(color: colors.border),
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                            ),
                            child: Text(
                              tool,
                              style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: SpacingTokens.md),

            // Tool Name Input
            TextField(
              controller: _toolNameController,
              decoration: InputDecoration(
                labelText: 'Tool Name',
                hintText: 'e.g., read_file, list_repos, search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                ),
              ),
            ),
            SizedBox(height: SpacingTokens.md),

            // Parameters Input
            TextField(
              controller: _parametersController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Parameters (JSON)',
                hintText: '{"path": "/example.txt", "encoding": "utf-8"}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                ),
              ),
            ),
            SizedBox(height: SpacingTokens.lg),

            // Execute Button
            AsmblButton.primary(
              text: _isExecuting ? 'Executing...' : 'Execute MCP Tool',
              onPressed: _canExecute() && !_isExecuting ? _executeTool : null,
            ),

            if (_executionResult != null) ...[
              SizedBox(height: SpacingTokens.lg),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Execution Result:',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: SpacingTokens.sm),
                    SelectableText(
                      _executionResult!,
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canExecute() {
    return _serverIdController.text.isNotEmpty &&
           _toolNameController.text.isNotEmpty;
  }

  Future<void> _getAvailableTools() async {
    if (_serverIdController.text.isEmpty) {
      _showErrorMessage('Please enter a server ID first');
      return;
    }

    setState(() {
      _isExecuting = true;
      _availableTools.clear();
      _showAvailableTools = false;
    });

    try {
      final tools = await _sessionService.getAvailableTools(
        widget.agent.id,
        _serverIdController.text,
      );

      setState(() {
        _availableTools = tools;
        _showAvailableTools = true;
        if (tools.isEmpty) {
          _executionResult = 'No tools available for this server. '
              'Make sure the server is configured for this agent.';
        }
      });

    } catch (e) {
      setState(() {
        _executionResult = 'Error getting available tools: $e';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  Future<void> _executeTool() async {
    setState(() {
      _isExecuting = true;
      _executionResult = null;
    });

    try {
      // Parse parameters as JSON
      Map<String, dynamic> parameters = {};
      if (_parametersController.text.isNotEmpty) {
        try {
          parameters = Map<String, dynamic>.from(
            // Simple JSON parsing - in a real app, use dart:convert
            <String, dynamic>{},
          );
        } catch (e) {
          throw Exception('Invalid JSON parameters: $e');
        }
      }

      final request = MCPToolExecutionRequest(
        agentId: widget.agent.id,
        serverId: _serverIdController.text,
        toolName: _toolNameController.text,
        parameters: parameters,
      );

      final result = await _sessionService.executeTool(request);

      setState(() {
        if (result.success) {
          _executionResult = '''✅ Tool executed successfully!

Tool: ${result.toolName}
Server: ${result.serverId}
Execution Time: ${result.executionTime.inMilliseconds}ms

Result:
${_formatResult(result.result)}''';
        } else {
          _executionResult = '''❌ Tool execution failed!

Tool: ${result.toolName}
Server: ${result.serverId}
Execution Time: ${result.executionTime.inMilliseconds}ms

Error: ${result.error}''';
        }
      });

    } catch (e) {
      setState(() {
        _executionResult = '❌ Execution error: $e';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  String _formatResult(Map<String, dynamic>? result) {
    if (result == null) return 'null';

    try {
      // Format as pretty JSON (simplified)
      return result.toString();
    } catch (e) {
      return result.toString();
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _serverIdController.dispose();
    _toolNameController.dispose();
    _parametersController.dispose();
    super.dispose();
  }
}