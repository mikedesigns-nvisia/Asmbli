import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/anthropic_style_mcp_service.dart';
import '../../../settings/presentation/widgets/enhanced_mcp_server_card.dart';

class CatalogueTab extends ConsumerStatefulWidget {
  const CatalogueTab({super.key});

  @override
  ConsumerState<CatalogueTab> createState() => _CatalogueTabState();
}

class _CatalogueTabState extends ConsumerState<CatalogueTab> {
  String _searchQuery = '';
  MCPCategory? _selectedCategory;
  MCPTrustLevel? _selectedTrustLevel;
  MCPSetupComplexity? _selectedComplexity;
  bool _showOnlyVerified = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final allServers = AnthropicStyleMCPService.essentialServers;
    final filteredServers = _filterServers(allServers);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'MCP Server Catalog',
            style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Production-ready MCP servers based on ecosystem research. Choose tools that match your security and complexity requirements.',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          // Search and Filters
          _buildSearchAndFilters(colors),
          const SizedBox(height: SpacingTokens.lg),
          
          // Results count and sorting
          _buildResultsHeader(filteredServers.length, colors),
          const SizedBox(height: SpacingTokens.md),
          
          // Server Grid
          if (filteredServers.isEmpty) 
            _buildEmptyState(colors)
          else
            Expanded(
              child: _buildServerGrid(filteredServers, colors),
            ),
        ],
      ),
    );
  }


  Widget _buildSearchAndFilters(ThemeColors colors) {
    return Column(
      children: [
        // Search row
        Row(
          children: [
            // Search field
            Expanded(
              flex: 3,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search servers by name, capability, or install command...',
                  hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
                  filled: true,
                  fillColor: colors.surface.withOpacity(0.5),
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
            
            // Trust level filter
            _buildDropdownFilter<MCPTrustLevel>(
              'Trust Level',
              _selectedTrustLevel,
              MCPTrustLevel.values,
              (level) => _getTrustLevelLabel(level),
              (value) => setState(() => _selectedTrustLevel = value),
              colors,
            ),
          ],
        ),
        
        const SizedBox(height: SpacingTokens.md),
        
        // Filter row
        Row(
          children: [
            // Category filter
            _buildDropdownFilter<MCPCategory>(
              'Category',
              _selectedCategory,
              MCPCategory.values,
              (cat) => _getCategoryLabel(cat),
              (value) => setState(() => _selectedCategory = value),
              colors,
            ),
            
            const SizedBox(width: SpacingTokens.md),
            
            // Complexity filter
            _buildDropdownFilter<MCPSetupComplexity>(
              'Setup Complexity',
              _selectedComplexity,
              MCPSetupComplexity.values,
              (comp) => _getComplexityLabel(comp),
              (value) => setState(() => _selectedComplexity = value),
              colors,
            ),
            
            const SizedBox(width: SpacingTokens.md),
            
            // Clear filters button
            AsmblButton.secondary(
              text: 'Clear Filters',
              icon: Icons.clear,
              onPressed: _hasFilters ? () {
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = null;
                  _selectedTrustLevel = null;
                  _selectedComplexity = null;
                  _showOnlyVerified = false;
                });
              } : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownFilter<T>(
    String label,
    T? value,
    List<T> options,
    String Function(T) getLabel,
    void Function(T?) onChanged,
    ThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      ),
      child: DropdownButton<T?>(
        value: value,
        hint: Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
        dropdownColor: colors.surface,
        style: TextStyle(color: colors.onSurface),
        underline: const SizedBox(),
        items: [
          DropdownMenuItem<T?>(
            value: null,
            child: Text('All ${label}s', style: TextStyle(color: colors.onSurface)),
          ),
          ...options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(getLabel(option), style: TextStyle(color: colors.onSurface)),
          )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildResultsHeader(int count, ThemeColors colors) {
    return Row(
      children: [
        Text(
          '$count server${count != 1 ? 's' : ''} found',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_hasFilters) ...[
          SizedBox(width: SpacingTokens.md),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SpacingTokens.sm,
              vertical: SpacingTokens.xs,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Text(
              'Filtered',
              style: TextStyles.caption.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServerGrid(List<CuratedMCPServer> servers, ThemeColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid: 3-4 columns based on width
        final columnCount = constraints.maxWidth > 1200 ? 4 : 3;
        final spacing = SpacingTokens.lg;
        final totalSpacing = spacing * (columnCount - 1);
        final columnWidth = (constraints.maxWidth - totalSpacing) / columnCount;
        
        return SingleChildScrollView(
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: servers.map((server) {
              return SizedBox(
                width: columnWidth,
                child: EnhancedMCPServerCard(
                  server: server,
                  onInstall: () => _showInstallDialog(server),
                  onLearnMore: () => _showServerDetails(server),
                ),
              );
            }).toList(),
          ),
        );
      },
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
                color: colors.primary.withOpacity(0.1),
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
              'No servers match your filters',
              style: TextStyles.bodyLarge.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              'Try adjusting your search terms or filters',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  bool get _hasFilters => 
      _searchQuery.isNotEmpty ||
      _selectedCategory != null ||
      _selectedTrustLevel != null ||
      _selectedComplexity != null ||
      _showOnlyVerified;

  List<CuratedMCPServer> _filterServers(List<CuratedMCPServer> servers) {
    return servers.where((server) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = 
            server.name.toLowerCase().contains(query) ||
            server.description.toLowerCase().contains(query) ||
            server.valueProposition.toLowerCase().contains(query) ||
            server.installCommand.toLowerCase().contains(query) ||
            server.capabilities.any((cap) => cap.toLowerCase().contains(query));
        if (!matchesSearch) return false;
      }

      // Category filter
      if (_selectedCategory != null && server.category != _selectedCategory) {
        return false;
      }

      // Trust level filter
      if (_selectedTrustLevel != null && server.trustLevel != _selectedTrustLevel) {
        return false;
      }

      // Complexity filter
      if (_selectedComplexity != null && server.setupComplexity != _selectedComplexity) {
        return false;
      }

      return true;
    }).toList();
  }

  String _getTrustLevelLabel(MCPTrustLevel level) {
    switch (level) {
      case MCPTrustLevel.anthropicOfficial:
        return 'Anthropic Official';
      case MCPTrustLevel.enterpriseVerified:
        return 'Enterprise Verified';
      case MCPTrustLevel.communityVerified:
        return 'Community Verified';
      case MCPTrustLevel.experimental:
        return 'Experimental';
      case MCPTrustLevel.unknown:
        return 'Unknown';
    }
  }

  String _getCategoryLabel(MCPCategory category) {
    switch (category) {
      case MCPCategory.development:
        return 'Development';
      case MCPCategory.productivity:
        return 'Productivity';
      case MCPCategory.information:
        return 'Information';
      case MCPCategory.communication:
        return 'Communication';
      case MCPCategory.reasoning:
        return 'AI Reasoning';
      case MCPCategory.utility:
        return 'System Utility';
      case MCPCategory.creative:
        return 'Creative';
    }
  }

  String _getComplexityLabel(MCPSetupComplexity complexity) {
    switch (complexity) {
      case MCPSetupComplexity.oneClick:
        return 'One Command';
      case MCPSetupComplexity.oauth:
        return 'OAuth Setup';
      case MCPSetupComplexity.minimal:
        return 'API Key Required';
      case MCPSetupComplexity.guided:
        return 'Guided Setup';
      case MCPSetupComplexity.advanced:
        return 'Advanced Config';
    }
  }

  void _showInstallDialog(CuratedMCPServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Install ${server.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(server.valueProposition),
            SizedBox(height: SpacingTokens.md),
            Text(
              'Installation Command:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: SpacingTokens.xs),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Text(
                server.installCommand,
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
            SizedBox(height: SpacingTokens.md),
            Text(
              'Permissions Required:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...server.dataAccess.map((access) => Text('• $access')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual installation
            },
            child: Text('Install'),
          ),
        ],
      ),
    );
  }

  void _showServerDetails(CuratedMCPServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(server.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(server.description),
              SizedBox(height: SpacingTokens.md),
              Text('Value Proposition:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(server.valueProposition),
              SizedBox(height: SpacingTokens.md),
              Text('Capabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...server.capabilities.map((cap) => Text('• $cap')),
              SizedBox(height: SpacingTokens.md),
              Text('Data Access:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...server.dataAccess.map((data) => Text('• $data')),
              if (server.documentationUrl != null) ...[
                SizedBox(height: SpacingTokens.md),
                Text('Documentation: ${server.documentationUrl}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}