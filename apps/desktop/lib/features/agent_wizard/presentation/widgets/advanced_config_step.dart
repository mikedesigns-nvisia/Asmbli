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
    final mcpService = ref.read(mcpSettingsServiceProvider);
    final commonVars = <String, String>{};
    
    // Add environment variables based on selected MCP servers from actual configurations
    for (final serverId in selectedServers) {
      final serverConfig = mcpService.allMCPServers[serverId];
      if (serverConfig != null) {
        // Extract environment variable patterns from server configuration
        serverConfig.env?.forEach((key, value) {
          if (value.isEmpty || value.startsWith('\${')) {
            // This is a template variable that needs to be filled
            commonVars[key] = '';
          }
        });
      } else {
        // Fallback to hardcoded common variables for known servers
        _addHardcodedEnvVars(serverId, commonVars);
      }
    }
    
    // Add controllers for common variables
    for (final entry in commonVars.entries) {
      if (!_envControllers.containsKey(entry.key)) {
        _envControllers[entry.key] = TextEditingController(text: entry.value);
        widget.wizardState.setEnvironmentVariable(entry.key, entry.value);
      }
    }
    
    if (commonVars.isNotEmpty) {
      widget.onChanged();
    }
  }
  
  void _addHardcodedEnvVars(String serverId, Map<String, String> commonVars) {
    // Fallback environment variables for known servers
    switch (serverId.toLowerCase()) {
      case 'github':
        commonVars['GITHUB_TOKEN'] = '';
        break;
      case 'postgres':
        commonVars['POSTGRES_CONNECTION_STRING'] = '';
        break;
      case 'slack':
        commonVars['SLACK_TOKEN'] = '';
        break;
      case 'notion':
        commonVars['NOTION_TOKEN'] = '';
        break;
      case 'brave-search':
        commonVars['BRAVE_API_KEY'] = '';
        break;
      case 'openai':
        commonVars['OPENAI_API_KEY'] = '';
        break;
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
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step title and description
              _buildStepHeader(context),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Environment Variables Section
              _buildEnvironmentVariablesSection(context),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // MCP Server Status Section
              _buildMCPServerStatusSection(context),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Context Documents Section
              _buildContextDocumentsSection(context),
              
              const SizedBox(height: SpacingTokens.xxl),
              
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
        const SizedBox(height: SpacingTokens.sm),
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
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Environment Variables',
                style: TextStyles.cardTitle,
              ),
              const Spacer(),
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
          
          const SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Configure API keys, tokens, and other environment variables needed by your MCP servers.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          if (_showEnvironmentHelp) ...[
            const SizedBox(height: SpacingTokens.md),
            _buildEnvironmentHelp(context),
          ],
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Environment variables list
          if (envVars.isEmpty) ...[
            _buildEmptyEnvState(context),
          ] else ...[
            Column(
              children: envVars.keys.map((key) {
                return Container(
                  margin: const EdgeInsets.only(bottom: SpacingTokens.md),
                  child: _buildEnvVariableField(context, key),
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Add environment variable section
          _buildAddEnvVariable(context),
        ],
      ),
    );
  }

  Widget _buildEnvironmentHelp(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: ThemeColors(context).info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: ThemeColors(context).info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: ThemeColors(context).info.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: ThemeColors(context).info,
                  size: 20,
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Text(
                'Environment Variable Guide',
                style: TextStyles.cardTitle.copyWith(
                  color: ThemeColors(context).info,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          _buildHelpSection(context, 'How to get API keys:', [
            'GitHub: Settings → Developer settings → Personal access tokens → Generate new token',
            'OpenAI: Platform.openai.com → API Keys → Create new secret key',
            'Brave Search: Search.brave.com → Sign up → API Keys',
          ]),
          
          const SizedBox(height: SpacingTokens.md),
          
          _buildHelpSection(context, 'Security & Storage:', [
            'All variables are encrypted and stored securely',
            'Values are never displayed in plain text or logs',
            'Only your agents can access these variables',
            'You can update or remove variables anytime',
          ]),
          
          const SizedBox(height: SpacingTokens.md),
          
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: ThemeColors(context).warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: ThemeColors(context).warning,
                  size: 16,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    'Never share your API keys or tokens with others. Keep them secure and rotate them regularly.',
                    style: TextStyles.bodySmall.copyWith(
                      color: ThemeColors(context).onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHelpSection(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: ThemeColors(context).onSurface,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(
            left: SpacingTokens.md,
            bottom: SpacingTokens.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  item,
                  style: TextStyles.bodySmall.copyWith(
                    color: ThemeColors(context).onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyEnvState(BuildContext context) {
    return Column(
      children: [
        // Enhanced empty state with better visual design
        Container(
          padding: const EdgeInsets.all(SpacingTokens.xl),
          decoration: BoxDecoration(
            color: ThemeColors(context).surface,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            border: Border.all(
              color: ThemeColors(context).border.withValues(alpha: 0.5),
              style: BorderStyle.solid,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                ),
                child: Icon(
                  Icons.key,
                  size: 40,
                  color: ThemeColors(context).primary,
                ),
              ),
              const SizedBox(height: SpacingTokens.lg),
              Text(
                'No environment variables configured',
                style: TextStyles.cardTitle.copyWith(
                  color: ThemeColors(context).onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                'Environment variables store API keys, tokens, and other sensitive configuration data that your agents need to access external services.',
                style: TextStyles.bodyMedium.copyWith(
                  color: ThemeColors(context).onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: SpacingTokens.lg),
        
        // Quick setup cards for common variables
        _buildCommonVariablesSection(context),
      ],
    );
  }
  
  Widget _buildCommonVariablesSection(BuildContext context) {
    final commonVars = [
      {
        'name': 'GITHUB_TOKEN',
        'description': 'Personal access token for GitHub API access',
        'icon': Icons.code,
        'example': 'ghp_xxxxxxxxxxxxxxxxxxxx',
        'category': 'Development',
      },
      {
        'name': 'OPENAI_API_KEY',
        'description': 'API key for OpenAI services',
        'icon': Icons.psychology,
        'example': 'sk-xxxxxxxxxxxxxxxxxxxxxxxx',
        'category': 'AI Services',
      },
      {
        'name': 'BRAVE_API_KEY',
        'description': 'API key for Brave Search integration',
        'icon': Icons.search,
        'example': 'BSAxxxxxxxxxxxxxxxxxxxxxxx',
        'category': 'Web Services',
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Setup - Common Variables',
          style: TextStyles.sectionTitle.copyWith(
            color: ThemeColors(context).onSurface,
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        Text(
          'Click on any card below to quickly add a common environment variable:',
          style: TextStyles.bodySmall.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        const SizedBox(height: SpacingTokens.lg),
        ...commonVars.map((variable) => _buildQuickSetupCard(context, variable)),
      ],
    );
  }
  
  Widget _buildQuickSetupCard(BuildContext context, Map<String, dynamic> variable) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: AsmblCard(
        onTap: () => _addCommonVariable(variable['name'], variable['example']),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(
                  variable['icon'],
                  size: 20,
                  color: ThemeColors(context).primary,
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          variable['name'],
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeColors(context).primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                          ),
                          child: Text(
                            variable['category'],
                            style: TextStyles.caption.copyWith(
                              color: ThemeColors(context).primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      variable['description'],
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                color: ThemeColors(context).primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnvVariableField(BuildContext context, String key) {
    final controller = _envControllers[key]!;
    final isSecure = _isSecureVariable(key);
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      const SizedBox(width: 2),
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
                icon: const Icon(Icons.delete_outline),
                style: IconButton.styleFrom(
                  foregroundColor: ThemeColors(context).error,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
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
              contentPadding: const EdgeInsets.all(SpacingTokens.sm),
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
        const SizedBox(width: SpacingTokens.sm),
        AsmblButton.secondary(
          text: 'Load from File',
          icon: Icons.file_upload,
          onPressed: () => _showLoadEnvFileDialog(),
        ),
      ],
    );
  }

  Widget _buildMCPServerStatusSection(BuildContext context) {
    final selectedServers = widget.wizardState.selectedMCPServers;
    final mcpService = ref.read(mcpSettingsServiceProvider);
    
    if (selectedServers.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.integration_instructions,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'MCP Server Status',
                style: TextStyles.cardTitle,
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Status of MCP servers selected for this agent:',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          Column(
            children: selectedServers.map((serverId) {
              return Container(
                margin: const EdgeInsets.only(bottom: SpacingTokens.md),
                child: _buildMCPServerStatusItem(context, serverId, mcpService),
              );
            }).toList(),
          ),
          
          if (_hasUnconfiguredServers(selectedServers, mcpService)) ...[
            const SizedBox(height: SpacingTokens.lg),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: ThemeColors(context).warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(color: ThemeColors(context).warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ThemeColors(context).warning,
                    size: 16,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      'Some MCP servers need configuration. Visit Settings > MCP Servers to set them up.',
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMCPServerStatusItem(BuildContext context, String serverId, mcpService) {
    final serverConfig = mcpService.allMCPServers[serverId];
    final isConfigured = serverConfig != null;
    final isEnabled = serverConfig?.enabled ?? false;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isConfigured && isEnabled) {
      statusColor = SemanticColors.success;
      statusIcon = Icons.check_circle;
      statusText = 'Ready';
    } else if (isConfigured && !isEnabled) {
      statusColor = ThemeColors(context).warning;
      statusIcon = Icons.pause_circle;
      statusText = 'Disabled';
    } else {
      statusColor = ThemeColors(context).error;
      statusIcon = Icons.error_outline;
      statusText = 'Not configured';
    }
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: ThemeColors(context).border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 16,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serverId,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConfigured 
                    ? (serverConfig?.description ?? 'MCP Server')
                    : 'Server not configured in settings',
                  style: TextStyles.bodySmall.copyWith(
                    color: ThemeColors(context).onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Text(
              statusText,
              style: TextStyles.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasUnconfiguredServers(List<String> selectedServers, mcpService) {
    return selectedServers.any((serverId) {
      final serverConfig = mcpService.allMCPServers[serverId];
      return serverConfig == null;
    });
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
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Context Documents',
                style: TextStyles.cardTitle,
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Select additional context documents to include with your agent. These will be available during conversations.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
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
                  const SizedBox(height: SpacingTokens.sm),
                  
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
                  }),
                ],
              );
            },
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
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
          const SizedBox(height: SpacingTokens.sm),
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
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Advanced Settings',
                style: TextStyles.cardTitle,
              ),
              const Spacer(),
              Switch(
                value: _showAdvancedSettings,
                onChanged: (value) {
                  setState(() {
                    _showAdvancedSettings = value;
                  });
                },
                activeThumbColor: ThemeColors(context).primary,
              ),
            ],
          ),
          
          if (!_showAdvancedSettings) ...[
            const SizedBox(height: SpacingTokens.sm),
            Text(
              'Enable to configure performance, security, and behavior settings.',
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).onSurfaceVariant,
              ),
            ),
          ],
          
          if (_showAdvancedSettings) ...[
            const SizedBox(height: SpacingTokens.lg),
            
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
            
            const SizedBox(height: SpacingTokens.lg),
            
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
            
            const SizedBox(height: SpacingTokens.lg),
            
            _buildAdvancedToggle(
              context,
              'Debug Mode',
              'Enable detailed logging for troubleshooting',
              'debugMode',
              false,
            ),
            
            const SizedBox(height: SpacingTokens.lg),
            
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
        
        const SizedBox(height: SpacingTokens.xs),
        
        Text(
          description,
          style: TextStyles.bodySmall.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        
        const SizedBox(height: SpacingTokens.sm),
        
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
          activeThumbColor: ThemeColors(context).primary,
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
        title: const Text('Add Environment Variable'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
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
  
  void _addCommonVariable(String name, String example) {
    setState(() {
      if (!widget.wizardState.environmentVariables.containsKey(name)) {
        _envControllers[name] = TextEditingController();
        widget.wizardState.setEnvironmentVariable(name, '');
        widget.onChanged();
      }
    });
    
    // Show a helpful message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $name - don\'t forget to enter your actual API key!'),
        backgroundColor: SemanticColors.success,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showLoadEnvFileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Environment File'),
        content: const Text('Environment file loading would be implemented here'),
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