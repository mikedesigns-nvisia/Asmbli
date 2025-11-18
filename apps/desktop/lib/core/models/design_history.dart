import 'package:equatable/equatable.dart';

/// Design history tracking for undo/redo capabilities
///
/// Week 3 Task 22: Track all canvas modifications and enable undo/redo
class DesignHistory extends Equatable {
  final List<HistoryEntry> entries;
  final int currentIndex;
  final int maxEntries;

  const DesignHistory({
    this.entries = const [],
    this.currentIndex = -1,
    this.maxEntries = 50,
  });

  /// Can undo (has previous entries)
  bool get canUndo => currentIndex >= 0;

  /// Can redo (has future entries)
  bool get canRedo => currentIndex < entries.length - 1;

  /// Get current entry
  HistoryEntry? get currentEntry {
    if (currentIndex >= 0 && currentIndex < entries.length) {
      return entries[currentIndex];
    }
    return null;
  }

  /// Add a new history entry
  DesignHistory addEntry(HistoryEntry entry) {
    // Remove any entries after current index (they're in the "future")
    final newEntries = entries.sublist(0, currentIndex + 1);

    // Add new entry
    newEntries.add(entry);

    // Limit to max entries (remove oldest if needed)
    final limitedEntries = newEntries.length > maxEntries
        ? newEntries.sublist(newEntries.length - maxEntries)
        : newEntries;

    return DesignHistory(
      entries: limitedEntries,
      currentIndex: limitedEntries.length - 1,
      maxEntries: maxEntries,
    );
  }

  /// Move to previous entry (undo)
  DesignHistory undo() {
    if (!canUndo) return this;

    return DesignHistory(
      entries: entries,
      currentIndex: currentIndex - 1,
      maxEntries: maxEntries,
    );
  }

  /// Move to next entry (redo)
  DesignHistory redo() {
    if (!canRedo) return this;

    return DesignHistory(
      entries: entries,
      currentIndex: currentIndex + 1,
      maxEntries: maxEntries,
    );
  }

  /// Clear all history
  DesignHistory clear() {
    return const DesignHistory();
  }

  /// Get recent entries (for display)
  List<HistoryEntry> getRecentEntries({int limit = 10}) {
    if (entries.isEmpty) return [];

    final startIndex = (currentIndex - limit + 1).clamp(0, entries.length);
    final endIndex = (currentIndex + 1).clamp(0, entries.length);

    return entries.sublist(startIndex, endIndex);
  }

  @override
  List<Object?> get props => [entries, currentIndex, maxEntries];
}

/// Single history entry
class HistoryEntry extends Equatable {
  final String id;
  final HistoryAction action;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String description;

  const HistoryEntry({
    required this.id,
    required this.action,
    required this.timestamp,
    required this.data,
    required this.description,
  });

  /// Create from JSON
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      action: HistoryAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => HistoryAction.unknown,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>,
      description: json['description'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, action, timestamp, data, description];
}

/// Types of history actions
enum HistoryAction {
  createElement,
  updateElement,
  deleteElement,
  createComponent,
  createStyle,
  applyLayout,
  clearCanvas,
  buildDesign,
  unknown,
}

/// Helper to create history entries
class HistoryEntryFactory {
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Create element action
  static HistoryEntry createElement({
    required String elementType,
    required Map<String, dynamic> elementData,
  }) {
    return HistoryEntry(
      id: _generateId(),
      action: HistoryAction.createElement,
      timestamp: DateTime.now(),
      data: {
        'elementType': elementType,
        'elementData': elementData,
      },
      description: 'Created $elementType',
    );
  }

  /// Update element action
  static HistoryEntry updateElement({
    required String elementId,
    required Map<String, dynamic> oldData,
    required Map<String, dynamic> newData,
  }) {
    return HistoryEntry(
      id: _generateId(),
      action: HistoryAction.updateElement,
      timestamp: DateTime.now(),
      data: {
        'elementId': elementId,
        'oldData': oldData,
        'newData': newData,
      },
      description: 'Updated element',
    );
  }

  /// Delete element action
  static HistoryEntry deleteElement({
    required String elementId,
    required Map<String, dynamic> elementData,
  }) {
    return HistoryEntry(
      id: _generateId(),
      action: HistoryAction.deleteElement,
      timestamp: DateTime.now(),
      data: {
        'elementId': elementId,
        'elementData': elementData,
      },
      description: 'Deleted element',
    );
  }

  /// Create component action
  static HistoryEntry createComponent({
    required String componentId,
    required String componentName,
    required List<String> elementIds,
  }) {
    return HistoryEntry(
      id: _generateId(),
      action: HistoryAction.createComponent,
      timestamp: DateTime.now(),
      data: {
        'componentId': componentId,
        'componentName': componentName,
        'elementIds': elementIds,
      },
      description: 'Created component: $componentName',
    );
  }

  /// Create style action
  static HistoryEntry createStyle({
    required String styleId,
    required String styleName,
    required String styleType,
    required Map<String, dynamic> styleData,
  }) {
    return HistoryEntry(
      id: _generateId(),
      action: HistoryAction.createStyle,
      timestamp: DateTime.now(),
      data: {
        'styleId': styleId,
        'styleName': styleName,
        'styleType': styleType,
        'styleData': styleData,
      },
      description: 'Created $styleType style: $styleName',
    );
  }

  /// Apply layout action
  static HistoryEntry applyLayout({
    required String elementId,
    required Map<String, dynamic> layoutData,
  }) {
    return HistoryEntry(
      id: _generateId(),
      action: HistoryAction.applyLayout,
      timestamp: DateTime.now(),
      data: {
        'elementId': elementId,
        'layoutData': layoutData,
      },
      description: 'Applied layout',
    );
  }

  /// Clear canvas action
  static HistoryEntry clearCanvas({
    required List<Map<String, dynamic>> deletedElements,
  }) {
    return HistoryEntry(
      id: _generateId(),
      action: HistoryAction.clearCanvas,
      timestamp: DateTime.now(),
      data: {
        'deletedElements': deletedElements,
      },
      description: 'Cleared canvas (${deletedElements.length} elements)',
    );
  }

  /// Build design action
  static HistoryEntry buildDesign({
    required Map<String, dynamic> designSpec,
    required List<String> createdElementIds,
  }) {
    return HistoryEntry(
      id: _generateId(),
      action: HistoryAction.buildDesign,
      timestamp: DateTime.now(),
      data: {
        'designSpec': designSpec,
        'createdElementIds': createdElementIds,
      },
      description: 'Built design (${createdElementIds.length} elements)',
    );
  }
}
