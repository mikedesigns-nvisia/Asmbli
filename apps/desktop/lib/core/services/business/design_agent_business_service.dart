import 'dart:async';
import 'package:agent_engine_core/models/agent.dart';
import '../../models/business_result.dart';
import 'agent_business_service.dart';

/// Extension of AgentBusinessService for design-specific agent functionality
extension DesignAgentBusinessService on AgentBusinessService {
  
  /// Creates a design agent with dual-model orchestration
  Future<BusinessResult<Agent>> createDesignAgent({
    required String name,
    String? description,
    List<String> additionalCapabilities = const [],
    List<String> contextDocs = const [],
    Map<String, dynamic> additionalConfig = const {},
  }) async {
    try {
      // Get the orchestrator service
      // Design orchestrator removed for single model optimization
      
      // Initialize and verify models are available
      final isReady = await orchestrator.initialize();
      if (!isReady) {
        return BusinessResult.failure(
          'Design agent models not available. Please ensure DeepSeek-R1 and LLaVA models are installed in Ollama.'
        );
      }
      
      // Get the discovered model IDs
      final (planningModelId, visionModelId) = await orchestrator.findDesignModels();
      
      if (planningModelId == null || visionModelId == null) {
        return BusinessResult.failure(
          'Could not find required models. Please install:\n'
          '- Planning model: ollama pull deepseek-r1:32b\n'
          '- Vision model: ollama pull llava:13b'
        );
      }
      
      // Define design-specific capabilities
      final designCapabilities = [
        'ui_design',
        'visual_analysis',
        'design_planning',
        'component_generation',
        'accessibility_review',
        'responsive_design',
        'design_iteration',
        ...additionalCapabilities,
      ];
      
      // Create the configuration for a dual-model design agent
      final designConfig = {
        'type': 'design_agent',
        'orchestratorEnabled': true,
        'models': {
          'planning': planningModelId,
          'vision': visionModelId,
        },
        'designFeatures': {
          'autoAnalyzeImages': true,
          'generateImplementation': true,
          'iterativeRefinement': true,
          'frameworkSupport': ['flutter', 'react', 'html'],
        },
        ...additionalConfig,
      };
      
      // Create the agent using the base service
      final result = await createAgent(
        name: name,
        description: description ?? 'AI-powered design agent with planning and vision capabilities for UI/UX tasks',
        capabilities: designCapabilities,
        modelId: planningModelId, // Primary model for chat interface
        contextDocs: contextDocs,
        configuration: designConfig,
      );
      
      if (result.isSuccess && result.data != null) {
        // Log successful creation
        print('✅ Design agent "${name}" created successfully');
        print('   Planning model: $planningModelId');
        print('   Vision model: $visionModelId');
      }
      
      return result;
    } catch (e) {
      return BusinessResult.failure(
        'Failed to create design agent: $e'
      );
    }
  }
  
  /// Check if an agent is a design agent with orchestration
  bool isDesignAgent(Agent agent) {
    final config = agent.configuration ?? {};
    return config['type'] == 'design_agent' && 
           config['orchestratorEnabled'] == true;
  }
  
  /// Get the design agent orchestrator for a specific agent
  /// Removed for single model optimization
  Future<void> getDesignOrchestrator(String agentId) async {
    // No longer needed with simplified architecture
  }
  
  /// Execute a design workflow with the agent
  Future<BusinessResult<DesignWorkflowResult>> executeDesignWorkflow({
    required String agentId,
    required String userRequest,
    String? projectContext,
    List<String>? existingComponents,
    String? imageBase64,
  }) async {
    try {
      // Get the agent and verify it's a design agent
      final agentResult = await getAgentById(agentId);
      if (!agentResult.isSuccess || agentResult.data == null) {
        return BusinessResult.failure('Agent not found');
      }
      
      final agent = agentResult.data!;
      if (!isDesignAgent(agent)) {
        return BusinessResult.failure('Agent is not configured for design tasks');
      }
      
      // Get the orchestrator
      final orchestrator = await getDesignOrchestrator(agentId);
      if (orchestrator == null) {
        return BusinessResult.failure('Design orchestrator not available');
      }
      
      // Initialize if needed
      await orchestrator.initialize();
      
      // Execute the workflow
      // 1. Planning phase
      final plan = await orchestrator.planDesign(
        userRequest: userRequest,
        projectContext: projectContext,
        existingComponents: existingComponents,
      );
      
      // 2. Visual analysis phase (if image provided)
      DesignAnalysis? analysis;
      if (imageBase64 != null) {
        analysis = await orchestrator.analyzeDesign(
          base64Image: imageBase64,
          plan: plan,
        );
      }
      
      // 3. Generate suggestions
      final suggestions = await orchestrator.getDesignSuggestions(
        context: userRequest,
        currentDesignDescription: analysis?.summary,
      );
      
      return BusinessResult.success(
        DesignWorkflowResult(
          plan: plan,
          analysis: analysis,
          suggestions: suggestions,
        )
      );
    } catch (e) {
      return BusinessResult.failure('Design workflow failed: $e');
    }
  }
}

/// Result of a design workflow execution
class DesignWorkflowResult {
  final DesignPlan plan;
  final DesignAnalysis? analysis;
  final List<DesignSuggestion> suggestions;
  
  DesignWorkflowResult({
    required this.plan,
    this.analysis,
    this.suggestions = const [],
  });
}