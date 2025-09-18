import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/agent_terminal.dart';
import 'production_logger.dart';
import 'agent_terminal_manager.dart';

/// Service for persisting and restoring terminal sessions
class TerminalSessionService {
  final AgentTerminalManager _terminalManager;
  final String _sessionsDirectory;
  
  TerminalSessionService(this._terminalManager, {String? sessionsDirectory})
      : _sessionsDirectory = sessionsDirectory ?? _getDefaultSessionsDirectory();

  static String _getDefaultSessionsDirectory() {
    final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return path.join(homeDir, '.kiro', 'terminal_sessions');
  }

  /// Save terminal session state to disk
  Future<void> saveTerminalSession(String agentId) async {
    try {
      final sessionState = _terminalManager.getTerminalState(agentId);
      final sessionFile = path.join(_sessionsDirectory, '$agentId.json');
      
      // Ensure directory exists
      final directory = Directory(_sessionsDirectory);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Write session data
      final file = File(sessionFile);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(sessionState),
      );

      ProductionLogger.instance.info(
        'Terminal session saved',
        data: {'agent_id': agentId, 'file': sessionFile},
        category: 'terminal_session',
      );
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to save terminal session',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_session',
      );
      rethrow;
    }
  }

  /// Load terminal session state from disk
  Future<Map<String, dynamic>?> loadTerminalSession(String agentId) async {
    try {
      final sessionFile = path.join(_sessionsDirectory, '$agentId.json');
      final file = File(sessionFile);

      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final sessionState = jsonDecode(content) as Map<String, dynamic>;

      ProductionLogger.instance.info(
        'Terminal session loaded',
        data: {'agent_id': agentId, 'file': sessionFile},
        category: 'terminal_session',
      );

      return sessionState;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to load terminal session',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_session',
      );
      return null;
    }
  }

  /// Restore terminal from saved session
  Future<AgentTerminal?> restoreTerminalSession(String agentId) async {
    final sessionState = await loadTerminalSession(agentId);
    if (sessionState == null) {
      return null;
    }

    try {
      return await _terminalManager.restoreTerminalState(agentId, sessionState);
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to restore terminal from session',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_session',
      );
      return null;
    }
  }

  /// Delete terminal session file
  Future<void> deleteTerminalSession(String agentId) async {
    try {
      final sessionFile = path.join(_sessionsDirectory, '$agentId.json');
      final file = File(sessionFile);

      if (await file.exists()) {
        await file.delete();
        ProductionLogger.instance.info(
          'Terminal session deleted',
          data: {'agent_id': agentId, 'file': sessionFile},
          category: 'terminal_session',
        );
      }
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to delete terminal session',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_session',
      );
    }
  }

  /// List all saved terminal sessions
  Future<List<String>> listTerminalSessions() async {
    try {
      final directory = Directory(_sessionsDirectory);
      if (!await directory.exists()) {
        return [];
      }

      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      return files
          .map((file) => path.basenameWithoutExtension(file.path))
          .toList();
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to list terminal sessions',
        error: e,
        category: 'terminal_session',
      );
      return [];
    }
  }

  /// Save all active terminal sessions
  Future<void> saveAllActiveSessions() async {
    final activeTerminals = _terminalManager.getActiveTerminals();
    
    final futures = activeTerminals.map((terminal) => 
        saveTerminalSession(terminal.agentId));
    
    await Future.wait(futures);
    
    ProductionLogger.instance.info(
      'All active terminal sessions saved',
      data: {'count': activeTerminals.length},
      category: 'terminal_session',
    );
  }

  /// Restore all saved terminal sessions
  Future<List<AgentTerminal>> restoreAllSessions() async {
    final sessionIds = await listTerminalSessions();
    final restoredTerminals = <AgentTerminal>[];

    for (final agentId in sessionIds) {
      try {
        final terminal = await restoreTerminalSession(agentId);
        if (terminal != null) {
          restoredTerminals.add(terminal);
        }
      } catch (e) {
        ProductionLogger.instance.error(
          'Failed to restore session during bulk restore',
          error: e,
          data: {'agent_id': agentId},
          category: 'terminal_session',
        );
      }
    }

    ProductionLogger.instance.info(
      'Terminal sessions restored',
      data: {
        'total_sessions': sessionIds.length,
        'restored_count': restoredTerminals.length,
      },
      category: 'terminal_session',
    );

    return restoredTerminals;
  }

  /// Clean up old session files
  Future<void> cleanupOldSessions({Duration maxAge = const Duration(days: 30)}) async {
    try {
      final directory = Directory(_sessionsDirectory);
      if (!await directory.exists()) {
        return;
      }

      final cutoffTime = DateTime.now().subtract(maxAge);
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      int deletedCount = 0;
      for (final file in files) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffTime)) {
          await file.delete();
          deletedCount++;
        }
      }

      ProductionLogger.instance.info(
        'Old terminal sessions cleaned up',
        data: {
          'deleted_count': deletedCount,
          'max_age_days': maxAge.inDays,
        },
        category: 'terminal_session',
      );
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to cleanup old sessions',
        error: e,
        category: 'terminal_session',
      );
    }
  }

  /// Get session file info
  Future<Map<String, dynamic>?> getSessionInfo(String agentId) async {
    try {
      final sessionFile = path.join(_sessionsDirectory, '$agentId.json');
      final file = File(sessionFile);

      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      final content = await file.readAsString();
      final sessionState = jsonDecode(content) as Map<String, dynamic>;

      return {
        'agentId': agentId,
        'filePath': sessionFile,
        'fileSize': stat.size,
        'lastModified': stat.modified.toIso8601String(),
        'createdAt': sessionState['createdAt'],
        'lastActivity': sessionState['lastActivity'],
        'commandCount': (sessionState['commandHistory'] as List?)?.length ?? 0,
        'mcpServerCount': (sessionState['mcpServers'] as List?)?.length ?? 0,
      };
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to get session info',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_session',
      );
      return null;
    }
  }

  /// Auto-save terminal session at regular intervals
  Timer? _autoSaveTimer;
  final Duration _autoSaveInterval = const Duration(minutes: 5);

  /// Start auto-save for active terminals
  void startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) async {
      await saveAllActiveSessions();
    });

    ProductionLogger.instance.info(
      'Auto-save started for terminal sessions',
      data: {'interval_minutes': _autoSaveInterval.inMinutes},
      category: 'terminal_session',
    );
  }

  /// Stop auto-save
  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;

    ProductionLogger.instance.info(
      'Auto-save stopped for terminal sessions',
      category: 'terminal_session',
    );
  }

  /// Save session with incremental backup
  Future<void> saveTerminalSessionWithBackup(String agentId) async {
    try {
      final sessionState = _terminalManager.getTerminalState(agentId);
      final sessionFile = path.join(_sessionsDirectory, '$agentId.json');
      final backupFile = path.join(_sessionsDirectory, '$agentId.backup.json');
      
      // Ensure directory exists
      final directory = Directory(_sessionsDirectory);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Create backup of existing session
      final existingFile = File(sessionFile);
      if (await existingFile.exists()) {
        await existingFile.copy(backupFile);
      }

      // Write new session data
      final file = File(sessionFile);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(sessionState),
      );

      ProductionLogger.instance.info(
        'Terminal session saved with backup',
        data: {'agent_id': agentId, 'file': sessionFile, 'backup': backupFile},
        category: 'terminal_session',
      );
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to save terminal session with backup',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_session',
      );
      rethrow;
    }
  }

  /// Restore session from backup if main session is corrupted
  Future<Map<String, dynamic>?> loadTerminalSessionWithFallback(String agentId) async {
    try {
      // Try to load main session first
      final mainSession = await loadTerminalSession(agentId);
      if (mainSession != null) {
        return mainSession;
      }

      // Try backup if main session failed
      final backupFile = path.join(_sessionsDirectory, '$agentId.backup.json');
      final file = File(backupFile);

      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final sessionState = jsonDecode(content) as Map<String, dynamic>;

      ProductionLogger.instance.info(
        'Terminal session loaded from backup',
        data: {'agent_id': agentId, 'file': backupFile},
        category: 'terminal_session',
      );

      return sessionState;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to load terminal session with fallback',
        error: e,
        data: {'agent_id': agentId},
        category: 'terminal_session',
      );
      return null;
    }
  }

  /// Get session statistics
  Future<Map<String, dynamic>> getSessionStatistics() async {
    try {
      final sessionIds = await listTerminalSessions();
      final stats = <String, dynamic>{
        'totalSessions': sessionIds.length,
        'activeSessions': 0,
        'totalCommands': 0,
        'totalMcpServers': 0,
        'oldestSession': null,
        'newestSession': null,
        'averageCommandsPerSession': 0.0,
      };

      DateTime? oldestDate;
      DateTime? newestDate;
      int totalCommands = 0;

      for (final agentId in sessionIds) {
        final sessionInfo = await getSessionInfo(agentId);
        if (sessionInfo != null) {
          // Check if session is active
          if (_terminalManager.getTerminal(agentId) != null) {
            stats['activeSessions'] = (stats['activeSessions'] as int) + 1;
          }

          // Accumulate command count
          final commandCount = sessionInfo['commandCount'] as int? ?? 0;
          totalCommands += commandCount;

          // Track oldest and newest sessions
          final lastModified = DateTime.parse(sessionInfo['lastModified'] as String);
          if (oldestDate == null || lastModified.isBefore(oldestDate)) {
            oldestDate = lastModified;
            stats['oldestSession'] = agentId;
          }
          if (newestDate == null || lastModified.isAfter(newestDate)) {
            newestDate = lastModified;
            stats['newestSession'] = agentId;
          }
        }
      }

      stats['totalCommands'] = totalCommands;
      stats['averageCommandsPerSession'] = sessionIds.isNotEmpty 
          ? totalCommands / sessionIds.length 
          : 0.0;

      return stats;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to get session statistics',
        error: e,
        category: 'terminal_session',
      );
      return {};
    }
  }

  /// Dispose resources
  void dispose() {
    stopAutoSave();
  }
}