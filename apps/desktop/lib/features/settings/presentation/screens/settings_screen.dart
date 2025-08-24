import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
 lastUsed: DateTime.now().subtract(Duration(minutes: 15)),
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
 lastUsed: DateTime.now().subtract(Duration(hours: 2)),
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
 _tabController = TabController(length: 4, vsync: this);
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
 decoration: BoxDecoration(
 gradient: RadialGradient(
 center: Alignment.topCenter,
 radius: 1.5,
 colors: [
 ThemeColors(context).backgroundGradientStart,
 ThemeColors(context).backgroundGradientMiddle,
 ThemeColors(context).backgroundGradientEnd,
 ],
 stops: const [0.0, 0.6, 1.0],
 ),
 ),
 child: SafeArea(
 child: Column(
 children: [
 // Header
 AppNavigationBar(currentRoute: AppRoutes.settings),
 
 // Main Content
 Expanded(
 child: SingleChildScrollView(
 padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
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
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: SpacingTokens.iconSpacing),
 Text(
 'Back to Chat',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 
 SizedBox(height: SpacingTokens.sectionSpacing),
 
 // Page Title and Tab Bar (inline, compact)
 Row(
 children: [
 Text(
 'Settings',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 24,
 fontWeight: FontWeight.bold,
 color: Theme.of(context).colorScheme.onSurface,
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 
 // Tab Bar (inline)
 Expanded(
 child: Container(
 decoration: BoxDecoration(
 color: ThemeColors(context).surface.withValues(alpha: 0.8),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: ThemeColors(context).border.withValues(alpha: 0.5)),
 ),
 child: TabBar(
 controller: _tabController,
 tabs: const [
 Tab(text: 'API Configuration'),
 Tab(text: 'Agent Management'),
 Tab(text: 'Integrations'),
 Tab(text: 'General Settings'),
 ],
 labelColor: Theme.of(context).colorScheme.primary,
 unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
 color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(8),
 ),
 indicatorPadding: EdgeInsets.all(4),
 dividerColor: Colors.transparent,
 ),
 ),
 ),
 ],
 ),
 
 SizedBox(height: SpacingTokens.xs),
 
 // Tab View Content (expanded height)
 SizedBox(
 height: 680,
 child: TabBarView(
 controller: _tabController,
 children: [
 _buildAPIConfigurationTab(),
 _buildAgentManagementTab(),
 _buildIntegrationsTab(),
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
 constraints: BoxConstraints(maxWidth: 1200),
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
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // API Keys List
 ...savedApiKeys.map((apiConfig) {
 return Container(
 margin: const EdgeInsets.only(bottom: 12),
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: ThemeColors(context).surface.withValues(alpha: 0.9),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(
 color: apiConfig.isDefault 
 ? ThemeColors(context).primary.withValues(alpha: 0.3)
 : ThemeColors(context).border.withValues(alpha: 0.5),
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
 ? ThemeColors(context).success.withValues(alpha: 0.1)
 : ThemeColors(context).error.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(
 color: apiConfig.isConfigured 
 ? ThemeColors(context).success.withValues(alpha: 0.3)
 : ThemeColors(context).error.withValues(alpha: 0.3),
 ),
 ),
 child: Icon(
 apiConfig.isConfigured ? Icons.check_circle : Icons.error,
 color: apiConfig.isConfigured ? ThemeColors(context).success : ThemeColors(context).error,
 size: 20,
 ),
 ),
 
 SizedBox(width: 16),
 
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
 color: Theme.of(context).colorScheme.onSurface,
 ),
 ),
 if (apiConfig.isDefault) ...[
 SizedBox(width: SpacingTokens.iconSpacing),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
 ),
 child: Text(
 'DEFAULT',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 fontWeight: FontWeight.w600,
 color: Theme.of(context).colorScheme.primary,
 ),
 ),
 ),
 ],
 ],
 ),
 SizedBox(height: 4),
 Text(
 '${apiConfig.provider} - ${apiConfig.model}',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 color: Theme.of(context).colorScheme.onSurfaceVariant,
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
 color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
 ),
 child: Text(
 'Set Default',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 fontWeight: FontWeight.w500,
 color: Theme.of(context).colorScheme.primary,
 ),
 ),
 ),
 ),
 SizedBox(width: SpacingTokens.iconSpacing),
 GestureDetector(
 onTap: () => _editApiKey(apiConfig),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3)),
 ),
 child: Text(
 'Edit',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 fontWeight: FontWeight.w500,
 color: ThemeColors(context).primary,
 ),
 ),
 ),
 ),
 SizedBox(width: SpacingTokens.iconSpacing),
 GestureDetector(
 onTap: () => _deleteApiKey(apiConfig.id),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: ThemeColors(context).error.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(color: ThemeColors(context).error.withValues(alpha: 0.3)),
 ),
 child: Text(
 'Delete',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 fontWeight: FontWeight.w500,
 color: ThemeColors(context).error,
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
 
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // Add New API Key Button
 SizedBox(
 width: double.infinity,
 child: AsmblButtonEnhanced.accent(
 text: 'Add New API Key',
 icon: Icons.add,
 onPressed: _showAddApiKeyDialog,
 size: AsmblButtonSize.medium,
 ),
 ),
 ],
 ),
 ),
 
 SizedBox(height: SpacingTokens.textSectionSpacing),
 
 // Security Section
 _SettingsSection(
 title: 'Security',
 child: Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3)),
 ),
 child: Row(
 children: [
 Icon(
 Icons.security,
 size: 20,
 color: ThemeColors(context).primary,
 ),
 SizedBox(width: 12),
 Expanded(
 child: Text(
 'Your API keys are stored locally and encrypted. They are never transmitted to our servers.',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 13,
 color: Theme.of(context).colorScheme.onSurface,
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
 constraints: BoxConstraints(maxWidth: 1200),
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
 child: AsmblStringDropdown(
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
 child: AsmblStringDropdown(
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
 
 SizedBox(height: 24),
 
 // Agent Info Display
 Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
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
 ? ThemeColors(context).success : Theme.of(context).colorScheme.onSurfaceVariant,
 shape: BoxShape.circle,
 ),
 ),
 SizedBox(width: 12),
 Expanded(
 child: Text(
 agents.firstWhere((a) => a.name == selectedAgent).description,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 color: Theme.of(context).colorScheme.onSurface,
 ),
 ),
 ),
 ],
 ),
 SizedBox(height: 12),
 
 // API Assignment Display
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: ThemeColors(context).surface.withValues(alpha: 0.8),
 borderRadius: BorderRadius.circular(6),
 border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
 ),
 child: Row(
 children: [
 Icon(
 Icons.api,
 size: 16,
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: SpacingTokens.iconSpacing),
 Text(
 'API:',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 12,
 fontWeight: FontWeight.w500,
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 ),
 SizedBox(width: SpacingTokens.iconSpacing),
 Expanded(
 child: _getApiAssignmentWidget(),
 ),
 SizedBox(width: SpacingTokens.iconSpacing),
 GestureDetector(
 onTap: _showApiSelectionDialog,
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
 ),
 child: Text(
 'Change',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 fontWeight: FontWeight.w500,
 color: Theme.of(context).colorScheme.primary,
 ),
 ),
 ),
 ),
 ],
 ),
 ),
 
 SizedBox(height: 12),
 
 // MCP Servers
 Wrap(
 spacing: 8,
 runSpacing: 8,
 children: agents.firstWhere((a) => a.name == selectedAgent).mcpServers.map((server) {
 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(
 color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
 width: 1,
 ),
 ),
 child: Text(
 server,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 fontWeight: FontWeight.w500,
 color: Theme.of(context).colorScheme.primary,
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
 
 SizedBox(height: 32),
 
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
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 ),
 SizedBox(height: 12),
 Container(
 decoration: BoxDecoration(
 border: Border.all(color: Theme.of(context).colorScheme.outline),
 borderRadius: BorderRadius.circular(8),
 color: ThemeColors(context).surface.withValues(alpha: 0.8),
 ),
 child: TextField(
 controller: systemPromptController,
 maxLines: 8,
 decoration: InputDecoration(
 hintText: 'Enter system prompt for this agent template...',
 hintStyle: TextStyle(
 fontFamily: 'Space Grotesk',
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 border: InputBorder.none,
 contentPadding: EdgeInsets.all(16),
 ),
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 color: Theme.of(context).colorScheme.onSurface,
 height: 1.5,
 ),
 ),
 ),
 SizedBox(height: 16),
 Row(
 children: [
 Container(
 decoration: BoxDecoration(
 border: Border.all(color: Theme.of(context).colorScheme.outline),
 borderRadius: BorderRadius.circular(6),
 ),
 child: TextButton(
 onPressed: _loadSystemPrompt,
 style: TextButton.styleFrom(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
 foregroundColor: Theme.of(context).colorScheme.onSurface,
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
 SizedBox(width: 12),
 Container(
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.primary,
 borderRadius: BorderRadius.circular(6),
 ),
 child: TextButton(
 onPressed: _saveAgentPrompt,
 style: TextButton.styleFrom(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
 foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

 Widget _buildIntegrationsTab() {
 return SingleChildScrollView(
 padding: const EdgeInsets.all(24),
 child: Center(
 child: Container(
 constraints: BoxConstraints(maxWidth: 1200),
 child: const IntegrationsTabContent(),
 ),
 ),
 );
 }

 Widget _buildGeneralSettingsTab(ThemeService themeService) {
 return SingleChildScrollView(
 padding: const EdgeInsets.all(24),
 child: Center(
 child: Container(
 constraints: BoxConstraints(maxWidth: 1200),
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
 final currentThemeName = currentThemeMode == ThemeMode.light ? 'Mint' : 'Forest';
 
 return AsmblStringDropdown(
 value: currentThemeName,
 items: const ['Mint', 'Forest'],
 onChanged: (value) {
 if (value == 'Mint') {
 themeService.setTheme(ThemeMode.light);
 } else if (value == 'Forest') {
 themeService.setTheme(ThemeMode.dark);
 }
 },
 );
 },
 ),
 ),
 SizedBox(height: 24),
 Row(
 children: [
 Icon(
 Icons.notifications,
 size: 20,
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: 12),
 Expanded(
 child: Text(
 'Enable notifications',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 color: Theme.of(context).colorScheme.onSurface,
 ),
 ),
 ),
 Switch(
 value: true,
 onChanged: (value) {},
 activeColor: Theme.of(context).colorScheme.primary,
 ),
 ],
 ),
 ],
 ),
 ),
 SizedBox(height: 32),
 _SettingsSection(
 title: 'About',
 child: Column(
 children: [
 Row(
 children: [
 Icon(
 Icons.info,
 size: 20,
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: 12),
 Text(
 'Version 1.0.0',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 color: Theme.of(context).colorScheme.onSurface,
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
 color: Colors.orange.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 Icons.warning,
 size: 12,
 color: Colors.orange,
 ),
 SizedBox(width: 4),
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
 ? ThemeColors(context).success.withValues(alpha: 0.1) 
 : ThemeColors(context).error.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(
 color: apiConfig.isConfigured 
 ? ThemeColors(context).success.withValues(alpha: 0.3) 
 : ThemeColors(context).error.withValues(alpha: 0.3),
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 apiConfig.isConfigured ? Icons.check_circle : Icons.error,
 size: 12,
 color: apiConfig.isConfigured ? ThemeColors(context).success : ThemeColors(context).error,
 ),
 SizedBox(width: 4),
 Text(
 '${apiConfig.provider} (${apiConfig.model})',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 fontWeight: FontWeight.w500,
 color: apiConfig.isConfigured ? ThemeColors(context).success : ThemeColors(context).error,
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
 backgroundColor: ThemeColors(context).surface.withValues(alpha: 0.95),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
 ),
 title: Text(
 'Select API for ${selectedAgent}',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 18,
 fontWeight: FontWeight.w600,
 color: Theme.of(context).colorScheme.onSurface,
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
 margin: EdgeInsets.only(bottom: 8),
 decoration: BoxDecoration(
 color: isSelected 
 ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
 : ThemeColors(context).surface.withValues(alpha: 0.8),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(
 color: isSelected 
 ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
 : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
 ),
 ),
 child: ListTile(
 leading: Container(
 width: 32,
 height: 32,
 decoration: BoxDecoration(
 color: apiConfig.isConfigured 
 ? ThemeColors(context).success.withValues(alpha: 0.1)
 : ThemeColors(context).error.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(6),
 border: Border.all(
 color: apiConfig.isConfigured 
 ? ThemeColors(context).success.withValues(alpha: 0.3)
 : ThemeColors(context).error.withValues(alpha: 0.3),
 ),
 ),
 child: Icon(
 apiConfig.isConfigured ? Icons.check_circle : Icons.error,
 color: apiConfig.isConfigured ? ThemeColors(context).success : ThemeColors(context).error,
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
 color: Theme.of(context).colorScheme.onSurface,
 ),
 ),
 if (apiConfig.isDefault) ...[
 SizedBox(width: SpacingTokens.iconSpacing),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
 ),
 child: Text(
 'DEFAULT',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 8,
 fontWeight: FontWeight.w600,
 color: Theme.of(context).colorScheme.primary,
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
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 ),
 trailing: Container(
 width: 20,
 height: 20,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 border: Border.all(
 color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
 width: 2,
 ),
 color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
 ),
 child: isSelected 
 ? Icon(Icons.check, size: 12, color: ThemeColors(context).onPrimary)
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
 SizedBox(height: 16),
 Container(
 width: double.infinity,
 decoration: BoxDecoration(
 border: Border.all(color: Theme.of(context).colorScheme.outline),
 borderRadius: BorderRadius.circular(8),
 ),
 child: TextButton.icon(
 onPressed: () {
 Navigator.pop(context);
 _tabController.animateTo(0); // Go to API Configuration tab
 },
 icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
 label: Text(
 'Add New API Configuration',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 color: Theme.of(context).colorScheme.primary,
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
 border: Border.all(color: Theme.of(context).colorScheme.outline),
 borderRadius: BorderRadius.circular(6),
 ),
 child: TextButton(
 onPressed: () => Navigator.pop(context),
 style: TextButton.styleFrom(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
 foregroundColor: Theme.of(context).colorScheme.onSurface,
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
 backgroundColor: ThemeColors(context).surface.withValues(alpha: 0.95),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
 ),
 title: Text(
 isEditing ? 'Edit API Configuration' : 'Add New API Configuration',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 20,
 fontWeight: FontWeight.w600,
 color: Theme.of(context).colorScheme.onSurface,
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
 border: Border.all(color: Theme.of(context).colorScheme.outline),
 borderRadius: BorderRadius.circular(8),
 color: ThemeColors(context).surface.withValues(alpha: 0.8),
 ),
 child: TextField(
 decoration: InputDecoration(
 hintText: 'e.g., "Production Claude", "GPT-4 Testing"',
 hintStyle: TextStyle(
 fontFamily: 'Space Grotesk',
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 border: InputBorder.none,
 contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
 ),
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 color: Theme.of(context).colorScheme.onSurface,
 ),
 onChanged: (value) => nameValue = value,
 controller: TextEditingController(text: nameValue),
 ),
 ),
 ),
 
 SizedBox(height: 20),
 
 // Provider and Model row
 Row(
 children: [
 Expanded(
 child: _FormField(
 label: 'Provider',
 child: AsmblStringDropdown(
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
 SizedBox(width: 16),
 Expanded(
 child: _FormField(
 label: 'Model',
 child: AsmblStringDropdown(
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
 
 SizedBox(height: 20),
 
 // API Key field
 _FormField(
 label: 'API Key',
 helpText: 'Your API key is stored locally and encrypted',
 child: Container(
 decoration: BoxDecoration(
 border: Border.all(color: Theme.of(context).colorScheme.outline),
 borderRadius: BorderRadius.circular(8),
 color: ThemeColors(context).surface.withValues(alpha: 0.8),
 ),
 child: TextField(
 decoration: InputDecoration(
 hintText: 'Enter your API key',
 hintStyle: TextStyle(
 fontFamily: 'Space Grotesk',
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 border: InputBorder.none,
 contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
 ),
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 color: Theme.of(context).colorScheme.onSurface,
 ),
 obscureText: true,
 onChanged: (value) => apiKeyValue = value,
 ),
 ),
 ),
 
 SizedBox(height: 20),
 
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
 border: Border.all(color: Theme.of(context).colorScheme.outline),
 borderRadius: BorderRadius.circular(8),
 color: ThemeColors(context).surface.withValues(alpha: 0.8),
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
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 ),
 Container(
 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 ),
 child: Text(
 tempValue.toStringAsFixed(2),
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 fontWeight: FontWeight.w600,
 color: Theme.of(context).colorScheme.primary,
 ),
 ),
 ),
 Text(
 'Creative',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 12,
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 SizedBox(height: 8),
 SliderTheme(
 data: SliderTheme.of(context).copyWith(
 activeTrackColor: Theme.of(context).colorScheme.primary,
 inactiveTrackColor: Theme.of(context).colorScheme.outline,
 thumbColor: Theme.of(context).colorScheme.primary,
 overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
 thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
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
 SizedBox(width: 16),
 Expanded(
 child: _FormField(
 label: 'Response Length',
 helpText: 'Default: 2048 tokens',
 child: Container(
 decoration: BoxDecoration(
 border: Border.all(color: Theme.of(context).colorScheme.outline),
 borderRadius: BorderRadius.circular(8),
 color: ThemeColors(context).surface.withValues(alpha: 0.8),
 ),
 child: TextField(
 decoration: InputDecoration(
 hintText: '2048 (Default)',
 hintStyle: TextStyle(
 fontFamily: 'Space Grotesk',
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 border: InputBorder.none,
 contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
 ),
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 color: Theme.of(context).colorScheme.onSurface,
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
 border: Border.all(color: Theme.of(context).colorScheme.outline),
 borderRadius: BorderRadius.circular(6),
 ),
 child: TextButton(
 onPressed: () => Navigator.pop(context),
 style: TextButton.styleFrom(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
 foregroundColor: Theme.of(context).colorScheme.onSurface,
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
 SizedBox(width: 12),
 Container(
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.primary,
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
 foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
 style: TextStyle(fontFamily: 'Space Grotesk'),
 ),
 backgroundColor: isError ? ThemeColors(context).error : ThemeColors(context).success,
 behavior: SnackBarBehavior.floating,
 margin: EdgeInsets.all(16),
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
 color: ThemeColors(context).surface.withValues(alpha: 0.8),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
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
 color: Theme.of(context).colorScheme.onSurface,
 ),
 ),
 SizedBox(height: 16),
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
 color: Theme.of(context).colorScheme.onSurface,
 ),
 ),
 if (helpText != null) ...[
 SizedBox(height: 4),
 Text(
 helpText!,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 12,
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 SizedBox(height: 8),
 child,
 ],
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

class IntegrationsTabContent extends StatefulWidget {
 const IntegrationsTabContent({super.key});

 @override
 State<IntegrationsTabContent> createState() => _IntegrationsTabContentState();
}

class _IntegrationsTabContentState extends State<IntegrationsTabContent> {
 String _selectedCategory = 'all';
 String _searchQuery = '';
 final TextEditingController _searchController = TextEditingController();

 final List<String> _categories = [
 'All', 'Files & Storage', 'Development', 'Productivity', 'Web & APIs', 'Database', 
 'DevOps', 'Cloud', 'Design', 'API', 'Testing', 'Finance', 'Analytics', 'Security',
 'AI/ML', 'Gaming'
 ];

 final List<Integration> _integrations = [
 // Core MCP Servers
 Integration(
 id: 'filesystem',
 name: 'File System',
 description: 'Read, write, and manage local files and folders',
 category: 'Files & Storage',
 icon: Icons.folder_outlined,
 isInstalled: true,
 developer: 'Anthropic',
 downloadCount: 'Dec 2024',
 features: ['Read files', 'Write files', 'Directory operations', 'File search'],
 ),
 Integration(
 id: 'brave-search',
 name: 'Brave Search',
 description: 'Search the web with privacy-focused Brave Search',
 category: 'Web & APIs',
 icon: Icons.search,
 isInstalled: true,
 developer: 'Brave Software',
 downloadCount: 'Dec 2024',
 features: ['Web search', 'Real-time results', 'Privacy-focused', 'Rich snippets'],
 ),
 Integration(
 id: 'memory',
 name: 'Memory',
 description: 'Remember conversations and context across sessions',
 category: 'Productivity',
 icon: Icons.memory,
 isInstalled: true,
 developer: 'Anthropic',
 downloadCount: 'Dec 2024',
 features: ['Context memory', 'Session persistence', 'Smart recall', 'Privacy-focused'],
 ),
 
 // Development & DevOps
 Integration(
 id: 'github',
 name: 'GitHub',
 description: 'Access repositories, issues, and pull requests',
 category: 'Development',
 icon: Icons.code,
 isInstalled: false,
 developer: 'GitHub',
 downloadCount: 'Jan 2025',
 features: ['Repository access', 'Issue management', 'Pull requests', 'Code search'],
 ),
 Integration(
 id: 'git',
 name: 'Git',
 description: 'Local Git repository operations and version control',
 category: 'Development',
 icon: Icons.source,
 isInstalled: false,
 developer: 'Git',
 downloadCount: 'Jan 2025',
 features: ['Local Git ops', 'Branch management', 'Commit history', 'Diff analysis'],
 ),
 Integration(
 id: 'docker',
 name: 'Docker',
 description: 'Manage Docker containers and images',
 category: 'DevOps',
 icon: Icons.view_in_ar,
 isInstalled: false,
 developer: 'Docker Inc',
 downloadCount: 'Feb 2025',
 features: ['Container management', 'Image operations', 'Docker Compose', 'Registry access'],
 ),
 Integration(
 id: 'aws',
 name: 'Amazon Web Services',
 description: 'Access and manage AWS cloud resources',
 category: 'Cloud',
 icon: Icons.cloud,
 isInstalled: false,
 developer: 'Amazon',
 downloadCount: 'Jan 2025',
 features: ['EC2 management', 'S3 operations', 'Lambda functions', 'CloudFormation'],
 ),
 Integration(
 id: 'kubernetes',
 name: 'Kubernetes',
 description: 'Orchestrate and manage Kubernetes clusters',
 category: 'DevOps',
 icon: Icons.settings_ethernet,
 isInstalled: false,
 developer: 'CNCF',
 downloadCount: 'Mar 2025',
 features: ['Pod management', 'Service discovery', 'Config maps', 'Deployments'],
 ),
 
 // Databases
 Integration(
 id: 'postgres',
 name: 'PostgreSQL',
 description: 'Connect to PostgreSQL databases and run queries',
 category: 'Database',
 icon: Icons.storage,
 isInstalled: false,
 developer: 'PostgreSQL',
 downloadCount: 'Jan 2025',
 features: ['Database queries', 'Schema inspection', 'Data analysis', 'Secure connections'],
 ),
 Integration(
 id: 'mysql',
 name: 'MySQL',
 description: 'Connect to MySQL databases and perform operations',
 category: 'Database',
 icon: Icons.dns,
 isInstalled: false,
 developer: 'Oracle',
 downloadCount: 'Feb 2025',
 features: ['SQL queries', 'Database administration', 'Performance tuning', 'Backup operations'],
 ),
 Integration(
 id: 'redis',
 name: 'Redis',
 description: 'In-memory data structure store and cache',
 category: 'Database',
 icon: Icons.flash_on,
 isInstalled: false,
 developer: 'Redis Ltd',
 downloadCount: 'Mar 2025',
 features: ['Key-value operations', 'Pub/Sub messaging', 'Data structures', 'Performance metrics'],
 ),
 Integration(
 id: 'mongodb',
 name: 'MongoDB',
 description: 'NoSQL document database operations',
 category: 'Database',
 icon: Icons.article,
 isInstalled: false,
 developer: 'MongoDB Inc',
 downloadCount: 'Apr 2025',
 features: ['Document queries', 'Aggregation pipelines', 'Index management', 'Schema validation'],
 ),
 
 // Design & Creative
 Integration(
 id: 'figma',
 name: 'Figma',
 description: 'Access design files and components from Figma',
 category: 'Design',
 icon: Icons.design_services,
 isInstalled: false,
 developer: 'Figma',
 downloadCount: 'Feb 2025',
 features: ['Design access', 'Component library', 'Asset export', 'Team collaboration'],
 ),
 Integration(
 id: 'canva',
 name: 'Canva',
 description: 'Create and edit designs with Canva integration',
 category: 'Design',
 icon: Icons.palette,
 isInstalled: false,
 developer: 'Canva',
 downloadCount: 'Apr 2025',
 features: ['Template access', 'Design automation', 'Brand kits', 'Asset library'],
 ),
 
 // Productivity & Communication
 Integration(
 id: 'slack',
 name: 'Slack',
 description: 'Send messages and interact with Slack workspaces',
 category: 'Productivity',
 icon: Icons.chat,
 isInstalled: false,
 developer: 'Slack Technologies',
 downloadCount: 'Jan 2025',
 features: ['Message sending', 'Channel access', 'File sharing', 'Workflow automation'],
 ),
 Integration(
 id: 'jira',
 name: 'Jira',
 description: 'Manage projects and track issues with Jira',
 category: 'Productivity',
 icon: Icons.bug_report,
 isInstalled: false,
 developer: 'Atlassian',
 downloadCount: 'Feb 2025',
 features: ['Issue tracking', 'Project management', 'Sprint planning', 'Custom workflows'],
 ),
 Integration(
 id: 'notion',
 name: 'Notion',
 description: 'Access and manage Notion workspaces and pages',
 category: 'Productivity',
 icon: Icons.note,
 isInstalled: false,
 developer: 'Notion Labs',
 downloadCount: 'Apr 2025',
 features: ['Page access', 'Database queries', 'Content creation', 'Team collaboration'],
 ),
 Integration(
 id: 'airtable',
 name: 'Airtable',
 description: 'Database and spreadsheet operations with Airtable',
 category: 'Productivity',
 icon: Icons.table_chart,
 isInstalled: false,
 developer: 'Airtable Inc',
 downloadCount: 'May 2025',
 features: ['Base management', 'Record operations', 'View filtering', 'API integration'],
 ),
 
 // Development Tools
 Integration(
 id: 'python',
 name: 'Python',
 description: 'Execute Python code and scripts',
 category: 'Development',
 icon: Icons.code,
 isInstalled: false,
 developer: 'Python Software Foundation',
 downloadCount: 'Dec 2024',
 features: ['Code execution', 'Package management', 'Virtual environments', 'Debugging'],
 ),
 Integration(
 id: 'jupyter',
 name: 'Jupyter',
 description: 'Interactive notebooks and data analysis',
 category: 'Development',
 icon: Icons.analytics,
 isInstalled: false,
 developer: 'Project Jupyter',
 downloadCount: 'Mar 2025',
 features: ['Notebook execution', 'Data visualization', 'Interactive computing', 'Kernel management'],
 ),
 Integration(
 id: 'shell',
 name: 'Shell',
 description: 'Execute shell commands and scripts',
 category: 'Development',
 icon: Icons.terminal,
 isInstalled: false,
 developer: 'Various',
 downloadCount: 'Jan 2025',
 features: ['Command execution', 'Script automation', 'Process management', 'Environment variables'],
 ),
 
 // API & Testing
 Integration(
 id: 'postman',
 name: 'Postman',
 description: 'API testing and development with Postman',
 category: 'API',
 icon: Icons.api,
 isInstalled: false,
 developer: 'Postman Inc',
 downloadCount: 'Apr 2025',
 features: ['API testing', 'Collection management', 'Environment variables', 'Mock servers'],
 ),
 Integration(
 id: 'selenium',
 name: 'Selenium',
 description: 'Browser automation and web testing',
 category: 'Testing',
 icon: Icons.web,
 isInstalled: false,
 developer: 'Selenium',
 downloadCount: 'Apr 2025',
 features: ['Browser automation', 'Web testing', 'Element interaction', 'Cross-browser support'],
 ),
 Integration(
 id: 'browserbase',
 name: 'Browserbase',
 description: 'Cloud browser automation and testing',
 category: 'Testing',
 icon: Icons.cloud_queue,
 isInstalled: false,
 developer: 'Browserbase',
 downloadCount: 'May 2025',
 features: ['Cloud browsers', 'Headless automation', 'Screenshot capture', 'Performance testing'],
 ),
 
 // Finance & Trading
 Integration(
 id: 'alpaca',
 name: 'Alpaca',
 description: 'Stock and options trading with Alpaca Markets',
 category: 'Finance',
 icon: Icons.trending_up,
 isInstalled: false,
 developer: 'Alpaca Markets',
 downloadCount: 'Apr 2025',
 features: ['Stock trading', 'Options trading', 'Portfolio management', 'Market data'],
 ),
 Integration(
 id: 'stripe',
 name: 'Stripe',
 description: 'Payment processing and financial operations',
 category: 'Finance',
 icon: Icons.payment,
 isInstalled: false,
 developer: 'Stripe Inc',
 downloadCount: 'Mar 2025',
 features: ['Payment processing', 'Subscription management', 'Invoice creation', 'Financial reporting'],
 ),
 
 // Cloud Services
 Integration(
 id: 'azure',
 name: 'Microsoft Azure',
 description: 'Access Microsoft Azure cloud services',
 category: 'Cloud',
 icon: Icons.cloud_circle,
 isInstalled: false,
 developer: 'Microsoft',
 downloadCount: 'Feb 2025',
 features: ['Virtual machines', 'Storage accounts', 'App services', 'Function apps'],
 ),
 Integration(
 id: 'google-analytics',
 name: 'Google Analytics',
 description: 'Website analytics and user behavior insights',
 category: 'Analytics',
 icon: Icons.analytics,
 isInstalled: false,
 developer: 'Google',
 downloadCount: 'Mar 2025',
 features: ['Traffic analysis', 'User behavior', 'Conversion tracking', 'Custom reports'],
 ),
 
 // Authentication
 Integration(
 id: 'auth0',
 name: 'Auth0',
 description: 'Identity and access management platform',
 category: 'Security',
 icon: Icons.security,
 isInstalled: false,
 developer: 'Auth0 Inc',
 downloadCount: 'May 2025',
 features: ['User authentication', 'SSO integration', 'MFA support', 'User management'],
 ),
 
 // Coming Soon
 Integration(
 id: 'openai',
 name: 'OpenAI',
 description: 'AI model fine-tuning and training operations',
 category: 'AI/ML',
 icon: Icons.psychology,
 isInstalled: false,
 developer: 'OpenAI',
 downloadCount: 'Coming Soon',
 features: ['Model fine-tuning', 'API access', 'Custom training', 'Model deployment'],
 ),
 Integration(
 id: 'huggingface',
 name: 'Hugging Face',
 description: 'Access AI models and datasets hub',
 category: 'AI/ML',
 icon: Icons.face,
 isInstalled: false,
 developer: 'Hugging Face',
 downloadCount: 'Coming Soon',
 features: ['Model hub access', 'Dataset management', 'Transformers library', 'Model inference'],
 ),
 Integration(
 id: 'unity',
 name: 'Unity',
 description: 'Game development and Unity Editor integration',
 category: 'Gaming',
 icon: Icons.videogame_asset,
 isInstalled: false,
 developer: 'Unity Technologies',
 downloadCount: 'Coming Soon',
 features: ['Scene management', 'Asset pipeline', 'Build automation', 'Performance profiling'],
 ),
 ];

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 final filteredIntegrations = _getFilteredIntegrations();
 
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Search Bar (simplified, app-like)
 Container(
 margin: EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
 decoration: BoxDecoration(
 color: colors.surfaceVariant.withValues(alpha: 0.5),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: colors.border.withValues(alpha: 0.3)),
 ),
 child: Row(
 children: [
 Icon(Icons.search, color: colors.onSurfaceVariant, size: 20),
 SizedBox(width: 12),
 Expanded(
 child: TextField(
 controller: _searchController,
 decoration: InputDecoration(
 hintText: 'Search integrations',
 hintStyle: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 16,
 color: colors.onSurfaceVariant,
 ),
 border: InputBorder.none,
 isDense: true,
 ),
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 16,
 color: colors.onSurface,
 ),
 onChanged: (value) {
 setState(() {
 _searchQuery = value;
 });
 },
 ),
 ),
 if (_searchQuery.isNotEmpty)
 GestureDetector(
 onTap: () {
 _searchController.clear();
 setState(() {
 _searchQuery = '';
 });
 },
 child: Icon(Icons.clear, color: colors.onSurfaceVariant, size: 20),
 ),
 ],
 ),
 ),
 
 // Filter Chips (app-store style)
 Container(
 height: 40,
 margin: EdgeInsets.only(bottom: SpacingTokens.sectionSpacing),
 child: ListView.separated(
 scrollDirection: Axis.horizontal,
 padding: const EdgeInsets.symmetric(horizontal: 4),
 itemCount: _categories.length,
 separatorBuilder: (_, __) => SizedBox(width: SpacingTokens.xs),
 itemBuilder: (context, index) {
 final category = _categories[index];
 final categoryKey = category.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_');
 final isSelected = _selectedCategory == categoryKey;
 
 return GestureDetector(
 onTap: () {
 setState(() {
 _selectedCategory = categoryKey;
 });
 },
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
 decoration: BoxDecoration(
 color: isSelected ? colors.primary : colors.surface,
 borderRadius: BorderRadius.circular(20),
 border: Border.all(
 color: isSelected ? colors.primary : colors.border,
 width: 1,
 ),
 ),
 child: Center(
 child: Text(
 category,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
 color: isSelected ? Colors.white : colors.onSurface,
 ),
 ),
 ),
 ),
 );
 },
 ),
 ),
 
 SizedBox(height: SpacingTokens.textSectionSpacing),
 
 // Popular Integrations Section
 if (_searchQuery.isEmpty && _selectedCategory == 'all') ...[
 Padding(
 padding: EdgeInsets.only(left: 4, bottom: SpacingTokens.componentSpacing),
 child: Text(
 'Popular',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 20,
 fontWeight: FontWeight.w700,
 color: colors.onSurface,
 ),
 ),
 ),
 SizedBox(
 height: 180,
 child: ListView.separated(
 scrollDirection: Axis.horizontal,
 padding: const EdgeInsets.symmetric(horizontal: 4),
 itemCount: _integrations.take(6).length,
 separatorBuilder: (_, __) => SizedBox(width: SpacingTokens.componentSpacing),
 itemBuilder: (context, index) {
 final featuredIntegrations = _integrations.take(6).toList();
 return _buildIntegrationCard(featuredIntegrations[index], isCompact: true);
 },
 ),
 ),
 SizedBox(height: SpacingTokens.sectionSpacing),
 ],
 
 // Main Integrations List
 if (_searchQuery.isEmpty && _selectedCategory == 'all') ...[
 Padding(
 padding: EdgeInsets.only(left: 4, bottom: SpacingTokens.componentSpacing),
 child: Text(
 'All Integrations',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 20,
 fontWeight: FontWeight.w700,
 color: colors.onSurface,
 ),
 ),
 ),
 ] else if (_searchQuery.isNotEmpty || _selectedCategory != 'all') ...[
 Padding(
 padding: EdgeInsets.only(left: 4, bottom: SpacingTokens.componentSpacing),
 child: Text(
 _searchQuery.isNotEmpty 
 ? 'Results (${filteredIntegrations.length})'
 : _categories.firstWhere((cat) => cat.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_') == _selectedCategory),
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 20,
 fontWeight: FontWeight.w700,
 color: colors.onSurface,
 ),
 ),
 ),
 ],
 
 // Integrations Grid
 filteredIntegrations.isEmpty 
 ? _buildEmptyState()
 : GridView.builder(
 shrinkWrap: true,
 physics: NeverScrollableScrollPhysics(),
 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
 crossAxisCount: 4,
 crossAxisSpacing: SpacingTokens.componentSpacing,
 mainAxisSpacing: SpacingTokens.componentSpacing,
 childAspectRatio: 0.9,
 ),
 itemCount: filteredIntegrations.length,
 itemBuilder: (context, index) {
 return _buildIntegrationCard(filteredIntegrations[index], isCompact: true);
 },
 ),
 ],
 );
 }

 List<Integration> _getFilteredIntegrations() {
 var filtered = _integrations;
 
 // Filter by category
 if (_selectedCategory != 'all') {
 filtered = filtered.where((integration) {
 return integration.category.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_') == _selectedCategory;
 }).toList();
 }
 
 // Filter by search query
 if (_searchQuery.isNotEmpty) {
 filtered = filtered.where((integration) {
 return integration.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
 integration.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
 integration.developer.toLowerCase().contains(_searchQuery.toLowerCase());
 }).toList();
 }
 
 return filtered;
 }

 Widget _buildIntegrationCard(Integration integration, {bool isCompact = false, bool isGrid = false}) {
 final colors = ThemeColors(context);
 
 if (isCompact) {
 // Compact card for featured section (app-like)
 return Container(
 width: 160,
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 decoration: BoxDecoration(
 color: colors.surface,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
 border: Border.all(color: colors.border),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header with icon
 Row(
 children: [
 Container(
 width: 48,
 height: 48,
 decoration: BoxDecoration(
 color: colors.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(12),
 ),
 child: Icon(
 integration.icon,
 color: colors.primary,
 size: 24,
 ),
 ),
 ],
 ),
 
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // App name
 Text(
 integration.name,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 
 SizedBox(height: 4),
 
 // Description
 Expanded(
 child: Text(
 integration.description,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 12,
 color: colors.onSurfaceVariant,
 height: 1.3,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // Button row
 Row(
 children: [
 
 const Spacer(),
 
 // Action button (compact)
 GestureDetector(
 onTap: () {
 if (integration.isInstalled) {
 _manageIntegration(integration);
 } else {
 _installIntegration(integration);
 }
 },
 child: Container(
 padding: EdgeInsets.symmetric(
 horizontal: integration.isInstalled ? 10 : 12, 
 vertical: 4,
 ),
 decoration: BoxDecoration(
 color: integration.isInstalled ? colors.surfaceVariant : colors.primary,
 borderRadius: BorderRadius.circular(12),
 ),
 child: Text(
 integration.isInstalled ? 'OPEN' : 'GET',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 fontWeight: FontWeight.w700,
 color: integration.isInstalled ? colors.primary : Colors.white,
 letterSpacing: 0.5,
 ),
 ),
 ),
 ),
 ],
 ),
 ],
 ),
 );
 }
 
 if (isGrid) {
 // Grid card (app store grid style)
 return Container(
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 decoration: BoxDecoration(
 color: colors.surface,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
 border: Border.all(color: colors.border),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header with icon
 Row(
 children: [
 Container(
 width: 48,
 height: 48,
 decoration: BoxDecoration(
 color: colors.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(12),
 ),
 child: Icon(
 integration.icon,
 color: colors.primary,
 size: 24,
 ),
 ),
 ],
 ),
 
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // App name
 Text(
 integration.name,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 16,
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 
 SizedBox(height: 4),
 
 // Description
 Expanded(
 child: Text(
 integration.description,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 13,
 color: colors.onSurfaceVariant,
 height: 1.3,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // Button row
 Row(
 children: [
 const Spacer(),
 
 // Action button (compact)
 GestureDetector(
 onTap: () {
 if (integration.isInstalled) {
 _manageIntegration(integration);
 } else {
 _installIntegration(integration);
 }
 },
 child: Container(
 padding: EdgeInsets.symmetric(
 horizontal: integration.isInstalled ? 12 : 16, 
 vertical: 6,
 ),
 decoration: BoxDecoration(
 color: integration.isInstalled ? colors.surfaceVariant : colors.primary,
 borderRadius: BorderRadius.circular(16),
 ),
 child: Text(
 integration.isInstalled ? 'OPEN' : 'GET',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 11,
 fontWeight: FontWeight.w700,
 color: integration.isInstalled ? colors.primary : Colors.white,
 letterSpacing: 0.5,
 ),
 ),
 ),
 ),
 ],
 ),
 ],
 ),
 );
 }
 
 // List-style card (like iOS App Store list view)
 return Container(
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 decoration: BoxDecoration(
 color: colors.surface,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
 border: Border.all(color: colors.border),
 ),
 child: Row(
 children: [
 // App icon
 Container(
 width: 64,
 height: 64,
 decoration: BoxDecoration(
 color: colors.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(16),
 ),
 child: Icon(
 integration.icon,
 color: colors.primary,
 size: 32,
 ),
 ),
 
 SizedBox(width: SpacingTokens.componentSpacing),
 
 // App info
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Name and rating row
 Row(
 children: [
 Expanded(
 child: Text(
 integration.name,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 18,
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 ],
 ),
 
 SizedBox(height: 4),
 
 // Description
 Text(
 integration.description,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 color: colors.onSurfaceVariant,
 height: 1.3,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 
 SizedBox(height: SpacingTokens.xs),
 
 // Developer info
 Row(
 children: [
 Text(
 'By ${integration.developer}',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 12,
 color: colors.onSurfaceVariant,
 ),
 ),
 Spacer(),
 Text(
 integration.downloadCount,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 12,
 fontWeight: FontWeight.w500,
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 
 SizedBox(width: SpacingTokens.componentSpacing),
 
 // Action button (app store style)
 GestureDetector(
 onTap: () {
 if (integration.isInstalled) {
 _manageIntegration(integration);
 } else {
 _installIntegration(integration);
 }
 },
 child: Container(
 padding: EdgeInsets.symmetric(
 horizontal: integration.isInstalled ? 16 : 20, 
 vertical: 8,
 ),
 decoration: BoxDecoration(
 color: integration.isInstalled ? colors.surfaceVariant : colors.primary,
 borderRadius: BorderRadius.circular(20),
 ),
 child: Text(
 integration.isInstalled ? 'OPEN' : 'GET',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 12,
 fontWeight: FontWeight.w700,
 color: integration.isInstalled ? colors.primary : Colors.white,
 letterSpacing: 0.5,
 ),
 ),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildEmptyState() {
 final colors = ThemeColors(context);
 
 return Center(
 child: Padding(
 padding: EdgeInsets.symmetric(vertical: SpacingTokens.sectionSpacing * 2),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 Icons.search_off,
 size: 48,
 color: colors.onSurfaceVariant.withValues(alpha: 0.6),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'No integrations found',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 18,
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 ),
 SizedBox(height: SpacingTokens.xs),
 Text(
 'Try adjusting your search or category filter',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 );
 }

 void _installIntegration(Integration integration) {
 // Simulate installation
 setState(() {
 final index = _integrations.indexWhere((i) => i.id == integration.id);
 if (index != -1) {
 _integrations[index] = integration.copyWith(isInstalled: true);
 }
 });
 
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text(
 '${integration.name} installed successfully!',
 style: TextStyle(fontFamily: 'Space Grotesk'),
 ),
 backgroundColor: ThemeColors(context).success,
 behavior: SnackBarBehavior.floating,
 ),
 );
 }

 void _manageIntegration(Integration integration) {
 showDialog(
 context: context,
 builder: (context) => _IntegrationDetailsDialog(integration: integration),
 );
 }

 @override
 void dispose() {
 _searchController.dispose();
 super.dispose();
 }
}

class Integration {
 final String id;
 final String name;
 final String description;
 final String category;
 final IconData icon;
 final bool isInstalled;
 final String developer;
 final String downloadCount;
 final List<String> features;

 const Integration({
 required this.id,
 required this.name,
 required this.description,
 required this.category,
 required this.icon,
 required this.isInstalled,
 required this.developer,
 required this.downloadCount,
 required this.features,
 });

 Integration copyWith({
 String? id,
 String? name,
 String? description,
 String? category,
 IconData? icon,
 bool? isInstalled,
 String? developer,
 String? downloadCount,
 List<String>? features,
 }) {
 return Integration(
 id: id ?? this.id,
 name: name ?? this.name,
 description: description ?? this.description,
 category: category ?? this.category,
 icon: icon ?? this.icon,
 isInstalled: isInstalled ?? this.isInstalled,
 developer: developer ?? this.developer,
 downloadCount: downloadCount ?? this.downloadCount,
 features: features ?? this.features,
 );
 }
}

class _IntegrationDetailsDialog extends StatelessWidget {
 final Integration integration;

 const _IntegrationDetailsDialog({required this.integration});

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 
 return Dialog(
 backgroundColor: Colors.transparent,
 child: Container(
 width: 500,
 constraints: BoxConstraints(maxHeight: 600),
 decoration: BoxDecoration(
 color: colors.surface,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
 border: Border.all(color: colors.border),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header
 Container(
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 decoration: BoxDecoration(
 border: Border(bottom: BorderSide(color: colors.border)),
 ),
 child: Row(
 children: [
 Container(
 width: 48,
 height: 48,
 decoration: BoxDecoration(
 color: colors.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(12),
 ),
 child: Icon(
 integration.icon,
 color: colors.primary,
 size: 24,
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 integration.name,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 20,
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 ),
 Text(
 'by ${integration.developer}',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 IconButton(
 onPressed: () => Navigator.of(context).pop(),
 icon: Icon(Icons.close),
 style: IconButton.styleFrom(
 foregroundColor: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 
 // Content
 Expanded(
 child: SingleChildScrollView(
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Description
 Text(
 integration.description,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 16,
 color: colors.onSurface,
 height: 1.5,
 ),
 ),
 
 SizedBox(height: SpacingTokens.sectionSpacing),
 
 // Stats
 Row(
 children: [
 _buildStatChip(colors, Icons.download, integration.downloadCount),
 SizedBox(width: SpacingTokens.componentSpacing),
 _buildStatChip(colors, Icons.category, integration.category),
 SizedBox(width: SpacingTokens.componentSpacing),
 _buildStatChip(colors, Icons.person, integration.developer),
 ],
 ),
 
 SizedBox(height: SpacingTokens.sectionSpacing),
 
 // Features
 Text(
 'Features',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 18,
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 ...integration.features.map((feature) => Padding(
 padding: const EdgeInsets.only(bottom: 8),
 child: Row(
 children: [
 Icon(
 Icons.check_circle,
 size: 16,
 color: colors.success,
 ),
 SizedBox(width: SpacingTokens.xs),
 Expanded(
 child: Text(
 feature,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 color: colors.onSurface,
 ),
 ),
 ),
 ],
 ),
 )),
 ],
 ),
 ),
 ),
 
 // Footer
 Container(
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 decoration: BoxDecoration(
 border: Border(top: BorderSide(color: colors.border)),
 ),
 child: Row(
 children: [
 Expanded(
 child: integration.isInstalled
 ? AsmblButtonEnhanced.secondary(
 text: 'Uninstall',
 icon: Icons.delete_outline,
 onPressed: () {
 Navigator.of(context).pop();
 // Handle uninstall
 },
 size: AsmblButtonSize.medium,
 )
 : AsmblButtonEnhanced.accent(
 text: 'Install Integration',
 icon: Icons.download_outlined,
 onPressed: () {
 Navigator.of(context).pop();
 // Handle install
 },
 size: AsmblButtonSize.medium,
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildStatChip(ThemeColors colors, IconData icon, String text) {
 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: colors.surfaceVariant.withValues(alpha: 0.5),
 borderRadius: BorderRadius.circular(4),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(icon, size: 14, color: colors.onSurfaceVariant),
 SizedBox(width: 4),
 Text(
 text,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 12,
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 );
 }
}