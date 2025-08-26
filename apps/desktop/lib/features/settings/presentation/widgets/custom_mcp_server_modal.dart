import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../../core/design_system/design_system.dart';

/// Modal for manually configuring custom MCP servers with JSON input
class CustomMCPServerModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onConfigurationComplete;
  final Map<String, dynamic>? initialConfig;

  const CustomMCPServerModal({
    super.key,
    required this.onConfigurationComplete,
    this.initialConfig,
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
        padding: EdgeInsets.all(SpacingTokens.xxl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(colors),
              SizedBox(height: SpacingTokens.sectionSpacing),
              
              // Configuration method selector
              _buildConfigurationMethodSelector(colors),
              SizedBox(height: SpacingTokens.sectionSpacing),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: configMethod == ConfigurationMethod.json
                    ? _buildJsonConfigurationView(colors)
                    : _buildManualConfigurationView(colors),
                ),
              ),
              
              SizedBox(height: SpacingTokens.sectionSpacing),
              
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
          padding: EdgeInsets.all(SpacingTokens.iconSpacing),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Icon(
            Icons.code,
            size: 24,
            color: colors.primary,
          ),
        ),
        SizedBox(width: SpacingTokens.componentSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom MCP Server Configuration',
                style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
              ),
              SizedBox(height: SpacingTokens.xs_precise),
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
        _MethodTab(
          label: 'JSON Configuration',
          isSelected: configMethod == ConfigurationMethod.json,
          onTap: () => setState(() => configMethod = ConfigurationMethod.json),
        ),
        SizedBox(width: SpacingTokens.iconSpacing),
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
        SizedBox(height: SpacingTokens.sectionSpacing),
        
        // JSON editor section
        Text(
          'MCP Server Configuration (JSON)',
          style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: SpacingTokens.componentSpacing),
        
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
                decoration: InputDecoration(
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
          SizedBox(height: SpacingTokens.iconSpacing),
          Container(
            padding: EdgeInsets.all(SpacingTokens.componentSpacing),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: colors.error, size: 16),
                SizedBox(width: SpacingTokens.iconSpacing),
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
        
        SizedBox(height: SpacingTokens.sectionSpacing),
        
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
        SizedBox(height: SpacingTokens.sectionSpacing),
        
        // Transport type selector
        _buildTransportTypeSelector(colors),
        SizedBox(height: SpacingTokens.sectionSpacing),
        
        if (transportType == TransportType.stdio) ...[
          // Command configuration
          _buildCommandConfiguration(colors),
        ] else ...[
          // URL configuration
          _buildUrlConfiguration(colors),
        ],
        
        SizedBox(height: SpacingTokens.sectionSpacing),
        
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
        SizedBox(height: SpacingTokens.iconSpacing),
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
            contentPadding: EdgeInsets.all(SpacingTokens.componentSpacing),
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
        SizedBox(height: SpacingTokens.iconSpacing),
        Row(
          children: [
            Expanded(
              child: RadioListTile<TransportType>(
                title: Text('Standard I/O'),
                subtitle: Text('Process communication'),
                value: TransportType.stdio,
                groupValue: transportType,
                onChanged: (value) => setState(() => transportType = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<TransportType>(
                title: Text('Server-Sent Events'),
                subtitle: Text('HTTP/SSE connection'),
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
        SizedBox(height: SpacingTokens.componentSpacing),
        
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
            contentPadding: EdgeInsets.all(SpacingTokens.componentSpacing),
          ),
        ),
        
        SizedBox(height: SpacingTokens.componentSpacing),
        
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
        SizedBox(height: SpacingTokens.componentSpacing),
        
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
            contentPadding: EdgeInsets.all(SpacingTokens.componentSpacing),
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
            Spacer(),
            AsmblButton.secondary(
              text: 'Add Argument',
              onPressed: _addArgument,
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.componentSpacing),
        
        if (arguments.isEmpty)
          Container(
            padding: EdgeInsets.all(SpacingTokens.componentSpacing),
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
              margin: EdgeInsets.only(bottom: SpacingTokens.iconSpacing),
              padding: EdgeInsets.all(SpacingTokens.componentSpacing),
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
                  SizedBox(width: SpacingTokens.componentSpacing),
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
          }).toList(),
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
            Spacer(),
            AsmblButton.secondary(
              text: 'Add Variable',
              onPressed: _addEnvVar,
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.componentSpacing),
        
        if (envVars.isEmpty)
          Container(
            padding: EdgeInsets.all(SpacingTokens.componentSpacing),
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
              margin: EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
              child: _EnvVarInput(
                envVar: envVar,
                onRemove: () => _removeEnvVar(index),
              ),
            );
          }).toList(),
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
          config: {
            'command': 'npx',
            'args': ['-y', '@my-org/my-mcp-server'],
          },
          onUse: (config) => _jsonConfigController.text = jsonEncode(config),
        ),
        _ExampleConfigCard(
          title: 'Python Server',
          description: 'Python-based MCP server with virtual environment',
          config: {
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
          config: {
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
        SizedBox(width: SpacingTokens.componentSpacing),
        AsmblButton.primary(
          text: 'Add MCP Server',
          onPressed: _handleAddServer,
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
      final formatted = JsonEncoder.withIndent('  ').convert(parsed);
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

  void _handleAddServer() {
    if (!_formKey.currentState!.validate()) return;
    
    final serverName = _serverNameController.text;
    Map<String, dynamic> serverConfig;
    
    if (configMethod == ConfigurationMethod.json) {
      if (parsedConfig == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fix JSON configuration errors'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
        return;
      }
      serverConfig = parsedConfig!;
    } else {
      // Build manual configuration
      if (transportType == TransportType.stdio) {
        serverConfig = {
          'command': _commandController.text,
          'args': arguments,
        };
      } else {
        serverConfig = {
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
          serverConfig['env'] = envMap;
        }
      }
    }
    
    final finalConfig = {serverName: serverConfig};
    widget.onConfigurationComplete(finalConfig);
    Navigator.of(context).pop();
  }
}

// Enums and helper classes
enum ConfigurationMethod { json, manual }
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
        padding: EdgeInsets.symmetric(
          horizontal: SpacingTokens.sectionSpacing,
          vertical: SpacingTokens.componentSpacing,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.1) : colors.surfaceVariant,
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
      padding: EdgeInsets.all(SpacingTokens.componentSpacing),
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
              decoration: InputDecoration(
                labelText: 'Variable Name',
                hintText: 'API_KEY',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          SizedBox(width: SpacingTokens.componentSpacing),
          Expanded(
            flex: 3,
            child: TextField(
              controller: envVar.valueController,
              decoration: InputDecoration(
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
      margin: EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
      padding: EdgeInsets.all(SpacingTokens.componentSpacing),
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
                    SizedBox(height: SpacingTokens.xs_precise),
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
          SizedBox(height: SpacingTokens.componentSpacing),
          Container(
            padding: EdgeInsets.all(SpacingTokens.componentSpacing),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Text(
              JsonEncoder.withIndent('  ').convert(config),
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
      title: Text('Add Argument'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
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
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty) {
              widget.onAdd(value);
              Navigator.of(context).pop();
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}