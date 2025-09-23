import 'package:flutter/material.dart';
import '../design_system.dart';
import '../../services/desktop/file_system_service.dart';

/// Universal field type system for MCP server configuration
/// Supports all server types: local, cloud, enterprise, database, etc.

// Base abstract class for all MCP fields
abstract class MCPField extends StatelessWidget {
  final String label;
  final String? description;
  final String? placeholder;
  final bool required;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? Function(String?)? validator;

  const MCPField({
    super.key,
    required this.label,
    this.description,
    this.placeholder,
    this.required = false,
    this.value,
    this.onChanged,
    this.validator,
  });
}

/// Path picker field for file/folder selection
/// Used by: Filesystem, Git, Memory, SQLite, etc.
class PathPickerField extends MCPField {
  final bool isDirectory;
  final String? initialDirectory;
  final List<String>? allowedExtensions;
  final bool showPreview;

  const PathPickerField({
    super.key,
    required super.label,
    super.description,
    super.placeholder,
    super.required,
    super.value,
    super.onChanged,
    super.validator,
    this.isDirectory = true,
    this.initialDirectory,
    this.allowedExtensions,
    this.showPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        const SizedBox(height: SpacingTokens.componentSpacing),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: value,
                decoration: InputDecoration(
                  hintText: placeholder ?? (isDirectory ? 'Choose folder...' : 'Choose file...'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: Icon(
                    isDirectory ? Icons.folder_open : Icons.file_open,
                    color: SemanticColors.primary,
                  ),
                ),
                readOnly: true,
                validator: validator ?? (this.required ? _defaultValidator : null),
              ),
            ),
            const SizedBox(width: SpacingTokens.componentSpacing),
            AsmblButton.secondary(
              text: 'Browse',
              icon: Icons.folder,
              onPressed: () => _pickPath(context),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (showPreview && value != null && value!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildPathPreview(context),
        ],
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (this.required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: SemanticColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPathPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDirectory ? Icons.folder : Icons.file_present,
            size: 16,
            color: SemanticColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value!,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _openInExplorer(context),
            icon: const Icon(Icons.open_in_new, size: 14),
            tooltip: 'Open in Explorer',
            style: IconButton.styleFrom(
              minimumSize: const Size(24, 24),
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPath(BuildContext context) async {
    try {
      final fileSystemService = DesktopFileSystemService.instance;
      String? selectedPath;

      if (isDirectory) {
        selectedPath = await fileSystemService.pickDirectory();
      } else {
        selectedPath = await fileSystemService.pickFile(
          allowedExtensions: allowedExtensions,
        );
      }

      if (selectedPath != null && onChanged != null) {
        onChanged!(selectedPath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select path: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    }
  }

  Future<void> _openInExplorer(BuildContext context) async {
    if (value == null || value!.isEmpty) return;
    
    try {
      final fileSystemService = DesktopFileSystemService.instance;
      await fileSystemService.openDirectoryInExplorer(value!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open in explorer: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    }
  }

  String? _defaultValidator(String? value) {
    if (this.required && (value?.trim().isEmpty ?? true)) {
      return '$label is required';
    }
    return null;
  }
}

/// API token field with validation and formatting
/// Used by: GitHub, Figma, OpenAI, Anthropic, Brave Search, etc.
class ApiTokenField extends MCPField {
  final String? tokenFormat;
  final bool isSecret;
  final VoidCallback? onValidate;
  final bool showValidationStatus;

  const ApiTokenField({
    super.key,
    required super.label,
    super.description,
    super.placeholder,
    super.required,
    super.value,
    super.onChanged,
    super.validator,
    this.tokenFormat,
    this.isSecret = true,
    this.onValidate,
    this.showValidationStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        const SizedBox(height: SpacingTokens.componentSpacing),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: value,
                decoration: InputDecoration(
                  hintText: placeholder ?? _getPlaceholderFromFormat(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(
                    Icons.key,
                    color: SemanticColors.primary,
                  ),
                  suffixIcon: showValidationStatus ? _buildValidationIcon() : null,
                ),
                obscureText: isSecret,
                onChanged: onChanged,
                validator: validator ?? (this.required ? _tokenValidator : null),
              ),
            ),
            if (onValidate != null) ...[
              const SizedBox(width: SpacingTokens.componentSpacing),
              AsmblButton.secondary(
                text: 'Test',
                icon: Icons.check_circle_outline,
                onPressed: onValidate,
              ),
            ],
          ],
        ),
        if (description != null || tokenFormat != null) ...[
          const SizedBox(height: 4),
          if (tokenFormat != null)
            Text(
              'Format: $tokenFormat',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (description != null) ...[
            if (tokenFormat != null) const SizedBox(height: 2),
            Text(
              description!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (this.required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: SemanticColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        if (isSecret) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.lock_outline,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }

  Widget? _buildValidationIcon() {
    // This would be connected to actual validation state
    return const Icon(
      Icons.check_circle,
      color: SemanticColors.success,
      size: 20,
    );
  }

  String? _getPlaceholderFromFormat() {
    if (tokenFormat == null) return null;
    
    switch (tokenFormat) {
      case 'github_pat':
        return 'ghp_xxxxxxxxxxxxxxxxxxxx';
      case 'figma_token':
        return 'figd_xxxxxxxxxxxxxxxxxxxx';
      case 'openai_key':
        return 'sk-xxxxxxxxxxxxxxxxxxxx';
      case 'anthropic_key':
        return 'sk-ant-xxxxxxxxxxxxxxxxxxxx';
      case 'brave_key':
        return 'BSA_xxxxxxxxxxxxxxxxxxxx';
      default:
        return 'Enter your $label...';
    }
  }

  String? _tokenValidator(String? value) {
    if (this.required && (value?.trim().isEmpty ?? true)) {
      return '$label is required';
    }
    
    if (value != null && value.isNotEmpty && tokenFormat != null) {
      if (!_validateTokenFormat(value, tokenFormat!)) {
        return 'Invalid token format for $tokenFormat';
      }
    }
    
    return null;
  }

  bool _validateTokenFormat(String token, String format) {
    switch (format) {
      case 'github_pat':
        return token.startsWith('ghp_') || token.startsWith('github_pat_');
      case 'figma_token':
        return token.startsWith('figd_');
      case 'openai_key':
        return token.startsWith('sk-') && token.length >= 50;
      case 'anthropic_key':
        return token.startsWith('sk-ant-');
      case 'brave_key':
        return token.startsWith('BSA_');
      default:
        return true; // No validation for unknown formats
    }
  }
}

/// Select dropdown field for predefined options
/// Used by: Cloud regions, database types, permission levels, etc.
class SelectField extends MCPField {
  final List<SelectOption> options;
  final bool allowCustom;
  final Widget? customOptionWidget;

  const SelectField({
    super.key,
    required super.label,
    super.description,
    super.placeholder,
    super.required,
    super.value,
    super.onChanged,
    super.validator,
    required this.options,
    this.allowCustom = false,
    this.customOptionWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        const SizedBox(height: SpacingTokens.componentSpacing),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: placeholder ?? 'Select ${label.toLowerCase()}...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(
              Icons.arrow_drop_down,
              color: SemanticColors.primary,
            ),
          ),
          items: [
            ...options.map((option) => DropdownMenuItem<String>(
              value: option.value,
              child: Row(
                children: [
                  if (option.icon != null) ...[
                    Icon(option.icon, size: 16),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: Text(option.label)),
                  if (option.badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: option.badgeColor ?? SemanticColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        option.badge!,
                        style: TextStyle(
                          color: option.badgeColor ?? SemanticColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )),
            if (allowCustom)
              const DropdownMenuItem<String>(
                value: '__custom__',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 8),
                    Text('Custom...'),
                  ],
                ),
              ),
          ],
          onChanged: (newValue) {
            if (newValue == '__custom__') {
              _showCustomInput(context);
            } else {
              onChanged?.call(newValue);
            }
          },
          validator: validator ?? (this.required ? _defaultValidator : null),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (this.required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: SemanticColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  void _showCustomInput(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Custom $label'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter custom value...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final customValue = controller.text.trim();
              if (customValue.isNotEmpty) {
                onChanged?.call(customValue);
              }
              Navigator.of(context).pop();
            },
            child: Text('Set'),
          ),
        ],
      ),
    );
  }

  String? _defaultValidator(String? value) {
    if (this.required && (value?.trim().isEmpty ?? true)) {
      return '$label is required';
    }
    return null;
  }
}

/// Connection string builder for databases
/// Used by: PostgreSQL, MySQL, SQLite, MongoDB, etc.
class DatabaseConnectionField extends MCPField {
  final String dbType;
  final bool showAdvanced;
  final Map<String, String>? defaultValues;

  const DatabaseConnectionField({
    super.key,
    required super.label,
    super.description,
    super.placeholder,
    super.required,
    super.value,
    super.onChanged,
    super.validator,
    required this.dbType,
    this.showAdvanced = false,
    this.defaultValues,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        const SizedBox(height: SpacingTokens.componentSpacing),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _getDbIcon(),
                    color: SemanticColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Connection Builder',
                    style: TextStyle(
                                            fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  AsmblButton.secondary(
                    text: 'Test Connection',
                    icon: Icons.play_arrow,
                    onPressed: () => _testConnection(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildConnectionFields(context),
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (this.required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: SemanticColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnectionFields(BuildContext context) {
    switch (dbType.toLowerCase()) {
      case 'postgresql':
        return _buildPostgresFields(context);
      case 'sqlite':
        return _buildSqliteFields(context);
      default:
        return _buildGenericFields(context);
    }
  }

  Widget _buildPostgresFields(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Host',
                  hintText: 'localhost',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Port',
                  hintText: '5432',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Database',
                  hintText: 'myapp',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'postgres',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter password...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            suffixIcon: const Icon(Icons.visibility_off),
          ),
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildSqliteFields(BuildContext context) {
    return PathPickerField(
      label: 'Database File',
      placeholder: 'Choose SQLite database file...',
      isDirectory: false,
      allowedExtensions: const ['db', 'sqlite', 'sqlite3'],
      showPreview: true,
      onChanged: onChanged,
    );
  }

  Widget _buildGenericFields(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        hintText: placeholder ?? 'Enter connection string...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onChanged: onChanged,
    );
  }

  IconData _getDbIcon() {
    switch (dbType.toLowerCase()) {
      case 'postgresql':
        return Icons.storage;
      case 'sqlite':
        return Icons.storage_outlined;
      case 'mysql':
        return Icons.storage;
      default:
        return Icons.storage;
    }
  }

  void _testConnection(BuildContext context) {
    // This would implement actual connection testing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Testing connection to $dbType database...'),
        backgroundColor: SemanticColors.primary,
      ),
    );
  }
}

// Data models for select options
class SelectOption {
  final String value;
  final String label;
  final IconData? icon;
  final String? badge;
  final Color? badgeColor;
  final String? description;

  const SelectOption({
    required this.value,
    required this.label,
    this.icon,
    this.badge,
    this.badgeColor,
    this.description,
  });
}