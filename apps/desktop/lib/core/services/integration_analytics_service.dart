import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'integration_service.dart';
import 'mcp_settings_service.dart';
import 'desktop/desktop_storage_service.dart';

/// Service for tracking integration usage analytics and generating insights
class IntegrationAnalyticsService {
  final IntegrationService _integrationService;
  final MCPSettingsService _mcpService;
  final DesktopStorageService _storage = DesktopStorageService.instance;
  
  // Usage tracking
  final Map<String, IntegrationUsageData> _usageData = {};
  
  // Analytics history (persisted to local storage) - accessible for real-time tracking
  final List<AnalyticsEvent> events = [];
  
  IntegrationAnalyticsService(this._integrationService, this._mcpService) {
    _initializeRealData();
  }
  
  /// Initialize with real analytics data from actual integrations
  void _initializeRealData() {
    final configured = _integrationService.getConfiguredIntegrations();
    
    // Initialize usage data from actual configured integrations
    for (final integration in configured.where((i) => i.isEnabled)) {
      _usageData[integration.definition.id] = IntegrationUsageData(
        integrationId: integration.definition.id,
        totalInvocations: 0,
        lastUsed: DateTime.now().subtract(Duration(days: 30)), // Default to 30 days ago
        averageResponseTime: 0,
        successRate: 1.0,
        dailyUsage: {},
        topTools: {},
        errorCount: 0,
        totalDataTransferred: 0,
      );
    }
    
    // Load stored analytics data from persistent storage
    _loadStoredAnalyticsData();
  }

  /// Load analytics data from persistent storage
  Future<void> _loadStoredAnalyticsData() async {
    try {
      // Load usage data
      final usageJson = _storage.getHiveData('analytics', 'usage_data');
      if (usageJson is Map<String, dynamic>) {
        for (final entry in usageJson.entries) {
          final data = entry.value as Map<String, dynamic>;
          _usageData[entry.key] = IntegrationUsageData.fromJson(data);
        }
      }
      
      // Load events
      final eventsJson = _storage.getHiveData('analytics', 'events');
      if (eventsJson is List) {
        events.clear();
        for (final eventData in eventsJson.cast<Map<String, dynamic>>()) {
          events.add(AnalyticsEvent.fromJson(eventData));
        }
      }
    } catch (e) {
      print('Warning: Failed to load stored analytics data: $e');
      // Continue with empty data if loading fails
    }
  }

  /// Save analytics data to persistent storage
  Future<void> saveAnalyticsData() async {
    try {
      // Save usage data
      final usageJson = <String, dynamic>{};
      for (final entry in _usageData.entries) {
        usageJson[entry.key] = entry.value.toJson();
      }
      await _storage.setHiveData('analytics', 'usage_data', usageJson);
      
      // Save recent events (keep last 1000 events)
      final recentEvents = events.length > 1000 ? events.sublist(events.length - 1000) : events;
      final eventsJson = recentEvents.map((e) => e.toJson()).toList();
      await _storage.setHiveData('analytics', 'events', eventsJson);
    } catch (e) {
      print('Warning: Failed to save analytics data: $e');
    }
  }
  
  /// Record integration usage
  void recordUsage(String integrationId, String tool, {
    int responseTime = 0,
    bool success = true,
    int dataBytes = 0,
  }) {
    final usage = _usageData[integrationId] ?? IntegrationUsageData(
      integrationId: integrationId,
      totalInvocations: 0,
      lastUsed: DateTime.now(),
      averageResponseTime: 0,
      successRate: 1.0,
      dailyUsage: {},
      topTools: {},
      errorCount: 0,
      totalDataTransferred: 0,
    );
    
    // Update usage statistics
    final updatedUsage = usage.copyWith(
      totalInvocations: usage.totalInvocations + 1,
      lastUsed: DateTime.now(),
      averageResponseTime: ((usage.averageResponseTime * usage.totalInvocations) + responseTime) ~/ (usage.totalInvocations + 1),
      errorCount: success ? usage.errorCount : usage.errorCount + 1,
      totalDataTransferred: usage.totalDataTransferred + dataBytes,
    );
    
    // Update success rate
    final totalAttempts = updatedUsage.totalInvocations;
    final successfulAttempts = totalAttempts - updatedUsage.errorCount;
    updatedUsage.successRate = successfulAttempts / totalAttempts;
    
    // Update daily usage
    final today = DateTime.now().toIso8601String().split('T')[0];
    updatedUsage.dailyUsage[today] = (updatedUsage.dailyUsage[today] ?? 0) + 1;
    
    // Update top tools
    updatedUsage.topTools[tool] = (updatedUsage.topTools[tool] ?? 0) + 1;
    
    _usageData[integrationId] = updatedUsage;
    
    // Record analytics event
    events.add(AnalyticsEvent(
      timestamp: DateTime.now(),
      type: AnalyticsEventType.integrationUsed,
      integrationId: integrationId,
      details: {
        'tool': tool,
        'responseTime': responseTime,
        'success': success,
        'dataBytes': dataBytes,
      },
    ));
    
    // Save data to persistent storage
    saveAnalyticsData();
  }
  
  /// Get usage data for a specific integration
  IntegrationUsageData? getUsageData(String integrationId) {
    return _usageData[integrationId];
  }
  
  /// Get usage data for all integrations
  Map<String, IntegrationUsageData> getAllUsageData() {
    return Map.from(_usageData);
  }
  
  /// Get integration usage statistics
  IntegrationStatistics getStatistics() {
    final allUsage = getAllUsageData();
    
    if (allUsage.isEmpty) {
      return IntegrationStatistics(
        totalIntegrations: 0,
        activeIntegrations: 0,
        totalInvocations: 0,
        averageResponseTime: 0,
        overallSuccessRate: 0.0,
        mostUsedIntegration: null,
        leastUsedIntegration: null,
        totalDataTransferred: 0,
        dailyActiveUsers: 0,
      );
    }
    
    final totalInvocations = allUsage.values.fold(0, (sum, usage) => sum + usage.totalInvocations);
    final totalResponseTime = allUsage.values.fold(0, (sum, usage) => sum + (usage.averageResponseTime * usage.totalInvocations));
    final averageResponseTime = totalInvocations > 0 ? totalResponseTime ~/ totalInvocations : 0;
    
    final totalSuccessful = allUsage.values.fold(0, (sum, usage) => sum + (usage.totalInvocations - usage.errorCount));
    final overallSuccessRate = totalInvocations > 0 ? totalSuccessful / totalInvocations : 0.0;
    
    final sortedByUsage = allUsage.entries.toList()
      ..sort((a, b) => b.value.totalInvocations.compareTo(a.value.totalInvocations));
    
    final totalDataTransferred = allUsage.values.fold(0, (sum, usage) => sum + usage.totalDataTransferred);
    
    // Count active integrations (used in last 7 days)
    final weekAgo = DateTime.now().subtract(Duration(days: 7));
    final activeIntegrations = allUsage.values.where((usage) => usage.lastUsed.isAfter(weekAgo)).length;
    
    return IntegrationStatistics(
      totalIntegrations: allUsage.length,
      activeIntegrations: activeIntegrations,
      totalInvocations: totalInvocations,
      averageResponseTime: averageResponseTime,
      overallSuccessRate: overallSuccessRate,
      mostUsedIntegration: sortedByUsage.isNotEmpty ? sortedByUsage.first.key : null,
      leastUsedIntegration: sortedByUsage.isNotEmpty ? sortedByUsage.last.key : null,
      totalDataTransferred: totalDataTransferred,
      dailyActiveUsers: 1, // Mock single user
    );
  }
  
  /// Get usage trends over time
  List<UsageTrend> getUsageTrends({int days = 30}) {
    final trends = <UsageTrend>[];
    final now = DateTime.now();
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = date.toIso8601String().split('T')[0];
      
      int totalUsage = 0;
      for (final usage in _usageData.values) {
        totalUsage += usage.dailyUsage[dateKey] ?? 0;
      }
      
      trends.add(UsageTrend(
        date: date,
        totalInvocations: totalUsage,
        activeIntegrations: _getActiveIntegrationsForDate(date),
      ));
    }
    
    return trends;
  }
  
  /// Get performance insights
  List<PerformanceInsight> getPerformanceInsights() {
    final insights = <PerformanceInsight>[];
    final allUsage = getAllUsageData();
    
    if (allUsage.isEmpty) return insights;
    
    // Find slow integrations
    final avgResponseTime = allUsage.values.fold(0, (sum, usage) => sum + usage.averageResponseTime) / allUsage.length;
    final slowIntegrations = allUsage.entries.where((entry) => entry.value.averageResponseTime > avgResponseTime * 1.5);
    
    for (final slow in slowIntegrations) {
      final integration = IntegrationRegistry.getById(slow.key);
      insights.add(PerformanceInsight(
        type: InsightType.performance,
        severity: InsightSeverity.warning,
        title: '${integration?.name ?? slow.key} is responding slowly',
        description: 'Average response time is ${slow.value.averageResponseTime}ms, which is above average',
        integrationId: slow.key,
        metric: slow.value.averageResponseTime.toDouble(),
        recommendation: 'Consider checking the integration configuration or server performance',
      ));
    }
    
    // Find error-prone integrations
    final highErrorIntegrations = allUsage.entries.where((entry) => entry.value.successRate < 0.9);
    
    for (final errorProne in highErrorIntegrations) {
      final integration = IntegrationRegistry.getById(errorProne.key);
      insights.add(PerformanceInsight(
        type: InsightType.reliability,
        severity: InsightSeverity.error,
        title: '${integration?.name ?? errorProne.key} has reliability issues',
        description: 'Success rate is ${(errorProne.value.successRate * 100).toStringAsFixed(1)}%',
        integrationId: errorProne.key,
        metric: errorProne.value.successRate,
        recommendation: 'Check integration credentials and server connectivity',
      ));
    }
    
    // Find underused integrations
    final avgUsage = allUsage.values.fold(0, (sum, usage) => sum + usage.totalInvocations) / allUsage.length;
    final underusedIntegrations = allUsage.entries.where((entry) => entry.value.totalInvocations < avgUsage * 0.3);
    
    for (final underused in underusedIntegrations) {
      final integration = IntegrationRegistry.getById(underused.key);
      insights.add(PerformanceInsight(
        type: InsightType.usage,
        severity: InsightSeverity.info,
        title: '${integration?.name ?? underused.key} is underutilized',
        description: 'Only ${underused.value.totalInvocations} invocations compared to average of ${avgUsage.toInt()}',
        integrationId: underused.key,
        metric: underused.value.totalInvocations.toDouble(),
        recommendation: 'Consider reviewing whether this integration is needed or exploring its full capabilities',
      ));
    }
    
    return insights;
  }
  
  /// Get integration recommendations based on usage patterns
  List<UsageBasedRecommendation> getUsageBasedRecommendations() {
    final recommendations = <UsageBasedRecommendation>[];
    final allUsage = getAllUsageData();
    final configuredIds = allUsage.keys.toSet();
    
    // Recommend complementary integrations
    for (final entry in allUsage.entries) {
      if (entry.value.totalInvocations > 10) { // Only for actively used integrations
        final integration = IntegrationRegistry.getById(entry.key);
        if (integration != null) {
          final complementary = _getComplementaryIntegrations(integration.category, configuredIds);
          
          for (final comp in complementary.take(2)) {
            recommendations.add(UsageBasedRecommendation(
              type: RecommendationType.complementary,
              integrationId: comp.id,
              reason: 'Works well with ${integration.name} based on usage patterns',
              confidence: 0.8,
              basedOnIntegration: entry.key,
            ));
          }
        }
      }
    }
    
    // Recommend based on category usage
    final categoryUsage = <IntegrationCategory, int>{};
    for (final entry in allUsage.entries) {
      final integration = IntegrationRegistry.getById(entry.key);
      if (integration != null) {
        categoryUsage[integration.category] = (categoryUsage[integration.category] ?? 0) + entry.value.totalInvocations;
      }
    }
    
    final mostUsedCategory = categoryUsage.entries.fold<MapEntry<IntegrationCategory, int>?>(
      null,
      (prev, entry) => prev == null || entry.value > prev.value ? entry : prev,
    );
    
    if (mostUsedCategory != null) {
      final categoryIntegrations = IntegrationRegistry.getByCategory(mostUsedCategory.key)
          .where((integration) => !configuredIds.contains(integration.id) && integration.isAvailable)
          .take(3);
      
      for (final integration in categoryIntegrations) {
        recommendations.add(UsageBasedRecommendation(
          type: RecommendationType.categoryBased,
          integrationId: integration.id,
          reason: 'Popular in ${mostUsedCategory.key.displayName} category which you use frequently',
          confidence: 0.7,
          basedOnIntegration: null,
        ));
      }
    }
    
    return recommendations.take(5).toList();
  }
  
  // Helper methods
  int _getActiveIntegrationsForDate(DateTime date) {
    // Count integrations that had usage on this date
    final dateKey = date.toIso8601String().split('T')[0];
    return _usageData.values.where((usage) => usage.dailyUsage[dateKey] != null && usage.dailyUsage[dateKey]! > 0).length;
  }
  
  List<IntegrationDefinition> _getComplementaryIntegrations(IntegrationCategory category, Set<String> configured) {
    return IntegrationRegistry.getByCategory(category)
        .where((integration) => !configured.contains(integration.id) && integration.isAvailable)
        .toList();
  }
}

/// Integration usage data
class IntegrationUsageData {
  final String integrationId;
  int totalInvocations;
  DateTime lastUsed;
  int averageResponseTime;
  double successRate;
  Map<String, int> dailyUsage;
  Map<String, int> topTools;
  int errorCount;
  int totalDataTransferred;
  
  IntegrationUsageData({
    required this.integrationId,
    required this.totalInvocations,
    required this.lastUsed,
    required this.averageResponseTime,
    required this.successRate,
    required this.dailyUsage,
    required this.topTools,
    required this.errorCount,
    required this.totalDataTransferred,
  });
  
  IntegrationUsageData copyWith({
    int? totalInvocations,
    DateTime? lastUsed,
    int? averageResponseTime,
    double? successRate,
    int? errorCount,
    int? totalDataTransferred,
  }) {
    return IntegrationUsageData(
      integrationId: integrationId,
      totalInvocations: totalInvocations ?? this.totalInvocations,
      lastUsed: lastUsed ?? this.lastUsed,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      successRate: successRate ?? this.successRate,
      dailyUsage: dailyUsage,
      topTools: topTools,
      errorCount: errorCount ?? this.errorCount,
      totalDataTransferred: totalDataTransferred ?? this.totalDataTransferred,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'integrationId': integrationId,
      'totalInvocations': totalInvocations,
      'lastUsed': lastUsed.toIso8601String(),
      'averageResponseTime': averageResponseTime,
      'successRate': successRate,
      'dailyUsage': dailyUsage,
      'topTools': topTools,
      'errorCount': errorCount,
      'totalDataTransferred': totalDataTransferred,
    };
  }
  
  factory IntegrationUsageData.fromJson(Map<String, dynamic> json) {
    return IntegrationUsageData(
      integrationId: json['integrationId'] as String,
      totalInvocations: json['totalInvocations'] as int? ?? 0,
      lastUsed: DateTime.parse(json['lastUsed'] as String? ?? DateTime.now().toIso8601String()),
      averageResponseTime: json['averageResponseTime'] as int? ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 1.0,
      dailyUsage: Map<String, int>.from(json['dailyUsage'] as Map? ?? {}),
      topTools: Map<String, int>.from(json['topTools'] as Map? ?? {}),
      errorCount: json['errorCount'] as int? ?? 0,
      totalDataTransferred: json['totalDataTransferred'] as int? ?? 0,
    );
  }
}

/// Integration statistics
class IntegrationStatistics {
  final int totalIntegrations;
  final int activeIntegrations;
  final int totalInvocations;
  final int averageResponseTime;
  final double overallSuccessRate;
  final String? mostUsedIntegration;
  final String? leastUsedIntegration;
  final int totalDataTransferred;
  final int dailyActiveUsers;
  
  const IntegrationStatistics({
    required this.totalIntegrations,
    required this.activeIntegrations,
    required this.totalInvocations,
    required this.averageResponseTime,
    required this.overallSuccessRate,
    required this.mostUsedIntegration,
    required this.leastUsedIntegration,
    required this.totalDataTransferred,
    required this.dailyActiveUsers,
  });
}

/// Usage trend data
class UsageTrend {
  final DateTime date;
  final int totalInvocations;
  final int activeIntegrations;
  
  const UsageTrend({
    required this.date,
    required this.totalInvocations,
    required this.activeIntegrations,
  });
}

/// Performance insight
class PerformanceInsight {
  final InsightType type;
  final InsightSeverity severity;
  final String title;
  final String description;
  final String integrationId;
  final double metric;
  final String recommendation;
  
  const PerformanceInsight({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.integrationId,
    required this.metric,
    required this.recommendation,
  });
}

/// Usage-based recommendation
class UsageBasedRecommendation {
  final RecommendationType type;
  final String integrationId;
  final String reason;
  final double confidence;
  final String? basedOnIntegration;
  
  const UsageBasedRecommendation({
    required this.type,
    required this.integrationId,
    required this.reason,
    required this.confidence,
    required this.basedOnIntegration,
  });
}

/// Analytics event
class AnalyticsEvent {
  final DateTime timestamp;
  final AnalyticsEventType type;
  final String integrationId;
  final Map<String, dynamic> details;
  
  const AnalyticsEvent({
    required this.timestamp,
    required this.type,
    required this.integrationId,
    required this.details,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'integrationId': integrationId,
      'details': details,
    };
  }
  
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: AnalyticsEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnalyticsEventType.integrationUsed,
      ),
      integrationId: json['integrationId'] as String,
      details: Map<String, dynamic>.from(json['details'] as Map? ?? {}),
    );
  }
}

enum InsightType {
  performance,
  reliability,
  usage,
  security,
}

enum InsightSeverity {
  info,
  warning,
  error,
}

enum RecommendationType {
  complementary,
  categoryBased,
  trending,
  similar,
}

enum AnalyticsEventType {
  integrationUsed,
  integrationInstalled,
  integrationRemoved,
  integrationError,
  configurationChanged,
}

// Provider
final integrationAnalyticsServiceProvider = Provider<IntegrationAnalyticsService>((ref) {
  final integrationService = ref.watch(integrationServiceProvider);
  final mcpService = ref.watch(mcpSettingsServiceProvider);
  return IntegrationAnalyticsService(integrationService, mcpService);
});