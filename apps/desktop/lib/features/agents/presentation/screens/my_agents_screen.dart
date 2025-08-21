import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';

class MyAgentsScreen extends StatefulWidget {
  const MyAgentsScreen({super.key});

  @override
  State<MyAgentsScreen> createState() => _MyAgentsScreenState();
}

class _MyAgentsScreenState extends State<MyAgentsScreen> {
  int selectedTab = 0; // 0 = My Agents, 1 = Agent Library
  String searchQuery = '';
  String selectedCategory = 'All';

  final List<String> categories = [
    'All', 'Research', 'Development', 'Writing', 'Data Analysis', 
    'Customer Support', 'Marketing', 'Design'
  ];

  final List<AgentItem> agents = [
    AgentItem(
      name: 'Research Assistant',
      description: 'Academic research agent with citation management',
      category: 'Research',
      isActive: true,
      lastUsed: DateTime.now().subtract(const Duration(minutes: 15)),
      totalChats: 23,
    ),
    AgentItem(
      name: 'Code Reviewer',
      description: 'Automated code review with best practices',
      category: 'Development',
      isActive: true,
      lastUsed: DateTime.now().subtract(const Duration(hours: 2)),
      totalChats: 8,
    ),
    AgentItem(
      name: 'Content Writer',
      description: 'SEO-optimized content generation',
      category: 'Writing',
      isActive: false,
      lastUsed: DateTime.now().subtract(const Duration(days: 1)),
      totalChats: 15,
    ),
    AgentItem(
      name: 'Data Analyst',
      description: 'Statistical analysis and visualization',
      category: 'Data Analysis',
      isActive: true,
      lastUsed: DateTime.now().subtract(const Duration(hours: 6)),
      totalChats: 12,
    ),
  ];

  final List<AgentTemplate> templates = [
    AgentTemplate(
      name: 'Research Assistant',
      description: 'Academic research agent with citation management and fact-checking',
      category: 'Research',
      tags: ['academic', 'citations', 'fact-checking'],
      mcpStack: true,
      mcpServers: ['Brave Search', 'Memory', 'Files', 'Time'],
    ),
    AgentTemplate(
      name: 'Code Reviewer',
      description: 'Automated code review with best practices and security checks',
      category: 'Development', 
      tags: ['code-review', 'security', 'best-practices'],
      mcpStack: true,
      mcpServers: ['GitHub', 'Git', 'Files', 'Memory'],
    ),
    AgentTemplate(
      name: 'Content Writer',
      description: 'SEO-optimized content generation with tone customization',
      category: 'Writing',
      tags: ['seo', 'content', 'marketing'],
      mcpStack: true,
      mcpServers: ['Brave Search', 'Memory', 'Files'],
    ),
    AgentTemplate(
      name: 'Data Analyst',
      description: 'Statistical analysis and visualization for business insights',
      category: 'Data Analysis',
      tags: ['statistics', 'visualization', 'insights'],
      mcpStack: true,
      mcpServers: ['Postgres', 'Files', 'Memory', 'Time'],
    ),
    AgentTemplate(
      name: 'Customer Support Bot',
      description: 'Intelligent support agent with ticket management integration',
      category: 'Customer Support',
      tags: ['support', 'tickets', 'automation'],
      mcpStack: true,
      mcpServers: ['Linear', 'Slack', 'Memory', 'Time'],
    ),
    AgentTemplate(
      name: 'Marketing Strategist',
      description: 'Campaign planning and performance analysis agent',
      category: 'Marketing',
      tags: ['campaigns', 'strategy', 'analytics'],
      mcpStack: true,
      mcpServers: ['Brave Search', 'Notion', 'Memory', 'Time'],
    ),
    AgentTemplate(
      name: 'Design Agent',
      description: 'Comprehensive design assistant with Figma integration, code generation, and GitHub collaboration',
      category: 'Design',
      tags: ['design-systems', 'ui-ux', 'figma', 'components', 'collaboration'],
      mcpStack: true,
      mcpServers: ['Figma', 'GitHub', 'Files', 'Memory'],
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
              const AppNavigationBar(currentRoute: AppRoutes.agents),

              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Title
                      Text(
                        selectedTab == 0 ? 'My AI Agents' : 'Agent Library',
                        style: TextStyles.pageTitle.copyWith(
                          color: SemanticColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        selectedTab == 0 
                          ? 'Manage and organize your AI-powered assistants'
                          : 'Start with a pre-built template and customize it to your needs',
                        style: TextStyles.bodyLarge.copyWith(
                          color: SemanticColors.onSurfaceVariant,
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
                          const SizedBox(width: SpacingTokens.md),
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
    return Column(
      children: [
        // Stats Row
        Row(
          children: [
            Expanded(
              child: AsmblStatsCard(
                title: 'Total Agents',
                value: '${agents.length}',
                icon: Icons.smart_toy,
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: AsmblStatsCard(
                title: 'Active Today',
                value: '${agents.where((a) => a.isActive).length}',
                icon: Icons.schedule,
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: AsmblStatsCard(
                title: 'Total Chats',
                value: '${agents.fold(0, (sum, agent) => sum + agent.totalChats)}',
                icon: Icons.message,
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: AsmblStatsCard(
                title: 'Categories',
                value: '${agents.map((a) => a.category).toSet().length}',
                icon: Icons.category,
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sectionSpacing),
        // Agents List
        Expanded(
          child: ListView.separated(
            itemCount: agents.length,
            separatorBuilder: (context, index) => 
              const SizedBox(height: SpacingTokens.lg),
            itemBuilder: (context, index) {
              final agent = agents[index];
              return _AgentCard(agent: agent);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgentLibraryContent() {
    return Column(
      children: [
        // Search and Filter Row
        Row(
          children: [
            // Search Field
            Expanded(
              flex: 2,
              child: AsmblCard(
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
                    hintStyle: TextStyles.bodyMedium.copyWith(
                      color: SemanticColors.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: SemanticColors.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md, vertical: SpacingTokens.sm),
                  ),
                  style: TextStyles.bodyMedium.copyWith(color: SemanticColors.onSurface),
                ),
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
            // Category Filter
            AsmblCard(
              child: DropdownButton<String>(
                value: selectedCategory,
                onChanged: (value) => setState(() => selectedCategory = value!),
                underline: const SizedBox(),
                style: TextStyles.bodyMedium.copyWith(color: SemanticColors.onSurface),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sectionSpacing),
        // Templates Grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: SpacingTokens.lg,
              mainAxisSpacing: SpacingTokens.lg,
              childAspectRatio: 0.85,
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
    // Navigate to chat or configuration with this template
    context.go('${AppRoutes.chat}?template=${template.name}');
  }
}

class _AgentCard extends StatelessWidget {
  final AgentItem agent;

  const _AgentCard({required this.agent});

  @override
  Widget build(BuildContext context) {
    return AsmblCard(
      onTap: () {
        // Navigate to agent chat
      },
      child: Row(
        children: [
          // Agent Icon
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: SemanticColors.surfaceVariant,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            ),
            child: Icon(
              Icons.smart_toy,
              size: 24,
              color: SemanticColors.primary,
            ),
          ),
          const SizedBox(width: SpacingTokens.lg),
          
          // Agent Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status Indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: agent.isActive 
                          ? SemanticColors.success 
                          : SemanticColors.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    Expanded(
                      child: Text(
                        agent.name,
                        style: TextStyles.cardTitle.copyWith(
                          color: SemanticColors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '${agent.totalChats} chats',
                      style: TextStyles.caption.copyWith(
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  agent.description,
                  style: TextStyles.bodyMedium.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm,
                        vertical: SpacingTokens.xs,
                      ),
                      decoration: BoxDecoration(
                        color: SemanticColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      ),
                      child: Text(
                        agent.category,
                        style: TextStyles.caption.copyWith(
                          color: SemanticColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Last used: ${_formatLastUsed(agent.lastUsed)}',
                      style: TextStyles.caption.copyWith(
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: SpacingTokens.lg),
          
          // Actions
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: SemanticColors.onSurfaceVariant,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Agent'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Duplicate'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              // Handle menu actions
            },
          ),
        ],
      ),
    );
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and category
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: SemanticColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(
                  _getCategoryIcon(template.category),
                  size: 20,
                  color: SemanticColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm, vertical: SpacingTokens.xs),
                decoration: BoxDecoration(
                  color: SemanticColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  template.category,
                  style: TextStyles.caption.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          
          // Template name and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: TextStyles.cardTitle.copyWith(
                    color: SemanticColors.onSurface,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  template.description,
                  style: TextStyles.bodySmall.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: SpacingTokens.md),
                
                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: template.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm, vertical: SpacingTokens.xs),
                      decoration: BoxDecoration(
                        color: SemanticColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      ),
                      child: Text(
                        tag,
                        style: TextStyles.caption.copyWith(
                          color: SemanticColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: SpacingTokens.md),
                
                // MCP Servers
                if (template.mcpStack) ...[
                  Text(
                    'MCP Servers',
                    style: TextStyles.caption.copyWith(
                      color: SemanticColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: template.mcpServers.take(4).map((server) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs, vertical: 2),
                        decoration: BoxDecoration(
                          color: SemanticColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                          border: Border.all(
                            color: SemanticColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getMCPServerIcon(server),
                              size: 12,
                              color: SemanticColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              server,
                              style: TextStyles.caption.copyWith(
                                color: SemanticColors.primary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          // Use Template button
          const SizedBox(height: SpacingTokens.md),
          AsmblButton.primary(
            text: 'Use Template',
            onPressed: onUseTemplate,
            icon: Icons.arrow_forward,
          ),
        ],
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
}

class AgentTemplate {
  final String name;
  final String description;
  final String category;
  final List<String> tags;
  final bool mcpStack;
  final List<String> mcpServers;

  AgentTemplate({
    required this.name,
    required this.description,
    required this.category,
    required this.tags,
    required this.mcpStack,
    required this.mcpServers,
  });
}

class AgentItem {
  final String name;
  final String description;
  final String category;
  final bool isActive;
  final DateTime lastUsed;
  final int totalChats;

  AgentItem({
    required this.name,
    required this.description,
    required this.category,
    required this.isActive,
    required this.lastUsed,
    required this.totalChats,
  });
}