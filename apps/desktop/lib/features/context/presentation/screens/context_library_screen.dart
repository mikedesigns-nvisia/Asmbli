import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/design_system/components/app_navigation_bar.dart';
import '../providers/context_provider.dart';
import '../../data/repositories/context_repository.dart';
import '../widgets/context_creation_flow.dart';
import '../../data/models/context_document.dart';
import '../widgets/context_hub_widget.dart';
import '../../../templates/presentation/screens/templates_screen.dart';

class ContextLibraryScreen extends ConsumerStatefulWidget {
  const ContextLibraryScreen({super.key});

  @override
  ConsumerState<ContextLibraryScreen> createState() => _ContextLibraryScreenState();
}

class _ContextLibraryScreenState extends ConsumerState<ContextLibraryScreen> {
  String searchQuery = '';
  String _selectedFilter = 'All';
  bool _showCreateFlow = false;

  // Filter categories with colors and icons
  final Map<String, Map<String, dynamic>> filterCategories = {
    'All': {'color': Colors.grey, 'icon': Icons.apps},
    'System Prompts': {'color': Colors.blue, 'icon': Icons.psychology},
    'Context Docs': {'color': Colors.green, 'icon': Icons.description},
    'Agent Templates': {'color': Colors.orange, 'icon': Icons.smart_toy},
    'Code Samples': {'color': Colors.purple, 'icon': Icons.code},
    'Documentation': {'color': Colors.teal, 'icon': Icons.menu_book},
    'Guidelines': {'color': Colors.indigo, 'icon': Icons.rule},
    'Examples': {'color': Colors.cyan, 'icon': Icons.lightbulb},
  };

  // Agent templates from templates screen
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

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final contextAsync = ref.watch(contextDocumentsProvider);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Navigation Bar
              AppNavigationBar(currentRoute: AppRoutes.context),
              
              // Page Header
              Container(
                padding: EdgeInsets.all(SpacingTokens.headerPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HeaderButton(
                          text: 'Back',
                          icon: Icons.arrow_back,
                          onPressed: () => context.go(AppRoutes.home),
                        ),
                        Spacer(),
                        Text(
                          'Context Library',
                          style: TextStyles.pageTitle.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                        Spacer(),
                        SizedBox(width: 100), // Balance the back button
                      ],
                    ),
                    SizedBox(height: SpacingTokens.lg),
                    Text(
                      'Manage your context documents, agent templates, and knowledge samples',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search context library...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          filled: true,
                          fillColor: colors.surface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    SizedBox(width: SpacingTokens.lg),
                    AsmblButtonEnhanced.accent(
                      text: 'Add Context',
                      icon: Icons.add,
                      onPressed: () => setState(() => _showCreateFlow = true),
                      size: AsmblButtonSize.medium,
                    ),
                  ],
                ),
              ),

              SizedBox(height: SpacingTokens.lg),

              // Filter Chips
              Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterCategories.entries.map((entry) {
                      final filterName = entry.key;
                      final filterData = entry.value;
                      final isSelected = _selectedFilter == filterName;
                      
                      return Padding(
                        padding: EdgeInsets.only(right: SpacingTokens.sm),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                filterData['icon'],
                                size: 16,
                                color: isSelected ? Colors.white : filterData['color'],
                              ),
                              SizedBox(width: 6),
                              Text(
                                filterName,
                                style: TextStyles.bodySmall.copyWith(
                                  color: isSelected ? Colors.white : colors.onSurface,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filterName);
                          },
                          selectedColor: filterData['color'],
                          backgroundColor: colors.surface,
                          side: BorderSide(
                            color: isSelected ? filterData['color'] : colors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          elevation: isSelected ? 2 : 0,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              SizedBox(height: SpacingTokens.lg),

              // Main Content - Filtered View
              Expanded(
                child: _buildFilteredContent(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredContent(ThemeColors colors) {
    switch (_selectedFilter) {
      case 'Agent Templates':
        return _buildAgentTemplatesSection(colors);
      case 'Context Docs':
      case 'System Prompts':
      case 'Documentation':
      case 'Guidelines':
      case 'Examples':
      case 'Code Samples':
        return _buildContextSamplesSection(colors);
      case 'All':
      default:
        return _buildAllContentSection(colors);
    }
  }

  Widget _buildAllContentSection(ThemeColors colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agent Templates Section
          Text(
            'Agent Templates',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            'Pre-built agent templates to get started quickly',
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          SizedBox(height: SpacingTokens.lg),
          Container(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: templates.take(4).length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return Container(
                  width: 280,
                  margin: EdgeInsets.only(right: SpacingTokens.lg),
                  child: _TemplateCard(
                    template: template,
                    onUseTemplate: () => _useTemplate(template),
                    colors: colors,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: SpacingTokens.xxl),

          // Context Samples Section
          Text(
            'Context Samples & Knowledge',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            'Ready-to-use context examples and knowledge templates',
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          SizedBox(height: SpacingTokens.lg),
          ContextHubWidget(),
        ],
      ),
    );
  }

  Widget _buildAgentTemplatesSection(ThemeColors colors) {
    final filteredTemplates = templates.where((template) {
      final matchesSearch = searchQuery.isEmpty || 
                          template.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          template.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          template.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()));
      return matchesSearch;
    }).toList();

    return Padding(
      padding: EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agent Templates',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            'Start with a pre-built template and customize it to your needs',
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          SizedBox(height: SpacingTokens.lg),
          Expanded(
            child: GridView.builder(
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
                  colors: colors,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextSamplesSection(ThemeColors colors) {
    return Padding(
      padding: EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Context Samples & Knowledge',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            'Ready-to-use context examples filtered by category',
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          SizedBox(height: SpacingTokens.lg),
          Expanded(
            child: ContextHubWidget(),
          ),
        ],
      ),
    );
  }

  void _useTemplate(AgentTemplate template) {
    context.go('${AppRoutes.chat}?template=${template.name}');
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
}

// Template Card Widget
class _TemplateCard extends StatelessWidget {
  final AgentTemplate template;
  final VoidCallback onUseTemplate;
  final ThemeColors colors;

  const _TemplateCard({
    required this.template,
    required this.onUseTemplate,
    required this.colors,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(template.category),
                  size: 20,
                  color: colors.onSurface,
                ),
              ),
              Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  template.category,
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          // Template name and description
          Text(
            template.name,
            style: TextStyles.cardTitle.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            template.description,
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: template.tags.take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
          
          Spacer(),
          
          // MCP Servers info
          if (template.mcpServers.isNotEmpty) ...[
            SizedBox(height: SpacingTokens.sm),
            Text(
              'MCP Servers: ${template.mcpServers.take(2).join(', ')}${template.mcpServers.length > 2 ? '...' : ''}',
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          SizedBox(height: SpacingTokens.lg),
          
          // Use Template button
          SizedBox(
            width: double.infinity,
            child: AsmblButtonEnhanced.primary(
              text: 'Use Template',
              icon: Icons.arrow_forward,
              onPressed: onUseTemplate,
              size: AsmblButtonSize.small,
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
}