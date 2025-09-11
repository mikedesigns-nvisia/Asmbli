import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/oauth_provider.dart';
import '../../../../core/services/oauth_integration_service.dart';
import '../../../../core/services/mcp_catalog_service.dart';
import '../../../../core/models/mcp_catalog_entry.dart';
import '../widgets/oauth_provider_card.dart';

/// OAuth connections management screen for secure 3rd party authentication
class OAuthConnectionsScreen extends ConsumerStatefulWidget {
  const OAuthConnectionsScreen({super.key});

  @override
  ConsumerState<OAuthConnectionsScreen> createState() => _OAuthConnectionsScreenState();
}

class _OAuthConnectionsScreenState extends ConsumerState<OAuthConnectionsScreen> {
  final Map<OAuthProvider, OAuthProviderState> _providerStates = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeProviderStates();
  }

  Future<void> _initializeProviderStates() async {
    final oauthService = ref.read(oauthIntegrationServiceProvider);
    
    // Initialize all provider states
    for (final provider in OAuthProvider.values) {
      final hasValidToken = await oauthService.hasValidToken(provider);
      _providerStates[provider] = OAuthProviderState(
        provider: provider,
        status: hasValidToken 
            ? OAuthConnectionStatus.connected 
            : OAuthConnectionStatus.disconnected,
        connectedAt: hasValidToken ? DateTime.now() : null,
      );
    }
    
    if (mounted) {
      setState(() => _isInitialized = true);
    }
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
              child: _isInitialized
                  ? _buildContent(colors)
                  : _buildLoadingState(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.headerPadding),
      child: Row(
        children: [
          HeaderButton(
            text: 'Back',
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text(
            'OAuth Connections',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const Spacer(),
          SizedBox(width: 120), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildContent(ThemeColors colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(colors),
          SizedBox(height: SpacingTokens.xl),
          _buildProvidersSection(colors),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(ThemeColors colors) {
    final connectedCount = _providerStates.values
        .where((state) => state.status.isActive)
        .length;
    
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Icon(
                    Icons.security,
                    size: 24,
                    color: colors.primary,
                  ),
                ),
                SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure OAuth 2.0 Connections',
                        style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
                      ),
                      SizedBox(height: SpacingTokens.xs),
                      Text(
                        'Connect third-party services securely using industry-standard OAuth 2.0',
                        style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.md),
            
            // Connection Status Summary
            Container(
              padding: EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: colors.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    connectedCount > 0 ? Icons.check_circle : Icons.info,
                    color: connectedCount > 0 ? colors.primary : colors.accent,
                    size: 20,
                  ),
                  SizedBox(width: SpacingTokens.sm),
                  Text(
                    connectedCount > 0
                        ? '$connectedCount of ${OAuthProvider.values.length} services connected'
                        : 'No services connected yet',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (connectedCount > 0)
                    AsmblButton.secondary(
                      text: 'Refresh All',
                      onPressed: _refreshAllConnections,
                      icon: Icons.refresh,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersSection(ThemeColors colors) {
    final mcpEntries = ref.watch(mcpCatalogEntriesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Available Providers',
              style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
            ),
            const Spacer(),
            AsmblButton.secondary(
              text: 'Browse MCP Catalog',
              icon: Icons.apps,
              onPressed: () {
                Navigator.of(context).pop(); // Go back to settings
                // Note: User can navigate to Tools > Catalog from main navigation
              },
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.md),
        Text(
          'Connect to external services to enable enhanced MCP server functionality. ${_getMcpIntegrationSummary(ref.watch(mcpCatalogEntriesProvider))}',
          style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
        ),
        SizedBox(height: SpacingTokens.lg),
        
        // Provider cards with MCP integration info
        ...OAuthProvider.values.map((provider) {
          final state = _providerStates[provider]!;
          final relatedMcpServers = _getRelatedMcpServers(provider, mcpEntries);
          
          return Padding(
            padding: EdgeInsets.only(bottom: SpacingTokens.md),
            child: Column(
              children: [
                OAuthProviderCard(
                  provider: provider,
                  state: state,
                  onConnect: () => _handleConnect(provider),
                  onDisconnect: () => _handleDisconnect(provider),
                  onRefresh: () => _handleRefresh(provider),
                ),
                if (relatedMcpServers.isNotEmpty) ...[
                  SizedBox(height: SpacingTokens.xs),
                  _buildMcpServersInfo(colors, provider, relatedMcpServers),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLoadingState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colors.primary),
          SizedBox(height: SpacingTokens.md),
          Text(
            'Loading OAuth connections...',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConnect(OAuthProvider provider) async {
    setState(() {
      _providerStates[provider] = _providerStates[provider]!.copyWith(
        status: OAuthConnectionStatus.connecting,
      );
    });

    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      final result = await oauthService.authenticate(provider);

      if (result.isSuccess) {
        setState(() {
          _providerStates[provider] = _providerStates[provider]!.copyWith(
            status: OAuthConnectionStatus.connected,
            connectedAt: DateTime.now(),
            errorMessage: null,
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully connected to ${provider.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _providerStates[provider] = _providerStates[provider]!.copyWith(
            status: OAuthConnectionStatus.error,
            errorMessage: result.error,
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to connect: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _providerStates[provider] = _providerStates[provider]!.copyWith(
          status: OAuthConnectionStatus.error,
          errorMessage: e.toString(),
        );
      });
    }
  }

  Future<void> _handleDisconnect(OAuthProvider provider) async {
    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      await oauthService.revokeCredentials(provider);

      setState(() {
        _providerStates[provider] = _providerStates[provider]!.copyWith(
          status: OAuthConnectionStatus.disconnected,
          connectedAt: null,
          lastUsed: null,
          errorMessage: null,
        );
      });

      if (mounted) {
        final colors = ThemeColors(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disconnected from ${provider.displayName}'),
            backgroundColor: colors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRefresh(OAuthProvider provider) async {
    setState(() {
      _providerStates[provider] = _providerStates[provider]!.copyWith(
        status: OAuthConnectionStatus.connecting,
      );
    });

    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      final result = await oauthService.refreshToken(provider);

      if (result.isSuccess) {
        setState(() {
          _providerStates[provider] = _providerStates[provider]!.copyWith(
            status: OAuthConnectionStatus.connected,
            lastUsed: DateTime.now(),
            errorMessage: null,
          );
        });
      } else {
        setState(() {
          _providerStates[provider] = _providerStates[provider]!.copyWith(
            status: OAuthConnectionStatus.error,
            errorMessage: result.error,
          );
        });
      }
    } catch (e) {
      setState(() {
        _providerStates[provider] = _providerStates[provider]!.copyWith(
          status: OAuthConnectionStatus.error,
          errorMessage: e.toString(),
        );
      });
    }
  }

  Future<void> _refreshAllConnections() async {
    for (final provider in OAuthProvider.values) {
      final state = _providerStates[provider]!;
      if (state.status.isActive) {
        await _handleRefresh(provider);
      }
    }
  }

  String _getMcpIntegrationSummary(List<MCPCatalogEntry> mcpEntries) {
    final oauthRequiredServers = mcpEntries.where((entry) => 
      entry.requiredAuth.any((auth) => auth.type == MCPAuthType.oauth)
    ).length;
    
    if (oauthRequiredServers == 0) {
      return 'Browse the MCP catalog to discover OAuth-enabled servers.';
    }
    
    return '$oauthRequiredServers MCP servers in the catalog support OAuth authentication.';
  }

  List<MCPCatalogEntry> _getRelatedMcpServers(OAuthProvider provider, List<MCPCatalogEntry> mcpEntries) {
    // Map OAuth providers to MCP server IDs that require them
    final providerMappings = {
      OAuthProvider.github: ['github-mcp', 'github-repo-manager'],
      OAuthProvider.slack: ['slack-mcp', 'slack-integration'],
      OAuthProvider.linear: ['linear-mcp', 'linear-project-manager'],
      OAuthProvider.microsoft: ['microsoft-graph', 'outlook-mcp'],
      OAuthProvider.notion: ['notion-mcp', 'notion-database'],
      OAuthProvider.braveSearch: ['brave-search'],
    };

    final relatedIds = providerMappings[provider] ?? [];
    return mcpEntries.where((entry) => 
      relatedIds.contains(entry.id) ||
      entry.requiredAuth.any((auth) => auth.type == MCPAuthType.oauth)
    ).toList();
  }

  Widget _buildMcpServersInfo(ThemeColors colors, OAuthProvider provider, List<MCPCatalogEntry> relatedServers) {
    return Container(
      margin: EdgeInsets.only(left: SpacingTokens.xl),
      padding: EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.extension,
                size: 16,
                color: colors.accent,
              ),
              SizedBox(width: SpacingTokens.xs),
              Text(
                'MCP Servers requiring this provider:',
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.xs),
          Wrap(
            spacing: SpacingTokens.xs,
            runSpacing: SpacingTokens.xs,
            children: relatedServers.take(3).map((server) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: SpacingTokens.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
              ),
              child: Text(
                server.name,
                style: TextStyles.caption.copyWith(
                  color: colors.accent,
                  fontSize: 10,
                ),
              ),
            )).toList(),
          ),
          if (relatedServers.length > 3) ...[
            SizedBox(height: SpacingTokens.xs),
            Text(
              '+ ${relatedServers.length - 3} more servers',
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}