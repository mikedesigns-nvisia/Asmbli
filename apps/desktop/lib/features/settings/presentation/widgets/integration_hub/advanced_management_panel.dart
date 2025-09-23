import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_system/design_system.dart';
import '../integration_health_dashboard.dart';
import '../integration_analytics_dashboard.dart';
import '../integration_testing_dashboard.dart';

/// Advanced Management Panel - Slide-out panel for expert features
/// Contains health monitoring, analytics, testing tools, and system controls
class AdvancedManagementPanel extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const AdvancedManagementPanel({
    super.key,
    this.onClose,
  });

  @override
  ConsumerState<AdvancedManagementPanel> createState() => _AdvancedManagementPanelState();
}

class _AdvancedManagementPanelState extends ConsumerState<AdvancedManagementPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<AdvancedTab> _tabs = [
    const AdvancedTab(
      id: 'health',
      label: 'Health',
      icon: Icons.health_and_safety,
      tooltip: 'System health monitoring',
    ),
    const AdvancedTab(
      id: 'analytics',
      label: 'Analytics',
      icon: Icons.analytics,
      tooltip: 'Usage analytics and insights',
    ),
    const AdvancedTab(
      id: 'testing',
      label: 'Testing',
      icon: Icons.bug_report,
      tooltip: 'Integration testing tools',
    ),
    const AdvancedTab(
      id: 'system',
      label: 'System',
      icon: Icons.settings_system_daydream,
      tooltip: 'System administration',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
    );
    // Tab controller listener removed as selectedTabIndex is not used
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Column(
      children: [
        // Panel header
        _buildHeader(colors),
        
        // Tab navigation
        _buildTabBar(colors),
        
        // Tab content
        Expanded(
          child: _buildTabContent(colors),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              Icons.tune,
              size: 20,
              color: colors.primary,
            ),
          ),
          
          const SizedBox(width: SpacingTokens.componentSpacing),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced Tools',
                  style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.xs_precise),
                Text(
                  'Expert-level management and monitoring',
                  style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(Icons.close, color: colors.onSurfaceVariant),
            tooltip: 'Close Advanced Panel',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border.withOpacity(0.5), width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurfaceVariant,
        indicatorColor: colors.primary,
        indicatorWeight: 2,
        labelStyle: TextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyles.caption,
        tabs: _tabs.map((tab) {
          return Tooltip(
            message: tab.tooltip,
            child: Tab(
              icon: Icon(tab.icon, size: 20),
              text: tab.label,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(ThemeColors colors) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildHealthTab(colors),
        _buildAnalyticsTab(colors),
        _buildTestingTab(colors),
        _buildSystemTab(colors),
      ],
    );
  }

  Widget _buildHealthTab(ThemeColors colors) {
    return const Padding(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: IntegrationHealthDashboard(),
    );
  }

  Widget _buildAnalyticsTab(ThemeColors colors) {
    return const Padding(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: IntegrationAnalyticsDashboard(),
    );
  }

  Widget _buildTestingTab(ThemeColors colors) {
    return const Padding(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: IntegrationTestingDashboard(),
    );
  }

  Widget _buildSystemTab(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: _buildSystemControls(colors),
    );
  }

  Widget _buildSystemControls(ThemeColors colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Information
          _buildSystemSection(
            title: 'System Information',
            icon: Icons.info,
            colors: colors,
            child: _buildSystemInfo(colors),
          ),
          
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Configuration Management
          _buildSystemSection(
            title: 'Configuration',
            icon: Icons.settings,
            colors: colors,
            child: _buildConfigurationControls(colors),
          ),
          
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Maintenance Tools
          _buildSystemSection(
            title: 'Maintenance',
            icon: Icons.build,
            colors: colors,
            child: _buildMaintenanceTools(colors),
          ),
          
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Debug Tools
          _buildSystemSection(
            title: 'Debug & Diagnostics',
            icon: Icons.bug_report,
            colors: colors,
            child: _buildDebugTools(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSection({
    required String title,
    required IconData icon,
    required ThemeColors colors,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: SpacingTokens.iconSpacing),
                Text(
                  title,
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: SpacingTokens.lg,
              right: SpacingTokens.lg,
              bottom: SpacingTokens.lg,
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo(ThemeColors colors) {
    // TODO: Get actual system information
    return Column(
      children: [
        _InfoRow('Integration Registry', 'v2.1.0', colors),
        _InfoRow('Active Integrations', '12', colors),
        _InfoRow('System Health', 'Good', colors),
        _InfoRow('Last Health Check', '2 minutes ago', colors),
        _InfoRow('Memory Usage', '45.2 MB', colors),
      ],
    );
  }

  Widget _buildConfigurationControls(ThemeColors colors) {
    return Column(
      children: [
        _ControlButton(
          icon: Icons.backup,
          label: 'Backup Configuration',
          description: 'Export all integration settings',
          onPressed: () => _exportConfiguration(),
          colors: colors,
        ),
        
        const SizedBox(height: SpacingTokens.iconSpacing),
        
        _ControlButton(
          icon: Icons.restore,
          label: 'Restore Configuration',
          description: 'Import integration settings',
          onPressed: () => _importConfiguration(),
          colors: colors,
        ),
        
        const SizedBox(height: SpacingTokens.iconSpacing),
        
        _ControlButton(
          icon: Icons.refresh,
          label: 'Reset to Defaults',
          description: 'Restore factory settings',
          isDestructive: true,
          onPressed: () => _resetToDefaults(),
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildMaintenanceTools(ThemeColors colors) {
    return Column(
      children: [
        _ControlButton(
          icon: Icons.cleaning_services,
          label: 'Clean Cache',
          description: 'Clear temporary files and cache',
          onPressed: () => _cleanCache(),
          colors: colors,
        ),
        
        const SizedBox(height: SpacingTokens.iconSpacing),
        
        _ControlButton(
          icon: Icons.sync,
          label: 'Sync Registry',
          description: 'Update integration definitions',
          onPressed: () => _syncRegistry(),
          colors: colors,
        ),
        
        const SizedBox(height: SpacingTokens.iconSpacing),
        
        _ControlButton(
          icon: Icons.healing,
          label: 'Repair Integrations',
          description: 'Auto-fix common issues',
          onPressed: () => _repairIntegrations(),
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildDebugTools(ThemeColors colors) {
    return Column(
      children: [
        _ControlButton(
          icon: Icons.memory,
          label: 'System Diagnostics',
          description: 'Run comprehensive system check',
          onPressed: () => _runDiagnostics(),
          colors: colors,
        ),
        
        const SizedBox(height: SpacingTokens.iconSpacing),
        
        _ControlButton(
          icon: Icons.description,
          label: 'Generate Report',
          description: 'Create detailed system report',
          onPressed: () => _generateReport(),
          colors: colors,
        ),
        
        const SizedBox(height: SpacingTokens.iconSpacing),
        
        _ControlButton(
          icon: Icons.code,
          label: 'Debug Console',
          description: 'Access low-level debugging',
          onPressed: () => _openDebugConsole(),
          colors: colors,
        ),
      ],
    );
  }

  // Action handlers - TODO: Implement actual functionality
  void _exportConfiguration() {}
  void _importConfiguration() {}
  void _resetToDefaults() {}
  void _cleanCache() {}
  void _syncRegistry() {}
  void _repairIntegrations() {}
  void _runDiagnostics() {}
  void _generateReport() {}
  void _openDebugConsole() {}
}

/// Information row widget for system details
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeColors colors;

  const _InfoRow(this.label, this.value, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.iconSpacing),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Control button widget for system actions
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final ThemeColors colors;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.colors,
    this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDestructive ? colors.error : colors.primary;
    final textColor = isDestructive ? colors.error : colors.onSurface;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        child: Container(
          padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDestructive 
                ? colors.error.withOpacity(0.3)
                : colors.border,
            ),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              
              const SizedBox(width: SpacingTokens.componentSpacing),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyles.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xs_precise),
                    Text(
                      description,
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Advanced tab configuration
class AdvancedTab {
  final String id;
  final String label;
  final IconData icon;
  final String tooltip;

  const AdvancedTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.tooltip,
  });
}