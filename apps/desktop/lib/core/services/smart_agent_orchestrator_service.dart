import 'package:flutter/foundation.dart';
import 'package:agent_engine_core/models/agent.dart';
import 'llm/unified_llm_service.dart';
import 'llm/llm_provider.dart';
import 'agent_model_recommendation_service.dart';

/// Intelligent orchestrator that routes tasks to the best model based on content and capability
class SmartAgentOrchestratorService {
  final UnifiedLLMService _llmService;
  final AgentModelRecommendationService _recommendationService;
  
  SmartAgentOrchestratorService(
    this._llmService,
    this._recommendationService,
  );

  /// Process a message with intelligent model routing
  Future<SmartAgentResponse> processMessage({
    required Agent agent,
    required String message,
    String? imageBase64,
    ChatContext? context,
  }) async {
    try {
      // Analyze the message to determine the best capability/model
      final analysis = _analyzeMessage(message, imageBase64 != null);
      
      // Get agent configuration
      final config = agent.configuration ?? {};
      final agentModelConfig = config['modelConfiguration'] as Map<String, dynamic>?;
      
      String modelId;
      String reasoning = '';
      
      if (agentModelConfig != null) {
        // Agent has optimized model configuration
        final optimizedConfig = AgentModelConfiguration(
          primaryModelId: agentModelConfig['primaryModelId'],
          specializedModels: Map<String, String>.from(agentModelConfig['specializedModels'] ?? {}),
          capabilities: List<String>.from(agentModelConfig['capabilities'] ?? []),
          recommendations: Map<String, String>.from(agentModelConfig['recommendations'] ?? {}),
        );
        
        modelId = optimizedConfig.getModelForCapability(analysis.primaryCapability);
        reasoning = 'Using ${analysis.primaryCapability} specialist: ${optimizedConfig.recommendations[analysis.primaryCapability] ?? "specialized model"}';
      } else {
        // Fallback to finding best available model
        final recommendedModel = await _recommendationService.findBestAvailableModel(analysis.primaryCapability);
        modelId = recommendedModel?.id ?? agent.configuration?['modelId'] ?? 'default';
        reasoning = recommendedModel != null 
            ? 'Using recommended ${analysis.primaryCapability} model: ${recommendedModel.name}'
            : 'Using agent\'s default model';
      }
      
      // Handle vision tasks
      if (imageBase64 != null && analysis.requiresVision) {
        return await _processVisionTask(
          message: message,
          imageBase64: imageBase64,
          modelId: modelId,
          context: context,
          reasoning: reasoning,
        );
      }
      
      // Handle text tasks
      return await _processTextTask(
        message: message,
        modelId: modelId,
        context: context,
        reasoning: reasoning,
      );
      
    } catch (e) {
      debugPrint('Error in smart orchestration: $e');
      // Fallback to default processing
      final defaultModelId = agent.configuration?['modelId'] ?? 'default';
      return await _processTextTask(
        message: message,
        modelId: defaultModelId,
        context: context,
        reasoning: 'Fallback to default model due to error',
      );
    }
  }

  /// Analyze message content to determine the best capability and model
  MessageAnalysis _analyzeMessage(String message, bool hasImage) {
    final lowercaseMessage = message.toLowerCase();
    
    // Vision tasks
    if (hasImage || _containsVisualKeywords(lowercaseMessage)) {
      return MessageAnalysis(
        primaryCapability: 'vision',
        confidence: 0.95,
        requiresVision: true,
        detectedIntents: ['visual_analysis', 'ui_design'],
      );
    }
    
    // Code-related tasks
    if (_containsCodeKeywords(lowercaseMessage)) {
      return MessageAnalysis(
        primaryCapability: 'coding',
        confidence: 0.9,
        detectedIntents: ['code_generation', 'debugging', 'refactoring'],
      );
    }
    
    // Math and science
    if (_containsMathKeywords(lowercaseMessage)) {
      return MessageAnalysis(
        primaryCapability: 'math',
        confidence: 0.85,
        detectedIntents: ['mathematical_reasoning', 'calculations'],
      );
    }
    
    // Creative writing
    if (_containsCreativeKeywords(lowercaseMessage)) {
      return MessageAnalysis(
        primaryCapability: 'creative',
        confidence: 0.8,
        detectedIntents: ['content_creation', 'storytelling'],
      );
    }
    
    // Data analysis
    if (_containsAnalysisKeywords(lowercaseMessage)) {
      return MessageAnalysis(
        primaryCapability: 'analysis',
        confidence: 0.85,
        detectedIntents: ['data_interpretation', 'research'],
      );
    }
    
    // Complex reasoning
    if (_containsReasoningKeywords(lowercaseMessage)) {
      return MessageAnalysis(
        primaryCapability: 'reasoning',
        confidence: 0.8,
        detectedIntents: ['planning', 'problem_solving'],
      );
    }
    
    // Tool usage
    if (_containsToolKeywords(lowercaseMessage)) {
      return MessageAnalysis(
        primaryCapability: 'tools',
        confidence: 0.85,
        detectedIntents: ['function_calling', 'api_integration'],
      );
    }
    
    // Support/conversation
    return MessageAnalysis(
      primaryCapability: 'support',
      confidence: 0.6,
      detectedIntents: ['general_conversation'],
    );
  }

  Future<SmartAgentResponse> _processVisionTask({
    required String message,
    required String imageBase64,
    required String modelId,
    ChatContext? context,
    required String reasoning,
  }) async {
    final provider = _llmService.getProvider(modelId);
    if (provider == null) {
      throw Exception('Model $modelId not available');
    }
    
    // Check if provider supports vision
    if (provider is! dynamic || !provider.capabilities.capabilities.contains('vision')) {
      // Fallback to a vision model
      final visionModel = await _recommendationService.findBestAvailableModel('vision');
      if (visionModel == null) {
        throw Exception('No vision models available');
      }
      
      final visionProvider = _llmService.getProvider(visionModel.id);
      final response = await (visionProvider as dynamic).visionChat(
        message, 
        imageBase64, 
        context ?? const ChatContext(),
      );
      
      return SmartAgentResponse(
        content: response.content,
        modelUsed: visionModel.id,
        reasoning: 'Switched to vision model: ${visionModel.name}',
        capabilities: ['vision'],
      );
    }
    
    final response = await (provider as dynamic).visionChat(
      message, 
      imageBase64, 
      context ?? const ChatContext(),
    );
    
    return SmartAgentResponse(
      content: response.content,
      modelUsed: modelId,
      reasoning: reasoning,
      capabilities: ['vision'],
    );
  }

  Future<SmartAgentResponse> _processTextTask({
    required String message,
    required String modelId,
    ChatContext? context,
    required String reasoning,
  }) async {
    final response = await _llmService.chat(
      message: message,
      modelId: modelId,
      context: context,
    );
    
    return SmartAgentResponse(
      content: response.content,
      modelUsed: modelId,
      reasoning: reasoning,
      capabilities: ['text'],
    );
  }

  // Keyword detection methods
  bool _containsVisualKeywords(String message) {
    const keywords = [
      'screenshot', 'image', 'picture', 'photo', 'visual', 'ui', 'interface',
      'design', 'layout', 'mockup', 'wireframe', 'dashboard', 'analyze this image',
      'what do you see', 'describe the image', 'color scheme', 'typography'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }

  bool _containsCodeKeywords(String message) {
    const keywords = [
      'code', 'function', 'class', 'method', 'variable', 'bug', 'debug',
      'refactor', 'implement', 'algorithm', 'api', 'database', 'sql',
      'javascript', 'python', 'dart', 'flutter', 'react', 'html', 'css'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }

  bool _containsMathKeywords(String message) {
    const keywords = [
      'calculate', 'equation', 'formula', 'mathematics', 'algebra', 'geometry',
      'statistics', 'probability', 'derivative', 'integral', 'solve', 'graph'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }

  bool _containsCreativeKeywords(String message) {
    const keywords = [
      'write a story', 'create content', 'blog post', 'article', 'marketing copy',
      'creative', 'brainstorm', 'ideas', 'poem', 'story', 'novel', 'script'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }

  bool _containsAnalysisKeywords(String message) {
    const keywords = [
      'analyze', 'data', 'report', 'research', 'study', 'trends', 'insights',
      'interpret', 'findings', 'statistics', 'survey', 'metrics'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }

  bool _containsReasoningKeywords(String message) {
    const keywords = [
      'plan', 'strategy', 'decision', 'problem', 'solution', 'approach',
      'step by step', 'think through', 'reasoning', 'logic', 'complex'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }

  bool _containsToolKeywords(String message) {
    const keywords = [
      'use tool', 'function call', 'api call', 'execute', 'run command',
      'search', 'fetch data', 'save file', 'send email', 'integrate'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }
}

/// Analysis of a message to determine optimal processing approach
class MessageAnalysis {
  final String primaryCapability;
  final double confidence;
  final bool requiresVision;
  final List<String> detectedIntents;

  MessageAnalysis({
    required this.primaryCapability,
    required this.confidence,
    this.requiresVision = false,
    this.detectedIntents = const [],
  });
}

/// Response from the smart agent orchestrator
class SmartAgentResponse {
  final String content;
  final String modelUsed;
  final String reasoning;
  final List<String> capabilities;

  SmartAgentResponse({
    required this.content,
    required this.modelUsed,
    required this.reasoning,
    required this.capabilities,
  });
}