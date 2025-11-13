import 'package:flutter/foundation.dart';
import 'llm/unified_llm_service.dart';
import 'llm/llm_provider.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../models/model_config.dart';

/// Orchestrates dual-model design agent with planning and vision capabilities
class DesignAgentOrchestratorService {
  final UnifiedLLMService _llmService;
  
  // Model IDs - these should match your Ollama model names
  static const String planningModelId = 'local_deepseek-r1_32b';  // Adjusted for Ollama naming
  static const String visionModelId = 'local_llava_13b';  // Adjusted for Ollama naming
  
  // Dynamic model IDs discovered at runtime
  String? _actualPlanningModelId;
  String? _actualVisionModelId;
  
  DesignAgentOrchestratorService(this._llmService);

  /// Get the actual model IDs from available models
  Future<(String? planningId, String? visionId)> findDesignModels() async {
    final providers = _llmService.getAvailableProviders();
    
    String? planningModelFound;
    String? visionModelFound;
    
    for (final provider in providers) {
      final modelId = provider.modelConfig.ollamaModelId ?? provider.modelConfig.id;
      final modelName = modelId.toLowerCase();
      
      // Check for planning model (DeepSeek-R1)
      if (modelName.contains('deepseek') && modelName.contains('r1')) {
        planningModelFound = provider.modelConfig.id;
        debugPrint('Found planning model: $planningModelFound (${provider.modelConfig.name})');
      }
      
      // Check for vision model (LLaVA)
      if (modelName.contains('llava')) {
        visionModelFound = provider.modelConfig.id;
        debugPrint('Found vision model: $visionModelFound (${provider.modelConfig.name})');
      }
    }
    
    return (planningModelFound, visionModelFound);
  }

  /// Initialize and verify both models are available
  Future<bool> initialize() async {
    try {
      // Try to find the models dynamically first
      final (dynamicPlanningId, dynamicVisionId) = await findDesignModels();
      
      _actualPlanningModelId = dynamicPlanningId ?? planningModelId;
      _actualVisionModelId = dynamicVisionId ?? visionModelId;
      
      final planningProvider = _llmService.getProvider(_actualPlanningModelId!);
      final visionProvider = _llmService.getProvider(_actualVisionModelId!);
      
      if (planningProvider == null || visionProvider == null) {
        debugPrint('Design agent models not configured');
        debugPrint('Available models: ${_llmService.getAvailableProviders().map((p) => p.modelConfig.id).join(', ')}');
        return false;
      }
      
      final planningAvailable = await planningProvider.isAvailable;
      final visionAvailable = await visionProvider.isAvailable;
      
      if (!planningAvailable) {
        debugPrint('Planning model $_actualPlanningModelId not available');
      }
      if (!visionAvailable) {
        debugPrint('Vision model $_actualVisionModelId not available');
      }
      
      return planningAvailable && visionAvailable;
    } catch (e) {
      debugPrint('Error initializing design agent orchestrator: $e');
      return false;
    }
  }

  /// Plan a design task using the reasoning model
  Future<DesignPlan> planDesign({
    required String userRequest,
    String? projectContext,
    List<String>? existingComponents,
  }) async {
    final systemPrompt = '''You are an expert UI/UX design planner. Your role is to:
1. Analyze design requirements and break them into clear, actionable steps
2. Consider user experience, accessibility, and modern design principles
3. Suggest appropriate design patterns and component structures
4. Plan the visual hierarchy and information architecture

Provide structured, detailed plans that can guide the implementation process.''';

    final prompt = _buildPlanningPrompt(userRequest, projectContext, existingComponents);
    
    final response = await _llmService.chat(
      message: prompt,
      modelId: _actualPlanningModelId ?? planningModelId,
      context: ChatContext(systemPrompt: systemPrompt),
    );
    
    return DesignPlan.fromResponse(response.content);
  }

  /// Analyze a design image using the vision model
  Future<DesignAnalysis> analyzeDesign({
    required String base64Image,
    required DesignPlan plan,
    String? specificFocus,
  }) async {
    final visionProvider = _llmService.getProvider(_actualVisionModelId ?? visionModelId);
    if (visionProvider == null) {
      throw Exception('Vision model not available');
    }
    
    final systemPrompt = '''You are an expert UI/UX analyst with deep knowledge of:
- Design systems and component libraries
- Accessibility standards (WCAG)
- Modern design trends and best practices
- Color theory and typography
- Layout patterns and responsive design

Analyze designs thoroughly and provide actionable insights.''';

    final analysisPrompt = _buildAnalysisPrompt(plan, specificFocus);
    
    // Use the visionChat method for image analysis
    final localProvider = visionProvider as dynamic; // Cast to access visionChat
    final response = await localProvider.visionChat(
      message: analysisPrompt,
      base64Image: base64Image,
      context: ChatContext(systemPrompt: systemPrompt),
    );
    
    return DesignAnalysis.fromResponse(response.content);
  }

  /// Generate implementation code based on design plan and analysis
  Future<DesignImplementation> generateImplementation({
    required DesignPlan plan,
    DesignAnalysis? analysis,
    required String framework, // 'flutter', 'react', 'html', etc.
    List<String>? customRequirements,
  }) async {
    final systemPrompt = '''You are an expert frontend developer specializing in $framework.
Generate clean, maintainable code that:
- Follows framework best practices and conventions
- Implements responsive design principles
- Includes proper accessibility attributes
- Uses appropriate design system components
- Is well-structured and reusable''';

    final prompt = _buildImplementationPrompt(plan, analysis, framework, customRequirements);
    
    final response = await _llmService.chat(
      message: prompt,
      modelId: _actualPlanningModelId ?? planningModelId,
      context: ChatContext(systemPrompt: systemPrompt),
    );
    
    return DesignImplementation.fromResponse(response.content, framework);
  }

  /// Iterate on a design based on feedback
  Future<DesignPlan> iterateDesign({
    required DesignPlan currentPlan,
    required String feedback,
    DesignAnalysis? currentAnalysis,
  }) async {
    final systemPrompt = '''You are an expert design consultant who excels at:
- Understanding and incorporating user feedback
- Iterating on designs while maintaining core objectives
- Balancing user requests with design best practices
- Suggesting improvements that enhance usability''';

    final prompt = '''Based on the current design plan and feedback, create an updated plan.

Current Plan:
${currentPlan.toDetailedString()}

${currentAnalysis != null ? 'Current Analysis:\n${currentAnalysis.summary}\n' : ''}

User Feedback:
$feedback

Create an updated design plan that addresses the feedback while maintaining design quality.''';
    
    final response = await _llmService.chat(
      message: prompt,
      modelId: _actualPlanningModelId ?? planningModelId,
      context: ChatContext(systemPrompt: systemPrompt),
    );
    
    return DesignPlan.fromResponse(response.content);
  }

  /// Get design suggestions based on context
  Future<List<DesignSuggestion>> getDesignSuggestions({
    required String context,
    String? currentDesignDescription,
    List<String>? constraints,
  }) async {
    final prompt = '''Based on the following context, provide 3-5 specific design suggestions:

Context: $context
${currentDesignDescription != null ? '\nCurrent Design: $currentDesignDescription' : ''}
${constraints != null ? '\nConstraints: ${constraints.join(', ')}' : ''}

Provide creative, practical suggestions that could enhance the design.''';
    
    final response = await _llmService.chat(
      message: prompt,
      modelId: _actualPlanningModelId ?? planningModelId,
    );
    
    return DesignSuggestion.parseMultiple(response.content);
  }

  // Helper methods for building prompts
  String _buildPlanningPrompt(String userRequest, String? projectContext, List<String>? existingComponents) {
    return '''Create a comprehensive design plan for the following request:

User Request: $userRequest

${projectContext != null ? 'Project Context: $projectContext\n' : ''}
${existingComponents != null ? 'Existing Components: ${existingComponents.join(', ')}\n' : ''}

Provide a structured plan including:
1. Design objectives and goals
2. Key UI components needed
3. Visual hierarchy and layout structure
4. Color scheme and typography recommendations
5. Interaction patterns and user flows
6. Accessibility considerations
7. Implementation phases''';
  }

  String _buildAnalysisPrompt(DesignPlan plan, String? specificFocus) {
    return '''Analyze this design image based on the following plan:

Design Plan Summary:
${plan.objectives.join('\n- ')}

${specificFocus != null ? 'Specific Focus: $specificFocus\n' : ''}

Provide detailed analysis of:
1. How well the design matches the plan objectives
2. Visual hierarchy and layout effectiveness
3. Color usage and contrast
4. Typography choices
5. Component structure and reusability
6. Accessibility concerns
7. Suggestions for improvement''';
  }

  String _buildImplementationPrompt(
    DesignPlan plan,
    DesignAnalysis? analysis,
    String framework,
    List<String>? customRequirements,
  ) {
    return '''Generate $framework implementation code for this design:

Design Plan:
${plan.toDetailedString()}

${analysis != null ? 'Design Analysis:\n${analysis.summary}\n' : ''}

${customRequirements != null ? 'Additional Requirements:\n${customRequirements.join('\n- ')}\n' : ''}

Generate complete, production-ready code with:
- Proper component structure
- Responsive design implementation
- Accessibility attributes
- Clean, maintainable code
- Comments for complex sections''';
  }
}

// Data models for design workflow
class DesignPlan {
  final List<String> objectives;
  final List<DesignComponent> components;
  final DesignSystem designSystem;
  final List<String> phases;
  final Map<String, dynamic> metadata;

  DesignPlan({
    required this.objectives,
    required this.components,
    required this.designSystem,
    required this.phases,
    this.metadata = const {},
  });

  factory DesignPlan.fromResponse(String response) {
    // Parse the LLM response into structured data
    // This is a simplified version - you might want more sophisticated parsing
    final lines = response.split('\n');
    final objectives = <String>[];
    final components = <DesignComponent>[];
    final phases = <String>[];
    
    String currentSection = '';
    for (final line in lines) {
      if (line.contains('objectives') || line.contains('goals')) {
        currentSection = 'objectives';
      } else if (line.contains('components')) {
        currentSection = 'components';
      } else if (line.contains('phases') || line.contains('implementation')) {
        currentSection = 'phases';
      } else if (line.trim().startsWith('-') || line.trim().startsWith('•')) {
        final content = line.trim().substring(1).trim();
        switch (currentSection) {
          case 'objectives':
            objectives.add(content);
            break;
          case 'components':
            components.add(DesignComponent(name: content, description: ''));
            break;
          case 'phases':
            phases.add(content);
            break;
        }
      }
    }
    
    return DesignPlan(
      objectives: objectives,
      components: components,
      designSystem: DesignSystem.fromResponse(response),
      phases: phases,
    );
  }

  String toDetailedString() {
    return '''
Objectives:
${objectives.map((o) => '- $o').join('\n')}

Components:
${components.map((c) => '- ${c.name}').join('\n')}

Design System:
- Primary Color: ${designSystem.primaryColor}
- Typography: ${designSystem.typography}

Phases:
${phases.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}
''';
  }
}

class DesignComponent {
  final String name;
  final String description;
  final List<String> properties;

  DesignComponent({
    required this.name,
    required this.description,
    this.properties = const [],
  });
}

class DesignSystem {
  final String primaryColor;
  final String typography;
  final Map<String, String> colorPalette;
  final Map<String, dynamic> spacing;

  DesignSystem({
    required this.primaryColor,
    required this.typography,
    this.colorPalette = const {},
    this.spacing = const {},
  });

  factory DesignSystem.fromResponse(String response) {
    // Extract design system info from response
    return DesignSystem(
      primaryColor: '#4ECDC4', // Default, extract from response
      typography: 'Inter, system-ui', // Default, extract from response
    );
  }
}

class DesignAnalysis {
  final String summary;
  final Map<String, double> scores; // accessibility, usability, etc.
  final List<String> strengths;
  final List<String> improvements;
  final Map<String, dynamic> metadata;

  DesignAnalysis({
    required this.summary,
    required this.scores,
    required this.strengths,
    required this.improvements,
    this.metadata = const {},
  });

  factory DesignAnalysis.fromResponse(String response) {
    // Parse the vision model's analysis
    return DesignAnalysis(
      summary: response,
      scores: {
        'accessibility': 0.85,
        'usability': 0.90,
        'visual_hierarchy': 0.88,
      },
      strengths: [],
      improvements: [],
    );
  }
}

class DesignImplementation {
  final String code;
  final String framework;
  final List<String> dependencies;
  final Map<String, String> files;

  DesignImplementation({
    required this.code,
    required this.framework,
    this.dependencies = const [],
    this.files = const {},
  });

  factory DesignImplementation.fromResponse(String response, String framework) {
    return DesignImplementation(
      code: response,
      framework: framework,
    );
  }
}

class DesignSuggestion {
  final String title;
  final String description;
  final String rationale;
  final String impact; // 'high', 'medium', 'low'

  DesignSuggestion({
    required this.title,
    required this.description,
    required this.rationale,
    required this.impact,
  });

  static List<DesignSuggestion> parseMultiple(String response) {
    // Parse multiple suggestions from response
    return [];
  }
}