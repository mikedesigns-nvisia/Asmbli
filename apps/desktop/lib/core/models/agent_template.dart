import 'package:flutter/material.dart';
import '../services/agent_template_service.dart';

/// Template for creating pre-configured agents with optimal model selection
class AgentTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final List<String> capabilities;
  final String primaryCapability;
  final Map<String, String> recommendedModels; // capability -> model ID
  final String systemPrompt;
  final List<String> exampleTasks;
  final List<String> suggestedMCPTools;
  final EstimatedUsage estimatedTokenUsage;

  const AgentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.capabilities,
    required this.primaryCapability,
    required this.recommendedModels,
    required this.systemPrompt,
    required this.exampleTasks,
    required this.suggestedMCPTools,
    required this.estimatedTokenUsage,
  });

  /// Create an agent configuration from this template
  Map<String, dynamic> toAgentConfiguration() {
    return {
      'type': 'templated_agent',
      'templateId': id,
      'capabilities': capabilities,
      'primaryCapability': primaryCapability,
      'modelConfiguration': {
        'primaryModelId': recommendedModels[primaryCapability],
        'specializedModels': Map.from(recommendedModels)..remove(primaryCapability),
        'capabilities': capabilities,
        'recommendations': recommendedModels,
      },
      'systemPrompt': systemPrompt,
      'suggestedMCPTools': suggestedMCPTools,
      'estimatedTokenUsage': estimatedTokenUsage.name,
    };
  }

  /// Get display name for the primary model
  String get primaryModelDisplayName {
    final primaryModel = recommendedModels[primaryCapability];
    if (primaryModel == null) return 'Not specified';
    
    // Clean up model name for display
    return _formatModelName(primaryModel);
  }

  /// Get count of specialized models
  int get specializedModelCount {
    return recommendedModels.length - 1; // -1 for primary model
  }

  /// Check if template uses multiple models
  bool get isMultiModel => recommendedModels.length > 1;

  String _formatModelName(String modelId) {
    // Convert model IDs to display names
    final cleanName = modelId
        .replaceAll(':', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
    
    return cleanName;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}