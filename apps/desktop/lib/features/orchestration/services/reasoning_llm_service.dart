import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../../core/services/llm/llm_provider.dart';
import '../../../core/services/llm/unified_llm_service.dart';
import '../models/reasoning_capabilities.dart';
import '../models/logic_block.dart';

/// Enhanced LLM service specifically for reasoning workflows
/// Extends existing Asmbli LLM architecture with reasoning capabilities
class ReasoningLLMService {
  final UnifiedLLMService _unifiedLLMService;
  final Map<String, ReasoningCapabilities> _capabilityCache = {};
  final Map<String, CapabilityDetectionResult> _detectionCache = {};
  
  ReasoningLLMService(this._unifiedLLMService);
  
  /// Get or detect reasoning capabilities for a model
  Future<ReasoningCapabilities> getModelCapabilities(String modelId) async {
    // Check cache first
    if (_capabilityCache.containsKey(modelId)) {
      return _capabilityCache[modelId]!;
    }
    
    // Try to get model info from unified service
    final provider = await _unifiedLLMService.getProvider(modelId);
    if (provider == null) {
      throw Exception('Model not found: $modelId');
    }
    
    // Check if we have a detection result
    if (_detectionCache.containsKey(modelId)) {
      final detection = _detectionCache[modelId]!;
      _capabilityCache[modelId] = detection.capabilities;
      return detection.capabilities;
    }
    
    // Detect capabilities
    final capabilities = await _detectCapabilities(provider);
    _capabilityCache[modelId] = capabilities.capabilities;
    _detectionCache[modelId] = capabilities;
    
    return capabilities.capabilities;
  }
  
  /// Detect model capabilities through runtime testing
  Future<CapabilityDetectionResult> _detectCapabilities(LLMProvider provider) async {
    final testResults = <String, dynamic>{};
    var totalScore = 0.0;
    
    try {
      // Test 1: Basic reasoning capability
      final reasoningScore = await _testReasoningCapability(provider);
      testResults['reasoning'] = reasoningScore;
      totalScore += reasoningScore;
      
      // Test 2: Structured output capability
      final structuredScore = await _testStructuredOutput(provider);
      testResults['structured_output'] = structuredScore;
      totalScore += structuredScore;
      
      // Test 3: Function calling (if supported by provider)
      final functionScore = await _testFunctionCalling(provider);
      testResults['function_calling'] = functionScore;
      totalScore += functionScore;
      
      // Test 4: Context length estimation
      final contextScore = await _testContextLength(provider);
      testResults['context_length'] = contextScore;
      totalScore += contextScore;
      
      final averageScore = totalScore / 4;
      
      // Build capabilities based on test results
      final capabilities = ReasoningCapabilities(
        reasoning: reasoningScore > 0.7,
        functionCalling: functionScore > 0.7,
        structuredOutput: structuredScore > 0.7,
        contextLength: contextScore > 0.7,
        streaming: provider.capabilities.supportsStreaming,
        maxTokens: provider.capabilities.maxContextLength,
        confidenceSupport: reasoningScore,
        reasoningPatterns: _getPatterns(reasoningScore, functionScore, structuredScore),
      );
      
      return CapabilityDetectionResult(
        modelName: provider.name,
        capabilities: capabilities,
        confidenceScore: averageScore,
        detectedAt: DateTime.now(),
        testResults: testResults,
      );
      
    } catch (e) {
      // Fall back to known model patterns
      final fallbackCapabilities = ReasoningCapabilities.forModel(provider.name);
      
      return CapabilityDetectionResult(
        modelName: provider.name,
        capabilities: fallbackCapabilities,
        confidenceScore: 0.5, // Lower confidence for fallback
        detectedAt: DateTime.now(),
        testResults: {'error': e.toString()},
      );
    }
  }
  
  Future<double> _testReasoningCapability(LLMProvider provider) async {
    const testPrompt = '''
Analyze this step by step:
Goal: Determine if user should proceed with file deletion
Context: file_size=large, file_type=important, user_confidence=low

Respond in this exact format:
CONFIDENCE: [0-100]
DECISION: [proceed/defer/abort]
REASONING: [explanation]
''';
    
    try {
      final response = await provider.chat(testPrompt, const ChatContext());
      return _parseReasoningResponse(response.content);
    } catch (e) {
      return 0.0;
    }
  }
  
  double _parseReasoningResponse(String response) {
    final confidenceMatch = RegExp(r'CONFIDENCE:\s*(\d+)').firstMatch(response);
    final decisionMatch = RegExp(r'DECISION:\s*(proceed|defer|abort)').firstMatch(response);
    final reasoningMatch = RegExp(r'REASONING:\s*(.+)', multiLine: true).firstMatch(response);
    
    var score = 0.0;
    
    if (confidenceMatch != null) {
      final confidence = int.tryParse(confidenceMatch.group(1) ?? '');
      if (confidence != null && confidence >= 0 && confidence <= 100) {
        score += 0.4; // Correct confidence format
      }
    }
    
    if (decisionMatch != null) {
      final decision = decisionMatch.group(1);
      if (decision == 'defer' || decision == 'abort') {
        score += 0.3; // Correct decision for low confidence scenario
      }
    }
    
    if (reasoningMatch != null && reasoningMatch.group(1)!.trim().isNotEmpty) {
      score += 0.3; // Has reasoning explanation
    }
    
    return score;
  }
  
  Future<double> _testStructuredOutput(LLMProvider provider) async {
    const testPrompt = '''
Generate a JSON object with these exact fields:
{
  "confidence": number between 0 and 1,
  "decision": one of ["proceed", "defer", "abort"],
  "factors": array of strings
}

For the scenario: User wants to delete an important large file but has low confidence.
''';
    
    try {
      final response = await provider.chat(testPrompt, const ChatContext());
      return _parseJsonResponse(response.content);
    } catch (e) {
      return 0.0;
    }
  }
  
  double _parseJsonResponse(String response) {
    try {
      // Extract JSON from response (handle markdown code blocks)
      final jsonMatch = RegExp(r'```(?:json)?\s*(\{.*?\})\s*```', dotAll: true).firstMatch(response);
      final jsonString = jsonMatch?.group(1) ?? response.trim();
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      var score = 0.0;
      
      // Check for required fields
      if (json.containsKey('confidence') && json['confidence'] is num) {
        final confidence = json['confidence'] as num;
        if (confidence >= 0 && confidence <= 1) {
          score += 0.4;
        }
      }
      
      if (json.containsKey('decision') && 
          ['proceed', 'defer', 'abort'].contains(json['decision'])) {
        score += 0.3;
      }
      
      if (json.containsKey('factors') && json['factors'] is List) {
        final factors = json['factors'] as List;
        if (factors.isNotEmpty && factors.every((f) => f is String)) {
          score += 0.3;
        }
      }
      
      return score;
    } catch (e) {
      return 0.0;
    }
  }
  
  Future<double> _testFunctionCalling(LLMProvider provider) async {
    // For now, return 0 since we'll implement function calling in a later iteration
    // This is where we'd test tool calling capabilities
    return 0.0;
  }
  
  Future<double> _testContextLength(LLMProvider provider) async {
    // Estimate based on provider capabilities and simple test
    final maxTokens = provider.capabilities.maxContextLength;
    
    if (maxTokens > 32000) return 1.0;   // Long context
    if (maxTokens > 8000) return 0.8;    // Medium context
    if (maxTokens > 4000) return 0.6;    // Standard context
    return 0.4; // Short context
  }
  
  List<String> _getPatterns(double reasoning, double function, double structured) {
    final patterns = <String>[];
    
    if (function > 0.7) patterns.add('function_calling');
    if (structured > 0.7) patterns.add('structured_output');
    if (reasoning > 0.7) {
      patterns.addAll(['cot', 'react']);
      if (reasoning > 0.8) patterns.add('tot');
    }
    if (patterns.isEmpty) patterns.add('basic_chat');
    
    return patterns;
  }
  
  /// Execute a reasoning block with appropriate strategy
  Future<ReasoningResult> executeReasoningBlock(
    LogicBlock block,
    String modelId,
    ReasoningContext context,
  ) async {
    final capabilities = await getModelCapabilities(modelId);
    final strategy = capabilities.optimalStrategy;
    
    switch (block.type) {
      case LogicBlockType.reasoning:
        return _executeReasoningLayer(block, modelId, context, strategy);
      case LogicBlockType.gateway:
        return _executeDecisionGateway(block, modelId, context, strategy);
      case LogicBlockType.context:
        return _executeContextFilter(block, modelId, context, strategy);
      default:
        throw UnsupportedError('Block type ${block.type} not supported for LLM execution');
    }
  }
  
  Future<ReasoningResult> _executeReasoningLayer(
    LogicBlock block,
    String modelId,
    ReasoningContext context,
    ReasoningStrategy strategy,
  ) async {
    final pattern = block.properties['pattern'] as String? ?? 'react';
    final maxIterations = block.properties['maxIterations'] as int? ?? 3;
    
    final provider = await _unifiedLLMService.getProvider(modelId);
    if (provider == null) {
      throw Exception('Model not found: $modelId');
    }
    
    switch (pattern) {
      case 'cot':
        return _executeChainOfThought(provider, context, strategy);
      case 'react':
        return _executeReAct(provider, context, strategy, maxIterations);
      case 'tot':
        return _executeTreeOfThought(provider, context, strategy);
      default:
        return _executeBasicReasoning(provider, context, strategy);
    }
  }
  
  Future<ReasoningResult> _executeChainOfThought(
    LLMProvider provider,
    ReasoningContext context,
    ReasoningStrategy strategy,
  ) async {
    final prompt = '''
Think through this step by step:

Goal: ${context.goal}
Context: ${context.contextData}

Let's work through this systematically:
1. First, let me understand what we're trying to achieve
2. Then, I'll analyze the available information
3. Next, I'll consider different approaches
4. Finally, I'll reach a conclusion

Please provide your reasoning:
''';
    
    final response = await provider.chat(prompt, ChatContext(
      messages: context.conversationHistory,
      systemPrompt: 'You are a systematic reasoning assistant. Think step by step.',
    ));
    
    return ReasoningResult(
      output: response.content,
      confidence: _extractConfidence(response.content),
      reasoning: response.content,
      metadata: {
        'pattern': 'cot',
        'tokens_used': response.usage?.totalTokens ?? 0,
        'model': response.modelUsed,
      },
    );
  }
  
  Future<ReasoningResult> _executeReAct(
    LLMProvider provider,
    ReasoningContext context,
    ReasoningStrategy strategy,
    int maxIterations,
  ) async {
    var currentContext = context;
    var iteration = 0;
    var reasoning = StringBuffer();
    
    while (iteration < maxIterations) {
      final prompt = '''
You are solving this task using the ReAct pattern (Reason-Act-Observe).

Goal: ${currentContext.goal}
Context: ${currentContext.contextData}

Current iteration: ${iteration + 1}/$maxIterations

Think about what you need to do next, then act on it:

Thought: [Your reasoning about the next step]
Action: [What you will do]
Observation: [What you learned from the action]

If you have enough information to complete the task, provide your final answer.
''';
      
      final response = await provider.chat(prompt, ChatContext(
        messages: currentContext.conversationHistory,
        systemPrompt: 'You are a ReAct reasoning assistant.',
      ));
      
      reasoning.writeln('=== Iteration ${iteration + 1} ===');
      reasoning.writeln(response.content);
      reasoning.writeln();
      
      // Check if we have a final answer
      if (response.content.toLowerCase().contains('final answer') ||
          response.content.toLowerCase().contains('conclusion')) {
        break;
      }
      
      iteration++;
    }
    
    return ReasoningResult(
      output: reasoning.toString(),
      confidence: _extractConfidence(reasoning.toString()),
      reasoning: reasoning.toString(),
      metadata: {
        'pattern': 'react',
        'iterations': iteration + 1,
        'max_iterations': maxIterations,
      },
    );
  }
  
  Future<ReasoningResult> _executeTreeOfThought(
    LLMProvider provider,
    ReasoningContext context,
    ReasoningStrategy strategy,
  ) async {
    // Simplified ToT implementation - explore multiple reasoning paths
    final prompt = '''
Explore multiple approaches to solve this problem:

Goal: ${context.goal}
Context: ${context.contextData}

Generate 3 different reasoning paths:

Path 1: [First approach and reasoning]
Path 2: [Second approach and reasoning]
Path 3: [Third approach and reasoning]

Evaluate each path and select the best one:
Best Path: [Selected path with justification]
''';
    
    final response = await provider.chat(prompt, ChatContext(
      messages: context.conversationHistory,
      systemPrompt: 'You are a systematic reasoning assistant exploring multiple approaches.',
    ));
    
    return ReasoningResult(
      output: response.content,
      confidence: _extractConfidence(response.content),
      reasoning: response.content,
      metadata: {
        'pattern': 'tot',
        'paths_explored': 3,
      },
    );
  }
  
  Future<ReasoningResult> _executeBasicReasoning(
    LLMProvider provider,
    ReasoningContext context,
    ReasoningStrategy strategy,
  ) async {
    final prompt = '''
${context.goal}

Context: ${context.contextData}

Please provide your response:
''';
    
    final response = await provider.chat(prompt, ChatContext(
      messages: context.conversationHistory,
    ));
    
    return ReasoningResult(
      output: response.content,
      confidence: 0.5, // Lower confidence for basic reasoning
      reasoning: 'Basic reasoning applied',
      metadata: {
        'pattern': 'basic',
      },
    );
  }
  
  Future<ReasoningResult> _executeDecisionGateway(
    LogicBlock block,
    String modelId,
    ReasoningContext context,
    ReasoningStrategy strategy,
  ) async {
    final confidenceThreshold = block.properties['confidence'] as double? ?? 0.8;
    final decisionStrategy = block.properties['strategy'] as String? ?? 'llm_decision';
    
    if (decisionStrategy == 'rule_based') {
      return _executeRuleBasedDecision(block, context, confidenceThreshold);
    }
    
    final provider = await _unifiedLLMService.getProvider(modelId);
    if (provider == null) {
      throw Exception('Model not found: $modelId');
    }
    
    final prompt = '''
Make a routing decision based on this information:

Goal: ${context.goal}
Context: ${context.contextData}
Current State: ${context.currentState}

Confidence Threshold: ${(confidenceThreshold * 100).round()}%

Analyze the situation and decide:
1. What is your confidence level (0-100%)?
2. Should we proceed, defer, or escalate?
3. What is your reasoning?

Format your response as:
CONFIDENCE: [0-100]
DECISION: [proceed/defer/escalate]
REASONING: [your explanation]
''';
    
    final response = await provider.chat(prompt, ChatContext(
      messages: context.conversationHistory,
      systemPrompt: 'You are a decision gateway analyzing confidence and routing decisions.',
    ));
    
    final confidence = _extractConfidence(response.content) / 100;
    final decision = _extractDecision(response.content);
    
    return ReasoningResult(
      output: decision,
      confidence: confidence,
      reasoning: response.content,
      metadata: {
        'threshold': confidenceThreshold,
        'strategy': 'llm_decision',
        'meets_threshold': confidence >= confidenceThreshold,
      },
    );
  }
  
  Future<ReasoningResult> _executeRuleBasedDecision(
    LogicBlock block,
    ReasoningContext context,
    double threshold,
  ) async {
    // Simple rule-based decision making
    var confidence = 0.5;
    var decision = 'defer';
    var reasoning = 'Rule-based decision: ';
    
    // Analyze context for confidence indicators
    final contextData = context.contextData.toLowerCase();
    
    if (contextData.contains('high confidence') || contextData.contains('certain')) {
      confidence = 0.9;
    } else if (contextData.contains('low confidence') || contextData.contains('uncertain')) {
      confidence = 0.3;
    }
    
    if (confidence >= threshold) {
      decision = 'proceed';
      reasoning += 'Confidence $confidence meets threshold $threshold';
    } else {
      decision = 'defer';
      reasoning += 'Confidence $confidence below threshold $threshold';
    }
    
    return ReasoningResult(
      output: decision,
      confidence: confidence,
      reasoning: reasoning,
      metadata: {
        'threshold': threshold,
        'strategy': 'rule_based',
      },
    );
  }
  
  Future<ReasoningResult> _executeContextFilter(
    LogicBlock block,
    String modelId,
    ReasoningContext context,
    ReasoningStrategy strategy,
  ) async {
    final maxResults = block.properties['maxResults'] as int? ?? 10;
    
    // For now, return the existing context
    // In Phase 3, this will integrate with vector stores and RAG
    return ReasoningResult(
      output: context.contextData,
      confidence: 0.8,
      reasoning: 'Context filter applied (Phase 3 will add RAG integration)',
      metadata: {
        'max_results': maxResults,
        'filtered_items': 1,
      },
    );
  }
  
  double _extractConfidence(String text) {
    final confidenceMatch = RegExp(r'CONFIDENCE:\s*(\d+)').firstMatch(text);
    if (confidenceMatch != null) {
      return double.tryParse(confidenceMatch.group(1) ?? '50') ?? 50.0;
    }
    
    // Look for percentage patterns
    final percentMatch = RegExp(r'(\d+)%').firstMatch(text);
    if (percentMatch != null) {
      return double.tryParse(percentMatch.group(1) ?? '50') ?? 50.0;
    }
    
    return 50.0; // Default confidence
  }
  
  String _extractDecision(String text) {
    final decisionMatch = RegExp(r'DECISION:\s*(proceed|defer|escalate|abort)', caseSensitive: false).firstMatch(text);
    return decisionMatch?.group(1)?.toLowerCase() ?? 'defer';
  }
}

/// Context for reasoning execution
class ReasoningContext {
  final String goal;
  final String contextData;
  final List<Map<String, String>> conversationHistory;
  final Map<String, dynamic> currentState;
  final Map<String, dynamic> metadata;
  
  const ReasoningContext({
    required this.goal,
    required this.contextData,
    this.conversationHistory = const [],
    this.currentState = const {},
    this.metadata = const {},
  });
  
  ReasoningContext copyWith({
    String? goal,
    String? contextData,
    List<Map<String, String>>? conversationHistory,
    Map<String, dynamic>? currentState,
    Map<String, dynamic>? metadata,
  }) {
    return ReasoningContext(
      goal: goal ?? this.goal,
      contextData: contextData ?? this.contextData,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      currentState: currentState ?? this.currentState,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Result from reasoning execution
class ReasoningResult {
  final String output;
  final double confidence;
  final String reasoning;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  
  ReasoningResult({
    required this.output,
    required this.confidence,
    required this.reasoning,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  bool get isSuccessful => confidence > 0.5;
  bool get isHighConfidence => confidence > 0.8;
}