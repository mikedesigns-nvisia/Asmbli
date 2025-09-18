import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../providers/conversation_provider.dart';
import '../../../context/presentation/providers/context_provider.dart';
import '../../../context/data/models/context_document.dart';
import '../../../context/data/repositories/context_repository.dart';
import '../../../../core/vector/models/vector_models.dart';
import '../../../../core/utils/file_validation_utils.dart';
import '../../../../core/services/desktop/desktop_service_provider.dart';
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
  final List<String> _sessionContextIds = [];
  
  // Vector search state
  final TextEditingController _searchController = TextEditingController();
  List<VectorSearchResult> _searchResults = [];
  bool _isSearching = false;

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
        
    // Watch context documents with vector integration
    final contextDocuments = ref.watch(contextDocumentsWithVectorProvider);
    
    // Watch vector ingestion status
    final ingestionStatus = ref.watch(contextIngestionStatusProvider);

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
            
            // Show helpful context status instead of technical vector DB info
            _buildContextStatusIndicator(theme),
            
            // Context Browser (if expanded)
            if (_showContextBrowser) ...[
              const SizedBox(height: SpacingTokens.componentSpacing),
              _buildEnhancedContextBrowser(theme, contextDocuments),
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
              color: ThemeColors(context).primary.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ThemeColors(context).primary.withOpacity( 0.3)),
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
          color: theme.colorScheme.surface.withOpacity( 0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.colorScheme.outline.withOpacity( 0.3)),
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
        color: theme.colorScheme.surface.withOpacity( 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outline.withOpacity( 0.3)),
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
                  color: ThemeColors(context).primary.withOpacity( 0.1),
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
          color: theme.colorScheme.surface.withOpacity( 0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.colorScheme.outline.withOpacity( 0.3)),
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
        color: theme.colorScheme.surface.withOpacity( 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outline.withOpacity( 0.3)),
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
            // Create a simple context representation for the UI
            final context = (
              title: contextId,
              icon: Icons.description,
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
              color: theme.colorScheme.surface.withOpacity( 0.8),
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
                    color: theme.colorScheme.surface.withOpacity( 0.8),
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
                    color: theme.colorScheme.surface.withOpacity( 0.8),
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

        // Save Template Action (only show if session context exists)
        if (_sessionContextIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showSaveAsTemplateDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: ThemeColors(context).primary.withOpacity( 0.3)),
                borderRadius: BorderRadius.circular(6),
                color: ThemeColors(context).primary.withOpacity( 0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_add,
                    size: 16,
                    color: ThemeColors(context).primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Save as Template',
                    style: GoogleFonts.fustat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ThemeColors(context).primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build user-friendly context status indicator
  Widget _buildContextStatusIndicator(ThemeData theme) {
    final hasAgentContext = false; // TODO: Get from current conversation 
    final hasSessionContext = _sessionContextIds.isNotEmpty;
    final totalContextItems = (hasAgentContext ? 1 : 0) + _sessionContextIds.length;
    
    if (totalContextItems == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity( 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.colorScheme.outline.withOpacity( 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 12,
              color: ThemeColors(context).primary.withOpacity( 0.7),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '💡 Add documents to help your assistant understand your needs',
                style: GoogleFonts.fustat(
                  fontSize: 10,
                  color: ThemeColors(context).primary.withOpacity( 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Show encouraging context status
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ThemeColors(context).primary.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ThemeColors(context).primary.withOpacity( 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 12,
            color: ThemeColors(context).primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              totalContextItems == 1 
                ? '✨ Your assistant has context to help you'
                : '✨ Your assistant has $totalContextItems sources of context',
              style: GoogleFonts.fustat(
                fontSize: 10,
                color: ThemeColors(context).primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build enhanced context browser with vector search
  Widget _buildEnhancedContextBrowser(ThemeData theme, AsyncValue<List<ContextDocument>> contextDocs) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity( 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity( 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Browser Header with Vector Search
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outline.withOpacity( 0.3)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.search, size: 16, color: ThemeColors(context).primary),
                    const SizedBox(width: 8),
                    Text(
                      'Vector Search',
                      style: GoogleFonts.fustat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    // Quick template access
                    GestureDetector(
                      onTap: _showTemplateSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ThemeColors(context).primary.withOpacity( 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark,
                              size: 12,
                              color: ThemeColors(context).primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Templates',
                              style: GoogleFonts.fustat(
                                fontSize: 10,
                                color: ThemeColors(context).primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search context...',
                    hintStyle: GoogleFonts.fustat(fontSize: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search, size: 16),
                            onPressed: () => _performVectorSearch(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                  ),
                  style: GoogleFonts.fustat(fontSize: 11),
                  onSubmitted: (_) => _performVectorSearch(),
                ),
              ],
            ),
          ),
          
          // Search Results or Document List
          Expanded(
            child: _buildSearchResults(theme, contextDocs),
          ),
        ],
      ),
    );
  }

  /// Build search results area
  Widget _buildSearchResults(ThemeData theme, AsyncValue<List<ContextDocument>> contextDocs) {
    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          final chunk = result.chunk;
          final title = chunk.metadata['document_title']?.toString() ?? 'Unknown';
          final snippet = chunk.text.length > 100
              ? '${chunk.text.substring(0, 100)}...'
              : chunk.text;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity( 0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: theme.colorScheme.outline.withOpacity( 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.fustat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ThemeColors(context).primary,
                        ),
                      ),
                    ),
                    Text(
                      '${(result.similarity * 100).toInt()}%',
                      style: GoogleFonts.fustat(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  snippet,
                  style: GoogleFonts.fustat(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chunk ${chunk.chunkIndex + 1}/${chunk.totalChunks}',
                        style: GoogleFonts.fustat(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addSearchResultToSession(result),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ThemeColors(context).primary.withOpacity( 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Add',
                          style: GoogleFonts.fustat(
                            fontSize: 9,
                            color: ThemeColors(context).primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
    
    // Show context documents list when no search
    return contextDocs.when(
      data: (docs) {
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_add,
                  size: 32,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'No context documents found',
                  style: GoogleFonts.fustat(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => context.go(AppRoutes.context),
                  child: Text(
                    'Add documents',
                    style: GoogleFonts.fustat(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: doc.isActive
                    ? theme.colorScheme.surface.withOpacity( 0.3)
                    : theme.colorScheme.surface.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: doc.isActive
                      ? ThemeColors(context).primary.withOpacity( 0.3)
                      : theme.colorScheme.outline.withOpacity( 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getContextTypeIcon(doc.type),
                    size: 14,
                    color: doc.isActive ? ThemeColors(context).primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: GoogleFonts.fustat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: doc.isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          doc.type.toString().split('.').last,
                          style: GoogleFonts.fustat(
                            fontSize: 9,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (doc.isActive) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _addDocumentToSession(doc.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ThemeColors(context).primary.withOpacity( 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'Add',
                              style: GoogleFonts.fustat(
                                fontSize: 9,
                                color: ThemeColors(context).primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showDeleteDocumentConfirmation(doc),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity( 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.fustat(
                                fontSize: 9,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 32, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Failed to load documents',
              style: GoogleFonts.fustat(fontSize: 12, color: Colors.red),
            ),
            Text(
              error.toString(),
              style: GoogleFonts.fustat(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  /// Perform vector search
  Future<void> _performVectorSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final searchParams = VectorSearchParams(
        query: query,
        limit: 10,
        minSimilarity: 0.2,
        enableReranking: true,
      );
      
      final results = await ref.read(vectorSearchContextProvider(searchParams).future);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      
    } catch (e) {
      print('❌ Vector search failed: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Add search result to session context
  void _addSearchResultToSession(VectorSearchResult result) {
    final contextId = result.chunk.metadata['context_document_id']?.toString();
    if (contextId != null) {
      _addDocumentToSession(contextId);
    }
  }

  /// Add document to session context
  void _addDocumentToSession(String documentId) {
    setState(() {
      if (!_sessionContextIds.contains(documentId)) {
        _sessionContextIds.add(documentId);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.add_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Added document to session context',
                style: GoogleFonts.fustat(),
              ),
            ),
          ],
        ),
        backgroundColor: ThemeColors(context).primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Get icon for context type
  IconData _getContextTypeIcon(ContextType type) {
    switch (type) {
      case ContextType.knowledge:
        return Icons.school;
      case ContextType.examples:
        return Icons.code;
      case ContextType.guidelines:
        return Icons.rule;
      case ContextType.documentation:
        return Icons.description;
      case ContextType.codebase:
        return Icons.integration_instructions;
      case ContextType.custom:
        return Icons.edit_note;
    }
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
      builder: (context) => _buildUploadDialog(),
    );
  }

  Widget _buildUploadDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: ThemeColors(context).surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeColors(context).border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeColors(context).surface.withOpacity( 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: ThemeColors(context).border),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: ThemeColors(context).primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Context Documents',
                          style: GoogleFonts.fustat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ThemeColors(context).onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add files to your context for this conversation',
                          style: GoogleFonts.fustat(
                            fontSize: 12,
                            color: ThemeColors(context).onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildUploadContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadContent() {
    return Column(
      children: [
        // Upload area
        GestureDetector(
          onTap: _handleFileUpload,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: ThemeColors(context).primary.withOpacity( 0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: ThemeColors(context).primary.withOpacity( 0.05),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: ThemeColors(context).primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Click to browse or drag and drop',
                  style: GoogleFonts.fustat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ThemeColors(context).onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supported: PDF, TXT, MD, JSON, CSV, DOCX, RTF',
                  style: GoogleFonts.fustat(
                    fontSize: 11,
                    color: ThemeColors(context).onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quick actions
        Row(
          children: [
            Expanded(
              child: AsmblButton.secondary(
                text: 'Browse Files',
                icon: Icons.folder_open,
                onPressed: _handleFileUpload,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AsmblButton.secondary(
                text: 'Text Input',
                icon: Icons.text_fields,
                onPressed: _showTextInputDialog,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Info text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ThemeColors(context).primary.withOpacity( 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: ThemeColors(context).primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Uploaded documents will be processed and available as context for this conversation only.',
                  style: GoogleFonts.fustat(
                    fontSize: 11,
                    color: ThemeColors(context).primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Handle file upload from picker
  Future<void> _handleFileUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'json', 'csv', 'docx', 'doc', 'rtf', 'xml'],
        dialogTitle: 'Select Context Documents',
      );

      if (result != null && result.files.isNotEmpty) {
        // Close current dialog
        if (mounted) Navigator.of(context).pop();
        
        // Validate files
        final validationResult = FileValidationUtils.validateContextFiles(result.files);
        
        if (validationResult.isValid) {
          await _processUploadedFiles(result.files);
        } else {
          _showValidationError(validationResult.error ?? 'Validation failed');
        }
      }
    } catch (e) {
      print('❌ File picker error: $e');
      if (mounted) {
        _showError('Failed to open file picker: ${e.toString()}');
      }
    }
  }

  /// Process uploaded files and create context documents
  Future<void> _processUploadedFiles(List<PlatformFile> files) async {
    try {
      // Check if storage services are available
      final repository = ref.read(contextRepositoryProvider);
      int successCount = 0;
      
      for (final file in files) {
        if (file.bytes != null || file.path != null) {
          String content = '';
          
          try {
            // Read file content
            if (file.bytes != null) {
              content = String.fromCharCodes(file.bytes!);
            } else if (file.path != null) {
              final fileSystemService = ref.read(fileSystemServiceProvider);
              content = await fileSystemService.readFile(file.path!);
            }
            
            // Validate content is not empty
            if (content.trim().isEmpty) {
              print('⚠️ File ${file.name} has empty content');
              continue;
            }
            
            // Create context document with retry logic
            ContextDocument? document;
            int retryCount = 0;
            while (document == null && retryCount < 3) {
              try {
                document = await repository.createDocument(
                  title: file.name,
                  content: content,
                  type: _getContextTypeFromExtension(file.extension ?? ''),
                  tags: ['uploaded', 'session'],
                  metadata: {
                    'uploadedAt': DateTime.now().toIso8601String(),
                    'fileSize': file.size,
                    'fileName': file.name,
                    'fileExtension': file.extension,
                  },
                );
                
                // Add to session context
                _addDocumentToSession(document.id);
                successCount++;
                
              } catch (e) {
                retryCount++;
                print('⚠️ Attempt $retryCount failed for ${file.name}: $e');
                if (retryCount < 3) {
                  // Wait before retry
                  await Future.delayed(Duration(milliseconds: 500 * retryCount));
                } else {
                  print('❌ Failed to create document for ${file.name} after 3 attempts: $e');
                  // Show error for this specific file
                  if (mounted) {
                    _showError('Failed to process ${file.name}: Storage service not ready. Please try again.');
                  }
                }
              }
            }
            
          } catch (e) {
            print('❌ File content reading failed for ${file.name}: $e');
            if (mounted) {
              _showError('Failed to read ${file.name}: ${e.toString()}');
            }
          }
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Successfully uploaded $successCount document${successCount == 1 ? '' : 's'}',
                    style: GoogleFonts.fustat(),
                  ),
                ),
              ],
            ),
            backgroundColor: ThemeColors(context).primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ File processing error: $e');
      if (mounted) {
        _showError('Failed to process uploaded files: ${e.toString()}');
      }
    }
  }

  /// Show text input dialog for manual context creation
  void _showTextInputDialog() {
    Navigator.of(context).pop(); // Close upload dialog
    
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: ThemeColors(context).surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ThemeColors(context).border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ThemeColors(context).surface.withOpacity( 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(color: ThemeColors(context).border),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.text_fields, color: ThemeColors(context).primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Text Context',
                            style: GoogleFonts.fustat(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: ThemeColors(context).onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a custom text document for context',
                            style: GoogleFonts.fustat(
                              fontSize: 12,
                              color: ThemeColors(context).onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: ThemeColors(context).onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Title input
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Document Title',
                          hintText: 'Enter a descriptive title...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: GoogleFonts.fustat(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Content input
                      Expanded(
                        child: TextField(
                          controller: contentController,
                          maxLines: null,
                          expands: true,
                          decoration: InputDecoration(
                            labelText: 'Content',
                            hintText: 'Enter your context content here...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignLabelWithHint: true,
                          ),
                          style: GoogleFonts.fustat(),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: AsmblButton.secondary(
                              text: 'Cancel',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AsmblButton.primary(
                              text: 'Add Context',
                              onPressed: () => _createTextContext(
                                titleController.text,
                                contentController.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      titleController.dispose();
      contentController.dispose();
    });
  }

  /// Create text context document
  Future<void> _createTextContext(String title, String content) async {
    if (title.trim().isEmpty || content.trim().isEmpty) {
      _showError('Please provide both title and content');
      return;
    }
    
    try {
      final repository = ref.read(contextRepositoryProvider);
      
      final document = await repository.createDocument(
        title: title.trim(),
        content: content.trim(),
        type: ContextType.custom,
        tags: ['manual', 'session'],
        metadata: {
          'createdAt': DateTime.now().toIso8601String(),
          'source': 'manual_input',
        },
      );
      
      // Close dialog and add to session
      if (mounted) {
        Navigator.of(context).pop();
        _addDocumentToSession(document.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Text context "$title" added successfully',
                    style: GoogleFonts.fustat(),
                  ),
                ),
              ],
            ),
            backgroundColor: ThemeColors(context).primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Text context creation error: $e');
      if (mounted) {
        _showError('Failed to create text context: ${e.toString()}');
      }
    }
  }

  /// Get context type based on file extension
  ContextType _getContextTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'md':
      case 'txt':
      case 'rtf':
        return ContextType.documentation;
      case 'json':
      case 'xml':
        return ContextType.codebase;
      case 'pdf':
      case 'docx':
      case 'doc':
        return ContextType.knowledge;
      case 'csv':
        return ContextType.examples;
      default:
        return ContextType.custom;
    }
  }

  /// Show validation error
  void _showValidationError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Validation Error: $error',
                  style: GoogleFonts.fustat(),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Show error message
  void _showError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: GoogleFonts.fustat(),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Show save as template dialog
  void _showSaveAsTemplateDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    ContextType selectedType = ContextType.custom;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: ThemeColors(context).surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ThemeColors(context).border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ThemeColors(context).surface.withOpacity( 0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(color: ThemeColors(context).border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_add, color: ThemeColors(context).primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Save Session Context as Template',
                              style: GoogleFonts.fustat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: ThemeColors(context).onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a reusable template from your current session context',
                              style: GoogleFonts.fustat(
                                fontSize: 12,
                                color: ThemeColors(context).onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: ThemeColors(context).onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Template title
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Template Title *',
                            hintText: 'Enter a descriptive name for this template...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: GoogleFonts.fustat(),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Template description
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Describe when and how to use this template...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignLabelWithHint: true,
                          ),
                          style: GoogleFonts.fustat(),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Context type selection
                        Text(
                          'Template Category',
                          style: GoogleFonts.fustat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ThemeColors(context).onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: ThemeColors(context).border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ContextType>(
                              value: selectedType,
                              isExpanded: true,
                              onChanged: (ContextType? newValue) {
                                if (newValue != null) {
                                  setDialogState(() {
                                    selectedType = newValue;
                                  });
                                }
                              },
                              style: GoogleFonts.fustat(
                                color: ThemeColors(context).onSurface,
                              ),
                              items: ContextType.values.map<DropdownMenuItem<ContextType>>((ContextType type) {
                                return DropdownMenuItem<ContextType>(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getContextTypeIcon(type),
                                        size: 16,
                                        color: ThemeColors(context).primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            type.displayName,
                                            style: GoogleFonts.fustat(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            type.description,
                                            style: GoogleFonts.fustat(
                                              fontSize: 11,
                                              color: ThemeColors(context).onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Session context preview
                        Text(
                          'Documents to include in template (${_sessionContextIds.length})',
                          style: GoogleFonts.fustat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ThemeColors(context).onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: ThemeColors(context).border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _sessionContextIds.length,
                            itemBuilder: (context, index) {
                              final contextId = _sessionContextIds[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ThemeColors(context).primary.withOpacity( 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      size: 14,
                                      color: ThemeColors(context).primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        contextId,
                                        style: GoogleFonts.fustat(
                                          fontSize: 12,
                                          color: ThemeColors(context).onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: AsmblButton.secondary(
                                text: 'Cancel',
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AsmblButton.primary(
                                text: 'Save Template',
                                onPressed: () => _saveSessionAsTemplate(
                                  titleController.text,
                                  descriptionController.text,
                                  selectedType,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      titleController.dispose();
      descriptionController.dispose();
    });
  }

  /// Save session context as template
  Future<void> _saveSessionAsTemplate(String title, String description, ContextType type) async {
    if (title.trim().isEmpty) {
      _showError('Please provide a template title');
      return;
    }
    
    try {
      final repository = ref.read(contextRepositoryProvider);
      
      // Get content from all session context documents
      final sessionDocuments = <ContextDocument>[];
      for (final contextId in _sessionContextIds) {
        try {
          final docs = await repository.getDocuments();
          final doc = docs.firstWhere((d) => d.id == contextId);
          sessionDocuments.add(doc);
        } catch (e) {
          print('⚠️ Could not find document $contextId');
        }
      }
      
      if (sessionDocuments.isEmpty) {
        _showError('No valid documents found in session context');
        return;
      }
      
      // Combine all documents into a template format
      final combinedContent = _createTemplateContent(sessionDocuments);
      
      await repository.createDocument(
        title: title.trim(),
        content: combinedContent,
        type: type,
        tags: ['template', 'session-created', 'reusable'],
        metadata: {
          'createdAt': DateTime.now().toIso8601String(),
          'source': 'session_context',
          'description': description.trim(),
          'originalSessionDocuments': _sessionContextIds.length,
          'templateVersion': '1.0',
          'isTemplate': true,
        },
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bookmark_added, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Template "$title" saved successfully to context library',
                    style: GoogleFonts.fustat(),
                  ),
                ),
              ],
            ),
            backgroundColor: ThemeColors(context).primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => context.go(AppRoutes.context),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Template save error: $e');
      if (mounted) {
        _showError('Failed to save template: ${e.toString()}');
      }
    }
  }

  /// Create combined template content from session documents
  String _createTemplateContent(List<ContextDocument> documents) {
    final buffer = StringBuffer();
    
    // Template header
    buffer.writeln('# Session Context Template');
    buffer.writeln('');
    buffer.writeln('> This template was created from a chat session context.');
    buffer.writeln('> It contains ${documents.length} document${documents.length == 1 ? '' : 's'} that were used together.');
    buffer.writeln('');
    
    // Table of contents
    buffer.writeln('## Contents');
    for (int i = 0; i < documents.length; i++) {
      final doc = documents[i];
      buffer.writeln('${i + 1}. [${doc.title}](#${_sanitizeAnchor(doc.title)})');
    }
    buffer.writeln('');
    
    // Individual document sections
    for (int i = 0; i < documents.length; i++) {
      final doc = documents[i];
      
      buffer.writeln('---');
      buffer.writeln('');
      buffer.writeln('## ${doc.title}');
      buffer.writeln('');
      buffer.writeln('**Type:** ${doc.type.displayName}');
      if (doc.tags.isNotEmpty) {
        buffer.writeln('**Tags:** ${doc.tags.join(', ')}');
      }
      if (doc.metadata['source'] != null) {
        buffer.writeln('**Source:** ${doc.metadata['source']}');
      }
      buffer.writeln('');
      
      // Add document content
      buffer.writeln(doc.content);
      buffer.writeln('');
    }
    
    // Template footer
    buffer.writeln('---');
    buffer.writeln('');
    buffer.writeln('## Usage Notes');
    buffer.writeln('');
    buffer.writeln('This template combines multiple context documents that were used together in a conversation.');
    buffer.writeln('You can modify, split, or extend this content as needed for your specific use case.');
    buffer.writeln('');
    buffer.writeln('**Original session contained:**');
    for (final doc in documents) {
      buffer.writeln('- ${doc.title} (${doc.type.displayName})');
    }
    
    return buffer.toString();
  }

  /// Sanitize string for markdown anchor links
  String _sanitizeAnchor(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  /// Show template selector
  void _showTemplateSelector() async {
    try {
      final repository = ref.read(contextRepositoryProvider);
      final allDocs = await repository.getDocuments();
      
      // Filter for template documents
      final templates = allDocs.where((doc) =>
        doc.tags.contains('template') ||
        doc.metadata['isTemplate'] == true ||
        doc.tags.contains('session-created')
      ).toList();
      
      if (templates.isEmpty) {
        _showError('No templates found. Create templates by saving session context.');
        return;
      }
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: ThemeColors(context).surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ThemeColors(context).border),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ThemeColors(context).surface.withOpacity( 0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(color: ThemeColors(context).border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark, color: ThemeColors(context).primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Load Context Template',
                              style: GoogleFonts.fustat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: ThemeColors(context).onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select a template to add to your session context',
                              style: GoogleFonts.fustat(
                                fontSize: 12,
                                color: ThemeColors(context).onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: ThemeColors(context).onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Template list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      final isSessionCreated = template.tags.contains('session-created');
                      final description = template.metadata['description']?.toString() ?? '';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: ThemeColors(context).border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ThemeColors(context).primary.withOpacity( 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              isSessionCreated ? Icons.bookmark_added : _getContextTypeIcon(template.type),
                              size: 20,
                              color: ThemeColors(context).primary,
                            ),
                          ),
                          title: Text(
                            template.title,
                            style: GoogleFonts.fustat(
                              fontWeight: FontWeight.w600,
                              color: ThemeColors(context).onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: GoogleFonts.fustat(
                                    fontSize: 12,
                                    color: ThemeColors(context).onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ThemeColors(context).primary.withOpacity( 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      template.type.displayName,
                                      style: GoogleFonts.fustat(
                                        fontSize: 10,
                                        color: ThemeColors(context).primary,
                                      ),
                                    ),
                                  ),
                                  if (isSessionCreated) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity( 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Session Template',
                                        style: GoogleFonts.fustat(
                                          fontSize: 10,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _previewTemplate(template),
                                icon: const Icon(Icons.preview, size: 18),
                                tooltip: 'Preview',
                              ),
                              IconButton(
                                onPressed: () => _loadTemplate(template),
                                icon: const Icon(Icons.add_circle, size: 18),
                                tooltip: 'Add to session',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ Template selector error: $e');
      if (mounted) {
        _showError('Failed to load templates: ${e.toString()}');
      }
    }
  }

  /// Preview template content
  void _previewTemplate(ContextDocument template) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 700,
          height: 600,
          decoration: BoxDecoration(
            color: ThemeColors(context).surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ThemeColors(context).border),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeColors(context).surface.withOpacity( 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(color: ThemeColors(context).border),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.preview, color: ThemeColors(context).primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Preview: ${template.title}',
                        style: GoogleFonts.fustat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ThemeColors(context).onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: ThemeColors(context).onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content preview
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      template.content,
                      style: GoogleFonts.fustat(
                        fontSize: 12,
                        color: ThemeColors(context).onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: ThemeColors(context).border),
                  ),
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    AsmblButton.secondary(
                      text: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    AsmblButton.primary(
                      text: 'Add to Session',
                      onPressed: () {
                        Navigator.of(context).pop(); // Close preview
                        Navigator.of(context).pop(); // Close template selector
                        _loadTemplate(template);
                      },
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

  /// Load template into session context
  void _loadTemplate(ContextDocument template) async {
    try {
      // Close template selector if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      _addDocumentToSession(template.id);
      
    } catch (e) {
      print('❌ Template load error: $e');
      if (mounted) {
        _showError('Failed to load template: ${e.toString()}');
      }
    }
  }
  
  /// Show delete document confirmation dialog
  void _showDeleteDocumentConfirmation(ContextDocument doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors(context).surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Delete Context Document',
          style: GoogleFonts.fustat(
            fontWeight: FontWeight.w600,
            color: ThemeColors(context).onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${doc.title}"? This action cannot be undone.',
          style: GoogleFonts.fustat(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.fustat(
                color: ThemeColors(context).onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog
              
              try {
                final deleteAction = ref.read(deleteContextDocumentActionProvider);
                await deleteAction(doc.id);
                
                // Remove from session context if present
                setState(() {
                  _sessionContextIds.remove(doc.id);
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Context document "${doc.title}" deleted',
                              style: GoogleFonts.fustat(),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: ThemeColors(context).primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Failed to delete document: $e',
                              style: GoogleFonts.fustat(),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.fustat(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

