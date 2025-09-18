import 'package:flutter/material.dart';
import '../design_system.dart';
import 'mcp_field_types.dart';
import 'oauth_fields.dart';
import 'service_detection_fields.dart';
import '../../models/enhanced_mcp_template.dart';

/// Smart MCP configuration form that automatically generates UI
/// from enhanced template definitions
class SmartMCPForm extends StatefulWidget {
  final EnhancedMCPTemplate template;
  final Map<String, dynamic> initialValues;
  final ValueChanged<Map<String, dynamic>>? onValuesChanged;
  final VoidCallback? onValidationChanged;
  final bool showAdvanced;

  const SmartMCPForm({
    super.key,
    required this.template,
    this.initialValues = const {},
    this.onValuesChanged,
    this.onValidationChanged,
    this.showAdvanced = false,
  });

  @override
  State<SmartMCPForm> createState() => _SmartMCPFormState();
}

class _SmartMCPFormState extends State<SmartMCPForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _values;
  final Map<String, bool> _fieldValidation = {};

  @override
  void initState() {
    super.initState();
    _values = Map.from(widget.initialValues);
    _initializeDefaultValues();
  }

  void _initializeDefaultValues() {
    for (final field in widget.template.fields) {
      if (!_values.containsKey(field.id) && field.defaultValue != null) {
        _values[field.id] = field.defaultValue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template header with branding
          _buildTemplateHeader(context),
          
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Prerequisites check
          if (widget.template.prerequisites.isNotEmpty) ...[
            _buildPrerequisites(context),
            const SizedBox(height: SpacingTokens.sectionSpacing),
          ],
          
          // Auto-generated form fields
          ...widget.template.fields.map((field) => _buildFieldFromDefinition(context, field)),
          
          // Advanced options
          if (widget.showAdvanced) ...[
            const SizedBox(height: SpacingTokens.sectionSpacing),
            _buildAdvancedOptions(context),
          ],
          
          // Setup instructions
          if (widget.template.setupInstructions.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.sectionSpacing),
            _buildSetupInstructions(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (widget.template.brandColor ?? SemanticColors.primary).withOpacity( 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (widget.template.brandColor ?? SemanticColors.primary).withOpacity( 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (widget.template.brandColor ?? SemanticColors.primary).withOpacity( 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.template.icon,
              color: widget.template.brandColor ?? SemanticColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.template.name,
                      style: TextStyle(
                        color: widget.template.brandColor ?? SemanticColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildDifficultyBadge(context),
                    if (widget.template.isPopular) ...[
                      const SizedBox(width: 8),
                      _buildPopularBadge(context),
                    ],
                  ],
                ),
                Text(
                  widget.template.description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (widget.template.capabilities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: widget.template.capabilities.take(4).map((capability) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity( 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          capability,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(BuildContext context) {
    Color badgeColor;
    switch (widget.template.difficulty.toLowerCase()) {
      case 'easy':
        badgeColor = SemanticColors.success;
        break;
      case 'medium':
        badgeColor = Colors.orange;
        break;
      case 'hard':
        badgeColor = SemanticColors.error;
        break;
      default:
        badgeColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.template.difficulty,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPopularBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: SemanticColors.primary.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 8,
            color: SemanticColors.primary,
          ),
          SizedBox(width: 2),
          Text(
            'Popular',
            style: TextStyle(
              color: SemanticColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrerequisites(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity( 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Text(
                'Prerequisites',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.template.prerequisites.map((prereq) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 12,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prereq,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFieldFromDefinition(BuildContext context, MCPFieldDefinition field) {
    Widget fieldWidget;

    switch (field.fieldType) {
      case MCPFieldType.text:
      case MCPFieldType.email:
      case MCPFieldType.url:
      case MCPFieldType.password:
        fieldWidget = _buildTextFormField(field);
        break;
        
      case MCPFieldType.number:
        fieldWidget = _buildNumberField(field);
        break;
        
      case MCPFieldType.boolean:
        fieldWidget = _buildBooleanField(field);
        break;
        
      case MCPFieldType.select:
        fieldWidget = _buildSelectField(field);
        break;
        
      case MCPFieldType.path:
      case MCPFieldType.file:
      case MCPFieldType.directory:
        fieldWidget = _buildPathField(field);
        break;
        
      case MCPFieldType.apiToken:
        fieldWidget = _buildApiTokenField(field);
        break;
        
      case MCPFieldType.oauth:
        fieldWidget = _buildOAuthField(field);
        break;
        
      case MCPFieldType.database:
        fieldWidget = _buildDatabaseField(field);
        break;
        
      case MCPFieldType.serviceDetection:
        fieldWidget = _buildServiceDetectionField(field);
        break;
        
      case MCPFieldType.permissionScope:
        fieldWidget = _buildPermissionScopeField(field);
        break;
        
      default:
        fieldWidget = _buildTextFormField(field);
    }

    return Column(
      children: [
        fieldWidget,
        const SizedBox(height: SpacingTokens.sectionSpacing),
      ],
    );
  }

  Widget _buildTextFormField(MCPFieldDefinition field) {
    return TextFormField(
      initialValue: _values[field.id]?.toString(),
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        hintText: field.placeholder,
        helperText: field.description,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      obscureText: field.fieldType == MCPFieldType.password,
      keyboardType: _getKeyboardType(field.fieldType),
      validator: (value) => _validateField(field, value),
      onChanged: (value) => _updateValue(field.id, value),
    );
  }

  Widget _buildNumberField(MCPFieldDefinition field) {
    return TextFormField(
      initialValue: _values[field.id]?.toString(),
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        hintText: field.placeholder,
        helperText: field.description,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) => _validateField(field, value),
      onChanged: (value) {
        final numValue = int.tryParse(value) ?? double.tryParse(value);
        _updateValue(field.id, numValue);
      },
    );
  }

  Widget _buildBooleanField(MCPFieldDefinition field) {
    return Row(
      children: [
        Switch(
          value: _values[field.id] ?? field.defaultValue ?? false,
          onChanged: (value) => _updateValue(field.id, value),
          thumbColor: MaterialStateProperty.all(SemanticColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (field.description != null)
                Text(
                  field.description!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectField(MCPFieldDefinition field) {
    final options = (field.options['options'] as List<SelectOption>?) ?? [];
    
    return SelectField(
      label: field.label,
      description: field.description,
      placeholder: field.placeholder,
      required: field.required,
      value: _values[field.id]?.toString(),
      options: options,
      onChanged: (value) => _updateValue(field.id, value),
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildPathField(MCPFieldDefinition field) {
    return PathPickerField(
      label: field.label,
      description: field.description,
      placeholder: field.placeholder,
      required: field.required,
      value: _values[field.id]?.toString(),
      isDirectory: field.fieldType == MCPFieldType.directory,
      showPreview: field.options['showPreview'] ?? false,
      onChanged: (value) => _updateValue(field.id, value),
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildApiTokenField(MCPFieldDefinition field) {
    return ApiTokenField(
      label: field.label,
      description: field.description,
      placeholder: field.placeholder,
      required: field.required,
      value: _values[field.id]?.toString(),
      tokenFormat: field.options['tokenFormat'],
      showValidationStatus: field.options['showValidation'] ?? false,
      onChanged: (value) => _updateValue(field.id, value),
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildOAuthField(MCPFieldDefinition field) {
    final provider = field.options['provider'] as OAuthProvider?;
    if (provider == null) return const SizedBox.shrink();
    
    return OAuthField(
      label: field.label,
      description: field.description,
      required: field.required,
      value: _values[field.id]?.toString(),
      provider: provider,
      scopes: (field.options['scopes'] as List<String>?) ?? [],
      onChanged: (value) => _updateValue(field.id, value),
    );
  }

  Widget _buildDatabaseField(MCPFieldDefinition field) {
    return DatabaseConnectionField(
      label: field.label,
      description: field.description,
      required: field.required,
      value: _values[field.id]?.toString(),
      dbType: field.options['dbType'] ?? 'generic',
      showAdvanced: field.options['showAdvanced'] ?? false,
      onChanged: (value) => _updateValue(field.id, value),
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildServiceDetectionField(MCPFieldDefinition field) {
    final serviceType = field.options['serviceType'] as ServiceType?;
    if (serviceType == null) return const SizedBox.shrink();
    
    return ServiceDetectionField(
      label: field.label,
      description: field.description,
      required: field.required,
      serviceType: serviceType,
      onChanged: (value) => _updateValue(field.id, value),
    );
  }

  Widget _buildPermissionScopeField(MCPFieldDefinition field) {
    final provider = field.options['provider'] as OAuthProvider?;
    if (provider == null) return const SizedBox.shrink();
    
    return PermissionScopeField(
      label: field.label,
      description: field.description,
      provider: provider,
      selectedScopes: (_values[field.id] as List<String>?) ?? [],
      onScopesChanged: (scopes) => _updateValue(field.id, scopes),
    );
  }

  Widget _buildAdvancedOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Options',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        // Add advanced configuration options here
      ],
    );
  }

  Widget _buildSetupInstructions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SemanticColors.primary.withOpacity( 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SemanticColors.primary.withOpacity( 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 16,
                color: SemanticColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Setup Instructions',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: SemanticColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.template.setupInstructions.map((instruction) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: SemanticColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        instruction.step.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instruction.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          instruction.description,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (instruction.actionUrl != null) ...[
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () {
                              // Open URL
                            },
                            child: Text(
                              instruction.actionText ?? 'Learn More',
                              style: TextStyles.caption,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  TextInputType _getKeyboardType(MCPFieldType fieldType) {
    switch (fieldType) {
      case MCPFieldType.email:
        return TextInputType.emailAddress;
      case MCPFieldType.url:
        return TextInputType.url;
      case MCPFieldType.number:
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  String? _validateField(MCPFieldDefinition field, String? value) {
    if (field.required && (value?.trim().isEmpty ?? true)) {
      return '${field.label} is required';
    }
    
    if (value != null && value.isNotEmpty && field.validationPattern != null) {
      final regex = RegExp(field.validationPattern!);
      if (!regex.hasMatch(value)) {
        return field.validationMessage ?? 'Invalid format';
      }
    }
    
    return null;
  }

  void _updateValue(String fieldId, dynamic value) {
    setState(() {
      _values[fieldId] = value;
    });
    widget.onValuesChanged?.call(_values);
  }
}