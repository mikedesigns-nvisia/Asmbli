import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'integration_service.dart';

/// Service for managing integration documentation and help content
class IntegrationDocumentationService {
  final IntegrationService _integrationService;
  
  // Documentation cache
  final Map<String, IntegrationDocumentation> _documentationCache = {};
  
  // Help content cache
  final Map<String, List<HelpArticle>> _helpCache = {};
  
  IntegrationDocumentationService(this._integrationService) {
    _initializeDocumentation();
  }
  
  /// Initialize documentation for all integrations
  void _initializeDocumentation() {
    final allIntegrations = IntegrationRegistry.allIntegrations;
    
    for (final integration in allIntegrations) {
      _documentationCache[integration.id] = _generateDocumentation(integration);
      _helpCache[integration.id] = _generateHelpArticles(integration);
    }
  }
  
  /// Get documentation for a specific integration
  IntegrationDocumentation? getDocumentation(String integrationId) {
    return _documentationCache[integrationId];
  }
  
  /// Get help articles for a specific integration
  List<HelpArticle> getHelpArticles(String integrationId) {
    return _helpCache[integrationId] ?? [];
  }
  
  /// Get quick start guide for an integration
  QuickStartGuide getQuickStartGuide(String integrationId) {
    final integration = IntegrationRegistry.getById(integrationId);
    if (integration == null) {
      throw DocumentationException('Integration not found: $integrationId');
    }
    
    return QuickStartGuide(
      integrationId: integrationId,
      title: 'Quick Start: ${integration.name}',
      estimatedTime: _getEstimatedSetupTime(integration),
      difficulty: integration.difficulty,
      prerequisites: _getPrerequisiteSteps(integration),
      steps: _getQuickStartSteps(integration),
      commonIssues: _getCommonIssues(integration),
      nextSteps: _getNextSteps(integration),
    );
  }
  
  /// Get configuration examples for an integration
  List<ConfigurationExample> getConfigurationExamples(String integrationId) {
    final integration = IntegrationRegistry.getById(integrationId);
    if (integration == null) return [];
    
    return _generateConfigurationExamples(integration);
  }
  
  /// Get troubleshooting guide
  TroubleshootingGuide getTroubleshootingGuide(String integrationId) {
    final integration = IntegrationRegistry.getById(integrationId);
    if (integration == null) {
      throw DocumentationException('Integration not found: $integrationId');
    }
    
    return TroubleshootingGuide(
      integrationId: integrationId,
      title: 'Troubleshooting: ${integration.name}',
      commonIssues: _getCommonTroubleshootingIssues(integration),
      diagnosticSteps: _getDiagnosticSteps(integration),
      supportResources: _getSupportResources(integration),
    );
  }
  
  /// Get API reference documentation
  APIReference? getAPIReference(String integrationId) {
    final integration = IntegrationRegistry.getById(integrationId);
    if (integration == null) return null;
    
    return _generateAPIReference(integration);
  }
  
  /// Search documentation and help content
  List<SearchResult> searchDocumentation(String query) {
    final results = <SearchResult>[];
    final queryLower = query.toLowerCase();
    
    for (final entry in _documentationCache.entries) {
      final doc = entry.value;
      final integration = IntegrationRegistry.getById(entry.key);
      if (integration == null) continue;
      
      // Search in integration name and description
      if (integration.name.toLowerCase().contains(queryLower) ||
          integration.description.toLowerCase().contains(queryLower)) {
        results.add(SearchResult(
          type: SearchResultType.integration,
          integrationId: entry.key,
          title: integration.name,
          excerpt: integration.description,
          relevanceScore: _calculateRelevance(queryLower, '${integration.name} ${integration.description}'),
        ));
      }
      
      // Search in overview
      if (doc.overview.toLowerCase().contains(queryLower)) {
        results.add(SearchResult(
          type: SearchResultType.documentation,
          integrationId: entry.key,
          title: '${integration.name} - Overview',
          excerpt: _extractExcerpt(doc.overview, queryLower),
          relevanceScore: _calculateRelevance(queryLower, doc.overview),
        ));
      }
      
      // Search in features
      for (final feature in doc.features) {
        if (feature.toLowerCase().contains(queryLower)) {
          results.add(SearchResult(
            type: SearchResultType.feature,
            integrationId: entry.key,
            title: '${integration.name} - $feature',
            excerpt: feature,
            relevanceScore: _calculateRelevance(queryLower, feature),
          ));
        }
      }
    }
    
    // Search in help articles
    for (final entry in _helpCache.entries) {
      final articles = entry.value;
      final integration = IntegrationRegistry.getById(entry.key);
      if (integration == null) continue;
      
      for (final article in articles) {
        if (article.title.toLowerCase().contains(queryLower) ||
            article.content.toLowerCase().contains(queryLower)) {
          results.add(SearchResult(
            type: SearchResultType.helpArticle,
            integrationId: entry.key,
            title: article.title,
            excerpt: _extractExcerpt(article.content, queryLower),
            relevanceScore: _calculateRelevance(queryLower, '${article.title} ${article.content}'),
          ));
        }
      }
    }
    
    // Sort by relevance score
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    
    return results;
  }
  
  /// Get popular help topics
  List<PopularTopic> getPopularTopics() {
    return [
      const PopularTopic(
        title: 'Getting Started with Integrations',
        description: 'Learn how to set up your first integration',
        category: 'Getting Started',
        viewCount: 1250,
        helpfulVotes: 89,
      ),
      const PopularTopic(
        title: 'Configuring API Authentication',
        description: 'Set up API keys and authentication for cloud integrations',
        category: 'Configuration',
        viewCount: 980,
        helpfulVotes: 76,
      ),
      const PopularTopic(
        title: 'Troubleshooting Connection Issues',
        description: 'Common solutions for integration connectivity problems',
        category: 'Troubleshooting',
        viewCount: 850,
        helpfulVotes: 65,
      ),
      const PopularTopic(
        title: 'Understanding Integration Dependencies',
        description: 'How integration dependencies work and how to manage them',
        category: 'Advanced',
        viewCount: 620,
        helpfulVotes: 48,
      ),
      const PopularTopic(
        title: 'Performance Optimization Tips',
        description: 'Best practices for optimizing integration performance',
        category: 'Optimization',
        viewCount: 540,
        helpfulVotes: 42,
      ),
    ];
  }
  
  /// Get documentation categories
  List<DocumentationCategory> getDocumentationCategories() {
    final categories = <String, List<String>>{};
    
    for (final integration in IntegrationRegistry.allIntegrations) {
      final categoryName = integration.category.displayName;
      if (!categories.containsKey(categoryName)) {
        categories[categoryName] = [];
      }
      categories[categoryName]!.add(integration.id);
    }
    
    return categories.entries.map((entry) {
      final integrationCount = entry.value.length;
      final allStatuses = _integrationService.getAllIntegrationsWithStatus();
      final configuredCount = entry.value
          .where((id) => allStatuses.any((status) => status.definition.id == id && status.isConfigured))
          .length;
      
      return DocumentationCategory(
        name: entry.key,
        description: _getCategoryDescription(entry.key),
        integrationIds: entry.value,
        integrationCount: integrationCount,
        configuredCount: configuredCount,
        icon: _getCategoryIcon(entry.key),
      );
    }).toList();
  }
  
  /// Get contextual help based on current state
  List<ContextualHelp> getContextualHelp(String integrationId, String? currentStep) {
    final integration = IntegrationRegistry.getById(integrationId);
    if (integration == null) return [];
    
    final help = <ContextualHelp>[];
    
    // Add general help
    help.add(ContextualHelp(
      title: 'About ${integration.name}',
      content: integration.description,
      type: ContextualHelpType.info,
      priority: 1,
    ));
    
    // Add step-specific help
    if (currentStep != null) {
      switch (currentStep) {
        case 'authentication':
          help.add(ContextualHelp(
            title: 'Setting up Authentication',
            content: 'Enter your API credentials or authentication tokens for ${integration.name}. '
                    'These are typically found in your account settings or developer dashboard.',
            type: ContextualHelpType.guidance,
            priority: 5,
          ));
          break;
          
        case 'configuration':
          help.add(ContextualHelp(
            title: 'Configuration Options',
            content: 'Configure the specific settings for how ${integration.name} will be used. '
                    'You can modify these settings later if needed.',
            type: ContextualHelpType.guidance,
            priority: 4,
          ));
          break;
          
        case 'testing':
          help.add(ContextualHelp(
            title: 'Testing Your Integration',
            content: 'Verify that ${integration.name} is working correctly by running a test. '
                    'This ensures your configuration is valid and the connection is successful.',
            type: ContextualHelpType.guidance,
            priority: 5,
          ));
          break;
      }
    }
    
    // Add warnings based on integration type
    if (integration.category == IntegrationCategory.cloudAPIs) {
      help.add(const ContextualHelp(
        title: 'API Rate Limits',
        content: 'This integration connects to external APIs which may have rate limits. '
                'Monitor your usage to avoid hitting these limits.',
        type: ContextualHelpType.warning,
        priority: 3,
      ));
    }
    
    if (integration.prerequisites.isNotEmpty) {
      help.add(ContextualHelp(
        title: 'Prerequisites Required',
        content: 'This integration requires: ${integration.prerequisites.join(', ')}. '
                'Make sure these are properly set up before proceeding.',
        type: ContextualHelpType.warning,
        priority: 4,
      ));
    }
    
    // Sort by priority
    help.sort((a, b) => b.priority.compareTo(a.priority));
    
    return help;
  }
  
  // Private helper methods
  IntegrationDocumentation _generateDocumentation(IntegrationDefinition integration) {
    return IntegrationDocumentation(
      integrationId: integration.id,
      title: integration.name,
      overview: _generateOverview(integration),
      features: _generateFeatureList(integration),
      useCases: _generateUseCases(integration),
      requirements: _generateRequirements(integration),
      limitations: _generateLimitations(integration),
      lastUpdated: DateTime.now(),
      version: '1.0.0',
    );
  }
  
  List<HelpArticle> _generateHelpArticles(IntegrationDefinition integration) {
    final articles = <HelpArticle>[];
    
    // Setup guide
    articles.add(HelpArticle(
      id: '${integration.id}_setup',
      title: 'Setting up ${integration.name}',
      content: _generateSetupContent(integration),
      category: 'Setup',
      tags: ['setup', 'configuration', integration.category.name],
      difficulty: integration.difficulty,
      estimatedReadTime: const Duration(minutes: 5),
      lastUpdated: DateTime.now(),
      helpfulVotes: 0,
      viewCount: 0,
    ));
    
    // Configuration guide
    articles.add(HelpArticle(
      id: '${integration.id}_config',
      title: '${integration.name} Configuration Options',
      content: _generateConfigContent(integration),
      category: 'Configuration',
      tags: ['configuration', 'settings', integration.category.name],
      difficulty: integration.difficulty,
      estimatedReadTime: const Duration(minutes: 3),
      lastUpdated: DateTime.now(),
      helpfulVotes: 0,
      viewCount: 0,
    ));
    
    // Troubleshooting guide
    articles.add(HelpArticle(
      id: '${integration.id}_troubleshooting',
      title: 'Troubleshooting ${integration.name}',
      content: _generateTroubleshootingContent(integration),
      category: 'Troubleshooting',
      tags: ['troubleshooting', 'issues', 'problems'],
      difficulty: 'Medium',
      estimatedReadTime: const Duration(minutes: 4),
      lastUpdated: DateTime.now(),
      helpfulVotes: 0,
      viewCount: 0,
    ));
    
    return articles;
  }
  
  String _generateOverview(IntegrationDefinition integration) {
    return '''
${integration.description}

${integration.name} is a ${integration.category.displayName.toLowerCase()} integration that provides ${integration.capabilities.join(', ')} capabilities. This integration allows your agents to interact with ${integration.name} services seamlessly.

**Key Benefits:**
• Enhanced agent capabilities through ${integration.name} features
• Streamlined workflow integration
• Professional-grade API access
• Secure authentication and data handling

This integration is classified as "${integration.difficulty}" difficulty and ${integration.isAvailable ? 'is currently available' : 'will be available soon'}.
    '''.trim();
  }
  
  List<String> _generateFeatureList(IntegrationDefinition integration) {
    final features = <String>[];
    
    for (final capability in integration.capabilities) {
      switch (capability) {
        case 'read':
          features.add('Read and retrieve data from ${integration.name}');
          break;
        case 'write':
          features.add('Create and update content in ${integration.name}');
          break;
        case 'search':
          features.add('Search and query ${integration.name} data');
          break;
        case 'sync':
          features.add('Synchronize data with ${integration.name}');
          break;
        case 'webhook':
          features.add('Real-time updates via ${integration.name} webhooks');
          break;
        default:
          features.add('${capability.replaceAll('_', ' ').toUpperCase()} operations');
      }
    }
    
    return features;
  }
  
  List<String> _generateUseCases(IntegrationDefinition integration) {
    final useCases = <String>[];
    
    switch (integration.category) {
      case IntegrationCategory.databases:
        useCases.addAll([
          'Store and retrieve persistent data for agents',
          'Maintain conversation history and context',
          'Cache frequently accessed information',
          'Generate reports and analytics',
        ]);
        break;
        
      case IntegrationCategory.cloudAPIs:
        useCases.addAll([
          'Access external services and data',
          'Integrate with third-party platforms',
          'Automate cross-platform workflows',
          'Enhance agent capabilities with external tools',
        ]);
        break;
        
      case IntegrationCategory.local:
        useCases.addAll([
          'Access local files and directories',
          'Execute system commands and scripts',
          'Monitor local system resources',
          'Process local data and documents',
        ]);
        break;
        
      // case IntegrationCategory.aiEnhanced: // Not available in current core version
      //   useCases.addAll([
      //     'Enhanced reasoning and problem-solving',
      //     'Memory and context management',
      //     'Advanced natural language processing',
      //     'Intelligent automation workflows',
      //   ]);
      //   break;
        
      case IntegrationCategory.utilities:
        useCases.addAll([
          'Utility functions and helpers',
          'Data transformation and processing',
          'System integration support',
          'Development and debugging tools',
        ]);
        break;
        
      default:
        useCases.addAll([
          'General integration capabilities',
          'Custom workflows and automation',
          'Data processing and analysis',
        ]);
        break;
    }
    
    return useCases;
  }
  
  List<String> _generateRequirements(IntegrationDefinition integration) {
    final requirements = <String>[];
    
    if (integration.prerequisites.isNotEmpty) {
      requirements.addAll(integration.prerequisites.map((req) => 'Prerequisite: $req'));
    }
    
    switch (integration.category) {
      case IntegrationCategory.cloudAPIs:
        requirements.addAll([
          'Active internet connection',
          'Valid API credentials or authentication tokens',
          'Appropriate service plan or subscription',
        ]);
        break;
        
      case IntegrationCategory.databases:
        requirements.addAll([
          'Database server access',
          'Valid database credentials',
          'Network connectivity to database',
        ]);
        break;
        
      case IntegrationCategory.local:
        requirements.addAll([
          'Local file system access',
          'Appropriate operating system permissions',
          'Required software or tools installed',
        ]);
        break;
        
      default:
        requirements.add('Basic system requirements');
    }
    
    return requirements;
  }
  
  List<String> _generateLimitations(IntegrationDefinition integration) {
    final limitations = <String>[];
    
    switch (integration.category) {
      case IntegrationCategory.cloudAPIs:
        limitations.addAll([
          'Subject to external API rate limits',
          'Requires stable internet connection',
          'Performance depends on external service availability',
          'May incur usage costs from the external service',
        ]);
        break;
        
      case IntegrationCategory.databases:
        limitations.addAll([
          'Performance depends on database server capacity',
          'Requires proper database maintenance',
          'Subject to database connection limits',
        ]);
        break;
        
      case IntegrationCategory.local:
        limitations.addAll([
          'Limited to local system capabilities',
          'Performance depends on local hardware',
          'May require elevated permissions for some operations',
        ]);
        break;
        
      default:
        limitations.add('Standard integration limitations apply');
    }
    
    return limitations;
  }
  
  Duration _getEstimatedSetupTime(IntegrationDefinition integration) {
    switch (integration.difficulty) {
      case 'Easy':
        return const Duration(minutes: 5);
      case 'Medium':
        return const Duration(minutes: 15);
      case 'Hard':
        return const Duration(minutes: 30);
      default:
        return const Duration(minutes: 10);
    }
  }
  
  List<PrerequisiteStep> _getPrerequisiteSteps(IntegrationDefinition integration) {
    final steps = <PrerequisiteStep>[];
    
    for (final prereq in integration.prerequisites) {
      steps.add(PrerequisiteStep(
        title: 'Set up $prereq',
        description: 'Ensure $prereq is properly configured and accessible',
        isRequired: true,
        estimatedTime: const Duration(minutes: 5),
      ));
    }
    
    return steps;
  }
  
  List<SetupStep> _getQuickStartSteps(IntegrationDefinition integration) {
    final steps = <SetupStep>[];
    
    steps.add(SetupStep(
      stepNumber: 1,
      title: 'Add Integration',
      description: 'Add ${integration.name} to your configured integrations',
      action: 'Click "Add Integration" and select ${integration.name}',
      expectedResult: 'Integration appears in your integrations list',
    ));
    
    if (integration.category == IntegrationCategory.cloudAPIs) {
      steps.add(SetupStep(
        stepNumber: 2,
        title: 'Configure Authentication',
        description: 'Set up your ${integration.name} API credentials',
        action: 'Enter your API key, tokens, or login credentials',
        expectedResult: 'Authentication test passes successfully',
      ));
    }
    
    steps.add(SetupStep(
      stepNumber: steps.length + 1,
      title: 'Test Connection',
      description: 'Verify the integration is working correctly',
      action: 'Run the connection test',
      expectedResult: 'Test completes successfully with no errors',
    ));
    
    steps.add(SetupStep(
      stepNumber: steps.length + 1,
      title: 'Enable Integration',
      description: 'Activate the integration for use',
      action: 'Toggle the integration to "Enabled" status',
      expectedResult: 'Integration shows as "Active" in the dashboard',
    ));
    
    return steps;
  }
  
  List<CommonIssue> _getCommonIssues(IntegrationDefinition integration) {
    final issues = <CommonIssue>[];
    
    if (integration.category == IntegrationCategory.cloudAPIs) {
      issues.addAll([
        const CommonIssue(
          title: 'Authentication Failed',
          description: 'API credentials are invalid or expired',
          solution: 'Verify your API key is correct and has not expired. Check the service documentation for proper credential format.',
        ),
        const CommonIssue(
          title: 'Rate Limit Exceeded',
          description: 'Too many requests sent to the API',
          solution: 'Wait for the rate limit to reset or upgrade your service plan for higher limits.',
        ),
      ]);
    }
    
    issues.add(const CommonIssue(
      title: 'Connection Timeout',
      description: 'Unable to establish connection within timeout period',
      solution: 'Check your internet connection and verify the service is accessible. Try increasing the timeout value.',
    ));
    
    return issues;
  }
  
  List<String> _getNextSteps(IntegrationDefinition integration) {
    return [
      'Explore the integration\'s capabilities in the Analytics tab',
      'Configure additional settings in the advanced options',
      'Set up automated workflows using this integration',
      'Review the troubleshooting guide for common issues',
      'Check out related integrations that work well with ${integration.name}',
    ];
  }
  
  // Additional helper methods for generating content...
  String _generateSetupContent(IntegrationDefinition integration) {
    return '''
# Setting up ${integration.name}

This guide will walk you through the process of setting up ${integration.name} integration.

## Prerequisites

${integration.prerequisites.isEmpty ? 'No special prerequisites required.' : integration.prerequisites.map((p) => '• $p').join('\n')}

## Step-by-step Setup

1. **Add Integration**: Navigate to the Integrations tab and click "Add Integration"
2. **Select ${integration.name}**: Find and select ${integration.name} from the list
3. **Configure Settings**: Fill in the required configuration fields
4. **Test Connection**: Run a connection test to verify setup
5. **Enable**: Activate the integration for use

## Configuration Options

The following settings are available for ${integration.name}:

${integration.capabilities.map((cap) => '• **${cap.toUpperCase()}**: Enable $cap capabilities').join('\n')}

## Verification

After setup, verify the integration is working by:
• Checking the status indicator shows "Active"
• Running a test from the Testing tab
• Monitoring the health dashboard for any issues

Need help? Check the troubleshooting guide or contact support.
    '''.trim();
  }
  
  String _generateConfigContent(IntegrationDefinition integration) {
    return '''
# ${integration.name} Configuration

Configure ${integration.name} to match your specific needs and use cases.

## Basic Configuration

• **Name**: Friendly name for this integration instance
• **Description**: Optional description for documentation
• **Enabled**: Whether this integration is active

## ${integration.category == IntegrationCategory.cloudAPIs ? 'Authentication' : 'Connection'} Settings

${integration.category == IntegrationCategory.cloudAPIs 
  ? '• **API Key**: Your ${integration.name} API key\n• **Endpoint**: API endpoint URL (usually auto-configured)\n• **Timeout**: Request timeout in seconds'
  : '• **Connection String**: How to connect to ${integration.name}\n• **Timeout**: Connection timeout in seconds\n• **Retry Attempts**: Number of retry attempts on failure'
}

## Advanced Options

• **Rate Limiting**: Configure request rate limits
• **Caching**: Enable response caching for better performance  
• **Logging**: Set logging level for debugging
• **Custom Headers**: Add custom headers to requests

## Environment Variables

Some configurations can be set via environment variables for security:

${integration.category == IntegrationCategory.cloudAPIs
  ? '• `${integration.id.toUpperCase()}_API_KEY`: API key\n• `${integration.id.toUpperCase()}_ENDPOINT`: Custom endpoint'
  : '• `${integration.id.toUpperCase()}_CONNECTION`: Connection string\n• `${integration.id.toUpperCase()}_CONFIG`: JSON configuration'
}

## Best Practices

• Keep sensitive credentials in environment variables
• Test configuration changes in a development environment first
• Monitor integration performance after configuration changes
• Document any custom configurations for team members
    '''.trim();
  }
  
  String _generateTroubleshootingContent(IntegrationDefinition integration) {
    return '''
# Troubleshooting ${integration.name}

Common issues and solutions for ${integration.name} integration.

## Connection Issues

**Problem**: Cannot connect to ${integration.name}
**Solutions**:
• Verify network connectivity
• Check firewall settings
• Confirm service is operational
• Validate connection credentials

**Problem**: Intermittent connection failures
**Solutions**:
• Increase timeout values
• Enable connection retry logic
• Check for rate limiting
• Monitor network stability

## Authentication Issues

${integration.category == IntegrationCategory.cloudAPIs ? '''
**Problem**: Authentication failed
**Solutions**:
• Verify API key is correct and active
• Check API key permissions and scopes
• Ensure API key hasn't expired
• Confirm correct authentication method

**Problem**: Unauthorized access
**Solutions**:
• Check API key has required permissions
• Verify account subscription status
• Contact service provider for access issues
''' : '''
**Problem**: Access denied
**Solutions**:
• Check file/system permissions
• Verify user account has required access
• Run with elevated privileges if needed
'''}

## Performance Issues

**Problem**: Slow response times
**Solutions**:
• Check network latency
• Optimize query complexity
• Enable caching where appropriate
• Consider load balancing

**Problem**: High error rates
**Solutions**:
• Review error logs for patterns
• Check service status and limitations
• Validate request formats
• Implement proper error handling

## Getting Help

If you're still experiencing issues:

1. Check the integration health dashboard
2. Review recent error logs
3. Run diagnostic tests
4. Contact support with error details

## Diagnostic Information

When reporting issues, include:
• Integration configuration (without sensitive data)
• Error messages and timestamps
• Steps to reproduce the issue
• System environment details
    '''.trim();
  }
  
  List<ConfigurationExample> _generateConfigurationExamples(IntegrationDefinition integration) {
    final examples = <ConfigurationExample>[];
    
    // Basic example
    examples.add(ConfigurationExample(
      title: 'Basic Configuration',
      description: 'Standard setup for ${integration.name}',
      difficulty: 'Easy',
      config: _generateBasicConfig(integration),
      explanation: 'This is the minimal configuration needed to get ${integration.name} working.',
    ));
    
    // Advanced example
    examples.add(ConfigurationExample(
      title: 'Advanced Configuration',
      description: 'Full-featured setup with all options',
      difficulty: 'Hard',
      config: _generateAdvancedConfig(integration),
      explanation: 'This configuration includes all available options and optimizations.',
    ));
    
    return examples;
  }
  
  Map<String, dynamic> _generateBasicConfig(IntegrationDefinition integration) {
    final config = <String, dynamic>{
      'name': integration.name,
      'enabled': true,
    };
    
    if (integration.category == IntegrationCategory.cloudAPIs) {
      config.addAll({
        'apiKey': '\${${integration.id.toUpperCase()}_API_KEY}',
        'timeout': 30,
      });
    }
    
    return config;
  }
  
  Map<String, dynamic> _generateAdvancedConfig(IntegrationDefinition integration) {
    final config = _generateBasicConfig(integration);
    
    config.addAll({
      'retryAttempts': 3,
      'caching': {
        'enabled': true,
        'ttl': 300,
      },
      'logging': {
        'level': 'info',
        'includeHeaders': false,
      },
    });
    
    return config;
  }
  
  // Additional helper methods...
  String _extractExcerpt(String content, String query) {
    final index = content.toLowerCase().indexOf(query);
    if (index == -1) return '${content.substring(0, 150)}...';
    
    final start = (index - 50).clamp(0, content.length);
    final end = (index + query.length + 50).clamp(0, content.length);
    
    return '${content.substring(start, end)}...';
  }
  
  double _calculateRelevance(String query, String content) {
    final contentLower = content.toLowerCase();
    final queryLower = query.toLowerCase();
    
    double score = 0.0;
    
    // Exact match bonus
    if (contentLower.contains(queryLower)) {
      score += 10.0;
    }
    
    // Word match scoring
    final queryWords = queryLower.split(' ');
    for (final word in queryWords) {
      if (contentLower.contains(word)) {
        score += 2.0;
      }
    }
    
    return score;
  }
  
  String _getCategoryDescription(String categoryName) {
    switch (categoryName) {
      case 'Local':
        return 'Integrations that work with local files, system resources, and installed software';
      case 'Cloud APIs':
        return 'Integrations with cloud services and external APIs';
      case 'Databases':
        return 'Database connections and data storage integrations';
      case 'AI Enhanced':
        return 'AI-powered integrations that enhance agent capabilities';
      case 'Utilities':
        return 'Utility integrations for development and system management';
      default:
        return 'Integration category';
    }
  }
  
  String _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Local': return 'computer';
      case 'Cloud APIs': return 'cloud';
      case 'Databases': return 'storage';
      case 'AI Enhanced': return 'psychology';
      case 'Utilities': return 'build';
      default: return 'help_outline';
    }
  }
  
  List<CommonIssue> _getCommonTroubleshootingIssues(IntegrationDefinition integration) {
    return _getCommonIssues(integration);
  }
  
  List<DiagnosticStep> _getDiagnosticSteps(IntegrationDefinition integration) {
    return [
      const DiagnosticStep(
        step: 1,
        title: 'Check Integration Status',
        description: 'Verify the integration is enabled and configured',
        command: 'Check the integration dashboard for status indicators',
      ),
      const DiagnosticStep(
        step: 2,
        title: 'Test Connection',
        description: 'Run a connection test to verify basic connectivity',
        command: 'Use the Testing tab to run connectivity tests',
      ),
      const DiagnosticStep(
        step: 3,
        title: 'Review Logs',
        description: 'Check recent logs for error messages',
        command: 'Examine the integration logs in the Analytics tab',
      ),
    ];
  }
  
  List<SupportResource> _getSupportResources(IntegrationDefinition integration) {
    return [
      SupportResource(
        title: 'Integration Documentation',
        description: 'Complete documentation for ${integration.name}',
        type: 'Documentation',
        url: '#',
      ),
      const SupportResource(
        title: 'Community Forum',
        description: 'Get help from the community',
        type: 'Community',
        url: '#',
      ),
      const SupportResource(
        title: 'Contact Support',
        description: 'Direct support for complex issues',
        type: 'Support',
        url: '#',
      ),
    ];
  }
  
  APIReference _generateAPIReference(IntegrationDefinition integration) {
    return APIReference(
      integrationId: integration.id,
      title: '${integration.name} API Reference',
      baseUrl: 'https://api.${integration.id}.com',
      authentication: integration.category == IntegrationCategory.cloudAPIs 
          ? 'API Key in Authorization header'
          : 'Not applicable',
      endpoints: _generateEndpoints(integration),
      examples: _generateAPIExamples(integration),
    );
  }
  
  List<APIEndpoint> _generateEndpoints(IntegrationDefinition integration) {
    final endpoints = <APIEndpoint>[];
    
    for (final capability in integration.capabilities) {
      switch (capability) {
        case 'read':
          endpoints.add(APIEndpoint(
            method: 'GET',
            path: '/data',
            description: 'Retrieve data from ${integration.name}',
            parameters: ['id', 'filter'],
            response: 'JSON object with requested data',
          ));
          break;
        case 'write':
          endpoints.add(APIEndpoint(
            method: 'POST',
            path: '/data',
            description: 'Create or update data in ${integration.name}',
            parameters: ['data', 'options'],
            response: 'Success confirmation with created resource ID',
          ));
          break;
        case 'search':
          endpoints.add(APIEndpoint(
            method: 'GET',
            path: '/search',
            description: 'Search ${integration.name} data',
            parameters: ['query', 'limit', 'offset'],
            response: 'Array of matching results',
          ));
          break;
      }
    }
    
    return endpoints;
  }
  
  List<String> _generateAPIExamples(IntegrationDefinition integration) {
    return [
      '''
// Basic usage example
const ${integration.id} = new ${integration.name}Integration();
const result = await ${integration.id}.getData({ id: '123' });
console.log(result);
      '''.trim(),
    ];
  }
}

// Data models
class IntegrationDocumentation {
  final String integrationId;
  final String title;
  final String overview;
  final List<String> features;
  final List<String> useCases;
  final List<String> requirements;
  final List<String> limitations;
  final DateTime lastUpdated;
  final String version;
  
  const IntegrationDocumentation({
    required this.integrationId,
    required this.title,
    required this.overview,
    required this.features,
    required this.useCases,
    required this.requirements,
    required this.limitations,
    required this.lastUpdated,
    required this.version,
  });
}

class HelpArticle {
  final String id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final String difficulty;
  final Duration estimatedReadTime;
  final DateTime lastUpdated;
  final int helpfulVotes;
  final int viewCount;
  
  const HelpArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.difficulty,
    required this.estimatedReadTime,
    required this.lastUpdated,
    required this.helpfulVotes,
    required this.viewCount,
  });
}

class QuickStartGuide {
  final String integrationId;
  final String title;
  final Duration estimatedTime;
  final String difficulty;
  final List<PrerequisiteStep> prerequisites;
  final List<SetupStep> steps;
  final List<CommonIssue> commonIssues;
  final List<String> nextSteps;
  
  const QuickStartGuide({
    required this.integrationId,
    required this.title,
    required this.estimatedTime,
    required this.difficulty,
    required this.prerequisites,
    required this.steps,
    required this.commonIssues,
    required this.nextSteps,
  });
}

class PrerequisiteStep {
  final String title;
  final String description;
  final bool isRequired;
  final Duration estimatedTime;
  
  const PrerequisiteStep({
    required this.title,
    required this.description,
    required this.isRequired,
    required this.estimatedTime,
  });
}

class SetupStep {
  final int stepNumber;
  final String title;
  final String description;
  final String action;
  final String expectedResult;
  
  const SetupStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.action,
    required this.expectedResult,
  });
}

class CommonIssue {
  final String title;
  final String description;
  final String solution;
  
  const CommonIssue({
    required this.title,
    required this.description,
    required this.solution,
  });
}

class ConfigurationExample {
  final String title;
  final String description;
  final String difficulty;
  final Map<String, dynamic> config;
  final String explanation;
  
  const ConfigurationExample({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.config,
    required this.explanation,
  });
}

class TroubleshootingGuide {
  final String integrationId;
  final String title;
  final List<CommonIssue> commonIssues;
  final List<DiagnosticStep> diagnosticSteps;
  final List<SupportResource> supportResources;
  
  const TroubleshootingGuide({
    required this.integrationId,
    required this.title,
    required this.commonIssues,
    required this.diagnosticSteps,
    required this.supportResources,
  });
}

class DiagnosticStep {
  final int step;
  final String title;
  final String description;
  final String command;
  
  const DiagnosticStep({
    required this.step,
    required this.title,
    required this.description,
    required this.command,
  });
}

class SupportResource {
  final String title;
  final String description;
  final String type;
  final String url;
  
  const SupportResource({
    required this.title,
    required this.description,
    required this.type,
    required this.url,
  });
}

class APIReference {
  final String integrationId;
  final String title;
  final String baseUrl;
  final String authentication;
  final List<APIEndpoint> endpoints;
  final List<String> examples;
  
  const APIReference({
    required this.integrationId,
    required this.title,
    required this.baseUrl,
    required this.authentication,
    required this.endpoints,
    required this.examples,
  });
}

class APIEndpoint {
  final String method;
  final String path;
  final String description;
  final List<String> parameters;
  final String response;
  
  const APIEndpoint({
    required this.method,
    required this.path,
    required this.description,
    required this.parameters,
    required this.response,
  });
}

class SearchResult {
  final SearchResultType type;
  final String integrationId;
  final String title;
  final String excerpt;
  final double relevanceScore;
  
  const SearchResult({
    required this.type,
    required this.integrationId,
    required this.title,
    required this.excerpt,
    required this.relevanceScore,
  });
}

class PopularTopic {
  final String title;
  final String description;
  final String category;
  final int viewCount;
  final int helpfulVotes;
  
  const PopularTopic({
    required this.title,
    required this.description,
    required this.category,
    required this.viewCount,
    required this.helpfulVotes,
  });
}

class DocumentationCategory {
  final String name;
  final String description;
  final List<String> integrationIds;
  final int integrationCount;
  final int configuredCount;
  final String icon;
  
  const DocumentationCategory({
    required this.name,
    required this.description,
    required this.integrationIds,
    required this.integrationCount,
    required this.configuredCount,
    required this.icon,
  });
}

class ContextualHelp {
  final String title;
  final String content;
  final ContextualHelpType type;
  final int priority;
  
  const ContextualHelp({
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
  });
}

// Enums
enum SearchResultType {
  integration,
  documentation,
  feature,
  helpArticle,
}

enum ContextualHelpType {
  info,
  guidance,
  warning,
  tip,
}

class DocumentationException implements Exception {
  final String message;
  
  const DocumentationException(this.message);
  
  @override
  String toString() => 'DocumentationException: $message';
}

// Provider
final integrationDocumentationServiceProvider = Provider<IntegrationDocumentationService>((ref) {
  final integrationService = ref.watch(integrationServiceProvider);
  return IntegrationDocumentationService(integrationService);
});