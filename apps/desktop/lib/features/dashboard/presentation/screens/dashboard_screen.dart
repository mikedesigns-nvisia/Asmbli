import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/design_system/design_system.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedView = 'overview';

  final List<AgentItem> myAgents = [
    AgentItem(
      name: 'Research Assistant',
      description: 'Academic research agent with citation management',
      category: 'Research',
      isActive: true,
      lastUsed: DateTime.now().subtract(const Duration(minutes: 15)),
      totalChats: 23,
      mcpServers: ['Brave Search', 'Memory', 'Files'],
    ),
    AgentItem(
      name: 'Code Reviewer',
      description: 'Automated code review with best practices',
      category: 'Development',
      isActive: true,
      lastUsed: DateTime.now().subtract(const Duration(hours: 2)),
      totalChats: 8,
      mcpServers: ['GitHub', 'Git', 'Files'],
    ),
    AgentItem(
      name: 'Content Writer',
      description: 'SEO-optimized content generation',
      category: 'Writing',
      isActive: false,
      lastUsed: DateTime.now().subtract(const Duration(days: 1)),
      totalChats: 15,
      mcpServers: ['Brave Search', 'Files'],
    ),
    AgentItem(
      name: 'Data Analyst',
      description: 'Statistical analysis and visualization',
      category: 'Data Analysis',
      isActive: true,
      lastUsed: DateTime.now().subtract(const Duration(hours: 6)),
      totalChats: 12,
      mcpServers: ['Postgres', 'Files', 'Memory'],
    ),
  ];

  final List<RecentActivity> recentActivity = [
    RecentActivity(
      type: 'chat',
      title: 'Started chat with Research Assistant',
      subtitle: 'Asked about AI research methodologies',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    RecentActivity(
      type: 'agent',
      title: 'Modified Code Reviewer agent',
      subtitle: 'Updated system prompt for better feedback',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    RecentActivity(
      type: 'template',
      title: 'Used Marketing Strategist template',
      subtitle: 'Created new campaign analysis agent',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    RecentActivity(
      type: 'mcp',
      title: 'Connected Postgres MCP server',
      subtitle: 'Added database integration for Data Analyst',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
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
              // Header
              const AppNavigationBar(currentRoute: '/dashboard'),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Title
                      Text(
                        'Agent Library',
                        style: TextStyles.pageTitle.copyWith(
                          color: SemanticColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        'Manage your AI agents, view analytics, and track recent activity',
                        style: TextStyles.bodyLarge.copyWith(
                          color: SemanticColors.onSurfaceVariant,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Dashboard Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _StatsCard(
                              title: 'Active Agents',
                              value: myAgents.where((a) => a.isActive).length.toString(),
                              subtitle: '${myAgents.length} total',
                              icon: Icons.smart_toy,
                              color: AppTheme.lightPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatsCard(
                              title: 'Total Conversations',
                              value: myAgents.map((a) => a.totalChats).reduce((a, b) => a + b).toString(),
                              subtitle: 'All time',
                              icon: Icons.chat_bubble_outline,
                              color: SemanticColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatsCard(
                              title: 'MCP Connections',
                              value: myAgents.expand((a) => a.mcpServers).toSet().length.toString(),
                              subtitle: 'Unique servers',
                              icon: Icons.hub,
                              color: SemanticColors.success,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Main Content Area
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // My Agents Section
                          Expanded(
                            flex: 2,
                            child: _DashboardSection(
                              title: 'My Agents',
                              action: GestureDetector(
                                onTap: () => context.go('/templates'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightPrimary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, size: 14, color: AppTheme.lightPrimaryForeground),
                                      SizedBox(width: 4),
                                      Text(
                                        'Create New',
                                        style: TextStyle(
                                          color: AppTheme.lightPrimaryForeground,
                                          fontFamily: 'Space Grotesk',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              child: Column(
                                children: myAgents.map((agent) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _AgentCard(agent: agent),
                                )).toList(),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 24),
                          
                          // Recent Activity Section
                          Expanded(
                            child: _DashboardSection(
                              title: 'Recent Activity',
                              child: Column(
                                children: recentActivity.map((activity) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ActivityCard(activity: activity),
                                )).toList(),
                              ),
                            ),
                          ),
                        ],
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

// Data Models
class AgentItem {
  final String name;
  final String description;
  final String category;
  final bool isActive;
  final DateTime lastUsed;
  final int totalChats;
  final List<String> mcpServers;

  AgentItem({
    required this.name,
    required this.description,
    required this.category,
    required this.isActive,
    required this.lastUsed,
    required this.totalChats,
    required this.mcpServers,
  });
}

class RecentActivity {
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  RecentActivity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });
}

// Widget Components

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.xl),
      decoration: BoxDecoration(
        color: SemanticColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        border: Border.all(color: SemanticColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 12,
              color: AppTheme.lightMutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _DashboardSection({
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightForeground,
                ),
              ),
              if (action != null) ...[
                const Spacer(),
                action!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  final AgentItem agent;

  const _AgentCard({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: agent.isActive 
            ? AppTheme.lightPrimary.withOpacity(0.3)
            : AppTheme.lightBorder.withOpacity(0.5),
        ),
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
                  color: agent.isActive ? Colors.green : AppTheme.lightMutedForeground,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.description,
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 13,
                        color: AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  agent.category,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightForeground,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Stats Row
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 14, color: AppTheme.lightMutedForeground),
                  const SizedBox(width: 4),
                  Text(
                    '${agent.totalChats} chats',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 12,
                      color: AppTheme.lightMutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppTheme.lightMutedForeground),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(agent.lastUsed),
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 12,
                      color: AppTheme.lightMutedForeground,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/chat?agent=${agent.name}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.lightPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Chat',
                    style: TextStyle(
                      color: AppTheme.lightPrimaryForeground,
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // MCP Servers
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: agent.mcpServers.map((server) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.lightPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.lightPrimary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  server,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _ActivityCard extends StatelessWidget {
  final RecentActivity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              size: 14,
              color: _getActivityColor(activity.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 11,
                    color: AppTheme.lightMutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(activity.timestamp),
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 10,
                    color: AppTheme.lightMutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'chat': return Icons.chat_bubble_outline;
      case 'agent': return Icons.smart_toy;
      case 'template': return Icons.library_books;
      case 'mcp': return Icons.hub;
      default: return Icons.circle;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'chat': return Colors.blue;
      case 'agent': return AppTheme.lightPrimary;
      case 'template': return Colors.purple;
      case 'mcp': return Colors.green;
      default: return AppTheme.lightMutedForeground;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}