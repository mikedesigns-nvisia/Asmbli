import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../providers/agent_provider.dart';
import 'package:agent_engine_core/models/agent.dart';

class MyAgentsScreen extends ConsumerStatefulWidget {
 const MyAgentsScreen({super.key});

 @override
 ConsumerState<MyAgentsScreen> createState() => _MyAgentsScreenState();
}

class _MyAgentsScreenState extends ConsumerState<MyAgentsScreen> {
 int selectedTab = 0; // 0 = My Agents, 1 = Agent Library
 String searchQuery = '';
 String selectedCategory = 'All';

 final List<String> categories = [
 'All', 'Research', 'Development', 'Writing', 'Data Analysis', 
 'Customer Support', 'Marketing', 'Design', 'DevOps', 'Security',
 'Product', 'Database', 'API', 'Blockchain', 'QA', 'AI/ML',
 'Content Creation', 'IoT', 'Gaming', 'Robotics', 'AR/VR',
 'Quantum', 'Bioinformatics', 'Finance', 'E-commerce', 'Cloud',
 'Automation', 'Mobile', 'Real Estate', 'Legal', 'Healthcare'
 ];


 final List<AgentTemplate> templates = [
 AgentTemplate(
 name: 'Research Assistant',
 description: 'Academic research agent with citation management and fact-checking',
 category: 'Research',
 tags: ['academic', 'citations', 'fact-checking'],
 mcpStack: true,
 mcpServers: ['brave-search', 'memory', 'filesystem'],
 exampleUse: 'Find recent papers on quantum computing with proper citations',
 popularity: 95,
 ),
 AgentTemplate(
 name: 'Code Reviewer',
 description: 'Automated code review with best practices and security checks',
 category: 'Development', 
 tags: ['code-review', 'security', 'best-practices'],
 mcpStack: true,
 mcpServers: ['github', 'git', 'filesystem', 'memory'],
 exampleUse: 'Review React components for security vulnerabilities',
 popularity: 87,
 ),
 AgentTemplate(
 name: 'Content Writer',
 description: 'SEO-optimized content generation with tone customization',
 category: 'Writing',
 tags: ['seo', 'content', 'marketing'],
 mcpStack: true,
 mcpServers: ['brave-search', 'web-fetch', 'memory', 'filesystem'],
 exampleUse: 'Create engaging blog posts about sustainable technology',
 popularity: 92,
 ),
 AgentTemplate(
 name: 'Data Analyst',
 description: 'Statistical analysis and visualization for business insights',
 category: 'Data Analysis',
 tags: ['statistics', 'visualization', 'insights'],
 mcpStack: true,
 mcpServers: ['postgres', 'python', 'jupyter', 'memory', 'filesystem'],
 exampleUse: 'Analyze customer churn patterns and create visualizations',
 popularity: 78,
 ),
 AgentTemplate(
 name: 'Customer Support Bot',
 description: 'Intelligent support agent with ticket management integration',
 category: 'Customer Support',
 tags: ['support', 'tickets', 'automation'],
 mcpStack: true,
 mcpServers: ['jira', 'slack', 'zendesk', 'memory'],
 exampleUse: 'Handle customer inquiries and route tickets efficiently',
 popularity: 89,
 ),
 AgentTemplate(
 name: 'Marketing Strategist',
 description: 'Campaign planning and performance analysis agent',
 category: 'Marketing',
 tags: ['campaigns', 'strategy', 'analytics'],
 mcpStack: true,
 mcpServers: ['brave-search', 'google-analytics', 'notion', 'memory'],
 exampleUse: 'Plan social media campaigns with performance tracking',
 popularity: 84,
 ),
 AgentTemplate(
 name: 'Design Agent',
 description: 'Comprehensive design assistant with Figma integration, code generation, and GitHub collaboration',
 category: 'Design',
 tags: ['design-systems', 'ui-ux', 'figma', 'components', 'collaboration'],
 mcpStack: true,
 mcpServers: ['figma', 'github', 'filesystem', 'memory'],
 exampleUse: 'Generate design system components from Figma files',
 popularity: 91,
 ),
 // DevOps & Infrastructure
 AgentTemplate(
 name: 'DevOps Engineer',
 description: 'Infrastructure automation and deployment specialist',
 category: 'DevOps',
 tags: ['docker', 'kubernetes', 'aws', 'ci-cd', 'automation'],
 mcpStack: true,
 mcpServers: ['aws', 'docker', 'kubernetes', 'shell', 'memory'],
 exampleUse: 'Automate deployment pipelines and manage cloud infrastructure',
 popularity: 88,
 ),
 AgentTemplate(
 name: 'Database Administrator',
 description: 'Database optimization with PostgreSQL and Redis',
 category: 'Database',
 tags: ['postgresql', 'mysql', 'redis', 'mongodb', 'optimization'],
 mcpStack: true,
 mcpServers: ['postgres', 'mysql', 'redis', 'mongodb', 'memory'],
 exampleUse: 'Optimize database queries and manage backup strategies',
 popularity: 82,
 ),
 // Security
 AgentTemplate(
 name: 'Security Analyst',
 description: 'Cybersecurity expert with penetration testing tools',
 category: 'Security',
 tags: ['pentesting', 'nmap', 'metasploit', 'vulnerability', 'ethical-hacking'],
 mcpStack: true,
 mcpServers: ['nmap', 'burp-suite', 'filesystem', 'shell', 'memory'],
 exampleUse: 'Conduct security audits and vulnerability assessments',
 popularity: 85,
 ),
 // Product & Analytics
 AgentTemplate(
 name: 'Product Manager',
 description: 'Product strategy with Jira and analytics integration',
 category: 'Product',
 tags: ['jira', 'analytics', 'roadmap', 'stakeholder', 'metrics'],
 mcpStack: true,
 mcpServers: ['jira', 'google-analytics', 'slack', 'memory', 'filesystem'],
 exampleUse: 'Plan product roadmaps and track success metrics',
 popularity: 86,
 ),
 AgentTemplate(
 name: 'Data Scientist',
 description: 'ML/AI specialist with Python and data analysis tools',
 category: 'Data Analysis',
 tags: ['python', 'jupyter', 'machine-learning', 'visualization', 'sql'],
 mcpStack: true,
 mcpServers: ['python', 'jupyter', 'postgres', 'memory', 'filesystem'],
 exampleUse: 'Build ML models and analyze complex datasets',
 popularity: 90,
 ),
 // API & Development
 AgentTemplate(
 name: 'API Architect',
 description: 'RESTful and GraphQL API design specialist',
 category: 'API',
 tags: ['rest', 'graphql', 'openapi', 'postman', 'microservices'],
 mcpStack: true,
 mcpServers: ['postman', 'swagger-ui', 'graphql', 'memory', 'filesystem'],
 exampleUse: 'Design robust APIs with comprehensive documentation',
 popularity: 83,
 ),
 AgentTemplate(
 name: 'QA Automation Engineer',
 description: 'Test automation with Selenium and Cypress',
 category: 'QA',
 tags: ['selenium', 'cypress', 'jest', 'testing', 'automation'],
 mcpStack: true,
 mcpServers: ['selenium', 'browserbase', 'jest', 'github', 'memory'],
 exampleUse: 'Create comprehensive test suites and automation frameworks',
 popularity: 81,
 ),
 // Blockchain & Web3
 AgentTemplate(
 name: 'Blockchain Developer',
 description: 'Smart contract and Web3 development expert',
 category: 'Blockchain',
 tags: ['ethereum', 'solidity', 'web3', 'defi', 'smart-contracts'],
 mcpStack: true,
 mcpServers: ['ethereum', 'ipfs', 'the-graph', 'memory', 'filesystem'],
 exampleUse: 'Develop and audit smart contracts for DeFi protocols',
 popularity: 79,
 ),
 AgentTemplate(
 name: 'UX Designer',
 description: 'User experience design with Figma integration',
 category: 'Design',
 tags: ['figma', 'ux', 'user-research', 'prototyping', 'accessibility'],
 mcpStack: true,
 mcpServers: ['figma', 'hotjar', 'airtable', 'memory', 'filesystem'],
 exampleUse: 'Create user-centered designs with comprehensive research',
 popularity: 87,
 ),
 // Coming Soon - AI/ML
 AgentTemplate(
 name: 'AI Model Trainer',
 description: 'Fine-tuning and training custom AI models',
 category: 'AI/ML',
 tags: ['huggingface', 'fine-tuning', 'wandb', 'gpu', 'training'],
 mcpStack: true,
 mcpServers: ['huggingface', 'openai', 'wandb', 'aws', 'memory'],
 exampleUse: 'Fine-tune LLMs for domain-specific applications',
 popularity: 93,
 isComingSoon: true,
 ),
 // Coming Soon - Content Creation
 AgentTemplate(
 name: 'Video Content Creator',
 description: 'AI-powered video editing and generation',
 category: 'Content Creation',
 tags: ['runway', 'elevenlabs', 'youtube', 'premiere', 'video-ai'],
 mcpStack: true,
 mcpServers: ['runway', 'elevenlabs', 'youtube', 'adobe-creative', 'memory'],
 exampleUse: 'Create and edit videos with AI-powered tools',
 popularity: 89,
 isComingSoon: true,
 ),
 // Coming Soon - IoT
 AgentTemplate(
 name: 'IoT Systems Engineer',
 description: 'IoT device management and edge computing',
 category: 'IoT',
 tags: ['mqtt', 'azure-iot', 'influxdb', 'edge', 'sensors'],
 mcpStack: true,
 mcpServers: ['azure-iot', 'aws-iot', 'influxdb', 'mqtt', 'memory'],
 exampleUse: 'Manage IoT devices and process sensor data streams',
 popularity: 76,
 isComingSoon: true,
 ),
 // Coming Soon - Gaming
 AgentTemplate(
 name: 'Game Developer',
 description: 'Game development with Unity and Unreal integration',
 category: 'Gaming',
 tags: ['unity', 'unreal', 'steam', 'playfab', 'gamedev'],
 mcpStack: true,
 mcpServers: ['unity', 'steam', 'playfab', 'github', 'memory'],
 exampleUse: 'Develop games with automated testing and deployment',
 popularity: 80,
 isComingSoon: true,
 ),
 // Coming Soon - Robotics
 AgentTemplate(
 name: 'Robotics Engineer',
 description: 'ROS integration and robot control systems',
 category: 'Robotics',
 tags: ['ros', 'gazebo', 'opencv', 'arduino', 'control-systems'],
 mcpStack: true,
 mcpServers: ['ros', 'gazebo', 'opencv', 'arduino', 'memory'],
 exampleUse: 'Program autonomous robots with computer vision',
 popularity: 74,
 isComingSoon: true,
 ),
 // Coming Soon - AR/VR
 AgentTemplate(
 name: 'AR/VR Developer',
 description: 'Augmented and Virtual Reality experiences',
 category: 'AR/VR',
 tags: ['arcore', 'oculus', 'babylon', 'blender', 'spatial'],
 mcpStack: true,
 mcpServers: ['arcore', 'oculus', 'unity', 'blender', 'memory'],
 exampleUse: 'Build immersive AR/VR applications and experiences',
 popularity: 77,
 isComingSoon: true,
 ),
 // Coming Soon - Quantum
 AgentTemplate(
 name: 'Quantum Computing Researcher',
 description: 'Quantum algorithm development and simulation',
 category: 'Quantum',
 tags: ['qiskit', 'cirq', 'aws-braket', 'pennylane', 'quantum-ml'],
 mcpStack: true,
 mcpServers: ['qiskit', 'cirq', 'aws-braket', 'pennylane', 'memory'],
 exampleUse: 'Develop quantum algorithms and run quantum simulations',
 popularity: 68,
 isComingSoon: true,
 ),
 // Coming Soon - Bioinformatics
 AgentTemplate(
 name: 'Bioinformatics Analyst',
 description: 'Genomic analysis and protein modeling',
 category: 'Bioinformatics',
 tags: ['blast', 'alphafold', 'pubmed', 'biopython', 'genomics'],
 mcpStack: true,
 mcpServers: ['blast', 'alphafold', 'pubmed', 'biopython', 'memory'],
 exampleUse: 'Analyze genomic sequences and predict protein structures',
 popularity: 71,
 isComingSoon: true,
 ),
 // Finance & Trading
 AgentTemplate(
 name: 'Financial Analyst',
 description: 'Market analysis with real-time data and trading tools',
 category: 'Finance',
 tags: ['trading', 'market-data', 'alpaca', 'financial', 'analysis'],
 mcpStack: true,
 mcpServers: ['alpaca', 'alpha-vantage', 'yahoo-finance', 'stripe', 'memory'],
 exampleUse: 'Analyze stock trends and execute automated trading strategies',
 popularity: 84,
 ),
 // E-commerce
 AgentTemplate(
 name: 'E-commerce Manager',
 description: 'Online store management with Shopify and payment integration',
 category: 'E-commerce',
 tags: ['shopify', 'stripe', 'inventory', 'orders', 'analytics'],
 mcpStack: true,
 mcpServers: ['shopify', 'stripe', 'google-analytics', 'zendesk', 'memory'],
 exampleUse: 'Manage inventory, process orders, and analyze sales performance',
 popularity: 82,
 ),
 // Cloud Infrastructure
 AgentTemplate(
 name: 'Cloud Architect',
 description: 'Multi-cloud infrastructure with Azure, AWS, and Alibaba Cloud',
 category: 'Cloud',
 tags: ['azure', 'aws', 'alibaba-cloud', 'terraform', 'monitoring'],
 mcpStack: true,
 mcpServers: ['azure', 'aws', 'alibaba-cloud', 'terraform', 'datadog', 'memory'],
 exampleUse: 'Design and deploy scalable multi-cloud architectures',
 popularity: 86,
 ),
 // Authentication & Identity
 AgentTemplate(
 name: 'Identity & Access Manager',
 description: 'Authentication and authorization with Auth0 and Asgardeo',
 category: 'Security',
 tags: ['auth0', 'asgardeo', 'identity', 'oauth', 'security'],
 mcpStack: true,
 mcpServers: ['auth0', 'asgardeo', 'okta', 'ldap', 'memory'],
 exampleUse: 'Configure SSO, manage user permissions, and audit access logs',
 popularity: 78,
 ),
 // Browser Automation
 AgentTemplate(
 name: 'Web Automation Specialist',
 description: 'Advanced browser automation with Browserbase and Puppeteer',
 category: 'Automation',
 tags: ['browserbase', 'puppeteer', 'selenium', 'scraping', 'testing'],
 mcpStack: true,
 mcpServers: ['browserbase', 'puppeteer', 'selenium', 'playwright', 'memory'],
 exampleUse: 'Automate complex web workflows and data extraction tasks',
 popularity: 79,
 ),
 // Mobile Development
 AgentTemplate(
 name: 'Mobile App Developer',
 description: 'Cross-platform mobile development with CI/CD integration',
 category: 'Mobile',
 tags: ['bitrise', 'firebase', 'react-native', 'flutter', 'ci-cd'],
 mcpStack: true,
 mcpServers: ['bitrise', 'firebase', 'expo', 'fastlane', 'memory'],
 exampleUse: 'Build, test, and deploy mobile apps with automated workflows',
 popularity: 83,
 isComingSoon: true,
 ),
 // Content Creation
 AgentTemplate(
 name: 'Visual Content Creator',
 description: 'Design automation with Canva and creative tools integration',
 category: 'Design',
 tags: ['canva', 'unsplash', 'adobe', 'creative', 'automation'],
 mcpStack: true,
 mcpServers: ['canva', 'unsplash', 'adobe-creative', 'pexels', 'memory'],
 exampleUse: 'Generate branded graphics and marketing materials automatically',
 popularity: 85,
 isComingSoon: true,
 ),
 // Real Estate
 AgentTemplate(
 name: 'Real Estate Analyst',
 description: 'Property analysis with market data and CRM integration',
 category: 'Real Estate',
 tags: ['zillow', 'mls', 'crm', 'market-analysis', 'properties'],
 mcpStack: true,
 mcpServers: ['zillow', 'mls-data', 'salesforce', 'google-maps', 'memory'],
 exampleUse: 'Analyze property values, market trends, and manage client relationships',
 popularity: 76,
 isComingSoon: true,
 ),
 // Legal & Compliance
 AgentTemplate(
 name: 'Legal Research Assistant',
 description: 'Legal document analysis and compliance checking',
 category: 'Legal',
 tags: ['westlaw', 'legal-research', 'compliance', 'documents', 'analysis'],
 mcpStack: true,
 mcpServers: ['westlaw', 'lexis-nexis', 'courthouse', 'docusign', 'memory'],
 exampleUse: 'Research case law, analyze contracts, and ensure regulatory compliance',
 popularity: 73,
 isComingSoon: true,
 ),
 // Healthcare
 AgentTemplate(
 name: 'Healthcare Data Analyst',
 description: 'Medical data analysis with FHIR and healthcare systems',
 category: 'Healthcare',
 tags: ['fhir', 'hl7', 'medical-data', 'epic', 'cerner'],
 mcpStack: true,
 mcpServers: ['fhir', 'hl7', 'epic', 'cerner', 'smart-on-fhir', 'memory'],
 exampleUse: 'Analyze patient data, generate health insights, and ensure HIPAA compliance',
 popularity: 77,
 isComingSoon: true,
 ),
 ];

 List<AgentTemplate> get filteredTemplates {
 return templates.where((template) {
 final matchesSearch = template.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
 template.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
 template.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()));
 
 final matchesCategory = selectedCategory == 'All' || template.category == selectedCategory;
 
 return matchesSearch && matchesCategory;
 }).toList();
 }

 @override
 Widget build(BuildContext context) {
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
 AppNavigationBar(currentRoute: AppRoutes.agents),

 // Main Content
 Expanded(
 child: Padding(
 padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Page Title
 Text(
 selectedTab == 0 ? 'My AI Agents' : 'Agent Library',
 style: TextStyles.pageTitle.copyWith(
 color: ThemeColors(context).onSurface,
 ),
 ),
 SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 selectedTab == 0 
 ? 'Manage and organize your AI-powered assistants'
 : 'Start with a pre-built template and customize it to your needs',
 style: TextStyles.bodyLarge.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 SizedBox(height: SpacingTokens.sectionSpacing),

 // Tab Selector
 Row(
 children: [
 _TabButton(
 text: 'My Agents',
 isSelected: selectedTab == 0,
 onTap: () => setState(() => selectedTab = 0),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 _TabButton(
 text: 'Agent Library',
 isSelected: selectedTab == 1,
 onTap: () => setState(() => selectedTab = 1),
 ),
 ],
 ),
 SizedBox(height: SpacingTokens.sectionSpacing),

 // Content based on selected tab
 Expanded(
 child: selectedTab == 0 ? _buildMyAgentsContent() : _buildAgentLibraryContent(),
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

 Widget _buildMyAgentsContent() {
 final agentsAsync = ref.watch(agentsProvider);
 
 return agentsAsync.when(
 data: (agents) {
 if (agents.isEmpty) {
 return _buildEmptyAgentsState();
 }
 
 return Column(
 children: [
 // Agents Grid
 Expanded(
 child: GridView.builder(
 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
 crossAxisCount: 3,
 crossAxisSpacing: SpacingTokens.componentSpacing,
 mainAxisSpacing: SpacingTokens.componentSpacing,
 childAspectRatio: 1.6,
 ),
 itemCount: agents.length,
 itemBuilder: (context, index) {
 final agent = agents[index];
 return _AgentCard(agent: agent);
 },
 ),
 ),
 ],
 );
 },
 loading: () => Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 CircularProgressIndicator(
 color: ThemeColors(context).primary,
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'Loading your agents...',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 error: (error, stack) => Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.error_outline,
 size: 48,
 color: ThemeColors(context).error,
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'Failed to load agents',
 style: TextStyles.bodyLarge.copyWith(
 color: ThemeColors(context).error,
 ),
 ),
 SizedBox(height: SpacingTokens.xs),
 Text(
 error.toString(),
 style: TextStyles.bodySmall.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 AsmblButton.secondary(
 text: 'Retry',
 onPressed: () {
 ref.invalidate(agentsProvider);
 },
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildAgentLibraryContent() {
 return Column(
 children: [
 // Search and Filter Section - Responsive Layout
 LayoutBuilder(
 builder: (context, constraints) {
 // Determine if we should stack (when width is less than 800px)
 final shouldStack = constraints.maxWidth < 800;
 
 if (shouldStack) {
 // Stacked layout for smaller screens
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Search Bar (full width when stacked)
 AsmblCard(
 child: TextField(
 onChanged: (value) => setState(() => searchQuery = value),
 decoration: InputDecoration(
 hintText: 'Search templates...',
 hintStyle: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 prefixIcon: Icon(
 Icons.search,
 color: ThemeColors(context).onSurfaceVariant,
 size: 18,
 ),
 border: InputBorder.none,
 contentPadding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing, 
 vertical: SpacingTokens.sm,
 ),
 ),
 style: TextStyles.bodyMedium.copyWith(color: ThemeColors(context).onSurface),
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // Filter Chips
 Wrap(
 spacing: SpacingTokens.xs,
 runSpacing: SpacingTokens.xs,
 children: _buildFilterChips(),
 ),
 ],
 );
 } else {
 // Horizontal layout for larger screens
 return Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Search Bar (flexible width)
 Expanded(
 flex: 2,
 child: AsmblCard(
 child: TextField(
 onChanged: (value) => setState(() => searchQuery = value),
 decoration: InputDecoration(
 hintText: 'Search templates...',
 hintStyle: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 prefixIcon: Icon(
 Icons.search,
 color: ThemeColors(context).onSurfaceVariant,
 size: 18,
 ),
 border: InputBorder.none,
 contentPadding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing, 
 vertical: SpacingTokens.sm,
 ),
 ),
 style: TextStyles.bodyMedium.copyWith(color: ThemeColors(context).onSurface),
 ),
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 
 // Filter Chips (flexible width)
 Expanded(
 flex: 3,
 child: Wrap(
 spacing: SpacingTokens.xs,
 runSpacing: SpacingTokens.xs,
 children: _buildFilterChips(),
 ),
 ),
 ],
 );
 }
 },
 ),
 SizedBox(height: SpacingTokens.elementSpacing),
 // Templates Grid
 Expanded(
 child: filteredTemplates.isEmpty 
 ? _buildEmptyState()
 : GridView.builder(
 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
 crossAxisCount: 3,
 crossAxisSpacing: SpacingTokens.componentSpacing,
 mainAxisSpacing: SpacingTokens.componentSpacing,
 childAspectRatio: 1.4,
 ),
 itemCount: filteredTemplates.length,
 itemBuilder: (context, index) {
 return _TemplateCard(
 template: filteredTemplates[index],
 onUseTemplate: () => _useTemplate(filteredTemplates[index]),
 );
 },
 ),
 ),
 ],
 );
 }

 void _useTemplate(AgentTemplate template) {
 // Navigate to agent wizard with this template pre-populated
 context.go('${AppRoutes.agentWizard}?template=${Uri.encodeComponent(template.name)}');
 }

 IconData _getCategoryIcon(String category) {
 switch (category) {
 case 'Research': return Icons.search;
 case 'Development': return Icons.code;
 case 'Writing': return Icons.edit;
 case 'Data Analysis': return Icons.analytics;
 case 'Customer Support': return Icons.support_agent;
 case 'Marketing': return Icons.campaign;
 case 'Design': return Icons.design_services;
 default: return Icons.smart_toy;
 }
 }

 List<Widget> _buildFilterChips() {
 return categories.map((category) {
 final isSelected = selectedCategory == category;
 return GestureDetector(
 onTap: () => setState(() => selectedCategory = category),
 child: Container(
 padding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing,
 vertical: SpacingTokens.xs,
 ),
 decoration: BoxDecoration(
 color: isSelected 
 ? ThemeColors(context).primary 
 : ThemeColors(context).surfaceVariant.withValues(alpha: 0.7),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
 border: Border.all(
 color: isSelected 
 ? ThemeColors(context).primary 
 : ThemeColors(context).border,
 width: 1,
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 if (category != 'All') ...[
 Icon(
 _getCategoryIcon(category),
 size: 12,
 color: isSelected 
 ? Colors.white 
 : ThemeColors(context).onSurfaceVariant,
 ),
 SizedBox(width: 4),
 ],
 Text(
 category,
 style: TextStyles.caption.copyWith(
 color: isSelected 
 ? Colors.white 
 : ThemeColors(context).onSurfaceVariant,
 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
 fontSize: 11,
 ),
 ),
 ],
 ),
 ),
 );
 }).toList();
 }

 Widget _buildEmptyState() {
 return Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.search_off,
 size: 48,
 color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.5),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'No templates found',
 style: TextStyles.bodyLarge.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 SizedBox(height: SpacingTokens.xs),
 Text(
 'Try adjusting your search or filters',
 style: TextStyles.bodySmall.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 AsmblButton.secondary(
 text: 'Clear Filters',
 onPressed: () {
 setState(() {
 searchQuery = '';
 selectedCategory = 'All';
 });
 },
 ),
 ],
 ),
 );
 }

 Widget _buildEmptyAgentsState() {
 return Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.smart_toy_outlined,
 size: 64,
 color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.5),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'No agents yet',
 style: TextStyles.bodyLarge.copyWith(
 color: ThemeColors(context).onSurface,
 fontWeight: FontWeight.bold,
 ),
 ),
 SizedBox(height: SpacingTokens.xs),
 Text(
 'Create your first AI agent to get started',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 SizedBox(height: SpacingTokens.sectionSpacing),
 AsmblButton.primary(
 text: 'Create Agent',
 onPressed: () {
 context.go(AppRoutes.agentWizard);
 },
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 AsmblButton.secondary(
 text: 'Browse Templates',
 onPressed: () {
 setState(() => selectedTab = 1);
 },
 ),
 ],
 ),
 );
 }
}

class _AgentCard extends StatelessWidget {
 final Agent agent;

 const _AgentCard({required this.agent});

 @override
 Widget build(BuildContext context) {
 return AsmblCard(
 onTap: () {
 // Navigate to agent chat
 context.go('${AppRoutes.chat}?agent=${agent.id}');
 },
 child: Padding(
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header with icon, name, and actions
 Row(
 children: [
 // Icon with status indicator
 Stack(
 alignment: Alignment.bottomRight,
 children: [
 Container(
 padding: EdgeInsets.all(SpacingTokens.xs),
 decoration: BoxDecoration(
 color: ThemeColors(context).surfaceVariant,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Icon(
 Icons.smart_toy,
 size: 18,
 color: ThemeColors(context).primary,
 ),
 ),
 // Status indicator
 Container(
 width: 6,
 height: 6,
 decoration: BoxDecoration(
 color: agent.status == AgentStatus.idle 
 ? ThemeColors(context).success 
 : ThemeColors(context).onSurfaceVariant,
 shape: BoxShape.circle,
 border: Border.all(
 color: ThemeColors(context).surface,
 width: 1,
 ),
 ),
 ),
 ],
 ),
 SizedBox(width: SpacingTokens.sm),
 
 // Agent name and category
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 agent.name,
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurface,
 fontWeight: FontWeight.w600,
 fontSize: 13,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 SizedBox(height: 2),
 Text(
 agent.capabilities.isNotEmpty ? agent.capabilities.first : 'General',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 10,
 ),
 ),
 ],
 ),
 ),
 
 // Action buttons
 Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 IconButton(
 icon: Icon(
 Icons.edit,
 size: 14,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 padding: EdgeInsets.all(4),
 constraints: const BoxConstraints(
 minWidth: 24,
 minHeight: 24,
 ),
 onPressed: () {
 context.go('/agents/configure/${agent.id}');
 },
 tooltip: 'Edit',
 ),
 PopupMenuButton(
 icon: Icon(
 Icons.more_vert,
 color: ThemeColors(context).onSurfaceVariant,
 size: 14,
 ),
 padding: EdgeInsets.zero,
 iconSize: 14,
 itemBuilder: (context) => [
 PopupMenuItem(
 value: 'duplicate',
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.copy, size: 12, color: ThemeColors(context).onSurface),
 SizedBox(width: 6),
 Text('Duplicate', style: TextStyle(fontSize: 11, color: ThemeColors(context).onSurface)),
 ],
 ),
 ),
 PopupMenuItem(
 value: 'delete',
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.delete, color: Colors.red, size: 12),
 SizedBox(width: 6),
 Text('Delete', style: TextStyle(color: Colors.red, fontSize: 11)),
 ],
 ),
 ),
 ],
 onSelected: (value) {
 // Handle menu actions
 },
 ),
 ],
 ),
 ],
 ),
 
 SizedBox(height: SpacingTokens.sm),
 
 // Recent chat preview
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(
 Icons.info_outline,
 size: 11,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 SizedBox(width: 4),
 Text(
 'Description',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 10,
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ),
 SizedBox(height: 4),
 
 // Agent description
 Container(
 padding: EdgeInsets.all(SpacingTokens.xs),
 decoration: BoxDecoration(
 color: ThemeColors(context).surfaceVariant.withValues(alpha: 0.3),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 border: Border.all(
 color: ThemeColors(context).border.withValues(alpha: 0.5),
 width: 0.5,
 ),
 ),
 child: Text(
 agent.description,
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurface,
 fontSize: 10,
 height: 1.2,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 
 Spacer(),
 
 // Stats row
 Row(
 children: [
 Icon(
 Icons.hub,
 size: 10,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 SizedBox(width: 3),
 Text(
 '${agent.capabilities.length} capabilities',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 9,
 fontWeight: FontWeight.w500,
 ),
 ),
 SizedBox(width: SpacingTokens.xs),
 Icon(
 Icons.circle,
 size: 8,
 color: agent.status == AgentStatus.idle 
 ? ThemeColors(context).success 
 : ThemeColors(context).onSurfaceVariant,
 ),
 SizedBox(width: 3),
 Expanded(
 child: Text(
 agent.status == AgentStatus.idle ? 'Ready' : 'Busy',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 9,
 ),
 overflow: TextOverflow.ellipsis,
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
 );
 }

}

class _TabButton extends StatelessWidget {
 final String text;
 final bool isSelected;
 final VoidCallback onTap;

 const _TabButton({
 required this.text,
 required this.isSelected,
 required this.onTap,
 });

 @override
 Widget build(BuildContext context) {
 return isSelected 
 ? AsmblButton.primary(text: text, onPressed: onTap)
 : AsmblButton.secondary(text: text, onPressed: onTap);
 }
}

class _TemplateCard extends StatelessWidget {
 final AgentTemplate template;
 final VoidCallback onUseTemplate;

 const _TemplateCard({
 required this.template,
 required this.onUseTemplate,
 });

 @override
 Widget build(BuildContext context) {
 return AsmblCard(
 onTap: template.isComingSoon ? null : onUseTemplate,
 child: Padding(
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header with icon, name, and popularity
 Row(
 children: [
 // Icon
 Container(
 padding: EdgeInsets.all(SpacingTokens.xs),
 decoration: BoxDecoration(
 color: ThemeColors(context).surfaceVariant,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Icon(
 _getCategoryIcon(template.category),
 size: 18,
 color: ThemeColors(context).primary,
 ),
 ),
 SizedBox(width: SpacingTokens.sm),
 
 // Template name and category
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Expanded(
 child: Text(
 template.name,
 style: TextStyles.bodyMedium.copyWith(
 color: template.isComingSoon 
 ? ThemeColors(context).onSurfaceVariant
 : ThemeColors(context).onSurface,
 fontWeight: FontWeight.w600,
 fontSize: 13,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 if (template.isComingSoon) ...[
 SizedBox(width: 6),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
 decoration: BoxDecoration(
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 ),
 child: Text(
 'SOON',
 style: TextStyles.caption.copyWith(
 fontSize: 8,
 fontWeight: FontWeight.bold,
 color: ThemeColors(context).primary,
 ),
 ),
 ),
 ],
 ],
 ),
 SizedBox(height: 2),
 Text(
 template.category,
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 10,
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 
 SizedBox(height: SpacingTokens.sm),
 
 // Example use case preview
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(
 Icons.lightbulb_outline,
 size: 11,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 SizedBox(width: 4),
 Text(
 'Example Use',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 10,
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ),
 SizedBox(height: 4),
 
 // Example use case
 Container(
 padding: EdgeInsets.all(SpacingTokens.xs),
 decoration: BoxDecoration(
 color: ThemeColors(context).primary.withValues(alpha: 0.05),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 border: Border.all(
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 width: 0.5,
 ),
 ),
 child: Text(
 template.exampleUse,
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurface,
 fontSize: 10,
 height: 1.2,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 
 Spacer(),
 
 // MCP servers preview
 if (template.mcpServers.isNotEmpty) ...[
 SizedBox(height: 6),
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
 decoration: BoxDecoration(
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 Icons.hub,
 size: 10,
 color: ThemeColors(context).primary,
 ),
 SizedBox(width: 2),
 Text(
 'MCP',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).primary,
 fontSize: 8,
 fontWeight: FontWeight.bold,
 ),
 ),
 ],
 ),
 ),
 SizedBox(width: 6),
 Text(
 '${template.mcpServers.length} integrations',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 9,
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ),
 SizedBox(height: 4),
 Wrap(
 spacing: 3,
 runSpacing: 2,
 children: template.mcpServers.take(4).map((server) {
 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
 decoration: BoxDecoration(
 color: ThemeColors(context).surfaceVariant.withValues(alpha: 0.5),
 borderRadius: BorderRadius.circular(3),
 border: Border.all(
 color: ThemeColors(context).primary.withValues(alpha: 0.2),
 width: 0.5,
 ),
 ),
 child: Text(
 server,
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).primary,
 fontSize: 8,
 fontWeight: FontWeight.w500,
 ),
 ),
 );
 }).toList(),
 ),
 if (template.mcpServers.length > 4)
 Padding(
 padding: const EdgeInsets.only(top: 2),
 child: Text(
 '+${template.mcpServers.length - 4} more',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 8,
 fontStyle: FontStyle.italic,
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
 ),
 );
 }

 IconData _getCategoryIcon(String category) {
 switch (category) {
 case 'Research': return Icons.search;
 case 'Development': return Icons.code;
 case 'Writing': return Icons.edit;
 case 'Data Analysis': return Icons.analytics;
 case 'Customer Support': return Icons.support_agent;
 case 'Marketing': return Icons.campaign;
 case 'Design': return Icons.design_services;
 default: return Icons.smart_toy;
 }
 }

 IconData _getMCPServerIcon(String server) {
 switch (server) {
 case 'Files': return Icons.folder;
 case 'Git': return Icons.code;
 case 'Postgres': return Icons.storage;
 case 'Filesystem': return Icons.description;
 case 'Memory': return Icons.memory;
 case 'Time': return Icons.schedule;
 case 'GitHub': return Icons.code_outlined;
 case 'Slack': return Icons.chat;
 case 'Linear': return Icons.assignment;
 case 'Notion': return Icons.note;
 case 'Brave Search': return Icons.search;
 case 'Figma': return Icons.design_services;
 default: return Icons.extension;
 }
 }

 Color _getPopularityColor(int popularity, BuildContext context) {
 if (popularity >= 90) {
 return Colors.green.shade600;
 } else if (popularity >= 80) {
 return Colors.orange.shade600;
 } else {
 return ThemeColors(context).primary;
 }
 }
}

class AgentTemplate {
 final String name;
 final String description;
 final String category;
 final List<String> tags;
 final bool mcpStack;
 final List<String> mcpServers;
 final String exampleUse;
 final int popularity;
 final bool isComingSoon;

 AgentTemplate({
 required this.name,
 required this.description,
 required this.category,
 required this.tags,
 required this.mcpStack,
 required this.mcpServers,
 required this.exampleUse,
 required this.popularity,
 this.isComingSoon = false,
 });
}

