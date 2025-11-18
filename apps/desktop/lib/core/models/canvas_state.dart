import 'package:equatable/equatable.dart';

/// Enhanced canvas state model for real-time visibility
///
/// Week 3 Task 21: Provides detailed canvas state for debugging and monitoring
class CanvasState extends Equatable {
  final String canvasId;
  final PageInfo currentPage;
  final List<ElementInfo> elements;
  final CanvasStatistics statistics;
  final DateTime timestamp;

  const CanvasState({
    required this.canvasId,
    required this.currentPage,
    required this.elements,
    required this.statistics,
    required this.timestamp,
  });

  /// Create from MCP response
  factory CanvasState.fromJson(Map<String, dynamic> json) {
    final elementsData = json['elements'] as List? ?? [];
    final elements = elementsData
        .map((e) => ElementInfo.fromJson(e as Map<String, dynamic>))
        .toList();

    return CanvasState(
      canvasId: json['canvasId'] as String? ?? 'unknown',
      currentPage: PageInfo.fromJson(json['currentPage'] ?? {}),
      elements: elements,
      statistics: CanvasStatistics.fromElements(elements),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canvasId': canvasId,
      'currentPage': currentPage.toJson(),
      'elements': elements.map((e) => e.toJson()).toList(),
      'statistics': statistics.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [canvasId, currentPage, elements, statistics, timestamp];
}

/// Page information
class PageInfo extends Equatable {
  final String id;
  final String name;
  final int width;
  final int height;

  const PageInfo({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    return PageInfo(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Untitled Page',
      width: json['width'] as int? ?? 1920,
      height: json['height'] as int? ?? 1080,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'width': width,
      'height': height,
    };
  }

  @override
  List<Object?> get props => [id, name, width, height];
}

/// Element information
class ElementInfo extends Equatable {
  final String id;
  final String name;
  final ElementType type;
  final BoundingBox bounds;
  final Map<String, dynamic> styles;
  final List<String> children;

  const ElementInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.bounds,
    required this.styles,
    this.children = const [],
  });

  factory ElementInfo.fromJson(Map<String, dynamic> json) {
    return ElementInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed',
      type: _parseElementType(json['type'] as String?),
      bounds: BoundingBox.fromJson(json['bounds'] ?? {}),
      styles: json['styles'] as Map<String, dynamic>? ?? {},
      children: (json['children'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }

  static ElementType _parseElementType(String? typeStr) {
    switch (typeStr?.toLowerCase()) {
      case 'rectangle':
      case 'rect':
        return ElementType.rectangle;
      case 'text':
        return ElementType.text;
      case 'frame':
      case 'group':
        return ElementType.frame;
      case 'ellipse':
      case 'circle':
        return ElementType.ellipse;
      case 'path':
        return ElementType.path;
      case 'image':
        return ElementType.image;
      default:
        return ElementType.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'bounds': bounds.toJson(),
      'styles': styles,
      if (children.isNotEmpty) 'children': children,
    };
  }

  @override
  List<Object?> get props => [id, name, type, bounds, styles, children];
}

/// Element types
enum ElementType {
  rectangle,
  text,
  frame,
  ellipse,
  path,
  image,
  unknown,
}

/// Bounding box for element
class BoundingBox extends Equatable {
  final double x;
  final double y;
  final double width;
  final double height;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  @override
  List<Object?> get props => [x, y, width, height];
}

/// Canvas statistics for monitoring
class CanvasStatistics extends Equatable {
  final int totalElements;
  final Map<ElementType, int> elementsByType;
  final int totalLayers;
  final Map<String, int> styleUsage;

  const CanvasStatistics({
    required this.totalElements,
    required this.elementsByType,
    required this.totalLayers,
    required this.styleUsage,
  });

  /// Calculate statistics from elements
  factory CanvasStatistics.fromElements(List<ElementInfo> elements) {
    final elementsByType = <ElementType, int>{};
    final styleUsage = <String, int>{};
    int totalLayers = 0;

    for (final element in elements) {
      // Count by type
      elementsByType[element.type] = (elementsByType[element.type] ?? 0) + 1;

      // Count layers (elements with children are layers)
      if (element.children.isNotEmpty) {
        totalLayers++;
      }

      // Count style usage
      for (final styleKey in element.styles.keys) {
        styleUsage[styleKey] = (styleUsage[styleKey] ?? 0) + 1;
      }
    }

    return CanvasStatistics(
      totalElements: elements.length,
      elementsByType: elementsByType,
      totalLayers: totalLayers,
      styleUsage: styleUsage,
    );
  }

  factory CanvasStatistics.fromJson(Map<String, dynamic> json) {
    return CanvasStatistics(
      totalElements: json['totalElements'] as int? ?? 0,
      elementsByType: (json['elementsByType'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              ElementType.values.firstWhere(
                (e) => e.name == key,
                orElse: () => ElementType.unknown,
              ),
              value as int,
            ),
          ) ??
          {},
      totalLayers: json['totalLayers'] as int? ?? 0,
      styleUsage: (json['styleUsage'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalElements': totalElements,
      'elementsByType': elementsByType.map((key, value) => MapEntry(key.name, value)),
      'totalLayers': totalLayers,
      'styleUsage': styleUsage,
    };
  }

  @override
  List<Object?> get props => [totalElements, elementsByType, totalLayers, styleUsage];
}
