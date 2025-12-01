/// Recommended LLM model configuration for agent templates
class RecommendedLLM {
  final String modelId;
  final String displayName;
  final String provider; // 'ollama', 'openai', 'anthropic', 'google'
  final String reason;
  final bool isLocal;
  final String? minRam; // Minimum RAM for local models

  const RecommendedLLM({
    required this.modelId,
    required this.displayName,
    required this.provider,
    required this.reason,
    this.isLocal = false,
    this.minRam,
  });

  /// Common recommended models
  static const gpt4o = RecommendedLLM(
    modelId: 'gpt-4o',
    displayName: 'GPT-4o',
    provider: 'openai',
    reason: 'Best for complex reasoning and code generation',
  );

  static const gpt4oMini = RecommendedLLM(
    modelId: 'gpt-4o-mini',
    displayName: 'GPT-4o Mini',
    provider: 'openai',
    reason: 'Fast and cost-effective for most tasks',
  );

  static const claude35Sonnet = RecommendedLLM(
    modelId: 'claude-3-5-sonnet-20241022',
    displayName: 'Claude 3.5 Sonnet',
    provider: 'anthropic',
    reason: 'Excellent for writing and analysis',
  );

  static const claude35Haiku = RecommendedLLM(
    modelId: 'claude-3-5-haiku-20241022',
    displayName: 'Claude 3.5 Haiku',
    provider: 'anthropic',
    reason: 'Fast and efficient for quick tasks',
  );

  static const gemini15Pro = RecommendedLLM(
    modelId: 'gemini-1.5-pro',
    displayName: 'Gemini 1.5 Pro',
    provider: 'google',
    reason: 'Great for multimodal and long context',
  );

  static const llama32 = RecommendedLLM(
    modelId: 'llama3.2:latest',
    displayName: 'Llama 3.2',
    provider: 'ollama',
    reason: 'Local, private, and efficient',
    isLocal: true,
    minRam: '8GB',
  );

  static const deepseekR1 = RecommendedLLM(
    modelId: 'deepseek-r1:8b',
    displayName: 'DeepSeek R1',
    provider: 'ollama',
    reason: 'Excellent reasoning and coding locally',
    isLocal: true,
    minRam: '16GB',
  );

  static const llava13b = RecommendedLLM(
    modelId: 'llava:13b',
    displayName: 'LLaVA 13B',
    provider: 'ollama',
    reason: 'Vision + language for design tasks',
    isLocal: true,
    minRam: '16GB',
  );
}

class AgentTemplate {
  final String name;
  final String description;
  final String category;
  final List<String> tags;
  final bool mcpStack;
  final List<String> mcpServers;
  final String exampleUse;
  final int popularity;
  final bool isComingSoon;
  final ReasoningFlow reasoningFlow;
  final List<String> taskOutline;
  final RecommendedLLM? recommendedModel;
  final List<RecommendedLLM> alternativeModels;

  AgentTemplate({
    required this.name,
    required this.description,
    required this.category,
    required this.tags,
    required this.mcpStack,
    required this.mcpServers,
    required this.exampleUse,
    required this.popularity,
    this.isComingSoon = false,
    this.reasoningFlow = ReasoningFlow.sequential,
    this.taskOutline = const [],
    this.recommendedModel,
    this.alternativeModels = const [],
  });
}

enum ReasoningFlow {
  sequential,     // Step-by-step linear reasoning
  parallel,       // Multiple parallel analyses
  iterative,      // Refining through iterations
  hierarchical,   // Top-down decomposition
  collaborative,  // Multi-perspective reasoning
}

extension ReasoningFlowExtension on ReasoningFlow {
  String get name {
    switch (this) {
      case ReasoningFlow.sequential:
        return 'Sequential';
      case ReasoningFlow.parallel:
        return 'Parallel';
      case ReasoningFlow.iterative:
        return 'Iterative';
      case ReasoningFlow.hierarchical:
        return 'Hierarchical';
      case ReasoningFlow.collaborative:
        return 'Collaborative';
    }
  }
  
  String get description {
    switch (this) {
      case ReasoningFlow.sequential:
        return 'Step-by-step linear processing';
      case ReasoningFlow.parallel:
        return 'Multiple concurrent analyses';
      case ReasoningFlow.iterative:
        return 'Continuous refinement loops';
      case ReasoningFlow.hierarchical:
        return 'Top-down task decomposition';
      case ReasoningFlow.collaborative:
        return 'Multi-perspective synthesis';
    }
  }
  
  String get icon {
    switch (this) {
      case ReasoningFlow.sequential:
        return '→';
      case ReasoningFlow.parallel:
        return '⋄';
      case ReasoningFlow.iterative:
        return '↻';
      case ReasoningFlow.hierarchical:
        return '⬇';
      case ReasoningFlow.collaborative:
        return '⋈';
    }
  }
}