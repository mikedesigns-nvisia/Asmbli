import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'desktop/desktop_storage_service.dart';
import 'desktop/desktop_service_provider.dart';

/// Service for managing API configurations and keys
class ApiConfigService {
  final DesktopStorageService _storageService;
  final Map<String, ApiConfig> _apiConfigs = {};
  String? _defaultApiConfigId;

  ApiConfigService(this._storageService);

  /// Initialize the service
  Future<void> initialize() async {
    try {
      await _storageService.initialize();
      await _loadApiConfigs();
    } catch (e) {
      print('Error initializing API config service: $e');
      await _createDefaultConfig();
    }
  }

  /// Get all API configurations
  Map<String, ApiConfig> get allApiConfigs => Map.from(_apiConfigs);

  /// Get default API configuration ID
  String? get defaultApiConfigId => _defaultApiConfigId;

  /// Get API configuration by ID
  ApiConfig? getApiConfig(String id) => _apiConfigs[id];

  /// Get the default API configuration
  ApiConfig? get defaultApiConfig {
    if (_defaultApiConfigId != null) {
      return _apiConfigs[_defaultApiConfigId];
    }
    return null;
  }

  /// Add or update API configuration
  Future<void> setApiConfig(String id, ApiConfig config) async {
    _apiConfigs[id] = config;
    await _saveApiConfigs();
  }

  /// Remove API configuration
  Future<void> removeApiConfig(String id) async {
    _apiConfigs.remove(id);
    if (_defaultApiConfigId == id) {
      // Set new default if available
      if (_apiConfigs.isNotEmpty) {
        _defaultApiConfigId = _apiConfigs.keys.first;
      } else {
        _defaultApiConfigId = null;
      }
    }
    await _saveApiConfigs();
  }

  /// Set default API configuration
  Future<void> setDefaultApiConfig(String id) async {
    if (_apiConfigs.containsKey(id)) {
      _defaultApiConfigId = id;
      await _saveApiConfigs();
    }
  }

  /// Test API configuration
  Future<bool> testApiConfig(String id) async {
    final config = _apiConfigs[id];
    if (config == null) return false;

    try {
      // Import the Claude API service
      // For now, return true for basic validation
      return config.apiKey.isNotEmpty && config.provider.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Load API configurations from storage
  Future<void> _loadApiConfigs() async {
    try {
      final data = _storageService.getPreference<String>('api_configs');
      if (data != null) {
        final Map<String, dynamic> configsJson = json.decode(data);
        
        for (final entry in configsJson.entries) {
          if (entry.key == '_default') {
            _defaultApiConfigId = entry.value as String?;
          } else {
            _apiConfigs[entry.key] = ApiConfig.fromJson(entry.value);
          }
        }
      }

      // Create default Anthropic config if none exists
      if (_apiConfigs.isEmpty) {
        await _createDefaultConfig();
      }
    } catch (e) {
      print('Error loading API configs: $e');
      await _createDefaultConfig();
    }
  }

  /// Save API configurations to storage
  Future<void> _saveApiConfigs() async {
    try {
      final Map<String, dynamic> configsJson = {};
      
      // Add all configs
      for (final entry in _apiConfigs.entries) {
        configsJson[entry.key] = entry.value.toJson();
      }
      
      // Add default config ID
      if (_defaultApiConfigId != null) {
        configsJson['_default'] = _defaultApiConfigId;
      }

      await _storageService.setPreference('api_configs', json.encode(configsJson));
    } catch (e) {
      print('Error saving API configs: $e');
    }
  }

  /// Create default API configuration
  Future<void> _createDefaultConfig() async {
    const defaultConfig = ApiConfig(
      id: 'anthropic-default',
      name: 'Claude 3.5 Sonnet',
      provider: 'Anthropic',
      model: 'claude-3-5-sonnet-20241022',
      apiKey: '', // Will be set by user
      baseUrl: 'https://api.anthropic.com',
      isDefault: true,
      enabled: true,
    );

    _apiConfigs[defaultConfig.id] = defaultConfig;
    _defaultApiConfigId = defaultConfig.id;
    await _saveApiConfigs();
  }
}

/// API Configuration model
class ApiConfig {
  final String id;
  final String name;
  final String provider;
  final String model;
  final String apiKey;
  final String baseUrl;
  final bool isDefault;
  final bool enabled;
  final Map<String, dynamic>? settings;

  const ApiConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.model,
    required this.apiKey,
    required this.baseUrl,
    this.isDefault = false,
    this.enabled = true,
    this.settings,
  });

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String,
      model: json['model'] as String,
      apiKey: json['apiKey'] as String,
      baseUrl: json['baseUrl'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'model': model,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'isDefault': isDefault,
      'enabled': enabled,
      if (settings != null) 'settings': settings,
    };
  }

  ApiConfig copyWith({
    String? id,
    String? name,
    String? provider,
    String? model,
    String? apiKey,
    String? baseUrl,
    bool? isDefault,
    bool? enabled,
    Map<String, dynamic>? settings,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      isDefault: isDefault ?? this.isDefault,
      enabled: enabled ?? this.enabled,
      settings: settings ?? this.settings,
    );
  }

  bool get isConfigured => apiKey.isNotEmpty;
}

// Riverpod provider for API config service
final apiConfigServiceProvider = Provider<ApiConfigService>((ref) {
  final storageService = ref.read(desktopStorageServiceProvider);
  final service = ApiConfigService(storageService);
  
  // Initialize the service
  service.initialize().catchError((e) {
    print('Failed to initialize API config service: $e');
  });
  
  return service;
});

// State notifier for API configurations
class ApiConfigsNotifier extends StateNotifier<Map<String, ApiConfig>> {
  final ApiConfigService _service;
  bool _isInitialized = false;
  
  ApiConfigsNotifier(this._service) : super({}) {
    _loadConfigs();
  }
  
  Future<void> _loadConfigs() async {
    if (_isInitialized) return;
    
    try {
      await _service.initialize();
      state = _service.allApiConfigs;
      _isInitialized = true;
    } catch (e) {
      print('Failed to load API configs: $e');
      // Create a default configuration if loading fails
      final defaultConfig = ApiConfig(
        id: 'anthropic-default',
        name: 'Claude 3.5 Sonnet',
        provider: 'Anthropic',
        model: 'claude-3-5-sonnet-20241022',
        apiKey: '',
        baseUrl: 'https://api.anthropic.com',
        isDefault: true,
        enabled: true,
      );
      state = {defaultConfig.id: defaultConfig};
      _isInitialized = true;
    }
  }
  
  Future<void> addConfig(String id, ApiConfig config) async {
    await _service.setApiConfig(id, config);
    state = {...state, id: config};
  }
  
  Future<void> removeConfig(String id) async {
    await _service.removeApiConfig(id);
    final newState = Map<String, ApiConfig>.from(state);
    newState.remove(id);
    state = newState;
  }
  
  Future<void> setDefault(String id) async {
    await _service.setDefaultApiConfig(id);
    // Update the configs to reflect the new default
    final updatedConfigs = <String, ApiConfig>{};
    for (final entry in state.entries) {
      updatedConfigs[entry.key] = entry.value.copyWith(
        isDefault: entry.key == id,
      );
    }
    state = updatedConfigs;
  }
}

// Provider for API configs state notifier
final apiConfigsProvider = StateNotifierProvider<ApiConfigsNotifier, Map<String, ApiConfig>>((ref) {
  final service = ref.watch(apiConfigServiceProvider);
  return ApiConfigsNotifier(service);
});

// Provider for all API configs
final allApiConfigsProvider = Provider<Map<String, ApiConfig>>((ref) {
  return ref.watch(apiConfigsProvider);
});

// Provider for default API config
final defaultApiConfigProvider = Provider<ApiConfig?>((ref) {
  final configs = ref.watch(apiConfigsProvider);
  return configs.values.where((config) => config.isDefault).firstOrNull;
});