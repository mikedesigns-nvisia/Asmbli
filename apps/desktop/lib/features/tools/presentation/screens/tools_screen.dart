import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../providers/tools_provider.dart';
import '../widgets/server_management_tab.dart';
import '../widgets/catalogue_tab.dart';
import '../widgets/agent_connections_tab.dart';

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
            
            // Header
            _buildHeader(colors, state),
            
            // Tab Bar
            _buildTabBar(colors),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ServerManagementTab(),
                  CatalogueTab(),
                  AgentConnectionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors, ToolsState state) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon and Title
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            child: Icon(
              Icons.precision_manufacturing,
              size: 24,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: SpacingTokens.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tools & Integrations',
                  style: TextStyles.pageTitle.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  'Manage MCP servers and connect them to your agents',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Status indicators
          if (state.isInitialized) ...[
            _buildStatusCard(
              colors,
              'Installed',
              state.installedServers.length.toString(),
              Icons.dns,
              colors.primary,
            ),
            const SizedBox(width: SpacingTokens.lg),
            _buildStatusCard(
              colors,
              'Running',
              state.installedServers.where((s) => s.isRunning).length.toString(),
              Icons.play_circle,
              colors.success,
            ),
            const SizedBox(width: SpacingTokens.lg),
            _buildStatusCard(
              colors,
              'Connections',
              state.agentConnections.fold<int>(
                0,
                (sum, connection) => sum + connection.connectedServerIds.length,
              ).toString(),
              Icons.hub,
              colors.accent,
            ),
          ],
          
          const SizedBox(width: SpacingTokens.lg),
          
          // Actions
          Row(
            children: [
              if (state.isLoading)
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  onPressed: () => ref.read(toolsProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              const SizedBox(width: SpacingTokens.sm),
              AsmblButton.primary(
                text: 'Install Server',
                icon: Icons.add,
                onPressed: () => _tabController.animateTo(1), // Navigate to marketplace
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeColors colors,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.dns),
            text: 'My Servers',
          ),
          Tab(
            icon: Icon(Icons.store),
            text: 'Catalogue',
          ),
          Tab(
            icon: Icon(Icons.hub),
            text: 'Agent Connections',
          ),
        ],
        indicatorColor: colors.primary,
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyles.bodyMedium,
      ),
    );
  }
}