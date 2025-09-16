import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'structured_logger.dart';
import 'performance_monitor.dart';
import 'metrics_collector.dart';

/// Service for monitoring performance and generating alerts
class AlertingService {
  static AlertingService? _instance;
  static AlertingService get instance => _instance ??= AlertingService._();
  
  AlertingService._();

  final StructuredLogger _logger = StructuredLogger.instance;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor.instance;
  final MetricsCollector _metricsCollector = MetricsCollector.instance;
  
  final Map<String, AlertRule> _alertRules = {};
  final Map<String, AlertState> _alertStates = {};
  final List<Alert> _activeAlerts = [];
  final List<Alert> _alertHistory = [];
  final StreamController<Alert> _alertController = StreamController.broadcast();
  
  Timer? _evaluationTimer;
  bool _initialized = false;

  /// Stream of alerts
  Stream<Alert> get alertStream => _alertController.stream;

  /// Initialize alerting service
  Future<void> initialize() async {
    if (_initialized) return;

    await _loadAlertRules();
    _setupDefaultAlertRules();

    // Start periodic alert evaluation (every 30 seconds)
    _evaluationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _evaluateAlerts(),
    );

    // Listen to performance events
    _performanceMonitor.metricsStream.listen(_handlePerformanceEvent);
    _metricsCollector.snapshotStream.listen(_handleMetricsSnapshot);

    _initialized = true;

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'alerting_service_init',
      success: true,
      metadata: {
        'alert_rules': _alertRules.length,
        'evaluation_interval': 30,
      },
    );
  }

  /// Add or update an alert rule
  void addAlertRule(AlertRule rule) {
    _alertRules[rule.id] = rule;
    _alertStates[rule.id] = AlertState(
      ruleId: rule.id,
      isTriggered: false,
      lastEvaluation: DateTime.now(),
      consecutiveFailures: 0,
      lastTriggerTime: null,
    );

    _saveAlertRules();

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'add_alert_rule',
      success: true,
      metadata: {
        'rule_id': rule.id,
        'rule_type': rule.type.name,
        'severity': rule.severity.name,
      },
    );
  }

  /// Remove an alert rule
  void removeAlertRule(String ruleId) {
    _alertRules.remove(ruleId);
    _alertStates.remove(ruleId);
    
    // Resolve any active alerts for this rule
    _resolveAlertsForRule(ruleId);
    
    _saveAlertRules();

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'remove_alert_rule',
      success: true,
      metadata: {'rule_id': ruleId},
    );
  }

  /// Get all active alerts
  List<Alert> getActiveAlerts({AlertSeverity? severity, String? component}) {
    return _activeAlerts.where((alert) {
      if (severity != null && alert.severity != severity) return false;
      if (component != null && alert.component != component) return false;
      return true;
    }).toList();
  }

  /// Get alert history
  List<Alert> getAlertHistory({
    DateTime? fromDate,
    DateTime? toDate,
    AlertSeverity? severity,
    String? component,
    int limit = 100,
  }) {
    var history = _alertHistory.where((alert) {
      if (fromDate != null && alert.timestamp.isBefore(fromDate)) return false;
      if (toDate != null && alert.timestamp.isAfter(toDate)) return false;
      if (severity != null && alert.severity != severity) return false;
      if (component != null && alert.component != component) return false;
      return true;
    }).toList();

    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return history.take(limit).toList();
  }

  /// Manually trigger an alert
  void triggerAlert({
    required String title,
    required String description,
    required AlertSeverity severity,
    required String component,
    String? agentId,
    String? serverId,
    Map<String, dynamic>? context,
  }) {
    final alert = Alert(
      id: _generateAlertId(),
      ruleId: 'manual',
      title: title,
      description: description,
      severity: severity,
      component: component,
      agentId: agentId,
      serverId: serverId,
      timestamp: DateTime.now(),
      context: context ?? {},
      isResolved: false,
    );

    _addAlert(alert);
  }

  /// Resolve an alert
  void resolveAlert(String alertId, {String? resolution}) {
    final alertIndex = _activeAlerts.indexWhere((a) => a.id == alertId);
    if (alertIndex == -1) return;

    final alert = _activeAlerts[alertIndex];
    final resolvedAlert = Alert(
      id: alert.id,
      ruleId: alert.ruleId,
      title: alert.title,
      description: alert.description,
      severity: alert.severity,
      component: alert.component,
      agentId: alert.agentId,
      serverId: alert.serverId,
      timestamp: alert.timestamp,
      context: alert.context,
      isResolved: true,
      resolvedAt: DateTime.now(),
      resolution: resolution,
    );

    _activeAlerts.removeAt(alertIndex);
    _alertHistory.add(resolvedAlert);

    _alertController.add(resolvedAlert);

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'resolve_alert',
      success: true,
      metadata: {
        'alert_id': alertId,
        'resolution': resolution,
      },
    );
  }

  /// Get alert statistics
  AlertStatistics getAlertStatistics({Duration? timeWindow}) {
    final now = DateTime.now();
    final windowStart = timeWindow != null ? now.subtract(timeWindow) : null;

    final relevantAlerts = _alertHistory.where((alert) {
      return windowStart == null || alert.timestamp.isAfter(windowStart);
    }).toList();

    final severityCount = <AlertSeverity, int>{};
    final componentCount = <String, int>{};
    final hourlyCount = <int, int>{};

    for (final alert in relevantAlerts) {
      // Count by severity
      severityCount[alert.severity] = (severityCount[alert.severity] ?? 0) + 1;
      
      // Count by component
      componentCount[alert.component] = (componentCount[alert.component] ?? 0) + 1;
      
      // Count by hour
      final hour = alert.timestamp.hour;
      hourlyCount[hour] = (hourlyCount[hour] ?? 0) + 1;
    }

    return AlertStatistics(
      totalAlerts: relevantAlerts.length,
      activeAlerts: _activeAlerts.length,
      resolvedAlerts: relevantAlerts.where((a) => a.isResolved).length,
      severityDistribution: severityCount,
      componentDistribution: componentCount,
      hourlyDistribution: hourlyCount,
      averageResolutionTimeMinutes: _calculateAverageResolutionTime(relevantAlerts),
      timeWindow: timeWindow,
    );
  }

  /// Setup default alert rules
  void _setupDefaultAlertRules() {
    // High memory usage alert
    addAlertRule(AlertRule(
      id: 'high_memory_usage',
      name: 'High Memory Usage',
      description: 'Triggers when memory usage exceeds threshold',
      type: AlertType.threshold,
      severity: AlertSeverity.warning,
      component: 'system',
      condition: ThresholdCondition(
        metric: 'memory_usage_mb',
        operator: ThresholdOperator.greaterThan,
        value: 6000, // 6GB
      ),
      evaluationInterval: const Duration(minutes: 1),
      consecutiveFailures: 2,
    ));

    // High CPU usage alert
    addAlertRule(AlertRule(
      id: 'high_cpu_usage',
      name: 'High CPU Usage',
      description: 'Triggers when CPU usage exceeds threshold',
      type: AlertType.threshold,
      severity: AlertSeverity.warning,
      component: 'system',
      condition: ThresholdCondition(
        metric: 'cpu_usage_percent',
        operator: ThresholdOperator.greaterThan,
        value: 80.0,
      ),
      evaluationInterval: const Duration(minutes: 1),
      consecutiveFailures: 3,
    ));

    // Terminal error rate alert
    addAlertRule(AlertRule(
      id: 'terminal_error_rate',
      name: 'High Terminal Error Rate',
      description: 'Triggers when terminal error rate is high',
      type: AlertType.threshold,
      severity: AlertSeverity.error,
      component: 'terminal',
      condition: ThresholdCondition(
        metric: 'error_rate',
        operator: ThresholdOperator.greaterThan,
        value: 10.0, // 10% error rate
      ),
      evaluationInterval: const Duration(minutes: 2),
      consecutiveFailures: 2,
    ));

    // MCP server down alert
    addAlertRule(AlertRule(
      id: 'mcp_server_down',
      name: 'MCP Server Down',
      description: 'Triggers when MCP server stops responding',
      type: AlertType.availability,
      severity: AlertSeverity.critical,
      component: 'mcp_server',
      condition: AvailabilityCondition(
        checkType: 'process_running',
        timeout: const Duration(seconds: 30),
      ),
      evaluationInterval: const Duration(minutes: 1),
      consecutiveFailures: 1,
    ));

    // Slow response time alert
    addAlertRule(AlertRule(
      id: 'slow_response_time',
      name: 'Slow Response Time',
      description: 'Triggers when response times are consistently slow',
      type: AlertType.threshold,
      severity: AlertSeverity.warning,
      component: 'terminal',
      condition: ThresholdCondition(
        metric: 'average_response_time_ms',
        operator: ThresholdOperator.greaterThan,
        value: 5000.0, // 5 seconds
      ),
      evaluationInterval: const Duration(minutes: 2),
      consecutiveFailures: 3,
    ));
  }

  /// Handle performance events
  void _handlePerformanceEvent(PerformanceEvent event) {
    // Check if any alert rules should be triggered by this event
    for (final rule in _alertRules.values) {
      if (rule.component != event.component) continue;
      
      _evaluateRule(rule, {
        'event': event,
        'metrics': event.metrics,
      });
    }
  }

  /// Handle metrics snapshots
  void _handleMetricsSnapshot(MetricsSnapshot snapshot) {
    // Evaluate system-level alert rules
    for (final rule in _alertRules.values) {
      if (rule.component == 'system') {
        _evaluateRule(rule, {
          'system_metrics': snapshot.systemMetrics,
        });
      }
    }
  }

  /// Evaluate all alert rules
  Future<void> _evaluateAlerts() async {
    for (final rule in _alertRules.values) {
      try {
        await _evaluateRuleAsync(rule);
      } catch (e) {
        _logger.logError(
          component: 'alerting_service',
          error: 'Failed to evaluate rule: ${rule.id}',
          operation: 'evaluate_rule',
          context: {'rule_id': rule.id, 'error': e.toString()},
        );
      }
    }
  }

  /// Evaluate a specific rule asynchronously
  Future<void> _evaluateRuleAsync(AlertRule rule) async {
    Map<String, dynamic> context = {};

    // Gather context based on rule component
    switch (rule.component) {
      case 'system':
        final systemMetrics = await _metricsCollector.collectSystemMetrics();
        context['system_metrics'] = systemMetrics;
        break;
      case 'terminal':
        // Would collect terminal-specific metrics
        break;
      case 'mcp_server':
        // Would collect MCP server-specific metrics
        break;
    }

    _evaluateRule(rule, context);
  }

  /// Evaluate a single alert rule
  void _evaluateRule(AlertRule rule, Map<String, dynamic> context) {
    final state = _alertStates[rule.id];
    if (state == null) return;

    final now = DateTime.now();
    final timeSinceLastEval = now.difference(state.lastEvaluation);
    
    // Check if it's time to evaluate this rule
    if (timeSinceLastEval < rule.evaluationInterval) return;

    bool shouldTrigger = false;
    String? failureReason;

    try {
      switch (rule.type) {
        case AlertType.threshold:
          final result = _evaluateThresholdCondition(rule.condition as ThresholdCondition, context);
          shouldTrigger = result.shouldTrigger;
          failureReason = result.reason;
          break;
        case AlertType.availability:
          final result = _evaluateAvailabilityCondition(rule.condition as AvailabilityCondition, context);
          shouldTrigger = result.shouldTrigger;
          failureReason = result.reason;
          break;
        case AlertType.anomaly:
          // Would implement anomaly detection
          break;
      }
    } catch (e) {
      _logger.logError(
        component: 'alerting_service',
        error: 'Failed to evaluate condition for rule: ${rule.id}',
        operation: 'evaluate_condition',
        context: {'rule_id': rule.id, 'error': e.toString()},
      );
      return;
    }

    // Update alert state
    state.lastEvaluation = now;

    if (shouldTrigger) {
      state.consecutiveFailures++;
      
      // Trigger alert if consecutive failures threshold is met
      if (state.consecutiveFailures >= rule.consecutiveFailures && !state.isTriggered) {
        _triggerAlert(rule, failureReason ?? 'Condition met', context);
        state.isTriggered = true;
        state.lastTriggerTime = now;
      }
    } else {
      // Reset consecutive failures and resolve alert if triggered
      if (state.consecutiveFailures > 0) {
        state.consecutiveFailures = 0;
      }
      
      if (state.isTriggered) {
        _resolveAlertsForRule(rule.id);
        state.isTriggered = false;
      }
    }
  }

  /// Evaluate threshold condition
  ConditionResult _evaluateThresholdCondition(ThresholdCondition condition, Map<String, dynamic> context) {
    double? value;

    // Extract metric value from context
    if (context.containsKey('system_metrics')) {
      final systemMetrics = context['system_metrics'] as SystemMetrics;
      switch (condition.metric) {
        case 'memory_usage_mb':
          value = systemMetrics.usedMemoryMB.toDouble();
          break;
        case 'cpu_usage_percent':
          value = systemMetrics.cpuUsagePercent;
          break;
      }
    } else if (context.containsKey('event')) {
      final event = context['event'] as PerformanceEvent;
      if (event.metrics.containsKey(condition.metric)) {
        final metricValue = event.metrics[condition.metric];
        if (metricValue is num) {
          value = metricValue.toDouble();
        }
      }
    }

    if (value == null) {
      return ConditionResult(shouldTrigger: false, reason: 'Metric not found: ${condition.metric}');
    }

    bool shouldTrigger = false;
    switch (condition.operator) {
      case ThresholdOperator.greaterThan:
        shouldTrigger = value > condition.value;
        break;
      case ThresholdOperator.lessThan:
        shouldTrigger = value < condition.value;
        break;
      case ThresholdOperator.equals:
        shouldTrigger = value == condition.value;
        break;
    }

    return ConditionResult(
      shouldTrigger: shouldTrigger,
      reason: shouldTrigger 
        ? '${condition.metric} ($value) ${condition.operator.name} ${condition.value}'
        : null,
    );
  }

  /// Evaluate availability condition
  ConditionResult _evaluateAvailabilityCondition(AvailabilityCondition condition, Map<String, dynamic> context) {
    // This would implement actual availability checks
    // For now, return a mock result
    return ConditionResult(shouldTrigger: false, reason: null);
  }

  /// Trigger an alert
  void _triggerAlert(AlertRule rule, String reason, Map<String, dynamic> context) {
    final alert = Alert(
      id: _generateAlertId(),
      ruleId: rule.id,
      title: rule.name,
      description: '${rule.description}\nReason: $reason',
      severity: rule.severity,
      component: rule.component,
      agentId: context['agent_id'] as String?,
      serverId: context['server_id'] as String?,
      timestamp: DateTime.now(),
      context: context,
      isResolved: false,
    );

    _addAlert(alert);
  }

  /// Add an alert to active alerts
  void _addAlert(Alert alert) {
    _activeAlerts.add(alert);
    _alertHistory.add(alert);
    _alertController.add(alert);

    _logger.logError(
      component: 'alerting_service',
      error: 'Alert triggered: ${alert.title}',
      operation: 'trigger_alert',
      agentId: alert.agentId,
      serverId: alert.serverId,
      context: {
        'alert_id': alert.id,
        'rule_id': alert.ruleId,
        'severity': alert.severity.name,
        'component': alert.component,
      },
    );
  }

  /// Resolve alerts for a specific rule
  void _resolveAlertsForRule(String ruleId) {
    final alertsToResolve = _activeAlerts.where((a) => a.ruleId == ruleId).toList();
    
    for (final alert in alertsToResolve) {
      resolveAlert(alert.id, resolution: 'Condition no longer met');
    }
  }

  /// Generate unique alert ID
  String _generateAlertId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}_${_activeAlerts.length}';
  }

  /// Calculate average resolution time
  double _calculateAverageResolutionTime(List<Alert> alerts) {
    final resolvedAlerts = alerts.where((a) => a.isResolved && a.resolvedAt != null).toList();
    
    if (resolvedAlerts.isEmpty) return 0.0;

    final totalMinutes = resolvedAlerts
        .map((a) => a.resolvedAt!.difference(a.timestamp).inMinutes)
        .reduce((a, b) => a + b);

    return totalMinutes / resolvedAlerts.length;
  }

  /// Load alert rules from configuration
  Future<void> _loadAlertRules() async {
    try {
      final configFile = File(await _getAlertRulesConfigPath());
      if (await configFile.exists()) {
        final configJson = await configFile.readAsString();
        final config = jsonDecode(configJson) as Map<String, dynamic>;
        
        for (final entry in config.entries) {
          final ruleData = entry.value as Map<String, dynamic>;
          final rule = AlertRule.fromJson(ruleData);
          _alertRules[rule.id] = rule;
          _alertStates[rule.id] = AlertState(
            ruleId: rule.id,
            isTriggered: false,
            lastEvaluation: DateTime.now(),
            consecutiveFailures: 0,
            lastTriggerTime: null,
          );
        }
      }
    } catch (e) {
      _logger.logError(
        component: 'alerting_service',
        error: 'Failed to load alert rules',
        operation: 'load_alert_rules',
        context: {'error': e.toString()},
      );
    }
  }

  /// Save alert rules to configuration
  Future<void> _saveAlertRules() async {
    try {
      final configFile = File(await _getAlertRulesConfigPath());
      await configFile.parent.create(recursive: true);
      
      final config = <String, dynamic>{};
      for (final entry in _alertRules.entries) {
        config[entry.key] = entry.value.toJson();
      }
      
      await configFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(config),
      );
    } catch (e) {
      _logger.logError(
        component: 'alerting_service',
        error: 'Failed to save alert rules',
        operation: 'save_alert_rules',
        context: {'error': e.toString()},
      );
    }
  }

  Future<String> _getAlertRulesConfigPath() async {
    final configDir = await _getConfigDirectory();
    return path.join(configDir, 'alert_rules.json');
  }

  Future<String> _getConfigDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ?? Platform.environment['APPDATA'];
      return path.join(appData!, 'Asmbli', 'config');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME']!;
      return path.join(home, 'Library', 'Application Support', 'Asmbli');
    } else {
      final home = Platform.environment['HOME']!;
      return path.join(home, '.config', 'asmbli');
    }
  }

  /// Dispose resources
  void dispose() {
    _evaluationTimer?.cancel();
    _alertController.close();
    _alertRules.clear();
    _alertStates.clear();
    _activeAlerts.clear();
    _alertHistory.clear();
    _initialized = false;
  }
}

/// Data models
class AlertRule {
  final String id;
  final String name;
  final String description;
  final AlertType type;
  final AlertSeverity severity;
  final String component;
  final AlertCondition condition;
  final Duration evaluationInterval;
  final int consecutiveFailures;

  AlertRule({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.severity,
    required this.component,
    required this.condition,
    required this.evaluationInterval,
    required this.consecutiveFailures,
  });

  factory AlertRule.fromJson(Map<String, dynamic> json) {
    AlertCondition condition;
    switch (AlertType.values.byName(json['type'])) {
      case AlertType.threshold:
        condition = ThresholdCondition.fromJson(json['condition']);
        break;
      case AlertType.availability:
        condition = AvailabilityCondition.fromJson(json['condition']);
        break;
      case AlertType.anomaly:
        condition = AnomalyCondition.fromJson(json['condition']);
        break;
    }

    return AlertRule(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: AlertType.values.byName(json['type']),
      severity: AlertSeverity.values.byName(json['severity']),
      component: json['component'],
      condition: condition,
      evaluationInterval: Duration(seconds: json['evaluation_interval_seconds']),
      consecutiveFailures: json['consecutive_failures'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'severity': severity.name,
      'component': component,
      'condition': condition.toJson(),
      'evaluation_interval_seconds': evaluationInterval.inSeconds,
      'consecutive_failures': consecutiveFailures,
    };
  }
}

abstract class AlertCondition {
  Map<String, dynamic> toJson();
}

class ThresholdCondition extends AlertCondition {
  final String metric;
  final ThresholdOperator operator;
  final double value;

  ThresholdCondition({
    required this.metric,
    required this.operator,
    required this.value,
  });

  factory ThresholdCondition.fromJson(Map<String, dynamic> json) {
    return ThresholdCondition(
      metric: json['metric'],
      operator: ThresholdOperator.values.byName(json['operator']),
      value: json['value'].toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'metric': metric,
      'operator': operator.name,
      'value': value,
    };
  }
}

class AvailabilityCondition extends AlertCondition {
  final String checkType;
  final Duration timeout;

  AvailabilityCondition({
    required this.checkType,
    required this.timeout,
  });

  factory AvailabilityCondition.fromJson(Map<String, dynamic> json) {
    return AvailabilityCondition(
      checkType: json['check_type'],
      timeout: Duration(seconds: json['timeout_seconds']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'check_type': checkType,
      'timeout_seconds': timeout.inSeconds,
    };
  }
}

class AnomalyCondition extends AlertCondition {
  final String algorithm;
  final double sensitivity;

  AnomalyCondition({
    required this.algorithm,
    required this.sensitivity,
  });

  factory AnomalyCondition.fromJson(Map<String, dynamic> json) {
    return AnomalyCondition(
      algorithm: json['algorithm'],
      sensitivity: json['sensitivity'].toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'algorithm': algorithm,
      'sensitivity': sensitivity,
    };
  }
}

class Alert {
  final String id;
  final String ruleId;
  final String title;
  final String description;
  final AlertSeverity severity;
  final String component;
  final String? agentId;
  final String? serverId;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolution;

  Alert({
    required this.id,
    required this.ruleId,
    required this.title,
    required this.description,
    required this.severity,
    required this.component,
    this.agentId,
    this.serverId,
    required this.timestamp,
    required this.context,
    required this.isResolved,
    this.resolvedAt,
    this.resolution,
  });
}

class AlertState {
  final String ruleId;
  bool isTriggered;
  DateTime lastEvaluation;
  int consecutiveFailures;
  DateTime? lastTriggerTime;

  AlertState({
    required this.ruleId,
    required this.isTriggered,
    required this.lastEvaluation,
    required this.consecutiveFailures,
    this.lastTriggerTime,
  });
}

class AlertStatistics {
  final int totalAlerts;
  final int activeAlerts;
  final int resolvedAlerts;
  final Map<AlertSeverity, int> severityDistribution;
  final Map<String, int> componentDistribution;
  final Map<int, int> hourlyDistribution;
  final double averageResolutionTimeMinutes;
  final Duration? timeWindow;

  AlertStatistics({
    required this.totalAlerts,
    required this.activeAlerts,
    required this.resolvedAlerts,
    required this.severityDistribution,
    required this.componentDistribution,
    required this.hourlyDistribution,
    required this.averageResolutionTimeMinutes,
    this.timeWindow,
  });
}

class ConditionResult {
  final bool shouldTrigger;
  final String? reason;

  ConditionResult({required this.shouldTrigger, this.reason});
}

enum AlertType { threshold, availability, anomaly }
enum AlertSeverity { info, warning, error, critical }
enum ThresholdOperator { greaterThan, lessThan, equals }

// ==================== Riverpod Provider ====================

final alertingServiceProvider = Provider<AlertingService>((ref) {
  return AlertingService.instance;
});