import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../models/mcp_server.dart';
import '../providers/tools_provider.dart';
import 'json_syntax_highlighter.dart';
import 'dart:convert';

class MCPScriptTerminal extends ConsumerStatefulWidget {
  const MCPScriptTerminal({super.key});

  @override
  ConsumerState<MCPScriptTerminal> createState() => _MCPScriptTerminalState();
}

class _MCPScriptTerminalState extends ConsumerState<MCPScriptTerminal> {
  final TextEditingController _scriptController = TextEditingController();
  final FocusNode _scriptFocusNode = FocusNode();
  bool _isExpanded = false;
  bool _isExecuting = false;
  String? _validationError;
  final List<String> _scriptHistory = [];
  
  static const Map<String, String> _templates = {
    'Basic Server': '''
{
  "name": "My Custom Server",
  "description": "Custom MCP server description",
  "command": "node",
  "args": ["path/to/server.js"],
  "capabilities": ["tools", "resources"],
  "autoStart": true
}''',
    'Python Server': '''
{
  "name": "Python MCP Server",
  "description": "Custom Python-based MCP server",
  "command": "python",
  "args": ["-m", "my_mcp_server"],
  "capabilities": ["tools", "resources", "prompts"],
  "autoStart": false
}''',
    'File System Tool': '''
{
  "name": "File System Access",
  "description": "Read and write files and directories",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed"],
  "capabilities": ["resources", "tools"],
  "autoStart": true
}''',
    'Database Tool': '''
{
  "name": "SQLite Database",
  "description": "Query and manage SQLite databases",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-sqlite", "database.db"],
  "capabilities": ["tools", "resources"],
  "autoStart": false
}''',
    'SSE Dev Server': '''
{
  "name": "Dev Mode MCP Server",
  "description": "Server-Sent Events based MCP server for code editors",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-everything", "--port", "3001", "--transport", "sse"],
  "capabilities": ["tools", "resources", "prompts"],
  "autoStart": true,
  "category": "development",
  "version": "1.0.0"
}'''
  };

  @override
  void initState() {
    super.initState();
    _scriptController.addListener(_validateScript);
  }

  @override
  void dispose() {
    _scriptController.dispose();
    _scriptFocusNode.dispose();
    super.dispose();
  }

  void _validateScript() {
    final text = _scriptController.text.trim();
    if (text.isEmpty) {
      setState(() => _validationError = null);
      return;
    }

    try {
      final json = jsonDecode(text);
      if (json is Map<String, dynamic>) {
        // Validate required MCP server fields
        if (!json.containsKey('name') || json['name']?.toString().trim().isEmpty == true) {
          setState(() => _validationError = 'MCP server must have a non-empty "name" field');
          return;
        }
        
        if (!json.containsKey('command') || json['command']?.toString().trim().isEmpty == true) {
          setState(() => _validationError = 'MCP server must have a non-empty "command" field');
          return;
        }

        // Validate optional fields have correct types
        if (json.containsKey('description') && json['description'] is! String) {
          setState(() => _validationError = '"description" must be a string');
          return;
        }

        if (json.containsKey('args') && json['args'] is! List) {
          setState(() => _validationError = '"args" must be an array');
          return;
        } else if (json.containsKey('args')) {
          final args = json['args'] as List;
          for (final arg in args) {
            if (arg is! String) {
              setState(() => _validationError = 'All items in "args" must be strings');
              return;
            }
          }
        }

        if (json.containsKey('autoStart') && json['autoStart'] is! bool) {
          setState(() => _validationError = '"autoStart" must be a boolean (true/false)');
          return;
        }

        if (json.containsKey('capabilities') && json['capabilities'] is! List) {
          setState(() => _validationError = '"capabilities" must be an array');
          return;
        } else if (json.containsKey('capabilities')) {
          final capabilities = json['capabilities'] as List;
          for (final capability in capabilities) {
            if (capability is! String) {
              setState(() => _validationError = 'All items in "capabilities" must be strings');
              return;
            }
            // Validate capability values
            if (!['tools', 'resources', 'prompts'].contains(capability)) {
              setState(() => _validationError = 'Invalid capability "$capability". Valid options: tools, resources, prompts');
              return;
            }
          }
        }

        if (json.containsKey('version') && json['version'] is! String) {
          setState(() => _validationError = '"version" must be a string');
          return;
        }

        if (json.containsKey('category') && json['category'] is! String) {
          setState(() => _validationError = '"category" must be a string');
          return;
        }
      } else {
        setState(() => _validationError = 'JSON must be an object (enclosed in curly braces)');
        return;
      }
      
      setState(() => _validationError = null);
    } catch (e) {
      setState(() => _validationError = 'Invalid JSON format: ${e.toString()}');
    }
  }

  Future<void> _executeScript() async {
    final text = _scriptController.text.trim();
    if (text.isEmpty || _validationError != null) return;

    setState(() => _isExecuting = true);

    try {
      final json = jsonDecode(text);
      if (json is Map<String, dynamic>) {
        final server = MCPServer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: json['name'] as String,
          description: json['description'] as String? ?? 'Custom MCP server',
          command: json['command'] as String,
          args: (json['args'] as List<dynamic>?)?.cast<String>() ?? [],
          autoStart: json['autoStart'] as bool? ?? false,
          isRunning: false,
          isOfficial: false,
          version: json['version'] as String? ?? '1.0.0',
          category: json['category'] as String? ?? 'custom',
          capabilities: (json['capabilities'] as List<dynamic>?)?.cast<String>() ?? [],
        );

        // Add to tools provider
        await ref.read(toolsProvider.notifier).addCustomServer(server);

        // Add to history
        if (!_scriptHistory.contains(text)) {
          setState(() {
            _scriptHistory.insert(0, text);
            if (_scriptHistory.length > 10) {
              _scriptHistory.removeLast();
            }
          });
        }

        // Clear input
        _scriptController.clear();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('MCP server "${server.name}" created successfully'),
              backgroundColor: ThemeColors(context).success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating server: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    } finally {
      setState(() => _isExecuting = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData?.text != null) {
      _scriptController.text = clipboardData!.text!;
    }
  }

  void _loadFromHistory(String script) {
    _scriptController.text = script;
    _scriptFocusNode.requestFocus();
  }

  void _loadTemplate(String template) {
    _scriptController.text = template;
    _scriptFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AsmblCard(
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Icon(
                      Icons.terminal,
                      size: 18,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MCP Script Terminal',
                          style: TextStyles.bodyLarge.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Enter or paste MCP server configuration scripts',
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          
          // Terminal content
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: colors.border.withOpacity(0.2),
            ),
            Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Action buttons row
                  Row(
                    children: [
                      AsmblButton.secondary(
                        text: 'Paste',
                        icon: Icons.paste,
                        onPressed: _pasteFromClipboard,
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      PopupMenuButton<String>(
                        onSelected: _loadTemplate,
                        itemBuilder: (context) => _templates.entries
                            .map((entry) => PopupMenuItem(
                                  value: entry.value,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.code,
                                        size: 16,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: SpacingTokens.sm),
                                      Text(entry.key),
                                    ],
                                  ),
                                ))
                            .toList(),
                        child: AsmblButton.secondary(
                          text: 'Templates',
                          icon: Icons.snippet_folder,
                          onPressed: null,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      if (_scriptHistory.isNotEmpty)
                        PopupMenuButton<String>(
                          onSelected: _loadFromHistory,
                          itemBuilder: (context) => _scriptHistory
                              .take(5)
                              .map((script) => PopupMenuItem(
                                    value: script,
                                    child: SizedBox(
                                      width: 300,
                                      child: Text(
                                        _getScriptPreview(script),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyles.caption,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          child: AsmblButton.secondary(
                            text: 'History',
                            icon: Icons.history,
                            onPressed: null,
                          ),
                        ),
                      const Spacer(),
                      if (_validationError == null && _scriptController.text.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.sm,
                            vertical: SpacingTokens.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: colors.success,
                              ),
                              const SizedBox(width: SpacingTokens.xs),
                              Text(
                                'Valid',
                                style: TextStyles.caption.copyWith(
                                  color: colors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  
                  // Script input area with syntax highlighting preview
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Input area
                      Expanded(
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: colors.surface.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                            border: Border.all(
                              color: _validationError != null
                                  ? colors.error.withOpacity(0.5)
                                  : colors.border.withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _scriptController,
                            focusNode: _scriptFocusNode,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: TextStyles.bodySmall.copyWith(
                              fontFamily: 'monospace',
                              color: colors.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: '''Enter MCP server configuration:
{
  "name": "My Custom Server",
  "description": "Custom MCP server description",
  "command": "node",
  "args": ["path/to/server.js"],
  "autoStart": true
}''',
                              hintStyle: TextStyles.bodySmall.copyWith(
                                fontFamily: 'monospace',
                                color: colors.onSurfaceVariant.withOpacity(0.6),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(SpacingTokens.lg),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: SpacingTokens.md),
                      
                      // Syntax highlighted preview
                      Expanded(
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: colors.surface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                            border: Border.all(
                              color: colors.border.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: SpacingTokens.md,
                                  vertical: SpacingTokens.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface.withOpacity(0.2),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(BorderRadiusTokens.md),
                                    topRight: Radius.circular(BorderRadiusTokens.md),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.preview,
                                      size: 14,
                                      color: colors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: SpacingTokens.xs),
                                    Text(
                                      'Syntax Preview',
                                      style: TextStyles.caption.copyWith(
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(SpacingTokens.lg),
                                  child: JsonSyntaxHighlighter(
                                    jsonText: _scriptController.text,
                                    baseStyle: TextStyles.bodySmall.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Error message
                  if (_validationError != null) ...[
                    const SizedBox(height: SpacingTokens.sm),
                    Container(
                      padding: const EdgeInsets.all(SpacingTokens.sm),
                      decoration: BoxDecoration(
                        color: colors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: colors.error,
                          ),
                          const SizedBox(width: SpacingTokens.sm),
                          Expanded(
                            child: Text(
                              _validationError!,
                              style: TextStyles.caption.copyWith(
                                color: colors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: SpacingTokens.lg),
                  
                  // Execute button
                  AsmblButton.primary(
                    text: _isExecuting ? 'Creating Server...' : 'Create MCP Server',
                    icon: _isExecuting ? null : Icons.add_circle_outline,
                    onPressed: _isExecuting || 
                               _validationError != null || 
                               _scriptController.text.trim().isEmpty
                        ? null
                        : _executeScript,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getScriptPreview(String script) {
    try {
      final json = jsonDecode(script);
      if (json is Map<String, dynamic> && json.containsKey('name')) {
        return '${json['name']} - ${json['description'] ?? 'Custom server'}';
      }
    } catch (e) {
      // Ignore and show raw preview
    }
    return script.length > 50 ? '${script.substring(0, 47)}...' : script;
  }
}