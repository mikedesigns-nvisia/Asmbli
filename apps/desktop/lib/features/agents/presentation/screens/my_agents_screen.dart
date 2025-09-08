import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../providers/agent_provider.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../widgets/enhanced_agent_card.dart';
import '../widgets/enhanced_agent_template_card.dart';
import '../../../agents/data/models/agent_template.dart';

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
 const AppNavigationBar(currentRoute: AppRoutes.agents),

 // Main Content
 Expanded(
 child: Padding(
 padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
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
 const SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 selectedTab == 0 
 ? 'Manage and organize your AI-powered assistants'
 : 'Start with a pre-built template and customize it to your needs',
 style: TextStyles.bodyLarge.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 const SizedBox(height: SpacingTokens.sectionSpacing),

 // Tab Selector
 Row(
 children: [
 _TabButton(
 text: 'My Agents',
 isSelected: selectedTab == 0,
 onTap: () => setState(() => selectedTab = 0),
 ),
 const SizedBox(width: SpacingTokens.componentSpacing),
 _TabButton(
 text: 'Agent Library',
 isSelected: selectedTab == 1,
 onTap: () => setState(() => selectedTab = 1),
 ),
 ],
 ),
 const SizedBox(height: SpacingTokens.sectionSpacing),

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
 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
 crossAxisCount: 4,
 crossAxisSpacing: SpacingTokens.componentSpacing,
 mainAxisSpacing: SpacingTokens.componentSpacing,
 childAspectRatio: 0.9,
 ),
 itemCount: agents.length,
 itemBuilder: (context, index) {
 final agent = agents[index];
 return EnhancedAgentCard(
   agent: agent,
   onEdit: () => _editAgent(agent),
   onDelete: () => _deleteAgent(agent),
   onDuplicate: () => _duplicateAgent(agent),
 );
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
 const SizedBox(height: SpacingTokens.componentSpacing),
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
 const SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'Failed to load agents',
 style: TextStyles.bodyLarge.copyWith(
 color: ThemeColors(context).error,
 ),
 ),
 const SizedBox(height: SpacingTokens.xs),
 Text(
 error.toString(),
 style: TextStyles.bodySmall.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
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
 contentPadding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing, 
 vertical: SpacingTokens.sm,
 ),
 ),
 style: TextStyles.bodyMedium.copyWith(color: ThemeColors(context).onSurface),
 ),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 
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
 contentPadding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing, 
 vertical: SpacingTokens.sm,
 ),
 ),
 style: TextStyles.bodyMedium.copyWith(color: ThemeColors(context).onSurface),
 ),
 ),
 ),
 const SizedBox(width: SpacingTokens.componentSpacing),
 
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
 const SizedBox(height: SpacingTokens.elementSpacing),
 // Templates Grid
 Expanded(
 child: filteredTemplates.isEmpty 
 ? _buildEmptyState()
 : GridView.builder(
 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
 crossAxisCount: 4,
 crossAxisSpacing: SpacingTokens.componentSpacing,
 mainAxisSpacing: SpacingTokens.componentSpacing,
 childAspectRatio: 0.8,
 ),
 itemCount: filteredTemplates.length,
 itemBuilder: (context, index) {
 return EnhancedAgentTemplateCard(
 template: filteredTemplates[index],
 onUseTemplate: () => _useTemplate(filteredTemplates[index]),
 onPreview: () => _previewTemplate(filteredTemplates[index]),
 );
 },
 ),
 ),
 ],
 );
 }

 void _useTemplate(AgentTemplate template) async {
 // Create a new agent from template using agent provider
 final agentNotifier = ref.read(agentNotifierProvider.notifier);
 
 try {
   final newAgent = Agent(
     id: 'agent_${DateTime.now().millisecondsSinceEpoch}',
     name: template.name.replaceAll(' (Template)', ''),
     description: template.description.split(' - ').first,
     capabilities: _getCapabilitiesFromTemplate(template),
     configuration: {
       'systemPrompt': _generateSystemPromptFromTemplate(template),
       'temperature': 0.7,
       'maxTokens': 2048,
       'source_template': template.name,
       'category': template.category,
       'mcpServers': template.mcpServers,
     },
   );
   
   await agentNotifier.createAgent(newAgent);
   
   // Navigate to agent configuration screen to edit the new agent
   context.go('/agents/configure/${newAgent.id}');
 } catch (e) {
   // If agent creation fails, just navigate to new agent screen
   context.go('/agents/configure');
 }
 }
 
 void _editAgent(Agent agent) {
   context.go('/agents/configure/${agent.id}');
 }
 
 void _deleteAgent(Agent agent) {
   // Show confirmation dialog and delete agent
   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       backgroundColor: ThemeColors(context).surface,
       title: Text(
         'Delete Agent',
         style: TextStyles.cardTitle.copyWith(
           color: ThemeColors(context).onSurface,
         ),
       ),
       content: Text(
         'Are you sure you want to delete "${agent.name}"? This action cannot be undone.',
         style: TextStyles.bodyMedium.copyWith(
           color: ThemeColors(context).onSurfaceVariant,
         ),
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.of(context).pop(),
           child: const Text('Cancel'),
         ),
         TextButton(
           onPressed: () async {
             Navigator.of(context).pop();
             try {
               final agentNotifier = ref.read(agentNotifierProvider.notifier);
               await agentNotifier.deleteAgent(agent.id);
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Deleted "${agent.name}"')),
               );
             } catch (e) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text('Failed to delete agent: $e'),
                   backgroundColor: ThemeColors(context).error,
                 ),
               );
             }
           },
           style: TextButton.styleFrom(
             foregroundColor: ThemeColors(context).error,
           ),
           child: const Text('Delete'),
         ),
       ],
     ),
   );
 }
 
 void _duplicateAgent(Agent agent) async {
   try {
     final agentNotifier = ref.read(agentNotifierProvider.notifier);
     final duplicatedAgent = Agent(
       id: 'agent_${DateTime.now().millisecondsSinceEpoch}',
       name: '${agent.name} (Copy)',
       description: agent.description,
       capabilities: List.from(agent.capabilities),
       configuration: Map.from(agent.configuration ?? {}),
       status: AgentStatus.idle,
     );
     
     await agentNotifier.createAgent(duplicatedAgent);
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Duplicated "${agent.name}"')),
     );
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text('Failed to duplicate agent: $e'),
         backgroundColor: ThemeColors(context).error,
       ),
     );
   }
 }
 
 void _previewTemplate(AgentTemplate template) {
   showDialog(
     context: context,
     builder: (context) => Dialog(
       backgroundColor: ThemeColors(context).surface,
       child: Container(
         width: MediaQuery.of(context).size.width * 0.8,
         height: MediaQuery.of(context).size.height * 0.8,
         padding: EdgeInsets.all(SpacingTokens.xl),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(SpacingTokens.sm),
                   decoration: BoxDecoration(
                     color: ThemeColors(context).primary.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                   ),
                   child: Icon(
                     _getCategoryIcon(template.category),
                     color: ThemeColors(context).primary,
                     size: 24,
                   ),
                 ),
                 SizedBox(width: SpacingTokens.sm),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         template.name,
                         style: TextStyles.pageTitle.copyWith(
                           color: ThemeColors(context).onSurface,
                         ),
                       ),
                       Text(
                         template.category,
                         style: TextStyles.bodyMedium.copyWith(
                           color: ThemeColors(context).primary,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ],
                   ),
                 ),
                 IconButton(
                   onPressed: () => Navigator.of(context).pop(),
                   icon: Icon(Icons.close, color: ThemeColors(context).onSurfaceVariant),
                 ),
               ],
             ),
             SizedBox(height: SpacingTokens.lg),
             
             // Description
             Text(
               'Description',
               style: TextStyles.bodyLarge.copyWith(
                 color: ThemeColors(context).onSurface,
                 fontWeight: FontWeight.w600,
               ),
             ),
             SizedBox(height: SpacingTokens.sm),
             Text(
               template.description,
               style: TextStyles.bodyMedium.copyWith(
                 color: ThemeColors(context).onSurfaceVariant,
                 height: 1.6,
               ),
             ),
             
             SizedBox(height: SpacingTokens.lg),
             
             // Example Use Case
             Text(
               'Example Use Case',
               style: TextStyles.bodyLarge.copyWith(
                 color: ThemeColors(context).onSurface,
                 fontWeight: FontWeight.w600,
               ),
             ),
             SizedBox(height: SpacingTokens.sm),
             Container(
               width: double.infinity,
               padding: EdgeInsets.all(SpacingTokens.sm),
               decoration: BoxDecoration(
                 color: ThemeColors(context).primary.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                 border: Border.all(color: ThemeColors(context).primary.withOpacity(0.2)),
               ),
               child: Text(
                 template.exampleUse,
                 style: TextStyles.bodyMedium.copyWith(
                   color: ThemeColors(context).onSurface,
                   height: 1.6,
                 ),
               ),
             ),
             
             if (template.mcpServers.isNotEmpty) ...[
               SizedBox(height: SpacingTokens.lg),
               Text(
                 'MCP Integrations',
                 style: TextStyles.bodyLarge.copyWith(
                   color: ThemeColors(context).onSurface,
                   fontWeight: FontWeight.w600,
                 ),
               ),
               SizedBox(height: SpacingTokens.sm),
               Wrap(
                 spacing: SpacingTokens.sm,
                 runSpacing: SpacingTokens.sm,
                 children: template.mcpServers.map((server) {
                   return Container(
                     padding: EdgeInsets.symmetric(
                       horizontal: SpacingTokens.sm,
                       vertical: SpacingTokens.xs,
                     ),
                     decoration: BoxDecoration(
                       color: ThemeColors(context).surfaceVariant,
                       borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                       border: Border.all(color: ThemeColors(context).primary.withOpacity(0.3)),
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(
                           Icons.hub,
                           size: 14,
                           color: ThemeColors(context).primary,
                         ),
                         SizedBox(width: SpacingTokens.xs),
                         Text(
                           server,
                           style: TextStyles.bodySmall.copyWith(
                             color: ThemeColors(context).onSurface,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ],
                     ),
                   );
                 }).toList(),
               ),
             ],
             
             Spacer(),
             
             // Action buttons
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 AsmblButton.secondary(
                   text: 'Close',
                   onPressed: () => Navigator.of(context).pop(),
                 ),
                 SizedBox(width: SpacingTokens.sm),
                 AsmblButton.primary(
                   text: template.isComingSoon ? 'Coming Soon' : 'Use Template',
                   onPressed: template.isComingSoon ? null : () {
                     Navigator.of(context).pop();
                     _useTemplate(template);
                   },
                 ),
               ],
             ),
           ],
         ),
       ),
     ),
   );
 }
 
 List<String> _getCapabilitiesFromTemplate(AgentTemplate template) {
   switch (template.category) {
     case 'Research':
       return ['research', 'analysis', 'citation', 'fact-checking'];
     case 'Development':
       return ['coding', 'debugging', 'code-review', 'testing'];
     case 'Writing':
       return ['content-creation', 'editing', 'seo', 'copywriting'];
     case 'Data Analysis':
       return ['data-analysis', 'visualization', 'statistics', 'reporting'];
     case 'Customer Support':
       return ['customer-service', 'troubleshooting', 'communication', 'ticket-management'];
     case 'Marketing':
       return ['marketing', 'campaigns', 'analytics', 'strategy'];
     default:
       return ['general-assistance', 'problem-solving', 'communication'];
   }
 }
 
 String _generateSystemPromptFromTemplate(AgentTemplate template) {
   switch (template.category) {
     case 'Research':
       return '''You are a helpful research assistant specializing in ${template.name.toLowerCase()}. You excel at:

• Finding and analyzing relevant information from multiple sources
• Providing accurate citations and references  
• Synthesizing complex information into clear summaries
• Fact-checking and verifying information accuracy

Always provide well-sourced, objective information and clearly indicate when something is uncertain or requires verification.''';

     case 'Development': 
       return '''You are an expert ${template.name.toLowerCase()} focused on software development. Your strengths include:

• Writing clean, efficient, and maintainable code
• Following best practices and coding standards
• Debugging and troubleshooting technical issues
• Code review and optimization suggestions
• Explaining complex technical concepts clearly

Always provide well-commented code examples and explain your reasoning behind technical decisions.''';

     case 'Writing':
       return '''You are a professional ${template.name.toLowerCase()} who helps with content creation. You specialize in:

• Creating engaging, well-structured content
• Adapting tone and style to target audiences  
• Grammar, style, and clarity improvements
• SEO optimization and readability
• Creative and persuasive writing techniques

Always maintain high writing standards while preserving the author's unique voice and intent.''';

     case 'Data Analysis':
       return '''You are a skilled ${template.name.toLowerCase()} with expertise in data science. You excel at:

• Statistical analysis and data interpretation
• Data visualization and reporting
• Identifying patterns and trends in datasets
• Providing actionable insights from data
• Explaining complex analytical concepts simply

Always provide clear explanations of your analytical methods and ensure recommendations are data-driven.''';

     case 'Customer Support':
       return '''You are a friendly and efficient ${template.name.toLowerCase()}. Your core capabilities include:

• Providing helpful, accurate customer service
• Troubleshooting common issues step-by-step  
• Escalating complex problems appropriately
• Maintaining professional, empathetic communication
• Following company policies and procedures

Always prioritize customer satisfaction while being helpful, patient, and solution-focused.''';

     case 'Marketing':
       return '''You are a creative ${template.name.toLowerCase()} with expertise in marketing strategy. You specialize in:

• Developing effective marketing campaigns
• Understanding target audience needs and behaviors
• Creating compelling content and messaging
• Analyzing marketing performance and ROI
• Staying current with marketing trends and best practices  

Always focus on data-driven strategies that deliver measurable results and authentic brand engagement.''';

     default:
       return '''You are a helpful AI assistant specializing in ${template.name.toLowerCase()}. 

Please customize this system prompt to define:
• Your specific role and expertise
• Key capabilities and strengths  
• How you approach tasks and problems
• Your communication style and tone
• Any important guidelines or limitations

This template gives you a starting point - modify it to create your perfect AI assistant!''';
   }
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
 padding: const EdgeInsets.symmetric(
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
 const SizedBox(width: 4),
 ],
 Text(
 category,
 style: TextStyles.caption.copyWith(
 color: isSelected 
 ? Colors.white 
 : ThemeColors(context).onSurfaceVariant,
 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
 const SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'No templates found',
 style: TextStyles.bodyLarge.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 const SizedBox(height: SpacingTokens.xs),
 Text(
 'Try adjusting your search or filters',
 style: TextStyles.bodySmall.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
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
 const SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'No agents yet',
 style: TextStyles.bodyLarge.copyWith(
 color: ThemeColors(context).onSurface,
 fontWeight: FontWeight.bold,
 ),
 ),
 const SizedBox(height: SpacingTokens.xs),
 Text(
 'Create your first AI agent to get started',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 const SizedBox(height: SpacingTokens.sectionSpacing),
 AsmblButton.primary(
 text: 'Create Agent',
 onPressed: () {
 context.go('/agents/configure');
 },
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
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
 padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
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
 padding: const EdgeInsets.all(SpacingTokens.xs),
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
 const SizedBox(width: SpacingTokens.sm),
 
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
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 const SizedBox(height: 2),
 Text(
 agent.capabilities.isNotEmpty ? agent.capabilities.first : 'General',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
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
 padding: const EdgeInsets.all(4),
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
 const SizedBox(width: 6),
 Text('Duplicate', style: TextStyles.caption.copyWith(color: ThemeColors(context).onSurface)),
 ],
 ),
 ),
 const PopupMenuItem(
 value: 'delete',
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.delete, color: Colors.red, size: 12),
 SizedBox(width: 6),
 Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
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
 
 const SizedBox(height: SpacingTokens.sm),
 
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
 const SizedBox(width: 4),
 Text(
 'Description',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ),
 const SizedBox(height: 4),
 
 // Agent description
 Container(
 padding: const EdgeInsets.all(SpacingTokens.xs),
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
 height: 1.2,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 
 const Spacer(),
 
 // Stats row
 Row(
 children: [
 Icon(
 Icons.hub,
 size: 10,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 const SizedBox(width: 3),
 Text(
 '${agent.capabilities.length} capabilities',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontWeight: FontWeight.w500,
 ),
 ),
 const SizedBox(width: SpacingTokens.xs),
 Icon(
 Icons.circle,
 size: 8,
 color: agent.status == AgentStatus.idle 
 ? ThemeColors(context).success 
 : ThemeColors(context).onSurfaceVariant,
 ),
 const SizedBox(width: 3),
 Expanded(
 child: Text(
 agent.status == AgentStatus.idle ? 'Ready' : 'Busy',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
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


