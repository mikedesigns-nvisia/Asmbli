import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/oauth_provider.dart';
import '../../../../core/services/oauth_integration_service.dart';
import '../../../../core/services/oauth_extensions.dart';
import '../../../../core/services/mcp_catalog_service.dart';
import '../../../../core/design_system/components/app_navigation_bar.dart';
import '../../../../core/constants/routes.dart';

/// Apple-style OAuth settings screen with simplified UX
class AppleStyleOAuthScreen extends ConsumerStatefulWidget {
  const AppleStyleOAuthScreen({super.key});

  @override
  ConsumerState<AppleStyleOAuthScreen> createState() => _AppleStyleOAuthScreenState();
}

class _AppleStyleOAuthScreenState extends ConsumerState<AppleStyleOAuthScreen>
    with TickerProviderStateMixin {
  
  final Map<OAuthProvider, OAuthProviderState> _providerStates = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadProviderStates();
  }

  Future<void> _loadProviderStates() async {
    final oauthService = ref.read(oauthIntegrationServiceProvider);
    
    for (final provider in OAuthProvider.values) {
      try {
        final hasValidToken = await oauthService.hasValidToken(provider);
        final tokenInfo = hasValidToken ? await oauthService.getTokenInfo(provider) : null;
        
        _providerStates[provider] = OAuthProviderState(
          provider: provider,
          status: hasValidToken 
              ? OAuthConnectionStatus.connected 
              : OAuthConnectionStatus.disconnected,
          connectedAt: tokenInfo?.issuedAt,
          lastUsed: tokenInfo?.issuedAt,
        );
      } catch (e) {
        _providerStates[provider] = OAuthProviderState(
          provider: provider,
          status: OAuthConnectionStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Scaffold(
      backgroundColor: colors.background,
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
            // Main app navigation bar
            AppNavigationBar(currentRoute: AppRoutes.settings),
            _buildSimpleHeader(colors),
            Expanded(
              child: _isLoading 
                  ? _buildLoadingState(colors)
                  : _buildContent(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleHeader(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SpacingTokens.headerPadding,
        MediaQuery.of(context).padding.top + SpacingTokens.lg,
        SpacingTokens.headerPadding,
        SpacingTokens.lg,
      ),
      child: Row(
        children: [
          // Simple back button - Apple style
          GestureDetector(
            onTap: () => context.go(AppRoutes.settings),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: colors.primary,
                size: 18,
              ),
            ),
          ),
          
          SizedBox(width: SpacingTokens.lg),
          
          // Clean title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Accounts',
                  style: TextStyles.pageTitle.copyWith(
                    color: colors.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Link your accounts to expand capabilities',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
          SizedBox(height: SpacingTokens.lg),
          Text(
            'Loading accounts...',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeColors colors) {
    final connectedProviders = _providerStates.entries
        .where((entry) => entry.value.status == OAuthConnectionStatus.connected)
        .toList();
    
    final availableProviders = _providerStates.entries
        .where((entry) => entry.value.status != OAuthConnectionStatus.connected)
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: SpacingTokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connected accounts section
          if (connectedProviders.isNotEmpty) ...[
            _buildSectionHeader('Connected', connectedProviders.length, colors),
            SizedBox(height: SpacingTokens.lg),
            ...connectedProviders.map((entry) => 
              _buildConnectedProviderCard(entry.key, entry.value, colors)
            ),
            SizedBox(height: SpacingTokens.xxl),
          ],
          
          // Available accounts section
          if (availableProviders.isNotEmpty) ...[
            _buildSectionHeader('Available', availableProviders.length, colors),
            SizedBox(height: SpacingTokens.lg),
            ...availableProviders.map((entry) => 
              _buildAvailableProviderCard(entry.key, entry.value, colors)
            ),
          ],
          
          // Bottom spacing
          SizedBox(height: SpacingTokens.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, ThemeColors colors) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyles.labelMedium.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SpacingTokens.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: colors.onSurfaceVariant.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedProviderCard(
    OAuthProvider provider,
    OAuthProviderState state,
    ThemeColors colors,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: SpacingTokens.md),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          border: Border.all(
            color: colors.border.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showProviderDetails(provider),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            child: Padding(
              padding: EdgeInsets.all(SpacingTokens.lg),
              child: Row(
                children: [
                  // Provider icon with connected indicator
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          _getProviderIcon(provider),
                          color: colors.primary,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(width: SpacingTokens.lg),
                  
                  // Provider info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.displayName,
                          style: TextStyles.bodyLarge.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _getStatusMessage(state),
                          style: TextStyles.bodySmall.copyWith(
                            color: Colors.green,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Subtle arrow
                  Icon(
                    Icons.arrow_forward_ios,
                    color: colors.onSurfaceVariant.withOpacity(0.3),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableProviderCard(
    OAuthProvider provider,
    OAuthProviderState state,
    ThemeColors colors,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: SpacingTokens.md),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          border: Border.all(
            color: colors.border.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _connectProvider(provider),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            child: Padding(
              padding: EdgeInsets.all(SpacingTokens.lg),
              child: Row(
                children: [
                  // Provider icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      _getProviderIcon(provider),
                      color: colors.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  
                  SizedBox(width: SpacingTokens.lg),
                  
                  // Provider info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.displayName,
                          style: TextStyles.bodyLarge.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _getProviderBenefit(provider),
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Connect button
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SpacingTokens.md,
                      vertical: SpacingTokens.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Connect',
                      style: TextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusMessage(OAuthProviderState state) {
    if (state.expiresAt != null) {
      final now = DateTime.now();
      final expiresAt = state.expiresAt!;
      final daysUntilExpiry = expiresAt.difference(now).inDays;
      
      if (daysUntilExpiry < 7) {
        return 'Expires in $daysUntilExpiry days';
      }
    }
    
    return 'Connected and active';
  }

  String _getProviderBenefit(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return 'Access repositories and code';
      case OAuthProvider.slack:
        return 'Send messages and notifications';
      case OAuthProvider.linear:
        return 'Manage issues and projects';
      case OAuthProvider.microsoft:
        return 'Access files and calendar';
      default:
        return 'Expand your capabilities';
    }
  }

  Future<void> _connectProvider(OAuthProvider provider) async {
    final colors = ThemeColors(context);
    
    try {
      // Show connecting state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connecting to ${provider.displayName}...'),
          backgroundColor: colors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
        ),
      );

      final oauthService = ref.read(oauthIntegrationServiceProvider);
      final result = await oauthService.authenticate(provider);
      
      if (result.isSuccess) {
        // Sync OAuth connection with MCP servers
        await _syncOAuthWithMCPServers(provider);
        
        await _loadProviderStates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${provider.displayName} connected successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorMessage('Connection Failed', result.error ?? 'Unknown error');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Connection Error', e.toString());
      }
    }
  }

  void _showProviderDetails(OAuthProvider provider) {
    final colors = ThemeColors(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(BorderRadiusTokens.xl),
            topRight: Radius.circular(BorderRadiusTokens.xl),
          ),
        ),
        child: _buildProviderDetailsSheet(provider, colors),
      ),
    );
  }

  Widget _buildProviderDetailsSheet(OAuthProvider provider, ThemeColors colors) {
    final state = _providerStates[provider]!;
    
    return Column(
      children: [
        // Handle bar
        Container(
          margin: EdgeInsets.only(top: SpacingTokens.md),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: colors.onSurfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header
        Padding(
          padding: EdgeInsets.all(SpacingTokens.xl),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _getProviderIcon(provider),
                  color: colors.primary,
                  size: 28,
                ),
              ),
              SizedBox(width: SpacingTokens.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.displayName,
                      style: TextStyles.bodyLarge.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      _getStatusMessage(state),
                      style: TextStyles.bodyMedium.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Divider(color: colors.border.withOpacity(0.3), height: 1),
        
        // Options
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildSheetOption(
                'Manage Permissions',
                'Review and update access levels',
                Icons.security,
                () => _managePermissions(provider),
                colors,
              ),
              _buildSheetOption(
                'Available MCP Tools',
                'See tools that can use this connection',
                Icons.extension,
                () => _showCompatibleMCPTools(provider),
                colors,
              ),
              _buildSheetOption(
                'Refresh Connection',
                'Update authentication tokens',
                Icons.refresh,
                () => _refreshConnection(provider),
                colors,
              ),
              _buildSheetOption(
                'View Activity',
                'See recent integration activity',
                Icons.history,
                () => _viewActivity(provider),
                colors,
              ),
              Divider(color: colors.border.withOpacity(0.3), height: 1),
              _buildSheetOption(
                'Disconnect Account',
                'Remove this connection',
                Icons.logout,
                () => _disconnectProvider(provider),
                colors,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSheetOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    ThemeColors colors, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : colors.primary,
      ),
      title: Text(
        title,
        style: TextStyles.bodyMedium.copyWith(
          color: isDestructive ? Colors.red : colors.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyles.bodySmall.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: colors.onSurfaceVariant.withOpacity(0.3),
      ),
    );
  }

  Future<void> _refreshConnection(OAuthProvider provider) async {
    Navigator.of(context).pop(); // Close bottom sheet
    
    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      final result = await oauthService.refreshToken(provider);
      
      if (result.isSuccess) {
        await _loadProviderStates();
        _showSuccessMessage('Connection refreshed successfully');
      } else {
        _showErrorMessage('Refresh Failed', result.error ?? 'Unknown error');
      }
    } catch (e) {
      _showErrorMessage('Refresh Error', e.toString());
    }
  }

  Future<void> _disconnectProvider(OAuthProvider provider) async {
    Navigator.of(context).pop(); // Close bottom sheet
    
    final confirmed = await _showConfirmationDialog(
      'Disconnect ${provider.displayName}?',
      'This will remove the connection and you\'ll need to reconnect to use this integration.',
    );
    
    if (!confirmed) return;
    
    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      await oauthService.revokeCredentials(provider);
      await _loadProviderStates();
      _showSuccessMessage('${provider.displayName} disconnected');
    } catch (e) {
      _showErrorMessage('Disconnect Error', e.toString());
    }
  }

  void _managePermissions(OAuthProvider provider) {
    Navigator.of(context).pop(); // Close bottom sheet
    // Navigate to permissions screen
  }

  void _showCompatibleMCPTools(OAuthProvider provider) async {
    Navigator.of(context).pop(); // Close bottom sheet

    final mcpService = ref.read(mcpCatalogServiceProvider);
    final allEntries = await mcpService.getAllCatalogEntries();
    final compatibleServers = allEntries.where((entry) {
      return _isOAuthProviderCompatible(provider, entry.id);
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        ),
        title: Text('Compatible MCP Tools'),
        content: Container(
          width: double.maxFinite,
          child: compatibleServers.isEmpty
            ? Text('No MCP tools currently compatible with ${provider.displayName}')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: compatibleServers.map((server) => 
                  ListTile(
                    leading: Icon(Icons.extension),
                    title: Text(server.name),
                    subtitle: Text(server.description),
                    dense: true,
                  )
                ).toList(),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewActivity(OAuthProvider provider) {
    Navigator.of(context).pop(); // Close bottom sheet  
    // Navigate to activity screen
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        ),
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
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        ),
      ),
    );
  }

  void _showErrorMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Sync OAuth connection with available MCP servers
  Future<void> _syncOAuthWithMCPServers(OAuthProvider provider) async {
    try {
      final mcpService = ref.read(mcpCatalogServiceProvider);
      final allEntries = await mcpService.getAllCatalogEntries();

      // Find MCP servers that can use this OAuth provider
      final compatibleServers = allEntries.where((entry) {
        return _isOAuthProviderCompatible(provider, entry.id);
      });
      
      // For each compatible server, we can enable notifications or pre-configure
      for (final server in compatibleServers) {
        print('📡 OAuth ${provider.displayName} now available for MCP server: ${server.name}');
      }
      
      // Notify user about newly available integrations
      if (compatibleServers.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${compatibleServers.length} MCP tools now available with ${provider.displayName}'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
          ),
        );
      }
    } catch (e) {
      print('Failed to sync OAuth with MCP servers: $e');
    }
  }

  /// Check if OAuth provider is compatible with MCP server
  bool _isOAuthProviderCompatible(OAuthProvider provider, String mcpServerId) {
    switch (provider) {
      case OAuthProvider.github:
        return mcpServerId.toLowerCase().contains('github');
      case OAuthProvider.slack:
        return mcpServerId.toLowerCase().contains('slack');
      case OAuthProvider.linear:
        return mcpServerId.toLowerCase().contains('linear');
      case OAuthProvider.microsoft:
        return mcpServerId.toLowerCase().contains('microsoft') ||
               mcpServerId.toLowerCase().contains('outlook') ||
               mcpServerId.toLowerCase().contains('teams');
      default:
        return false;
    }
  }

  IconData _getProviderIcon(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return Icons.code;
      case OAuthProvider.slack:
        return Icons.chat;
      case OAuthProvider.linear:
        return Icons.linear_scale;
      case OAuthProvider.microsoft:
        return Icons.business;
      default:
        return Icons.link;
    }
  }
}

// Helper extension for additional state properties
extension OAuthProviderStateExtension on OAuthProviderState {
  DateTime? get expiresAt => null; // Would be implemented with token expiration
  List<String> get grantedScopes => []; // Would be implemented with scope tracking
  DateTime? get lastRefresh => null; // Would be implemented with refresh tracking
  bool get isRefreshable => false; // Would be implemented based on token type
  String? get error => errorMessage;
}