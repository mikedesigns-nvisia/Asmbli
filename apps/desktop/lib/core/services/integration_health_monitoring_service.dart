import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mcp_settings_service.dart';
import 'integration_service.dart';

/// Service for monitoring the health and status of all integrations
class IntegrationHealthMonitoringService {
  final MCPSettingsService _mcpSettingsService;
  final IntegrationService _integrationService;

  // Health monitoring state
  final Map<String, IntegrationHealth> _healthCache = {};
  final StreamController<Map<String, IntegrationHealth>> _healthUpdatesController = 
      StreamController<Map<String, IntegrationHealth>>.broadcast();
  Timer? _monitoringTimer;

  // Configuration
  static const Duration _monitoringInterval = Duration(minutes: 2);
  static const Duration _healthCacheTimeout = Duration(minutes: 5);

  IntegrationHealthMonitoringService(this._mcpSettingsService, this._integrationService) {
    _startMonitoring();
  }

  /// Stream of health updates for all integrations
  Stream<Map<String, IntegrationHealth>> get healthUpdates => 
      _healthUpdatesController.stream;

  /// Get current health status for all integrations
  Map<String, IntegrationHealth> get currentHealth => Map.from(_healthCache);

  /// Get health status for specific integration
  IntegrationHealth? getIntegrationHealth(String integrationId) {
    return _healthCache[integrationId];
  }

  /// Start continuous health monitoring
  void _startMonitoring() {
    print('IntegrationHealthMonitoringService: Starting health monitoring');
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) => _performHealthCheck());
    
    // Perform initial health check
    _performHealthCheck();
  }

  /// Stop health monitoring
  void stopMonitoring() {
    print('IntegrationHealthMonitoringService: Stopping health monitoring');
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Perform health check on all active integrations
  Future<void> _performHealthCheck() async {
    try {
      print('IntegrationHealthMonitoringService: Performing health check');
      
      final allMCPServers = _mcpSettingsService.allMCPServers;
      final healthResults = <String, IntegrationHealth>{};
      
      // Check each MCP server
      for (final entry in allMCPServers.entries) {
        final integrationId = entry.key;
        final mcpConfig = entry.value;
        
        if (mcpConfig.enabled) {
          final health = await _checkIntegrationHealth(integrationId, mcpConfig);
          healthResults[integrationId] = health;
        } else {
          healthResults[integrationId] = IntegrationHealth(
            integrationId: integrationId,
            status: IntegrationHealthStatus.disabled,
            lastChecked: DateTime.now(),
            message: 'Integration is disabled',
          );
        }
      }
      
      // Update cache and notify listeners
      _healthCache.clear();
      _healthCache.addAll(healthResults);
      
      _healthUpdatesController.add(Map.from(_healthCache));
      print('IntegrationHealthMonitoringService: Health check completed for ${healthResults.length} integrations');
      
    } catch (e) {
      print('IntegrationHealthMonitoringService: Error during health check: $e');
    }
  }

  /// Check health of specific integration
  Future<IntegrationHealth> _checkIntegrationHealth(String integrationId, MCPServerConfig config) async {
    final startTime = DateTime.now();
    
    try {
      // Test MCP server connection
      final mcpStatus = await _mcpSettingsService.testMCPServerConnection(integrationId);
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      
      if (mcpStatus.isConnected) {
        return IntegrationHealth(
          integrationId: integrationId,
          status: IntegrationHealthStatus.healthy,
          lastChecked: DateTime.now(),
          latencyMs: latency,
          message: 'Integration is working normally',
          details: _buildHealthDetails(config, mcpStatus),
        );
      } else {
        return IntegrationHealth(
          integrationId: integrationId,
          status: IntegrationHealthStatus.unhealthy,
          lastChecked: DateTime.now(),
          latencyMs: latency,
          message: mcpStatus.errorMessage ?? 'Connection failed',
          errorDetails: mcpStatus.errorMessage,
        );
      }
    } catch (e) {
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      
      return IntegrationHealth(
        integrationId: integrationId,
        status: IntegrationHealthStatus.error,
        lastChecked: DateTime.now(),
        latencyMs: latency,
        message: 'Health check failed',
        errorDetails: e.toString(),
      );
    }
  }

  /// Build detailed health information
  Map<String, dynamic> _buildHealthDetails(MCPServerConfig config, MCPServerStatus status) {
    return {
      'serverName': config.name,
      'command': config.command,
      'args': config.args,
      'environmentVariables': config.env?.length ?? 0,
      'createdAt': config.createdAt.toIso8601String(),
      'lastUpdated': config.lastUpdated?.toIso8601String(),
      'connectionStatus': status.isConnected ? 'Connected' : 'Disconnected',
      'serverLatency': status.latencyMs,
    };
  }

  /// Force immediate health check for specific integration
  Future<IntegrationHealth> forceHealthCheck(String integrationId) async {
    print('IntegrationHealthMonitoringService: Forcing health check for $integrationId');
    
    final mcpConfig = _mcpSettingsService.getMCPServer(integrationId);
    if (mcpConfig == null) {
      return IntegrationHealth(
        integrationId: integrationId,
        status: IntegrationHealthStatus.notFound,
        lastChecked: DateTime.now(),
        message: 'Integration not configured',
      );
    }
    
    final health = await _checkIntegrationHealth(integrationId, mcpConfig);
    _healthCache[integrationId] = health;
    _healthUpdatesController.add(Map.from(_healthCache));
    
    return health;
  }

  /// Get aggregated health statistics
  HealthStatistics getHealthStatistics() {
    final stats = HealthStatistics();
    
    for (final health in _healthCache.values) {
      switch (health.status) {
        case IntegrationHealthStatus.healthy:
          stats.healthy++;
          break;
        case IntegrationHealthStatus.unhealthy:
          stats.unhealthy++;
          break;
        case IntegrationHealthStatus.error:
          stats.error++;
          break;
        case IntegrationHealthStatus.disabled:
          stats.disabled++;
          break;
        case IntegrationHealthStatus.notFound:
          stats.notConfigured++;
          break;
      }
      
      stats.total++;
      
      if (health.latencyMs != null) {
        stats.totalLatency += health.latencyMs!;
        stats.latencyCount++;
      }
    }
    
    stats.averageLatency = stats.latencyCount > 0 
        ? (stats.totalLatency / stats.latencyCount).round()
        : 0;
    
    return stats;
  }

  /// Get integrations that need attention
  List<IntegrationHealth> getIntegrationsNeedingAttention() {
    return _healthCache.values
        .where((health) => 
            health.status == IntegrationHealthStatus.unhealthy ||
            health.status == IntegrationHealthStatus.error)
        .toList();
  }

  /// Get recently failed integrations
  List<IntegrationHealth> getRecentlyFailedIntegrations({Duration? within}) {
    final cutoff = DateTime.now().subtract(within ?? const Duration(hours: 1));
    
    return _healthCache.values
        .where((health) =>
            (health.status == IntegrationHealthStatus.unhealthy ||
             health.status == IntegrationHealthStatus.error) &&
            health.lastChecked.isAfter(cutoff))
        .toList();
  }

  /// Clean up old health data
  void _cleanupOldHealthData() {
    final cutoff = DateTime.now().subtract(_healthCacheTimeout);
    final keysToRemove = <String>[];
    
    for (final entry in _healthCache.entries) {
      if (entry.value.lastChecked.isBefore(cutoff)) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _healthCache.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      print('IntegrationHealthMonitoringService: Cleaned up ${keysToRemove.length} old health records');
    }
  }

  /// Dispose of resources
  void dispose() {
    stopMonitoring();
    _healthUpdatesController.close();
  }
}

/// Health status of an integration
class IntegrationHealth {
  final String integrationId;
  final IntegrationHealthStatus status;
  final DateTime lastChecked;
  final int? latencyMs;
  final String message;
  final String? errorDetails;
  final Map<String, dynamic>? details;

  const IntegrationHealth({
    required this.integrationId,
    required this.status,
    required this.lastChecked,
    this.latencyMs,
    required this.message,
    this.errorDetails,
    this.details,
  });

  /// Check if health data is stale
  bool get isStale {
    final age = DateTime.now().difference(lastChecked);
    return age > const Duration(minutes: 10);
  }

  /// Get user-friendly status text
  String get statusText {
    switch (status) {
      case IntegrationHealthStatus.healthy:
        return 'Healthy';
      case IntegrationHealthStatus.unhealthy:
        return 'Unhealthy';
      case IntegrationHealthStatus.error:
        return 'Error';
      case IntegrationHealthStatus.disabled:
        return 'Disabled';
      case IntegrationHealthStatus.notFound:
        return 'Not Configured';
    }
  }

  /// Get status color for UI
  String get statusColor {
    switch (status) {
      case IntegrationHealthStatus.healthy:
        return '#4CAF50'; // Green
      case IntegrationHealthStatus.unhealthy:
        return '#FF9800'; // Orange
      case IntegrationHealthStatus.error:
        return '#F44336'; // Red
      case IntegrationHealthStatus.disabled:
        return '#9E9E9E'; // Grey
      case IntegrationHealthStatus.notFound:
        return '#607D8B'; // Blue Grey
    }
  }
}

/// Health status enumeration
enum IntegrationHealthStatus {
  healthy,
  unhealthy,
  error,
  disabled,
  notFound,
}

/// Aggregated health statistics
class HealthStatistics {
  int total = 0;
  int healthy = 0;
  int unhealthy = 0;
  int error = 0;
  int disabled = 0;
  int notConfigured = 0;
  
  int totalLatency = 0;
  int latencyCount = 0;
  int averageLatency = 0;

  /// Check if overall health is good
  bool get isHealthy {
    if (total == 0) return true;
    return (unhealthy + error) == 0;
  }
  
  /// Get health percentage
  double get healthPercentage {
    if (total == 0) return 100.0;
    return (healthy / total) * 100.0;
  }

  /// Get active integrations count (healthy + unhealthy + error)
  int get activeCount {
    return healthy + unhealthy + error;
  }


  /// Get overall status text
  String get overallStatus {
    if (total == 0) return 'No integrations configured';
    if (error > 0) return 'Critical issues detected';
    if (unhealthy > 0) return 'Some issues detected';
    if (healthy == 0) return 'No active integrations';
    return 'All integrations healthy';
  }
}

/// Provider for integration health monitoring service
final integrationHealthMonitoringServiceProvider = Provider<IntegrationHealthMonitoringService>((ref) {
  final mcpSettingsService = ref.read(mcpSettingsServiceProvider);
  final integrationService = ref.read(integrationServiceProvider);
  
  final service = IntegrationHealthMonitoringService(mcpSettingsService, integrationService);
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for health statistics
final healthStatisticsProvider = StreamProvider<HealthStatistics>((ref) {
  final healthService = ref.read(integrationHealthMonitoringServiceProvider);
  
  return healthService.healthUpdates.map((healthMap) {
    return healthService.getHealthStatistics();
  });
});

/// Provider for integrations needing attention
final integrationsNeedingAttentionProvider = StreamProvider<List<IntegrationHealth>>((ref) {
  final healthService = ref.read(integrationHealthMonitoringServiceProvider);
  
  return healthService.healthUpdates.map((healthMap) {
    return healthService.getIntegrationsNeedingAttention();
  });
});