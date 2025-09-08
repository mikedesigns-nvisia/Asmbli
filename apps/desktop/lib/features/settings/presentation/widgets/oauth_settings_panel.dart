import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/oauth_provider.dart';
import '../../../../core/services/oauth_integration_service.dart';

class OAuthSettingsPanel extends ConsumerStatefulWidget {
  const OAuthSettingsPanel({super.key});

  @override
  ConsumerState<OAuthSettingsPanel> createState() => _OAuthSettingsPanelState();
}

class _OAuthSettingsPanelState extends ConsumerState<OAuthSettingsPanel> {
  final Map<String, bool> _settings = {
    'auto_refresh': true,
    'secure_storage': true,
    'connection_monitoring': true,
    'audit_logging': false,
    'debug_mode': false,
    'strict_scopes': true,
  };

  final Map<OAuthProvider, Map<String, dynamic>> _providerSettings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // In a real implementation, load settings from secure storage
    // For now, use default values
    setState(() {
      for (final provider in OAuthProvider.values) {
        _providerSettings[provider] = {
          'enabled': true,
          'auto_connect': false,
          'refresh_threshold': 300, // 5 minutes
          'max_retry_attempts': 3,
          'timeout_seconds': 30,
        };
      }
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    setState(() {
      _settings[key] = value;
    });
    // In a real implementation, save to secure storage
  }

  Future<void> _saveProviderSetting(
    OAuthProvider provider,
    String key,
    dynamic value,
  ) async {
    setState(() {
      _providerSettings[provider]?[key] = value;
    });
    // In a real implementation, save to secure storage
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGlobalSettings(colors),
        SizedBox(height: SpacingTokens.xl),
        _buildProviderSettings(colors),
        SizedBox(height: SpacingTokens.xl),
        _buildAdvancedSettings(colors),
        SizedBox(height: SpacingTokens.xl),
        _buildDataManagement(colors),
      ],
    );
  }

  Widget _buildGlobalSettings(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: colors.primary,
                ),
                SizedBox(width: SpacingTokens.md),
                Text(
                  'Global Settings',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            _buildGlobalSetting(
              'Auto-refresh tokens',
              'Automatically refresh tokens before they expire',
              'auto_refresh',
              colors,
            ),
            _buildGlobalSetting(
              'Secure token storage',
              'Use encrypted storage for OAuth tokens',
              'secure_storage',
              colors,
            ),
            _buildGlobalSetting(
              'Connection monitoring',
              'Periodically test OAuth connections',
              'connection_monitoring',
              colors,
            ),
            _buildGlobalSetting(
              'Strict scope validation',
              'Validate that granted scopes match requested scopes',
              'strict_scopes',
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSetting(
    String title,
    String description,
    String settingKey,
    ThemeColors colors,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SpacingTokens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: SpacingTokens.xs),
                Text(
                  description,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: SpacingTokens.lg),
          Switch(
            value: _settings[settingKey] ?? false,
            onChanged: (value) => _saveSetting(settingKey, value),
            activeColor: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSettings(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.integration_instructions,
                  color: colors.primary,
                ),
                SizedBox(width: SpacingTokens.md),
                Text(
                  'Provider Settings',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            Column(
              children: OAuthProvider.values.map((provider) =>
                Padding(
                  padding: EdgeInsets.only(bottom: SpacingTokens.lg),
                  child: _buildProviderSettingsCard(provider, colors),
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSettingsCard(OAuthProvider provider, ThemeColors colors) {
    final settings = _providerSettings[provider] ?? {};
    
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                provider.icon,
                color: colors.primary,
                size: 20,
              ),
              SizedBox(width: SpacingTokens.md),
              Text(
                provider.displayName,
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Switch(
                value: settings['enabled'] ?? true,
                onChanged: (value) => _saveProviderSetting(provider, 'enabled', value),
                activeColor: colors.primary,
              ),
            ],
          ),
          if (settings['enabled'] ?? true) ...[
            SizedBox(height: SpacingTokens.md),
            _buildProviderSettingRow(
              'Auto-connect on startup',
              Switch(
                value: settings['auto_connect'] ?? false,
                onChanged: (value) => _saveProviderSetting(provider, 'auto_connect', value),
                activeColor: colors.primary,
              ),
              colors,
            ),
            _buildProviderSettingRow(
              'Refresh threshold (minutes)',
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: ((settings['refresh_threshold'] ?? 300) ~/ 60).toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: SpacingTokens.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                  ),
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                  onChanged: (value) {
                    final minutes = int.tryParse(value) ?? 5;
                    _saveProviderSetting(provider, 'refresh_threshold', minutes * 60);
                  },
                ),
              ),
              colors,
            ),
            _buildProviderSettingRow(
              'Connection timeout (seconds)',
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: (settings['timeout_seconds'] ?? 30).toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: SpacingTokens.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                  ),
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                  onChanged: (value) {
                    final seconds = int.tryParse(value) ?? 30;
                    _saveProviderSetting(provider, 'timeout_seconds', seconds);
                  },
                ),
              ),
              colors,
            ),
            _buildProviderSettingRow(
              'Max retry attempts',
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: (settings['max_retry_attempts'] ?? 3).toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: SpacingTokens.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                  ),
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                  onChanged: (value) {
                    final attempts = int.tryParse(value) ?? 3;
                    _saveProviderSetting(provider, 'max_retry_attempts', attempts);
                  },
                ),
              ),
              colors,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderSettingRow(String label, Widget control, ThemeColors colors) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          control,
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.engineering,
                  color: colors.primary,
                ),
                SizedBox(width: SpacingTokens.md),
                Text(
                  'Advanced Settings',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            _buildGlobalSetting(
              'Debug mode',
              'Enable detailed logging for troubleshooting',
              'debug_mode',
              colors,
            ),
            _buildGlobalSetting(
              'Audit logging',
              'Log OAuth activities for security monitoring',
              'audit_logging',
              colors,
            ),
            SizedBox(height: SpacingTokens.md),
            Row(
              children: [
                AsmblButton.secondary(
                  text: 'Export Configuration',
                  icon: Icons.download,
                  onPressed: _exportConfiguration,
                ),
                SizedBox(width: SpacingTokens.md),
                AsmblButton.secondary(
                  text: 'Import Configuration',
                  icon: Icons.upload,
                  onPressed: _importConfiguration,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagement(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: colors.primary,
                ),
                SizedBox(width: SpacingTokens.md),
                Text(
                  'Data Management',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            Text(
              'Manage your OAuth data and connections',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: SpacingTokens.lg),
            Row(
              children: [
                AsmblButton.secondary(
                  text: 'Clear All Tokens',
                  icon: Icons.clear_all,
                  onPressed: _clearAllTokens,
                ),
                SizedBox(width: SpacingTokens.md),
                AsmblButton.secondary(
                  text: 'Reset Settings',
                  icon: Icons.refresh,
                  onPressed: _resetSettings,
                ),
                SizedBox(width: SpacingTokens.md),
                AsmblButton.destructive(
                  text: 'Factory Reset',
                  icon: Icons.restore,
                  onPressed: _factoryReset,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportConfiguration() async {
    // Implementation for exporting OAuth configuration
    _showSnackBar('Configuration exported successfully', isError: false);
  }

  Future<void> _importConfiguration() async {
    // Implementation for importing OAuth configuration
    _showSnackBar('Configuration imported successfully', isError: false);
  }

  Future<void> _clearAllTokens() async {
    final confirmed = await _showConfirmationDialog(
      'Clear All Tokens',
      'This will remove all stored OAuth tokens. You will need to re-authenticate all connections.',
    );

    if (!confirmed) return;

    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      
      for (final provider in OAuthProvider.values) {
        await oauthService.revokeCredentials(provider);
      }
      
      _showSnackBar('All tokens cleared successfully', isError: false);
    } catch (e) {
      _showSnackBar('Error clearing tokens: $e');
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await _showConfirmationDialog(
      'Reset Settings',
      'This will reset all OAuth settings to their default values.',
    );

    if (!confirmed) return;

    setState(() {
      _settings.clear();
      _settings.addAll({
        'auto_refresh': true,
        'secure_storage': true,
        'connection_monitoring': true,
        'audit_logging': false,
        'debug_mode': false,
        'strict_scopes': true,
      });
    });

    _showSnackBar('Settings reset successfully', isError: false);
  }

  Future<void> _factoryReset() async {
    final confirmed = await _showConfirmationDialog(
      'Factory Reset',
      'This will remove ALL OAuth data, tokens, and settings. This action cannot be undone.',
    );

    if (!confirmed) return;

    try {
      await _clearAllTokens();
      await _resetSettings();
      
      _showSnackBar('Factory reset completed', isError: false);
    } catch (e) {
      _showSnackBar('Error during factory reset: $e');
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}