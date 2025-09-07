import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Production-grade environment configuration management
/// Supports multiple environments with secure credential loading
class EnvironmentConfig {
  static EnvironmentConfig? _instance;
  static EnvironmentConfig get instance => _instance ??= EnvironmentConfig._();
  
  EnvironmentConfig._();

  // Environment types
  static const String development = 'development';
  static const String staging = 'staging';  
  static const String production = 'production';

  late final Environment _currentEnvironment;
  late final Map<String, dynamic> _config;
  bool _initialized = false;

  /// Initialize environment configuration
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Determine current environment
      _currentEnvironment = _detectEnvironment();
      
      // Load configuration
      _config = await _loadConfiguration();
      
      _initialized = true;
      print('🌍 Environment: ${_currentEnvironment.name}');
      print('🔧 Config loaded: ${_config.keys.join(', ')}');
      
    } catch (e) {
      print('❌ Environment initialization failed: $e');
      // Initialize with minimal safe defaults
      _currentEnvironment = Environment(development, false, LogLevel.debug);
      _config = _getDefaultConfiguration();
      _initialized = true;
    }
  }

  /// Get current environment
  Environment get environment {
    if (!_initialized) throw Exception('EnvironmentConfig not initialized');
    return _currentEnvironment;
  }

  /// Get configuration value
  T get<T>(String key, {T? defaultValue}) {
    if (!_initialized) throw Exception('EnvironmentConfig not initialized');
    
    // Check environment variables first
    final envValue = Platform.environment[key];
    if (envValue != null) {
      return _convertType<T>(envValue, defaultValue);
    }
    
    // Check config file
    final configValue = _config[key] as T?;
    if (configValue != null) return configValue;
    if (defaultValue != null) return defaultValue;
    throw Exception('Configuration value not found for key: $key');
  }

  /// Get OAuth client configuration
  Map<String, String> getOAuthConfig(String provider) {
    final config = <String, String>{};
    
    // Standard OAuth environment variable patterns
    final clientId = get<String>('${provider.toUpperCase()}_CLIENT_ID');
    final clientSecret = get<String>('${provider.toUpperCase()}_CLIENT_SECRET');
    final redirectUri = get<String>('${provider.toUpperCase()}_REDIRECT_URI');
    
    if (clientId != null) config['client_id'] = clientId;
    if (clientSecret != null) config['client_secret'] = clientSecret;
    if (redirectUri != null) config['redirect_uri'] = redirectUri;
    
    return config;
  }

  /// Get database configuration
  Map<String, dynamic> get databaseConfig {
    return {
      'name': get<String>('DATABASE_NAME', defaultValue: 'asmbli_desktop.db'),
      'path': get<String>('DATABASE_PATH'),
      'encryption_key': get<String>('DATABASE_ENCRYPTION_KEY'),
      'backup_enabled': get<bool>('DATABASE_BACKUP_ENABLED', defaultValue: true),
      'backup_interval_hours': get<int>('DATABASE_BACKUP_INTERVAL_HOURS', defaultValue: 24),
    };
  }

  /// Get API configuration  
  Map<String, dynamic> get apiConfig {
    return {
      'base_url': get<String>('API_BASE_URL', 
        defaultValue: environment.isDevelopment 
          ? 'http://localhost:3000/api' 
          : 'https://api.asmbli.com'),
      'timeout_seconds': get<int>('API_TIMEOUT_SECONDS', defaultValue: 30),
      'retry_attempts': get<int>('API_RETRY_ATTEMPTS', defaultValue: 3),
      'api_key': get<String>('API_KEY'),
      'user_agent': 'Asmbli-Desktop/${get<String>('APP_VERSION', defaultValue: '1.0.0')}',
    };
  }

  /// Get logging configuration
  Map<String, dynamic> get loggingConfig {
    return {
      'level': get<String>('LOG_LEVEL', defaultValue: environment.logLevel.name),
      'file_enabled': get<bool>('LOG_FILE_ENABLED', defaultValue: !environment.isDevelopment),
      'file_path': get<String>('LOG_FILE_PATH'),
      'max_file_size_mb': get<int>('LOG_MAX_FILE_SIZE_MB', defaultValue: 10),
      'max_files': get<int>('LOG_MAX_FILES', defaultValue: 5),
      'console_enabled': get<bool>('LOG_CONSOLE_ENABLED', defaultValue: environment.isDevelopment),
    };
  }

  /// Get security configuration
  Map<String, dynamic> get securityConfig {
    return {
      'master_key_iterations': get<int>('SECURITY_MASTER_KEY_ITERATIONS', defaultValue: 100000),
      'session_timeout_minutes': get<int>('SECURITY_SESSION_TIMEOUT_MINUTES', defaultValue: 480),
      'max_failed_attempts': get<int>('SECURITY_MAX_FAILED_ATTEMPTS', defaultValue: 5),
      'lockout_duration_minutes': get<int>('SECURITY_LOCKOUT_DURATION_MINUTES', defaultValue: 15),
      'require_biometric': get<bool>('SECURITY_REQUIRE_BIOMETRIC', defaultValue: false),
    };
  }

  /// Get feature flags
  Map<String, bool> get featureFlags {
    return {
      'mcp_servers_enabled': get<bool>('FEATURE_MCP_SERVERS', defaultValue: true),
      'oauth_enabled': get<bool>('FEATURE_OAUTH', defaultValue: true),
      'telemetry_enabled': get<bool>('FEATURE_TELEMETRY', defaultValue: !environment.isDevelopment),
      'crash_reporting': get<bool>('FEATURE_CRASH_REPORTING', defaultValue: environment.isProduction),
      'beta_features': get<bool>('FEATURE_BETA', defaultValue: environment.isDevelopment),
      'debug_mode': get<bool>('FEATURE_DEBUG', defaultValue: environment.isDevelopment),
    };
  }

  /// Detect current environment
  Environment _detectEnvironment() {
    // Check explicit environment variable
    final envName = Platform.environment['ENVIRONMENT'] ?? 
                   Platform.environment['FLUTTER_ENV'] ??
                   Platform.environment['NODE_ENV'];
    
    if (envName != null) {
      switch (envName.toLowerCase()) {
        case 'prod':
        case 'production':
          return Environment(production, true, LogLevel.info);
        case 'staging':
        case 'stage':
          return Environment(staging, false, LogLevel.debug);
        case 'dev':
        case 'development':
          return Environment(development, false, LogLevel.debug);
      }
    }

    // Detect based on build mode and other indicators
    if (kReleaseMode && !kDebugMode) {
      // Check if this is a staging build
      final buildNumber = Platform.environment['BUILD_NUMBER'];
      final isStaging = Platform.environment['IS_STAGING'] == 'true' ||
                       (buildNumber != null && buildNumber.contains('staging'));
      
      return isStaging 
        ? Environment(staging, false, LogLevel.info)
        : Environment(production, true, LogLevel.warning);
    }

    // Default to development
    return Environment(development, false, LogLevel.debug);
  }

  /// Load configuration from multiple sources
  Future<Map<String, dynamic>> _loadConfiguration() async {
    final config = <String, dynamic>{};

    // 1. Load from config files
    config.addAll(await _loadConfigFile('config.json'));
    config.addAll(await _loadConfigFile('config.${_currentEnvironment.name}.json'));
    config.addAll(await _loadConfigFile('.env.json'));

    // 2. Load from .env file
    config.addAll(await _loadEnvFile('.env'));
    config.addAll(await _loadEnvFile('.env.${_currentEnvironment.name}'));

    // 3. Environment variables take precedence
    config.addAll(_loadEnvironmentVariables());

    return config;
  }

  /// Load JSON configuration file
  Future<Map<String, dynamic>> _loadConfigFile(String filename) async {
    try {
      final file = File(filename);
      if (await file.exists()) {
        final content = await file.readAsString();
        return Map<String, dynamic>.from(json.decode(content));
      }
    } catch (e) {
      print('⚠️ Failed to load config file $filename: $e');
    }
    return {};
  }

  /// Load .env file
  Future<Map<String, dynamic>> _loadEnvFile(String filename) async {
    try {
      final file = File(filename);
      if (await file.exists()) {
        final lines = await file.readAsLines();
        final config = <String, dynamic>{};
        
        for (final line in lines) {
          if (line.trim().isEmpty || line.startsWith('#')) continue;
          
          final parts = line.split('=');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.skip(1).join('=').trim();
            
            // Remove quotes if present
            final cleanValue = value.startsWith('"') && value.endsWith('"')
                ? value.substring(1, value.length - 1)
                : value.startsWith("'") && value.endsWith("'")
                ? value.substring(1, value.length - 1)
                : value;
            
            config[key] = cleanValue;
          }
        }
        
        return config;
      }
    } catch (e) {
      print('⚠️ Failed to load env file $filename: $e');
    }
    return {};
  }

  /// Load environment variables with ASMBLI_ prefix
  Map<String, dynamic> _loadEnvironmentVariables() {
    final config = <String, dynamic>{};
    final prefix = 'ASMBLI_';
    
    Platform.environment.forEach((key, value) {
      if (key.startsWith(prefix)) {
        final configKey = key.substring(prefix.length).toLowerCase();
        config[configKey] = value;
      }
    });
    
    return config;
  }

  /// Get default configuration
  Map<String, dynamic> _getDefaultConfiguration() {
    return {
      'app_name': 'Asmbli Desktop',
      'app_version': '1.0.0',
      'log_level': 'debug',
      'api_timeout_seconds': 30,
      'database_name': 'asmbli_desktop.db',
    };
  }

  /// Convert string value to typed value
  T _convertType<T>(String value, T? defaultValue) {
    try {
      if (T == bool) {
        return (['true', '1', 'yes', 'on'].contains(value.toLowerCase())) as T;
      } else if (T == int) {
        return int.parse(value) as T;
      } else if (T == double) {
        return double.parse(value) as T;
      } else {
        return value as T;
      }
    } catch (e) {
      return defaultValue ?? value as T;
    }
  }

  /// Validate required configuration
  void validateRequired(List<String> requiredKeys) {
    if (!_initialized) throw Exception('EnvironmentConfig not initialized');
    
    final missing = <String>[];
    for (final key in requiredKeys) {
      if (get<String>(key) == null) {
        missing.add(key);
      }
    }
    
    if (missing.isNotEmpty) {
      throw Exception('Missing required configuration: ${missing.join(', ')}');
    }
  }

  /// Check if running in specific environment
  bool get isDevelopment => _currentEnvironment.name == development;
  bool get isStaging => _currentEnvironment.name == staging;
  bool get isProduction => _currentEnvironment.name == production;
}

/// Environment information
class Environment {
  final String name;
  final bool isProduction;
  final LogLevel logLevel;

  const Environment(this.name, this.isProduction, this.logLevel);

  bool get isDevelopment => name == EnvironmentConfig.development;
  bool get isStaging => name == EnvironmentConfig.staging;

  @override
  String toString() => name;
}

/// Log levels
enum LogLevel {
  debug('debug'),
  info('info'),
  warning('warning'),
  error('error');

  const LogLevel(this.name);
  final String name;
}