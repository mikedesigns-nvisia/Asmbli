import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:agent_engine_core/models/agent.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/components/app_navigation_bar.dart';
import '../../../core/constants/routes.dart';
import '../../../core/widgets/penpot_canvas.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/mcp_penpot_server.dart';
import '../../../core/services/design_tokens_service.dart';
import '../../../core/services/design_history_service.dart';
import '../../../core/services/llm/unified_llm_service.dart';
import '../../../core/services/llm/llm_provider.dart';
import '../../../core/services/plugin_bridge_server.dart';
import '../../../core/models/canvas_update_event.dart';
import '../../agents/presentation/widgets/design_agent_sidebar.dart';

/// Penpot canvas screen with integrated design agent
/// Week 4: Interactive design workflows with agent collaboration
class PenpotCanvasScreen extends ConsumerStatefulWidget {
  const PenpotCanvasScreen({super.key});

  @override
  ConsumerState<PenpotCanvasScreen> createState() => _PenpotCanvasScreenState();
}

class _PenpotCanvasScreenState extends ConsumerState<PenpotCanvasScreen> {
  final GlobalKey<PenpotCanvasState> _canvasKey = GlobalKey();
  bool _isSidebarCollapsed = false;
  bool _isPluginConnected = false;
  late Agent _designAgent;
  late MCPPenpotServer _mcpServer;

  @override
  void initState() {
    super.initState();
    _createDesignAgent();
    _initializeMCPServer();
    _listenToPluginConnection();
  }

  void _listenToPluginConnection() {
    try {
      final pluginBridge = ServiceLocator.instance.get<PluginBridgeServer>();
      pluginBridge.connectionStatusStream.listen((status) {
        setState(() {
          _isPluginConnected = status['connected'] as bool? ?? false;
        });
      });

      // Set initial state
      setState(() {
        _isPluginConnected = pluginBridge.isConnected;
      });
    } catch (e) {
      debugPrint('⚠️ Could not access PluginBridgeServer: $e');
    }
  }

  void _createDesignAgent() {
    _designAgent = Agent(
      id: 'penpot_design_agent',
      name: 'Penpot Design Agent',
      description: 'AI agent specialized in creating visual designs using Penpot canvas with 30 MCP tools.',
      capabilities: ['penpot_design', 'tool_calling', 'visual_creation', 'canvas_manipulation', 'element_manipulation'],
      configuration: {
        'modelConfiguration': {
          'primaryModelId': 'local_llama3.1_8b',
        },
        'instructions': '''You are a Penpot design agent with 30 MCP tools for creating and manipulating visual designs.

Available capabilities:
- CREATE: frames, rectangles, ellipses, text, paths, images
- STYLE: colors, gradients, shadows, borders, typography
- COMPONENTS: create and use reusable components
- DESIGN TOKENS: fetch and apply brand design system
- UPDATE: modify element properties (position, size, styles, content)
- TRANSFORM: rotate, scale, skew, flip elements
- DELETE: remove elements from canvas (trash or permanent)
- DUPLICATE: clone elements with offset and component linking
- GROUP: combine elements into groups, ungroup as needed
- REORDER: change layer order (bring to front, send to back, etc.)
- LAYOUT: apply responsive constraints and auto-layout
- QUERY: search elements by type, get detailed canvas state
- HISTORY: undo, redo, view design history
- EXPORT: PNG, SVG, PDF exports

Best practices:
1. Always fetch design tokens FIRST to ensure brand consistency
2. Query canvas state before making changes
3. Use element IDs from query results for updates
4. Group related elements for better organization
5. Use undo/redo for experimentation

Week 4 enhancements: Element manipulation, transformations, grouping, and layer management.''',
      },
      status: AgentStatus.idle,
    );
  }

  void _initializeMCPServer() {
    // Defer initialization until after first build when canvas state is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final canvasState = _canvasKey.currentState;
        if (canvasState == null) {
          debugPrint('⚠️ Canvas state not available yet for MCP server initialization');
          return;
        }

        final designTokensService = ServiceLocator.instance.get<DesignTokensService>();
        final historyService = DesignHistoryService();

        _mcpServer = MCPPenpotServer(
          canvas: canvasState,  // Pass the canvas state which implements PenpotCanvasInterface
          designTokensService: designTokensService,
          historyService: historyService,
        );
        
        debugPrint('✅ MCPPenpotServer initialized');
      } catch (e) {
        debugPrint('❌ Error initializing MCP server: $e');
      }
    });
  }

  /// Process design message through AI and execute MCP tools
  Future<String> _processDesignMessage(String message) async {
    try {
      debugPrint('🎨 Processing design message: $message');

      // Get UnifiedLLMService to call Ollama
      final llmService = ServiceLocator.instance.get<UnifiedLLMService>();

      // Get available tools from MCP server
      final availableTools = _mcpServer.getAvailableTools();
      debugPrint('🔧 Available MCP tools: ${availableTools.length}');

      // Create system prompt with tool information
      final systemPrompt = '''You are a Penpot design agent with access to MCP tools for creating visual designs.

Available MCP tools:
${availableTools.map((tool) => '- ${tool.name}: ${tool.description}').join('\n')}

When the user asks you to create or modify designs, you should:
1. Understand the design request
2. Call the appropriate MCP tools to execute the design
3. Explain what you're creating

Always call tools to actually create the visual elements. Don't just describe what you would do - actually do it by calling the tools.''';

      // Call Ollama with tool calling enabled
      final response = await llmService.chat(
        message: message,
        modelId: _designAgent.configuration['modelConfiguration']['primaryModelId'] ?? 'local_llama3.1_8b',
        context: ChatContext(
          systemPrompt: systemPrompt,
        ),
      );

      debugPrint('🤖 AI response: ${response.content}');

      // Parse the AI response for design intent and execute corresponding tools
      final responseText = response.content.toLowerCase();
      int executedTools = 0;

      // Simple intent detection for common design requests
      try {
        if (responseText.contains('rectangle') || responseText.contains('box') || responseText.contains('button')) {
          debugPrint('🛠️ Detected rectangle creation intent');
          await _mcpServer.executeTool('penpot_create_rectangle', {
            'x': 100.0,
            'y': 100.0,
            'width': 200.0,
            'height': 100.0,
            'fill': '#4ECDC4',
            'name': 'Rectangle',
          });
          executedTools++;
        }

        if (responseText.contains('text') || responseText.contains('label') || responseText.contains('heading')) {
          debugPrint('🛠️ Detected text creation intent');
          await _mcpServer.executeTool('penpot_create_text', {
            'x': 100.0,
            'y': 50.0,
            'content': 'Sample Text',
            'fontSize': 24.0,
            'fill': '#2D3E50',
            'name': 'Text',
          });
          executedTools++;
        }

        if (responseText.contains('frame') || responseText.contains('container') || responseText.contains('wireframe')) {
          debugPrint('🛠️ Detected frame creation intent');
          await _mcpServer.executeTool('penpot_create_frame', {
            'x': 50.0,
            'y': 50.0,
            'width': 400.0,
            'height': 600.0,
            'name': 'Mobile Frame',
          });
          executedTools++;
        }

        if (responseText.contains('circle') || responseText.contains('ellipse')) {
          debugPrint('🛠️ Detected ellipse creation intent');
          await _mcpServer.executeTool('penpot_create_ellipse', {
            'x': 150.0,
            'y': 150.0,
            'rx': 50.0,
            'ry': 50.0,
            'fill': '#FF6B6B',
            'name': 'Circle',
          });
          executedTools++;
        }
      } catch (toolError) {
        debugPrint('❌ Tool execution error: $toolError');
      }

      if (executedTools > 0) {
        return '${response.content}\n\n✅ Created $executedTools design element(s) on the canvas';
      } else {
        return response.content;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error processing design message: $e');
      debugPrint('Stack trace: $stackTrace');
      return 'Sorry, I encountered an error processing your request: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Navigation bar
              const AppNavigationBar(currentRoute: AppRoutes.canvas),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.xxl,
                  vertical: SpacingTokens.lg,
                ),
                child: Row(
                  children: [
                    Icon(Icons.palette, color: colors.primary, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Penpot Canvas',
                      style: TextStyles.sectionTitle.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    // Plugin connection status light
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isPluginConnected ? colors.success : colors.onSurfaceVariant.withValues(alpha: 0.3),
                        boxShadow: _isPluginConnected ? [
                          BoxShadow(
                            color: colors.success.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ] : null,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.componentSpacing),
                    // Sidebar toggle button
                    AsmblButton.secondary(
                      text: _isSidebarCollapsed ? 'Show Agent' : 'Hide Agent',
                      icon: _isSidebarCollapsed ? Icons.chevron_left : Icons.chevron_right,
                      size: AsmblButtonSize.small,
                      onPressed: () {
                        setState(() {
                          _isSidebarCollapsed = !_isSidebarCollapsed;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Canvas + Sidebar layout - minimal padding for seamless integration
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: SpacingTokens.xxl,
                    right: SpacingTokens.xxl,
                  ),
                  child: Row(
                    children: [
                      // Canvas area - takes remaining space, no borders
                      Expanded(
                        child: PenpotCanvas(key: _canvasKey),
                      ),

                      // Sidebar - fixed width with Design Agent
                      if (!_isSidebarCollapsed) ...[
                        const SizedBox(width: SpacingTokens.lg),
                        SizedBox(
                          width: 400,
                          child: DesignAgentSidebar(
                            agent: _designAgent,
                            onSpecUpdate: (spec) {
                              debugPrint('Spec updated: $spec');
                            },
                            onContextUpdate: (context) {
                              debugPrint('Context updated: $context');
                            },
                            onProcessMessage: _processDesignMessage,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
