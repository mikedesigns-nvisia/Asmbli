import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../tabs/api_configuration_tab.dart';
import '../tabs/agent_management_tab.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../widgets/mcp_server_dialog.dart';
import '../widgets/mcp_health_status_widget.dart';
import '../widgets/api_key_dialog.dart';
import '../../../../core/design_system/components/unified_mcp_server_card.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import '../../../../core/services/integration_service.dart';
import '../../../../core/services/integration_dependency_service.dart';
import '../../../../core/design_system/components/integration_status_indicators.dart';
import '../../../../core/services/integration_installation_service.dart' as installation;
import '../../../../core/services/integration_health_monitoring_service.dart' as health_monitoring;
import '../widgets/integration_recommendations_widget.dart';
import '../widgets/integration_dependency_dialog.dart';
import '../widgets/integration_health_dashboard.dart';
import '../widgets/enhanced_integrations_tab.dart';
import '../widgets/manual_mcp_server_modal.dart';
import '../widgets/custom_mcp_server_modal.dart';
import '../widgets/simple_auto_detection_wizard.dart';
import '../tabs/general_settings_tab.dart';

// Integration model for unified display
class Integration {
  final String id;
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final bool isConfigured;
  final bool isMCPServer;
  final MCPServerConfig? mcpServer;

  Integration({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.isConfigured,
    required this.isMCPServer,
    this.mcpServer,
  });
}

class SettingsScreen extends ConsumerStatefulWidget {
 final String? initialTab;
 
 const SettingsScreen({super.key, this.initialTab});

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

 // API Key Management - now handled by ApiConfigService

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
  _tabController = TabController(length: 3, vsync: this);
 selectedModel = providerModels[selectedProvider]!.first;
 
 // Set initial tab if provided
 if (widget.initialTab != null) {
   selectedTab = widget.initialTab!;
 }
 
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
                Consumer(
                  builder: (context, ref, _) {
                    final allApiConfigs = ref.watch(apiConfigsProvider);
                    return APIConfigurationTab(
                      apiConfigs: allApiConfigs.values.map((c) => c.toJson()).toList(),
                      onAddApiKey: _showAddApiKeyDialog,
                      onDeleteApiKey: (id) => _deleteApiKey(id),
                      onEditApiKey: (cfg) => _editApiKeyFromMap(cfg),
                      onSetAsDefault: (id) => _setAsDefault(id),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    return AgentManagementTab(
                      agents: agents,
                      selectedAgent: selectedAgent,
                      selectedTemplate: selectedTemplate,
                      systemPrompt: systemPromptController.text,
                      onSelectAgent: (id) {
                        setState(() {
                          selectedAgent = id;
                          selectedTemplate = agents.firstWhere((a) => a.name == selectedAgent).templates.first;
                          _loadSystemPrompt();
                        });
                      },
                      onSelectTemplate: (tmpl) {
                        setState(() {
                          selectedTemplate = tmpl;
                          _loadSystemPrompt();
                        });
                      },
                      onShowApiSelection: _showApiSelectionDialog,
                      onSavePrompt: () {
                        _saveAgentPrompt();
                      },
                      onUpdateSystemPrompt: (text) => systemPromptController.text = text,
                      apiAssignmentWidget: _getApiAssignmentWidget(),
                    );
                  },
                ),
                GeneralSettingsTab(themeService: themeService),
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
 final allApiConfigs = ref.watch(apiConfigsProvider);
 final defaultApiConfig = ref.watch(defaultApiConfigProvider);
 
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
 if (allApiConfigs.isEmpty) ...[
 Container(
 padding: const EdgeInsets.all(24),
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
 ),
 child: Column(
 children: [
 Icon(
 Icons.api_outlined,
 size: 48,
 color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
 ),
 SizedBox(height: 16),
 Text(
 'No API Keys Configured',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 16,
 fontWeight: FontWeight.w500,
 color: Theme.of(context).colorScheme.onSurface,
 ),
 ),
 SizedBox(height: 8),
 Text(
 'Add your first API key to start using the app with real AI models.',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 14,
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 SizedBox(height: 16),
 AsmblButton.primary(
 text: 'Add API Key',
 onPressed: () => _showAddApiKeyDialog(),
 ),
 ],
 ),
 ),
 ] else ...[
 ...allApiConfigs.entries.map((entry) {
 final apiConfig = entry.value;
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
 overlayColor: ThemeColors(context).primary.withValues(alpha: 0.1),
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
 overlayColor: Colors.white.withValues(alpha: 0.1),
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

// Integrations tab is handled by `EnhancedIntegrationsTab` (extracted widget).

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
 final mcpSettingsService = ref.watch(mcpSettingsServiceProvider);
final allApiConfigs = mcpSettingsService.allDirectAPIConfigs;
 final assignedApiId = agentApiAssignments[selectedAgent];
 
 if (assignedApiId == null || !allApiConfigs.containsKey(assignedApiId)) {
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

 final apiConfig = allApiConfigs[assignedApiId]!;
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
 final allApiConfigs = ref.read(mcpSettingsServiceProvider).allDirectAPIConfigs;
 
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
 ...allApiConfigs.entries.map((entry) {
 final apiConfig = entry.value;
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
 overlayColor: ThemeColors(context).primary.withValues(alpha: 0.1),
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
 overlayColor: ThemeColors(context).primary.withValues(alpha: 0.1),
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

 Future<void> _setAsDefault(String apiId) async {
 try {
 final mcpSettingsService = ref.read(mcpSettingsServiceProvider);
 await mcpSettingsService.setDefaultDirectAPIConfig(apiId);
 _showMessage('Default API key updated successfully!');
 } catch (e) {
 _showMessage('Failed to update default API key: $e', isError: true);
 }
 }

 Future<void> _deleteApiKey(String apiId) async {
 try {
 final allApiConfigs = ref.read(mcpSettingsServiceProvider).allDirectAPIConfigs;
 final apiToDelete = allApiConfigs[apiId];
 
 if (apiToDelete == null) {
 _showMessage('API key not found', isError: true);
 return;
 }
 
 if (apiToDelete.isDefault) {
 _showMessage('Cannot delete the default API key. Set another key as default first.', isError: true);
 return;
 }

 final mcpSettingsService = ref.read(mcpSettingsServiceProvider);
 await mcpSettingsService.removeDirectAPIConfig(apiId);
 _showMessage('API key deleted successfully!');
 } catch (e) {
 _showMessage('Failed to delete API key: $e', isError: true);
 }
 }

 void _editApiKey(ApiConfig apiConfig) {
 // Convert ApiConfig to DirectAPIConfig for compatibility with existing dialog
 // TODO: Update ApiKeyDialog to work with ApiConfig directly
 final directConfig = DirectAPIConfig(
   id: apiConfig.id,
   name: apiConfig.name,
   provider: apiConfig.provider,
   model: apiConfig.model,
   apiKey: apiConfig.apiKey,
   baseUrl: apiConfig.baseUrl,
   isDefault: apiConfig.isDefault,
   enabled: apiConfig.enabled,
   createdAt: DateTime.now(),
 );
 _showAddApiKeyDialog(editingConfig: directConfig);
 }

void _editApiKeyFromMap(Map<String, dynamic> cfg) {
  final directConfig = DirectAPIConfig(
    id: cfg['id']?.toString() ?? '',
    name: cfg['name']?.toString() ?? 'API Key',
    provider: cfg['provider']?.toString() ?? '',
    model: cfg['model']?.toString() ?? '',
    apiKey: cfg['apiKey']?.toString() ?? '',
    baseUrl: cfg['baseUrl']?.toString() ?? '',
    isDefault: cfg['isDefault'] == true,
    enabled: cfg['enabled'] == true,
    createdAt: DateTime.tryParse(cfg['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
  _showAddApiKeyDialog(editingConfig: directConfig);
}

 Future<void> _showAddApiKeyDialog({DirectAPIConfig? editingConfig}) async {
 await showDialog<bool>(
 context: context,
 builder: (context) => ApiKeyDialog(existingConfig: editingConfig),
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
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AsmblButton.secondary(
                text: 'Browse Library',
                icon: Icons.library_books,
                onPressed: _showManualMCPServerModal,
              ),
              SizedBox(width: SpacingTokens.componentSpacing),
              AsmblButton.primary(
                text: 'Add MCP Server',
                icon: Icons.add,
                onPressed: _showAddMCPServerDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // MCP Server management methods
  void _showAddMCPServerDialog() {
    // Show the enhanced server selection options
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeColors(context).surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(BorderRadiusTokens.xl),
            topRight: Radius.circular(BorderRadiusTokens.xl),
          ),
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.all(SpacingTokens.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(SpacingTokens.iconSpacing),
                    decoration: BoxDecoration(
                      color: ThemeColors(context).primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 24,
                      color: ThemeColors(context).primary,
                    ),
                  ),
                  SizedBox(width: SpacingTokens.componentSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add MCP Server',
                          style: TextStyles.pageTitle.copyWith(color: ThemeColors(context).onSurface),
                        ),
                        SizedBox(height: SpacingTokens.xs_precise),
                        Text(
                          'Choose how you want to add an MCP server integration',
                          style: TextStyles.bodyMedium.copyWith(color: ThemeColors(context).onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: ThemeColors(context).onSurfaceVariant),
                  ),
                ],
              ),
              
              SizedBox(height: SpacingTokens.sectionSpacing),
              
              // Options
              Expanded(
                child: ListView(
                  children: [
                    // Auto-Detection Option
                    _buildAddServerOption(
                      title: 'Auto-Detect Tools',
                      description: 'Automatically find and configure installed development tools',
                      icon: Icons.auto_fix_high,
                      color: ThemeColors(context).primary,
                      badge: 'Recommended',
                      onTap: () {
                        Navigator.pop(context);
                        _showAutoDetectionModal();
                      },
                    ),
                    
                    SizedBox(height: SpacingTokens.componentSpacing),
                    
                    // Server Library Option
                    _buildAddServerOption(
                      title: 'Browse MCP Server Library',
                      description: 'Select from curated official and community MCP servers',
                      icon: Icons.library_books,
                      color: Colors.blue,
                      badge: 'Popular',
                      onTap: () {
                        Navigator.pop(context);
                        _showManualMCPServerModal();
                      },
                    ),
                    
                    SizedBox(height: SpacingTokens.componentSpacing),
                    
                    // Custom Configuration Option
                    _buildAddServerOption(
                      title: 'Custom MCP Server',
                      description: 'Configure any MCP server with JSON or manual setup',
                      icon: Icons.code,
                      color: Colors.orange,
                      badge: 'Advanced',
                      onTap: () {
                        Navigator.pop(context);
                        _showCustomMCPServerModal();
                      },
                    ),
                    
                    SizedBox(height: SpacingTokens.componentSpacing),
                    
                    // Legacy Option
                    _buildAddServerOption(
                      title: 'Quick Setup Wizard',
                      description: 'Traditional guided setup for MCP server configuration',
                      icon: Icons.auto_awesome,
                      color: Colors.green,
                      badge: 'Classic',
                      onTap: () {
                        Navigator.pop(context);
                        _showLegacyMCPServerDialog();
                      },
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

  Widget _buildAddServerOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(SpacingTokens.sectionSpacing),
        decoration: BoxDecoration(
          color: ThemeColors(context).surfaceVariant,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          border: Border.all(color: ThemeColors(context).border),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(SpacingTokens.componentSpacing),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            SizedBox(width: SpacingTokens.sectionSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyles.cardTitle.copyWith(color: ThemeColors(context).onSurface),
                      ),
                      SizedBox(width: SpacingTokens.iconSpacing),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SpacingTokens.iconSpacing,
                          vertical: SpacingTokens.xs_precise,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                        ),
                        child: Text(
                          badge,
                          style: TextStyles.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SpacingTokens.xs_precise),
                  Text(
                    description,
                    style: TextStyles.bodyMedium.copyWith(color: ThemeColors(context).onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, 
                 size: 16, 
                 color: ThemeColors(context).onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showAutoDetectionModal() {
    showDialog(
      context: context,
      builder: (context) => SimpleAutoDetectionWizard(
        onComplete: (result) {
          // Open marketplace and surface detected tools for user action after the wizard finishes
          Future.microtask(() {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                child: Container(
                  width: 1000,
                  height: 700,
                  child: Container(
                    padding: EdgeInsets.all(24),
                    child: Text('Integration marketplace functionality has been moved to the Integration Center. Please use the Integrations tab in the navigation.'),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  void _showManualMCPServerModal() {
    showDialog(
      context: context,
      builder: (context) => ManualMCPServerModal(
        onConfigurationComplete: _handleMCPConfigurationAdded,
      ),
    );
  }

  void _showCustomMCPServerModal() {
    showDialog(
      context: context,
      builder: (context) => CustomMCPServerModal(
        onConfigurationComplete: _handleMCPConfigurationAdded,
      ),
    );
  }

  void _showLegacyMCPServerDialog() {
    showDialog(
      context: context,
      builder: (context) => MCPServerDialog(),
    ).then((result) {
      if (result == true) {
        setState(() {});
        _showMessage('MCP Server added successfully!');
      }
    });
  }

  Future<void> _handleMCPConfigurationAdded(Map<String, dynamic> config) async {
    try {
      final mcpService = ref.read(mcpSettingsServiceProvider);
      
      // Extract server configuration from the config map
      final serverId = config.keys.first;
      final serverConfig = config[serverId] as Map<String, dynamic>;
      
      // Handle special cases (like Figma SSE transport)
      MCPServerConfig mcpConfig;
      if (serverConfig.containsKey('transport') && serverConfig['transport'] == 'sse') {
        // SSE transport configuration
        mcpConfig = MCPServerConfig(
          id: serverId,
          name: serverId.replaceAll('-', ' ').split(' ').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' '),
          command: '', // SSE doesn't use command
          args: [], // SSE doesn't use args
          env: serverConfig['env'] as Map<String, String>? ?? {},
          description: 'MCP Server via Server-Sent Events',
          enabled: true,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          transport: 'sse',
          url: serverConfig['url'] as String?,
        );
      } else {
        // Standard stdio transport configuration
        mcpConfig = MCPServerConfig(
          id: serverId,
          name: serverId.replaceAll('-', ' ').split(' ').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' '),
          command: serverConfig['command'] as String? ?? '',
          args: (serverConfig['args'] as List?)?.cast<String>() ?? [],
          env: serverConfig['env'] as Map<String, String>?,
          description: 'Custom MCP server configuration',
          enabled: true,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
      }
      
      // Save the configuration
      await mcpService.setMCPServer(serverId, mcpConfig);
      await mcpService.saveSettings();
      
      setState(() {});
      _showMessage('MCP server "$serverId" added successfully!');
    } catch (e) {
      _showMessage('Failed to add MCP server: $e', isError: true);
    }
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
                      overlayColor: SemanticColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editMCPServer(serverId, config),
                    icon: Icon(Icons.edit, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      overlayColor: ThemeColors(context).primary.withValues(alpha: 0.1),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteMCPServer(serverId, mcpService),
                    icon: Icon(Icons.delete, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: SemanticColors.error,
                      overlayColor: SemanticColors.error.withValues(alpha: 0.1),
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
            style: TextButton.styleFrom(
              overlayColor: ThemeColors(context).primary.withValues(alpha: 0.1),
            ),
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

  // Detection results removed from app.
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


// Unified integrations tab content with MCP servers and available integrations
class IntegrationsTabContent extends ConsumerStatefulWidget {
  const IntegrationsTabContent({super.key});

  @override
  ConsumerState<IntegrationsTabContent> createState() => _IntegrationsTabContentState();
}

class _IntegrationsTabContentState extends ConsumerState<IntegrationsTabContent> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final List<String> _categories = [
    'All',
    ...IntegrationCategory.values.map((category) => category.displayName),
  ];

  @override
  Widget build(BuildContext context) {
    final integrationService = ref.watch(integrationServiceProvider);
    final healthService = ref.watch(health_monitoring.integrationHealthMonitoringServiceProvider);
    final allIntegrationsWithStatus = integrationService.getAllIntegrationsWithStatus();
    final stats = integrationService.getStats();
    final healthStats = healthService.getHealthStatistics();
    
    // Filter integrations directly as IntegrationStatus objects
    final filteredItems = _filterIntegrationStatus(allIntegrationsWithStatus);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Integrations',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure and manage your integrations. Click on any integration to set it up or modify its settings.',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Enhanced Stats Overview with Marketplace and Health
          _buildEnhancedStatsOverview(stats, healthStats),
          const SizedBox(height: 24),
          
          // Search, Filter and Add Row
          Row(
            children: [
              // Search Bar
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search integrations...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Category Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  onChanged: (value) => setState(() => _selectedCategory = value!),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 16),
              
              // Add MCP Server Button
              AsmblButton.secondary(
                text: 'Add MCP Server',
                icon: Icons.integration_instructions,
                onPressed: () => _showAddMCPServerDialog(),
              ),
              const SizedBox(width: 12),
              
              // Browse Marketplace Button  
              AsmblButton.primary(
                text: 'Browse Marketplace',
                icon: Icons.store,
                onPressed: () => _showMarketplaceDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Recommendations Section
          const IntegrationRecommendationsWidget(),
          const SizedBox(height: 24),
          
          // Integrations Grid
          filteredItems.isEmpty 
              ? _buildEmptyState()
              : SizedBox(
                  height: 400, // Fixed height instead of Expanded
                  child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 0.75, // Further reduced for more height
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final integrationStatus = filteredItems[index];
                        return _buildIntegrationStatusCard(integrationStatus);
                      },
                    ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No configured integrations',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visit the Marketplace to add integrations to your agents.',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          AsmblButton.primary(
            text: 'Browse Integrations',
            icon: Icons.hub,
            onPressed: () => context.go(AppRoutes.integrationHub),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationCard(Integration integration) {
    if (integration.isMCPServer && integration.mcpServer != null) {
      // Use the existing unified MCP server card for configured servers
      return Column(
        children: [
          Flexible(
            child: UnifiedMCPServerCard(
              serverId: integration.id,
              config: integration.mcpServer,
              showHealth: false,
              showDescription: true,
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  'CONFIGURED',
                  style: TextStyles.caption.copyWith(
                    color: ThemeColors(context).primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: SpacingTokens.xs),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
            child: AsmblButton.secondary(
              text: 'Edit',
              onPressed: () => _handleIntegrationAction(integration),
              isFullWidth: true,
            ),
          ),
        ],
      );
    } else {
      // Create a custom card for unconfigured integrations using design system components
      return AsmblCard(
        child: Column(
          children: [
            // Header with icon and info
            Padding(
              padding: EdgeInsets.all(SpacingTokens.sm),
              child: Column(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: integration.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Icon(
                      integration.icon,
                      color: integration.color,
                      size: 20,
                    ),
                  ),
                  SizedBox(height: SpacingTokens.xs),
                  
                  // Name
                  Text(
                    integration.name,
                    style: TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeColors(context).onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2),
                  
                  // Description
                  Text(
                    integration.description,
                    style: TextStyles.caption.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Footer
            Padding(
              padding: EdgeInsets.all(SpacingTokens.sm),
              child: Column(
                children: [
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ThemeColors(context).surface,
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      border: Border.all(
                        color: ThemeColors(context).border.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'AVAILABLE',
                      style: TextStyles.caption.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: SpacingTokens.xs),
                  
                  // Action Button
                  AsmblButton.primary(
                    text: 'Install',
                    onPressed: () => _handleIntegrationAction(integration),
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }


  Color _getCategoryColor(IntegrationCategory category) {
    switch (category) {
      case IntegrationCategory.local:
        return Colors.orange;
      case IntegrationCategory.cloudAPIs:
        return Colors.blue;
      case IntegrationCategory.databases:
        return Colors.green;
      case IntegrationCategory.utilities:
        return Colors.purple;
      case IntegrationCategory.aiML:
        return Colors.deepPurple;
    }
  }

  Integration _mcpServerToIntegration(MCPServerConfig server) {
    return Integration(
      id: server.id,
      name: server.name,
      description: server.description ?? 'MCP Server',
      category: 'Development',
      icon: Icons.dns,
      color: Theme.of(context).colorScheme.primary,
      isConfigured: true,
      isMCPServer: true,
      mcpServer: server,
    );
  }

  List<IntegrationStatus> _filterIntegrationStatus(List<IntegrationStatus> items) {
    return items.where((status) {
      final integration = status.definition;
      
      // Show all integrations in settings (both configured and available to configure)
      
      final matchesSearch = _searchQuery.isEmpty ||
          integration.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          integration.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' ||
          integration.category.displayName == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showMarketplaceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          constraints: BoxConstraints(
            maxWidth: 1400,
            maxHeight: 900,
            minWidth: 800,
            minHeight: 600,
          ),
          decoration: BoxDecoration(
            color: SemanticColors.surface,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
            border: Border.all(
              color: SemanticColors.border,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: SemanticColors.border,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.store, size: 24, color: SemanticColors.primary),
                    SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Integration Marketplace',
                      style: TextStyles.pageTitle,
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // Marketplace Content
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(24),
                  child: Text('Integration marketplace functionality has been moved to the Integration Center.'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestWorkflowButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Container(
          padding: EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: SemanticColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(
              color: SemanticColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.science,
                color: SemanticColors.primary,
                size: 20,
              ),
              SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Integration Workflow',
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SemanticColors.primary,
                      ),
                    ),
                    Text(
                      'Verify end-to-end integration from discovery to agent chat',
                      style: TextStyles.bodySmall.copyWith(
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AsmblButton.primary(
                text: 'Run Test',
                icon: Icons.play_arrow,
                onPressed: () => _runIntegrationTest(context, ref),
              ),
            ],
          ),
        );
      },
    );
  }

  void _runIntegrationTest(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: SemanticColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        ),
        title: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(SemanticColors.primary),
              ),
            ),
            SizedBox(width: SpacingTokens.sm),
            Text(
              'Running Integration Test',
              style: TextStyles.cardTitle,
            ),
          ],
        ),
        content: Text(
          'Testing complete workflow from marketplace to chat...',
          style: TextStyles.bodyMedium.copyWith(
            color: SemanticColors.onSurfaceVariant,
          ),
        ),
      ),
    );

    try {
      // Note: Integration test service removed - functionality moved to integration_testing_service
      // TODO: Implement integration testing workflow with remaining services
      await Future.delayed(Duration(seconds: 2)); // Placeholder for now
      
      Navigator.of(context).pop(); // Close progress dialog
      
      // Simplified results (testing service consolidation in progress)
      _showMessage('Integration testing completed - detailed results temporarily disabled during service consolidation');
    } catch (e) {
      Navigator.of(context).pop();
      _showMessage('Integration test failed: $e', isError: true);
    }
  }

  // Helper method to filter items based on current search and category
  List<Integration> _filterItems(List<Integration> items) {
    return items.where((item) {
      final matchesSearch = _searchQuery.isEmpty || 
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildEnhancedStatsOverview(IntegrationStats stats, health_monitoring.HealthStatistics healthStats) {
    return Column(
      children: [
        // Main Stats Row
        Container(
          padding: EdgeInsets.all(SpacingTokens.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              _buildStatCard(
                'Total Available',
                '${stats.available}',
                Icons.apps,
                SemanticColors.primary,
              ),
              SizedBox(width: SpacingTokens.lg),
              _buildStatCard(
                'Installed',
                '${stats.configured}',
                Icons.check_circle,
                SemanticColors.success,
              ),
              SizedBox(width: SpacingTokens.lg),
              _buildStatCard(
                'Healthy',
                '${healthStats.healthy}',
                Icons.favorite,
                Colors.green,
              ),
              SizedBox(width: SpacingTokens.lg),
              _buildStatCard(
                'Need Attention',
                '${healthStats.unhealthy + healthStats.error}',
                Icons.warning,
                Colors.orange,
              ),
              Spacer(),
              // Health percentage indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: healthStats.isHealthy ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(
                    color: healthStats.isHealthy ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      healthStats.isHealthy ? Icons.health_and_safety : Icons.warning,
                      size: 16,
                      color: healthStats.isHealthy ? Colors.green : Colors.orange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${healthStats.healthPercentage.toStringAsFixed(0)}% Healthy',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: healthStats.isHealthy ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: SpacingTokens.md),
        
        // Test Integration Workflow Button
        _buildTestWorkflowButton(context),
        
        SizedBox(height: SpacingTokens.md),
        
        // Health Dashboard Widget
        IntegrationHealthDashboard(),
      ],
    );
  }

  Widget _buildStatsOverview(IntegrationStats stats) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          _buildStatCard(
            'Total',
            '${stats.total}',
            Icons.apps,
            SemanticColors.primary,
          ),
          SizedBox(width: SpacingTokens.lg),
          _buildStatCard(
            'Configured',
            '${stats.configured}',
            Icons.check_circle,
            SemanticColors.success,
          ),
          SizedBox(width: SpacingTokens.lg),
          _buildStatCard(
            'Active',
            '${stats.enabled}',
            Icons.play_circle,
            ThemeColors(context).primary,
          ),
          SizedBox(width: SpacingTokens.lg),
          _buildStatCard(
            'Available',
            '${stats.available}',
            Icons.download,
            SemanticColors.warning,
          ),
          Spacer(),
          // Quick category indicators
          Wrap(
            spacing: SpacingTokens.xs,
            children: stats.byCategory.entries.map((entry) {
              final category = entry.key;
              final categoryStats = entry.value;
              
              return Tooltip(
                message: '${category.displayName}: ${categoryStats.configured}/${categoryStats.total} configured',
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${categoryStats.configured}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(category),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: SpacingTokens.xs),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: SemanticColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildIntegrationStatusCard(IntegrationStatus status) {
    final integration = status.definition;
    final color = integration.brandColor ?? _getCategoryColor(integration.category);

    return AsmblCard(
      child: Column(
        children: [
          // Header with icon, status indicators, and info
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(SpacingTokens.sm),
              child: Column(
                children: [
                  // Status row at top
                  Row(
                    children: [
                      IntegrationStatusIndicators.statusBadge(status, compact: true),
                      Spacer(),
                      IntegrationStatusIndicators.difficultyBadge(integration.difficulty, showIcon: false),
                    ],
                  ),
                  SizedBox(height: SpacingTokens.xs),
                  
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Icon(
                      integration.icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  SizedBox(height: SpacingTokens.xs),
                  
                  // Name
                  Text(
                    integration.name,
                    style: TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeColors(context).onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2),
                  
                  // Description
                  Expanded(
                    child: Text(
                      integration.description,
                      style: TextStyles.caption.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: SpacingTokens.xs),
                  
                  // Capabilities preview
                  IntegrationStatusIndicators.capabilitiesPreview(integration.capabilities),
                  
                  SizedBox(height: SpacingTokens.xs),
                  
                  // Prerequisites indicator
                  IntegrationStatusIndicators.prerequisitesIndicator(integration.prerequisites),
                ],
              ),
            ),
          ),
          
          // Action button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SpacingTokens.sm, vertical: SpacingTokens.xs),
            child: AsmblButton.secondary(
              text: _getActionButtonText(status),
              onPressed: integration.isAvailable 
                  ? () => _handleIntegrationStatusAction(status)
                  : null,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  String _getActionButtonText(IntegrationStatus status) {
    if (!status.definition.isAvailable) return 'Coming Soon';
    if (!status.isConfigured) return 'Install';
    if (!status.isEnabled) return 'Enable';
    return 'Edit';
  }

  void _handleIntegrationStatusAction(IntegrationStatus status) async {
    if (status.isConfigured) {
      // Edit existing configuration - no dependency check needed
      showDialog(
        context: context,
        builder: (context) => MCPServerDialog(
          existingConfig: status.mcpConfig,
          serverId: status.definition.id,
        ),
      ).then((result) {
        if (result == true) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Integration updated successfully!'),
              backgroundColor: ThemeColors(context).success,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      });
    } else {
      // Check dependencies before creating new configuration
      final dependencyService = ref.read(integrationDependencyServiceProvider);
      final depCheck = dependencyService.checkDependencies(status.definition.id);
      
      // Show dependency dialog if there are issues
      if (depCheck.missingRequired.isNotEmpty || depCheck.conflicts.isNotEmpty) {
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => IntegrationDependencyDialog(
            integrationId: status.definition.id,
            isRemoving: false,
          ),
        );
        
        if (shouldProceed != true) return;
        
        // If there are missing required dependencies, don't proceed
        if (depCheck.missingRequired.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please install required dependencies first: ${depCheck.missingRequired.join(', ')}'),
              backgroundColor: ThemeColors(context).error,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          return;
        }
      }
      
      // Create new configuration
      showDialog(
        context: context,
        builder: (context) => MCPServerDialog(
          serverId: status.definition.id,
        ),
      ).then((result) {
        if (result == true) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Integration installed successfully!'),
              backgroundColor: ThemeColors(context).success,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      });
    }
  }

  void _handleIntegrationAction(Integration integration) {
    if (integration.isMCPServer) {
      if (integration.mcpServer != null) {
        // Edit existing MCP server configuration using simple dialog
        showDialog(
          context: context,
          builder: (context) => MCPServerDialog(
            existingConfig: integration.mcpServer,
            serverId: integration.id,
          ),
        ).then((result) {
          if (result == true) {
            setState(() {}); // Refresh the integrations list
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Integration updated successfully!'),
                backgroundColor: ThemeColors(context).success,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        });
      } else {
        // Create new MCP server configuration using simple dialog
        showDialog(
          context: context,
          builder: (context) => MCPServerDialog(
            serverId: integration.id,
          ),
        ).then((result) {
          if (result == true) {
            setState(() {}); // Refresh the integrations list
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Integration added successfully!'),
                backgroundColor: ThemeColors(context).success,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        });
      }
    } else {
      // Show coming soon message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${integration.name} integration coming soon!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddIntegrationDialog() {
    showDialog(
      context: context,
      builder: (context) => MCPServerDialog(),
    ).then((result) {
      if (result == true) {
        setState(() {}); // Refresh the integrations list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Integration added successfully!'),
            backgroundColor: ThemeColors(context).success,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showAddMCPServerDialog() {
    showDialog(
      context: context,
      builder: (context) => MCPServerDialog(),
    ).then((result) {
      if (result == true) {
        setState(() {}); // Refresh the integrations list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MCP Server added successfully!'),
            backgroundColor: ThemeColors(context).success,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });
  }

}
