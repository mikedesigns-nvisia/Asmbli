import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../providers/agent_provider.dart';

class AgentSettingsScreen extends ConsumerStatefulWidget {
  const AgentSettingsScreen({super.key});

  @override
  ConsumerState<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends ConsumerState<AgentSettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';


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

  List<Agent> _getFilteredAgents(List<Agent> agents) {

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      agents = agents.where((agent) =>
        agent.name.toLowerCase().contains(query) ||
        agent.description.toLowerCase().contains(query) ||
        (agent.configuration['model']?.toString() ?? '').toLowerCase().contains(query)
      ).toList();
    }

    // Apply status filter
    switch (_selectedFilter) {
      case 'active':
        agents = agents.where((agent) => agent.status == AgentStatus.active || agent.status == AgentStatus.idle).toList();
        break;
      case 'inactive':
        agents = agents.where((agent) => agent.status == AgentStatus.paused || agent.status == AgentStatus.error).toList();
        break;
    }

    // Sort by name for now (usage tracking would need additional data)
    agents.sort((a, b) => a.name.compareTo(b.name));

    return agents;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final agentsAsync = ref.watch(agentNotifierProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.background,
              colors.background.withOpacity( 0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            const AppNavigationBar(currentRoute: AppRoutes.settings),
            _buildHeader(colors),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: agentsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => _buildErrorState(colors, error.toString()),
                      data: (agents) => _buildMainContent(colors, _getFilteredAgents(agents)),
                    ),
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
      padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity( 0.8),
        border: Border(
          bottom: BorderSide(color: colors.border.withOpacity( 0.5)),
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
              const SizedBox(width: SpacingTokens.componentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Agents',
                      style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: SpacingTokens.xs_precise),
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
          const SizedBox(height: SpacingTokens.sectionSpacing),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.componentSpacing),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: colors.onSurfaceVariant, size: 20),
                      const SizedBox(width: SpacingTokens.componentSpacing),
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
              const SizedBox(width: SpacingTokens.componentSpacing),
              _buildFilterChips(colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeColors colors) {
    final filters = [
      ('all', 'All', 0), // Count will be updated dynamically
      ('active', 'Active', 0),
      ('inactive', 'Inactive', 0),
    ];

    return Row(
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter.$1;
        return Padding(
          padding: const EdgeInsets.only(right: SpacingTokens.iconSpacing),
          child: FilterChip(
            label: Text('${filter.$2} (${filter.$3})'),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filter.$1;
              });
            },
            backgroundColor: colors.surface,
            selectedColor: colors.primary.withOpacity( 0.1),
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

  Widget _buildMainContent(ThemeColors colors, List<Agent> agents) {
    if (agents.isEmpty) {
      return _buildEmptyState(colors);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agents (${agents.length})',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.componentSpacing),
          ...agents.map((agent) => Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
            child: _buildAgentCard(agent, colors),
          )),
        ],
      ),
    );
  }

  Widget _buildAgentCard(Agent agent, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: SpacingTokens.componentSpacing),
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
                          const SizedBox(width: SpacingTokens.iconSpacing),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingTokens.iconSpacing,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getAgentStatusColor(agent.status).withOpacity( 0.1),
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                            ),
                            child: Text(
                              _getAgentStatusText(agent.status),
                              style: TextStyles.caption.copyWith(
                                color: _getAgentStatusColor(agent.status),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SpacingTokens.xs_precise),
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
                    const PopupMenuItem(value: 'edit', child: Text('Edit Agent')),
                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                    const PopupMenuItem(value: 'export', child: Text('Export Config')),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete', 
                      child: Text('Delete', style: TextStyle(color: colors.error)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity( 0.3),
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
                  const SizedBox(height: SpacingTokens.xs_precise),
                  Text(
                    (agent.configuration['systemPrompt']?.toString().length ?? 0) > 100 
                      ? '${agent.configuration['systemPrompt']?.toString().substring(0, 100)}...'
                      : agent.configuration['systemPrompt']?.toString() ?? 'No system prompt configured',
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Row(
              children: [
                _buildAgentStat('Model', agent.configuration['model']?.toString() ?? 'Not configured', Icons.psychology, colors),
                const SizedBox(width: SpacingTokens.sectionSpacing),
                _buildAgentStat('Capabilities', '${agent.capabilities.length} items', Icons.bar_chart, colors),
                const SizedBox(width: SpacingTokens.sectionSpacing),
                _buildAgentStat('Status', _getAgentStatusText(agent.status), Icons.schedule, colors),
                const Spacer(),
                Switch(
                  value: agent.status != AgentStatus.paused && agent.status != AgentStatus.error,
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
        const SizedBox(width: SpacingTokens.iconSpacing),
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

  // Sidebar removed as requested by user

  // Quick action and usage stat builders removed with sidebar

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withOpacity( 0.5),
            ),
            const SizedBox(height: SpacingTokens.sectionSpacing),
            Text(
              'No agents found',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Try adjusting your search terms or create a new agent',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.sectionSpacing),
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

  // Last used formatter removed - not needed for Agent model

  void _createNewAgent() {
    // TODO: Implement agent creation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Agent'),
        content: const Text('Agent creation functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }


  void _handleAgentAction(Agent agent, String action) {
    // TODO: Implement agent actions
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Agent'),
        content: Text('${action.capitalize()} functionality for "${agent.name}" coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _toggleAgent(Agent agent, bool value) {
    final newStatus = value ? AgentStatus.idle : AgentStatus.paused;
    ref.read(agentNotifierProvider.notifier).setAgentStatus(agent.id, newStatus);
  }

  // Export functionality removed as requested by user

  Color _getAgentStatusColor(AgentStatus status) {
    final colors = ThemeColors(context);
    switch (status) {
      case AgentStatus.active:
        return Colors.green;
      case AgentStatus.idle:
        return Colors.blue;
      case AgentStatus.paused:
        return colors.onSurfaceVariant;
      case AgentStatus.error:
        return Colors.red;
    }
  }

  String _getAgentStatusText(AgentStatus status) {
    switch (status) {
      case AgentStatus.active:
        return 'ACTIVE';
      case AgentStatus.idle:
        return 'IDLE';
      case AgentStatus.paused:
        return 'PAUSED';
      case AgentStatus.error:
        return 'ERROR';
    }
  }

  Widget _buildErrorState(ThemeColors colors, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colors.error,
            ),
            const SizedBox(height: SpacingTokens.sectionSpacing),
            Text(
              'Error Loading Agents',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              error,
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.sectionSpacing),
            AsmblButton.primary(
              text: 'Retry',
              icon: Icons.refresh,
              onPressed: () => ref.invalidate(agentNotifierProvider),
            ),
          ],
        ),
      ),
    );
  }
}

// AgentConfig class removed - now using Agent model from agent_engine_core

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}