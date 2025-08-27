import 'package:flutter/material.dart';
import '../../../../../core/design_system/design_system.dart';
import 'universal_integration_card.dart';

/// Integration Cards Grid - Main content area showing all integration cards
/// Responsive grid that adapts to screen size and filters
class IntegrationCardsGrid extends StatelessWidget {
  final String searchQuery;
  final String selectedCategory;

  const IntegrationCardsGrid({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final filteredIntegrations = _getFilteredIntegrations();

    if (filteredIntegrations.isEmpty) {
      return _buildEmptyState(colors);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results Header
          if (searchQuery.isNotEmpty || selectedCategory != 'all')
            Padding(
              padding: EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
              child: Text(
                _buildResultsText(filteredIntegrations.length),
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          // Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
              
              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.4, // Width/Height ratio for cards
                  crossAxisSpacing: SpacingTokens.componentSpacing,
                  mainAxisSpacing: SpacingTokens.componentSpacing,
                ),
                itemCount: filteredIntegrations.length,
                itemBuilder: (context, index) {
                  final integration = filteredIntegrations[index];
                  return UniversalIntegrationCard(
                    integration: integration,
                    onPrimaryAction: () => _handlePrimaryAction(integration),
                    onSecondaryAction: () => _handleSecondaryAction(integration),
                  );
                },
              );
            },
          ),
          
          // Load More Button (if more integrations available)
          if (_hasMoreIntegrations())
            Padding(
              padding: EdgeInsets.only(top: SpacingTokens.sectionSpacing),
              child: Center(
                child: AsmblButton.secondary(
                  text: 'Show more integrations',
                  icon: Icons.expand_more,
                  onPressed: _loadMoreIntegrations,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    final isSearching = searchQuery.isNotEmpty;
    final isFiltering = selectedCategory != 'all';
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.hub_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: SpacingTokens.sectionSpacing),
            Text(
              isSearching 
                ? 'No integrations found'
                : isFiltering 
                  ? 'No integrations in this category'
                  : 'No integrations available',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              isSearching
                ? 'Try different search terms or browse categories'
                : isFiltering
                  ? 'Try selecting a different category'
                  : 'Integration marketplace will be available soon',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (isSearching || isFiltering) ...[
              SizedBox(height: SpacingTokens.sectionSpacing),
              AsmblButton.secondary(
                text: isSearching ? 'Clear search' : 'Show all categories',
                onPressed: _clearFilters,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildResultsText(int count) {
    final categoryText = selectedCategory != 'all' 
        ? ' in ${selectedCategory.replaceAll('_', ' ')}'
        : '';
    final searchText = searchQuery.isNotEmpty 
        ? ' for "$searchQuery"'
        : '';
    
    return '$count integration${count != 1 ? 's' : ''}$searchText$categoryText';
  }

  int _calculateCrossAxisCount(double width) {
    // Responsive grid: more columns for wider screens
    if (width > 1400) return 4;
    if (width > 1000) return 3;
    if (width > 600) return 2;
    return 1;
  }

  List<IntegrationCardData> _getFilteredIntegrations() {
    var integrations = _getAllIntegrations();
    
    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      integrations = integrations.where((integration) =>
        integration.name.toLowerCase().contains(query) ||
        integration.description.toLowerCase().contains(query)
      ).toList();
    }
    
    // Filter by category
    if (selectedCategory != 'all') {
      integrations = integrations.where((integration) =>
        integration.category == selectedCategory
      ).toList();
    }
    
    // Sort by status priority (configured/active first, then available)
    integrations.sort((a, b) {
      final statusPriority = {
        IntegrationStatus.active: 0,
        IntegrationStatus.configured: 1,
        IntegrationStatus.needsAttention: 2,
        IntegrationStatus.installing: 3,
        IntegrationStatus.error: 4,
        IntegrationStatus.available: 5,
      };
      
      final priorityA = statusPriority[a.status] ?? 5;
      final priorityB = statusPriority[b.status] ?? 5;
      
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      
      // Secondary sort by rating for same status
      return b.rating.compareTo(a.rating);
    });
    
    return integrations;
  }

  List<IntegrationCardData> _getAllIntegrations() {
    // Sample integration data - in real app this would come from a service
    return [
      IntegrationCardData(
        id: 'github',
        name: 'GitHub',
        description: 'Version control and collaborative development platform',
        icon: Icons.code,
        brandColor: Color(0xFF24292F),
        status: IntegrationStatus.active,
        category: 'development',
        rating: 4.9,
        metrics: [
          IntegrationMetric(label: 'Repos', value: '12', icon: Icons.folder),
          IntegrationMetric(label: 'Last sync', value: '2m ago', icon: Icons.sync),
        ],
      ),
      IntegrationCardData(
        id: 'notion',
        name: 'Notion',
        description: 'All-in-one workspace for notes, docs, and collaboration',
        icon: Icons.note,
        brandColor: Color(0xFF000000),
        status: IntegrationStatus.configured,
        category: 'productivity',
        rating: 4.7,
        metrics: [
          IntegrationMetric(label: 'Pages', value: '89', icon: Icons.description),
          IntegrationMetric(label: 'Updated', value: '1h ago', icon: Icons.update),
        ],
      ),
      IntegrationCardData(
        id: 'slack',
        name: 'Slack',
        description: 'Team communication and collaboration platform',
        icon: Icons.chat,
        brandColor: Color(0xFF4A154B),
        status: IntegrationStatus.needsAttention,
        category: 'communication',
        rating: 4.5,
        metrics: [
          IntegrationMetric(label: 'Channels', value: '8', icon: Icons.tag),
          IntegrationMetric(label: 'Messages', value: '1.2k', icon: Icons.message),
        ],
      ),
      IntegrationCardData(
        id: 'openai',
        name: 'OpenAI',
        description: 'Advanced AI models for natural language processing',
        icon: Icons.psychology,
        brandColor: Color(0xFF412991),
        status: IntegrationStatus.active,
        category: 'ai',
        rating: 4.8,
        metrics: [
          IntegrationMetric(label: 'API calls', value: '2.3k', icon: Icons.api),
          IntegrationMetric(label: 'Tokens', value: '45k', icon: Icons.token),
        ],
      ),
      IntegrationCardData(
        id: 'figma',
        name: 'Figma',
        description: 'Collaborative design and prototyping tool',
        icon: Icons.design_services,
        brandColor: Color(0xFFF24E1E),
        status: IntegrationStatus.available,
        category: 'development',
        rating: 4.6,
      ),
      IntegrationCardData(
        id: 'postgresql',
        name: 'PostgreSQL',
        description: 'Powerful open-source relational database system',
        icon: Icons.storage,
        brandColor: Color(0xFF336791),
        status: IntegrationStatus.installing,
        category: 'data',
        rating: 4.4,
      ),
      IntegrationCardData(
        id: 'aws',
        name: 'AWS',
        description: 'Amazon Web Services cloud computing platform',
        icon: Icons.cloud,
        brandColor: Color(0xFFFF9900),
        status: IntegrationStatus.error,
        category: 'development',
        rating: 4.3,
      ),
      IntegrationCardData(
        id: 'discord',
        name: 'Discord',
        description: 'Voice, video, and text communication platform',
        icon: Icons.forum,
        brandColor: Color(0xFF5865F2),
        status: IntegrationStatus.available,
        category: 'communication',
        rating: 4.2,
      ),
    ];
  }

  void _handlePrimaryAction(IntegrationCardData integration) {
    // Handle primary action based on integration status
    print('Primary action for ${integration.name}: ${integration.status}');
  }

  void _handleSecondaryAction(IntegrationCardData integration) {
    // Handle secondary action (settings, more options, etc.)
    print('Secondary action for ${integration.name}');
  }

  void _clearFilters() {
    // This would be handled by parent widget in real implementation
    print('Clear filters');
  }

  bool _hasMoreIntegrations() {
    // In real app, check if there are more integrations to load
    return false;
  }

  void _loadMoreIntegrations() {
    // Load more integrations from service
    print('Load more integrations');
  }
}