import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'integration_analytics_service.dart';

/// Service that tracks real-time integration usage by monitoring MCP server calls
class RealTimeIntegrationTracker {
  final IntegrationAnalyticsService _analyticsService;
  final Map<String, Stopwatch> _activeCallTimers = {};
  
  RealTimeIntegrationTracker(this._analyticsService);
  
  /// Record the start of an MCP integration call
  void startIntegrationCall(String integrationId, String tool) {
    final callKey = '$integrationId:$tool:${DateTime.now().millisecondsSinceEpoch}';
    final stopwatch = Stopwatch()..start();
    _activeCallTimers[callKey] = stopwatch;
  }
  
  /// Record the completion of an MCP integration call
  void completeIntegrationCall(
    String integrationId, 
    String tool, {
    bool success = true,
    int? dataBytes,
    String? error,
  }) {
    // Find the matching timer (most recent for this integration/tool)
    final matchingKey = _activeCallTimers.keys
        .where((key) => key.startsWith('$integrationId:$tool:'))
        .fold<String?>(null, (prev, current) {
          if (prev == null) return current;
          final prevTime = int.parse(prev.split(':').last);
          final currentTime = int.parse(current.split(':').last);
          return currentTime > prevTime ? current : prev;
        });
    
    int responseTime = 0;
    if (matchingKey != null) {
      final stopwatch = _activeCallTimers.remove(matchingKey);
      responseTime = stopwatch?.elapsedMilliseconds ?? 0;
    }
    
    // Record the usage in analytics
    _analyticsService.recordUsage(
      integrationId,
      tool,
      responseTime: responseTime,
      success: success,
      dataBytes: dataBytes ?? 0,
    );
    
    // If there was an error, record it as an analytics event
    if (!success && error != null) {
      _recordError(integrationId, tool, error, responseTime);
    }
  }
  
  /// Record an integration error
  void _recordError(String integrationId, String tool, String error, int responseTime) {
    // This could be expanded to create specific error events
    print('Integration Error: $integrationId.$tool - $error (${responseTime}ms)');
  }
  
  /// Record integration installation
  void recordIntegrationInstalled(String integrationId) {
    _analyticsService.events.add(AnalyticsEvent(
      timestamp: DateTime.now(),
      type: AnalyticsEventType.integrationInstalled,
      integrationId: integrationId,
      details: {},
    ));
    _analyticsService.saveAnalyticsData();
  }
  
  /// Record integration removal
  void recordIntegrationRemoved(String integrationId) {
    _analyticsService.events.add(AnalyticsEvent(
      timestamp: DateTime.now(),
      type: AnalyticsEventType.integrationRemoved,
      integrationId: integrationId,
      details: {},
    ));
    _analyticsService.saveAnalyticsData();
  }
  
  /// Record configuration change
  void recordConfigurationChanged(String integrationId, Map<String, dynamic> changes) {
    _analyticsService.events.add(AnalyticsEvent(
      timestamp: DateTime.now(),
      type: AnalyticsEventType.configurationChanged,
      integrationId: integrationId,
      details: changes,
    ));
    _analyticsService.saveAnalyticsData();
  }
  
  /// Get current active calls count
  int get activeCallsCount => _activeCallTimers.length;
  
  /// Get active calls for a specific integration
  List<String> getActiveCallsForIntegration(String integrationId) {
    return _activeCallTimers.keys
        .where((key) => key.startsWith('$integrationId:'))
        .map((key) => key.split(':')[1]) // Extract tool name
        .toList();
  }
  
  /// Clean up stale timers (calls that have been active for more than 5 minutes)
  void cleanupStaleTimers() {
    final fiveMinutesAgo = DateTime.now().millisecondsSinceEpoch - (5 * 60 * 1000);
    final staleKeys = _activeCallTimers.keys
        .where((key) {
          final timestamp = int.parse(key.split(':').last);
          return timestamp < fiveMinutesAgo;
        })
        .toList();
    
    for (final key in staleKeys) {
      _activeCallTimers.remove(key);
    }
  }
}

/// Provider for the real-time integration tracker
final realTimeIntegrationTrackerProvider = Provider<RealTimeIntegrationTracker>((ref) {
  final analyticsService = ref.watch(integrationAnalyticsServiceProvider);
  final tracker = RealTimeIntegrationTracker(analyticsService);
  
  // Set up periodic cleanup of stale timers
  Timer.periodic(const Duration(minutes: 1), (_) {
    tracker.cleanupStaleTimers();
  });
  
  return tracker;
});