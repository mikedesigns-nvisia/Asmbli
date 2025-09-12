import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/anthropic_style_mcp_service.dart';
import '../providers/tools_provider.dart';
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
            '🛠️ Give Your Assistant New Skills',
            style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Browse tools that help your assistant be more useful. Each skill connects your AI to new capabilities.',
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
                  hintText: 'Search for skills like "file helper", "web research", etc...',
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
          const SizedBox(width: SpacingTokens.md),
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
    if (!mounted) return;
    
    final toolsNotifier = ref.read(toolsProvider.notifier);
    
    showDialog(
      context: context,
      builder: (context) => _InstallServerDialog(
        server: server,
        onInstall: () => toolsNotifier.installServer(server.id),
      ),
    );
  }

  void _showServerDetails(CuratedMCPServer server) {
    if (!mounted) return;
    
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
              const SizedBox(height: SpacingTokens.md),
              Text('Value Proposition:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(server.valueProposition),
              const SizedBox(height: SpacingTokens.md),
              Text('Capabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...server.capabilities.map((cap) => Text('• $cap')),
              const SizedBox(height: SpacingTokens.md),
              Text('Data Access:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...server.dataAccess.map((data) => Text('• $data')),
              if (server.documentationUrl != null) ...[
                const SizedBox(height: SpacingTokens.md),
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

/// Dialog for installing MCP servers with proper tools provider integration
class _InstallServerDialog extends ConsumerStatefulWidget {
  final CuratedMCPServer server;
  final Future<void> Function() onInstall;

  const _InstallServerDialog({
    required this.server,
    required this.onInstall,
  });

  @override
  ConsumerState<_InstallServerDialog> createState() => _InstallServerDialogState();
}

class _InstallServerDialogState extends ConsumerState<_InstallServerDialog> {
  bool _isInstalling = false;
  String? _installationError;
  bool _installationComplete = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        _installationComplete
            ? '✅ ${widget.server.name} Installed'
            : 'Install ${widget.server.name}',
        style: TextStyle(color: colors.onSurface),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_installationComplete) ...[
              Text(
                widget.server.valueProposition,
                style: TextStyle(color: colors.onSurface),
              ),
              const SizedBox(height: SpacingTokens.md),
              Text(
                'Installation Command:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: colors.background.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  widget.server.installCommand,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: SpacingTokens.md),
              Text(
                'Permissions Required:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              ...widget.server.dataAccess.map((access) => Text(
                '• $access',
                style: TextStyle(color: colors.onSurfaceVariant),
              )),
            ] else ...[
              Container(
                padding: EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  border: Border.all(color: colors.success.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: colors.success,
                      size: 48,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Text(
                      'Installation successful!',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      'The ${widget.server.name} server is now available for use.',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            
            if (_installationError != null) ...[
              const SizedBox(height: SpacingTokens.md),
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: colors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(color: colors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: colors.error, size: 16),
                        const SizedBox(width: SpacingTokens.xs),
                        Text(
                          'Installation Failed',
                          style: TextStyle(
                            color: colors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      _installationError!,
                      style: TextStyle(color: colors.onSurface, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            
            if (_isInstalling) ...[
              const SizedBox(height: SpacingTokens.md),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(colors.primary),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    'Installing...',
                    style: TextStyle(color: colors.primary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_installationComplete && !_isInstalling) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          AsmblButton.primary(
            text: 'Install',
            onPressed: _installServer,
          ),
        ] else if (_installationError != null) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          AsmblButton.primary(
            text: 'Retry',
            onPressed: () {
              setState(() {
                _installationError = null;
              });
              _installServer();
            },
          ),
        ] else ...[
          AsmblButton.primary(
            text: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ],
    );
  }

  Future<void> _installServer() async {
    setState(() {
      _isInstalling = true;
      _installationError = null;
    });

    try {
      // Use the proper tools provider installation method
      await widget.onInstall();
      
      setState(() {
        _isInstalling = false;
        _installationComplete = true;
      });
    } catch (e) {
      setState(() {
        _isInstalling = false;
        _installationError = 'Installation failed: $e';
      });
    }
  }
}