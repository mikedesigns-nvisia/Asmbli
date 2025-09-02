import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mcp_bridge_service.dart';
import 'mcp_settings_service.dart';

/// Health status of an MCP server
enum MCPServerHealthStatus {
  healthy,
  degraded,
  unhealthy,
  offline,
  reconnecting,
  unknown
}

/// Health metrics for an MCP server
class MCPServerHealth {
  final String serverId;
  final MCPServerHealthStatus status;
  final int responseTimeMs;
  final DateTime lastCheck;
  final DateTime? lastHealthy;
  final int consecutiveFailures;
  final String? errorMessage;
  final Map<String, dynamic> metrics;

  const MCPServerHealth({
    required this.serverId,
    required this.status,
    required this.responseTimeMs,
    required this.lastCheck,
    this.lastHealthy,
    this.consecutiveFailures = 0,
    this.errorMessage,
    this.metrics = const {},
  });

  MCPServerHealth copyWith({
    MCPServerHealthStatus? status,
    int? responseTimeMs,
    DateTime? lastCheck,
    DateTime? lastHealthy,
    int? consecutiveFailures,
    String? errorMessage,
    Map<String, dynamic>? metrics,
  }) {
    return MCPServerHealth(
      serverId: serverId,
      status: status ?? this.status,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      lastCheck: lastCheck ?? this.lastCheck,
      lastHealthy: lastHealthy ?? this.lastHealthy,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      errorMessage: errorMessage ?? this.errorMessage,
      metrics: metrics ?? this.metrics,
    );
  }

  bool get isHealthy => status == MCPServerHealthStatus.healthy;
  bool get isConnected => status != MCPServerHealthStatus.offline;
  bool get needsReconnection => status == MCPServerHealthStatus.offline || 
                                status == MCPServerHealthStatus.unhealthy;
}

/// Configuration for health monitoring
class HealthMonitorConfig {
  final Duration checkInterval;
  final Duration healthyThreshold;
  final Duration unhealthyThreshold;
  final int maxConsecutiveFailures;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;
  final double exponentialBackoffFactor;

  const HealthMonitorConfig({
    this.checkInterval = const Duration(seconds: 30),
    this.healthyThreshold = const Duration(milliseconds: 1000),
    this.unhealthyThreshold = const Duration(milliseconds: 5000),
    this.maxConsecutiveFailures = 3,
    this.reconnectDelay = const Duration(seconds: 5),
    this.maxReconnectAttempts = 5,
    this.exponentialBackoffFactor = 2.0,
  });
}

/// MCP server health monitoring service
class MCPHealthMonitor {
  final MCPBridgeService _bridgeService;
  final MCPSettingsService _settingsService;
  final HealthMonitorConfig _config;

  // State tracking
  final Map<String, MCPServerHealth> _serverHealth = {};
  final Map<String, Timer> _healthCheckTimers = {};
  final Map<String, Timer> _reconnectTimers = {};
  final Map<String, int> _reconnectAttempts = {};

  // Event streams
  final StreamController<Map<String, MCPServerHealth>> _healthUpdatesController =
      StreamController<Map<String, MCPServerHealth>>.broadcast();
  
  final StreamController<MCPServerHealthEvent> _healthEventsController =
      StreamController<MCPServerHealthEvent>.broadcast();

  bool _isMonitoring = false;

  MCPHealthMonitor(
    this._bridgeService,
    this._settingsService, {
    HealthMonitorConfig? config,
  }) : _config = config ?? const HealthMonitorConfig();

  /// Stream of health status updates for all servers
  Stream<Map<String, MCPServerHealth>> get healthUpdates => 
      _healthUpdatesController.stream;

  /// Stream of individual health events
  Stream<MCPServerHealthEvent> get healthEvents => 
      _healthEventsController.stream;

  /// Get current health status for all servers
  Map<String, MCPServerHealth> get currentHealth => 
      Map.unmodifiable(_serverHealth);

  /// Get health status for a specific server
  MCPServerHealth? getServerHealth(String serverId) => _serverHealth[serverId];

  /// Start health monitoring for all configured MCP servers
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    print('🔍 Starting MCP server health monitoring');

    // Get all configured servers
    final servers = _settingsService.getAllMCPServers();
    
    // Initialize health tracking for each server
    for (final server in servers) {
      await _initializeServerMonitoring(server.id);
    }

    // Listen for settings changes to add/remove monitoring
    _settingsService.settingsUpdates.listen(_onSettingsChanged);

    print('✓ MCP health monitoring started for ${servers.length} servers');
  }

  /// Stop health monitoring
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    print('🛑 Stopping MCP server health monitoring');

    // Cancel all timers
    for (final timer in _healthCheckTimers.values) {
      timer.cancel();
    }
    for (final timer in _reconnectTimers.values) {
      timer.cancel();
    }

    _healthCheckTimers.clear();
    _reconnectTimers.clear();
    _reconnectAttempts.clear();
    _serverHealth.clear();

    print('✓ MCP health monitoring stopped');
  }

  /// Initialize monitoring for a specific server
  Future<void> _initializeServerMonitoring(String serverId) async {
    // Create initial health entry
    _serverHealth[serverId] = MCPServerHealth(
      serverId: serverId,
      status: MCPServerHealthStatus.unknown,
      responseTimeMs: 0,
      lastCheck: DateTime.now(),
    );

    // Start periodic health checks
    _startHealthChecks(serverId);

    // Perform initial health check
    await _performHealthCheck(serverId);
  }

  /// Start periodic health checks for a server
  void _startHealthChecks(String serverId) {
    _healthCheckTimers[serverId]?.cancel();
    
    _healthCheckTimers[serverId] = Timer.periodic(
      _config.checkInterval,
      (timer) => _performHealthCheck(serverId),
    );
  }

  /// Perform a single health check for a server
  Future<void> _performHealthCheck(String serverId) async {
    final stopwatch = Stopwatch()..start();
    final checkTime = DateTime.now();

    try {
      // Attempt to ping the MCP server
      final isHealthy = await _pingServer(serverId);
      stopwatch.stop();
      
      final responseTime = stopwatch.elapsedMilliseconds;
      final currentHealth = _serverHealth[serverId]!;

      MCPServerHealthStatus newStatus;
      if (isHealthy) {
        if (responseTime <= _config.healthyThreshold.inMilliseconds) {
          newStatus = MCPServerHealthStatus.healthy;
        } else if (responseTime <= _config.unhealthyThreshold.inMilliseconds) {
          newStatus = MCPServerHealthStatus.degraded;
        } else {
          newStatus = MCPServerHealthStatus.unhealthy;
        }

        // Reset reconnection attempts on successful health check
        _reconnectAttempts[serverId] = 0;
        _reconnectTimers[serverId]?.cancel();
      } else {
        newStatus = MCPServerHealthStatus.offline;
      }

      // Update health status
      final updatedHealth = currentHealth.copyWith(
        status: newStatus,
        responseTimeMs: responseTime,
        lastCheck: checkTime,
        lastHealthy: isHealthy ? checkTime : currentHealth.lastHealthy,
        consecutiveFailures: isHealthy ? 0 : currentHealth.consecutiveFailures + 1,
        errorMessage: null,
        metrics: {
          'responseTime': responseTime,
          'availability': _calculateAvailability(serverId),
          'uptime': _calculateUptime(serverId),
        },
      );

      _updateServerHealth(serverId, updatedHealth);

      // Start reconnection if needed
      if (newStatus == MCPServerHealthStatus.offline) {
        await _attemptReconnection(serverId);
      }

    } catch (e) {
      stopwatch.stop();
      
      final currentHealth = _serverHealth[serverId]!;
      final updatedHealth = currentHealth.copyWith(
        status: MCPServerHealthStatus.offline,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        lastCheck: checkTime,
        consecutiveFailures: currentHealth.consecutiveFailures + 1,
        errorMessage: e.toString(),
      );

      _updateServerHealth(serverId, updatedHealth);
      
      // Start reconnection process
      await _attemptReconnection(serverId);
    }
  }

  /// Ping an MCP server to check if it's responsive
  Future<bool> _pingServer(String serverId) async {
    try {
      // Use the bridge service to test server connection
      final response = await _bridgeService.testConnection(serverId);
      return response.isConnected;
    } catch (e) {
      return false;
    }
  }

  /// Attempt to reconnect a server
  Future<void> _attemptReconnection(String serverId) async {
    if (_reconnectTimers.containsKey(serverId)) return; // Already reconnecting

    final attempts = _reconnectAttempts[serverId] ?? 0;
    if (attempts >= _config.maxReconnectAttempts) {
      print('❌ Max reconnection attempts reached for server: $serverId');
      return;
    }

    // Calculate exponential backoff delay
    final backoffDelay = Duration(
      milliseconds: (_config.reconnectDelay.inMilliseconds * 
                    pow(_config.exponentialBackoffFactor, attempts)).round(),
    );

    print('🔄 Attempting reconnection for server: $serverId (attempt ${attempts + 1})');
    
    // Update status to reconnecting
    final currentHealth = _serverHealth[serverId]!;
    _updateServerHealth(serverId, currentHealth.copyWith(
      status: MCPServerHealthStatus.reconnecting,
    ));

    _reconnectTimers[serverId] = Timer(backoffDelay, () async {
      _reconnectTimers.remove(serverId);
      _reconnectAttempts[serverId] = attempts + 1;

      try {
        // Attempt to reinitialize the server connection
        await _bridgeService.reinitializeServer(serverId);
        
        // Perform immediate health check
        await _performHealthCheck(serverId);
        
        print('✓ Reconnection successful for server: $serverId');
        
        // Emit reconnection success event
        _healthEventsController.add(MCPServerReconnectedEvent(serverId));
        
      } catch (e) {
        print('❌ Reconnection failed for server: $serverId - $e');
        
        // Emit reconnection failure event
        _healthEventsController.add(MCPServerReconnectionFailedEvent(serverId, e.toString()));
        
        // Schedule next reconnection attempt
        await _attemptReconnection(serverId);
      }
    });
  }

  /// Update server health and broadcast changes
  void _updateServerHealth(String serverId, MCPServerHealth newHealth) {
    final oldHealth = _serverHealth[serverId];
    _serverHealth[serverId] = newHealth;

    // Emit status change event if status changed
    if (oldHealth?.status != newHealth.status) {
      _healthEventsController.add(MCPServerStatusChangedEvent(
        serverId,
        oldHealth?.status ?? MCPServerHealthStatus.unknown,
        newHealth.status,
      ));
    }

    // Broadcast health updates
    _healthUpdatesController.add(Map.from(_serverHealth));
  }

  /// Handle settings changes (add/remove server monitoring)
  void _onSettingsChanged(Map<String, dynamic> changes) {
    // This would be called when servers are added/removed in settings
    // Implementation depends on the settings service change notification format
  }

  /// Calculate availability percentage for a server
  double _calculateAvailability(String serverId) {
    // Simplified calculation - in production you'd track more historical data
    final health = _serverHealth[serverId];
    if (health == null) return 0.0;
    
    return health.consecutiveFailures == 0 ? 100.0 : 
           max(0.0, 100.0 - (health.consecutiveFailures * 20.0));
  }

  /// Calculate uptime for a server
  Duration _calculateUptime(String serverId) {
    final health = _serverHealth[serverId];
    if (health?.lastHealthy == null) return Duration.zero;
    
    return DateTime.now().difference(health!.lastHealthy!);
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _healthUpdatesController.close();
    _healthEventsController.close();
  }
}

/// Base class for health monitoring events
abstract class MCPServerHealthEvent {
  final String serverId;
  final DateTime timestamp;

  MCPServerHealthEvent(this.serverId) : timestamp = DateTime.now();
}

/// Event when server status changes
class MCPServerStatusChangedEvent extends MCPServerHealthEvent {
  final MCPServerHealthStatus oldStatus;
  final MCPServerHealthStatus newStatus;

  MCPServerStatusChangedEvent(super.serverId, this.oldStatus, this.newStatus);
}

/// Event when server reconnection succeeds
class MCPServerReconnectedEvent extends MCPServerHealthEvent {
  MCPServerReconnectedEvent(super.serverId);
}

/// Event when server reconnection fails
class MCPServerReconnectionFailedEvent extends MCPServerHealthEvent {
  final String error;

  MCPServerReconnectionFailedEvent(super.serverId, this.error);
}

// ==================== Riverpod Providers ====================

/// Provider for the health monitor service
final mcpHealthMonitorProvider = Provider<MCPHealthMonitor>((ref) {
  final bridgeService = MCPBridgeService(ref.read(mcpSettingsServiceProvider));
  final settingsService = ref.read(mcpSettingsServiceProvider);
  
  final monitor = MCPHealthMonitor(bridgeService, settingsService);
  
  // Auto-start monitoring
  monitor.startMonitoring();
  
  // Dispose when no longer needed
  ref.onDispose(() => monitor.dispose());
  
  return monitor;
});

/// Provider for server health status streams
final mcpServerHealthProvider = StreamProvider<Map<String, MCPServerHealth>>((ref) {
  final monitor = ref.watch(mcpHealthMonitorProvider);
  return monitor.healthUpdates;
});

/// Provider for health events stream
final mcpHealthEventsProvider = StreamProvider<MCPServerHealthEvent>((ref) {
  final monitor = ref.watch(mcpHealthMonitorProvider);
  return monitor.healthEvents;
});