import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/integration_service.dart';
import '../../../../core/services/integration_dependency_service.dart';
import '../../../../core/design_system/components/integration_status_indicators.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'integration_dependency_dialog.dart';
import '../widgets/mcp_server_dialog.dart';

class IntegrationMarketplace extends ConsumerStatefulWidget {
  const IntegrationMarketplace({super.key});

  @override
  ConsumerState<IntegrationMarketplace> createState() => _IntegrationMarketplaceState();
}

class _IntegrationMarketplaceState extends ConsumerState<IntegrationMarketplace> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Popular';
  bool _showConfiguredOnly = false;
  
  final List<String> _categories = [
    'All',
    ...IntegrationCategory.values.map((category) => category.displayName),
  ];
  
  final List<String> _sortOptions = ['Popular', 'Alphabetical', 'Category', 'Recently Added', 'Most Used'];
  
  @override
  Widget build(BuildContext context) {
    final integrationService = ref.watch(integrationServiceProvider);
    final allIntegrationsWithStatus = integrationService.getAllIntegrationsWithStatus();
    final filteredIntegrations = _filterIntegrations(allIntegrationsWithStatus);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: SpacingTokens.xxl),
          
          // Featured Integrations Banner
          _buildFeaturedSection(allIntegrationsWithStatus),
          SizedBox(height: SpacingTokens.xxl),
          
          // Search and Filters
          _buildSearchAndFilters(),
          SizedBox(height: SpacingTokens.xl),
          
          // Category Overview
          _buildCategoryOverview(allIntegrationsWithStatus),
          SizedBox(height: SpacingTokens.xxl),
          
          // Main Integration Grid
          _buildIntegrationsGrid(filteredIntegrations),
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
            Icon(
              Icons.store,
              color: SemanticColors.primary,
              size: 28,
            ),
            SizedBox(width: SpacingTokens.sm),
            Text(
              'Integration Marketplace',
              style: TextStyles.pageTitle,
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.xs),
        Text(
          'Discover and install powerful integrations to enhance your agents',
          style: TextStyles.bodyMedium.copyWith(
            color: SemanticColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeaturedSection(List<IntegrationStatus> allIntegrations) {
    // Get featured integrations (popular ones that are available)
    final featured = allIntegrations
        .where((status) => status.definition.isAvailable && !status.isConfigured)
        .take(3)
        .toList();
    
    if (featured.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: SemanticColors.warning, size: 16),
            SizedBox(width: SpacingTokens.xs),
            Text(
              'Featured Integrations',
              style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.lg),
        
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            separatorBuilder: (context, index) => SizedBox(width: SpacingTokens.lg),
            itemBuilder: (context, index) => _buildFeaturedCard(featured[index]),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeaturedCard(IntegrationStatus status) {
    return Container(
      width: 300,
      child: AsmblCard(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildIntegrationIcon(status.definition, size: 32),
                SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.definition.name,
                        style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        status.definition.category.displayName,
                        style: TextStyles.bodySmall.copyWith(
                          color: SemanticColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SemanticColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FEATURED',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: SemanticColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.sm),
            
            Text(
              status.definition.description,
              style: TextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            Spacer(),
            
            Row(
              children: [
                IntegrationStatusIndicators.difficultyBadge(status.definition.difficulty),
                Spacer(),
                AsmblButton.primary(
                  text: 'Install',
                  onPressed: () => _handleInstall(status),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        // Search Bar
        Expanded(
          flex: 3,
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search integrations...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                borderSide: BorderSide(color: SemanticColors.border),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: SpacingTokens.lg, vertical: SpacingTokens.sm),
            ),
          ),
        ),
        SizedBox(width: SpacingTokens.lg),
        
        // Category Filter
        Expanded(
          child: AsmblStringDropdown(
            value: _selectedCategory,
            items: _categories,
            onChanged: (value) => setState(() => _selectedCategory = value ?? 'All'),
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        
        // Sort By
        Expanded(
          child: AsmblStringDropdown(
            value: _sortBy,
            items: _sortOptions,
            onChanged: (value) => setState(() => _sortBy = value ?? 'Popular'),
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        
        // Show Configured Only Toggle
        Row(
          children: [
            Checkbox(
              value: _showConfiguredOnly,
              onChanged: (value) => setState(() => _showConfiguredOnly = value ?? false),
            ),
            Text(
              'Configured Only',
              style: TextStyles.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCategoryOverview(List<IntegrationStatus> allIntegrations) {
    final categoryStats = <IntegrationCategory, Map<String, int>>{};
    
    for (final category in IntegrationCategory.values) {
      final categoryIntegrations = allIntegrations.where((status) => status.definition.category == category);
      categoryStats[category] = {
        'total': categoryIntegrations.length,
        'configured': categoryIntegrations.where((status) => status.isConfigured).length,
        'available': categoryIntegrations.where((status) => status.definition.isAvailable).length,
      };
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse by Category',
          style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: SpacingTokens.lg),
        
        Wrap(
          spacing: SpacingTokens.sm,
          runSpacing: SpacingTokens.sm,
          children: IntegrationCategory.values.map((category) {
            final stats = categoryStats[category]!;
            final isSelected = _selectedCategory == category.displayName;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category.displayName),
              child: Container(
                padding: EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? SemanticColors.primary.withValues(alpha: 0.1)
                      : SemanticColors.surface,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  border: Border.all(
                    color: isSelected 
                        ? SemanticColors.primary
                        : SemanticColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: isSelected ? SemanticColors.primary : SemanticColors.onSurface,
                          size: 16,
                        ),
                        SizedBox(width: SpacingTokens.xs),
                        Text(
                          category.displayName,
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? SemanticColors.primary : SemanticColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SpacingTokens.xs),
                    Text(
                      '${stats['configured']}/${stats['available']} configured',
                      style: TextStyles.bodySmall.copyWith(
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
            Row(
              children: [
                Icon(Icons.grid_view, size: 16),
                SizedBox(width: SpacingTokens.xs),
                Icon(Icons.list, size: 16, color: SemanticColors.onSurfaceVariant),
              ],
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.lg),
        
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
    return AsmblCard(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and status
          Row(
            children: [
              _buildIntegrationIcon(status.definition),
              Spacer(),
              if (status.isConfigured)
                Icon(Icons.check_circle, color: SemanticColors.success, size: 16),
            ],
          ),
          SizedBox(height: SpacingTokens.sm),
          
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
          SizedBox(height: SpacingTokens.sm),
          
          // Description
          Expanded(
            child: Text(
              status.definition.description,
              style: TextStyles.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: SpacingTokens.sm),
          
          // Badges
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              IntegrationStatusIndicators.difficultyBadge(status.definition.difficulty, showIcon: false),
              if (!status.definition.isAvailable)
                IntegrationStatusIndicators.availabilityIndicator(status.definition),
              if (status.definition.prerequisites.isNotEmpty)
                IntegrationStatusIndicators.prerequisitesIndicator(status.definition.prerequisites),
            ],
          ),
          SizedBox(height: SpacingTokens.sm),
          
          // Action button
          SizedBox(
            width: double.infinity,
            child: AsmblButton.primary(
              text: _getActionText(status),
              onPressed: status.definition.isAvailable 
                  ? () => _handleAction(status)
                  : null,
              ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: SemanticColors.onSurfaceVariant,
          ),
          SizedBox(height: SpacingTokens.lg),
          Text(
            'No integrations found',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: SpacingTokens.xs),
          Text(
            'Try adjusting your search or filters',
            style: TextStyles.bodyMedium.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: SpacingTokens.lg),
          AsmblButton.secondary(
            text: 'Clear Filters',
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'All';
                _showConfiguredOnly = false;
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
        color: SemanticColors.primary.withValues(alpha: 0.1),
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
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = status.definition.name.toLowerCase().contains(query);
        final descMatch = status.definition.description.toLowerCase().contains(query);
        if (!nameMatch && !descMatch) return false;
      }
      
      // Category filter
      if (_selectedCategory != 'All' && 
          status.definition.category.displayName != _selectedCategory) {
        return false;
      }
      
      // Configured only filter
      if (_showConfiguredOnly && !status.isConfigured) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sorting
    switch (_sortBy) {
      case 'Alphabetical':
        filtered.sort((a, b) => a.definition.name.compareTo(b.definition.name));
        break;
      case 'Category':
        filtered.sort((a, b) => a.definition.category.displayName.compareTo(b.definition.category.displayName));
        break;
      case 'Recently Added':
        // Mock sorting - in real app would use actual dates
        filtered.sort((a, b) => a.definition.id.compareTo(b.definition.id));
        break;
      case 'Most Used':
        // Sort configured first, then by availability
        filtered.sort((a, b) {
          if (a.isConfigured && !b.isConfigured) return -1;
          if (!a.isConfigured && b.isConfigured) return 1;
          return 0;
        });
        break;
      case 'Popular':
      default:
        // Sort by: configured > available > coming soon
        filtered.sort((a, b) {
          if (a.isConfigured && !b.isConfigured) return -1;
          if (!a.isConfigured && b.isConfigured) return 1;
          if (a.definition.isAvailable && !b.definition.isAvailable) return -1;
          if (!a.definition.isAvailable && b.definition.isAvailable) return 1;
          return a.definition.name.compareTo(b.definition.name);
        });
        break;
    }
    
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
    
    // Show installation dialog
    showDialog(
      context: context,
      builder: (context) => MCPServerDialog(
        serverId: status.definition.id,
      ),
    ).then((result) {
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${status.definition.name} installed successfully!'),
            backgroundColor: SemanticColors.success,
          ),
        );
      }
    });
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
    }
  }
}