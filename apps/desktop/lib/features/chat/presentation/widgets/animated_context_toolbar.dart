import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:agent_engine_core/models/conversation.dart' as core;
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/models/model_config.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../core/services/model_config_service.dart';
import '../../../../core/services/quick_chat_model_service.dart';
import '../../../../providers/conversation_provider.dart';
import '../../../../providers/artifact_provider.dart';
import '../../../../providers/agent_provider.dart';
import '../../../../core/models/artifact.dart';
import 'package:agent_engine_core/models/agent.dart';

/// Animated context toolbar that shows conversation status and quick actions
///
/// Features:
/// - Hover expansion to show full details
/// - Smooth animations for status changes
/// - Minimal when inactive, informative when hovered
/// - Shows Quick Chat, MCP tools, context docs status
/// - Shows active agent with its configured tools
/// - Always visible, even before a conversation is created
class AnimatedContextToolbar extends ConsumerStatefulWidget {
  final String? conversationId;
  final String? agentId;

  const AnimatedContextToolbar({
    super.key,
    this.conversationId,
    this.agentId,
  });

  @override
  ConsumerState<AnimatedContextToolbar> createState() => _AnimatedContextToolbarState();
}

class _AnimatedContextToolbarState extends ConsumerState<AnimatedContextToolbar>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final mcpService = ref.watch(mcpSettingsServiceProvider);
    final modelConfigService = ref.read(modelConfigServiceProvider);

    // Fetch active agent if agentId is provided
    Agent? activeAgent;
    if (widget.agentId != null) {
      final agentsAsync = ref.watch(agentsProvider);
      agentsAsync.whenData((agents) {
        activeAgent = agents.where((a) => a.id == widget.agentId).firstOrNull;
      });
    }

    // If no conversation, show toolbar with MCP/context info only
    if (widget.conversationId == null) {
      final mcpServers = mcpService.getAllMCPServers().where((s) => s.enabled).toList();
      final contextDocs = mcpService.globalContextDocuments;
      final hasContent = mcpServers.isNotEmpty || contextDocs.isNotEmpty || activeAgent != null;
      final defaultModel = modelConfigService.defaultModelConfig;

      return _buildToolbarUI(
        context: context,
        colors: colors,
        hasContent: hasContent,
        isQuickChatActive: false,
        mcpServers: mcpServers,
        contextDocs: contextDocs,
        artifacts: const [], // No artifacts without a conversation
        modelConfig: defaultModel,
        activeAgent: activeAgent,
      );
    }

    // With conversation, show full info including Quick Chat status
    final isQuickChatActive = ref.watch(isQuickChatActiveProvider(widget.conversationId!));
    final conversationAsync = ref.watch(conversationProvider(widget.conversationId!));
    final modelConfig = ref.watch(conversationModelConfigProvider(widget.conversationId!));

    return conversationAsync.when(
      data: (conversation) {
        final isAgent = conversation.metadata?['type'] == 'agent';
        final mcpServers = mcpService.getAllMCPServers().where((s) => s.enabled).toList();
        final contextDocs = mcpService.globalContextDocuments;

        // Get artifacts for this conversation
        final artifacts = ref.watch(conversationArtifactsProvider(widget.conversationId!));

        // ALWAYS show toolbar - start at 0.5 opacity/visibility as base state
        // Even with no content, show minimal presence
        final hasContent = isQuickChatActive || mcpServers.isNotEmpty ||
                           contextDocs.isNotEmpty || artifacts.isNotEmpty || activeAgent != null;

        return _buildToolbarUI(
          context: context,
          colors: colors,
          hasContent: hasContent,
          isQuickChatActive: isQuickChatActive,
          mcpServers: mcpServers,
          contextDocs: contextDocs,
          artifacts: artifacts,
          modelConfig: modelConfig,
          activeAgent: activeAgent,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Builds the toolbar UI with status indicators and quick actions
  Widget _buildToolbarUI({
    required BuildContext context,
    required ThemeColors colors,
    required bool hasContent,
    required bool isQuickChatActive,
    required List mcpServers,
    required List contextDocs,
    required List<Artifact> artifacts,
    required ModelConfig? modelConfig,
    Agent? activeAgent,
  }) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: SpacingTokens.lg),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            // macOS dock-style height: compact when idle, expands on hover
            height: _isHovered ? 52 : (hasContent ? 44 : 40),
            padding: EdgeInsets.symmetric(
              horizontal: _isHovered ? SpacingTokens.xl : SpacingTokens.lg,
              vertical: SpacingTokens.sm,
            ),
            decoration: BoxDecoration(
              // Frosted glass effect background
              color: colors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16), // Pill shape like dock
              border: Border.all(
                color: colors.border.withValues(alpha: 0.2),
                width: 0.5,
              ),
              boxShadow: [
                // macOS dock-style shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Left side: Status indicators
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      // Agent Tools indicator (clickable with popup menu like other dock items)
                      if (activeAgent != null) ...[
                        _AgentToolsChip(
                          agent: activeAgent,
                          tools: _getAgentToolsList(activeAgent),
                          isHovered: _isHovered,
                          pulseController: _pulseController,
                        ),
                        const SizedBox(width: SpacingTokens.md),
                      ],

                      // Quick Chat indicator
                      if (isQuickChatActive) ...[
                        _StatusChip(
                          icon: Icons.bolt,
                          label: 'Instant',
                          color: colors.accent,
                          isHovered: _isHovered,
                          pulseController: _pulseController,
                          details: _isHovered ? 'Quick Chat • Fast responses' : null,
                        ),
                        const SizedBox(width: SpacingTokens.md),
                      ],

                      // MCP Tools indicator (only show if no agent, to avoid duplicate)
                      if (activeAgent == null && mcpServers.isNotEmpty) ...[
                        _StatusChip(
                          icon: Icons.construction,
                          label: '${mcpServers.length} ${mcpServers.length == 1 ? 'tool' : 'tools'}',
                          color: colors.primary,
                          isHovered: _isHovered,
                          pulseController: _pulseController,
                          details: _isHovered ? mcpServers.take(3).map((s) => s.name).join(' • ') : null,
                        ),
                        const SizedBox(width: SpacingTokens.md),
                      ],

                      // Context documents indicator
                      if (contextDocs.isNotEmpty) ...[
                        _StatusChip(
                          icon: Icons.description,
                          label: '${contextDocs.length} ${contextDocs.length == 1 ? 'doc' : 'docs'}',
                          color: colors.success,
                          isHovered: _isHovered,
                          pulseController: _pulseController,
                          details: null,
                        ),
                        const SizedBox(width: SpacingTokens.md),
                      ],

                      // Artifacts indicator
                      if (artifacts.isNotEmpty) ...[
                        _StatusChip(
                          icon: Icons.widgets,
                          label: '${artifacts.length} ${artifacts.length == 1 ? 'artifact' : 'artifacts'}',
                          color: colors.accent,
                          isHovered: _isHovered,
                          pulseController: _pulseController,
                          details: _isHovered ? artifacts.take(3).map((a) => '${a.type.icon} ${a.title}').join(' • ') : null,
                        ),
                      ],

                      // Model status indicator - always visible
                      _buildModelStatusIndicator(colors, modelConfig),
                    ],
                  ),

                  // Divider between status and actions
                  if (hasContent || _isHovered)
                    Container(
                      height: 24,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
                      color: colors.border.withValues(alpha: 0.3),
                    ),

                  // Right side: Quick actions (minimal when not hovered)
                  AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHovered ? 1.0 : 0.3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // New conversation with context menu
                    _ActionButtonWithMenu(
                      icon: Icons.add_circle_outline,
                      label: _isHovered ? 'New Chat' : null,
                      onTap: () => _createNewConversation(context),
                      isHovered: _isHovered,
                      menuItems: [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.chat, size: 18),
                              const SizedBox(width: 8),
                              const Text('New Chat'),
                            ],
                          ),
                          onTap: () => _createNewConversation(context),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.smart_toy, size: 18),
                              const SizedBox(width: 8),
                              const Text('New Agent Chat'),
                            ],
                          ),
                          onTap: () => _createNewAgentConversation(context),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.bolt, size: 18),
                              const SizedBox(width: 8),
                              const Text('Quick Chat'),
                            ],
                          ),
                          onTap: () => _createQuickChat(context),
                        ),
                      ],
                    ),
                    const SizedBox(width: SpacingTokens.sm),

                    // Conversation list with context menu
                    _ActionButtonWithMenu(
                      icon: Icons.chat_bubble_outline,
                      label: _isHovered ? 'Chats' : null,
                      onTap: () => _showConversationList(context),
                      isHovered: _isHovered,
                      menuItems: [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.list, size: 18),
                              const SizedBox(width: 8),
                              const Text('All Conversations'),
                            ],
                          ),
                          onTap: () => _showConversationList(context),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 18),
                              const SizedBox(width: 8),
                              const Text('Favorites'),
                            ],
                          ),
                          onTap: () => _showFavoriteConversations(context),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.delete_sweep, size: 18),
                              const SizedBox(width: 8),
                              const Text('Clear All'),
                            ],
                          ),
                          onTap: () => _clearAllConversations(context),
                        ),
                      ],
                    ),
                    const SizedBox(width: SpacingTokens.sm),

                    // Model selector with context menu
                    _ActionButtonWithMenu(
                      icon: Icons.psychology_outlined,
                      label: _isHovered ? 'Model' : null,
                      onTap: () => _showModelSelector(context),
                      isHovered: _isHovered,
                      menuItems: [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.computer, size: 18),
                              const SizedBox(width: 8),
                              const Text('Local Models'),
                            ],
                          ),
                          onTap: () => _showLocalModels(context),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.cloud, size: 18),
                              const SizedBox(width: 8),
                              const Text('API Models'),
                            ],
                          ),
                          onTap: () => _showAPIModels(context),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: 18),
                              const SizedBox(width: 8),
                              const Text('Add Model'),
                            ],
                          ),
                          onTap: () => _addNewModel(context),
                        ),
                      ],
                    ),
                    const SizedBox(width: SpacingTokens.sm),

                    // Artifacts with context menu
                    if (artifacts.isNotEmpty)
                      _ActionButtonWithMenu(
                        icon: Icons.widgets_outlined,
                        label: _isHovered ? 'Artifacts' : null,
                        onTap: () => _showArtifactsPanel(context, artifacts),
                        isHovered: _isHovered,
                        menuItems: [
                          ...artifacts.map((artifact) {
                            return PopupMenuItem(
                              child: Row(
                                children: [
                                  Text(artifact.type.icon, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      artifact.title,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _showArtifact(artifact.id),
                            );
                          }),
                          const PopupMenuDivider(),
                          // Only show "Show All" if any artifacts are hidden
                          if (artifacts.any((a) => !a.isVisible))
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  const Icon(Icons.visibility, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Show All'),
                                ],
                              ),
                              onTap: () => _showAllArtifacts(artifacts),
                            ),
                          // Only show "Hide All" if any artifacts are visible
                          if (artifacts.any((a) => a.isVisible))
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  const Icon(Icons.visibility_off, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Hide All'),
                                ],
                              ),
                              onTap: () => _hideAllArtifacts(artifacts),
                            ),
                        ],
                      ),
                    if (artifacts.isNotEmpty) const SizedBox(width: SpacingTokens.sm),

                    // Settings with context menu
                    _ActionButtonWithMenu(
                      icon: Icons.settings_outlined,
                      label: _isHovered ? 'Settings' : null,
                      onTap: () => _openSettings(context),
                      isHovered: _isHovered,
                      menuItems: [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.settings, size: 18),
                              const SizedBox(width: 8),
                              const Text('General Settings'),
                            ],
                          ),
                          onTap: () => _openSettings(context),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.palette, size: 18),
                              const SizedBox(width: 8),
                              const Text('Themes'),
                            ],
                          ),
                          onTap: () => _openThemeSettings(context),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.extension, size: 18),
                              const SizedBox(width: 8),
                              const Text('MCP Servers'),
                            ],
                          ),
                          onTap: () => _openMCPSettings(context),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Create a new conversation
  void _createNewConversation(BuildContext context) async {
    final conversationService = ref.read(conversationServiceProvider);
    final selectedModel = ref.read(selectedModelProvider);

    if (selectedModel == null) {
      debugPrint('⚠️ No model selected for new conversation');
      return;
    }

    try {
      final newConversation = core.Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Chat',
        messages: [],
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        metadata: {
          'model_id': selectedModel.id,
          'model_name': selectedModel.name,
          'model_type': selectedModel.isLocal ? 'local' : 'api',
          'type': 'direct',
        },
      );

      await conversationService.createConversation(newConversation);
      ref.invalidate(conversationsProvider);
      ref.read(selectedConversationIdProvider.notifier).state = newConversation.id;

      debugPrint('✅ Created new conversation: ${newConversation.id}');
    } catch (e) {
      debugPrint('❌ Failed to create conversation: $e');
    }
  }

  /// Show conversation list modal
  void _showConversationList(BuildContext context) {
    final colors = ThemeColors(context);
    final conversationsAsync = ref.read(conversationsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Recent Conversations',
          style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: conversationsAsync.when(
            data: (conversations) {
              if (conversations.isEmpty) {
                return Center(
                  child: Text(
                    'No conversations yet',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final isSelected = conversation.id == widget.conversationId;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: colors.primary.withValues(alpha: 0.1),
                    leading: Icon(
                      Icons.chat_bubble_outline,
                      color: isSelected ? colors.primary : colors.onSurfaceVariant,
                    ),
                    title: Text(
                      conversation.title,
                      style: TextStyles.bodyMedium.copyWith(
                        color: isSelected ? colors.primary : colors.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${conversation.messages.length} messages',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    onTap: () {
                      ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
                      Navigator.of(context).pop();
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Error loading conversations: $error',
                style: TextStyles.bodyMedium.copyWith(color: colors.error),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: colors.primary)),
          ),
        ],
      ),
    );
  }

  /// Show model selector modal
  void _showModelSelector(BuildContext context) {
    final colors = ThemeColors(context);
    final modelConfigService = ref.read(modelConfigServiceProvider);
    final allModels = modelConfigService.allModelConfigs.values
        .where((model) => model.isConfigured && model.status == ModelStatus.ready)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Select Model',
          style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: allModels.isEmpty
              ? Center(
                  child: Text(
                    'No models configured',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: allModels.length,
                  itemBuilder: (context, index) {
                    final model = allModels[index];
                    final isSelected = ref.read(selectedModelProvider)?.id == model.id;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: colors.primary.withValues(alpha: 0.1),
                      leading: Icon(
                        model.isLocal ? Icons.computer : Icons.cloud,
                        color: isSelected ? colors.primary : colors.onSurfaceVariant,
                      ),
                      title: Text(
                        model.name,
                        style: TextStyles.bodyMedium.copyWith(
                          color: isSelected ? colors.primary : colors.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        model.isLocal ? 'Local (Ollama)' : 'API',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {
                        ref.read(selectedModelProvider.notifier).state = model;
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: colors.primary)),
          ),
        ],
      ),
    );
  }

  /// Create new agent conversation
  void _createNewAgentConversation(BuildContext context) async {
    // Navigate to agents page to create agent
    context.go(AppRoutes.agents);
  }

  /// Create quick chat (minimal, fast model)
  void _createQuickChat(BuildContext context) async {
    final conversationService = ref.read(conversationServiceProvider);
    final quickChatService = ref.read(quickChatModelServiceProvider);

    final quickModel = quickChatService.getBestQuickChatModel();
    if (quickModel == null) {
      debugPrint('⚠️ No quick chat model available');
      return;
    }

    final modelConfig = ref.read(modelConfigServiceProvider).getModelConfig(quickModel);
    if (modelConfig == null) return;

    try {
      final newConversation = core.Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Quick Chat',
        messages: [],
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        metadata: {
          'model_id': modelConfig.id,
          'model_name': modelConfig.name,
          'type': 'quick_chat',
        },
      );

      await conversationService.createConversation(newConversation);
      ref.invalidate(conversationsProvider);
      ref.read(selectedConversationIdProvider.notifier).state = newConversation.id;
    } catch (e) {
      debugPrint('❌ Failed to create quick chat: $e');
    }
  }

  /// Show favorite conversations
  void _showFavoriteConversations(BuildContext context) {
    // TODO: Implement favorites filter
    _showConversationList(context);
  }

  /// Clear all conversations
  void _clearAllConversations(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Conversations'),
        content: const Text('Are you sure you want to delete all conversations? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement clear all
              debugPrint('Clear all conversations');
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Show only local models
  void _showLocalModels(BuildContext context) {
    final colors = ThemeColors(context);
    final modelConfigService = ref.read(modelConfigServiceProvider);
    final localModels = modelConfigService.allModelConfigs.values
        .where((model) => model.isLocal && model.isConfigured && model.status == ModelStatus.ready)
        .toList();

    _showModelListDialog(context, 'Local Models', localModels, Icons.computer);
  }

  /// Show only API models
  void _showAPIModels(BuildContext context) {
    final modelConfigService = ref.read(modelConfigServiceProvider);
    final apiModels = modelConfigService.allModelConfigs.values
        .where((model) => !model.isLocal && model.isConfigured && model.status == ModelStatus.ready)
        .toList();

    _showModelListDialog(context, 'API Models', apiModels, Icons.cloud);
  }

  /// Helper to show model list dialog
  void _showModelListDialog(BuildContext context, String title, List models, IconData icon) {
    final colors = ThemeColors(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(title, style: TextStyles.sectionTitle.copyWith(color: colors.onSurface)),
        content: SizedBox(
          width: 500,
          height: 400,
          child: models.isEmpty
              ? Center(child: Text('No models found', style: TextStyles.bodyMedium))
              : ListView.builder(
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final model = models[index];
                    final isSelected = ref.read(selectedModelProvider)?.id == model.id;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: colors.primary.withValues(alpha: 0.1),
                      leading: Icon(icon, color: isSelected ? colors.primary : colors.onSurfaceVariant),
                      title: Text(model.name),
                      onTap: () {
                        ref.read(selectedModelProvider.notifier).state = model;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: colors.primary)),
          ),
        ],
      ),
    );
  }

  /// Add new model
  void _addNewModel(BuildContext context) {
    context.go(AppRoutes.settings);
  }

  /// Open theme settings
  void _openThemeSettings(BuildContext context) {
    context.go(AppRoutes.settings);
  }

  /// Open MCP settings
  void _openMCPSettings(BuildContext context) {
    context.go(AppRoutes.settings);
  }

  /// Show artifacts panel
  void _showArtifactsPanel(BuildContext context, List<Artifact> artifacts) {
    // Panel is already visible in artifact workspace
    debugPrint('📦 Artifacts panel: ${artifacts.length} artifacts');
  }

  /// Show specific artifact by ID
  void _showArtifact(String artifactId) {
    ref.read(artifactProvider.notifier).showArtifact(artifactId);
    debugPrint('📦 Showing artifact: $artifactId');
  }

  /// Show all artifacts
  void _showAllArtifacts(List<Artifact> artifacts) {
    for (final artifact in artifacts) {
      ref.read(artifactProvider.notifier).showArtifact(artifact.id);
    }
    debugPrint('📦 Showing all ${artifacts.length} artifacts');
  }

  /// Hide all artifacts
  void _hideAllArtifacts(List<Artifact> artifacts) {
    for (final artifact in artifacts) {
      ref.read(artifactProvider.notifier).hideArtifact(artifact.id);
    }
    debugPrint('📦 Hiding all ${artifacts.length} artifacts');
  }

  /// Open settings page
  void _openSettings(BuildContext context) {
    context.go(AppRoutes.settings);
  }

  /// Get the agent's configured tools as a list
  List<String> _getAgentToolsList(Agent agent) {
    final tools = agent.configuration['selectedTools'] as List<dynamic>?;
    if (tools == null || tools.isEmpty) {
      return [];
    }
    return tools.map((t) => t.toString()).toList();
  }

  /// Get the agent's configured tools as a string for the details tooltip
  String _getAgentToolsDetails(Agent agent) {
    final tools = _getAgentToolsList(agent);
    if (tools.isEmpty) {
      return 'No tools configured';
    }
    final toolNames = tools.take(4).join(' • ');
    final suffix = tools.length > 4 ? ' +${tools.length - 4} more' : '';
    return '$toolNames$suffix';
  }

  /// Builds the model status indicator with real-time status from ModelConfig
  Widget _buildModelStatusIndicator(ThemeColors colors, ModelConfig? modelConfig) {
    // Determine status, color, and label
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (modelConfig == null) {
      statusColor = colors.error;
      statusLabel = _isHovered ? 'No Model' : '⚠';
      statusIcon = Icons.warning_rounded;
    } else {
      switch (modelConfig.status) {
        case ModelStatus.ready:
          statusColor = const Color(0xFF10B981); // Green
          statusLabel = '';
          statusIcon = Icons.check_circle;
        case ModelStatus.loading:
          statusColor = const Color(0xFFF59E0B); // Amber
          statusLabel = _isHovered ? 'Warming...' : '○';
          statusIcon = Icons.hourglass_bottom;
        case ModelStatus.downloading:
          statusColor = colors.primary;
          statusLabel = _isHovered ? 'Downloading...' : '⟳';
          statusIcon = Icons.downloading;
        case ModelStatus.needsSetup:
          statusColor = colors.error;
          statusLabel = _isHovered ? 'Setup Required' : '○';
          statusIcon = Icons.settings_suggest;
        case ModelStatus.error:
          statusColor = colors.error;
          statusLabel = _isHovered ? 'Error' : '✕';
          statusIcon = Icons.error_outline;
      }
    }

    // Hide indicator completely when model is ready
    if (modelConfig != null && modelConfig.status == ModelStatus.ready) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isHovered ? 1.0 : 0.6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: _isHovered ? 12 : 8,
            color: statusColor,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            statusLabel,
            style: GoogleFonts.fustat(
              fontSize: _isHovered ? 11 : 10,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button with context menu support
class _ActionButtonWithMenu extends StatefulWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isHovered;
  final List<PopupMenuEntry> menuItems;

  const _ActionButtonWithMenu({
    required this.icon,
    this.label,
    required this.onTap,
    required this.isHovered,
    required this.menuItems,
  });

  @override
  State<_ActionButtonWithMenu> createState() => _ActionButtonWithMenuState();
}

class _ActionButtonWithMenuState extends State<_ActionButtonWithMenu> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return PopupMenuButton(
      tooltip: '', // Remove "Show menu" tooltip
      itemBuilder: (context) => widget.menuItems,
      offset: const Offset(0, -10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: widget.label != null ? SpacingTokens.sm : SpacingTokens.xs,
              vertical: SpacingTokens.xs,
            ),
            decoration: BoxDecoration(
              color: _isPressed
                  ? colors.surface.withValues(alpha: 0.8)
                  : colors.surface.withValues(alpha: 0.0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: widget.isHovered ? 1.1 : 1.0,
                  child: Icon(
                    widget.icon,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (widget.label != null) ...[
                  const SizedBox(width: 4),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: widget.isHovered ? 1.0 : 0.0,
                    child: Text(
                      widget.label!,
                      style: GoogleFonts.fustat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status chip that shows conversation status (Quick Chat, MCP, Context)
class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isHovered;
  final AnimationController pulseController;
  final String? details;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isHovered,
    required this.pulseController,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: isHovered ? SpacingTokens.md : SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isHovered ? 8 : 6),
        border: Border.all(
          color: color.withValues(alpha: isHovered ? 0.4 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with subtle pulse animation
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = 1.0 + (pulseController.value * 0.05);
              return Transform.scale(
                scale: scale,
                child: Icon(
                  icon,
                  size: isHovered ? 16 : 14,
                  color: color,
                ),
              );
            },
          ),
          const SizedBox(width: 4),

          // Label with fade animation
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: 1.0,
            child: Text(
              details ?? label,
              style: GoogleFonts.fustat(
                fontSize: isHovered ? 13 : 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Agent tools chip with popup menu showing each tool with status
class _AgentToolsChip extends StatelessWidget {
  final Agent agent;
  final List<String> tools;
  final bool isHovered;
  final AnimationController pulseController;

  const _AgentToolsChip({
    required this.agent,
    required this.tools,
    required this.isHovered,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final toolCount = tools.length;
    final label = toolCount == 0
        ? agent.name
        : '$toolCount ${toolCount == 1 ? 'tool' : 'tools'}';

    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, -10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      ),
      color: colors.surface,
      itemBuilder: (context) => [
        // Header with agent name
        PopupMenuItem<String>(
          enabled: false,
          height: 36,
          child: Row(
            children: [
              Icon(Icons.smart_toy, size: 16, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                agent.name,
                style: GoogleFonts.fustat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Tools list with status indicators
        if (tools.isEmpty)
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'No tools configured',
                  style: GoogleFonts.fustat(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...tools.map((tool) => PopupMenuItem<String>(
            value: tool,
            child: Row(
              children: [
                Icon(
                  _getToolIcon(tool),
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tool,
                    style: GoogleFonts.fustat(
                      fontSize: 12,
                      color: colors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isHovered ? SpacingTokens.md : SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isHovered ? 8 : 6),
          border: Border.all(
            color: colors.primary.withValues(alpha: isHovered ? 0.4 : 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with subtle pulse animation
            AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) {
                final scale = 1.0 + (pulseController.value * 0.05);
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.construction,
                    size: isHovered ? 16 : 14,
                    color: colors.primary,
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            // Label
            Text(
              label,
              style: GoogleFonts.fustat(
                fontSize: isHovered ? 13 : 11,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getToolIcon(String tool) {
    final lower = tool.toLowerCase();
    if (lower.contains('github')) return Icons.code;
    if (lower.contains('git')) return Icons.merge_type;
    if (lower.contains('figma')) return Icons.draw;
    if (lower.contains('canvas')) return Icons.brush;
    if (lower.contains('memory')) return Icons.memory;
    if (lower.contains('filesystem') || lower.contains('file')) return Icons.folder;
    if (lower.contains('search') || lower.contains('brave')) return Icons.search;
    if (lower.contains('web') || lower.contains('fetch')) return Icons.language;
    if (lower.contains('slack')) return Icons.chat;
    if (lower.contains('notion')) return Icons.note;
    if (lower.contains('postgres') || lower.contains('mysql') || lower.contains('db')) return Icons.storage;
    if (lower.contains('docker')) return Icons.inventory_2;
    if (lower.contains('aws') || lower.contains('cloud')) return Icons.cloud;
    if (lower.contains('python') || lower.contains('jupyter')) return Icons.terminal;
    return Icons.extension;
  }
}

/// Action button for quick actions (search, settings, export)
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isHovered;

  const _ActionButton({
    required this.icon,
    this.label,
    required this.onTap,
    required this.isHovered,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.label != null ? SpacingTokens.sm : SpacingTokens.xs,
            vertical: SpacingTokens.xs,
          ),
          decoration: BoxDecoration(
            color: _isPressed
                ? colors.surface.withValues(alpha: 0.8)
                : colors.surface.withValues(alpha: 0.0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 150),
                scale: widget.isHovered ? 1.1 : 1.0,
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (widget.label != null) ...[
                const SizedBox(width: 4),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.isHovered ? 1.0 : 0.0,
                  child: Text(
                    widget.label!,
                    style: GoogleFonts.fustat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
