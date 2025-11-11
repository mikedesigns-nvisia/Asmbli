import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Security service for Canvas operations
/// Handles input validation, sanitization, and security checks
class CanvasSecurityService {
  // Security constraints
  static const int maxElementsPerCanvas = 1000;
  static const int maxElementSize = 10000; // pixels
  static const int maxTextLength = 10000; // characters
  static const int maxStringLength = 1000; // for IDs, names, etc.
  static const int maxCanvasSize = 20000; // pixels
  static const int maxStyleProperties = 100;
  static const int maxRequestSize = 10 * 1024 * 1024; // 10MB
  
  // Allowed domains for external resources
  static const Set<String> allowedDomains = {
    'fonts.googleapis.com',
    'fonts.gstatic.com',
    'unpkg.com', // For Konva.js
  };
  
  // Allowed element types
  static const Set<String> allowedElementTypes = {
    'container',
    'text', 
    'button',
    'input',
    'image',
    'icon',
    'card'
  };
  
  // Allowed style properties
  static const Set<String> allowedStyleProperties = {
    'backgroundColor',
    'borderColor',
    'borderWidth',
    'borderRadius',
    'color',
    'fontSize',
    'fontFamily',
    'fontWeight',
    'padding',
    'margin',
    'width',
    'height',
    'opacity',
    'transform',
    'boxShadow',
    'textAlign',
    'lineHeight',
    'letterSpacing',
  };

  /// Validate canvas state
  static ValidationResult validateCanvasState(Map<String, dynamic> state) {
    try {
      // Check required fields
      if (!state.containsKey('id') || !state.containsKey('elements')) {
        return ValidationResult.failure('Canvas state missing required fields: id, elements');
      }

      // Validate canvas dimensions
      final width = state['width'] as num?;
      final height = state['height'] as num?;
      
      if (width != null && (width <= 0 || width > maxCanvasSize)) {
        return ValidationResult.failure('Canvas width must be between 1 and $maxCanvasSize pixels');
      }
      
      if (height != null && (height <= 0 || height > maxCanvasSize)) {
        return ValidationResult.failure('Canvas height must be between 1 and $maxCanvasSize pixels');
      }

      // Validate elements
      final elements = state['elements'] as List?;
      if (elements != null) {
        if (elements.length > maxElementsPerCanvas) {
          return ValidationResult.failure('Canvas cannot have more than $maxElementsPerCanvas elements');
        }

        for (int i = 0; i < elements.length; i++) {
          final element = elements[i];
          if (element is! Map<String, dynamic>) {
            return ValidationResult.failure('Element at index $i is not a valid object');
          }
          
          final elementResult = validateElement(element);
          if (!elementResult.isValid) {
            return ValidationResult.failure('Element at index $i: ${elementResult.error}');
          }
        }
      }

      // Validate canvas name
      final name = state['name'] as String?;
      if (name != null && !isValidString(name, maxStringLength)) {
        return ValidationResult.failure('Canvas name is invalid or too long');
      }

      return ValidationResult.success();

    } catch (e) {
      return ValidationResult.failure('Canvas state validation error: $e');
    }
  }

  /// Validate individual element
  static ValidationResult validateElement(Map<String, dynamic> element) {
    try {
      // Check required fields
      if (!element.containsKey('id') || !element.containsKey('type')) {
        return ValidationResult.failure('Element missing required fields: id, type');
      }

      // Validate ID
      final id = element['id'] as String?;
      if (id == null || !isValidString(id, maxStringLength) || !isValidId(id)) {
        return ValidationResult.failure('Element ID is invalid');
      }

      // Validate type
      final type = element['type'] as String?;
      if (type == null || !allowedElementTypes.contains(type)) {
        return ValidationResult.failure('Element type "$type" is not allowed');
      }

      // Validate position and size
      final x = element['x'] as num?;
      final y = element['y'] as num?;
      final width = element['width'] as num?;
      final height = element['height'] as num?;

      if (x != null && (x < -maxElementSize || x > maxElementSize)) {
        return ValidationResult.failure('Element x position is out of bounds');
      }
      
      if (y != null && (y < -maxElementSize || y > maxElementSize)) {
        return ValidationResult.failure('Element y position is out of bounds');
      }
      
      if (width != null && (width <= 0 || width > maxElementSize)) {
        return ValidationResult.failure('Element width must be between 1 and $maxElementSize pixels');
      }
      
      if (height != null && (height <= 0 || height > maxElementSize)) {
        return ValidationResult.failure('Element height must be between 1 and $maxElementSize pixels');
      }

      // Validate text content
      final text = element['text'] as String?;
      if (text != null && !isValidString(text, maxTextLength)) {
        return ValidationResult.failure('Element text is too long or contains invalid characters');
      }

      // Validate style
      final style = element['style'] as Map<String, dynamic>?;
      if (style != null) {
        final styleResult = validateStyle(style);
        if (!styleResult.isValid) {
          return ValidationResult.failure('Element style: ${styleResult.error}');
        }
      }

      // Validate component and variant
      final component = element['component'] as String?;
      if (component != null && !isValidString(component, maxStringLength)) {
        return ValidationResult.failure('Element component name is invalid');
      }

      final variant = element['variant'] as String?;
      if (variant != null && !isValidString(variant, maxStringLength)) {
        return ValidationResult.failure('Element variant name is invalid');
      }

      return ValidationResult.success();

    } catch (e) {
      return ValidationResult.failure('Element validation error: $e');
    }
  }

  /// Validate style object
  static ValidationResult validateStyle(Map<String, dynamic> style) {
    try {
      if (style.length > maxStyleProperties) {
        return ValidationResult.failure('Style object has too many properties (max: $maxStyleProperties)');
      }

      for (final entry in style.entries) {
        final key = entry.key;
        final value = entry.value;

        // Check if property is allowed
        if (!allowedStyleProperties.contains(key)) {
          return ValidationResult.failure('Style property "$key" is not allowed');
        }

        // Validate property value
        if (!isValidStyleValue(key, value)) {
          return ValidationResult.failure('Style property "$key" has invalid value: $value');
        }
      }

      return ValidationResult.success();

    } catch (e) {
      return ValidationResult.failure('Style validation error: $e');
    }
  }

  /// Validate MCP tool arguments
  static ValidationResult validateMCPArguments(String tool, Map<String, dynamic> arguments) {
    try {
      // Check argument size
      final jsonSize = utf8.encode(jsonEncode(arguments)).length;
      if (jsonSize > maxRequestSize) {
        return ValidationResult.failure('MCP arguments too large (max: ${maxRequestSize ~/ 1024 / 1024}MB)');
      }

      switch (tool) {
        case 'create_element':
          return _validateCreateElementArgs(arguments);
        case 'modify_element':
          return _validateModifyElementArgs(arguments);
        case 'delete_element':
          return _validateDeleteElementArgs(arguments);
        case 'render_design':
          return _validateRenderDesignArgs(arguments);
        case 'export_code':
          return _validateExportCodeArgs(arguments);
        case 'align_elements':
          return _validateAlignElementsArgs(arguments);
        default:
          return ValidationResult.success(); // Allow other tools
      }

    } catch (e) {
      return ValidationResult.failure('MCP arguments validation error: $e');
    }
  }

  /// Sanitize canvas state
  static Map<String, dynamic> sanitizeCanvasState(Map<String, dynamic> state) {
    final sanitized = <String, dynamic>{};

    // Copy safe fields
    for (final entry in state.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key) {
        case 'id':
        case 'name':
        case 'width':
        case 'height':
        case 'backgroundColor':
        case 'designSystemId':
          sanitized[key] = sanitizeValue(value);
          break;
        case 'elements':
          if (value is List) {
            sanitized[key] = value.map((e) => sanitizeElement(e)).toList();
          }
          break;
        case 'selectedElements':
          if (value is List) {
            sanitized[key] = value.where((e) => e is String && isValidId(e)).toList();
          }
          break;
        case 'grid':
        case 'guides':
          if (value is Map<String, dynamic>) {
            sanitized[key] = sanitizeObject(value);
          }
          break;
      }
    }

    return sanitized;
  }

  /// Sanitize element
  static Map<String, dynamic> sanitizeElement(dynamic element) {
    if (element is! Map<String, dynamic>) return {};

    final sanitized = <String, dynamic>{};

    for (final entry in element.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key) {
        case 'id':
        case 'type':
        case 'x':
        case 'y':
        case 'width':
        case 'height':
        case 'text':
        case 'component':
        case 'variant':
        case 'parent':
          sanitized[key] = sanitizeValue(value);
          break;
        case 'style':
        case 'tokenOverrides':
          if (value is Map<String, dynamic>) {
            sanitized[key] = sanitizeStyle(value);
          }
          break;
      }
    }

    return sanitized;
  }

  /// Sanitize style object
  static Map<String, dynamic> sanitizeStyle(Map<String, dynamic> style) {
    final sanitized = <String, dynamic>{};

    for (final entry in style.entries) {
      final key = entry.key;
      final value = entry.value;

      if (allowedStyleProperties.contains(key)) {
        sanitized[key] = sanitizeValue(value);
      }
    }

    return sanitized;
  }

  /// Sanitize generic object
  static Map<String, dynamic> sanitizeObject(Map<String, dynamic> obj) {
    final sanitized = <String, dynamic>{};

    for (final entry in obj.entries) {
      sanitized[entry.key] = sanitizeValue(entry.value);
    }

    return sanitized;
  }

  /// Sanitize individual value
  static dynamic sanitizeValue(dynamic value) {
    if (value is String) {
      return sanitizeString(value);
    } else if (value is num) {
      return value;
    } else if (value is bool) {
      return value;
    } else if (value is List) {
      return value.map(sanitizeValue).toList();
    } else if (value is Map<String, dynamic>) {
      return sanitizeObject(value);
    }
    return null;
  }

  /// Sanitize string
  static String sanitizeString(String input) {
    // Remove null bytes and control characters except newlines and tabs
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  /// Check if string is valid
  static bool isValidString(String input, int maxLength) {
    if (input.length > maxLength) return false;
    
    // Check for null bytes and other dangerous characters
    if (input.contains('\x00')) return false;
    
    return true;
  }

  /// Check if ID is valid
  static bool isValidId(String id) {
    // Allow alphanumeric, dash, underscore
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id) && id.length <= 100;
  }

  /// Check if style value is valid
  static bool isValidStyleValue(String property, dynamic value) {
    if (value == null) return true;

    switch (property) {
      case 'backgroundColor':
      case 'borderColor':
      case 'color':
        return isValidColor(value);
      case 'fontSize':
      case 'borderWidth':
      case 'width':
      case 'height':
      case 'padding':
      case 'margin':
        return isValidNumber(value);
      case 'opacity':
        return isValidNumber(value) && value >= 0 && value <= 1;
      case 'fontFamily':
        return value is String && isValidString(value, 100);
      case 'fontWeight':
        return isValidFontWeight(value);
      default:
        return value is String && isValidString(value, 200);
    }
  }

  /// Check if color value is valid
  static bool isValidColor(dynamic value) {
    if (value is! String) return false;
    
    // Allow hex colors, rgb/rgba, named colors
    return RegExp(r'^(#[0-9A-Fa-f]{3,8}|rgb\(|rgba\(|[a-zA-Z]+)').hasMatch(value);
  }

  /// Check if number is valid
  static bool isValidNumber(dynamic value) {
    return value is num && value.isFinite && value >= -maxElementSize && value <= maxElementSize;
  }

  /// Check if font weight is valid
  static bool isValidFontWeight(dynamic value) {
    if (value is num) {
      return [100, 200, 300, 400, 500, 600, 700, 800, 900].contains(value);
    }
    if (value is String) {
      return ['normal', 'bold', 'lighter', 'bolder'].contains(value);
    }
    return false;
  }

  // Validation helper methods for specific MCP tools
  static ValidationResult _validateCreateElementArgs(Map<String, dynamic> args) {
    if (!args.containsKey('type')) {
      return ValidationResult.failure('create_element requires type argument');
    }
    return validateElement({...args, 'id': 'temp'});
  }

  static ValidationResult _validateModifyElementArgs(Map<String, dynamic> args) {
    if (!args.containsKey('elementId')) {
      return ValidationResult.failure('modify_element requires elementId argument');
    }
    
    final elementId = args['elementId'];
    if (elementId is! String || !isValidId(elementId)) {
      return ValidationResult.failure('Invalid elementId');
    }

    final updates = args['updates'] as Map<String, dynamic>?;
    if (updates != null) {
      return validateElement({...updates, 'id': elementId, 'type': 'container'});
    }

    return ValidationResult.success();
  }

  static ValidationResult _validateDeleteElementArgs(Map<String, dynamic> args) {
    if (!args.containsKey('elementId')) {
      return ValidationResult.failure('delete_element requires elementId argument');
    }
    
    final elementId = args['elementId'];
    if (elementId is! String || !isValidId(elementId)) {
      return ValidationResult.failure('Invalid elementId');
    }

    return ValidationResult.success();
  }

  static ValidationResult _validateRenderDesignArgs(Map<String, dynamic> args) {
    if (!args.containsKey('description')) {
      return ValidationResult.failure('render_design requires description argument');
    }
    
    final description = args['description'];
    if (description is! String || !isValidString(description, maxTextLength)) {
      return ValidationResult.failure('Invalid description');
    }

    return ValidationResult.success();
  }

  static ValidationResult _validateExportCodeArgs(Map<String, dynamic> args) {
    if (!args.containsKey('format')) {
      return ValidationResult.failure('export_code requires format argument');
    }
    
    final format = args['format'];
    if (format is! String || !['flutter', 'react', 'html', 'swiftui'].contains(format)) {
      return ValidationResult.failure('Invalid export format');
    }

    return ValidationResult.success();
  }

  static ValidationResult _validateAlignElementsArgs(Map<String, dynamic> args) {
    if (!args.containsKey('alignment') || !args.containsKey('elementIds')) {
      return ValidationResult.failure('align_elements requires alignment and elementIds arguments');
    }
    
    final alignment = args['alignment'];
    if (alignment is! String || !['left', 'center', 'right', 'top', 'middle', 'bottom'].contains(alignment)) {
      return ValidationResult.failure('Invalid alignment value');
    }

    final elementIds = args['elementIds'];
    if (elementIds is! List || elementIds.isEmpty) {
      return ValidationResult.failure('elementIds must be a non-empty array');
    }

    for (final id in elementIds) {
      if (id is! String || !isValidId(id)) {
        return ValidationResult.failure('Invalid element ID in elementIds');
      }
    }

    return ValidationResult.success();
  }
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult._(this.isValid, this.error);

  factory ValidationResult.success() => ValidationResult._(true, null);
  factory ValidationResult.failure(String error) => ValidationResult._(false, error);
}