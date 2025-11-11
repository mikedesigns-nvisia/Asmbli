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