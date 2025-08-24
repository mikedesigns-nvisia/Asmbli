import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_settings_service.dart';

/// Dialog for adding or editing MCP server configurations
class MCPServerDialog extends ConsumerStatefulWidget {
  final MCPServerConfig? existingConfig;
  final String? serverId;
  
  const MCPServerDialog({
    super.key,
    this.existingConfig,
    this.serverId,
  });

  @override
  ConsumerState<MCPServerDialog> createState() => _MCPServerDialogState();
}

class _MCPServerDialogState extends ConsumerState<MCPServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commandController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<String> _args = [];
  Map<String, String> _envVars = {};
  bool _enabled = true;
  String? _selectedTemplate;
  bool _isLoading = false;

  // Pre-configured MCP server templates
  final Map<String, MCPServerTemplate> _templates = {
    'filesystem': MCPServerTemplate(
      name: 'Filesystem',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-filesystem'],
      description: 'Access local file system for reading and writing files',
      icon: Icons.folder,
      category: 'Storage',
      envVars: {},
      requiredPaths: ['\${HOME}/Documents', '\${HOME}/Projects'],
    ),
    'web-search': MCPServerTemplate(
      name: 'Web Search (Brave)',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-brave-search'],
      description: 'Search the web using Brave Search API',
      icon: Icons.search,
      category: 'Web',
      envVars: {'BRAVE_API_KEY': ''},
      requiredPaths: [],
    ),
    'memory': MCPServerTemplate(
      name: 'Memory',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-memory'],
      description: 'Persistent memory and knowledge management',
      icon: Icons.psychology,
      category: 'AI',
      envVars: {},
      requiredPaths: [],
    ),
    'github': MCPServerTemplate(
      name: 'GitHub',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-github'],
      description: 'GitHub repository access and management',
      icon: Icons.code,
      category: 'Development',
      envVars: {'GITHUB_PERSONAL_ACCESS_TOKEN': ''},
      requiredPaths: [],
    ),
    'git': MCPServerTemplate(
      name: 'Git',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-git'],
      description: 'Git repository operations and version control',
      icon: Icons.source,
      category: 'Development',
      envVars: {},
      requiredPaths: [],
    ),
    'postgres': MCPServerTemplate(
      name: 'PostgreSQL',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-postgres'],
      description: 'PostgreSQL database access and management',
      icon: Icons.storage,
      category: 'Database',
      envVars: {'POSTGRES_URL': 'postgresql://user:password@localhost:5432/db'},
      requiredPaths: [],
    ),
    'sqlite': MCPServerTemplate(
      name: 'SQLite',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-sqlite'],
      description: 'SQLite database access',
      icon: Icons.storage_outlined,
      category: 'Database',
      envVars: {},
      requiredPaths: ['\${HOME}/databases'],
    ),
    'custom': MCPServerTemplate(
      name: 'Custom Server',
      command: '',
      args: [],
      description: 'Configure a custom MCP server',
      icon: Icons.settings,
      category: 'Custom',
      envVars: {},
      requiredPaths: [],
    ),
  };

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.existingConfig != null) {
      final config = widget.existingConfig!;
      _nameController.text = config.name;
      _commandController.text = config.command;
      _descriptionController.text = config.description;
      _args = List.from(config.args);
      _envVars = Map.from(config.env ?? {});
      _enabled = config.enabled;
    }
  }

  void _applyTemplate(String templateId) {
    final template = _templates[templateId];
    if (template == null) return;

    setState(() {
      _selectedTemplate = templateId;
      _nameController.text = template.name;
      _commandController.text = template.command;
      _descriptionController.text = template.description;
      _args = List.from(template.args);
      _envVars = Map.from(template.envVars);
      
      // Add required paths as arguments for filesystem-based servers
      if (template.requiredPaths.isNotEmpty) {
        _args.addAll(template.requiredPaths);
      }
    });
  }

  Future<void> _saveServer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final serverId = widget.serverId ?? 
          _nameController.text.toLowerCase().replaceAll(' ', '-');

      final config = MCPServerConfig(
        id: serverId,
        name: _nameController.text.trim(),
        command: _commandController.text.trim(),
        args: _args.where((arg) => arg.trim().isNotEmpty).toList(),
        env: _envVars.isNotEmpty ? _envVars : null,
        description: _descriptionController.text.trim(),
        enabled: _enabled,
        createdAt: widget.existingConfig?.createdAt ?? DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      final mcpService = ref.read(mcpSettingsServiceProvider);
      await mcpService.setMCPServer(serverId, config);
      await mcpService.saveSettings();

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save server: $e'),
            backgroundColor: SemanticColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingConfig != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 800,
        constraints: BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: ThemeColors(context).surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(SpacingTokens.elementSpacing),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.storage,
                    size: 24,
                    color: SemanticColors.primary,
                  ),
                  SizedBox(width: SpacingTokens.componentSpacing),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit MCP Server' : 'Add MCP Server',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(SpacingTokens.elementSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Template Selection (only for new servers)
                      if (!isEdit) ...[
                        _buildTemplateSelection(),
                        SizedBox(height: SpacingTokens.sectionSpacing),
                      ],

                      // Basic Configuration
                      _buildBasicConfiguration(),

                      SizedBox(height: SpacingTokens.sectionSpacing),

                      // Command Configuration
                      _buildCommandConfiguration(),

                      SizedBox(height: SpacingTokens.sectionSpacing),

                      // Environment Variables
                      _buildEnvironmentVariables(),

                      SizedBox(height: SpacingTokens.sectionSpacing),

                      // Advanced Options
                      _buildAdvancedOptions(),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(SpacingTokens.elementSpacing),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AsmblButton.secondary(
                    text: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: SpacingTokens.componentSpacing),
                  AsmblButton.primary(
                    text: _isLoading 
                      ? 'Saving...'
                      : isEdit 
                        ? 'Update Server' 
                        : 'Add Server',
                    onPressed: _isLoading ? null : _saveServer,
                    icon: _isLoading ? Icons.hourglass_empty : Icons.save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Server Template',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: SpacingTokens.componentSpacing),
        
        // Template grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _templates.entries.map((entry) {
            final templateId = entry.key;
            final template = entry.value;
            final isSelected = _selectedTemplate == templateId;

            return GestureDetector(
              onTap: () => _applyTemplate(templateId),
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? SemanticColors.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                      ? SemanticColors.primary
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      template.icon,
                      size: 32,
                      color: isSelected 
                        ? SemanticColors.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 8),
                    Text(
                      template.name,
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                          ? SemanticColors.primary
                          : Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      template.category,
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBasicConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Configuration',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: SpacingTokens.componentSpacing),

        // Server Name
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Server Name',
            hintText: 'e.g., My Filesystem Server',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Server name is required';
            }
            return null;
          },
        ),

        SizedBox(height: SpacingTokens.componentSpacing),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Brief description of what this server provides',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 2,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Description is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCommandConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Command Configuration',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: SpacingTokens.componentSpacing),

        // Command
        TextFormField(
          controller: _commandController,
          decoration: InputDecoration(
            labelText: 'Command',
            hintText: 'uvx, python, node, etc.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Command is required';
            }
            return null;
          },
        ),

        SizedBox(height: SpacingTokens.componentSpacing),

        // Arguments
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Arguments',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _args.add(''));
                  },
                  icon: Icon(Icons.add, size: 16),
                  label: Text('Add Argument'),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            ..._args.asMap().entries.map((entry) {
              final index = entry.key;
              final arg = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: arg,
                        decoration: InputDecoration(
                          hintText: 'Argument ${index + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, 
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _args[index] = value);
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() => _args.removeAt(index));
                      },
                      icon: Icon(Icons.remove_circle, size: 20),
                      style: IconButton.styleFrom(
                        foregroundColor: SemanticColors.error,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildEnvironmentVariables() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Environment Variables',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Spacer(),
            TextButton.icon(
              onPressed: () {
                _showAddEnvVarDialog();
              },
              icon: Icon(Icons.add, size: 16),
              label: Text('Add Variable'),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.componentSpacing),

        if (_envVars.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8),
                Text(
                  'No environment variables configured',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        else
          ..._envVars.entries.map((entry) {
            final key = entry.key;
            final value = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      key,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      value.isEmpty ? '(not set)' : value,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        color: value.isEmpty 
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                        fontStyle: value.isEmpty ? FontStyle.italic : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editEnvVar(key, value),
                    icon: Icon(Icons.edit, size: 16),
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      minimumSize: Size(32, 32),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _envVars.remove(key));
                    },
                    icon: Icon(Icons.delete, size: 16),
                    style: IconButton.styleFrom(
                      foregroundColor: SemanticColors.error,
                      minimumSize: Size(32, 32),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Options',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: SpacingTokens.componentSpacing),

        // Enable/Disable Server
        Row(
          children: [
            Switch(
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
              activeColor: SemanticColors.success,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enable Server',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Server will be available for agent deployment when enabled',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddEnvVarDialog() {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors(context).surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        title: Text(
          'Add Environment Variable',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: keyController,
              decoration: InputDecoration(
                labelText: 'Variable Name',
                hintText: 'e.g., API_KEY',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: valueController,
              decoration: InputDecoration(
                labelText: 'Value',
                hintText: 'Variable value (can be set later)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final key = keyController.text.trim();
              if (key.isNotEmpty) {
                setState(() {
                  _envVars[key] = valueController.text.trim();
                });
                Navigator.of(context).pop();
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editEnvVar(String key, String currentValue) {
    final valueController = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors(context).surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        title: Text(
          'Edit $key',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextFormField(
          controller: valueController,
          decoration: InputDecoration(
            labelText: 'Value',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          obscureText: key.toLowerCase().contains('key') || 
                      key.toLowerCase().contains('token') ||
                      key.toLowerCase().contains('password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _envVars[key] = valueController.text.trim();
              });
              Navigator.of(context).pop();
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }
}

// ==================== Data Models ====================

/// MCP server template for quick setup
class MCPServerTemplate {
  final String name;
  final String command;
  final List<String> args;
  final String description;
  final IconData icon;
  final String category;
  final Map<String, String> envVars;
  final List<String> requiredPaths;

  const MCPServerTemplate({
    required this.name,
    required this.command,
    required this.args,
    required this.description,
    required this.icon,
    required this.category,
    required this.envVars,
    required this.requiredPaths,
  });
}