import 'package:flutter/foundation.dart';

/// Service that manages system prompt generation with MCP agent identity
class AgentSystemPromptService {
  static const String _mcpAgentIdentityPrompt = '''# Agent Identity & Core Capabilities

You are an AI assistant configured as a specialized agent with access to MCP (Model Context Protocol) servers that function as your tools and capabilities. You can be referred to in an anthropomorphized way as the user's assistant - you have a distinct personality and role based on your specialization.

## Your MCP-Enabled Nature
- You have access to specific MCP servers that act as extensions of your capabilities
- These MCP servers are your "tools" - use them proactively to fulfill user requests
- You can perform actions in external systems through these MCP connections
- You maintain context and memory across interactions within your specialized domain

## Agent Interaction Guidelines
- Present yourself as a knowledgeable, capable assistant in your domain
- Be proactive in using your MCP server capabilities to help users
- Explain what tools/capabilities you're using when relevant
- Maintain consistency with your specialized role and personality
- You are not just a language model - you're an active agent with real capabilities

---

''';

  /// Gets the complete system prompt for an agent with real-time MCP integration context
  /// 
  /// [baseSystemPrompt] - The agent's specific role and instructions
  /// [agentId] - Optional agent ID to determine if MCP identity should be included
  /// [mcpServers] - List of available MCP servers for this agent
  /// [mcpServerConfigs] - Configuration details for MCP servers
  /// [contextDocuments] - Available context documents
  /// [environmentTokens] - Available environment variables and tokens
  /// [includeIdentity] - Whether to include MCP identity (defaults to true)
  static String getCompleteSystemPrompt({
    required String baseSystemPrompt,
    String? agentId,
    List<String>? mcpServers,
    Map<String, dynamic>? mcpServerConfigs,
    List<String>? contextDocuments,
    Map<String, String>? environmentTokens,
    bool includeIdentity = true,
  }) {
    // Skip MCP identity for default API agents or when explicitly disabled
    if (!includeIdentity || agentId == 'default-api' || agentId?.startsWith('default') == true) {
      return baseSystemPrompt;
    }

    final buffer = StringBuffer(_mcpAgentIdentityPrompt);

    // Add real-time MCP server information with functional access instructions
    if (mcpServers != null && mcpServers.isNotEmpty) {
      buffer.writeln('## Your Available MCP Servers & Tools');
      buffer.writeln('You have direct access to the following MCP servers. These function as your external capabilities:');
      buffer.writeln();
      
      for (final serverId in mcpServers) {
        final config = mcpServerConfigs?[serverId] as Map<String, dynamic>?;
        final status = config?['status'] ?? 'connected';
        final description = config?['description'] ?? 'MCP server integration';
        
        buffer.writeln('### $serverId');
        buffer.writeln('- **Description**: $description');
        buffer.writeln('- **Status**: $status');
        buffer.writeln('- **Access**: Direct tool integration - use proactively when relevant');
        
        // Add server-specific capabilities and usage instructions
        final capabilities = config?['capabilities'] as List<dynamic>?;
        if (capabilities != null && capabilities.isNotEmpty) {
          buffer.writeln('- **Capabilities**:');
          for (final capability in capabilities) {
            buffer.writeln('  - $capability');
          }
        }
        
        // Add functional usage examples based on server type
        _addServerUsageInstructions(buffer, serverId, config);
        buffer.writeln();
      }
      
      buffer.writeln('**Important**: You can invoke these tools directly. They are not hypothetical - they provide real functionality.');
      buffer.writeln();
    }

    // Add context documents information
    if (contextDocuments != null && contextDocuments.isNotEmpty) {
      buffer.writeln('## Available Context Documents');
      buffer.writeln('You have access to the following context documents for enhanced responses:');
      for (final doc in contextDocuments) {
        buffer.writeln('- $doc');
      }
      buffer.writeln('Use these documents to provide more accurate and contextual responses.');
      buffer.writeln();
    }

    // Add environment tokens information (without exposing actual values)
    if (environmentTokens != null && environmentTokens.isNotEmpty) {
      buffer.writeln('## Environment Integration');
      buffer.writeln('You have access to the following environment integrations:');
      for (final key in environmentTokens.keys) {
        if (!key.toLowerCase().contains('secret') && !key.toLowerCase().contains('key')) {
          buffer.writeln('- $key: Available for integration');
        } else {
          buffer.writeln('- ${key.replaceAll(RegExp(r'(key|secret)', caseSensitive: false), '***')}: Configured');
        }
      }
      buffer.writeln('These integrations enable real-time data access and external service interactions.');
      buffer.writeln();
    }

    buffer.writeln(baseSystemPrompt);
    return buffer.toString();
  }

  /// Creates a complete system prompt for user-generated agents
  /// This ensures even custom agents get the proper MCP identity
  static String createUserAgentPrompt({
    required String userPrompt,
    required String agentName,
    List<String>? mcpServers,
  }) {
    final mcpContext = mcpServers != null && mcpServers.isNotEmpty
        ? '''

## Your Available MCP Servers
You have access to the following MCP servers as tools:
${mcpServers.map((server) => '- $server').join('\n')}

Use these tools appropriately to fulfill user requests within your specialization.

'''
        : '';

    return _mcpAgentIdentityPrompt + mcpContext + userPrompt;
  }

  /// Validates and sanitizes user-provided system prompts
  static String validateAndSanitizePrompt(String userPrompt) {
    if (userPrompt.trim().isEmpty) {
      return 'You are a helpful AI assistant.';
    }

    // Remove any existing MCP identity sections to avoid duplication
    final cleanPrompt = userPrompt
        .replaceAll(RegExp(r'# Agent Identity & Core Capabilities.*?---\s*', dotAll: true), '')
        .trim();

    return cleanPrompt.isEmpty ? 'You are a helpful AI assistant.' : cleanPrompt;
  }

  /// Detects if a prompt already contains MCP identity instructions
  static bool containsMcpIdentity(String prompt) {
    return prompt.contains('# Agent Identity & Core Capabilities') ||
           prompt.contains('MCP (Model Context Protocol)') ||
           prompt.contains('You are an AI assistant configured as a specialized agent');
  }

  /// Adds server-specific usage instructions based on server type
  static void _addServerUsageInstructions(StringBuffer buffer, String serverId, Map<String, dynamic>? config) {
    final serverName = serverId.toLowerCase();
    
    if (serverName.contains('filesystem') || serverName.contains('files')) {
      buffer.writeln('- **Usage**: Read, write, and manage files. Use for document processing, code analysis, configuration management.');
    } else if (serverName.contains('git') || serverName.contains('github')) {
      buffer.writeln('- **Usage**: Repository operations, commit history, branch management, pull requests. Essential for version control.');
    } else if (serverName.contains('search') || serverName.contains('web')) {
      buffer.writeln('- **Usage**: Real-time web searches, current information retrieval, research assistance.');
    } else if (serverName.contains('memory') || serverName.contains('knowledge')) {
      buffer.writeln('- **Usage**: Store and retrieve information across conversations. Build persistent knowledge base.');
    } else if (serverName.contains('postgres') || serverName.contains('sql') || serverName.contains('database')) {
      buffer.writeln('- **Usage**: Database queries, schema analysis, data manipulation. Direct SQL execution capability.');
    } else if (serverName.contains('slack') || serverName.contains('teams') || serverName.contains('discord')) {
      buffer.writeln('- **Usage**: Team communication, channel management, message posting, collaboration workflows.');
    } else if (serverName.contains('notion') || serverName.contains('docs')) {
      buffer.writeln('- **Usage**: Documentation management, knowledge organization, content creation and editing.');
    } else if (serverName.contains('linear') || serverName.contains('jira') || serverName.contains('project')) {
      buffer.writeln('- **Usage**: Project management, issue tracking, task assignment, workflow automation.');
    } else if (serverName.contains('figma') || serverName.contains('design')) {
      buffer.writeln('- **Usage**: Design file access, component management, prototype review, design system integration.');
    } else if (serverName.contains('python') || serverName.contains('jupyter') || serverName.contains('code')) {
      buffer.writeln('- **Usage**: Code execution, data analysis, visualization, computational tasks.');
    } else if (serverName.contains('docker') || serverName.contains('kubernetes') || serverName.contains('aws')) {
      buffer.writeln('- **Usage**: Infrastructure management, deployment automation, container orchestration.');
    } else if (serverName.contains('api') || serverName.contains('rest') || serverName.contains('graphql')) {
      buffer.writeln('- **Usage**: External API integration, data fetching, service communication.');
    } else {
      buffer.writeln('- **Usage**: Specialized tool integration - refer to server documentation for specific capabilities.');
    }
  }
}