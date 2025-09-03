import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';
import '../widgets/improved_conversation_sidebar.dart';
import '../widgets/context_sidebar_section.dart';
import '../components/service_driven_model_selector.dart';
import '../components/mcp_status_indicator.dart';
import '../components/context_status_indicator.dart';
import '../components/conversation_input.dart';
import '../components/message_display_area.dart';

/// Modern chat screen - 100% service-driven, design system compliant
class ModernChatScreenV2 extends ConsumerStatefulWidget {
  const ModernChatScreenV2({super.key});

  @override
  ConsumerState<ModernChatScreenV2> createState() => _ModernChatScreenV2State();
}

class _ModernChatScreenV2State extends ConsumerState<ModernChatScreenV2> {
  final TextEditingController messageController = TextEditingController();
  bool isLeftSidebarCollapsed = false;
  bool isRightSidebarCollapsed = false;
  bool _isSendingMessage = false; // Prevent double-sending

  @override
  void initState() {
    super.initState();
    _ensureDefaultConversation();
  }

  Future<void> _ensureDefaultConversation() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return; // Check if widget is still mounted
      
      final currentSelection = ref.read(selectedConversationIdProvider);
      if (currentSelection == null) {
        // Create a clean conversation without hardcoded defaults
        final createConversation = ref.read(createConversationProvider);
        try {
          final conversation = await createConversation(
            title: 'New Chat',
            metadata: {'type': 'user_created'}, // No default_api type
          );
          
          // Always check mounted state after async operations
          if (!mounted) return;
          
          ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
        } catch (e) {
          // Handle creation errors gracefully
          if (mounted) {
            print('Failed to create default conversation: $e');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              ThemeColors(context).backgroundGradientStart,
              ThemeColors(context).backgroundGradientMiddle,
              ThemeColors(context).backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Left Sidebar - AI Control Panel
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isLeftSidebarCollapsed ? 60 : 280,
                child: _buildLeftSidebar(),
              ),
              
              // Main Chat Area
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: MessageDisplayArea(
                        conversationId: ref.watch(selectedConversationIdProvider),
                      ),
                    ),
                    ConversationInput(
                      controller: messageController,
                      onSubmit: _handleSubmit,
                    ),
                  ],
                ),
              ),
              
              // Right Sidebar - Conversations
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isRightSidebarCollapsed ? 60 : 320,
                child: _buildRightSidebar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.headerPadding),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: ThemeColors(context).border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // App Title
          Text(
            'Asmbli',
            style: TextStyles.brandTitle.copyWith(
              color: ThemeColors(context).primary,
            ),
          ),
          
          const Spacer(),
          
          // Service-driven model selector
          const ServiceDrivenModelSelector(),
          
          const SizedBox(width: SpacingTokens.lg),
          
          // Real MCP status from service
          const MCPStatusIndicator(),
          
          const SizedBox(width: SpacingTokens.lg),
          
          // Real context status from service
          const ContextStatusIndicator(),
          
          const SizedBox(width: SpacingTokens.lg),
          
          // Sidebar toggle buttons
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => isLeftSidebarCollapsed = !isLeftSidebarCollapsed),
                icon: Icon(
                  isLeftSidebarCollapsed ? Icons.menu_open : Icons.menu,
                  color: ThemeColors(context).onSurface,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => isRightSidebarCollapsed = !isRightSidebarCollapsed),
                icon: Icon(
                  isRightSidebarCollapsed ? Icons.chat_bubble_outline : Icons.chat_bubble,
                  color: ThemeColors(context).onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isLeftSidebarCollapsed) ...[
              Text(
                'AI Control Panel',
                style: TextStyles.pageTitle.copyWith(
                  color: ThemeColors(context).onSurface,
                ),
              ),
              const SizedBox(height: SpacingTokens.xxl),
              
              // Context sidebar section (service-driven)
              const Expanded(
                child: ContextSidebarSection(),
              ),
            ] else ...[
              // Collapsed state - show icons only
              Column(
                children: [
                  Icon(
                    Icons.smart_toy,
                    color: ThemeColors(context).primary,
                    size: 32,
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  Icon(
                    Icons.folder,
                    color: ThemeColors(context).onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRightSidebar() {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isRightSidebarCollapsed) ...[
              Text(
                'Conversations',
                style: TextStyles.pageTitle.copyWith(
                  color: ThemeColors(context).onSurface,
                ),
              ),
              const SizedBox(height: SpacingTokens.xxl),
              
              // Service-driven conversation sidebar
              const Expanded(
                child: ImprovedConversationSidebar(),
              ),
            ] else ...[
              // Collapsed state - show chat icon
              Icon(
                Icons.chat,
                color: ThemeColors(context).primary,
                size: 32,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit(String message) async {
    if (!mounted) return; // Check mounted state before starting
    
    // Prevent race conditions - don't allow multiple sends at once
    if (_isSendingMessage) {
      print('⚠️ Message send already in progress, ignoring duplicate request');
      return;
    }
    
    final selectedConversationId = ref.read(selectedConversationIdProvider);
    if (selectedConversationId == null || message.trim().isEmpty) return;

    // Set sending lock
    _isSendingMessage = true;

    try {
      // Use existing sendMessage provider - fully service-driven
      final sendMessage = ref.read(sendMessageProvider);
      await sendMessage(
        conversationId: selectedConversationId,
        content: message.trim(),
      );

      // Check mounted state after async operation before UI updates
      if (!mounted) return;
      
      messageController.clear();
    } catch (e) {
      // Handle send errors gracefully
      if (mounted) {
        print('Failed to send message: $e');
        // Could show error snackbar here if needed
      }
    } finally {
      // Always release the lock, even on error
      _isSendingMessage = false;
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}