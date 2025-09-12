import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/data/mcp_server_configs.dart';
import '../../../../core/services/mcp_server_configuration_service.dart';
import '../../../../core/services/universal_detection_service.dart';
import '../../../../core/services/integration_service.dart';
import '../../../../core/services/integration_marketplace_service.dart';
import '../../../../core/services/integration_health_monitoring_service.dart' as health_monitoring;
import 'manual_mcp_server_modal.dart';
import 'custom_mcp_server_modal.dart';
import 'enhanced_auto_detection_modal.dart';
import 'integration_recommendations_widget.dart';


import '../../../../core/models/mcp_server_config.dart';

/// Enhanced integrations tab that ties together:
/// 1. Auto-detection → Available MCP servers
/// 2. Manual browsing → Curated server library  
/// 3. Custom configuration → JSON/manual input
/// 4. Agent integration → Add servers to agent configs
class EnhancedIntegrationsTab extends ConsumerStatefulWidget {
  const EnhancedIntegrationsTab({super.key});

  @override
  ConsumerState<EnhancedIntegrationsTab> createState() => _EnhancedIntegrationsTabState();
}

class _EnhancedIntegrationsTabState extends ConsumerState<EnhancedIntegrationsTab> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  MCPServerType? _filterType;
  MCPServerStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with action buttons
          _buildHeader(colors),
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Tab navigation
          _buildTabBar(colors),
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildMCPLibraryTab(),
                _buildDetectedIntegrationsTab(),
                _buildConfiguredServersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Icon(
            Icons.integration_instructions,
            size: 28,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: SpacingTokens.componentSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Integrations & MCP Servers',
                style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: SpacingTokens.xs_precise),
              Text(
                'Manage your AI agent integrations, MCP servers, and tool connections',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        // Quick actions
        Row(
          children: [
            AsmblButton.secondary(
              text: 'Auto-Detect',
              icon: Icons.auto_fix_high,
              onPressed: _showAutoDetection,
            ),
            const SizedBox(width: SpacingTokens.componentSpacing),
            AsmblButton.primary(
              text: 'Add MCP Server',
              icon: Icons.add,
              onPressed: _showAddServerOptions,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'MCP Library'),
          Tab(text: 'Detected Tools'),
          Tab(text: 'Configured'),
        ],
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurfaceVariant,
        indicator: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelStyle: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyles.bodyMedium,
      ),
    );
  }

  Widget _buildOverviewTab() {
    final integrationService = ref.watch(integrationServiceProvider);
    final marketplaceService = ref.watch(integrationMarketplaceServiceProvider);
    final healthService = ref.watch(health_monitoring.integrationHealthMonitoringServiceProvider);
    final colors = ThemeColors(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats
          _buildQuickStats(colors),
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Getting started section
          _buildGettingStartedSection(colors),
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Recommendations
          const IntegrationRecommendationsWidget(),
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Popular MCP servers
          _buildPopularServersSection(colors),
        ],
      ),
    );
  }

  Widget _buildMCPLibraryTab() {
    final colors = ThemeColors(context);
    final filteredServers = _getFilteredServers();
    
    return Column(
      children: [
        // Search and filter bar
        _buildServerFilters(colors),
        const SizedBox(height: SpacingTokens.componentSpacing),
        
        // Server library grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: SpacingTokens.componentSpacing,
              mainAxisSpacing: SpacingTokens.componentSpacing,
            ),
            itemCount: filteredServers.length,
            itemBuilder: (context, index) {
              final server = filteredServers[index];
              return _buildMCPServerCard(server, colors);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetectedIntegrationsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final detectionService = ref.watch(universalDetectionServiceProvider);
        
        return FutureBuilder<UniversalDetectionResult>(
          future: detectionService.detectEverything(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 48, color: ThemeColors(context).error),
                    const SizedBox(height: SpacingTokens.componentSpacing),
                    const Text('Failed to detect integrations'),
                    const SizedBox(height: SpacingTokens.componentSpacing),
                    AsmblButton.primary(
                      text: 'Retry Detection',
                      onPressed: () => setState(() {}),
                    ),
                  ],
                ),
              );
            }
            
            final result = snapshot.data!;
            return _buildDetectionResults(result);
          },
        );
      },
    );
  }

  Widget _buildConfiguredServersTab() {
    // TODO: Implement configured servers tab
    // This would show all currently configured MCP servers with management options
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 48, color: ThemeColors(context).onSurfaceVariant),
          const SizedBox(height: SpacingTokens.componentSpacing),
          Text(
            'Configured Servers',
            style: TextStyles.sectionTitle.copyWith(color: ThemeColors(context).onSurface),
          ),
          const SizedBox(height: SpacingTokens.iconSpacing),
          Text(
            'View and manage your configured MCP servers',
            style: TextStyles.bodyMedium.copyWith(color: ThemeColors(context).onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeColors colors) {
    final officialCount = MCPServerLibrary.getOfficialStableServers().length;
    final totalCount = MCPServerLibrary.servers.length;
    final noAuthCount = MCPServerLibrary.getServersWithoutAuth().length;
    
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total MCP Servers', '$totalCount', Icons.inventory, colors)),
        const SizedBox(width: SpacingTokens.componentSpacing),
        Expanded(child: _buildStatCard('Official Servers', '$officialCount', Icons.verified, colors)),
        const SizedBox(width: SpacingTokens.componentSpacing),
        Expanded(child: _buildStatCard('No Auth Required', '$noAuthCount', Icons.lock_open, colors)),
        const SizedBox(width: SpacingTokens.componentSpacing),
        Expanded(child: _buildStatCard('Configured', '0', Icons.check_circle, colors)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, ThemeColors colors) {
    return AsmblCard(
      child: Column(
        children: [
          Icon(icon, size: 24, color: colors.primary),
          const SizedBox(height: SpacingTokens.iconSpacing),
          Text(
            value,
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.xs_precise),
          Text(
            title,
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGettingStartedSection(ThemeColors colors) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Getting Started with MCP Integrations',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.componentSpacing),
          Text(
            'Connect your AI agents to powerful tools and services using the Model Context Protocol (MCP).',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: SpacingTokens.sectionSpacing),
          Row(
            children: [
              Expanded(
                child: _buildGettingStartedStep(
                  '1', 'Auto-Detect', 'Find installed tools automatically',
                  Icons.auto_fix_high, colors,
                ),
              ),
              const SizedBox(width: SpacingTokens.componentSpacing),
              Expanded(
                child: _buildGettingStartedStep(
                  '2', 'Browse Library', 'Select from curated MCP servers',
                  Icons.library_books, colors,
                ),
              ),
              const SizedBox(width: SpacingTokens.componentSpacing),
              Expanded(
                child: _buildGettingStartedStep(
                  '3', 'Configure', 'Add authentication and settings',
                  Icons.settings, colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGettingStartedStep(String number, String title, String description, IconData icon, ThemeColors colors) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Center(child: Icon(icon, color: colors.primary)),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: TextStyles.caption.copyWith(
                        color: colors.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        Text(
          title,
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs_precise),
        Text(
          description,
          style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPopularServersSection(ThemeColors colors) {
    final popularServers = MCPServerLibrary.getOfficialStableServers().take(6).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Popular MCP Servers',
              style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.componentSpacing),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: popularServers.length,
            itemBuilder: (context, index) {
              final server = popularServers[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: SpacingTokens.componentSpacing),
                child: _buildMCPServerCard(server, colors),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServerFilters(ThemeColors colors) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search MCP servers...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              contentPadding: const EdgeInsets.all(SpacingTokens.componentSpacing),
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.componentSpacing),
        DropdownButton<MCPServerType?>(
          value: _filterType,
          hint: const Text('Type'),
          onChanged: (value) => setState(() => _filterType = value),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Types')),
            ...MCPServerType.values.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type.name.toUpperCase()),
            )),
          ],
        ),
        const SizedBox(width: SpacingTokens.componentSpacing),
        DropdownButton<MCPServerStatus?>(
          value: _filterStatus,
          hint: const Text('Status'),
          onChanged: (value) => setState(() => _filterStatus = value),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Status')),
            ...MCPServerStatus.values.map((status) => DropdownMenuItem(
              value: status,
              child: Text(status.name.toUpperCase()),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildMCPServerCard(MCPServerConfig server, ThemeColors colors) {
    return AsmblCard(
      onTap: () => _showServerConfigModal(server),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.xs_precise),
                decoration: BoxDecoration(
                  color: server.type == MCPServerType.official
                    ? colors.primary.withValues(alpha: 0.1)
                    : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  server.type == MCPServerType.official ? 'OFFICIAL' : 'COMMUNITY',
                  style: TextStyles.caption.copyWith(
                    color: server.type == MCPServerType.official ? colors.primary : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              _buildStatusBadge(server.status, colors),
            ],
          ),
          const SizedBox(height: SpacingTokens.componentSpacing),
          Text(
            server.name,
            style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: SpacingTokens.xs_precise),
          Text(
            server.description,
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: SpacingTokens.componentSpacing),
          if (server.requiredEnvVars.isNotEmpty)
            Row(
              children: [
                Icon(Icons.key, size: 14, color: colors.warning),
                const SizedBox(width: SpacingTokens.xs_precise),
                Text(
                  'Requires Auth',
                  style: TextStyles.caption.copyWith(color: colors.warning),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MCPServerStatus status, ThemeColors colors) {
    Color getStatusColor() {
      switch (status) {
        case MCPServerStatus.stable: return Colors.green;
        case MCPServerStatus.beta: return Colors.orange;
        case MCPServerStatus.alpha: return Colors.red;
        case MCPServerStatus.deprecated: return colors.onSurfaceVariant;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.xs_precise,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyles.caption.copyWith(
          color: getStatusColor(),
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDetectionResults(UniversalDetectionResult result) {
    final colors = ThemeColors(context);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detection summary
          AsmblCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detection Results',
                  style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.componentSpacing),
                Text(
                  result.summary,
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: SpacingTokens.sectionSpacing),
                Row(
                  children: [
                    _buildDetectionStat('Found', '${result.totalIntegrationsFound}', colors),
                    const SizedBox(width: SpacingTokens.sectionSpacing),
                    _buildDetectionStat('Ready', '${result.totalReady}', colors),
                    const SizedBox(width: SpacingTokens.sectionSpacing),
                    _buildDetectionStat('Score', '${result.readinessScore}%', colors),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Detection categories
          ...result.detections.entries.map((entry) {
            final category = entry.key;
            final detection = entry.value;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detection.category,
                  style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.componentSpacing),
                if (detection.integrations.isEmpty)
                  Text(
                    'No integrations detected in this category',
                    style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                  )
                else
                  ...detection.integrations.map((integration) => Container(
                    margin: const EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
                    child: _buildDetectedIntegrationCard(integration, colors),
                  )),
                const SizedBox(height: SpacingTokens.sectionSpacing),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetectionStat(String label, String value, ThemeColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyles.pageTitle.copyWith(color: colors.primary),
        ),
        Text(
          label,
          style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildDetectedIntegrationCard(DetectedIntegration integration, ThemeColors colors) {
    final availableServers = MCPServerLibraryConfigurationService.getServersForIntegration(integration.id);
    
    return AsmblCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
            decoration: BoxDecoration(
              color: _getStatusColor(integration.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              _getStatusIcon(integration.status),
              color: _getStatusColor(integration.status),
            ),
          ),
          const SizedBox(width: SpacingTokens.componentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  integration.name,
                  style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.xs_precise),
                Text(
                  integration.message,
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                ),
                if (availableServers.isNotEmpty) ...[
                  const SizedBox(height: SpacingTokens.xs_precise),
                  Text(
                    '${availableServers.length} MCP server(s) available',
                    style: TextStyles.caption.copyWith(color: colors.primary),
                  ),
                ],
              ],
            ),
          ),
          if (availableServers.isNotEmpty)
            AsmblButton.secondary(
              text: 'Add MCP Server',
              onPressed: () => _showServerSelectionForIntegration(integration.id),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(DetectionStatus status) {
    switch (status) {
      case DetectionStatus.ready: return Colors.green;
      case DetectionStatus.needsAuth: return Colors.orange;
      case DetectionStatus.needsStart: return Colors.blue;
      case DetectionStatus.notFound: return Colors.grey;
    }
  }

  IconData _getStatusIcon(DetectionStatus status) {
    switch (status) {
      case DetectionStatus.ready: return Icons.check_circle;
      case DetectionStatus.needsAuth: return Icons.key;
      case DetectionStatus.needsStart: return Icons.play_arrow;
      case DetectionStatus.notFound: return Icons.help;
    }
  }

  List<MCPServerLibraryConfig> _getFilteredServers() {
    var servers = MCPServerLibrary.servers;
    
    if (_searchQuery.isNotEmpty) {
      servers = servers.where((server) =>
        server.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        server.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        server.capabilities.any((cap) => cap.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }
    
    if (_filterType != null) {
      servers = servers.where((server) => server.type == _filterType).toList();
    }
    
    if (_filterStatus != null) {
      servers = servers.where((server) => server.status == _filterStatus).toList();
    }
    
    return servers;
  }

  void _showAutoDetection() {
    showDialog(
      context: context,
      builder: (context) => EnhancedAutoDetectionModal(
        onComplete: () {
          // Refresh the detected integrations tab
          setState(() {});
          _tabController.animateTo(2);
        },
      ),
    );
  }

  void _showAddServerOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.sectionSpacing),
              child: Text(
                'Add MCP Server',
                style: TextStyles.sectionTitle.copyWith(color: ThemeColors(context).onSurface),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.library_books),
                    title: const Text('Browse Server Library'),
                    subtitle: const Text('Select from curated MCP servers'),
                    onTap: () {
                      Navigator.pop(context);
                      _showManualServerModal();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('Custom Configuration'),
                    subtitle: const Text('Add any MCP server with JSON'),
                    onTap: () {
                      Navigator.pop(context);
                      _showCustomServerModal();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_fix_high),
                    title: const Text('Auto-Detection'),
                    subtitle: const Text('Find and configure installed tools'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAutoDetection();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualServerModal() {
    showDialog(
      context: context,
      builder: (context) => ManualMCPServerModal(
        onConfigurationComplete: _handleMCPConfigAdded,
      ),
    );
  }

  void _showCustomServerModal() {
    showDialog(
      context: context,
      builder: (context) => CustomMCPServerModal(
        onConfigurationComplete: _handleMCPConfigAdded,
      ),
    );
  }

  void _showServerConfigModal(MCPServerConfig server) {
    showDialog(
      context: context,
      builder: (context) => ManualMCPServerModal(
        preselectedServerId: server.id,
        onConfigurationComplete: _handleMCPConfigAdded,
      ),
    );
  }

  void _showServerSelectionForIntegration(String integrationId) {
    final availableServers = MCPServerLibraryConfigurationService.getServersForIntegration(integrationId);
    
    if (availableServers.length == 1) {
      // Direct configuration for single server
      _showServerConfigModal(availableServers.first);
    } else {
      // Show selection dialog for multiple servers
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select MCP Server'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableServers.map((server) => ListTile(
              title: Text(server.name),
              subtitle: Text(server.description),
              onTap: () {
                Navigator.pop(context);
                _showServerConfigModal(server);
              },
            )).toList(),
          ),
        ),
      );
    }
  }

  Future<void> _handleMCPConfigAdded(Map<String, dynamic> config) async {
    // TODO: Implement MCP server configuration persistence
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('MCP server configuration added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Refresh the configured servers tab
    setState(() {});
    _tabController.animateTo(3);
  }
}