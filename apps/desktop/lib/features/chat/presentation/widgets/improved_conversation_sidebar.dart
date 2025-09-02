import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';
import 'conversation_list.dart';
import 'conversation_archive_modal.dart';
import 'topic_management_section.dart';

class ImprovedConversationSidebar extends ConsumerStatefulWidget {
  const ImprovedConversationSidebar({super.key});

  @override
  ConsumerState<ImprovedConversationSidebar> createState() => _ImprovedConversationSidebarState();
}

class _ImprovedConversationSidebarState extends ConsumerState<ImprovedConversationSidebar> {
  bool isCollapsed = false;
  bool _showTopicsSection = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Collapse/expand toggle when collapsed
        if (isCollapsed)
          Container(
            width: 48,
            decoration: BoxDecoration(
              color: ThemeColors(context).surface.withValues(alpha: 0.7),
              border: Border(
                left: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.3)),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: SpacingTokens.elementSpacing),
                IconButton(
                  onPressed: () => setState(() => isCollapsed = false),
                  icon: Icon(Icons.chevron_left, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: ThemeColors(context).surface.withValues(alpha: 0.8),
                    foregroundColor: ThemeColors(context).onSurfaceVariant,
                    side: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.5)),
                  ),
                  tooltip: 'Show Conversations',
                ),
              ],
            ),
          ),

        // Main sidebar content
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: isCollapsed ? 0 : 320,
          child: isCollapsed ? null : _buildSidebarContent(),
        ),
      ],
    );
  }

  Widget _buildSidebarContent() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withValues(alpha: 0.7),
        border: Border(
          left: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with hierarchical layout
          Container(
            padding: EdgeInsets.all(SpacingTokens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and collapse button row
                Row(
                  children: [
                    Text(
                      'Conversations',
                      style: TextStyles.bodyMedium.copyWith(
                        color: ThemeColors(context).onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => setState(() => isCollapsed = true),
                      icon: Icon(Icons.chevron_right, size: 20),
                      style: IconButton.styleFrom(
                        foregroundColor: ThemeColors(context).onSurfaceVariant,
                      ),
                      tooltip: 'Hide Conversations',
                    ),
                  ],
                ),
                SizedBox(height: SpacingTokens.iconSpacing),
                // New Chat Button on its own row
                AsmblButton.primary(
                  text: 'New Chat',
                  icon: Icons.add,
                  onPressed: _startNewChat,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
          
          // Optional Topics Organization
          Container(
            padding: EdgeInsets.symmetric(horizontal: SpacingTokens.cardPadding, vertical: SpacingTokens.sm),
            decoration: BoxDecoration(
              color: _showTopicsSection 
                ? ThemeColors(context).primary.withValues(alpha: 0.05)
                : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.3)),
              ),
            ),
            child: InkWell(
              onTap: () => setState(() => _showTopicsSection = !_showTopicsSection),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: SpacingTokens.xs),
                child: Row(
                  children: [
                    Icon(
                      _showTopicsSection ? Icons.folder_open : Icons.folder_outlined,
                      size: 16,
                      color: _showTopicsSection 
                        ? ThemeColors(context).primary 
                        : ThemeColors(context).onSurfaceVariant,
                    ),
                    SizedBox(width: SpacingTokens.iconSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showTopicsSection ? 'Organized by Topics' : 'Organize with Topics',
                            style: TextStyles.bodySmall.copyWith(
                              color: _showTopicsSection 
                                ? ThemeColors(context).primary 
                                : ThemeColors(context).onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!_showTopicsSection)
                            Text(
                              'Group conversations into topics',
                              style: TextStyles.caption.copyWith(
                                color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _showTopicsSection ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: _showTopicsSection 
                        ? ThemeColors(context).primary 
                        : ThemeColors(context).onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content based on mode
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _showTopicsSection 
                ? TopicManagementSection(key: ValueKey('topics'))
                : ConversationList(key: ValueKey('conversations')),
            ),
          ),
          
          // Footer with secondary actions
          Container(
            padding: EdgeInsets.all(SpacingTokens.cardPadding),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.3)),
              ),
            ),
            child: Column(
              children: [
                // Quick actions row
                Row(
                  children: [
                    Expanded(
                      child: AsmblButton.secondary(
                        text: 'Archived',
                        icon: Icons.archive_outlined,
                        onPressed: () => _showArchiveModal(context),
                      ),
                    ),
                    SizedBox(width: SpacingTokens.componentSpacing),
                    Expanded(
                      child: AsmblButton.secondary(
                        text: 'Export',
                        icon: Icons.download_outlined,
                        onPressed: () => _showExportDialog(context),
                      ),
                    ),
                  ],
                ),
                
                // Stats or tips
                if (!_showTopicsSection) ...[
                  SizedBox(height: SpacingTokens.componentSpacing),
                  _buildQuickTips(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTips() {
    final conversationsAsync = ref.watch(conversationsProvider);
    final conversationCount = conversationsAsync.valueOrNull?.length ?? 0;
    
    return Container(
      padding: EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ThemeColors(context).border.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 14,
            color: ThemeColors(context).onSurfaceVariant,
          ),
          SizedBox(width: SpacingTokens.iconSpacing),
          Expanded(
            child: Text(
              conversationCount > 5 
                ? 'Try organizing with topics for easier navigation'
                : 'Start conversations directly or organize them later',
              style: TextStyles.caption.copyWith(
                color: ThemeColors(context).onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showArchiveModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ConversationArchiveModal(),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: ThemeColors(context).primary),
            SizedBox(width: 8),
            Text('Export Conversations'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export your conversations as:'),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.description),
              title: Text('Markdown Files'),
              subtitle: Text('Individual .md files for each conversation'),
              onTap: () {
                Navigator.pop(context);
                _exportAsMarkdown();
              },
            ),
            ListTile(
              leading: Icon(Icons.data_object),
              title: Text('JSON Archive'),
              subtitle: Text('Complete data export with metadata'),
              onTap: () {
                Navigator.pop(context);
                _exportAsJson();
              },
            ),
          ],
        ),
        actions: [
          AsmblButton.secondary(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _exportAsMarkdown() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Markdown export coming soon'),
        backgroundColor: ThemeColors(context).primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportAsJson() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('JSON export coming soon'),
        backgroundColor: ThemeColors(context).primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startNewChat() async {
    try {
      // Create a new conversation
      final createConversation = ref.read(createConversationProvider);
      final conversation = await createConversation(title: 'New Chat');
      
      // Set as selected conversation
      ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
      
      // Refresh conversations list
      ref.invalidate(conversationsProvider);
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.chat_bubble, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('New conversation started'),
            ],
          ),
          backgroundColor: ThemeColors(context).success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create new chat: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }
}