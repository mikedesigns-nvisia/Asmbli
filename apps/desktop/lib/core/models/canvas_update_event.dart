/// Represents a real-time update event from the canvas
/// Used for Watch Mode to show agent operations in real-time
class CanvasUpdateEvent {
  final String id;
  final CanvasUpdateType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String? elementId;
  final String? toolName;
  final String? description;

  const CanvasUpdateEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
    this.elementId,
    this.toolName,
    this.description,
  });

  factory CanvasUpdateEvent.fromJson(Map<String, dynamic> json) {
    return CanvasUpdateEvent(
      id: json['id'] as String,
      type: CanvasUpdateType.values.firstWhere(
        (e) => e.toString() == 'CanvasUpdateType.${json['type']}',
        orElse: () => CanvasUpdateType.stateChanged,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>,
      elementId: json['elementId'] as String?,
      toolName: json['toolName'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      if (elementId != null) 'elementId': elementId,
      if (toolName != null) 'toolName': toolName,
      if (description != null) 'description': description,
    };
  }
}

/// Types of canvas update events
enum CanvasUpdateType {
  /// Element was created
  elementCreated,

  /// Element was updated
  elementUpdated,

  /// Element was deleted
  elementDeleted,

  /// Element was duplicated
  elementDuplicated,

  /// Elements were grouped
  elementsGrouped,

  /// Group was ungrouped
  elementsUngrouped,

  /// Element order changed
  elementReordered,

  /// Element was transformed (rotate, scale, etc.)
  elementTransformed,

  /// Style was applied
  styleApplied,

  /// Canvas was cleared
  canvasCleared,

  /// Export operation
  exportCompleted,

  /// Undo/redo operation
  historyChanged,

  /// General canvas state change
  stateChanged,
}

/// Extension to get user-friendly descriptions
extension CanvasUpdateTypeExtension on CanvasUpdateType {
  String get displayName {
    switch (this) {
      case CanvasUpdateType.elementCreated:
        return 'Created';
      case CanvasUpdateType.elementUpdated:
        return 'Updated';
      case CanvasUpdateType.elementDeleted:
        return 'Deleted';
      case CanvasUpdateType.elementDuplicated:
        return 'Duplicated';
      case CanvasUpdateType.elementsGrouped:
        return 'Grouped';
      case CanvasUpdateType.elementsUngrouped:
        return 'Ungrouped';
      case CanvasUpdateType.elementReordered:
        return 'Reordered';
      case CanvasUpdateType.elementTransformed:
        return 'Transformed';
      case CanvasUpdateType.styleApplied:
        return 'Styled';
      case CanvasUpdateType.canvasCleared:
        return 'Cleared';
      case CanvasUpdateType.exportCompleted:
        return 'Exported';
      case CanvasUpdateType.historyChanged:
        return 'History Changed';
      case CanvasUpdateType.stateChanged:
        return 'State Changed';
    }
  }

  String get icon {
    switch (this) {
      case CanvasUpdateType.elementCreated:
        return '➕';
      case CanvasUpdateType.elementUpdated:
        return '✏️';
      case CanvasUpdateType.elementDeleted:
        return '🗑️';
      case CanvasUpdateType.elementDuplicated:
        return '📋';
      case CanvasUpdateType.elementsGrouped:
        return '📦';
      case CanvasUpdateType.elementsUngrouped:
        return '📂';
      case CanvasUpdateType.elementReordered:
        return '🔀';
      case CanvasUpdateType.elementTransformed:
        return '🔄';
      case CanvasUpdateType.styleApplied:
        return '🎨';
      case CanvasUpdateType.canvasCleared:
        return '🧹';
      case CanvasUpdateType.exportCompleted:
        return '💾';
      case CanvasUpdateType.historyChanged:
        return '⏮️';
      case CanvasUpdateType.stateChanged:
        return '📊';
    }
  }
}
