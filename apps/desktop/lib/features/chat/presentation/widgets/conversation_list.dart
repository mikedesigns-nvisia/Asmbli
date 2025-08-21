import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';
import 'loading_overlay.dart';

class ConversationList extends ConsumerWidget {
  const ConversationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final selectedConversationId = ref.watch(selectedConversationIdProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Conversations',
                style: TextStyles.sectionTitle.copyWith(
                  color: SemanticColors.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _createNewConversation(ref),
                icon: const Icon(Icons.add, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: SemanticColors.primary.withOpacity(0.1),
                  foregroundColor: SemanticColors.primary,
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                ),
                tooltip: 'New Conversation',
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                if (conversations.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final isSelected = conversation.id == selectedConversationId;
                    
                    return _ConversationItem(
                      conversation: conversation,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
                      },
                    );
                  },
                );
              },
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString(), ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: SemanticColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'No conversations yet',
            style: TextStyles.bodyMedium.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Create your first conversation to get started',
            style: TextStyles.bodySmall.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: SemanticColors.primary,
            strokeWidth: 2,
          ),
          SizedBox(height: SpacingTokens.lg),
          Text(
            'Loading conversations...',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: ErrorMessage(
        message: 'Failed to load conversations: $error',
        onRetry: () {
          ref.invalidate(conversationsProvider);
        },
      ),
    );
  }

  void _createNewConversation(WidgetRef ref) async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;
      
      final createConversation = ref.read(createConversationProvider);
      final conversation = await createConversation(
        title: 'New Conversation - ${DateTime.now().toString().substring(0, 16)}',
      );
      
      ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
      ref.invalidate(conversationsProvider);
    } catch (e) {
      // Handle error
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }
}

class _ConversationItem extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConversationItem({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          hoverColor: SemanticColors.primary.withOpacity(0.04),
          splashColor: SemanticColors.primary.withOpacity(0.12),
          child: Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              border: isSelected 
                  ? Border.all(color: SemanticColors.primary, width: 2)
                  : Border.all(color: SemanticColors.border),
              color: isSelected 
                  ? SemanticColors.primary.withOpacity(0.05)
                  : SemanticColors.surface.withOpacity(0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.title,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? SemanticColors.primary
                        : SemanticColors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: SpacingTokens.xs),
                Row(
                  children: [
                    Icon(
                      Icons.message,
                      size: 12,
                      color: SemanticColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Text(
                      '${conversation.messages.length} messages',
                      style: TextStyles.caption.copyWith(
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(conversation.createdAt),
                      style: TextStyles.caption.copyWith(
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}