import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../widgets/mcp_server_dialog.dart';
import '../widgets/mcp_health_status_widget.dart';

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
 _tabController = TabController(length: 5, vsync: this); // Updated to 5 tabs
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
 Tab(text: 'MCP Servers'),
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
 _buildMCPServersTab(),
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
  Widget _buildMCPServersTab() {
    return Consumer(
      builder: (context, ref, child) {
        final mcpService = ref.watch(mcpSettingsServiceProvider);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  // MCP Server Configuration Section
                  _SettingsSection(
                    title: 'MCP Server Configuration',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configure Model Context Protocol (MCP) servers that provide tools and capabilities to your agents.',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: SpacingTokens.componentSpacing),
                        
                        // Add New MCP Server Button
                        Row(
                          children: [
                            Expanded(
                              child: AsmblButton.primary(
                                text: 'Add MCP Server',
                                onPressed: () => _showAddMCPServerDialog(),
                                icon: Icons.add,
                              ),
                            ),
                            SizedBox(width: 12),
                            AsmblButton.secondary(
                              text: 'Import Config',
                              onPressed: () => _showImportMCPConfigDialog(),
                              icon: Icons.file_upload,
                            ),
                          ],
                        ),
                        
                        SizedBox(height: SpacingTokens.componentSpacing),
                        
                        // MCP Servers List - show actual servers or empty state
                        FutureBuilder<Map<String, MCPServerConfig>>(
                          future: Future.value(mcpService.allMCPServers),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return _buildEmptyMCPState();
                            }
                            
                            final servers = snapshot.data!;
                            return Column(
                              children: servers.entries.map((entry) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: _buildMCPServerCard(entry.key, entry.value, mcpService),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // MCP Server Health Monitoring Section
                  _SettingsSection(
                    title: 'Server Health Monitoring',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Real-time health monitoring and auto-reconnection for MCP servers.',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: SpacingTokens.componentSpacing),
                        
                        // Health monitoring widget
                        MCPHealthStatusWidget(showDetails: true),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Global Context Documents Section
                  _SettingsSection(
                    title: 'Global Context Documents',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documents available to all agents as context. These will be injected into MCP sessions.',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: SpacingTokens.componentSpacing),
                        
                        AsmblButton.secondary(
                          text: 'Add Context Document',
                          onPressed: () => _showAddContextDocumentDialog(),
                          icon: Icons.description,
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Empty state for context documents
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'No global context documents configured',
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyMCPState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.storage,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 16),
          Text(
            'No MCP Servers Configured',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add MCP servers to provide tools and capabilities to your agents.\nServers can offer file system access, web search, databases, and more.',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // MCP Server management methods
  void _showAddMCPServerDialog() {
    showDialog(
      context: context,
      builder: (context) => MCPServerDialog(),
    ).then((result) {
      if (result == true) {
        // Refresh the UI after successful add
        setState(() {});
        _showMessage('MCP Server added successfully!');
      }
    });
  }

  void _showImportMCPConfigDialog() {
    _showMessage('Import MCP Config - Coming soon!');
  }

  void _showAddContextDocumentDialog() {
    _showMessage('Add Context Document - Coming soon!');
  }

  Widget _buildMCPServerCard(String serverId, MCPServerConfig config, MCPSettingsService mcpService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: config.enabled 
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Status Indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: config.enabled 
                    ? SemanticColors.success.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: config.enabled 
                      ? SemanticColors.success.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.storage,
                  color: config.enabled ? SemanticColors.success : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              
              SizedBox(width: 16),
              
              // Server Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            config.name,
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // Connection Status
                        Consumer(
                          builder: (context, ref, child) {
                            return ref.watch(mcpServerStatusProvider(serverId)).when(
                              data: (status) => _buildConnectionStatusBadge(status),
                              loading: () => _buildConnectionStatusBadge(null, isLoading: true),
                              error: (_, __) => _buildConnectionStatusBadge(null, hasError: true),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      config.description,
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: 12),
              
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _testMCPServerConnection(serverId, mcpService),
                    icon: Icon(Icons.play_circle, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: SemanticColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editMCPServer(serverId, config),
                    icon: Icon(Icons.edit, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteMCPServer(serverId, mcpService),
                    icon: Icon(Icons.delete, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: SemanticColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Server Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.terminal,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Command: ${config.command} ${config.args.join(' ')}',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (config.env?.isNotEmpty == true) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.settings,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Environment: ${config.env!.keys.join(', ')}',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusBadge(MCPServerStatus? status, {bool isLoading = false, bool hasError = false}) {
    Color color;
    String text;
    IconData icon;

    if (isLoading) {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
      text = 'Testing...';
      icon = Icons.hourglass_empty;
    } else if (hasError || status?.status == ConnectionStatus.error) {
      color = SemanticColors.error;
      text = 'Error';
      icon = Icons.error;
    } else if (status?.isConnected == true) {
      color = SemanticColors.success;
      text = 'Connected';
      icon = Icons.check_circle;
    } else {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
      text = 'Not tested';
      icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _testMCPServerConnection(String serverId, MCPSettingsService mcpService) async {
    _showMessage('Testing connection to $serverId...', isError: false);
    
    try {
      final result = await mcpService.testMCPServerConnection(serverId);
      final message = result.isConnected 
        ? 'Successfully connected to $serverId!'
        : 'Failed to connect to $serverId: ${result.message ?? 'Unknown error'}';
      
      _showMessage(message, isError: !result.isConnected);
      setState(() {}); // Refresh to show updated status
    } catch (e) {
      _showMessage('Connection test failed: $e', isError: true);
    }
  }

  void _editMCPServer(String serverId, MCPServerConfig config) {
    showDialog(
      context: context,
      builder: (context) => MCPServerDialog(
        existingConfig: config,
        serverId: serverId,
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
        _showMessage('MCP Server updated successfully!');
      }
    });
  }

  void _deleteMCPServer(String serverId, MCPSettingsService mcpService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors(context).surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        title: Text(
          'Delete MCP Server',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this MCP server? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Space Grotesk'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SemanticColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await mcpService.removeMCPServer(serverId);
        setState(() {});
        _showMessage('MCP Server deleted successfully!');
      } catch (e) {
        _showMessage('Failed to delete server: $e', isError: true);
      }
    }
  }
}

// Helper widget classes
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
          const SizedBox(height: 4),
          Text(
            helpText!,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
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

// Integration class for the integrations tab
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
}

// Simple placeholder for IntegrationsTabContent
class IntegrationsTabContent extends StatelessWidget {
  const IntegrationsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Integrations Coming Soon',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your favorite tools and services to extend functionality.',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
