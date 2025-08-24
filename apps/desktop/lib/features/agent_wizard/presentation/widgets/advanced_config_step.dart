import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../models/agent_wizard_state.dart';

/// Fourth step of the agent wizard - advanced configuration
class AdvancedConfigStep extends ConsumerStatefulWidget {
  final AgentWizardState wizardState;
  final VoidCallback onChanged;

  const AdvancedConfigStep({
    super.key,
    required this.wizardState,
    required this.onChanged,
  });

  @override
  ConsumerState<AdvancedConfigStep> createState() => _AdvancedConfigStepState();
}

class _AdvancedConfigStepState extends ConsumerState<AdvancedConfigStep> {
  final Map<String, TextEditingController> _envControllers = {};
  bool _showAdvancedSettings = false;
  bool _showEnvironmentHelp = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize controllers for existing environment variables
    for (final entry in widget.wizardState.environmentVariables.entries) {
      _envControllers[entry.key] = TextEditingController(text: entry.value);
    }
    
    // Add common environment variables if none exist
    if (widget.wizardState.environmentVariables.isEmpty) {
      _addCommonEnvVariables();
    }
  }

  void _addCommonEnvVariables() {
    final selectedServers = widget.wizardState.selectedMCPServers;
    final commonVars = <String, String>{};
    
    // Add environment variables based on selected MCP servers
    if (selectedServers.contains('github')) {
      commonVars['GITHUB_TOKEN'] = '';
    }
    if (selectedServers.contains('postgres')) {
      commonVars['POSTGRES_CONNECTION_STRING'] = '';
    }
    if (selectedServers.contains('slack')) {
      commonVars['SLACK_TOKEN'] = '';
    }
    if (selectedServers.contains('notion')) {
      commonVars['NOTION_TOKEN'] = '';
    }
    
    // Add controllers for common variables
    for (final entry in commonVars.entries) {
      _envControllers[entry.key] = TextEditingController(text: entry.value);
      widget.wizardState.setEnvironmentVariable(entry.key, entry.value);
    }
    
    if (commonVars.isNotEmpty) {
      widget.onChanged();
    }
  }

  @override
  void dispose() {
    for (final controller in _envControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step title and description
              _buildStepHeader(context),
              
              SizedBox(height: SpacingTokens.xxl),
              
              // Environment Variables Section
              _buildEnvironmentVariablesSection(context),
              
              SizedBox(height: SpacingTokens.xxl),
              
              // Context Documents Section
              _buildContextDocumentsSection(context),
              
              SizedBox(height: SpacingTokens.xxl),
              
              // Advanced Settings Section
              _buildAdvancedSettingsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Configuration',
          style: TextStyles.pageTitle,
        ),
        SizedBox(height: SpacingTokens.sm),
        Text(
          'Configure environment variables, context documents, and advanced settings to customize your agent\'s behavior and access.',
          style: TextStyles.bodyMedium.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentVariablesSection(BuildContext context) {
    final envVars = widget.wizardState.environmentVariables;
    
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              SizedBox(width: SpacingTokens.sm),
              Text(
                'Environment Variables',
                style: TextStyles.cardTitle,
              ),
              Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showEnvironmentHelp = !_showEnvironmentHelp;
                  });
                },
                icon: Icon(
                  _showEnvironmentHelp ? Icons.help : Icons.help_outline,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: ThemeColors(context).onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Configure API keys, tokens, and other environment variables needed by your MCP servers.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          if (_showEnvironmentHelp) ...[
            SizedBox(height: SpacingTokens.md),
            _buildEnvironmentHelp(context),
          ],
          
          SizedBox(height: SpacingTokens.lg),
          
          // Environment variables list
          if (envVars.isEmpty) ...[
            _buildEmptyEnvState(context),
          ] else ...[
            Column(
              children: envVars.keys.map((key) {
                return Container(
                  margin: EdgeInsets.only(bottom: SpacingTokens.md),
                  child: _buildEnvVariableField(context, key),
                );
              }).toList(),
            ),
          ],
          
          SizedBox(height: SpacingTokens.lg),
          
          // Add environment variable section
          _buildAddEnvVariable(context),
        ],
      ),
    );
  }

  Widget _buildEnvironmentHelp(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: ThemeColors(context).info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: ThemeColors(context).info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: ThemeColors(context).info,
                size: 16,
              ),
              SizedBox(width: SpacingTokens.xs),
              Text(
                'Environment Variable Guide',
                style: TextStyles.bodySmall.copyWith(
                  color: ThemeColors(context).info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.xs),
          Text(
            '• GITHUB_TOKEN: Personal access token for GitHub operations\n'
            '• SLACK_TOKEN: Bot or OAuth token for Slack integration\n'
            '• NOTION_TOKEN: Integration token for Notion workspace\n'
            '• POSTGRES_CONNECTION_STRING: Database connection string\n'
            '• Variables are securely stored and not visible in logs',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEnvState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.eco,
            size: 48,
            color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            'No environment variables configured',
            style: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          Text(
            'Your agent will work without environment variables, but some MCP servers may need API keys.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnvVariableField(BuildContext context, String key) {
    final controller = _envControllers[key]!;
    final isSecure = _isSecureVariable(key);
    
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: ThemeColors(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  key,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (isSecure)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ThemeColors(context).warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.security,
                        size: 12,
                        color: ThemeColors(context).warning,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'SECURE',
                        style: TextStyles.bodySmall.copyWith(
                          color: ThemeColors(context).warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              IconButton(
                onPressed: () => _removeEnvVariable(key),
                icon: Icon(Icons.delete_outline),
                style: IconButton.styleFrom(
                  foregroundColor: ThemeColors(context).error,
                ),
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.sm),
          
          TextField(
            controller: controller,
            obscureText: isSecure,
            onChanged: (value) {
              widget.wizardState.setEnvironmentVariable(key, value);
              widget.onChanged();
            },
            decoration: InputDecoration(
              hintText: _getEnvVariableHint(key),
              hintStyle: TextStyles.bodyMedium.copyWith(
                color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                borderSide: BorderSide(color: ThemeColors(context).border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                borderSide: BorderSide(color: ThemeColors(context).border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                borderSide: BorderSide(color: ThemeColors(context).primary, width: 2),
              ),
              filled: true,
              fillColor: ThemeColors(context).inputBackground,
              contentPadding: EdgeInsets.all(SpacingTokens.sm),
            ),
            style: TextStyles.bodyMedium.copyWith(
              fontFamily: isSecure ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEnvVariable(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AsmblButton.secondary(
            text: 'Add Environment Variable',
            icon: Icons.add,
            onPressed: () => _showAddEnvDialog(),
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        AsmblButton.secondary(
          text: 'Load from File',
          icon: Icons.file_upload,
          onPressed: () => _showLoadEnvFileDialog(),
        ),
      ],
    );
  }

  Widget _buildContextDocumentsSection(BuildContext context) {
    final contextDocs = widget.wizardState.contextDocuments;
    final mcpService = ref.watch(mcpSettingsServiceProvider);
    
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              SizedBox(width: SpacingTokens.sm),
              Text(
                'Context Documents',
                style: TextStyles.cardTitle,
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Select additional context documents to include with your agent. These will be available during conversations.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          // Global context documents from settings
          FutureBuilder<List<String>>(
            future: Future.value(mcpService.globalContextDocuments),
            builder: (context, snapshot) {
              final globalDocs = snapshot.data ?? [];
              
              if (globalDocs.isEmpty) {
                return _buildEmptyContextState(context);
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Context Documents',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: SpacingTokens.sm),
                  
                  ...globalDocs.map((doc) {
                    final isSelected = contextDocs.contains(doc);
                    
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (selected) {
                        if (selected == true) {
                          widget.wizardState.addContextDocument(doc);
                        } else {
                          widget.wizardState.removeContextDocument(doc);
                        }
                        widget.onChanged();
                      },
                      title: Text(
                        doc,
                        style: TextStyles.bodyMedium,
                      ),
                      subtitle: Text(
                        'Global context document',
                        style: TextStyles.bodySmall.copyWith(
                          color: ThemeColors(context).onSurfaceVariant,
                        ),
                      ),
                      activeColor: ThemeColors(context).primary,
                    );
                  }).toList(),
                ],
              );
            },
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          AsmblButton.secondary(
            text: 'Manage Context Documents',
            icon: Icons.settings,
            onPressed: () => _navigateToContextSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContextState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.description,
            size: 48,
            color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            'No context documents available',
            style: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          Text(
            'Add global context documents in Settings to make them available to agents.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsSection(BuildContext context) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              SizedBox(width: SpacingTokens.sm),
              Text(
                'Advanced Settings',
                style: TextStyles.cardTitle,
              ),
              Spacer(),
              Switch(
                value: _showAdvancedSettings,
                onChanged: (value) {
                  setState(() {
                    _showAdvancedSettings = value;
                  });
                },
                activeColor: ThemeColors(context).primary,
              ),
            ],
          ),
          
          if (!_showAdvancedSettings) ...[
            SizedBox(height: SpacingTokens.sm),
            Text(
              'Enable to configure performance, security, and behavior settings.',
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).onSurfaceVariant,
              ),
            ),
          ],
          
          if (_showAdvancedSettings) ...[
            SizedBox(height: SpacingTokens.lg),
            
            _buildAdvancedSetting(
              context,
              'Response Timeout',
              'Maximum time to wait for agent responses',
              'timeout',
              30,
              5,
              120,
              'seconds',
            ),
            
            SizedBox(height: SpacingTokens.lg),
            
            _buildAdvancedSetting(
              context,
              'Memory Limit',
              'Maximum conversation history to maintain',
              'memoryLimit',
              50,
              10,
              100,
              'messages',
            ),
            
            SizedBox(height: SpacingTokens.lg),
            
            _buildAdvancedToggle(
              context,
              'Debug Mode',
              'Enable detailed logging for troubleshooting',
              'debugMode',
              false,
            ),
            
            SizedBox(height: SpacingTokens.lg),
            
            _buildAdvancedToggle(
              context,
              'Strict Mode',
              'Enable stricter validation and error handling',
              'strictMode',
              true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedSetting(
    BuildContext context,
    String title,
    String description,
    String key,
    int defaultValue,
    int min,
    int max,
    String unit,
  ) {
    final currentValue = widget.wizardState.advancedSettings[key] ?? defaultValue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$currentValue $unit',
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        SizedBox(height: SpacingTokens.xs),
        
        Text(
          description,
          style: TextStyles.bodySmall.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        
        SizedBox(height: SpacingTokens.sm),
        
        Slider(
          value: currentValue.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (value) {
            setState(() {});
            widget.wizardState.setAdvancedSetting(key, value.round());
            widget.onChanged();
          },
          activeColor: ThemeColors(context).primary,
        ),
      ],
    );
  }

  Widget _buildAdvancedToggle(
    BuildContext context,
    String title,
    String description,
    String key,
    bool defaultValue,
  ) {
    final currentValue = widget.wizardState.advancedSettings[key] ?? defaultValue;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyles.bodySmall.copyWith(
                  color: ThemeColors(context).onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: currentValue,
          onChanged: (value) {
            widget.wizardState.setAdvancedSetting(key, value);
            widget.onChanged();
          },
          activeColor: ThemeColors(context).primary,
        ),
      ],
    );
  }

  bool _isSecureVariable(String key) {
    return key.toLowerCase().contains('token') ||
           key.toLowerCase().contains('key') ||
           key.toLowerCase().contains('secret') ||
           key.toLowerCase().contains('password');
  }

  String _getEnvVariableHint(String key) {
    switch (key.toLowerCase()) {
      case 'github_token':
        return 'ghp_xxxxxxxxxxxxxxxxxxxx';
      case 'slack_token':
        return 'xoxb-xxxxxxxxxxxx-xxxxxxxxxxxx';
      case 'notion_token':
        return 'secret_xxxxxxxxxxxxxxxxxxxx';
      case 'postgres_connection_string':
        return 'postgresql://user:password@host:port/database';
      default:
        return 'Enter value for $key';
    }
  }

  void _removeEnvVariable(String key) {
    setState(() {
      _envControllers[key]?.dispose();
      _envControllers.remove(key);
    });
    widget.wizardState.setEnvironmentVariable(key, '');
    widget.onChanged();
  }

  void _showAddEnvDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Environment Variable'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Variable Name',
            hintText: 'e.g., API_KEY',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          AsmblButton.secondary(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AsmblButton.primary(
            text: 'Add',
            onPressed: () {
              final name = controller.text.trim().toUpperCase();
              if (name.isNotEmpty && !_envControllers.containsKey(name)) {
                setState(() {
                  _envControllers[name] = TextEditingController();
                });
                widget.wizardState.setEnvironmentVariable(name, '');
                widget.onChanged();
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showLoadEnvFileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Load Environment File'),
        content: Text('Environment file loading would be implemented here'),
        actions: [
          AsmblButton.primary(
            text: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _navigateToContextSettings() {
    Navigator.of(context).pushNamed('/settings', arguments: {'tab': 'context'});
  }
}