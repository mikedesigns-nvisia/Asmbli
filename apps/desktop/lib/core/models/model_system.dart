/// Universal Model Management System
/// 
/// This module provides a comprehensive model management system with support for
/// multiple providers, intelligent routing, cost tracking, and fallback chains.
/// 
/// Key Features:
/// - Universal model interface across providers
/// - Intelligent model selection and routing
/// - Cost tracking and usage analytics
/// - Fallback chains for reliability
/// - Local model support (Ollama)
/// - Performance monitoring
/// - Usage reporting and trends
/// 
/// Supported Providers:
/// - OpenAI (GPT models)
/// - Anthropic (Claude models)
/// - Ollama (Local models)

library model_system;

import 'model_interfaces.dart';

// Core interfaces and models
export 'model_interfaces.dart';

// Model providers
export 'providers/openai_provider.dart';
export 'providers/anthropic_provider.dart';
export 'providers/ollama_provider.dart';

// Routing and management
export 'model_router.dart';
export 'model_manager.dart';

// Examples and testing
// export 'model_management_example.dart'; // TODO: Create example file when needed

/// Quick start guide for the Model System
/// 
/// 1. Basic usage:
/// ```dart
/// final modelManager = ModelManager();
/// await modelManager.initialize();
/// 
/// final request = ModelRequest(
///   messages: [Message.user('Hello!')],
///   maxTokens: 100,
/// );
/// 
/// final response = await modelManager.complete(request);
/// print(response.content);
/// ```
/// 
/// 2. With specific provider preference:
/// ```dart
/// final response = await modelManager.complete(
///   request,
///   preferredProviders: ['ollama'], // Use local models first
/// );
/// ```
/// 
/// 3. Streaming responses:
/// ```dart
/// await for (final chunk in modelManager.stream(request)) {
///   print(chunk);
/// }
/// ```
/// 
/// 4. Cost tracking:
/// ```dart
/// final costReport = await modelManager.getCostReport();
/// print('Total cost: \$${costReport.totalCost}');
/// ```
/// 
/// 5. Run the complete example:
/// ```dart
/// await runModelManagementExample();
/// ```

/// Model System Constants
class ModelSystemConstants {
  static const String version = '1.0.0';
  static const String name = 'Universal Model Management System';
  static const String description = 'Multi-provider model management with intelligent routing';
  
  // Default configuration
  static const ModelSelectionStrategy defaultStrategy = ModelSelectionStrategy.cheapest;
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int defaultMaxTokens = 1000;
  
  // Provider priorities (lower number = higher priority)
  static const Map<String, int> providerPriorities = {
    'ollama': 1,     // Local models first (free, private)
    'anthropic': 2,  // Anthropic second (good quality/price ratio)
    'openai': 3,     // OpenAI third (widely compatible)
  };
  
  // Common model mappings
  static const Map<String, String> modelAliases = {
    'gpt-3.5': 'gpt-3.5-turbo',
    'gpt-4': 'gpt-4-turbo',
    'claude': 'claude-3-haiku-20240307',
    'claude-sonnet': 'claude-3-sonnet-20240229',
    'claude-opus': 'claude-3-opus-20240229',
    'llama': 'llama2',
    'codellama': 'codellama',
  };
  
  // Usage limits (tokens per hour)
  static const Map<String, int> defaultUsageLimits = {
    'openai': 1000000,    // 1M tokens/hour
    'anthropic': 500000,  // 500K tokens/hour
    'ollama': -1,         // Unlimited (local)
  };
}