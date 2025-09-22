import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/integration_service.dart';
import '../../../../core/services/integration_dependency_service.dart';
import '../../../../core/services/integration_marketplace_service.dart';
// integration_installation_service is available via provider when needed
import '../../../../core/services/integration_health_monitoring_service.dart';
import '../../../../core/services/detection_integration_mapping.dart';
import '../../../../core/design_system/components/integration_status_indicators.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'integration_dependency_dialog.dart';
import '../widgets/mcp_server_dialog.dart';

class IntegrationMarketplace extends ConsumerStatefulWidget {
  final Map<String, bool>? detectedTools;

  const IntegrationMarketplace({
    super.key,
    this.detectedTools,
  });

  @override
  ConsumerState<IntegrationMarketplace> createState() => _IntegrationMarketplaceState();
}

class _IntegrationMarketplaceState extends ConsumerState<IntegrationMarketplace> {
  String _selectedCategory = 'All';
  bool _showDetectedOnly = false;
  
  @override
  Widget build(BuildContext context) {
    final integrationService = ref.watch(integrationServiceProvider);
    final marketplaceService = ref.watch(integrationMarketplaceServiceProvider);
    final healthService = ref.watch(integrationHealthMonitoringServiceProvider);
    final allIntegrationsWithStatus = integrationService.getAllIntegrationsWithStatus();
    final marketplaceStats = marketplaceService.getMarketplaceStatistics();
    final healthStats = healthService.getHealthStatistics();
    final filteredIntegrations = _filterIntegrations(allIntegrationsWithStatus);
    
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.detectedTools != null && widget.detectedTools!.isNotEmpty) ...[
            _buildDetectedToolsBanner(widget.detectedTools!),
            const SizedBox(height: SpacingTokens.lg),
          ],
          _buildHeader(),
          const SizedBox(height: SpacingTokens.lg),
          
          // Marketplace Stats Overview
          _buildMarketplaceStats(marketplaceStats, healthStats),
          const SizedBox(height: SpacingTokens.xxl),
          
          // Main content with sidebar
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar
                _buildSidebar(allIntegrationsWithStatus),
                const SizedBox(width: SpacingTokens.xxl),
                
                // Main content
                Expanded(
                  child: _buildMainContent(filteredIntegrations),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.store,
              color: SemanticColors.primary,
              size: 28,
            ),
            const SizedBox(width: SpacingTokens.sm),
            Text(
              'Integration Marketplace',
              style: TextStyles.pageTitle,
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          'Discover and install powerful integrations to enhance your agents',
          style: TextStyles.bodyMedium.copyWith(
            color: SemanticColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDetectedToolsBanner(Map<String, bool> detected) {
    final found = detected.entries.where((e) => e.value).map((e) => e.key).toList();
    if (found.isEmpty) return const SizedBox();

    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We found ${found.length} tools on your system',
                  style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  'Quick actions: configure detected tools or browse other integrations',
                  style: TextStyles.bodyMedium.copyWith(color: SemanticColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: SpacingTokens.lg),
          Column(
            children: [
              Row(
                children: [
                  AsmblButton.secondary(
                    text: _showDetectedOnly ? 'Show All' : 'Configure Detected',
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                        _showDetectedOnly = !_showDetectedOnly;
                      });
                    },
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  AsmblButton.primary(
                    text: 'Install Selected',
                    onPressed: () => _showConfigureDetectedDialog(detected),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConfigureDetectedDialog(Map<String, bool> detected) {
    final found = detected.entries.where((e) => e.value).map((e) => e.key).toList();
    showDialog(
      context: context,
      builder: (context) {
        final selections = <String, bool>{for (var k in found) k: true};
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Configure Detected Tools'),
              content: SizedBox(
                width: 520,
                height: 360,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: found.map((name) {
                          return CheckboxListTile(
                            value: selections[name],
                            title: Text(name),
                            onChanged: (v) => setState(() => selections[name] = v ?? false),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Text(
                      'Selected items will be auto-configured where we have an integration match.',
                      style: TextStyles.bodySmall.copyWith(color: SemanticColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                AsmblButton.primary(
                  text: 'Install Selected',
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final marketplaceService = ref.read(integrationMarketplaceServiceProvider);
                    final results = <String, bool>{};
                    for (final entry in selections.entries.where((e) => e.value)) {
                      final name = entry.key;
                      String? integrationId = mapDetectionToIntegrationId(name);
                      if (integrationId == null) {
                        // fallback to search
                        final matches = IntegrationRegistry.search(name);
                        if (matches.isNotEmpty) integrationId = matches.first;
                      }

                      if (integrationId != null) {
                        final res = await marketplaceService.installIntegration(integrationId, autoDetect: true);
                        results[name] = res.success;
                      } else {
                        results[name] = false;
                      }
                    }

                    final successCount = results.values.where((v) => v).length;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Installed $successCount of ${results.length} selected integrations'),
                        backgroundColor: successCount > 0 ? SemanticColors.success : SemanticColors.error,
                      ),
                    );
                    setState(() {});
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSidebar(List<IntegrationStatus> allIntegrations) {
    final categoryStats = <IntegrationCategory, Map<String, int>>{};
    
    for (final category in IntegrationCategory.values) {
      final categoryIntegrations = allIntegrations.where((status) => status.definition.category == category);
      categoryStats[category] = {
        'total': categoryIntegrations.length,
        'configured': categoryIntegrations.where((status) => status.isConfigured).length,
        'available': categoryIntegrations.where((status) => status.definition.isAvailable).length,
      };
    }
    
    return SizedBox(
      width: 280,
      child: AsmblCard(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: SpacingTokens.lg),
            
            // All category
            _buildSidebarCategoryItem(
              'All',
              Icons.apps,
              allIntegrations.length,
              allIntegrations.where((status) => status.isConfigured).length,
              _selectedCategory == 'All',
              () => setState(() => _selectedCategory = 'All'),
            ),
            const SizedBox(height: SpacingTokens.sm),
            
            // Individual categories
            ...IntegrationCategory.values.map((category) {
              final stats = categoryStats[category]!;
              final isSelected = _selectedCategory == category.displayName;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                child: _buildSidebarCategoryItem(
                  category.displayName,
                  _getCategoryIcon(category),
                  stats['total']!,
                  stats['configured']!,
                  isSelected,
                  () => setState(() => _selectedCategory = category.displayName),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSidebarCategoryItem(
    String name,
    IconData icon,
    int total,
    int configured,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        decoration: BoxDecoration(
          color: isSelected 
              ? SemanticColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          border: isSelected 
              ? Border.all(color: SemanticColors.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? SemanticColors.primary : SemanticColors.onSurface,
              size: 18,
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? SemanticColors.primary : SemanticColors.onSurface,
                    ),
                  ),
                  Text(
                    '$configured/$total configured',
                    style: TextStyles.bodySmall.copyWith(
                      color: SemanticColors.onSurfaceVariant,
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
  
  Widget _buildMainContent(List<IntegrationStatus> filteredIntegrations) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntegrationsGrid(filteredIntegrations),
        ],
      ),
    );
  }

  Widget _buildMarketplaceStats(MarketplaceStatistics marketplaceStats, HealthStatistics healthStats) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: SemanticColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: SemanticColors.border.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          _buildStatCard(
            'Available',
            '${marketplaceStats.available}',
            Icons.apps,
            SemanticColors.primary,
          ),
          const SizedBox(width: SpacingTokens.lg),
          _buildStatCard(
            'Installed',
            '${marketplaceStats.installed}',
            Icons.check_circle,
            SemanticColors.success,
          ),
          const SizedBox(width: SpacingTokens.lg),
          _buildStatCard(
            'Popular',
            '${marketplaceStats.popular}',
            Icons.star,
            SemanticColors.warning,
          ),
          const SizedBox(width: SpacingTokens.lg),
          _buildStatCard(
            'Recommended',
            '${marketplaceStats.recommended}',
            Icons.thumb_up,
            SemanticColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            value,
            style: TextStyles.bodyLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIntegrationsGrid(List<IntegrationStatus> integrations) {
    if (integrations.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Integrations (${integrations.length})',
              style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const Row(
              children: [
                Icon(Icons.grid_view, size: 16),
                SizedBox(width: SpacingTokens.xs),
                Icon(Icons.list, size: 16, color: SemanticColors.onSurfaceVariant),
              ],
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.lg),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.8,
            crossAxisSpacing: SpacingTokens.lg,
            mainAxisSpacing: SpacingTokens.lg,
          ),
          itemCount: integrations.length,
          itemBuilder: (context, index) => _buildIntegrationCard(integrations[index]),
        ),
      ],
    );
  }
  
  Widget _buildIntegrationCard(IntegrationStatus status) {
    // Determine if this integration matches any detected tool
    bool matchedByDetection = false;
    String? matchedToolName;
    if (widget.detectedTools != null && widget.detectedTools!.isNotEmpty) {
      for (final entry in widget.detectedTools!.entries) {
        if (!entry.value) continue;
        final mapped = mapDetectionToIntegrationId(entry.key);
        if (mapped != null && mapped == status.definition.id) {
          matchedByDetection = true;
          matchedToolName = entry.key;
          break;
        }
      }
    }
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and status
          Row(
            children: [
              _buildIntegrationIcon(status.definition),
              const Spacer(),
              if (status.isConfigured)
                const Icon(Icons.check_circle, color: SemanticColors.success, size: 16),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          
          // Name and category
          Text(
            status.definition.name,
            style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            status.definition.category.displayName,
            style: TextStyles.bodySmall.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          
          // Description
          Expanded(
            child: Text(
              status.definition.description,
              style: TextStyles.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          
          // Badges
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              IntegrationStatusIndicators.difficultyBadge(status.definition.difficulty, showIcon: false),
              if (matchedByDetection)
                Chip(
                  label: Text('Detected: ${matchedToolName ?? ''}'),
                  backgroundColor: SemanticColors.primary.withOpacity(0.12),
                ),
              if (!status.definition.isAvailable)
                IntegrationStatusIndicators.availabilityIndicator(status.definition),
              if (status.definition.prerequisites.isNotEmpty)
                IntegrationStatusIndicators.prerequisitesIndicator(status.definition.prerequisites),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          
          // Action button
          Row(
            children: [
              Expanded(
                child: AsmblButton.primary(
                  text: _getActionText(status),
                  onPressed: status.definition.isAvailable 
                      ? () => _handleAction(status)
                      : null,
                ),
              ),
              if (matchedByDetection) ...[
                const SizedBox(width: SpacingTokens.sm),
                TextButton(
                  onPressed: status.isConfigured ? () => _handleConfigure(status) : () => _handleInstall(status),
                  child: const Text('Configure'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.apps,
            size: 64,
            color: SemanticColors.onSurfaceVariant,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'No integrations in this category',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Try selecting a different category',
            style: TextStyles.bodyMedium.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          AsmblButton.secondary(
            text: 'Show All',
            onPressed: () {
              setState(() {
                _selectedCategory = 'All';
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildIntegrationIcon(IntegrationDefinition integration, {double size = 24}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SemanticColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        _getCategoryIcon(integration.category),
        color: SemanticColors.primary,
        size: size * 0.6,
      ),
    );
  }
  
  // Helper methods
  List<IntegrationStatus> _filterIntegrations(List<IntegrationStatus> integrations) {
    var filtered = integrations.where((status) {
      // Category filter
      if (_selectedCategory != 'All' && 
          status.definition.category.displayName != _selectedCategory) {
        return false;
      }
      
      // If showing detected only, filter by names passed from the wizard
      if (_showDetectedOnly && widget.detectedTools != null && widget.detectedTools!.isNotEmpty) {
        final detectedNames = widget.detectedTools!.entries.where((e) => e.value).map((e) => e.key).toList();
        // match if integration name appears in detected name list (case-insensitive)
        final name = status.definition.name.toLowerCase();
        final matches = detectedNames.any((d) => d.toLowerCase().contains(name) || name.contains(d.toLowerCase()));
        return matches;
      }

      return true;
    }).toList();
    
    // Sort by: configured > available > coming soon, then alphabetically
    filtered.sort((a, b) {
      if (a.isConfigured && !b.isConfigured) return -1;
      if (!a.isConfigured && b.isConfigured) return 1;
      if (a.definition.isAvailable && !b.definition.isAvailable) return -1;
      if (!a.definition.isAvailable && b.definition.isAvailable) return 1;
      return a.definition.name.compareTo(b.definition.name);
    });
    
    return filtered;
  }
  
  String _getActionText(IntegrationStatus status) {
    if (!status.definition.isAvailable) return 'Coming Soon';
    if (status.isConfigured) return 'Configure';
    return 'Install';
  }
  
  void _handleAction(IntegrationStatus status) {
    if (status.isConfigured) {
      _handleConfigure(status);
    } else {
      _handleInstall(status);
    }
  }
  
  void _handleInstall(IntegrationStatus status) async {
  final dependencyService = ref.read(integrationDependencyServiceProvider);
  final marketplaceService = ref.read(integrationMarketplaceServiceProvider);
    
    final depCheck = dependencyService.checkDependencies(status.definition.id);
    
    // Show dependency dialog if there are issues
    if (depCheck.missingRequired.isNotEmpty || depCheck.conflicts.isNotEmpty) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => IntegrationDependencyDialog(
          integrationId: status.definition.id,
          isRemoving: false,
        ),
      );
      
      if (shouldProceed != true) return;
      
      // If there are missing required dependencies, don't proceed
      if (depCheck.missingRequired.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please install required dependencies first: ${depCheck.missingRequired.join(', ')}'),
            backgroundColor: SemanticColors.error,
          ),
        );
        return;
      }
    }
    
    try {
      // Use the new installation service for enhanced workflow
      final result = await marketplaceService.installIntegration(
        status.definition.id,
        autoDetect: true,
      );
      
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${status.definition.name} installed successfully!'),
            backgroundColor: SemanticColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Installation failed: ${result.error ?? 'Unknown error'}'),
            backgroundColor: SemanticColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Installation error: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    }
  }
  
  void _handleConfigure(IntegrationStatus status) {
    showDialog(
      context: context,
      builder: (context) => MCPServerDialog(
        existingConfig: status.mcpConfig,
        serverId: status.definition.id,
      ),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${status.definition.name} updated successfully!'),
            backgroundColor: SemanticColors.success,
          ),
        );
      }
    });
  }
  
  IconData _getCategoryIcon(IntegrationCategory category) {
    switch (category) {
      case IntegrationCategory.local:
        return Icons.computer;
      case IntegrationCategory.cloudAPIs:
        return Icons.cloud;
      case IntegrationCategory.databases:
        return Icons.storage;
      case IntegrationCategory.aiML:
        return Icons.psychology;
      case IntegrationCategory.utilities:
        return Icons.build;
      case IntegrationCategory.devops:
        return Icons.settings;
    }
  }
}