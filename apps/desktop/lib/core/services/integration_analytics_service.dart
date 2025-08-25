import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'integration_service.dart';
import 'mcp_settings_service.dart';

/// Service for tracking integration usage analytics and generating insights
class IntegrationAnalyticsService {
  final IntegrationService _integrationService;
  final MCPSettingsService _mcpService;
  
  // Usage tracking
  final Map<String, IntegrationUsageData> _usageData = {};
  
  // Analytics history (in a real app, this would be persisted)
  final List<AnalyticsEvent> _events = [];
  
  IntegrationAnalyticsService(this._integrationService, this._mcpService) {
    _initializeMockData();
  }
  
  /// Initialize with mock analytics data for demonstration
  void _initializeMockData() {
    final configured = _integrationService.getConfiguredIntegrations();
    
    for (final integration in configured) {
      if (integration.isEnabled) {
        _usageData[integration.definition.id] = IntegrationUsageData(
          integrationId: integration.definition.id,
          totalInvocations: _generateRandomUsage(),
          lastUsed: DateTime.now().subtract(Duration(
            hours: Random().nextInt(72), // Last 3 days
          )),
          averageResponseTime: 100 + Random().nextInt(400), // 100-500ms
          successRate: 0.85 + (Random().nextDouble() * 0.14), // 85-99%
          dailyUsage: _generateDailyUsage(),
          topTools: _generateTopTools(integration.definition.id),
          errorCount: Random().nextInt(5),
          totalDataTransferred: _generateDataTransfer(),
        );
      }
    }
    
    _generateAnalyticsEvents();
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
    _events.add(AnalyticsEvent(
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
  int _generateRandomUsage() {
    return Random().nextInt(100) + 10; // 10-110 invocations
  }
  
  Map<String, int> _generateDailyUsage() {
    final usage = <String, int>{};
    final now = DateTime.now();
    
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final key = date.toIso8601String().split('T')[0];
      usage[key] = Random().nextInt(10); // 0-10 per day
    }
    
    return usage;
  }
  
  Map<String, int> _generateTopTools(String integrationId) {
    final tools = <String, int>{};
    
    // Generate mock tool usage based on integration type
    switch (integrationId) {
      case 'github':
        tools['list-repos'] = Random().nextInt(20) + 5;
        tools['create-issue'] = Random().nextInt(15) + 2;
        tools['get-pr'] = Random().nextInt(25) + 3;
        break;
      case 'filesystem':
        tools['read-file'] = Random().nextInt(50) + 10;
        tools['write-file'] = Random().nextInt(30) + 5;
        tools['list-directory'] = Random().nextInt(40) + 8;
        break;
      default:
        tools['default-tool'] = Random().nextInt(30) + 5;
    }
    
    return tools;
  }
  
  int _generateDataTransfer() {
    return Random().nextInt(1024 * 1024) + 1024; // 1KB - 1MB
  }
  
  void _generateAnalyticsEvents() {
    final now = DateTime.now();
    
    for (int i = 0; i < 50; i++) {
      _events.add(AnalyticsEvent(
        timestamp: now.subtract(Duration(hours: Random().nextInt(72))),
        type: AnalyticsEventType.values[Random().nextInt(AnalyticsEventType.values.length)],
        integrationId: _usageData.keys.elementAt(Random().nextInt(_usageData.length)),
        details: {'mock': true},
      ));
    }
  }
  
  int _getActiveIntegrationsForDate(DateTime date) {
    // Mock implementation
    return Random().nextInt(5) + 1;
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