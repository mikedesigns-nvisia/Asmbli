import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/mcp_catalog_entry.dart';
import '../../../../core/services/mcp_catalog_service.dart';
import '../../../../features/settings/presentation/widgets/mcp_catalog_entry_card.dart';

class CatalogueTab extends ConsumerStatefulWidget {
  const CatalogueTab({super.key});

  @override
  ConsumerState<CatalogueTab> createState() => _CatalogueTabState();
}

class _CatalogueTabState extends ConsumerState<CatalogueTab> {
  String _searchQuery = '';
  MCPServerCategory? _selectedCategory;
  bool _showOnlyFeatured = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final catalogEntries = ref.watch(mcpCatalogEntriesProvider);
    final filteredEntries = _filterEntries(catalogEntries);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'MCP Server Catalogue',
                style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
              ),
              const Spacer(),
              AsmblButton.secondary(
                text: 'Refresh',
                icon: Icons.refresh,
                onPressed: () {
                  // Force refresh of catalog
                  ref.invalidate(mcpCatalogEntriesProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Discover and configure MCP servers to extend your agent capabilities',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          // Search and Filters
          _buildSearchAndFilters(colors),
          const SizedBox(height: SpacingTokens.lg),
          
          // Content
          if (filteredEntries.isEmpty) 
            _buildEmptyState(colors)
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  print('📐 CatalogueTab Grid Debug: width=${constraints.maxWidth}, using 4 columns (fixed)');
                  
                  // Calculate column width for 4 columns with spacing
                  final spacing = SpacingTokens.lg;
                  final totalSpacing = spacing * 3; // 3 gaps between 4 columns
                  final columnWidth = (constraints.maxWidth - totalSpacing) / 4;
                  
                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: filteredEntries.map((entry) {
                        return SizedBox(
                          width: columnWidth,
                          child: MCPCatalogEntryCard(
                            entry: entry,
                            onTap: () => _showServerDetails(context, entry),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeColors colors) {
    return Row(
      children: [
        // Search field
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search MCP servers...',
              hintStyle: TextStyle(color: colors.onSurfaceVariant),
              prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
              filled: true,
              fillColor: colors.surface.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
            ),
            style: TextStyle(color: colors.onSurface),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        
        const SizedBox(width: SpacingTokens.md),
        
        // Category filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
          child: DropdownButton<MCPServerCategory?>(
            value: _selectedCategory,
            hint: Text('Category', style: TextStyle(color: colors.onSurfaceVariant)),
            dropdownColor: colors.surface,
            style: TextStyle(color: colors.onSurface),
            underline: const SizedBox(),
            items: [
              DropdownMenuItem<MCPServerCategory?>(
                value: null,
                child: Text('All Categories', style: TextStyle(color: colors.onSurface)),
              ),
              ...MCPServerCategory.values.map((category) => DropdownMenuItem(
                value: category,
                child: Text(_getCategoryDisplayName(category), style: TextStyle(color: colors.onSurface)),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
        ),
        
        const SizedBox(width: SpacingTokens.md),
        
        // Featured toggle
        AsmblButton.secondary(
          text: _showOnlyFeatured ? 'Show All' : 'Featured Only',
          icon: _showOnlyFeatured ? Icons.star : Icons.star_outline,
          onPressed: () {
            setState(() {
              _showOnlyFeatured = !_showOnlyFeatured;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
              ),
              child: Icon(
                Icons.search_off,
                size: 40,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'No servers found',
              style: TextStyles.headlineSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              'Try adjusting your search or filters',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  List<MCPCatalogEntry> _filterEntries(List<MCPCatalogEntry> entries) {
    var filtered = entries.toList();
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((entry) {
        return entry.name.toLowerCase().contains(query) ||
               entry.description.toLowerCase().contains(query) ||
               entry.capabilities.any((cap) => cap.toLowerCase().contains(query));
      }).toList();
    }
    
    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((entry) => entry.category == _selectedCategory).toList();
    }
    
    // Apply featured filter
    if (_showOnlyFeatured) {
      filtered = filtered.where((entry) => entry.isFeatured).toList();
    }
    
    return filtered;
  }

  String _getCategoryDisplayName(MCPServerCategory category) {
    switch (category) {
      case MCPServerCategory.ai:
        return 'AI & Machine Learning';
      case MCPServerCategory.cloud:
        return 'Cloud Services';
      case MCPServerCategory.communication:
        return 'Communication';
      case MCPServerCategory.database:
        return 'Database';
      case MCPServerCategory.design:
        return 'Design & Media';
      case MCPServerCategory.development:
        return 'Development';
      case MCPServerCategory.filesystem:
        return 'File System';
      case MCPServerCategory.productivity:
        return 'Productivity';
      case MCPServerCategory.security:
        return 'Security';
      case MCPServerCategory.web:
        return 'Web & APIs';
    }
  }

  void _showServerDetails(BuildContext context, MCPCatalogEntry entry) {
    final colors = ThemeColors(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.name,
                style: TextStyle(color: colors.onSurface),
              ),
            ),
            if (entry.isFeatured)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  'FEATURED',
                  style: TextStyles.caption.copyWith(
                    color: colors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                'Description',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                entry.description,
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: SpacingTokens.lg),
              
              // Capabilities
              Text(
                'Capabilities',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Wrap(
                spacing: SpacingTokens.xs,
                runSpacing: SpacingTokens.xs,
                children: entry.capabilities.map((capability) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.sm,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Text(
                    capability,
                    style: TextStyles.caption.copyWith(color: colors.accent),
                  ),
                )).toList(),
              ),
              
              const SizedBox(height: SpacingTokens.lg),
              
              // Category
              Text(
                'Category',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                _getCategoryDisplayName(entry.category),
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        actions: [
          AsmblButton.secondary(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AsmblButton.primary(
            text: 'Configure',
            onPressed: () {
              Navigator.of(context).pop();
              _showConfigurationDialog(context, entry);
            },
          ),
        ],
      ),
    );
  }

  void _showConfigurationDialog(BuildContext context, MCPCatalogEntry entry) {
    final colors = ThemeColors(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Configure ${entry.name}',
          style: TextStyle(color: colors.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This server requires configuration before it can be used with your agents.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: SpacingTokens.lg),
            
            // Required auth info
            if (entry.requiredAuth.isNotEmpty) ...[
              Text(
                'Required Authentication:',
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              ...entry.requiredAuth.map((auth) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      auth.required ? Icons.circle : Icons.radio_button_unchecked,
                      size: 8,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Text(
                      auth.name,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    if (auth.required)
                      Text(
                        ' (required)',
                        style: TextStyle(
                          color: colors.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              )),
              const SizedBox(height: SpacingTokens.lg),
            ],
            
            Text(
              'Go to Settings → Integrations to configure this server for your agents.',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          AsmblButton.secondary(
            text: 'Later',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AsmblButton.primary(
            text: 'Go to Settings',
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to settings - you might need to implement this navigation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigate to Settings → Integrations to configure ${entry.name}'),
                  backgroundColor: colors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}