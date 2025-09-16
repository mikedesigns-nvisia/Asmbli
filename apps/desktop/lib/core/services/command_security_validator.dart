import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/security_context.dart';

/// Command security validator with whitelisting and approval workflows
class CommandSecurityValidator {
  final Map<String, SecurityContext> _agentContexts = {};
  final Map<String, CommandMonitor> _commandMonitors = {};
  final CommandApprovalWorkflow _approvalWorkflow = CommandApprovalWorkflow();
  final DangerousCommandDetector _dangerousDetector = DangerousCommandDetector();
  final CommandPatternAnalyzer _patternAnalyzer = CommandPatternAnalyzer();

  /// Register an agent with its security context
  void registerAgent(String agentId, SecurityContext context) {
    _agentContexts[agentId] = context;
    _commandMonitors[agentId] = CommandMonitor(agentId);
  }

  /// Update agent security context
  void updateAgentContext(String agentId, SecurityContext context) {
    _agentContexts[agentId] = context;
  }

  /// Remove agent from command security validation
  void unregisterAgent(String agentId) {
    _agentContexts.remove(agentId);
    _commandMonitors.remove(agentId);
  }

  /// Validate command against security policies
  Future<CommandValidationResult> validateCommand(
    String agentId,
    String command, {
    Map<String, String> environment = const {},
    String? workingDirectory,
    bool bypassApproval = false,
  }) async {
    final context = _agentContexts[agentId];
    if (context == null) {
      return CommandValidationResult.denied(
        reason: 'No security context found for agent',
        riskLevel: RiskLevel.high,
      );
    }

    try {
      // Parse and analyze the command
      final parsedCommand = _parseCommand(command);
      final analysisResult = await _analyzeCommand(agentId, parsedCommand, context, environment, workingDirectory);

      // Log the validation attempt
      _logCommandValidation(agentId, command, analysisResult.isAllowed, analysisResult.reason);

      // If command is blocked, return immediately
      if (!analysisResult.isAllowed) {
        return analysisResult;
      }

      // Check if approval is required and not bypassed
      if (analysisResult.requiresApproval && !bypassApproval) {
        // Submit for approval workflow
        final approvalId = await _approvalWorkflow.submitForApproval(
          agentId,
          command,
          analysisResult.riskLevel,
          analysisResult.reason,
        );

        return CommandValidationResult.pendingApproval(
          approvalId: approvalId,
          riskLevel: analysisResult.riskLevel,
          reason: 'Command requires approval: ${analysisResult.reason}',
          monitoringLevel: analysisResult.monitoringLevel,
        );
      }

      // Command is allowed
      return analysisResult;

    } catch (e) {
      _logCommandValidation(agentId, command, false, 'Validation error: $e');
      return CommandValidationResult.denied(
        reason: 'Command validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Check approval status for a pending command
  Future<ApprovalStatus> checkApprovalStatus(String approvalId) async {
    return await _approvalWorkflow.getApprovalStatus(approvalId);
  }

  /// Approve a pending command
  Future<bool> approveCommand(String approvalId, String approverUserId, {String? reason}) async {
    return await _approvalWorkflow.approveCommand(approvalId, approverUserId, reason: reason);
  }

  /// Reject a pending command
  Future<bool> rejectCommand(String approvalId, String approverUserId, {String? reason}) async {
    return await _approvalWorkflow.rejectCommand(approvalId, approverUserId, reason: reason);
  }

  /// Get pending approvals for review
  List<PendingApproval> getPendingApprovals() {
    return _approvalWorkflow.getPendingApprovals();
  }

  /// Get command validation statistics
  CommandValidationStats getValidationStats(String agentId) {
    final monitor = _commandMonitors[agentId];
    if (monitor == null) {
      return CommandValidationStats.empty();
    }

    return monitor.getStats();
  }

  /// Get command validation logs
  List<CommandValidationLog> getValidationLogs(String agentId) {
    final monitor = _commandMonitors[agentId];
    if (monitor == null) {
      return [];
    }

    return monitor.getLogs();
  }

  /// Analyze command for security issues
  Future<CommandValidationResult> _analyzeCommand(
    String agentId,
    ParsedCommand parsedCommand,
    SecurityContext context,
    Map<String, String> environment,
    String? workingDirectory,
  ) async {
    // Step 1: Check whitelist/blacklist
    final whitelistResult = _checkWhitelist(parsedCommand, context);
    if (!whitelistResult.isAllowed) {
      return whitelistResult;
    }

    // Step 2: Check for dangerous commands
    final dangerousResult = await _dangerousDetector.checkCommand(parsedCommand);
    if (!dangerousResult.isAllowed) {
      return dangerousResult;
    }

    // Step 3: Analyze command patterns
    final patternResult = await _patternAnalyzer.analyzeCommand(agentId, parsedCommand);
    if (!patternResult.isAllowed) {
      return patternResult;
    }

    // Step 4: Check argument safety
    final argumentResult = _checkArgumentSafety(parsedCommand, context, workingDirectory);
    if (!argumentResult.isAllowed) {
      return argumentResult;
    }

    // Step 5: Check environment variable safety
    final envResult = _checkEnvironmentSafety(environment, context);
    if (!envResult.isAllowed) {
      return envResult;
    }

    // Step 6: Check for privilege escalation
    final privilegeResult = _checkPrivilegeEscalation(parsedCommand);
    if (!privilegeResult.isAllowed) {
      return privilegeResult;
    }

    // Step 7: Determine final risk level and approval requirements
    final finalRiskLevel = _calculateFinalRiskLevel(parsedCommand, dangerousResult, patternResult);
    final requiresApproval = _determineApprovalRequirement(parsedCommand, context, finalRiskLevel);
    final monitoringLevel = _determineMonitoringLevel(parsedCommand, finalRiskLevel);

    return CommandValidationResult.allowed(
      riskLevel: finalRiskLevel,
      requiresApproval: requiresApproval,
      monitoringLevel: monitoringLevel,
      reason: 'Command passed all security checks',
    );
  }

  /// Parse command into structured format
  ParsedCommand _parseCommand(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Empty command');
    }

    // Split command while preserving quoted strings
    final parts = _splitCommandPreservingQuotes(trimmed);
    if (parts.isEmpty) {
      throw ArgumentError('Invalid command format');
    }

    final executable = parts.first;
    final arguments = parts.skip(1).toList();

    // Detect shell operators and redirections
    final operators = <String>[];
    final redirections = <String>[];
    final cleanArguments = <String>[];

    for (final arg in arguments) {
      if (_isShellOperator(arg)) {
        operators.add(arg);
      } else if (_isRedirection(arg)) {
        redirections.add(arg);
      } else {
        cleanArguments.add(arg);
      }
    }

    return ParsedCommand(
      original: command,
      executable: executable,
      arguments: cleanArguments,
      operators: operators,
      redirections: redirections,
    );
  }

  /// Split command while preserving quoted strings
  List<String> _splitCommandPreservingQuotes(String command) {
    final parts = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    String? quoteChar;

    for (int i = 0; i < command.length; i++) {
      final char = command[i];
      
      if (!inQuotes && (char == '"' || char == "'")) {
        inQuotes = true;
        quoteChar = char;
        buffer.write(char);
      } else if (inQuotes && char == quoteChar) {
        inQuotes = false;
        quoteChar = null;
        buffer.write(char);
      } else if (!inQuotes && char == ' ') {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }

  /// Check command against whitelist/blacklist
  CommandValidationResult _checkWhitelist(ParsedCommand command, SecurityContext context) {
    final executable = command.executable;

    // Check blacklist first
    if (context.blockedCommands.contains(executable)) {
      return CommandValidationResult.denied(
        reason: 'Command is explicitly blocked: $executable',
        riskLevel: RiskLevel.high,
      );
    }

    // Check whitelist (if not empty, only whitelisted commands are allowed)
    if (context.allowedCommands.isNotEmpty && !context.allowedCommands.contains(executable)) {
      return CommandValidationResult.denied(
        reason: 'Command not in whitelist: $executable',
        riskLevel: RiskLevel.medium,
      );
    }

    // Check terminal permissions
    if (!context.terminalPermissions.canExecuteShellCommands) {
      return CommandValidationResult.denied(
        reason: 'Shell command execution is disabled',
        riskLevel: RiskLevel.medium,
      );
    }

    // Check specific command whitelist/blacklist
    if (context.terminalPermissions.commandBlacklist.contains(executable)) {
      return CommandValidationResult.denied(
        reason: 'Command in terminal blacklist: $executable',
        riskLevel: RiskLevel.high,
      );
    }

    if (context.terminalPermissions.commandWhitelist.isNotEmpty &&
        !context.terminalPermissions.commandWhitelist.contains(executable)) {
      return CommandValidationResult.denied(
        reason: 'Command not in terminal whitelist: $executable',
        riskLevel: RiskLevel.medium,
      );
    }

    return CommandValidationResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
      reason: 'Command passed whitelist check',
    );
  }

  /// Check argument safety
  CommandValidationResult _checkArgumentSafety(
    ParsedCommand command,
    SecurityContext context,
    String? workingDirectory,
  ) {
    for (final arg in command.arguments) {
      // Check for path traversal
      if (arg.contains('../') || arg.contains('..\\')) {
        return CommandValidationResult.denied(
          reason: 'Path traversal detected in argument: $arg',
          riskLevel: RiskLevel.high,
        );
      }

      // Check for command injection
      if (_hasCommandInjection(arg)) {
        return CommandValidationResult.denied(
          reason: 'Command injection detected in argument: $arg',
          riskLevel: RiskLevel.critical,
        );
      }

      // Check file path permissions
      if (_looksLikeFilePath(arg)) {
        final fullPath = _resolveFilePath(arg, workingDirectory);
        final isWrite = _isWriteOperation(command.executable);
        
        if (!context.isPathAllowed(fullPath, isWrite: isWrite)) {
          return CommandValidationResult.denied(
            reason: 'File path not permitted: $fullPath',
            riskLevel: RiskLevel.medium,
          );
        }
      }

      // Check for sensitive data in arguments
      if (_containsSensitiveData(arg)) {
        return CommandValidationResult.allowed(
          riskLevel: RiskLevel.high,
          requiresApproval: true,
          monitoringLevel: MonitoringLevel.comprehensive,
          reason: 'Sensitive data detected in arguments',
        );
      }
    }

    return CommandValidationResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
      reason: 'Arguments passed safety check',
    );
  }

  /// Check environment variable safety
  CommandValidationResult _checkEnvironmentSafety(
    Map<String, String> environment,
    SecurityContext context,
  ) {
    for (final entry in environment.entries) {
      final key = entry.key;
      final value = entry.value;

      // Check for sensitive environment variables
      if (_isSensitiveEnvironmentVariable(key)) {
        return CommandValidationResult.allowed(
          riskLevel: RiskLevel.high,
          requiresApproval: true,
          monitoringLevel: MonitoringLevel.comprehensive,
          reason: 'Sensitive environment variable: $key',
        );
      }

      // Check for dangerous values
      if (_hasDangerousEnvironmentValue(value)) {
        return CommandValidationResult.denied(
          reason: 'Dangerous environment variable value detected',
          riskLevel: RiskLevel.high,
        );
      }
    }

    return CommandValidationResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
      reason: 'Environment variables passed safety check',
    );
  }

  /// Check for privilege escalation attempts
  CommandValidationResult _checkPrivilegeEscalation(ParsedCommand command) {
    final privilegeCommands = ['sudo', 'su', 'doas', 'runas'];
    
    if (privilegeCommands.contains(command.executable.toLowerCase())) {
      return CommandValidationResult.allowed(
        riskLevel: RiskLevel.critical,
        requiresApproval: true,
        monitoringLevel: MonitoringLevel.comprehensive,
        reason: 'Privilege escalation command detected',
      );
    }

    // Check for privilege escalation in arguments
    for (final arg in command.arguments) {
      if (privilegeCommands.any((cmd) => arg.toLowerCase().contains(cmd))) {
        return CommandValidationResult.allowed(
          riskLevel: RiskLevel.high,
          requiresApproval: true,
          monitoringLevel: MonitoringLevel.comprehensive,
          reason: 'Privilege escalation detected in arguments',
        );
      }
    }

    return CommandValidationResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
      reason: 'No privilege escalation detected',
    );
  }

  /// Calculate final risk level
  RiskLevel _calculateFinalRiskLevel(
    ParsedCommand command,
    CommandValidationResult dangerousResult,
    CommandValidationResult patternResult,
  ) {
    final riskLevels = [
      _getCommandRiskLevel(command.executable),
      dangerousResult.riskLevel,
      patternResult.riskLevel,
    ];

    // Return the highest risk level
    return riskLevels.reduce((a, b) => a.index > b.index ? a : b);
  }

  /// Determine if approval is required
  bool _determineApprovalRequirement(
    ParsedCommand command,
    SecurityContext context,
    RiskLevel riskLevel,
  ) {
    // Always require approval for high/critical risk
    if (riskLevel.index >= RiskLevel.high.index) {
      return true;
    }

    // Check context-specific approval requirements
    if (context.terminalPermissions.requiresApprovalForAPICalls) {
      // Check if command might make API calls
      final apiCommands = ['curl', 'wget', 'http', 'httpie'];
      if (apiCommands.contains(command.executable.toLowerCase())) {
        return true;
      }
    }

    // Check for specific commands that always require approval
    final approvalCommands = ['rm', 'del', 'format', 'fdisk', 'chmod', 'chown'];
    if (approvalCommands.contains(command.executable.toLowerCase())) {
      return true;
    }

    return false;
  }

  /// Determine monitoring level
  MonitoringLevel _determineMonitoringLevel(ParsedCommand command, RiskLevel riskLevel) {
    if (riskLevel.index >= RiskLevel.high.index) {
      return MonitoringLevel.comprehensive;
    }

    if (riskLevel == RiskLevel.medium) {
      return MonitoringLevel.enhanced;
    }

    return MonitoringLevel.basic;
  }

  /// Get risk level for specific command
  RiskLevel _getCommandRiskLevel(String executable) {
    final criticalCommands = ['sudo', 'su', 'format', 'fdisk', 'rm', 'del'];
    final highRiskCommands = ['chmod', 'chown', 'kill', 'killall', 'shutdown', 'reboot'];
    final mediumRiskCommands = ['curl', 'wget', 'ssh', 'scp', 'git', 'npm', 'pip'];

    final lowerExecutable = executable.toLowerCase();

    if (criticalCommands.contains(lowerExecutable)) {
      return RiskLevel.critical;
    } else if (highRiskCommands.contains(lowerExecutable)) {
      return RiskLevel.high;
    } else if (mediumRiskCommands.contains(lowerExecutable)) {
      return RiskLevel.medium;
    }

    return RiskLevel.low;
  }

  /// Helper methods
  bool _isShellOperator(String arg) {
    final operators = ['&&', '||', '|', ';', '&'];
    return operators.contains(arg);
  }

  bool _isRedirection(String arg) {
    return arg.startsWith('>') || arg.startsWith('<') || arg.contains('>>');
  }

  bool _hasCommandInjection(String arg) {
    final injectionPatterns = [';', '|', '&', '`', r'$', r'$(', r'${'];
    return injectionPatterns.any((pattern) => arg.contains(pattern));
  }

  bool _looksLikeFilePath(String arg) {
    return arg.contains('/') || arg.contains('\\') || arg.startsWith('./') || arg.startsWith('../');
  }

  String _resolveFilePath(String path, String? workingDirectory) {
    if (path.startsWith('/') || path.contains(':\\')) {
      return path; // Absolute path
    }
    
    final baseDir = workingDirectory ?? Directory.current.path;
    return '$baseDir/$path';
  }

  bool _isWriteOperation(String executable) {
    final writeCommands = ['cp', 'copy', 'mv', 'move', 'rm', 'del', 'mkdir', 'touch', 'echo'];
    return writeCommands.contains(executable.toLowerCase());
  }

  bool _containsSensitiveData(String arg) {
    final sensitivePatterns = [
      r'password=',
      r'token=',
      r'key=',
      r'secret=',
      r'api_key=',
      r'--password',
      r'--token',
      r'--key',
    ];

    return sensitivePatterns.any((pattern) => 
        RegExp(pattern, caseSensitive: false).hasMatch(arg));
  }

  bool _isSensitiveEnvironmentVariable(String key) {
    final sensitiveKeys = [
      'PASSWORD', 'TOKEN', 'SECRET', 'API_KEY', 'PRIVATE_KEY',
      'AWS_SECRET_ACCESS_KEY', 'GITHUB_TOKEN', 'ANTHROPIC_API_KEY',
      'OPENAI_API_KEY', 'DATABASE_PASSWORD',
    ];

    return sensitiveKeys.any((sensitive) => 
        key.toUpperCase().contains(sensitive));
  }

  bool _hasDangerousEnvironmentValue(String value) {
    final dangerousPatterns = [
      r'\$\([^)]*\)', // Command substitution
      r'`[^`]*`',     // Backticks
      r';.*',         // Command chaining
    ];

    return dangerousPatterns.any((pattern) => 
        RegExp(pattern).hasMatch(value));
  }

  /// Log command validation
  void _logCommandValidation(String agentId, String command, bool allowed, String reason) {
    final monitor = _commandMonitors[agentId];
    if (monitor != null) {
      monitor.logValidation(command, allowed, reason);
    }

    if (kDebugMode) {
      final status = allowed ? 'ALLOWED' : 'DENIED';
      debugPrint('Command Validation [$agentId]: $status - $command - $reason');
    }
  }
}

/// Parsed command structure
class ParsedCommand {
  final String original;
  final String executable;
  final List<String> arguments;
  final List<String> operators;
  final List<String> redirections;

  const ParsedCommand({
    required this.original,
    required this.executable,
    required this.arguments,
    required this.operators,
    required this.redirections,
  });
}

/// Command validation result
class CommandValidationResult {
  final bool isAllowed;
  final String reason;
  final RiskLevel riskLevel;
  final bool requiresApproval;
  final MonitoringLevel monitoringLevel;
  final String? approvalId;
  final bool isPendingApproval;

  const CommandValidationResult._({
    required this.isAllowed,
    required this.reason,
    required this.riskLevel,
    this.requiresApproval = false,
    this.monitoringLevel = MonitoringLevel.basic,
    this.approvalId,
    this.isPendingApproval = false,
  });

  factory CommandValidationResult.allowed({
    required RiskLevel riskLevel,
    bool requiresApproval = false,
    MonitoringLevel monitoringLevel = MonitoringLevel.basic,
    required String reason,
  }) {
    return CommandValidationResult._(
      isAllowed: true,
      reason: reason,
      riskLevel: riskLevel,
      requiresApproval: requiresApproval,
      monitoringLevel: monitoringLevel,
    );
  }

  factory CommandValidationResult.denied({
    required String reason,
    required RiskLevel riskLevel,
  }) {
    return CommandValidationResult._(
      isAllowed: false,
      reason: reason,
      riskLevel: riskLevel,
    );
  }

  factory CommandValidationResult.pendingApproval({
    required String approvalId,
    required RiskLevel riskLevel,
    required String reason,
    MonitoringLevel monitoringLevel = MonitoringLevel.enhanced,
  }) {
    return CommandValidationResult._(
      isAllowed: false,
      reason: reason,
      riskLevel: riskLevel,
      requiresApproval: true,
      monitoringLevel: monitoringLevel,
      approvalId: approvalId,
      isPendingApproval: true,
    );
  }
}

/// Dangerous command detector
class DangerousCommandDetector {
  final Map<String, DangerLevel> _dangerousCommands = {
    // Critical system commands
    'format': DangerLevel.critical,
    'fdisk': DangerLevel.critical,
    'mkfs': DangerLevel.critical,
    'dd': DangerLevel.critical,
    'shred': DangerLevel.critical,
    'wipe': DangerLevel.critical,
    
    // High-risk commands
    'rm': DangerLevel.high,
    'del': DangerLevel.high,
    'rmdir': DangerLevel.high,
    'sudo': DangerLevel.high,
    'su': DangerLevel.high,
    'chmod': DangerLevel.high,
    'chown': DangerLevel.high,
    'kill': DangerLevel.high,
    'killall': DangerLevel.high,
    'pkill': DangerLevel.high,
    
    // Medium-risk commands
    'curl': DangerLevel.medium,
    'wget': DangerLevel.medium,
    'ssh': DangerLevel.medium,
    'scp': DangerLevel.medium,
    'nc': DangerLevel.medium,
    'netcat': DangerLevel.medium,
    'telnet': DangerLevel.medium,
    'ftp': DangerLevel.medium,
  };

  Future<CommandValidationResult> checkCommand(ParsedCommand command) async {
    final executable = command.executable.toLowerCase();
    final dangerLevel = _dangerousCommands[executable];

    if (dangerLevel == null) {
      return CommandValidationResult.allowed(
        riskLevel: RiskLevel.low,
        requiresApproval: false,
        monitoringLevel: MonitoringLevel.basic,
        reason: 'Command not in dangerous command list',
      );
    }

    final riskLevel = _dangerLevelToRiskLevel(dangerLevel);
    final requiresApproval = dangerLevel.index >= DangerLevel.high.index;

    // Check for specific dangerous argument patterns
    final dangerousArgs = _checkDangerousArguments(command);
    if (dangerousArgs.isNotEmpty) {
      return CommandValidationResult.denied(
        reason: 'Dangerous argument patterns detected: ${dangerousArgs.join(', ')}',
        riskLevel: RiskLevel.critical,
      );
    }

    return CommandValidationResult.allowed(
      riskLevel: riskLevel,
      requiresApproval: requiresApproval,
      monitoringLevel: _getMonitoringLevelForDanger(dangerLevel),
      reason: 'Dangerous command detected: $executable (${dangerLevel.name})',
    );
  }

  List<String> _checkDangerousArguments(ParsedCommand command) {
    final dangerous = <String>[];
    
    for (final arg in command.arguments) {
      // Check for force flags
      if (['--force', '-f', '/f', '--recursive', '-r', '/s'].contains(arg.toLowerCase())) {
        dangerous.add('force/recursive flag: $arg');
      }
      
      // Check for system paths
      final systemPaths = ['/etc/', '/usr/', '/System/', 'C:\\Windows\\', 'C:\\Program Files\\'];
      if (systemPaths.any((path) => arg.toLowerCase().contains(path.toLowerCase()))) {
        dangerous.add('system path: $arg');
      }
      
      // Check for wildcards with dangerous commands
      if (arg.contains('*') && ['rm', 'del', 'format'].contains(command.executable.toLowerCase())) {
        dangerous.add('wildcard with dangerous command: $arg');
      }
    }
    
    return dangerous;
  }

  RiskLevel _dangerLevelToRiskLevel(DangerLevel dangerLevel) {
    switch (dangerLevel) {
      case DangerLevel.low:
        return RiskLevel.low;
      case DangerLevel.medium:
        return RiskLevel.medium;
      case DangerLevel.high:
        return RiskLevel.high;
      case DangerLevel.critical:
        return RiskLevel.critical;
    }
  }

  MonitoringLevel _getMonitoringLevelForDanger(DangerLevel dangerLevel) {
    switch (dangerLevel) {
      case DangerLevel.low:
        return MonitoringLevel.basic;
      case DangerLevel.medium:
        return MonitoringLevel.enhanced;
      case DangerLevel.high:
      case DangerLevel.critical:
        return MonitoringLevel.comprehensive;
    }
  }
}

/// Command pattern analyzer
class CommandPatternAnalyzer {
  final Map<String, List<CommandPattern>> _agentPatterns = {};

  Future<CommandValidationResult> analyzeCommand(String agentId, ParsedCommand command) async {
    // Track command patterns for this agent
    _trackCommandPattern(agentId, command);
    
    // Analyze for suspicious patterns
    final suspiciousPatterns = _detectSuspiciousPatterns(agentId, command);
    
    if (suspiciousPatterns.isNotEmpty) {
      return CommandValidationResult.allowed(
        riskLevel: RiskLevel.high,
        requiresApproval: true,
        monitoringLevel: MonitoringLevel.comprehensive,
        reason: 'Suspicious patterns detected: ${suspiciousPatterns.join(', ')}',
      );
    }

    return CommandValidationResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
      reason: 'No suspicious patterns detected',
    );
  }

  void _trackCommandPattern(String agentId, ParsedCommand command) {
    final patterns = _agentPatterns[agentId] ?? <CommandPattern>[];
    
    patterns.add(CommandPattern(
      executable: command.executable,
      argumentCount: command.arguments.length,
      timestamp: DateTime.now(),
    ));
    
    // Keep only last 100 patterns
    if (patterns.length > 100) {
      patterns.removeRange(0, patterns.length - 100);
    }
    
    _agentPatterns[agentId] = patterns;
  }

  List<String> _detectSuspiciousPatterns(String agentId, ParsedCommand command) {
    final patterns = _agentPatterns[agentId] ?? <CommandPattern>[];
    final suspicious = <String>[];
    
    // Check for rapid command execution
    final recentCommands = patterns.where((p) => 
        DateTime.now().difference(p.timestamp) < const Duration(seconds: 10)).length;
    
    if (recentCommands > 5) {
      suspicious.add('rapid command execution');
    }
    
    // Check for repeated dangerous commands
    final recentDangerous = patterns.where((p) => 
        DateTime.now().difference(p.timestamp) < const Duration(minutes: 1) &&
        ['rm', 'del', 'kill', 'sudo'].contains(p.executable.toLowerCase())).length;
    
    if (recentDangerous > 2) {
      suspicious.add('repeated dangerous commands');
    }
    
    return suspicious;
  }
}

/// Command approval workflow
class CommandApprovalWorkflow {
  final Map<String, PendingApproval> _pendingApprovals = {};
  int _nextApprovalId = 1;

  Future<String> submitForApproval(
    String agentId,
    String command,
    RiskLevel riskLevel,
    String reason,
  ) async {
    final approvalId = 'approval_${_nextApprovalId++}';
    
    final approval = PendingApproval(
      id: approvalId,
      agentId: agentId,
      command: command,
      riskLevel: riskLevel,
      reason: reason,
      submittedAt: DateTime.now(),
      status: ApprovalStatus.pending,
    );
    
    _pendingApprovals[approvalId] = approval;
    
    return approvalId;
  }

  Future<ApprovalStatus> getApprovalStatus(String approvalId) async {
    final approval = _pendingApprovals[approvalId];
    return approval?.status ?? ApprovalStatus.notFound;
  }

  Future<bool> approveCommand(String approvalId, String approverUserId, {String? reason}) async {
    final approval = _pendingApprovals[approvalId];
    if (approval == null || approval.status != ApprovalStatus.pending) {
      return false;
    }

    approval.status = ApprovalStatus.approved;
    approval.approverUserId = approverUserId;
    approval.approverReason = reason;
    approval.decidedAt = DateTime.now();

    return true;
  }

  Future<bool> rejectCommand(String approvalId, String approverUserId, {String? reason}) async {
    final approval = _pendingApprovals[approvalId];
    if (approval == null || approval.status != ApprovalStatus.pending) {
      return false;
    }

    approval.status = ApprovalStatus.rejected;
    approval.approverUserId = approverUserId;
    approval.approverReason = reason;
    approval.decidedAt = DateTime.now();

    return true;
  }

  List<PendingApproval> getPendingApprovals() {
    return _pendingApprovals.values
        .where((approval) => approval.status == ApprovalStatus.pending)
        .toList();
  }
}

/// Command monitor
class CommandMonitor {
  final String agentId;
  final List<CommandValidationLog> _logs = [];
  final Map<String, int> _commandCounts = {};

  CommandMonitor(this.agentId);

  void logValidation(String command, bool allowed, String reason) {
    final log = CommandValidationLog(
      agentId: agentId,
      command: command,
      allowed: allowed,
      reason: reason,
      timestamp: DateTime.now(),
    );

    _logs.add(log);
    
    // Keep only last 1000 logs
    if (_logs.length > 1000) {
      _logs.removeRange(0, _logs.length - 1000);
    }

    // Update command counts
    final executable = command.split(' ').first;
    _commandCounts[executable] = (_commandCounts[executable] ?? 0) + 1;
  }

  List<CommandValidationLog> getLogs() => List.unmodifiable(_logs);

  CommandValidationStats getStats() {
    final totalValidations = _logs.length;
    final allowedValidations = _logs.where((log) => log.allowed).length;
    final deniedValidations = totalValidations - allowedValidations;

    return CommandValidationStats(
      agentId: agentId,
      totalValidations: totalValidations,
      allowedValidations: allowedValidations,
      deniedValidations: deniedValidations,
      commandCounts: Map.unmodifiable(_commandCounts),
      lastValidation: _logs.isNotEmpty ? _logs.last.timestamp : null,
    );
  }
}

/// Supporting classes and enums

enum DangerLevel {
  low,
  medium,
  high,
  critical,
}

enum ApprovalStatus {
  pending,
  approved,
  rejected,
  expired,
  notFound,
}

class CommandPattern {
  final String executable;
  final int argumentCount;
  final DateTime timestamp;

  CommandPattern({
    required this.executable,
    required this.argumentCount,
    required this.timestamp,
  });
}

class PendingApproval {
  final String id;
  final String agentId;
  final String command;
  final RiskLevel riskLevel;
  final String reason;
  final DateTime submittedAt;
  ApprovalStatus status;
  String? approverUserId;
  String? approverReason;
  DateTime? decidedAt;

  PendingApproval({
    required this.id,
    required this.agentId,
    required this.command,
    required this.riskLevel,
    required this.reason,
    required this.submittedAt,
    required this.status,
    this.approverUserId,
    this.approverReason,
    this.decidedAt,
  });
}

class CommandValidationLog {
  final String agentId;
  final String command;
  final bool allowed;
  final String reason;
  final DateTime timestamp;

  const CommandValidationLog({
    required this.agentId,
    required this.command,
    required this.allowed,
    required this.reason,
    required this.timestamp,
  });
}

class CommandValidationStats {
  final String agentId;
  final int totalValidations;
  final int allowedValidations;
  final int deniedValidations;
  final Map<String, int> commandCounts;
  final DateTime? lastValidation;

  const CommandValidationStats({
    required this.agentId,
    required this.totalValidations,
    required this.allowedValidations,
    required this.deniedValidations,
    required this.commandCounts,
    this.lastValidation,
  });

  factory CommandValidationStats.empty() {
    return const CommandValidationStats(
      agentId: '',
      totalValidations: 0,
      allowedValidations: 0,
      deniedValidations: 0,
      commandCounts: {},
    );
  }

  double get allowedRate {
    if (totalValidations == 0) return 0.0;
    return allowedValidations / totalValidations;
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