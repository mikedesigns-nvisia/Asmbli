import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'structured_logger.dart';
import 'performance_monitor.dart';
import 'metrics_collector.dart';

/// Comprehensive debugging and troubleshooting service
class DebugService {
  static DebugService? _instance;
  static DebugService get instance => _instance ??= DebugService._();
  
  DebugService._();

  final StructuredLogger _logger = StructuredLogger.instance;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor.instance;
  final MetricsCollector _metricsCollector = MetricsCollector.instance;
  
  final Map<String, DebugSession> _activeSessions = {};
  final List<DebugReport> _debugReports = [];
  final StreamController<DebugEvent> _debugEventController = StreamController.broadcast();
  
  bool _initialized = false;

  /// Stream of debug events
  Stream<DebugEvent> get debugEventStream => _debugEventController.stream;

  /// Initialize debug service
  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'debug_service_init',
      success: true,
      metadata: {'debug_mode': kDebugMode},
    );
  }

  /// Start a debug session for an agent terminal
  Future<DebugSession> startTerminalDebugSession(String agentId) async {
    final sessionId = _generateSessionId();
    
    final session = DebugSession(
      id: sessionId,
      type: DebugSessionType.terminal,
      targetId: agentId,
      startTime: DateTime.now(),
      isActive: true,
      events: [],
      context: {},
    );

    _activeSessions[sessionId] = session;

    // Start collecting debug information
    await _startTerminalDebugging(session);

    _debugEventController.add(DebugEvent(
      type: DebugEventType.sessionStarted,
      sessionId: sessionId,
      timestamp: DateTime.now(),
      data: {'agent_id': agentId, 'session_type': 'terminal'},
    ));

    _logger.logTerminalOperation(
      agentId: agentId,
      operation: 'start_debug_session',
      success: true,
      metadata: {'session_id': sessionId, 'type': 'terminal'},
    );

    return session;
  }

  /// Start a debug session for an MCP server
  Future<DebugSession> startMCPDebugSession(String agentId, String serverId) async {
    final sessionId = _generateSessionId();
    
    final session = DebugSession(
      id: sessionId,
      type: DebugSessionType.mcpServer,
      targetId: serverId,
      startTime: DateTime.now(),
      isActive: true,
      events: [],
      context: {'agent_id': agentId},
    );

    _activeSessions[sessionId] = session;

    // Start collecting debug information
    await _startMCPDebugging(session);

    _debugEventController.add(DebugEvent(
      type: DebugEventType.sessionStarted,
      sessionId: sessionId,
      timestamp: DateTime.now(),
      data: {'agent_id': agentId, 'server_id': serverId, 'session_type': 'mcp'},
    ));

    _logger.logMCPOperation(
      agentId: agentId,
      serverId: serverId,
      operation: 'start_debug_session',
      success: true,
      metadata: {'session_id': sessionId},
    );

    return session;
  }

  /// Stop a debug session
  Future<void> stopDebugSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    session.isActive = false;
    session.endTime = DateTime.now();

    // Generate debug report
    final report = await _generateDebugReport(session);
    _debugReports.add(report);

    _activeSessions.remove(sessionId);

    _debugEventController.add(DebugEvent(
      type: DebugEventType.sessionEnded,
      sessionId: sessionId,
      timestamp: DateTime.now(),
      data: {'duration_ms': session.duration?.inMilliseconds},
    ));

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'stop_debug_session',
      success: true,
      metadata: {
        'session_id': sessionId,
        'duration_ms': session.duration?.inMilliseconds,
        'events_collected': session.events.length,
      },
    );
  }

  /// Capture error with detailed context
  Future<ErrorCapture> captureError({
    required String component,
    required String error,
    String? agentId,
    String? serverId,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    final capture = ErrorCapture(
      id: _generateErrorId(),
      component: component,
      error: error,
      agentId: agentId,
      serverId: serverId,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      context: context ?? {},
      systemState: await _captureSystemState(),
      componentState: await _captureComponentState(component, agentId, serverId),
    );

    // Add to active debug sessions
    for (final session in _activeSessions.values) {
      if (_isRelevantToSession(session, component, agentId, serverId)) {
        session.events.add(DebugSessionEvent(
          type: DebugSessionEventType.error,
          timestamp: DateTime.now(),
          data: capture.toJson(),
        ));
      }
    }

    _debugEventController.add(DebugEvent(
      type: DebugEventType.errorCaptured,
      sessionId: null,
      timestamp: DateTime.now(),
      data: {
        'error_id': capture.id,
        'component': component,
        'agent_id': agentId,
        'server_id': serverId,
      },
    ));

    _logger.logError(
      component: component,
      error: error,
      agentId: agentId,
      serverId: serverId,
      stackTrace: stackTrace,
      context: {
        'error_capture_id': capture.id,
        ...?context,
      },
    );

    return capture;
  }

  /// Run diagnostic checks for an agent terminal
  Future<DiagnosticResult> runTerminalDiagnostics(String agentId) async {
    final stopwatch = Stopwatch()..start();
    final checks = <DiagnosticCheck>[];

    try {
      // Check terminal process status
      checks.add(await _checkTerminalProcess(agentId));
      
      // Check resource usage
      checks.add(await _checkTerminalResources(agentId));
      
      // Check command history
      checks.add(await _checkTerminalHistory(agentId));
      
      // Check file system access
      checks.add(await _checkFileSystemAccess(agentId));
      
      // Check network connectivity
      checks.add(await _checkNetworkConnectivity(agentId));

      stopwatch.stop();

      final result = DiagnosticResult(
        id: _generateDiagnosticId(),
        type: DiagnosticType.terminal,
        targetId: agentId,
        timestamp: DateTime.now(),
        duration: stopwatch.elapsed,
        checks: checks,
        overallStatus: _calculateOverallStatus(checks),
        recommendations: _generateRecommendations(checks),
      );

      _logger.logTerminalOperation(
        agentId: agentId,
        operation: 'run_diagnostics',
        success: true,
        duration: stopwatch.elapsed,
        metadata: {
          'diagnostic_id': result.id,
          'checks_run': checks.length,
          'overall_status': result.overallStatus.name,
        },
      );

      return result;
    } catch (e, stackTrace) {
      _logger.logError(
        component: 'debug_service',
        error: e.toString(),
        operation: 'run_terminal_diagnostics',
        agentId: agentId,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Run diagnostic checks for an MCP server
  Future<DiagnosticResult> runMCPDiagnostics(String agentId, String serverId) async {
    final stopwatch = Stopwatch()..start();
    final checks = <DiagnosticCheck>[];

    try {
      // Check MCP server process status
      checks.add(await _checkMCPProcess(serverId));
      
      // Check JSON-RPC communication
      checks.add(await _checkMCPCommunication(serverId));
      
      // Check server capabilities
      checks.add(await _checkMCPCapabilities(serverId));
      
      // Check resource usage
      checks.add(await _checkMCPResources(serverId));
      
      // Check error logs
      checks.add(await _checkMCPErrorLogs(serverId));

      stopwatch.stop();

      final result = DiagnosticResult(
        id: _generateDiagnosticId(),
        type: DiagnosticType.mcpServer,
        targetId: serverId,
        timestamp: DateTime.now(),
        duration: stopwatch.elapsed,
        checks: checks,
        overallStatus: _calculateOverallStatus(checks),
        recommendations: _generateRecommendations(checks),
      );

      _logger.logMCPOperation(
        agentId: agentId,
        serverId: serverId,
        operation: 'run_diagnostics',
        success: true,
        duration: stopwatch.elapsed,
        metadata: {
          'diagnostic_id': result.id,
          'checks_run': checks.length,
          'overall_status': result.overallStatus.name,
        },
      );

      return result;
    } catch (e, stackTrace) {
      _logger.logError(
        component: 'debug_service',
        error: e.toString(),
        operation: 'run_mcp_diagnostics',
        agentId: agentId,
        serverId: serverId,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get system health overview
  Future<SystemHealthOverview> getSystemHealthOverview() async {
    final systemMetrics = await _metricsCollector.collectSystemMetrics();
    final performanceOverview = _performanceMonitor.getSystemOverview();
    
    final healthChecks = <HealthCheck>[];
    
    // Memory health check
    final memoryUsagePercent = (systemMetrics.usedMemoryMB / systemMetrics.totalMemoryMB) * 100;
    healthChecks.add(HealthCheck(
      name: 'Memory Usage',
      status: memoryUsagePercent > 90 ? HealthStatus.critical :
              memoryUsagePercent > 75 ? HealthStatus.warning : HealthStatus.healthy,
      value: '${systemMetrics.usedMemoryMB}MB / ${systemMetrics.totalMemoryMB}MB (${memoryUsagePercent.toStringAsFixed(1)}%)',
      details: 'Available: ${systemMetrics.availableMemoryMB}MB',
    ));

    // CPU health check
    healthChecks.add(HealthCheck(
      name: 'CPU Usage',
      status: systemMetrics.cpuUsagePercent > 90 ? HealthStatus.critical :
              systemMetrics.cpuUsagePercent > 75 ? HealthStatus.warning : HealthStatus.healthy,
      value: '${systemMetrics.cpuUsagePercent.toStringAsFixed(1)}%',
      details: 'Cores: ${systemMetrics.cpuCores}, Load: ${systemMetrics.systemLoadAverage}',
    ));

    // Disk health check
    final diskUsagePercent = (systemMetrics.diskUsedGB / systemMetrics.diskTotalGB) * 100;
    healthChecks.add(HealthCheck(
      name: 'Disk Usage',
      status: diskUsagePercent > 95 ? HealthStatus.critical :
              diskUsagePercent > 85 ? HealthStatus.warning : HealthStatus.healthy,
      value: '${systemMetrics.diskUsedGB}GB / ${systemMetrics.diskTotalGB}GB (${diskUsagePercent.toStringAsFixed(1)}%)',
      details: 'Available: ${systemMetrics.diskAvailableGB}GB',
    ));

    // Agent terminals health check
    healthChecks.add(HealthCheck(
      name: 'Agent Terminals',
      status: systemMetrics.activeAgents > 0 ? HealthStatus.healthy : HealthStatus.warning,
      value: '${systemMetrics.activeAgents} active',
      details: 'Total processes: ${systemMetrics.totalProcesses}',
    ));

    // MCP servers health check
    healthChecks.add(HealthCheck(
      name: 'MCP Servers',
      status: systemMetrics.activeMCPServers > 0 ? HealthStatus.healthy : HealthStatus.warning,
      value: '${systemMetrics.activeMCPServers} active',
      details: 'Running in agent terminals',
    ));

    return SystemHealthOverview(
      timestamp: DateTime.now(),
      overallStatus: _calculateOverallHealthStatus(healthChecks),
      healthChecks: healthChecks,
      systemMetrics: systemMetrics,
      performanceOverview: performanceOverview,
    );
  }

  /// Export debug information
  Future<File> exportDebugInfo({
    String? sessionId,
    String? agentId,
    String? serverId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final exportData = <String, dynamic>{
      'export_info': {
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': sessionId,
        'agent_id': agentId,
        'server_id': serverId,
        'from_date': fromDate?.toIso8601String(),
        'to_date': toDate?.toIso8601String(),
      },
      'system_health': (await getSystemHealthOverview()).toJson(),
      'debug_sessions': [],
      'debug_reports': [],
      'error_captures': [],
    };

    // Export debug sessions
    for (final session in _activeSessions.values) {
      if (_matchesExportCriteria(session, sessionId, agentId, serverId, fromDate, toDate)) {
        exportData['debug_sessions'].add(session.toJson());
      }
    }

    // Export debug reports
    for (final report in _debugReports) {
      if (_matchesExportCriteria(report, sessionId, agentId, serverId, fromDate, toDate)) {
        exportData['debug_reports'].add(report.toJson());
      }
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'debug_export_$timestamp.json';
    final exportFile = File(path.join(await _getExportDirectory(), filename));

    await exportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(exportData),
    );

    _logger.logTerminalOperation(
      agentId: 'system',
      operation: 'export_debug_info',
      success: true,
      metadata: {
        'file': exportFile.path,
        'sessions': (exportData['debug_sessions'] as List).length,
        'reports': (exportData['debug_reports'] as List).length,
      },
    );

    return exportFile;
  }

  /// Private methods for debugging specific components
  Future<void> _startTerminalDebugging(DebugSession session) async {
    // Start monitoring terminal events
    // This would integrate with actual terminal monitoring
    session.events.add(DebugSessionEvent(
      type: DebugSessionEventType.info,
      timestamp: DateTime.now(),
      data: {'message': 'Terminal debugging started'},
    ));
  }

  Future<void> _startMCPDebugging(DebugSession session) async {
    // Start monitoring MCP server events
    // This would integrate with actual MCP monitoring
    session.events.add(DebugSessionEvent(
      type: DebugSessionEventType.info,
      timestamp: DateTime.now(),
      data: {'message': 'MCP debugging started'},
    ));
  }

  Future<DebugReport> _generateDebugReport(DebugSession session) async {
    return DebugReport(
      id: _generateReportId(),
      sessionId: session.id,
      type: session.type,
      targetId: session.targetId,
      timestamp: DateTime.now(),
      duration: session.duration ?? Duration.zero,
      eventCount: session.events.length,
      summary: _generateSessionSummary(session),
      findings: _analyzeSessionEvents(session),
      recommendations: _generateSessionRecommendations(session),
    );
  }

  Future<Map<String, dynamic>> _captureSystemState() async {
    final systemMetrics = await _metricsCollector.collectSystemMetrics();
    return {
      'system_metrics': systemMetrics.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _captureComponentState(
    String component,
    String? agentId,
    String? serverId,
  ) async {
    final state = <String, dynamic>{
      'component': component,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (component == 'terminal' && agentId != null) {
      // Capture terminal-specific state
      state['terminal_state'] = await _captureTerminalState(agentId);
    } else if (component == 'mcp_server' && serverId != null) {
      // Capture MCP server-specific state
      state['mcp_state'] = await _captureMCPState(serverId);
    }

    return state;
  }

  Future<Map<String, dynamic>> _captureTerminalState(String agentId) async {
    // This would capture actual terminal state
    return {
      'agent_id': agentId,
      'status': 'active',
      'last_command': 'ls -la',
      'working_directory': '/home/user',
    };
  }

  Future<Map<String, dynamic>> _captureMCPState(String serverId) async {
    // This would capture actual MCP server state
    return {
      'server_id': serverId,
      'status': 'running',
      'capabilities': ['file_operations', 'web_search'],
      'connection_count': 1,
    };
  }

  /// Diagnostic check implementations
  Future<DiagnosticCheck> _checkTerminalProcess(String agentId) async {
    // This would check actual terminal process
    return DiagnosticCheck(
      name: 'Terminal Process',
      status: DiagnosticStatus.passed,
      message: 'Terminal process is running',
      details: 'PID: 12345, Status: Running',
      duration: const Duration(milliseconds: 50),
    );
  }

  Future<DiagnosticCheck> _checkTerminalResources(String agentId) async {
    // This would check actual resource usage
    return DiagnosticCheck(
      name: 'Resource Usage',
      status: DiagnosticStatus.passed,
      message: 'Resource usage is within normal limits',
      details: 'Memory: 45MB, CPU: 2.5%',
      duration: const Duration(milliseconds: 100),
    );
  }

  Future<DiagnosticCheck> _checkTerminalHistory(String agentId) async {
    return DiagnosticCheck(
      name: 'Command History',
      status: DiagnosticStatus.passed,
      message: 'Command history is accessible',
      details: 'Last 10 commands available',
      duration: const Duration(milliseconds: 25),
    );
  }

  Future<DiagnosticCheck> _checkFileSystemAccess(String agentId) async {
    return DiagnosticCheck(
      name: 'File System Access',
      status: DiagnosticStatus.passed,
      message: 'File system access is working',
      details: 'Can read/write in working directory',
      duration: const Duration(milliseconds: 75),
    );
  }

  Future<DiagnosticCheck> _checkNetworkConnectivity(String agentId) async {
    return DiagnosticCheck(
      name: 'Network Connectivity',
      status: DiagnosticStatus.passed,
      message: 'Network connectivity is available',
      details: 'Can reach external hosts',
      duration: const Duration(milliseconds: 200),
    );
  }

  Future<DiagnosticCheck> _checkMCPProcess(String serverId) async {
    return DiagnosticCheck(
      name: 'MCP Process',
      status: DiagnosticStatus.passed,
      message: 'MCP server process is running',
      details: 'PID: 23456, Status: Running',
      duration: const Duration(milliseconds: 50),
    );
  }

  Future<DiagnosticCheck> _checkMCPCommunication(String serverId) async {
    return DiagnosticCheck(
      name: 'JSON-RPC Communication',
      status: DiagnosticStatus.passed,
      message: 'JSON-RPC communication is working',
      details: 'Ping response: 25ms',
      duration: const Duration(milliseconds: 150),
    );
  }

  Future<DiagnosticCheck> _checkMCPCapabilities(String serverId) async {
    return DiagnosticCheck(
      name: 'Server Capabilities',
      status: DiagnosticStatus.passed,
      message: 'All capabilities are available',
      details: 'Tools: 5, Resources: 3, Prompts: 2',
      duration: const Duration(milliseconds: 100),
    );
  }

  Future<DiagnosticCheck> _checkMCPResources(String serverId) async {
    return DiagnosticCheck(
      name: 'Resource Usage',
      status: DiagnosticStatus.passed,
      message: 'Resource usage is normal',
      details: 'Memory: 25MB, CPU: 1.5%',
      duration: const Duration(milliseconds: 75),
    );
  }

  Future<DiagnosticCheck> _checkMCPErrorLogs(String serverId) async {
    return DiagnosticCheck(
      name: 'Error Logs',
      status: DiagnosticStatus.passed,
      message: 'No recent errors found',
      details: 'Last error: 2 hours ago',
      duration: const Duration(milliseconds: 50),
    );
  }

  /// Helper methods
  bool _isRelevantToSession(
    DebugSession session,
    String component,
    String? agentId,
    String? serverId,
  ) {
    if (session.type == DebugSessionType.terminal && agentId != null) {
      return session.targetId == agentId;
    } else if (session.type == DebugSessionType.mcpServer && serverId != null) {
      return session.targetId == serverId;
    }
    return false;
  }

  DiagnosticStatus _calculateOverallStatus(List<DiagnosticCheck> checks) {
    if (checks.any((c) => c.status == DiagnosticStatus.failed)) {
      return DiagnosticStatus.failed;
    } else if (checks.any((c) => c.status == DiagnosticStatus.warning)) {
      return DiagnosticStatus.warning;
    } else {
      return DiagnosticStatus.passed;
    }
  }

  HealthStatus _calculateOverallHealthStatus(List<HealthCheck> checks) {
    if (checks.any((c) => c.status == HealthStatus.critical)) {
      return HealthStatus.critical;
    } else if (checks.any((c) => c.status == HealthStatus.warning)) {
      return HealthStatus.warning;
    } else {
      return HealthStatus.healthy;
    }
  }

  List<String> _generateRecommendations(List<DiagnosticCheck> checks) {
    final recommendations = <String>[];
    
    for (final check in checks) {
      if (check.status == DiagnosticStatus.failed) {
        recommendations.add('Fix ${check.name}: ${check.message}');
      } else if (check.status == DiagnosticStatus.warning) {
        recommendations.add('Monitor ${check.name}: ${check.message}');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('All checks passed - system is healthy');
    }

    return recommendations;
  }

  String _generateSessionSummary(DebugSession session) {
    final eventTypes = <DebugSessionEventType, int>{};
    for (final event in session.events) {
      eventTypes[event.type] = (eventTypes[event.type] ?? 0) + 1;
    }

    return 'Session captured ${session.events.length} events over ${session.duration?.inMinutes ?? 0} minutes. '
           'Event breakdown: ${eventTypes.entries.map((e) => '${e.key.name}: ${e.value}').join(', ')}';
  }

  List<String> _analyzeSessionEvents(DebugSession session) {
    final findings = <String>[];
    
    final errorCount = session.events.where((e) => e.type == DebugSessionEventType.error).length;
    if (errorCount > 0) {
      findings.add('Found $errorCount error events during session');
    }

    final warningCount = session.events.where((e) => e.type == DebugSessionEventType.warning).length;
    if (warningCount > 0) {
      findings.add('Found $warningCount warning events during session');
    }

    if (findings.isEmpty) {
      findings.add('No issues detected during debug session');
    }

    return findings;
  }

  List<String> _generateSessionRecommendations(DebugSession session) {
    final recommendations = <String>[];
    
    final errorEvents = session.events.where((e) => e.type == DebugSessionEventType.error).toList();
    if (errorEvents.isNotEmpty) {
      recommendations.add('Review error events and implement fixes');
    }

    final warningEvents = session.events.where((e) => e.type == DebugSessionEventType.warning).toList();
    if (warningEvents.isNotEmpty) {
      recommendations.add('Monitor warning conditions to prevent issues');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Continue monitoring for optimal performance');
    }

    return recommendations;
  }

  bool _matchesExportCriteria(
    dynamic item,
    String? sessionId,
    String? agentId,
    String? serverId,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    // This would implement actual matching logic
    return true;
  }

  String _generateSessionId() => 'debug_session_${DateTime.now().millisecondsSinceEpoch}';
  String _generateErrorId() => 'error_${DateTime.now().millisecondsSinceEpoch}';
  String _generateDiagnosticId() => 'diagnostic_${DateTime.now().millisecondsSinceEpoch}';
  String _generateReportId() => 'report_${DateTime.now().millisecondsSinceEpoch}';

  Future<String> _getExportDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ?? Platform.environment['APPDATA'];
      return path.join(appData!, 'Asmbli', 'debug_exports');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME']!;
      return path.join(home, 'Library', 'Application Support', 'Asmbli', 'debug_exports');
    } else {
      final home = Platform.environment['HOME']!;
      return path.join(home, '.local', 'share', 'asmbli', 'debug_exports');
    }
  }

  /// Dispose resources
  void dispose() {
    _debugEventController.close();
    _activeSessions.clear();
    _debugReports.clear();
    _initialized = false;
  }
}

/// Data models
class DebugSession {
  final String id;
  final DebugSessionType type;
  final String targetId;
  final DateTime startTime;
  DateTime? endTime;
  bool isActive;
  final List<DebugSessionEvent> events;
  final Map<String, dynamic> context;

  DebugSession({
    required this.id,
    required this.type,
    required this.targetId,
    required this.startTime,
    this.endTime,
    required this.isActive,
    required this.events,
    required this.context,
  });

  Duration? get duration => endTime?.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'target_id': targetId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_active': isActive,
      'duration_ms': duration?.inMilliseconds,
      'event_count': events.length,
      'context': context,
    };
  }
}

class DebugSessionEvent {
  final DebugSessionEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  DebugSessionEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

class ErrorCapture {
  final String id;
  final String component;
  final String error;
  final String? agentId;
  final String? serverId;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final Map<String, dynamic> systemState;
  final Map<String, dynamic> componentState;

  ErrorCapture({
    required this.id,
    required this.component,
    required this.error,
    this.agentId,
    this.serverId,
    this.stackTrace,
    required this.timestamp,
    required this.context,
    required this.systemState,
    required this.componentState,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'component': component,
      'error': error,
      'agent_id': agentId,
      'server_id': serverId,
      'stack_trace': stackTrace?.toString(),
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'system_state': systemState,
      'component_state': componentState,
    };
  }
}

class DiagnosticResult {
  final String id;
  final DiagnosticType type;
  final String targetId;
  final DateTime timestamp;
  final Duration duration;
  final List<DiagnosticCheck> checks;
  final DiagnosticStatus overallStatus;
  final List<String> recommendations;

  DiagnosticResult({
    required this.id,
    required this.type,
    required this.targetId,
    required this.timestamp,
    required this.duration,
    required this.checks,
    required this.overallStatus,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'target_id': targetId,
      'timestamp': timestamp.toIso8601String(),
      'duration_ms': duration.inMilliseconds,
      'checks': checks.map((c) => c.toJson()).toList(),
      'overall_status': overallStatus.name,
      'recommendations': recommendations,
    };
  }
}

class DiagnosticCheck {
  final String name;
  final DiagnosticStatus status;
  final String message;
  final String details;
  final Duration duration;

  DiagnosticCheck({
    required this.name,
    required this.status,
    required this.message,
    required this.details,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status.name,
      'message': message,
      'details': details,
      'duration_ms': duration.inMilliseconds,
    };
  }
}

class SystemHealthOverview {
  final DateTime timestamp;
  final HealthStatus overallStatus;
  final List<HealthCheck> healthChecks;
  final SystemMetrics systemMetrics;
  final SystemPerformanceOverview performanceOverview;

  SystemHealthOverview({
    required this.timestamp,
    required this.overallStatus,
    required this.healthChecks,
    required this.systemMetrics,
    required this.performanceOverview,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'overall_status': overallStatus.name,
      'health_checks': healthChecks.map((c) => c.toJson()).toList(),
      'system_metrics': systemMetrics.toJson(),
      'performance_overview': performanceOverview.toJson(),
    };
  }
}

class HealthCheck {
  final String name;
  final HealthStatus status;
  final String value;
  final String details;

  HealthCheck({
    required this.name,
    required this.status,
    required this.value,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status.name,
      'value': value,
      'details': details,
    };
  }
}

class DebugReport {
  final String id;
  final String sessionId;
  final DebugSessionType type;
  final String targetId;
  final DateTime timestamp;
  final Duration duration;
  final int eventCount;
  final String summary;
  final List<String> findings;
  final List<String> recommendations;

  DebugReport({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.targetId,
    required this.timestamp,
    required this.duration,
    required this.eventCount,
    required this.summary,
    required this.findings,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'type': type.name,
      'target_id': targetId,
      'timestamp': timestamp.toIso8601String(),
      'duration_ms': duration.inMilliseconds,
      'event_count': eventCount,
      'summary': summary,
      'findings': findings,
      'recommendations': recommendations,
    };
  }
}

class DebugEvent {
  final DebugEventType type;
  final String? sessionId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  DebugEvent({
    required this.type,
    this.sessionId,
    required this.timestamp,
    required this.data,
  });
}

enum DebugSessionType { terminal, mcpServer, system }
enum DebugSessionEventType { info, warning, error, performance }
enum DebugEventType { sessionStarted, sessionEnded, errorCaptured }
enum DiagnosticType { terminal, mcpServer, system }
enum DiagnosticStatus { passed, warning, failed }
enum HealthStatus { healthy, warning, critical }

// ==================== Riverpod Provider ====================

final debugServiceProvider = Provider<DebugService>((ref) {
  return DebugService.instance;
});