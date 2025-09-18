import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import '../../../../../core/design_system/design_system.dart';
import '../../../../../core/services/integration_service.dart';
import 'integration_card.dart';

/// Integration Grid - Main content area displaying filtered integration cards
/// Supports responsive layout, search filtering, and category-based organization
class IntegrationGrid extends ConsumerStatefulWidget {
  final String searchQuery;
  final String selectedCategory;
  final bool isExpertMode;
  final Function(String)? onIntegrationTap;
  final Function(String, String)? onIntegrationAction;

  const IntegrationGrid({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    this.isExpertMode = false,
    this.onIntegrationTap,
    this.onIntegrationAction,
  });

  @override
  ConsumerState<IntegrationGrid> createState() => _IntegrationGridState();
}

class _IntegrationGridState extends ConsumerState<IntegrationGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final integrationService = ref.watch(integrationServiceProvider);
    final allIntegrations = integrationService.getAllIntegrationsWithStatus();
    
    // Apply filtering
    final filteredIntegrations = _filterIntegrations(allIntegrations);
    
    // Check if we have any results
    if (filteredIntegrations.isEmpty) {
      return _buildEmptyState(colors);
    }

    // Group integrations for better organization
    final groupedIntegrations = _groupIntegrations(filteredIntegrations);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Priority integrations (suggested/active)
        if (groupedIntegrations['priority']?.isNotEmpty == true)
          _buildSection(
            'Recommended for You',
            groupedIntegrations['priority']!,
            colors,
            isPriority: true,
          ),
        
        // Active integrations
        if (groupedIntegrations['active']?.isNotEmpty == true)
          _buildSection(
            'Active Integrations',
            groupedIntegrations['active']!,
            colors,
          ),
        
        // Configured but inactive
        if (groupedIntegrations['configured']?.isNotEmpty == true)
          _buildSection(
            'Configured',
            groupedIntegrations['configured']!,
            colors,
          ),
        
        // Available integrations by category
        ...groupedIntegrations['available']?.entries.map((entry) {
          return _buildSection(
            _getCategoryDisplayName(entry.key),
            entry.value,
            colors,
          );
        }) ?? [],
      ],
    );
  }

  Widget _buildSection(
    String title,
    List<IntegrationStatus> integrations,
    ThemeColors colors, {
    bool isPriority = false,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(
              bottom: SpacingTokens.componentSpacing,
              top: SpacingTokens.sectionSpacing,
            ),
            child: Row(
              children: [
                if (isPriority)
                  Icon(
                    Icons.star,
                    size: 20,
                    color: colors.primary,
                  ),
                if (isPriority)
                  const SizedBox(width: SpacingTokens.iconSpacing),
                Text(
                  title,
                  style: TextStyles.sectionTitle.copyWith(
                    color: isPriority ? colors.primary : colors.onSurface,
                  ),
                ),
                const SizedBox(width: SpacingTokens.iconSpacing),
                Text(
                  '(${integrations.length})',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Integration grid
          _buildGrid(integrations, colors),
        ],
      ),
    );
  }

  Widget _buildGrid(List<IntegrationStatus> integrations, ThemeColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: _calculateAspectRatio(crossAxisCount),
            crossAxisSpacing: SpacingTokens.componentSpacing,
            mainAxisSpacing: SpacingTokens.componentSpacing,
          ),
          itemCount: integrations.length,
          itemBuilder: (context, index) {
            final integration = integrations[index];
            return IntegrationCard(
              integrationStatus: integration,
              isExpertMode: widget.isExpertMode,
              onTap: widget.onIntegrationTap,
              onAction: widget.onIntegrationAction,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    String title;
    String message;
    IconData icon;
    Widget? actionButton;

    if (widget.searchQuery.isNotEmpty) {
      // Empty search results
      title = 'No integrations found';
      message = 'Try adjusting your search or filter criteria';
      icon = Icons.search_off;
    } else if (widget.selectedCategory != 'all') {
      // Empty category
      title = 'No integrations in this category';
      message = 'Try exploring other categories or add new integrations';
      icon = Icons.category;
      actionButton = AsmblButton.primary(
        text: 'Browse All Integrations',
        onPressed: () => _clearFilters(),
      );
    } else {
      // No integrations at all (shouldn't happen)
      title = 'No integrations available';
      message = 'Start by running auto-detection or adding integrations manually';
      icon = Icons.extension_off;
      actionButton = AsmblButton.primary(
        text: 'Run Auto Detection',
        onPressed: () => _runAutoDetection(),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.xxl),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withOpacity( 0.5),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
            ),
            child: Icon(
              icon,
              size: 64,
              color: colors.onSurfaceVariant.withOpacity( 0.5),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          Text(
            title,
            style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
          ),
          
          const SizedBox(height: SpacingTokens.componentSpacing),
          
          Text(
            message,
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (actionButton != null) ...[
            const SizedBox(height: SpacingTokens.sectionSpacing),
            actionButton,
          ],
        ],
      ),
    );
  }

  // Helper methods
  List<IntegrationStatus> _filterIntegrations(List<IntegrationStatus> integrations) {
    var filtered = integrations.where((integration) {
      // Search query filter
      if (widget.searchQuery.isNotEmpty) {
        final query = widget.searchQuery.toLowerCase();
        final name = integration.definition.name.toLowerCase();
        final description = integration.definition.description.toLowerCase();
        final tags = integration.definition.tags.join(' ').toLowerCase();
        
        if (!name.contains(query) && 
            !description.contains(query) && 
            !tags.contains(query)) {
          return false;
        }
      }
      
      // Category filter
      if (widget.selectedCategory != 'all') {
        switch (widget.selectedCategory) {
          case 'active':
            return integration.isEnabled && integration.isConfigured;
          case 'configured':
            return integration.isConfigured && !integration.isEnabled;
          case 'available':
            return !integration.isConfigured;
          case 'suggested':
            return _isSuggested(integration);
          default:
            // Category-based filtering
            return _matchesCategory(integration, widget.selectedCategory);
        }
      }
      
      return true;
    }).toList();

    // Sort integrations by relevance
    filtered.sort((a, b) => _compareIntegrations(a, b));
    
    return filtered;
  }

  Map<String, dynamic> _groupIntegrations(List<IntegrationStatus> integrations) {
    final groups = <String, dynamic>{
      'priority': <IntegrationStatus>[],
      'active': <IntegrationStatus>[],
      'configured': <IntegrationStatus>[],
      'available': <String, List<IntegrationStatus>>{},
    };

    for (final integration in integrations) {
      if (_isSuggested(integration)) {
        groups['priority'].add(integration);
      } else if (integration.isEnabled && integration.isConfigured) {
        groups['active'].add(integration);
      } else if (integration.isConfigured) {
        groups['configured'].add(integration);
      } else {
        // Group available integrations by category
        final category = _getCategoryKey(integration.definition.category);
        groups['available'][category] ??= <IntegrationStatus>[];
        groups['available'][category].add(integration);
      }
    }

    return groups;
  }

  bool _isSuggested(IntegrationStatus integration) {
    // TODO: Implement actual suggestion logic
    // For now, mock some suggestions based on common integrations
    final commonIntegrations = ['git', 'vscode', 'github', 'slack'];
    return commonIntegrations.contains(integration.definition.id.toLowerCase());
  }

  bool _matchesCategory(IntegrationStatus integration, String categoryFilter) {
    final categoryKey = _getCategoryKey(integration.definition.category);
    return categoryKey == categoryFilter;
  }

  String _getCategoryKey(IntegrationCategory category) {
    switch (category) {
      case IntegrationCategory.local:
        return 'development';
      case IntegrationCategory.cloudAPIs:
        return 'productivity';
      case IntegrationCategory.databases:
        return 'data';
      case IntegrationCategory.aiML:
        return 'ai';
      default:
        return 'other';
    }
  }

  String _getCategoryDisplayName(String categoryKey) {
    switch (categoryKey) {
      case 'development':
        return 'Development Tools';
      case 'productivity':
        return 'Cloud APIs';
      case 'data':
        return 'Data & Storage';
      case 'ai':
        return 'AI & ML';
      default:
        return 'Other';
    }
  }

  int _compareIntegrations(IntegrationStatus a, IntegrationStatus b) {
    // Priority order: Active > Configured > Suggested > Available
    final aScore = _getIntegrationScore(a);
    final bScore = _getIntegrationScore(b);
    
    if (aScore != bScore) {
      return bScore.compareTo(aScore); // Higher scores first
    }
    
    // Secondary sort by name
    return a.definition.name.compareTo(b.definition.name);
  }

  int _getIntegrationScore(IntegrationStatus integration) {
    if (integration.isEnabled && integration.isConfigured) {
      return 4; // Active
    } else if (integration.isConfigured) {
      return 3; // Configured
    } else if (_isSuggested(integration)) {
      return 2; // Suggested
    } else {
      return 1; // Available
    }
  }

  int _calculateCrossAxisCount(double width) {
    if (width < 600) {
      return 1; // Mobile
    } else if (width < 900) {
      return 2; // Tablet
    } else if (width < 1200) {
      return 3; // Small desktop
    } else {
      return 4; // Large desktop
    }
  }

  double _calculateAspectRatio(int crossAxisCount) {
    // Adjust card height based on grid density
    switch (crossAxisCount) {
      case 1:
        return 2.5; // Taller cards for single column
      case 2:
        return 1.8;
      case 3:
        return 1.4;
      case 4:
      default:
        return 1.2; // More compact cards for dense grid
    }
  }

  void _clearFilters() {
    // TODO: Implement filter clearing
  }

  void _runAutoDetection() {
    // TODO: Implement auto-detection trigger
  }
}