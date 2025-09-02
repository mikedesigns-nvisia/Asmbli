import 'package:flutter/foundation.dart';
import '../../../core/services/agent_system_prompt_service.dart';

/// State management for the agent deployment wizard
/// Tracks user input across all wizard steps
class AgentWizardState extends ChangeNotifier {
  // Step 1: Agent Basics
  String _agentName = '';
  String _agentDescription = '';
  String _agentRole = '';
  String? _selectedTemplate;
  
  // Step 2: Intelligence Configuration
  String _systemPrompt = '';
  String _selectedApiProvider = '';
  Map<String, dynamic> _modelParameters = {};
  
  // Step 3: MCP Server Selection
  List<String> _selectedMCPServers = [];
  Map<String, Map<String, String>> _mcpServerConfigs = {};
  
  // Step 4: Advanced Configuration
  Map<String, String> _environmentVariables = {};
  List<String> _contextDocuments = [];
  Map<String, dynamic> _advancedSettings = {};
  
  // Step 5: Deploy & Test
  bool _isValidated = false;
  String? _testConversationId;

  // Getters for Step 1: Agent Basics
  String get agentName => _agentName;
  String get agentDescription => _agentDescription;
  String get agentRole => _agentRole;
  String? get selectedTemplate => _selectedTemplate;

  // Getters for Step 2: Intelligence Configuration
  String get systemPrompt => _systemPrompt;
  String get selectedApiProvider => _selectedApiProvider;
  Map<String, dynamic> get modelParameters => Map.unmodifiable(_modelParameters);

  // Getters for Step 3: MCP Server Selection
  List<String> get selectedMCPServers => List.unmodifiable(_selectedMCPServers);
  Map<String, Map<String, String>> get mcpServerConfigs => Map.unmodifiable(_mcpServerConfigs);

  // Getters for Step 4: Advanced Configuration
  Map<String, String> get environmentVariables => Map.unmodifiable(_environmentVariables);
  List<String> get contextDocuments => List.unmodifiable(_contextDocuments);
  Map<String, dynamic> get advancedSettings => Map.unmodifiable(_advancedSettings);

  // Getters for Step 5: Deploy & Test
  bool get isValidated => _isValidated;
  String? get testConversationId => _testConversationId;

  // Setters for Step 1: Agent Basics
  void setAgentName(String name) {
    _agentName = name;
    notifyListeners();
  }

  void setAgentDescription(String description) {
    _agentDescription = description;
    notifyListeners();
  }

  void setAgentRole(String role) {
    _agentRole = role;
    notifyListeners();
  }

  void setSelectedTemplate(String? template) {
    _selectedTemplate = template;
    if (template != null) {
      _loadTemplateDefaults(template);
    }
    notifyListeners();
  }

  // Setters for Step 2: Intelligence Configuration
  void setSystemPrompt(String prompt) {
    _systemPrompt = prompt;
    notifyListeners();
  }

  void setSelectedApiProvider(String provider) {
    _selectedApiProvider = provider;
    notifyListeners();
  }

  void setModelParameter(String key, dynamic value) {
    _modelParameters[key] = value;
    notifyListeners();
  }

  void setModelParameters(Map<String, dynamic> parameters) {
    _modelParameters = Map.from(parameters);
    notifyListeners();
  }

  // Setters for Step 3: MCP Server Selection
  void addMCPServer(String serverId) {
    if (!_selectedMCPServers.contains(serverId)) {
      _selectedMCPServers.add(serverId);
      notifyListeners();
    }
  }

  void removeMCPServer(String serverId) {
    _selectedMCPServers.remove(serverId);
    _mcpServerConfigs.remove(serverId);
    notifyListeners();
  }

  void setMCPServerConfig(String serverId, Map<String, String> config) {
    _mcpServerConfigs[serverId] = Map.from(config);
    notifyListeners();
  }

  void clearMCPServers() {
    _selectedMCPServers.clear();
    _mcpServerConfigs.clear();
    notifyListeners();
  }

  // Setters for Step 4: Advanced Configuration
  void setEnvironmentVariable(String key, String value) {
    if (value.isEmpty) {
      _environmentVariables.remove(key);
    } else {
      _environmentVariables[key] = value;
    }
    notifyListeners();
  }

  void setEnvironmentVariables(Map<String, String> variables) {
    _environmentVariables = Map.from(variables);
    notifyListeners();
  }

  void addContextDocument(String document) {
    if (!_contextDocuments.contains(document)) {
      _contextDocuments.add(document);
      notifyListeners();
    }
  }

  void removeContextDocument(String document) {
    _contextDocuments.remove(document);
    notifyListeners();
  }

  void setAdvancedSetting(String key, dynamic value) {
    _advancedSettings[key] = value;
    notifyListeners();
  }

  // Setters for Step 5: Deploy & Test
  void setValidated(bool validated) {
    _isValidated = validated;
    notifyListeners();
  }

  void setTestConversationId(String? conversationId) {
    _testConversationId = conversationId;
    notifyListeners();
  }

  // Template loading helper
  void _loadTemplateDefaults(String templateId) {
    final template = AgentTemplate.getById(templateId);
    if (template != null) {
      _agentName = template.name;
      _agentDescription = template.description;
      _agentRole = template.role;
      _systemPrompt = template.systemPrompt;
      _selectedApiProvider = template.defaultApiProvider;
      _selectedMCPServers = List.from(template.suggestedMCPServers);
      _modelParameters = Map.from(template.defaultModelParameters);
    }
  }

  // Validation
  bool isValid() {
    return _agentName.isNotEmpty &&
           _agentDescription.isNotEmpty &&
           _systemPrompt.isNotEmpty &&
           _selectedApiProvider.isNotEmpty;
  }

  bool isStepValid(int step) {
    switch (step) {
      case 0: // Agent Basics
        return _agentName.isNotEmpty && _agentDescription.isNotEmpty;
      case 1: // Intelligence Configuration
        return _systemPrompt.isNotEmpty && _selectedApiProvider.isNotEmpty;
      case 2: // MCP Server Selection
        return true; // MCP servers are optional
      case 3: // Advanced Configuration
        return true; // Advanced settings are optional
      case 4: // Deploy & Test
        return isValid();
      default:
        return false;
    }
  }

  // Build final agent configuration
  Future<Map<String, dynamic>> buildAgentConfig() async {
    final agentId = _generateAgentId();
    
    // Generate complete system prompt with MCP integration context
    final completeSystemPrompt = AgentSystemPromptService.getCompleteSystemPrompt(
      baseSystemPrompt: _systemPrompt,
      agentId: agentId,
      mcpServers: _selectedMCPServers,
      mcpServerConfigs: _mcpServerConfigs,
      contextDocuments: _contextDocuments,
      environmentTokens: _environmentVariables.map((k, v) => MapEntry(k, v.toString())),
    );
    
    return {
      'id': agentId,
      'name': _agentName,
      'description': _agentDescription,
      'role': _agentRole,
      'systemPrompt': completeSystemPrompt, // Enhanced with MCP identity and context
      'baseSystemPrompt': _systemPrompt, // Keep original for reference
      'apiProvider': _selectedApiProvider,
      'modelParameters': _modelParameters,
      'mcpServers': _selectedMCPServers,
      'mcpServerConfigs': _mcpServerConfigs,
      'environmentVariables': _environmentVariables,
      'contextDocuments': _contextDocuments,
      'advancedSettings': _advancedSettings,
      'created': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  // Export to agent editor format
  Map<String, dynamic> toAgentConfig() {
    return {
      'name': _agentName,
      'description': _agentDescription,
      'role': _agentRole,
      'systemPrompt': _systemPrompt,
      'apiProvider': _selectedApiProvider,
      'modelParameters': _modelParameters,
      'mcpServers': _selectedMCPServers,
      'mcpServerConfigs': _mcpServerConfigs,
      'environmentVariables': _environmentVariables,
      'contextDocuments': _contextDocuments,
      'advancedSettings': _advancedSettings,
    };
  }

  // Import from existing agent configuration
  void fromAgentConfig(Map<String, dynamic> config) {
    _agentName = config['name'] ?? '';
    _agentDescription = config['description'] ?? '';
    _agentRole = config['role'] ?? '';
    _systemPrompt = config['systemPrompt'] ?? '';
    _selectedApiProvider = config['apiProvider'] ?? '';
    _modelParameters = Map<String, dynamic>.from(config['modelParameters'] ?? {});
    _selectedMCPServers = List<String>.from(config['mcpServers'] ?? []);
    _mcpServerConfigs = Map<String, Map<String, String>>.from(
      (config['mcpServerConfigs'] ?? {}).map(
        (key, value) => MapEntry(key, Map<String, String>.from(value))
      )
    );
    _environmentVariables = Map<String, String>.from(config['environmentVariables'] ?? {});
    _contextDocuments = List<String>.from(config['contextDocuments'] ?? []);
    _advancedSettings = Map<String, dynamic>.from(config['advancedSettings'] ?? {});
    notifyListeners();
  }

  // Reset wizard state
  void reset() {
    _agentName = '';
    _agentDescription = '';
    _agentRole = '';
    _selectedTemplate = null;
    _systemPrompt = '';
    _selectedApiProvider = '';
    _modelParameters.clear();
    _selectedMCPServers.clear();
    _mcpServerConfigs.clear();
    _environmentVariables.clear();
    _contextDocuments.clear();
    _advancedSettings.clear();
    _isValidated = false;
    _testConversationId = null;
    notifyListeners();
  }

  String _generateAgentId() {
    // Generate a unique ID based on name and timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nameHash = _agentName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
    return '$nameHash-$timestamp';
  }
}

/// Agent template definitions for quick setup
class AgentTemplate {
  final String id;
  final String name;
  final String description;
  final String role;
  final String systemPrompt;
  final String defaultApiProvider;
  final List<String> suggestedMCPServers;
  final Map<String, dynamic> defaultModelParameters;
  final String category;

  const AgentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.role,
    required this.systemPrompt,
    required this.defaultApiProvider,
    this.suggestedMCPServers = const [],
    this.defaultModelParameters = const {},
    this.category = 'General',
  });

  static AgentTemplate? getById(String id) {
    return _templates.firstWhere((template) => template.id == id);
  }

  static List<AgentTemplate> getByCategory(String category) {
    return _templates.where((template) => template.category == category).toList();
  }

  static List<AgentTemplate> get allTemplates => List.unmodifiable(_templates);

  static List<String> get categories => 
      _templates.map((t) => t.category).toSet().toList();

  static const List<AgentTemplate> _templates = [
    // Development templates
    AgentTemplate(
      id: 'senior-developer',
      name: 'Senior Developer',
      description: 'Full-stack development with best practices',
      role: 'Senior Software Developer',
      category: 'Development',
      systemPrompt: '''You are a senior software developer with expertise across the full stack. You write clean, maintainable code following best practices. You have access to filesystem tools for reading/writing code, version control for Git operations, and development tools for testing and building applications.

Key responsibilities:
- Write high-quality, well-tested code
- Follow established coding standards and patterns
- Provide thoughtful code reviews and suggestions
- Help with architecture and system design decisions
- Debug complex technical issues

When coding, always consider:
- Code readability and maintainability
- Performance implications
- Security best practices
- Testing strategies
- Documentation needs''',
      defaultApiProvider: 'Default API Model',
      suggestedMCPServers: ['filesystem', 'git', 'memory'],
      defaultModelParameters: {'temperature': 0.3, 'maxTokens': 4000},
    ),

    AgentTemplate(
      id: 'devops-engineer',
      name: 'DevOps Engineer',
      description: 'Infrastructure automation and deployment',
      role: 'DevOps Engineer',
      category: 'Development',
      systemPrompt: '''You are a DevOps engineer specializing in infrastructure automation, CI/CD, and cloud deployments. You have access to filesystem tools for managing configuration files, and various infrastructure tools for deployment and monitoring.

Key responsibilities:
- Design and implement CI/CD pipelines
- Manage cloud infrastructure and deployments
- Automate operational tasks and monitoring
- Ensure system reliability and scalability
- Implement security best practices for infrastructure

Focus areas:
- Docker and containerization
- Kubernetes orchestration
- Cloud platforms (AWS, Azure, GCP)
- Infrastructure as Code (Terraform, CloudFormation)
- Monitoring and observability
- Security and compliance''',
      defaultApiProvider: 'Default API Model',
      suggestedMCPServers: ['filesystem', 'memory', 'http'],
      defaultModelParameters: {'temperature': 0.2, 'maxTokens': 3000},
    ),

    // Business templates
    AgentTemplate(
      id: 'product-manager',
      name: 'Product Manager',
      description: 'Product strategy and user-focused development',
      role: 'Product Manager',
      category: 'Business',
      systemPrompt: '''You are a product manager focused on building user-centered products that solve real problems. You have access to analytics tools for understanding user behavior, project management tools for tracking progress, and communication tools for stakeholder alignment.

Key responsibilities:
- Define product vision and strategy
- Gather and prioritize user requirements
- Create detailed user stories and acceptance criteria
- Coordinate cross-functional teams
- Track product metrics and success indicators

Your approach:
- Always start with user needs and problems
- Use data to inform product decisions
- Communicate clearly with both technical and non-technical stakeholders
- Balance business goals with technical constraints
- Focus on delivering value incrementally''',
      defaultApiProvider: 'Default API Model',
      suggestedMCPServers: ['memory', 'http'],
      defaultModelParameters: {'temperature': 0.4, 'maxTokens': 3500},
    ),

    AgentTemplate(
      id: 'marketing-analyst',
      name: 'Marketing Analyst',
      description: 'Data-driven marketing insights and optimization',
      role: 'Marketing Analyst',
      category: 'Business',
      systemPrompt: '''You are a marketing analyst who uses data to drive marketing strategy and optimization. You excel at interpreting marketing metrics, identifying trends, and providing actionable insights for campaign improvement.

Key responsibilities:
- Analyze marketing campaign performance
- Identify audience segments and behaviors
- Provide recommendations for optimization
- Create reports and dashboards for stakeholders
- Track ROI and conversion metrics

Your analytical approach:
- Focus on actionable insights from data
- Consider multiple attribution models
- Segment analysis for targeted strategies
- A/B testing and experimentation
- Competitive landscape analysis''',
      defaultApiProvider: 'Default API Model',
      suggestedMCPServers: ['memory', 'http'],
      defaultModelParameters: {'temperature': 0.3, 'maxTokens': 3000},
    ),

    // Research templates
    AgentTemplate(
      id: 'research-assistant',
      name: 'Research Assistant',
      description: 'Comprehensive research and analysis',
      role: 'Research Assistant',
      category: 'Research',
      systemPrompt: '''You are a research assistant who excels at gathering, analyzing, and synthesizing information from multiple sources. You provide thorough, well-cited research with critical analysis and actionable insights.

Key responsibilities:
- Conduct comprehensive research on complex topics
- Analyze and synthesize information from multiple sources
- Provide critical evaluation of evidence and claims
- Create well-structured research summaries
- Suggest additional research directions

Research methodology:
- Use diverse and credible sources
- Apply critical thinking to evaluate information quality
- Provide proper citations and references
- Present findings in clear, structured formats
- Identify gaps and limitations in available research''',
      defaultApiProvider: 'Default API Model',
      suggestedMCPServers: ['memory', 'http'],
      defaultModelParameters: {'temperature': 0.2, 'maxTokens': 4000},
    ),

    // Creative templates
    AgentTemplate(
      id: 'creative-writer',
      name: 'Creative Writer',
      description: 'Engaging content creation and storytelling',
      role: 'Creative Writer',
      category: 'Creative',
      systemPrompt: '''You are a creative writer who crafts engaging, original content across various formats and genres. You excel at storytelling, maintaining consistent voice and tone, and adapting your writing style to different audiences and purposes.

Key responsibilities:
- Create original, engaging content
- Maintain consistent voice and brand tone
- Adapt writing style for different audiences
- Develop compelling narratives and storylines
- Edit and refine content for maximum impact

Writing approach:
- Focus on clear, engaging communication
- Use storytelling techniques to connect with readers
- Consider audience needs and preferences
- Balance creativity with strategic objectives
- Incorporate feedback and iterate on content''',
      defaultApiProvider: 'Default API Model',
      suggestedMCPServers: ['memory', 'filesystem'],
      defaultModelParameters: {'temperature': 0.7, 'maxTokens': 4000},
    ),
  ];
}