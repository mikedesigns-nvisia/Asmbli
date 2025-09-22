import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/oauth_provider.dart';
import '../../../../core/services/oauth_integration_service.dart';
import '../../../../core/services/oauth_extensions.dart';
import '../widgets/oauth_provider_card.dart';
import '../widgets/oauth_scope_management_dialog.dart';
import '../widgets/oauth_token_manager.dart';
import '../widgets/oauth_security_panel.dart';
import '../widgets/oauth_settings_panel.dart';

/// Enhanced OAuth connections settings screen with comprehensive management
class EnhancedOAuthSettingsScreen extends ConsumerStatefulWidget {
  const EnhancedOAuthSettingsScreen({super.key});

  @override
  ConsumerState<EnhancedOAuthSettingsScreen> createState() => _EnhancedOAuthSettingsScreenState();
}

class _EnhancedOAuthSettingsScreenState extends ConsumerState<EnhancedOAuthSettingsScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final Map<OAuthProvider, OAuthProviderState> _providerStates = {};
  bool _isInitialized = false;
  String _searchQuery = '';
  OAuthProviderFilter _currentFilter = OAuthProviderFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeProviderStates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeProviderStates() async {
    final oauthService = ref.read(oauthIntegrationServiceProvider);
    
    // Load all provider states with enhanced metadata
    for (final provider in OAuthProvider.values) {
      try {
        final hasValidToken = await oauthService.hasValidToken(provider);
        final tokenInfo = hasValidToken ? await oauthService.getTokenInfo(provider) : null;
        final scopes = hasValidToken ? await oauthService.getGrantedScopes(provider) : <String>[];
        
        _providerStates[provider] = OAuthProviderState(
          provider: provider,
          status: hasValidToken 
              ? OAuthConnectionStatus.connected 
              : OAuthConnectionStatus.disconnected,
          connectedAt: tokenInfo?.issuedAt,
          expiresAt: tokenInfo?.expiresAt,
          grantedScopes: scopes,
          lastRefresh: tokenInfo?.lastRefresh,
          isRefreshable: tokenInfo?.refreshToken != null,
        );
      } catch (e) {
        _providerStates[provider] = OAuthProviderState(
          provider: provider,
          status: OAuthConnectionStatus.error,
          error: e.toString(),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  List<OAuthProvider> get _filteredProviders {
    var providers = OAuthProvider.values.where((provider) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!provider.toString().toLowerCase().contains(query) &&
            !provider.info.description.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Status filter
      final state = _providerStates[provider];
      switch (_currentFilter) {
        case OAuthProviderFilter.connected:
          return state?.status == OAuthConnectionStatus.connected;
        case OAuthProviderFilter.disconnected:
          return state?.status == OAuthConnectionStatus.disconnected;
        case OAuthProviderFilter.errors:
          return state?.status == OAuthConnectionStatus.error;
        case OAuthProviderFilter.all:
        default:
          return true;
      }
    }).toList();

    // Sort by connection status, then alphabetically
    providers.sort((a, b) {
      final stateA = _providerStates[a]?.status ?? OAuthConnectionStatus.disconnected;
      final stateB = _providerStates[b]?.status ?? OAuthConnectionStatus.disconnected;
      
      if (stateA != stateB) {
        // Connected first, then disconnected, then errors
        final priorityA = stateA == OAuthConnectionStatus.connected ? 0 :
                         stateA == OAuthConnectionStatus.disconnected ? 1 : 2;
        final priorityB = stateB == OAuthConnectionStatus.connected ? 0 :
                         stateB == OAuthConnectionStatus.disconnected ? 1 : 2;
        return priorityA.compareTo(priorityB);
      }
      
      return a.displayName.compareTo(b.displayName);
    });

    return providers;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(colors),
              
              // Tab Bar
              _buildTabBar(colors),
              
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildConnectionsTab(colors),
                    _buildScopesTab(colors),
                    _buildSecurityTab(colors),
                    _buildSettingsTab(colors),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.headerPadding),
      decoration: BoxDecoration(
        color: colors.headerBackground,
        border: Border(bottom: BorderSide(color: colors.headerBorder)),
      ),
      child: Row(
        children: [
          // Back button
          HeaderButton(
            icon: Icons.arrow_back,
            text: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          const SizedBox(width: SpacingTokens.lg),
          
          // Title and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3rd Party Authentication',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  'Manage OAuth connections and secure integrations',
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          // Quick actions
          Row(
            children: [
              AsmblButton.secondary(
                text: 'Refresh All',
                icon: Icons.refresh,
                size: AsmblButtonSize.small,
                onPressed: _refreshAllConnections,
              ),
              const SizedBox(width: SpacingTokens.sm),
              AsmblButton.primary(
                text: 'Add Integration',
                icon: Icons.add,
                size: AsmblButtonSize.small,
                onPressed: _showAddIntegrationDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeColors colors) {
    return Container(
      color: colors.surface.withOpacity(0.5),
      child: TabBar(
        controller: _tabController,
        tabs: [
          _buildTab('Connections', Icons.link, _getConnectionsCount()),
          _buildTab('Scopes', Icons.security, _getScopesCount()),
          _buildTab('Security', Icons.shield, null),
          _buildTab('Settings', Icons.settings, null),
        ],
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurfaceVariant,
        indicatorColor: colors.primary,
        indicatorWeight: 3.0,
        labelStyle: TextStyles.labelMedium,
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, int? count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: SpacingTokens.xs),
          Text(label),
          if (count != null) ...[
            const SizedBox(width: SpacingTokens.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ThemeColors(context).primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyles.caption.copyWith(
                  color: ThemeColors(context).primary,
                  fontWeight: TypographyTokens.medium,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionsTab(ThemeColors colors) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search and filters
        _buildSearchAndFilters(colors),
        
        // Provider list
        Expanded(
          child: _filteredProviders.isEmpty
              ? _buildEmptyState(colors)
              : _buildProviderList(colors),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search integrations...',
              prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: colors.onSurfaceVariant),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                borderSide: BorderSide(color: colors.border),
              ),
              filled: true,
              fillColor: colors.inputBackground,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.md),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: OAuthProviderFilter.values.map((filter) {
                final isSelected = _currentFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: SpacingTokens.sm),
                  child: FilterChip(
                    label: Text(_getFilterLabel(filter)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _currentFilter = filter);
                    },
                    backgroundColor: colors.surface,
                    selectedColor: colors.primary.withOpacity(0.2),
                    labelStyle: TextStyles.labelMedium.copyWith(
                      color: isSelected ? colors.primary : colors.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderList(ThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
      itemCount: _filteredProviders.length,
      separatorBuilder: (context, index) => const SizedBox(height: SpacingTokens.md),
      itemBuilder: (context, index) {
        final provider = _filteredProviders[index];
        final state = _providerStates[provider]!;
        
        return OAuthProviderCard(
          provider: provider,
          state: state,
          onConnect: () => _connectProvider(provider),
          onDisconnect: () => _disconnectProvider(provider),
          onRefresh: () => _refreshProvider(provider),
          onManageScopes: () => _manageScopes(provider),
          onViewDetails: () => _viewProviderDetails(provider),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'No integrations found',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'No integrations match the current filter',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScopesTab(ThemeColors colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scope overview
          AsmblCard(
            child: Padding(
              padding: EdgeInsets.all(SpacingTokens.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: colors.primary),
                      SizedBox(width: SpacingTokens.md),
                      Text(
                        'OAuth Scopes Overview',
                        style: TextStyles.bodyLarge.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SpacingTokens.lg),
                  Text(
                    'Manage permissions and access levels for each connected service',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: SpacingTokens.xl),
          
          // Connected providers with scope management
          ...OAuthProvider.values
              .where((provider) => _providerStates[provider]?.status == OAuthConnectionStatus.connected)
              .map((provider) => Padding(
                    padding: EdgeInsets.only(bottom: SpacingTokens.lg),
                    child: _buildProviderScopeCard(provider, colors),
                  )),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(ThemeColors colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.xl),
      child: const OAuthSecurityPanel(),
    );
  }

  Widget _buildSettingsTab(ThemeColors colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.xl),
      child: const OAuthSettingsPanel(),
    );
  }

  Widget _buildProviderScopeCard(OAuthProvider provider, ThemeColors colors) {
    final state = _providerStates[provider];
    if (state == null) return const SizedBox.shrink();
    
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: colors.primary, size: 24),
                SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.toString(),
                        style: TextStyles.bodyLarge.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${state.grantedScopes.length} scopes granted',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AsmblButton.secondary(
                  text: 'Manage Scopes',
                  size: AsmblButtonSize.small,
                  onPressed: () => _showScopeManagementDialog(provider),
                ),
              ],
            ),
            if (state.grantedScopes.isNotEmpty) ...[
              SizedBox(height: SpacingTokens.lg),
              Wrap(
                spacing: SpacingTokens.sm,
                runSpacing: SpacingTokens.sm,
                children: state.grantedScopes.take(6).map((scope) =>
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SpacingTokens.md,
                      vertical: SpacingTokens.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      border: Border.all(color: colors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      scope,
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                ).toList()
                  ..addAll(state.grantedScopes.length > 6 ? [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SpacingTokens.md,
                        vertical: SpacingTokens.xs,
                      ),
                      child: Text(
                        '+${state.grantedScopes.length - 6} more',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ] : []),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _showScopeManagementDialog(OAuthProvider provider) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OAuthScopeManagementDialog(provider: provider),
    );
    
    // Refresh provider states after scope changes
    await _initializeProviderStates();
  }

  // Helper methods
  int _getConnectionsCount() {
    return _providerStates.values
        .where((state) => state.status == OAuthConnectionStatus.connected)
        .length;
  }

  int _getScopesCount() {
    return _providerStates.values
        .expand((state) => state.grantedScopes)
        .toSet()
        .length;
  }

  String _getFilterLabel(OAuthProviderFilter filter) {
    switch (filter) {
      case OAuthProviderFilter.all:
        return 'All (${_providerStates.length})';
      case OAuthProviderFilter.connected:
        return 'Connected (${_getConnectionsCount()})';
      case OAuthProviderFilter.disconnected:
        return 'Available (${_providerStates.length - _getConnectionsCount()})';
      case OAuthProviderFilter.errors:
        final errorCount = _providerStates.values
            .where((state) => state.status == OAuthConnectionStatus.error)
            .length;
        return 'Errors ($errorCount)';
    }
  }

  // Action methods
  Future<void> _refreshAllConnections() async {
    setState(() => _isInitialized = false);
    await _initializeProviderStates();
  }

  Future<void> _connectProvider(OAuthProvider provider) async {
    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      await oauthService.authorize(provider);
      await _refreshProvider(provider);
    } catch (e) {
      _showErrorDialog('Connection Failed', 'Failed to connect to ${provider.toString()}: $e');
    }
  }

  Future<void> _disconnectProvider(OAuthProvider provider) async {
    final confirmed = await _showConfirmDialog(
      'Disconnect ${provider.toString()}?',
      'This will revoke access and remove all stored tokens. You can reconnect anytime.',
    );
    
    if (confirmed) {
      try {
        final oauthService = ref.read(oauthIntegrationServiceProvider);
        // TODO: Implement revoke functionality
        print('Disconnecting from ${provider.toString()}');
        await _refreshProvider(provider);
      } catch (e) {
        _showErrorDialog('Disconnect Failed', 'Failed to disconnect from ${provider.toString()}: $e');
      }
    }
  }

  Future<void> _refreshProvider(OAuthProvider provider) async {
    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      await oauthService.refreshToken(provider);
      
      // Update state
      final hasValidToken = await oauthService.hasValidToken(provider);
      final tokenInfo = hasValidToken ? await oauthService.getTokenInfo(provider) : null;
      final scopes = hasValidToken ? await oauthService.getGrantedScopes(provider) : <String>[];
      
      setState(() {
        _providerStates[provider] = OAuthProviderState(
          provider: provider,
          status: hasValidToken 
              ? OAuthConnectionStatus.connected 
              : OAuthConnectionStatus.disconnected,
          connectedAt: tokenInfo?.issuedAt,
          expiresAt: tokenInfo?.expiresAt,
          grantedScopes: scopes,
          lastRefresh: DateTime.now(),
          isRefreshable: tokenInfo?.refreshToken != null,
        );
      });
    } catch (e) {
      _showErrorDialog('Refresh Failed', 'Failed to refresh ${provider.toString()} token: $e');
    }
  }

  void _manageScopes(OAuthProvider provider) {
    // Navigate to scope management screen
  }

  void _viewProviderDetails(OAuthProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text('${provider.toString()} Details'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(SpacingTokens.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider info
                _buildProviderInfoSection(provider),
                SizedBox(height: SpacingTokens.xl),
                
                // Token management
                Text(
                  'Token Management',
                  style: TextStyles.sectionTitle.copyWith(
                    color: ThemeColors(context).onSurface,
                  ),
                ),
                SizedBox(height: SpacingTokens.lg),
                OAuthTokenManager(provider: provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderInfoSection(OAuthProvider provider) {
    final colors = ThemeColors(context);
    final state = _providerStates[provider];
    
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: colors.primary, size: 32),
                SizedBox(width: SpacingTokens.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.toString(),
                        style: TextStyles.bodyLarge.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: SpacingTokens.xs),
                      Text(
                        provider.info.description,
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            Row(
              children: [
                _buildInfoItem('Status', state?.status.toString() ?? 'Unknown', colors),
                SizedBox(width: SpacingTokens.xl),
                if (state?.connectedAt != null)
                  _buildInfoItem('Connected', _formatDateTime(state!.connectedAt!), colors),
              ],
            ),
            if (state?.expiresAt != null) ...[
              SizedBox(height: SpacingTokens.md),
              _buildInfoItem('Expires', _formatDateTime(state!.expiresAt!), colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: SpacingTokens.xs),
        Text(
          value,
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showAddIntegrationDialog() {
    // Show dialog for adding custom OAuth providers
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }
}

// Supporting enums and classes
enum OAuthProviderFilter {
  all,
  connected,
  disconnected,
  errors,
}

