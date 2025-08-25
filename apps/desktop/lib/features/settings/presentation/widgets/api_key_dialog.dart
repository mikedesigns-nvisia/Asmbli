import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../core/services/claude_api_service.dart';
import '../../../../core/services/api_config_service.dart';

class ApiKeyDialog extends ConsumerStatefulWidget {
  final DirectAPIConfig? existingConfig;

  const ApiKeyDialog({
    super.key,
    this.existingConfig,
  });

  @override
  ConsumerState<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends ConsumerState<ApiKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  
  String selectedProvider = 'Anthropic';
  String selectedModel = 'claude-3-5-sonnet-20241022';
  bool _isObscured = true;
  bool _isTesting = false;
  bool _isTestSuccessful = false;
  String? _testError;

  final Map<String, List<String>> _providerModels = {
    'Anthropic': [
      'claude-3-5-sonnet-20241022',
      'claude-3-5-sonnet-20240620',
      'claude-3-5-haiku-20241022',
      'claude-3-opus-20240229',
      'claude-3-sonnet-20240229',
      'claude-3-haiku-20240307',
    ],
    'OpenAI': [
      'gpt-4o',
      'gpt-4o-mini',
      'gpt-4-turbo',
      'gpt-4',
      'gpt-3.5-turbo',
    ],
  };

  @override
  void initState() {
    super.initState();
    
    if (widget.existingConfig != null) {
      _nameController.text = widget.existingConfig!.name;
      _apiKeyController.text = widget.existingConfig!.apiKey;
      selectedProvider = widget.existingConfig!.provider;
      selectedModel = widget.existingConfig!.model;
    } else {
      _nameController.text = 'Claude 3.5 Sonnet';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
      ),
      child: Container(
        width: 520,
        padding: EdgeInsets.all(SpacingTokens.xxl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SemanticColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.api,
                      color: SemanticColors.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: SpacingTokens.componentSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingConfig != null ? 'Edit API Configuration' : 'Add API Configuration',
                          style: TextStyles.pageTitle.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Configure your API key to enable real AI conversations',
                          style: TextStyles.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      overlayColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: SpacingTokens.sectionSpacing),
              
              // Configuration Name
              _buildTextField(
                label: 'Configuration Name',
                controller: _nameController,
                hintText: 'e.g., Claude Production',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a configuration name';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: SpacingTokens.elementSpacing),
              
              // Provider Selection
              _buildDropdown(
                label: 'Provider',
                value: selectedProvider,
                items: _providerModels.keys.toList(),
                onChanged: (value) {
                  setState(() {
                    selectedProvider = value!;
                    selectedModel = _providerModels[value]!.first;
                    _isTestSuccessful = false;
                    _testError = null;
                  });
                },
              ),
              
              SizedBox(height: SpacingTokens.elementSpacing),
              
              // Model Selection
              _buildDropdown(
                label: 'Model',
                value: selectedModel,
                items: _providerModels[selectedProvider] ?? [],
                onChanged: (value) {
                  setState(() {
                    selectedModel = value!;
                    _isTestSuccessful = false;
                    _testError = null;
                  });
                },
              ),
              
              SizedBox(height: SpacingTokens.elementSpacing),
              
              // API Key
              _buildApiKeyField(),
              
              SizedBox(height: SpacingTokens.componentSpacing),
              
              // Test Connection
              _buildTestConnection(),
              
              SizedBox(height: SpacingTokens.sectionSpacing),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AsmblButton.secondary(
                    text: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: SpacingTokens.componentSpacing),
                  AsmblButton.primary(
                    text: widget.existingConfig != null ? 'Update' : 'Add',
                    onPressed: _saveApiConfig,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.labelMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: SemanticColors.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          style: TextStyles.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.labelMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: SemanticColors.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeyField() {
    return _buildTextField(
      label: 'API Key',
      controller: _apiKeyController,
      hintText: 'sk-ant-... (your API key)',
      obscureText: _isObscured,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your API key';
        }
        if (selectedProvider == 'Anthropic' && !value.startsWith('sk-ant-')) {
          return 'Anthropic API keys should start with sk-ant-';
        }
        return null;
      },
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => setState(() => _isObscured = !_isObscured),
            icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
            style: IconButton.styleFrom(
              overlayColor: ThemeColors(context).primary.withValues(alpha: 0.1),
            ),
          ),
          IconButton(
            onPressed: _pasteFromClipboard,
            icon: Icon(Icons.paste),
            tooltip: 'Paste from clipboard',
            style: IconButton.styleFrom(
              overlayColor: ThemeColors(context).primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestConnection() {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(SpacingTokens.elementSpacing),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: _isTestSuccessful 
            ? SemanticColors.success.withValues(alpha: 0.5)
            : _testError != null 
              ? SemanticColors.error.withValues(alpha: 0.5)
              : theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_isTesting)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                )
              else if (_isTestSuccessful)
                Icon(Icons.check_circle, color: SemanticColors.success, size: 16)
              else if (_testError != null)
                Icon(Icons.error, color: SemanticColors.error, size: 16)
              else
                Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant, size: 16),
              
              SizedBox(width: 8),
              
              Text(
                _isTesting 
                  ? 'Testing connection...'
                  : _isTestSuccessful 
                    ? 'Connection successful!'
                    : _testError != null 
                      ? 'Connection failed'
                      : 'Test your API key',
                style: TextStyles.labelMedium.copyWith(
                  color: _isTestSuccessful 
                    ? SemanticColors.success
                    : _testError != null 
                      ? SemanticColors.error
                      : theme.colorScheme.onSurface,
                ),
              ),
              
              Spacer(),
              
              AsmblButtonEnhanced.secondary(
                text: 'Test Connection',
                onPressed: _isTesting ? null : _testApiKey,
                size: AsmblButtonSize.small,
              ),
            ],
          ),
          
          if (_testError != null) ...[
            SizedBox(height: 8),
            Text(
              _testError!,
              style: TextStyles.bodySmall.copyWith(
                color: SemanticColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _apiKeyController.text = data!.text!;
      setState(() {
        _isTestSuccessful = false;
        _testError = null;
      });
    }
  }

  Future<void> _testApiKey() async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() {
        _testError = 'Please enter an API key first';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testError = null;
      _isTestSuccessful = false;
    });

    try {
      final claudeApiService = ref.read(claudeApiServiceProvider);
      final isValid = await claudeApiService.testApiKey(_apiKeyController.text.trim());
      
      setState(() {
        _isTesting = false;
        _isTestSuccessful = isValid;
        if (!isValid) {
          _testError = 'Invalid API key or insufficient permissions';
        }
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testError = e.toString();
      });
    }
  }

  Future<void> _saveApiConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final apiConfigsNotifier = ref.read(apiConfigsProvider.notifier);
      final currentConfigs = ref.read(apiConfigsProvider);
      
      final configId = widget.existingConfig?.id ?? 
          '${selectedProvider.toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}';
      
      final config = ApiConfig(
        id: configId,
        name: _nameController.text.trim(),
        provider: selectedProvider,
        model: selectedModel,
        apiKey: _apiKeyController.text.trim(),
        baseUrl: selectedProvider == 'Anthropic' 
          ? 'https://api.anthropic.com'
          : selectedProvider == 'OpenAI'
            ? 'https://api.openai.com'
            : 'https://generativelanguage.googleapis.com',
        isDefault: widget.existingConfig?.isDefault ?? currentConfigs.isEmpty,
        enabled: true,
      );

      await apiConfigsNotifier.addConfig(configId, config);
      
      // Set as default if it's the first one
      if (currentConfigs.isEmpty) {
        await apiConfigsNotifier.setDefault(configId);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingConfig != null 
                ? 'API configuration updated successfully!'
                : 'API configuration added successfully!',
            ),
            backgroundColor: SemanticColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save API configuration: $e'),
            backgroundColor: SemanticColors.error,
          ),
        );
      }
    }
  }
}