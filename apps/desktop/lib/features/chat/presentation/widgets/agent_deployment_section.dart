import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../settings/presentation/widgets/mcp_health_status_widget.dart';
import '../../../../providers/conversation_provider.dart';
import 'package:agent_engine_core/models/conversation.dart';

/// Widget for real agent loading and preview in the chat sidebar
class AgentLoaderSection extends ConsumerStatefulWidget {
 const AgentLoaderSection({super.key});

 @override
 ConsumerState<AgentLoaderSection> createState() => _AgentLoaderSectionState();
}

class _AgentLoaderSectionState extends ConsumerState<AgentLoaderSection> {
 bool _isExpanded = true;
 String? _loadingAgentId;
 String? _previousConversationId;
 
 @override
 void didChangeDependencies() {
 super.didChangeDependencies();
 
 // Check if conversation selection changed
 final currentConversationId = ref.read(selectedConversationIdProvider);
 if (_previousConversationId != currentConversationId) {
 // Clear manual agent selection when switching conversations
 if (currentConversationId != null) {
 WidgetsBinding.instance.addPostFrameCallback((_) {
 if (mounted) {
 ref.read(selectedAgentPreviewProvider.notifier).state = null;
 }
 });
 }
 _previousConversationId = currentConversationId;
 }
 }

 // Production agent data with real ChatMCP server configurations
 final List<ProductionAgent> _agents = [
 ProductionAgent(
 id: 'research-assistant',
 name: 'Research Assistant',
 description: 'Academic research with citations and memory',
 systemPrompt: 'You are a research assistant specialized in academic research, fact-checking, and citation management. You have access to web search, persistent memory, and file systems. Always provide accurate sources and maintain academic standards. Use your memory to track research progress and build upon previous findings.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['web-search', 'memory', 'filesystem'],
 mcpServerConfigs: {
 'web-search': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-brave-search'],
 env: {'BRAVE_API_KEY': '\${BRAVE_API_KEY}'},
 description: 'Web search capabilities via Brave Search',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Persistent memory and knowledge management',
 ),
 'filesystem': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-filesystem', '\${HOME}/Documents', '\${HOME}/Projects'],
 description: 'Local file system access and management',
 ),
 },
 contextDocuments: ['research_guidelines.md', 'citation_formats.pdf'],
 isActive: true,
 ),
 ProductionAgent(
 id: 'code-reviewer',
 name: 'Code Reviewer',
 description: 'Full-stack code review with Git integration',
 systemPrompt: 'You are a senior software engineer focused on code quality, security, and best practices. You have access to Git repositories, GitHub, the filesystem, and persistent memory. Review code thoroughly, provide constructive feedback, and help maintain high coding standards. Use Git integration to understand change context and history.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['git', 'github', 'filesystem', 'memory'],
 mcpServerConfigs: {
 'git': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-git'],
 description: 'Git repository operations and version control',
 ),
 'github': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-github'],
 env: {'GITHUB_PERSONAL_ACCESS_TOKEN': '\${GITHUB_PERSONAL_ACCESS_TOKEN}'},
 description: 'GitHub repository access and management',
 ),
 'filesystem': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-filesystem', '\${HOME}/Documents', '\${HOME}/Projects'],
 description: 'Local file system access and management',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Persistent memory and knowledge management',
 ),
 },
 contextDocuments: ['coding_standards.md', 'security_checklist.md'],
 isActive: true,
 ),
 ProductionAgent(
 id: 'content-writer',
 name: 'Content Writer',
 description: 'SEO content creation with research capabilities',
 systemPrompt: 'You are a content writer specialized in SEO-optimized content creation. You have access to web search, web content fetching, persistent memory, and file systems. Focus on engaging, well-structured content that ranks well. Research topics thoroughly and build a knowledge base of content strategies.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['web-search', 'web-fetch', 'memory', 'filesystem'],
 mcpServerConfigs: {
 'web-search': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-brave-search'],
 env: {'BRAVE_API_KEY': '\${BRAVE_API_KEY}'},
 description: 'Web search capabilities via Brave Search',
 ),
 'web-fetch': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-fetch'],
 description: 'Web content fetching and processing',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Persistent memory and knowledge management',
 ),
 'filesystem': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-filesystem', '\${HOME}/Documents', '\${HOME}/Projects'],
 description: 'Local file system access and management',
 ),
 },
 contextDocuments: ['seo_guidelines.md', 'brand_voice.md', 'content_calendar.md'],
 isActive: true,
 ),
 ProductionAgent(
 id: 'devops-engineer',
 name: 'DevOps Engineer',
 description: 'Infrastructure automation and deployment specialist',
 systemPrompt: 'You are a DevOps engineer specializing in infrastructure as code, CI/CD pipelines, and cloud deployments. You have access to Docker, Kubernetes, AWS services, and shell commands. Focus on automation, reliability, and security best practices. Help with containerization, orchestration, and deployment strategies.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['docker', 'kubernetes', 'aws', 'shell', 'memory'],
 mcpServerConfigs: {
 'docker': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-docker'],
 description: 'Docker container management and operations',
 ),
 'kubernetes': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-kubernetes'],
 description: 'Kubernetes cluster orchestration and deployment',
 ),
 'aws': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-aws'],
 env: {'AWS_ACCESS_KEY_ID': '\${AWS_ACCESS_KEY_ID}', 'AWS_SECRET_ACCESS_KEY': '\${AWS_SECRET_ACCESS_KEY}'},
 description: 'AWS services management and deployment',
 ),
 'shell': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-shell'],
 description: 'Shell command execution for automation',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Persistent memory for configuration tracking',
 ),
 },
 contextDocuments: ['deployment_playbook.md', 'infrastructure_specs.yaml', 'security_policies.md'],
 isActive: true,
 ),
 ProductionAgent(
 id: 'data-scientist',
 name: 'Data Scientist',
 description: 'ML/AI specialist with Python and data analysis tools',
 systemPrompt: 'You are a data scientist specializing in machine learning, statistical analysis, and data visualization. You have access to Python environments, Jupyter notebooks, SQL databases, and memory for tracking experiments. Focus on data-driven insights, model development, and clear visualizations. Help with exploratory data analysis, feature engineering, and model deployment.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['python', 'jupyter', 'sql', 'memory', 'filesystem'],
 mcpServerConfigs: {
 'python': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-python'],
 description: 'Python execution environment for data science',
 ),
 'jupyter': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-jupyter'],
 description: 'Jupyter notebook environment for interactive analysis',
 ),
 'sql': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-sqlite', '\${HOME}/databases'],
 description: 'SQL database access for data queries',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Experiment tracking and results storage',
 ),
 'filesystem': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-filesystem', '\${HOME}/data', '\${HOME}/models'],
 description: 'Access to datasets and model files',
 ),
 },
 contextDocuments: ['ml_pipeline.md', 'feature_definitions.csv', 'model_metrics.json'],
 isActive: true,
 ),
 ProductionAgent(
 id: 'security-analyst',
 name: 'Security Analyst',
 description: 'Cybersecurity expert with penetration testing tools',
 systemPrompt: 'You are a cybersecurity analyst focused on vulnerability assessment, penetration testing, and security hardening. You have access to security scanning tools, network analysis, and file systems. Always prioritize ethical hacking practices and responsible disclosure. Help identify vulnerabilities, suggest mitigations, and improve security posture.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['nmap', 'metasploit', 'filesystem', 'shell', 'memory'],
 mcpServerConfigs: {
 'nmap': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-nmap'],
 description: 'Network discovery and security scanning',
 ),
 'metasploit': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-metasploit'],
 description: 'Penetration testing framework',
 ),
 'filesystem': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-filesystem', '\${HOME}/security', '\${HOME}/reports'],
 description: 'Security reports and configuration access',
 ),
 'shell': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-shell'],
 description: 'Shell access for security tools',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Vulnerability tracking and audit logs',
 ),
 },
 contextDocuments: ['security_standards.md', 'vulnerability_database.json', 'compliance_checklist.md'],
 isActive: true,
 ),
 ProductionAgent(
 id: 'product-manager',
 name: 'Product Manager',
 description: 'Product strategy with Jira and analytics integration',
 systemPrompt: 'You are a product manager focused on user needs, feature prioritization, and data-driven decisions. You have access to Jira for project management, analytics tools, and documentation systems. Help with roadmap planning, user story creation, and stakeholder communication. Use data to inform product decisions and track success metrics.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['jira', 'analytics', 'slack', 'memory', 'filesystem'],
 mcpServerConfigs: {
 'jira': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-jira'],
 env: {'JIRA_API_TOKEN': '\${JIRA_API_TOKEN}', 'JIRA_URL': '\${JIRA_URL}'},
 description: 'Jira project management and issue tracking',
 ),
 'analytics': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-google-analytics'],
 env: {'GA_API_KEY': '\${GA_API_KEY}'},
 description: 'Google Analytics for user behavior insights',
 ),
 'slack': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-slack'],
 env: {'SLACK_TOKEN': '\${SLACK_TOKEN}'},
 description: 'Slack integration for team communication',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Product decisions and roadmap tracking',
 ),
 'filesystem': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-filesystem', '\${HOME}/specs', '\${HOME}/roadmaps'],
 description: 'Product specifications and documentation',
 ),
 },
 contextDocuments: ['product_roadmap.md', 'user_personas.json', 'success_metrics.md'],
 isActive: true,
 ),
 ProductionAgent(
 id: 'database-admin',
 name: 'Database Administrator',
 description: 'Database optimization with PostgreSQL and Redis',
 systemPrompt: 'You are a database administrator specializing in performance optimization, backup strategies, and data integrity. You have access to PostgreSQL, MySQL, Redis, and MongoDB. Focus on query optimization, index management, replication, and disaster recovery. Help with database design, migration strategies, and performance tuning.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['postgresql', 'mysql', 'redis', 'mongodb', 'memory'],
 mcpServerConfigs: {
 'postgresql': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-postgres'],
 env: {'POSTGRES_URL': '\${POSTGRES_URL}'},
 description: 'PostgreSQL database management',
 ),
 'mysql': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-mysql'],
 env: {'MYSQL_URL': '\${MYSQL_URL}'},
 description: 'MySQL database administration',
 ),
 'redis': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-redis'],
 env: {'REDIS_URL': '\${REDIS_URL}'},
 description: 'Redis cache and key-value store management',
 ),
 'mongodb': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-mongodb'],
 env: {'MONGODB_URL': '\${MONGODB_URL}'},
 description: 'MongoDB NoSQL database management',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Query optimization history and performance metrics',
 ),
 },
 contextDocuments: ['database_schema.sql', 'backup_procedures.md', 'performance_baselines.json'],
 isActive: true,
 ),
 ProductionAgent(
 id: 'api-architect',
 name: 'API Architect',
 description: 'RESTful and GraphQL API design specialist',
 systemPrompt: 'You are an API architect specializing in RESTful services, GraphQL, and microservices design. You have access to API testing tools, documentation generators, and monitoring services. Focus on API design best practices, versioning strategies, and developer experience. Help with OpenAPI specifications, authentication patterns, and rate limiting.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['postman', 'swagger', 'graphql', 'memory', 'filesystem'],
 mcpServerConfigs: {
 'postman': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-postman'],
 env: {'POSTMAN_API_KEY': '\${POSTMAN_API_KEY}'},
 description: 'Postman API testing and documentation',
 ),
 'swagger': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-swagger'],
 description: 'OpenAPI/Swagger specification management',
 ),
 'graphql': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-graphql'],
 description: 'GraphQL schema design and testing',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'API versioning history and design decisions',
 ),
 'filesystem': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-filesystem', '\${HOME}/apis', '\${HOME}/schemas'],
 description: 'API specifications and schema files',
 ),
 },
 contextDocuments: ['api_standards.md', 'openapi_spec.yaml', 'graphql_schema.graphql'],
 isActive: true,
 ),
 ProductionAgent(
 id: 'blockchain-developer',
 name: 'Blockchain Developer',
 description: 'Smart contract and Web3 development expert',
 systemPrompt: 'You are a blockchain developer specializing in smart contracts, DeFi protocols, and Web3 applications. You have access to Ethereum tools, IPFS, and blockchain analytics. Focus on security, gas optimization, and decentralized architecture. Help with Solidity development, contract auditing, and Web3 integration.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['ethereum', 'ipfs', 'thegraph', 'memory', 'filesystem'],
 mcpServerConfigs: {
 'ethereum': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-ethereum'],
 env: {'ETH_RPC_URL': '\${ETH_RPC_URL}', 'PRIVATE_KEY': '\${PRIVATE_KEY}'},
 description: 'Ethereum blockchain interaction and smart contracts',
 ),
 'ipfs': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-ipfs'],
 description: 'IPFS distributed storage system',
 ),
 'thegraph': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-thegraph'],
 env: {'GRAPH_API_KEY': '\${GRAPH_API_KEY}'},
 description: 'The Graph protocol for blockchain indexing',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Smart contract addresses and deployment history',
 ),
 'filesystem': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-filesystem', '\${HOME}/contracts', '\${HOME}/dapps'],
 description: 'Smart contracts and DApp source code',
 ),
 },
 contextDocuments: ['solidity_patterns.md', 'gas_optimization.md', 'audit_checklist.md'],
 isActive: true,
 ),
 ProductionAgent(
 id: 'ux-designer',
 name: 'UX Designer',
 description: 'User experience design with Figma integration',
 systemPrompt: 'You are a UX designer focused on user-centered design, accessibility, and design systems. You have access to Figma, user analytics, and design documentation. Create intuitive interfaces, conduct user research, and maintain design consistency. Help with wireframing, prototyping, and usability testing.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['figma', 'hotjar', 'airtable', 'memory', 'filesystem'],
 mcpServerConfigs: {
 'figma': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-figma'],
 env: {'FIGMA_TOKEN': '\${FIGMA_TOKEN}'},
 description: 'Figma design file access and collaboration',
 ),
 'hotjar': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-hotjar'],
 env: {'HOTJAR_API_KEY': '\${HOTJAR_API_KEY}'},
 description: 'Hotjar user behavior analytics and heatmaps',
 ),
 'airtable': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-airtable'],
 env: {'AIRTABLE_API_KEY': '\${AIRTABLE_API_KEY}'},
 description: 'Airtable for design system documentation',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Design decisions and user research insights',
 ),
 'filesystem': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-filesystem', '\${HOME}/designs', '\${HOME}/research'],
 description: 'Design assets and user research files',
 ),
 },
 contextDocuments: ['design_system.md', 'user_research.pdf', 'accessibility_guide.md'],
 isActive: true,
 ),
 ProductionAgent(
 id: 'qa-automation',
 name: 'QA Automation Engineer',
 description: 'Test automation with Selenium and Cypress',
 systemPrompt: 'You are a QA automation engineer specializing in test strategy, automation frameworks, and continuous testing. You have access to Selenium, Cypress, Jest, and performance testing tools. Focus on comprehensive test coverage, reliability, and fast feedback. Help with test planning, automation development, and quality metrics.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['selenium', 'cypress', 'jest', 'browserstack', 'memory'],
 mcpServerConfigs: {
 'selenium': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-selenium'],
 description: 'Selenium WebDriver for browser automation',
 ),
 'cypress': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-cypress'],
 description: 'Cypress end-to-end testing framework',
 ),
 'jest': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-jest'],
 description: 'Jest unit and integration testing',
 ),
 'browserstack': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-browserstack'],
 env: {'BROWSERSTACK_KEY': '\${BROWSERSTACK_KEY}'},
 description: 'BrowserStack cross-browser testing',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Test results history and coverage metrics',
 ),
 },
 contextDocuments: ['test_strategy.md', 'test_cases.json', 'automation_framework.md'],
 isActive: true,
 ),
 // Coming Soon Agents (Future MCP Servers)
 ProductionAgent(
 id: 'ai-trainer',
 name: 'AI Model Trainer',
 description: 'Fine-tuning and training custom AI models',
 systemPrompt: 'You are an AI trainer specializing in fine-tuning LLMs, training custom models, and optimizing AI performance. You will have access to Hugging Face, OpenAI fine-tuning, model evaluation tools, and GPU clusters. Focus on dataset preparation, hyperparameter tuning, and model deployment.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['huggingface', 'openai-finetune', 'wandb', 'gpu-cluster', 'memory'],
 mcpServerConfigs: {
 'huggingface': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-huggingface'],
 env: {'HF_TOKEN': '\${HF_TOKEN}'},
 description: 'Hugging Face model hub and training (Coming Soon)',
 ),
 'openai-finetune': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-openai-finetune'],
 env: {'OPENAI_API_KEY': '\${OPENAI_API_KEY}'},
 description: 'OpenAI fine-tuning API (Coming Soon)',
 ),
 'wandb': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-wandb'],
 env: {'WANDB_API_KEY': '\${WANDB_API_KEY}'},
 description: 'Weights & Biases experiment tracking (Coming Soon)',
 ),
 'gpu-cluster': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-gpu-cluster'],
 description: 'GPU cluster management for training (Coming Soon)',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Training history and model versions',
 ),
 },
 contextDocuments: ['training_pipeline.md', 'dataset_specs.json', 'evaluation_metrics.md'],
 isActive: false, // Coming soon
 ),
 ProductionAgent(
 id: 'video-creator',
 name: 'Video Content Creator',
 description: 'AI-powered video editing and generation',
 systemPrompt: 'You are a video content creator with access to AI video generation, editing tools, and streaming platforms. You will be able to create, edit, and publish video content using advanced AI tools. Focus on storytelling, visual effects, and audience engagement.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['runway', 'elevenlabs', 'youtube', 'premiere', 'memory'],
 mcpServerConfigs: {
 'runway': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-runway'],
 env: {'RUNWAY_API_KEY': '\${RUNWAY_API_KEY}'},
 description: 'Runway AI video generation (Coming Soon)',
 ),
 'elevenlabs': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-elevenlabs'],
 env: {'ELEVENLABS_API_KEY': '\${ELEVENLABS_API_KEY}'},
 description: 'ElevenLabs AI voice synthesis (Coming Soon)',
 ),
 'youtube': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-youtube'],
 env: {'YOUTUBE_API_KEY': '\${YOUTUBE_API_KEY}'},
 description: 'YouTube upload and analytics (Coming Soon)',
 ),
 'premiere': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-adobe-premiere'],
 env: {'ADOBE_API_KEY': '\${ADOBE_API_KEY}'},
 description: 'Adobe Premiere Pro integration (Coming Soon)',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Video project history and templates',
 ),
 },
 contextDocuments: ['video_scripts.md', 'brand_guidelines.pdf', 'content_calendar.json'],
 isActive: false, // Coming soon
 ),
 ProductionAgent(
 id: 'iot-engineer',
 name: 'IoT Systems Engineer',
 description: 'IoT device management and edge computing',
 systemPrompt: 'You are an IoT engineer managing connected devices, edge computing, and sensor networks. You will have access to MQTT brokers, device twins, time-series databases, and edge deployment tools. Focus on device security, data pipelines, and real-time processing.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['mqtt', 'azure-iot', 'influxdb', 'edge-deploy', 'memory'],
 mcpServerConfigs: {
 'mqtt': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-mqtt'],
 env: {'MQTT_BROKER': '\${MQTT_BROKER}'},
 description: 'MQTT broker for IoT messaging (Coming Soon)',
 ),
 'azure-iot': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-azure-iot'],
 env: {'AZURE_IOT_CONNECTION': '\${AZURE_IOT_CONNECTION}'},
 description: 'Azure IoT Hub device management (Coming Soon)',
 ),
 'influxdb': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-influxdb'],
 env: {'INFLUX_TOKEN': '\${INFLUX_TOKEN}'},
 description: 'InfluxDB time-series data (Coming Soon)',
 ),
 'edge-deploy': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-edge-deploy'],
 description: 'Edge device deployment (Coming Soon)',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Device configurations and telemetry',
 ),
 },
 contextDocuments: ['device_registry.json', 'edge_topology.yaml', 'sensor_protocols.md'],
 isActive: false, // Coming soon
 ),
 ProductionAgent(
 id: 'game-developer',
 name: 'Game Developer',
 description: 'Game development with Unity and Unreal integration',
 systemPrompt: 'You are a game developer with expertise in Unity, Unreal Engine, and game design. You will have access to game engines, asset stores, multiplayer services, and analytics. Focus on gameplay mechanics, performance optimization, and player experience.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['unity', 'unreal', 'steam', 'playfab', 'memory'],
 mcpServerConfigs: {
 'unity': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-unity'],
 description: 'Unity Editor automation (Coming Soon)',
 ),
 'unreal': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-unreal'],
 description: 'Unreal Engine integration (Coming Soon)',
 ),
 'steam': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-steam'],
 env: {'STEAM_API_KEY': '\${STEAM_API_KEY}'},
 description: 'Steam platform integration (Coming Soon)',
 ),
 'playfab': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-playfab'],
 env: {'PLAYFAB_SECRET': '\${PLAYFAB_SECRET}'},
 description: 'PlayFab game services (Coming Soon)',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Game design documents and assets',
 ),
 },
 contextDocuments: ['game_design.md', 'level_layouts.json', 'balancing_data.csv'],
 isActive: false, // Coming soon
 ),
 ProductionAgent(
 id: 'robotics-engineer',
 name: 'Robotics Engineer',
 description: 'ROS integration and robot control systems',
 systemPrompt: 'You are a robotics engineer working with ROS, computer vision, and control systems. You will have access to robot simulators, sensor data, motion planning, and hardware interfaces. Focus on autonomy, safety, and real-time control.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['ros', 'gazebo', 'opencv', 'arduino', 'memory'],
 mcpServerConfigs: {
 'ros': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-ros'],
 description: 'ROS (Robot Operating System) interface (Coming Soon)',
 ),
 'gazebo': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-gazebo'],
 description: 'Gazebo robot simulator (Coming Soon)',
 ),
 'opencv': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-opencv'],
 description: 'OpenCV computer vision (Coming Soon)',
 ),
 'arduino': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-arduino'],
 description: 'Arduino hardware control (Coming Soon)',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Robot configurations and sensor logs',
 ),
 },
 contextDocuments: ['robot_specs.yaml', 'control_algorithms.md', 'sensor_calibration.json'],
 isActive: false, // Coming soon
 ),
 ProductionAgent(
 id: 'ar-vr-developer',
 name: 'AR/VR Developer',
 description: 'Augmented and Virtual Reality experiences',
 systemPrompt: 'You are an AR/VR developer creating immersive experiences. You will have access to AR frameworks, VR platforms, 3D modeling tools, and spatial computing APIs. Focus on user comfort, performance, and innovative interactions.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['arcore', 'oculus', 'babylon', 'blender', 'memory'],
 mcpServerConfigs: {
 'arcore': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-arcore'],
 description: 'Google ARCore for AR development (Coming Soon)',
 ),
 'oculus': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-oculus'],
 env: {'OCULUS_APP_ID': '\${OCULUS_APP_ID}'},
 description: 'Oculus/Meta Quest platform (Coming Soon)',
 ),
 'babylon': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-babylonjs'],
 description: 'Babylon.js 3D engine (Coming Soon)',
 ),
 'blender': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-blender'],
 description: 'Blender 3D modeling automation (Coming Soon)',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: '3D assets and interaction patterns',
 ),
 },
 contextDocuments: ['vr_interactions.md', '3d_asset_pipeline.json', 'performance_targets.yaml'],
 isActive: false, // Coming soon
 ),
 ProductionAgent(
 id: 'quantum-researcher',
 name: 'Quantum Computing Researcher',
 description: 'Quantum algorithm development and simulation',
 systemPrompt: 'You are a quantum computing researcher working with quantum algorithms and simulators. You will have access to quantum computing platforms, circuit designers, and quantum machine learning tools. Focus on algorithm optimization, error correction, and practical applications.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['qiskit', 'cirq', 'aws-braket', 'pennylane', 'memory'],
 mcpServerConfigs: {
 'qiskit': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-qiskit'],
 description: 'IBM Qiskit quantum computing (Coming Soon)',
 ),
 'cirq': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-cirq'],
 description: 'Google Cirq quantum circuits (Coming Soon)',
 ),
 'aws-braket': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-braket'],
 env: {'AWS_ACCESS_KEY': '\${AWS_ACCESS_KEY}'},
 description: 'AWS Braket quantum computing (Coming Soon)',
 ),
 'pennylane': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-pennylane'],
 description: 'PennyLane quantum ML (Coming Soon)',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Quantum circuit designs and results',
 ),
 },
 contextDocuments: ['quantum_algorithms.md', 'circuit_library.json', 'error_models.yaml'],
 isActive: false, // Coming soon
 ),
 ProductionAgent(
 id: 'bioinformatics',
 name: 'Bioinformatics Analyst',
 description: 'Genomic analysis and protein modeling',
 systemPrompt: 'You are a bioinformatics analyst working with genomic data, protein structures, and biological databases. You will have access to sequence analysis tools, molecular visualization, and scientific databases. Focus on data analysis, pattern discovery, and biological insights.',
 apiProvider: 'Claude 3.5 Sonnet',
 mcpServers: ['blast', 'alphafold', 'pubmed', 'biopython', 'memory'],
 mcpServerConfigs: {
 'blast': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-blast'],
 description: 'NCBI BLAST sequence alignment (Coming Soon)',
 ),
 'alphafold': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-alphafold'],
 description: 'AlphaFold protein structure prediction (Coming Soon)',
 ),
 'pubmed': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-pubmed'],
 description: 'PubMed literature search (Coming Soon)',
 ),
 'biopython': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-biopython'],
 description: 'BioPython analysis tools (Coming Soon)',
 ),
 'memory': MCPServerConfig(
 command: 'uvx',
 args: ['@modelcontextprotocol/server-memory'],
 description: 'Sequence data and analysis results',
 ),
 },
 contextDocuments: ['genome_annotation.gff', 'protein_families.json', 'pathway_analysis.md'],
 isActive: false, // Coming soon
 ),
 ];

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final selectedConversationId = ref.watch(selectedConversationIdProvider);
 final selectedAgentId = ref.watch(selectedAgentPreviewProvider);
 final loadedAgentIds = ref.watch(loadedAgentIdsProvider);
 
 // Get current conversation to determine active agent
 final currentConversation = selectedConversationId != null 
 ? ref.watch(conversationProvider(selectedConversationId)).when(
 data: (conversation) => conversation,
 loading: () => null,
 error: (_, __) => null,
 )
 : null;
 
 // Determine which agent should be shown based on current conversation
 String? effectiveAgentId;
 if (currentConversation?.metadata?['type'] == 'agent') {
 effectiveAgentId = currentConversation?.metadata?['agentId'] as String?;
 } else {
 effectiveAgentId = selectedAgentId;
 }
 
 final selectedAgent = effectiveAgentId != null 
 ? _agents.firstWhere((agent) => agent.id == effectiveAgentId, 
 orElse: () => _agents.first)
 : null;
 
 return Padding(
 padding: const EdgeInsets.symmetric(horizontal: 20),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Section Header
 Row(
 children: [
 Icon(
 Icons.smart_toy,
 size: 16,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: SpacingTokens.iconSpacing),
 Text(
 currentConversation?.metadata?['type'] == 'agent' 
 ? 'Active Agent'
 : 'Agent Preview',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 13,
 fontWeight: FontWeight.w500,
 color: currentConversation?.metadata?['type'] == 'agent'
 ? ThemeColors(context).primary
 : theme.colorScheme.onSurfaceVariant,
 ),
 ),
 Spacer(),
 IconButton(
 onPressed: () => setState(() => _isExpanded = !_isExpanded),
 icon: Icon(
 _isExpanded ? Icons.expand_less : Icons.expand_more,
 size: 16,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 style: IconButton.styleFrom(
 foregroundColor: theme.colorScheme.onSurfaceVariant,
 minimumSize: Size(24, 24),
 padding: EdgeInsets.zero,
 ),
 ),
 ],
 ),
 
 if (_isExpanded) ...[
 SizedBox(height: 12),
 
 // Agent Selection Dropdown
 Container(
 width: double.infinity,
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 decoration: BoxDecoration(
 border: Border.all(color: theme.colorScheme.outline),
 borderRadius: BorderRadius.circular(6),
 color: theme.colorScheme.surface.withValues(alpha: 0.8),
 ),
 child: DropdownButtonHideUnderline(
 child: DropdownButton<String>(
 value: effectiveAgentId,
 hint: Text(
 currentConversation?.metadata?['type'] == 'agent' 
 ? 'Current conversation agent'
 : 'Select agent to load',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 12,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 isExpanded: true,
 icon: Icon(
 Icons.keyboard_arrow_down,
 size: 16,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 items: _agents.map((agent) {
 return DropdownMenuItem<String>(
 value: agent.id,
 child: Row(
 children: [
 Container(
 width: 6,
 height: 6,
 decoration: BoxDecoration(
 color: agent.isActive 
 ? ThemeColors(context).success 
 : theme.colorScheme.onSurfaceVariant,
 shape: BoxShape.circle,
 ),
 ),
 SizedBox(width: 8),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: [
 Text(
 agent.name,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 12,
 fontWeight: FontWeight.w500,
 color: agent.isActive 
 ? theme.colorScheme.onSurface
 : theme.colorScheme.onSurfaceVariant,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 Text(
 agent.description,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }).toList(),
 onChanged: (value) {
 // Only allow changing if not viewing an agent conversation
 if (currentConversation?.metadata?['type'] != 'agent') {
 ref.read(selectedAgentPreviewProvider.notifier).state = value;
 }
 },
 ),
 ),
 ),
 
 // Show current conversation context if applicable
 if (currentConversation?.metadata?['type'] == 'agent') ...[
 SizedBox(height: 12),
 Container(
 width: double.infinity,
 padding: const EdgeInsets.all(10),
 decoration: BoxDecoration(
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(6),
 border: Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3)),
 ),
 child: Row(
 children: [
 Icon(
 Icons.info_outline,
 size: 14,
 color: ThemeColors(context).primary,
 ),
 SizedBox(width: 8),
 Expanded(
 child: Text(
 'Viewing agent from current conversation',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 11,
 color: ThemeColors(context).primary,
 fontWeight: FontWeight.w500,
 ),
 ),
 ),
 ],
 ),
 ),
 ],
 
 if (selectedAgent != null) ...[
 SizedBox(height: 16),
 
 // System Prompt Preview
 _buildSystemPromptPreview(selectedAgent, theme),
 
 SizedBox(height: 12),
 
 // API Provider
 _buildApiProviderInfo(selectedAgent, theme),
 
 SizedBox(height: 12),
 
 // MCP Servers Status
 _buildMCPServersStatus(selectedAgent, theme),
 
 SizedBox(height: 12),
 
 // Context Documents
 _buildContextDocuments(selectedAgent, theme),
 
 SizedBox(height: 16),
 
 // Load Agent Button - conditional display
 if (currentConversation?.metadata?['type'] != 'agent') 
 _buildLoadAgentButton(selectedAgent, theme)
 else
 Container(
 width: double.infinity,
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
 decoration: BoxDecoration(
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3)),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.chat,
 size: 18,
 color: ThemeColors(context).primary,
 ),
 SizedBox(width: 8),
 Flexible(
 child: Text(
 'Currently Active in Conversation',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 13,
 fontWeight: FontWeight.w600,
 color: ThemeColors(context).primary,
 ),
 overflow: TextOverflow.ellipsis,
 ),
 ),
 ],
 ),
 ),
 ],
 
 SizedBox(height: 12),
 
 // Quick Actions
 if (currentConversation?.metadata?['type'] == 'agent') ...[
 // When viewing agent conversation, show switch option
 Row(
 children: [
 Expanded(
 child: GestureDetector(
 onTap: () {
 // Clear current selection to allow new agent selection
 ref.read(selectedAgentPreviewProvider.notifier).state = null;
 ref.read(selectedConversationIdProvider.notifier).state = null;
 },
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
 decoration: BoxDecoration(
 border: Border.all(color: ThemeColors(context).primary),
 borderRadius: BorderRadius.circular(6),
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 ),
 child: Center(
 child: Text(
 'Switch Agent',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 11,
 color: ThemeColors(context).primary,
 fontWeight: FontWeight.w600,
 ),
 ),
 ),
 ),
 ),
 ),
 SizedBox(width: 8),
 Expanded(
 child: GestureDetector(
 onTap: () => context.go(AppRoutes.agents),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
 decoration: BoxDecoration(
 border: Border.all(color: theme.colorScheme.outline),
 borderRadius: BorderRadius.circular(6),
 color: theme.colorScheme.surface.withValues(alpha: 0.8),
 ),
 child: Center(
 child: Text(
 'My Agents',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 11,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ),
 ),
 ),
 ),
 ],
 ),
 ] else ...[
 // Normal quick actions when not viewing agent conversation
 Row(
 children: [
 Expanded(
 child: GestureDetector(
 onTap: () => context.go(AppRoutes.agents),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
 decoration: BoxDecoration(
 border: Border.all(color: theme.colorScheme.outline),
 borderRadius: BorderRadius.circular(6),
 color: theme.colorScheme.surface.withValues(alpha: 0.8),
 ),
 child: Center(
 child: Text(
 'My Agents',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 11,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ),
 ),
 ),
 ),
 SizedBox(width: 8),
 Expanded(
 child: GestureDetector(
 onTap: () => context.go(AppRoutes.wizard),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
 decoration: BoxDecoration(
 border: Border.all(color: theme.colorScheme.outline),
 borderRadius: BorderRadius.circular(6),
 color: theme.colorScheme.surface.withValues(alpha: 0.8),
 ),
 child: Center(
 child: Text(
 'Create New',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 11,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ),
 ),
 ),
 ),
 ],
 ),
 ],
 ],
 ],
 ),
 );
 }

 Widget _buildSystemPromptPreview(ProductionAgent agent, ThemeData theme) {
 return Container(
 width: double.infinity,
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: theme.colorScheme.surface.withValues(alpha: 0.8),
 borderRadius: BorderRadius.circular(6),
 border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(
 Icons.description_outlined,
 size: 14,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: 6),
 Text(
 'System Prompt',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 11,
 fontWeight: FontWeight.w500,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 SizedBox(height: 8),
 Container(
 constraints: BoxConstraints(maxHeight: 80),
 child: SingleChildScrollView(
 child: Text(
 agent.systemPrompt,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 color: theme.colorScheme.onSurface,
 height: 1.3,
 ),
 ),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildApiProviderInfo(ProductionAgent agent, ThemeData theme) {
 return Container(
 width: double.infinity,
 padding: const EdgeInsets.all(10),
 decoration: BoxDecoration(
 color: theme.colorScheme.surface.withValues(alpha: 0.8),
 borderRadius: BorderRadius.circular(6),
 border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
 ),
 child: Row(
 children: [
 Icon(
 Icons.api,
 size: 14,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: 8),
 Text(
 'API:',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 11,
 fontWeight: FontWeight.w500,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 SizedBox(width: 4),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
 decoration: BoxDecoration(
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 ),
 child: Text(
 agent.apiProvider,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 fontWeight: FontWeight.w500,
 color: ThemeColors(context).primary,
 ),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildMCPServersStatus(ProductionAgent agent, ThemeData theme) {
 return Container(
 width: double.infinity,
 padding: const EdgeInsets.all(10),
 decoration: BoxDecoration(
 color: theme.colorScheme.surface.withValues(alpha: 0.8),
 borderRadius: BorderRadius.circular(6),
 border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(
 Icons.storage,
 size: 14,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: 6),
 Text(
 'MCP Servers',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 11,
 fontWeight: FontWeight.w500,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 Spacer(),
 // Live status count from settings service
 Consumer(
 builder: (context, ref, child) {
 return ref.watch(mcpServerStatusesProvider(agent.mcpServers)).when(
 data: (statusMap) {
 final connectedCount = statusMap.values
 .where((status) => status.isConnected)
 .length;
 final totalCount = agent.mcpServers.length;
 
 return Text(
 '$connectedCount/$totalCount connected',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 color: connectedCount == totalCount 
 ? ThemeColors(context).success 
 : connectedCount > 0
 ? Colors.orange
 : ThemeColors(context).error,
 ),
 );
 },
 loading: () => Text(
 'Checking...',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 error: (_, __) => Text(
 'Error',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 color: ThemeColors(context).error,
 ),
 ),
 );
 },
 ),
 ],
 ),
 SizedBox(height: 6),
 // Live server status badges from settings service
 Consumer(
 builder: (context, ref, child) {
 return ref.watch(mcpServerStatusesProvider(agent.mcpServers)).when(
 data: (statusMap) {
 return Wrap(
 spacing: 4,
 runSpacing: 4,
 children: agent.mcpServers.map((server) {
 final status = statusMap[server];
 final isConnected = status?.isConnected ?? false;
 final connectionStatus = status?.status ?? ConnectionStatus.disconnected;
 
 Color statusColor;
 switch (connectionStatus) {
 case ConnectionStatus.connected:
 statusColor = ThemeColors(context).success;
 break;
 case ConnectionStatus.connecting:
 statusColor = Colors.orange;
 break;
 case ConnectionStatus.error:
 statusColor = ThemeColors(context).error;
 break;
 case ConnectionStatus.warning:
 statusColor = Colors.orange;
 break;
 default:
 statusColor = theme.colorScheme.onSurfaceVariant;
 }
 
 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: statusColor.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(
 color: statusColor.withValues(alpha: 0.3),
 width: 1,
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Container(
 width: 4,
 height: 4,
 decoration: BoxDecoration(
 color: statusColor,
 shape: BoxShape.circle,
 ),
 ),
 SizedBox(width: 4),
 Text(
 server,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 9,
 color: statusColor,
 ),
 ),
 ],
 ),
 );
 }).toList(),
 );
 },
 loading: () => Wrap(
 spacing: 4,
 runSpacing: 4,
 children: agent.mcpServers.map((server) {
 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(
 color: theme.colorScheme.outline.withValues(alpha: 0.3),
 width: 1,
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 SizedBox(
 width: 8,
 height: 8,
 child: CircularProgressIndicator(
 strokeWidth: 1,
 valueColor: AlwaysStoppedAnimation<Color>(
 theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ),
 SizedBox(width: 4),
 Text(
 server,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 9,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 );
 }).toList(),
 ),
 error: (_, __) => Wrap(
 spacing: 4,
 runSpacing: 4,
 children: agent.mcpServers.map((server) {
 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: ThemeColors(context).error.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(4),
 border: Border.all(
 color: ThemeColors(context).error.withValues(alpha: 0.3),
 width: 1,
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 Icons.error_outline,
 size: 8,
 color: ThemeColors(context).error,
 ),
 SizedBox(width: 4),
 Text(
 server,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 9,
 color: ThemeColors(context).error,
 ),
 ),
 ],
 ),
 );
 }).toList(),
 ),
 );
 },
 ),
 ],
 ),
 );
 }

 Widget _buildContextDocuments(ProductionAgent agent, ThemeData theme) {
 return Container(
 width: double.infinity,
 padding: const EdgeInsets.all(10),
 decoration: BoxDecoration(
 color: theme.colorScheme.surface.withValues(alpha: 0.8),
 borderRadius: BorderRadius.circular(6),
 border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(
 Icons.folder_outlined,
 size: 14,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: 6),
 Text(
 'Context Documents',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 11,
 fontWeight: FontWeight.w500,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 Spacer(),
 Text(
 '${agent.contextDocuments.length} files',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 SizedBox(height: 6),
 Column(
 children: agent.contextDocuments.take(3).map((doc) {
 return Padding(
 padding: const EdgeInsets.only(bottom: 4),
 child: Row(
 children: [
 Icon(
 Icons.description,
 size: 12,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: 6),
 Expanded(
 child: Text(
 doc,
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 color: theme.colorScheme.onSurface,
 ),
 overflow: TextOverflow.ellipsis,
 ),
 ),
 ],
 ),
 );
 }).toList(),
 ),
 ],
 ),
 );
 }

 Widget _buildLoadAgentButton(ProductionAgent agent, ThemeData theme) {
 final isLoading = _loadingAgentId == agent.id;
 final loadedAgentIds = ref.watch(loadedAgentIdsProvider);
 final selectedConversationId = ref.watch(selectedConversationIdProvider);
 final currentConversation = selectedConversationId != null 
 ? ref.watch(conversationProvider(selectedConversationId)).when(
 data: (conversation) => conversation,
 loading: () => null,
 error: (_, __) => null,
 )
 : null;
 
 // Consider agent loaded if it's in the loaded set OR if it's the current conversation agent
 final isLoaded = loadedAgentIds.contains(agent.id) || 
 (currentConversation?.metadata?['agentId'] == agent.id);
 
 // Show "Coming Soon" for inactive agents
 if (!agent.isActive) {
 return Container(
 width: double.infinity,
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
 decoration: BoxDecoration(
 color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.schedule,
 size: 18,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 SizedBox(width: 8),
 Text(
 'Coming Soon',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 13,
 fontWeight: FontWeight.w600,
 color: theme.colorScheme.onSurfaceVariant,
 fontStyle: FontStyle.italic,
 ),
 ),
 ],
 ),
 );
 }
 
 if (isLoaded) {
 // Show "Agent Loaded" state - no button
 return Container(
 width: double.infinity,
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
 decoration: BoxDecoration(
 color: ThemeColors(context).success.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: ThemeColors(context).success.withValues(alpha: 0.3)),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.check_circle,
 size: 18,
 color: ThemeColors(context).success,
 ),
 SizedBox(width: 8),
 Flexible(
 child: Text(
 'Agent Loaded',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 13,
 fontWeight: FontWeight.w600,
 color: ThemeColors(context).success,
 ),
 overflow: TextOverflow.ellipsis,
 ),
 ),
 ],
 ),
 );
 }
 
 if (isLoading) {
 // Novel loading animation - "Agent Awakening"
 return Container(
 width: double.infinity,
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
 decoration: BoxDecoration(
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3)),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 SizedBox(
 width: 18,
 height: 18,
 child: CircularProgressIndicator(
 strokeWidth: 2,
 valueColor: AlwaysStoppedAnimation<Color>(ThemeColors(context).primary),
 ),
 ),
 SizedBox(width: 12),
 Flexible(
 child: Column(
 children: [
 Text(
 'Agent Awakening...',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 13,
 fontWeight: FontWeight.w600,
 color: ThemeColors(context).primary,
 ),
 overflow: TextOverflow.ellipsis,
 ),
 SizedBox(height: 2),
 Text(
 'Initializing neural pathways',
 style: TextStyle(
 fontFamily: 'Space Grotesk',
 fontSize: 10,
 color: ThemeColors(context).primary.withValues(alpha: 0.8),
 fontStyle: FontStyle.italic,
 ),
 overflow: TextOverflow.ellipsis,
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }
 
 // Default "Load Agent" button
 return AsmblButton.primary(
 text: 'Load Agent',
 onPressed: () => _loadAgent(agent),
 icon: Icons.psychology, // Brain icon for AI agent
 );
 }

 void _loadAgent(ProductionAgent agent) async {
 setState(() {
 _loadingAgentId = agent.id;
 });
 
 try {
 // Add some dramatic pause for the "awakening" effect
 await Future.delayed(Duration(milliseconds: 1500));
 
 // Create new conversation with agent configuration
 final createAgentConversation = ref.read(createAgentConversationProvider);
 
 final conversation = await createAgentConversation(
 agentId: agent.id,
 agentName: agent.name,
 systemPrompt: agent.systemPrompt,
 apiProvider: agent.apiProvider,
 mcpServers: agent.mcpServers,
 mcpServerConfigs: agent.mcpServerConfigs.map((key, config) => MapEntry(key, config.toJson())),
 contextDocuments: agent.contextDocuments,
 );
 
 // Switch to the new agent conversation
 ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
 
 // Refresh conversations list to show the new conversation
 ref.invalidate(conversationsProvider);
 
 setState(() {
 _loadingAgentId = null;
 });
 
 // Update global loaded agents state
 ref.read(loadedAgentIdsProvider.notifier).update((state) => {...state, agent.id});
 
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Row(
 children: [
 Icon(Icons.auto_awesome, color: Colors.white, size: 16),
 SizedBox(width: 8),
 Text(
 '${agent.name} is now awake and ready!',
 style: TextStyle(fontFamily: 'Space Grotesk'),
 ),
 ],
 ),
 backgroundColor: ThemeColors(context).success,
 behavior: SnackBarBehavior.floating,
 ),
 );
 
 } catch (e) {
 setState(() {
 _loadingAgentId = null;
 });
 
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text(
 'Failed to awaken agent: $e',
 style: TextStyle(fontFamily: 'Space Grotesk'),
 ),
 backgroundColor: ThemeColors(context).error,
 behavior: SnackBarBehavior.floating,
 ),
 );
 }
 }
}

class ProductionAgent {
 final String id;
 final String name;
 final String description;
 final String systemPrompt;
 final String apiProvider;
 final List<String> mcpServers;
 final Map<String, MCPServerConfig> mcpServerConfigs;
 final List<String> contextDocuments;
 final bool isActive;

 ProductionAgent({
 required this.id,
 required this.name,
 required this.description,
 required this.systemPrompt,
 required this.apiProvider,
 required this.mcpServers,
 required this.mcpServerConfigs,
 required this.contextDocuments,
 required this.isActive,
 });
}

class MCPServerConfig {
 final String command;
 final List<String> args;
 final Map<String, String>? env;
 final String description;

 MCPServerConfig({
 required this.command,
 required this.args,
 this.env,
 required this.description,
 });

 Map<String, dynamic> toJson() => {
 'command': command,
 'args': args,
 if (env != null) 'env': env,
 'description': description,
 };
}