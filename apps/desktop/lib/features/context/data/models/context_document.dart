import 'package:equatable/equatable.dart';

/// Represents different types of context that can be stored
enum ContextType {
  documentation,
  codebase,
  guidelines,
  examples,
  knowledge,
  custom,
}

/// Extension to provide human-readable names for context types
extension ContextTypeExtension on ContextType {
  String get displayName {
    switch (this) {
      case ContextType.documentation:
        return 'Documentation';
      case ContextType.codebase:
        return 'Codebase';
      case ContextType.guidelines:
        return 'Guidelines';
      case ContextType.examples:
        return 'Examples';
      case ContextType.knowledge:
        return 'Knowledge Base';
      case ContextType.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case ContextType.documentation:
        return 'Technical documentation and API references';
      case ContextType.codebase:
        return 'Code snippets and project structure information';
      case ContextType.guidelines:
        return 'Coding standards and best practices';
      case ContextType.examples:
        return 'Example implementations and templates';
      case ContextType.knowledge:
        return 'Domain-specific knowledge and facts';
      case ContextType.custom:
        return 'Custom context defined by the user';
    }
  }
}

/// Represents a context document that can be assigned to agents
class ContextDocument extends Equatable {
  final String id;
  final String title;
  final String content;
  final ContextType type;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const ContextDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.metadata = const {},
  });

  ContextDocument copyWith({
    String? id,
    String? title,
    String? content,
    ContextType? type,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return ContextDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory ContextDocument.fromJson(Map<String, dynamic> json) {
    return ContextDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: ContextType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ContextType.custom,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        type,
        tags,
        createdAt,
        updatedAt,
        isActive,
        metadata,
      ];
}