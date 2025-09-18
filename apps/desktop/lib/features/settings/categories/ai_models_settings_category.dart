import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/api_config_service.dart';
import '../components/settings_field.dart';
import '../providers/settings_provider.dart';

/// AI Models settings category - comprehensive API configuration management
class AiModelsSettingsCategory extends ConsumerStatefulWidget {
  const AiModelsSettingsCategory({super.key});

  @override
  ConsumerState<AiModelsSettingsCategory> createState() => _AiModelsSettingsCategoryState();
}

class _AiModelsSettingsCategoryState extends ConsumerState<AiModelsSettingsCategory> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  String _selectedProvider = 'Anthropic';
  bool _showAddForm = false;
  bool _isLoading = false;
  String? _formError;

  final List<String> _availableProviders = [
    'Anthropic',
    'OpenAI',
    'Google',
    'Cohere',
    'Hugging Face',
    'Custom',
  ];

  final Map<String, String> _defaultBaseUrls = {
    'Anthropic': 'https://api.anthropic.com',
    'OpenAI': 'https://api.openai.com/v1',
    'Google': 'https://generativelanguage.googleapis.com/v1',
    'Cohere': 'https://api.cohere.ai/v1',
    'Hugging Face': 'https://api-inference.huggingface.co/models',
    'Custom': '',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final aiModelsSettings = ref.watch(aiModelsSettingsProvider);
    final allApiConfigs = ref.watch(allApiConfigsProvider);
    final defaultApiConfig = ref.watch(defaultApiConfigProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview stats
              _buildOverviewStats(aiModelsSettings, colors),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Current configurations
              _buildConfigurationsSection(allApiConfigs, defaultApiConfig, colors),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Add new configuration form or button
              if (_showAddForm) 
                _buildAddConfigurationForm(colors)
              else
                _buildAddConfigurationButton(colors),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Test connections section
              _buildTestConnectionsSection(colors),
            ],
          ),
        ),
      ),
    );
  }

  /// Build overview statistics
  Widget _buildOverviewStats(dynamic aiModelsSettings, ThemeColors colors) {
    final configCount = aiModelsSettings.configurations.length;
    final enabledCount = aiModelsSettings.configurations
        .where((config) => config.enabled && config.isConfigured).length;

    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Models Overview',
              style: TextStyles.headingSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.md),
            Row(
              children: [
                _buildStatItem('Total Models', configCount.toString(), colors.primary, colors),
                const SizedBox(width: SpacingTokens.xl),
                _buildStatItem('Configured', enabledCount.toString(), colors.accent, colors),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(String label, String value, Color color, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyles.headingLarge.copyWith(color: color),
        ),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          label,
          style: TextStyles.labelMedium.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  /// Build configurations list section
  Widget _buildConfigurationsSection(
    Map<String, ApiConfig> configs,
    ApiConfig? defaultConfig,
    ThemeColors colors,
  ) {
    return SettingsSection(
      title: 'API Configurations',
      description: 'Manage your AI model API configurations and keys',
      children: [
        if (configs.isEmpty) 
          _buildEmptyState(colors)
        else
          ...configs.entries.map((entry) => _buildConfigurationCard(
            entry.key,
            entry.value,
            entry.value.id == defaultConfig?.id,
            colors,
          )),
      ],
    );
  }

  /// Build empty state when no configurations exist
  Widget _buildEmptyState(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xl),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 48,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: SpacingTokens.md),
              Text(
                'No AI Models Configured',
                style: TextStyles.headingSmall.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                'Add your first AI model configuration to start using the chat features.',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacingTokens.lg),
              AsmblButton.primary(
                text: 'Add AI Model',
                icon: Icons.add,
                onPressed: () => setState(() => _showAddForm = true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual configuration card
  Widget _buildConfigurationCard(
    String id,
    ApiConfig config,
    bool isDefault,
    ThemeColors colors,
  ) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Provider icon and info
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Icon(
                    _getProviderIcon(config.provider),
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                
                // Configuration details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            config.name,
                            style: TextStyles.labelLarge.copyWith(color: colors.onSurface),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: SpacingTokens.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.sm,
                                vertical: SpacingTokens.xs,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                              ),
                              child: Text(
                                'Default',
                                style: TextStyles.captionMedium.copyWith(color: colors.accent),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        '${config.provider} • ${config.model}',
                        style: TextStyles.captionMedium.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                
                // Configuration status
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: config.isConfigured ? colors.accent : colors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: SpacingTokens.md),
            
            // Action buttons
            Row(
              children: [
                if (!isDefault)
                  AsmblButton.secondary(
                    text: 'Set as Default',
                    onPressed: () => _setAsDefault(id),
                  ),
                if (!isDefault) const SizedBox(width: SpacingTokens.sm),
                AsmblButton.outline(
                  text: 'Test',
                  icon: Icons.check_circle_outline,
                  onPressed: () => _testConfiguration(id),
                ),
                const SizedBox(width: SpacingTokens.sm),
                AsmblButton.danger(
                  text: 'Remove',
                  icon: Icons.delete_outline,
                  onPressed: () => _removeConfiguration(id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build add configuration button
  Widget _buildAddConfigurationButton(ThemeColors colors) {
    return Center(
      child: AsmblButton.primary(
        text: 'Add AI Model',
        icon: Icons.add,
        onPressed: () => setState(() {
          _showAddForm = true;
          _clearForm();
        }),
      ),
    );
  }

  /// Build add configuration form
  Widget _buildAddConfigurationForm(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Add AI Model Configuration',
                  style: TextStyles.headingSmall.copyWith(color: colors.onSurface),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() {
                    _showAddForm = false;
                    _clearForm();
                  }),
                  icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                ),
              ],
            ),
            
            if (_formError != null) ...[
              const SizedBox(height: SpacingTokens.md),
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: colors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(color: colors.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colors.error, size: 16),
                    const SizedBox(width: SpacingTokens.sm),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: TextStyles.captionMedium.copyWith(color: colors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: SpacingTokens.lg),
            
            // Form fields
            SettingsField(
              label: 'Configuration Name',
              hint: 'e.g., "Claude 3.5 Sonnet" or "GPT-4"',
              value: _nameController.text,
              required: true,
              onChanged: (value) => _nameController.text = value,
            ),
            
            const SizedBox(height: SpacingTokens.md),
            
            // Provider dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider',
                  style: TextStyles.labelMedium.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    border: Border.all(color: colors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedProvider,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
                      items: _availableProviders.map((provider) {
                        return DropdownMenuItem(
                          value: provider,
                          child: Row(
                            children: [
                              Icon(
                                _getProviderIcon(provider),
                                size: 16,
                                color: colors.onSurface,
                              ),
                              const SizedBox(width: SpacingTokens.sm),
                              Text(provider, style: TextStyles.bodyMedium.copyWith(color: colors.onSurface)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedProvider = value;
                            _baseUrlController.text = _defaultBaseUrls[value] ?? '';
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: SpacingTokens.md),
            
            SettingsField(
              label: 'Model Name',
              hint: 'e.g., "claude-3-5-sonnet-20241022" or "gpt-4"',
              value: _modelController.text,
              required: true,
              onChanged: (value) => _modelController.text = value,
            ),
            
            const SizedBox(height: SpacingTokens.md),
            
            SettingsField(
              label: 'API Key',
              hint: 'Your API key for this provider',
              value: _apiKeyController.text,
              obscureText: true,
              required: true,
              onChanged: (value) => _apiKeyController.text = value,
            ),
            
            const SizedBox(height: SpacingTokens.md),
            
            SettingsField(
              label: 'Base URL',
              hint: 'API endpoint base URL',
              value: _baseUrlController.text,
              required: true,
              onChanged: (value) => _baseUrlController.text = value,
            ),
            
            const SizedBox(height: SpacingTokens.lg),
            
            // Form actions
            Row(
              children: [
                AsmblButton.primary(
                  text: 'Add Configuration',
                  icon: Icons.save,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _saveConfiguration,
                ),
                const SizedBox(width: SpacingTokens.sm),
                AsmblButton.outline(
                  text: 'Cancel',
                  onPressed: _isLoading ? null : () => setState(() {
                    _showAddForm = false;
                    _clearForm();
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build test connections section
  Widget _buildTestConnectionsSection(ThemeColors colors) {
    return SettingsSection(
      title: 'Connection Testing',
      description: 'Test your API configurations to ensure they work correctly',
      children: [
        SettingsButton(
          text: 'Test All Connections',
          description: 'Verify all configured API endpoints are working',
          icon: Icons.network_check,
          onPressed: _testAllConnections,
        ),
      ],
    );
  }

  /// Get provider icon
  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'anthropic':
        return Icons.psychology;
      case 'openai':
        return Icons.auto_awesome;
      case 'google':
        return Icons.search;
      case 'cohere':
        return Icons.chat;
      case 'hugging face':
        return Icons.face;
      default:
        return Icons.api;
    }
  }

  /// Clear form fields
  void _clearForm() {
    _nameController.clear();
    _apiKeyController.clear();
    _baseUrlController.clear();
    _modelController.clear();
    _selectedProvider = 'Anthropic';
    _baseUrlController.text = _defaultBaseUrls[_selectedProvider] ?? '';
    _formError = null;
  }

  /// Save new configuration
  Future<void> _saveConfiguration() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _formError = null;
    });

    try {
      // Validate form
      if (_nameController.text.trim().isEmpty ||
          _apiKeyController.text.trim().isEmpty ||
          _baseUrlController.text.trim().isEmpty ||
          _modelController.text.trim().isEmpty) {
        throw Exception('All fields are required');
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final config = ApiConfig(
        id: id,
        name: _nameController.text.trim(),
        provider: _selectedProvider,
        model: _modelController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        enabled: true,
      );

      // Save through the API configs notifier
      await ref.read(apiConfigsProvider.notifier).addConfig(id, config);

      if (mounted) {
        setState(() {
          _showAddForm = false;
          _isLoading = false;
        });
        _clearForm();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI model "${config.name}" added successfully'),
            backgroundColor: ThemeColors(context).accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _formError = e.toString();
        });
      }
    }
  }

  /// Set configuration as default
  Future<void> _setAsDefault(String id) async {
    try {
      await ref.read(apiConfigsProvider.notifier).setDefault(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Default model updated successfully'),
            backgroundColor: ThemeColors(context).accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set default: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  /// Test individual configuration
  Future<void> _testConfiguration(String id) async {
    try {
      final service = ref.read(apiConfigServiceProvider);
      final result = await service.testApiConfig(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ? 'Configuration test passed' : 'Configuration test failed'),
            backgroundColor: result ? ThemeColors(context).accent : ThemeColors(context).error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  /// Remove configuration
  Future<void> _removeConfiguration(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Configuration'),
        content: const Text('Are you sure you want to remove this AI model configuration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(apiConfigsProvider.notifier).removeConfig(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Configuration removed successfully'),
              backgroundColor: ThemeColors(context).accent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove configuration: $e'),
              backgroundColor: ThemeColors(context).error,
            ),
          );
        }
      }
    }
  }

  /// Test all connections
  Future<void> _testAllConnections() async {
    try {
      final result = await ref.read(settingsProvider.notifier).testConnection(SettingsCategory.aiModels);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.isSuccess ? ThemeColors(context).accent : ThemeColors(context).error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }
}