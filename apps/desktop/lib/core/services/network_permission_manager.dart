import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/security_context.dart';

/// Network permission management service for agent operations
class NetworkPermissionManager {
  final Map<String, SecurityContext> _agentContexts = {};
  final Map<String, NetworkMonitor> _networkMonitors = {};
  final Map<String, Set<NetworkConnection>> _activeConnections = {};
  final NetworkThreatIntelligence _threatIntelligence = NetworkThreatIntelligence();

  /// Register an agent with its security context
  void registerAgent(String agentId, SecurityContext context) {
    _agentContexts[agentId] = context;
    _networkMonitors[agentId] = NetworkMonitor(agentId);
    _activeConnections[agentId] = <NetworkConnection>{};
  }

  /// Update agent security context
  void updateAgentContext(String agentId, SecurityContext context) {
    _agentContexts[agentId] = context;
  }

  /// Remove agent from network permission management
  void unregisterAgent(String agentId) {
    // Close all active connections
    final connections = _activeConnections[agentId];
    if (connections != null) {
      for (final connection in connections) {
        connection.close();
      }
    }

    _agentContexts.remove(agentId);
    _networkMonitors.remove(agentId);
    _activeConnections.remove(agentId);
  }

  /// Check if agent can make a network connection
  Future<NetworkPermissionResult> checkNetworkPermission(
    String agentId,
    String host,
    int port, {
    String protocol = 'tcp',
    NetworkConnectionType connectionType = NetworkConnectionType.outbound,
  }) async {
    final context = _agentContexts[agentId];
    if (context == null) {
      return NetworkPermissionResult.denied(
        reason: 'No security context found for agent',
        riskLevel: RiskLevel.high,
      );
    }

    try {
      // Check if network access is enabled
      if (!context.terminalPermissions.canAccessNetwork) {
        _logNetworkAttempt(agentId, host, port, protocol, false, 'Network access disabled');
        return NetworkPermissionResult.denied(
          reason: 'Network access is disabled for this agent',
          riskLevel: RiskLevel.medium,
        );
      }

      // Validate host format
      final hostValidation = _validateHost(host);
      if (!hostValidation.isValid) {
        _logNetworkAttempt(agentId, host, port, protocol, false, hostValidation.reason);
        return NetworkPermissionResult.denied(
          reason: hostValidation.reason,
          riskLevel: RiskLevel.medium,
        );
      }

      // Check against allowed hosts
      if (!context.isNetworkHostAllowed(host)) {
        _logNetworkAttempt(agentId, host, port, protocol, false, 'Host not in allowed list');
        return NetworkPermissionResult.denied(
          reason: 'Network access not permitted to host: $host',
          riskLevel: RiskLevel.medium,
        );
      }

      // Check port restrictions
      final portValidation = _validatePort(port, protocol);
      if (!portValidation.isAllowed) {
        _logNetworkAttempt(agentId, host, port, protocol, false, portValidation.reason);
        return portValidation;
      }

      // Check connection limits
      final connectionLimitCheck = _checkConnectionLimits(agentId, context);
      if (!connectionLimitCheck.isAllowed) {
        _logNetworkAttempt(agentId, host, port, protocol, false, connectionLimitCheck.reason);
        return connectionLimitCheck;
      }

      // Check threat intelligence
      final threatCheck = await _checkThreatIntelligence(host, port);
      if (!threatCheck.isAllowed) {
        _logNetworkAttempt(agentId, host, port, protocol, false, threatCheck.reason);
        return threatCheck;
      }

      // Check for suspicious patterns
      final suspiciousCheck = _checkSuspiciousPatterns(host, port, protocol);
      if (suspiciousCheck.requiresApproval) {
        _logNetworkAttempt(agentId, host, port, protocol, true, 'Suspicious pattern detected');
        return NetworkPermissionResult.allowed(
          riskLevel: RiskLevel.high,
          requiresApproval: true,
          monitoringLevel: MonitoringLevel.comprehensive,
        );
      }

      // All checks passed
      _logNetworkAttempt(agentId, host, port, protocol, true, 'Network access granted');
      
      return NetworkPermissionResult.allowed(
        riskLevel: _calculateNetworkRiskLevel(host, port, protocol),
        requiresApproval: false,
        monitoringLevel: _getNetworkMonitoringLevel(host, port, protocol),
      );

    } catch (e) {
      _logNetworkAttempt(agentId, host, port, protocol, false, 'Permission check error: $e');
      return NetworkPermissionResult.denied(
        reason: 'Network permission validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Create a secure network connection
  Future<SecureNetworkConnection?> createSecureConnection(
    String agentId,
    String host,
    int port, {
    String protocol = 'tcp',
    Duration? timeout,
  }) async {
    final permissionResult = await checkNetworkPermission(agentId, host, port, protocol: protocol);
    
    if (!permissionResult.isAllowed) {
      return null;
    }

    try {
      final connection = await SecureNetworkConnection.create(
        agentId: agentId,
        host: host,
        port: port,
        protocol: protocol,
        timeout: timeout ?? const Duration(seconds: 30),
        monitor: _networkMonitors[agentId]!,
        permissionManager: this,
      );

      // Track active connection
      _activeConnections[agentId]?.add(connection);
      
      return connection;
    } catch (e) {
      _logNetworkAttempt(agentId, host, port, protocol, false, 'Connection creation failed: $e');
      return null;
    }
  }

  /// Get network statistics for an agent
  NetworkStats getNetworkStats(String agentId) {
    final monitor = _networkMonitors[agentId];
    if (monitor == null) {
      return NetworkStats.empty();
    }

    return monitor.getStats();
  }

  /// Get network access logs for an agent
  List<NetworkAccessLog> getNetworkLogs(String agentId) {
    final monitor = _networkMonitors[agentId];
    if (monitor == null) {
      return [];
    }

    return monitor.getLogs();
  }

  /// Get active connections for an agent
  List<NetworkConnection> getActiveConnections(String agentId) {
    final connections = _activeConnections[agentId];
    if (connections == null) {
      return [];
    }

    return connections.where((conn) => !conn.isClosed).toList();
  }

  /// Close all connections for an agent
  Future<void> closeAllConnections(String agentId) async {
    final connections = _activeConnections[agentId];
    if (connections != null) {
      for (final connection in connections) {
        await connection.close();
      }
      connections.clear();
    }
  }

  /// Validate host format and security
  HostValidationResult _validateHost(String host) {
    // Check for empty host
    if (host.isEmpty) {
      return HostValidationResult(isValid: false, reason: 'Empty host');
    }

    // Check for localhost variations
    final localhostPatterns = ['localhost', '127.0.0.1', '::1', '0.0.0.0'];
    if (localhostPatterns.contains(host.toLowerCase())) {
      return HostValidationResult(isValid: true, reason: 'Localhost access');
    }

    // Validate IP address format
    if (_isIPAddress(host)) {
      if (_isPrivateIP(host)) {
        return HostValidationResult(isValid: true, reason: 'Private IP address');
      } else {
        return HostValidationResult(isValid: true, reason: 'Public IP address');
      }
    }

    // Validate domain name format
    if (_isValidDomain(host)) {
      return HostValidationResult(isValid: true, reason: 'Valid domain name');
    }

    return HostValidationResult(isValid: false, reason: 'Invalid host format');
  }

  /// Validate port and protocol
  NetworkPermissionResult _validatePort(int port, String protocol) {
    // Check port range
    if (port < 1 || port > 65535) {
      return NetworkPermissionResult.denied(
        reason: 'Invalid port number: $port',
        riskLevel: RiskLevel.medium,
      );
    }

    // Check for well-known dangerous ports
    final dangerousPorts = {
      22: 'SSH',
      23: 'Telnet',
      135: 'RPC',
      139: 'NetBIOS',
      445: 'SMB',
      1433: 'SQL Server',
      3389: 'RDP',
      5432: 'PostgreSQL',
    };

    if (dangerousPorts.containsKey(port)) {
      return NetworkPermissionResult.allowed(
        riskLevel: RiskLevel.high,
        requiresApproval: true,
        monitoringLevel: MonitoringLevel.comprehensive,
      );
    }

    // Check for privileged ports (< 1024)
    if (port < 1024) {
      return NetworkPermissionResult.allowed(
        riskLevel: RiskLevel.medium,
        requiresApproval: false,
        monitoringLevel: MonitoringLevel.enhanced,
      );
    }

    return NetworkPermissionResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
    );
  }

  /// Check connection limits
  NetworkPermissionResult _checkConnectionLimits(String agentId, SecurityContext context) {
    final activeConnections = _activeConnections[agentId]?.length ?? 0;
    final maxConnections = context.resourceLimits.maxNetworkConnections;

    if (activeConnections >= maxConnections) {
      return NetworkPermissionResult.denied(
        reason: 'Maximum network connections exceeded ($activeConnections/$maxConnections)',
        riskLevel: RiskLevel.medium,
      );
    }

    return NetworkPermissionResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
    );
  }

  /// Check threat intelligence
  Future<NetworkPermissionResult> _checkThreatIntelligence(String host, int port) async {
    final threatResult = await _threatIntelligence.checkHost(host);
    
    if (threatResult.isMalicious) {
      return NetworkPermissionResult.denied(
        reason: 'Host flagged as malicious: ${threatResult.reason}',
        riskLevel: RiskLevel.critical,
      );
    }

    if (threatResult.isSuspicious) {
      return NetworkPermissionResult.allowed(
        riskLevel: RiskLevel.high,
        requiresApproval: true,
        monitoringLevel: MonitoringLevel.comprehensive,
      );
    }

    return NetworkPermissionResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
    );
  }

  /// Check for suspicious patterns
  SuspiciousPatternResult _checkSuspiciousPatterns(String host, int port, String protocol) {
    // Check for suspicious domain patterns
    final suspiciousDomainPatterns = [
      r'\.tk$', r'\.ml$', r'\.ga$', r'\.cf$', // Free TLDs often used maliciously
      r'\d+\.\d+\.\d+\.\d+\.xip\.io$', // Dynamic DNS
      r'\.ngrok\.io$', r'\.localtunnel\.me$', // Tunneling services
    ];

    for (final pattern in suspiciousDomainPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(host)) {
        return SuspiciousPatternResult(
          isSuspicious: true,
          requiresApproval: true,
          reason: 'Suspicious domain pattern detected',
        );
      }
    }

    // Check for suspicious port combinations
    final suspiciousPortCombos = {
      'irc.': [6667, 6668, 6669], // IRC servers
      'tor.': [9050, 9051], // Tor
    };

    for (final entry in suspiciousPortCombos.entries) {
      if (host.toLowerCase().contains(entry.key) && entry.value.contains(port)) {
        return SuspiciousPatternResult(
          isSuspicious: true,
          requiresApproval: true,
          reason: 'Suspicious service detected: ${entry.key}',
        );
      }
    }

    return SuspiciousPatternResult(
      isSuspicious: false,
      requiresApproval: false,
      reason: 'No suspicious patterns detected',
    );
  }

  /// Calculate network risk level
  RiskLevel _calculateNetworkRiskLevel(String host, int port, String protocol) {
    // High risk for system ports
    if (port < 1024) {
      return RiskLevel.high;
    }

    // Medium risk for external hosts
    if (!_isLocalHost(host) && !_isPrivateIP(host)) {
      return RiskLevel.medium;
    }

    return RiskLevel.low;
  }

  /// Get network monitoring level
  MonitoringLevel _getNetworkMonitoringLevel(String host, int port, String protocol) {
    // Comprehensive monitoring for external connections
    if (!_isLocalHost(host) && !_isPrivateIP(host)) {
      return MonitoringLevel.comprehensive;
    }

    // Enhanced monitoring for system ports
    if (port < 1024) {
      return MonitoringLevel.enhanced;
    }

    return MonitoringLevel.basic;
  }

  /// Helper methods
  bool _isIPAddress(String host) {
    return RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(host) ||
           RegExp(r'^[0-9a-fA-F:]+$').hasMatch(host); // IPv6 simplified
  }

  bool _isPrivateIP(String host) {
    final privateRanges = [
      RegExp(r'^10\.'),
      RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.'),
      RegExp(r'^192\.168\.'),
      RegExp(r'^127\.'),
    ];

    return privateRanges.any((range) => range.hasMatch(host));
  }

  bool _isLocalHost(String host) {
    final localhostPatterns = ['localhost', '127.0.0.1', '::1', '0.0.0.0'];
    return localhostPatterns.contains(host.toLowerCase());
  }

  bool _isValidDomain(String host) {
    return RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$')
        .hasMatch(host);
  }

  /// Log network access attempt
  void _logNetworkAttempt(
    String agentId,
    String host,
    int port,
    String protocol,
    bool success,
    String reason,
  ) {
    final monitor = _networkMonitors[agentId];
    if (monitor != null) {
      monitor.logNetworkAccess(host, port, protocol, success, reason);
    }

    if (kDebugMode) {
      final status = success ? 'ALLOWED' : 'DENIED';
      debugPrint('Network Access [$agentId]: $status - $host:$port ($protocol) - $reason');
    }
  }

  /// Remove closed connection from tracking
  void _removeConnection(String agentId, NetworkConnection connection) {
    _activeConnections[agentId]?.remove(connection);
  }
}

/// Network connection types
enum NetworkConnectionType {
  outbound,
  inbound,
}

/// Network permission result
class NetworkPermissionResult {
  final bool isAllowed;
  final String reason;
  final RiskLevel riskLevel;
  final bool requiresApproval;
  final MonitoringLevel monitoringLevel;

  const NetworkPermissionResult._({
    required this.isAllowed,
    required this.reason,
    required this.riskLevel,
    this.requiresApproval = false,
    this.monitoringLevel = MonitoringLevel.basic,
  });

  factory NetworkPermissionResult.allowed({
    required RiskLevel riskLevel,
    bool requiresApproval = false,
    MonitoringLevel monitoringLevel = MonitoringLevel.basic,
  }) {
    return NetworkPermissionResult._(
      isAllowed: true,
      reason: 'Network access allowed',
      riskLevel: riskLevel,
      requiresApproval: requiresApproval,
      monitoringLevel: monitoringLevel,
    );
  }

  factory NetworkPermissionResult.denied({
    required String reason,
    required RiskLevel riskLevel,
  }) {
    return NetworkPermissionResult._(
      isAllowed: false,
      reason: reason,
      riskLevel: riskLevel,
    );
  }
}

/// Host validation result
class HostValidationResult {
  final bool isValid;
  final String reason;

  const HostValidationResult({
    required this.isValid,
    required this.reason,
  });
}

/// Suspicious pattern result
class SuspiciousPatternResult {
  final bool isSuspicious;
  final bool requiresApproval;
  final String reason;

  const SuspiciousPatternResult({
    required this.isSuspicious,
    required this.requiresApproval,
    required this.reason,
  });
}

/// Secure network connection wrapper
class SecureNetworkConnection extends NetworkConnection {
  final String agentId;
  final NetworkMonitor monitor;
  final NetworkPermissionManager permissionManager;
  late final Socket _socket;
  bool _isClosed = false;

  SecureNetworkConnection._({
    required this.agentId,
    required String host,
    required int port,
    required String protocol,
    required this.monitor,
    required this.permissionManager,
    required Socket socket,
  }) : _socket = socket, super(host: host, port: port, protocol: protocol);

  static Future<SecureNetworkConnection> create({
    required String agentId,
    required String host,
    required int port,
    required String protocol,
    required Duration timeout,
    required NetworkMonitor monitor,
    required NetworkPermissionManager permissionManager,
  }) async {
    final socket = await Socket.connect(host, port, timeout: timeout);
    
    final connection = SecureNetworkConnection._(
      agentId: agentId,
      host: host,
      port: port,
      protocol: protocol,
      monitor: monitor,
      permissionManager: permissionManager,
      socket: socket,
    );

    monitor.logNetworkAccess(host, port, protocol, true, 'Connection established');
    return connection;
  }

  /// Write data to connection
  Future<void> write(List<int> data) async {
    if (_isClosed) {
      throw StateError('Connection is closed');
    }

    try {
      _socket.add(data);
      await _socket.flush();
      monitor.logDataTransfer(host, port, 'outbound', data.length);
    } catch (e) {
      monitor.logNetworkAccess(host, port, protocol, false, 'Write failed: $e');
      rethrow;
    }
  }

  /// Read data from connection
  Stream<List<int>> read() {
    if (_isClosed) {
      throw StateError('Connection is closed');
    }

    return _socket.map((data) {
      monitor.logDataTransfer(host, port, 'inbound', data.length);
      return data;
    });
  }

  @override
  Future<void> close() async {
    if (!_isClosed) {
      _isClosed = true;
      await _socket.close();
      permissionManager._removeConnection(agentId, this);
      monitor.logNetworkAccess(host, port, protocol, true, 'Connection closed');
    }
  }

  @override
  bool get isClosed => _isClosed;
}

/// Base network connection class
abstract class NetworkConnection {
  final String host;
  final int port;
  final String protocol;

  NetworkConnection({
    required this.host,
    required this.port,
    required this.protocol,
  });

  Future<void> close();
  bool get isClosed;
}

/// Network monitor for tracking access and data transfer
class NetworkMonitor {
  final String agentId;
  final List<NetworkAccessLog> _logs = [];
  final Map<String, int> _hostAccessCounts = {};
  int _totalBytesTransferred = 0;

  NetworkMonitor(this.agentId);

  void logNetworkAccess(String host, int port, String protocol, bool success, String reason) {
    final log = NetworkAccessLog(
      agentId: agentId,
      host: host,
      port: port,
      protocol: protocol,
      success: success,
      reason: reason,
      timestamp: DateTime.now(),
    );

    _logs.add(log);
    
    // Keep only last 1000 logs
    if (_logs.length > 1000) {
      _logs.removeRange(0, _logs.length - 1000);
    }

    // Update host access counts
    if (success) {
      _hostAccessCounts[host] = (_hostAccessCounts[host] ?? 0) + 1;
    }
  }

  void logDataTransfer(String host, int port, String direction, int bytes) {
    _totalBytesTransferred += bytes;
    
    if (kDebugMode) {
      debugPrint('Data Transfer [$agentId]: $direction - $host:$port - $bytes bytes');
    }
  }

  List<NetworkAccessLog> getLogs() => List.unmodifiable(_logs);

  NetworkStats getStats() {
    return NetworkStats(
      agentId: agentId,
      totalConnections: _logs.length,
      successfulConnections: _logs.where((log) => log.success).length,
      failedConnections: _logs.where((log) => !log.success).length,
      hostAccessCounts: Map.unmodifiable(_hostAccessCounts),
      totalBytesTransferred: _totalBytesTransferred,
      lastConnection: _logs.isNotEmpty ? _logs.last.timestamp : null,
    );
  }
}

/// Network access log entry
class NetworkAccessLog {
  final String agentId;
  final String host;
  final int port;
  final String protocol;
  final bool success;
  final String reason;
  final DateTime timestamp;

  const NetworkAccessLog({
    required this.agentId,
    required this.host,
    required this.port,
    required this.protocol,
    required this.success,
    required this.reason,
    required this.timestamp,
  });
}

/// Network statistics
class NetworkStats {
  final String agentId;
  final int totalConnections;
  final int successfulConnections;
  final int failedConnections;
  final Map<String, int> hostAccessCounts;
  final int totalBytesTransferred;
  final DateTime? lastConnection;

  const NetworkStats({
    required this.agentId,
    required this.totalConnections,
    required this.successfulConnections,
    required this.failedConnections,
    required this.hostAccessCounts,
    required this.totalBytesTransferred,
    this.lastConnection,
  });

  factory NetworkStats.empty() {
    return const NetworkStats(
      agentId: '',
      totalConnections: 0,
      successfulConnections: 0,
      failedConnections: 0,
      hostAccessCounts: {},
      totalBytesTransferred: 0,
    );
  }

  double get successRate {
    if (totalConnections == 0) return 0.0;
    return successfulConnections / totalConnections;
  }
}

/// Network threat intelligence service
class NetworkThreatIntelligence {
  final Map<String, ThreatResult> _cache = {};
  final Duration _cacheExpiry = const Duration(hours: 1);

  Future<ThreatResult> checkHost(String host) async {
    // Check cache first
    final cached = _cache[host];
    if (cached != null && !cached.isExpired) {
      return cached;
    }

    // In a real implementation, this would query threat intelligence APIs
    // For now, use a simple local blacklist
    final result = _checkLocalBlacklist(host);
    
    // Cache result
    _cache[host] = result;
    
    return result;
  }

  ThreatResult _checkLocalBlacklist(String host) {
    final maliciousDomains = [
      'malware.com',
      'phishing.net',
      'botnet.org',
    ];

    final suspiciousDomains = [
      'suspicious.com',
      'untrusted.net',
    ];

    if (maliciousDomains.any((domain) => host.toLowerCase().contains(domain))) {
      return ThreatResult(
        isMalicious: true,
        isSuspicious: false,
        reason: 'Host in malicious domain list',
        timestamp: DateTime.now(),
      );
    }

    if (suspiciousDomains.any((domain) => host.toLowerCase().contains(domain))) {
      return ThreatResult(
        isMalicious: false,
        isSuspicious: true,
        reason: 'Host in suspicious domain list',
        timestamp: DateTime.now(),
      );
    }

    return ThreatResult(
      isMalicious: false,
      isSuspicious: false,
      reason: 'Host not in threat database',
      timestamp: DateTime.now(),
    );
  }
}

/// Threat intelligence result
class ThreatResult {
  final bool isMalicious;
  final bool isSuspicious;
  final String reason;
  final DateTime timestamp;

  const ThreatResult({
    required this.isMalicious,
    required this.isSuspicious,
    required this.reason,
    required this.timestamp,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > const Duration(hours: 1);
  }
}

/// Risk levels (reused from other security services)
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Monitoring levels (reused from other security services)
enum MonitoringLevel {
  basic,
  enhanced,
  comprehensive,
}