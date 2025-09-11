import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../widgets/contextual_context_widget.dart';

/// Demo screen showcasing the contextual context feature
class ContextualContextDemo extends ConsumerStatefulWidget {
  const ContextualContextDemo({super.key});

  @override
  ConsumerState<ContextualContextDemo> createState() => _ContextualContextDemoState();
}

class _ContextualContextDemoState extends ConsumerState<ContextualContextDemo> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contextual Context Demo',
          style: TextStyles.pageTitle.copyWith(
            color: ThemeColors(context).onSurface,
          ),
        ),
        backgroundColor: ThemeColors(context).surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ThemeColors(context).onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ThemeColors(context).backgroundGradientStart,
              ThemeColors(context).backgroundGradientMiddle,
              ThemeColors(context).backgroundGradientEnd,
            ],
          ),
        ),
        child: Column(
          children: [
            // Demo Information
            Container(
              margin: const EdgeInsets.all(SpacingTokens.lg),
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: ThemeColors(context).surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                border: Border.all(color: ThemeColors(context).border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 Contextual Context Feature',
                    style: TextStyles.pageTitle.copyWith(
                      color: ThemeColors(context).primary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    'This demo shows the new "contextual context" UX pattern that replaces the complex left sidebar with a cleaner, conversation-first approach.',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ThemeColors(context).onSurface,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  _buildFeatureList(),
                ],
              ),
            ),
            
            // Demo Messages Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
                padding: const EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: ThemeColors(context).surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  border: Border.all(color: ThemeColors(context).border),
                ),
                child: _buildDemoMessages(),
              ),
            ),
            
            // Contextual Input Area Demo
            ContextualInputArea(
              messageController: _messageController,
              onSendMessage: _handleSendMessage,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      '📎 Context prompt appears when no context is added',
      '🔄 Smart "Add context" vs "Just chat" options',
      '📁 Unified file upload, text input, and document browser',
      '📊 Context indicator shows added documents',
      '✨ Clean, conversation-first interface',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Features:',
          style: TextStyles.bodyMedium.copyWith(
            color: ThemeColors(context).onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            feature,
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildDemoMessages() {
    return Column(
      children: [
        Text(
          '💬 Demo Chat Area',
          style: TextStyles.bodyLarge.copyWith(
            color: ThemeColors(context).onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        
        // Sample messages
        _buildDemoMessage(
          isUser: false,
          text: 'Hello! I\'m ready to help. Notice how the context prompt appears below - you can add documents before we start chatting, or just begin our conversation.',
        ),
        
        _buildDemoMessage(
          isUser: true,
          text: 'This is much cleaner than having all the controls in a sidebar!',
        ),
        
        _buildDemoMessage(
          isUser: false,
          text: 'Exactly! The contextual approach means you only see complexity when you need it. Try clicking "Add context" below to see the unified upload flow.',
        ),
      ],
    );
  }

  Widget _buildDemoMessage({required bool isUser, required String text}) {
    return Container(
      margin: EdgeInsets.only(
        bottom: SpacingTokens.md,
        left: isUser ? SpacingTokens.xxl : 0,
        right: isUser ? 0 : SpacingTokens.xxl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: ThemeColors(context).primary,
              child: Icon(
                Icons.smart_toy,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: isUser 
                  ? ThemeColors(context).primary.withValues(alpha: 0.1)
                  : ThemeColors(context).surface,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: isUser 
                  ? Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3))
                  : Border.all(color: ThemeColors(context).border),
              ),
              child: Text(
                text,
                style: TextStyles.bodyMedium.copyWith(
                  color: isUser 
                    ? ThemeColors(context).primary
                    : ThemeColors(context).onSurface,
                ),
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: SpacingTokens.sm),
            CircleAvatar(
              radius: 16,
              backgroundColor: ThemeColors(context).primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 20,
                color: ThemeColors(context).primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleSendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate message sending
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _messageController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent: "${_messageController.text}"'),
            backgroundColor: ThemeColors(context).primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
}