import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/components/mcp_testing_widgets.dart';
import '../../../../core/design_system/components/enhanced_template_browser.dart';
import '../../../../core/models/enhanced_mcp_template.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../core/services/enhanced_mcp_testing_service.dart';
import '../../../../core/services/intelligent_mcp_recommendations.dart';
import 'enhanced_mcp_server_wizard.dart';

/// Comprehensive MCP integration dashboard with management, monitoring, and recommendations
class EnhancedMCPDashboard extends ConsumerStatefulWidget {
  final String? agentRole;
  final String? agentDescription;

  const EnhancedMCPDashboard({
    super.key,
    this.agentRole,
    this.agentDescription,
  });

  @override
  ConsumerState<EnhancedMCPDashboard> createState() => _EnhancedMCPDashboardState();
}

class _EnhancedMCPDashboardState extends ConsumerState<EnhancedMCPDashboard> 
    with TickerProviderStateMixin {
  final _testingService = EnhancedMCPTestingService();
  final _recommendationService = IntelligentMCPRecommendations();
  
  late TabController _tabController;
  List<MCPRecommendation> _recommendations = [];
  Map<String, TestResult?> _testResults = {};
  String _searchQuery = '';
  String _filterCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadRecommendations() {
    final context = AgentContext(
      role: widget.agentRole,
      description: widget.agentDescription,
      existingMCPServers: ref.read(mcpSettingsServiceProvider).getAllMCPServers().keys.toList(),
    );
    
    setState(() {
      _recommendations = _recommendationService.getRecommendationsForAgent(
        agentRole: context.role,
        agentDescription: context.description,
        existingMCPServers: context.existingMCPServers,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with stats and actions
        _buildHeader(context),
        
        SizedBox(height: SpacingTokens.sectionSpacing),
        
        // Tab navigation
        _buildTabBar(context),
        
        SizedBox(height: SpacingTokens.sectionSpacing),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActiveIntegrationsTab(context),
              _buildRecommendationsTab(context),
              _buildBrowseIntegrationsTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final mcpService = ref.watch(mcpSettingsServiceProvider);
    final servers = mcpService.getAllMCPServers();
    final activeServers = servers.values.where((s) => s.enabled).length;
    final totalServers = servers.length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SemanticColors.primary.withValues(alpha: 0.1),
            SemanticColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SemanticColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hub,
                size: 24,
                color: SemanticColors.primary,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Integration Hub',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SemanticColors.primary,
                      ),
                    ),
                    Text(
                      'Manage your agent\'s external service connections',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AsmblButton.primary(
                text: 'Add Integration',
                icon: Icons.add,
                onPressed: _showAddIntegrationDialog,
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Stats row
          Row(
            children: [
              _buildStatCard(
                context,
                icon: Icons.link,
                label: 'Active',
                value: activeServers.toString(),
                color: SemanticColors.success,
              ),
              SizedBox(width: 16),
              _buildStatCard(
                context,
                icon: Icons.storage,
                label: 'Total',
                value: totalServers.toString(),
                color: SemanticColors.primary,
              ),
              SizedBox(width: 16),
              _buildStatCard(
                context,
                icon: Icons.auto_awesome,
                label: 'Suggested',
                value: _recommendations.length.toString(),
                color: Colors.orange,
              ),
              Spacer(),
              // Health indicator
              MCPHealthDashboard(
                serverIds: servers.keys.toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: Icon(Icons.link, size: 16),
            text: 'Active',
          ),
          Tab(
            icon: Icon(Icons.auto_awesome, size: 16),
            text: 'Recommended',
          ),
          Tab(
            icon: Icon(Icons.explore, size: 16),
            text: 'Browse All',
          ),
        ],
        labelColor: SemanticColors.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: SemanticColors.primary,
        dividerColor: Colors.transparent,
      ),
    );
  }

  Widget _buildActiveIntegrationsTab(BuildContext context) {
    final mcpService = ref.watch(mcpSettingsServiceProvider);
    final servers = mcpService.getAllMCPServers();
    final filteredServers = servers.entries.where((entry) {
      final config = entry.value;
      if (_searchQuery.isNotEmpty) {
        return config.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               config.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    if (filteredServers.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.hub_outlined,
        title: 'No integrations configured',
        message: 'Add your first integration to get started',
        actionText: 'Browse Integrations',
        onAction: () => _tabController.animateTo(2),
      );
    }

    return Column(
      children: [
        // Search and filter
        _buildSearchAndFilter(context),
        
        SizedBox(height: 16),
        
        // Server list
        Expanded(
          child: ListView.builder(
            itemCount: filteredServers.length,
            itemBuilder: (context, index) {
              final entry = filteredServers[index];
              return _buildServerCard(context, entry.key, entry.value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsTab(BuildContext context) {
    if (_recommendations.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.auto_awesome,
        title: 'No recommendations available',
        message: 'Complete your agent profile to get personalized recommendations',
        actionText: 'Browse All Integrations',
        onAction: () => _tabController.animateTo(2),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        return _buildRecommendationCard(context, recommendation);
      },
    );
  }

  Widget _buildBrowseIntegrationsTab(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: EnhancedTemplateBrowser(
        userRole: widget.agentRole,
        onTemplateSelected: (template) {
          _showConfigurationWizard(template);
        },
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search integrations...',
              prefixIcon: Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        SizedBox(width: 12),
        DropdownButton<String>(
          value: _filterCategory,
          onChanged: (value) => setState(() => _filterCategory = value!),
          items: ['All', ...TemplateCategories.all].map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category, style: TextStyle(fontSize: 12)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildServerCard(BuildContext context, String serverId, MCPServerConfig config) {
    final template = _findTemplateForServer(config);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showServerDetails(serverId, config),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Server icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (template?.brandColor ?? SemanticColors.primary).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        template?.icon ?? Icons.storage,
                        color: template?.brandColor ?? SemanticColors.primary,
                        size: 20,
                      ),
                    ),
                    
                    SizedBox(width: 12),
                    
                    // Server info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                config.name,
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(width: 8),
                              if (template != null)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    template.category,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            config.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Status and actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Connection status
                        MCPConnectionStatus(
                          testResult: _testResults[serverId],
                          onTap: () => _testConnection(serverId, config),
                        ),
                        
                        SizedBox(height: 8),
                        
                        // Enable/disable toggle
                        Switch(
                          value: config.enabled,
                          onChanged: (value) => _toggleServer(serverId, value),
                          activeColor: SemanticColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Quick actions
                SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _testConnection(serverId, config),
                      icon: Icon(Icons.play_arrow, size: 14),
                      label: Text('Test', style: TextStyle(fontSize: 11)),
                    ),
                    TextButton.icon(
                      onPressed: () => _editServer(serverId, config),
                      icon: Icon(Icons.edit, size: 14),
                      label: Text('Edit', style: TextStyle(fontSize: 11)),
                    ),
                    TextButton.icon(
                      onPressed: () => _duplicateServer(serverId, config),
                      icon: Icon(Icons.copy, size: 14),
                      label: Text('Duplicate', style: TextStyle(fontSize: 11)),
                    ),
                    Spacer(),
                    TextButton.icon(
                      onPressed: () => _deleteServer(serverId, config),
                      icon: Icon(Icons.delete, size: 14, color: SemanticColors.error),
                      label: Text('Delete', style: TextStyle(fontSize: 11, color: SemanticColors.error)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, MCPRecommendation recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: recommendation.category.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommendation.category.color.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showConfigurationWizard(recommendation.template),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Template icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (recommendation.template.brandColor ?? SemanticColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    recommendation.template.icon,
                    color: recommendation.template.brandColor ?? SemanticColors.primary,
                    size: 24,
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            recommendation.template.name,
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: recommendation.category.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              recommendation.category.displayName,
                              style: TextStyle(
                                fontSize: 9,
                                color: recommendation.category.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        recommendation.reason,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action button
                AsmblButton.secondary(
                  text: 'Add',
                  icon: Icons.add,
                  onPressed: () => _showConfigurationWizard(recommendation.template),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            SizedBox(height: 16),
            AsmblButton.primary(
              text: actionText,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }

  // Action methods
  void _showAddIntegrationDialog() {
    showDialog(
      context: context,
      builder: (context) => EnhancedMCPServerWizard(
        userRole: widget.agentRole,
        contextTags: widget.agentDescription?.split(' ') ?? [],
      ),
    ).then((result) {
      if (result == true) {
        _loadRecommendations();
        setState(() {}); // Refresh the dashboard
      }
    });
  }

  void _showConfigurationWizard(EnhancedMCPTemplate template) {
    showDialog(
      context: context,
      builder: (context) => EnhancedMCPServerWizard(
        userRole: widget.agentRole,
      ),
    ).then((result) {
      if (result == true) {
        _loadRecommendations();
        setState(() {});
      }
    });
  }

  void _showServerDetails(String serverId, MCPServerConfig config) {
    // Show detailed server information
  }

  void _testConnection(String serverId, MCPServerConfig config) async {
    final template = _findTemplateForServer(config);
    if (template != null) {
      final result = await _testingService.testConnection(
        serverId,
        template,
        config.env ?? {},
      );
      setState(() {
        _testResults[serverId] = result;
      });
    }
  }

  void _toggleServer(String serverId, bool enabled) {
    final mcpService = ref.read(mcpSettingsServiceProvider);
    final config = mcpService.getMCPServer(serverId);
    if (config != null) {
      final updatedConfig = MCPServerConfig(
        id: config.id,
        name: config.name,
        command: config.command,
        args: config.args,
        env: config.env,
        description: config.description,
        enabled: enabled,
        createdAt: config.createdAt,
        lastUpdated: DateTime.now(),
      );
      mcpService.setMCPServer(serverId, updatedConfig);
      setState(() {});
    }
  }

  void _editServer(String serverId, MCPServerConfig config) {
    showDialog(
      context: context,
      builder: (context) => EnhancedMCPServerWizard(
        existingConfig: config,
        serverId: serverId,
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _duplicateServer(String serverId, MCPServerConfig config) {
    // Create duplicate with modified name
    final duplicateConfig = MCPServerConfig(
      id: '${config.id}_copy',
      name: '${config.name} (Copy)',
      command: config.command,
      args: config.args,
      env: config.env,
      description: config.description,
      enabled: false,
      createdAt: DateTime.now(),
    );
    
    final mcpService = ref.read(mcpSettingsServiceProvider);
    mcpService.setMCPServer(duplicateConfig.id, duplicateConfig);
    setState(() {});
  }

  void _deleteServer(String serverId, MCPServerConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Integration'),
        content: Text('Are you sure you want to delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final mcpService = ref.read(mcpSettingsServiceProvider);
              mcpService.removeMCPServer(serverId);
              Navigator.of(context).pop();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: SemanticColors.error),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  EnhancedMCPTemplate? _findTemplateForServer(MCPServerConfig config) {
    return EnhancedMCPTemplates.allTemplates.where((template) {
      return template.command == config.command || 
             template.name.toLowerCase() == config.name.toLowerCase();
    }).firstOrNull;
  }
}