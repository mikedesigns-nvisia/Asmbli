import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/enhanced_mcp_template.dart';

/// Intelligent MCP recommendation engine
/// Analyzes agent context to suggest relevant integrations
class IntelligentMCPRecommendations {
  static final IntelligentMCPRecommendations _instance = IntelligentMCPRecommendations._internal();
  factory IntelligentMCPRecommendations() => _instance;
  IntelligentMCPRecommendations._internal();

  /// Get MCP recommendations based on agent configuration
  List<MCPRecommendation> getRecommendationsForAgent({
    String? agentRole,
    String? agentDescription,
    List<String>? capabilities,
    List<String>? existingMCPServers,
    String? industry,
    String? useCase,
  }) {
    final recommendations = <MCPRecommendation>[];
    final context = AgentContext(
      role: agentRole,
      description: agentDescription,
      capabilities: capabilities ?? [],
      existingMCPServers: existingMCPServers ?? [],
      industry: industry,
      useCase: useCase,
    );

    // Role-based recommendations
    recommendations.addAll(_getRoleBasedRecommendations(context));
    
    // Capability-based recommendations
    recommendations.addAll(_getCapabilityBasedRecommendations(context));
    
    // Industry-specific recommendations
    recommendations.addAll(_getIndustryBasedRecommendations(context));
    
    // Description analysis recommendations
    if (agentDescription != null) {
      recommendations.addAll(_getDescriptionBasedRecommendations(context));
    }

    // Remove duplicates and filter out existing servers
    final uniqueRecommendations = _deduplicateAndFilter(recommendations, context);
    
    // Sort by relevance score
    uniqueRecommendations.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    
    return uniqueRecommendations.take(8).toList();
  }

  List<MCPRecommendation> _getRoleBasedRecommendations(AgentContext context) {
    final recommendations = <MCPRecommendation>[];
    
    switch (context.role?.toLowerCase()) {
      case 'designer':
      case 'ui/ux designer':
      case 'creative director':
        recommendations.addAll([
          MCPRecommendation(
            template: EnhancedMCPTemplates.figma,
            reason: 'Essential for design workflow and component management',
            relevanceScore: 0.95,
            category: RecommendationCategory.essential,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.filesystem,
            reason: 'Access design assets and project files',
            relevanceScore: 0.85,
            category: RecommendationCategory.recommended,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.github,
            reason: 'Collaborate on design systems and documentation',
            relevanceScore: 0.75,
            category: RecommendationCategory.useful,
          ),
        ]);
        break;

      case 'developer':
      case 'software engineer':
      case 'full-stack developer':
      case 'backend developer':
      case 'frontend developer':
        recommendations.addAll([
          MCPRecommendation(
            template: EnhancedMCPTemplates.github,
            reason: 'Essential for code management and collaboration',
            relevanceScore: 0.95,
            category: RecommendationCategory.essential,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.git,
            reason: 'Local repository operations and version control',
            relevanceScore: 0.90,
            category: RecommendationCategory.essential,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.filesystem,
            reason: 'Access project files and codebase',
            relevanceScore: 0.85,
            category: RecommendationCategory.recommended,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.postgresql,
            reason: 'Database management and queries',
            relevanceScore: 0.80,
            category: RecommendationCategory.recommended,
          ),
        ]);
        break;

      case 'data analyst':
      case 'data scientist':
      case 'business analyst':
        recommendations.addAll([
          MCPRecommendation(
            template: EnhancedMCPTemplates.postgresql,
            reason: 'Essential for data analysis and reporting',
            relevanceScore: 0.95,
            category: RecommendationCategory.essential,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.filesystem,
            reason: 'Access datasets and analysis files',
            relevanceScore: 0.90,
            category: RecommendationCategory.recommended,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.openai,
            reason: 'AI-powered insights and analysis',
            relevanceScore: 0.85,
            category: RecommendationCategory.recommended,
          ),
        ]);
        break;

      case 'project manager':
      case 'product manager':
      case 'business owner':
        recommendations.addAll([
          MCPRecommendation(
            template: EnhancedMCPTemplates.microsoftGraph,
            reason: 'Essential for team collaboration and document management',
            relevanceScore: 0.95,
            category: RecommendationCategory.essential,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.github,
            reason: 'Track development progress and issues',
            relevanceScore: 0.80,
            category: RecommendationCategory.recommended,
          ),
        ]);
        break;

      case 'content creator':
      case 'writer':
      case 'marketing':
        recommendations.addAll([
          MCPRecommendation(
            template: EnhancedMCPTemplates.openai,
            reason: 'AI-powered content generation and editing',
            relevanceScore: 0.90,
            category: RecommendationCategory.recommended,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.filesystem,
            reason: 'Manage content files and assets',
            relevanceScore: 0.85,
            category: RecommendationCategory.recommended,
          ),
        ]);
        break;
    }
    
    return recommendations;
  }

  List<MCPRecommendation> _getCapabilityBasedRecommendations(AgentContext context) {
    final recommendations = <MCPRecommendation>[];
    
    for (final capability in context.capabilities) {
      switch (capability.toLowerCase()) {
        case 'code generation':
        case 'programming':
          recommendations.add(MCPRecommendation(
            template: EnhancedMCPTemplates.github,
            reason: 'Code generation benefits from repository access',
            relevanceScore: 0.85,
            category: RecommendationCategory.recommended,
          ));
          break;

        case 'data analysis':
        case 'reporting':
          recommendations.add(MCPRecommendation(
            template: EnhancedMCPTemplates.postgresql,
            reason: 'Data analysis requires database connectivity',
            relevanceScore: 0.90,
            category: RecommendationCategory.recommended,
          ));
          break;

        case 'design review':
        case 'ui feedback':
          recommendations.add(MCPRecommendation(
            template: EnhancedMCPTemplates.figma,
            reason: 'Design capabilities require Figma integration',
            relevanceScore: 0.90,
            category: RecommendationCategory.recommended,
          ));
          break;

        case 'file management':
        case 'document processing':
          recommendations.add(MCPRecommendation(
            template: EnhancedMCPTemplates.filesystem,
            reason: 'File operations require filesystem access',
            relevanceScore: 0.95,
            category: RecommendationCategory.essential,
          ));
          break;
      }
    }
    
    return recommendations;
  }

  List<MCPRecommendation> _getIndustryBasedRecommendations(AgentContext context) {
    final recommendations = <MCPRecommendation>[];
    
    switch (context.industry?.toLowerCase()) {
      case 'technology':
      case 'software':
        recommendations.addAll([
          MCPRecommendation(
            template: EnhancedMCPTemplates.github,
            reason: 'Standard for tech industry collaboration',
            relevanceScore: 0.90,
            category: RecommendationCategory.recommended,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.git,
            reason: 'Version control is essential in tech',
            relevanceScore: 0.85,
            category: RecommendationCategory.recommended,
          ),
        ]);
        break;

      case 'finance':
      case 'banking':
        recommendations.addAll([
          MCPRecommendation(
            template: EnhancedMCPTemplates.postgresql,
            reason: 'Financial data requires robust database access',
            relevanceScore: 0.90,
            category: RecommendationCategory.recommended,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.microsoftGraph,
            reason: 'Enterprise collaboration in regulated industries',
            relevanceScore: 0.85,
            category: RecommendationCategory.recommended,
          ),
        ]);
        break;

      case 'healthcare':
      case 'medical':
        recommendations.addAll([
          MCPRecommendation(
            template: EnhancedMCPTemplates.filesystem,
            reason: 'Secure file access for medical documents',
            relevanceScore: 0.85,
            category: RecommendationCategory.recommended,
          ),
        ]);
        break;

      case 'education':
      case 'academic':
        recommendations.addAll([
          MCPRecommendation(
            template: EnhancedMCPTemplates.microsoftGraph,
            reason: 'Educational institutions often use Office 365',
            relevanceScore: 0.80,
            category: RecommendationCategory.recommended,
          ),
          MCPRecommendation(
            template: EnhancedMCPTemplates.filesystem,
            reason: 'Access course materials and student files',
            relevanceScore: 0.75,
            category: RecommendationCategory.useful,
          ),
        ]);
        break;
    }
    
    return recommendations;
  }

  List<MCPRecommendation> _getDescriptionBasedRecommendations(AgentContext context) {
    final recommendations = <MCPRecommendation>[];
    final description = context.description?.toLowerCase() ?? '';
    
    // Keyword-based analysis
    if (description.contains('database') || description.contains('sql') || description.contains('data')) {
      recommendations.add(MCPRecommendation(
        template: EnhancedMCPTemplates.postgresql,
        reason: 'Agent description mentions database operations',
        relevanceScore: 0.80,
        category: RecommendationCategory.recommended,
      ));
    }
    
    if (description.contains('github') || description.contains('repository') || description.contains('code')) {
      recommendations.add(MCPRecommendation(
        template: EnhancedMCPTemplates.github,
        reason: 'Agent description indicates code-related functionality',
        relevanceScore: 0.85,
        category: RecommendationCategory.recommended,
      ));
    }
    
    if (description.contains('design') || description.contains('figma') || description.contains('ui')) {
      recommendations.add(MCPRecommendation(
        template: EnhancedMCPTemplates.figma,
        reason: 'Agent description mentions design capabilities',
        relevanceScore: 0.85,
        category: RecommendationCategory.recommended,
      ));
    }
    
    if (description.contains('file') || description.contains('document') || description.contains('folder')) {
      recommendations.add(MCPRecommendation(
        template: EnhancedMCPTemplates.filesystem,
        reason: 'Agent description indicates file management needs',
        relevanceScore: 0.80,
        category: RecommendationCategory.recommended,
      ));
    }
    
    if (description.contains('microsoft') || description.contains('office') || description.contains('outlook') || description.contains('teams')) {
      recommendations.add(MCPRecommendation(
        template: EnhancedMCPTemplates.microsoftGraph,
        reason: 'Agent description mentions Microsoft services',
        relevanceScore: 0.85,
        category: RecommendationCategory.recommended,
      ));
    }
    
    if (description.contains('ai') || description.contains('openai') || description.contains('gpt')) {
      recommendations.add(MCPRecommendation(
        template: EnhancedMCPTemplates.openai,
        reason: 'Agent description indicates AI integration needs',
        relevanceScore: 0.75,
        category: RecommendationCategory.useful,
      ));
    }
    
    return recommendations;
  }

  List<MCPRecommendation> _deduplicateAndFilter(
    List<MCPRecommendation> recommendations, 
    AgentContext context,
  ) {
    final seen = <String>{};
    final filtered = <MCPRecommendation>[];
    
    for (final recommendation in recommendations) {
      final templateId = recommendation.template.id;
      
      // Skip if already exists or already recommended
      if (seen.contains(templateId) || 
          context.existingMCPServers.contains(templateId)) {
        continue;
      }
      
      seen.add(templateId);
      filtered.add(recommendation);
    }
    
    return filtered;
  }

  /// Get complementary recommendations based on selected servers
  List<MCPRecommendation> getComplementaryRecommendations(
    List<String> selectedServerIds,
    AgentContext context,
  ) {
    final recommendations = <MCPRecommendation>[];
    
    // If they selected GitHub, recommend Git for local operations
    if (selectedServerIds.contains('github') && !selectedServerIds.contains('git')) {
      recommendations.add(MCPRecommendation(
        template: EnhancedMCPTemplates.git,
        reason: 'Complements GitHub with local repository operations',
        relevanceScore: 0.80,
        category: RecommendationCategory.complementary,
      ));
    }
    
    // If they selected Figma, recommend Filesystem for assets
    if (selectedServerIds.contains('figma') && !selectedServerIds.contains('filesystem')) {
      recommendations.add(MCPRecommendation(
        template: EnhancedMCPTemplates.filesystem,
        reason: 'Access design assets and export files locally',
        relevanceScore: 0.75,
        category: RecommendationCategory.complementary,
      ));
    }
    
    // If they selected any database, recommend OpenAI for analysis
    if (selectedServerIds.any((id) => ['postgresql', 'sqlite'].contains(id)) && 
        !selectedServerIds.contains('openai')) {
      recommendations.add(MCPRecommendation(
        template: EnhancedMCPTemplates.openai,
        reason: 'AI-powered database analysis and query generation',
        relevanceScore: 0.70,
        category: RecommendationCategory.complementary,
      ));
    }
    
    return recommendations;
  }

  /// Generate explanation for why a recommendation was made
  String generateRecommendationExplanation(
    MCPRecommendation recommendation,
    AgentContext context,
  ) {
    final buffer = StringBuffer();
    buffer.write('Recommended because ');
    
    // Add context-specific explanation
    if (context.role != null) {
      buffer.write('${context.role}s typically benefit from ${recommendation.template.name.toLowerCase()} integration');
    } else {
      buffer.write('this integration enhances agent capabilities');
    }
    
    if (recommendation.reason.isNotEmpty) {
      buffer.write(': ${recommendation.reason}');
    }
    
    return buffer.toString();
  }
}

/// Agent context for generating recommendations
class AgentContext {
  final String? role;
  final String? description;
  final List<String> capabilities;
  final List<String> existingMCPServers;
  final String? industry;
  final String? useCase;

  const AgentContext({
    this.role,
    this.description,
    this.capabilities = const [],
    this.existingMCPServers = const [],
    this.industry,
    this.useCase,
  });
}

/// MCP recommendation with context and scoring
class MCPRecommendation {
  final EnhancedMCPTemplate template;
  final String reason;
  final double relevanceScore; // 0.0 to 1.0
  final RecommendationCategory category;
  final List<String> benefits;

  const MCPRecommendation({
    required this.template,
    required this.reason,
    required this.relevanceScore,
    required this.category,
    this.benefits = const [],
  });
}

enum RecommendationCategory {
  essential,     // Must-have for this role/use case
  recommended,   // Highly beneficial
  useful,        // Nice to have
  complementary, // Works well with other selections
}

extension RecommendationCategoryExtension on RecommendationCategory {
  String get displayName {
    switch (this) {
      case RecommendationCategory.essential:
        return 'Essential';
      case RecommendationCategory.recommended:
        return 'Recommended';
      case RecommendationCategory.useful:
        return 'Useful';
      case RecommendationCategory.complementary:
        return 'Complementary';
    }
  }

  Color get color {
    switch (this) {
      case RecommendationCategory.essential:
        return Color(0xFFE53E3E); // Red
      case RecommendationCategory.recommended:
        return Color(0xFF38A169); // Green
      case RecommendationCategory.useful:
        return Color(0xFF3182CE); // Blue
      case RecommendationCategory.complementary:
        return Color(0xFFD69E2E); // Orange
    }
  }
}