import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/services/api_config_service.dart';

/// Modern API Configuration Screen - Clean, focused, user-friendly
class APISettingsScreen extends ConsumerStatefulWidget {
  const APISettingsScreen({super.key});

  @override
  ConsumerState<APISettingsScreen> createState() => _APISettingsScreenState();
}

class _APISettingsScreenState extends ConsumerState<APISettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final apiConfigs = ref.watch(apiConfigsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.background,
              colors.background.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // App Navigation
            AppNavigationBar(currentRoute: AppRoutes.settings),
            
            // Page Header
            _buildHeader(colors),
            
            // Main Content
            Expanded(
              child: Row(
                children: [
                  // Main API Configuration Content
                  Expanded(
                    flex: 3,
                    child: _buildMainContent(colors, apiConfigs),
                  ),
                  
                  // Quick Actions Sidebar
                  SizedBox(
                    width: 300,
                    child: _buildSidebar(colors, apiConfigs),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          // Breadcrumb & Title
          Row(
            children: [
              // Back Button
              AsmblButton.secondary(
                text: 'Settings',
                onPressed: () => Navigator.of(context).pop(),
                                icon: Icons.arrow_back,
              ),
              
              SizedBox(width: SpacingTokens.componentSpacing),
              
              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant,
                size: 16,
              ),
              
              SizedBox(width: SpacingTokens.componentSpacing),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Configuration',
                      style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                    ),
                    Text(
                      'Manage AI provider connections and API keys',
                      style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              
              // Search
              SizedBox(
                width: 250,
                child: _buildSearchField(colors),
              ),
            ],
          ),
          
          // Quick Stats
          SizedBox(height: SpacingTokens.sectionSpacing),
          _buildQuickStats(colors, ref.watch(apiConfigsProvider)),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: 'Search providers...',
          hintStyle: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: colors.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: SpacingTokens.componentSpacing,
            vertical: SpacingTokens.componentSpacing,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeColors colors, Map<String, ApiConfig> configs) {
    final activeConfigs = configs.values.where((c) => c.apiKey.isNotEmpty).length;
    final totalProviders = configs.length;

    return Row(
      children: [
        _buildStatCard(
          'Active Connections',
          activeConfigs.toString(),
          Icons.link,
          colors.success,
          colors,
        ),
        SizedBox(width: SpacingTokens.componentSpacing),
        _buildStatCard(
          'Total Providers',
          totalProviders.toString(),
          Icons.cloud,
          colors.primary,
          colors,
        ),
        SizedBox(width: SpacingTokens.componentSpacing),
        _buildStatCard(
          'Default Provider',
          configs.values.firstWhere((c) => c.isDefault, orElse: () => configs.values.first).provider,
          Icons.star,
          colors.warning,
          colors,
        ),
        
        Spacer(),
        
        // Quick Actions
        AsmblButton.secondary(
          text: 'Test All',
          onPressed: _testAllConnections,
                    icon: Icons.speed,
        ),
        SizedBox(width: SpacingTokens.componentSpacing),
        AsmblButton.primary(
          text: 'Add Provider',
          onPressed: _addProvider,
                    icon: Icons.add,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.componentSpacing),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: SpacingTokens.iconSpacing),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeColors colors, Map<String, ApiConfig> configs) {
    final filteredConfigs = _getFilteredConfigs(configs);

    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Cards
          if (filteredConfigs.isNotEmpty) ...[
            ...filteredConfigs.entries.map((entry) => Padding(
              padding: EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
              child: _buildProviderCard(entry.key, entry.value, colors),
            )),
          ] else ...[
            _buildEmptyState(colors),
          ],
          
          SizedBox(height: SpacingTokens.xxl),
        ],
      ),
    );
  }

  Widget _buildProviderCard(String configId, ApiConfig config, ThemeColors colors) {
    final isConfigured = config.apiKey.isNotEmpty;
    final isDefault = config.isDefault;

    return AsmblCard(
      isInteractive: true,
      child: Column(
        children: [
          // Provider Header
          Row(
            children: [
              // Provider Icon/Avatar
              Container(
                padding: EdgeInsets.all(SpacingTokens.componentSpacing),
                decoration: BoxDecoration(
                  color: _getProviderColor(config.provider).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                ),
                child: Icon(
                  _getProviderIcon(config.provider),
                  size: 24,
                  color: _getProviderColor(config.provider),
                ),
              ),
              
              SizedBox(width: SpacingTokens.componentSpacing),
              
              // Provider Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          config.provider,
                          style: TextStyles.cardTitle.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        if (isDefault) ...[
                          SizedBox(width: SpacingTokens.iconSpacing),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: SpacingTokens.iconSpacing,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                              border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 10, color: colors.warning),
                                SizedBox(width: 2),
                                Text(
                                  'DEFAULT',
                                  style: TextStyles.caption.copyWith(
                                    color: colors.warning,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    SizedBox(height: SpacingTokens.xs_precise),
                    
                    Row(
                      children: [
                        // Status Indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConfigured ? colors.success : colors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: SpacingTokens.iconSpacing),
                        
                        Text(
                          isConfigured ? 'Connected' : 'Not configured',
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        
                        if (isConfigured) ...[
                          SizedBox(width: SpacingTokens.componentSpacing),
                          Text(
                            'Model: ${config.model}',
                            style: TextStyles.caption.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              _buildProviderActions(configId, config, colors),
            ],
          ),
          
          // Configuration Details (if configured)
          if (isConfigured) ...[
            SizedBox(height: SpacingTokens.componentSpacing),
            Divider(color: colors.border),
            SizedBox(height: SpacingTokens.componentSpacing),
            _buildProviderDetails(config, colors),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderActions(String configId, ApiConfig config, ThemeColors colors) {
    final isConfigured = config.apiKey.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isConfigured) ...[
          // Test Connection
          IconButton(
            onPressed: () => _testConnection(configId),
            icon: Icon(Icons.speed, color: colors.primary),
            tooltip: 'Test Connection',
          ),
          
          // Set as Default
          if (!config.isDefault)
            IconButton(
              onPressed: () => _setAsDefault(configId),
              icon: Icon(Icons.star_border, color: colors.warning),
              tooltip: 'Set as Default',
            ),
        ],
        
        // Configure/Edit
        IconButton(
          onPressed: () => _configureProvider(configId, config),
          icon: Icon(
            isConfigured ? Icons.edit : Icons.add,
            color: colors.primary,
          ),
          tooltip: isConfigured ? 'Edit Configuration' : 'Configure Provider',
        ),
        
        // More Actions
        PopupMenuButton<String>(
          onSelected: (action) => _handleProviderAction(action, configId, config),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 16),
                  SizedBox(width: SpacingTokens.iconSpacing),
                  Text('Duplicate'),
                ],
              ),
            ),
            if (isConfigured) ...[
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 16),
                    SizedBox(width: SpacingTokens.iconSpacing),
                    Text('Export Config'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'disconnect',
                child: Row(
                  children: [
                    Icon(Icons.link_off, size: 16, color: colors.error),
                    SizedBox(width: SpacingTokens.iconSpacing),
                    Text('Disconnect'),
                  ],
                ),
              ),
            ] else ...[
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: colors.error),
                    SizedBox(width: SpacingTokens.iconSpacing),
                    Text('Remove'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildProviderDetails(ApiConfig config, ThemeColors colors) {
    return Column(
      children: [
        // Configuration Row
        Row(
          children: [
            _buildDetailChip('Provider', config.provider, colors),
            SizedBox(width: SpacingTokens.componentSpacing),
            _buildDetailChip('Model', config.model, colors),
            SizedBox(width: SpacingTokens.componentSpacing),
            _buildDetailChip('Status', config.enabled ? 'Active' : 'Inactive', colors),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailChip(String label, String value, ThemeColors colors) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.componentSpacing,
        vertical: SpacingTokens.iconSpacing,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyles.caption.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeColors colors, Map<String, ApiConfig> configs) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.componentSpacing),
          
          // TODO: Add quick action cards
          _buildQuickActionCard('Import Configuration', Icons.upload, colors),
          SizedBox(height: SpacingTokens.componentSpacing),
          _buildQuickActionCard('Export All', Icons.download, colors),
          SizedBox(height: SpacingTokens.componentSpacing),
          _buildQuickActionCard('API Usage Stats', Icons.analytics, colors),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, ThemeColors colors) {
    return AsmblCard(
      isInteractive: true,
      onTap: () {}, // TODO: Implement actions
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          SizedBox(width: SpacingTokens.componentSpacing),
          Text(
            title,
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: SpacingTokens.xxl),
          Icon(
            Icons.cloud_off,
            size: 64,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: SpacingTokens.sectionSpacing),
          Text(
            'No API providers found',
            style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.componentSpacing),
          Text(
            'Add your first AI provider to get started',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Map<String, ApiConfig> _getFilteredConfigs(Map<String, ApiConfig> configs) {
    if (_searchQuery.isEmpty) return configs;
    
    return Map.fromEntries(
      configs.entries.where((entry) => 
        entry.value.provider.toLowerCase().contains(_searchQuery.toLowerCase())
      ),
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'anthropic':
        return Colors.orange;
      case 'openai':
        return Colors.green;
      case 'google':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'anthropic':
        return Icons.psychology;
      case 'openai':
        return Icons.auto_awesome;
      case 'google':
        return Icons.search;
      default:
        return Icons.cloud;
    }
  }

  // Action Methods
  void _testAllConnections() {
    // TODO: Implement
  }

  void _addProvider() {
    // TODO: Implement
  }

  void _testConnection(String configId) {
    // TODO: Implement
  }

  void _setAsDefault(String configId) {
    // TODO: Implement
  }

  void _configureProvider(String configId, ApiConfig config) {
    // TODO: Implement
  }

  void _handleProviderAction(String action, String configId, ApiConfig config) {
    // TODO: Implement
  }
}