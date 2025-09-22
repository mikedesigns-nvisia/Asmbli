import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';

// Simple topic model
class Topic {
  final String id;
  final String name;
  final String? description;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
  
  const Topic({
    required this.id,
    required this.name,
    this.description,
    this.icon = Icons.folder,
    this.color = Colors.blue,
    required this.createdAt,
  });
  
  Topic copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    DateTime? createdAt,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Sample topics for now
final defaultTopics = [
  Topic(
    id: 'general',
    name: 'General',
    description: 'General conversations',
    icon: Icons.chat,
    color: Colors.grey,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  ),
  Topic(
    id: 'work',
    name: 'Work Projects',
    description: 'Work-related discussions',
    icon: Icons.work,
    color: Colors.blue,
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
  ),
  Topic(
    id: 'research',
    name: 'Research',
    description: 'Research and learning',
    icon: Icons.science,
    color: Colors.green,
    createdAt: DateTime.now().subtract(const Duration(days: 15)),
  ),
  Topic(
    id: 'personal',
    name: 'Personal',
    description: 'Personal conversations',
    icon: Icons.person,
    color: Colors.purple,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
];

// Topic providers (simplified for now)
final topicsProvider = StateProvider<List<Topic>>((ref) => defaultTopics);

// Provider to track which topic is expanded
final expandedTopicProvider = StateProvider<String?>((ref) => null);

// Provider to get conversations by topic
final conversationsByTopicProvider = Provider.family<List<Conversation>, String>((ref, topicId) {
  final conversations = ref.watch(conversationsProvider).valueOrNull ?? [];
  return conversations.where((conv) {
    final convTopicId = conv.metadata?['topicId'] as String?;
    return convTopicId == topicId || (topicId == 'general' && convTopicId == null);
  }).toList();
});

/// Topic Management Section for organizing conversations
class TopicManagementSection extends ConsumerStatefulWidget {
  const TopicManagementSection({super.key});

  @override
  ConsumerState<TopicManagementSection> createState() => _TopicManagementSectionState();
}

class _TopicManagementSectionState extends ConsumerState<TopicManagementSection> {
  bool _showCreateTopicDialog = false;
  final TextEditingController _topicNameController = TextEditingController();
  final TextEditingController _topicDescriptionController = TextEditingController();
  final IconData _selectedIcon = Icons.folder;
  final Color _selectedColor = Colors.blue;
  
  @override
  void dispose() {
    _topicNameController.dispose();
    _topicDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topics = ref.watch(topicsProvider);
    final expandedTopic = ref.watch(expandedTopicProvider);
    final selectedConversationId = ref.watch(selectedConversationIdProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: SpacingTokens.lg),
        // Topics Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
          child: Row(
            children: [
              Icon(
                Icons.topic,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: SpacingTokens.iconSpacing),
              Text(
                'Topics',
                style: TextStyle(
                  
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showCreateTopic(),
                icon: const Icon(Icons.add, size: 16),
                style: IconButton.styleFrom(
                  foregroundColor: ThemeColors(context).primary,
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(24, 24),
                ),
                tooltip: 'Create Topic',
              ),
            ],
          ),
        ),
        
        const SizedBox(height: SpacingTokens.componentSpacing),
        
        // Topics List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final conversations = ref.watch(conversationsByTopicProvider(topic.id));
              final isExpanded = expandedTopic == topic.id;
              
              return _buildTopicSection(
                context, 
                topic, 
                conversations, 
                isExpanded,
                selectedConversationId,
              );
            },
          ),
        ),
        
        // Create Topic Dialog
        if (_showCreateTopicDialog) _buildCreateTopicDialog(theme),
      ],
    );
  }

  Widget _buildTopicSection(
    BuildContext context, 
    Topic topic, 
    List<Conversation> conversations,
    bool isExpanded,
    String? selectedConversationId,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Topic Header
          InkWell(
            onTap: () => _toggleTopic(topic.id),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(6),
              bottom: isExpanded ? Radius.zero : const Radius.circular(6),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: topic.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: topic.color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      topic.icon,
                      size: 16,
                      color: topic.color,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.componentSpacing),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.name,
                          style: TextStyle(
                            
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (topic.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            topic.description!,
                            style: TextStyle(
                              
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Conversation count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: topic.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${conversations.length}',
                      style: TextStyle(
                        
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: topic.color,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Expand/collapse icon
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          
          // Conversations in topic
          if (isExpanded) ...[
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
              ),
              child: conversations.isEmpty
                  ? _buildEmptyTopicState(context, topic)
                  : Column(
                      children: conversations.map((conversation) {
                        final isSelected = conversation.id == selectedConversationId;
                        return _buildTopicConversationItem(
                          context,
                          conversation,
                          topic,
                          isSelected,
                        );
                      }).toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyTopicState(BuildContext context, Topic topic) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No conversations in ${topic.name}',
            style: TextStyle(
              
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _createConversationInTopic(topic.id),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Start Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: topic.color.withValues(alpha: 0.1),
              foregroundColor: topic.color,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicConversationItem(
    BuildContext context,
    Conversation conversation,
    Topic topic,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => _selectConversation(conversation.id),
      onLongPress: () => _showConversationOptions(conversation, topic),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? topic.color.withValues(alpha: 0.1) 
              : Colors.transparent,
          border: isSelected 
              ? Border(left: BorderSide(color: topic.color, width: 3))
              : null,
        ),
        child: Row(
          children: [
            // Type indicator
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _getConversationTypeColor(conversation, theme),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: TextStyle(
                      
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? topic.color : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _getConversationTypeIcon(conversation),
                        size: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${conversation.messages.length} msgs',
                        style: TextStyle(
                          
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(conversation.createdAt),
                        style: TextStyle(
                          
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTopicDialog(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.9),
      child: Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Topic',
                style: TextStyle(
                  
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _topicNameController,
                decoration: const InputDecoration(
                  labelText: 'Topic Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _topicDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: AsmblButton.secondary(
                      text: 'Cancel',
                      onPressed: () => _cancelCreateTopic(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AsmblButton.primary(
                      text: 'Create',
                      onPressed: () => _confirmCreateTopic(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTopic(String topicId) {
    final currentExpanded = ref.read(expandedTopicProvider);
    ref.read(expandedTopicProvider.notifier).state = 
        currentExpanded == topicId ? null : topicId;
  }

  void _selectConversation(String conversationId) {
    ref.read(selectedConversationIdProvider.notifier).state = conversationId;
  }

  void _showCreateTopic() {
    setState(() {
      _showCreateTopicDialog = true;
    });
  }

  void _cancelCreateTopic() {
    setState(() {
      _showCreateTopicDialog = false;
    });
    _topicNameController.clear();
    _topicDescriptionController.clear();
  }

  void _confirmCreateTopic() {
    if (_topicNameController.text.trim().isEmpty) return;
    
    final newTopic = Topic(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _topicNameController.text.trim(),
      description: _topicDescriptionController.text.trim().isEmpty 
          ? null : _topicDescriptionController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
      createdAt: DateTime.now(),
    );
    
    final currentTopics = ref.read(topicsProvider);
    ref.read(topicsProvider.notifier).state = [...currentTopics, newTopic];
    
    _cancelCreateTopic();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Topic "${newTopic.name}" created'),
        backgroundColor: ThemeColors(context).success,
      ),
    );
  }

  void _createConversationInTopic(String topicId) async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;
      
      final createConversation = ref.read(createConversationProvider);
      final conversation = await createConversation(
        title: 'New Conversation - ${DateTime.now().toString().substring(0, 16)}',
        metadata: {'topicId': topicId},
      );
      
      ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
      ref.invalidate(conversationsProvider);
    } catch (e) {
      // Handle error
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  void _showConversationOptions(Conversation conversation, Topic topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversation Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: const Text('Move to Different Topic'),
              onTap: () {
                Navigator.pop(context);
                _showMoveConversationDialog(conversation);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive Conversation'),
              onTap: () {
                Navigator.pop(context);
                _archiveConversation(conversation.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveConversationDialog(Conversation conversation) {
    final topics = ref.read(topicsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: topics.map((topic) => ListTile(
            leading: Icon(topic.icon, color: topic.color),
            title: Text(topic.name),
            onTap: () {
              // TODO: Implement move conversation to topic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Moved to ${topic.name}')),
              );
            },
          )).toList(),
        ),
      ),
    );
  }

  void _archiveConversation(String conversationId) async {
    try {
      final archiveConversation = ref.read(archiveConversationProvider);
      await archiveConversation(conversationId, true);
      
      final selectedId = ref.read(selectedConversationIdProvider);
      if (selectedId == conversationId) {
        ref.read(selectedConversationIdProvider.notifier).state = null;
      }
    } catch (e) {
      // Handle error
    }
  }

  Color _getConversationTypeColor(Conversation conversation, ThemeData theme) {
    final type = conversation.metadata?['type'] as String?;
    switch (type) {
      case 'agent':
        return ThemeColors(context).primary;
      case 'default_api':
        return theme.colorScheme.onSurfaceVariant;
      default:
        return theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    }
  }

  IconData _getConversationTypeIcon(Conversation conversation) {
    final type = conversation.metadata?['type'] as String?;
    switch (type) {
      case 'agent':
        return Icons.smart_toy;
      case 'default_api':
        return Icons.api;
      default:
        return Icons.chat;
    }
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