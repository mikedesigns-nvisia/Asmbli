import 'package:json_annotation/json_annotation.dart';

part 'logic_block.g.dart';

/// The seven core logic block types from Procedural Intelligence framework
enum LogicBlockType {
  @JsonValue('goal')
  goal,
  
  @JsonValue('context')
  context,
  
  @JsonValue('gateway')
  gateway,
  
  @JsonValue('reasoning')
  reasoning,
  
  @JsonValue('fallback')
  fallback,
  
  @JsonValue('trace')
  trace,
  
  @JsonValue('exit')
  exit,

  @JsonValue('human_verification')
  humanVerification,
}

/// Connection types for visual flow representation
enum ConnectionType {
  @JsonValue('execution')
  execution, // White/thick lines for control flow
  
  @JsonValue('data')
  data, // Colored lines for data flow
}

/// Visual position for canvas layout
@JsonSerializable()
class Position {
  final double x;
  final double y;
  
  const Position({
    required this.x,
    required this.y,
  });
  
  factory Position.fromJson(Map<String, dynamic> json) => _$PositionFromJson(json);
  Map<String, dynamic> toJson() => _$PositionToJson(this);
  
  Position copyWith({double? x, double? y}) {
    return Position(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

/// Connection between logic blocks
@JsonSerializable()
class BlockConnection {
  final String id;
  final String sourceBlockId;
  final String targetBlockId;
  final String sourcePin;
  final String targetPin;
  final ConnectionType type;
  
  const BlockConnection({
    required this.id,
    required this.sourceBlockId,
    required this.targetBlockId,
    required this.sourcePin,
    required this.targetPin,
    required this.type,
  });
  
  factory BlockConnection.fromJson(Map<String, dynamic> json) => _$BlockConnectionFromJson(json);
  Map<String, dynamic> toJson() => _$BlockConnectionToJson(this);
}

/// Individual logic block in the reasoning workflow
@JsonSerializable()
class LogicBlock {
  final String id;
  final LogicBlockType type;
  final String label;
  final Position position;
  final Map<String, dynamic> properties;
  final List<String> mcpToolIds; // Connected MCP tools
  
  const LogicBlock({
    required this.id,
    required this.type,
    required this.label,
    required this.position,
    this.properties = const {},
    this.mcpToolIds = const [],
  });
  
  factory LogicBlock.fromJson(Map<String, dynamic> json) => _$LogicBlockFromJson(json);
  Map<String, dynamic> toJson() => _$LogicBlockToJson(this);
  
  LogicBlock copyWith({
    String? id,
    LogicBlockType? type,
    String? label,
    Position? position,
    Map<String, dynamic>? properties,
    List<String>? mcpToolIds,
  }) {
    return LogicBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      position: position ?? this.position,
      properties: properties ?? this.properties,
      mcpToolIds: mcpToolIds ?? this.mcpToolIds,
    );
  }
  
  /// Get display color based on block type (following research recommendations)
  String get displayColor {
    switch (type) {
      case LogicBlockType.goal:
        return '#4CAF50'; // Green
      case LogicBlockType.context:
        return '#2196F3'; // Blue
      case LogicBlockType.gateway:
        return '#FF9800'; // Orange/Yellow
      case LogicBlockType.reasoning:
        return '#9C27B0'; // Purple
      case LogicBlockType.fallback:
        return '#F44336'; // Red
      case LogicBlockType.trace:
        return '#607D8B'; // Blue Grey
      case LogicBlockType.exit:
        return '#4CAF50'; // Green
      case LogicBlockType.humanVerification:
        return '#E91E63'; // Pink
    }
  }
  
  /// Get block icon based on type
  String get iconName {
    switch (type) {
      case LogicBlockType.goal:
        return 'target';
      case LogicBlockType.context:
        return 'filter';
      case LogicBlockType.gateway:
        return 'diamond';
      case LogicBlockType.reasoning:
        return 'psychology';
      case LogicBlockType.fallback:
        return 'error_outline';
      case LogicBlockType.trace:
        return 'timeline';
      case LogicBlockType.exit:
        return 'check_circle';
      case LogicBlockType.humanVerification:
        return 'verified_user';
    }
  }
  
  /// Get default width/height based on research recommendations (120-200px wide, 40-60px tall)
  double get defaultWidth {
    switch (type) {
      case LogicBlockType.gateway:
        return 140.0; // Slightly wider for decision text
      case LogicBlockType.reasoning:
        return 160.0; // Wider for reasoning display
      case LogicBlockType.humanVerification:
        return 160.0; // Wider for verification details
      default:
        return 120.0;
    }
  }
  
  double get defaultHeight {
    switch (type) {
      case LogicBlockType.reasoning:
        return 60.0; // Taller for reasoning content
      default:
        return 50.0;
    }
  }
}