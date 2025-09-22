import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_template_service.dart';

/// A widget that renders structured forms based on IntegrationDefinition configFields
/// or MCPConfigField definitions with automatic validation and value collection
class StructuredFormRenderer extends StatefulWidget {
  final List<dynamic> configFields; // Can be IntegrationConfigField or MCPConfigField
  final Map<String, dynamic> initialValues;
  final Function(Map<String, dynamic> values, bool isValid) onValuesChanged;
  final bool isEnabled;

  const StructuredFormRenderer({
    super.key,
    required this.configFields,
    this.initialValues = const {},
    required this.onValuesChanged,
    this.isEnabled = true,
  });

  @override
  State<StructuredFormRenderer> createState() => _StructuredFormRendererState();
}

class _StructuredFormRendererState extends State<StructuredFormRenderer> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _updateParent();
  }

  @override
  void didUpdateWidget(StructuredFormRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.configFields != oldWidget.configFields ||
        widget.initialValues != oldWidget.initialValues) {
      _disposeControllers();
      _initializeControllers();
      _updateParent();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  void _initializeControllers() {
    _values.clear();
    _errors.clear();

    for (final field in widget.configFields) {
      final fieldId = _getFieldId(field);
      final initialValue = widget.initialValues[fieldId];
      
      // Initialize value
      if (initialValue != null) {
        _values[fieldId] = initialValue;
      } else {
        final defaultValue = _getFieldDefaultValue(field);
        if (defaultValue != null) {
          _values[fieldId] = defaultValue;
        }
      }

      // Initialize controller for text-based fields
      final fieldType = _getFieldType(field);
      if (_needsTextController(fieldType)) {
        final textValue = _values[fieldId]?.toString() ?? '';
        _controllers[fieldId] = TextEditingController(text: textValue);
        _controllers[fieldId]!.addListener(() {
          final value = _controllers[fieldId]!.text;
          _values[fieldId] = _convertValue(value, fieldType);
          _validateField(field);
          _updateParent();
        });
      }
    }
  }

  void _validateField(dynamic field) {
    final fieldId = _getFieldId(field);
    final value = _values[fieldId];
    final fieldType = _getFieldType(field);
    final isRequired = _getFieldRequired(field);

    String? error;

    // Required field validation
    if (isRequired && (value == null || value.toString().trim().isEmpty)) {
      error = '${_getFieldLabel(field)} is required';
    }
    // Type-specific validation
    else if (value != null && value.toString().isNotEmpty) {
      error = _validateFieldType(field, value);
    }

    setState(() {
      _errors[fieldId] = error;
    });
  }

  String? _validateFieldType(dynamic field, dynamic value) {
    final fieldType = _getFieldType(field);
    final label = _getFieldLabel(field);

    switch (fieldType) {
      case 'email':
        if (!_isValidEmail(value.toString())) {
          return '$label must be a valid email address';
        }
        break;
      case 'url':
        if (!_isValidUrl(value.toString())) {
          return '$label must be a valid URL';
        }
        break;
      case 'number':
        if (double.tryParse(value.toString()) == null) {
          return '$label must be a valid number';
        }
        break;
      case 'path':
      case 'directory':
        // TODO: Add file/directory validation if needed
        break;
    }

    // Check custom validation pattern
    final validation = _getFieldValidation(field);
    if (validation != null && validation.pattern != null) {
      final pattern = RegExp(validation.pattern!);
      if (!pattern.hasMatch(value.toString())) {
        return validation.message ?? '$label format is invalid';
      }
    }

    // Check min/max for numbers
    if (fieldType == 'number' && validation != null) {
      final numValue = double.tryParse(value.toString());
      if (numValue != null) {
        if (validation.min != null && numValue < validation.min!) {
          return '$label must be at least ${validation.min}';
        }
        if (validation.max != null && numValue > validation.max!) {
          return '$label must be at most ${validation.max}';
        }
      }
    }

    return null;
  }

  void _updateParent() {
    final hasErrors = _errors.values.any((error) => error != null);
    widget.onValuesChanged(_values, !hasErrors);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.configFields.map<Widget>((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.sectionSpacing),
            child: _buildFieldWidget(field, colors),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFieldWidget(dynamic field, ThemeColors colors) {
    final fieldType = _getFieldType(field);
    final fieldId = _getFieldId(field);

    switch (fieldType) {
      case 'boolean':
        return _buildBooleanField(field, colors);
      case 'select':
        return _buildSelectField(field, colors);
      case 'password':
        return _buildTextFieldWithObscure(field, colors, true);
      case 'text':
      case 'email':
      case 'url':
      case 'number':
      case 'path':
      case 'directory':
      case 'file':
        return _buildTextField(field, colors);
      default:
        return _buildUnknownFieldFallback(field, colors);
    }
  }

  Widget _buildTextField(dynamic field, ThemeColors colors) {
    final fieldId = _getFieldId(field);
    final controller = _controllers[fieldId];
    final error = _errors[fieldId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(field, colors),
        const SizedBox(height: SpacingTokens.iconSpacing),
        Container(
          decoration: BoxDecoration(
            color: widget.isEnabled ? colors.surfaceVariant : colors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(
              color: error != null ? colors.error : colors.border,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: widget.isEnabled,
            decoration: InputDecoration(
              hintText: _getFieldPlaceholder(field),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(SpacingTokens.componentSpacing),
            ),
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
            keyboardType: _getKeyboardType(_getFieldType(field)),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: SpacingTokens.xs_precise),
          Text(
            error,
            style: TextStyles.caption.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildTextFieldWithObscure(dynamic field, ThemeColors colors, bool obscureText) {
    final fieldId = _getFieldId(field);
    final controller = _controllers[fieldId];
    final error = _errors[fieldId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(field, colors),
        const SizedBox(height: SpacingTokens.iconSpacing),
        Container(
          decoration: BoxDecoration(
            color: widget.isEnabled ? colors.surfaceVariant : colors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(
              color: error != null ? colors.error : colors.border,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: widget.isEnabled,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: _getFieldPlaceholder(field),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(SpacingTokens.componentSpacing),
              suffixIcon: Icon(
                Icons.key,
                color: colors.primary,
              ),
            ),
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: SpacingTokens.xs_precise),
          Text(
            error,
            style: TextStyles.caption.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildBooleanField(dynamic field, ThemeColors colors) {
    final fieldId = _getFieldId(field);
    final value = _values[fieldId] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: value as bool,
              onChanged: widget.isEnabled ? (bool? newValue) {
                setState(() {
                  _values[fieldId] = newValue ?? false;
                });
                _updateParent();
              } : null,
              activeColor: colors.primary,
            ),
            const SizedBox(width: SpacingTokens.iconSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getFieldLabel(field),
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_getFieldDescription(field).isNotEmpty) ...[
                    const SizedBox(height: SpacingTokens.xs_precise),
                    Text(
                      _getFieldDescription(field),
                      style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectField(dynamic field, ThemeColors colors) {
    final fieldId = _getFieldId(field);
    final value = _values[fieldId];
    final options = _getFieldOptions(field);
    final error = _errors[fieldId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(field, colors),
        const SizedBox(height: SpacingTokens.iconSpacing),
        Container(
          decoration: BoxDecoration(
            color: widget.isEnabled ? colors.surfaceVariant : colors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(
              color: error != null ? colors.error : colors.border,
            ),
          ),
          child: DropdownButtonFormField<dynamic>(
            value: value,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(SpacingTokens.componentSpacing),
              hintText: _getFieldPlaceholder(field),
            ),
            items: options.map<DropdownMenuItem<dynamic>>((option) {
              final optionValue = _getOptionValue(option);
              final optionLabel = _getOptionLabel(option);
              return DropdownMenuItem<dynamic>(
                value: optionValue,
                child: Text(
                  optionLabel,
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                ),
              );
            }).toList(),
            onChanged: widget.isEnabled ? (newValue) {
              setState(() {
                _values[fieldId] = newValue;
              });
              _validateField(field);
              _updateParent();
            } : null,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: SpacingTokens.xs_precise),
          Text(
            error,
            style: TextStyles.caption.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldLabel(dynamic field, ThemeColors colors) {
    final isRequired = _getFieldRequired(field);
    final description = _getFieldDescription(field);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _getFieldLabel(field),
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: SpacingTokens.xs_precise),
              Text(
                '*',
                style: TextStyles.bodyMedium.copyWith(color: colors.error),
              ),
            ],
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: SpacingTokens.xs_precise),
          Text(
            description,
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  // Utility methods to handle both IntegrationConfigField and MCPConfigField
  String _getFieldId(dynamic field) {
    if (field is MCPConfigField) {
      return field.name;
    }
    // IntegrationConfigField from agent_engine_core
    return field.id ?? field.name ?? '';
  }

  String _getFieldLabel(dynamic field) {
    if (field is MCPConfigField) {
      return field.label;
    }
    return field.label ?? field.name ?? '';
  }

  String _getFieldType(dynamic field) {
    if (field is MCPConfigField) {
      return field.type;
    }
    // Map IntegrationFieldType to string
    return field.fieldType?.toString().split('.').last ?? 'text';
  }

  bool _getFieldRequired(dynamic field) {
    if (field is MCPConfigField) {
      return field.required;
    }
    return field.required ?? false;
  }

  String _getFieldDescription(dynamic field) {
    if (field is MCPConfigField) {
      return field.description;
    }
    return field.description ?? '';
  }

  String? _getFieldPlaceholder(dynamic field) {
    if (field is MCPConfigField) {
      return field.placeholder;
    }
    return field.placeholder;
  }

  dynamic _getFieldDefaultValue(dynamic field) {
    if (field is MCPConfigField) {
      return field.defaultValue;
    }
    return field.defaultValue;
  }

  List<dynamic> _getFieldOptions(dynamic field) {
    if (field is MCPConfigField) {
      return field.options ?? [];
    }
    return field.options ?? [];
  }

  MCPFieldValidation? _getFieldValidation(dynamic field) {
    if (field is MCPConfigField) {
      return field.validation;
    }
    // Convert IntegrationFieldValidation to MCPFieldValidation if needed
    return null; // TODO: Handle IntegrationDefinition validation if needed
  }

  dynamic _getOptionValue(dynamic option) {
    if (option is MCPSelectOption) {
      return option.value;
    }
    return option.value ?? option;
  }

  String _getOptionLabel(dynamic option) {
    if (option is MCPSelectOption) {
      return option.label;
    }
    return option.label ?? option.toString();
  }

  bool _needsTextController(String fieldType) {
    return !['boolean', 'select'].contains(fieldType);
  }

  dynamic _convertValue(String textValue, String fieldType) {
    switch (fieldType) {
      case 'number':
        return double.tryParse(textValue) ?? textValue;
      case 'boolean':
        return textValue.toLowerCase() == 'true';
      default:
        return textValue;
    }
  }

  TextInputType _getKeyboardType(String fieldType) {
    switch (fieldType) {
      case 'email':
        return TextInputType.emailAddress;
      case 'number':
        return TextInputType.number;
      case 'url':
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Widget _buildUnknownFieldFallback(dynamic field, ThemeColors colors) {
    final fieldId = _getFieldId(field);
    final fieldType = _getFieldType(field);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(field, colors),
        const SizedBox(height: SpacingTokens.iconSpacing),
        Container(
          padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(color: colors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: colors.primary, size: 16),
                  const SizedBox(width: SpacingTokens.iconSpacing),
                  Text(
                    'Unknown field type: $fieldType',
                    style: TextStyles.caption.copyWith(color: colors.primary),
                  ),
                ],
              ),
              const SizedBox(height: SpacingTokens.iconSpacing),
              Text(
                'This field type is not supported by the structured form. Please use JSON configuration mode to set this field manually.',
                style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}