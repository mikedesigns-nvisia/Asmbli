import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/security_context.dart';
import 'security_policy_engine.dart';
import 'file_system_access_control.dart';
import 'network_permission_manager.dart';
import 'api_access_control.dart';
import 'command_security_validator.dart';

/// Integrated security service that coordinates all security components
class IntegratedSecurityService {
  final SecurityPolicyEngine _policyEngine = SecurityPolicyEngine();
  final FileSystemAccessControl _fileSystemControl = FileSystemAccessControl();
  final NetworkPermissionManager _networkManager = NetworkPermissionManager();
  final APIAccessControl _apiControl = APIAccessControl();
  final CommandSecurityValidator _commandValidator = CommandSecurityValidator();
  
  final Map<String, SecurityContext> _agentContexts = {};
  final SecurityEventAggregator _eventAggregator = SecurityEventAggregator();

  /// Initialize the security service
  Future<void> initialize() async {
    debugPrint('Initializing Integrated Security Service');
    
    // Initialize all security components
    await _apiControl.registerAgent('system', SecurityContext.defaultForAgent('system'));
    
    debugPrint('Integrated Security Service initialized successfully');
  }

  /// Register an agent with comprehensive security setup
  Future<void> registerAgent(String agentId, {SecurityContext? customContext}) async {
    final context = customContext ?? SecurityContext.defaultForAgent(agentId);
    _agentContexts[agentId] = context;

    // Register with all security components
    _policyEngine.registerAgent(agentId, context);
    _fileSystemControl.registerAgent(agentId, context);
    _networkManager.registerAgent(agentId, context);
    await _apiControl.registerAgent(agentId, context);
    _commandValidator.registerAgent(agentId, context);

    _eventAggregator.logEvent(SecurityEvent(
      agentId: agentId,
      type: SecurityEventType.agentRegistered,
      message: 'Agent registered with security service',
      timestamp: DateTime.now(),
    ));

    debugPrint('Agent $agentId registered with integrated security service');
  }

  /// Update agent security context across all components
  Future<void> updateAgentContext(String agentId, SecurityContext context) async {
    _agentContexts[agentId] = context;

    // Update all security components
    _policyEngine.updateAgentContext(agentId, context);
    _fileSystemControl.updateAgentContext(agentId, context);
    _networkManager.updateAgentContext(agentId, context);
    await _apiControl.updateAgentContext(agentId, context);
    _commandValidator.updateAgentContext(agentId, context);

    _eventAggregator.logEvent(SecurityEvent(
      agentId: agentId,
      type: SecurityEventType.contextUpdated,
      message: 'Agent security context updated',
      timestamp: DateTime.now(),
    ));

    debugPrint('Agent $agentId security context updated');
  }

  /// Unregister an agent from all security components
  Future<void> unregisterAgent(String agentId) async {
    // Unregister from all security components
    _policyEngine.unregisterAgent(agentId);
    _fileSystemControl.unregisterAgent(agentId);
    _networkManager.unregisterAgent(agentId);
    await _apiControl.unregisterAgent(agentId);
    _commandValidator.unregisterAgent(agentId);

    _agentContexts.remove(agentId);

    _eventAggregator.logEvent(SecurityEvent(
      agentId: agentId,
      type: SecurityEventType.agentUnregistered,
      message: 'Agent unregistered from security service',
      timestamp: DateTime.now(),
    ));

    debugPrint('Agent $agentId unregistered from integrated security service');
  }

  /// Comprehensive command validation
  Future<ComprehensiveSecurityResult> validateCommand(
    String agentId,
    String command, {
    Map<String, String> environment = const {},
    String? workingDirectory,
  }) async {
    try {
      // Step 1: Policy engine validation
      final policyResult = await _policyEngine.validateCommand(
        agentId,
        command,
        environment: environment,
        workingDirectory: workingDirectory,
      );

      if (!policyResult.isAllowed) {
        return ComprehensiveSecurityResult.fromPolicyResult(policyResult);
      }

      // Step 2: Command security validation
      final commandResult = await _commandValidator.validateCommand(
        agentId,
        command,
        environment: environment,
        workingDirectory: workingDirectory,
      );

      if (!commandResult.isAllowed) {
        return ComprehensiveSecurityResult.fromCommandResult(commandResult);
      }

      // Step 3: Check for file system access in command
      final fileAccessChecks = await _validateFileAccessInCommand(agentId, command, workingDirectory);
      if (!fileAccessChecks.isAllowed) {
        return fileAccessChecks;
      }

      // Step 4: Check for network access in command
      final networkAccessChecks = await _validateNetworkAccessInCommand(agentId, command);
      if (!networkAccessChecks.isAllowed) {
        return networkAccessChecks;
      }

      // All validations passed
      final finalRiskLevel = _calculateOverallRiskLevel([
        policyResult.riskLevel,
        commandResult.riskLevel,
      ]);

      final requiresApproval = policyResult.requiresApproval || 
                              commandResult.requiresApproval ||
                              commandResult.isPendingApproval;

      return ComprehensiveSecurityResult.allowed(
        riskLevel: finalRiskLevel,
        requiresApproval: requiresApproval,
        approvalId: commandResult.approvalId,
        monitoringLevel: _calculateOverallMonitoringLevel([
          policyResult.monitoringLevel,
          commandResult.monitoringLevel,
        ]),
        validationDetails: {
          'policy': policyResult.reason,
          'command': commandResult.reason,
        },
      );

    } catch (e) {
      _eventAggregator.logEvent(SecurityEvent(
        agentId: agentId,
        type: SecurityEventType.validationError,
        message: 'Command validation error: $e',
        timestamp: DateTime.now(),
      ));

      return ComprehensiveSecurityResult.denied(
        reason: 'Security validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Validate file access with comprehensive checks
  Future<ComprehensiveSecurityResult> validateFileAccess(
    String agentId,
    String filePath, {
    required FileAccessType accessType,
    bool createIfNotExists = false,
  }) async {
    try {
      // File system access control validation
      final fileResult = await _fileSystemControl.checkAccess(
        agentId,
        filePath,
        accessType: accessType,
        createIfNotExists: createIfNotExists,
      );

      if (!fileResult.isAllowed) {
        return ComprehensiveSecurityResult.fromFileResult(fileResult);
      }

      return ComprehensiveSecurityResult.allowed(
        riskLevel: fileResult.riskLevel,
        requiresApproval: fileResult.requiresApproval,
        monitoringLevel: fileResult.monitoringLevel,
        validationDetails: {
          'file_access': fileResult.reason,
        },
      );

    } catch (e) {
      return ComprehensiveSecurityResult.denied(
        reason: 'File access validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Validate network access with comprehensive checks
  Future<ComprehensiveSecurityResult> validateNetworkAccess(
    String agentId,
    String host,
    int port, {
    String protocol = 'tcp',
  }) async {
    try {
      // Network permission validation
      final networkResult = await _networkManager.checkNetworkPermission(
        agentId,
        host,
        port,
        protocol: protocol,
      );

      if (!networkResult.isAllowed) {
        return ComprehensiveSecurityResult.fromNetworkResult(networkResult);
      }

      return ComprehensiveSecurityResult.allowed(
        riskLevel: networkResult.riskLevel,
        requiresApproval: networkResult.requiresApproval,
        monitoringLevel: networkResult.monitoringLevel,
        validationDetails: {
          'network_access': networkResult.reason,
        },
      );

    } catch (e) {
      return ComprehensiveSecurityResult.denied(
        reason: 'Network access validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Validate API access with comprehensive checks
  Future<ComprehensiveSecurityResult> validateAPIAccess(
    String agentId,
    String provider,
    String model, {
    int estimatedTokens = 0,
    Map<String, dynamic> requestMetadata = const {},
  }) async {
    try {
      // API access control validation
      final apiResult = await _apiControl.validateAPIAccess(
        agentId,
        provider,
        model,
        estimatedTokens: estimatedTokens,
        requestMetadata: requestMetadata,
      );

      if (!apiResult.isAllowed) {
        return ComprehensiveSecurityResult.fromAPIResult(apiResult);
      }

      return ComprehensiveSecurityResult.allowed(
        riskLevel: apiResult.riskLevel,
        requiresApproval: apiResult.requiresApproval,
        monitoringLevel: apiResult.monitoringLevel,
        validationDetails: {
          'api_access': apiResult.reason,
        },
      );

    } catch (e) {
      return ComprehensiveSecurityResult.denied(
        reason: 'API access validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Make secure API call with full security validation
  Future<APICallResult> makeSecureAPICall(
    String agentId,
    String provider,
    String model,
    Map<String, dynamic> request, {
    Map<String, String> additionalHeaders = const {},
  }) async {
    return await _apiControl.makeSecureAPICall(
      agentId,
      provider,
      model,
      request,
      additionalHeaders: additionalHeaders,
    );
  }

  /// Create secure file wrapper
  Future<SecureFile?> createSecureFile(
    String agentId,
    String filePath, {
    FileAccessType accessType = FileAccessType.readWrite,
  }) async {
    return await _fileSystemControl.createSecureFile(
      agentId,
      filePath,
      accessType: accessType,
    );
  }

  /// Create secure network connection
  Future<SecureNetworkConnection?> createSecureConnection(
    String agentId,
    String host,
    int port, {
    String protocol = 'tcp',
    Duration? timeout,
  }) async {
    return await _networkManager.createSecureConnection(
      agentId,
      host,
      port,
      protocol: protocol,
      timeout: timeout,
    );
  }

  /// Get comprehensive security dashboard for an agent
  Future<SecurityDashboard> getSecurityDashboard(String agentId) async {
    final context = _agentContexts[agentId];
    if (context == null) {
      return SecurityDashboard.empty(agentId);
    }

    // Gather statistics from all components
    final policyAuditLog = _policyEngine.getAuditLog(agentId);
    final fileAccessStats = _fileSystemControl.getAccessStats(agentId);
    final networkStats = _networkManager.getNetworkStats(agentId);
    final apiUsageStats = _apiControl.getAPIUsageStats(agentId);
    final commandValidationStats = _commandValidator.getValidationStats(agentId);

    // Get recent security events
    final recentEvents = _eventAggregator.getEventsForAgent(agentId, limit: 100);

    return SecurityDashboard(
      agentId: agentId,
      securityContext: context,
      policyAuditLog: policyAuditLog,
      fileAccessStats: fileAccessStats,
      networkStats: networkStats,
      apiUsageStats: apiUsageStats,
      commandValidationStats: commandValidationStats,
      recentEvents: recentEvents,
      overallRiskLevel: _calculateAgentRiskLevel(agentId),
      lastActivity: _getLastActivityTime(agentId),
    );
  }

  /// Get all security events
  List<SecurityEvent> getAllSecurityEvents({int limit = 1000}) {
    return _eventAggregator.getAllEvents(limit: limit);
  }

  /// Get security events for a specific agent
  List<SecurityEvent> getAgentSecurityEvents(String agentId, {int limit = 100}) {
    return _eventAggregator.getEventsForAgent(agentId, limit: limit);
  }

  /// Validate file access patterns in command
  Future<ComprehensiveSecurityResult> _validateFileAccessInCommand(
    String agentId,
    String command,
    String? workingDirectory,
  ) async {
    // Extract potential file paths from command
    final filePaths = _extractFilePathsFromCommand(command);
    
    for (final filePath in filePaths) {
      final accessType = _determineAccessTypeFromCommand(command, filePath);
      final result = await validateFileAccess(agentId, filePath, accessType: accessType);
      
      if (!result.isAllowed) {
        return result;
      }
    }

    return ComprehensiveSecurityResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
      validationDetails: {'file_paths_checked': filePaths.length.toString()},
    );
  }

  /// Validate network access patterns in command
  Future<ComprehensiveSecurityResult> _validateNetworkAccessInCommand(
    String agentId,
    String command,
  ) async {
    // Extract potential network hosts from command
    final networkTargets = _extractNetworkTargetsFromCommand(command);
    
    for (final target in networkTargets) {
      final result = await validateNetworkAccess(
        agentId,
        target.host,
        target.port,
        protocol: target.protocol,
      );
      
      if (!result.isAllowed) {
        return result;
      }
    }

    return ComprehensiveSecurityResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
      validationDetails: {'network_targets_checked': networkTargets.length.toString()},
    );
  }

  /// Extract file paths from command
  List<String> _extractFilePathsFromCommand(String command) {
    final filePaths = <String>[];
    final parts = command.split(' ');
    
    for (final part in parts) {
      if (_looksLikeFilePath(part)) {
        String cleanPart = part;
        if ((cleanPart.startsWith('"') && cleanPart.endsWith('"')) ||
            (cleanPart.startsWith("'") && cleanPart.endsWith("'"))) {
          cleanPart = cleanPart.substring(1, cleanPart.length - 1);
        }
        filePaths.add(cleanPart);
      }
    }
    
    return filePaths;
  }

  /// Extract network targets from command
  List<NetworkTarget> _extractNetworkTargetsFromCommand(String command) {
    final targets = <NetworkTarget>[];
    
    // Look for URLs
    final urlPattern = RegExp(r'https?://([^/\s:]+)(?::(\d+))?');
    final urlMatches = urlPattern.allMatches(command);
    
    for (final match in urlMatches) {
      final host = match.group(1)!;
      final port = int.tryParse(match.group(2) ?? '') ?? (command.contains('https://') ? 443 : 80);
      targets.add(NetworkTarget(host: host, port: port, protocol: 'tcp'));
    }
    
    // Look for host:port patterns
    final hostPortPattern = RegExp(r'(\w+(?:\.\w+)*):(\d+)');
    final hostPortMatches = hostPortPattern.allMatches(command);
    
    for (final match in hostPortMatches) {
      final host = match.group(1)!;
      final port = int.parse(match.group(2)!);
      targets.add(NetworkTarget(host: host, port: port, protocol: 'tcp'));
    }
    
    return targets;
  }

  /// Determine file access type from command
  FileAccessType _determineAccessTypeFromCommand(String command, String filePath) {
    final lowerCommand = command.toLowerCase();
    
    if (lowerCommand.startsWith('rm ') || lowerCommand.startsWith('del ')) {
      return FileAccessType.delete;
    } else if (lowerCommand.startsWith('mkdir ')) {
      return FileAccessType.directory;
    } else if (lowerCommand.contains('>') || lowerCommand.startsWith('echo ') || 
               lowerCommand.startsWith('cp ') || lowerCommand.startsWith('mv ')) {
      return FileAccessType.write;
    } else if (lowerCommand.startsWith('chmod ') || lowerCommand.startsWith('chown ')) {
      return FileAccessType.execute;
    } else {
      return FileAccessType.read;
    }
  }

  /// Check if string looks like a file path
  bool _looksLikeFilePath(String str) {
    return str.contains('/') || str.contains('\\') || 
           str.startsWith('./') || str.startsWith('../') ||
           str.contains('.') && !str.contains(' ');
  }

  /// Calculate overall risk level from multiple risk levels
  RiskLevel _calculateOverallRiskLevel(List<RiskLevel> riskLevels) {
    if (riskLevels.isEmpty) return RiskLevel.low;
    return riskLevels.reduce((a, b) => a.index > b.index ? a : b);
  }

  /// Calculate overall monitoring level from multiple monitoring levels
  MonitoringLevel _calculateOverallMonitoringLevel(List<MonitoringLevel> monitoringLevels) {
    if (monitoringLevels.isEmpty) return MonitoringLevel.basic;
    return monitoringLevels.reduce((a, b) => a.index > b.index ? a : b);
  }

  /// Calculate agent risk level based on recent activity
  RiskLevel _calculateAgentRiskLevel(String agentId) {
    final events = _eventAggregator.getEventsForAgent(agentId, limit: 50);
    
    // Count high-risk events in the last hour
    final recentHighRiskEvents = events.where((event) =>
        DateTime.now().difference(event.timestamp) < const Duration(hours: 1) &&
        (event.type == SecurityEventType.commandBlocked ||
         event.type == SecurityEventType.fileAccessDenied ||
         event.type == SecurityEventType.networkAccessDenied ||
         event.type == SecurityEventType.apiAccessDenied)).length;

    if (recentHighRiskEvents > 5) {
      return RiskLevel.high;
    } else if (recentHighRiskEvents > 2) {
      return RiskLevel.medium;
    } else {
      return RiskLevel.low;
    }
  }

  /// Get last activity time for agent
  DateTime? _getLastActivityTime(String agentId) {
    final events = _eventAggregator.getEventsForAgent(agentId, limit: 1);
    return events.isNotEmpty ? events.first.timestamp : null;
  }
}

/// Comprehensive security result that combines all security validations
class ComprehensiveSecurityResult {
  final bool isAllowed;
  final String reason;
  final RiskLevel riskLevel;
  final bool requiresApproval;
  final MonitoringLevel monitoringLevel;
  final String? approvalId;
  final Map<String, String> validationDetails;

  const ComprehensiveSecurityResult._({
    required this.isAllowed,
    required this.reason,
    required this.riskLevel,
    this.requiresApproval = false,
    this.monitoringLevel = MonitoringLevel.basic,
    this.approvalId,
    this.validationDetails = const {},
  });

  factory ComprehensiveSecurityResult.allowed({
    required RiskLevel riskLevel,
    bool requiresApproval = false,
    MonitoringLevel monitoringLevel = MonitoringLevel.basic,
    String? approvalId,
    Map<String, String> validationDetails = const {},
  }) {
    return ComprehensiveSecurityResult._(
      isAllowed: true,
      reason: 'Security validation passed',
      riskLevel: riskLevel,
      requiresApproval: requiresApproval,
      monitoringLevel: monitoringLevel,
      approvalId: approvalId,
      validationDetails: validationDetails,
    );
  }

  factory ComprehensiveSecurityResult.denied({
    required String reason,
    required RiskLevel riskLevel,
    Map<String, String> validationDetails = const {},
  }) {
    return ComprehensiveSecurityResult._(
      isAllowed: false,
      reason: reason,
      riskLevel: riskLevel,
      validationDetails: validationDetails,
    );
  }

  factory ComprehensiveSecurityResult.fromPolicyResult(SecurityValidationResult result) {
    return ComprehensiveSecurityResult._(
      isAllowed: result.isAllowed,
      reason: result.reason,
      riskLevel: result.riskLevel,
      requiresApproval: result.requiresApproval,
      monitoringLevel: result.monitoringLevel,
      validationDetails: {'policy': result.reason},
    );
  }

  factory ComprehensiveSecurityResult.fromCommandResult(CommandValidationResult result) {
    return ComprehensiveSecurityResult._(
      isAllowed: result.isAllowed,
      reason: result.reason,
      riskLevel: result.riskLevel,
      requiresApproval: result.requiresApproval,
      monitoringLevel: result.monitoringLevel,
      approvalId: result.approvalId,
      validationDetails: {'command': result.reason},
    );
  }

  factory ComprehensiveSecurityResult.fromFileResult(FileAccessResult result) {
    return ComprehensiveSecurityResult._(
      isAllowed: result.isAllowed,
      reason: result.reason,
      riskLevel: result.riskLevel,
      requiresApproval: result.requiresApproval,
      monitoringLevel: result.monitoringLevel,
      validationDetails: {'file_access': result.reason},
    );
  }

  factory ComprehensiveSecurityResult.fromNetworkResult(NetworkPermissionResult result) {
    return ComprehensiveSecurityResult._(
      isAllowed: result.isAllowed,
      reason: result.reason,
      riskLevel: result.riskLevel,
      requiresApproval: result.requiresApproval,
      monitoringLevel: result.monitoringLevel,
      validationDetails: {'network': result.reason},
    );
  }

  factory ComprehensiveSecurityResult.fromAPIResult(APIAccessResult result) {
    return ComprehensiveSecurityResult._(
      isAllowed: result.isAllowed,
      reason: result.reason,
      riskLevel: result.riskLevel,
      requiresApproval: result.requiresApproval,
      monitoringLevel: result.monitoringLevel,
      validationDetails: {'api': result.reason},
    );
  }
}

/// Security dashboard for comprehensive monitoring
class SecurityDashboard {
  final String agentId;
  final SecurityContext securityContext;
  final List<SecurityAuditEvent> policyAuditLog;
  final FileAccessStats fileAccessStats;
  final NetworkStats networkStats;
  final APIUsageStats apiUsageStats;
  final CommandValidationStats commandValidationStats;
  final List<SecurityEvent> recentEvents;
  final RiskLevel overallRiskLevel;
  final DateTime? lastActivity;

  const SecurityDashboard({
    required this.agentId,
    required this.securityContext,
    required this.policyAuditLog,
    required this.fileAccessStats,
    required this.networkStats,
    required this.apiUsageStats,
    required this.commandValidationStats,
    required this.recentEvents,
    required this.overallRiskLevel,
    this.lastActivity,
  });

  factory SecurityDashboard.empty(String agentId) {
    return SecurityDashboard(
      agentId: agentId,
      securityContext: SecurityContext.defaultForAgent(agentId),
      policyAuditLog: [],
      fileAccessStats: FileAccessStats.empty(),
      networkStats: NetworkStats.empty(),
      apiUsageStats: APIUsageStats.empty(),
      commandValidationStats: CommandValidationStats.empty(),
      recentEvents: [],
      overallRiskLevel: RiskLevel.low,
    );
  }
}

/// Network target for command analysis
class NetworkTarget {
  final String host;
  final int port;
  final String protocol;

  const NetworkTarget({
    required this.host,
    required this.port,
    required this.protocol,
  });
}

/// Security event aggregator
class SecurityEventAggregator {
  final List<SecurityEvent> _events = [];

  void logEvent(SecurityEvent event) {
    _events.add(event);
    
    // Keep only last 10000 events
    if (_events.length > 10000) {
      _events.removeRange(0, _events.length - 10000);
    }

    if (kDebugMode) {
      debugPrint('Security Event [${event.agentId}]: ${event.type.name} - ${event.message}');
    }
  }

  List<SecurityEvent> getAllEvents({int limit = 1000}) {
    final events = List<SecurityEvent>.from(_events);
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events.take(limit).toList();
  }

  List<SecurityEvent> getEventsForAgent(String agentId, {int limit = 100}) {
    final agentEvents = _events.where((event) => event.agentId == agentId).toList();
    agentEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return agentEvents.take(limit).toList();
  }
}

/// Security event
class SecurityEvent {
  final String agentId;
  final SecurityEventType type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const SecurityEvent({
    required this.agentId,
    required this.type,
    required this.message,
    required this.timestamp,
    this.metadata = const {},
  });

  /// Get security context for an agent
  Future<SecurityContext?> getAgentSecurityContext(String agentId) async {
    return _agentContexts[agentId];
  }

  /// Update security context for an agent
  Future<void> updateAgentSecurityContext(String agentId, SecurityContext context) async {
    _agentContexts[agentId] = context;

    // Update all security components
    _policyEngine.updateAgentContext(agentId, context);
    _fileSystemControl.updateAgentContext(agentId, context);
    _networkManager.updateAgentContext(agentId, context);
    await _apiControl.updateAgentContext(agentId, context);
    _commandValidator.updateAgentContext(agentId, context);

    _eventAggregator.logEvent(SecurityEvent(
      agentId: agentId,
      type: SecurityEventType.contextUpdated,
      message: 'Security context updated for agent',
      timestamp: DateTime.now(),
    ));

    debugPrint('Security context updated for agent $agentId');
  }

  /// Get global security context
  Future<SecurityContext?> getGlobalSecurityContext() async {
    return _agentContexts['global'];
  }

  /// Update global security context
  Future<void> updateGlobalSecurityContext(SecurityContext context) async {
    await updateAgentSecurityContext('global', context);
  }
}

/// Security event types
enum SecurityEventType {
  agentRegistered,
  agentUnregistered,
  contextUpdated,
  commandAllowed,
  commandBlocked,
  fileAccessAllowed,
  fileAccessDenied,
  networkAccessAllowed,
  networkAccessDenied,
  apiAccessAllowed,
  apiAccessDenied,
  validationError,
}

/// Import required enums and classes from other services
// These would normally be imported, but for completeness they're redefined here

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

enum MonitoringLevel {
  basic,
  enhanced,
  comprehensive,
}