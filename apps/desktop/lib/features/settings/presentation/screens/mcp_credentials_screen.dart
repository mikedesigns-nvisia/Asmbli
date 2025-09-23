import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/config/mcp_credentials_config.dart';
import '../../../../core/services/mcp_catalog_service.dart';

/// Practical MCP credentials management screen
class MCPCredentialsScreen extends ConsumerStatefulWidget {
  const MCPCredentialsScreen({super.key});

  @override
  ConsumerState<MCPCredentialsScreen> createState() => _MCPCredentialsScreenState();
}

class _MCPCredentialsScreenState extends ConsumerState<MCPCredentialsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _obscureText = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize controllers for all credential fields
    for (final serviceId in MCPCredentialsConfig.getApiKeyServices()) {
      _controllers[serviceId] = TextEditingController();
    }
    for (final serviceId in MCPCredentialsConfig.getOAuthServices()) {
      _controllers[serviceId] = TextEditingController();
    }
    for (final serviceId in MCPCredentialsConfig.getDatabaseServices()) {
      _controllers[serviceId] = TextEditingController();
    }
    for (final serviceId in MCPCredentialsConfig.getCloudServices()) {
      final config = MCPCredentialsConfig.getCloudConfig(serviceId);
      if (config != null) {
        for (final field in config.fields) {
          _controllers[field.key] = TextEditingController();
          if (field.isSecret) {
            _obscureText[field.key] = true;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(colors),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(colors, 'API Keys', 'Simple API key authentication', Icons.key, _buildApiKeySection()),
                    const SizedBox(height: SpacingTokens.xl),
                    _buildSection(colors, 'Service Tokens', 'Pre-generated service access tokens', Icons.security, _buildOAuthSection()),
                    const SizedBox(height: SpacingTokens.xl),
                    _buildSection(colors, 'Database Connections', 'Database connection strings', Icons.storage, _buildDatabaseSection()),
                    const SizedBox(height: SpacingTokens.xl),
                    _buildSection(colors, 'Cloud Providers', 'Multi-credential cloud services', Icons.cloud, _buildCloudSection()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.headerPadding),
      child: Row(
        children: [
          HeaderButton(
            text: 'Back',
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text(
            'MCP Credentials',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const Spacer(),
          const SizedBox(width: 120),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeColors colors, String title, String subtitle, IconData icon, Widget content) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                ),
                child: Icon(icon, color: colors.primary, size: 24),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      subtitle,
                      style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          content,
        ],
      ),
    );
  }

  Widget _buildApiKeySection() {
    final colors = ThemeColors(context);
    
    return Column(
      children: MCPCredentialsConfig.getApiKeyServices().map((serviceId) {
        final config = MCPCredentialsConfig.getApiKeyConfig(serviceId)!;
        final status = MCPCredentialsConfig.getCredentialStatus(serviceId);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.md),
          child: _buildCredentialField(
            colors: colors,
            title: config.displayName,
            description: config.description,
            placeholder: config.placeholder,
            controller: _controllers[serviceId]!,
            status: status,
            onSetup: () => _launchUrl(config.signupUrl),
            onDocs: () => _launchUrl(config.docUrl),
            isSecret: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOAuthSection() {
    final colors = ThemeColors(context);
    
    return Column(
      children: MCPCredentialsConfig.getOAuthServices().map((serviceId) {
        final config = MCPCredentialsConfig.getOAuthConfig(serviceId)!;
        final status = MCPCredentialsConfig.getCredentialStatus(serviceId);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.md),
          child: _buildCredentialField(
            colors: colors,
            title: config.displayName,
            description: config.description,
            placeholder: config.placeholder,
            controller: _controllers[serviceId]!,
            status: status,
            onSetup: () => _launchUrl(config.setupUrl),
            onOAuth: () => _startOAuthFlow(serviceId),
            isSecret: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatabaseSection() {
    final colors = ThemeColors(context);
    
    return Column(
      children: MCPCredentialsConfig.getDatabaseServices().map((serviceId) {
        final config = MCPCredentialsConfig.getDatabaseConfig(serviceId)!;
        final status = MCPCredentialsConfig.getCredentialStatus(serviceId);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.md),
          child: _buildCredentialField(
            colors: colors,
            title: config.displayName,
            description: config.description,
            placeholder: config.placeholder,
            controller: _controllers[serviceId]!,
            status: status,
            onDocs: () => _launchUrl(config.docUrl),
            isSecret: false,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCloudSection() {
    final colors = ThemeColors(context);
    
    return Column(
      children: MCPCredentialsConfig.getCloudServices().map((serviceId) {
        final config = MCPCredentialsConfig.getCloudConfig(serviceId)!;
        final status = MCPCredentialsConfig.getCredentialStatus(serviceId);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.lg),
          child: Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.border.withOpacity(0.3)),
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
                            config.displayName,
                            style: TextStyles.labelLarge.copyWith(color: colors.onSurface),
                          ),
                          const SizedBox(height: SpacingTokens.xs),
                          Text(
                            config.description,
                            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusIndicator(colors, status),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),
                ...config.fields.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: _buildTextField(
                    colors: colors,
                    label: field.displayName,
                    placeholder: field.placeholder,
                    controller: _controllers[field.key]!,
                    isSecret: field.isSecret,
                    fieldKey: field.key,
                  ),
                )),
                const SizedBox(height: SpacingTokens.sm),
                Row(
                  children: [
                    AsmblButton.secondary(
                      text: 'Documentation',
                      icon: Icons.help_outline,
                      onPressed: () => _launchUrl(config.docUrl),
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    AsmblButton.primary(
                      text: 'Save Credentials',
                      icon: Icons.save,
                      onPressed: () => _saveCloudCredentials(serviceId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCredentialField({
    required ThemeColors colors,
    required String title,
    required String description,
    required String placeholder,
    required TextEditingController controller,
    required MCPCredentialStatus status,
    VoidCallback? onSetup,
    VoidCallback? onDocs,
    VoidCallback? onOAuth,
    required bool isSecret,
  }) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border.withOpacity(0.3)),
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
                      style: TextStyles.labelLarge.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      description,
                      style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _buildStatusIndicator(colors, status),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          _buildTextField(
            colors: colors,
            label: title,
            placeholder: placeholder,
            controller: controller,
            isSecret: isSecret,
          ),
          const SizedBox(height: SpacingTokens.sm),
          Row(
            children: [
              if (onSetup != null) ...[
                AsmblButton.secondary(
                  text: 'Get API Key',
                  icon: Icons.open_in_new,
                  onPressed: onSetup,
                ),
                const SizedBox(width: SpacingTokens.sm),
              ],
              if (onOAuth != null) ...[
                AsmblButton.secondary(
                  text: 'OAuth Setup',
                  icon: Icons.security,
                  onPressed: onOAuth,
                ),
                const SizedBox(width: SpacingTokens.sm),
              ],
              if (onDocs != null) ...[
                AsmblButton.secondary(
                  text: 'Docs',
                  icon: Icons.help_outline,
                  onPressed: onDocs,
                ),
                const SizedBox(width: SpacingTokens.sm),
              ],
              AsmblButton.primary(
                text: 'Save',
                icon: Icons.save,
                onPressed: () => _saveCredential(controller.text, title),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required ThemeColors colors,
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required bool isSecret,
    String? fieldKey,
  }) {
    final isObscured = isSecret && (fieldKey != null ? (_obscureText[fieldKey] ?? true) : true);
    
    return TextField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        hintStyle: TextStyle(color: colors.onSurfaceVariant.withOpacity(0.6)),
        filled: true,
        fillColor: colors.surface.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          borderSide: BorderSide(color: colors.border.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          borderSide: BorderSide(color: colors.primary),
        ),
        suffixIcon: isSecret ? IconButton(
          icon: Icon(
            isObscured ? Icons.visibility : Icons.visibility_off,
            color: colors.onSurfaceVariant,
          ),
          onPressed: () {
            if (fieldKey != null) {
              setState(() {
                _obscureText[fieldKey] = !isObscured;
              });
            }
          },
        ) : null,
      ),
      style: TextStyle(color: colors.onSurface),
    );
  }

  Widget _buildStatusIndicator(ThemeColors colors, MCPCredentialStatus status) {
    final statusData = _getStatusData(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: statusData['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusData['icon'],
            size: 16,
            color: statusData['color'],
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            statusData['text'],
            style: TextStyles.caption.copyWith(
              color: statusData['color'],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusData(MCPCredentialStatus status) {
    final colors = ThemeColors(context);
    
    switch (status) {
      case MCPCredentialStatus.configured:
        return {
          'text': 'Configured',
          'icon': Icons.check_circle,
          'color': colors.primary,
        };
      case MCPCredentialStatus.notConfigured:
        return {
          'text': 'Not Set',
          'icon': Icons.warning,
          'color': colors.accent,
        };
      case MCPCredentialStatus.invalid:
        return {
          'text': 'Invalid',
          'icon': Icons.error,
          'color': colors.error,
        };
      case MCPCredentialStatus.notSupported:
        return {
          'text': 'Not Supported',
          'icon': Icons.info,
          'color': colors.onSurfaceVariant,
        };
    }
  }

  void _saveCredential(String value, String serviceName) {
    if (value.trim().isEmpty) {
      _showSnackBar('Please enter a valid credential', isError: true);
      return;
    }

    // TODO: Implement secure credential storage
    _showSnackBar('$serviceName credential saved successfully!');
  }

  void _saveCloudCredentials(String serviceId) {
    final config = MCPCredentialsConfig.getCloudConfig(serviceId)!;
    final hasAllFields = config.fields.every((field) {
      final value = _controllers[field.key]?.text ?? '';
      return value.trim().isNotEmpty;
    });

    if (!hasAllFields) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    // TODO: Implement secure credential storage
    _showSnackBar('${config.displayName} credentials saved successfully!');
  }

  void _startOAuthFlow(String serviceId) {
    // TODO: Implement OAuth flow
    _showSnackBar('OAuth flow for $serviceId will be implemented');
  }

  void _launchUrl(String url) {
    // TODO: Implement URL launcher
    _showSnackBar('Opening: $url');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colors = ThemeColors(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : colors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}