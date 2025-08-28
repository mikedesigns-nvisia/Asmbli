import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'integration_service.dart';
import 'integration_backup_service.dart';

/// Service for managing integration templates and sharing
class IntegrationTemplatesService {
  final IntegrationService _integrationService;
  final IntegrationBackupService _backupService;
  
  // Template storage and cache
  final Map<String, IntegrationTemplate> _templates = {};
  final Map<String, List<IntegrationTemplate>> _categoryTemplates = {};
  final List<CommunityTemplate> _communityTemplates = [];
  
  IntegrationTemplatesService(this._integrationService, this._backupService) {
    _initializeTemplates();
  }
  
  /// Initialize built-in and community templates
  void _initializeTemplates() {
    _initializeBuiltInTemplates();
    _initializeCommunityTemplates();
    _organizeCategorizedTemplates();
  }
  
  /// Get all available templates
  List<IntegrationTemplate> getAllTemplates() {
    return _templates.values.toList();
  }
  
  /// Get templates by category
  List<IntegrationTemplate> getTemplatesByCategory(String category) {
    return _categoryTemplates[category] ?? [];
  }
  
  /// Get featured templates
  List<IntegrationTemplate> getFeaturedTemplates() {
    return _templates.values
        .where((template) => template.isFeatured)
        .toList()
        ..sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
  }
  
  /// Get popular templates
  List<IntegrationTemplate> getPopularTemplates({int limit = 10}) {
    return _templates.values
        .toList()
        ..sort((a, b) => b.downloadCount.compareTo(a.downloadCount))
        ..take(limit);
  }
  
  /// Get templates by difficulty
  List<IntegrationTemplate> getTemplatesByDifficulty(String difficulty) {
    return _templates.values
        .where((template) => template.difficulty == difficulty)
        .toList();
  }
  
  /// Search templates
  List<IntegrationTemplate> searchTemplates(String query) {
    final queryLower = query.toLowerCase();
    
    return _templates.values.where((template) {
      return template.name.toLowerCase().contains(queryLower) ||
             template.description.toLowerCase().contains(queryLower) ||
             template.tags.any((tag) => tag.toLowerCase().contains(queryLower)) ||
             template.integrationIds.any((id) => 
               IntegrationRegistry.getById(id)?.name.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }
  
  /// Get template by ID
  IntegrationTemplate? getTemplate(String templateId) {
    return _templates[templateId];
  }
  
  /// Create template from current configuration
  Future<IntegrationTemplate> createTemplateFromConfiguration(
    List<String> integrationIds,
    TemplateMetadata metadata,
  ) async {
    final configurations = <IntegrationConfiguration>[];
    
    for (final integrationId in integrationIds) {
      final allStatuses = _integrationService.getAllIntegrationsWithStatus();
      final status = allStatuses.where((s) => s.definition.id == integrationId).firstOrNull;
      if (status?.isConfigured == true && status?.mcpConfig != null) {
        final integration = IntegrationRegistry.getById(integrationId);
        if (integration != null) {
          configurations.add(IntegrationConfiguration(
            integrationId: integrationId,
            name: integration.name,
            enabled: status!.isEnabled,
            settings: status.mcpConfig!.toJson(),
            capabilities: integration.capabilities,
            category: integration.category.name,
            version: '1.0.0',
            lastModified: DateTime.now(),
          ));
        }
      }
    }
    
    final template = IntegrationTemplate(
      id: _generateTemplateId(),
      name: metadata.name,
      description: metadata.description,
      author: metadata.author,
      version: '1.0.0',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      integrationIds: integrationIds,
      configurations: configurations,
      difficulty: metadata.difficulty,
      estimatedSetupTime: metadata.estimatedSetupTime,
      tags: metadata.tags,
      category: metadata.category,
      isOfficial: false,
      isFeatured: false,
      downloadCount: 0,
      rating: 0.0,
      reviewCount: 0,
      screenshots: metadata.screenshots ?? [],
      requirements: metadata.requirements ?? [],
      changelog: [],
      supportUrl: metadata.supportUrl,
      documentationUrl: metadata.documentationUrl,
    );
    
    _templates[template.id] = template;
    _updateCategorizedTemplates();
    
    return template;
  }
  
  /// Import template from JSON
  Future<IntegrationTemplate> importTemplate(String templateData) async {
    final templateJson = jsonDecode(templateData) as Map<String, dynamic>;
    final template = IntegrationTemplate.fromJson(templateJson);
    
    // Validate template
    final validation = await validateTemplate(template);
    if (!validation.isValid) {
      throw TemplateException('Template validation failed: ${validation.issues.join(', ')}');
    }
    
    // Generate new ID to avoid conflicts
    final importedTemplate = template.copyWith(
      id: _generateTemplateId(),
      isOfficial: false,
      downloadCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _templates[importedTemplate.id] = importedTemplate;
    _updateCategorizedTemplates();
    
    return importedTemplate;
  }
  
  /// Export template to JSON
  String exportTemplate(String templateId) {
    final template = _templates[templateId];
    if (template == null) {
      throw TemplateException('Template not found: $templateId');
    }
    
    return JsonEncoder.withIndent('  ').convert(template.toJson());
  }
  
  /// Apply template to configure integrations
  Future<TemplateApplicationResult> applyTemplate(
    String templateId,
    TemplateApplicationOptions options,
  ) async {
    final template = _templates[templateId];
    if (template == null) {
      throw TemplateException('Template not found: $templateId');
    }
    
    final result = TemplateApplicationResult(
      templateId: templateId,
      appliedAt: DateTime.now(),
      successfulApplications: [],
      failedApplications: [],
      skippedApplications: [],
      warnings: [],
    );
    
    for (final config in template.configurations) {
      try {
        final integration = IntegrationRegistry.getById(config.integrationId);
        if (integration == null) {
          result.failedApplications.add(TemplateApplicationItem(
            integrationId: config.integrationId,
            status: ApplicationStatus.failed,
            error: 'Integration not found in registry',
          ));
          continue;
        }
        
        if (!integration.isAvailable) {
          result.skippedApplications.add(TemplateApplicationItem(
            integrationId: config.integrationId,
            status: ApplicationStatus.skipped,
            reason: 'Integration not yet available',
          ));
          continue;
        }
        
        // Check if integration is already configured
        final allStatuses = _integrationService.getAllIntegrationsWithStatus();
        final existingStatus = allStatuses.where((s) => s.definition.id == config.integrationId).firstOrNull;
        if (existingStatus?.isConfigured == true) {
          switch (options.conflictResolution) {
            case ConflictResolution.skip:
              result.skippedApplications.add(TemplateApplicationItem(
                integrationId: config.integrationId,
                status: ApplicationStatus.skipped,
                reason: 'Integration already configured',
              ));
              continue;
              
            case ConflictResolution.replace:
              // Replace existing configuration
              break;
              
            case ConflictResolution.merge:
              result.warnings.add('Merge not yet implemented for ${config.integrationId}');
              break;
              
            case ConflictResolution.rename:
              result.warnings.add('Rename not applicable for integrations');
              break;
          }
        }
        
        // Apply configuration with customizations
        final customizedConfig = _applyCustomizations(config, options.customizations);
        await _applyIntegrationConfiguration(customizedConfig);
        
        result.successfulApplications.add(TemplateApplicationItem(
          integrationId: config.integrationId,
          status: ApplicationStatus.success,
          message: 'Successfully configured ${integration.name}',
        ));
        
      } catch (e) {
        result.failedApplications.add(TemplateApplicationItem(
          integrationId: config.integrationId,
          status: ApplicationStatus.failed,
          error: e.toString(),
        ));
      }
    }
    
    // Update download count
    if (result.successfulApplications.isNotEmpty) {
      _updateDownloadCount(templateId);
    }
    
    return result;
  }
  
  /// Validate template
  Future<TemplateValidation> validateTemplate(IntegrationTemplate template) async {
    final issues = <String>[];
    final compatibleIntegrations = <String>[];
    final incompatibleIntegrations = <String>[];
    
    // Validate integrations exist and are available
    for (final integrationId in template.integrationIds) {
      final integration = IntegrationRegistry.getById(integrationId);
      if (integration == null) {
        incompatibleIntegrations.add(integrationId);
        issues.add('Integration not found: $integrationId');
      } else if (!integration.isAvailable) {
        incompatibleIntegrations.add(integrationId);
        issues.add('Integration not available: $integrationId');
      } else {
        compatibleIntegrations.add(integrationId);
      }
    }
    
    // Validate configurations
    for (final config in template.configurations) {
      if (config.settings.isEmpty) {
        issues.add('Empty configuration for ${config.integrationId}');
      }
    }
    
    // Validate metadata
    if (template.name.isEmpty) {
      issues.add('Template name is required');
    }
    
    if (template.description.isEmpty) {
      issues.add('Template description is required');
    }
    
    return TemplateValidation(
      isValid: issues.isEmpty,
      issues: issues,
      compatibleIntegrations: compatibleIntegrations,
      incompatibleIntegrations: incompatibleIntegrations,
      hasRequiredFields: template.name.isNotEmpty && template.description.isNotEmpty,
    );
  }
  
  /// Get template preview
  TemplatePreview getTemplatePreview(String templateId) {
    final template = _templates[templateId];
    if (template == null) {
      throw TemplateException('Template not found: $templateId');
    }
    
    final integrationPreviews = <IntegrationPreview>[];
    
    for (final config in template.configurations) {
      final integration = IntegrationRegistry.getById(config.integrationId);
      if (integration != null) {
        integrationPreviews.add(IntegrationPreview(
          integrationId: config.integrationId,
          name: integration.name,
          description: integration.description,
          category: integration.category.displayName,
          isAvailable: integration.isAvailable,
          difficulty: integration.difficulty,
          estimatedSetupTime: Duration(minutes: 5), // Default estimate
          configurationPreview: _generateConfigPreview(config),
        ));
      }
    }
    
    return TemplatePreview(
      templateId: templateId,
      name: template.name,
      description: template.description,
      author: template.author,
      totalIntegrations: template.integrationIds.length,
      availableIntegrations: integrationPreviews.where((p) => p.isAvailable).length,
      estimatedSetupTime: template.estimatedSetupTime,
      difficulty: template.difficulty,
      integrations: integrationPreviews,
      tags: template.tags,
      requirements: template.requirements,
      screenshots: template.screenshots,
    );
  }
  
  /// Get community templates
  List<CommunityTemplate> getCommunityTemplates({
    String? category,
    String? difficulty,
    int limit = 20,
  }) {
    var templates = _communityTemplates.where((template) {
      if (category != null && template.category != category) return false;
      if (difficulty != null && template.difficulty != difficulty) return false;
      return true;
    }).toList();
    
    // Sort by popularity and rating
    templates.sort((a, b) {
      final aScore = (a.downloadCount * 0.3) + (a.rating * 0.7);
      final bScore = (b.downloadCount * 0.3) + (b.rating * 0.7);
      return bScore.compareTo(aScore);
    });
    
    return templates.take(limit).toList();
  }
  
  /// Submit template to community
  Future<TemplateSubmission> submitToCommunity(
    String templateId,
    SubmissionMetadata metadata,
  ) async {
    final template = _templates[templateId];
    if (template == null) {
      throw TemplateException('Template not found: $templateId');
    }
    
    // Validate template before submission
    final validation = await validateTemplate(template);
    if (!validation.isValid) {
      throw TemplateException('Template validation failed: ${validation.issues.join(', ')}');
    }
    
    final submission = TemplateSubmission(
      submissionId: _generateSubmissionId(),
      templateId: templateId,
      submittedAt: DateTime.now(),
      submittedBy: metadata.submitterName,
      submitterEmail: metadata.submitterEmail,
      status: SubmissionStatus.pending,
      moderationNotes: '',
      reviewComments: [],
    );
    
    // In a real implementation, this would submit to a backend service
    // For now, we'll simulate the submission process
    await Future.delayed(Duration(seconds: 2));
    
    return submission;
  }
  
  /// Get template statistics
  TemplateStatistics getTemplateStatistics() {
    final totalTemplates = _templates.length;
    final officialTemplates = _templates.values.where((t) => t.isOfficial).length;
    final communityTemplates = totalTemplates - officialTemplates;
    final totalDownloads = _templates.values.fold(0, (sum, t) => sum + t.downloadCount);
    
    final categoryStats = <String, int>{};
    for (final template in _templates.values) {
      categoryStats[template.category] = (categoryStats[template.category] ?? 0) + 1;
    }
    
    final difficultyStats = <String, int>{};
    for (final template in _templates.values) {
      difficultyStats[template.difficulty] = (difficultyStats[template.difficulty] ?? 0) + 1;
    }
    
    return TemplateStatistics(
      totalTemplates: totalTemplates,
      officialTemplates: officialTemplates,
      communityTemplates: communityTemplates,
      totalDownloads: totalDownloads,
      averageRating: _templates.values.fold(0.0, (sum, t) => sum + t.rating) / totalTemplates,
      categoryBreakdown: categoryStats,
      difficultyBreakdown: difficultyStats,
      mostPopularTemplate: _templates.values
          .reduce((a, b) => a.downloadCount > b.downloadCount ? a : b),
      newestTemplate: _templates.values
          .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b),
    );
  }
  
  // Private helper methods
  void _initializeBuiltInTemplates() {
    // Development Workflow Template
    _templates['dev-workflow'] = IntegrationTemplate(
      id: 'dev-workflow',
      name: 'Complete Development Workflow',
      description: 'A comprehensive setup for software development with Git, GitHub, filesystem access, and terminal capabilities.',
      author: 'AgentEngine Team',
      version: '1.2.0',
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now().subtract(Duration(days: 5)),
      integrationIds: ['git', 'github', 'filesystem', 'terminal'],
      configurations: [],
      difficulty: 'Medium',
      estimatedSetupTime: Duration(minutes: 20),
      tags: ['development', 'git', 'github', 'workflow'],
      category: 'Development',
      isOfficial: true,
      isFeatured: true,
      downloadCount: 1250,
      rating: 4.8,
      reviewCount: 89,
      screenshots: ['dev-workflow-1.png', 'dev-workflow-2.png'],
      requirements: ['Git installed', 'GitHub account', 'File system permissions'],
      changelog: [
        ChangelogEntry(
          version: '1.2.0',
          date: DateTime.now().subtract(Duration(days: 5)),
          changes: ['Added terminal integration', 'Improved GitHub configuration'],
        ),
        ChangelogEntry(
          version: '1.1.0',
          date: DateTime.now().subtract(Duration(days: 15)),
          changes: ['Enhanced filesystem access', 'Bug fixes'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/dev-workflow',
      documentationUrl: 'https://docs.agentengine.com/templates/dev-workflow/guide',
    );
    
    // Data Analysis Template
    _templates['data-analysis'] = IntegrationTemplate(
      id: 'data-analysis',
      name: 'Data Analysis Suite',
      description: 'Perfect setup for data analysis with database connections, memory management, and web search capabilities.',
      author: 'AgentEngine Team',
      version: '1.0.0',
      createdAt: DateTime.now().subtract(Duration(days: 20)),
      updatedAt: DateTime.now().subtract(Duration(days: 10)),
      integrationIds: ['postgresql', 'memory', 'web-search', 'filesystem'],
      configurations: [],
      difficulty: 'Hard',
      estimatedSetupTime: Duration(minutes: 35),
      tags: ['data', 'analysis', 'database', 'research'],
      category: 'Data & Analytics',
      isOfficial: true,
      isFeatured: true,
      downloadCount: 890,
      rating: 4.6,
      reviewCount: 67,
      screenshots: ['data-analysis-1.png'],
      requirements: ['PostgreSQL server', 'Database credentials'],
      changelog: [
        ChangelogEntry(
          version: '1.0.0',
          date: DateTime.now().subtract(Duration(days: 20)),
          changes: ['Initial release'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/data-analysis',
      documentationUrl: 'https://docs.agentengine.com/templates/data-analysis/guide',
    );
    
    // Content Creation Template
    _templates['content-creation'] = IntegrationTemplate(
      id: 'content-creation',
      name: 'Content Creator\'s Toolkit',
      description: 'All-in-one setup for content creators with Notion, Slack, web search, and file management.',
      author: 'AgentEngine Team',
      version: '1.1.0',
      createdAt: DateTime.now().subtract(Duration(days: 25)),
      updatedAt: DateTime.now().subtract(Duration(days: 8)),
      integrationIds: ['notion', 'slack', 'web-search', 'filesystem'],
      configurations: [],
      difficulty: 'Easy',
      estimatedSetupTime: Duration(minutes: 15),
      tags: ['content', 'creation', 'notion', 'slack', 'productivity'],
      category: 'Productivity',
      isOfficial: true,
      isFeatured: false,
      downloadCount: 645,
      rating: 4.4,
      reviewCount: 42,
      screenshots: ['content-creation-1.png', 'content-creation-2.png'],
      requirements: ['Notion workspace', 'Slack workspace'],
      changelog: [
        ChangelogEntry(
          version: '1.1.0',
          date: DateTime.now().subtract(Duration(days: 8)),
          changes: ['Added Slack integration', 'Improved Notion setup'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/content-creation',
    );
    
    // AI Research Template
    _templates['ai-research'] = IntegrationTemplate(
      id: 'ai-research',
      name: 'AI Research Assistant',
      description: 'Advanced template for AI research with memory management, sequential thinking, and web search.',
      author: 'AgentEngine Team',
      version: '2.0.0',
      createdAt: DateTime.now().subtract(Duration(days: 35)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
      integrationIds: ['memory', 'sequential-thinking', 'web-search', 'filesystem'],
      configurations: [],
      difficulty: 'Hard',
      estimatedSetupTime: Duration(minutes: 25),
      tags: ['ai', 'research', 'memory', 'thinking', 'advanced'],
      category: 'AI & Research',
      isOfficial: true,
      isFeatured: true,
      downloadCount: 1180,
      rating: 4.9,
      reviewCount: 156,
      screenshots: ['ai-research-1.png', 'ai-research-2.png', 'ai-research-3.png'],
      requirements: ['Advanced AI model', 'Sufficient memory allocation'],
      changelog: [
        ChangelogEntry(
          version: '2.0.0',
          date: DateTime.now().subtract(Duration(days: 2)),
          changes: ['Major update with sequential thinking', 'Enhanced memory management'],
        ),
        ChangelogEntry(
          version: '1.5.0',
          date: DateTime.now().subtract(Duration(days: 12)),
          changes: ['Improved research capabilities', 'Better web search integration'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/ai-research',
      documentationUrl: 'https://docs.agentengine.com/templates/ai-research/advanced-guide',
    );
    
    // Quick Start Template
    _templates['quick-start'] = IntegrationTemplate(
      id: 'quick-start',
      name: 'Quick Start Essentials',
      description: 'Basic template to get started quickly with essential integrations.',
      author: 'AgentEngine Team',
      version: '1.0.0',
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      updatedAt: DateTime.now().subtract(Duration(days: 10)),
      integrationIds: ['filesystem', 'web-search', 'time'],
      configurations: [],
      difficulty: 'Easy',
      estimatedSetupTime: Duration(minutes: 10),
      tags: ['beginner', 'essential', 'quick-start', 'basic'],
      category: 'Getting Started',
      isOfficial: true,
      isFeatured: false,
      downloadCount: 2340,
      rating: 4.2,
      reviewCount: 198,
      screenshots: ['quick-start-1.png'],
      requirements: ['Basic system permissions'],
      changelog: [
        ChangelogEntry(
          version: '1.0.0',
          date: DateTime.now().subtract(Duration(days: 10)),
          changes: ['Initial release with essential integrations'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/quick-start',
    );

    // NEW ENTERPRISE TEMPLATES LEVERAGING 51 MCP SERVERS

    // Cloud Infrastructure Engineer Pro
    _templates['cloud-infrastructure-pro'] = IntegrationTemplate(
      id: 'cloud-infrastructure-pro',
      name: 'Cloud Infrastructure Engineer Pro',
      description: 'Enterprise-grade cloud architect with multi-provider support, cost optimization, and infrastructure automation.',
      author: 'AgentEngine Team',
      version: '1.0.0',
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
      integrationIds: ['aws-bedrock', 'aws-cdk', 'aws-cost-analysis', 'cloudflare', 'vercel', 'netlify', 'azure', 'docker'],
      configurations: [],
      difficulty: 'Hard',
      estimatedSetupTime: Duration(minutes: 45),
      tags: ['cloud', 'infrastructure', 'aws', 'azure', 'devops', 'enterprise'],
      category: 'Cloud & Infrastructure',
      isOfficial: true,
      isFeatured: true,
      downloadCount: 320,
      rating: 4.9,
      reviewCount: 28,
      screenshots: ['cloud-infra-1.png', 'cloud-infra-2.png'],
      requirements: ['AWS Account', 'Azure Subscription', 'Cloudflare Account'],
      changelog: [
        ChangelogEntry(
          version: '1.0.0',
          date: DateTime.now().subtract(Duration(days: 3)),
          changes: ['Initial release with multi-cloud support', 'Cost optimization features', 'Infrastructure automation'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/cloud-infrastructure-pro',
      documentationUrl: 'https://docs.agentengine.com/templates/cloud-infrastructure-pro/guide',
    );

    // E-commerce Business Intelligence Agent
    _templates['ecommerce-bi-specialist'] = IntegrationTemplate(
      id: 'ecommerce-bi-specialist',
      name: 'E-commerce BI Specialist',
      description: 'Complete business intelligence for e-commerce with payments, analytics, and customer communications.',
      author: 'AgentEngine Team',
      version: '1.0.0',
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
      integrationIds: ['stripe', 'supabase', 'bigquery', 'tako', 'twilio', 'zapier', 'supadata', 'box'],
      configurations: [],
      difficulty: 'Medium',
      estimatedSetupTime: Duration(minutes: 35),
      tags: ['ecommerce', 'business intelligence', 'analytics', 'payments', 'crm'],
      category: 'Business & Analytics',
      isOfficial: true,
      isFeatured: true,
      downloadCount: 480,
      rating: 4.7,
      reviewCount: 45,
      screenshots: ['ecommerce-bi-1.png', 'ecommerce-bi-2.png', 'ecommerce-bi-3.png'],
      requirements: ['Stripe Account', 'Supabase Project', 'BigQuery Access', 'Tako API Key'],
      changelog: [
        ChangelogEntry(
          version: '1.0.0',
          date: DateTime.now().subtract(Duration(days: 5)),
          changes: ['Revenue analytics dashboard', 'Customer journey tracking', 'Automated reporting'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/ecommerce-bi',
      documentationUrl: 'https://docs.agentengine.com/templates/ecommerce-bi/setup',
    );

    // DevSecOps Automation Hub
    _templates['devsecops-automation'] = IntegrationTemplate(
      id: 'devsecops-automation',
      name: 'DevSecOps Automation Hub',
      description: 'Security-first CI/CD with automated scanning, monitoring, and chaos engineering.',
      author: 'AgentEngine Team',
      version: '1.1.0',
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      updatedAt: DateTime.now().subtract(Duration(hours: 6)),
      integrationIds: ['gitguardian', 'sentry', 'circleci', 'buildkite', 'gremlin', 'git', 'github'],
      configurations: [],
      difficulty: 'Hard',
      estimatedSetupTime: Duration(minutes: 50),
      tags: ['devsecops', 'security', 'ci-cd', 'automation', 'monitoring', 'chaos-engineering'],
      category: 'Security & DevOps',
      isOfficial: true,
      isFeatured: true,
      downloadCount: 560,
      rating: 4.8,
      reviewCount: 38,
      screenshots: ['devsecops-1.png', 'devsecops-2.png'],
      requirements: ['GitGuardian API Key', 'Sentry Account', 'CircleCI Token', 'GitHub Access'],
      changelog: [
        ChangelogEntry(
          version: '1.1.0',
          date: DateTime.now().subtract(Duration(hours: 6)),
          changes: ['Added chaos engineering with Gremlin', 'Enhanced security scanning'],
        ),
        ChangelogEntry(
          version: '1.0.0',
          date: DateTime.now().subtract(Duration(days: 7)),
          changes: ['Initial release with security automation', 'CI/CD pipeline integration'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/devsecops-automation',
    );

    // Multi-Database Analytics Powerhouse
    _templates['multi-database-analytics'] = IntegrationTemplate(
      id: 'multi-database-analytics',
      name: 'Multi-Database Analytics Powerhouse',
      description: 'Advanced analytics across multiple database systems with AI-powered insights.',
      author: 'AgentEngine Team',
      version: '1.0.0',
      createdAt: DateTime.now().subtract(Duration(days: 4)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
      integrationIds: ['postgresql', 'bigquery', 'clickhouse', 'redis', 'supabase', 'memory', 'sequential-thinking'],
      configurations: [],
      difficulty: 'Hard',
      estimatedSetupTime: Duration(minutes: 40),
      tags: ['database', 'analytics', 'big-data', 'ai', 'multi-source'],
      category: 'Data & Analytics',
      isOfficial: true,
      isFeatured: true,
      downloadCount: 290,
      rating: 4.6,
      reviewCount: 22,
      screenshots: ['multi-db-1.png', 'multi-db-2.png'],
      requirements: ['Database Credentials', 'BigQuery Access', 'ClickHouse Server'],
      changelog: [
        ChangelogEntry(
          version: '1.0.0',
          date: DateTime.now().subtract(Duration(days: 4)),
          changes: ['Cross-database query engine', 'AI-powered insights', 'Real-time analytics'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/multi-database-analytics',
    );

    // Social Media Marketing Command Center
    _templates['social-media-command-center'] = IntegrationTemplate(
      id: 'social-media-command-center',
      name: 'Social Media Marketing Command Center',
      description: 'Complete social media management with analytics, scheduling, and multi-channel communication.',
      author: 'AgentEngine Team',
      version: '1.0.0',
      createdAt: DateTime.now().subtract(Duration(days: 6)),
      updatedAt: DateTime.now().subtract(Duration(days: 3)),
      integrationIds: ['supadata', 'discord', 'slack', 'twilio', 'zapier', 'boost-space', 'caldav'],
      configurations: [],
      difficulty: 'Medium',
      estimatedSetupTime: Duration(minutes: 30),
      tags: ['social-media', 'marketing', 'analytics', 'automation', 'scheduling'],
      category: 'Marketing & Communication',
      isOfficial: true,
      isFeatured: true,
      downloadCount: 720,
      rating: 4.5,
      reviewCount: 67,
      screenshots: ['social-media-1.png', 'social-media-2.png', 'social-media-3.png'],
      requirements: ['Social Media Accounts', 'Supadata API', 'Discord/Slack Tokens'],
      changelog: [
        ChangelogEntry(
          version: '1.0.0',
          date: DateTime.now().subtract(Duration(days: 6)),
          changes: ['Multi-platform scheduling', 'Engagement analytics', 'Automated responses'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/social-media-command-center',
    );

    // Enterprise Security Operations Center
    _templates['enterprise-security-ops'] = IntegrationTemplate(
      id: 'enterprise-security-ops',
      name: 'Enterprise Security Operations Center',
      description: 'Comprehensive security monitoring, threat detection, and incident response.',
      author: 'AgentEngine Team',
      version: '1.0.0',
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      updatedAt: DateTime.now().subtract(Duration(days: 4)),
      integrationIds: ['gitguardian', 'sentry', 'gremlin', 'atlassian-remote', 'glean', 'sequential-thinking'],
      configurations: [],
      difficulty: 'Hard',
      estimatedSetupTime: Duration(minutes: 55),
      tags: ['security', 'operations', 'enterprise', 'monitoring', 'incident-response'],
      category: 'Enterprise Security',
      isOfficial: true,
      isFeatured: true,
      downloadCount: 180,
      rating: 4.9,
      reviewCount: 15,
      screenshots: ['security-ops-1.png', 'security-ops-2.png'],
      requirements: ['Enterprise Security Tools', 'Atlassian Access', 'Advanced Permissions'],
      changelog: [
        ChangelogEntry(
          version: '1.0.0',
          date: DateTime.now().subtract(Duration(days: 8)),
          changes: ['Real-time threat monitoring', 'Automated incident response', 'Compliance reporting'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/enterprise-security-ops',
    );

    // Customer Success Automation Agent
    _templates['customer-success-automation'] = IntegrationTemplate(
      id: 'customer-success-automation',
      name: 'Customer Success Automation Agent',
      description: 'Complete customer success platform with knowledge management and multi-channel support.',
      author: 'AgentEngine Team',
      version: '1.0.0',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      updatedAt: DateTime.now().subtract(Duration(hours: 12)),
      integrationIds: ['buildable', 'box', 'glean', 'twilio', 'discord', 'slack', 'caldav', 'zapier'],
      configurations: [],
      difficulty: 'Medium',
      estimatedSetupTime: Duration(minutes: 25),
      tags: ['customer-success', 'automation', 'support', 'knowledge-management'],
      category: 'Customer Success',
      isOfficial: true,
      isFeatured: true,
      downloadCount: 410,
      rating: 4.6,
      reviewCount: 31,
      screenshots: ['customer-success-1.png', 'customer-success-2.png'],
      requirements: ['Customer Support Platform', 'Knowledge Base', 'Communication Channels'],
      changelog: [
        ChangelogEntry(
          version: '1.0.0',
          date: DateTime.now().subtract(Duration(days: 2)),
          changes: ['Automated customer onboarding', 'Health score tracking', 'Multi-channel support'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/customer-success-automation',
    );

    // FinTech Data Pipeline Manager
    _templates['fintech-data-pipeline'] = IntegrationTemplate(
      id: 'fintech-data-pipeline',
      name: 'FinTech Data Pipeline Manager',
      description: 'Real-time financial data processing with compliance and risk analysis.',
      author: 'AgentEngine Team',
      version: '1.0.0',
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      updatedAt: DateTime.now().subtract(Duration(hours: 8)),
      integrationIds: ['stripe', 'tako', 'bigquery', 'clickhouse', 'redis', 'aws-cost-analysis', 'sequential-thinking'],
      configurations: [],
      difficulty: 'Hard',
      estimatedSetupTime: Duration(minutes: 45),
      tags: ['fintech', 'finance', 'data-pipeline', 'compliance', 'risk-analysis'],
      category: 'Financial Technology',
      isOfficial: true,
      isFeatured: true,
      downloadCount: 95,
      rating: 5.0,
      reviewCount: 8,
      screenshots: ['fintech-1.png', 'fintech-2.png', 'fintech-3.png'],
      requirements: ['Financial Data Access', 'Compliance Framework', 'High-Performance Computing'],
      changelog: [
        ChangelogEntry(
          version: '1.0.0',
          date: DateTime.now().subtract(Duration(days: 1)),
          changes: ['Real-time payment processing', 'Advanced risk modeling', 'Regulatory reporting'],
        ),
      ],
      supportUrl: 'https://docs.agentengine.com/templates/fintech-data-pipeline',
    );
  }
  
  void _initializeCommunityTemplates() {
    // Add mock community templates
    _communityTemplates.addAll([
      CommunityTemplate(
        id: 'community-devops',
        name: 'DevOps Automation',
        description: 'Complete DevOps workflow with CI/CD integrations',
        author: 'DevOps Pro',
        authorAvatar: 'https://example.com/avatar1.png',
        downloadCount: 456,
        rating: 4.3,
        reviewCount: 23,
        category: 'DevOps',
        difficulty: 'Hard',
        tags: ['devops', 'ci-cd', 'automation'],
        isVerified: true,
        createdAt: DateTime.now().subtract(Duration(days: 15)),
      ),
      CommunityTemplate(
        id: 'community-ecommerce',
        name: 'E-commerce Analytics',
        description: 'Track and analyze e-commerce metrics',
        author: 'Analytics Expert',
        authorAvatar: 'https://example.com/avatar2.png',
        downloadCount: 234,
        rating: 4.1,
        reviewCount: 15,
        category: 'E-commerce',
        difficulty: 'Medium',
        tags: ['ecommerce', 'analytics', 'metrics'],
        isVerified: false,
        createdAt: DateTime.now().subtract(Duration(days: 8)),
      ),
      CommunityTemplate(
        id: 'community-social-media',
        name: 'Social Media Manager',
        description: 'Manage multiple social media platforms',
        author: 'Social Guru',
        authorAvatar: 'https://example.com/avatar3.png',
        downloadCount: 567,
        rating: 4.5,
        reviewCount: 34,
        category: 'Social Media',
        difficulty: 'Medium',
        tags: ['social', 'media', 'management'],
        isVerified: true,
        createdAt: DateTime.now().subtract(Duration(days: 22)),
      ),
    ]);
  }
  
  void _organizeCategorizedTemplates() {
    _categoryTemplates.clear();
    
    for (final template in _templates.values) {
      if (!_categoryTemplates.containsKey(template.category)) {
        _categoryTemplates[template.category] = [];
      }
      _categoryTemplates[template.category]!.add(template);
    }
  }
  
  void _updateCategorizedTemplates() {
    _organizeCategorizedTemplates();
  }
  
  IntegrationConfiguration _applyCustomizations(
    IntegrationConfiguration config,
    Map<String, dynamic> customizations,
  ) {
    if (customizations.isEmpty) return config;
    
    final customizedSettings = Map<String, dynamic>.from(config.settings);
    
    // Apply customizations to settings
    for (final entry in customizations.entries) {
      customizedSettings[entry.key] = entry.value;
    }
    
    return IntegrationConfiguration(
      integrationId: config.integrationId,
      name: config.name,
      enabled: config.enabled,
      settings: customizedSettings,
      capabilities: config.capabilities,
      category: config.category,
      version: config.version,
      lastModified: DateTime.now(),
    );
  }
  
  Future<void> _applyIntegrationConfiguration(IntegrationConfiguration config) async {
    // In a real implementation, this would apply the configuration to the integration service
    // For now, we'll simulate the process
    await Future.delayed(Duration(milliseconds: 500));
    
    // This would typically involve:
    // 1. Converting IntegrationConfiguration back to MCPServerConfig
    // 2. Calling the MCP service to add/update the configuration
    // 3. Enabling the integration if specified
  }
  
  void _updateDownloadCount(String templateId) {
    final template = _templates[templateId];
    if (template != null) {
      _templates[templateId] = template.copyWith(
        downloadCount: template.downloadCount + 1,
      );
    }
  }
  
  String _generateConfigPreview(IntegrationConfiguration config) {
    final preview = <String, dynamic>{};
    
    // Create a sanitized preview of the configuration
    for (final entry in config.settings.entries) {
      if (entry.key.toLowerCase().contains('key') || 
          entry.key.toLowerCase().contains('token') ||
          entry.key.toLowerCase().contains('password')) {
        preview[entry.key] = '***hidden***';
      } else {
        preview[entry.key] = entry.value;
      }
    }
    
    return JsonEncoder.withIndent('  ').convert(preview);
  }
  
  String _generateTemplateId() {
    return 'template_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
  
  String _generateSubmissionId() {
    return 'submission_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}

// Data models
class IntegrationTemplate {
  final String id;
  final String name;
  final String description;
  final String author;
  final String version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> integrationIds;
  final List<IntegrationConfiguration> configurations;
  final String difficulty;
  final Duration estimatedSetupTime;
  final List<String> tags;
  final String category;
  final bool isOfficial;
  final bool isFeatured;
  final int downloadCount;
  final double rating;
  final int reviewCount;
  final List<String> screenshots;
  final List<String> requirements;
  final List<ChangelogEntry> changelog;
  final String? supportUrl;
  final String? documentationUrl;
  
  const IntegrationTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.integrationIds,
    required this.configurations,
    required this.difficulty,
    required this.estimatedSetupTime,
    required this.tags,
    required this.category,
    required this.isOfficial,
    required this.isFeatured,
    required this.downloadCount,
    required this.rating,
    required this.reviewCount,
    required this.screenshots,
    required this.requirements,
    required this.changelog,
    this.supportUrl,
    this.documentationUrl,
  });
  
  IntegrationTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? author,
    String? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? integrationIds,
    List<IntegrationConfiguration>? configurations,
    String? difficulty,
    Duration? estimatedSetupTime,
    List<String>? tags,
    String? category,
    bool? isOfficial,
    bool? isFeatured,
    int? downloadCount,
    double? rating,
    int? reviewCount,
    List<String>? screenshots,
    List<String>? requirements,
    List<ChangelogEntry>? changelog,
    String? supportUrl,
    String? documentationUrl,
  }) {
    return IntegrationTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      integrationIds: integrationIds ?? this.integrationIds,
      configurations: configurations ?? this.configurations,
      difficulty: difficulty ?? this.difficulty,
      estimatedSetupTime: estimatedSetupTime ?? this.estimatedSetupTime,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      isOfficial: isOfficial ?? this.isOfficial,
      isFeatured: isFeatured ?? this.isFeatured,
      downloadCount: downloadCount ?? this.downloadCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      screenshots: screenshots ?? this.screenshots,
      requirements: requirements ?? this.requirements,
      changelog: changelog ?? this.changelog,
      supportUrl: supportUrl ?? this.supportUrl,
      documentationUrl: documentationUrl ?? this.documentationUrl,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'integrationIds': integrationIds,
      'configurations': configurations.map((c) => c.toJson()).toList(),
      'difficulty': difficulty,
      'estimatedSetupTime': estimatedSetupTime.inMinutes,
      'tags': tags,
      'category': category,
      'isOfficial': isOfficial,
      'isFeatured': isFeatured,
      'downloadCount': downloadCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'screenshots': screenshots,
      'requirements': requirements,
      'changelog': changelog.map((e) => e.toJson()).toList(),
      if (supportUrl != null) 'supportUrl': supportUrl,
      if (documentationUrl != null) 'documentationUrl': documentationUrl,
    };
  }
  
  factory IntegrationTemplate.fromJson(Map<String, dynamic> json) {
    return IntegrationTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      author: json['author'],
      version: json['version'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      integrationIds: List<String>.from(json['integrationIds']),
      configurations: (json['configurations'] as List)
          .map((c) => IntegrationConfiguration.fromJson(c))
          .toList(),
      difficulty: json['difficulty'],
      estimatedSetupTime: Duration(minutes: json['estimatedSetupTime']),
      tags: List<String>.from(json['tags']),
      category: json['category'],
      isOfficial: json['isOfficial'],
      isFeatured: json['isFeatured'],
      downloadCount: json['downloadCount'],
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      screenshots: List<String>.from(json['screenshots']),
      requirements: List<String>.from(json['requirements']),
      changelog: (json['changelog'] as List)
          .map((e) => ChangelogEntry.fromJson(e))
          .toList(),
      supportUrl: json['supportUrl'],
      documentationUrl: json['documentationUrl'],
    );
  }
}

class CommunityTemplate {
  final String id;
  final String name;
  final String description;
  final String author;
  final String? authorAvatar;
  final int downloadCount;
  final double rating;
  final int reviewCount;
  final String category;
  final String difficulty;
  final List<String> tags;
  final bool isVerified;
  final DateTime createdAt;
  
  const CommunityTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    this.authorAvatar,
    required this.downloadCount,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.difficulty,
    required this.tags,
    required this.isVerified,
    required this.createdAt,
  });
}

class ChangelogEntry {
  final String version;
  final DateTime date;
  final List<String> changes;
  
  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.changes,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'date': date.toIso8601String(),
      'changes': changes,
    };
  }
  
  factory ChangelogEntry.fromJson(Map<String, dynamic> json) {
    return ChangelogEntry(
      version: json['version'],
      date: DateTime.parse(json['date']),
      changes: List<String>.from(json['changes']),
    );
  }
}

class TemplateMetadata {
  final String name;
  final String description;
  final String author;
  final String difficulty;
  final Duration estimatedSetupTime;
  final List<String> tags;
  final String category;
  final List<String>? screenshots;
  final List<String>? requirements;
  final String? supportUrl;
  final String? documentationUrl;
  
  const TemplateMetadata({
    required this.name,
    required this.description,
    required this.author,
    required this.difficulty,
    required this.estimatedSetupTime,
    required this.tags,
    required this.category,
    this.screenshots,
    this.requirements,
    this.supportUrl,
    this.documentationUrl,
  });
}

class TemplateApplicationOptions {
  final ConflictResolution conflictResolution;
  final Map<String, dynamic> customizations;
  final bool enableAfterApplication;
  final bool runTests;
  
  const TemplateApplicationOptions({
    this.conflictResolution = ConflictResolution.skip,
    this.customizations = const {},
    this.enableAfterApplication = true,
    this.runTests = false,
  });
}

class TemplateApplicationResult {
  final String templateId;
  final DateTime appliedAt;
  final List<TemplateApplicationItem> successfulApplications;
  final List<TemplateApplicationItem> failedApplications;
  final List<TemplateApplicationItem> skippedApplications;
  final List<String> warnings;
  
  TemplateApplicationResult({
    required this.templateId,
    required this.appliedAt,
    required this.successfulApplications,
    required this.failedApplications,
    required this.skippedApplications,
    required this.warnings,
  });
  
  bool get isSuccess => failedApplications.isEmpty;
  int get totalApplications => successfulApplications.length + failedApplications.length + skippedApplications.length;
}

class TemplateApplicationItem {
  final String integrationId;
  final ApplicationStatus status;
  final String? message;
  final String? error;
  final String? reason;
  
  const TemplateApplicationItem({
    required this.integrationId,
    required this.status,
    this.message,
    this.error,
    this.reason,
  });
}

class TemplateValidation {
  final bool isValid;
  final List<String> issues;
  final List<String> compatibleIntegrations;
  final List<String> incompatibleIntegrations;
  final bool hasRequiredFields;
  
  const TemplateValidation({
    required this.isValid,
    required this.issues,
    required this.compatibleIntegrations,
    required this.incompatibleIntegrations,
    required this.hasRequiredFields,
  });
}

class TemplatePreview {
  final String templateId;
  final String name;
  final String description;
  final String author;
  final int totalIntegrations;
  final int availableIntegrations;
  final Duration estimatedSetupTime;
  final String difficulty;
  final List<IntegrationPreview> integrations;
  final List<String> tags;
  final List<String> requirements;
  final List<String> screenshots;
  
  const TemplatePreview({
    required this.templateId,
    required this.name,
    required this.description,
    required this.author,
    required this.totalIntegrations,
    required this.availableIntegrations,
    required this.estimatedSetupTime,
    required this.difficulty,
    required this.integrations,
    required this.tags,
    required this.requirements,
    required this.screenshots,
  });
}

class IntegrationPreview {
  final String integrationId;
  final String name;
  final String description;
  final String category;
  final bool isAvailable;
  final String difficulty;
  final Duration estimatedSetupTime;
  final String configurationPreview;
  
  const IntegrationPreview({
    required this.integrationId,
    required this.name,
    required this.description,
    required this.category,
    required this.isAvailable,
    required this.difficulty,
    required this.estimatedSetupTime,
    required this.configurationPreview,
  });
}

class TemplateSubmission {
  final String submissionId;
  final String templateId;
  final DateTime submittedAt;
  final String submittedBy;
  final String submitterEmail;
  final SubmissionStatus status;
  final String moderationNotes;
  final List<String> reviewComments;
  
  const TemplateSubmission({
    required this.submissionId,
    required this.templateId,
    required this.submittedAt,
    required this.submittedBy,
    required this.submitterEmail,
    required this.status,
    required this.moderationNotes,
    required this.reviewComments,
  });
}

class SubmissionMetadata {
  final String submitterName;
  final String submitterEmail;
  final String description;
  final List<String> tags;
  
  const SubmissionMetadata({
    required this.submitterName,
    required this.submitterEmail,
    required this.description,
    required this.tags,
  });
}

class TemplateStatistics {
  final int totalTemplates;
  final int officialTemplates;
  final int communityTemplates;
  final int totalDownloads;
  final double averageRating;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> difficultyBreakdown;
  final IntegrationTemplate mostPopularTemplate;
  final IntegrationTemplate newestTemplate;
  
  const TemplateStatistics({
    required this.totalTemplates,
    required this.officialTemplates,
    required this.communityTemplates,
    required this.totalDownloads,
    required this.averageRating,
    required this.categoryBreakdown,
    required this.difficultyBreakdown,
    required this.mostPopularTemplate,
    required this.newestTemplate,
  });
}

// Enums
enum ApplicationStatus {
  success,
  failed,
  skipped,
}

enum SubmissionStatus {
  pending,
  approved,
  rejected,
  underReview,
}

class TemplateException implements Exception {
  final String message;
  
  const TemplateException(this.message);
  
  @override
  String toString() => 'TemplateException: $message';
}

// Provider
final integrationTemplatesServiceProvider = Provider<IntegrationTemplatesService>((ref) {
  final integrationService = ref.watch(integrationServiceProvider);
  final backupService = ref.watch(integrationBackupServiceProvider);
  return IntegrationTemplatesService(integrationService, backupService);
});