import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../providers/conversation_provider.dart';
import '../../../context/data/sample_context_data.dart';
import '../../../context/presentation/widgets/context_hub_widget.dart';
import '../../../context/data/models/context_document.dart';
import 'package:agent_engine_core/models/conversation.dart';

/// Robust context document management section for chat sidebar
/// Separates agent context (built-in) from session context (temporary)
class ContextSidebarSection extends ConsumerStatefulWidget {
  const ContextSidebarSection({super.key});

  @override
  ConsumerState<ContextSidebarSection> createState() => _ContextSidebarSectionState();
}

class _ContextSidebarSectionState extends ConsumerState<ContextSidebarSection> {
  bool _isExpanded = true;
  bool _showContextBrowser = false;
  List<SampleContext> _availableContexts = [];
  final List<String> _sessionContextIds = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableContexts();
  }

  void _loadAvailableContexts() {
    setState(() {
      _availableContexts = SampleContextData.getAllSamples();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedConversationId = ref.watch(selectedConversationIdProvider);
    
    // Get current conversation to determine active agent context
    final currentConversation = selectedConversationId != null 
        ? ref.watch(conversationProvider(selectedConversationId)).when(
            data: (conversation) => conversation,
            loading: () => null,
            error: (_, __) => null,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _buildSectionHeader(theme, currentConversation),
          
          if (_isExpanded) ...[
            const SizedBox(height: SpacingTokens.componentSpacing),
            
            // Agent Context (Built-in from agent configuration)
            if (currentConversation?.metadata?['type'] == 'agent') ...[
              _buildAgentContextSection(theme, currentConversation!),
              const SizedBox(height: SpacingTokens.componentSpacing),
            ],
            
            // Session Context (Available for both agent and direct API conversations)
            _buildSessionContextSection(theme, selectedConversationId, currentConversation),
            
            const SizedBox(height: SpacingTokens.componentSpacing),
            
            // Context Actions
            _buildContextActions(theme),
            
            // Context Browser (if expanded)
            if (_showContextBrowser) ...[
              const SizedBox(height: SpacingTokens.componentSpacing),
              _buildContextBrowser(theme),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, Conversation? currentConversation) {
    final hasContext = (currentConversation?.metadata?['contextDocuments'] as List?)?.isNotEmpty == true ||
                     _sessionContextIds.isNotEmpty;
                     
    return Row(
      children: [
        Icon(
          Icons.library_books,
          size: 16,
          color: hasContext ? ThemeColors(context).primary : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: SpacingTokens.iconSpacing),
        Expanded(
          child: Text(
            'Context Documents',
            style: GoogleFonts.fustat(
                            fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasContext ? ThemeColors(context).primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        // Context count badge
        if (hasContext) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ThemeColors(context).primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${((currentConversation?.metadata?['contextDocuments'] as List?)?.length ?? 0) + _sessionContextIds.length}',
              style: GoogleFonts.fustat(
                                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: ThemeColors(context).primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            minimumSize: const Size(24, 24),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildAgentContextSection(ThemeData theme, Conversation conversation) {
    final agentContextDocs = conversation.metadata?['contextDocuments'] as List<dynamic>? ?? [];
    final agentName = conversation.metadata?['agentName'] ?? 'Agent';
    
    if (agentContextDocs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$agentName Context',
                    style: GoogleFonts.fustat(
                                            fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'No built-in context documents configured',
              style: GoogleFonts.fustat(
                                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                size: 16,
                color: ThemeColors(context).primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$agentName Context',
                      style: GoogleFonts.fustat(
                                                fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Built-in agent knowledge',
                      style: GoogleFonts.fustat(
                                                fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${agentContextDocs.length}',
                  style: GoogleFonts.fustat(
                                        fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors(context).primary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Show first few agent context documents
          ...agentContextDocs.take(3).map<Widget>((doc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: ThemeColors(context).primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.description, size: 12, color: ThemeColors(context).primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      doc.toString(),
                      style: GoogleFonts.fustat(
                                                fontSize: 11,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          
          if (agentContextDocs.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 2),
              child: Text(
                '+ ${agentContextDocs.length - 3} more documents',
                style: GoogleFonts.fustat(
                                    fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionContextSection(ThemeData theme, String? conversationId, Conversation? conversation) {
    if (_sessionContextIds.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Session Context',
                    style: GoogleFonts.fustat(
                                            fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              conversation?.metadata?['type'] == 'agent' 
                  ? 'Add extra documents for this conversation'
                  : 'Add context documents to enhance AI understanding',
              style: GoogleFonts.fustat(
                                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Context',
                      style: GoogleFonts.fustat(
                                                fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Temporary for this conversation',
                      style: GoogleFonts.fustat(
                                                fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '(${_sessionContextIds.length})',
                style: GoogleFonts.fustat(
                                    fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Show session context documents
          ..._sessionContextIds.map<Widget>((contextId) {
            final context = _availableContexts.firstWhere(
              (ctx) => ctx.title == contextId,
              orElse: () => SampleContext(
                title: contextId,
                description: 'Custom document',
                content: '',
                contextType: ContextType.custom,
                category: ContextHubCategory.templates,
                tags: [],
                icon: Icons.description,
              ),
            );
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(context.icon, size: 12, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.title,
                      style: GoogleFonts.fustat(
                                                fontSize: 11,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _removeSessionContext(contextId),
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContextActions(ThemeData theme) {
    return Column(
      children: [
        // Primary Action: Add Context
        InkWell(
          onTap: () => setState(() => _showContextBrowser = !_showContextBrowser),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(6),
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
            ),
            child: Row(
              children: [
                Icon(
                  _showContextBrowser ? Icons.expand_less : Icons.library_add,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: SpacingTokens.iconSpacing),
                Text(
                  _showContextBrowser ? 'Hide Context Library' : 'Add Context',
                  style: GoogleFonts.fustat(
                                        fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (!_showContextBrowser)
                  Icon(
                    Icons.add,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Secondary Actions Row
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showUploadDialog(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(6),
                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Upload',
                        style: GoogleFonts.fustat(
                                                    fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(6),
                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.explore,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Browse',
                        style: GoogleFonts.fustat(
                                                    fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContextBrowser(ThemeData theme) {
    const categories = ContextHubCategory.values;
    
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Browser Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.library_books, size: 16, color: ThemeColors(context).primary),
                const SizedBox(width: 8),
                Text(
                  'Context Library',
                  style: GoogleFonts.fustat(
                                        fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // Categories List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final categoryContexts = _availableContexts
                    .where((ctx) => ctx.category == category)
                    .take(3)
                    .toList();
                
                if (categoryContexts.isEmpty) return const SizedBox.shrink();
                
                return _buildCategorySection(theme, category, categoryContexts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ThemeData theme, ContextHubCategory category, List<SampleContext> contexts) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.displayName,
            style: GoogleFonts.fustat(
                            fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          
          ...contexts.map((ctx) {
            final isAdded = _sessionContextIds.contains(ctx.title);
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: GestureDetector(
                onTap: () => isAdded ? _removeSessionContext(ctx.title) : _addSessionContext(ctx.title),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAdded 
                        ? ThemeColors(context).success.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isAdded 
                        ? Border.all(color: ThemeColors(context).success.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAdded ? Icons.check_circle : ctx.icon,
                        size: 12,
                        color: isAdded 
                            ? ThemeColors(context).success 
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ctx.title,
                          style: GoogleFonts.fustat(
                                                        fontSize: 10,
                            color: isAdded 
                                ? ThemeColors(context).success
                                : theme.colorScheme.onSurface,
                            fontWeight: isAdded ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _addSessionContext(String contextId) {
    setState(() {
      if (!_sessionContextIds.contains(contextId)) {
        _sessionContextIds.add(contextId);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.add_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Added "$contextId" to session context',
              style: GoogleFonts.fustat(),
            ),
          ],
        ),
        backgroundColor: ThemeColors(context).success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeSessionContext(String contextId) {
    setState(() {
      _sessionContextIds.remove(contextId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.remove_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Removed "$contextId" from session context',
              style: GoogleFonts.fustat(),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload_file, color: ThemeColors(context).primary),
            const SizedBox(width: 8),
            const Text('Upload Documents'),
          ],
        ),
        content: const Text(
          'File upload functionality will be implemented here. This will allow you to upload your own documents to use as context.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

