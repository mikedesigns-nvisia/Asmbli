import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Chat screen that matches the screenshot with collapsible sidebar and MCP servers
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isSidebarCollapsed = false;
  String selectedAgent = 'general-assistant';
  List<Message> messages = [];
  final TextEditingController messageController = TextEditingController();
  bool isLoading = false;

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBF9F5),
              Color(0xFFFCFAF7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header matching other pages
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  border: Border(bottom: BorderSide(color: AppTheme.lightBorder.withOpacity(0.3))),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: Text(
                        'Asmbli',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.lightForeground,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _HeaderButton('Templates', Icons.library_books, () => context.go('/templates')),
                    const SizedBox(width: 16),
                    _HeaderButton('Library', Icons.folder, () => context.go('/dashboard')),
                    const SizedBox(width: 16),
                    _HeaderButton('Settings', Icons.settings, () => context.go('/settings')),
                  ],
                ),
              ),
              
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
                          color: Colors.white.withOpacity(0.7),
                          border: Border(right: BorderSide(color: AppTheme.lightBorder.withOpacity(0.3))),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            IconButton(
                              onPressed: () => setState(() => isSidebarCollapsed = false),
                              icon: const Icon(Icons.chevron_right, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.8),
                                foregroundColor: AppTheme.lightMutedForeground,
                                side: BorderSide(color: AppTheme.lightBorder.withOpacity(0.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Chat Area
                    Expanded(
                      child: _buildChatArea(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        border: Border(right: BorderSide(color: AppTheme.lightBorder.withOpacity(0.3))),
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
                  'Agent Control',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightForeground,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => isSidebarCollapsed = true),
                  icon: const Icon(Icons.chevron_left, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.lightMutedForeground,
                  ),
                ),
              ],
            ),
          ),
          
          // Agent Selection Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Agent',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightMutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white.withOpacity(0.8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedAgent,
                      onChanged: (value) => setState(() => selectedAgent = value!),
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 14,
                        color: AppTheme.lightForeground,
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
                    border: Border.all(color: AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white.withOpacity(0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.library_books,
                        size: 16,
                        color: AppTheme.lightMutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Browse Agent Library',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 13,
                          color: AppTheme.lightMutedForeground,
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
                      color: AppTheme.lightMutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MCP Servers',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.lightMutedForeground,
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
                          color: server.isConnected ? Colors.green : AppTheme.lightMutedForeground,
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
                              color: AppTheme.lightForeground,
                            ),
                          ),
                          Text(
                            server.description,
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 11,
                              color: AppTheme.lightMutedForeground,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (server.isConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'connected',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
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
                    color: AppTheme.lightMutedForeground,
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
                    border: Border.all(color: AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white.withOpacity(0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 16,
                        color: AppTheme.lightMutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upload Documents',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 13,
                          color: AppTheme.lightMutedForeground,
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
                    border: Border.all(color: AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white.withOpacity(0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings,
                        size: 16,
                        color: AppTheme.lightMutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'API Settings',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 13,
                          color: AppTheme.lightMutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Browse Templates Button
                GestureDetector(
                  onTap: () => context.go('/templates'),
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
                          color: AppTheme.lightMutedForeground,
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
                    color: AppTheme.lightForeground,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.lightMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    agents.firstWhere((a) => a.id == selectedAgent).description,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 12,
                      color: AppTheme.lightMutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Messages Area or Empty State
          Expanded(
            child: messages.isEmpty ? _buildEmptyState(context) : _buildMessagesList(context),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.lightBorder),
                    ),
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(
                          fontFamily: 'Space Grotesk',
                          color: AppTheme.lightMutedForeground,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: AppTheme.lightForeground,
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
                    color: AppTheme.lightMutedForeground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: messageController.text.trim().isNotEmpty && !isLoading
                        ? _sendMessage
                        : null,
                    icon: isLoading 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.lightPrimaryForeground),
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: AppTheme.lightPrimaryForeground,
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
                color: AppTheme.lightMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.lightBorder),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 32,
                color: AppTheme.lightMutedForeground,
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
                color: AppTheme.lightForeground,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Select an agent and send a message to begin.\nYou can upload documents for context or\nconfigure API settings in the sidebar.',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                color: AppTheme.lightMutedForeground,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.role == 'user';
        
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
  }

  void _sendMessage() {
    if (messageController.text.trim().isEmpty || isLoading) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      messages.add(userMessage);
      isLoading = true;
    });

    messageController.clear();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      final assistantMessage = Message(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: 'I\'m a mock response to: "${userMessage.content}". In production, this would connect to your configured AI model via API.',
        timestamp: DateTime.now(),
      );

      setState(() {
        messages.add(assistantMessage);
        isLoading = false;
      });
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class Message {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
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

class _HeaderButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _HeaderButton(this.text, this.icon, this.onTap, {this.isActive = false});

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.lightPrimary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.lightPrimaryForeground),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: AppTheme.lightPrimaryForeground,
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.lightMutedForeground,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}