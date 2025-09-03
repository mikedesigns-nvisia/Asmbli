import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import 'enhanced_auto_detection_modal.dart';
import '../../../../core/services/mcp_settings_service.dart';
import 'enhanced_mcp_server_wizard.dart';
import 'manual_mcp_server_modal.dart';
import 'custom_mcp_server_modal.dart';


import '../../../core/models/mcp_server_config.dart';

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
    'filesystem': const MCPServerTemplate(
      name: 'Filesystem',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-filesystem'],
      description: 'Access local file system for reading and writing files',
      icon: Icons.folder,
      category: 'Storage',
      envVars: {},
      requiredPaths: ['\${HOME}/Documents', '\${HOME}/Projects'],
    ),
    'web-search': const MCPServerTemplate(
      name: 'Web Search (Brave)',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-brave-search'],
      description: 'Search the web using Brave Search API',
      icon: Icons.search,
      category: 'Web',
      envVars: {'BRAVE_API_KEY': ''},
      requiredPaths: [],
    ),
    'memory': const MCPServerTemplate(
      name: 'Memory',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-memory'],
      description: 'Persistent memory and knowledge management',
      icon: Icons.psychology,
      category: 'AI',
      envVars: {},
      requiredPaths: [],
    ),
    'github': const MCPServerTemplate(
      name: 'GitHub',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-github'],
      description: 'GitHub repository access and management',
      icon: Icons.code,
      category: 'Development',
      envVars: {'GITHUB_PERSONAL_ACCESS_TOKEN': ''},
      requiredPaths: [],
    ),
    'git': const MCPServerTemplate(
      name: 'Git',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-git'],
      description: 'Git repository operations and version control',
      icon: Icons.source,
      category: 'Development',
      envVars: {},
      requiredPaths: [],
    ),
    'postgres': const MCPServerTemplate(
      name: 'PostgreSQL',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-postgres'],
      description: 'PostgreSQL database access and management',
      icon: Icons.storage,
      category: 'Database',
      envVars: {'POSTGRES_URL': 'postgresql://user:password@localhost:5432/db'},
      requiredPaths: [],
    ),
    'sqlite': const MCPServerTemplate(
      name: 'SQLite',
      command: 'uvx',
      args: ['@modelcontextprotocol/server-sqlite'],
      description: 'SQLite database access',
      icon: Icons.storage_outlined,
      category: 'Database',
      envVars: {},
      requiredPaths: ['\${HOME}/databases'],
    ),
    'custom': const MCPServerTemplate(
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

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
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

    _safeSetState(() {
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

    _safeSetState(() => _isLoading = true);

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
      if (mounted) {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  /// Handle MCP configuration added from manual/custom modals
  Future<void> _handleMCPConfigAdded(Map<String, dynamic> config) async {
    try {
      final mcpService = ref.read(mcpSettingsServiceProvider);
      
      // Extract server configuration from the config map
      // Format: {serverId: {command: "...", args: [...], env: {...}}}
      final serverId = config.keys.first;
      final serverConfig = config[serverId] as Map<String, dynamic>;
      
      // Create MCPServerConfig object
      final mcpConfig = MCPServerConfig(
        id: serverId,
        name: serverId.replaceAll('-', ' ').split(' ').map((word) => 
          word[0].toUpperCase() + word.substring(1)).join(' '),
        command: serverConfig['command'] as String? ?? '',
        args: (serverConfig['args'] as List?)?.cast<String>() ?? [],
        env: serverConfig['env'] as Map<String, String>?,
        description: 'Custom MCP server configuration',
        enabled: true,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      // Save the configuration
      await mcpService.setMCPServer(serverId, mcpConfig);
      await mcpService.saveSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MCP server "$serverId" added successfully!'),
            backgroundColor: SemanticColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add MCP server: $e'),
            backgroundColor: SemanticColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingConfig != null;

    // Show choice between wizard and quick form
    return _buildDialogChoice(context, isEdit);
  }

  Widget _buildDialogChoice(BuildContext context, bool isEdit) {
    if (isEdit) {
      // For editing, go straight to the enhanced wizard
      return EnhancedMCPServerWizard(
        existingConfig: widget.existingConfig,
        serverId: widget.serverId,
      );
    }

    // For new servers, show choice between wizard and quick setup
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          minWidth: 400,
        ),
        padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
        decoration: BoxDecoration(
          color: ThemeColors(context).surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.integration_instructions,
                  size: 28,
                  color: SemanticColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Integration',
                        style: TextStyles.sectionTitle,
                      ),
                      Text(
                        'Choose how you want to set up your integration',
                        style: TextStyles.bodyMedium.copyWith(
                          color: SemanticColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Auto-detect option at top
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SemanticColors.primary.withValues(alpha: 0.1),
                    SemanticColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: SemanticColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: SemanticColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.auto_fix_high,
                          color: SemanticColors.surface,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto-Detect Configuration',
                              style: TextStyles.titleMedium.copyWith(
                                color: SemanticColors.primary,
                              ),
                            ),
                            Text(
                              'Automatically find and configure installed tools',
                              style: TextStyles.bodyMedium.copyWith(
                                color: SemanticColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AsmblButton.primary(
                    text: 'Start Detection',
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (context) => EnhancedAutoDetectionModal(
                          onComplete: () {},
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Divider with "OR" text
            Row(
              children: [
                const Expanded(child: Divider(color: SemanticColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyles.labelSmall.copyWith(
                      color: SemanticColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: SemanticColors.border)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Manual setup options
            Column(
              children: [
                // First row - Server Library and Custom Config
                Row(
                  children: [
                    // MCP Server Library Option
                    Expanded(
                      child: _buildSetupOption(
                        context,
                        title: 'Server Library',
                        description: 'Select from curated MCP servers',
                        icon: Icons.library_books,
                        badge: 'Popular',
                        badgeColor: SemanticColors.primary,
                        onTap: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (context) => ManualMCPServerModal(
                              onConfigurationComplete: _handleMCPConfigAdded,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Custom Configuration Option
                    Expanded(
                      child: _buildSetupOption(
                        context,
                        title: 'Custom Config',
                        description: 'Add any MCP server with JSON',
                        icon: Icons.code,
                        badge: 'JSON',
                        badgeColor: SemanticColors.warning,
                        onTap: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (context) => CustomMCPServerModal(
                              onConfigurationComplete: _handleMCPConfigAdded,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Second row - Legacy options
                Row(
                  children: [
                    // Enhanced Wizard Option
                    Expanded(
                      child: _buildSetupOption(
                        context,
                        title: 'Guided Setup',
                        description: 'Step-by-step wizard with recommendations',
                        icon: Icons.auto_awesome,
                        badge: 'Recommended',
                        badgeColor: SemanticColors.success,
                        onTap: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (context) => const EnhancedMCPServerWizard(),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Quick Setup Option
                    Expanded(
                      child: _buildSetupOption(
                        context,
                        title: 'Manual Setup',
                        description: 'Traditional form for advanced users',
                        icon: Icons.settings,
                        badge: 'Advanced',
                        badgeColor: SemanticColors.warning,
                        onTap: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (context) => _buildTraditionalDialog(context, isEdit),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SemanticColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  color: SemanticColors.primary,
                  size: 24,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                title,
                style: TextStyles.cardTitle,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 6),
              
              Text(
                description,
                style: TextStyles.caption.copyWith(
                  color: SemanticColors.onSurfaceVariant,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (badge != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? SemanticColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyles.labelSmall.copyWith(
                      color: badgeColor ?? SemanticColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTraditionalDialog(BuildContext context, bool isEdit) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 700,
          minWidth: 600,
        ),
        decoration: BoxDecoration(
          color: ThemeColors(context).surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.storage,
                    size: 24,
                    color: SemanticColors.primary,
                  ),
                  const SizedBox(width: SpacingTokens.componentSpacing),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit MCP Server' : 'Add MCP Server',
                      style: TextStyles.sectionTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Template Selection (only for new servers)
                      if (!isEdit) ...[
                        _buildTemplateSelection(),
                        const SizedBox(height: SpacingTokens.sectionSpacing),
                      ],

                      // Basic Configuration
                      _buildBasicConfiguration(),

                      const SizedBox(height: SpacingTokens.sectionSpacing),

                      // Command Configuration
                      _buildCommandConfiguration(),

                      const SizedBox(height: SpacingTokens.sectionSpacing),

                      // Environment Variables
                      _buildEnvironmentVariables(),

                      const SizedBox(height: SpacingTokens.sectionSpacing),

                      // Advanced Options
                      _buildAdvancedOptions(),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
                  const SizedBox(width: SpacingTokens.componentSpacing),
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
          style: TextStyles.cardTitle,
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        
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
                constraints: const BoxConstraints(
                  maxWidth: 160,
                  minWidth: 120,
                ),
                padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
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
                    const SizedBox(height: 8),
                    Text(
                      template.name,
                      style: TextStyles.labelMedium.copyWith(
                        color: isSelected 
                          ? SemanticColors.primary
                          : SemanticColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.category,
                      style: TextStyles.labelSmall.copyWith(
                        color: SemanticColors.onSurfaceVariant,
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
          style: TextStyles.cardTitle,
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),

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

        const SizedBox(height: SpacingTokens.componentSpacing),

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
          style: TextStyles.cardTitle,
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),

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

        const SizedBox(height: SpacingTokens.componentSpacing),

        // Arguments
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Arguments',
                  style: TextStyles.labelLarge,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    _safeSetState(() => _args.add(''));
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Argument'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
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
                          _safeSetState(() => _args[index] = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        _safeSetState(() => _args.removeAt(index));
                      },
                      icon: const Icon(Icons.remove_circle, size: 20),
                      style: IconButton.styleFrom(
                        foregroundColor: SemanticColors.error,
                      ),
                    ),
                  ],
                ),
              );
            }),
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
              style: TextStyles.cardTitle,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                _showAddEnvVarDialog();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Variable'),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),

        if (_envVars.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                const SizedBox(width: 8),
                Text(
                  'No environment variables configured',
                  style: TextStyles.bodySmall.copyWith(
                    color: SemanticColors.onSurfaceVariant,
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
                  const SizedBox(width: 12),
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
                    icon: const Icon(Icons.edit, size: 16),
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _safeSetState(() => _envVars.remove(key));
                    },
                    icon: const Icon(Icons.delete, size: 16),
                    style: IconButton.styleFrom(
                      foregroundColor: SemanticColors.error,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Options',
          style: TextStyles.cardTitle,
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),

        // Enable/Disable Server
        Row(
          children: [
            Switch(
              value: _enabled,
              onChanged: (value) => _safeSetState(() => _enabled = value),
              activeThumbColor: SemanticColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enable Server',
                    style: TextStyles.labelLarge,
                  ),
                  Text(
                    'Server will be available for agent deployment when enabled',
                    style: TextStyles.caption.copyWith(
                      color: SemanticColors.onSurfaceVariant,
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 400,
            minWidth: 400,
          ),
          decoration: BoxDecoration(
            color: ThemeColors(context).surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: SemanticColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: SemanticColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add Environment Variable',
                        style: TextStyles.cardTitle,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        foregroundColor: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
                  child: Column(
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
                      const SizedBox(height: SpacingTokens.componentSpacing),
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
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: SemanticColors.border.withValues(alpha: 0.3),
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
                    const SizedBox(width: SpacingTokens.componentSpacing),
                    AsmblButton.primary(
                      text: 'Add',
                      onPressed: () {
                        final key = keyController.text.trim();
                        if (key.isNotEmpty) {
                          _safeSetState(() {
                            _envVars[key] = valueController.text.trim();
                          });
                          Navigator.of(context).pop();
                        }
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

  void _editEnvVar(String key, String currentValue) {
    final valueController = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 350,
            minWidth: 400,
          ),
          decoration: BoxDecoration(
            color: ThemeColors(context).surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: SemanticColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: SemanticColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit $key',
                        style: TextStyles.cardTitle,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        foregroundColor: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
                  child: TextFormField(
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
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: SemanticColors.border.withValues(alpha: 0.3),
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
                    const SizedBox(width: SpacingTokens.componentSpacing),
                    AsmblButton.primary(
                      text: 'Update',
                      onPressed: () {
                        _safeSetState(() {
                          _envVars[key] = valueController.text.trim();
                        });
                        Navigator.of(context).pop();
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