import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';

class AgentSettingsScreen extends ConsumerStatefulWidget {
  const AgentSettingsScreen({super.key});

  @override
  ConsumerState<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends ConsumerState<AgentSettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  final List<AgentConfig> _sampleAgents = [
    AgentConfig(
      id: 'default-assistant',
      name: 'Default Assistant',
      description: 'General-purpose AI assistant for everyday tasks',
      systemPrompt: 'You are a helpful AI assistant.',
      isActive: true,
      lastUsed: DateTime.now().subtract(Duration(hours: 2)),
      usageCount: 245,
      model: 'Claude 3.5 Sonnet',
      color: Colors.blue,
    ),
    AgentConfig(
      id: 'code-reviewer',
      name: 'Code Reviewer',
      description: 'Specialized agent for code analysis and review',
      systemPrompt: 'You are a senior software engineer reviewing code.',
      isActive: true,
      lastUsed: DateTime.now().subtract(Duration(days: 1)),
      usageCount: 89,
      model: 'Claude 3.5 Sonnet',
      color: Colors.green,
    ),
    AgentConfig(
      id: 'writing-assistant',
      name: 'Writing Assistant',
      description: 'Helps with creative writing and content creation',
      systemPrompt: 'You are a professional writing assistant.',
      isActive: false,
      lastUsed: DateTime.now().subtract(Duration(days: 7)),
      usageCount: 23,
      model: 'Claude 3 Opus',
      color: Colors.purple,
    ),
    AgentConfig(
      id: 'research-analyst',
      name: 'Research Analyst',
      description: 'Conducts thorough research and analysis',
      systemPrompt: 'You are a meticulous research analyst.',
      isActive: true,
      lastUsed: DateTime.now().subtract(Duration(hours: 6)),
      usageCount: 156,
      model: 'Claude 3.5 Sonnet',
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<AgentConfig> get _filteredAgents {
    var agents = _sampleAgents;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      agents = agents.where((agent) =>
        agent.name.toLowerCase().contains(query) ||
        agent.description.toLowerCase().contains(query) ||
        agent.model.toLowerCase().contains(query)
      ).toList();
    }

    // Apply status filter
    switch (_selectedFilter) {
      case 'active':
        agents = agents.where((agent) => agent.isActive).toList();
        break;
      case 'inactive':
        agents = agents.where((agent) => !agent.isActive).toList();
        break;
    }

    // Sort by usage count
    agents.sort((a, b) => b.usageCount.compareTo(a.usageCount));

    return agents;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final filteredAgents = _filteredAgents;

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.background,
              colors.background.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            AppNavigationBar(currentRoute: AppRoutes.settings),
            _buildHeader(colors),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildMainContent(colors, filteredAgents),
                  ),
                  SizedBox(
                    width: 300,
                    child: _buildSidebar(colors),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back, color: colors.onSurface),
              ),
              SizedBox(width: SpacingTokens.componentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Agents',
                      style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                    ),
                    SizedBox(height: SpacingTokens.xs_precise),
                    Text(
                      'Manage your AI agents and system prompts',
                      style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              AsmblButton.primary(
                text: 'Create Agent',
                icon: Icons.add,
                onPressed: _createNewAgent,
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.sectionSpacing),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: EdgeInsets.symmetric(horizontal: SpacingTokens.componentSpacing),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: colors.onSurfaceVariant, size: 20),
                      SizedBox(width: SpacingTokens.componentSpacing),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search agents...',
                            border: InputBorder.none,
                            hintStyle: TextStyles.bodyMedium.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: SpacingTokens.componentSpacing),
              _buildFilterChips(colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeColors colors) {
    final filters = [
      ('all', 'All', _sampleAgents.length),
      ('active', 'Active', _sampleAgents.where((a) => a.isActive).length),
      ('inactive', 'Inactive', _sampleAgents.where((a) => !a.isActive).length),
    ];

    return Row(
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter.$1;
        return Padding(
          padding: EdgeInsets.only(right: SpacingTokens.iconSpacing),
          child: FilterChip(
            label: Text('${filter.$2} (${filter.$3})'),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filter.$1;
              });
            },
            backgroundColor: colors.surface,
            selectedColor: colors.primary.withValues(alpha: 0.1),
            labelStyle: TextStyles.caption.copyWith(
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? colors.primary : colors.border,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMainContent(ThemeColors colors, List<AgentConfig> agents) {
    if (agents.isEmpty) {
      return _buildEmptyState(colors);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agents (${agents.length})',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.componentSpacing),
          ...agents.map((agent) => Padding(
            padding: EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
            child: _buildAgentCard(agent, colors),
          )),
        ],
      ),
    );
  }

  Widget _buildAgentCard(AgentConfig agent, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(SpacingTokens.componentSpacing),
                  decoration: BoxDecoration(
                    color: agent.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: agent.color,
                    size: 24,
                  ),
                ),
                SizedBox(width: SpacingTokens.componentSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            agent.name,
                            style: TextStyles.cardTitle.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: SpacingTokens.iconSpacing),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: SpacingTokens.iconSpacing,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: agent.isActive 
                                ? colors.success.withValues(alpha: 0.1)
                                : colors.onSurfaceVariant.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                            ),
                            child: Text(
                              agent.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyles.caption.copyWith(
                                color: agent.isActive ? colors.success : colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SpacingTokens.xs_precise),
                      Text(
                        agent.description,
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAgentAction(agent, value),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('Edit Agent')),
                    PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                    PopupMenuItem(value: 'export', child: Text('Export Config')),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete', 
                      child: Text('Delete', style: TextStyle(color: colors.error)),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            Container(
              padding: EdgeInsets.all(SpacingTokens.componentSpacing),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Prompt',
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: SpacingTokens.xs_precise),
                  Text(
                    agent.systemPrompt.length > 100 
                      ? '${agent.systemPrompt.substring(0, 100)}...'
                      : agent.systemPrompt,
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            Row(
              children: [
                _buildAgentStat('Model', agent.model, Icons.psychology, colors),
                SizedBox(width: SpacingTokens.sectionSpacing),
                _buildAgentStat('Usage', '${agent.usageCount} times', Icons.bar_chart, colors),
                SizedBox(width: SpacingTokens.sectionSpacing),
                _buildAgentStat('Last Used', _formatLastUsed(agent.lastUsed), Icons.schedule, colors),
                Spacer(),
                Switch(
                  value: agent.isActive,
                  onChanged: (value) => _toggleAgent(agent, value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentStat(String label, String value, IconData icon, ThemeColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        SizedBox(width: SpacingTokens.iconSpacing),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: TextStyles.caption.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebar(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.componentSpacing),
          AsmblCard(
            child: Padding(
              padding: EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                children: [
                  _buildQuickAction('Create Agent', Icons.add, () => _createNewAgent(), colors),
                  Divider(height: SpacingTokens.sectionSpacing),
                  _buildQuickAction('Import Config', Icons.upload, () => _importConfig(), colors),
                  Divider(height: SpacingTokens.sectionSpacing),
                  _buildQuickAction('Export All', Icons.download, () => _exportAll(), colors),
                  Divider(height: SpacingTokens.sectionSpacing),
                  _buildQuickAction('Agent Templates', Icons.dashboard, () => _showTemplates(), colors),
                ],
              ),
            ),
          ),
          SizedBox(height: SpacingTokens.sectionSpacing),
          AsmblCard(
            child: Padding(
              padding: EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage Statistics',
                    style: TextStyles.bodyLarge.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: SpacingTokens.componentSpacing),
                  _buildUsageStat('Total Agents', '${_sampleAgents.length}', colors),
                  _buildUsageStat('Active Agents', '${_sampleAgents.where((a) => a.isActive).length}', colors),
                  _buildUsageStat('Total Usage', '${_sampleAgents.fold<int>(0, (sum, a) => sum + a.usageCount)}', colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, VoidCallback onPressed, ThemeColors colors) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SpacingTokens.iconSpacing),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 20),
            SizedBox(width: SpacingTokens.componentSpacing),
            Expanded(
              child: Text(
                title,
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStat(String label, String value, ThemeColors colors) {
    return Padding(
      padding: EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: SpacingTokens.sectionSpacing),
            Text(
              'No agents found',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Try adjusting your search terms or create a new agent',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SpacingTokens.sectionSpacing),
            AsmblButton.primary(
              text: 'Create First Agent',
              icon: Icons.add,
              onPressed: _createNewAgent,
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastUsed(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _createNewAgent() {
    // TODO: Implement agent creation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Agent'),
        content: Text('Agent creation functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _handleAgentAction(AgentConfig agent, String action) {
    // TODO: Implement agent actions
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Agent'),
        content: Text('${action.capitalize()} functionality for "${agent.name}" coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _toggleAgent(AgentConfig agent, bool value) {
    setState(() {
      agent.isActive = value;
    });
  }

  void _importConfig() {
    // TODO: Implement config import
  }

  void _exportAll() {
    // TODO: Implement export all
  }

  void _showTemplates() {
    // TODO: Implement template browser
  }
}

class AgentConfig {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  bool isActive;
  final DateTime lastUsed;
  final int usageCount;
  final String model;
  final Color color;

  AgentConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    required this.isActive,
    required this.lastUsed,
    required this.usageCount,
    required this.model,
    required this.color,
  });
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}