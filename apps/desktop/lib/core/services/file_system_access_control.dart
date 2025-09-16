import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/security_context.dart';

/// File system access control service for agent operations
class FileSystemAccessControl {
  final Map<String, SecurityContext> _agentContexts = {};
  final Map<String, Set<String>> _agentSandboxes = {};
  final Map<String, FileAccessMonitor> _accessMonitors = {};

  /// Register an agent with its security context
  void registerAgent(String agentId, SecurityContext context) {
    _agentContexts[agentId] = context;
    _accessMonitors[agentId] = FileAccessMonitor(agentId);
    _createAgentSandbox(agentId, context);
  }

  /// Update agent security context
  void updateAgentContext(String agentId, SecurityContext context) {
    _agentContexts[agentId] = context;
    _updateAgentSandbox(agentId, context);
  }

  /// Remove agent from access control
  void unregisterAgent(String agentId) {
    _agentContexts.remove(agentId);
    _accessMonitors.remove(agentId);
    _cleanupAgentSandbox(agentId);
  }

  /// Check if agent can access a file or directory
  Future<FileAccessResult> checkAccess(
    String agentId,
    String filePath, {
    required FileAccessType accessType,
    bool createIfNotExists = false,
  }) async {
    final context = _agentContexts[agentId];
    if (context == null) {
      return FileAccessResult.denied(
        reason: 'No security context found for agent',
        riskLevel: RiskLevel.high,
      );
    }

    try {
      // Normalize and resolve the path
      final normalizedPath = await _normalizePath(filePath);
      final resolvedPath = await _resolvePath(normalizedPath);

      // Check basic path validation
      final pathValidation = _validatePath(resolvedPath);
      if (!pathValidation.isValid) {
        return FileAccessResult.denied(
          reason: pathValidation.reason,
          riskLevel: RiskLevel.high,
        );
      }

      // Check against security context permissions
      final permissionCheck = _checkPermissions(context, resolvedPath, accessType);
      if (!permissionCheck.isAllowed) {
        _logAccessAttempt(agentId, resolvedPath, accessType, false, permissionCheck.reason);
        return permissionCheck;
      }

      // Check for sensitive files
      final sensitivityCheck = _checkFileSensitivity(resolvedPath, accessType);
      if (sensitivityCheck.requiresApproval) {
        _logAccessAttempt(agentId, resolvedPath, accessType, true, 'Sensitive file access');
        return FileAccessResult.allowed(
          riskLevel: RiskLevel.high,
          requiresApproval: true,
          monitoringLevel: MonitoringLevel.comprehensive,
        );
      }

      // Check sandbox boundaries
      final sandboxCheck = _checkSandboxBoundaries(agentId, resolvedPath);
      if (!sandboxCheck.isAllowed) {
        _logAccessAttempt(agentId, resolvedPath, accessType, false, sandboxCheck.reason);
        return sandboxCheck;
      }

      // Check file existence and create if needed
      if (createIfNotExists && !await File(resolvedPath).exists() && !await Directory(resolvedPath).exists()) {
        final createResult = await _createFileOrDirectory(agentId, resolvedPath, accessType);
        if (!createResult.isAllowed) {
          return createResult;
        }
      }

      // Log successful access
      _logAccessAttempt(agentId, resolvedPath, accessType, true, 'Access granted');

      return FileAccessResult.allowed(
        riskLevel: _calculateRiskLevel(resolvedPath, accessType),
        requiresApproval: false,
        monitoringLevel: _getMonitoringLevel(resolvedPath, accessType),
      );

    } catch (e) {
      _logAccessAttempt(agentId, filePath, accessType, false, 'Access check error: $e');
      return FileAccessResult.denied(
        reason: 'File access validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Create a secure file wrapper for agent operations
  Future<SecureFile?> createSecureFile(
    String agentId,
    String filePath, {
    FileAccessType accessType = FileAccessType.readWrite,
  }) async {
    final accessResult = await checkAccess(agentId, filePath, accessType: accessType);
    
    if (!accessResult.isAllowed) {
      return null;
    }

    return SecureFile(
      agentId: agentId,
      filePath: filePath,
      accessType: accessType,
      accessControl: this,
      monitor: _accessMonitors[agentId]!,
    );
  }

  /// Get file access statistics for an agent
  FileAccessStats getAccessStats(String agentId) {
    final monitor = _accessMonitors[agentId];
    if (monitor == null) {
      return FileAccessStats.empty();
    }

    return monitor.getStats();
  }

  /// Get all access logs for an agent
  List<FileAccessLog> getAccessLogs(String agentId) {
    final monitor = _accessMonitors[agentId];
    if (monitor == null) {
      return [];
    }

    return monitor.getLogs();
  }

  /// Create agent sandbox directory
  void _createAgentSandbox(String agentId, SecurityContext context) {
    final sandboxPaths = <String>{};
    
    // Create sandbox directories based on allowed paths
    for (final allowedPath in context.allowedPaths.keys) {
      if (allowedPath.contains('sandbox') || allowedPath.contains('temp')) {
        sandboxPaths.add(allowedPath);
      }
    }

    // Create default sandbox if none specified
    if (sandboxPaths.isEmpty) {
      final defaultSandbox = _getDefaultSandboxPath(agentId);
      sandboxPaths.add(defaultSandbox);
      
      // Create the directory
      try {
        Directory(defaultSandbox).createSync(recursive: true);
      } catch (e) {
        debugPrint('Failed to create sandbox directory: $e');
      }
    }

    _agentSandboxes[agentId] = sandboxPaths;
  }

  /// Update agent sandbox
  void _updateAgentSandbox(String agentId, SecurityContext context) {
    _createAgentSandbox(agentId, context);
  }

  /// Cleanup agent sandbox
  void _cleanupAgentSandbox(String agentId) {
    final sandboxPaths = _agentSandboxes[agentId];
    if (sandboxPaths != null) {
      for (final sandboxPath in sandboxPaths) {
        try {
          final dir = Directory(sandboxPath);
          if (dir.existsSync()) {
            dir.deleteSync(recursive: true);
          }
        } catch (e) {
          debugPrint('Failed to cleanup sandbox directory $sandboxPath: $e');
        }
      }
    }
    _agentSandboxes.remove(agentId);
  }

  /// Normalize file path
  Future<String> _normalizePath(String filePath) async {
    // Convert to absolute path
    String normalized = path.normalize(path.absolute(filePath));
    
    // Handle Windows/Unix path separators
    if (Platform.isWindows) {
      normalized = normalized.replaceAll('/', '\\');
    } else {
      normalized = normalized.replaceAll('\\', '/');
    }

    return normalized;
  }

  /// Resolve symbolic links and relative paths
  Future<String> _resolvePath(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.resolveSymbolicLinks();
      }
      
      final dir = Directory(filePath);
      if (await dir.exists()) {
        return await dir.resolveSymbolicLinks();
      }
      
      // Path doesn't exist, return normalized path
      return filePath;
    } catch (e) {
      // If resolution fails, return original path
      return filePath;
    }
  }

  /// Validate path for security issues
  PathValidationResult _validatePath(String filePath) {
    // Check for path traversal
    if (filePath.contains('../') || filePath.contains('..\\')) {
      return PathValidationResult(
        isValid: false,
        reason: 'Path traversal detected',
      );
    }

    // Check for null bytes
    if (filePath.contains('\x00')) {
      return PathValidationResult(
        isValid: false,
        reason: 'Null byte in path',
      );
    }

    // Check for extremely long paths
    if (filePath.length > 4096) {
      return PathValidationResult(
        isValid: false,
        reason: 'Path too long',
      );
    }

    // Check for invalid characters
    final invalidChars = Platform.isWindows 
        ? ['<', '>', ':', '"', '|', '?', '*']
        : ['\x00'];
    
    for (final char in invalidChars) {
      if (filePath.contains(char)) {
        return PathValidationResult(
          isValid: false,
          reason: 'Invalid character in path: $char',
        );
      }
    }

    return PathValidationResult(isValid: true, reason: 'Path valid');
  }

  /// Check permissions against security context
  FileAccessResult _checkPermissions(
    SecurityContext context,
    String filePath,
    FileAccessType accessType,
  ) {
    final isWrite = accessType == FileAccessType.write || 
                   accessType == FileAccessType.readWrite ||
                   accessType == FileAccessType.execute;

    if (!context.isPathAllowed(filePath, isWrite: isWrite)) {
      return FileAccessResult.denied(
        reason: 'Path not permitted by security policy',
        riskLevel: isWrite ? RiskLevel.high : RiskLevel.medium,
      );
    }

    return FileAccessResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
    );
  }

  /// Check file sensitivity
  FileSensitivityResult _checkFileSensitivity(String filePath, FileAccessType accessType) {
    final sensitivePatterns = [
      // System files
      '/etc/', '/usr/bin/', '/System/', 'C:\\Windows\\',
      
      // User credentials
      '.ssh/', '.aws/', '.env', 'id_rsa', 'id_dsa', '.pem',
      
      // Application secrets
      'config.json', 'secrets.json', 'credentials.json',
      '.env.local', '.env.production',
      
      // Database files
      '.db', '.sqlite', '.sqlite3',
    ];

    final isSensitive = sensitivePatterns.any((pattern) => 
        filePath.toLowerCase().contains(pattern.toLowerCase()));

    if (isSensitive) {
      return FileSensitivityResult(
        isSensitive: true,
        requiresApproval: true,
        reason: 'Sensitive file detected',
      );
    }

    return FileSensitivityResult(
      isSensitive: false,
      requiresApproval: false,
      reason: 'File not sensitive',
    );
  }

  /// Check sandbox boundaries
  FileAccessResult _checkSandboxBoundaries(String agentId, String filePath) {
    final sandboxPaths = _agentSandboxes[agentId];
    if (sandboxPaths == null || sandboxPaths.isEmpty) {
      // No sandbox restrictions
      return FileAccessResult.allowed(
        riskLevel: RiskLevel.low,
        requiresApproval: false,
        monitoringLevel: MonitoringLevel.basic,
      );
    }

    // Check if path is within any sandbox
    final isInSandbox = sandboxPaths.any((sandboxPath) => 
        filePath.startsWith(sandboxPath));

    if (!isInSandbox) {
      return FileAccessResult.denied(
        reason: 'Path outside sandbox boundaries',
        riskLevel: RiskLevel.high,
      );
    }

    return FileAccessResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
    );
  }

  /// Create file or directory
  Future<FileAccessResult> _createFileOrDirectory(
    String agentId,
    String filePath,
    FileAccessType accessType,
  ) async {
    try {
      if (accessType == FileAccessType.directory) {
        await Directory(filePath).create(recursive: true);
      } else {
        await File(filePath).create(recursive: true);
      }

      _logAccessAttempt(agentId, filePath, FileAccessType.create, true, 'File/directory created');
      
      return FileAccessResult.allowed(
        riskLevel: RiskLevel.low,
        requiresApproval: false,
        monitoringLevel: MonitoringLevel.basic,
      );
    } catch (e) {
      _logAccessAttempt(agentId, filePath, FileAccessType.create, false, 'Creation failed: $e');
      
      return FileAccessResult.denied(
        reason: 'Failed to create file/directory: $e',
        riskLevel: RiskLevel.medium,
      );
    }
  }

  /// Calculate risk level for file access
  RiskLevel _calculateRiskLevel(String filePath, FileAccessType accessType) {
    // High risk for system files
    if (_isSystemFile(filePath)) {
      return RiskLevel.high;
    }

    // Medium risk for executable files
    if (accessType == FileAccessType.execute || _isExecutableFile(filePath)) {
      return RiskLevel.medium;
    }

    // Medium risk for write operations
    if (accessType == FileAccessType.write || accessType == FileAccessType.readWrite) {
      return RiskLevel.medium;
    }

    return RiskLevel.low;
  }

  /// Get monitoring level for file access
  MonitoringLevel _getMonitoringLevel(String filePath, FileAccessType accessType) {
    if (_isSystemFile(filePath) || accessType == FileAccessType.execute) {
      return MonitoringLevel.comprehensive;
    }

    if (accessType == FileAccessType.write || accessType == FileAccessType.readWrite) {
      return MonitoringLevel.enhanced;
    }

    return MonitoringLevel.basic;
  }

  /// Check if file is a system file
  bool _isSystemFile(String filePath) {
    final systemPaths = [
      '/etc/', '/usr/bin/', '/usr/sbin/', '/System/',
      'C:\\Windows\\', 'C:\\Program Files\\',
    ];

    return systemPaths.any((systemPath) => 
        filePath.toLowerCase().startsWith(systemPath.toLowerCase()));
  }

  /// Check if file is executable
  bool _isExecutableFile(String filePath) {
    final executableExtensions = ['.exe', '.bat', '.cmd', '.sh', '.py', '.js', '.dart'];
    final extension = path.extension(filePath).toLowerCase();
    return executableExtensions.contains(extension);
  }

  /// Get default sandbox path for agent
  String _getDefaultSandboxPath(String agentId) {
    final tempDir = Directory.systemTemp.path;
    return path.join(tempDir, 'agent_sandbox', agentId);
  }

  /// Log file access attempt
  void _logAccessAttempt(
    String agentId,
    String filePath,
    FileAccessType accessType,
    bool success,
    String reason,
  ) {
    final monitor = _accessMonitors[agentId];
    if (monitor != null) {
      monitor.logAccess(filePath, accessType, success, reason);
    }

    if (kDebugMode) {
      final status = success ? 'ALLOWED' : 'DENIED';
      debugPrint('File Access [$agentId]: $status - $filePath ($accessType) - $reason');
    }
  }
}

/// File access types
enum FileAccessType {
  read,
  write,
  readWrite,
  execute,
  create,
  delete,
  directory,
}

/// File access result
class FileAccessResult {
  final bool isAllowed;
  final String reason;
  final RiskLevel riskLevel;
  final bool requiresApproval;
  final MonitoringLevel monitoringLevel;

  const FileAccessResult._({
    required this.isAllowed,
    required this.reason,
    required this.riskLevel,
    this.requiresApproval = false,
    this.monitoringLevel = MonitoringLevel.basic,
  });

  factory FileAccessResult.allowed({
    required RiskLevel riskLevel,
    bool requiresApproval = false,
    MonitoringLevel monitoringLevel = MonitoringLevel.basic,
  }) {
    return FileAccessResult._(
      isAllowed: true,
      reason: 'Access allowed',
      riskLevel: riskLevel,
      requiresApproval: requiresApproval,
      monitoringLevel: monitoringLevel,
    );
  }

  factory FileAccessResult.denied({
    required String reason,
    required RiskLevel riskLevel,
  }) {
    return FileAccessResult._(
      isAllowed: false,
      reason: reason,
      riskLevel: riskLevel,
    );
  }
}

/// Path validation result
class PathValidationResult {
  final bool isValid;
  final String reason;

  const PathValidationResult({
    required this.isValid,
    required this.reason,
  });
}

/// File sensitivity result
class FileSensitivityResult {
  final bool isSensitive;
  final bool requiresApproval;
  final String reason;

  const FileSensitivityResult({
    required this.isSensitive,
    required this.requiresApproval,
    required this.reason,
  });
}

/// Secure file wrapper
class SecureFile {
  final String agentId;
  final String filePath;
  final FileAccessType accessType;
  final FileSystemAccessControl accessControl;
  final FileAccessMonitor monitor;

  SecureFile({
    required this.agentId,
    required this.filePath,
    required this.accessType,
    required this.accessControl,
    required this.monitor,
  });

  /// Read file contents
  Future<String> readAsString() async {
    if (!_canRead()) {
      throw SecurityException('Read access not permitted');
    }

    try {
      final content = await File(filePath).readAsString();
      monitor.logAccess(filePath, FileAccessType.read, true, 'File read successfully');
      return content;
    } catch (e) {
      monitor.logAccess(filePath, FileAccessType.read, false, 'Read failed: $e');
      rethrow;
    }
  }

  /// Write file contents
  Future<void> writeAsString(String content) async {
    if (!_canWrite()) {
      throw SecurityException('Write access not permitted');
    }

    try {
      await File(filePath).writeAsString(content);
      monitor.logAccess(filePath, FileAccessType.write, true, 'File written successfully');
    } catch (e) {
      monitor.logAccess(filePath, FileAccessType.write, false, 'Write failed: $e');
      rethrow;
    }
  }

  /// Check if file exists
  Future<bool> exists() async {
    try {
      final exists = await File(filePath).exists();
      monitor.logAccess(filePath, FileAccessType.read, true, 'Existence check');
      return exists;
    } catch (e) {
      monitor.logAccess(filePath, FileAccessType.read, false, 'Existence check failed: $e');
      return false;
    }
  }

  /// Delete file
  Future<void> delete() async {
    if (!_canWrite()) {
      throw SecurityException('Delete access not permitted');
    }

    try {
      await File(filePath).delete();
      monitor.logAccess(filePath, FileAccessType.delete, true, 'File deleted successfully');
    } catch (e) {
      monitor.logAccess(filePath, FileAccessType.delete, false, 'Delete failed: $e');
      rethrow;
    }
  }

  bool _canRead() {
    return accessType == FileAccessType.read || 
           accessType == FileAccessType.readWrite;
  }

  bool _canWrite() {
    return accessType == FileAccessType.write || 
           accessType == FileAccessType.readWrite;
  }
}

/// File access monitor
class FileAccessMonitor {
  final String agentId;
  final List<FileAccessLog> _logs = [];
  final Map<FileAccessType, int> _accessCounts = {};

  FileAccessMonitor(this.agentId);

  void logAccess(String filePath, FileAccessType accessType, bool success, String reason) {
    final log = FileAccessLog(
      agentId: agentId,
      filePath: filePath,
      accessType: accessType,
      success: success,
      reason: reason,
      timestamp: DateTime.now(),
    );

    _logs.add(log);
    
    // Keep only last 1000 logs
    if (_logs.length > 1000) {
      _logs.removeRange(0, _logs.length - 1000);
    }

    // Update counters
    _accessCounts[accessType] = (_accessCounts[accessType] ?? 0) + 1;
  }

  List<FileAccessLog> getLogs() => List.unmodifiable(_logs);

  FileAccessStats getStats() {
    return FileAccessStats(
      agentId: agentId,
      totalAccesses: _logs.length,
      successfulAccesses: _logs.where((log) => log.success).length,
      failedAccesses: _logs.where((log) => !log.success).length,
      accessCounts: Map.unmodifiable(_accessCounts),
      lastAccess: _logs.isNotEmpty ? _logs.last.timestamp : null,
    );
  }
}

/// File access log entry
class FileAccessLog {
  final String agentId;
  final String filePath;
  final FileAccessType accessType;
  final bool success;
  final String reason;
  final DateTime timestamp;

  const FileAccessLog({
    required this.agentId,
    required this.filePath,
    required this.accessType,
    required this.success,
    required this.reason,
    required this.timestamp,
  });
}

/// File access statistics
class FileAccessStats {
  final String agentId;
  final int totalAccesses;
  final int successfulAccesses;
  final int failedAccesses;
  final Map<FileAccessType, int> accessCounts;
  final DateTime? lastAccess;

  const FileAccessStats({
    required this.agentId,
    required this.totalAccesses,
    required this.successfulAccesses,
    required this.failedAccesses,
    required this.accessCounts,
    this.lastAccess,
  });

  factory FileAccessStats.empty() {
    return const FileAccessStats(
      agentId: '',
      totalAccesses: 0,
      successfulAccesses: 0,
      failedAccesses: 0,
      accessCounts: {},
    );
  }

  double get successRate {
    if (totalAccesses == 0) return 0.0;
    return successfulAccesses / totalAccesses;
  }
}

/// Security exception for file access violations
class SecurityException implements Exception {
  final String message;
  
  const SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

/// Risk levels (reused from security policy engine)
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Monitoring levels (reused from security policy engine)
enum MonitoringLevel {
  basic,
  enhanced,
  comprehensive,
}