import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';
import '../../providers/simple_real_execution_provider.dart';

/// Simplified capabilities sidebar following Anthropic PM recommendations
/// Focuses on what the AI can help with, not technical implementation
class SimplifiedCapabilitiesSidebar extends ConsumerStatefulWidget {
  final String? selectedConversationId;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const SimplifiedCapabilitiesSidebar({
    super.key,
    this.selectedConversationId,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  ConsumerState<SimplifiedCapabilitiesSidebar> createState() => _SimplifiedCapabilitiesSidebarState();
}

class _SimplifiedCapabilitiesSidebarState extends ConsumerState<SimplifiedCapabilitiesSidebar> {
  bool _showCapabilitiesDetails = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isCollapsed ? 48 : 320,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.95),
        border: Border(
          right: BorderSide(color: colors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: widget.isCollapsed 
        ? _buildCollapsedSidebar(colors)
        : _buildExpandedSidebar(colors),
    );
  }

  Widget _buildCollapsedSidebar(ThemeColors colors) {
    return Column(
      children: [
        const SizedBox(height: SpacingTokens.lg),
        
        // AI capabilities indicator
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 16,
            color: colors.primary,
          ),
        ),
        
        const Spacer(),
        
        // Expand button
        IconButton(
          onPressed: widget.onToggleCollapse,
          icon: const Icon(Icons.chevron_right, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: colors.primary.withValues(alpha: 0.1),
            foregroundColor: colors.primary,
          ),
          tooltip: 'Show AI capabilities',
        ),
        
        const SizedBox(height: SpacingTokens.lg),
      ],
    );
  }

  Widget _buildExpandedSidebar(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(colors),
        
        // Main capabilities section
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Core AI capabilities
                _buildCapabilitiesSection(colors),
                
                const SizedBox(height: SpacingTokens.xl),
                
                // Context information (simplified)
                _buildContextSection(colors),
              ],
            ),
          ),
        ),
        
        // Footer
        _buildFooter(colors),
      ],
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What I Can Help With',
                  style: TextStyles.cardTitle.copyWith(
                    color: colors.primary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Your AI assistant\'s current abilities',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onToggleCollapse,
            icon: const Icon(Icons.chevron_left, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
            ),
            tooltip: 'Hide sidebar',
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesSection(ThemeColors colors) {
    // Get real MCP connection data
    final executionState = ref.watch(simpleExecutionProvider);
    final agentConnections = ref.watch(agentConnectionsWithStatusProvider);
    
    // Determine capabilities based on real data
    final capabilities = _getCapabilitiesFromConnections(agentConnections);
    final contextCount = _getContextCount();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'I can help you with:',
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const Spacer(),
            if (capabilities.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${capabilities.length} skills',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: SpacingTokens.md),
        
        // Capabilities list
        if (capabilities.isEmpty)
          _buildBasicCapabilities(colors)
        else
          ...capabilities.map((capability) => _buildCapabilityItem(colors, capability)),
        
        // Context indicator
        if (contextCount > 0) ...[
          const SizedBox(height: SpacingTokens.lg),
          _buildContextIndicator(colors, contextCount),
        ],
        
        // Show details toggle
        if (capabilities.isNotEmpty) ...[
          const SizedBox(height: SpacingTokens.md),
          GestureDetector(
            onTap: () => setState(() => _showCapabilitiesDetails = !_showCapabilitiesDetails),
            child: Row(
              children: [
                Icon(
                  _showCapabilitiesDetails ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  _showCapabilitiesDetails ? 'Hide details' : 'Show technical details',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Technical details (collapsed by default)
        if (_showCapabilitiesDetails && capabilities.isNotEmpty) ...[
          const SizedBox(height: SpacingTokens.md),
          _buildTechnicalDetails(colors, agentConnections),
        ],
      ],
    );
  }

  Widget _buildBasicCapabilities(ThemeColors colors) {
    final basicCapabilities = [
      CapabilityInfo(
        icon: Icons.chat_bubble_outline,
        title: 'General conversation',
        description: 'Answer questions and have discussions',
        status: 'Ready',
        color: colors.primary,
      ),
      CapabilityInfo(
        icon: Icons.lightbulb_outline,
        title: 'Problem solving',
        description: 'Help analyze problems and find solutions',
        status: 'Ready',
        color: colors.primary,
      ),
      CapabilityInfo(
        icon: Icons.edit_note,
        title: 'Writing assistance',
        description: 'Help with writing, editing, and creative tasks',
        status: 'Ready',
        color: colors.primary,
      ),
    ];

    return Column(
      children: [
        ...basicCapabilities.map((capability) => _buildCapabilityItem(colors, capability)),
        const SizedBox(height: SpacingTokens.lg),
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.rocket_launch, size: 16, color: colors.accent),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  'Connect tools to unlock more capabilities like web search, file access, and specialized skills',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilityItem(ThemeColors colors, CapabilityInfo capability) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: capability.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: capability.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              capability.icon,
              size: 16,
              color: capability.color,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capability.title,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  capability.description,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (capability.status == 'Ready')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '●',
                style: TextStyles.bodySmall.copyWith(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            )
          else if (capability.status == 'Issue')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '!',
                style: TextStyles.bodySmall.copyWith(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContextIndicator(ThemeColors colors, int contextCount) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, size: 16, color: colors.primary),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enhanced with context',
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Using $contextCount document${contextCount == 1 ? '' : 's'} for better understanding',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetails(ThemeColors colors, List<AgentConnectionWithStatus> connections) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.onSurfaceVariant.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Technical Details:',
            style: TextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          
          // Show agent connections
          ...connections.map((connection) => Container(
            margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: connection.hasActiveServers ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: SpacingTokens.xs),
                Expanded(
                  child: Text(
                    '${connection.connection.agentName} (${connection.connectedRunningServers.length}/${connection.totalConnectedServers} servers)',
                    style: TextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildContextSection(ThemeColors colors) {
    return Container(); // Simplified - context is shown inline above
  }

  Widget _buildFooter(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            'Ready to help',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Convert real MCP connection data into user-friendly capabilities
  List<CapabilityInfo> _getCapabilitiesFromConnections(List<AgentConnectionWithStatus> connections) {
    final capabilities = <CapabilityInfo>[];
    
    // Always include basic capabilities
    capabilities.add(CapabilityInfo(
      icon: Icons.chat_bubble_outline,
      title: 'Conversation',
      description: 'Answer questions and have discussions',
      status: 'Ready',
      color: ThemeColors(context).primary,
    ));

    // Add capabilities based on real MCP servers
    for (final connection in connections) {
      for (final server in connection.connectedRunningServers) {
        // Map server names to user-friendly capabilities
        final capability = _mapServerToCapability(server.id, server.name);
        if (capability != null && !capabilities.any((c) => c.title == capability.title)) {
          capabilities.add(capability);
        }
      }
    }
    
    return capabilities;
  }

  /// Map MCP server to user-friendly capability
  CapabilityInfo? _mapServerToCapability(String serverId, String serverName) {
    final colors = ThemeColors(context);
    
    // Map common server types to capabilities
    if (serverId.toLowerCase().contains('search') || serverName.toLowerCase().contains('search')) {
      return CapabilityInfo(
        icon: Icons.search,
        title: 'Web search',
        description: 'Find current information online',
        status: 'Ready',
        color: colors.accent,
      );
    }
    
    if (serverId.toLowerCase().contains('filesystem') || serverName.toLowerCase().contains('file')) {
      return CapabilityInfo(
        icon: Icons.folder_open,
        title: 'File access',
        description: 'Read and work with your files',
        status: 'Ready',
        color: Colors.blue,
      );
    }
    
    if (serverId.toLowerCase().contains('git') || serverName.toLowerCase().contains('git')) {
      return CapabilityInfo(
        icon: Icons.code,
        title: 'Code analysis',
        description: 'Review and work with code repositories',
        status: 'Ready',
        color: Colors.purple,
      );
    }
    
    if (serverId.toLowerCase().contains('database') || serverName.toLowerCase().contains('db')) {
      return CapabilityInfo(
        icon: Icons.storage,
        title: 'Database queries',
        description: 'Query and analyze database information',
        status: 'Ready',
        color: Colors.orange,
      );
    }
    
    // Generic tool capability
    return CapabilityInfo(
      icon: Icons.extension,
      title: serverName,
      description: 'Specialized tool integration',
      status: 'Ready',
      color: colors.onSurfaceVariant,
    );
  }

  /// Get context document count (simplified)
  int _getContextCount() {
    if (widget.selectedConversationId == null) return 0;
    
    final conversationAsync = ref.read(conversationProvider(widget.selectedConversationId!));
    return conversationAsync.when(
      data: (conversation) {
        final contextDocs = conversation.metadata?['contextDocuments'] as List<dynamic>? ?? [];
        return contextDocs.length;
      },
      loading: () => 0,
      error: (_, __) => 0,
    );
  }
}

/// Simple capability info model
class CapabilityInfo {
  final IconData icon;
  final String title;
  final String description;
  final String status;
  final Color color;

  CapabilityInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.color,
  });
}