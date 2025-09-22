import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../providers/tools_provider.dart';
import '../widgets/server_management_tab.dart';
import '../widgets/catalogue_tab.dart';
import '../widgets/agent_connections_tab.dart';
import '../widgets/working_agent_connections_tab.dart';

class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final state = ref.watch(toolsProvider);

    return Scaffold(
      backgroundColor: colors.backgroundGradientStart,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
          ),
        ),
        child: Column(
          children: [
            // Navigation
            const AppNavigationBar(currentRoute: AppRoutes.integrationHub),
            
            // Combined Header with Tabs
            _buildHeaderWithTabs(colors, state),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ServerManagementTab(),
                  CatalogueTab(),
                  WorkingAgentConnectionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderWithTabs(ThemeColors colors, ToolsState state) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: colors.border.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Main header with integrated tabs on same line
          Padding(
            padding: const EdgeInsets.fromLTRB(SpacingTokens.xxl, SpacingTokens.lg, SpacingTokens.xxl, SpacingTokens.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon and Title
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Icon(
                    Icons.precision_manufacturing,
                    size: 20,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Give Your AI New Skills',
                      style: TextStyles.headingMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Connect your assistant to useful tools and services',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: SpacingTokens.lg),
                
                // Tab bar inline with title
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.dns, size: 16),
                        text: 'My Servers',
                      ),
                      Tab(
                        icon: Icon(Icons.hub, size: 16),
                        text: 'GitHub Registry',
                      ),
                      Tab(
                        icon: Icon(Icons.hub, size: 16),
                        text: 'Connections',
                      ),
                    ],
                    indicatorColor: colors.primary,
                    labelColor: colors.onSurface,
                    unselectedLabelColor: colors.onSurfaceVariant,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: TextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyles.caption,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
                  ),
                ),
                
                const SizedBox(width: SpacingTokens.lg),
                
                // Compact status indicators  
                if (state.isInitialized) ...[
                  _buildCompactStatusCard(
                    colors,
                    'Available',
                    state.installedServers.length.toString(),
                    Icons.auto_awesome,
                    colors.primary,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  _buildCompactStatusCard(
                    colors,
                    'Active',
                    state.installedServers.where((s) => s.isRunning).length.toString(),
                    Icons.check_circle,
                    colors.success,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  _buildCompactStatusCard(
                    colors,
                    'Connected',
                    state.agentConnections.fold<int>(
                      0,
                      (sum, connection) => sum + connection.connectedServerIds.length,
                    ).toString(),
                    Icons.hub,
                    colors.accent,
                  ),
                ],
                
                const SizedBox(width: SpacingTokens.md),
                
                // Compact actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        onPressed: () => ref.read(toolsProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh',
                        padding: EdgeInsets.all(SpacingTokens.xs),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    const SizedBox(width: SpacingTokens.xs),
                    AsmblButton.primary(
                      text: 'Browse Registry',
                      icon: Icons.hub,
                      onPressed: () async {
                        // Switch to GitHub Registry tab
                        _tabController.animateTo(1);

                        // Also open the external GitHub MCP Registry URL
                        final url = Uri.parse('https://github.com/modelcontextprotocol/servers');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      size: AsmblButtonSize.small,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusCard(
    ThemeColors colors,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}