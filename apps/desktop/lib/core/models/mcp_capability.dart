/// User-friendly capabilities that agents can provide
/// 
/// This maps human requests like "analyze my code" to specific MCP servers
/// following Anthropic PM approach of hiding technical complexity
class AgentCapability {
  final String id;
  final String displayName;
  final String description;
  final String userBenefit;
  final List<String> requiredMCPServers;
  final CapabilityCategory category;
  final CapabilityRiskLevel riskLevel;
  final String iconEmoji;

  const AgentCapability._({
    required this.id,
    required this.displayName,
    required this.description,
    required this.userBenefit,
    required this.requiredMCPServers,
    required this.category,
    required this.riskLevel,
    required this.iconEmoji,
  });

  // Code & Development Capabilities
  static const codeAnalysis = AgentCapability._(
    id: 'code-analysis',
    displayName: 'Code Analysis',
    description: 'Analyze your codebase, review code quality, and suggest improvements',
    userBenefit: 'Get insights into your code structure, find bugs, and improve code quality',
    requiredMCPServers: ['filesystem', 'git'],
    category: CapabilityCategory.development,
    riskLevel: CapabilityRiskLevel.low,
    iconEmoji: '🔍',
  );

  static const gitIntegration = AgentCapability._(
    id: 'git-integration',
    displayName: 'Git Integration',
    description: 'Work with Git repositories, branches, commits, and history',
    userBenefit: 'Manage your Git workflow without leaving the conversation',
    requiredMCPServers: ['git'],
    category: CapabilityCategory.development,
    riskLevel: CapabilityRiskLevel.medium,
    iconEmoji: '🌿',
  );

  static const fileAccess = AgentCapability._(
    id: 'file-access',
    displayName: 'File Access',
    description: 'Read, write, and organize files on your computer',
    userBenefit: 'Let me help you manage files and folders efficiently',
    requiredMCPServers: ['filesystem'],
    category: CapabilityCategory.productivity,
    riskLevel: CapabilityRiskLevel.high,
    iconEmoji: '📁',
  );

  // Web & Search Capabilities
  static const webSearch = AgentCapability._(
    id: 'web-search',
    displayName: 'Web Search',
    description: 'Search the web for current information and research',
    userBenefit: 'Get up-to-date information from across the internet',
    requiredMCPServers: ['brave-search'],
    category: CapabilityCategory.research,
    riskLevel: CapabilityRiskLevel.low,
    iconEmoji: '🔍',
  );

  static const webScraping = AgentCapability._(
    id: 'web-scraping',
    displayName: 'Web Content Access',
    description: 'Fetch and analyze content from websites',
    userBenefit: 'Extract information from web pages for analysis',
    requiredMCPServers: ['fetch', 'puppeteer'],
    category: CapabilityCategory.research,
    riskLevel: CapabilityRiskLevel.medium,
    iconEmoji: '🌐',
  );

  // Data & Database Capabilities
  static const databaseAccess = AgentCapability._(
    id: 'database-access',
    displayName: 'Database Access',
    description: 'Query and analyze data from databases',
    userBenefit: 'Work with your data without writing SQL manually',
    requiredMCPServers: ['postgresql', 'sqlite'],
    category: CapabilityCategory.data,
    riskLevel: CapabilityRiskLevel.high,
    iconEmoji: '🗄️',
  );

  // Cloud & Integration Capabilities
  static const githubIntegration = AgentCapability._(
    id: 'github-integration',
    displayName: 'GitHub Integration',
    description: 'Manage GitHub repositories, issues, and pull requests',
    userBenefit: 'Handle GitHub workflows directly from our conversation',
    requiredMCPServers: ['github'],
    category: CapabilityCategory.productivity,
    riskLevel: CapabilityRiskLevel.medium,
    iconEmoji: '🐙',
  );

  static const slackIntegration = AgentCapability._(
    id: 'slack-integration',
    displayName: 'Slack Integration',
    description: 'Send messages and manage Slack channels',
    userBenefit: 'Stay connected with your team without switching apps',
    requiredMCPServers: ['slack'],
    category: CapabilityCategory.communication,
    riskLevel: CapabilityRiskLevel.medium,
    iconEmoji: '💬',
  );

  // Memory & Context Capabilities
  static const persistentMemory = AgentCapability._(
    id: 'persistent-memory',
    displayName: 'Persistent Memory',
    description: 'Remember important information across conversations',
    userBenefit: 'I\'ll remember your preferences and important details',
    requiredMCPServers: ['memory'],
    category: CapabilityCategory.intelligence,
    riskLevel: CapabilityRiskLevel.low,
    iconEmoji: '🧠',
  );

  // Design & Content Capabilities
  static const figmaIntegration = AgentCapability._(
    id: 'figma-integration',
    displayName: 'Figma Integration',
    description: 'Access and analyze Figma design files',
    userBenefit: 'Work with your designs and get implementation guidance',
    requiredMCPServers: ['figma-official'],
    category: CapabilityCategory.design,
    riskLevel: CapabilityRiskLevel.low,
    iconEmoji: '🎨',
  );

  /// Get all available capabilities
  static List<AgentCapability> getAllCapabilities() {
    return [
      codeAnalysis,
      gitIntegration,
      fileAccess,
      webSearch,
      webScraping,
      databaseAccess,
      githubIntegration,
      slackIntegration,
      persistentMemory,
      figmaIntegration,
    ];
  }

  /// Get capabilities by category
  static List<AgentCapability> getCapabilitiesByCategory(CapabilityCategory category) {
    return getAllCapabilities().where((cap) => cap.category == category).toList();
  }

  /// Get low-risk capabilities (good for auto-enabling)
  static List<AgentCapability> getLowRiskCapabilities() {
    return getAllCapabilities()
        .where((cap) => cap.riskLevel == CapabilityRiskLevel.low)
        .toList();
  }

  /// Find capability by user intent/request
  static AgentCapability? findByUserIntent(String userRequest) {
    final request = userRequest.toLowerCase();
    
    // Code analysis intents
    if (request.contains('code') && (request.contains('analyze') || 
        request.contains('review') || request.contains('quality'))) {
      return codeAnalysis;
    }
    
    // Git intents
    if (request.contains('git') || request.contains('commit') || 
        request.contains('branch') || request.contains('repository')) {
      return gitIntegration;
    }
    
    // File access intents
    if (request.contains('file') && (request.contains('read') || 
        request.contains('write') || request.contains('organize'))) {
      return fileAccess;
    }
    
    // Web search intents
    if (request.contains('search') || request.contains('find information') ||
        request.contains('research online')) {
      return webSearch;
    }
    
    // Database intents
    if (request.contains('database') || request.contains('sql') || 
        request.contains('query data')) {
      return databaseAccess;
    }
    
    // GitHub intents
    if (request.contains('github') || request.contains('pull request') ||
        request.contains('issue')) {
      return githubIntegration;
    }
    
    // Memory intents
    if (request.contains('remember') || request.contains('memory') ||
        request.contains('context')) {
      return persistentMemory;
    }
    
    return null;
  }

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentCapability &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Categories of capabilities for organization
enum CapabilityCategory {
  development('Development', '💻'),
  productivity('Productivity', '⚡'),
  research('Research', '📚'),
  data('Data & Analytics', '📊'),
  communication('Communication', '💬'),
  intelligence('AI Intelligence', '🤖'),
  design('Design', '🎨');

  const CapabilityCategory(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

/// Risk levels for capabilities (determines approval requirements)
enum CapabilityRiskLevel {
  low('Low Risk', 'These are safe to enable automatically'),
  medium('Medium Risk', 'These require user approval but are generally safe'),
  high('High Risk', 'These require explicit approval and have security implications');

  const CapabilityRiskLevel(this.displayName, this.description);
  final String displayName;
  final String description;
}