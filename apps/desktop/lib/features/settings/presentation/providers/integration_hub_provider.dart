import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import '../../../../core/services/integration_service.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../core/services/integration_health_monitoring_service.dart' as health;
import '../../../../core/services/integration_marketplace_service.dart';
import '../../../../core/services/simple_detection_service.dart';

/// Unified Integration Hub State
/// Consolidates all integration-related data and operations
class IntegrationHubState {
  final List<IntegrationStatus> integrations;
  final health.HealthStatistics healthStats;
  final MarketplaceStatistics marketplaceStats;
  final SimpleDetectionResult? lastDetectionResult;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;

  const IntegrationHubState({
    this.integrations = const [],
    required this.healthStats,
    required this.marketplaceStats,
    this.lastDetectionResult,
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
  });

  IntegrationHubState copyWith({
    List<IntegrationStatus>? integrations,
    health.HealthStatistics? healthStats,
    MarketplaceStatistics? marketplaceStats,
    SimpleDetectionResult? lastDetectionResult,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return IntegrationHubState(
      integrations: integrations ?? this.integrations,
      healthStats: healthStats ?? this.healthStats,
      marketplaceStats: marketplaceStats ?? this.marketplaceStats,
      lastDetectionResult: lastDetectionResult ?? this.lastDetectionResult,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Computed properties
  int get activeCount => integrations.where((i) => i.isEnabled && i.isConfigured).length;
  int get configuredCount => integrations.where((i) => i.isConfigured && !i.isEnabled).length;
  int get availableCount => integrations.where((i) => !i.isConfigured).length;
  int get totalCount => integrations.length;
  
  double get healthScore {
    if (healthStats.total == 0) return 1.0;
    return healthStats.healthy / healthStats.total;
  }
}

/// Integration Hub Notifier
/// Manages all integration hub operations and state updates
class IntegrationHubNotifier extends StateNotifier<IntegrationHubState> {
  final IntegrationService _integrationService;
  final MCPSettingsService _mcpSettingsService;
  final health.IntegrationHealthMonitoringService _healthService;
  final IntegrationMarketplaceService _marketplaceService;
  final SimpleDetectionService _detectionService;

  IntegrationHubNotifier(
    this._integrationService,
    this._mcpSettingsService,
    this._healthService,
    this._marketplaceService,
    this._detectionService,
  ) : super(IntegrationHubState(
          healthStats: _createInitialHealthStats(),
          marketplaceStats: _createInitialMarketplaceStats(),
          lastUpdated: DateTime.now(),
        )) {
    _initialize();
  }

  static health.HealthStatistics _createInitialHealthStats() {
    return health.HealthStatistics();
  }

  static MarketplaceStatistics _createInitialMarketplaceStats() {
    return MarketplaceStatistics(
      totalIntegrations: 0,
      featuredIntegrations: [],
      popularIntegrations: [],
      recentlyUpdated: [],
      categories: {},
    );
  }

  /// Initialize the integration hub state
  Future<void> _initialize() async {
    await refresh();
  }

  /// Refresh all integration data
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Load all integration data in parallel
      final results = await Future.wait([
        _loadIntegrations(),
        _loadHealthStatistics(),
        _loadMarketplaceStatistics(),
      ]);

      state = state.copyWith(
        integrations: results[0] as List<IntegrationStatus>,
        healthStats: results[1] as health.HealthStatistics,
        marketplaceStats: results[2] as MarketplaceStatistics,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  /// Run auto-detection for available integrations
  Future<void> runAutoDetection() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final detectionResult = await _detectionService.detectBasicTools();
      
      state = state.copyWith(
        lastDetectionResult: detectionResult,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      
      // Refresh integrations to reflect any changes
      await _refreshIntegrations();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: 'Detection failed: ${error.toString()}',
      );
    }
  }

  /// Install/configure an integration
  Future<void> configureIntegration(String integrationId) async {
    try {
      // TODO: Implement integration configuration logic
      // This would typically involve:
      // 1. Getting integration definition
      // 2. Running auto-detection for specific integration
      // 3. Showing configuration modal
      // 4. Creating MCP server configuration
      // 5. Testing connection
      
      await _refreshIntegrations();
    } catch (error) {
      state = state.copyWith(
        error: 'Failed to configure integration: ${error.toString()}',
      );
    }
  }

  /// Enable/disable an integration
  Future<void> toggleIntegration(String integrationId, bool enabled) async {
    try {
      // TODO: Implement toggle logic through MCP settings service
      await _refreshIntegrations();
    } catch (error) {
      state = state.copyWith(
        error: 'Failed to toggle integration: ${error.toString()}',
      );
    }
  }

  /// Remove an integration
  Future<void> removeIntegration(String integrationId) async {
    try {
      await _mcpSettingsService.removeMCPServer(integrationId);
      await _refreshIntegrations();
    } catch (error) {
      state = state.copyWith(
        error: 'Failed to remove integration: ${error.toString()}',
      );
    }
  }

  /// Test integration connection
  Future<void> testIntegration(String integrationId) async {
    try {
      final status = await _mcpSettingsService.testMCPServerConnection(integrationId);
      // TODO: Handle test results and update UI
      await _refreshIntegrations();
    } catch (error) {
      state = state.copyWith(
        error: 'Connection test failed: ${error.toString()}',
      );
    }
  }

  /// Get integration suggestions based on detected tools
  List<IntegrationStatus> getSuggestions() {
    // TODO: Implement intelligent suggestion logic
    // This could use detection results, user patterns, popular integrations, etc.
    return state.integrations.where((integration) {
      // Mock suggestion logic
      return !integration.isConfigured && 
             _isCommonIntegration(integration.definition.id);
    }).take(3).toList();
  }

  /// Filter integrations by category
  List<IntegrationStatus> filterByCategory(String category) {
    if (category == 'all') return state.integrations;
    
    return state.integrations.where((integration) {
      switch (category) {
        case 'active':
          return integration.isEnabled && integration.isConfigured;
        case 'configured':
          return integration.isConfigured && !integration.isEnabled;
        case 'available':
          return !integration.isConfigured;
        case 'development':
          return integration.definition.category == IntegrationCategory.local;
        case 'productivity':
          return integration.definition.category == IntegrationCategory.cloudAPIs;
        case 'communication':
          return integration.definition.category == IntegrationCategory.aiML;
        case 'data':
          return integration.definition.category == IntegrationCategory.databases;
        default:
          return true;
      }
    }).toList();
  }

  /// Search integrations by query
  List<IntegrationStatus> searchIntegrations(String query) {
    if (query.isEmpty) return state.integrations;
    
    final lowercaseQuery = query.toLowerCase();
    return state.integrations.where((integration) {
      final name = integration.definition.name.toLowerCase();
      final description = integration.definition.description.toLowerCase();
      final tags = integration.definition.tags.join(' ').toLowerCase();
      
      return name.contains(lowercaseQuery) ||
             description.contains(lowercaseQuery) ||
             tags.contains(lowercaseQuery);
    }).toList();
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Private helper methods
  Future<List<IntegrationStatus>> _loadIntegrations() async {
    return _integrationService.getAllIntegrationsWithStatus();
  }

  Future<health.HealthStatistics> _loadHealthStatistics() async {
    return _healthService.getHealthStatistics();
  }

  Future<MarketplaceStatistics> _loadMarketplaceStatistics() async {
    final stats = _marketplaceService.getMarketplaceStatistics();
    return stats;
  }

  Future<void> _refreshIntegrations() async {
    final integrations = await _loadIntegrations();
    state = state.copyWith(
      integrations: integrations,
      lastUpdated: DateTime.now(),
    );
  }

  bool _isCommonIntegration(String integrationId) {
    const commonIntegrations = [
      'git', 'github', 'vscode', 'slack', 'docker', 'postgres', 'filesystem'
    ];
    return commonIntegrations.contains(integrationId.toLowerCase());
  }
}

/// Provider for the Integration Hub state
final integrationHubProvider = StateNotifierProvider<IntegrationHubNotifier, IntegrationHubState>((ref) {
  final integrationService = ref.read(integrationServiceProvider);
  final mcpSettingsService = ref.read(mcpSettingsServiceProvider);
  final healthService = ref.read(health.integrationHealthMonitoringServiceProvider);
  final marketplaceService = ref.read(integrationMarketplaceServiceProvider);
  final detectionService = ref.read(simpleDetectionServiceProvider);

  return IntegrationHubNotifier(
    integrationService,
    mcpSettingsService,
    healthService,
    marketplaceService,
    detectionService,
  );
});

/// Convenience providers for specific data slices
final integrationHubIntegrationsProvider = Provider<List<IntegrationStatus>>((ref) {
  return ref.watch(integrationHubProvider).integrations;
});

final integrationHubHealthProvider = Provider<health.HealthStatistics>((ref) {
  return ref.watch(integrationHubProvider).healthStats;
});

final integrationHubStatsProvider = Provider<IntegrationHubStats>((ref) {
  final state = ref.watch(integrationHubProvider);
  return IntegrationHubStats(
    activeCount: state.activeCount,
    configuredCount: state.configuredCount,
    availableCount: state.availableCount,
    totalCount: state.totalCount,
    healthScore: state.healthScore,
  );
});

/// Quick stats data class
class IntegrationHubStats {
  final int activeCount;
  final int configuredCount;
  final int availableCount;
  final int totalCount;
  final double healthScore;

  const IntegrationHubStats({
    required this.activeCount,
    required this.configuredCount,
    required this.availableCount,
    required this.totalCount,
    required this.healthScore,
  });
}

/// Mock data classes - TODO: Replace with actual service implementations

class MarketplaceStatistics {
  final int totalIntegrations;
  final List<String> featuredIntegrations;
  final List<String> popularIntegrations;
  final List<String> recentlyUpdated;
  final Map<String, int> categories;

  const MarketplaceStatistics({
    required this.totalIntegrations,
    required this.featuredIntegrations,
    required this.popularIntegrations,
    required this.recentlyUpdated,
    required this.categories,
  });
}