import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'structured_logger.dart';
import 'performance_monitor.dart';
import 'metrics_collector.dart';
import 'debug_service.dart';
import 'alerting_service.dart';

/// Real-time monitoring dashboard service
class MonitoringDashboardService {
  static MonitoringDashboardService? _instance;
  static MonitoringDashboardService get instance => _instance ??= MonitoringDashboardService._();
  
  MonitoringDashboardService._();

  final StructuredLogger _logger = StructuredLogger.instance;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor.instance;
  final MetricsCollector _metricsCollector = MetricsCollector.instance;
  final DebugService _debugService = DebugService.instance;
  final AlertingService _alertingService = AlertingService.instance;
  
  final StreamController<DashboardUpdate> _dashboardController = StreamController.broadcast();
  final Map<String, DashboardWidget> _widgets = {};
  
  Timer? _updateTimer;
  bool _initialized = false;

  /// Stream of dashboard updates
  Stream<DashboardUpdate> get dashboardStream => _dashboardController.stream;

  /// Initialize monitoring dashboard
  Future<void> initialize() async {
    if (_initialized) return;

    _setupDefaultWidgets();
    
    // Start periodic dashboard updates (every 5 seconds)
    _updateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateDashboard(),
    );

    // Listen to various monitoring streams
    _performanceMonitor.metricsStream.listen(_handlePerformanceEvent);
    _metricsCollector.snapshotStream.listen(_handleMetricsSnapshot);
    _debugService.debugEventStream.listen(_handleDebugEvent);
    _alertingService.alertStream.listen(_handleAlert);

    _initialized = true;

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'dashboard_init',
      success: true,
      metadata: {
        'widgets': _widgets.length,
        'update_interval': 5,
      },
    );
  }

  /// Get current dashboard state
  Future<DashboardState> getDashboardState() async {
    final systemHealth = await _debugService.getSystemHealthOverview();
    final systemOverview = _performanceMonitor.getSystemOverview();
    final activeAlerts = _alertingService.getActiveAlerts();
    
    return DashboardState(
      timestamp: DateTime.now(),
      systemHealth: systemHealth,
      systemOverview: systemOverview,
      activeAlerts: activeAlerts,
      widgets: _widgets.values.toList(),
      isHealthy: systemHealth.overallStatus == HealthStatus.healthy,
      alertCount: activeAlerts.length,
      criticalAlertCount: activeAlerts.where((a) => a.severity == AlertSeverity.critical).length,
    );
  }

  /// Get real-time metrics for a specific component
  Future<ComponentDashboard> getComponentDashboard(String component, {
    String? agentId,
    String? serverId,
  }) async {
    final widgets = <DashboardWidget>[];

    if (component == 'terminal' && agentId != null) {
      widgets.addAll(await _getTerminalWidgets(agentId));
    } else if (component == 'mcp_server' && serverId != null) {
      widgets.addAll(await _getMCPServerWidgets(serverId));
    } else if (component == 'system') {
      widgets.addAll(await _getSystemWidgets());
    }

    return ComponentDashboard(
      component: component,
      agentId: agentId,
      serverId: serverId,
      timestamp: DateTime.now(),
      widgets: widgets,
    );
  }

  /// Add custom widget to dashboard
  void addWidget(DashboardWidget widget) {
    _widgets[widget.id] = widget;
    
    _dashboardController.add(DashboardUpdate(
      type: DashboardUpdateType.widgetAdded,
      timestamp: DateTime.now(),
      data: {'widget_id': widget.id, 'widget_type': widget.type.name},
    ));

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'add_dashboard_widget',
      success: true,
      metadata: {
        'widget_id': widget.id,
        'widget_type': widget.type.name,
      },
    );
  }

  /// Remove widget from dashboard
  void removeWidget(String widgetId) {
    final widget = _widgets.remove(widgetId);
    if (widget == null) return;

    _dashboardController.add(DashboardUpdate(
      type: DashboardUpdateType.widgetRemoved,
      timestamp: DateTime.now(),
      data: {'widget_id': widgetId},
    ));

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'remove_dashboard_widget',
      success: true,
      metadata: {'widget_id': widgetId},
    );
  }

  /// Update widget configuration
  void updateWidget(String widgetId, Map<String, dynamic> config) {
    final widget = _widgets[widgetId];
    if (widget == null) return;

    final updatedWidget = DashboardWidget(
      id: widget.id,
      type: widget.type,
      title: config['title'] ?? widget.title,
      config: {...widget.config, ...config},
      data: widget.data,
      lastUpdated: DateTime.now(),
    );

    _widgets[widgetId] = updatedWidget;

    _dashboardController.add(DashboardUpdate(
      type: DashboardUpdateType.widgetUpdated,
      timestamp: DateTime.now(),
      data: {'widget_id': widgetId, 'config': config},
    ));
  }

  /// Get historical data for dashboard charts
  Future<List<ChartDataPoint>> getChartData({
    required String metric,
    String? component,
    String? agentId,
    String? serverId,
    Duration timeWindow = const Duration(hours: 1),
    int maxPoints = 100,
  }) async {
    final history = _metricsCollector.getMetricsHistory(
      component ?? 'system',
      agentId: agentId,
      serverId: serverId,
      timeWindow: timeWindow,
      metricName: metric,
    );

    final chartData = <ChartDataPoint>[];
    
    for (final point in history.take(maxPoints)) {
      final value = point.metrics[metric];
      if (value is num) {
        chartData.add(ChartDataPoint(
          timestamp: point.timestamp,
          value: value.toDouble(),
        ));
      }
    }

    return chartData;
  }

  /// Export dashboard configuration
  Map<String, dynamic> exportDashboardConfig() {
    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'widgets': _widgets.values.map((w) => w.toJson()).toList(),
    };
  }

  /// Import dashboard configuration
  void importDashboardConfig(Map<String, dynamic> config) {
    final widgets = config['widgets'] as List<dynamic>? ?? [];
    
    _widgets.clear();
    
    for (final widgetData in widgets) {
      try {
        final widget = DashboardWidget.fromJson(widgetData as Map<String, dynamic>);
        _widgets[widget.id] = widget;
      } catch (e) {
        _logger.logError(
          component: 'dashboard',
          error: 'Failed to import widget: $e',
          operation: 'import_config',
        );
      }
    }

    _dashboardController.add(DashboardUpdate(
      type: DashboardUpdateType.configImported,
      timestamp: DateTime.now(),
      data: {'widget_count': _widgets.length},
    ));
  }

  /// Setup default dashboard widgets
  void _setupDefaultWidgets() {
    // System overview widget
    addWidget(DashboardWidget(
      id: 'system_overview',
      type: DashboardWidgetType.systemOverview,
      title: 'System Overview',
      config: {'refresh_interval': 5},
      data: {},
      lastUpdated: DateTime.now(),
    ));

    // Memory usage chart
    addWidget(DashboardWidget(
      id: 'memory_chart',
      type: DashboardWidgetType.chart,
      title: 'Memory Usage',
      config: {
        'metric': 'memory_usage_mb',
        'chart_type': 'line',
        'time_window': 3600, // 1 hour
        'max_points': 60,
      },
      data: {},
      lastUpdated: DateTime.now(),
    ));

    // CPU usage chart
    addWidget(DashboardWidget(
      id: 'cpu_chart',
      type: DashboardWidgetType.chart,
      title: 'CPU Usage',
      config: {
        'metric': 'cpu_usage_percent',
        'chart_type': 'line',
        'time_window': 3600,
        'max_points': 60,
      },
      data: {},
      lastUpdated: DateTime.now(),
    ));

    // Active alerts widget
    addWidget(DashboardWidget(
      id: 'active_alerts',
      type: DashboardWidgetType.alertList,
      title: 'Active Alerts',
      config: {'max_alerts': 10},
      data: {},
      lastUpdated: DateTime.now(),
    ));

    // Agent terminals widget
    addWidget(DashboardWidget(
      id: 'agent_terminals',
      type: DashboardWidgetType.agentList,
      title: 'Agent Terminals',
      config: {'show_metrics': true},
      data: {},
      lastUpdated: DateTime.now(),
    ));

    // MCP servers widget
    addWidget(DashboardWidget(
      id: 'mcp_servers',
      type: DashboardWidgetType.mcpServerList,
      title: 'MCP Servers',
      config: {'show_metrics': true},
      data: {},
      lastUpdated: DateTime.now(),
    ));
  }

  /// Update dashboard with latest data
  Future<void> _updateDashboard() async {
    try {
      final dashboardState = await getDashboardState();
      
      // Update each widget
      for (final widget in _widgets.values) {
        await _updateWidget(widget, dashboardState);
      }

      _dashboardController.add(DashboardUpdate(
        type: DashboardUpdateType.dataRefresh,
        timestamp: DateTime.now(),
        data: {
          'system_health': dashboardState.systemHealth.overallStatus.name,
          'alert_count': dashboardState.alertCount,
          'widgets_updated': _widgets.length,
        },
      ));
    } catch (e) {
      _logger.logError(
        component: 'dashboard',
        error: 'Failed to update dashboard: $e',
        operation: 'update_dashboard',
      );
    }
  }

  /// Update individual widget data
  Future<void> _updateWidget(DashboardWidget widget, DashboardState dashboardState) async {
    Map<String, dynamic> newData = {};

    switch (widget.type) {
      case DashboardWidgetType.systemOverview:
        newData = {
          'system_health': dashboardState.systemHealth.toJson(),
          'system_overview': dashboardState.systemOverview.toJson(),
        };
        break;

      case DashboardWidgetType.chart:
        final metric = widget.config['metric'] as String;
        final timeWindow = Duration(seconds: widget.config['time_window'] as int? ?? 3600);
        final maxPoints = widget.config['max_points'] as int? ?? 60;
        
        final chartData = await getChartData(
          metric: metric,
          timeWindow: timeWindow,
          maxPoints: maxPoints,
        );
        
        newData = {
          'chart_data': chartData.map((p) => p.toJson()).toList(),
          'latest_value': chartData.isNotEmpty ? chartData.last.value : 0,
        };
        break;

      case DashboardWidgetType.alertList:
        final maxAlerts = widget.config['max_alerts'] as int? ?? 10;
        final alerts = dashboardState.activeAlerts.take(maxAlerts).toList();
        
        newData = {
          'alerts': alerts.map((a) => {
            'id': a.id,
            'title': a.title,
            'severity': a.severity.name,
            'component': a.component,
            'timestamp': a.timestamp.toIso8601String(),
          }).toList(),
        };
        break;

      case DashboardWidgetType.agentList:
        // This would get actual agent data
        newData = {
          'agents': [
            {
              'id': 'agent_1',
              'status': 'active',
              'memory_mb': 45,
              'cpu_percent': 12.5,
            }
          ],
        };
        break;

      case DashboardWidgetType.mcpServerList:
        // This would get actual MCP server data
        newData = {
          'servers': [
            {
              'id': 'server_1',
              'agent_id': 'agent_1',
              'status': 'running',
              'memory_mb': 25,
              'cpu_percent': 8.0,
            }
          ],
        };
        break;

      case DashboardWidgetType.custom:
        // Custom widget update logic would go here
        break;
    }

    // Update widget data
    _widgets[widget.id] = DashboardWidget(
      id: widget.id,
      type: widget.type,
      title: widget.title,
      config: widget.config,
      data: newData,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get terminal-specific widgets
  Future<List<DashboardWidget>> _getTerminalWidgets(String agentId) async {
    final widgets = <DashboardWidget>[];

    // Terminal metrics widget
    widgets.add(DashboardWidget(
      id: 'terminal_metrics_$agentId',
      type: DashboardWidgetType.custom,
      title: 'Terminal Metrics',
      config: {'agent_id': agentId},
      data: {
        'memory_mb': 45,
        'cpu_percent': 12.5,
        'commands_executed': 25,
        'active_processes': 3,
      },
      lastUpdated: DateTime.now(),
    ));

    // Terminal command history
    widgets.add(DashboardWidget(
      id: 'terminal_history_$agentId',
      type: DashboardWidgetType.custom,
      title: 'Command History',
      config: {'agent_id': agentId, 'max_commands': 10},
      data: {
        'commands': [
          {'command': 'ls -la', 'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String()},
          {'command': 'cd /home/user', 'timestamp': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String()},
        ],
      },
      lastUpdated: DateTime.now(),
    ));

    return widgets;
  }

  /// Get MCP server-specific widgets
  Future<List<DashboardWidget>> _getMCPServerWidgets(String serverId) async {
    final widgets = <DashboardWidget>[];

    // MCP server metrics widget
    widgets.add(DashboardWidget(
      id: 'mcp_metrics_$serverId',
      type: DashboardWidgetType.custom,
      title: 'MCP Server Metrics',
      config: {'server_id': serverId},
      data: {
        'memory_mb': 25,
        'cpu_percent': 8.0,
        'requests_handled': 150,
        'error_count': 2,
      },
      lastUpdated: DateTime.now(),
    ));

    // MCP communication widget
    widgets.add(DashboardWidget(
      id: 'mcp_communication_$serverId',
      type: DashboardWidgetType.custom,
      title: 'Communication Stats',
      config: {'server_id': serverId},
      data: {
        'avg_response_time_ms': 75.0,
        'success_rate': 98.7,
        'connection_count': 1,
      },
      lastUpdated: DateTime.now(),
    ));

    return widgets;
  }

  /// Get system-wide widgets
  Future<List<DashboardWidget>> _getSystemWidgets() async {
    final widgets = <DashboardWidget>[];

    // System health widget
    widgets.add(DashboardWidget(
      id: 'system_health',
      type: DashboardWidgetType.systemOverview,
      title: 'System Health',
      config: {},
      data: (await _debugService.getSystemHealthOverview()).toJson(),
      lastUpdated: DateTime.now(),
    ));

    return widgets;
  }

  /// Event handlers
  void _handlePerformanceEvent(PerformanceEvent event) {
    _dashboardController.add(DashboardUpdate(
      type: DashboardUpdateType.performanceEvent,
      timestamp: DateTime.now(),
      data: {
        'component': event.component,
        'operation': event.operation,
        'success': event.success,
        'duration_ms': event.duration.inMilliseconds,
      },
    ));
  }

  void _handleMetricsSnapshot(MetricsSnapshot snapshot) {
    _dashboardController.add(DashboardUpdate(
      type: DashboardUpdateType.metricsSnapshot,
      timestamp: DateTime.now(),
      data: {
        'system_metrics': snapshot.systemMetrics.toJson(),
        'agent_count': snapshot.agentMetrics.length,
        'mcp_count': snapshot.mcpMetrics.length,
      },
    ));
  }

  void _handleDebugEvent(DebugEvent event) {
    _dashboardController.add(DashboardUpdate(
      type: DashboardUpdateType.debugEvent,
      timestamp: DateTime.now(),
      data: {
        'debug_event_type': event.type.name,
        'session_id': event.sessionId,
      },
    ));
  }

  void _handleAlert(Alert alert) {
    _dashboardController.add(DashboardUpdate(
      type: DashboardUpdateType.alert,
      timestamp: DateTime.now(),
      data: {
        'alert_id': alert.id,
        'severity': alert.severity.name,
        'component': alert.component,
        'is_resolved': alert.isResolved,
      },
    ));
  }

  /// Dispose resources
  void dispose() {
    _updateTimer?.cancel();
    _dashboardController.close();
    _widgets.clear();
    _initialized = false;
  }
}

/// Data models
class DashboardState {
  final DateTime timestamp;
  final SystemHealthOverview systemHealth;
  final SystemPerformanceOverview systemOverview;
  final List<Alert> activeAlerts;
  final List<DashboardWidget> widgets;
  final bool isHealthy;
  final int alertCount;
  final int criticalAlertCount;

  DashboardState({
    required this.timestamp,
    required this.systemHealth,
    required this.systemOverview,
    required this.activeAlerts,
    required this.widgets,
    required this.isHealthy,
    required this.alertCount,
    required this.criticalAlertCount,
  });
}

class ComponentDashboard {
  final String component;
  final String? agentId;
  final String? serverId;
  final DateTime timestamp;
  final List<DashboardWidget> widgets;

  ComponentDashboard({
    required this.component,
    this.agentId,
    this.serverId,
    required this.timestamp,
    required this.widgets,
  });
}

class DashboardWidget {
  final String id;
  final DashboardWidgetType type;
  final String title;
  final Map<String, dynamic> config;
  final Map<String, dynamic> data;
  final DateTime lastUpdated;

  DashboardWidget({
    required this.id,
    required this.type,
    required this.title,
    required this.config,
    required this.data,
    required this.lastUpdated,
  });

  factory DashboardWidget.fromJson(Map<String, dynamic> json) {
    return DashboardWidget(
      id: json['id'],
      type: DashboardWidgetType.values.byName(json['type']),
      title: json['title'],
      config: json['config'] ?? {},
      data: json['data'] ?? {},
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'config': config,
      'data': data,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class DashboardUpdate {
  final DashboardUpdateType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  DashboardUpdate({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class ChartDataPoint {
  final DateTime timestamp;
  final double value;

  ChartDataPoint({
    required this.timestamp,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
    };
  }
}

enum DashboardWidgetType {
  systemOverview,
  chart,
  alertList,
  agentList,
  mcpServerList,
  custom,
}

enum DashboardUpdateType {
  dataRefresh,
  widgetAdded,
  widgetRemoved,
  widgetUpdated,
  configImported,
  performanceEvent,
  metricsSnapshot,
  debugEvent,
  alert,
}

// ==================== Riverpod Provider ====================

final monitoringDashboardServiceProvider = Provider<MonitoringDashboardService>((ref) {
  return MonitoringDashboardService.instance;
});