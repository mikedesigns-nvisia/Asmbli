import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:agent_engine_core/models/conversation.dart' as core;
import 'package:agent_engine_core/services/implementations/service_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../providers/conversation_provider.dart';
import '../widgets/conversation_sidebar.dart';
import '../widgets/loading_overlay.dart';

/// Chat screen that matches the screenshot with collapsible sidebar and MCP servers
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool isSidebarCollapsed = false;
  String selectedAgent = 'general-assistant';
  final TextEditingController messageController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      ServiceProvider.configure(useInMemory: true);
      await ServiceProvider.initialize();
    } catch (e) {
      print('Service initialization failed: $e');
    }
  }

  final List<Agent> agents = [
    Agent(id: 'general-assistant', name: 'General Assistant', description: 'A helpful AI assistant'),
    Agent(id: 'research-assistant', name: 'Research Assistant', description: 'Specialized in research and citations'),
    Agent(id: 'code-reviewer', name: 'Code Reviewer', description: 'Helps with code review and programming'),
  ];

  final List<MCPServer> mcpServers = [
    MCPServer(name: 'Filesystem', description: 'File operations', isConnected: true),
    MCPServer(name: 'Brave Search', description: 'Real-time web search', isConnected: true),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: LoadingOverlay(
        isLoading: ref.watch(isLoadingProvider),
        loadingText: 'Processing...',
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SemanticColors.backgroundGradientStart,
                SemanticColors.backgroundGradientEnd,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
            children: [
              // Header
              const AppNavigationBar(currentRoute: AppRoutes.chat),
              
              // Main Content
              Expanded(
                child: Row(
                  children: [
                    // Sidebar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isSidebarCollapsed ? 0 : 280,
                      child: isSidebarCollapsed ? null : _buildSidebar(context),
                    ),
                    
                    // Sidebar Toggle (when collapsed)
                    if (isSidebarCollapsed)
                      Container(
                        width: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.7),
                          border: Border(right: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            IconButton(
                              onPressed: () => setState(() => isSidebarCollapsed = false),
                              icon: const Icon(Icons.chevron_right, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
                                foregroundColor: theme.colorScheme.onSurfaceVariant,
                                side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Chat Area
                    Expanded(
                      child: _buildChatArea(context),
                    ),
                    
                    // Right Sidebar for Conversations
                    const ConversationSidebar(),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.7),
        border: Border(right: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Agent Settings',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => isSidebarCollapsed = true),
                  icon: const Icon(Icons.chevron_left, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Agent Selection Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Agent',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(6),
                    color: theme.colorScheme.surface.withOpacity(0.8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedAgent,
                      onChanged: (value) => setState(() => selectedAgent = value!),
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      items: agents.map((agent) {
                        return DropdownMenuItem(
                          value: agent.id,
                          child: Text(agent.name),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Browse Agent Library Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(6),
                    color: theme.colorScheme.surface.withOpacity(0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.library_books,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Browse Agent Library',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // MCP Servers Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.storage,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MCP Servers',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // MCP Server Items
                ...mcpServers.map((server) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: server.isConnected ? SemanticColors.success : theme.colorScheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            server.name,
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            server.description,
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (server.isConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: SemanticColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'connected',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: SemanticColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                )),
                
                const SizedBox(height: 8),
                Text(
                  '${mcpServers.where((s) => s.isConnected).length} of ${mcpServers.length} servers active',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Upload Documents
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(6),
                    color: theme.colorScheme.surface.withOpacity(0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upload Documents',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // API Settings
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(6),
                    color: theme.colorScheme.surface.withOpacity(0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'API Settings',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Browse Templates Button
                GestureDetector(
                  onTap: () => context.go(AppRoutes.templates),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Browse Templates',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          // Chat Header with agent info
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  agents.firstWhere((a) => a.id == selectedAgent).name,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    agents.firstWhere((a) => a.id == selectedAgent).description,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Messages Area or Empty State
          Expanded(
            child: _buildMessagesArea(context),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(
                          fontFamily: 'Space Grotesk',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 3,
                      minLines: 1,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: messageController.text.trim().isNotEmpty && !ref.watch(isLoadingProvider)
                        ? _sendMessage
                        : null,
                    icon: ref.watch(isLoadingProvider) 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Robot icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Start a Conversation
            Text(
              'Start a Conversation',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Select an agent and send a message to begin.\nYou can upload documents for context or\nconfigure API settings in the sidebar.',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesArea(BuildContext context) {
    final selectedConversationId = ref.watch(selectedConversationIdProvider);
    
    if (selectedConversationId == null) {
      return _buildEmptyState(context);
    }
    
    return _buildMessagesList(context, selectedConversationId);
  }
  
  Widget _buildMessagesList(BuildContext context, String conversationId) {
    final messagesAsync = ref.watch(messagesProvider(conversationId));
    
    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return _buildEmptyConversationState(context);
        }
        
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length + (ref.watch(isLoadingProvider) ? 1 : 0),
          itemBuilder: (context, index) {
            // Show typing indicator as last item when loading
            if (index == messages.length && ref.watch(isLoadingProvider)) {
              return const MessageLoadingIndicator();
            }
            
            final message = messages[index];
            final isUser = message.role == core.MessageRole.user;
            
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primary,
                      child: Icon(
                        Icons.smart_toy,
                        size: 20,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? colorScheme.primary : colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: !isUser ? Border.all(
                          color: colorScheme.outline.withOpacity(0.3),
                        ) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                              fontFamily: 'Space Grotesk',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(message.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: (isUser ? colorScheme.onPrimary : colorScheme.onSurface).withOpacity(0.7),
                              fontFamily: 'Space Grotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.surface,
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: SemanticColors.primary),
      ),
      error: (error, stack) => Center(
        child: ErrorMessage(
          message: 'Failed to load messages: ${error.toString()}',
          onRetry: () {
            ref.invalidate(messagesProvider(conversationId));
          },
        ),
      ),
    );
  }

  void _sendMessage() async {
    final selectedConversationId = ref.read(selectedConversationIdProvider);
    if (messageController.text.trim().isEmpty || 
        ref.read(isLoadingProvider) || 
        selectedConversationId == null) return;

    try {
      ref.read(isLoadingProvider.notifier).state = true;
      
      final sendMessage = ref.read(sendMessageProvider);
      await sendMessage(
        conversationId: selectedConversationId,
        content: messageController.text.trim(),
      );
      
      messageController.clear();
      
      // Simulate AI response
      await Future.delayed(const Duration(seconds: 1));
      
      final assistantMessage = core.Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'This is a simulated AI response. In production, this would connect to your configured AI model.',
        role: core.MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      
      final service = ref.read(conversationServiceProvider);
      await service.addMessage(selectedConversationId, assistantMessage);
      
      // Refresh messages
      ref.invalidate(messagesProvider(selectedConversationId));
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: SemanticColors.error,
          ),
        );
      }
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Widget _buildEmptyConversationState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Start the conversation',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Type a message below to begin this conversation.',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class Agent {
  final String id;
  final String name;
  final String description;

  Agent({
    required this.id,
    required this.name,
    required this.description,
  });
}

class MCPServer {
  final String name;
  final String description;
  final bool isConnected;

  MCPServer({
    required this.name,
    required this.description,
    required this.isConnected,
  });
}

