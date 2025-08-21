import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedTab = 'api';
  
  // API Settings
  String selectedProvider = 'Anthropic';
  String selectedModel = 'claude-3-5-sonnet-20241022';
  final TextEditingController apiKeyController = TextEditingController();
  double temperature = 0.7;
  int maxTokens = 2048;
  bool isConnected = false;
  bool isLoading = false;

  // Agent Management
  String selectedAgent = 'Research Assistant';
  String selectedTemplate = 'Default';
  final TextEditingController systemPromptController = TextEditingController();

  // API Key Management
  List<ApiKeyConfig> savedApiKeys = [
    ApiKeyConfig(
      id: 'anthropic-1',
      name: 'Anthropic Production',
      provider: 'Anthropic',
      model: 'claude-3-5-sonnet-20241022',
      isDefault: true,
      isConfigured: true,
    ),
    ApiKeyConfig(
      id: 'openai-1',
      name: 'OpenAI GPT-4o',
      provider: 'OpenAI',
      model: 'gpt-4o',
      isDefault: false,
      isConfigured: false,
    ),
  ];

  // Agent API Assignments
  Map<String, String> agentApiAssignments = {
    'Research Assistant': 'anthropic-1',
    'Code Reviewer': 'anthropic-1',
    'Content Writer': 'openai-1',
    'Data Analyst': 'anthropic-1',
  };

  final List<String> providers = ['Anthropic', 'OpenAI', 'Google', 'Azure OpenAI', 'xAI'];
  final Map<String, List<String>> providerModels = {
    'Anthropic': [
      'claude-3-5-sonnet-20241022',
      'claude-3-5-sonnet-20240620', 
      'claude-3-5-haiku-20241022',
      'claude-3-opus-20240229',
      'claude-3-sonnet-20240229',
      'claude-3-haiku-20240307'
    ],
    'OpenAI': [
      'gpt-4o',
      'gpt-4o-mini', 
      'gpt-4-turbo',
      'gpt-4-turbo-preview',
      'gpt-4',
      'gpt-3.5-turbo',
      'o1-preview',
      'o1-mini'
    ],
    'Google': [
      'gemini-1.5-pro',
      'gemini-1.5-flash',
      'gemini-1.0-pro',
      'gemini-pro-vision'
    ],
    'Azure OpenAI': [
      'gpt-4o',
      'gpt-4-turbo',
      'gpt-4',
      'gpt-35-turbo'
    ],
    'xAI': [
      'grok-beta'
    ],
  };

  final List<AgentItem> agents = [
    AgentItem(
      id: 'research-assistant',
      name: 'Research Assistant',
      description: 'Academic research agent with citation management',
      category: 'Research',
      isActive: true,
      lastUsed: DateTime.now().subtract(const Duration(minutes: 15)),
      totalChats: 23,
      mcpServers: ['Brave Search', 'Memory', 'Files'],
      systemPrompt: 'You are a research assistant specialized in academic research and citation management. Always provide well-sourced information and maintain academic standards.',
      templates: ['Default', 'Academic Papers', 'Literature Review', 'Data Analysis'],
    ),
    AgentItem(
      id: 'code-reviewer',
      name: 'Code Reviewer',
      description: 'Automated code review with best practices',
      category: 'Development',
      isActive: true,
      lastUsed: DateTime.now().subtract(const Duration(hours: 2)),
      totalChats: 8,
      mcpServers: ['GitHub', 'Git', 'Files'],
      systemPrompt: 'You are a senior software engineer specializing in code review. Focus on code quality, security, performance, and best practices.',
      templates: ['Default', 'Security Review', 'Performance Audit', 'Clean Code'],
    ),
    AgentItem(
      id: 'content-writer',
      name: 'Content Writer',
      description: 'SEO-optimized content generation',
      category: 'Writing',
      isActive: false,
      lastUsed: DateTime.now().subtract(const Duration(days: 1)),
      totalChats: 15,
      mcpServers: ['Brave Search', 'Files'],
      systemPrompt: 'You are a professional content writer specializing in SEO-optimized content. Create engaging, informative, and search-friendly content.',
      templates: ['Default', 'Blog Posts', 'Marketing Copy', 'Technical Writing'],
    ),
    AgentItem(
      id: 'data-analyst',
      name: 'Data Analyst',
      description: 'Statistical analysis and visualization',
      category: 'Data Analysis',
      isActive: true,
      lastUsed: DateTime.now().subtract(const Duration(hours: 6)),
      totalChats: 12,
      mcpServers: ['Postgres', 'Files', 'Memory'],
      systemPrompt: 'You are a data analyst expert in statistical analysis and data visualization. Provide clear insights and actionable recommendations.',
      templates: ['Default', 'Statistical Reports', 'Data Visualization', 'Predictive Analysis'],
    ),
  ];

  final Map<String, Map<String, String>> agentTemplatePrompts = {
    'Research Assistant': {
      'Default': 'You are a research assistant specialized in academic research and citation management. Always provide well-sourced information and maintain academic standards.',
      'Academic Papers': 'You are a research assistant focused on academic paper analysis. Help with literature reviews, methodology evaluation, and citation formatting following academic standards.',
      'Literature Review': 'You are a research assistant specialized in conducting comprehensive literature reviews. Synthesize information from multiple sources and identify research gaps.',
      'Data Analysis': 'You are a research assistant focused on data analysis and interpretation. Help with statistical analysis, data visualization, and drawing meaningful conclusions.',
    },
    'Code Reviewer': {
      'Default': 'You are a senior software engineer specializing in code review. Focus on code quality, security, performance, and best practices.',
      'Security Review': 'You are a security-focused code reviewer. Identify potential vulnerabilities, security anti-patterns, and suggest secure coding practices.',
      'Performance Audit': 'You are a performance-focused code reviewer. Analyze code for efficiency, scalability issues, and optimization opportunities.',
      'Clean Code': 'You are a code quality expert focused on clean code principles. Review for readability, maintainability, and adherence to coding standards.',
    },
    'Content Writer': {
      'Default': 'You are a professional content writer specializing in SEO-optimized content. Create engaging, informative, and search-friendly content.',
      'Blog Posts': 'You are a blog content specialist. Create engaging, informative blog posts with strong headlines, clear structure, and compelling calls-to-action.',
      'Marketing Copy': 'You are a marketing copywriter. Create persuasive, conversion-focused content that drives action and engages target audiences.',
      'Technical Writing': 'You are a technical writer. Create clear, accurate documentation and instructional content for technical audiences.',
    },
    'Data Analyst': {
      'Default': 'You are a data analyst expert in statistical analysis and data visualization. Provide clear insights and actionable recommendations.',
      'Statistical Reports': 'You are a statistical analyst focused on creating comprehensive reports. Present findings clearly with appropriate statistical methods and interpretations.',
      'Data Visualization': 'You are a data visualization expert. Help create compelling charts, graphs, and visual representations of data insights.',
      'Predictive Analysis': 'You are a predictive analytics specialist. Use statistical models and machine learning approaches to forecast trends and outcomes.',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    selectedModel = providerModels[selectedProvider]!.first;
    _loadSystemPrompt();
  }

  @override
  void dispose() {
    _tabController.dispose();
    apiKeyController.dispose();
    systemPromptController.dispose();
    super.dispose();
  }

  void _loadSystemPrompt() {
    final prompt = agentTemplatePrompts[selectedAgent]?[selectedTemplate] ?? '';
    systemPromptController.text = prompt;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeServiceProvider);
    final themeService = ref.read(themeServiceProvider.notifier);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SemanticColors.backgroundGradientStart,
              SemanticColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              const AppNavigationBar(currentRoute: AppRoutes.settings),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back navigation
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.chat),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: 16,
                              color: AppTheme.lightMutedForeground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Back to Chat',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 14,
                                color: AppTheme.lightMutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Page Title
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightForeground,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Tab Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.lightBorder.withOpacity(0.5)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'API Configuration'),
                            Tab(text: 'Agent Management'),
                            Tab(text: 'General Settings'),
                          ],
                          labelColor: AppTheme.lightPrimary,
                          unselectedLabelColor: AppTheme.lightMutedForeground,
                          labelStyle: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          indicator: BoxDecoration(
                            color: AppTheme.lightPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          indicatorPadding: const EdgeInsets.all(4),
                          dividerColor: Colors.transparent,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Tab View Content
                      SizedBox(
                        height: 600,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAPIConfigurationTab(),
                            _buildAgentManagementTab(),
                            _buildGeneralSettingsTab(themeService),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _testConnection() async {
    if (apiKeyController.text.trim().isEmpty) {
      _showMessage('Please enter an API key first', isError: true);
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Simulate API test
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoading = false;
      isConnected = true;
    });

    _showMessage('Connection successful!');
  }

  Widget _buildAPIConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Saved API Keys Section
              _SettingsSection(
                title: 'Saved API Keys',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage your API keys for different providers and models.',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 14,
                        color: AppTheme.lightMutedForeground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // API Keys List
                    ...savedApiKeys.map((apiConfig) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: apiConfig.isDefault 
                                ? AppTheme.lightPrimary.withOpacity(0.3)
                                : AppTheme.lightBorder.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Status Icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: apiConfig.isConfigured 
                                    ? SemanticColors.success.withOpacity(0.1)
                                    : SemanticColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: apiConfig.isConfigured 
                                      ? SemanticColors.success.withOpacity(0.3)
                                      : SemanticColors.error.withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                apiConfig.isConfigured ? Icons.check_circle : Icons.error,
                                color: apiConfig.isConfigured ? SemanticColors.success : SemanticColors.error,
                                size: 20,
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // API Key Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        apiConfig.name,
                                        style: TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.lightForeground,
                                        ),
                                      ),
                                      if (apiConfig.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.lightPrimary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppTheme.lightPrimary.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            'DEFAULT',
                                            style: TextStyle(
                                              fontFamily: 'Space Grotesk',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.lightPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${apiConfig.provider} - ${apiConfig.model}',
                                    style: TextStyle(
                                      fontFamily: 'Space Grotesk',
                                      fontSize: 14,
                                      color: AppTheme.lightMutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!apiConfig.isDefault)
                                  GestureDetector(
                                    onTap: () => _setAsDefault(apiConfig.id),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightPrimary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppTheme.lightPrimary.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        'Set Default',
                                        style: TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.lightPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _editApiKey(apiConfig),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: SemanticColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: SemanticColors.primary.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: SemanticColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _deleteApiKey(apiConfig.id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: SemanticColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: SemanticColors.error.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: SemanticColors.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    
                    const SizedBox(height: 16),
                    
                    // Add New API Key Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightBorder, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        onPressed: _showAddApiKeyDialog,
                        icon: Icon(Icons.add, color: AppTheme.lightPrimary),
                        label: Text(
                          'Add New API Key',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.lightPrimary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Security Section
              _SettingsSection(
                title: 'Security',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SemanticColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SemanticColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: 20,
                        color: SemanticColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your API keys are stored locally and encrypted. They are never transmitted to our servers.',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 13,
                            color: AppTheme.lightForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgentManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Agent Selection Section
              _SettingsSection(
                title: 'Agent Configuration',
                child: Column(
                  children: [
                    _ResponsiveRow(
                      children: [
                        _FormField(
                          label: 'Select Agent',
                          child: _CustomDropdown(
                            value: selectedAgent,
                            items: agents.map((agent) => agent.name).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedAgent = value!;
                                selectedTemplate = agents.firstWhere((a) => a.name == selectedAgent).templates.first;
                                _loadSystemPrompt();
                              });
                            },
                          ),
                        ),
                        
                        _FormField(
                          label: 'Template Variation',
                          child: _CustomDropdown(
                            value: selectedTemplate,
                            items: agents.firstWhere((a) => a.name == selectedAgent).templates,
                            onChanged: (value) {
                              setState(() {
                                selectedTemplate = value!;
                                _loadSystemPrompt();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                
                const SizedBox(height: 24),
                
                // Agent Info Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.lightBorder.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: agents.firstWhere((a) => a.name == selectedAgent).isActive 
                                  ? SemanticColors.success : AppTheme.lightMutedForeground,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              agents.firstWhere((a) => a.name == selectedAgent).description,
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 14,
                                color: AppTheme.lightForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // API Assignment Display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.lightBorder.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.api,
                              size: 16,
                              color: AppTheme.lightMutedForeground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'API:',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.lightMutedForeground,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _getApiAssignmentWidget(),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _showApiSelectionDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.lightPrimary.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Change',
                                  style: TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.lightPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // MCP Servers
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: agents.firstWhere((a) => a.name == selectedAgent).mcpServers.map((server) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.lightPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.lightPrimary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              server,
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.lightPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // System Prompt Editor
          _SettingsSection(
            title: 'System Prompt',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template: $selectedTemplate',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightMutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.lightBorder),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(0.8),
                  ),
                  child: TextField(
                    controller: systemPromptController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Enter system prompt for this agent template...',
                      hintStyle: TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: AppTheme.lightMutedForeground,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 14,
                      color: AppTheme.lightForeground,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextButton(
                        onPressed: _loadSystemPrompt,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          foregroundColor: AppTheme.lightForeground,
                        ),
                        child: Text(
                          'Reset to Default',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lightPrimary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextButton(
                        onPressed: _saveAgentPrompt,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          foregroundColor: AppTheme.lightPrimaryForeground,
                        ),
                        child: Text(
                          'Save Prompt',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSettingsTab(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
        children: [
          _SettingsSection(
            title: 'Application Settings',
            child: Column(
              children: [
                _FormField(
                  label: 'Theme',
                  child: Consumer(
                    builder: (context, ref, child) {
                      final currentThemeMode = ref.watch(themeServiceProvider);
                      final currentThemeName = currentThemeMode == ThemeMode.light ? 'Banana Pudding' : 'Midnight Mocha';
                      
                      return _CustomDropdown(
                        value: currentThemeName,
                        items: const ['Banana Pudding', 'Midnight Mocha'],
                        onChanged: (value) {
                          if (value == 'Banana Pudding') {
                            themeService.setTheme(ThemeMode.light);
                          } else if (value == 'Midnight Mocha') {
                            themeService.setTheme(ThemeMode.dark);
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.notifications,
                      size: 20,
                      color: AppTheme.lightMutedForeground,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enable notifications',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 14,
                          color: AppTheme.lightForeground,
                        ),
                      ),
                    ),
                    Switch(
                      value: true,
                      onChanged: (value) {},
                      activeColor: AppTheme.lightPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _SettingsSection(
            title: 'About',
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info,
                      size: 20,
                      color: AppTheme.lightMutedForeground,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 14,
                        color: AppTheme.lightForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveSettings() {
    _showMessage('Settings saved successfully!');
  }

  void _saveAgentPrompt() {
    // Save the system prompt for the selected agent/template
    agentTemplatePrompts[selectedAgent]![selectedTemplate] = systemPromptController.text;
    _showMessage('Agent prompt saved successfully!');
  }

  Widget _getApiAssignmentWidget() {
    final assignedApiId = agentApiAssignments[selectedAgent];
    if (assignedApiId == null) {
      return GestureDetector(
        onTap: () {
          // Navigate to API settings tab
          _tabController.animateTo(0);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning,
                size: 12,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                'Not Configured',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final apiConfig = savedApiKeys.firstWhere((key) => key.id == assignedApiId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: apiConfig.isConfigured 
            ? SemanticColors.success.withOpacity(0.1) 
            : SemanticColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: apiConfig.isConfigured 
              ? SemanticColors.success.withOpacity(0.3) 
              : SemanticColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            apiConfig.isConfigured ? Icons.check_circle : Icons.error,
            size: 12,
            color: apiConfig.isConfigured ? SemanticColors.success : SemanticColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            '${apiConfig.provider} (${apiConfig.model})',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: apiConfig.isConfigured ? SemanticColors.success : SemanticColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _showApiSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.lightBorder.withOpacity(0.5)),
        ),
        title: Text(
          'Select API for ${selectedAgent}',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightForeground,
          ),
        ),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...savedApiKeys.map((apiConfig) {
                final isSelected = agentApiAssignments[selectedAgent] == apiConfig.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.lightPrimary.withOpacity(0.05)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.lightPrimary.withOpacity(0.3)
                          : AppTheme.lightBorder.withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: apiConfig.isConfigured 
                            ? SemanticColors.success.withOpacity(0.1)
                            : SemanticColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: apiConfig.isConfigured 
                              ? SemanticColors.success.withOpacity(0.3)
                              : SemanticColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        apiConfig.isConfigured ? Icons.check_circle : Icons.error,
                        color: apiConfig.isConfigured ? SemanticColors.success : SemanticColors.error,
                        size: 16,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          apiConfig.name,
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w500,
                            color: AppTheme.lightForeground,
                          ),
                        ),
                        if (apiConfig.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.lightPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.lightPrimary.withOpacity(0.3)),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.lightPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${apiConfig.provider} - ${apiConfig.model}',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        color: AppTheme.lightMutedForeground,
                      ),
                    ),
                    trailing: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppTheme.lightPrimary : AppTheme.lightMutedForeground,
                          width: 2,
                        ),
                        color: isSelected ? AppTheme.lightPrimary : Colors.transparent,
                      ),
                      child: isSelected 
                          ? Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    onTap: () {
                      setState(() {
                        agentApiAssignments[selectedAgent] = apiConfig.id;
                      });
                      Navigator.pop(context);
                      _showMessage('API assignment updated for $selectedAgent');
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.lightBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _tabController.animateTo(0); // Go to API Configuration tab
                  },
                  icon: Icon(Icons.add, color: AppTheme.lightPrimary),
                  label: Text(
                    'Add New API Configuration',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      color: AppTheme.lightPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.lightBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                foregroundColor: AppTheme.lightForeground,
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(String apiId) {
    setState(() {
      // Remove default from all keys
      savedApiKeys = savedApiKeys.map((key) => ApiKeyConfig(
        id: key.id,
        name: key.name,
        provider: key.provider,
        model: key.model,
        isDefault: key.id == apiId,
        isConfigured: key.isConfigured,
      )).toList();
    });
    _showMessage('Default API key updated successfully!');
  }

  void _deleteApiKey(String apiId) {
    // Prevent deleting the default API key
    final apiToDelete = savedApiKeys.firstWhere((key) => key.id == apiId);
    if (apiToDelete.isDefault) {
      _showMessage('Cannot delete the default API key. Set another key as default first.', isError: true);
      return;
    }

    setState(() {
      savedApiKeys.removeWhere((key) => key.id == apiId);
      // Remove assignments for this API key
      agentApiAssignments.removeWhere((agent, assignedApiId) => assignedApiId == apiId);
    });
    _showMessage('API key deleted successfully!');
  }

  void _editApiKey(ApiKeyConfig apiConfig) {
    _showAddApiKeyDialog(editingConfig: apiConfig);
  }

  void _showAddApiKeyDialog({ApiKeyConfig? editingConfig}) {
    final isEditing = editingConfig != null;
    String nameValue = editingConfig?.name ?? '';
    String providerValue = editingConfig?.provider ?? 'Anthropic';
    String modelValue = editingConfig?.model ?? providerModels['Anthropic']!.first;
    String apiKeyValue = '';
    double tempValue = 0.7;
    int maxTokensValue = 2048;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.lightBorder.withOpacity(0.5)),
          ),
          title: Text(
            isEditing ? 'Edit API Configuration' : 'Add New API Configuration',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightForeground,
            ),
          ),
          content: Container(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name field
                  _FormField(
                    label: 'Configuration Name',
                    helpText: 'A friendly name for this API configuration',
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightBorder),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withOpacity(0.8),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'e.g., "Production Claude", "GPT-4 Testing"',
                          hintStyle: TextStyle(
                            fontFamily: 'Space Grotesk',
                            color: AppTheme.lightMutedForeground,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          color: AppTheme.lightForeground,
                        ),
                        onChanged: (value) => nameValue = value,
                        controller: TextEditingController(text: nameValue),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Provider and Model row
                  Row(
                    children: [
                      Expanded(
                        child: _FormField(
                          label: 'Provider',
                          child: _CustomDropdown(
                            value: providerValue,
                            items: providers,
                            onChanged: (value) {
                              setDialogState(() {
                                providerValue = value!;
                                modelValue = providerModels[providerValue]!.first;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FormField(
                          label: 'Model',
                          child: _CustomDropdown(
                            value: modelValue,
                            items: providerModels[providerValue]!,
                            onChanged: (value) {
                              setDialogState(() {
                                modelValue = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // API Key field
                  _FormField(
                    label: 'API Key',
                    helpText: 'Your API key is stored locally and encrypted',
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightBorder),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withOpacity(0.8),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter your API key',
                          hintStyle: TextStyle(
                            fontFamily: 'Space Grotesk',
                            color: AppTheme.lightMutedForeground,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          color: AppTheme.lightForeground,
                        ),
                        obscureText: true,
                        onChanged: (value) => apiKeyValue = value,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Temperature and Max Tokens row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _FormField(
                          label: 'Creativity Level',
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.lightBorder),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white.withOpacity(0.8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Focused',
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 12,
                                        color: AppTheme.lightMutedForeground,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightPrimary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tempValue.toStringAsFixed(2),
                                        style: TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.lightPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Creative',
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 12,
                                        color: AppTheme.lightMutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: AppTheme.lightPrimary,
                                    inactiveTrackColor: AppTheme.lightBorder,
                                    thumbColor: AppTheme.lightPrimary,
                                    overlayColor: AppTheme.lightPrimary.withOpacity(0.1),
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: tempValue,
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 20,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        tempValue = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FormField(
                          label: 'Response Length',
                          helpText: 'Default: 2048 tokens',
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.lightBorder),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white.withOpacity(0.8),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '2048 (Default)',
                                hintStyle: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  color: AppTheme.lightMutedForeground,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                color: AppTheme.lightForeground,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                maxTokensValue = int.tryParse(value) ?? 2048;
                              },
                              controller: TextEditingController(text: maxTokensValue == 2048 ? '' : maxTokensValue.toString()),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.lightBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  foregroundColor: AppTheme.lightForeground,
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.lightPrimary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextButton(
                onPressed: () {
                  if (nameValue.trim().isEmpty || apiKeyValue.trim().isEmpty) {
                    _showMessage('Please fill in all required fields', isError: true);
                    return;
                  }

                  final newId = isEditing ? editingConfig!.id : 'api_${DateTime.now().millisecondsSinceEpoch}';
                  final newConfig = ApiKeyConfig(
                    id: newId,
                    name: nameValue.trim(),
                    provider: providerValue,
                    model: modelValue,
                    isDefault: isEditing ? editingConfig!.isDefault : savedApiKeys.isEmpty,
                    isConfigured: true,
                  );

                  setState(() {
                    if (isEditing) {
                      final index = savedApiKeys.indexWhere((key) => key.id == editingConfig!.id);
                      savedApiKeys[index] = newConfig;
                    } else {
                      savedApiKeys.add(newConfig);
                    }
                  });

                  Navigator.pop(context);
                  _showMessage(isEditing ? 'API configuration updated successfully!' : 'API configuration added successfully!');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  foregroundColor: AppTheme.lightPrimaryForeground,
                ),
                child: Text(
                  isEditing ? 'Update Configuration' : 'Add Configuration',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Space Grotesk'),
        ),
        backgroundColor: isError ? SemanticColors.error : SemanticColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}


class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightForeground,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? helpText;

  const _FormField({
    required this.label,
    required this.child,
    this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightForeground,
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            helpText!,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 12,
              color: AppTheme.lightMutedForeground,
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _CustomDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _CustomDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.lightBorder),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withOpacity(0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.lightMutedForeground,
            size: 20,
          ),
          onChanged: onChanged,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 14,
            color: AppTheme.lightForeground,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          elevation: 8,
          menuMaxHeight: 300,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  item,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 14,
                    color: AppTheme.lightForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Responsive row component that stacks vertically on smaller screens
class _ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  static const double breakpoint = 899;
  static const double spacing = 24;

  const _ResponsiveRow({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= breakpoint) {
          // Stack vertically on smaller screens
          return Column(
            children: children.map((child) {
              final index = children.indexOf(child);
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(
                  bottom: index < children.length - 1 ? spacing : 0,
                ),
                child: child,
              );
            }).toList(),
          );
        } else {
          // Display horizontally on larger screens - without Expanded for children
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children.map((child) {
                final index = children.indexOf(child);
                return Flexible(
                  flex: 1,
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < children.length - 1 ? spacing : 0,
                    ),
                    child: child,
                  ),
                );
              }).toList(),
            ),
          );
        }
      },
    );
  }
}

// API Key configuration class
class ApiKeyConfig {
  final String id;
  final String name;
  final String provider;
  final String model;
  final bool isDefault;
  final bool isConfigured;
  
  ApiKeyConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.model,
    required this.isDefault,
    required this.isConfigured,
  });
}

// Enhanced AgentItem class for settings management
class AgentItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final bool isActive;
  final DateTime lastUsed;
  final int totalChats;
  final List<String> mcpServers;
  final String systemPrompt;
  final List<String> templates;

  AgentItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isActive,
    required this.lastUsed,
    required this.totalChats,
    required this.mcpServers,
    required this.systemPrompt,
    required this.templates,
  });
}