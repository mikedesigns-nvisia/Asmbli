import 'package:equatable/equatable.dart';

/// Represents the assignment of context documents to an agent
class ContextAssignment extends Equatable {
  final String id;
  final String agentId;
  final String contextDocumentId;
  final DateTime assignedAt;
  final bool isActive;
  final int priority; // Higher number = higher priority
  final Map<String, dynamic> settings; // Agent-specific context settings

  const ContextAssignment({
    required this.id,
    required this.agentId,
    required this.contextDocumentId,
    required this.assignedAt,
    this.isActive = true,
    this.priority = 0,
    this.settings = const {},
  });

  ContextAssignment copyWith({
    String? id,
    String? agentId,
    String? contextDocumentId,
    DateTime? assignedAt,
    bool? isActive,
    int? priority,
    Map<String, dynamic>? settings,
  }) {
    return ContextAssignment(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      contextDocumentId: contextDocumentId ?? this.contextDocumentId,
      assignedAt: assignedAt ?? this.assignedAt,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'contextDocumentId': contextDocumentId,
      'assignedAt': assignedAt.toIso8601String(),
      'isActive': isActive,
      'priority': priority,
      'settings': settings,
    };
  }

  factory ContextAssignment.fromJson(Map<String, dynamic> json) {
    return ContextAssignment(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      contextDocumentId: json['contextDocumentId'] as String,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        agentId,
        contextDocumentId,
        assignedAt,
        isActive,
        priority,
        settings,
      ];
}