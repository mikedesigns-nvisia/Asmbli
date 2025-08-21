import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/design_system/design_system.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  String searchQuery = '';
  String selectedCategory = 'All';

  final List<String> categories = [
    'All', 'Research', 'Development', 'Writing', 'Data Analysis', 
    'Customer Support', 'Marketing', 'Design'
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
              const AppNavigationBar(currentRoute: '/templates'),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Title & Description
                      Text(
                        'Agent Templates',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start with a pre-built template and customize it to your needs',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 16,
                          color: AppTheme.lightMutedForeground,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Search and Filter Row
                      Row(
                        children: [
                          // Search Field
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.lightBorder.withOpacity(0.5)),
                              ),
                              child: TextField(
                                onChanged: (value) => setState(() => searchQuery = value),
                                decoration: InputDecoration(
                                  hintText: 'Search templates...',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    color: AppTheme.lightMutedForeground,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppTheme.lightMutedForeground,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                style: const TextStyle(fontFamily: 'Space Grotesk'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Category Filter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.lightBorder.withOpacity(0.5)),
                            ),
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              onChanged: (value) => setState(() => selectedCategory = value!),
                              underline: const SizedBox(),
                              style: const TextStyle(fontFamily: 'Space Grotesk', color: AppTheme.lightForeground),
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
                      
                      const SizedBox(height: 32),
                      
                      // Templates Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
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

  void _useTemplate(AgentTemplate template) {
    // Navigate to chat or configuration with this template
    context.go('/chat?template=${template.name}');
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


class _TemplateCard extends StatelessWidget {
  final AgentTemplate template;
  final VoidCallback onUseTemplate;

  const _TemplateCard({
    required this.template,
    required this.onUseTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and category
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBorder.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(template.category),
                    size: 20,
                    color: AppTheme.lightForeground,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.lightSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    template.category,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.lightForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Template name and description
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.description,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 13,
                      color: AppTheme.lightMutedForeground,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: template.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBorder.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 10,
                            color: AppTheme.lightMutedForeground,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // MCP Servers
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MCP Servers',
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.lightMutedForeground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: template.mcpServers.map((server) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.lightPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.lightPrimary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getMCPServerIcon(server),
                                  size: 12,
                                  color: AppTheme.lightPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  server,
                                  style: const TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.lightPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // MCP Stack indicator and Use Template button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (template.mcpStack) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: AppTheme.lightMutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MCP Stack',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 11,
                          color: AppTheme.lightMutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                GestureDetector(
                  onTap: onUseTemplate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Use Template',
                          style: TextStyle(
                            color: AppTheme.lightPrimaryForeground,
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16, color: AppTheme.lightPrimaryForeground),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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