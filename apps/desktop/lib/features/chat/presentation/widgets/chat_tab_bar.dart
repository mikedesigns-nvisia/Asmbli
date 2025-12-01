import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agent_engine_core/models/conversation.dart' as core;
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';

/// Firefox-style browser tab bar for chat conversations
///
/// Features:
/// - Horizontal scrollable tabs
/// - Close button on each tab
/// - New tab button (+)
/// - Tab overflow menu for many tabs
/// - Visual indicator for active tab
class ChatTabBar extends ConsumerStatefulWidget {
  final Function()? onNewChat;

  const ChatTabBar({
    super.key,
    this.onNewChat,
  });

  @override
  ConsumerState<ChatTabBar> createState() => _ChatTabBarState();
}

class _ChatTabBarState extends ConsumerState<ChatTabBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final openTabs = ref.watch(openConversationTabsProvider);
    final activeTabId = ref.watch(activeConversationTabProvider);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Scrollable tab area
          Expanded(
            child: openTabs.isEmpty
                ? _buildEmptyTabArea(colors)
                : _buildTabScrollView(colors, openTabs, activeTabId),
          ),

          // Divider
          Container(
            width: 1,
            height: 24,
            color: colors.border.withValues(alpha: 0.3),
          ),

          // New tab button
          _buildNewTabButton(colors),

          const SizedBox(width: SpacingTokens.xs),

          // Tab list menu (for overflow)
          if (openTabs.length > 3)
            _buildTabListMenu(colors, openTabs, activeTabId),
        ],
      ),
    );
  }

  Widget _buildEmptyTabArea(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 14,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            'No conversations open',
            style: GoogleFonts.fustat(
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabScrollView(
    ThemeColors colors,
    List<String> openTabs,
    String? activeTabId,
  ) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: SpacingTokens.xs),
            ...openTabs.map((tabId) => _ChatTab(
              conversationId: tabId,
              isActive: tabId == activeTabId,
              onTap: () => _selectTab(tabId),
              onClose: () => _closeTab(tabId),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTabButton(ThemeColors colors) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _createNewTab,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            Icons.add,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTabListMenu(
    ThemeColors colors,
    List<String> openTabs,
    String? activeTabId,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.keyboard_arrow_down,
        size: 18,
        color: colors.onSurfaceVariant,
      ),
      tooltip: 'All tabs',
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      ),
      color: colors.surface,
      itemBuilder: (context) => openTabs.map((tabId) {
        final isActive = tabId == activeTabId;
        return PopupMenuItem<String>(
          value: tabId,
          child: Consumer(
            builder: (context, ref, _) {
              final conversationAsync = ref.watch(conversationProvider(tabId));
              return conversationAsync.when(
                data: (conversation) => Row(
                  children: [
                    Icon(
                      _getTabIcon(conversation),
                      size: 16,
                      color: isActive ? colors.primary : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    Expanded(
                      child: Text(
                        conversation.title,
                        style: GoogleFonts.fustat(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive ? colors.primary : colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                loading: () => Text('Loading...', style: TextStyles.bodySmall),
                error: (_, __) => Text('Error', style: TextStyles.bodySmall),
              );
            },
          ),
        );
      }).toList(),
      onSelected: (tabId) => _selectTab(tabId),
    );
  }

  void _selectTab(String tabId) {
    ref.read(activeConversationTabProvider.notifier).state = tabId;
    ref.read(selectedConversationIdProvider.notifier).state = tabId;
  }

  void _closeTab(String tabId) {
    final notifier = ref.read(openConversationTabsProvider.notifier);
    final openTabs = ref.read(openConversationTabsProvider);
    final activeTab = ref.read(activeConversationTabProvider);

    // Remove the tab
    notifier.closeTab(tabId);

    // If we closed the active tab, select another one
    if (activeTab == tabId) {
      final remainingTabs = openTabs.where((id) => id != tabId).toList();
      if (remainingTabs.isNotEmpty) {
        // Select the previous tab or the first one
        final closedIndex = openTabs.indexOf(tabId);
        final newIndex = closedIndex > 0 ? closedIndex - 1 : 0;
        final newActiveId = remainingTabs[newIndex.clamp(0, remainingTabs.length - 1)];
        ref.read(activeConversationTabProvider.notifier).state = newActiveId;
        ref.read(selectedConversationIdProvider.notifier).state = newActiveId;
      } else {
        ref.read(activeConversationTabProvider.notifier).state = null;
        ref.read(selectedConversationIdProvider.notifier).state = null;
      }
    }
  }

  void _createNewTab() async {
    if (widget.onNewChat != null) {
      widget.onNewChat!();
    } else {
      // Default behavior: create new conversation
      final createConversation = ref.read(getOrCreateDefaultConversationProvider);
      try {
        final conversation = await createConversation();
        final notifier = ref.read(openConversationTabsProvider.notifier);
        notifier.openTab(conversation.id);
        ref.read(activeConversationTabProvider.notifier).state = conversation.id;
        ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
      } catch (e) {
        debugPrint('Failed to create new tab: $e');
      }
    }
  }

  IconData _getTabIcon(core.Conversation conversation) {
    final type = conversation.metadata?['type'] as String?;
    switch (type) {
      case 'quickChat':
        return Icons.bolt;
      case 'deepReasoning':
        return Icons.psychology;
      case 'codeAssistant':
        return Icons.code;
      case 'visionAnalysis':
        return Icons.visibility;
      case 'agent':
        return Icons.smart_toy;
      default:
        return Icons.chat_bubble_outline;
    }
  }
}

/// Individual tab widget
class _ChatTab extends ConsumerStatefulWidget {
  final String conversationId;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _ChatTab({
    required this.conversationId,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final conversationAsync = ref.watch(conversationProvider(widget.conversationId));

    return conversationAsync.when(
      data: (conversation) => _buildTab(colors, conversation),
      loading: () => _buildLoadingTab(colors),
      error: (_, __) => _buildErrorTab(colors),
    );
  }

  Widget _buildTab(ThemeColors colors, core.Conversation conversation) {
    final type = conversation.metadata?['type'] as String?;
    final modelName = conversation.metadata?['modelName'] as String?;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(
            minWidth: 120,
            maxWidth: 220,
          ),
          margin: const EdgeInsets.only(right: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? colors.surface
                : (_isHovered ? colors.surface.withValues(alpha: 0.5) : Colors.transparent),
            // Note: Can't use borderRadius with non-uniform border colors
            // So we use a simple top border indicator instead
            border: widget.isActive
                ? Border(
                    top: BorderSide(color: colors.primary, width: 2),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tab icon based on conversation type
              Icon(
                _getIconForType(type),
                size: 14,
                color: widget.isActive ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: SpacingTokens.xs),

              // Tab title with model name
              Flexible(
                child: Text(
                  modelName != null ? 'Chat with $modelName' : conversation.title,
                  style: GoogleFonts.fustat(
                    fontSize: 12,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                    color: widget.isActive ? colors.onSurface : colors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),

              // Close button (shown on hover or when active)
              if (_isHovered || widget.isActive) ...[
                const SizedBox(width: SpacingTokens.xs),
                _CloseTabButton(
                  onClose: widget.onClose,
                  isActive: widget.isActive,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Get icon for conversation type
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'quickChat':
        return Icons.bolt;
      case 'deepReasoning':
        return Icons.psychology;
      case 'codeAssistant':
        return Icons.code;
      case 'visionAnalysis':
        return Icons.visibility;
      case 'agent':
        return Icons.smart_toy;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  Widget _buildLoadingTab(ThemeColors colors) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 2),
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            'Loading...',
            style: GoogleFonts.fustat(
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTab(ThemeColors colors) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 2),
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: colors.error),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            'Error',
            style: GoogleFonts.fustat(
              fontSize: 12,
              color: colors.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Close button for tabs
class _CloseTabButton extends StatefulWidget {
  final VoidCallback onClose;
  final bool isActive;

  const _CloseTabButton({
    required this.onClose,
    required this.isActive,
  });

  @override
  State<_CloseTabButton> createState() => _CloseTabButtonState();
}

class _CloseTabButtonState extends State<_CloseTabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onClose,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: _isHovered
                ? colors.error.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.close,
            size: 12,
            color: _isHovered ? colors.error : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
