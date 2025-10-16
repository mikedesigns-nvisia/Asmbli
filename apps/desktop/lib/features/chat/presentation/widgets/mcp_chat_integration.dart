import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/mcp_capability.dart';
import '../../../../core/services/mcp_orchestrator.dart';
import '../../../../core/services/mcp_user_interface_service.dart';
import '../../../../core/services/mcp_catalog_service.dart';
import '../../../../core/design_system/components/mcp_progress_widget.dart';
import 'package:agent_engine_core/models/agent.dart';

/// Server recommendation for contextual suggestions
class ServerRecommendation {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String reason; // Why this server is recommended
  final double relevanceScore; // 0.0 to 1.0

  const ServerRecommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.reason,
    required this.relevanceScore,
  });
}


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
            padding: EdgeInsets.all(SpacingTokens.lg),
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
    return Column(
      children: [
        // Existing progress widget
        Container(
          padding: EdgeInsets.all(SpacingTokens.lg),
          child: const MCPProgressListWidget(),
        ),

        // Contextual server recommendations
        _buildServerRecommendations(),
      ],
    );
  }

  Widget _buildServerRecommendations() {
    return Consumer(
      builder: (context, ref, child) {
        final colors = ThemeColors(context);

        // Get contextual recommendations based on current conversation
        final recommendations = _getContextualRecommendations();

        if (recommendations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
          padding: EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                    color: colors.accent, size: 18),
                  SizedBox(width: SpacingTokens.sm),
                  Text(
                    'Suggested Tools',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SpacingTokens.sm),
              Wrap(
                spacing: SpacingTokens.sm,
                runSpacing: SpacingTokens.xs,
                children: recommendations.map((rec) =>
                  _buildRecommendationChip(rec, colors)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecommendationChip(ServerRecommendation recommendation, ThemeColors colors) {
    return GestureDetector(
      onTap: () => _onRecommendationSelected(recommendation),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(recommendation.icon,
              color: colors.primary, size: 14),
            SizedBox(width: SpacingTokens.xs),
            Text(
              recommendation.name,
              style: TextStyles.bodySmall.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: SpacingTokens.xs),
            Icon(Icons.add_circle_outline,
              color: colors.primary, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final colors = ThemeColors(context);
    final isUser = message.sender == MessageSender.user;
    
    return Padding(
      padding: EdgeInsets.only(bottom: SpacingTokens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(message.sender, colors),
            SizedBox(width: SpacingTokens.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: isUser ? colors.primary : colors.surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyles.bodyMedium.copyWith(
                      color: isUser ? Colors.white : colors.onSurface,
                    ),
                  ),
                ),
                if (message.suggestedCapabilities.isNotEmpty) ...[
                  SizedBox(height: SpacingTokens.sm),
                  _buildCapabilitySuggestions(message.suggestedCapabilities),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: SpacingTokens.md),
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
        borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
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
      spacing: SpacingTokens.sm,
      runSpacing: SpacingTokens.sm,
      children: capabilities.map((capability) => 
        _buildCapabilitySuggestionChip(capability)
      ).toList(),
    );
  }

  Widget _buildCapabilitySuggestionChip(AgentCapability capability) {
    final colors = ThemeColors(context);
    
    return InkWell(
      onTap: () => _enableCapability(capability),
      borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              capability.iconEmoji,
              style: const TextStyle(fontSize: 14),
            ),
            SizedBox(width: SpacingTokens.xs),
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
      padding: EdgeInsets.all(SpacingTokens.lg),
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
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colors.background,
                contentPadding: EdgeInsets.all(SpacingTokens.md),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          SizedBox(width: SpacingTokens.md),
          AsmblButton.primary(
            text: 'Send',
            onPressed: () => _sendMessage(_messageController.text),
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

  // ==================== Contextual Recommendations ====================

  /// Get contextual server recommendations based on conversation content
  List<ServerRecommendation> _getContextualRecommendations() {
    if (_messages.isEmpty) {
      return _getDefaultRecommendations();
    }

    // Analyze recent messages for context
    final recentMessages = _messages.take(5).toList();
    final conversationContext = recentMessages
        .map((msg) => msg.content.toLowerCase())
        .join(' ');

    final recommendations = <ServerRecommendation>[];

    // File system operations
    if (_containsKeywords(conversationContext, ['file', 'read', 'write', 'directory', 'folder', 'upload'])) {
      recommendations.add(const ServerRecommendation(
        id: 'filesystem',
        name: 'File System',
        description: 'Read, write, and manage files',
        icon: Icons.folder,
        reason: 'Detected file operations in conversation',
        relevanceScore: 0.9,
      ));
    }

    // Git operations
    if (_containsKeywords(conversationContext, ['git', 'commit', 'branch', 'repository', 'merge', 'pull'])) {
      recommendations.add(const ServerRecommendation(
        id: 'git',
        name: 'Git Integration',
        description: 'Version control operations',
        icon: Icons.source,
        reason: 'Git operations mentioned',
        relevanceScore: 0.8,
      ));
    }

    // Database queries
    if (_containsKeywords(conversationContext, ['database', 'sql', 'query', 'table', 'data', 'postgres', 'mysql'])) {
      recommendations.add(const ServerRecommendation(
        id: 'database',
        name: 'Database Query',
        description: 'Execute SQL queries and manage databases',
        icon: Icons.storage,
        reason: 'Database operations discussed',
        relevanceScore: 0.85,
      ));
    }

    // Web search and research
    if (_containsKeywords(conversationContext, ['search', 'research', 'google', 'web', 'find', 'lookup'])) {
      recommendations.add(const ServerRecommendation(
        id: 'web-search',
        name: 'Web Search',
        description: 'Search the web for information',
        icon: Icons.search,
        reason: 'Research or search mentioned',
        relevanceScore: 0.7,
      ));
    }

    // API calls and HTTP requests
    if (_containsKeywords(conversationContext, ['api', 'http', 'request', 'endpoint', 'rest', 'webhook'])) {
      recommendations.add(const ServerRecommendation(
        id: 'http-client',
        name: 'HTTP Client',
        description: 'Make API calls and HTTP requests',
        icon: Icons.http,
        reason: 'API operations detected',
        relevanceScore: 0.8,
      ));
    }

    // Terminal/shell operations
    if (_containsKeywords(conversationContext, ['terminal', 'shell', 'command', 'execute', 'script', 'bash'])) {
      recommendations.add(const ServerRecommendation(
        id: 'terminal',
        name: 'Terminal',
        description: 'Execute shell commands',
        icon: Icons.terminal,
        reason: 'Terminal operations mentioned',
        relevanceScore: 0.9,
      ));
    }

    // Sort by relevance score and return top 3
    recommendations.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return recommendations.take(3).toList();
  }

  /// Get default recommendations when no context is available
  List<ServerRecommendation> _getDefaultRecommendations() {
    return const [
      ServerRecommendation(
        id: 'filesystem',
        name: 'File System',
        description: 'Read and write files',
        icon: Icons.folder,
        reason: 'Popular general-purpose tool',
        relevanceScore: 0.6,
      ),
      ServerRecommendation(
        id: 'web-search',
        name: 'Web Search',
        description: 'Search for information',
        icon: Icons.search,
        reason: 'Helpful for research tasks',
        relevanceScore: 0.5,
      ),
    ];
  }

  /// Check if conversation context contains any of the given keywords
  bool _containsKeywords(String context, List<String> keywords) {
    return keywords.any((keyword) => context.contains(keyword));
  }

  /// Handle recommendation selection
  void _onRecommendationSelected(ServerRecommendation recommendation) async {
    // Add a system message about enabling the tool
    _addSystemMessage('🔧 Enabling ${recommendation.name}...');

    try {
      // Here we would integrate with the actual MCP service to enable the server
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 1));

      _addSystemMessage('✅ ${recommendation.name} is now available! You can now ${recommendation.description.toLowerCase()}.');

      // Suggest some sample commands
      _suggestSampleCommands(recommendation);

    } catch (e) {
      _addSystemMessage('❌ Failed to enable ${recommendation.name}: $e');
    }
  }

  /// Suggest sample commands for the newly enabled server
  void _suggestSampleCommands(ServerRecommendation recommendation) {
    switch (recommendation.id) {
      case 'filesystem':
        _addSystemMessage('💡 Try: "Read the contents of my README.md file" or "List all files in the project directory"');
        break;
      case 'git':
        _addSystemMessage('💡 Try: "Show me the git status" or "Create a new branch called feature-xyz"');
        break;
      case 'database':
        _addSystemMessage('💡 Try: "Show me all tables in the database" or "Query users where status is active"');
        break;
      case 'web-search':
        _addSystemMessage('💡 Try: "Search for the latest news about AI" or "Find documentation for React hooks"');
        break;
      case 'http-client':
        _addSystemMessage('💡 Try: "Make a GET request to example.com/api" or "Test the webhook endpoint"');
        break;
      case 'terminal':
        _addSystemMessage('💡 Try: "Run npm install" or "Check the system uptime"');
        break;
    }
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