import 'package:flutter/foundation.dart';
import '../../../core/models/agent_template.dart';
import '../../../core/services/agent_model_recommendation_service.dart';
import 'agent_builder_state.dart';

/// Extension to AgentBuilderState for enhanced model configuration support
extension EnhancedAgentBuilderState on AgentBuilderState {
  
  // Enhanced model configuration fields
  AgentTemplate? _appliedTemplate;
  AgentModelConfiguration? _modelConfiguration;
  String _modelSelectionMode = 'template'; // 'template', 'custom', 'simple'
  List<String> _selectedCapabilities = [];
  
  // Getters for enhanced configuration
  AgentTemplate? get appliedTemplate => _appliedTemplate;
  AgentModelConfiguration? get modelConfiguration => _modelConfiguration;
  String get modelSelectionMode => _modelSelectionMode;
  List<String> get selectedCapabilities => List.unmodifiable(_selectedCapabilities);
  String? get selectedModelId => selectedModel;
  
  // Check if agent has multi-model configuration
  bool get isMultiModelAgent => _modelConfiguration?.isMultiModel ?? false;
  
  // Get the total number of models configured
  int get configuredModelCount => _modelConfiguration?.modelCount ?? 1;
  
  /// Apply a template to the builder state
  void applyTemplate(AgentTemplate template) {
    _appliedTemplate = template;
    _modelConfiguration = null; // Clear any custom configuration
    _modelSelectionMode = 'template';
    
    // Apply template settings to existing fields
    setName(template.name);
    setDescription(template.description);
    setCategory(template.category);
    setSystemPrompt(template.systemPrompt);
    _selectedCapabilities = List.from(template.capabilities);
    
    // Set the primary model as the selected model for backward compatibility
    final primaryModel = template.recommendedModels[template.primaryCapability];
    if (primaryModel != null) {
      setSelectedModelId(primaryModel);
    }
    
    // Store template configuration for later use
    final templateConfig = template.toAgentConfiguration();
    
    _hasUnsavedChanges = true;
    notifyListeners();
  }
  
  /// Set custom model configuration
  void setModelConfiguration(AgentModelConfiguration config) {
    _modelConfiguration = config;
    _appliedTemplate = null; // Clear any template
    _modelSelectionMode = 'custom';
    _selectedCapabilities = List.from(config.capabilities);
    
    // Set the primary model as the selected model for backward compatibility
    setSelectedModelId(config.primaryModelId);
    
    _hasUnsavedChanges = true;
    notifyListeners();
  }
  
  /// Set model selection mode
  void setModelSelectionMode(String mode) {
    _modelSelectionMode = mode;
    
    // Clear configurations when switching modes
    if (mode != 'template') {
      _appliedTemplate = null;
    }
    if (mode != 'custom') {
      _modelConfiguration = null;
    }
    
    _hasUnsavedChanges = true;
    notifyListeners();
  }
  
  /// Set selected capabilities
  void setSelectedCapabilities(List<String> capabilities) {
    _selectedCapabilities = List.from(capabilities);
    _hasUnsavedChanges = true;
    notifyListeners();
  }
  
  /// Set selected model ID (backward compatibility)
  void setSelectedModelId(String modelId) {
    _selectedModel = modelId;
    _hasUnsavedChanges = true;
    notifyListeners();
  }
  
  /// Get the model ID for a specific capability
  String? getModelForCapability(String capability) {
    if (_modelConfiguration != null) {
      return _modelConfiguration!.getModelForCapability(capability);
    }
    if (_appliedTemplate != null) {
      return _appliedTemplate!.recommendedModels[capability];
    }
    return selectedModel; // Fallback to single model
  }
  
  /// Build the final agent configuration including enhanced model settings
  Map<String, dynamic> buildAgentConfiguration() {
    final baseConfig = {
      'modelId': selectedModel,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'enableMemory': enableMemory,
      'enableWebSearch': enableWebSearch,
      'enableCodeExecution': enableCodeExecution,
      'mcpServers': selectedToolIds,
      'contextDocuments': contextDocuments,
      'reasoningWorkflows': reasoningWorkflowIds,
    };
    
    // Add enhanced configuration
    if (_appliedTemplate != null) {
      baseConfig.addAll(_appliedTemplate!.toAgentConfiguration());
    } else if (_modelConfiguration != null) {
      baseConfig['modelConfiguration'] = {
        'primaryModelId': _modelConfiguration!.primaryModelId,
        'specializedModels': _modelConfiguration!.specializedModels,
        'capabilities': _modelConfiguration!.capabilities,
        'recommendations': _modelConfiguration!.recommendations,
      };
      baseConfig['type'] = 'multi_model_agent';
      baseConfig['capabilities'] = _selectedCapabilities;
    } else {
      // Simple single model configuration
      baseConfig['type'] = 'single_model_agent';
      baseConfig['capabilities'] = _selectedCapabilities;
    }
    
    return baseConfig;
  }
  
  /// Validate enhanced configuration
  bool isEnhancedConfigurationValid() {
    // Check if we have a valid model configuration
    switch (_modelSelectionMode) {
      case 'template':
        return _appliedTemplate != null;
      case 'custom':
        return _modelConfiguration != null && _selectedCapabilities.isNotEmpty;
      case 'simple':
        return selectedModel.isNotEmpty;
      default:
        return false;
    }
  }
  
  /// Get display information for the current configuration
  String getConfigurationSummary() {
    if (_appliedTemplate != null) {
      final modelCount = _appliedTemplate!.isMultiModel 
          ? _appliedTemplate!.recommendedModels.length 
          : 1;
      return '${_appliedTemplate!.name} template with $modelCount model${modelCount > 1 ? 's' : ''}';
    } else if (_modelConfiguration != null) {
      return 'Custom configuration with ${_modelConfiguration!.modelCount} model${_modelConfiguration!.modelCount > 1 ? 's' : ''}';
    } else {
      return 'Single model: $selectedModel';
    }
  }
  
  /// Reset enhanced configuration
  void resetEnhancedConfiguration() {
    _appliedTemplate = null;
    _modelConfiguration = null;
    _modelSelectionMode = 'template';
    _selectedCapabilities = [];
    _hasUnsavedChanges = true;
    notifyListeners();
  }
  
  /// Override step validation to include enhanced model configuration
  @override
  bool isStepValid(AgentBuilderStep step) {
    switch (step) {
      case AgentBuilderStep.modelConfig:
        return isEnhancedConfigurationValid() && 
               super.isStepValid(step);
      default:
        return super.isStepValid(step);
    }
  }
}