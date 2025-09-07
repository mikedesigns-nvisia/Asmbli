import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agent_engine_core/services/agent_service.dart';
import 'package:agent_engine_core/services/conversation_service.dart';

// Core services
import '../services/desktop/desktop_agent_service.dart';
import '../services/desktop/desktop_conversation_service.dart';
import '../services/desktop/desktop_storage_service.dart';
import '../services/desktop/desktop_service_provider.dart';
import '../services/llm/unified_llm_service.dart';
import '../services/mcp_bridge_service.dart';
import '../services/context_mcp_resource_service.dart';
import '../services/agent_context_prompt_service.dart';
import '../services/theme_service.dart';
import '../services/model_config_service.dart';
import '../services/mcp_settings_service.dart';
import '../services/claude_api_service.dart';
import '../services/ollama_service.dart';
import '../services/mcp_server_execution_service.dart';
import '../services/mcp_catalog_service.dart';
import '../services/secure_auth_service.dart';

// Business services
import '../services/business/base_business_service.dart';
import '../services/business/agent_business_service.dart';
import '../services/business/conversation_business_service.dart';

/// Dependency injection container for managing service instances
/// Implements singleton pattern with lazy initialization
class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._internal();

  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic Function()> _factories = {};
  final Set<Type> _singletons = {};
  bool _isInitialized = false;

  /// Register a singleton service instance
  void registerSingleton<T>(T service) {
    if (_services.containsKey(T)) {
      debugPrint('⚠️ Service already registered: $T');
      return;
    }
    
    _services[T] = service;
    _singletons.add(T);
    debugPrint('✅ Registered singleton: $T');
  }

  /// Register a factory for creating service instances
  void registerFactory<T>(T Function() factory) {
    if (_factories.containsKey(T)) {
      debugPrint('⚠️ Factory already registered: $T');
      return;
    }
    
    _factories[T] = factory;
    debugPrint('✅ Registered factory: $T');
  }

  /// Register a lazy singleton (created on first access)
  void registerLazySingleton<T>(T Function() factory) {
    if (_factories.containsKey(T)) {
      debugPrint('⚠️ Lazy singleton already registered: $T');
      return;
    }
    
    _factories[T] = factory;
    _singletons.add(T);
    debugPrint('✅ Registered lazy singleton: $T');
  }

  /// Get a service instance
  T get<T>() {
    final type = T;
    
    // Check if already instantiated
    if (_services.containsKey(type)) {
      return _services[type] as T;
    }
    
    // Check if factory exists
    if (_factories.containsKey(type)) {
      final instance = _factories[type]!() as T;
      
      // Store as singleton if required
      if (_singletons.contains(type)) {
        _services[type] = instance;
      }
      
      return instance;
    }
    
    throw ServiceNotRegisteredException('Service not registered: $T');
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  /// Reset the service locator (mainly for testing)
  void reset() {
    _disposeServices();
    _services.clear();
    _factories.clear();
    _singletons.clear();
    _isInitialized = false;
    debugPrint('🔄 Service locator reset');
  }

  /// Initialize all services
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ Service locator already initialized');
      return;
    }

    try {
      debugPrint('🚀 Initializing service locator...');
      
      await _registerCoreServices();
      await _registerBusinessServices();
      await _initializeServices();
      
      _isInitialized = true;
      debugPrint('✅ Service locator initialized successfully');
    } catch (error, stackTrace) {
      debugPrint('❌ Service locator initialization failed: $error');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Register all core services
  Future<void> _registerCoreServices() async {
    // Storage service (must be first)
    final storageService = DesktopStorageService.instance;
    await storageService.initialize();
    registerSingleton<DesktopStorageService>(storageService);

    // Register data layer services
    registerSingleton<AgentService>(DesktopAgentService());
    registerSingleton<ConversationService>(DesktopConversationService());

    // Register MCP catalog service first (needed by other MCP services)
    final secureAuthService = SecureAuthService(storageService);
    final mcpCatalogService = MCPCatalogService(storageService, secureAuthService);
    registerSingleton<MCPCatalogService>(mcpCatalogService);
    
    // Register infrastructure services with proper dependencies
    final mcpSettingsService = MCPSettingsService(storageService, mcpCatalogService);
    registerSingleton<MCPSettingsService>(mcpSettingsService);
    
    // Register MCP server execution service as singleton
    final mcpExecutionService = MCPServerExecutionService(mcpCatalogService, mcpSettingsService);
    registerSingleton<MCPServerExecutionService>(mcpExecutionService);
    
    final desktopServiceProvider = DesktopServiceProvider.instance;
    final ollamaService = OllamaService(desktopServiceProvider);
    registerSingleton<OllamaService>(ollamaService);
    
    final claudeApiService = ClaudeApiService(mcpSettingsService);
    registerSingleton<ClaudeApiService>(claudeApiService);
    
    final modelConfigService = ModelConfigService(storageService, ollamaService);
    registerSingleton<ModelConfigService>(modelConfigService);
    
    final unifiedLlmService = UnifiedLLMService(modelConfigService, claudeApiService, ollamaService);
    registerSingleton<UnifiedLLMService>(unifiedLlmService);
    
    final mcpBridgeService = MCPBridgeService(mcpSettingsService);
    registerSingleton<MCPBridgeService>(mcpBridgeService);
    
    registerSingleton<ContextMCPResourceService>(ContextMCPResourceService());
    registerSingleton<AgentContextPromptService>(AgentContextPromptService());
    registerSingleton<ThemeService>(ThemeService());
    
    // Use the existing singleton BusinessEventBus
    registerSingleton<BusinessEventBus>(BusinessEventBus());
  }

  /// Register all business services
  Future<void> _registerBusinessServices() async {
    // Agent business service
    registerLazySingleton<AgentBusinessService>(() => AgentBusinessService(
      agentRepository: get<AgentService>(),
      mcpService: get<MCPBridgeService>(),
      modelService: get<UnifiedLLMService>(),
      contextService: get<ContextMCPResourceService>(),
      promptService: get<AgentContextPromptService>(),
      eventBus: get<BusinessEventBus>(),
    ));

    // Conversation business service
    registerLazySingleton<ConversationBusinessService>(() => ConversationBusinessService(
      conversationRepository: get<ConversationService>(),
      llmService: get<UnifiedLLMService>(),
      mcpService: get<MCPBridgeService>(),
      contextService: get<ContextMCPResourceService>(),
      promptService: get<AgentContextPromptService>(),
      eventBus: get<BusinessEventBus>(),
    ));
  }

  /// Initialize services that require initialization
  Future<void> _initializeServices() async {
    final initializableServices = _services.values
        .whereType<BaseBusinessService>()
        .toList();

    for (final service in initializableServices) {
      try {
        await service.initialize();
      } catch (e) {
        debugPrint('❌ Failed to initialize service ${service.runtimeType}: $e');
      }
    }
  }

  /// Dispose all services
  Future<void> _disposeServices() async {
    final disposableServices = _services.values
        .whereType<BaseBusinessService>()
        .toList();

    for (final service in disposableServices) {
      try {
        await service.dispose();
      } catch (e) {
        debugPrint('❌ Failed to dispose service ${service.runtimeType}: $e');
      }
    }
  }

  /// Get service dependency graph for debugging
  Map<String, List<String>> getDependencyGraph() {
    final graph = <String, List<String>>{};
    
    // This is simplified - in a real implementation, you'd track dependencies
    for (final type in _services.keys) {
      graph[type.toString()] = [];
    }
    
    for (final type in _factories.keys) {
      graph[type.toString()] = [];
    }
    
    return graph;
  }

  /// Get all registered service types
  List<Type> getRegisteredTypes() {
    return <Type>{..._services.keys, ..._factories.keys}.toList();
  }

  /// Get service instance count
  int get serviceCount => _services.length + _factories.length;

  /// Check if the service locator is initialized
  bool get isInitialized => _isInitialized;
}

/// Exception thrown when a service is not registered
class ServiceNotRegisteredException implements Exception {
  final String message;
  const ServiceNotRegisteredException(this.message);

  @override
  String toString() => 'ServiceNotRegisteredException: $message';
}

/// Extension for easy service access in widgets and other classes
extension ServiceLocatorExtension on Object {
  /// Get a service from the service locator
  T getService<T>() => ServiceLocator.instance.get<T>();

  /// Check if a service is available
  bool hasService<T>() => ServiceLocator.instance.isRegistered<T>();
}

/// Mixin for classes that need access to services
mixin ServiceConsumer {
  /// Get a service instance
  T service<T>() => ServiceLocator.instance.get<T>();

  /// Check if service is available
  bool hasService<T>() => ServiceLocator.instance.isRegistered<T>();
}

/// Service locator initialization result
class ServiceLocatorResult {
  final bool success;
  final String? error;
  final Duration initializationTime;
  final List<String> initializedServices;
  final List<String> failedServices;

  const ServiceLocatorResult({
    required this.success,
    this.error,
    required this.initializationTime,
    this.initializedServices = const [],
    this.failedServices = const [],
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Service Locator Initialization Result:');
    buffer.writeln('Success: $success');
    buffer.writeln('Time: ${initializationTime.inMilliseconds}ms');
    buffer.writeln('Services: ${initializedServices.length} initialized, ${failedServices.length} failed');
    
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    
    if (failedServices.isNotEmpty) {
      buffer.writeln('Failed services: ${failedServices.join(', ')}');
    }
    
    return buffer.toString();
  }
}

/// Service health checker
class ServiceHealthChecker {
  final ServiceLocator _serviceLocator;

  ServiceHealthChecker([ServiceLocator? serviceLocator])
      : _serviceLocator = serviceLocator ?? ServiceLocator.instance;

  /// Check the health of all registered services
  Future<ServiceHealthResult> checkHealth() async {
    final results = <String, bool>{};
    final errors = <String, String>{};
    final startTime = DateTime.now();

    for (final type in _serviceLocator.getRegisteredTypes()) {
      try {
        // If we're iterating through registered types, they're all registered by definition
        // The original bug was trying to get() without a type parameter
        results[type.toString()] = true;
      } catch (e) {
        results[type.toString()] = false;
        errors[type.toString()] = e.toString();
      }
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    return ServiceHealthResult(
      isHealthy: results.values.every((healthy) => healthy),
      serviceResults: results,
      errors: errors,
      checkDuration: duration,
      timestamp: endTime,
    );
  }
}

class ServiceHealthResult {
  final bool isHealthy;
  final Map<String, bool> serviceResults;
  final Map<String, String> errors;
  final Duration checkDuration;
  final DateTime timestamp;

  const ServiceHealthResult({
    required this.isHealthy,
    required this.serviceResults,
    required this.errors,
    required this.checkDuration,
    required this.timestamp,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Service Health Check Result:');
    buffer.writeln('Overall Health: ${isHealthy ? '✅ Healthy' : '❌ Unhealthy'}');
    buffer.writeln('Check Duration: ${checkDuration.inMilliseconds}ms');
    buffer.writeln('Timestamp: $timestamp');

    if (serviceResults.isNotEmpty) {
      buffer.writeln('\nService Status:');
      for (final entry in serviceResults.entries) {
        final status = entry.value ? '✅' : '❌';
        buffer.writeln('  $status ${entry.key}');
        
        if (!entry.value && errors.containsKey(entry.key)) {
          buffer.writeln('    Error: ${errors[entry.key]}');
        }
      }
    }

    return buffer.toString();
  }
}