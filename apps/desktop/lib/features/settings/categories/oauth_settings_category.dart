import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/models/oauth_provider.dart';
import '../../../core/services/oauth_integration_service.dart';
import '../components/settings_field.dart';
import '../providers/settings_provider.dart';

/// OAuth settings category - authentication and security management
class OAuthSettingsCategory extends ConsumerStatefulWidget {
  const OAuthSettingsCategory({super.key});

  @override
  ConsumerState<OAuthSettingsCategory> createState() => _OAuthSettingsCategoryState();
}

class _OAuthSettingsCategoryState extends ConsumerState<OAuthSettingsCategory> {
  bool _showSecuritySettings = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final oauthSettings = ref.watch(oauthSettingsProvider);
    final oauthService = ref.watch(oauthIntegrationServiceProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview stats
              _buildOverviewStats(oauthSettings, colors),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Connected providers
              SettingsSection(
                title: 'OAuth Providers',
                description: 'Manage your connected authentication providers',
                children: [
                  _buildProvidersGrid(oauthSettings, oauthService, colors),
                ],
              ),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Security settings
              SettingsSection(
                title: 'Security Settings',
                description: 'Configure OAuth security and privacy options',
                children: [
                  _buildSecuritySettings(colors),
                ],
              ),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Connection management
              SettingsSection(
                title: 'Connection Management',
                description: 'Test and refresh your OAuth connections',
                children: [
                  SettingsButton(
                    text: 'Test All Connections',
                    description: 'Verify all OAuth providers are working correctly',
                    icon: Icons.verified_user,
                    onPressed: _testAllConnections,
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  SettingsButton(
                    text: 'Refresh Tokens',
                    description: 'Refresh expired authentication tokens',
                    icon: Icons.refresh,
                    onPressed: _refreshTokens,
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  SettingsButton(
                    text: 'Revoke All',
                    description: 'Disconnect all OAuth providers',
                    icon: Icons.logout,
                    type: SettingsButtonType.danger,
                    onPressed: _revokeAllConnections,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build overview statistics
  Widget _buildOverviewStats(dynamic oauthSettings, ThemeColors colors) {
    final connectedCount = oauthSettings.connectedProviders.length;
    final totalProviders = OAuthProvider.values.length;

    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OAuth Overview',
              style: TextStyles.headingSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.md),
            Row(
              children: [
                _buildStatItem('Connected', connectedCount.toString(), colors.primary, colors),
                const SizedBox(width: SpacingTokens.xl),
                _buildStatItem('Available', totalProviders.toString(), colors.accent, colors),
                const SizedBox(width: SpacingTokens.xl),
                _buildStatItem(
                  'Status', 
                  connectedCount > 0 ? 'Active' : 'Inactive',
                  connectedCount > 0 ? Colors.green : colors.onSurfaceVariant,
                  colors,
                ),
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

  /// Build OAuth providers grid
  Widget _buildProvidersGrid(dynamic oauthSettings, OAuthIntegrationService oauthService, ThemeColors colors) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: SpacingTokens.md,
        mainAxisSpacing: SpacingTokens.md,
        childAspectRatio: 2.5,
      ),
      itemCount: OAuthProvider.values.length,
      itemBuilder: (context, index) {
        final provider = OAuthProvider.values[index];
        final isConnected = oauthSettings.connectedProviders.contains(provider);
        return _buildProviderCard(provider, isConnected, oauthService, colors);
      },
    );
  }

  /// Build individual provider card
  Widget _buildProviderCard(
    OAuthProvider provider,
    bool isConnected,
    OAuthIntegrationService oauthService,
    ThemeColors colors,
  ) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getProviderColor(provider).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(
                    _getProviderIcon(provider),
                    color: _getProviderColor(provider),
                    size: 16,
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getProviderDisplayName(provider),
                        style: TextStyles.labelMedium.copyWith(color: colors.onSurface),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isConnected ? Colors.green : colors.onSurfaceVariant,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.xs),
                          Text(
                            isConnected ? 'Connected' : 'Not connected',
                            style: TextStyles.captionSmall.copyWith(
                              color: isConnected ? Colors.green : colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            SizedBox(
              width: double.infinity,
              child: AsmblButton.outline(
                text: isConnected ? 'Disconnect' : 'Connect',
                icon: isConnected ? Icons.link_off : Icons.link,
                onPressed: () => _toggleProviderConnection(provider, isConnected, oauthService),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build security settings section
  Widget _buildSecuritySettings(ThemeColors colors) {
    return Column(
      children: [
        SettingsToggle(
          label: 'Automatic Token Refresh',
          description: 'Automatically refresh authentication tokens before they expire',
          value: true, // This would come from actual settings
          onChanged: (value) {
            // Handle auto refresh setting
          },
        ),
        const SizedBox(height: SpacingTokens.md),
        SettingsToggle(
          label: 'Secure Token Storage',
          description: 'Store authentication tokens using system keychain',
          value: true, // This would come from actual settings
          onChanged: (value) {
            // Handle secure storage setting
          },
        ),
        const SizedBox(height: SpacingTokens.md),
        SettingsToggle(
          label: 'Session Timeout',
          description: 'Automatically revoke tokens after extended inactivity',
          value: false, // This would come from actual settings
          onChanged: (value) {
            // Handle session timeout setting
          },
        ),
        const SizedBox(height: SpacingTokens.md),
        
        // Advanced security settings
        GestureDetector(
          onTap: () => setState(() => _showSecuritySettings = !_showSecuritySettings),
          child: Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advanced Security',
                        style: TextStyles.labelMedium.copyWith(color: colors.onSurface),
                      ),
                      Text(
                        'Configure advanced OAuth security options',
                        style: TextStyles.captionMedium.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showSecuritySettings ? Icons.expand_less : Icons.expand_more,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        
        if (_showSecuritySettings) ...[
          const SizedBox(height: SpacingTokens.md),
          AsmblCard(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsField(
                    label: 'Token Expiry Warning (minutes)',
                    value: '15',
                    keyboardType: TextInputType.number,
                    description: 'Show warning this many minutes before token expires',
                    onChanged: (value) {
                      // Handle warning time change
                    },
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  SettingsToggle(
                    label: 'Audit Logging',
                    description: 'Log OAuth authentication events for security monitoring',
                    value: false,
                    onChanged: (value) {
                      // Handle audit logging setting
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Get provider display name
  String _getProviderDisplayName(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return 'GitHub';
      case OAuthProvider.google:
        return 'Google';
      case OAuthProvider.dropbox:
        return 'Dropbox';
      case OAuthProvider.slack:
        return 'Slack';
      case OAuthProvider.notion:
        return 'Notion';
      case OAuthProvider.linear:
        return 'Linear';
    }
  }

  /// Get provider icon
  IconData _getProviderIcon(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return Icons.code;
      case OAuthProvider.google:
        return Icons.search;
      case OAuthProvider.dropbox:
        return Icons.cloud_upload;
      case OAuthProvider.slack:
        return Icons.chat;
      case OAuthProvider.notion:
        return Icons.note;
      case OAuthProvider.linear:
        return Icons.linear_scale;
    }
  }

  /// Get provider color
  Color _getProviderColor(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return Colors.grey.shade800;
      case OAuthProvider.google:
        return Colors.blue;
      case OAuthProvider.dropbox:
        return Colors.blue.shade800;
      case OAuthProvider.slack:
        return Colors.purple;
      case OAuthProvider.notion:
        return Colors.grey.shade700;
      case OAuthProvider.linear:
        return Colors.indigo;
    }
  }

  /// Toggle provider connection
  Future<void> _toggleProviderConnection(
    OAuthProvider provider,
    bool isCurrentlyConnected,
    OAuthIntegrationService oauthService,
  ) async {
    try {
      if (isCurrentlyConnected) {
        // Disconnect provider
        await oauthService.revokeToken(provider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getProviderDisplayName(provider)} disconnected successfully'),
              backgroundColor: ThemeColors(context).accent,
            ),
          );
        }
      } else {
        // Connect provider
        await oauthService.authenticate(provider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getProviderDisplayName(provider)} connected successfully'),
              backgroundColor: ThemeColors(context).accent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isCurrentlyConnected ? 'disconnect' : 'connect'} ${_getProviderDisplayName(provider)}: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  /// Test all OAuth connections
  Future<void> _testAllConnections() async {
    try {
      final result = await ref.read(settingsProvider.notifier).testConnection(SettingsCategory.oauth);
      
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

  /// Refresh authentication tokens
  Future<void> _refreshTokens() async {
    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      final oauthSettings = ref.read(oauthSettingsProvider);
      
      for (final provider in oauthSettings.connectedProviders) {
        try {
          await oauthService.refreshToken(provider);
        } catch (e) {
          // Continue with other providers if one fails
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Authentication tokens refreshed'),
            backgroundColor: ThemeColors(context).accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh tokens: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  /// Revoke all OAuth connections
  Future<void> _revokeAllConnections() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke All Connections'),
        content: const Text(
          'Are you sure you want to disconnect all OAuth providers? '
          'This will remove access to all connected services and you will need to '
          're-authenticate to use them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final oauthService = ref.read(oauthIntegrationServiceProvider);
        final oauthSettings = ref.read(oauthSettingsProvider);
        
        for (final provider in oauthSettings.connectedProviders) {
          try {
            await oauthService.revokeToken(provider);
          } catch (e) {
            // Continue with other providers if one fails
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('All OAuth connections revoked successfully'),
              backgroundColor: ThemeColors(context).accent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to revoke all connections: $e'),
              backgroundColor: ThemeColors(context).error,
            ),
          );
        }
      }
    }
  }
}