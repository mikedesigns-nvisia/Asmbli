import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'integration_installation_service.dart';
import 'integration_health_monitoring_service.dart';
import 'mcp_settings_service.dart';

/// Service for integration marketplace functionality
class IntegrationMarketplaceService {
  final IntegrationInstallationService _installationService;
  final IntegrationHealthMonitoringService _healthService;
  final MCPSettingsService _mcpSettingsService;

  // Marketplace state
  final Map<String, MarketplaceIntegration> _marketplaceCache = {};
  final StreamController<List<MarketplaceIntegration>> _marketplaceUpdatesController = 
      StreamController<List<MarketplaceIntegration>>.broadcast();

  IntegrationMarketplaceService(
    this._installationService,
    this._healthService,
    this._mcpSettingsService,
  ) {
    _buildMarketplaceCache();
  }

  /// Stream of marketplace integrations with current status
  Stream<List<MarketplaceIntegration>> get marketplaceUpdates => 
      _marketplaceUpdatesController.stream;

  /// Get all marketplace integrations
  List<MarketplaceIntegration> get allIntegrations => 
      _marketplaceCache.values.toList();

  /// Get integrations by category
  List<MarketplaceIntegration> getIntegrationsByCategory(IntegrationCategory category) {
    return _marketplaceCache.values
        .where((integration) => integration.definition.category == category)
        .toList();
  }

  /// Search integrations
  List<MarketplaceIntegration> searchIntegrations(String query) {
    if (query.isEmpty) return allIntegrations;
    
    final lowercaseQuery = query.toLowerCase();
    return _marketplaceCache.values
        .where((integration) =>
            integration.definition.name.toLowerCase().contains(lowercaseQuery) ||
            integration.definition.description.toLowerCase().contains(lowercaseQuery) ||
            integration.definition.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)))
        .toList();
  }

  /// Get popular integrations
  List<MarketplaceIntegration> getPopularIntegrations() {
    return _marketplaceCache.values
        .where((integration) => integration.definition.isPopular)
        .toList();
  }

  /// Get recommended integrations
  List<MarketplaceIntegration> getRecommendedIntegrations() {
    return _marketplaceCache.values
        .where((integration) => integration.definition.isRecommended)
        .toList();
  }

  /// Get integrations by difficulty
  List<MarketplaceIntegration> getIntegrationsByDifficulty(String difficulty) {
    return _marketplaceCache.values
        .where((integration) => integration.definition.difficulty == difficulty)
        .toList();
  }

  /// Get installed integrations
  List<MarketplaceIntegration> getInstalledIntegrations() {
    return _marketplaceCache.values
        .where((integration) => integration.installationStatus == IntegrationInstallationStatus.installed)
        .toList();
  }

  /// Get available (not installed) integrations
  List<MarketplaceIntegration> getAvailableIntegrations() {
    return _marketplaceCache.values
        .where((integration) => 
            integration.installationStatus == IntegrationInstallationStatus.available &&
            integration.definition.isAvailable)
        .toList();
  }

  /// Install integration from marketplace
  Future<InstallationResult> installIntegration(
    String integrationId, {
    Map<String, dynamic>? config,
    bool autoDetect = true,
  }) async {
    // Update status to installing
    _updateIntegrationStatus(integrationId, IntegrationInstallationStatus.installing);

    try {
      final result = await _installationService.installIntegration(
        integrationId: integrationId,
        customConfig: config,
        autoDetect: autoDetect,
      );

      // Update status based on result
      if (result.success) {
        _updateIntegrationStatus(integrationId, IntegrationInstallationStatus.installed);
      } else {
        _updateIntegrationStatus(integrationId, IntegrationInstallationStatus.failed);
      }

      return result;
    } catch (e) {
      _updateIntegrationStatus(integrationId, IntegrationInstallationStatus.failed);
      rethrow;
    }
  }

  /// Uninstall integration
  Future<bool> uninstallIntegration(String integrationId) async {
    _updateIntegrationStatus(integrationId, IntegrationInstallationStatus.uninstalling);

    try {
      final success = await _installationService.uninstallIntegration(integrationId);
      
      if (success) {
        _updateIntegrationStatus(integrationId, IntegrationInstallationStatus.available);
      } else {
        _updateIntegrationStatus(integrationId, IntegrationInstallationStatus.failed);
      }

      return success;
    } catch (e) {
      _updateIntegrationStatus(integrationId, IntegrationInstallationStatus.failed);
      return false;
    }
  }

  /// Get integration details with current status
  MarketplaceIntegration? getIntegrationDetails(String integrationId) {
    return _marketplaceCache[integrationId];
  }

  /// Get integration categories with counts
  Map<IntegrationCategory, int> getCategoryCounts() {
    final counts = <IntegrationCategory, int>{};
    
    for (final category in IntegrationCategory.values) {
      counts[category] = _marketplaceCache.values
          .where((integration) => integration.definition.category == category)
          .length;
    }
    
    return counts;
  }

  /// Get marketplace statistics
  MarketplaceStatistics getMarketplaceStatistics() {
    final stats = MarketplaceStatistics();
    
    for (final integration in _marketplaceCache.values) {
      stats.total++;
      
      if (integration.definition.isAvailable) {
        stats.available++;
      } else {
        stats.comingSoon++;
      }
      
      switch (integration.installationStatus) {
        case IntegrationInstallationStatus.installed:
          stats.installed++;
          break;
        case IntegrationInstallationStatus.installing:
          stats.installing++;
          break;
        case IntegrationInstallationStatus.failed:
          stats.failed++;
          break;
        default:
          break;
      }
      
      if (integration.definition.isPopular) {
        stats.popular++;
      }
      
      if (integration.definition.isRecommended) {
        stats.recommended++;
      }
    }
    
    return stats;
  }

  /// Build marketplace cache with current installation status
  void _buildMarketplaceCache() {
    _marketplaceCache.clear();
    
    final allMCPServers = _mcpSettingsService.allMCPServers;
    
    for (final integration in IntegrationRegistry.allIntegrations) {
      final isInstalled = allMCPServers.containsKey(integration.id);
      final installationStatus = isInstalled 
          ? IntegrationInstallationStatus.installed
          : IntegrationInstallationStatus.available;
      
      final health = _healthService.getIntegrationHealth(integration.id);
      
      _marketplaceCache[integration.id] = MarketplaceIntegration(
        definition: integration,
        installationStatus: installationStatus,
        health: health,
        lastUpdated: DateTime.now(),
      );
    }
    
    _notifyMarketplaceUpdates();
  }

  /// Update integration installation status
  void _updateIntegrationStatus(String integrationId, IntegrationInstallationStatus status) {
    final existing = _marketplaceCache[integrationId];
    if (existing != null) {
      _marketplaceCache[integrationId] = MarketplaceIntegration(
        definition: existing.definition,
        installationStatus: status,
        health: existing.health,
        lastUpdated: DateTime.now(),
      );
      
      _notifyMarketplaceUpdates();
    }
  }

  /// Refresh marketplace data
  void refreshMarketplace() {
    _buildMarketplaceCache();
  }

  /// Notify listeners of marketplace updates
  void _notifyMarketplaceUpdates() {
    _marketplaceUpdatesController.add(allIntegrations);
  }

  /// Get integration suggestions based on installed tools
  List<MarketplaceIntegration> getIntegrationSuggestions({int limit = 5}) {
    // For now, return popular and recommended integrations that aren't installed
    final suggestions = _marketplaceCache.values
        .where((integration) =>
            integration.installationStatus == IntegrationInstallationStatus.available &&
            integration.definition.isAvailable &&
            (integration.definition.isPopular || integration.definition.isRecommended))
        .toList();
    
    // Sort by popularity and recommendation
    suggestions.sort((a, b) {
      final aScore = (a.definition.isPopular ? 2 : 0) + (a.definition.isRecommended ? 1 : 0);
      final bScore = (b.definition.isPopular ? 2 : 0) + (b.definition.isRecommended ? 1 : 0);
      return bScore.compareTo(aScore);
    });
    
    return suggestions.take(limit).toList();
  }

  /// Filter integrations by multiple criteria
  List<MarketplaceIntegration> filterIntegrations({
    IntegrationCategory? category,
    String? difficulty,
    IntegrationInstallationStatus? status,
    bool? isPopular,
    bool? isRecommended,
    bool? isAvailable,
  }) {
    return _marketplaceCache.values.where((integration) {
      if (category != null && integration.definition.category != category) {
        return false;
      }
      
      if (difficulty != null && integration.definition.difficulty != difficulty) {
        return false;
      }
      
      if (status != null && integration.installationStatus != status) {
        return false;
      }
      
      if (isPopular != null && integration.definition.isPopular != isPopular) {
        return false;
      }
      
      if (isRecommended != null && integration.definition.isRecommended != isRecommended) {
        return false;
      }
      
      if (isAvailable != null && integration.definition.isAvailable != isAvailable) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Dispose resources
  void dispose() {
    _marketplaceUpdatesController.close();
  }
}

/// Integration with marketplace-specific information
class MarketplaceIntegration {
  final IntegrationDefinition definition;
  final IntegrationInstallationStatus installationStatus;
  final IntegrationHealth? health;
  final DateTime lastUpdated;

  const MarketplaceIntegration({
    required this.definition,
    required this.installationStatus,
    this.health,
    required this.lastUpdated,
  });

  /// Get display status for UI
  String get displayStatus {
    switch (installationStatus) {
      case IntegrationInstallationStatus.available:
        return definition.isAvailable ? 'Available' : 'Coming Soon';
      case IntegrationInstallationStatus.installing:
        return 'Installing...';
      case IntegrationInstallationStatus.installed:
        return health?.statusText ?? 'Installed';
      case IntegrationInstallationStatus.uninstalling:
        return 'Uninstalling...';
      case IntegrationInstallationStatus.failed:
        return 'Installation Failed';
    }
  }

  /// Check if integration can be installed
  bool get canInstall {
    return installationStatus == IntegrationInstallationStatus.available && 
           definition.isAvailable;
  }

  /// Check if integration can be uninstalled
  bool get canUninstall {
    return installationStatus == IntegrationInstallationStatus.installed;
  }

  /// Check if integration is currently processing
  bool get isProcessing {
    return installationStatus == IntegrationInstallationStatus.installing ||
           installationStatus == IntegrationInstallationStatus.uninstalling;
  }
}

/// Integration installation status
enum IntegrationInstallationStatus {
  available,
  installing,
  installed,
  uninstalling,
  failed,
}

/// Marketplace statistics
class MarketplaceStatistics {
  int total = 0;
  int available = 0;
  int installed = 0;
  int installing = 0;
  int failed = 0;
  int comingSoon = 0;
  int popular = 0;
  int recommended = 0;

  /// Get installation percentage
  double get installationPercentage {
    if (available == 0) return 0.0;
    return (installed / available) * 100.0;
  }

  /// Get availability percentage
  double get availabilityPercentage {
    if (total == 0) return 0.0;
    return (available / total) * 100.0;
  }
}

/// Provider for integration marketplace service
final integrationMarketplaceServiceProvider = Provider<IntegrationMarketplaceService>((ref) {
  final installationService = ref.read(integrationInstallationServiceProvider);
  final healthService = ref.read(integrationHealthMonitoringServiceProvider);
  final mcpSettingsService = ref.read(mcpSettingsServiceProvider);
  
  final service = IntegrationMarketplaceService(
    installationService,
    healthService,
    mcpSettingsService,
  );
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for marketplace statistics
final marketplaceStatisticsProvider = StreamProvider<MarketplaceStatistics>((ref) {
  final marketplaceService = ref.read(integrationMarketplaceServiceProvider);
  
  return marketplaceService.marketplaceUpdates.map((integrations) {
    return marketplaceService.getMarketplaceStatistics();
  });
});

/// Provider for integration suggestions
final integrationSuggestionsProvider = StreamProvider<List<MarketplaceIntegration>>((ref) {
  final marketplaceService = ref.read(integrationMarketplaceServiceProvider);
  
  return marketplaceService.marketplaceUpdates.map((integrations) {
    return marketplaceService.getIntegrationSuggestions();
  });
});