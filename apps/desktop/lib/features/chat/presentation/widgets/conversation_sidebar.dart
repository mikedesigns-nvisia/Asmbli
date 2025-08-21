import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import 'conversation_list.dart';
import 'conversation_archive_modal.dart';

class ConversationSidebar extends ConsumerStatefulWidget {
  const ConversationSidebar({super.key});

  @override
  ConsumerState<ConversationSidebar> createState() => _ConversationSidebarState();
}

class _ConversationSidebarState extends ConsumerState<ConversationSidebar> {
  bool isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Collapse/expand toggle when collapsed
        if (isCollapsed)
          Container(
            width: 48,
            decoration: BoxDecoration(
              color: SemanticColors.surface.withOpacity(0.7),
              border: Border(
                left: BorderSide(color: SemanticColors.border.withOpacity(0.3)),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: SpacingTokens.lg),
                IconButton(
                  onPressed: () => setState(() => isCollapsed = false),
                  icon: const Icon(Icons.chevron_left, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: SemanticColors.surface.withOpacity(0.8),
                    foregroundColor: SemanticColors.onSurfaceVariant,
                    side: BorderSide(color: SemanticColors.border.withOpacity(0.5)),
                  ),
                  tooltip: 'Show Conversations',
                ),
              ],
            ),
          ),

        // Main sidebar content
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCollapsed ? 0 : 320,
          child: isCollapsed ? null : _buildSidebarContent(),
        ),
      ],
    );
  }

  Widget _buildSidebarContent() {
    return Container(
      decoration: BoxDecoration(
        color: SemanticColors.surface.withOpacity(0.7),
        border: Border(
          left: BorderSide(color: SemanticColors.border.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Row(
              children: [
                Text(
                  'Conversations',
                  style: TextStyles.bodyMedium.copyWith(
                    color: SemanticColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => isCollapsed = true),
                  icon: const Icon(Icons.chevron_right, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: SemanticColors.onSurfaceVariant,
                  ),
                  tooltip: 'Hide Conversations',
                ),
              ],
            ),
          ),
          
          // Conversation List
          const Expanded(
            child: ConversationList(),
          ),
          
          // Footer with additional actions
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: SemanticColors.border.withOpacity(0.3)),
              ),
            ),
            child: Column(
              children: [
                // Archive conversations button
                AsmblButton.secondary(
                  text: 'View Archived',
                  icon: Icons.archive_outlined,
                  onPressed: () => _showArchiveModal(context),
                  isFullWidth: true,
                ),
                const SizedBox(height: SpacingTokens.sm),
                
                // Export conversations button
                AsmblButton.secondary(
                  text: 'Export Conversations',
                  icon: Icons.download_outlined,
                  onPressed: () {
                    // TODO: Implement export functionality
                  },
                  isFullWidth: true,
                ),
              ],
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
}