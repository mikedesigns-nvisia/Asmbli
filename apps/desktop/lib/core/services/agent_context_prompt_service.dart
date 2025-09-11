import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/context/data/models/context_document.dart';
import '../../features/context/presentation/providers/context_provider.dart';
import '../vector/models/vector_models.dart';
import 'streamlined_vector_context_service.dart';
import 'package:agent_engine_core/models/conversation.dart';

/// Service to integrate context documents into agent system prompts
/// Provides vector-enhanced prompt enhancement with contextual data
class AgentContextPromptService {
  static final AgentContextPromptService _instance = AgentContextPromptService._internal();
  factory AgentContextPromptService() => _instance;
  AgentContextPromptService._internal();

  /// Enhance a system prompt with context documents for a specific agent
  Future<String> enhancePromptWithContext(
    String basePrompt,
    String agentId,
    WidgetRef ref,
  ) async {
    try {
      final contextDocs = await ref.read(contextForAgentProvider(agentId).future);
      
      if (contextDocs.isEmpty) {
        return basePrompt;
      }

      return _buildEnhancedPrompt(basePrompt, contextDocs);
    } catch (e) {
      // If context loading fails, return base prompt
      return basePrompt;
    }
  }

  /// Enhanced version that uses vector search for relevant context based on user message
  Future<String> enhancePromptWithVectorContext(
    String basePrompt,
    String userMessage,
    String agentId,
    WidgetRef ref, {
    List<String>? sessionContextIds,
    int maxContextChunks = 5,
  }) async {
    try {
      final retrievalServiceAsync = ref.watch(streamlinedVectorContextInitializedProvider);
      
      return await retrievalServiceAsync.when(
        data: (retrievalService) async {
          // Get relevant context using vector search
          final contextResults = await retrievalService.getContextForMessage(
            userMessage,
            agentId: agentId,
            sessionContextIds: sessionContextIds,
            maxResults: maxContextChunks,
          );
          
          if (contextResults.isEmpty) {
            return basePrompt;
          }

          return _buildVectorEnhancedPrompt(basePrompt, contextResults, userMessage);
        },
        loading: () => basePrompt,
        error: (error, stack) async {
          print('⚠️ Vector service error: $error');
          // Fallback to traditional context enhancement
          return await enhancePromptWithContext(basePrompt, agentId, ref);
        },
      );
    } catch (e) {
      print('⚠️ Vector context enhancement failed: $e');
      // Fallback to traditional context enhancement
      return await enhancePromptWithContext(basePrompt, agentId, ref);
    }
  }

  /// Build enhanced prompt with vector search results
  String _buildVectorEnhancedPrompt(
    String basePrompt, 
    List<VectorSearchResult> contextResults,
    String userMessage,
  ) {
    final buffer = StringBuffer(basePrompt);
    
    buffer.writeln('\n\n## Relevant Context');
    buffer.writeln('Based on your query "$userMessage", here is the most relevant context:');
    
    // Group results by document
    final documentGroups = <String, List<VectorSearchResult>>{};
    for (final result in contextResults) {
      final docTitle = result.chunk.metadata['document_title']?.toString() ?? 'Unknown';
      documentGroups.putIfAbsent(docTitle, () => []).add(result);
    }
    
    // Add each document's relevant chunks
    for (final entry in documentGroups.entries) {
      final docTitle = entry.key;
      final results = entry.value;
      
      buffer.writeln('\n### $docTitle');
      
      // Sort by relevance
      results.sort((a, b) => b.effectiveScore.compareTo(a.effectiveScore));
      
      for (int i = 0; i < results.length && i < 3; i++) {
        final result = results[i];
        final chunk = result.chunk;
        final relevance = (result.effectiveScore * 100).toInt();
        
        buffer.writeln('\n**Context Chunk ${i + 1}** (${relevance}% relevant):');
        buffer.writeln(chunk.text.trim());
        
        // Add metadata if useful
        if (chunk.metadata.containsKey('section_type')) {
          buffer.writeln('_Type: ${chunk.metadata['section_type']}_');
        }
      }
    }
    
    // Add usage instructions
    buffer.writeln('\n### Context Usage Guidelines');
    buffer.writeln('- Use this context to provide accurate, relevant answers');
    buffer.writeln('- Reference specific examples or procedures when available');
    buffer.writeln('- If context contradicts your general knowledge, prioritize the context');
    buffer.writeln('- If the context doesn\'t contain relevant information, acknowledge this clearly');
    buffer.writeln('- Use the relevance percentages to prioritize information');
    
    return buffer.toString();
  }

  /// Build contextual message enhancement for conversations
  Future<String> buildMessageContext(
    List<Message> recentMessages,
    String agentId,
    WidgetRef ref, {
    List<String>? sessionContextIds,
    int maxMessages = 3,
  }) async {
    try {
      if (recentMessages.isEmpty) return '';
      
      // Extract key topics from recent messages
      final userMessages = recentMessages
          .where((msg) => msg.role == MessageRole.user)
          .take(maxMessages)
          .map((msg) => msg.content)
          .toList();
      
      if (userMessages.isEmpty) return '';
      
      // Combine recent messages for context search
      final combinedQuery = userMessages.join(' ');
      
      final retrievalServiceAsync = ref.watch(streamlinedVectorContextInitializedProvider);
      
      return await retrievalServiceAsync.when(
        data: (retrievalService) async {
          final contextResults = await retrievalService.getContextForMessage(
            combinedQuery,
          agentId: agentId,
          sessionContextIds: sessionContextIds,
          maxResults: 3,
        );
        
        if (contextResults.isEmpty) return '';
        
        // Build concise context summary
        final buffer = StringBuffer();
        buffer.writeln('## Conversation Context');
        
        final seenDocuments = <String>{};
        for (final result in contextResults) {
          final docTitle = result.chunk.metadata['document_title']?.toString() ?? 'Unknown';
          if (!seenDocuments.contains(docTitle)) {
            seenDocuments.add(docTitle);
            final snippet = result.chunk.text.length > 150 
                ? '${result.chunk.text.substring(0, 150)}...'
                : result.chunk.text;
            buffer.writeln('\n**$docTitle**: $snippet');
          }
        }
        
          return buffer.toString();
        },
        loading: () => '',
        error: (error, stack) => '',
      );
      
    } catch (e) {
      print('⚠️ Message context building failed: $e');
      return '';
    }
  }

  /// Get context statistics for debugging
  Future<Map<String, dynamic>> getContextStats(
    String agentId,
    WidgetRef ref, {
    List<String>? sessionContextIds,
  }) async {
    try {
      final retrievalServiceAsync = ref.watch(streamlinedVectorContextInitializedProvider);
      
      return await retrievalServiceAsync.when(
        data: (retrievalService) async {
          final stats = await retrievalService.getStats();
          return {
            'totalContextDocuments': stats['context_documents_ingested'] ?? 0,
            'availableChunks': stats['total_chunks'] ?? 0,
            'agent_id': agentId,
            'session_context_count': sessionContextIds?.length ?? 0,
          };
        },
        loading: () => {
          'error': 'Vector context retrieval service loading',
          'totalContextDocuments': 0,
          'availableChunks': 0,
        },
        error: (error, stack) => {
          'error': error.toString(),
          'totalContextDocuments': 0,
          'availableChunks': 0,
        },
      );
    } catch (e) {
      return {
        'error': e.toString(),
        'agent_id': agentId,
        'session_context_count': sessionContextIds?.length ?? 0,
      };
    }
  }

  /// Build an enhanced prompt with organized context sections
  String _buildEnhancedPrompt(String basePrompt, List<ContextDocument> contextDocs) {
    final buffer = StringBuffer(basePrompt);
    
    // Add context section
    buffer.writeln('\n\n## Knowledge & Context');
    buffer.writeln('You have access to the following specialized knowledge and examples:');
    
    // Group context by type
    final groupedContext = _groupContextByType(contextDocs);
    
    // Add each context type section
    for (final entry in groupedContext.entries) {
      buffer.writeln('\n### ${_getContextTypeTitle(entry.key)}');
      
      for (final doc in entry.value) {
        buffer.writeln(_formatContextDocument(doc));
      }
    }
    
    // Add usage instructions
    buffer.writeln('\n### Usage Instructions');
    buffer.writeln('- Reference this context when it\'s relevant to user questions');
    buffer.writeln('- Use examples to guide your response style and format');
    buffer.writeln('- Apply procedures and guidelines consistently');
    buffer.writeln('- If context conflicts with user requests, ask for clarification');
    
    return buffer.toString();
  }

  /// Group context documents by type for better organization
  Map<ContextType, List<ContextDocument>> _groupContextByType(List<ContextDocument> docs) {
    final grouped = <ContextType, List<ContextDocument>>{};
    
    for (final doc in docs) {
      grouped.putIfAbsent(doc.type, () => []).add(doc);
    }
    
    return grouped;
  }

  /// Get user-friendly title for context type
  String _getContextTypeTitle(ContextType type) {
    switch (type) {
      case ContextType.knowledge:
        return 'Knowledge Base';
      case ContextType.examples:
        return 'Examples & Templates';
      case ContextType.guidelines:
        return 'Guidelines & Procedures';
      case ContextType.documentation:
        return 'Documentation';
      case ContextType.codebase:
        return 'Codebase';
      case ContextType.custom:
        return 'Custom';
    }
  }

  /// Format a context document for inclusion in the prompt
  String _formatContextDocument(ContextDocument doc) {
    final buffer = StringBuffer();
    
    buffer.writeln('\n**${doc.title}**');
    if (doc.metadata.containsKey('description') && doc.metadata['description'].toString().isNotEmpty) {
      buffer.writeln('${doc.metadata['description']}');
    }
    
    // Include content summary or key excerpts
    if (doc.content.isNotEmpty) {
      final truncatedContent = _truncateContent(doc.content, 500);
      buffer.writeln('```');
      buffer.writeln(truncatedContent);
      buffer.writeln('```');
    }
    
    return buffer.toString();
  }

  /// Truncate content to prevent prompt from becoming too long
  String _truncateContent(String content, int maxLength) {
    if (content.length <= maxLength) {
      return content;
    }
    
    return '${content.substring(0, maxLength)}...\n[Content truncated - full document available in context]';
  }

  /// Generate MCP-specific context instructions
  String generateMCPContextInstructions(List<String> mcpServers) {
    if (mcpServers.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n## MCP Server Integration');
    buffer.writeln('You have access to the following MCP servers for enhanced capabilities:');
    
    for (final server in mcpServers) {
      buffer.writeln('- **$server**: ${_getMCPServerDescription(server)}');
    }
    
    buffer.writeln('\n**MCP Usage Guidelines:**');
    buffer.writeln('- Use MCP servers to access real-time data and perform actions');
    buffer.writeln('- Combine MCP capabilities with your context knowledge');
    buffer.writeln('- Always explain when you\'re using external tools or data sources');
    
    return buffer.toString();
  }

  /// Get description for known MCP servers
  String _getMCPServerDescription(String server) {
    switch (server.toLowerCase()) {
      case 'filesystem':
        return 'Read and write files, manage directories';
      case 'memory':
        return 'Store and retrieve information across conversations';
      case 'brave-search':
        return 'Search the web for current information';
      case 'github':
        return 'Interact with GitHub repositories and issues';
      case 'postgres':
        return 'Query and manage PostgreSQL databases';
      case 'python':
        return 'Execute Python code and scripts';
      case 'jupyter':
        return 'Run Jupyter notebooks and data analysis';
      case 'slack':
        return 'Send messages and interact with Slack';
      case 'jira':
        return 'Manage Jira tickets and projects';
      default:
        return 'Enhanced functionality and integrations';
    }
  }

  /// Create context-aware system prompt for new agents
  String createContextAwarePrompt({
    required String agentName,
    required String agentDescription,
    required String personality,
    required String expertise,
    required List<String> capabilities,
    required List<String> mcpServers,
    List<ContextDocument> contextDocs = const [],
  }) {
    final buffer = StringBuffer();
    
    // Base agent identity
    buffer.writeln('You are $agentName, an AI assistant specialized in $expertise.');
    buffer.writeln('\n**Your Role:** $agentDescription');
    buffer.writeln('**Personality:** $personality');
    
    // Capabilities
    if (capabilities.isNotEmpty) {
      buffer.writeln('\n**Your Capabilities:**');
      for (final capability in capabilities) {
        buffer.writeln('- $capability');
      }
    }
    
    // Add context if available
    if (contextDocs.isNotEmpty) {
      buffer.write(_buildEnhancedPrompt('', contextDocs));
    }
    
    // Add MCP instructions
    if (mcpServers.isNotEmpty) {
      buffer.write(generateMCPContextInstructions(mcpServers));
    }
    
    // Final guidelines
    buffer.writeln('\n## Response Guidelines');
    buffer.writeln('- Be helpful, accurate, and consistent with your expertise');
    buffer.writeln('- Use your knowledge base and context to provide detailed responses');
    buffer.writeln('- Ask clarifying questions when needed');
    buffer.writeln('- Explain your reasoning and sources when appropriate');
    
    return buffer.toString();
  }
}

/// Provider for the context prompt service
final agentContextPromptServiceProvider = Provider<AgentContextPromptService>((ref) {
  return AgentContextPromptService();
});