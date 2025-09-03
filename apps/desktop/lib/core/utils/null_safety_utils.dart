import 'dart:convert';
import 'dart:io';

/// Null safety and type safety utilities for robust data handling
class NullSafetyUtils {
  
  /// Safely parses JSON with comprehensive error handling
  static Map<String, dynamic> safeParseJson(String? jsonString, {
    Map<String, dynamic>? fallback,
  }) {
    if (jsonString == null || jsonString.trim().isEmpty) {
      return fallback ?? {};
    }
    
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      
      print('⚠️ JSON decoded to ${decoded.runtimeType}, expected Map<String, dynamic>');
      return fallback ?? {};
    } catch (e) {
      print('⚠️ JSON parse error: $e');
      return fallback ?? {};
    }
  }
  
  /// Safely parses JSON array
  static List<T> safeParseJsonArray<T>(
    String? jsonString, {
    List<T>? fallback,
    T Function(dynamic)? itemParser,
  }) {
    if (jsonString == null || jsonString.trim().isEmpty) {
      return fallback ?? <T>[];
    }
    
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        if (itemParser != null) {
          return decoded.map<T>((item) {
            try {
              return itemParser(item);
            } catch (e) {
              print('⚠️ Failed to parse array item: $e');
              return null;
            }
          }).whereType<T>().toList();
        }
        return List<T>.from(decoded);
      }
      
      print('⚠️ JSON decoded to ${decoded.runtimeType}, expected List');
      return fallback ?? <T>[];
    } catch (e) {
      print('⚠️ JSON array parse error: $e');
      return fallback ?? <T>[];
    }
  }
  
  /// Safely extracts a string value from a map
  static String safeString(
    Map<String, dynamic>? map,
    String key, {
    String fallback = '',
  }) {
    if (map == null) return fallback;
    
    final value = map[key];
    if (value == null) return fallback;
    
    if (value is String) return value;
    
    // Try to convert to string
    try {
      return value.toString();
    } catch (e) {
      print('⚠️ Failed to convert $key to string: $e');
      return fallback;
    }
  }
  
  /// Safely extracts an int value from a map
  static int safeInt(
    Map<String, dynamic>? map,
    String key, {
    int fallback = 0,
  }) {
    if (map == null) return fallback;
    
    final value = map[key];
    if (value == null) return fallback;
    
    if (value is int) return value;
    if (value is double) return value.round();
    
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('⚠️ Failed to parse $key as int: $e');
        return fallback;
      }
    }
    
    print('⚠️ Unexpected type for $key: ${value.runtimeType}');
    return fallback;
  }
  
  /// Safely extracts a double value from a map
  static double safeDouble(
    Map<String, dynamic>? map,
    String key, {
    double fallback = 0.0,
  }) {
    if (map == null) return fallback;
    
    final value = map[key];
    if (value == null) return fallback;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('⚠️ Failed to parse $key as double: $e');
        return fallback;
      }
    }
    
    print('⚠️ Unexpected type for $key: ${value.runtimeType}');
    return fallback;
  }
  
  /// Safely extracts a bool value from a map
  static bool safeBool(
    Map<String, dynamic>? map,
    String key, {
    bool fallback = false,
  }) {
    if (map == null) return fallback;
    
    final value = map[key];
    if (value == null) return fallback;
    
    if (value is bool) return value;
    
    if (value is String) {
      final lowerValue = value.toLowerCase();
      if (lowerValue == 'true') return true;
      if (lowerValue == 'false') return false;
    }
    
    if (value is int) {
      return value != 0;
    }
    
    print('⚠️ Unexpected type for $key: ${value.runtimeType}');
    return fallback;
  }
  
  /// Safely extracts a List value from a map
  static List<T> safeList<T>(
    Map<String, dynamic>? map,
    String key, {
    List<T>? fallback,
    T Function(dynamic)? itemParser,
  }) {
    if (map == null) return fallback ?? <T>[];
    
    final value = map[key];
    if (value == null) return fallback ?? <T>[];
    
    if (value is List) {
      try {
        if (itemParser != null) {
          return value.map<T>((item) {
            try {
              return itemParser(item);
            } catch (e) {
              print('⚠️ Failed to parse list item: $e');
              return null;
            }
          }).whereType<T>().toList();
        }
        return List<T>.from(value);
      } catch (e) {
        print('⚠️ Failed to convert list for $key: $e');
        return fallback ?? <T>[];
      }
    }
    
    print('⚠️ Unexpected type for $key: ${value.runtimeType}, expected List');
    return fallback ?? <T>[];
  }
  
  /// Safely extracts a Map value from a map
  static Map<String, dynamic> safeMap(
    Map<String, dynamic>? map,
    String key, {
    Map<String, dynamic>? fallback,
  }) {
    if (map == null) return fallback ?? {};
    
    final value = map[key];
    if (value == null) return fallback ?? {};
    
    if (value is Map<String, dynamic>) return value;
    
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        print('⚠️ Failed to convert map for $key: $e');
        return fallback ?? {};
      }
    }
    
    print('⚠️ Unexpected type for $key: ${value.runtimeType}, expected Map');
    return fallback ?? {};
  }
  
  /// Safely extracts a DateTime value from a map
  static DateTime? safeDateTime(
    Map<String, dynamic>? map,
    String key, {
    DateTime? fallback,
  }) {
    if (map == null) return fallback;
    
    final value = map[key];
    if (value == null) return fallback;
    
    if (value is DateTime) return value;
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Failed to parse $key as DateTime: $e');
        return fallback;
      }
    }
    
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        print('⚠️ Failed to convert $key timestamp to DateTime: $e');
        return fallback;
      }
    }
    
    print('⚠️ Unexpected type for $key: ${value.runtimeType}');
    return fallback;
  }
  
  /// Safely reads and parses a file as JSON
  static Future<Map<String, dynamic>> safeReadJsonFile(
    File file, {
    Map<String, dynamic>? fallback,
  }) async {
    if (!file.existsSync()) {
      print('⚠️ File does not exist: ${file.path}');
      return fallback ?? {};
    }
    
    try {
      final content = await file.readAsString();
      return safeParseJson(content, fallback: fallback);
    } catch (e) {
      print('⚠️ Failed to read file ${file.path}: $e');
      return fallback ?? {};
    }
  }
  
  /// Safely writes JSON to a file
  static Future<bool> safeWriteJsonFile(
    File file,
    Map<String, dynamic> data, {
    bool createDirs = true,
  }) async {
    try {
      if (createDirs) {
        final dir = file.parent;
        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }
      }
      
      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      print('⚠️ Failed to write JSON to ${file.path}: $e');
      return false;
    }
  }
  
  /// Safely casts a value to a specific type
  static T? safeCast<T>(dynamic value, {T? fallback}) {
    if (value == null) return fallback;
    
    try {
      if (value is T) return value;
      
      // Special handling for common conversions
      if (T == String) {
        return value.toString() as T?;
      }
      
      if (T == int && value is String) {
        return int.tryParse(value) as T?;
      }
      
      if (T == double && value is String) {
        return double.tryParse(value) as T?;
      }
      
      if (T == bool && value is String) {
        final lowerValue = value.toLowerCase();
        if (lowerValue == 'true') return true as T?;
        if (lowerValue == 'false') return false as T?;
      }
      
      return fallback;
    } catch (e) {
      print('⚠️ Safe cast failed for ${value.runtimeType} to $T: $e');
      return fallback;
    }
  }
  
  /// Validates that required fields exist in a map
  static ValidationResult validateRequiredFields(
    Map<String, dynamic>? data,
    List<String> requiredFields,
  ) {
    if (data == null) {
      return ValidationResult(
        isValid: false,
        error: 'Data is null',
        missingFields: requiredFields,
      );
    }
    
    final missingFields = <String>[];
    final nullFields = <String>[];
    
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        missingFields.add(field);
      } else if (data[field] == null) {
        nullFields.add(field);
      }
    }
    
    if (missingFields.isNotEmpty || nullFields.isNotEmpty) {
      final errors = <String>[];
      if (missingFields.isNotEmpty) {
        errors.add('Missing fields: ${missingFields.join(', ')}');
      }
      if (nullFields.isNotEmpty) {
        errors.add('Null fields: ${nullFields.join(', ')}');
      }
      
      return ValidationResult(
        isValid: false,
        error: errors.join('; '),
        missingFields: [...missingFields, ...nullFields],
      );
    }
    
    return ValidationResult(isValid: true);
  }
  
  /// Creates a null-safe map builder
  static MapBuilder createMapBuilder() => MapBuilder();
  
  /// Creates a null-safe list builder
  static ListBuilder<T> createListBuilder<T>() => ListBuilder<T>();
}

/// Builder for creating null-safe maps
class MapBuilder {
  final Map<String, dynamic> _map = {};
  
  /// Adds a value only if it's not null
  MapBuilder putIfNotNull(String key, dynamic value) {
    if (value != null) {
      _map[key] = value;
    }
    return this;
  }
  
  /// Adds a string value with fallback
  MapBuilder putString(String key, String? value, {String? fallback}) {
    _map[key] = value ?? fallback ?? '';
    return this;
  }
  
  /// Adds an int value with fallback
  MapBuilder putInt(String key, int? value, {int fallback = 0}) {
    _map[key] = value ?? fallback;
    return this;
  }
  
  /// Adds a bool value with fallback
  MapBuilder putBool(String key, bool? value, {bool fallback = false}) {
    _map[key] = value ?? fallback;
    return this;
  }
  
  /// Adds a list value with fallback
  MapBuilder putList<T>(String key, List<T>? value, {List<T>? fallback}) {
    _map[key] = value ?? fallback ?? <T>[];
    return this;
  }
  
  /// Builds the final map
  Map<String, dynamic> build() => Map.from(_map);
}

/// Builder for creating null-safe lists
class ListBuilder<T> {
  final List<T> _list = [];
  
  /// Adds an item only if it's not null
  ListBuilder<T> addIfNotNull(T? item) {
    if (item != null) {
      _list.add(item);
    }
    return this;
  }
  
  /// Adds all items from another list, filtering out nulls
  ListBuilder<T> addAllNotNull(Iterable<T?>? items) {
    if (items != null) {
      _list.addAll(items.whereType<T>());
    }
    return this;
  }
  
  /// Builds the final list
  List<T> build() => List.from(_list);
}

class ValidationResult {
  final bool isValid;
  final String? error;
  final List<String> missingFields;
  
  const ValidationResult({
    required this.isValid,
    this.error,
    this.missingFields = const [],
  });
}

/// Extension methods for null-safe operations
extension NullSafeMap on Map<String, dynamic>? {
  /// Safely gets a string value
  String getString(String key, {String fallback = ''}) {
    return NullSafetyUtils.safeString(this, key, fallback: fallback);
  }
  
  /// Safely gets an int value
  int getInt(String key, {int fallback = 0}) {
    return NullSafetyUtils.safeInt(this, key, fallback: fallback);
  }
  
  /// Safely gets a double value
  double getDouble(String key, {double fallback = 0.0}) {
    return NullSafetyUtils.safeDouble(this, key, fallback: fallback);
  }
  
  /// Safely gets a bool value
  bool getBool(String key, {bool fallback = false}) {
    return NullSafetyUtils.safeBool(this, key, fallback: fallback);
  }
  
  /// Safely gets a list value
  List<T> getList<T>(String key, {List<T>? fallback}) {
    return NullSafetyUtils.safeList<T>(this, key, fallback: fallback);
  }
  
  /// Safely gets a map value
  Map<String, dynamic> getMap(String key, {Map<String, dynamic>? fallback}) {
    return NullSafetyUtils.safeMap(this, key, fallback: fallback);
  }
  
  /// Safely gets a DateTime value
  DateTime? getDateTime(String key, {DateTime? fallback}) {
    return NullSafetyUtils.safeDateTime(this, key, fallback: fallback);
  }
}

extension NullSafeString on String? {
  /// Returns the string if not null or empty, otherwise returns fallback
  String orElse(String fallback) {
    final str = this;
    return (str == null || str.isEmpty) ? fallback : str;
  }
  
  /// Returns true if the string is null or empty
  bool get isNullOrEmpty {
    final str = this;
    return str == null || str.isEmpty;
  }
  
  /// Returns true if the string is not null and not empty
  bool get isNotNullOrEmpty {
    final str = this;
    return str != null && str.isNotEmpty;
  }
  
  /// Safely converts to int
  int? toIntSafe() {
    final str = this;
    if (str == null) return null;
    return int.tryParse(str);
  }
  
  /// Safely converts to double
  double? toDoubleSafe() {
    final str = this;
    if (str == null) return null;
    return double.tryParse(str);
  }
}