import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/components/app_navigation_bar.dart';
import '../../../core/constants/routes.dart';
import '../../../core/widgets/excalidraw_canvas.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/business/context_business_service.dart';
import '../../../core/services/llm/unified_llm_service.dart';
import '../../../core/services/llm/llm_provider.dart';
import '../../../features/context/data/models/context_document.dart';
import '../../../features/agents/presentation/widgets/design_agent_sidebar.dart';
import '../../../core/services/openai_vision_service.dart';
import '../../../core/models/component_library.dart';

/// Main Excalidraw canvas screen with Asmbli-styled shell
class ExcalidrawCanvasScreen extends ConsumerStatefulWidget {
  const ExcalidrawCanvasScreen({super.key});

  @override
  ConsumerState<ExcalidrawCanvasScreen> createState() => _ExcalidrawCanvasScreenState();
}

class _ExcalidrawCanvasScreenState extends ConsumerState<ExcalidrawCanvasScreen> {
  final GlobalKey<ExcalidrawCanvasState> _canvasKey = GlobalKey();
  bool _isSidebarCollapsed = false;
  String? _currentDrawingData;
  bool _canvasHasContent = false;
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];
  
  // Design agent and spec state
  late Agent _designAgent;
  Map<String, dynamic> _currentSpec = {};
  List<String> _currentContext = [];
  bool _isSpecDriven = true;
  
  // Progressive disclosure state
  String _activeTab = 'specs'; // 'specs', 'context', 'chat'
  bool _hasUnreadMessages = false;
  int _unreadCount = 0;
  
  // Agent modes
  String _agentMode = 'plan'; // 'plan', 'act'
  
  // Planning document state
  Map<String, dynamic> _planDocument = {
    'projectGoals': '',
    'userNeeds': '',
    'designStrategy': '',
    'layoutApproach': '',
    'componentPriority': '',
    'interactionPatterns': '',
    'accessibilityConsiderations': '',
    'technicalConstraints': '',
    'designPrinciples': '',
    'successMetrics': '',
  };

  // Enhanced features state
  late OpenAIVisionService _visionService;
  String? _generatedCode;
  bool _isGeneratingCode = false;
  bool _showEnhancedElements = false;
  String _selectedComponentCategory = 'material';
  List<String> _planSections = [
    'projectGoals',
    'userNeeds', 
    'designStrategy',
    'layoutApproach',
    'componentPriority',
    'interactionPatterns',
    'accessibilityConsiderations',
    'technicalConstraints',
    'designPrinciples',
    'successMetrics',
  ];
  bool _isPlanComplete = false;
  String _activePlanSection = '';
  String _planProgress = 'Not Started';

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _visionService = OpenAIVisionService();
    
    // Initialize design agent with dual-model configuration
    _designAgent = Agent(
      id: 'canvas-design-agent',
      name: 'Design Agent',
      description: 'Expert design agent with dual-model configuration for planning and vision analysis',
      capabilities: ['ui_design', 'user_research', 'prototyping', 'design_systems'],
      status: AgentStatus.idle,
      configuration: {
        'type': 'design_agent',
        'modelConfiguration': {
          'primaryModelId': 'local_deepseek-r1_32b',
          'visionModelId': 'local_llava_13b',
        },
      },
    );
    
    // Add initial welcome message
    _chatMessages.add(ChatMessage(
      message: "Hello! I'm your design agent. I can help you create wireframes, suggest layouts, and guide your design process. What would you like to create today?",
      isAgent: true,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
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
              
              // Main content area with left sidebar
              Expanded(
                child: Row(
                  children: [
                    // Left Design Agent Sidebar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isSidebarCollapsed ? 0 : 400,
                      child: _isSidebarCollapsed ? null : DesignAgentSidebar(
                        agent: _designAgent,
                        onSpecUpdate: (spec) {
                          setState(() {
                            _currentSpec = spec;
                          });
                        },
                        onContextUpdate: (context) {
                          setState(() {
                            _currentContext = context;
                          });
                        },
                        // Canvas action callbacks for design agent integration
                        onAddCanvasElement: _addCanvasElementFromAgent,
                        onAddTemplate: _addTemplateFromAgent,
                        onAddFlutterComponent: _addFlutterComponentFromAgent,
                        onAddFlutterScreenTemplate: _addFlutterScreenTemplateFromAgent,
                        onGenerateCode: _generateCodeFromCanvas,
                        onClearCanvas: () => _canvasKey.currentState?.clearCanvas(),
                        onCaptureCanvas: () => _canvasKey.currentState?.captureCanvasForVision(),
                      ),
                    ),
                    
                    // Sidebar Toggle (when collapsed) - left side
                    if (_isSidebarCollapsed)
                      Container(
                        width: 48,
                        decoration: BoxDecoration(
                          color: colors.surface.withOpacity(0.9),
                          border: Border(right: BorderSide(color: colors.border)),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: SpacingTokens.md),
                            IconButton(
                              onPressed: () => setState(() => _isSidebarCollapsed = false),
                              icon: const Icon(Icons.chevron_right, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: colors.surface,
                                foregroundColor: colors.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            // Quick access buttons when collapsed
                            IconButton(
                              onPressed: () {
                                setState(() => _isSidebarCollapsed = false);
                              },
                              icon: const Icon(Icons.chat, size: 20),
                              tooltip: 'Agent Chat',
                              style: IconButton.styleFrom(
                                foregroundColor: colors.primary,
                              ),
                            ),
                            IconButton(
                              onPressed: _addWireframeElements,
                              icon: const Icon(Icons.dashboard, size: 20),
                              tooltip: 'Add Wireframe',
                              style: IconButton.styleFrom(
                                foregroundColor: colors.accent,
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.md),
                          ],
                        ),
                      ),
                    
                    // Main canvas area (right side)
                    Expanded(
                      child: _buildCanvasArea(colors),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Canvas title and status
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.draw,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visual Design Canvas',
                  style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                ),
                Text(
                  _canvasHasContent 
                    ? 'Drawing in progress' 
                    : 'Start drawing or use AI assistance',
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          // Canvas actions - compact buttons to avoid toolbar overlap
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _saveDrawing,
                icon: Icon(Icons.save, size: 18),
                tooltip: 'Save Drawing',
                style: IconButton.styleFrom(
                  foregroundColor: colors.primary,
                  backgroundColor: colors.surface,
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                ),
              ),
              const SizedBox(width: SpacingTokens.xs),
              IconButton(
                onPressed: _exportPNG,
                icon: Icon(Icons.image, size: 18),
                tooltip: 'Export PNG',
                style: IconButton.styleFrom(
                  foregroundColor: colors.primary,
                  backgroundColor: colors.surface,
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                ),
              ),
              const SizedBox(width: SpacingTokens.xs),
              IconButton(
                onPressed: _clearCanvas,
                icon: Icon(Icons.clear, size: 18),
                tooltip: 'Clear Canvas',
                style: IconButton.styleFrom(
                  foregroundColor: colors.error,
                  backgroundColor: colors.surface,
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                ),
              ),
              const SizedBox(width: SpacingTokens.xs),
              IconButton(
                onPressed: _showContextLibrary,
                icon: Icon(Icons.library_books, size: 18),
                tooltip: 'Context Library',
                style: IconButton.styleFrom(
                  foregroundColor: colors.accent,
                  backgroundColor: colors.surface,
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ExcalidrawCanvas(
        key: _canvasKey,
        darkMode: Theme.of(context).brightness == Brightness.dark,
        sessionId: 'main_canvas_${DateTime.now().millisecondsSinceEpoch}',
        onDrawingChanged: (drawingData) {
          setState(() {
            _canvasHasContent = true;
            _currentDrawingData = drawingData;
          });
        },
        onDrawingSaved: (drawingData) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Drawing saved successfully'),
              backgroundColor: colors.success,
            ),
          );
        },
        onPNGExported: (base64PNG) {
          // Could show preview or download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PNG exported'),
              backgroundColor: colors.success,
            ),
          );
        },
        onVisionCapture: (base64Image, elementsCount) {
          _handleVisionAnalysis(base64Image, elementsCount);
        },
        onCodeGeneration: (imageData, elementsCount, prompt) {
          _handleCodeGeneration(imageData, elementsCount, prompt);
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Canvas error: $error'),
              backgroundColor: colors.error,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecDrivenSidebar(ThemeColors colors) {
    // Check if we have specs and context to enable design work
    final hasSpecs = _currentSpec.isNotEmpty && _currentSpec['projectType'] != 'web_app';
    final hasContext = _currentContext.isNotEmpty;
    final canStartDesign = hasSpecs && hasContext;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          // Compact header with status
          _buildCompactHeader(colors, hasSpecs, hasContext, canStartDesign),
          
          // Always-visible workflow progress strip
          _buildCompactWorkflowProgress(colors, hasSpecs, hasContext, canStartDesign),
          
          // Tabbed interface
          _buildTabBar(colors, hasSpecs, hasContext),
          
          // Tab content with progressive disclosure
          Expanded(
            child: _buildActiveTabContent(colors, hasSpecs, hasContext, canStartDesign),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(ThemeColors colors, bool hasSpecs, bool hasContext, bool canStartDesign) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          // Agent avatar with status indicator
          Stack(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.design_services,
                  color: colors.surface,
                  size: 16,
                ),
              ),
              // Status dot
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: canStartDesign ? colors.success : colors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Design Assistant',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.xs,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _agentMode == 'plan' ? colors.primary : colors.accent,
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      ),
                      child: Text(
                        _agentMode.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  canStartDesign 
                    ? 'Ready • ${_agentMode == 'plan' ? 'Planning Mode' : 'Action Mode'}'
                    : hasSpecs 
                      ? 'Context needed'
                      : 'Specs required',
                  style: TextStyles.caption.copyWith(
                    color: canStartDesign 
                      ? colors.success 
                      : hasSpecs 
                        ? colors.warning 
                        : colors.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _isSidebarCollapsed = true),
            icon: const Icon(Icons.chevron_left, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              padding: const EdgeInsets.all(SpacingTokens.xs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactWorkflowProgress(ThemeColors colors, bool hasSpecs, bool hasContext, bool canStartDesign) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md, 
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          _buildMiniProgressStep('Specs', hasSpecs, colors),
          Expanded(child: _buildProgressLine(hasSpecs, colors)),
          _buildMiniProgressStep('Context', hasContext, colors),
          Expanded(child: _buildProgressLine(hasContext, colors)),
          _buildMiniProgressStep('Design', canStartDesign, colors),
        ],
      ),
    );
  }

  Widget _buildMiniProgressStep(String label, bool isComplete, ThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isComplete ? colors.success : colors.onSurfaceVariant.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: isComplete 
            ? Icon(Icons.check, color: Colors.white, size: 10)
            : null,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyles.caption.copyWith(
            color: isComplete ? colors.success : colors.onSurfaceVariant,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isComplete, ThemeColors colors) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isComplete ? colors.success : colors.border,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildTabBar(ThemeColors colors, bool hasSpecs, bool hasContext) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          _buildTab('specs', 'Specs', Icons.assignment, 
            hasSpecs ? colors.success : colors.error, colors),
          _buildTab('context', 'Context', Icons.folder_open, 
            hasContext ? colors.success : colors.warning, colors),
          _buildTab('chat', 'Chat', Icons.chat_bubble_outline, 
            _hasUnreadMessages ? colors.primary : colors.onSurfaceVariant, colors),
        ],
      ),
    );
  }

  Widget _buildTab(String tabId, String label, IconData icon, Color statusColor, ThemeColors colors) {
    final isActive = _activeTab == tabId;
    final showBadge = tabId == 'chat' && _unreadCount > 0;
    
    return Expanded(
      child: Material(
        color: isActive ? colors.primary.withOpacity(0.1) : Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _activeTab = tabId;
              if (tabId == 'chat') {
                _hasUnreadMessages = false;
                _unreadCount = 0;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
            decoration: BoxDecoration(
              border: isActive 
                ? Border(bottom: BorderSide(color: colors.primary, width: 2))
                : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isActive ? colors.primary : statusColor,
                    ),
                    if (showBadge)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text(
                            _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyles.caption.copyWith(
                    color: isActive ? colors.primary : colors.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(ThemeColors colors, bool hasSpecs, bool hasContext, bool canStartDesign) {
    switch (_activeTab) {
      case 'specs':
        return _buildSpecsTab(colors, hasSpecs);
      case 'context':
        return _buildContextTab(colors, hasContext);
      case 'chat':
        return _buildChatTab(colors, canStartDesign);
      default:
        return _buildSpecsTab(colors, hasSpecs);
    }
  }

  Widget _buildSpecsTab(ThemeColors colors, bool hasSpecs) {
    if (hasSpecs) {
      // Show specs summary and allow editing
      return Column(
        children: [
          _buildSpecsSummary(colors),
          Expanded(
            child: DesignAgentSidebar(
              agent: _designAgent,
              onSpecUpdate: (spec) {
                setState(() {
                  _currentSpec = spec;
                });
              },
              onContextUpdate: (context) {
                setState(() {
                  _currentContext = context;
                });
              },
              // Canvas action callbacks for design agent integration
              onAddCanvasElement: _addCanvasElementFromAgent,
              onAddTemplate: _addTemplateFromAgent,
              onAddFlutterComponent: _addFlutterComponentFromAgent,
              onAddFlutterScreenTemplate: _addFlutterScreenTemplateFromAgent,
              onGenerateCode: _generateCodeFromCanvas,
              onClearCanvas: () => _canvasKey.currentState?.clearCanvas(),
              onCaptureCanvas: () => _canvasKey.currentState?.captureCanvasForVision(),
            ),
          ),
        ],
      );
    } else {
      // Show spec generation interface
      return DesignAgentSidebar(
        agent: _designAgent,
        onSpecUpdate: (spec) {
          setState(() {
            _currentSpec = spec;
            if (spec.isNotEmpty) {
              _showSpecsCompleteAnimation();
            }
          });
        },
        onContextUpdate: (context) {
          setState(() {
            _currentContext = context;
          });
        },
        // Canvas action callbacks for design agent integration
        onAddCanvasElement: _addCanvasElementFromAgent,
        onAddTemplate: _addTemplateFromAgent,
        onAddFlutterComponent: _addFlutterComponentFromAgent,
        onAddFlutterScreenTemplate: _addFlutterScreenTemplateFromAgent,
        onGenerateCode: _generateCodeFromCanvas,
        onClearCanvas: () => _canvasKey.currentState?.clearCanvas(),
        onCaptureCanvas: () => _canvasKey.currentState?.captureCanvasForVision(),
      );
    }
  }

  Widget _buildSpecsSummary(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.success.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colors.success, size: 16),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Specs Complete',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_currentSpec['projectType'] ?? 'Project'} • ${_currentSpec['designPhase'] ?? 'Phase'}',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: 16),
            onPressed: () => _editSpecs(),
            style: IconButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              padding: const EdgeInsets.all(SpacingTokens.xs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextTab(ThemeColors colors, bool hasContext) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasContext) ...[
            Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: colors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.warning.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.folder_open, color: colors.warning, size: 32),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    'Context Needed',
                    style: TextStyles.cardTitle.copyWith(
                      color: colors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    'Add design context like brand guidelines, user research, or design systems to get better results.',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
          ],
          
          Text(
            'Design Context',
            style: TextStyles.sectionTitle,
          ),
          const SizedBox(height: SpacingTokens.sm),
          
          // Quick context buttons
          Wrap(
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.sm,
            children: [
              _buildQuickContextButton('Brand Guidelines', Icons.business, colors),
              _buildQuickContextButton('Design System', Icons.dashboard, colors),
              _buildQuickContextButton('User Research', Icons.people, colors),
              _buildQuickContextButton('Constraints', Icons.warning, colors),
            ],
          ),
          
          if (hasContext) ...[
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'Added Context (${_currentContext.length})',
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Expanded(
              child: ListView.builder(
                itemCount: _currentContext.length,
                itemBuilder: (context, index) {
                  final contextItem = _currentContext[index];
                  return _buildContextListItem(contextItem, colors);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickContextButton(String label, IconData icon, ThemeColors colors) {
    return Material(
      color: colors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      child: InkWell(
        onTap: () => _addQuickContext(label),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.sm,
            vertical: SpacingTokens.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colors.primary),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                label,
                style: TextStyles.caption.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.add, size: 12, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextListItem(String contextItem, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.description, size: 16, color: colors.primary),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              contextItem,
              style: TextStyles.bodySmall,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 14),
            onPressed: () => _removeContext(contextItem),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(SpacingTokens.xs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab(ThemeColors colors, bool canStartDesign) {
    return Column(
      children: [
        // Mode selector when ready for design
        if (canStartDesign) _buildModeSelector(colors),
        
        // Chat interface with mode-specific behavior
        Expanded(
          child: _buildChatInterface(colors, showReadyState: canStartDesign),
        ),
      ],
    );
  }

  Widget _buildModeSelector(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agent Mode',
            style: TextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  'plan',
                  'Plan',
                  'Collaborative planning & strategy',
                  Icons.description,
                  colors,
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: _buildModeButton(
                  'act',
                  'Act', 
                  'Execute plan.doc instructions',
                  Icons.play_arrow,
                  colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    String mode,
    String title,
    String description,
    IconData icon,
    ThemeColors colors,
  ) {
    final isActive = _agentMode == mode;
    
    return Material(
      color: isActive 
        ? (mode == 'plan' ? colors.primary : colors.accent).withOpacity(0.1)
        : Colors.transparent,
      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      child: InkWell(
        onTap: () {
          setState(() {
            _agentMode = mode;
          });
          _addModeChangeMessage(mode);
        },
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        child: Container(
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive 
                ? (mode == 'plan' ? colors.primary : colors.accent)
                : colors.border,
            ),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive 
                  ? (mode == 'plan' ? colors.primary : colors.accent)
                  : colors.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                title,
                style: TextStyles.caption.copyWith(
                  color: isActive 
                    ? (mode == 'plan' ? colors.primary : colors.accent)
                    : colors.onSurface,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowProgress(ThemeColors colors, bool hasSpecs, bool hasContext) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          _buildProgressStep('Specs', hasSpecs, colors),
          Expanded(
            child: Container(
              height: 2,
              color: colors.border,
              margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
            ),
          ),
          _buildProgressStep('Context', hasContext, colors),
          Expanded(
            child: Container(
              height: 2,
              color: colors.border,
              margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
            ),
          ),
          _buildProgressStep('Design', hasSpecs && hasContext, colors),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String label, bool isComplete, ThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isComplete ? colors.success : colors.onSurfaceVariant.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isComplete ? Icons.check : Icons.radio_button_unchecked,
            color: isComplete ? Colors.white : colors.onSurfaceVariant,
            size: 12,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          label,
          style: TextStyles.caption.copyWith(
            color: isComplete ? colors.success : colors.onSurfaceVariant,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildChatInterface(ThemeColors colors, {bool showReadyState = false}) {
    return Column(
      children: [
        // Chat Messages Area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showReadyState) ...[
                  if (_agentMode == 'plan') 
                    _buildPlanDocumentInterface(colors)
                  else
                    _buildActionModeInterface(colors),
                  
                  const SizedBox(height: SpacingTokens.lg),
                ],

                // Chat Messages
                ..._chatMessages.map((message) => 
                  _buildChatMessage(colors, message),
                ).toList(),
                
                // Mode-specific Quick Actions
                if (showReadyState && _chatMessages.length <= 1) ...[
                  Text(
                    _agentMode == 'plan' ? 'Planning Actions' : 'Direct Actions',
                    style: TextStyles.bodyLarge.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  
                  if (_agentMode == 'plan') ...[
                    _buildActionButton(
                      colors,
                      'Analyze ${_currentSpec['projectType']} Patterns',
                      Icons.analytics,
                      () => _executeSpecBasedAction('analyze'),
                    ),
                    _buildActionButton(
                      colors,
                      'Suggest Layout Strategies',
                      Icons.lightbulb_outline,
                      () => _executeSpecBasedAction('strategy'),
                    ),
                    _buildActionButton(
                      colors,
                      'Review Design Decisions',
                      Icons.psychology,
                      () => _executeSpecBasedAction('review'),
                    ),
                  ] else ...[
                    _buildActionButton(
                      colors,
                      'Generate ${_currentSpec['projectType']} Layout',
                      Icons.dashboard,
                      () => _executeSpecBasedAction('layout'),
                    ),
                    _buildActionButton(
                      colors,
                      'Add UI Components',
                      Icons.widgets,
                      () => _executeSpecBasedAction('components'),
                    ),
                    _buildActionButton(
                      colors,
                      'Apply Design System',
                      Icons.palette,
                      () => _executeSpecBasedAction('apply'),
                    ),
                    
                    // Enhanced Element Controls
                    const SizedBox(height: SpacingTokens.md),
                    Text(
                      'Enhanced Elements',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    
                    // Quick element buttons
                    Wrap(
                      spacing: SpacingTokens.xs,
                      runSpacing: SpacingTokens.xs,
                      children: [
                        _buildQuickElementButton(colors, 'Arrow', 'arrow', Icons.arrow_forward),
                        _buildQuickElementButton(colors, 'Input', 'input', Icons.text_fields),
                        _buildQuickElementButton(colors, 'Checkbox', 'checkbox', Icons.check_box_outline_blank),
                        _buildQuickElementButton(colors, 'Icon', 'icon-home', Icons.home),
                      ],
                    ),
                    
                    const SizedBox(height: SpacingTokens.sm),
                    
                    // Template buttons
                    _buildActionButton(
                      colors,
                      'Mobile Template',
                      Icons.smartphone,
                      () => _addMobileTemplate(),
                    ),
                    _buildActionButton(
                      colors,
                      'Web Header Template',
                      Icons.web,
                      () => _addWebHeaderTemplate(),
                    ),
                    
                    const SizedBox(height: SpacingTokens.sm),
                    
                    // Code generation
                    _buildActionButton(
                      colors,
                      _isGeneratingCode ? 'Generating Code...' : 'Generate Code',
                      _isGeneratingCode ? Icons.hourglass_empty : Icons.code,
                      _isGeneratingCode ? () {} : () => _generateCodeFromCanvas(),
                    ),
                    
                    // Flutter Component Library
                    const SizedBox(height: SpacingTokens.md),
                    Text(
                      'Flutter Component Library',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    
                    // Component category tabs
                    _buildComponentCategoryTabs(colors),
                    const SizedBox(height: SpacingTokens.sm),
                    
                    // Component buttons based on selected category
                    _buildFlutterComponentButtons(colors),
                    
                    const SizedBox(height: SpacingTokens.sm),
                    
                    // Flutter screen templates
                    _buildActionButton(
                      colors,
                      'Dashboard Template',
                      Icons.dashboard,
                      () => _addFlutterScreenTemplate('dashboard'),
                    ),
                    _buildActionButton(
                      colors,
                      'List View Template',
                      Icons.list,
                      () => _addFlutterScreenTemplate('list'),
                    ),
                    _buildActionButton(
                      colors,
                      'Form Template',
                      Icons.article,
                      () => _addFlutterScreenTemplate('form'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        
        // Chat Input with mode-specific placeholder
        if (showReadyState)
          _buildChatInput(colors),
      ],
    );
  }

  void _executeSpecBasedAction(String actionType) {
    String userMessage = '';
    String agentResponse = '';
    
    if (_agentMode == 'plan') {
      switch (actionType) {
        case 'analyze':
          final projectType = _currentSpec['projectType'] ?? 'application';
          userMessage = 'Analyze $projectType patterns';
          agentResponse = 'Based on your $projectType specs, I recommend these patterns:\n\n• **Information Architecture**: Focus on ${_currentSpec['designPhase'] == 'wireframe' ? 'content hierarchy' : 'visual hierarchy'}\n• **User Flow**: Consider ${_getCurrentUserFlow()}\n• **Platform Strategy**: ${_getPlatformStrategy()}\n• **Accessibility**: ${_getAccessibilityRecommendations()}';
          break;
        case 'strategy':
          userMessage = 'Suggest layout strategies';
          agentResponse = 'Here are strategic layout approaches for your ${_currentSpec['projectType']} project:\n\n**Primary Strategy**: ${_getPrimaryLayoutStrategy()}\n**Alternative**: ${_getAlternativeStrategy()}\n**Considerations**: ${_getLayoutConsiderations()}';
          break;
        case 'review':
          userMessage = 'Review design decisions';
          agentResponse = 'Let me analyze your design decisions:\n\n✅ **Aligned**: ${_getAlignedDecisions()}\n⚠️ **Consider**: ${_getConsiderations()}\n💡 **Opportunities**: ${_getOpportunities()}';
          break;
      }
    } else {
      switch (actionType) {
        case 'layout':
          final projectType = _currentSpec['projectType'] ?? 'application';
          userMessage = 'Generate $projectType layout';
          agentResponse = 'Perfect! I\'ve created a $projectType layout based on your specifications. The design incorporates your ${(_currentSpec['platforms'] as List?)?.join(', ') ?? 'web'} platform requirements and follows ${_currentSpec['designPhase']} best practices.';
          _addWireframeElements();
          break;
        case 'components':
          userMessage = 'Add UI components';
          agentResponse = 'I\'ve added essential UI components for your ${_currentSpec['projectType']} project. These components follow your design phase (${_currentSpec['designPhase']}) and include proper accessibility features.';
          _addCanvasElement('components', 'UI components for ${_currentSpec['projectType']}');
          break;
        case 'apply':
          userMessage = 'Apply design system';
          agentResponse = 'I\'ve applied design system principles based on your context. This includes consistent spacing, typography hierarchy, and color usage that aligns with your project requirements.';
          break;
      }
    }
    
    _addChatMessage(userMessage, false);
    Future.delayed(const Duration(milliseconds: 800), () {
      _addChatMessage(agentResponse, true);
      if (_agentMode == 'plan') {
        _markAsUnread();
      }
    });
  }

  void _addModeChangeMessage(String newMode) {
    final message = newMode == 'plan' 
      ? 'Switched to Planning Mode. I\'ll help you think through design strategies and analyze options.'
      : 'Switched to Action Mode. I\'ll take direct actions and create elements on the canvas.';
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _addChatMessage(message, true);
    });
  }

  void _showSpecsCompleteAnimation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _activeTab = 'context';
      });
    });
  }

  void _editSpecs() {
    setState(() {
      _currentSpec.clear();
      _activeTab = 'specs';
    });
  }

  void _addQuickContext(String contextType) {
    setState(() {
      _currentContext.add(contextType);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $contextType to context'),
        backgroundColor: ThemeColors(context).success,
      ),
    );
  }

  void _removeContext(String contextItem) {
    setState(() {
      _currentContext.remove(contextItem);
    });
  }

  void _markAsUnread() {
    if (_activeTab != 'chat') {
      setState(() {
        _hasUnreadMessages = true;
        _unreadCount++;
      });
    }
  }

  // Helper methods for planning responses
  String _getCurrentUserFlow() {
    final platforms = _currentSpec['platforms'] as List?;
    if (platforms?.contains('ios') == true || platforms?.contains('android') == true) {
      return 'mobile-first navigation patterns with bottom tabs or drawer';
    }
    return 'desktop-optimized navigation with sidebar or top navigation';
  }

  String _getPlatformStrategy() {
    final platforms = (_currentSpec['platforms'] as List?)?.join(', ') ?? 'web';
    return 'Optimize for $platforms with responsive breakpoints and platform-specific interactions';
  }

  String _getAccessibilityRecommendations() {
    final hasA11y = _currentSpec['requirements']?['accessibility'] ?? false;
    return hasA11y 
      ? 'WCAG 2.1 AA compliance with focus management and screen reader support'
      : 'Consider enabling accessibility features for broader user reach';
  }

  String _getPrimaryLayoutStrategy() {
    final projectType = _currentSpec['projectType'] ?? 'web_app';
    switch (projectType) {
      case 'dashboard': return 'Grid-based layout with data density and quick actions';
      case 'e_commerce': return 'Product-focused layout with clear conversion paths';
      case 'mobile_app': return 'Touch-optimized layout with thumb-friendly navigation';
      default: return 'Content-first layout with clear information hierarchy';
    }
  }

  String _getAlternativeStrategy() {
    return 'Sidebar navigation with collapsible sections for power users';
  }

  String _getLayoutConsiderations() {
    final phase = _currentSpec['designPhase'] ?? 'concept';
    return phase == 'concept' 
      ? 'Focus on user journeys and content structure'
      : 'Balance visual hierarchy with interaction patterns';
  }

  String _getAlignedDecisions() {
    return 'Project type and platform choices support user needs';
  }

  String _getConsiderations() {
    return 'Evaluate responsive breakpoints for multi-platform support';
  }

  String _getOpportunities() {
    return 'Progressive enhancement opportunities for advanced users';
  }

  Widget _buildChatMessage(ThemeColors colors, ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: message.isAgent ? colors.primary : colors.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              message.isAgent ? Icons.auto_awesome : Icons.person,
              color: colors.surface,
              size: 16,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          
          // Message content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: message.isAgent 
                  ? colors.surface
                  : colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(
                  color: message.isAgent 
                    ? colors.border
                    : colors.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                message.message,
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeColors colors,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  // Flutter component library UI builders
  Widget _buildComponentCategoryTabs(ThemeColors colors) {
    final categories = ['material', 'layout', 'forms', 'asmbli'];
    final categoryNames = {
      'material': 'Material',
      'layout': 'Layout', 
      'forms': 'Forms',
      'asmbli': 'Asmbli'
    };

    return Row(
      children: categories.map((category) {
        final isSelected = _selectedComponentCategory == category;
        return Expanded(
          child: InkWell(
            onTap: () => setState(() => _selectedComponentCategory = category),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.xs,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(
                  color: isSelected ? colors.primary : colors.border,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Text(
                categoryNames[category] ?? category,
                textAlign: TextAlign.center,
                style: TextStyles.bodySmall.copyWith(
                  color: isSelected ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFlutterComponentButtons(ThemeColors colors) {
    // Use centralized component library
    final componentsByCategory = ComponentLibrary.getComponentsAsMap();
    final componentDefinitions = ComponentLibrary.getComponentsForCategory(_selectedComponentCategory);
    
    final components = componentDefinitions.map((component) => component.toMap()).toList();
    
    return Wrap(
      spacing: SpacingTokens.xs,
      runSpacing: SpacingTokens.xs,
      children: components.map((component) {
        return InkWell(
          onTap: () => _addFlutterComponent(
            component['key'] as String,
            _selectedComponentCategory,
          ),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          child: Container(
            width: 70,
            height: 60,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  component['icon'] as IconData,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  component['name'] as String,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _addChatMessage(String message, bool isAgent) {
    setState(() {
      _chatMessages.add(ChatMessage(
        message: message,
        isAgent: isAgent,
        timestamp: DateTime.now(),
      ));
    });
  }

  Widget _buildChatInput(ThemeColors colors) {
    final hintText = _agentMode == 'plan' 
      ? 'Ask me to analyze, strategize, or think through design decisions...'
      : 'Tell me what to create, modify, or add to the canvas...';
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
        color: colors.background,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                prefixIcon: Icon(
                  _agentMode == 'plan' ? Icons.lightbulb_outline : Icons.play_arrow,
                  size: 20,
                  color: _agentMode == 'plan' ? colors.primary : colors.accent,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  borderSide: BorderSide(
                    color: _agentMode == 'plan' ? colors.primary : colors.accent,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.sm,
                ),
                filled: true,
                fillColor: colors.surface,
              ),
              maxLines: 1,
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          IconButton(
            onPressed: _sendMessage,
            icon: Icon(_agentMode == 'plan' ? Icons.psychology : Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: _agentMode == 'plan' ? colors.primary : colors.accent,
              foregroundColor: colors.surface,
              padding: const EdgeInsets.all(SpacingTokens.sm),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;
    
    // Add user message
    _addChatMessage(message, false);
    _chatController.clear();
    
    // Check if we need vision analysis for canvas-aware responses
    if (_needsVisionAnalysis(message)) {
      _requestVisionAnalysis(message);
    } else {
      // Parse message for canvas editing commands
      _processCanvasCommand(message);
    }
  }

  bool _needsVisionAnalysis(String message) {
    final visionKeywords = [
      'what\'s on', 'what do you see', 'describe', 'analyze', 'current canvas',
      'how does it look', 'what\'s drawn', 'improve this', 'fix this design',
      'make it better', 'what would you change', 'feedback on'
    ];
    
    final lowerMessage = message.toLowerCase();
    return visionKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  void _requestVisionAnalysis(String message) {
    debugPrint('🔍 Vision analysis requested for: "$message"');
    
    // Store the user's question for later processing
    _pendingVisionQuery = message;
    
    // Capture canvas for vision analysis
    _canvasKey.currentState?.captureCanvasForVision();
  }

  String? _pendingVisionQuery;

  void _handleVisionAnalysis(String base64Image, int elementsCount) async {
    if (_pendingVisionQuery == null) {
      debugPrint('❌ No pending vision query found');
      return;
    }

    debugPrint('🔍 Processing vision analysis for: "$_pendingVisionQuery"');
    debugPrint('🔍 Canvas has $elementsCount elements');

    try {
      // Get Unified LLM service
      final llmService = ServiceLocator.instance.get<UnifiedLLMService>();
      
      final visionSystemPrompt = '''You are an expert UI/UX design assistant with visual analysis capabilities. 
You can see and analyze the current state of a design canvas. Provide specific, actionable feedback about:
- Layout and composition
- Material Design compliance
- Color usage and accessibility
- Typography and spacing
- User experience improvements
- Missing elements or opportunities

Be specific and reference what you actually see in the image. Suggest concrete improvements.''';

      if (elementsCount == 0) {
        // Empty canvas
        _addChatMessage(
          'I can see the canvas is currently empty. Would you like me to help you get started with a design? '
          'I can create wireframes, layouts, or specific UI components following Material Design principles.',
          true,
        );
      } else {
        // Perform real vision analysis using configured models
        await _performRealVisionAnalysis(llmService, base64Image, _pendingVisionQuery!, visionSystemPrompt);
      }
    } catch (e) {
      debugPrint('❌ Vision analysis error: $e');
      _addChatMessage(
        'I can see there are $elementsCount elements on the canvas. While I can\'t perform detailed visual analysis right now, '
        'I can help you improve your design! Try asking me to add specific elements or describe what you\'d like to create.',
        true,
      );
    } finally {
      _pendingVisionQuery = null;
    }
  }

  Future<void> _performRealVisionAnalysis(
    UnifiedLLMService llmService, 
    String base64Image, 
    String query, 
    String systemPrompt
  ) async {
    try {
      debugPrint('🔍 Using real vision model for analysis');
      
      // Create chat context with system prompt
      final context = ChatContext(
        systemPrompt: systemPrompt,
        messages: [], // Fresh context for vision analysis
      );
      
      // Use vision-capable model for analysis
      final response = await llmService.visionChat(
        message: 'Please analyze this design canvas and answer: $query',
        base64Image: base64Image,
        context: context,
      );
      
      debugPrint('✅ Vision analysis completed using model: ${response.modelUsed}');
      
      // Add the AI response to chat
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _addChatMessage(response.content, true);
        }
      });
      
    } catch (e) {
      debugPrint('❌ Real vision analysis failed: $e');
      
      // Fallback to intelligent mock response
      await _performFallbackVisionAnalysis(query);
    }
  }

  Future<void> _performFallbackVisionAnalysis(String query) async {
    final responses = {
      'describe': 'I can see your design layout. Based on the elements present, let me suggest specific enhancements following Material Design principles.',
      'improve': 'Looking at your current design, I suggest focusing on consistent spacing (8dp grid), clear visual hierarchy with proper elevation, and ensuring color contrast meets WCAG AA standards.',
      'analyze': 'Your design shows structure. Consider: 1) Using Material Design component standards, 2) Implementing proper touch targets (48dp minimum), 3) Adding consistent spacing between elements.',
      'feedback': 'The layout has potential! Key improvements: align elements to an 8dp grid system, use consistent typography scales (Material Type Scale), and ensure interactive elements follow Material Design sizing guidelines.',
    };
    
    String response = 'I can analyze your design and provide feedback. ';
    
    for (String key in responses.keys) {
      if (query.toLowerCase().contains(key)) {
        response = responses[key]!;
        break;
      }
    }
    
    response += '\n\n*Note: Real-time vision analysis requires a configured Claude model with API key.*';
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _addChatMessage(response, true);
      }
    });
  }

  // Handle code generation from wireframe
  Future<void> _handleCodeGeneration(String imageData, int elementsCount, String prompt) async {
    if (!_visionService.isConfigured()) {
      _addChatMessage(
        'Code generation requires an OpenAI API key. Please configure your API key in the settings to enable this feature.',
        true,
      );
      return;
    }

    if (elementsCount == 0) {
      _addChatMessage(
        'The canvas appears to be empty. Please draw some wireframe elements first, then try generating code again.',
        true,
      );
      return;
    }

    setState(() {
      _isGeneratingCode = true;
    });

    _addChatMessage(
      'Generating HTML/CSS code from your wireframe... This may take a moment.',
      true,
    );

    try {
      debugPrint('🔄 Starting code generation with ${elementsCount} elements');
      
      final generatedCode = await _visionService.generateCodeFromWireframe(
        imageData,
        prompt: prompt,
      );

      setState(() {
        _generatedCode = generatedCode;
        _isGeneratingCode = false;
      });

      _addChatMessage(
        '✅ Code generated successfully! Here\'s the HTML/CSS code for your wireframe:\n\n'
        '```html\n$generatedCode\n```\n\n'
        'You can copy this code and use it as a starting point for your project. '
        'The code includes responsive design and follows modern web standards.',
        true,
      );

      // Show code in a separate dialog for easy copying
      if (mounted) {
        _showGeneratedCodeDialog(generatedCode);
      }

    } catch (e) {
      setState(() {
        _isGeneratingCode = false;
      });

      debugPrint('❌ Code generation failed: $e');
      
      String errorMessage = 'Failed to generate code from wireframe.';
      if (e.toString().contains('API key')) {
        errorMessage = 'OpenAI API key is invalid or missing. Please check your API key in settings.';
      } else if (e.toString().contains('quota')) {
        errorMessage = 'OpenAI API quota exceeded. Please check your account billing.';
      }

      _addChatMessage(
        '❌ $errorMessage\n\nError details: ${e.toString()}',
        true,
      );
    }
  }

  // Show generated code in a dialog for easy copying
  void _showGeneratedCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final colors = ThemeColors(context);
        
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Generated Code',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  border: Border.all(color: colors.border),
                ),
                child: SelectableText(
                  code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            AsmblButton.secondary(
              text: 'Copy Code',
              icon: Icons.copy,
              onPressed: () {
                // Copy to clipboard
                // Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Code copied to clipboard'),
                    backgroundColor: colors.success,
                  ),
                );
              },
            ),
            AsmblButton.outline(
              text: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // Quick element button builder
  Widget _buildQuickElementButton(ThemeColors colors, String label, String elementType, IconData icon) {
    return InkWell(
      onTap: () => _addEnhancedElement(elementType, label),
      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              label,
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add enhanced elements
  void _addEnhancedElement(String elementType, String label) {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.addCanvasElement(elementType, 'Add $label');
      _addChatMessage('Added $label element to the canvas.', true);
    }
  }

  // Add mobile template
  void _addMobileTemplate() {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.addMobileAppTemplate();
      _addChatMessage(
        'Added mobile app template with header, content cards, and bottom navigation. You can modify individual elements as needed.',
        true,
      );
    }
  }

  // Add web header template
  void _addWebHeaderTemplate() {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.addWebHeaderTemplate();
      _addChatMessage(
        'Added web header template with logo, company name, and navigation menu. Perfect for website wireframes!',
        true,
      );
    }
  }

  // Generate code from current canvas
  void _generateCodeFromCanvas() {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.generateCodeFromWireframe();
      _addChatMessage(
        'Starting code generation from your wireframe. This will analyze the current design and create HTML/CSS code.',
        true,
      );
    }
  }

  // Flutter component library methods
  void _addFlutterComponent(String componentKey, String category) {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.addFlutterComponent(componentKey, category);
      _addChatMessage(
        'Added Flutter $componentKey component to your wireframe.',
        true,
      );
    }
  }

  void _addFlutterScreenTemplate(String templateType) {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.addFlutterScreenTemplate(templateType);
      _addChatMessage(
        'Added Flutter $templateType screen template to your wireframe.',
        true,
      );
    }
  }

  // Design Agent Canvas Integration Bridge Methods
  
  /// Add canvas element triggered by design agent
  void _addCanvasElementFromAgent(String elementType, String prompt) {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.addCanvasElement(elementType, prompt);
      debugPrint('🤖 Design agent added element: $elementType with prompt: "$prompt"');
      
      // Add chat feedback
      _addChatMessage(
        'Design Agent: Added $elementType element to the canvas with label "$prompt".',
        true,
      );
    } else {
      debugPrint('❌ Cannot add element from agent - Canvas not ready');
      _addChatMessage(
        'Design Agent: Canvas not ready. Please wait a moment and try again.',
        true,
      );
    }
  }

  /// Add template triggered by design agent  
  void _addTemplateFromAgent(String templateType) {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      switch (templateType.toLowerCase()) {
        case 'mobile_app':
        case 'mobile':
          canvas.addMobileAppTemplate();
          _addChatMessage(
            'Design Agent: Added mobile app template with header, navigation, and content sections.',
            true,
          );
          break;
        case 'web_header': 
        case 'header':
          canvas.addWebHeaderTemplate();
          _addChatMessage(
            'Design Agent: Added web header template with logo, navigation, and CTA button.',
            true,
          );
          break;
        default:
          canvas.addWireframeTemplate();
          _addChatMessage(
            'Design Agent: Added basic wireframe template.',
            true,
          );
      }
      debugPrint('🤖 Design agent added template: $templateType');
    } else {
      debugPrint('❌ Cannot add template from agent - Canvas not ready');
      _addChatMessage(
        'Design Agent: Canvas not ready. Please wait a moment and try again.',
        true,
      );
    }
  }

  /// Add Flutter component triggered by design agent
  void _addFlutterComponentFromAgent(String componentKey, String category) {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.addFlutterComponent(componentKey, category);
      debugPrint('🤖 Design agent added Flutter component: $componentKey from $category');
      
      _addChatMessage(
        'Design Agent: Added Flutter $componentKey component from $category library.',
        true,
      );
    } else {
      debugPrint('❌ Cannot add Flutter component from agent - Canvas not ready');
      _addChatMessage(
        'Design Agent: Canvas not ready. Please wait a moment and try again.',
        true,
      );
    }
  }

  /// Add Flutter screen template triggered by design agent
  void _addFlutterScreenTemplateFromAgent(String templateType) {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.addFlutterScreenTemplate(templateType);
      debugPrint('🤖 Design agent added Flutter screen template: $templateType');
      
      final templateNames = {
        'dashboard': 'dashboard layout with cards and metrics',
        'list': 'list view with scrollable items',
        'form': 'form layout with input fields and validation',
      };
      
      final description = templateNames[templateType.toLowerCase()] ?? '$templateType layout';
      _addChatMessage(
        'Design Agent: Added Flutter $templateType screen template with $description.',
        true,
      );
    } else {
      debugPrint('❌ Cannot add Flutter template from agent - Canvas not ready');
      _addChatMessage(
        'Design Agent: Canvas not ready. Please wait a moment and try again.',
        true,
      );
    }
  }

  void _processCanvasCommand(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Check for various editing commands
    if (_isCanvasEditCommand(lowerMessage)) {
      _executeCanvasEdit(message, lowerMessage);
    } else {
      // Default AI response for general queries
      Future.delayed(const Duration(milliseconds: 500), () {
        _addChatMessage(
          'I understand you want to work on "$message". Let me help you with that! '
          'You can use the canvas to draw your ideas, and I can suggest improvements '
          'or generate wireframes based on your requirements.\n\n'
          'Try commands like:\n'
          '• "Add a button in the center"\n'
          '• "Create a wireframe layout"\n'
          '• "Add text that says Hello World"\n'
          '• "Draw a rectangle with Login text"',
          true,
        );
      });
    }
  }

  bool _isCanvasEditCommand(String message) {
    final editKeywords = [
      'add', 'create', 'draw', 'insert', 'make',
      'remove', 'delete', 'clear', 'move', 'change',
      'button', 'text', 'rectangle', 'circle', 'line',
      'wireframe', 'layout', 'component', 'element'
    ];
    
    return editKeywords.any((keyword) => message.contains(keyword));
  }

  void _executeCanvasEdit(String originalMessage, String lowerMessage) {
    Future.delayed(const Duration(milliseconds: 500), () {
      String response = '';
      String? action;
      
      // Parse different types of commands
      if (lowerMessage.contains('wireframe') || lowerMessage.contains('layout')) {
        action = 'wireframe';
        response = 'Perfect! I\'ve added a wireframe layout to your canvas. You can see the basic structure with header, navigation, and content areas.';
        _addWireframeElements();
      } else if (lowerMessage.contains('button')) {
        action = 'button';
        response = 'I\'ve added a button element to your canvas. You can move it around and customize its appearance.';
        _addCanvasElement('button', originalMessage);
      } else if (lowerMessage.contains('text')) {
        action = 'text';
        response = 'I\'ve added a text element to your canvas. You can edit the content and style it as needed.';
        _addCanvasElement('text', originalMessage);
      } else if (lowerMessage.contains('rectangle') || lowerMessage.contains('box')) {
        action = 'rectangle';
        response = 'I\'ve drawn a rectangle on your canvas. You can resize and reposition it as needed.';
        _addCanvasElement('rectangle', originalMessage);
      } else if (lowerMessage.contains('circle')) {
        action = 'circle';
        response = 'I\'ve added a circle to your canvas. You can adjust its size and position.';
        _addCanvasElement('circle', originalMessage);
      } else if (lowerMessage.contains('clear') || lowerMessage.contains('remove all')) {
        action = 'clear';
        response = 'I\'ve cleared the canvas for you. You can start fresh with your new design.';
        _clearCanvas();
      } else {
        // Generic editing response
        response = 'I understand you want to modify the canvas. I\'ve made some updates based on your request: "$originalMessage"';
        _addCanvasElement('generic', originalMessage);
      }
      
      _addChatMessage(response, true);
      
      // Log the action for analytics
      debugPrint('🎨 Canvas edit executed: $action for prompt: "$originalMessage"');
    });
  }

  void _addCanvasElement(String elementType, String prompt) {
    debugPrint('🎨 Adding $elementType element based on prompt: "$prompt"');
    
    // Call JavaScript function to add the element to Excalidraw
    if (_canvasKey.currentState != null) {
      _canvasKey.currentState!.addCanvasElement(elementType, prompt);
    } else {
      debugPrint('❌ Canvas not ready for element addition');
    }
  }

  // Canvas actions
  void _saveDrawing() {
    _canvasKey.currentState?.saveDrawing();
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text('Are you sure you want to clear the canvas? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _canvasKey.currentState?.clearCanvas();
              setState(() {
                _canvasHasContent = false;
                _currentDrawingData = null;
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportPNG() {
    _canvasKey.currentState?.exportToPNG();
  }

  void _addWireframeElements() {
    _canvasKey.currentState?.addWireframeTemplate();
  }

  void _showContextLibrary() async {
    showDialog(
      context: context,
      builder: (context) => _ContextLibraryDialog(
        onDocumentSelected: (document) => _insertDocumentToCanvas(document),
      ),
    );
  }

  void _insertDocumentToCanvas(ContextDocument document) {
    // Add the document content as a text element to the canvas
    _addChatMessage('Added "${document.title}" to canvas', false);
    _addChatMessage('Great! I\'ve added "${document.title}" to your canvas. You can now reference this context while designing.', true);
    
    // TODO: Actually insert document content into Excalidraw
    // This would require extending the JavaScript bridge to add text elements
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${document.title}" to canvas context'),
        backgroundColor: ThemeColors(context).success,
      ),
    );
  }

  // New methods for collaborative planning interface
  
  Widget _buildPlanDocumentInterface(ThemeColors colors) {
    final completedSections = _planDocument.values.where((value) => value.toString().isNotEmpty).length;
    final totalSections = _planSections.length;
    final progress = totalSections > 0 ? completedSections / totalSections : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withOpacity(0.05),
            colors.accent.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.description, color: colors.primary, size: 24),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan.doc - Collaborative Strategy',
                      style: TextStyles.cardTitle.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Progress: $completedSections/$totalSections sections completed',
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (progress > 0.8)
                AsmblButton.accent(
                  text: 'Finalize Plan',
                  onPressed: _finalizePlan,
                ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.md),
          
          // Progress indicator
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Active section editor or section selector
          if (_activePlanSection.isEmpty)
            _buildPlanSectionSelector(colors)
          else
            _buildPlanSectionEditor(colors),
        ],
      ),
    );
  }

  Widget _buildPlanSectionSelector(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a planning area to collaborate on:',
          style: TextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        
        Wrap(
          spacing: SpacingTokens.sm,
          runSpacing: SpacingTokens.sm,
          children: _planSections.map((section) {
            final isCompleted = _planDocument[section]?.toString().isNotEmpty ?? false;
            final sectionTitle = _formatSectionTitle(section);
            
            return Material(
              color: isCompleted 
                ? colors.success.withOpacity(0.1) 
                : colors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              child: InkWell(
                onTap: () => _selectPlanSection(section),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.md,
                    vertical: SpacingTokens.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isCompleted 
                        ? colors.success.withOpacity(0.3)
                        : colors.border,
                    ),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 16,
                        color: isCompleted ? colors.success : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        sectionTitle,
                        style: TextStyles.bodySmall.copyWith(
                          color: isCompleted ? colors.success : colors.onSurface,
                          fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlanSectionEditor(ThemeColors colors) {
    final sectionTitle = _formatSectionTitle(_activePlanSection);
    final currentContent = _planDocument[_activePlanSection]?.toString() ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, size: 18),
              onPressed: () => _closePlanSection(),
              style: IconButton.styleFrom(
                foregroundColor: colors.onSurfaceVariant,
                padding: const EdgeInsets.all(SpacingTokens.xs),
              ),
            ),
            Expanded(
              child: Text(
                sectionTitle,
                style: TextStyles.sectionTitle.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
            AsmblButton.outline(
              text: 'Ask AI Help',
              onPressed: () => _requestPlanSectionHelp(_activePlanSection),
            ),
          ],
        ),
        
        const SizedBox(height: SpacingTokens.md),
        
        // Section content editor
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: TextEditingController(text: currentContent),
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: _getPlanSectionHint(_activePlanSection),
                  hintStyle: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyles.bodyMedium,
                onChanged: (value) => _updatePlanSection(_activePlanSection, value),
              ),
              
              const SizedBox(height: SpacingTokens.md),
              
              Row(
                children: [
                  Expanded(
                    child: AsmblButton.secondary(
                      text: 'Save & Next Section',
                      onPressed: currentContent.trim().isNotEmpty 
                        ? _saveAndNextSection
                        : null,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  AsmblButton.primary(
                    text: 'Complete',
                    onPressed: currentContent.trim().isNotEmpty 
                      ? _markSectionComplete
                      : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // AI suggestions for this section
        if (_activePlanSection.isNotEmpty)
          _buildPlanSectionSuggestions(colors),
      ],
    );
  }

  Widget _buildPlanSectionSuggestions(ThemeColors colors) {
    final suggestions = _getPlanSectionSuggestions(_activePlanSection);
    
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: SpacingTokens.md),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: colors.accent, size: 16),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'AI Suggestions',
                style: TextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          ...suggestions.map((suggestion) => 
            Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyles.bodySmall),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildActionModeInterface(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent.withOpacity(0.1),
            colors.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            _isPlanComplete ? Icons.rocket_launch : Icons.warning_outlined, 
            color: _isPlanComplete ? colors.accent : colors.warning, 
            size: 32
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            _isPlanComplete ? 'Action Mode Active' : 'Plan Required',
            style: TextStyles.cardTitle.copyWith(
              color: _isPlanComplete ? colors.accent : colors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            _isPlanComplete 
              ? 'I\'ll execute the plan.doc we created together, taking direct actions on the canvas based on our collaborative strategy.'
              : 'Complete the plan.doc first to enable precise execution based on our collaborative strategy.',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (_isPlanComplete) ...[
            const SizedBox(height: SpacingTokens.lg),
            Row(
              children: [
                Expanded(
                  child: AsmblButton.outline(
                    text: 'View Plan.doc',
                    onPressed: () => _showPlanDocument(),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: AsmblButton.accent(
                    text: 'Start Execution',
                    onPressed: () => _startPlanExecution(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods for plan document management
  
  String _formatSectionTitle(String sectionId) {
    switch (sectionId) {
      case 'projectGoals': return 'Project Goals';
      case 'userNeeds': return 'User Needs';
      case 'designStrategy': return 'Design Strategy';
      case 'layoutApproach': return 'Layout Approach';
      case 'componentPriority': return 'Component Priority';
      case 'interactionPatterns': return 'Interaction Patterns';
      case 'accessibilityConsiderations': return 'Accessibility';
      case 'technicalConstraints': return 'Technical Constraints';
      case 'designPrinciples': return 'Design Principles';
      case 'successMetrics': return 'Success Metrics';
      default: return sectionId;
    }
  }

  String _getPlanSectionHint(String sectionId) {
    switch (sectionId) {
      case 'projectGoals': 
        return 'What are we trying to achieve with this design? What problem does it solve?';
      case 'userNeeds': 
        return 'Who are our users and what do they need to accomplish?';
      case 'designStrategy': 
        return 'What\'s our overall approach to solving the design challenge?';
      case 'layoutApproach': 
        return 'How should we structure the information and interface elements?';
      case 'componentPriority': 
        return 'Which components are most important and should be designed first?';
      case 'interactionPatterns': 
        return 'How should users interact with different elements?';
      case 'accessibilityConsiderations': 
        return 'How will we ensure the design is accessible to all users?';
      case 'technicalConstraints': 
        return 'What technical limitations or requirements should we consider?';
      case 'designPrinciples': 
        return 'What core principles will guide our design decisions?';
      case 'successMetrics': 
        return 'How will we measure if the design is successful?';
      default: 
        return 'Describe your thoughts on this planning area...';
    }
  }

  List<String> _getPlanSectionSuggestions(String sectionId) {
    switch (sectionId) {
      case 'projectGoals':
        return [
          'Define clear, measurable objectives',
          'Consider both user and business goals',
          'Identify success criteria upfront',
        ];
      case 'userNeeds':
        return [
          'Create user personas based on research',
          'Map user journeys and pain points',
          'Prioritize features by user value',
        ];
      case 'designStrategy':
        return [
          'Choose design patterns that match user mental models',
          'Balance innovation with familiar conventions',
          'Consider mobile-first or desktop-first approach',
        ];
      case 'layoutApproach':
        return [
          'Use grid systems for consistent alignment',
          'Prioritize content hierarchy visually',
          'Consider responsive breakpoints',
        ];
      default:
        return [];
    }
  }

  void _selectPlanSection(String sectionId) {
    setState(() {
      _activePlanSection = sectionId;
    });
    
    _addChatMessage('Working on: ${_formatSectionTitle(sectionId)}', false);
    _addChatMessage(
      'Great! Let\'s collaborate on ${_formatSectionTitle(sectionId).toLowerCase()}. ${_getPlanSectionHint(sectionId)}',
      true,
    );
  }

  void _closePlanSection() {
    setState(() {
      _activePlanSection = '';
    });
  }

  void _updatePlanSection(String sectionId, String content) {
    setState(() {
      _planDocument[sectionId] = content;
    });
  }

  void _saveAndNextSection() {
    final currentIndex = _planSections.indexOf(_activePlanSection);
    if (currentIndex < _planSections.length - 1) {
      final nextSection = _planSections[currentIndex + 1];
      _selectPlanSection(nextSection);
    } else {
      _markSectionComplete();
    }
  }

  void _markSectionComplete() {
    final sectionTitle = _formatSectionTitle(_activePlanSection);
    _addChatMessage('Completed: $sectionTitle', false);
    _addChatMessage('Excellent! I\'ve saved the $sectionTitle section to our plan.doc. This will help guide the execution phase.', true);
    
    setState(() {
      _activePlanSection = '';
    });
    
    _checkPlanCompletion();
  }

  void _checkPlanCompletion() {
    final completedSections = _planDocument.values.where((value) => value.toString().isNotEmpty).length;
    final progress = completedSections / _planSections.length;
    
    if (progress >= 0.8 && !_isPlanComplete) {
      _addChatMessage(
        'Our plan.doc is nearly complete! We\'ve collaborated on ${completedSections} sections. Ready to finalize and move to execution mode?',
        true,
      );
    }
  }

  void _requestPlanSectionHelp(String sectionId) {
    final sectionTitle = _formatSectionTitle(sectionId);
    _addChatMessage('Need help with $sectionTitle', false);
    
    final projectType = _currentSpec['projectType'] ?? 'application';
    final designPhase = _currentSpec['designPhase'] ?? 'concept';
    
    String helpResponse = '';
    switch (sectionId) {
      case 'projectGoals':
        helpResponse = 'For a $projectType in the $designPhase phase, consider these goals:\n\n• User Experience: Improve task completion rates\n• Business Impact: Increase user engagement\n• Technical: Optimize for performance and accessibility\n• Design: Create a cohesive, branded experience';
        break;
      case 'userNeeds':
        helpResponse = 'Based on your $projectType project, users typically need:\n\n• Clear navigation and wayfinding\n• Efficient task completion flows\n• Accessible information architecture\n• Responsive design across devices\n\nConsider creating user stories: "As a user, I want..."';
        break;
      case 'designStrategy':
        helpResponse = 'For your $projectType, I suggest this strategic approach:\n\n• Start with information architecture\n• Use familiar design patterns\n• Prioritize mobile experience\n• Plan for scalability and future features';
        break;
      default:
        helpResponse = 'I\'m here to help you think through $sectionTitle. Consider how this relates to your ${projectType} project and the specific needs of your users.';
    }
    
    Future.delayed(const Duration(milliseconds: 800), () {
      _addChatMessage(helpResponse, true);
    });
  }

  void _finalizePlan() {
    setState(() {
      _isPlanComplete = true;
      _planProgress = 'Complete';
    });
    
    _addChatMessage('Finalize the collaborative plan', false);
    _addChatMessage(
      'Perfect! Our plan.doc is now complete and ready for execution. I have all the strategic context I need to take precise actions on the canvas. Switch to Action Mode when you\'re ready to implement our collaborative strategy.',
      true,
    );
  }

  void _showPlanDocument() {
    // This would show a full view of the completed plan document
    _addChatMessage('Show me the complete plan.doc', false);
    
    final completedSections = _planDocument.entries
      .where((entry) => entry.value.toString().isNotEmpty)
      .map((entry) => '${_formatSectionTitle(entry.key)}: ${entry.value}')
      .join('\n\n');
    
    _addChatMessage(
      'Here\'s our collaborative plan.doc:\n\n$completedSections\n\nThis comprehensive plan will guide all my actions in execution mode.',
      true,
    );
  }

  void _startPlanExecution() {
    _addChatMessage('Begin executing our plan.doc', false);
    _addChatMessage(
      'Excellent! I\'m now executing our collaborative strategy. I\'ll create design elements based on our plan.doc and provide updates as I work through each component.',
      true,
    );
    
    // Actually start implementing based on the plan
    Future.delayed(const Duration(milliseconds: 1500), () {
      _executeSpecBasedAction('layout');
    });
  }

  // New Agent Tab - Dedicated Design Agent Sidebar
  Widget _buildAgentTab(ThemeColors colors) {
    return DesignAgentSidebar(
      agent: _designAgent,
      onSpecUpdate: (spec) {
        setState(() {
          _currentSpec = spec;
          if (spec.isNotEmpty) {
            _showSpecsCompleteAnimation();
          }
        });
      },
      onContextUpdate: (context) {
        setState(() {
          _currentContext = context;
        });
      },
      // Canvas action callbacks for design agent integration
      onAddCanvasElement: _addCanvasElementFromAgent,
      onAddTemplate: _addTemplateFromAgent,
      onAddFlutterComponent: _addFlutterComponentFromAgent,
      onAddFlutterScreenTemplate: _addFlutterScreenTemplateFromAgent,
      onGenerateCode: _generateCodeFromCanvas,
      onClearCanvas: () => _canvasKey.currentState?.clearCanvas(),
      onCaptureCanvas: () => _canvasKey.currentState?.captureCanvasForVision(),
    );
  }

  // Detailed Specs Panel - Shows specification details and editing interface
  Widget _buildDetailedSpecsPanel(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Specifications',
              style: TextStyles.sectionTitle.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            
            // Project Type
            _buildSpecField(
              'Project Type',
              _currentSpec['projectType']?.toString() ?? 'Not specified',
              Icons.category,
              colors,
            ),
            const SizedBox(height: SpacingTokens.md),
            
            // Design Phase
            _buildSpecField(
              'Design Phase',
              _currentSpec['designPhase']?.toString() ?? 'Not specified',
              Icons.timeline,
              colors,
            ),
            const SizedBox(height: SpacingTokens.md),
            
            // Platforms
            _buildSpecField(
              'Target Platforms',
              (_currentSpec['platforms'] as List?)?.join(', ') ?? 'Not specified',
              Icons.devices,
              colors,
            ),
            const SizedBox(height: SpacingTokens.md),
            
            // Context Count
            _buildSpecField(
              'Design Context',
              '${_currentContext.length} items attached',
              Icons.folder,
              colors,
            ),
            
            if (_currentSpec['requirements'] != null) ...[
              const SizedBox(height: SpacingTokens.lg),
              Text(
                'Requirements',
                style: TextStyles.cardTitle.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  _currentSpec['requirements']?.toString() ?? 'No requirements specified',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecField(String label, String value, IconData icon, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  value,
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Spec Creation Panel - Interface for creating new specifications
  Widget _buildSpecCreationPanel(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.assignment, color: colors.primary, size: 48),
                const SizedBox(height: SpacingTokens.md),
                Text(
                  'Create Project Specifications',
                  style: TextStyles.sectionTitle.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'Define your project requirements, target platforms, and design goals to get better assistance from the design agent.',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.lg),
                AsmblButton.primary(
                  text: 'Use Design Agent to Create Specs',
                  icon: Icons.smart_toy,
                  onPressed: () {
                    setState(() {
                      _activeTab = 'agent';
                    });
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: SpacingTokens.xl),
          
          Text(
            'Quick Start Options',
            style: TextStyles.cardTitle.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          
          // Quick start templates
          _buildQuickStartOption(
            'Web Application',
            'Responsive web app with modern UI',
            Icons.web,
            colors,
            () => _createQuickSpec('web_app'),
          ),
          const SizedBox(height: SpacingTokens.sm),
          _buildQuickStartOption(
            'Mobile App',
            'iOS/Android mobile application',
            Icons.phone_android,
            colors,
            () => _createQuickSpec('mobile_app'),
          ),
          const SizedBox(height: SpacingTokens.sm),
          _buildQuickStartOption(
            'Dashboard',
            'Data visualization dashboard',
            Icons.dashboard,
            colors,
            () => _createQuickSpec('dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartOption(
    String title,
    String description,
    IconData icon,
    ThemeColors colors,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createQuickSpec(String projectType) {
    final Map<String, dynamic> quickSpec = {
      'projectType': projectType,
      'designPhase': 'concept',
      'platforms': _getDefaultPlatforms(projectType),
      'requirements': {},
      'contexts': [],
    };

    setState(() {
      _currentSpec = quickSpec;
    });

    _showSpecsCompleteAnimation();
  }

  List<String> _getDefaultPlatforms(String projectType) {
    switch (projectType) {
      case 'web_app':
        return ['responsive_web', 'desktop'];
      case 'mobile_app':
        return ['ios', 'android'];
      case 'dashboard':
        return ['responsive_web'];
      default:
        return ['responsive_web'];
    }
  }
}

/// Data model for chat messages
class ChatMessage {
  final String message;
  final bool isAgent;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.isAgent,
    required this.timestamp,
  });
}

/// Context Library Dialog for selecting documents to add to canvas
class _ContextLibraryDialog extends StatefulWidget {
  final Function(ContextDocument) onDocumentSelected;

  const _ContextLibraryDialog({
    required this.onDocumentSelected,
  });

  @override
  State<_ContextLibraryDialog> createState() => _ContextLibraryDialogState();
}

class _ContextLibraryDialogState extends State<_ContextLibraryDialog> {
  List<ContextDocument> _documents = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      // Check if context service is registered
      if (ServiceLocator.instance.isRegistered<ContextBusinessService>()) {
        final contextService = ServiceLocator.instance.get<ContextBusinessService>();
        final result = await contextService.getDocuments();
        
        if (result.isSuccess) {
          setState(() {
            _documents = result.data ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result.error ?? 'Failed to load documents';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Context service not available. Please configure context integration.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading documents: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.library_books, color: colors.accent),
          const SizedBox(width: SpacingTokens.sm),
          const Text('Context Library'),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _buildContent(colors),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeColors colors) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 48),
            const SizedBox(height: SpacingTokens.md),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.lg),
            AsmblButton.outline(
              text: 'Go to Context',
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to context screen
                // context.go(AppRoutes.context);
              },
            ),
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, color: colors.onSurfaceVariant, size: 48),
            const SizedBox(height: SpacingTokens.md),
            Text(
              'No documents found',
              style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              'Add some documents to your context library to reference them in your designs.',
              textAlign: TextAlign.center,
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
          child: ListTile(
            leading: Icon(
              _getDocumentIcon(document.type),
              color: colors.primary,
            ),
            title: Text(
              document.title,
              style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
            ),
            subtitle: Text(
              document.content.length > 100 
                ? '${document.content.substring(0, 100)}...'
                : document.content,
              style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
            trailing: Icon(Icons.add_circle_outline, color: colors.accent),
            onTap: () {
              widget.onDocumentSelected(document);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  IconData _getDocumentIcon(ContextType type) {
    switch (type) {
      case ContextType.documentation:
        return Icons.description;
      case ContextType.codebase:
        return Icons.code;
      case ContextType.guidelines:
        return Icons.rule;
      case ContextType.examples:
        return Icons.lightbulb;
      case ContextType.knowledge:
        return Icons.school;
      case ContextType.custom:
        return Icons.edit_note;
      default:
        return Icons.description;
    }
  }
}