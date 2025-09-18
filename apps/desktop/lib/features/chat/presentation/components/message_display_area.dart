import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart' as core;
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';
import '../widgets/streaming_message_widget.dart';
import '../widgets/rich_text_message_widget.dart';

/// Message display area - service-driven, design system compliant
class MessageDisplayArea extends ConsumerWidget {
  final String? conversationId;

  const MessageDisplayArea({
    super.key,
    this.conversationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (conversationId == null) {
      return _buildEmptyState(context);
    }

    // Watch real messages from service
    final messagesAsync = ref.watch(messagesProvider(conversationId!));

    return messagesAsync.when(
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, error),
      data: (messages) {
        if (messages.isEmpty) {
          return _buildEmptyState(context);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.lg),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildMessageCard(context, message);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: ThemeColors(context).onSurfaceVariant,
          ),
          const SizedBox(height: SpacingTokens.xl),
          Text(
            'Start a conversation',
            style: TextStyles.pageTitle.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Type a message below to begin chatting with your AI model',
            style: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ThemeColors(context).primary,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Loading conversation...',
            style: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: SpacingTokens.xl),
          Text(
            'Failed to load conversation',
            style: TextStyles.pageTitle.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            error.toString(),
            style: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, core.Message message) {
    final isUser = message.role == core.MessageRole.user;
    
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ThemeColors(context).primary,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: Icon(
                Icons.smart_toy,
                color: ThemeColors(context).onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: SpacingTokens.md),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                // Message content
                AsmblCard(
                  child: Container(
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: _buildMessageContent(context, message),
                  ),
                ),
                
                // Message timestamp and metadata
                const SizedBox(height: SpacingTokens.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                      ),
                    ),
                    
                    // Show model used for AI responses
                    if (!isUser && message.metadata?['modelUsed'] != null) ...[
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        '• ${message.metadata!['modelUsed']}',
                        style: TextStyles.bodySmall.copyWith(
                          color: ThemeColors(context).onSurfaceVariant,
                        ),
                      ),
                    ],
                    
                    // Show MCP/context indicators
                    if (!isUser) ...[
                      if (message.metadata?['mcpServersUsed'] != null) ...[
                        const SizedBox(width: SpacingTokens.xs),
                        Icon(
                          Icons.extension,
                          size: 12,
                          color: ThemeColors(context).primary,
                        ),
                      ],
                      if (message.metadata?['hasGlobalContext'] == true) ...[
                        const SizedBox(width: SpacingTokens.xs),
                        Icon(
                          Icons.description,
                          size: 12,
                          color: ThemeColors(context).accent,
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: SpacingTokens.md),
            // User avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ThemeColors(context).surface,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(
                  color: ThemeColors(context).border,
                ),
              ),
              child: Icon(
                Icons.person,
                color: ThemeColors(context).onSurface,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, core.Message message) {
    final isStreaming = message.metadata?['streaming'] == true;
    final isUser = message.role == core.MessageRole.user;
    
    print('DEBUG: Message - Role: ${message.role.name}, IsUser: $isUser, IsStreaming: $isStreaming, ContentLength: ${message.content.length}');
    print('DEBUG: Role check - Is Assistant: ${message.role == core.MessageRole.assistant}');
    print('DEBUG: Message metadata: ${message.metadata}');
    
    if (isStreaming) {
      print('DEBUG: Using StreamingMessageWidget');
      // Use existing streaming widget for real-time updates
      return StreamingMessageWidget(
        messageId: message.id,
        role: message.role.name,
      );
    }

    // Use rich text widget for AI responses, plain text for user messages
    if (message.role == core.MessageRole.assistant && message.content.isNotEmpty) {
      print('DEBUG: Using RichTextMessageWidget for assistant message: ${message.content.substring(0, message.content.length > 50 ? 50 : message.content.length)}...');
      return RichTextMessageWidget(
        content: message.content,
        isStreaming: isStreaming,
        isDarkTheme: Theme.of(context).brightness == Brightness.dark,
      );
    }

    print('DEBUG: Using fallback SelectableText');
    // Fallback for user messages or empty content
    return SelectableText(
      message.content,
      style: TextStyles.bodyMedium.copyWith(
        color: ThemeColors(context).onSurface,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}