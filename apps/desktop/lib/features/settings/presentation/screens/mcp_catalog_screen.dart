import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_catalog_service.dart';
import '../../../../core/models/mcp_catalog_entry.dart';
import '../../../../core/models/mcp_server_category.dart';
import '../widgets/mcp_catalog_entry_card.dart';
import '../widgets/mcp_server_setup_dialog.dart';

class MCPCatalogScreen extends ConsumerStatefulWidget {
  const MCPCatalogScreen({super.key});

  @override
  ConsumerState<MCPCatalogScreen> createState() => _MCPCatalogScreenState();
}

class _MCPCatalogScreenState extends ConsumerState<MCPCatalogScreen> {
  String _searchQuery = '';
  MCPServerCategory? _selectedCategory;
  bool _showOnlyFeatured = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final catalogEntries = ref.watch(mcpCatalogEntriesProvider);
    final filteredEntries = _filterEntries(catalogEntries);
    
    return Scaffold(
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
            _buildHeader(context, colors),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(SpacingTokens.pageHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SpacingTokens.lg),
                    _buildSearchAndFilters(colors),
                    SizedBox(height: SpacingTokens.xl),
                    if (_showOnlyFeatured || _searchQuery.isEmpty)
                      _buildFeaturedSection(filteredEntries, colors),
                    if (!_showOnlyFeatured)
                      _buildCategoriesSection(filteredEntries, colors),
                    SizedBox(height: SpacingTokens.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.headerPadding),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
          ),
          SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MCP Tool Catalog',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                ),
                SizedBox(height: SpacingTokens.xs),
                Text(
                  'Browse and add MCP servers to extend your agents\' capabilities',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeColors colors) {
    return Column(
      children: [
        // Search bar
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search MCP servers...',
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
            filled: true,
            fillColor: colors.surface.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          style: TextStyle(color: colors.onSurface),
        ),
        SizedBox(height: SpacingTokens.md),
        
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'Featured',
                _showOnlyFeatured,
                () => setState(() => _showOnlyFeatured = !_showOnlyFeatured),
                colors,
              ),
              SizedBox(width: SpacingTokens.sm),
              ..._buildCategoryChips(colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap, ThemeColors colors) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: colors.surface.withOpacity(0.3),
      selectedColor: colors.primary.withOpacity(0.2),
      checkmarkColor: colors.primary,
      labelStyle: TextStyle(
        color: selected ? colors.primary : colors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? colors.primary : colors.border,
        width: selected ? 2 : 1,
      ),
    );
  }

  List<Widget> _buildCategoryChips(ThemeColors colors) {
    return MCPServerCategory.values.map((category) {
      final isSelected = _selectedCategory == category;
      return Padding(
        padding: EdgeInsets.only(right: SpacingTokens.sm),
        child: FilterChip(
          label: Text(_getCategoryDisplayName(category)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCategory = selected ? category : null;
            });
          },
          backgroundColor: colors.surface.withOpacity(0.3),
          selectedColor: colors.accent.withOpacity(0.2),
          checkmarkColor: colors.accent,
          labelStyle: TextStyle(
            color: isSelected ? colors.accent : colors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? colors.accent : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFeaturedSection(List<MCPCatalogEntry> entries, ThemeColors colors) {
    final featuredEntries = entries.where((entry) => entry.isFeatured).toList();
    
    if (featuredEntries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: colors.accent, size: 20),
            SizedBox(width: SpacingTokens.sm),
            Text(
              'Featured',
              style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.md),
        _buildEntriesGrid(featuredEntries, colors),
        if (!_showOnlyFeatured) SizedBox(height: SpacingTokens.xl),
      ],
    );
  }

  Widget _buildCategoriesSection(List<MCPCatalogEntry> entries, ThemeColors colors) {
    final categorizedEntries = <MCPServerCategory, List<MCPCatalogEntry>>{};
    
    // Group entries by category
    for (final entry in entries) {
      if (!entry.isFeatured || _searchQuery.isNotEmpty) {
        final category = entry.category ?? MCPServerCategory.custom;
        categorizedEntries.putIfAbsent(category, () => []).add(entry);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categorizedEntries.entries.map((categoryEntry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(categoryEntry.key),
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: SpacingTokens.sm),
                Text(
                  _getCategoryDisplayName(categoryEntry.key),
                  style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
                ),
                SizedBox(width: SpacingTokens.sm),
                Text(
                  '(${categoryEntry.value.length})',
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.md),
            _buildEntriesGrid(categoryEntry.value, colors),
            SizedBox(height: SpacingTokens.xl),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEntriesGrid(List<MCPCatalogEntry> entries, ThemeColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fixed 4-column grid regardless of screen size
        int crossAxisCount = 4;
        
        // Debug print to see what's happening
        print('📐 Grid Debug: width=${constraints.maxWidth}, columns=$crossAxisCount (fixed 4-column)');
        
        // Fixed aspect ratio for 4-column compact cards (made smaller for better fit)
        double aspectRatio = 0.6;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: constraints.maxWidth / 4, // Force exactly 4 columns
            crossAxisSpacing: SpacingTokens.md,
            mainAxisSpacing: SpacingTokens.md,
            childAspectRatio: aspectRatio,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            return MCPCatalogEntryCard(
              entry: entries[index],
              onTap: () => _showServerSetupDialog(entries[index]),
            );
          },
        );
      },
    );
  }

  Future<void> _showServerSetupDialog(MCPCatalogEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MCPServerSetupDialog(catalogEntry: entry),
    );

    if (result == true) {
      // Refresh catalog or show success message
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.name} configured successfully!'),
            backgroundColor: ThemeColors(context).primary,
          ),
        );
      }
    }
  }

  List<MCPCatalogEntry> _filterEntries(List<MCPCatalogEntry> entries) {
    var filtered = entries;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((entry) {
        final query = _searchQuery.toLowerCase();
        return entry.name.toLowerCase().contains(query) ||
               entry.description.toLowerCase().contains(query) ||
               entry.capabilities.any((cap) => cap.toLowerCase().contains(query));
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered.where((entry) => entry.category == _selectedCategory).toList();
    }

    // Filter by featured if enabled
    if (_showOnlyFeatured) {
      filtered = filtered.where((entry) => entry.isFeatured).toList();
    }

    return filtered;
  }

  String _getCategoryDisplayName(MCPServerCategory category) {
    return category.displayName;
  }

  IconData _getCategoryIcon(MCPServerCategory category) {
    switch (category) {
      case MCPServerCategory.development:
        return Icons.code;
      case MCPServerCategory.productivity:
        return Icons.trending_up;
      case MCPServerCategory.communication:
        return Icons.chat;
      case MCPServerCategory.dataAnalysis:
        return Icons.analytics;
      case MCPServerCategory.automation:
        return Icons.auto_awesome;
      case MCPServerCategory.fileManagement:
        return Icons.folder;
      case MCPServerCategory.webServices:
        return Icons.language;
      case MCPServerCategory.cloud:
        return Icons.cloud;
      case MCPServerCategory.database:
        return Icons.storage;
      case MCPServerCategory.security:
        return Icons.security;
      case MCPServerCategory.monitoring:
        return Icons.monitor;
      case MCPServerCategory.ai:
        return Icons.psychology;
      case MCPServerCategory.utility:
        return Icons.build;
      case MCPServerCategory.experimental:
        return Icons.science;
      case MCPServerCategory.custom:
        return Icons.extension;
    }
  }
}