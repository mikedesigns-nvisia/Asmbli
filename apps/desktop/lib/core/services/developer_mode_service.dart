import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mcp_safety_service.dart';
import 'mcp_user_interface_service.dart';

/// Developer Mode Service - The Escape Hatch for Power Users
/// 
/// Following Anthropic PM philosophy:
/// - Hidden by default (progressive disclosure)
/// - Clear warnings about risks
/// - Full transparency when enabled
/// - Comprehensive logging and audit trail
/// - Can be disabled by enterprise policies
class DeveloperModeService {
  final MCPSafetyService _safetyService;
  final MCPUserInterfaceService _uiService;
  final StreamController<TerminalEvent> _terminalController;
  final List<TerminalSession> _activeSessions = [];
  final List<CommandHistoryEntry> _commandHistory = [];
  
  bool _isDeveloperModeEnabled = false;
  bool _isTerminalVisible = false;
  String? _currentSessionId;

  DeveloperModeService(this._safetyService, this._uiService) 
    : _terminalController = StreamController<TerminalEvent>.broadcast();

  /// Stream of terminal events
  Stream<TerminalEvent> get terminalEvents => _terminalController.stream;

  /// Whether developer mode is currently enabled
  bool get isDeveloperModeEnabled => _isDeveloperModeEnabled;

  /// Whether terminal is currently visible
  bool get isTerminalVisible => _isTerminalVisible;

  /// Command history for debugging and audit
  List<CommandHistoryEntry> get commandHistory => List.unmodifiable(_commandHistory);

  /// Enable developer mode with proper warnings
  Future<bool> enableDeveloperMode() async {
    if (_isDeveloperModeEnabled) return true;

    // Show scary but honest warning
    final approved = await _showDeveloperModeWarning();
    if (!approved) return false;

    _isDeveloperModeEnabled = true;
    
    // Log the activation
    _logEvent(DevLogLevel.warning, 'Developer Mode ENABLED - Full system access granted');
    
    // Emit event for UI updates
    _terminalController.add(TerminalEvent.developerModeChanged(enabled: true));
    
    return true;
  }

  /// Disable developer mode
  void disableDeveloperMode() {
    if (!_isDeveloperModeEnabled) return;

    _isDeveloperModeEnabled = false;
    _isTerminalVisible = false;
    
    // Kill all active sessions
    for (final session in _activeSessions) {
      session.kill();
    }
    _activeSessions.clear();
    _currentSessionId = null;

    _logEvent(DevLogLevel.info, 'Developer Mode DISABLED - Restricted access restored');
    
    _terminalController.add(TerminalEvent.developerModeChanged(enabled: false));
  }

  /// Show/hide terminal interface
  void toggleTerminal() {
    if (!_isDeveloperModeEnabled) return;
    
    _isTerminalVisible = !_isTerminalVisible;
    _terminalController.add(TerminalEvent.terminalVisibilityChanged(visible: _isTerminalVisible));
    
    if (_isTerminalVisible && _currentSessionId == null) {
      // Create initial terminal session
      createTerminalSession();
    }
  }

  /// Create a new terminal session
  String createTerminalSession({String? workingDirectory}) {
    if (!_isDeveloperModeEnabled) {
      throw StateError('Developer mode must be enabled to create terminal sessions');
    }

    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final session = TerminalSession(
      id: sessionId,
      workingDirectory: workingDirectory ?? Directory.current.path,
      onOutput: (output) => _handleSessionOutput(sessionId, output),
      onError: (error) => _handleSessionError(sessionId, error),
      onExit: (exitCode) => _handleSessionExit(sessionId, exitCode),
    );

    _activeSessions.add(session);
    _currentSessionId ??= sessionId; // Set as current if no active session

    _logEvent(DevLogLevel.info, 'Terminal session created: $sessionId');
    
    _terminalController.add(TerminalEvent.sessionCreated(
      sessionId: sessionId,
      workingDirectory: session.workingDirectory,
    ));

    return sessionId;
  }

  /// Execute command in current terminal session
  Future<CommandResult> executeCommand(String command, {
    String? sessionId,
    bool requiresApproval = true,
  }) async {
    if (!_isDeveloperModeEnabled) {
      return CommandResult.error('Developer mode is not enabled');
    }

    final targetSessionId = sessionId ?? _currentSessionId;
    if (targetSessionId == null) {
      return CommandResult.error('No active terminal session');
    }

    final session = _activeSessions.where((s) => s.id == targetSessionId).firstOrNull;
    if (session == null) {
      return CommandResult.error('Terminal session not found: $targetSessionId');
    }

    // Safety check even in developer mode
    final safetyDecision = await _safetyService.evaluateCommand(
      command,
      context: 'Developer Mode Terminal',
    );

    // Show approval dialog for risky commands (unless overridden)
    if (requiresApproval && safetyDecision.requiresApproval) {
      final approved = await _uiService.requestCommandApproval(
        command,
        safetyDecision.explanation,
        risk: safetyDecision.reason,
      );
      
      if (!approved) {
        _logCommand(command, CommandStatus.cancelled, 'User cancelled');
        return CommandResult.cancelled();
      }
    }

    // Block genuinely dangerous commands even in dev mode
    if (!safetyDecision.isAllowed) {
      _logCommand(command, CommandStatus.blocked, safetyDecision.reason ?? 'Safety check failed');
      return CommandResult.blocked(safetyDecision.reason ?? 'Command blocked for safety');
    }

    // Log command execution
    _logCommand(command, CommandStatus.executing, 'Executing in session $targetSessionId');

    try {
      // Execute command in session
      final result = await session.executeCommand(command);
      
      // Log result
      _logCommand(command, CommandStatus.completed, 'Exit code: ${result.exitCode}');
      
      return result;
    } catch (e) {
      _logCommand(command, CommandStatus.failed, e.toString());
      return CommandResult.error(e.toString());
    }
  }

  /// Send input to interactive command
  Future<void> sendInput(String input, {String? sessionId}) async {
    final targetSessionId = sessionId ?? _currentSessionId;
    if (targetSessionId == null) return;

    final session = _activeSessions.where((s) => s.id == targetSessionId).firstOrNull;
    if (session == null) return;

    await session.sendInput(input);
    _logEvent(DevLogLevel.debug, 'Input sent to session $targetSessionId: $input');
  }

  /// Get session output history
  List<String> getSessionOutput(String sessionId) {
    final session = _activeSessions.where((s) => s.id == sessionId).firstOrNull;
    return session?.outputHistory ?? [];
  }

  /// Kill a terminal session
  void killSession(String sessionId) {
    final session = _activeSessions.where((s) => s.id == sessionId).firstOrNull;
    if (session == null) return;

    session.kill();
    _activeSessions.removeWhere((s) => s.id == sessionId);
    
    if (_currentSessionId == sessionId) {
      _currentSessionId = _activeSessions.isNotEmpty ? _activeSessions.first.id : null;
    }

    _logEvent(DevLogLevel.info, 'Terminal session killed: $sessionId');
    
    _terminalController.add(TerminalEvent.sessionClosed(sessionId: sessionId));
  }

  /// Switch to different session
  void switchToSession(String sessionId) {
    if (_activeSessions.any((s) => s.id == sessionId)) {
      _currentSessionId = sessionId;
      _terminalController.add(TerminalEvent.sessionSwitched(sessionId: sessionId));
    }
  }

  /// Get comprehensive system information for debugging
  Future<SystemInfo> getSystemInfo() async {
    return SystemInfo(
      platform: Platform.operatingSystem,
      version: Platform.operatingSystemVersion,
      dartVersion: Platform.version,
      environment: Platform.environment,
      executablePath: Platform.resolvedExecutable,
      workingDirectory: Directory.current.path,
      availableCommands: await _getAvailableCommands(),
    );
  }

  /// Show developer mode warning dialog
  Future<bool> _showDeveloperModeWarning() async {
    // This would be implemented by the UI service
    // For now, return a mock approval
    return true;
  }

  /// Handle output from terminal session
  void _handleSessionOutput(String sessionId, String output) {
    _terminalController.add(TerminalEvent.output(
      sessionId: sessionId,
      content: output,
      isError: false,
    ));
  }

  /// Handle error from terminal session
  void _handleSessionError(String sessionId, String error) {
    _terminalController.add(TerminalEvent.output(
      sessionId: sessionId,
      content: error,
      isError: true,
    ));
  }

  /// Handle session exit
  void _handleSessionExit(String sessionId, int exitCode) {
    _terminalController.add(TerminalEvent.sessionExited(
      sessionId: sessionId,
      exitCode: exitCode,
    ));
    
    // Remove session from active list
    _activeSessions.removeWhere((s) => s.id == sessionId);
    
    if (_currentSessionId == sessionId) {
      _currentSessionId = _activeSessions.isNotEmpty ? _activeSessions.first.id : null;
    }
  }

  /// Log command execution for audit trail
  void _logCommand(String command, CommandStatus status, String details) {
    final entry = CommandHistoryEntry(
      command: command,
      status: status,
      timestamp: DateTime.now(),
      details: details,
      sessionId: _currentSessionId,
    );
    
    _commandHistory.add(entry);
    
    // Keep only last 1000 commands
    if (_commandHistory.length > 1000) {
      _commandHistory.removeAt(0);
    }
    
    _terminalController.add(TerminalEvent.commandLogged(entry: entry));
  }

  /// Log general developer mode events
  void _logEvent(DevLogLevel level, String message) {
    final entry = CommandHistoryEntry(
      command: '[SYSTEM]',
      status: CommandStatus.info,
      timestamp: DateTime.now(),
      details: message,
      sessionId: null,
    );
    
    _commandHistory.add(entry);
    
    _terminalController.add(TerminalEvent.eventLogged(
      level: level,
      message: message,
    ));
  }

  /// Get list of available commands on the system
  Future<List<String>> _getAvailableCommands() async {
    final commonCommands = ['npm', 'git', 'python', 'pip', 'node', 'dart', 'flutter'];
    final available = <String>[];
    
    for (final command in commonCommands) {
      try {
        final result = await Process.run(
          Platform.isWindows ? 'where' : 'which',
          [command],
          runInShell: true,
        );
        if (result.exitCode == 0) {
          available.add(command);
        }
      } catch (e) {
        // Command not available
      }
    }
    
    return available;
  }

  void dispose() {
    for (final session in _activeSessions) {
      session.kill();
    }
    _activeSessions.clear();
    _terminalController.close();
  }
}

/// Terminal session management
class TerminalSession {
  final String id;
  final String workingDirectory;
  final Function(String) onOutput;
  final Function(String) onError;
  final Function(int) onExit;
  final List<String> outputHistory = [];
  
  Process? _process;
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;

  TerminalSession({
    required this.id,
    required this.workingDirectory,
    required this.onOutput,
    required this.onError,
    required this.onExit,
  });

  /// Execute a command in this session
  Future<CommandResult> executeCommand(String command) async {
    try {
      final parts = command.split(' ');
      final executable = parts.first;
      final args = parts.length > 1 ? parts.sublist(1) : <String>[];

      final process = await Process.start(
        executable,
        args,
        workingDirectory: workingDirectory,
        runInShell: true,
      );

      final outputBuffer = StringBuffer();
      final errorBuffer = StringBuffer();

      // Listen to output
      final stdoutCompleter = Completer<void>();
      final stderrCompleter = Completer<void>();

      process.stdout.transform(utf8.decoder).listen(
        (data) {
          outputBuffer.write(data);
          outputHistory.add(data);
          onOutput(data);
        },
        onDone: () => stdoutCompleter.complete(),
      );

      process.stderr.transform(utf8.decoder).listen(
        (data) {
          errorBuffer.write(data);
          outputHistory.add(data);
          onError(data);
        },
        onDone: () => stderrCompleter.complete(),
      );

      // Wait for process to complete
      final exitCode = await process.exitCode;
      await Future.wait([stdoutCompleter.future, stderrCompleter.future]);

      return CommandResult.success(
        exitCode: exitCode,
        stdout: outputBuffer.toString(),
        stderr: errorBuffer.toString(),
      );
    } catch (e) {
      return CommandResult.error(e.toString());
    }
  }

  /// Send input to interactive process
  Future<void> sendInput(String input) async {
    if (_process != null) {
      _process!.stdin.writeln(input);
      await _process!.stdin.flush();
    }
  }

  /// Kill the session
  void kill() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _process?.kill();
    _process = null;
  }
}

/// Result of command execution
class CommandResult {
  final bool success;
  final int? exitCode;
  final String? stdout;
  final String? stderr;
  final String? error;
  final CommandResultType type;

  const CommandResult._({
    required this.success,
    this.exitCode,
    this.stdout,
    this.stderr,
    this.error,
    required this.type,
  });

  factory CommandResult.success({
    required int exitCode,
    required String stdout,
    required String stderr,
  }) {
    return CommandResult._(
      success: exitCode == 0,
      exitCode: exitCode,
      stdout: stdout,
      stderr: stderr,
      type: CommandResultType.completed,
    );
  }

  factory CommandResult.error(String error) {
    return CommandResult._(
      success: false,
      error: error,
      type: CommandResultType.error,
    );
  }

  factory CommandResult.cancelled() {
    return const CommandResult._(
      success: false,
      type: CommandResultType.cancelled,
    );
  }

  factory CommandResult.blocked(String reason) {
    return CommandResult._(
      success: false,
      error: reason,
      type: CommandResultType.blocked,
    );
  }
}

enum CommandResultType {
  completed,
  error,
  cancelled,
  blocked,
}

/// Command history entry for audit trail
class CommandHistoryEntry {
  final String command;
  final CommandStatus status;
  final DateTime timestamp;
  final String details;
  final String? sessionId;

  const CommandHistoryEntry({
    required this.command,
    required this.status,
    required this.timestamp,
    required this.details,
    this.sessionId,
  });
}

enum CommandStatus {
  executing,
  completed,
  failed,
  cancelled,
  blocked,
  info,
}

/// Terminal events for UI updates
class TerminalEvent {
  final TerminalEventType type;
  final Map<String, dynamic> data;

  const TerminalEvent._(this.type, this.data);

  factory TerminalEvent.developerModeChanged({required bool enabled}) {
    return TerminalEvent._(TerminalEventType.developerModeChanged, {'enabled': enabled});
  }

  factory TerminalEvent.terminalVisibilityChanged({required bool visible}) {
    return TerminalEvent._(TerminalEventType.terminalVisibilityChanged, {'visible': visible});
  }

  factory TerminalEvent.sessionCreated({
    required String sessionId,
    required String workingDirectory,
  }) {
    return TerminalEvent._(TerminalEventType.sessionCreated, {
      'sessionId': sessionId,
      'workingDirectory': workingDirectory,
    });
  }

  factory TerminalEvent.sessionClosed({required String sessionId}) {
    return TerminalEvent._(TerminalEventType.sessionClosed, {'sessionId': sessionId});
  }

  factory TerminalEvent.sessionSwitched({required String sessionId}) {
    return TerminalEvent._(TerminalEventType.sessionSwitched, {'sessionId': sessionId});
  }

  factory TerminalEvent.sessionExited({
    required String sessionId,
    required int exitCode,
  }) {
    return TerminalEvent._(TerminalEventType.sessionExited, {
      'sessionId': sessionId,
      'exitCode': exitCode,
    });
  }

  factory TerminalEvent.output({
    required String sessionId,
    required String content,
    required bool isError,
  }) {
    return TerminalEvent._(TerminalEventType.output, {
      'sessionId': sessionId,
      'content': content,
      'isError': isError,
    });
  }

  factory TerminalEvent.commandLogged({required CommandHistoryEntry entry}) {
    return TerminalEvent._(TerminalEventType.commandLogged, {'entry': entry});
  }

  factory TerminalEvent.eventLogged({
    required DevLogLevel level,
    required String message,
  }) {
    return TerminalEvent._(TerminalEventType.eventLogged, {
      'level': level,
      'message': message,
    });
  }
}

enum TerminalEventType {
  developerModeChanged,
  terminalVisibilityChanged,
  sessionCreated,
  sessionClosed,
  sessionSwitched,
  sessionExited,
  output,
  commandLogged,
  eventLogged,
}

enum DevLogLevel {
  debug,
  info,
  warning,
  error,
}

/// System information for debugging
class SystemInfo {
  final String platform;
  final String version;
  final String dartVersion;
  final Map<String, String> environment;
  final String executablePath;
  final String workingDirectory;
  final List<String> availableCommands;

  const SystemInfo({
    required this.platform,
    required this.version,
    required this.dartVersion,
    required this.environment,
    required this.executablePath,
    required this.workingDirectory,
    required this.availableCommands,
  });

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'version': version,
    'dartVersion': dartVersion,
    'environment': environment,
    'executablePath': executablePath,
    'workingDirectory': workingDirectory,
    'availableCommands': availableCommands,
  };
}

/// Provider for Developer Mode Service
final developerModeServiceProvider = Provider<DeveloperModeService>((ref) {
  final safetyService = ref.watch(mcpSafetyServiceProvider);
  final uiService = ref.watch(mcpUserInterfaceServiceProvider);
  return DeveloperModeService(safetyService, uiService);
});