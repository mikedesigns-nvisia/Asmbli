import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_catalog_service.dart';
import '../../../../core/services/github_mcp_registry_service.dart';
import '../../../../core/models/mcp_catalog_entry.dart';
import '../../../../core/models/mcp_server_category.dart';
import '../../../../core/models/github_mcp_registry_models.dart';
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
  bool _showTrending = false;
  bool _showPopular = false;
  InstallationDifficulty? _selectedDifficulty;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final catalogEntriesAsync = ref.watch(mcpCatalogEntriesProvider);
    
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
              child: catalogEntriesAsync.when(
                data: (catalogEntries) {
                  final filteredEntries = _filterEntries(catalogEntries);
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(SpacingTokens.pageHorizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: SpacingTokens.lg),
                        _buildSearchAndFilters(colors),
                        SizedBox(height: SpacingTokens.xl),
                        if (_showTrending)
                          _buildTrendingSection(colors),
                        if (_showPopular)
                          _buildPopularSection(colors),
                        if (_showOnlyFeatured)
                          _buildFeaturedSection(filteredEntries, colors),
                        if (!_showOnlyFeatured && !_showTrending && !_showPopular && _searchQuery.isEmpty)
                          _buildAllSections(colors),
                        if (_searchQuery.isNotEmpty || _selectedCategory != null || _selectedDifficulty != null)
                          _buildFilteredSection(filteredEntries, colors),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Failed to load catalog: $error'),
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
                  'MCP Registry',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                ),
                SizedBox(height: SpacingTokens.xs),
                Text(
                  'Discover and install Model Context Protocol servers',
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
                () => setState(() {
                  _showOnlyFeatured = !_showOnlyFeatured;
                  if (_showOnlyFeatured) {
                    _showTrending = false;
                    _showPopular = false;
                  }
                }),
                colors,
              ),
              SizedBox(width: SpacingTokens.sm),
              _buildFilterChip(
                '🆕 Latest',
                _showTrending,
                () => setState(() {
                  _showTrending = !_showTrending;
                  if (_showTrending) {
                    _showOnlyFeatured = false;
                    _showPopular = false;
                  }
                }),
                colors,
              ),
              SizedBox(width: SpacingTokens.sm),
              _buildFilterChip(
                '📊 Most Used',
                _showPopular,
                () => setState(() {
                  _showPopular = !_showPopular;
                  if (_showPopular) {
                    _showOnlyFeatured = false;
                    _showTrending = false;
                  }
                }),
                colors,
              ),
              SizedBox(width: SpacingTokens.sm),
              ..._buildDifficultyChips(colors),
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

  List<Widget> _buildDifficultyChips(ThemeColors colors) {
    return InstallationDifficulty.values.map((difficulty) {
      final isSelected = _selectedDifficulty == difficulty;
      final difficultyName = _getDifficultyDisplayName(difficulty);
      final difficultyIcon = _getDifficultyIcon(difficulty);

      return Padding(
        padding: EdgeInsets.only(right: SpacingTokens.sm),
        child: FilterChip(
          avatar: Icon(difficultyIcon, size: 16),
          label: Text(difficultyName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedDifficulty = selected ? difficulty : null;
            });
          },
          backgroundColor: colors.surface.withOpacity(0.3),
          selectedColor: colors.primary.withOpacity(0.2),
          checkmarkColor: colors.primary,
          labelStyle: TextStyle(
            color: isSelected ? colors.primary : colors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
      );
    }).toList();
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

  Widget _buildTrendingSection(ThemeColors colors) {
    return Consumer(
      builder: (context, ref, child) {
        final trendingAsync = ref.watch(trendingServersProvider);

        return trendingAsync.when(
          data: (githubEntries) {
            if (githubEntries.isEmpty) return const SizedBox.shrink();

            // Convert to catalog entries for display
            final trendingEntries = githubEntries.map((githubEntry) =>
              ref.read(mcpCatalogServiceProvider).convertGitHubToCatalogEntry(githubEntry)
            ).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: colors.accent, size: 20),
                    SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Newly Released & Updated',
                      style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
                    ),
                    SizedBox(width: SpacingTokens.sm),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Latest Updates',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SpacingTokens.md),
                _buildEntriesGrid(trendingEntries, colors),
                SizedBox(height: SpacingTokens.xl),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildPopularSection(ThemeColors colors) {
    return Consumer(
      builder: (context, ref, child) {
        final popularAsync = ref.watch(popularServersProvider);

        return popularAsync.when(
          data: (githubEntries) {
            if (githubEntries.isEmpty) return const SizedBox.shrink();

            // Convert to catalog entries for display
            final popularEntries = githubEntries.map((githubEntry) =>
              ref.read(mcpCatalogServiceProvider).convertGitHubToCatalogEntry(githubEntry)
            ).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: colors.accent, size: 20),
                    SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Most Downloaded',
                      style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
                    ),
                    SizedBox(width: SpacingTokens.sm),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Proven & Reliable',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SpacingTokens.md),
                _buildEntriesGrid(popularEntries, colors),
                SizedBox(height: SpacingTokens.xl),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildAllSections(ThemeColors colors) {
    return Column(
      children: [
        _buildTrendingSection(colors),
        _buildPopularSection(colors),
        Consumer(
          builder: (context, ref, child) {
            final catalogEntriesAsync = ref.watch(mcpCatalogEntriesProvider);
            return catalogEntriesAsync.when(
              data: (entries) {
                final featuredEntries = entries.where((entry) => entry.isFeatured).toList();
                return Column(
                  children: [
                    _buildFeaturedSection(featuredEntries, colors),
                    _buildCategoriesSection(entries, colors),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilteredSection(List<MCPCatalogEntry> filteredEntries, ThemeColors colors) {
    if (filteredEntries.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: SpacingTokens.xxl),
            Icon(Icons.search_off, size: 64, color: colors.onSurfaceVariant),
            SizedBox(height: SpacingTokens.md),
            Text(
              'No servers found',
              style: TextStyles.headingMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            SizedBox(height: SpacingTokens.sm),
            Text(
              'Try adjusting your search or filter criteria',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.filter_list, color: colors.onSurfaceVariant, size: 20),
            SizedBox(width: SpacingTokens.sm),
            Text(
              'Filtered Results',
              style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
            ),
            SizedBox(width: SpacingTokens.sm),
            Text(
              '(${filteredEntries.length})',
              style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.md),
        _buildEntriesGrid(filteredEntries, colors),
      ],
    );
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
    // GitHub-style single column list layout
    return Column(
      children: entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: SpacingTokens.md),
          child: MCPCatalogEntryCard(
            entry: entry,
            onTap: () => _showServerSetupDialog(entry),
          ),
        );
      }).toList(),
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

    // Filter by installation difficulty
    if (_selectedDifficulty != null) {
      filtered = filtered.where((entry) {
        final difficulty = _getDifficultyForEntry(entry);
        return difficulty == _selectedDifficulty;
      }).toList();
    }

    // Sort by quality score if no specific filters are applied
    if (_searchQuery.isEmpty && _selectedCategory == null && !_showOnlyFeatured && _selectedDifficulty == null) {
      filtered.sort((a, b) {
        // Simple quality scoring based on available data
        int scoreA = _calculateEntryScore(a);
        int scoreB = _calculateEntryScore(b);
        return scoreB.compareTo(scoreA);
      });
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

  String _getDifficultyDisplayName(InstallationDifficulty difficulty) {
    switch (difficulty) {
      case InstallationDifficulty.beginner:
        return 'Easy';
      case InstallationDifficulty.intermediate:
        return 'Medium';
      case InstallationDifficulty.advanced:
        return 'Advanced';
    }
  }

  IconData _getDifficultyIcon(InstallationDifficulty difficulty) {
    switch (difficulty) {
      case InstallationDifficulty.beginner:
        return Icons.sentiment_very_satisfied;
      case InstallationDifficulty.intermediate:
        return Icons.sentiment_neutral;
      case InstallationDifficulty.advanced:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  InstallationDifficulty _getDifficultyForEntry(MCPCatalogEntry entry) {
    final command = entry.command.toLowerCase();
    final hasEnvVars = entry.requiredEnvVars.isNotEmpty;
    final hasComplexSetup = entry.setupInstructions?.isNotEmpty == true;

    // Easy: Simple command, no env vars needed
    if ((command.contains('npx') || command.contains('uvx')) && !hasEnvVars && !hasComplexSetup) {
      return InstallationDifficulty.beginner;
    }

    // Hard: Requires compilation, complex setup, or many dependencies
    if (command.contains('git') ||
        command.contains('build') ||
        command.contains('compile') ||
        hasComplexSetup ||
        entry.requiredEnvVars.length > 3) {
      return InstallationDifficulty.advanced;
    }

    // Medium: Everything else (Docker, some env vars, etc.)
    return InstallationDifficulty.intermediate;
  }

  int _calculateEntryScore(MCPCatalogEntry entry) {
    int score = 0;

    // Base score
    score += 10;

    // Bonus for having version info
    if (entry.version?.isNotEmpty == true) score += 5;

    // Bonus for having documentation
    if (entry.documentationUrl?.isNotEmpty == true) score += 10;
    if (entry.setupInstructions?.isNotEmpty == true) score += 8;

    // Bonus for capabilities
    score += entry.capabilities.length * 3;

    // Bonus for being official or featured
    if (entry.isOfficial) score += 20;
    if (entry.isFeatured) score += 15;

    // Bonus for recent updates
    if (entry.lastUpdated != null) {
      final daysSinceUpdate = DateTime.now().difference(entry.lastUpdated!).inDays;
      if (daysSinceUpdate < 30) score += 15;
      else if (daysSinceUpdate < 90) score += 10;
      else if (daysSinceUpdate < 180) score += 5;
    }

    // Installation difficulty penalty/bonus
    final difficulty = _getDifficultyForEntry(entry);
    switch (difficulty) {
      case InstallationDifficulty.beginner:
        score += 10; // Easy to install
        break;
      case InstallationDifficulty.intermediate:
        score += 5; // Moderate complexity
        break;
      case InstallationDifficulty.advanced:
        score -= 5; // Complex setup might deter users
        break;
    }

    return score;
  }
}