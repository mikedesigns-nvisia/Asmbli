import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mcp_catalog_entry.dart';
import '../models/mcp_server_category.dart';
import '../utils/app_logger.dart';

/// Client for fetching MCP servers from the GitHub repository
/// Parses the README.md file since there's no official JSON API yet
class GitHubMCPRegistryClient {
  static const String _readmeUrl = 
      'https://raw.githubusercontent.com/modelcontextprotocol/servers/main/README.md';
  
  final http.Client _httpClient;
  
  GitHubMCPRegistryClient({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();

  /// Fetch all MCP servers from the GitHub registry
  Future<List<MCPCatalogEntry>> fetchServers() async {
    try {
      AppLogger.info(
        'Fetching MCP servers from GitHub registry',
        component: 'GitHubMCPRegistryClient',
      );

      final response = await _httpClient.get(Uri.parse(_readmeUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch README: HTTP ${response.statusCode}');
      }

      final readme = utf8.decode(response.bodyBytes);
      final servers = _parseReadmeContent(readme);

      AppLogger.info(
        'Successfully fetched ${servers.length} servers from GitHub',
        component: 'GitHubMCPRegistryClient',
      );

      return servers;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch servers from GitHub',
        error: e,
        component: 'GitHubMCPRegistryClient',
      );
      rethrow;
    }
  }

  /// Parse the README.md content to extract MCP server entries
  List<MCPCatalogEntry> _parseReadmeContent(String readme) {
    final servers = <MCPCatalogEntry>[];
    
    // Split by server sections (### headers)
    final lines = readme.split('\n');
    
    String? currentSection;
    final sectionBuffer = <String>[];
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Detect server entry (starts with ### and contains npm package or server name)
      if (line.startsWith('### ')) {
        // Process previous section if exists
        if (currentSection != null && sectionBuffer.isNotEmpty) {
          final entry = _parseServerSection(currentSection, sectionBuffer.join('\n'));
          if (entry != null) {
            servers.add(entry);
          }
        }
        
        // Start new section
        currentSection = line.substring(4).trim(); // Remove "### "
        sectionBuffer.clear();
      } else if (currentSection != null) {
        // Collect lines for current section until next header or category
        if (line.startsWith('##')) {
          // End of server sections, process last one
          if (sectionBuffer.isNotEmpty) {
            final entry = _parseServerSection(currentSection, sectionBuffer.join('\n'));
            if (entry != null) {
              servers.add(entry);
            }
          }
          currentSection = null;
          sectionBuffer.clear();
        } else {
          sectionBuffer.add(line);
        }
      }
    }
    
    // Process final section if exists
    if (currentSection != null && sectionBuffer.isNotEmpty) {
      final entry = _parseServerSection(currentSection, sectionBuffer.join('\n'));
      if (entry != null) {
        servers.add(entry);
      }
    }

    return servers;
  }

  /// Parse a single server section
  MCPCatalogEntry? _parseServerSection(String header, String content) {
    try {
      // Extract package name from header (e.g., "@modelcontextprotocol/server-filesystem")
      final packageName = header.trim();
      
      // Skip non-server sections
      if (!packageName.contains('server-') && !packageName.contains('/')) {
        return null;
      }

      // Extract server ID from package name
      String serverId;
      if (packageName.startsWith('@')) {
        // npm package format: @modelcontextprotocol/server-filesystem -> filesystem
        final parts = packageName.split('/');
        if (parts.length == 2) {
          serverId = parts[1].replaceAll('server-', '');
        } else {
          serverId = packageName.replaceAll('@', '').replaceAll('/', '-');
        }
      } else {
        serverId = packageName.toLowerCase().replaceAll(' ', '-');
      }

      // Extract description (first paragraph after header)
      final descriptionMatch = RegExp(r'^([^\n]+)', multiLine: true).firstMatch(content);
      final description = descriptionMatch?.group(1)?.trim() ?? 'No description available';

      // Extract npm package link
      final npmMatch = RegExp(r'\[(npm package|package)\]\((https://[^\)]+)\)').firstMatch(content);
      final npmUrl = npmMatch?.group(2);

      // Extract GitHub source link
      final sourceMatch = RegExp(r'\[source code\]\((https://[^\)]+)\)').firstMatch(content);
      final sourceUrl = sourceMatch?.group(2);

      // Determine command based on package type
      String command;
      List<String> args;
      
      if (npmUrl != null) {
        command = 'npx';
        args = ['-y', packageName];
      } else {
        // Non-npm server, might be Python, etc.
        command = 'python';
        args = ['-m', serverId];
      }

      // Extract required environment variables
      final envVars = <String, String>{};
      final envMatch = RegExp(r'Required:\s*`([^`]+)`', multiLine: true).firstMatch(content);
      if (envMatch != null) {
        final envVar = envMatch.group(1)!;
        envVars[envVar] = '';
      }

      // Determine category based on server name/description
      final category = _determineCategory(serverId, description);

      // Extract capabilities from description
      final capabilities = _extractCapabilities(content);

      return MCPCatalogEntry(
        id: serverId,
        name: _formatServerName(serverId),
        description: description,
        command: command,
        args: args,
        remoteUrl: npmUrl,
        repository: sourceUrl,
        category: category,
        transport: MCPTransportType.stdio,
        capabilities: capabilities,
        requiredEnvVars: envVars,
        optionalEnvVars: {},
        defaultEnvVars: {},
        setupInstructions: content.contains('**Configuration:**')
            ? 'See source documentation for setup'
            : null,
        tags: [if (npmUrl != null) 'npm', category.name],
        isFeatured: content.contains('🌟') || packageName.startsWith('@modelcontextprotocol/'),
        isOfficial: packageName.startsWith('@modelcontextprotocol/'),
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to parse server section: $header',
        component: 'GitHubMCPRegistryClient',
      );
      return null;
    }
  }

  /// Format server ID into a readable name
  String _formatServerName(String serverId) {
    return serverId
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Determine category based on server name and description
  MCPServerCategory _determineCategory(String serverId, String description) {
    final lowerDesc = description.toLowerCase();
    final lowerName = serverId.toLowerCase();

    if (lowerName.contains('git') || lowerName.contains('github')) {
      return MCPServerCategory.development;
    }
    if (lowerName.contains('filesystem') || lowerName.contains('file')) {
      return MCPServerCategory.fileManagement;
    }
    if (lowerName.contains('slack') || lowerName.contains('discord')) {
      return MCPServerCategory.communication;
    }
    if (lowerName.contains('postgres') || lowerName.contains('database') || lowerName.contains('sql')) {
      return MCPServerCategory.database;
    }
    if (lowerName.contains('brave') || lowerName.contains('search') || lowerName.contains('web')) {
      return MCPServerCategory.webServices;
    }
    if (lowerDesc.contains('cloud') || lowerName.contains('aws') || lowerName.contains('gcp')) {
      return MCPServerCategory.cloud;
    }
    if (lowerDesc.contains('security') || lowerDesc.contains('auth')) {
      return MCPServerCategory.security;
    }
    if (lowerDesc.contains('monitor') || lowerDesc.contains('observability')) {
      return MCPServerCategory.monitoring;
    }

    return MCPServerCategory.utility;
  }

  /// Extract capabilities from server description
  List<String> _extractCapabilities(String content) {
    final capabilities = <String>['tools']; // All MCP servers have tools

    if (content.contains('resource') || content.contains('Resource')) {
      capabilities.add('resources');
    }
    if (content.contains('prompt') || content.contains('Prompt')) {
      capabilities.add('prompts');
    }

    return capabilities;
  }

  /// Close the HTTP client
  void dispose() {
    _httpClient.close();
  }
}
