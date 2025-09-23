import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:agent_engine_core/agent_engine_core.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_template_service.dart';
import 'structured_form_renderer.dart';


import '../../../../core/models/mcp_server_config.dart';

/// Modal for manually configuring custom MCP servers with JSON input or structured forms
class CustomMCPServerModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onConfigurationComplete;
  final Map<String, dynamic>? initialConfig;
  final IntegrationDefinition? integration; // For structured form rendering
  final MCPServerTemplate? template; // Alternative structured form source

  const CustomMCPServerModal({
    super.key,
    required this.onConfigurationComplete,
    this.initialConfig,
    this.integration,
    this.template,
  });

  @override
  State<CustomMCPServerModal> createState() => _CustomMCPServerModalState();
}

class _CustomMCPServerModalState extends State<CustomMCPServerModal> {
  final _formKey = GlobalKey<FormState>();
  final _serverNameController = TextEditingController();
  final _jsonConfigController = TextEditingController();
  
  // Environment variables
  final List<_EnvVarPair> envVars = [];
  
  // Configuration method
  ConfigurationMethod configMethod = ConfigurationMethod.json;
  
  // Structured form data
  Map<String, dynamic> structuredFormValues = {};
  bool structuredFormValid = false;
  
  // Manual configuration fields
  final _commandController = TextEditingController();
  final List<String> arguments = [];
  final _argController = TextEditingController();
  
  // Transport configuration
  TransportType transportType = TransportType.stdio;
  final _urlController = TextEditingController();
  
  // Validation
  String? jsonError;
  Map<String, dynamic>? parsedConfig;
  
  @override
  void initState() {
    super.initState();
    // If we have integration or template, default to structured form
    if (widget.integration != null || widget.template != null) {
      configMethod = ConfigurationMethod.structured;
    }
    
    if (widget.initialConfig != null) {
      _loadInitialConfig(widget.initialConfig!);
    } else {
      _loadDefaultConfig();
    }
  }

  void _loadDefaultConfig() {
    _jsonConfigController.text = jsonEncode({
      'command': 'npx',
      'args': ['-y', '@my-org/my-mcp-server'],
      'env': {}
    }, toEncodable: (object) => object.toString());
  }

  void _loadInitialConfig(Map<String, dynamic> config) {
    // Extract server name (first key)
    if (config.isNotEmpty) {
      final serverName = config.keys.first;
      _serverNameController.text = serverName;
      
      final serverConfig = config[serverName] as Map<String, dynamic>;
      _jsonConfigController.text = jsonEncode(serverConfig, toEncodable: (object) => object.toString());
    }
  }

  @override
  void dispose() {
    _serverNameController.dispose();
    _jsonConfigController.dispose();
    _commandController.dispose();
    _argController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
      ),
      child: Container(
        width: 900,
        height: 800,
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(colors),
              const SizedBox(height: SpacingTokens.sectionSpacing),
              
              // Configuration method selector
              _buildConfigurationMethodSelector(colors),
              const SizedBox(height: SpacingTokens.sectionSpacing),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: _buildConfigurationContent(colors),
                ),
              ),
              
              const SizedBox(height: SpacingTokens.sectionSpacing),
              
              // Actions
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Icon(
            Icons.code,
            size: 24,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: SpacingTokens.componentSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom MCP Server Configuration',
                style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: SpacingTokens.xs_precise),
              Text(
                'Configure a custom MCP server with JSON or manual setup',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildConfigurationMethodSelector(ThemeColors colors) {
    return Row(
      children: [
        if (widget.integration != null || widget.template != null) ...[
          _MethodTab(
            label: 'Structured Form',
            isSelected: configMethod == ConfigurationMethod.structured,
            onTap: () => setState(() => configMethod = ConfigurationMethod.structured),
          ),
          const SizedBox(width: SpacingTokens.iconSpacing),
        ],
        _MethodTab(
          label: 'JSON Configuration',
          isSelected: configMethod == ConfigurationMethod.json,
          onTap: () => setState(() => configMethod = ConfigurationMethod.json),
        ),
        const SizedBox(width: SpacingTokens.iconSpacing),
        _MethodTab(
          label: 'Manual Configuration',
          isSelected: configMethod == ConfigurationMethod.manual,
          onTap: () => setState(() => configMethod = ConfigurationMethod.manual),
        ),
      ],
    );
  }

  Widget _buildJsonConfigurationView(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Server name input
        _buildServerNameInput(colors),
        const SizedBox(height: SpacingTokens.sectionSpacing),
        
        // JSON editor section
        Text(
          'MCP Server Configuration (JSON)',
          style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        
        // JSON editor
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(
              color: jsonError != null ? colors.error : colors.border,
            ),
          ),
          child: Stack(
            children: [
              TextField(
                controller: _jsonConfigController,
                onChanged: _validateJson,
                maxLines: null,
                expands: true,
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurface,
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter MCP server configuration JSON...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(SpacingTokens.componentSpacing),
                ),
              ),
              Positioned(
                top: SpacingTokens.iconSpacing,
                right: SpacingTokens.iconSpacing,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.content_paste, color: colors.primary),
                      tooltip: 'Paste from clipboard',
                      onPressed: _pasteFromClipboard,
                    ),
                    IconButton(
                      icon: Icon(Icons.auto_fix_high, color: colors.primary),
                      tooltip: 'Format JSON',
                      onPressed: _formatJson,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // JSON validation error
        if (jsonError != null) ...[
          const SizedBox(height: SpacingTokens.iconSpacing),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
            decoration: BoxDecoration(
              color: colors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: colors.error, size: 16),
                const SizedBox(width: SpacingTokens.iconSpacing),
                Expanded(
                  child: Text(
                    jsonError!,
                    style: TextStyles.caption.copyWith(color: colors.error),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: SpacingTokens.sectionSpacing),
        
        // Example configurations
        _buildExampleConfigurations(colors),
      ],
    );
  }

  Widget _buildManualConfigurationView(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Server name input
        _buildServerNameInput(colors),
        const SizedBox(height: SpacingTokens.sectionSpacing),
        
        // Transport type selector
        _buildTransportTypeSelector(colors),
        const SizedBox(height: SpacingTokens.sectionSpacing),
        
        if (transportType == TransportType.stdio) ...[
          // Command configuration
          _buildCommandConfiguration(colors),
        ] else ...[
          // URL configuration
          _buildUrlConfiguration(colors),
        ],
        
        const SizedBox(height: SpacingTokens.sectionSpacing),
        
        // Environment variables
        _buildEnvironmentVariables(colors),
      ],
    );
  }

  Widget _buildServerNameInput(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Server Name',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: SpacingTokens.iconSpacing),
        TextFormField(
          controller: _serverNameController,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Server name is required';
            }
            if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value!)) {
              return 'Server name can only contain letters, numbers, hyphens, and underscores';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'my-custom-server',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            contentPadding: const EdgeInsets.all(SpacingTokens.componentSpacing),
          ),
        ),
      ],
    );
  }

  Widget _buildTransportTypeSelector(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transport Type',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: SpacingTokens.iconSpacing),
        Row(
          children: [
            Expanded(
              child: RadioListTile<TransportType>(
                title: const Text('Standard I/O'),
                subtitle: const Text('Process communication'),
                value: TransportType.stdio,
                groupValue: transportType,
                onChanged: (value) => setState(() => transportType = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<TransportType>(
                title: const Text('Server-Sent Events'),
                subtitle: const Text('HTTP/SSE connection'),
                value: TransportType.sse,
                groupValue: transportType,
                onChanged: (value) => setState(() => transportType = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommandConfiguration(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Command Configuration',
          style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        
        // Command input
        TextFormField(
          controller: _commandController,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Command is required';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Command',
            hintText: 'npx, python, node, etc.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            contentPadding: const EdgeInsets.all(SpacingTokens.componentSpacing),
          ),
        ),
        
        const SizedBox(height: SpacingTokens.componentSpacing),
        
        // Arguments
        _buildArgumentsList(colors),
      ],
    );
  }

  Widget _buildUrlConfiguration(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'URL Configuration',
          style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        
        TextFormField(
          controller: _urlController,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'URL is required for SSE transport';
            }
            try {
              Uri.parse(value!);
            } catch (e) {
              return 'Please enter a valid URL';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Server URL',
            hintText: 'http://localhost:3845/mcp',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            contentPadding: const EdgeInsets.all(SpacingTokens.componentSpacing),
          ),
        ),
      ],
    );
  }

  Widget _buildArgumentsList(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Arguments',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            AsmblButton.secondary(
              text: 'Add Argument',
              onPressed: _addArgument,
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        
        if (arguments.isEmpty)
          Container(
            padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Text(
                'No arguments added',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          )
        else
          ...arguments.asMap().entries.map((entry) {
            final index = entry.key;
            final arg = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: SpacingTokens.iconSpacing),
              padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyles.caption.copyWith(color: colors.onPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.componentSpacing),
                  Expanded(
                    child: Text(
                      arg,
                      style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: colors.error),
                    onPressed: () => _removeArgument(index),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEnvironmentVariables(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Environment Variables',
              style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
            ),
            const Spacer(),
            AsmblButton.secondary(
              text: 'Add Variable',
              onPressed: _addEnvVar,
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        
        if (envVars.isEmpty)
          Container(
            padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Text(
                'No environment variables added',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          )
        else
          ...envVars.asMap().entries.map((entry) {
            final index = entry.key;
            final envVar = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
              child: _EnvVarInput(
                envVar: envVar,
                onRemove: () => _removeEnvVar(index),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildExampleConfigurations(ThemeColors colors) {
    return ExpansionTile(
      title: Text(
        'Example Configurations',
        style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
      ),
      children: [
        _ExampleConfigCard(
          title: 'NPX Server',
          description: 'Standard NPX-based MCP server',
          config: const {
            'command': 'npx',
            'args': ['-y', '@my-org/my-mcp-server'],
          },
          onUse: (config) => _jsonConfigController.text = jsonEncode(config),
        ),
        _ExampleConfigCard(
          title: 'Python Server',
          description: 'Python-based MCP server with virtual environment',
          config: const {
            'command': 'python',
            'args': ['-m', 'my_mcp_server'],
            'env': {
              'PYTHONPATH': '/path/to/server',
            },
          },
          onUse: (config) => _jsonConfigController.text = jsonEncode(config),
        ),
        _ExampleConfigCard(
          title: 'Local SSE Server',
          description: 'Server-sent events transport',
          config: const {
            'transport': 'sse',
            'url': 'http://localhost:8080/mcp',
          },
          onUse: (config) => _jsonConfigController.text = jsonEncode(config),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AsmblButton.secondary(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: SpacingTokens.componentSpacing),
        AsmblButton.primary(
          text: 'Add MCP Server',
          onPressed: _canAddServer() ? _handleAddServer : null,
        ),
      ],
    );
  }

  void _validateJson(String value) {
    setState(() {
      try {
        parsedConfig = jsonDecode(value);
        jsonError = null;
      } catch (e) {
        jsonError = 'Invalid JSON: ${e.toString()}';
        parsedConfig = null;
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _jsonConfigController.text = clipboardData!.text!;
      _validateJson(clipboardData.text!);
    }
  }

  void _formatJson() {
    try {
      final parsed = jsonDecode(_jsonConfigController.text);
      final formatted = const JsonEncoder.withIndent('  ').convert(parsed);
      _jsonConfigController.text = formatted;
      _validateJson(formatted);
    } catch (e) {
      // JSON is invalid, don't format
    }
  }

  void _addArgument() {
    showDialog(
      context: context,
      builder: (context) => _AddArgumentDialog(
        onAdd: (arg) => setState(() => arguments.add(arg)),
      ),
    );
  }

  void _removeArgument(int index) {
    setState(() => arguments.removeAt(index));
  }

  void _addEnvVar() {
    setState(() {
      envVars.add(_EnvVarPair(
        keyController: TextEditingController(),
        valueController: TextEditingController(),
      ));
    });
  }

  void _removeEnvVar(int index) {
    setState(() {
      envVars[index].dispose();
      envVars.removeAt(index);
    });
  }

  Widget _buildConfigurationContent(ThemeColors colors) {
    switch (configMethod) {
      case ConfigurationMethod.structured:
        return _buildStructuredConfigurationView(colors);
      case ConfigurationMethod.json:
        return _buildJsonConfigurationView(colors);
      case ConfigurationMethod.manual:
        return _buildManualConfigurationView(colors);
    }
  }

  Widget _buildStructuredConfigurationView(ThemeColors colors) {
    final configFields = _getConfigFields();
    
    if (configFields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              size: 48,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'No configuration fields available for this integration.',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Please use JSON or Manual configuration instead.',
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Server name input
        _buildServerNameInput(colors),
        const SizedBox(height: SpacingTokens.sectionSpacing),
        
        // Integration info (if available)
        if (widget.integration != null) ...[
          _buildIntegrationInfo(widget.integration!, colors),
          const SizedBox(height: SpacingTokens.sectionSpacing),
        ],
        
        // Structured form
        Text(
          'Configuration',
          style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        
        StructuredFormRenderer(
          configFields: configFields,
          initialValues: structuredFormValues,
          onValuesChanged: (values, isValid) {
            setState(() {
              structuredFormValues = values;
              structuredFormValid = isValid;
            });
          },
        ),
      ],
    );
  }

  Widget _buildIntegrationInfo(IntegrationDefinition integration, ThemeColors colors) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(
                  Icons.integration_instructions,
                  size: 20,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: SpacingTokens.componentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      integration.name,
                      style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: SpacingTokens.xs_precise),
                    Text(
                      integration.description,
                      style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<dynamic> _getConfigFields() {
    if (widget.integration != null) {
      return widget.integration!.configFields;
    }
    if (widget.template != null) {
      return widget.template!.configFields;
    }
    return [];
  }

  bool _canAddServer() {
    switch (configMethod) {
      case ConfigurationMethod.structured:
        return _serverNameController.text.isNotEmpty && structuredFormValid;
      case ConfigurationMethod.json:
        return _serverNameController.text.isNotEmpty && parsedConfig != null;
      case ConfigurationMethod.manual:
        return _formKey.currentState?.validate() ?? false;
    }
  }

  void _handleAddServer() {
    if (!_canAddServer()) return;
    
    final serverName = _serverNameController.text;
    Map<String, dynamic> serverConfigData;
    
    if (configMethod == ConfigurationMethod.structured) {
      // Use structured form values to build server config
      serverConfigData = _buildServerConfigFromStructuredForm();
    } else if (configMethod == ConfigurationMethod.json) {
      if (parsedConfig == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please fix JSON configuration errors'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
        return;
      }
      serverConfigData = parsedConfig!;
    } else {
      // Build manual configuration
      if (transportType == TransportType.stdio) {
        serverConfigData = {
          'command': _commandController.text,
          'args': arguments,
        };
      } else {
        serverConfigData = {
          'transport': 'sse',
          'url': _urlController.text,
        };
      }
      
      // Add environment variables
      if (envVars.isNotEmpty) {
        final envMap = <String, String>{};
        for (final envVar in envVars) {
          final key = envVar.keyController.text.trim();
          final value = envVar.valueController.text.trim();
          if (key.isNotEmpty && value.isNotEmpty) {
            envMap[key] = value;
          }
        }
        if (envMap.isNotEmpty) {
          serverConfigData['env'] = envMap;
        }
      }
    }
    
    // Create MCPServerConfig object
    final mcpConfig = MCPServerConfig(
      id: serverName,
      name: widget.integration?.name ?? serverName,
      command: serverConfigData['command']?.toString() ?? 'npx',
      args: List<String>.from(serverConfigData['args'] ?? []),
      env: serverConfigData['env'] != null ? Map<String, String>.from(serverConfigData['env']) : null,
      description: widget.integration?.description ?? 'Custom MCP Server',
      enabled: true,
      createdAt: DateTime.now(),
      transport: serverConfigData['transport']?.toString(),
      url: serverConfigData['url']?.toString() ?? 'local://$serverName',
    );
    
    // For backward compatibility with existing callers, pass the raw config format
    final finalConfig = {serverName: serverConfigData};
    widget.onConfigurationComplete(finalConfig);
    Navigator.of(context).pop();
  }

  Map<String, dynamic> _buildServerConfigFromStructuredForm() {
    // Build environment variables from form
    final envVars = <String, String>{};
    for (final entry in structuredFormValues.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value != null && value.toString().isNotEmpty) {
        // Convert to environment variable format
        final envKey = key.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_]'), '_');
        envVars[envKey] = value.toString();
      }
    }
    
    // Extract command and args from integration/template defaults
    String command = 'npx';
    List<String> args = [];
    String? transport;
    String? url;
    
    if (widget.integration != null) {
      command = widget.integration!.command;
      args = List<String>.from(widget.integration!.args);
    } else if (widget.template != null) {
      final serverDefaults = widget.template!.serverDefaults;
      command = serverDefaults['command']?.toString() ?? 'npx';
      if (serverDefaults['args'] is List) {
        args = List<String>.from(serverDefaults['args']);
      }
      transport = serverDefaults['transport']?.toString();
      url = serverDefaults['url']?.toString();
    }
    
    // Create the config object that matches what CustomMCPServerModal expects
    final config = <String, dynamic>{
      'command': command,
      'args': args,
    };
    
    if (transport != null) {
      config['transport'] = transport;
    }
    if (url != null) {
      config['url'] = url;
    }
    if (envVars.isNotEmpty) {
      config['env'] = envVars;
    }
    
    return config;
  }
}

// Enums and helper classes
enum ConfigurationMethod { json, manual, structured }
enum TransportType { stdio, sse }

class _EnvVarPair {
  final TextEditingController keyController;
  final TextEditingController valueController;
  
  _EnvVarPair({
    required this.keyController,
    required this.valueController,
  });
  
  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

// Helper widgets
class _MethodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _MethodTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sectionSpacing,
          vertical: SpacingTokens.componentSpacing,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withOpacity(0.1) : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyles.bodyMedium.copyWith(
            color: isSelected ? colors.primary : colors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _EnvVarInput extends StatelessWidget {
  final _EnvVarPair envVar;
  final VoidCallback onRemove;
  
  const _EnvVarInput({
    required this.envVar,
    required this.onRemove,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: envVar.keyController,
              decoration: const InputDecoration(
                labelText: 'Variable Name',
                hintText: 'API_KEY',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.componentSpacing),
          Expanded(
            flex: 3,
            child: TextField(
              controller: envVar.valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'your-api-key-here',
                border: InputBorder.none,
                isDense: true,
              ),
              obscureText: true,
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: colors.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ExampleConfigCard extends StatelessWidget {
  final String title;
  final String description;
  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onUse;
  
  const _ExampleConfigCard({
    required this.title,
    required this.description,
    required this.config,
    required this.onUse,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
      padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: SpacingTokens.xs_precise),
                    Text(
                      description,
                      style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              AsmblButton.secondary(
                text: 'Use',
                onPressed: () => onUse(config),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.componentSpacing),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Text(
              const JsonEncoder.withIndent('  ').convert(config),
              style: TextStyles.caption.copyWith(
                color: colors.onSurface,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddArgumentDialog extends StatefulWidget {
  final Function(String) onAdd;
  
  const _AddArgumentDialog({required this.onAdd});
  
  @override
  State<_AddArgumentDialog> createState() => _AddArgumentDialogState();
}

class _AddArgumentDialogState extends State<_AddArgumentDialog> {
  final _controller = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Argument'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Argument',
          hintText: '--port 8080',
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            widget.onAdd(value);
            Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty) {
              widget.onAdd(value);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}