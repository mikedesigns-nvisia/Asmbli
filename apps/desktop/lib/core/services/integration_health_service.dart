import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'mcp_settings_service.dart';
import 'integration_service.dart';
import '../design_system/components/integration_status_indicators.dart';

/// Service for monitoring integration health and performing health checks
class IntegrationHealthService {
  final MCPSettingsService _mcpService;
  final IntegrationService _integrationService;
  
  // Health check results cache
  final Map<String, IntegrationHealth> _healthCache = {};
  
  // Active health check timers
  final Map<String, Timer> _healthCheckTimers = {};
  
  // Health check intervals (in seconds)
  static const int _defaultCheckInterval = 60;
  static const int _criticalCheckInterval = 30;
  static const int _healthyCheckInterval = 120;
  
  // Stream controllers for health updates
  final _healthUpdatesController = StreamController<IntegrationHealthUpdate>.broadcast();
  
  IntegrationHealthService(this._mcpService, this._integrationService);
  
  /// Stream of health updates
  Stream<IntegrationHealthUpdate> get healthUpdates => _healthUpdatesController.stream;
  
  /// Get current health status for an integration
  IntegrationHealth? getHealth(String integrationId) {
    return _healthCache[integrationId];
  }
  
  /// Get all health statuses
  Map<String, IntegrationHealth> getAllHealth() {
    return Map.from(_healthCache);
  }
  
  /// Start monitoring all configured integrations
  void startMonitoring() {
    final configured = _integrationService.getConfiguredIntegrations();
    for (final integration in configured) {
      if (integration.isEnabled) {
        startMonitoringIntegration(integration.definition.id);
      }
    }
  }
  
  /// Stop monitoring all integrations
  void stopMonitoring() {
    for (final timer in _healthCheckTimers.values) {
      timer.cancel();
    }
    _healthCheckTimers.clear();
  }
  
  /// Start monitoring a specific integration
  void startMonitoringIntegration(String integrationId) {
    // Cancel existing timer if any
    _healthCheckTimers[integrationId]?.cancel();
    
    // Perform immediate health check
    _performHealthCheck(integrationId);
    
    // Schedule periodic health checks
    _healthCheckTimers[integrationId] = Timer.periodic(
      Duration(seconds: _getCheckInterval(integrationId)),
      (_) => _performHealthCheck(integrationId),
    );
  }
  
  /// Stop monitoring a specific integration
  void stopMonitoringIntegration(String integrationId) {
    _healthCheckTimers[integrationId]?.cancel();
    _healthCheckTimers.remove(integrationId);
    _healthCache.remove(integrationId);
  }
  
  /// Perform a manual health check for an integration
  Future<IntegrationHealth> checkHealth(String integrationId) async {
    return await _performHealthCheck(integrationId);
  }
  
  /// Perform batch health check for multiple integrations
  Future<Map<String, IntegrationHealth>> checkMultipleHealth(List<String> integrationIds) async {
    final results = <String, IntegrationHealth>{};
    
    await Future.wait(
      integrationIds.map((id) async {
        results[id] = await checkHealth(id);
      }),
    );
    
    return results;
  }
  
  /// Get health statistics
  HealthStatistics getStatistics() {
    final allHealth = getAllHealth();
    
    int healthy = 0;
    int warning = 0;
    int error = 0;
    int unknown = 0;
    
    for (final health in allHealth.values) {
      switch (health.status) {
        case IntegrationHealthStatus.healthy:
          healthy++;
          break;
        case IntegrationHealthStatus.warning:
          warning++;
          break;
        case IntegrationHealthStatus.error:
          error++;
          break;
        case IntegrationHealthStatus.unknown:
          unknown++;
          break;
      }
    }
    
    return HealthStatistics(
      totalMonitored: allHealth.length,
      healthy: healthy,
      warning: warning,
      error: error,
      unknown: unknown,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Get health history for an integration (last 24 hours)
  List<HealthHistoryEntry> getHealthHistory(String integrationId) {
    // In a real implementation, this would query a database
    // For now, return mock data based on current health
    final currentHealth = _healthCache[integrationId];
    if (currentHealth == null) return [];
    
    final history = <HealthHistoryEntry>[];
    final now = DateTime.now();
    
    // Generate mock history for last 24 hours
    for (int i = 0; i < 24; i++) {
      history.add(HealthHistoryEntry(
        timestamp: now.subtract(Duration(hours: i)),
        status: currentHealth.status,
        responseTime: 100 + (i * 10), // Mock response time
      ));
    }
    
    return history;
  }
  
  /// Perform actual health check for an integration
  Future<IntegrationHealth> _performHealthCheck(String integrationId) async {
    try {
      final integration = IntegrationRegistry.getById(integrationId);
      if (integration == null) {
        return _updateHealth(integrationId, IntegrationHealth(
          status: IntegrationHealthStatus.error,
          lastChecked: DateTime.now(),
          message: 'Integration not found',
        ));
      }
      
      final config = _mcpService.allMCPServers[integrationId];
      if (config == null) {
        return _updateHealth(integrationId, IntegrationHealth(
          status: IntegrationHealthStatus.error,
          lastChecked: DateTime.now(),
          message: 'Integration not configured',
        ));
      }
      
      if (!config.enabled) {
        return _updateHealth(integrationId, IntegrationHealth(
          status: IntegrationHealthStatus.warning,
          lastChecked: DateTime.now(),
          message: 'Integration is disabled',
        ));
      }
      
      // Perform integration-specific health checks
      final healthResult = await _performIntegrationSpecificCheck(integration, config);
      
      return _updateHealth(integrationId, healthResult);
      
    } catch (e) {
      return _updateHealth(integrationId, IntegrationHealth(
        status: IntegrationHealthStatus.error,
        lastChecked: DateTime.now(),
        message: 'Health check failed: $e',
      ));
    }
  }
  
  /// Perform integration-specific health checks
  Future<IntegrationHealth> _performIntegrationSpecificCheck(
    IntegrationDefinition integration,
    MCPServerConfig config,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // Simulate different check types based on integration category
      switch (integration.category) {
        case IntegrationCategory.databases:
          return await _checkDatabaseHealth(integration, config, startTime);
          
        case IntegrationCategory.cloudAPIs:
          return await _checkAPIHealth(integration, config, startTime);
          
        case IntegrationCategory.local:
          return await _checkLocalServiceHealth(integration, config, startTime);
          
        default:
          return await _checkGenericHealth(integration, config, startTime);
      }
    } catch (e) {
      return IntegrationHealth(
        status: IntegrationHealthStatus.error,
        lastChecked: DateTime.now(),
        message: 'Check failed: $e',
        details: {
          'error': e.toString(),
          'integration': integration.id,
        },
      );
    }
  }
  
  /// Check database integration health
  Future<IntegrationHealth> _checkDatabaseHealth(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    // Simulate database connection check
    await Future.delayed(Duration(milliseconds: 100));
    
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;
    
    // Mock health logic
    if (responseTime > 500) {
      return IntegrationHealth(
        status: IntegrationHealthStatus.warning,
        lastChecked: DateTime.now(),
        message: 'Database responding slowly',
        details: {
          'responseTime': responseTime,
          'threshold': 500,
        },
      );
    }
    
    return IntegrationHealth(
      status: IntegrationHealthStatus.healthy,
      lastChecked: DateTime.now(),
      message: 'Database connection healthy',
      details: {
        'responseTime': responseTime,
        'connections': 5,
        'activeQueries': 2,
      },
    );
  }
  
  /// Check API integration health
  Future<IntegrationHealth> _checkAPIHealth(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    // Simulate API endpoint check
    await Future.delayed(Duration(milliseconds: 200));
    
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;
    
    // Mock API health check
    final randomValue = DateTime.now().millisecond % 10;
    
    if (randomValue == 0) {
      return IntegrationHealth(
        status: IntegrationHealthStatus.error,
        lastChecked: DateTime.now(),
        message: 'API endpoint unreachable',
        details: {
          'responseTime': responseTime,
          'httpStatus': 503,
        },
      );
    } else if (randomValue < 3) {
      return IntegrationHealth(
        status: IntegrationHealthStatus.warning,
        lastChecked: DateTime.now(),
        message: 'API rate limit approaching',
        details: {
          'responseTime': responseTime,
          'rateLimitRemaining': 100,
          'rateLimitReset': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
        },
      );
    }
    
    return IntegrationHealth(
      status: IntegrationHealthStatus.healthy,
      lastChecked: DateTime.now(),
      message: 'API connection healthy',
      details: {
        'responseTime': responseTime,
        'rateLimitRemaining': 4500,
        'httpStatus': 200,
      },
    );
  }
  
  /// Check local service health
  Future<IntegrationHealth> _checkLocalServiceHealth(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    // Simulate local service check
    await Future.delayed(Duration(milliseconds: 50));
    
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;
    
    return IntegrationHealth(
      status: IntegrationHealthStatus.healthy,
      lastChecked: DateTime.now(),
      message: 'Local service running',
      details: {
        'responseTime': responseTime,
        'processId': 12345,
        'memoryUsage': '120MB',
      },
    );
  }
  
  /// Generic health check
  Future<IntegrationHealth> _checkGenericHealth(
    IntegrationDefinition integration,
    MCPServerConfig config,
    DateTime startTime,
  ) async {
    // Simulate generic check
    await Future.delayed(Duration(milliseconds: 150));
    
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;
    
    return IntegrationHealth(
      status: IntegrationHealthStatus.healthy,
      lastChecked: DateTime.now(),
      message: 'Integration operational',
      details: {
        'responseTime': responseTime,
      },
    );
  }
  
  /// Update health cache and notify listeners
  IntegrationHealth _updateHealth(String integrationId, IntegrationHealth health) {
    final previousHealth = _healthCache[integrationId];
    _healthCache[integrationId] = health;
    
    // Notify if health status changed
    if (previousHealth?.status != health.status) {
      _healthUpdatesController.add(IntegrationHealthUpdate(
        integrationId: integrationId,
        previousStatus: previousHealth?.status,
        currentStatus: health.status,
        health: health,
        timestamp: DateTime.now(),
      ));
    }
    
    // Adjust check interval based on health status
    if (_healthCheckTimers.containsKey(integrationId)) {
      final newInterval = _getCheckInterval(integrationId);
      _healthCheckTimers[integrationId]?.cancel();
      _healthCheckTimers[integrationId] = Timer.periodic(
        Duration(seconds: newInterval),
        (_) => _performHealthCheck(integrationId),
      );
    }
    
    return health;
  }
  
  /// Get appropriate check interval based on health status
  int _getCheckInterval(String integrationId) {
    final health = _healthCache[integrationId];
    if (health == null) return _defaultCheckInterval;
    
    switch (health.status) {
      case IntegrationHealthStatus.error:
        return _criticalCheckInterval;
      case IntegrationHealthStatus.warning:
        return _defaultCheckInterval;
      case IntegrationHealthStatus.healthy:
        return _healthyCheckInterval;
      case IntegrationHealthStatus.unknown:
        return _defaultCheckInterval;
    }
  }
  
  /// Dispose of resources
  void dispose() {
    stopMonitoring();
    _healthUpdatesController.close();
  }
}

/// Health update event
class IntegrationHealthUpdate {
  final String integrationId;
  final IntegrationHealthStatus? previousStatus;
  final IntegrationHealthStatus currentStatus;
  final IntegrationHealth health;
  final DateTime timestamp;
  
  const IntegrationHealthUpdate({
    required this.integrationId,
    this.previousStatus,
    required this.currentStatus,
    required this.health,
    required this.timestamp,
  });
}

/// Health statistics
class HealthStatistics {
  final int totalMonitored;
  final int healthy;
  final int warning;
  final int error;
  final int unknown;
  final DateTime lastUpdated;
  
  const HealthStatistics({
    required this.totalMonitored,
    required this.healthy,
    required this.warning,
    required this.error,
    required this.unknown,
    required this.lastUpdated,
  });
  
  double get healthPercentage {
    if (totalMonitored == 0) return 0;
    return (healthy / totalMonitored) * 100;
  }
  
  String get summaryText {
    if (error > 0) {
      return '$error integration${error > 1 ? 's' : ''} need attention';
    } else if (warning > 0) {
      return '$warning integration${warning > 1 ? 's' : ''} have warnings';
    } else if (healthy == totalMonitored && totalMonitored > 0) {
      return 'All integrations healthy';
    } else {
      return 'No active integrations';
    }
  }
}

/// Health history entry
class HealthHistoryEntry {
  final DateTime timestamp;
  final IntegrationHealthStatus status;
  final int responseTime;
  
  const HealthHistoryEntry({
    required this.timestamp,
    required this.status,
    required this.responseTime,
  });
}

// Providers
final integrationHealthServiceProvider = Provider<IntegrationHealthService>((ref) {
  final mcpService = ref.watch(mcpSettingsServiceProvider);
  final integrationService = ref.watch(integrationServiceProvider);
  final healthService = IntegrationHealthService(mcpService, integrationService);
  
  // Start monitoring on creation
  healthService.startMonitoring();
  
  // Stop monitoring on disposal
  ref.onDispose(() {
    healthService.dispose();
  });
  
  return healthService;
});

// Stream provider for health updates
final integrationHealthUpdatesProvider = StreamProvider<IntegrationHealthUpdate>((ref) {
  final healthService = ref.watch(integrationHealthServiceProvider);
  return healthService.healthUpdates;
});

// Provider for health statistics
final healthStatisticsProvider = Provider<HealthStatistics>((ref) {
  final healthService = ref.watch(integrationHealthServiceProvider);
  
  // Rebuild when health updates occur
  ref.watch(integrationHealthUpdatesProvider);
  
  return healthService.getStatistics();
});