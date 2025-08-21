import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/design_system/design_system.dart';

class MyAgentsScreen extends StatefulWidget {
  const MyAgentsScreen({super.key});

  @override
  State<MyAgentsScreen> createState() => _MyAgentsScreenState();
}

class _MyAgentsScreenState extends State<MyAgentsScreen> {
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
              // Header matching your existing pattern
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.headerPadding,
                  vertical: SpacingTokens.pageVertical,
                ),
                decoration: BoxDecoration(
                  color: SemanticColors.headerBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: SemanticColors.headerBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Brand Title
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: Text(
                        'Asmbli',
                        style: TextStyles.brandTitle.copyWith(
                          color: SemanticColors.onSurface,
                        ),
                      ),
                    ),
                    const Spacer(),
                    
                    // Navigation
                    HeaderButton(
                      text: 'Templates',
                      icon: Icons.library_books,
                      onPressed: () => context.go('/templates'),
                    ),
                    const SizedBox(width: SpacingTokens.lg),
                    HeaderButton(
                      text: 'My Agents',
                      icon: Icons.smart_toy,
                      onPressed: () {},
                      isActive: true,
                    ),
                    const SizedBox(width: SpacingTokens.lg),
                    HeaderButton(
                      text: 'Settings',
                      icon: Icons.settings,
                      onPressed: () => context.go('/settings'),
                    ),
                    const SizedBox(width: SpacingTokens.xxl),
                    
                    // New Chat Button
                    AsmblButton.primary(
                      text: 'New Chat',
                      icon: Icons.add,
                      onPressed: () => context.go('/chat'),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Title
                      Text(
                        'My AI Agents',
                        style: TextStyles.pageTitle.copyWith(
                          color: SemanticColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        'Manage and organize your AI-powered assistants',
                        style: TextStyles.bodyLarge.copyWith(
                          color: SemanticColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.sectionSpacing),

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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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