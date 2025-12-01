import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/context/data/models/context_document.dart';
import '../../features/context/presentation/providers/context_provider.dart';
import 'context_resource_server.dart';

/// Service for exposing context documents as MCP resources
/// Following MCP specification for resources: read-only data sources
import '../../features/context/data/repositories/context_repository.dart';

/// Service for exposing context documents as MCP resources
/// Following MCP specification for resources: read-only data sources
class ContextMCPResourceService {
  final ContextRepository _repository;

  ContextMCPResourceService([ContextRepository? repository]) 
      : _repository = repository ?? ContextRepository();

  /// Convert context documents to MCP resources for an agent
  static Future<List<MCPResource>> getAgentContextResources(String agentId, Ref ref) async {
    try {
      // Get context documents assigned to this agent
      final contextDocs = await ref.read(contextForAgentProvider(agentId).future);
      
      // Convert each context document to an MCP resource
      final resources = <MCPResource>[];
      
      for (final doc in contextDocs) {
        final resource = convertContextToMCPResource(doc);
        resources.add(resource);
      }
      
      return resources;
    } catch (e) {
      print('Failed to get context resources for agent $agentId: $e');
      return [];
    }
  }

  /// Convert a single context document to MCP resource format
  static MCPResource convertContextToMCPResource(ContextDocument doc) {
    // Create URI following MCP specification
    final uri = 'context://${doc.type.name}/${doc.id}';
    
    // Determine MIME type based on context type
    final mimeType = getMimeTypeForContext(doc.type);
    
    // Create resource following MCP specification
    return MCPResource(
      uri: uri,
      title: doc.title,
      mimeType: mimeType,
      text: doc.content,
      annotations: MCPResourceAnnotations(
        audience: ['user', 'assistant'],
        priority: _getPriorityForContextType(doc.type),
        lastModified: doc.updatedAt.toIso8601String(),
        tags: doc.tags,
        contextType: doc.type.name,
        metadata: doc.metadata,
      ),
    );
  }

  /// Get MIME type based on context type
  static String getMimeTypeForContext(ContextType type) {
    switch (type) {
      case ContextType.documentation:
        return 'text/markdown';
      case ContextType.codebase:
        return 'text/plain';
      case ContextType.guidelines:
        return 'text/markdown';
      case ContextType.examples:
        return 'text/plain';
      case ContextType.knowledge:
        return 'text/plain';
      case ContextType.custom:
        return 'text/plain';
    }
  }

  /// Get priority score for different context types
  static double _getPriorityForContextType(ContextType type) {
    switch (type) {
      case ContextType.guidelines:
        return 1.0; // Highest priority - guidelines are critical
      case ContextType.documentation:
        return 0.9; // High priority - docs are important
      case ContextType.knowledge:
        return 0.8; // High priority - domain knowledge
      case ContextType.examples:
        return 0.7; // Medium priority - helpful references
      case ContextType.codebase:
        return 0.6; // Medium priority - code context
      case ContextType.custom:
        return 0.5; // Lower priority - user-defined content
    }
  }

  /// Generate MCP server configuration for context resources
  static Map<String, dynamic> generateContextResourceServerConfig(String agentId) {
    return {
      'context-resources-$agentId': {
        'command': 'node',
        'args': ['-e', _getInlineContextServer(agentId)],
        'mcpVersion': '2024-11-05',
        'transport': 'stdio',
        'capabilities': {
          'resources': true,
          'tools': false,
          'prompts': false,
          'sampling': false,
        },
        'env': {
          'AGENT_ID': agentId,
        }
      }
    };
  }

  /// Generate inline Node.js server for serving context resources
  static String _getInlineContextServer(String agentId) {
    // Import the improved server from context_resource_server.dart
    return ContextResourceServerFactory.generateServerScript(agentId);
  }

  /// Update agent MCP configuration to include context resources
  static Map<String, dynamic> addContextResourcesToAgentConfig(
    Map<String, dynamic> existingConfig,
    String agentId,
  ) {
    final contextResourceConfig = generateContextResourceServerConfig(agentId);
    
    // Merge with existing configuration
    return {
      ...existingConfig,
      ...contextResourceConfig,
    };
  }

  /// Check if agent should have context resources enabled
  static Future<bool> shouldEnableContextResources(String agentId, Ref ref) async {
    try {
      final contextDocs = await ref.read(contextForAgentProvider(agentId).future);
      return contextDocs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Assign context to agent
  Future<void> assignContextToAgent(String agentId, List<String> contextIds) async {
    for (final contextId in contextIds) {
      await _repository.assignDocumentToAgent(
        agentId: agentId,
        contextDocumentId: contextId,
      );
    }
  }

  /// Unassign context from agent
  Future<void> unassignContextFromAgent(String agentId, List<String> contextIds) async {
    final assignments = await _repository.getAssignmentsForAgent(agentId);
    for (final assignment in assignments) {
      if (contextIds.contains(assignment.contextDocumentId)) {
        await _repository.removeAssignment(assignment.id);
      }
    }
  }

  /// Get context content for documents
  Future<String> getContextForDocuments(List<String> contextIds) async {
    if (contextIds.isEmpty) return '';
    
    try {
      final documents = await _repository.getDocuments();
      final relevantDocs = documents.where((doc) => contextIds.contains(doc.id)).toList();
      
      if (relevantDocs.isEmpty) return '';
      
      final buffer = StringBuffer();
      for (final doc in relevantDocs) {
        buffer.writeln('--- Document: ${doc.title} (${doc.type.name}) ---');
        buffer.writeln(doc.content);
        buffer.writeln('--- End Document ---\n');
      }
      
      return buffer.toString();
    } catch (e) {
      print('Error fetching context documents: $e');
      return '';
    }
  }

  /// Get resource content
  Future<String> getResourceContent(String resourceId) async {
    try {
      // Handle URI format: context://type/id
      String id = resourceId;
      if (resourceId.startsWith('context://')) {
        final parts = resourceId.split('/');
        id = parts.last;
      }
      
      final documents = await _repository.getDocuments();
      final doc = documents.firstWhere(
        (d) => d.id == id, 
        orElse: () => throw Exception('Resource not found: $resourceId')
      );
      
      return doc.content;
    } catch (e) {
      print('Error fetching resource content: $e');
      return 'Error: Could not fetch content for $resourceId';
    }
  }
}

/// MCP Resource model following the official specification
class MCPResource {
  final String uri;
  final String title;
  final String mimeType;
  final String text;
  final MCPResourceAnnotations annotations;

  const MCPResource({
    required this.uri,
    required this.title,
    required this.mimeType,
    required this.text,
    required this.annotations,
  });

  Map<String, dynamic> toJson() {
    return {
      'uri': uri,
      'title': title,
      'mimeType': mimeType,
      'text': text,
      'annotations': annotations.toJson(),
    };
  }

  factory MCPResource.fromJson(Map<String, dynamic> json) {
    return MCPResource(
      uri: json['uri'] as String,
      title: json['title'] as String,
      mimeType: json['mimeType'] as String,
      text: json['text'] as String,
      annotations: MCPResourceAnnotations.fromJson(json['annotations'] as Map<String, dynamic>),
    );
  }
}

/// MCP Resource annotations following the specification
class MCPResourceAnnotations {
  final List<String> audience;
  final double priority;
  final String lastModified;
  final List<String> tags;
  final String contextType;
  final Map<String, dynamic> metadata;

  const MCPResourceAnnotations({
    required this.audience,
    required this.priority,
    required this.lastModified,
    this.tags = const [],
    required this.contextType,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'audience': audience,
      'priority': priority,
      'lastModified': lastModified,
      'tags': tags,
      'contextType': contextType,
      'metadata': metadata,
    };
  }

  factory MCPResourceAnnotations.fromJson(Map<String, dynamic> json) {
    return MCPResourceAnnotations(
      audience: List<String>.from(json['audience'] ?? []),
      priority: (json['priority'] as num?)?.toDouble() ?? 0.5,
      lastModified: json['lastModified'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      contextType: json['contextType'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Provider for context MCP resource service
final contextMCPResourceServiceProvider = Provider<ContextMCPResourceService>((ref) {
  return ContextMCPResourceService();
});