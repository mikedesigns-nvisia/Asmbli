import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/mcp_capability.dart';
import '../../../../core/services/mcp_orchestrator.dart';
import '../../../../core/services/mcp_user_interface_service.dart';
import '../../../../core/design_system/components/mcp_progress_widget.dart';
import 'package:agent_engine_core/models/agent.dart';

/// MCP Chat Integration Widget
/// 
/// This widget demonstrates the Anthropic PM approach in action:
/// - Agents can request capabilities naturally in conversation
/// - Users see friendly progress updates instead of terminal output  
/// - One-click approval for enabling new capabilities
/// - Seamless integration with chat flow
class MCPChatIntegration extends ConsumerStatefulWidget {
  final Agent? currentAgent;

  const MCPChatIntegration({
    super.key,
    this.currentAgent,
  });

  @override
  ConsumerState<MCPChatIntegration> createState() => _MCPChatIntegrationState();
}

class _MCPChatIntegrationState extends ConsumerState<MCPChatIntegration> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addSystemMessage("👋 Hi! I can help you with various tasks. Just tell me what you'd like to do!");
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Column(
      children: [
        // MCP Progress Area (shows capability setup progress)
        _buildProgressArea(),
        
        // Chat Messages
        Expanded(
          child: Container(
            padding: SpacingTokens.lg,
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
        ),
        
        // Message Input
        _buildMessageInput(colors),
      ],
    );
  }

  Widget _buildProgressArea() {
    return Container(
      padding: SpacingTokens.lg,
      child: const MCPProgressListWidget(),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final colors = ThemeColors(context);
    final isUser = message.sender == MessageSender.user;
    
    return Padding(
      padding: EdgeInsets.only(bottom: SpacingTokens.md.vertical),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(message.sender, colors),
            SizedBox(width: SpacingTokens.md.horizontal),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: SpacingTokens.md,
                  decoration: BoxDecoration(
                    color: isUser ? colors.primary : colors.surface,
                    borderRadius: BorderRadiusTokens.lg,
                  ),
                  child: Text(
                    message.content,
                    style: TextStyles.bodyMedium.copyWith(
                      color: isUser ? Colors.white : colors.onSurface,
                    ),
                  ),
                ),
                if (message.suggestedCapabilities.isNotEmpty) ...[
                  SizedBox(height: SpacingTokens.sm.vertical),
                  _buildCapabilitySuggestions(message.suggestedCapabilities),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: SpacingTokens.md.horizontal),
            _buildAvatar(message.sender, colors),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(MessageSender sender, ThemeColors colors) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: sender == MessageSender.user ? colors.accent : colors.primary,
        borderRadius: BorderRadiusTokens.full,
      ),
      child: Center(
        child: Text(
          sender == MessageSender.user ? '👤' : '🤖',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCapabilitySuggestions(List<AgentCapability> capabilities) {
    return Wrap(
      spacing: SpacingTokens.sm.horizontal,
      runSpacing: SpacingTokens.sm.vertical,
      children: capabilities.map((capability) => 
        _buildCapabilitySuggestionChip(capability)
      ).toList(),
    );
  }

  Widget _buildCapabilitySuggestionChip(AgentCapability capability) {
    final colors = ThemeColors(context);
    
    return InkWell(
      onTap: () => _enableCapability(capability),
      borderRadius: BorderRadiusTokens.lg,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.1),
          borderRadius: BorderRadiusTokens.lg,
          border: Border.all(
            color: colors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              capability.iconEmoji,
              style: const TextStyle(fontSize: 14),
            ),
            SizedBox(width: SpacingTokens.xs.horizontal),
            Text(
              'Enable ${capability.displayName}',
              style: TextStyles.bodySmall.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeColors colors) {
    return Container(
      padding: SpacingTokens.lg,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask me to help with something...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadiusTokens.lg,
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colors.background,
                contentPadding: SpacingTokens.md,
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          SizedBox(width: SpacingTokens.md.horizontal),
          AsmblButton.primary(
            text: 'Send',
            onPressed: () => _sendMessage(_messageController.text),
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;

    // Add user message
    _addMessage(ChatMessage(
      content: content,
      sender: MessageSender.user,
    ));

    _messageController.clear();

    // Simulate AI response with capability suggestions
    _handleUserMessage(content);
  }

  void _handleUserMessage(String content) {
    // This simulates how the AI would respond and suggest capabilities
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains('code') || lowerContent.contains('repository')) {
      _addMessage(ChatMessage(
        content: "I'd love to help you with code analysis! I can examine your codebase, review code quality, and suggest improvements. To get started, I'll need to enable some development tools.",
        sender: MessageSender.agent,
        suggestedCapabilities: [
          AgentCapability.codeAnalysis,
          AgentCapability.gitIntegration,
          AgentCapability.fileAccess,
        ],
      ));
    } else if (lowerContent.contains('search') || lowerContent.contains('research')) {
      _addMessage(ChatMessage(
        content: "I can help you search for information online! This will allow me to find up-to-date information and research topics for you.",
        sender: MessageSender.agent,
        suggestedCapabilities: [
          AgentCapability.webSearch,
        ],
      ));
    } else if (lowerContent.contains('database') || lowerContent.contains('data')) {
      _addMessage(ChatMessage(
        content: "I can help you work with databases and analyze data! I'll be able to query databases, inspect schemas, and help you understand your data without you needing to write SQL.",
        sender: MessageSender.agent,
        suggestedCapabilities: [
          AgentCapability.databaseAccess,
        ],
      ));
    } else if (lowerContent.contains('remember') || lowerContent.contains('memory')) {
      _addMessage(ChatMessage(
        content: "I can remember important information across our conversations! This helps me provide more personalized assistance and remember your preferences.",
        sender: MessageSender.agent,
        suggestedCapabilities: [
          AgentCapability.persistentMemory,
        ],
      ));
    } else {
      _addMessage(ChatMessage(
        content: "I can help with many different tasks! Some things I can do include analyzing code, searching the web, working with databases, managing files, and more. What specific task would you like help with?",
        sender: MessageSender.agent,
      ));
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
  }

  void _addSystemMessage(String content) {
    _addMessage(ChatMessage(
      content: content,
      sender: MessageSender.system,
    ));
  }

  Future<void> _enableCapability(AgentCapability capability) async {
    if (widget.currentAgent == null) {
      _addSystemMessage("Please select an agent first to enable capabilities.");
      return;
    }

    _addSystemMessage("Enabling ${capability.displayName}...");

    final orchestrator = ref.read(mcpOrchestratorProvider);
    
    try {
      final result = await orchestrator.enableCapability(
        capability, 
        widget.currentAgent!,
      );

      if (result.success) {
        _addSystemMessage(result.message);
        
        // Show what the agent can now do
        final newMessage = _getCapabilityEnabledMessage(capability);
        _addMessage(newMessage);
        
      } else {
        _addSystemMessage("⚠️ ${result.message}");
        
        if (result.recoverySuggestions.isNotEmpty) {
          final suggestions = result.recoverySuggestions.take(2).join('\n• ');
          _addSystemMessage("💡 Suggestions:\n• $suggestions");
        }
      }
    } catch (e) {
      _addSystemMessage("❌ Something went wrong: $e");
    }
  }

  ChatMessage _getCapabilityEnabledMessage(AgentCapability capability) {
    String content;
    
    switch (capability) {
      case AgentCapability.codeAnalysis:
        content = "🚀 Great! I can now analyze your code. Try asking me to 'review my code quality' or 'find potential bugs in my project'.";
        break;
      case AgentCapability.webSearch:
        content = "🌐 Perfect! I can now search the web for you. Ask me to 'research the latest trends in AI' or 'find information about any topic'.";
        break;
      case AgentCapability.databaseAccess:
        content = "🗄️ Excellent! I can now work with your databases. Try asking me to 'show me my database schema' or 'analyze my data patterns'.";
        break;
      case AgentCapability.persistentMemory:
        content = "🧠 Awesome! I'll now remember our conversations and your preferences. This will help me provide better, more personalized assistance.";
        break;
      default:
        content = "✅ ${capability.displayName} is now ready! ${capability.userBenefit}";
    }
    
    return ChatMessage(
      content: content,
      sender: MessageSender.agent,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

/// Chat message model for demo
class ChatMessage {
  final String content;
  final MessageSender sender;
  final List<AgentCapability> suggestedCapabilities;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.sender,
    this.suggestedCapabilities = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum MessageSender {
  user,
  agent,
  system,
}