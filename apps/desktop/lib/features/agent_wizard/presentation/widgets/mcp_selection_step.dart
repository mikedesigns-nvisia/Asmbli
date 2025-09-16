import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_catalog_service.dart';
import '../../../../core/models/mcp_catalog_entry.dart';
import '../../../../core/models/mcp_server_category.dart';
import '../../../../core/models/agent_mcp_server_config.dart';
import '../../../settings/presentation/widgets/mcp_server_setup_dialog.dart';
import '../../../settings/presentation/widgets/mcp_catalog_entry_card.dart';
import '../../../settings/presentation/screens/mcp_catalog_screen.dart';
import '../../models/agent_wizard_state.dart';

/// Third step of the agent wizard - MCP server selection using catalog system
class MCPSelectionStep extends ConsumerStatefulWidget {
  final AgentWizardState wizardState;
  final VoidCallback onChanged;

  const MCPSelectionStep({
    super.key,
    required this.wizardState,
    required this.onChanged,
  });

  @override
  ConsumerState<MCPSelectionStep> createState() => _MCPSelectionStepState();
}

class _MCPSelectionStepState extends ConsumerState<MCPSelectionStep> {
  bool _showRecommendations = true;

  @override
  Widget build(BuildContext context) {
    final catalogEntries = ref.watch(mcpFeaturedEntriesProvider);
    final agentId = widget.wizardState.id ?? 'temp-agent';
    final agentConfigs = ref.watch(agentMCPConfigsProvider(agentId));
    final colors = ThemeColors(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(context, colors),
              const SizedBox(height: SpacingTokens.xxl),
              
              if (_showRecommendations) ...[
                _buildRecommendationsSection(context, catalogEntries, colors),
                const SizedBox(height: SpacingTokens.xxl),
              ],
              
              _buildSelectedServersSection(context, agentConfigs, catalogEntries, colors),
              const SizedBox(height: SpacingTokens.xxl),
              
              _buildBrowseCatalogSection(context, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MCP Server Selection',
          style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Choose MCP servers to give your agent additional capabilities like file access, web search, or integration with external services.',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(
    BuildContext context, 
    List<MCPCatalogEntry> catalogEntries,
    ThemeColors colors
  ) {
    final recommendations = _getRecommendedEntries(catalogEntries);
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Recommended for Your Agent',
                  style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showRecommendations = false;
                    });
                  },
                  icon: Icon(Icons.close, size: 18, color: colors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              'Based on your agent type, these MCP servers might be useful:',
              style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: SpacingTokens.lg),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                return MCPCatalogEntryCard(
                  entry: recommendations[index],
                  onTap: () => _showServerSetupDialog(recommendations[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedServersSection(
    BuildContext context,
    Map<String, AgentMCPServerConfig> agentConfigs,
    List<MCPCatalogEntry> catalogEntries,
    ThemeColors colors,
  ) {
    final enabledServers = agentConfigs.entries
        .where((entry) => entry.value.enabled)
        .toList();

    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Selected MCP Servers (${enabledServers.length})',
                  style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            
            if (enabledServers.isEmpty) ...[
              Container(
                padding: EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: colors.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    Text(
                      'No MCP servers selected yet',
                      style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Text(
                      'Browse the catalog below to add capabilities to your agent',
                      style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: enabledServers.length,
                separatorBuilder: (context, index) => SizedBox(height: SpacingTokens.md),
                itemBuilder: (context, index) {
                  final configEntry = enabledServers[index];
                  final catalogEntry = catalogEntries
                      .where((entry) => entry.id == configEntry.key)
                      .firstOrNull;
                  
                  if (catalogEntry == null) return const SizedBox.shrink();
                  
                  return _buildSelectedServerCard(
                    catalogEntry, 
                    configEntry.value,
                    colors,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedServerCard(
    MCPCatalogEntry entry,
    AgentMCPServerConfig config,
    ThemeColors colors,
  ) {
    final isConfigured = config.isConfigured;
    
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: isConfigured ? colors.primary.withOpacity(0.3) : colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              _getServerIcon(entry.category ?? MCPServerCategory.custom),
              size: 20,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isConfigured ? Icons.check_circle : Icons.warning,
                      size: 14,
                      color: isConfigured ? colors.primary : Colors.orange,
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Text(
                      isConfigured ? 'Configured' : 'Auth required',
                      style: TextStyles.caption.copyWith(
                        color: isConfigured ? colors.primary : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleServerAction(value, entry),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'configure',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Configure'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.remove_circle),
                    SizedBox(width: 8),
                    Text('Remove'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseCatalogSection(BuildContext context, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.explore,
                  color: colors.accent,
                  size: 20,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Browse MCP Catalog',
                  style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              'Explore all available MCP servers including GitHub, Slack, file system access, web search, and more.',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: SpacingTokens.lg),
            AsmblButton.primary(
              text: 'Open MCP Catalog',
              onPressed: () => _openCatalog(context),
              icon: Icons.launch,
            ),
          ],
        ),
      ),
    );
  }

  List<MCPCatalogEntry> _getRecommendedEntries(List<MCPCatalogEntry> catalogEntries) {
    // Basic recommendations based on agent type or common use cases
    final recommended = <String>[
      'filesystem', // Most agents benefit from file access
      'github',     // Common for development agents
      'brave-search', // Useful for research and web tasks
    ];

    return catalogEntries
        .where((entry) => recommended.contains(entry.id))
        .take(3)
        .toList();
  }

  Future<void> _showServerSetupDialog(MCPCatalogEntry entry) async {
    final agentId = widget.wizardState.id ?? 'temp-agent';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MCPServerSetupDialog(
        catalogEntry: entry,
        agentId: agentId,
      ),
    );

    if (result == true) {
      widget.onChanged(); // Notify wizard of changes
      setState(() {}); // Refresh UI
    }
  }

  void _handleServerAction(String action, MCPCatalogEntry entry) async {
    final agentId = widget.wizardState.id ?? 'temp-agent';
    final catalogService = ref.read(mcpCatalogServiceProvider);

    switch (action) {
      case 'configure':
        await _showServerSetupDialog(entry);
        break;
      case 'remove':
        await catalogService.removeServerFromAgent(agentId, entry.id);
        widget.onChanged();
        setState(() {});
        break;
    }
  }

  void _openCatalog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MCPCatalogScreen(),
      ),
    );
  }

  IconData _getServerIcon(MCPServerCategory category) {
    switch (category) {
      case MCPServerCategory.development:
        return Icons.code;
      case MCPServerCategory.productivity:
        return Icons.trending_up;
      case MCPServerCategory.communication:
        return Icons.chat;
      case MCPServerCategory.dataAnalysis:
        return Icons.analytics;
      case MCPServerCategory.automation:
        return Icons.auto_awesome;
      case MCPServerCategory.fileManagement:
        return Icons.folder;
      case MCPServerCategory.webServices:
        return Icons.language;
      case MCPServerCategory.cloud:
        return Icons.cloud;
      case MCPServerCategory.database:
        return Icons.storage;
      case MCPServerCategory.security:
        return Icons.security;
      case MCPServerCategory.monitoring:
        return Icons.monitor;
      case MCPServerCategory.ai:
        return Icons.psychology;
      case MCPServerCategory.utility:
        return Icons.build;
      case MCPServerCategory.experimental:
        return Icons.science;
      case MCPServerCategory.custom:
        return Icons.extension;
    }
  }
}