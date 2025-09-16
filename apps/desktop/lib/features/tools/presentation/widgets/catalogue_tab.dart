import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_catalog_service.dart';
import '../../../../core/models/mcp_catalog_entry.dart';
import '../../../../core/models/mcp_server_category.dart';
import '../providers/tools_provider.dart';
import '../../../settings/presentation/widgets/enhanced_mcp_server_card.dart';

class CatalogueTab extends ConsumerStatefulWidget {
  const CatalogueTab({super.key});

  @override
  ConsumerState<CatalogueTab> createState() => _CatalogueTabState();
}

class _CatalogueTabState extends ConsumerState<CatalogueTab> {
  String _searchQuery = '';
  MCPServerCategory? _selectedCategory;
  String? _selectedTrustLevel; // Changed to String to handle different trust models
  bool _showOnlyVerified = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final catalogEntries = ref.watch(mcpCatalogEntriesProvider);
    final filteredServers = _filterServers(catalogEntries);

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
            _buildDropdownFilter<String>(
              'Trust Level',
              _selectedTrustLevel,
              ['Official', 'Community'],
              (level) => level,
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
            _buildDropdownFilter<MCPServerCategory>(
              'Category',
              _selectedCategory,
              MCPServerCategory.values,
              (cat) => _getCategoryLabel(cat),
              (value) => setState(() => _selectedCategory = value),
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

  Widget _buildServerGrid(List<MCPCatalogEntry> servers, ThemeColors colors) {
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
                child: _buildCatalogEntryCard(server, colors),
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
      _showOnlyVerified;

  List<MCPCatalogEntry> _filterServers(List<MCPCatalogEntry> servers) {
    return servers.where((server) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = 
            server.name.toLowerCase().contains(query) ||
            server.description.toLowerCase().contains(query) ||
            server.capabilities.any((cap) => cap.toLowerCase().contains(query));
        if (!matchesSearch) return false;
      }

      // Category filter
      if (_selectedCategory != null && server.category != _selectedCategory) {
        return false;
      }

      // Trust level filter
      if (_selectedTrustLevel != null) {
        final isOfficial = server.isOfficial;
        if (_selectedTrustLevel == 'Official' && !isOfficial) {
          return false;
        } else if (_selectedTrustLevel == 'Community' && isOfficial) {
          return false;
        }
      }

      return true;
    }).toList();
  }


  String _getCategoryLabel(MCPServerCategory category) {
    return category.displayName;
  }

  Widget _buildCatalogEntryCard(MCPCatalogEntry server, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and status
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: server.isOfficial ? colors.primary.withOpacity(0.1) : colors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Icon(
                    _getCategoryIcon(server.category ?? MCPServerCategory.custom),
                    color: server.isOfficial ? colors.primary : colors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: TextStyles.titleMedium.copyWith(color: colors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        server.isOfficial ? 'Official' : 'Community',
                        style: TextStyles.caption.copyWith(
                          color: server.isOfficial ? colors.primary : colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: SpacingTokens.md),
            
            // Description
            Text(
              server.description,
              style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: SpacingTokens.md),
            
            // Requirements section
            _buildRequirementsSection(server, colors),
            
            // Capabilities
            if (server.capabilities.isNotEmpty) ...[
              Wrap(
                spacing: SpacingTokens.xs,
                runSpacing: SpacingTokens.xs,
                children: server.capabilities.take(3).map((capability) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: SpacingTokens.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      border: Border.all(color: colors.border.withOpacity(0.5)),
                    ),
                    child: Text(
                      capability,
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: SpacingTokens.md),
            ],
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: AsmblButton.secondary(
                    text: 'Install',
                    icon: Icons.download,
                    onPressed: () => _showInstallDialog(server),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                IconButton(
                  onPressed: () => _showServerDetails(server),
                  icon: Icon(Icons.info_outline, color: colors.onSurfaceVariant),
                  tooltip: 'Learn More',
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Widget _buildRequirementsSection(MCPCatalogEntry server, ThemeColors colors) {
    final requirements = <Widget>[];
    
    // Check for account requirements
    final accountRequirements = _getAccountRequirements(server);
    if (accountRequirements.isNotEmpty) {
      requirements.add(_buildAccountRequirementGroup(
        'Account Required',
        accountRequirements,
        Icons.account_circle,
        colors.primary,
        colors,
      ));
    }
    
    // Check for software dependencies
    final softwareDeps = _getSoftwareDependencies(server);
    if (softwareDeps.isNotEmpty) {
      requirements.add(_buildSoftwareRequirementGroup(
        'Software Required',
        softwareDeps,
        Icons.computer,
        colors.accent,
        colors,
      ));
    }
    
    // Check for API key requirements
    if (server.hasAuth) {
      final apiKeyReqs = server.requiredAuth.map((auth) => auth['displayName'] as String? ?? auth['name'] as String? ?? 'API Key').toList();
      requirements.add(_buildRequirementGroup(
        'API Key Required',
        apiKeyReqs,
        Icons.key,
        const Color(0xFFF59E0B), // Amber for auth requirements
        colors,
      ));
    }
    
    if (requirements.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...requirements.map((req) => Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
          child: req,
        )),
        const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }
  
  Widget _buildRequirementGroup(
    String title,
    List<String> items,
    IconData icon,
    Color iconColor,
    ThemeColors colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                ...items.map((item) => Text(
                  '• $item',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<({String name, String? signupUrl})> _getAccountRequirements(MCPCatalogEntry server) {
    final accounts = <({String name, String? signupUrl})>[];
    
    switch (server.id) {
      case 'github':
        accounts.add((name: 'GitHub Account', signupUrl: 'https://github.com/join'));
        break;
      case 'linear':
        accounts.add((name: 'Linear Account', signupUrl: 'https://linear.app/signup'));
        break;
      case 'slack':
        accounts.add((name: 'Slack Workspace Access', signupUrl: 'https://slack.com/get-started#/createnew'));
        break;
      case 'notion':
        accounts.add((name: 'Notion Account', signupUrl: 'https://www.notion.so/signup'));
        break;
      case 'figma':
        accounts.add((name: 'Figma Account', signupUrl: 'https://www.figma.com/signup'));
        break;
      case 'brave-search':
        accounts.add((name: 'Brave Search API Account', signupUrl: 'https://api.search.brave.com/'));
        break;
      case 'aws':
        accounts.add((name: 'AWS Account with IAM Permissions', signupUrl: 'https://portal.aws.amazon.com/billing/signup'));
        break;
    }
    
    return accounts;
  }

  Widget _buildAccountRequirementGroup(
    String title,
    List<({String name, String? signupUrl})> accountItems,
    IconData icon,
    Color iconColor,
    ThemeColors colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                ...accountItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '• ${item.name}',
                          style: TextStyles.caption.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (item.signupUrl != null) ...[
                        const SizedBox(width: SpacingTokens.xs),
                        GestureDetector(
                          onTap: () => _launchSignupUrl(item.signupUrl!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingTokens.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: iconColor.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 10,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 10,
                                  color: iconColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchSignupUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open signup link: $url'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening signup link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  List<({String name, String? downloadUrl})> _getSoftwareDependencies(MCPCatalogEntry server) {
    final software = <({String name, String? downloadUrl})>[];
    
    switch (server.id) {
      case 'git':
        software.add((name: 'Git (installed locally)', downloadUrl: 'https://git-scm.com/downloads'));
        break;
      case 'postgres':
        software.add((name: 'PostgreSQL Database', downloadUrl: 'https://www.postgresql.org/download/'));
        break;
      case 'sqlite':
        software.add((name: 'SQLite Database File', downloadUrl: 'https://www.sqlite.org/download.html'));
        break;
      case 'filesystem':
        software.add((name: 'Local File System Access', downloadUrl: null)); // No download needed
        break;
    }
    
    // Check for uvx/npx requirements
    if (server.command?.contains('uvx') == true) {
      software.add((name: 'Python with uv package manager', downloadUrl: 'https://docs.astral.sh/uv/getting-started/installation/'));
    } else if (server.command?.contains('npx') == true) {
      software.add((name: 'Node.js with npm', downloadUrl: 'https://nodejs.org/en/download/'));
    }
    
    return software;
  }

  Widget _buildSoftwareRequirementGroup(
    String title,
    List<({String name, String? downloadUrl})> softwareItems,
    IconData icon,
    Color iconColor,
    ThemeColors colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                ...softwareItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '• ${item.name}',
                          style: TextStyles.caption.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (item.downloadUrl != null) ...[
                        const SizedBox(width: SpacingTokens.xs),
                        GestureDetector(
                          onTap: () => _launchDownloadUrl(item.downloadUrl!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingTokens.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: colors.primary.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.download,
                                  size: 10,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 10,
                                  color: colors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchDownloadUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open download link: $url'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening download link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInstallDialog(MCPCatalogEntry server) {
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

  void _showServerDetails(MCPCatalogEntry server) {
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
              Text('Capabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...server.capabilities.map((cap) => Text('• $cap')),
              const SizedBox(height: SpacingTokens.md),
              Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(server.category != null ? _getCategoryLabel(server.category!) : 'Uncategorized'),
              const SizedBox(height: SpacingTokens.md),
              Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(server.isOfficial ? 'Official' : 'Community'),
              if (server.hasAuth) ...[
                const SizedBox(height: SpacingTokens.md),
                Text('Authentication Required:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...server.requiredAuth.map((auth) => Text('• ${auth['displayName'] as String? ?? auth['name'] as String? ?? 'API Key'}')),
              ],
              if (server.documentationUrl != null) ...[
                const SizedBox(height: SpacingTokens.md),
                Text('Documentation: ${server.documentationUrl}'),
              ],
              if (server.command != null) ...[
                const SizedBox(height: SpacingTokens.md),
                Text('Install Command:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(server.command!, style: TextStyle(fontFamily: 'monospace')),
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
  final MCPCatalogEntry server;
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
                widget.server.description,
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
                  widget.server.command ?? 'Installation command not available',
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
              if (widget.server.hasAuth) 
                ...widget.server.requiredAuth.map((auth) => Text(
                  '• ${auth['displayName'] as String? ?? auth['name'] as String? ?? 'API Key'}: ${auth['description'] as String? ?? 'Required for authentication'}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ))
              else
                Text(
                  '• No special permissions required',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
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