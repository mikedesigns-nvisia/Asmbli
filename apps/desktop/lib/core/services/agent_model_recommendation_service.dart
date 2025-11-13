import 'package:flutter/foundation.dart';
import 'model_config_service.dart';
import '../models/model_config.dart';
import 'llm/unified_llm_service.dart';

/// Service that recommends specific models for specific agentic use cases
class AgentModelRecommendationService {
  final ModelConfigService _modelConfigService;
  final UnifiedLLMService _llmService;
  
  AgentModelRecommendationService(
    this._modelConfigService,
    this._llmService,
  );

  /// Model recommendation matrix for different agentic capabilities
  static const Map<String, ModelRecommendation> modelRecommendations = {
    // Reasoning & Planning
    'reasoning': ModelRecommendation(
      capability: 'Complex Reasoning & Planning',
      recommendedModels: [
        ModelSpec('deepseek-r1:32b', 'DeepSeek-R1 32B', 'Best for complex reasoning with thinking mode'),
        ModelSpec('deepseek-r1:70b', 'DeepSeek-R1 70B', 'Superior reasoning for critical tasks'),
        ModelSpec('qwq:32b', 'QwQ 32B', 'Specialized reasoning model from Qwen'),
        ModelSpec('llama3.1:70b', 'Llama 3.1 70B', 'Strong general reasoning'),
      ],
      fallbackModels: [
        ModelSpec('deepseek-r1:8b', 'DeepSeek-R1 8B', 'Lighter reasoning model'),
        ModelSpec('phi-4:latest', 'Phi-4', 'Efficient reasoning for limited hardware'),
      ],
      useCases: [
        'Strategic planning',
        'Multi-step problem solving',
        'Decision trees',
        'Complex analysis',
      ],
    ),
    
    // Coding & Development
    'coding': ModelRecommendation(
      capability: 'Code Generation & Analysis',
      recommendedModels: [
        ModelSpec('qwen2.5-coder:32b', 'Qwen 2.5 Coder 32B', 'State-of-the-art coding model'),
        ModelSpec('deepseek-coder-v2:33b', 'DeepSeek Coder V2', 'Excellent for complex codebases'),
        ModelSpec('codellama:70b', 'Code Llama 70B', 'Meta\'s specialized coding model'),
      ],
      fallbackModels: [
        ModelSpec('qwen2.5-coder:7b', 'Qwen 2.5 Coder 7B', 'Efficient coding model'),
        ModelSpec('codellama:13b', 'Code Llama 13B', 'Good balance of size and capability'),
      ],
      useCases: [
        'Full-stack development',
        'Code refactoring',
        'Bug fixing',
        'Architecture design',
        'Code reviews',
      ],
    ),
    
    // Vision & Design
    'vision': ModelRecommendation(
      capability: 'Visual Analysis & Design',
      recommendedModels: [
        ModelSpec('llava:34b', 'LLaVA 34B', 'Best visual understanding and UI analysis'),
        ModelSpec('bakllava:latest', 'BakLLaVA', 'Efficient vision-language model'),
        ModelSpec('llava-v1.6:13b', 'LLaVA 1.6', 'Enhanced OCR and diagram understanding'),
      ],
      fallbackModels: [
        ModelSpec('llava:7b', 'LLaVA 7B', 'Lighter vision model'),
      ],
      useCases: [
        'UI/UX analysis',
        'Screenshot understanding',
        'Design feedback',
        'Visual QA',
        'OCR tasks',
      ],
    ),
    
    // Creative Writing
    'creative': ModelRecommendation(
      capability: 'Creative Content Generation',
      recommendedModels: [
        ModelSpec('dolphin-mixtral:8x22b', 'Dolphin Mixtral 8x22B', 'Uncensored creative model'),
        ModelSpec('llama3.1:70b', 'Llama 3.1 70B', 'Excellent creative writing'),
        ModelSpec('mixtral:8x7b', 'Mixtral 8x7B', 'MoE model for diverse content'),
      ],
      fallbackModels: [
        ModelSpec('dolphin-llama3:8b', 'Dolphin Llama 3', 'Smaller creative model'),
        ModelSpec('llama3.1:8b', 'Llama 3.1 8B', 'Efficient creative writing'),
      ],
      useCases: [
        'Story writing',
        'Marketing copy',
        'Blog posts',
        'Creative brainstorming',
        'Content ideation',
      ],
    ),
    
    // Data Analysis
    'analysis': ModelRecommendation(
      capability: 'Data Analysis & Research',
      recommendedModels: [
        ModelSpec('llama3.1:405b', 'Llama 3.1 405B', 'Massive context for data analysis'),
        ModelSpec('mixtral:8x22b', 'Mixtral 8x22B', 'Strong analytical capabilities'),
        ModelSpec('yi:34b-200k', 'Yi 34B', '200K context for large datasets'),
      ],
      fallbackModels: [
        ModelSpec('llama3.1:70b', 'Llama 3.1 70B', 'Good for most analysis tasks'),
        ModelSpec('phi-3-medium:14b-128k', 'Phi-3 Medium', '128K context window'),
      ],
      useCases: [
        'Data interpretation',
        'Statistical analysis',
        'Report generation',
        'Trend analysis',
        'Research synthesis',
      ],
    ),
    
    // Customer Support
    'support': ModelRecommendation(
      capability: 'Customer Support & Communication',
      recommendedModels: [
        ModelSpec('llama3.1:8b-instruct', 'Llama 3.1 Instruct', 'Well-tuned for conversations'),
        ModelSpec('mistral:7b-instruct', 'Mistral 7B Instruct', 'Fast and helpful'),
        ModelSpec('gemma2:9b', 'Gemma 2 9B', 'Google\'s efficient chat model'),
      ],
      fallbackModels: [
        ModelSpec('phi-3:mini', 'Phi-3 Mini', 'Ultra-light for simple support'),
      ],
      useCases: [
        'Customer inquiries',
        'FAQ responses',
        'Ticket resolution',
        'Live chat support',
        'Email drafting',
      ],
    ),
    
    // Function Calling & Tool Use
    'tools': ModelRecommendation(
      capability: 'Function Calling & Tool Integration',
      recommendedModels: [
        ModelSpec('mistral:7b-instruct', 'Mistral 7B Instruct', 'Excellent function calling'),
        ModelSpec('llama3.1:70b-instruct', 'Llama 3.1 70B Instruct', 'Reliable tool use'),
        ModelSpec('hermes3:8b', 'Hermes 3', 'Specifically tuned for tool use'),
      ],
      fallbackModels: [
        ModelSpec('openhermes:7b', 'OpenHermes', 'Good function calling support'),
      ],
      useCases: [
        'API integration',
        'Database queries',
        'System commands',
        'Multi-tool orchestration',
        'Workflow automation',
      ],
    ),
    
    // Math & Science
    'math': ModelRecommendation(
      capability: 'Mathematical & Scientific Reasoning',
      recommendedModels: [
        ModelSpec('deepseek-math:7b', 'DeepSeek Math', 'Specialized for mathematics'),
        ModelSpec('wizard-math:70b', 'WizardMath 70B', 'Strong mathematical reasoning'),
        ModelSpec('llama3.1:70b', 'Llama 3.1 70B', 'Good general math capabilities'),
      ],
      fallbackModels: [
        ModelSpec('phi-3:medium', 'Phi-3 Medium', 'Decent math for smaller model'),
      ],
      useCases: [
        'Mathematical proofs',
        'Scientific calculations',
        'Physics problems',
        'Statistical modeling',
        'Engineering computations',
      ],
    ),
  };

  /// Get recommended models for a specific capability
  ModelRecommendation? getRecommendation(String capability) {
    return modelRecommendations[capability];
  }

  /// Get all available recommendations
  Map<String, ModelRecommendation> getAllRecommendations() {
    return Map.from(modelRecommendations);
  }

  /// Find best available model for a capability from installed models
  Future<ModelConfig?> findBestAvailableModel(String capability) async {
    final recommendation = getRecommendation(capability);
    if (recommendation == null) return null;
    
    final availableModels = _modelConfigService.getReadyModels();
    
    // Check recommended models first
    for (final spec in recommendation.recommendedModels) {
      final model = _findMatchingModel(availableModels, spec.modelId);
      if (model != null) {
        debugPrint('Found recommended model for $capability: ${model.name}');
        return model;
      }
    }
    
    // Check fallback models
    for (final spec in recommendation.fallbackModels) {
      final model = _findMatchingModel(availableModels, spec.modelId);
      if (model != null) {
        debugPrint('Found fallback model for $capability: ${model.name}');
        return model;
      }
    }
    
    debugPrint('No suitable model found for $capability');
    return null;
  }

  /// Get model recommendations for multiple capabilities
  Future<Map<String, ModelConfig?>> findModelsForCapabilities(List<String> capabilities) async {
    final results = <String, ModelConfig?>{};
    
    for (final capability in capabilities) {
      results[capability] = await findBestAvailableModel(capability);
    }
    
    return results;
  }

  /// Create an optimized agent configuration based on use case
  Future<AgentModelConfiguration> createOptimizedConfiguration({
    required List<String> capabilities,
    required String primaryUseCase,
    int? maxModels,
  }) async {
    final modelMap = await findModelsForCapabilities(capabilities);
    
    // Determine primary model
    final primaryModel = modelMap[primaryUseCase] ?? 
                        modelMap.values.firstWhere((m) => m != null, orElse: () => null);
    
    if (primaryModel == null) {
      throw Exception('No suitable models found for requested capabilities');
    }
    
    // Build specialized models map
    final specializedModels = <String, String>{};
    modelMap.forEach((capability, model) {
      if (model != null && model.id != primaryModel.id) {
        specializedModels[capability] = model.id;
      }
    });
    
    // Limit number of models if requested
    if (maxModels != null && specializedModels.length > maxModels - 1) {
      final prioritized = capabilities
          .where((c) => specializedModels.containsKey(c))
          .take(maxModels - 1)
          .toList();
      
      specializedModels.removeWhere((key, value) => !prioritized.contains(key));
    }
    
    return AgentModelConfiguration(
      primaryModelId: primaryModel.id,
      specializedModels: specializedModels,
      capabilities: capabilities,
      recommendations: modelMap.map((k, v) => MapEntry(k, v?.name ?? 'Not available')),
    );
  }

  /// Helper to find matching model
  ModelConfig? _findMatchingModel(List<ModelConfig> models, String modelId) {
    // Clean up model ID for comparison
    final cleanId = modelId.toLowerCase().replaceAll(':', '_');
    
    return models.firstWhere(
      (model) {
        final ollamaId = model.ollamaModelId?.toLowerCase() ?? '';
        final modelName = model.name.toLowerCase();
        final id = model.id.toLowerCase();
        
        return ollamaId.contains(cleanId) || 
               modelName.contains(cleanId) || 
               id.contains(cleanId) ||
               ollamaId == modelId ||
               _fuzzyMatch(ollamaId, modelId);
      },
      orElse: () => models.firstWhere(
        (model) => _fuzzyMatch(model.name.toLowerCase(), modelId),
        orElse: () => models.firstWhere(
          (m) => m.id.contains('local_') && m.name.toLowerCase().contains(modelId.split(':')[0]),
          orElse: () => null as ModelConfig,
        ),
      ),
    );
  }

  bool _fuzzyMatch(String a, String b) {
    // Remove common prefixes and suffixes
    final cleanA = a.replaceAll('local_', '').replaceAll('.gguf', '').replaceAll('-', '').replaceAll('_', '');
    final cleanB = b.replaceAll('local_', '').replaceAll('.gguf', '').replaceAll('-', '').replaceAll('_', '');
    
    return cleanA.contains(cleanB) || cleanB.contains(cleanA);
  }
}

/// Model recommendation for a specific capability
class ModelRecommendation {
  final String capability;
  final List<ModelSpec> recommendedModels;
  final List<ModelSpec> fallbackModels;
  final List<String> useCases;

  const ModelRecommendation({
    required this.capability,
    required this.recommendedModels,
    required this.fallbackModels,
    required this.useCases,
  });
}

/// Specification for a recommended model
class ModelSpec {
  final String modelId;
  final String displayName;
  final String description;

  const ModelSpec(this.modelId, this.displayName, this.description);
}

/// Configuration for an agent with optimized model selection
class AgentModelConfiguration {
  final String primaryModelId;
  final Map<String, String> specializedModels; // capability -> modelId
  final List<String> capabilities;
  final Map<String, String> recommendations; // capability -> model name

  AgentModelConfiguration({
    required this.primaryModelId,
    required this.specializedModels,
    required this.capabilities,
    required this.recommendations,
  });

  /// Get the model ID for a specific capability
  String getModelForCapability(String capability) {
    return specializedModels[capability] ?? primaryModelId;
  }

  /// Check if agent has multiple models
  bool get isMultiModel => specializedModels.isNotEmpty;

  /// Get total number of models
  int get modelCount => specializedModels.length + 1; // +1 for primary
}