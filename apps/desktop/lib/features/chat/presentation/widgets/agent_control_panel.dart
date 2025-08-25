import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../providers/conversation_provider.dart';

/// Agent Control Panel - Shows exactly what the agent sees and can access
/// This is the agent's "brain" view for the user
class AgentControlPanel extends ConsumerStatefulWidget {
  final String? selectedConversationId;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AgentControlPanel({
    super.key,
    this.selectedConversationId,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  ConsumerState<AgentControlPanel> createState() => _AgentControlPanelState();
}

class _AgentControlPanelState extends ConsumerState<AgentControlPanel> {
  int _selectedSection = 0; // 0: Context, 1: Tools, 2: Memory, 3: Instructions

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Collapse/expand toggle when collapsed
        if (widget.isCollapsed)
          Container(
            width: 48,
            decoration: BoxDecoration(
              color: ThemeColors(context).surface.withValues(alpha: 0.9),
              border: Border(
                right: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.3)),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: SpacingTokens.lg),
                _buildCollapsedIcon(Icons.psychology, 'Agent Brain', 0),
                SizedBox(height: SpacingTokens.sm),
                _buildCollapsedIcon(Icons.extension, 'Tools', 1),
                SizedBox(height: SpacingTokens.sm),
                _buildCollapsedIcon(Icons.memory, 'Memory', 2),
                SizedBox(height: SpacingTokens.sm),
                _buildCollapsedIcon(Icons.assignment, 'Context', 3),
                Spacer(),
                IconButton(
                  onPressed: widget.onToggleCollapse,
                  icon: Icon(Icons.chevron_right, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: ThemeColors(context).primary.withValues(alpha: 0.1),
                    foregroundColor: ThemeColors(context).primary,
                  ),
                  tooltip: 'Show Agent Control Panel',
                ),
                SizedBox(height: SpacingTokens.lg),
              ],
            ),
          ),

        // Main control panel content
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: widget.isCollapsed ? 0 : 380,
          child: widget.isCollapsed ? null : _buildControlPanelContent(),
        ),
      ],
    );
  }

  Widget _buildCollapsedIcon(IconData icon, String tooltip, int section) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _selectedSection == section 
          ? ThemeColors(context).primary.withValues(alpha: 0.2)
          : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: _selectedSection == section
          ? Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3))
          : null,
      ),
      child: Icon(
        icon,
        size: 16,
        color: _selectedSection == section
          ? ThemeColors(context).primary
          : ThemeColors(context).onSurfaceVariant,
      ),
    );
  }

  Widget _buildControlPanelContent() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withValues(alpha: 0.95),
        border: Border(
          right: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with agent status
          _buildAgentHeader(),
          
          // Navigation tabs
          _buildNavigationTabs(),
          
          // Content sections
          Expanded(
            child: _buildSelectedSection(),
          ),
          
          // Footer with real-time status
          _buildStatusFooter(),
        ],
      ),
    );
  }

  Widget _buildAgentHeader() {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: ThemeColors(context).primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology,
                  color: ThemeColors(context).primary,
                  size: 20,
                ),
              ),
              SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agent Control Panel',
                      style: TextStyles.cardTitle.copyWith(
                        color: ThemeColors(context).primary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'What your agent sees & can access',
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onToggleCollapse,
                icon: Icon(Icons.chevron_left, size: 18),
                style: IconButton.styleFrom(
                  foregroundColor: ThemeColors(context).onSurfaceVariant,
                ),
                tooltip: 'Collapse Panel',
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.md),
          
          // Agent identity indicator
          if (widget.selectedConversationId != null)
            _buildAgentIdentityCard(),
        ],
      ),
    );
  }

  Widget _buildAgentIdentityCard() {
    final conversationAsync = ref.watch(conversationProvider(widget.selectedConversationId!));
    
    return conversationAsync.when(
      data: (conversation) {
        final agentName = conversation.metadata?['agentName'] ?? 'Default API';
        final agentRole = conversation.metadata?['agentRole'] ?? 'General Assistant';
        final agentType = conversation.metadata?['type'] ?? 'default_api';
        
        return Container(
          padding: EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: ThemeColors(context).surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: agentType == 'agent' 
                ? ThemeColors(context).primary.withValues(alpha: 0.3)
                : ThemeColors(context).border.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: agentType == 'agent'
                    ? ThemeColors(context).primary.withValues(alpha: 0.2)
                    : ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  agentType == 'agent' ? Icons.smart_toy : Icons.chat,
                  size: 16,
                  color: agentType == 'agent'
                    ? ThemeColors(context).primary
                    : ThemeColors(context).onSurfaceVariant,
                ),
              ),
              SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agentName,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      agentRole,
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: agentType == 'agent'
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  agentType == 'agent' ? 'MCP Agent' : 'Basic API',
                  style: TextStyles.bodySmall.copyWith(
                    color: agentType == 'agent' ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingCard(),
      error: (_, __) => _buildErrorCard(),
    );
  }

  Widget _buildNavigationTabs() {
    final tabs = [
      {'icon': Icons.view_list, 'label': 'Context', 'count': null},
      {'icon': Icons.extension, 'label': 'Tools', 'count': 0}, // Will be dynamic
      {'icon': Icons.memory, 'label': 'Memory', 'count': null},
      {'icon': Icons.assignment, 'label': 'Instructions', 'count': null},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: SpacingTokens.md, vertical: SpacingTokens.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedSection == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSection = index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? ThemeColors(context).primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab['icon'] as IconData,
                          size: 16,
                          color: isSelected
                            ? ThemeColors(context).primary
                            : ThemeColors(context).onSurfaceVariant,
                        ),
                        if (tab['count'] != null) ...[
                          SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                ? ThemeColors(context).primary
                                : ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${tab['count']}',
                              style: TextStyles.bodySmall.copyWith(
                                color: isSelected
                                  ? Colors.white
                                  : ThemeColors(context).surface,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      tab['label'] as String,
                      style: TextStyles.bodySmall.copyWith(
                        color: isSelected
                          ? ThemeColors(context).primary
                          : ThemeColors(context).onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedSection() {
    switch (_selectedSection) {
      case 0:
        return _buildContextSection();
      case 1:
        return _buildToolsSection();
      case 2:
        return _buildMemorySection();
      case 3:
        return _buildInstructionsSection();
      default:
        return _buildContextSection();
    }
  }

  Widget _buildContextSection() {
    if (widget.selectedConversationId == null) {
      return _buildNoConversationState();
    }

    final conversationAsync = ref.watch(conversationProvider(widget.selectedConversationId!));
    
    return conversationAsync.when(
      data: (conversation) {
        final contextDocs = conversation.metadata?['contextDocuments'] as List<dynamic>? ?? [];
        final environmentVars = conversation.metadata?['environmentVariables'] as Map<String, dynamic>? ?? {};
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Context Documents
              _buildSectionHeader('Context Documents', Icons.description, contextDocs.length),
              SizedBox(height: SpacingTokens.md),
              
              if (contextDocs.isEmpty)
                _buildEmptyContextState()
              else
                ...contextDocs.map((doc) => _buildContextDocItem(doc.toString())),
              
              SizedBox(height: SpacingTokens.xxl),
              
              // Environment Context
              _buildSectionHeader('Environment Context', Icons.settings, environmentVars.length),
              SizedBox(height: SpacingTokens.md),
              
              if (environmentVars.isEmpty)
                _buildEmptyEnvironmentState()
              else
                ...environmentVars.entries.map((entry) => _buildEnvironmentItem(entry.key, entry.value.toString())),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildErrorState(),
    );
  }

  Widget _buildToolsSection() {
    if (widget.selectedConversationId == null) {
      return _buildNoConversationState();
    }

    final conversationAsync = ref.watch(conversationProvider(widget.selectedConversationId!));
    
    return conversationAsync.when(
      data: (conversation) {
        final mcpServers = conversation.metadata?['mcpServers'] as List<dynamic>? ?? [];
        final mcpConfigs = conversation.metadata?['mcpServerConfigs'] as Map<String, dynamic>? ?? {};
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Active MCP Tools', Icons.extension, mcpServers.length),
              SizedBox(height: SpacingTokens.md),
              
              if (mcpServers.isEmpty)
                _buildNoToolsState()
              else
                ...mcpServers.map((serverId) {
                  final config = mcpConfigs[serverId] as Map<String, dynamic>?;
                  return _buildMCPServerItem(serverId.toString(), config);
                }),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildErrorState(),
    );
  }

  Widget _buildMemorySection() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Conversation Memory', Icons.memory, null),
          SizedBox(height: SpacingTokens.md),
          
          _buildMemoryInfo(
            'Context Window',
            'Active conversation context available to agent',
            'Real-time',
            Icons.chat_bubble_outline,
            Colors.green,
          ),
          
          _buildMemoryInfo(
            'Session Memory',
            'Information stored during this session',
            'Session-based',
            Icons.access_time,
            Colors.blue,
          ),
          
          _buildMemoryInfo(
            'Long-term Memory',
            'Persistent knowledge base (if MCP memory server active)',
            'Persistent',
            Icons.storage,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    if (widget.selectedConversationId == null) {
      return _buildNoConversationState();
    }

    final conversationAsync = ref.watch(conversationProvider(widget.selectedConversationId!));
    
    return conversationAsync.when(
      data: (conversation) {
        final systemPrompt = conversation.metadata?['systemPrompt'] as String? ?? '';
        final basePrompt = conversation.metadata?['baseSystemPrompt'] as String? ?? systemPrompt;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Agent Instructions', Icons.assignment, null),
              SizedBox(height: SpacingTokens.md),
              
              // System prompt preview
              _buildInstructionCard(
                'Complete System Prompt',
                'Full instructions the agent receives (including MCP context)',
                systemPrompt,
                Icons.psychology,
              ),
              
              SizedBox(height: SpacingTokens.lg),
              
              _buildInstructionCard(
                'Base Instructions',
                'Core role-specific instructions without MCP enhancements',
                basePrompt,
                Icons.person,
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildErrorState(),
    );
  }

  // Helper widgets for building various sections
  Widget _buildSectionHeader(String title, IconData icon, int? count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ThemeColors(context).primary),
        SizedBox(width: SpacingTokens.sm),
        Text(
          title,
          style: TextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: ThemeColors(context).onSurface,
          ),
        ),
        if (count != null) ...[
          SizedBox(width: SpacingTokens.sm),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ThemeColors(context).primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContextDocItem(String docName) {
    return Container(
      margin: EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeColors(context).border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.description, size: 16, color: ThemeColors(context).primary),
          SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              docName,
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ACTIVE',
              style: TextStyles.bodySmall.copyWith(
                color: Colors.green,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMCPServerItem(String serverId, Map<String, dynamic>? config) {
    final status = config?['status'] ?? 'connected';
    final description = config?['description'] ?? 'MCP server integration';
    final capabilities = config?['capabilities'] as List<dynamic>? ?? [];
    
    final statusColor = status == 'connected' ? Colors.green : 
                       status == 'error' ? Colors.red : Colors.orange;
    
    return Container(
      margin: EdgeInsets.only(bottom: SpacingTokens.md),
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.extension, size: 14, color: statusColor),
              ),
              SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serverId,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          if (capabilities.isNotEmpty) ...[
            SizedBox(height: SpacingTokens.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: capabilities.map((capability) => Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  capability.toString(),
                  style: TextStyles.bodySmall.copyWith(
                    color: ThemeColors(context).primary,
                    fontSize: 9,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemoryInfo(String title, String description, String type, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: SpacingTokens.md),
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyles.bodySmall.copyWith(
                    color: ThemeColors(context).onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: TextStyles.bodySmall.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(String title, String description, String content, IconData icon) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeColors(context).border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: ThemeColors(context).primary),
              SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.md),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: ThemeColors(context).onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              content.isEmpty ? 'No instructions defined' : content,
              style: TextStyles.bodySmall.copyWith(
                color: content.isEmpty 
                  ? ThemeColors(context).onSurfaceVariant 
                  : ThemeColors(context).onSurface,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentItem(String key, String value) {
    final isSecret = key.toLowerCase().contains('key') || 
                    key.toLowerCase().contains('secret') || 
                    key.toLowerCase().contains('token');
    
    return Container(
      margin: EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeColors(context).border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isSecret ? Icons.lock : Icons.settings,
            size: 14,
            color: isSecret ? Colors.orange : ThemeColors(context).primary,
          ),
          SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  style: TextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  isSecret ? '••••••••' : value,
                  style: TextStyles.bodySmall.copyWith(
                    color: ThemeColors(context).onSurfaceVariant,
                    fontSize: 10,
                    fontFamily: isSecret ? null : 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: (isSecret ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isSecret ? 'SECRET' : 'CONFIG',
              style: TextStyles.bodySmall.copyWith(
                color: isSecret ? Colors.orange : Colors.blue,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFooter() {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ThemeColors(context).primary.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: SpacingTokens.sm),
          Text(
            'Agent context synced in real-time',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          Spacer(),
          Text(
            'Live',
            style: TextStyles.bodySmall.copyWith(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // State widgets
  Widget _buildLoadingCard() {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: SpacingTokens.sm),
          Text('Loading agent info...', style: TextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('Error loading agent', style: TextStyles.bodySmall),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: SpacingTokens.md),
          Text('Loading...', style: TextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(height: SpacingTokens.md),
          Text('Error loading data', style: TextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildNoConversationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: ThemeColors(context).onSurfaceVariant),
          SizedBox(height: SpacingTokens.md),
          Text(
            'No conversation selected',
            style: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          Text(
            'Select a conversation to see agent context',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContextState() {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          Icon(Icons.description_outlined, size: 32, color: ThemeColors(context).onSurfaceVariant),
          SizedBox(height: SpacingTokens.md),
          Text(
            'No context documents',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEnvironmentState() {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          Icon(Icons.settings_outlined, size: 32, color: ThemeColors(context).onSurfaceVariant),
          SizedBox(height: SpacingTokens.md),
          Text(
            'No environment variables',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoToolsState() {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          Icon(Icons.extension_outlined, size: 32, color: ThemeColors(context).onSurfaceVariant),
          SizedBox(height: SpacingTokens.md),
          Text(
            'No MCP tools configured',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          Text(
            'This is a basic API conversation',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}