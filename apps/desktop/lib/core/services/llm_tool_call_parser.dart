import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parses LLM responses to extract MCP tool calls
/// Supports multiple tool call formats and conventions
class LLMToolCallParser {
  static const List<String> _toolCallPatterns = [
    // Standard tool call formats
    r'<tool_call>\s*(\{.*?\})\s*</tool_call>',
    r'<function_call>\s*(\{.*?\})\s*</function_call>',
    r'<mcp_call>\s*(\{.*?\})\s*</mcp_call>',

    // JSON-based tool calls
    r'```json\s*(\{[^}]*"tool"[^}]*\})\s*```',
    r'```tool\s*(\{.*?\})\s*```',

    // Function call syntax
    r'(\w+)\((.*?)\)',

    // Structured tool call format
    r'TOOL:\s*(\w+)\s*ARGS:\s*(\{.*?\})',
    r'CALL:\s*(\w+)\s*WITH:\s*(\{.*?\})',
  ];

  /// Parse LLM response for tool calls
  static List<ParsedToolCall> parseToolCalls(String response) {
    final toolCalls = <ParsedToolCall>[];

    // Try different parsing strategies
    toolCalls.addAll(_parseStructuredToolCalls(response));
    toolCalls.addAll(_parseJsonToolCalls(response));
    toolCalls.addAll(_parseFunctionSyntaxCalls(response));
    toolCalls.addAll(_parseInlineToolCalls(response));

    return toolCalls;
  }

  /// Check if response contains any tool calls
  static bool containsToolCalls(String response) {
    return parseToolCalls(response).isNotEmpty;
  }

  /// Extract tool call intent from natural language
  static List<ToolCallIntent> extractToolCallIntents(String response) {
    final intents = <ToolCallIntent>[];
    final lowerResponse = response.toLowerCase();

    // Common tool call indicators
    final patterns = {
      'file_operations': [
        r'read\s+(?:the\s+)?file\s+([^\s]+)',
        r'write\s+to\s+(?:the\s+)?file\s+([^\s]+)',
        r'create\s+(?:a\s+)?file\s+([^\s]+)',
        r'list\s+(?:the\s+)?(?:files\s+in\s+)?(?:directory\s+)?([^\s]+)',
      ],
      'web_search': [
        r'search\s+(?:for\s+)?(.+?)(?:\s+on\s+the\s+web)?',
        r'find\s+information\s+about\s+(.+)',
        r'look\s+up\s+(.+)',
      ],
      'git_operations': [
        r'(?:git\s+)?commit\s+(?:these\s+)?changes?',
        r'(?:git\s+)?push\s+(?:to\s+)?(?:the\s+)?(?:remote\s+)?(?:repository)?',
        r'(?:git\s+)?status',
        r'(?:git\s+)?log',
      ],
      'database_query': [
        r'query\s+(?:the\s+)?database\s+for\s+(.+)',
        r'select\s+(.+?)\s+from\s+(.+)',
        r'find\s+(?:all\s+)?(.+?)\s+in\s+(?:the\s+)?database',
      ],
    };

    for (final category in patterns.keys) {
      for (final pattern in patterns[category]!) {
        final regex = RegExp(pattern, caseSensitive: false);
        final matches = regex.allMatches(response);

        for (final match in matches) {
          final args = <String>[];
          for (int i = 1; i <= match.groupCount; i++) {
            final group = match.group(i);
            if (group != null) args.add(group.trim());
          }

          intents.add(ToolCallIntent(
            category: category,
            action: _extractActionFromPattern(pattern),
            arguments: args,
            confidence: _calculateConfidence(match, response),
            originalText: match.group(0) ?? '',
          ));
        }
      }
    }

    return intents;
  }

  // Private parsing methods

  static List<ParsedToolCall> _parseStructuredToolCalls(String response) {
    final toolCalls = <ParsedToolCall>[];

    // Look for structured tool call blocks
    final patterns = [
      RegExp(r'<tool_call>\s*(\{.*?\})\s*</tool_call>', dotAll: true),
      RegExp(r'<function_call>\s*(\{.*?\})\s*</function_call>', dotAll: true),
      RegExp(r'<mcp_call>\s*(\{.*?\})\s*</mcp_call>', dotAll: true),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(response);
      for (final match in matches) {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            final toolCall = _parseToolCallFromJson(json, match.start);
            if (toolCall != null) {
              toolCalls.add(toolCall);
            }
          } catch (e) {
            // Ignore invalid JSON
          }
        }
      }
    }

    return toolCalls;
  }

  static List<ParsedToolCall> _parseJsonToolCalls(String response) {
    final toolCalls = <ParsedToolCall>[];

    // Look for JSON code blocks that might contain tool calls
    final jsonPattern = RegExp(r'```(?:json)?\s*(\{.*?\})\s*```', dotAll: true);
    final matches = jsonPattern.allMatches(response);

    for (final match in matches) {
      final jsonStr = match.group(1);
      if (jsonStr != null) {
        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;

          // Check if this looks like a tool call
          if (json.containsKey('tool') || json.containsKey('function') ||
              json.containsKey('name') || json.containsKey('action')) {
            final toolCall = _parseToolCallFromJson(json, match.start);
            if (toolCall != null) {
              toolCalls.add(toolCall);
            }
          }
        } catch (e) {
          // Ignore invalid JSON
        }
      }
    }

    return toolCalls;
  }

  static List<ParsedToolCall> _parseFunctionSyntaxCalls(String response) {
    final toolCalls = <ParsedToolCall>[];

    // Look for function call syntax: function_name(arg1, arg2)
    final functionPattern = RegExp(r'(\w+)\((.*?)\)', multiLine: true);
    final matches = functionPattern.allMatches(response);

    for (final match in matches) {
      final functionName = match.group(1);
      final argsStr = match.group(2);

      if (functionName != null && _isLikelyToolFunction(functionName)) {
        final args = _parseArgumentString(argsStr ?? '');

        toolCalls.add(ParsedToolCall(
          name: functionName,
          arguments: args,
          serverId: null, // Will be resolved later
          rawContent: match.group(0) ?? '',
          position: match.start,
          confidence: 0.7, // Medium confidence for function syntax
        ));
      }
    }

    return toolCalls;
  }

  static List<ParsedToolCall> _parseInlineToolCalls(String response) {
    final toolCalls = <ParsedToolCall>[];

    // Look for inline tool call patterns
    final patterns = [
      RegExp(r'TOOL:\s*(\w+)\s*ARGS:\s*(\{.*?\})', dotAll: true),
      RegExp(r'CALL:\s*(\w+)\s*WITH:\s*(\{.*?\})', dotAll: true),
      RegExp(r'USE:\s*(\w+)\s*\((.*?)\)', dotAll: true),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(response);
      for (final match in matches) {
        final toolName = match.group(1);
        final argsStr = match.group(2);

        if (toolName != null && argsStr != null) {
          Map<String, dynamic> args = {};

          try {
            // Try to parse as JSON first
            args = jsonDecode(argsStr) as Map<String, dynamic>;
          } catch (e) {
            // Fall back to simple string parsing
            args = _parseArgumentString(argsStr);
          }

          toolCalls.add(ParsedToolCall(
            name: toolName,
            arguments: args,
            serverId: null,
            rawContent: match.group(0) ?? '',
            position: match.start,
            confidence: 0.8,
          ));
        }
      }
    }

    return toolCalls;
  }

  static ParsedToolCall? _parseToolCallFromJson(Map<String, dynamic> json, int position) {
    final name = json['name'] as String? ??
                json['tool'] as String? ??
                json['function'] as String? ??
                json['action'] as String?;

    if (name == null) return null;

    final arguments = json['arguments'] as Map<String, dynamic>? ??
                     json['args'] as Map<String, dynamic>? ??
                     json['parameters'] as Map<String, dynamic>? ??
                     json['params'] as Map<String, dynamic>? ??
                     {};

    final serverId = json['server_id'] as String? ??
                    json['serverId'] as String? ??
                    json['server'] as String?;

    return ParsedToolCall(
      name: name,
      arguments: arguments,
      serverId: serverId,
      rawContent: jsonEncode(json),
      position: position,
      confidence: 0.9, // High confidence for structured JSON
    );
  }

  static bool _isLikelyToolFunction(String functionName) {
    final commonToolFunctions = {
      'read_file', 'write_file', 'list_files', 'create_file', 'delete_file',
      'search_web', 'fetch_url', 'web_search',
      'git_commit', 'git_push', 'git_status', 'git_log',
      'query_database', 'execute_sql', 'database_query',
      'send_email', 'schedule_task', 'create_calendar_event',
      'weather_forecast', 'translate_text', 'summarize_text',
    };

    return commonToolFunctions.contains(functionName.toLowerCase()) ||
           functionName.contains('_') || // snake_case is common for tools
           functionName.startsWith('mcp_');
  }

  static Map<String, dynamic> _parseArgumentString(String argsStr) {
    final args = <String, dynamic>{};

    if (argsStr.trim().isEmpty) return args;

    // Try to parse as key=value pairs
    final kvPairs = argsStr.split(',');
    int paramIndex = 0;

    for (final pair in kvPairs) {
      final trimmed = pair.trim();

      if (trimmed.contains('=')) {
        final parts = trimmed.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim().replaceAll('"', '').replaceAll("'", '');
          final value = parts.sublist(1).join('=').trim().replaceAll('"', '').replaceAll("'", '');
          args[key] = value;
        }
      } else if (trimmed.isNotEmpty) {
        // Positional argument
        args['arg_$paramIndex'] = trimmed.replaceAll('"', '').replaceAll("'", '');
        paramIndex++;
      }
    }

    return args;
  }

  static String _extractActionFromPattern(String pattern) {
    // Extract action verb from regex pattern
    if (pattern.contains('read')) return 'read';
    if (pattern.contains('write')) return 'write';
    if (pattern.contains('create')) return 'create';
    if (pattern.contains('search')) return 'search';
    if (pattern.contains('commit')) return 'commit';
    if (pattern.contains('push')) return 'push';
    if (pattern.contains('query')) return 'query';
    return 'unknown';
  }

  static double _calculateConfidence(Match match, String response) {
    double confidence = 0.5; // Base confidence

    final matchText = match.group(0)?.toLowerCase() ?? '';

    // Increase confidence for specific indicators
    if (matchText.contains('please')) confidence += 0.1;
    if (matchText.contains('could you')) confidence += 0.1;
    if (matchText.contains('can you')) confidence += 0.1;
    if (matchText.startsWith('i need')) confidence += 0.2;
    if (matchText.contains('now') || matchText.contains('immediately')) confidence += 0.1;

    // Decrease confidence for conditional language
    if (matchText.contains('maybe')) confidence -= 0.1;
    if (matchText.contains('perhaps')) confidence -= 0.1;
    if (matchText.contains('if possible')) confidence -= 0.1;

    return confidence.clamp(0.0, 1.0);
  }
}

/// Represents a parsed tool call from LLM response
class ParsedToolCall {
  final String name;
  final Map<String, dynamic> arguments;
  final String? serverId;
  final String rawContent;
  final int position;
  final double confidence;

  const ParsedToolCall({
    required this.name,
    required this.arguments,
    this.serverId,
    required this.rawContent,
    required this.position,
    required this.confidence,
  });

  @override
  String toString() => 'ParsedToolCall(name: $name, args: $arguments, server: $serverId)';
}

/// Represents extracted tool call intent from natural language
class ToolCallIntent {
  final String category;
  final String action;
  final List<String> arguments;
  final double confidence;
  final String originalText;

  const ToolCallIntent({
    required this.category,
    required this.action,
    required this.arguments,
    required this.confidence,
    required this.originalText,
  });

  @override
  String toString() => 'ToolCallIntent(category: $category, action: $action, args: $arguments)';
}

/// Provider for LLM Tool Call Parser
final llmToolCallParserProvider = Provider<LLMToolCallParser>((ref) {
  return LLMToolCallParser();
});