import 'package:flutter/foundation.dart';
import '../models/design_history.dart';

/// Service for managing design history and undo/redo
///
/// Week 3 Task 22: Provides history tracking for all canvas operations
class DesignHistoryService {
  DesignHistory _history = const DesignHistory();

  /// Get current history
  DesignHistory get history => _history;

  /// Can undo
  bool get canUndo => _history.canUndo;

  /// Can redo
  bool get canRedo => _history.canRedo;

  /// Add a history entry
  void addEntry(HistoryEntry entry) {
    _history = _history.addEntry(entry);
    debugPrint('📝 History: ${entry.description} (${_history.entries.length} entries)');
  }

  /// Undo last action
  HistoryEntry? undo() {
    if (!canUndo) {
      debugPrint('⚠️ Cannot undo - no previous entries');
      return null;
    }

    final currentEntry = _history.currentEntry;
    _history = _history.undo();

    debugPrint('⬅️ Undo: ${currentEntry?.description}');
    return currentEntry;
  }

  /// Redo last undone action
  HistoryEntry? redo() {
    if (!canRedo) {
      debugPrint('⚠️ Cannot redo - no future entries');
      return null;
    }

    _history = _history.redo();
    final newEntry = _history.currentEntry;

    debugPrint('➡️ Redo: ${newEntry?.description}');
    return newEntry;
  }

  /// Clear all history
  void clear() {
    _history = _history.clear();
    debugPrint('🗑️ History cleared');
  }

  /// Get recent entries
  List<HistoryEntry> getRecentEntries({int limit = 10}) {
    return _history.getRecentEntries(limit: limit);
  }

  /// Get full history summary
  Map<String, dynamic> getHistorySummary() {
    return {
      'totalEntries': _history.entries.length,
      'currentIndex': _history.currentIndex,
      'canUndo': canUndo,
      'canRedo': canRedo,
      'currentEntry': _history.currentEntry?.toJson(),
      'recentEntries': getRecentEntries(limit: 5).map((e) => e.toJson()).toList(),
    };
  }
}
