import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/context/data/models/context_document.dart';
import '../../features/context/presentation/providers/context_provider.dart';
import 'context_mcp_resource_service.dart';

/// Standalone MCP resource server for serving context documents
/// This creates a proper MCP server following the protocol specification
class ContextResourceServer {
  final String agentId;
  final WidgetRef ref;
  
  ContextResourceServer({
    required this.agentId,
    required this.ref,
  });

  /// Start the context resource server
  Future<void> start() async {
    // Listen for MCP requests on stdin
    stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleMCPRequest);
  }

  /// Handle incoming MCP requests
  Future<void> _handleMCPRequest(String line) async {
    try {
      final request = jsonDecode(line) as Map<String, dynamic>;
      final response = await _processRequest(request);
      
      // Send response to stdout
      stdout.writeln(jsonEncode(response));
    } catch (e) {
      // Send error response
      final errorResponse = _createErrorResponse(
        id: null,
        code: -32700, // Parse error
        message: 'Parse error: $e',
      );
      stdout.writeln(jsonEncode(errorResponse));
    }
  }

  /// Process MCP request and generate response
  Future<Map<String, dynamic>> _processRequest(Map<String, dynamic> request) async {
    final method = request['method'] as String?;
    final id = request['id'];
    final params = request['params'] as Map<String, dynamic>? ?? {};

    switch (method) {
      case 'initialize':
        return _handleInitialize(id, params);
      
      case 'resources/list':
        return await _handleResourcesList(id);
      
      case 'resources/read':
        return await _handleResourcesRead(id, params);
      
      case 'initialized':
        // Notification - no response needed
        return {};
      
      default:
        return _createErrorResponse(
          id: id,
          code: -32601, // Method not found
          message: 'Method not found: $method',
        );
    }
  }

  /// Handle MCP initialize request
  Map<String, dynamic> _handleInitialize(dynamic id, Map<String, dynamic> params) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'resources': {
            'subscribe': false,
            'listChanged': false,
          }
        },
        'serverInfo': {
          'name': 'context-resources-server',
          'version': '1.0.0',
        }
      }
    };
  }

  /// Handle resources/list request
  Future<Map<String, dynamic>> _handleResourcesList(dynamic id) async {
    try {
      final contextDocs = await ref.read(contextForAgentProvider(agentId).future);
      final resources = contextDocs.map(_convertToMCPResourceDescriptor).toList();
      
      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': {
          'resources': resources,
        }
      };
    } catch (e) {
      return _createErrorResponse(
        id: id,
        code: -32603, // Internal error
        message: 'Failed to list resources: $e',
      );
    }
  }

  /// Handle resources/read request
  Future<Map<String, dynamic>> _handleResourcesRead(dynamic id, Map<String, dynamic> params) async {
    try {
      final uri = params['uri'] as String?;
      if (uri == null) {
        return _createErrorResponse(
          id: id,
          code: -32602, // Invalid params
          message: 'Missing required parameter: uri',
        );
      }

      // Parse URI to extract context document ID
      final docId = _parseContextURI(uri);
      if (docId == null) {
        return _createErrorResponse(
          id: id,
          code: -32602, // Invalid params
          message: 'Invalid context URI: $uri',
        );
      }

      // Get the specific context document
      final contextDocs = await ref.read(contextForAgentProvider(agentId).future);
      final doc = contextDocs.where((d) => d.id == docId).firstOrNull;
      
      if (doc == null) {
        return _createErrorResponse(
          id: id,
          code: -32602, // Invalid params
          message: 'Context document not found: $docId',
        );
      }

      final resource = ContextMCPResourceService.convertContextToMCPResource(doc);
      
      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': {
          'contents': [
            {
              'uri': resource.uri,
              'mimeType': resource.mimeType,
              'text': resource.text,
            }
          ]
        }
      };
    } catch (e) {
      return _createErrorResponse(
        id: id,
        code: -32603, // Internal error
        message: 'Failed to read resource: $e',
      );
    }
  }

  /// Convert context document to MCP resource descriptor
  Map<String, dynamic> _convertToMCPResourceDescriptor(ContextDocument doc) {
    return {
      'uri': 'context://${doc.type.name}/${doc.id}',
      'name': doc.title,
      'description': '${doc.type.description} - ${doc.tags.join(', ')}',
      'mimeType': ContextMCPResourceService.getMimeTypeForContext(doc.type),
    };
  }

  /// Parse context URI to extract document ID
  String? _parseContextURI(String uri) {
    final contextPrefix = 'context://';
    if (!uri.startsWith(contextPrefix)) {
      return null;
    }
    
    final pathParts = uri.substring(contextPrefix.length).split('/');
    return pathParts.length >= 2 ? pathParts[1] : null;
  }

  /// Create error response following JSON-RPC 2.0 spec
  Map<String, dynamic> _createErrorResponse({
    required dynamic id,
    required int code,
    required String message,
  }) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {
        'code': code,
        'message': message,
      }
    };
  }
}

/// Factory for creating context resource servers
class ContextResourceServerFactory {
  
  /// Create and start a context resource server for an agent
  static Future<ContextResourceServer> createServer(String agentId, WidgetRef ref) async {
    final server = ContextResourceServer(
      agentId: agentId,
      ref: ref,
    );
    
    await server.start();
    return server;
  }

  /// Generate Node.js script that starts a context resource server
  static String generateServerScript(String agentId) {
    return '''
const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const http = require('http');

class ContextResourceServer {
  constructor(agentId) {
    this.agentId = agentId;
    this.server = new Server(
      {
        name: 'context-resources-server',
        version: '1.0.0',
      },
      {
        capabilities: {
          resources: {},
        },
      }
    );
    
    this.setupHandlers();
  }

  setupHandlers() {
    // Handle resource list requests
    this.server.setRequestHandler('resources/list', async () => {
      try {
        // Make HTTP request to Flutter app to get context resources
        const response = await this.fetchContextResources();
        return {
          resources: response.resources || []
        };
      } catch (error) {
        console.error('Failed to fetch context resources:', error);
        return { resources: [] };
      }
    });

    // Handle resource read requests
    this.server.setRequestHandler('resources/read', async (request) => {
      try {
        const { uri } = request.params;
        const response = await this.fetchContextResource(uri);
        return {
          contents: response.contents || []
        };
      } catch (error) {
        console.error('Failed to read context resource:', error);
        throw new Error(`Failed to read resource: \${error.message}`);
      }
    });
  }

  async fetchContextResources() {
    // In production, this would make HTTP requests to your Flutter backend
    // For now, return mock data
    return {
      resources: [
        {
          uri: `context://guidelines/\${this.agentId}-coding-standards`,
          name: 'Coding Standards',
          description: 'Team coding guidelines and best practices',
          mimeType: 'text/markdown'
        },
        {
          uri: `context://documentation/\${this.agentId}-api-docs`,
          name: 'API Documentation',
          description: 'Internal API documentation and examples',
          mimeType: 'text/markdown'
        }
      ]
    };
  }

  async fetchContextResource(uri) {
    // In production, this would fetch the actual content
    return {
      contents: [
        {
          uri: uri,
          mimeType: 'text/markdown',
          text: `# Context Resource\\n\\nThis is the content for: \${uri}\\n\\nGenerated for agent: \${this.agentId}`
        }
      ]
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
  }
}

// Start the server
const agentId = process.env.AGENT_ID || 'default';
const server = new ContextResourceServer(agentId);
server.run().catch(console.error);
''';
  }
}

/// Provider for context resource server factory
final contextResourceServerFactoryProvider = Provider<ContextResourceServerFactory>((ref) {
  return ContextResourceServerFactory();
});