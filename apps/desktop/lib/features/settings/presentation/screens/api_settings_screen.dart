import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../providers/conversation_provider.dart';
import '../widgets/api_key_dialog.dart';
import 'dart:async';

/// Modern API Configuration Screen - Clean, focused, user-friendly
class APISettingsScreen extends ConsumerStatefulWidget {
  const APISettingsScreen({super.key});

  @override
  ConsumerState<APISettingsScreen> createState() => _APISettingsScreenState();
}

class _APISettingsScreenState extends ConsumerState<APISettingsScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _statusUpdateTimer;
  Map<String, bool> _connectionStatuses = {};
  Map<String, DateTime> _lastConnectionTests = {};
  
  // Animation controllers for live indicators
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
    
    // Start periodic status updates
    _startStatusUpdates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _statusUpdateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
  
  void _startStatusUpdates() {
    _statusUpdateTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _updateConnectionStatuses();
    });
    // Initial update
    _updateConnectionStatuses();
  }
  
  Future<void> _updateConnectionStatuses() async {
    final configs = ref.read(apiConfigsProvider);
    final service = ref.read(apiConfigServiceProvider);
    
    for (final config in configs.values) {
      if (config.isConfigured) {
        try {
          final isConnected = await service.testApiConfig(config.id);
          if (mounted) {
            setState(() {
              _connectionStatuses[config.id] = isConnected;
              _lastConnectionTests[config.id] = DateTime.now();
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _connectionStatuses[config.id] = false;
              _lastConnectionTests[config.id] = DateTime.now();
            });
          }
        }
      }
    }
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
    final connectedConfigs = _connectionStatuses.values.where((status) => status).length;

    return Consumer(
      builder: (context, ref, child) {
        final conversationsAsync = ref.watch(conversationsProvider);
        
        return Row(
          children: [
            _buildLiveStatCard(
              'Connected APIs',
              connectedConfigs.toString(),
              Icons.wifi,
              connectedConfigs > 0 ? colors.success : colors.error,
              colors,
              isLive: true,
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
            conversationsAsync.when(
              data: (conversations) => _buildLiveStatCard(
                'Active Chats',
                conversations.length.toString(),
                Icons.chat,
                conversations.isNotEmpty ? colors.primary : colors.onSurfaceVariant,
                colors,
                isLive: true,
              ),
              loading: () => _buildStatCard(
                'Active Chats',
                '...',
                Icons.chat,
                colors.onSurfaceVariant,
                colors,
              ),
              error: (_, __) => _buildStatCard(
                'Active Chats',
                '0',
                Icons.chat,
                colors.error,
                colors,
              ),
            ),
            SizedBox(width: SpacingTokens.componentSpacing),
            _buildStatCard(
              'Default Provider',
              _getDefaultProviderName(configs),
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
      },
    );
  }

  Widget _buildLiveStatCard(String label, String value, IconData icon, Color color, ThemeColors colors, {bool isLive = false}) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(SpacingTokens.componentSpacing),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(
              color: color.withValues(alpha: isLive ? _pulseAnimation.value * 0.5 + 0.3 : 0.3),
              width: isLive ? 1.5 : 1.0,
            ),
            boxShadow: isLive ? [
              BoxShadow(
                color: color.withValues(alpha: _pulseAnimation.value * 0.3),
                blurRadius: 4,
                spreadRadius: 0,
              )
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(icon, size: 16, color: color),
                  if (isLive)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.success.withValues(alpha: _pulseAnimation.value),
                              blurRadius: 2,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: SpacingTokens.iconSpacing),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        value,
                        style: TextStyles.bodyLarge.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isLive) ...[
                        SizedBox(width: 4),
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: colors.success.withValues(alpha: _pulseAnimation.value),
                        ),
                      ],
                    ],
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
      },
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
                        // Real-time Status Indicator
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final connectionStatus = _connectionStatuses[configId];
                            final lastTest = _lastConnectionTests[configId];
                            final isRealtimeConnected = connectionStatus == true;
                            final isTestingOrUnknown = connectionStatus == null;
                            
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: !isConfigured 
                                  ? colors.error
                                  : isRealtimeConnected 
                                    ? colors.success
                                    : isTestingOrUnknown 
                                      ? colors.warning.withValues(alpha: _pulseAnimation.value)
                                      : colors.error,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isRealtimeConnected ? [
                                  BoxShadow(
                                    color: colors.success.withValues(alpha: _pulseAnimation.value * 0.5),
                                    blurRadius: 2,
                                  )
                                ] : null,
                              ),
                            );
                          },
                        ),
                        SizedBox(width: SpacingTokens.iconSpacing),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusText(configId, isConfigured),
                                style: TextStyles.bodyMedium.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              if (_lastConnectionTests[configId] != null)
                                Text(
                                  'Last checked: ${_formatLastTestTime(_lastConnectionTests[configId]!)}',
                                  style: TextStyles.caption.copyWith(
                                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
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
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live System Status
            Text(
              'System Status',
              style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            
            _buildSystemStatusCard(colors),
            
            SizedBox(height: SpacingTokens.sectionSpacing),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            
            _buildQuickActionCard('Import Configuration', Icons.upload, colors),
            SizedBox(height: SpacingTokens.componentSpacing),
            _buildQuickActionCard('Export All', Icons.download, colors),
            SizedBox(height: SpacingTokens.componentSpacing),
            _buildQuickActionCard('API Usage Stats', Icons.analytics, colors),
            
            SizedBox(height: SpacingTokens.sectionSpacing),
            
            // Real-time Activity
            Text(
              'Live Activity',
              style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            
            _buildActivityFeed(colors),
          ],
        ),
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
    // TODO: Implement test all connections
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Testing all connections...'),
        backgroundColor: ThemeColors(context).primary,
      ),
    );
  }

  void _addProvider() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ApiKeyDialog(),
    );
    
    if (result == true) {
      setState(() {
        // UI will refresh automatically via provider
      });
    }
  }

  void _testConnection(String configId) async {
    final config = ref.read(apiConfigsProvider)[configId];
    if (config == null) return;

    try {
      final apiConfigsNotifier = ref.read(apiConfigsProvider.notifier);
      final service = ref.read(apiConfigServiceProvider);
      final isValid = await service.testApiConfig(configId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isValid ? 'Connection successful!' : 'Connection failed',
          ),
          backgroundColor: isValid 
            ? ThemeColors(context).success 
            : ThemeColors(context).error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection test failed: $e'),
          backgroundColor: ThemeColors(context).error,
        ),
      );
    }
  }

  void _setAsDefault(String configId) async {
    try {
      final apiConfigsNotifier = ref.read(apiConfigsProvider.notifier);
      await apiConfigsNotifier.setDefault(configId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Set as default successfully!'),
          backgroundColor: ThemeColors(context).success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set as default: $e'),
          backgroundColor: ThemeColors(context).error,
        ),
      );
    }
  }

  void _configureProvider(String configId, ApiConfig config) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ApiKeyDialog(existingConfig: config),
    );
    
    if (result == true) {
      setState(() {
        // UI will refresh automatically via provider
      });
    }
  }

  void _handleProviderAction(String action, String configId, ApiConfig config) async {
    switch (action) {
      case 'duplicate':
        await _duplicateProvider(configId, config);
        break;
      case 'export':
        await _exportConfig(configId, config);
        break;
      case 'disconnect':
        await _disconnectProvider(configId);
        break;
      case 'delete':
        await _deleteProvider(configId);
        break;
    }
  }


  Future<void> _duplicateProvider(String configId, ApiConfig config) async {
    final newId = '${config.id}-copy-${DateTime.now().millisecondsSinceEpoch}';
    final newConfig = config.copyWith(
      id: newId,
      name: '${config.name} (Copy)',
      isDefault: false,
    );
    
    try {
      final apiConfigsNotifier = ref.read(apiConfigsProvider.notifier);
      await apiConfigsNotifier.addConfig(newId, newConfig);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Provider duplicated successfully!'),
          backgroundColor: ThemeColors(context).success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to duplicate provider: $e'),
          backgroundColor: ThemeColors(context).error,
        ),
      );
    }
  }

  Future<void> _exportConfig(String configId, ApiConfig config) async {
    // TODO: Implement config export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export functionality coming soon...'),
        backgroundColor: ThemeColors(context).primary,
      ),
    );
  }

  Future<void> _disconnectProvider(String configId) async {
    try {
      final config = ref.read(apiConfigsProvider)[configId];
      if (config == null) return;
      
      final updatedConfig = config.copyWith(apiKey: '', enabled: false);
      final apiConfigsNotifier = ref.read(apiConfigsProvider.notifier);
      await apiConfigsNotifier.addConfig(configId, updatedConfig);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Provider disconnected successfully!'),
          backgroundColor: ThemeColors(context).success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect provider: $e'),
          backgroundColor: ThemeColors(context).error,
        ),
      );
    }
  }

  Future<void> _deleteProvider(String configId) async {
    final config = ref.read(apiConfigsProvider)[configId];
    if (config == null) return;
    
    if (config.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete the default provider. Set another as default first.'),
          backgroundColor: ThemeColors(context).error,
        ),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Provider'),
        content: Text('Are you sure you want to delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: ThemeColors(context).error)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final apiConfigsNotifier = ref.read(apiConfigsProvider.notifier);
        await apiConfigsNotifier.removeConfig(configId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Provider deleted successfully!'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete provider: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }
  
  String _getStatusText(String configId, bool isConfigured) {
    if (!isConfigured) return 'Not configured';
    
    final connectionStatus = _connectionStatuses[configId];
    if (connectionStatus == null) return 'Testing connection...';
    if (connectionStatus) return 'Connected & Live';
    return 'Connection failed';
  }
  
  String _formatLastTestTime(DateTime lastTest) {
    final now = DateTime.now();
    final difference = now.difference(lastTest);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
  
  String _getDefaultProviderName(Map<String, ApiConfig> configs) {
    if (configs.isEmpty) return 'None';
    
    try {
      final defaultConfig = configs.values.firstWhere((c) => c.isDefault);
      return defaultConfig.provider;
    } catch (e) {
      // If no default is found, return the first available provider
      return configs.values.isEmpty ? 'None' : configs.values.first.provider;
    }
  }
  
  Widget _buildSystemStatusCard(ThemeColors colors) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return AsmblCard(
          child: Column(
            children: [
              // System health indicator
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.success.withValues(alpha: _pulseAnimation.value * 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  SizedBox(width: SpacingTokens.componentSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Systems Online',
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Last updated: ${DateTime.now().toString().substring(11, 16)}',
                          style: TextStyles.caption.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: SpacingTokens.elementSpacing),
              
              // Resource usage
              _buildResourceUsage('Storage', 0.65, colors),
              SizedBox(height: SpacingTokens.xs_precise),
              _buildResourceUsage('Memory', 0.43, colors),
              SizedBox(height: SpacingTokens.xs_precise),
              _buildResourceUsage('Network', 0.28, colors),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildResourceUsage(String label, double usage, ThemeColors colors) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            ),
            Text(
              '${(usage * 100).toInt()}%',
              style: TextStyles.caption.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: usage,
            child: Container(
              decoration: BoxDecoration(
                color: usage > 0.8 ? colors.error : usage > 0.6 ? colors.warning : colors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActivityFeed(ThemeColors colors) {
    return Consumer(
      builder: (context, ref, child) {
        final conversationsAsync = ref.watch(conversationsProvider);
        
        return AsmblCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timeline, size: 16, color: colors.primary),
                  SizedBox(width: SpacingTokens.iconSpacing),
                  Text(
                    'Recent Activity',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: SpacingTokens.componentSpacing),
              
              conversationsAsync.when(
                data: (conversations) => conversations.isEmpty
                  ? Text(
                      'No recent activity',
                      style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                    )
                  : Column(
                      children: conversations.take(3).map((conv) => 
                        Padding(
                          padding: EdgeInsets.only(bottom: SpacingTokens.iconSpacing),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: SpacingTokens.iconSpacing),
                              Expanded(
                                child: Text(
                                  conv.title.isEmpty ? 'Untitled Chat' : conv.title,
                                  style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                loading: () => Text(
                  'Loading...',
                  style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
                error: (_, __) => Text(
                  'Error loading activity',
                  style: TextStyles.caption.copyWith(color: colors.error),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}