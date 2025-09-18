import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_catalog_service.dart';
import '../../../../core/services/github_mcp_registry_service.dart';
import '../../../../core/models/mcp_catalog_entry.dart';
import '../../../../core/models/mcp_server_category.dart';
import '../../../../core/models/github_mcp_registry_models.dart';
import '../providers/tools_provider.dart';
import '../../../settings/presentation/widgets/enhanced_mcp_server_card.dart';
import 'agent_mcp_install_dialog.dart';

/// GitHub MCP Registry tab that displays servers from the official registry
class CatalogueTab extends ConsumerStatefulWidget {
  const CatalogueTab({super.key});

  @override
  ConsumerState<CatalogueTab> createState() => _CatalogueTabState();
}

class _CatalogueTabState extends ConsumerState<CatalogueTab> {
  String _searchQuery = '';
  String _searchInput = ''; // For debounced search
  MCPServerCategory? _selectedCategory;
  String? _selectedTrustLevel; // Changed to String to handle different trust models
  bool _showOnlyVerified = false;
  bool _showTrending = false;
  bool _showPopular = false;
  InstallationDifficulty? _selectedDifficulty;

  // Search debouncing
  Timer? _searchDebounceTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _handleSearchInput(String value) {
    setState(() {
      _searchInput = value;
    });

    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Start new debounce timer
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchInput;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    // Use enhanced providers based on filter state
    late AsyncValue<List<MCPCatalogEntry>> registryEntriesAsync;

    if (_showTrending) {
      // Get trending servers and convert to registry entries
      final trendingAsync = ref.watch(trendingServersProvider);
      registryEntriesAsync = trendingAsync.when(
        data: (githubEntries) => AsyncValue.data(
          githubEntries.map((entry) =>
            ref.read(mcpCatalogServiceProvider).convertGitHubToCatalogEntry(entry)
          ).toList()
        ),
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    } else if (_showPopular) {
      // Get popular servers and convert to registry entries
      final popularAsync = ref.watch(popularServersProvider);
      registryEntriesAsync = popularAsync.when(
        data: (githubEntries) => AsyncValue.data(
          githubEntries.map((entry) =>
            ref.read(mcpCatalogServiceProvider).convertGitHubToCatalogEntry(entry)
          ).toList()
        ),
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    } else {
      // Use regular registry entries
      registryEntriesAsync = ref.watch(mcpCatalogEntriesProvider);
    }

    return registryEntriesAsync.when(
      data: (registryEntries) {
        final filteredServers = _filterServers(registryEntries);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildContent(context, colors, filteredServers),
        );
      },
      loading: () => _buildLoadingSkeletons(colors),
      error: (error, stack) => _buildErrorState(colors, error.toString()),
    );
  }

  Widget _buildContent(BuildContext context, ThemeColors colors, List<MCPCatalogEntry> filteredServers) {

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '🔗 Browse GitHub MCP Registry',
            style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Discover and install MCP servers from the official GitHub registry. Connect your agents to powerful tools and capabilities.',
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
              flex: 2,
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
                onChanged: _handleSearchInput,
              ),
            ),

            const SizedBox(width: SpacingTokens.md),

            // Category filter dropdown
            _buildDropdownFilter<MCPServerCategory>(
              'Category',
              _selectedCategory,
              MCPServerCategory.values,
              (category) => category.displayName,
              (value) => setState(() => _selectedCategory = value),
              colors,
              tooltip: 'Filter servers by their primary function: Development tools, Productivity apps, Communication services, etc.',
            ),

            const SizedBox(width: SpacingTokens.md),

            // Difficulty filter dropdown
            _buildDropdownFilter<InstallationDifficulty>(
              'Difficulty',
              _selectedDifficulty,
              InstallationDifficulty.values,
              (difficulty) => _getDifficultyDisplayName(difficulty),
              (value) => setState(() => _selectedDifficulty = value),
              colors,
              tooltip: 'Filter by installation complexity: Beginner (simple commands), Intermediate (some setup), Advanced (complex configuration)',
            ),

            const SizedBox(width: SpacingTokens.md),

            // Trust level filter
            _buildDropdownFilter<String>(
              'Trust Level',
              _selectedTrustLevel,
              ['Official', 'Verified Community', 'Community', 'Unverified'],
              (level) => level,
              (value) => setState(() => _selectedTrustLevel = value),
              colors,
              tooltip: 'Filter by trust level: Official (from MCP team/companies), Verified Community (established developers), Community (trusted contributors)',
            ),
          ],
        ),
        
        const SizedBox(height: SpacingTokens.md),
        
        // Enhanced Filter Chips Row (only for quick filters)
        Row(
          children: [
            _buildFilterChip(
              '🆕 Latest',
              _showTrending,
              () => setState(() {
                _showTrending = !_showTrending;
                if (_showTrending) {
                  _showPopular = false;
                  _showOnlyVerified = false;
                }
              }),
              colors,
              tooltip: 'Show the most recently added or updated MCP servers',
            ),
            const SizedBox(width: SpacingTokens.sm),
            _buildFilterChip(
              '📊 Most Used',
              _showPopular,
              () => setState(() {
                _showPopular = !_showPopular;
                if (_showPopular) {
                  _showTrending = false;
                  _showOnlyVerified = false;
                }
              }),
              colors,
              tooltip: 'Show the most popular MCP servers based on GitHub stars and community usage',
            ),
            const SizedBox(width: SpacingTokens.sm),
            _buildFilterChip(
              '✅ Verified',
              _showOnlyVerified,
              () => setState(() {
                _showOnlyVerified = !_showOnlyVerified;
                if (_showOnlyVerified) {
                  _showTrending = false;
                  _showPopular = false;
                }
              }),
              colors,
              tooltip: 'Show only verified servers from official sources and trusted developers',
            ),
          ],
        ),

        const SizedBox(height: SpacingTokens.md),

        // Filter row
        Row(
          children: [
            // Clear filters button
            AsmblButton.secondary(
              text: 'Clear Filters',
              icon: Icons.clear,
              onPressed: _hasFilters ? () {
                _searchDebounceTimer?.cancel();
                setState(() {
                  _searchQuery = '';
                  _searchInput = '';
                  _selectedCategory = null;
                  _selectedTrustLevel = null;
                  _showTrending = false;
                  _showPopular = false;
                  _showOnlyVerified = false;
                  _selectedDifficulty = null;
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
    ThemeColors colors, {
    String? tooltip,
  }) {
    final dropdown = Container(
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

    return tooltip != null
        ? Tooltip(
            message: tooltip,
            child: dropdown,
          )
        : dropdown;
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
    // Enhanced virtualization with estimated item extent and slivers
    return CustomScrollView(
      slivers: [
        SliverList.builder(
          itemCount: servers.length,
          itemBuilder: (context, index) {
            final server = servers[index];
            return Padding(
              padding: EdgeInsets.only(bottom: SpacingTokens.md),
              child: _buildGitHubStyleRegistryCard(server, colors),
            );
          },
        ),
      ],
      // Advanced performance optimizations for large lists
      cacheExtent: 2000, // Increased cache for smoother scrolling
      semanticChildCount: servers.length,
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

  /// Loading skeletons with shimmer effect for better user experience
  Widget _buildLoadingSkeletons(ThemeColors colors) {
    return Column(
      children: [
        _buildSearchAndFilters(colors),
        const SizedBox(height: SpacingTokens.lg),
        Expanded(
          child: ListView.builder(
            itemCount: 6, // Show 6 skeleton cards
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: SpacingTokens.md),
              child: _buildSkeletonCard(colors),
            ),
          ),
        ),
      ],
    );
  }

  /// Individual skeleton card that mimics the server card layout
  Widget _buildSkeletonCard(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar skeleton
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title skeleton
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      // Subtitle skeleton
                      Container(
                        height: 14,
                        width: 200,
                        decoration: BoxDecoration(
                          color: colors.onSurface.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                        ),
                      ),
                    ],
                  ),
                ),
                // Install button skeleton
                Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            // Description skeleton
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Container(
              height: 12,
              width: 250,
              decoration: BoxDecoration(
                color: colors.onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            // Tags skeleton
            Row(
              children: [
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                  ),
                ),
                const SizedBox(width: SpacingTokens.xs),
                Container(
                  width: 50,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                  ),
                ),
                const SizedBox(width: SpacingTokens.xs),
                Container(
                  width: 40,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced error state with retry functionality
  Widget _buildErrorState(ThemeColors colors, String error) {
    return Column(
      children: [
        _buildSearchAndFilters(colors),
        const SizedBox(height: SpacingTokens.lg),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  ),
                  child: Icon(
                    Icons.cloud_off,
                    size: 40,
                    color: colors.error,
                  ),
                ),
                const SizedBox(height: SpacingTokens.lg),
                Text(
                  'Failed to load servers',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'Check your internet connection and try again',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: SpacingTokens.lg),
                AsmblButton.secondary(
                  text: 'Retry',
                  icon: Icons.refresh,
                  onPressed: () {
                    // Trigger a refresh of the data
                    ref.invalidate(mcpCatalogEntriesProvider);
                    ref.invalidate(trendingServersProvider);
                    ref.invalidate(popularServersProvider);
                  },
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'Error: $error',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  bool get _hasFilters =>
      _searchQuery.isNotEmpty ||
      _searchInput.isNotEmpty ||
      _selectedCategory != null ||
      _selectedTrustLevel != null ||
      _showOnlyVerified ||
      _showTrending ||
      _showPopular ||
      _selectedDifficulty != null;

  List<MCPCatalogEntry> _filterServers(List<MCPCatalogEntry> servers) {
    var filtered = servers.where((server) {
      // Enhanced search filter with fuzzy matching
      if (_searchQuery.isNotEmpty) {
        final searchScore = _calculateSearchScore(server, _searchQuery);
        if (searchScore == 0) return false;
      }

      // Category filter
      if (_selectedCategory != null && server.category != _selectedCategory) {
        return false;
      }

      // Enhanced trust level filter with more granular classification
      if (_selectedTrustLevel != null) {
        final trustClassification = _getTrustClassification(server);
        if (_selectedTrustLevel != trustClassification) {
          return false;
        }
      }

      // Difficulty filter
      if (_selectedDifficulty != null) {
        final serverDifficulty = _getDifficultyForEntry(server);
        if (serverDifficulty != _selectedDifficulty) {
          return false;
        }
      }

      // Verified filter
      if (_showOnlyVerified && !server.isOfficial) {
        return false;
      }

      return true;
    }).toList();

    // Sort by search relevance first, then by quality
    if (_searchQuery.isNotEmpty) {
      filtered.sort((a, b) {
        int searchScoreA = _calculateSearchScore(a, _searchQuery);
        int searchScoreB = _calculateSearchScore(b, _searchQuery);
        if (searchScoreA != searchScoreB) {
          return searchScoreB.compareTo(searchScoreA);
        }
        // If search scores are equal, use quality score
        int qualityScoreA = _calculateEntryScore(a);
        int qualityScoreB = _calculateEntryScore(b);
        return qualityScoreB.compareTo(qualityScoreA);
      });
    } else if (!_showTrending && !_showPopular && _selectedCategory == null &&
               _selectedTrustLevel == null && !_showOnlyVerified && _selectedDifficulty == null) {
      // Sort by quality if no specific ordering is applied
      filtered.sort((a, b) {
        int scoreA = _calculateEntryScore(a);
        int scoreB = _calculateEntryScore(b);
        return scoreB.compareTo(scoreA);
      });
    }

    // Remove duplicates based on server name and ID
    final seen = <String>{};
    filtered = filtered.where((server) {
      final key = '${server.id}_${server.name}';
      if (seen.contains(key)) {
        return false;
      }
      seen.add(key);
      return true;
    }).toList();

    return filtered;
  }

  /// Calculate search relevance score using fuzzy matching algorithm
  int _calculateSearchScore(MCPCatalogEntry entry, String query) {
    if (query.isEmpty) return 100;

    final queryLower = query.toLowerCase();
    final queryWords = queryLower.split(' ').where((w) => w.isNotEmpty).toList();

    int totalScore = 0;

    // Exact name match gets highest score
    final nameLower = entry.name.toLowerCase();
    if (nameLower == queryLower) return 1000;
    if (nameLower.contains(queryLower)) totalScore += 800;

    // Check each word in the query
    for (final word in queryWords) {
      // Name matching (high priority)
      if (nameLower.contains(word)) {
        totalScore += word.length == nameLower.length ? 500 : 300;
      }

      // Description matching (medium priority)
      final descLower = entry.description.toLowerCase();
      if (descLower.contains(word)) {
        totalScore += 200;
      }

      // Capability matching (medium priority)
      for (final cap in entry.capabilities) {
        if (cap.toLowerCase().contains(word)) {
          totalScore += 150;
        }
      }

      // Tag matching (lower priority)
      for (final tag in entry.tags) {
        if (tag.toLowerCase().contains(word)) {
          totalScore += 100;
        }
      }

      // Fuzzy matching for typos (very low priority)
      if (_calculateLevenshteinDistance(word, nameLower) <= 2 && word.length > 2) {
        totalScore += 50;
      }
    }

    // Boost official servers in search results
    if (entry.isOfficial) totalScore += 100;

    // Boost recently updated servers
    if (entry.lastUpdated != null) {
      final daysSinceUpdate = DateTime.now().difference(entry.lastUpdated!).inDays;
      if (daysSinceUpdate < 30) totalScore += 50;
      else if (daysSinceUpdate < 90) totalScore += 25;
    }

    return totalScore;
  }

  /// Calculate Levenshtein distance for fuzzy matching
  int _calculateLevenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= s2.length; j++) matrix[0][j] = j;

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,     // deletion
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Classify trust level based on multiple factors
  String _getTrustClassification(MCPCatalogEntry server) {
    if (server.isOfficial) {
      return 'Official';
    }

    // Calculate trust score for community servers
    int trustScore = 0;

    // Repository analysis
    if (server.repository != null) {
      final repoUrl = server.repository!.toLowerCase();

      // GitHub repos get higher trust
      if (repoUrl.contains('github.com')) trustScore += 3;

      // Organization vs individual repos
      final pathSegments = Uri.tryParse(server.repository!)?.pathSegments ?? [];
      if (pathSegments.length >= 2) {
        final owner = pathSegments[0];
        // Known organizations or popular accounts get boost
        if (_isKnownTrustedOrganization(owner)) {
          trustScore += 5;
        }
      }
    }

    // Documentation quality indicates trust
    if (server.documentationUrl != null) trustScore += 2;
    if (server.setupInstructions?.isNotEmpty == true) trustScore += 1;

    // Regular updates indicate maintained code
    if (server.lastUpdated != null) {
      final daysSinceUpdate = DateTime.now().difference(server.lastUpdated!).inDays;
      if (daysSinceUpdate < 30) trustScore += 3;
      else if (daysSinceUpdate < 90) trustScore += 2;
      else if (daysSinceUpdate < 180) trustScore += 1;
    }

    // Version tagging indicates proper release management
    if (server.version != null && server.version!.isNotEmpty) trustScore += 2;

    // Capabilities count - more comprehensive tools might be more trustworthy
    if (server.capabilities.length >= 3) trustScore += 1;
    if (server.capabilities.length >= 5) trustScore += 1;

    // Classification based on trust score
    if (trustScore >= 8) {
      return 'Verified Community'; // High-trust community servers
    } else if (trustScore >= 5) {
      return 'Community'; // Regular community servers
    } else {
      return 'Unverified'; // Low-trust or new servers
    }
  }

  /// Check if organization/user is known to be trustworthy
  bool _isKnownTrustedOrganization(String owner) {
    const trustedOrgs = {
      'microsoft', 'google', 'facebook', 'meta', 'openai', 'anthropic',
      'vercel', 'netlify', 'supabase', 'prisma', 'planetscale',
      'modelcontextprotocol', 'mcp-server-git', 'aws', 'azure',
      'firebase', 'stripe', 'twilio', 'sendgrid', 'github'
    };
    return trustedOrgs.contains(owner.toLowerCase());
  }

  /// Enhanced installation difficulty assessment with comprehensive analysis
  InstallationDifficulty _getDifficultyForEntry(MCPCatalogEntry entry) {
    final command = entry.command.toLowerCase();
    final hasEnvVars = entry.requiredEnvVars.isNotEmpty;
    final envVarCount = entry.requiredEnvVars.length;
    final hasComplexSetup = entry.setupInstructions?.isNotEmpty == true;
    final hasOptionalEnvVars = entry.optionalEnvVars.isNotEmpty;

    int difficultyScore = 0;

    // Installation method analysis
    if (command.contains('npx') || command.contains('uvx')) {
      difficultyScore += 1; // Very easy one-command install
    } else if (command.contains('pip install') || command.contains('npm install')) {
      difficultyScore += 2; // Easy package manager install
    } else if (command.contains('docker run') || command.contains('docker-compose')) {
      difficultyScore += 4; // Medium - Docker complexity
    } else if (command.contains('git clone') || command.contains('git') ||
               command.contains('make') || command.contains('build') ||
               command.contains('compile') || command.contains('cargo')) {
      difficultyScore += 6; // High - Manual build/compilation
    } else if (command.contains('curl') || command.contains('wget')) {
      difficultyScore += 5; // Medium-high - Manual download
    } else {
      difficultyScore += 3; // Unknown command, assume medium
    }

    // Environment variables complexity
    if (envVarCount == 0) {
      difficultyScore += 0; // No setup needed
    } else if (envVarCount <= 2) {
      difficultyScore += 2; // Few variables
    } else if (envVarCount <= 5) {
      difficultyScore += 4; // Moderate setup
    } else {
      difficultyScore += 6; // Complex configuration
    }

    // Additional complexity factors
    if (hasComplexSetup) difficultyScore += 3;
    if (hasOptionalEnvVars) difficultyScore += 1;
    if (entry.repository?.contains('github.com') == false) difficultyScore += 2; // Non-GitHub repos might be less documented

    // Check for authentication requirements
    final hasAuth = entry.requiredEnvVars.keys.any((key) =>
      key.toLowerCase().contains('api_key') ||
      key.toLowerCase().contains('token') ||
      key.toLowerCase().contains('secret') ||
      key.toLowerCase().contains('auth')
    );
    if (hasAuth) difficultyScore += 2;

    // Check for database/service requirements
    final requiresServices = entry.description.toLowerCase().contains('database') ||
                           entry.description.toLowerCase().contains('postgres') ||
                           entry.description.toLowerCase().contains('mysql') ||
                           entry.description.toLowerCase().contains('redis') ||
                           entry.capabilities.any((cap) => cap.toLowerCase().contains('database'));
    if (requiresServices) difficultyScore += 3;

    // Final difficulty classification
    if (difficultyScore <= 3) {
      return InstallationDifficulty.beginner;
    } else if (difficultyScore <= 7) {
      return InstallationDifficulty.intermediate;
    } else {
      return InstallationDifficulty.advanced;
    }
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

    return score;
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
                        _getDisplayName(server.name, server.description, server.capabilities),
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

    showDialog(
      context: context,
      builder: (context) => AgentMCPInstallDialog(
        catalogEntry: server,
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
              const SizedBox(height: SpacingTokens.md),
              Text('Install Command:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(server.command, style: TextStyle(fontFamily: 'monospace')),
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

  // Enhanced filter methods for tools catalogue
  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap, ThemeColors colors, {String? tooltip}) {
    final chip = FilterChip(
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

    return tooltip != null
        ? Tooltip(
            message: tooltip,
            child: chip,
          )
        : chip;
  }

  List<Widget> _buildDifficultyChips(ThemeColors colors) {
    return InstallationDifficulty.values.map((difficulty) {
      final isSelected = _selectedDifficulty == difficulty;
      final difficultyName = _getDifficultyDisplayName(difficulty);
      final difficultyIcon = _getDifficultyIcon(difficulty);

      return Padding(
        padding: const EdgeInsets.only(right: SpacingTokens.sm),
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
        padding: const EdgeInsets.only(right: SpacingTokens.sm),
        child: FilterChip(
          label: Text(_getCategoryLabel(category)),
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

  /// Get functional title that describes what the server actually does
  String _getDisplayName(String name, String description, List<String> capabilities) {
    // Extract service name from description if it follows "ServiceName MCP server" pattern
    final descPattern = RegExp(r'^(\w+)\s+MCP\s+server', caseSensitive: false);
    final match = descPattern.firstMatch(description);
    if (match != null) {
      return match.group(1)!;
    }

    // Extract from "MCP server for ServiceName" pattern
    final forPattern = RegExp(r'server\s+for\s+(\w+)', caseSensitive: false);
    final forMatch = forPattern.firstMatch(description);
    if (forMatch != null) {
      return forMatch.group(1)!;
    }

    // Clean up technical repository names
    String displayName = name
        .replaceFirst(RegExp(r'^mcp-'), '')
        .replaceFirst(RegExp(r'^@mcp-'), '')
        .replaceFirst(RegExp(r'^@[^/]+/'), '')
        .replaceFirst(RegExp(r'^io\.github\.[^.]+\.'), '')
        .replaceFirst(RegExp(r'-mcp$'), '')
        .replaceFirst(RegExp(r'-server$'), '');

    if (displayName.isEmpty) {
      displayName = name;
    }

    // Convert to title case
    displayName = displayName
        .replaceAll(RegExp(r'[-_]'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');

    return displayName.isEmpty ? name : displayName;
  }

  /// Enhanced GitHub-style card with consistent hover/focus states
  Widget _buildGitHubStyleRegistryCard(MCPCatalogEntry server, ThemeColors colors) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        bool isFocused = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: Focus(
            onFocusChange: (focused) => setState(() => isFocused = focused),
            child: GestureDetector(
              onTap: () => _showInstallDialog(server),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: isHovered || isFocused
                      ? colors.surface.withOpacity(0.8)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  border: Border.all(
                    color: isFocused
                        ? colors.primary.withOpacity(0.6)
                        : isHovered
                            ? colors.border.withOpacity(0.5)
                            : colors.border.withOpacity(0.3),
                    width: isFocused ? 2 : 1,
                  ),
                  boxShadow: isHovered || isFocused ? [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                transform: isHovered
                    ? Matrix4.translationValues(0, -2, 0)
                    : Matrix4.identity(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGitHubStyleHeader(server, colors),
                    SizedBox(height: SpacingTokens.sm),
                    _buildGitHubStyleDescription(server, colors),
                    SizedBox(height: SpacingTokens.md),
                    _buildGitHubStyleFooter(server, colors),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGitHubStyleHeader(MCPCatalogEntry server, ThemeColors colors) {
    return Row(
      children: [
        // Repository avatar (circular icon)
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getServerIcon(server),
            size: 12,
            color: colors.primary,
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getGitHubStyleName(server.name),
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (server.isOfficial)
                    Container(
                      margin: EdgeInsets.only(left: SpacingTokens.xs),
                      padding: EdgeInsets.symmetric(
                        horizontal: SpacingTokens.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                        border: Border.all(color: colors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Official',
                        style: TextStyles.caption.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: SpacingTokens.xxs),
              Text(
                'by ${_getOwnerName(server.name)}',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AsmblButton.outline(
          text: 'Install',
          onPressed: () => _showInstallDialog(server),
          size: AsmblButtonSize.small,
        ),
      ],
    );
  }

  Widget _buildGitHubStyleDescription(MCPCatalogEntry server, ThemeColors colors) {
    return Text(
      server.description,
      style: TextStyles.bodySmall.copyWith(
        color: colors.onSurfaceVariant,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildGitHubStyleFooter(MCPCatalogEntry server, ThemeColors colors) {
    return Row(
      children: [
        // Language indicator (for primary capability)
        if (server.capabilities.isNotEmpty) ...[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getLanguageColor(server.capabilities.first),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: SpacingTokens.xs),
          Text(
            _getPrimaryLanguage(server.capabilities.first),
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(width: SpacingTokens.md),
        ],
        // Star count (mock)
        Icon(
          Icons.star_border,
          size: 16,
          color: colors.onSurfaceVariant,
        ),
        SizedBox(width: SpacingTokens.xs),
        Text(
          _getStarCount(server),
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(width: SpacingTokens.md),
        // Updated time
        if (server.lastUpdated != null)
          Text(
            'Updated ${_getTimeAgo(server.lastUpdated!)}',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  String _getGitHubStyleName(String name) {
    // Handle io.github.* format (common in GitHub MCP registry)
    if (name.startsWith('io.github.')) {
      final parts = name.split('/');
      if (parts.length > 1) {
        return parts.last;
      }
    }

    // Handle npm-style names like "@owner/server-name"
    if (name.startsWith('@')) {
      final parts = name.split('/');
      if (parts.length > 1) {
        return parts.last.replaceFirst(RegExp(r'^mcp-'), '');
      }
    }

    // Handle direct names like "mcp-server-name"
    name = name.replaceFirst(RegExp(r'^mcp-'), '');

    return name.isEmpty ? name : name;
  }

  String _getOwnerName(String name) {
    // Handle io.github.* format
    if (name.startsWith('io.github.')) {
      final parts = name.split('/');
      if (parts.length > 1) {
        return parts[1];
      }
    }

    // Handle npm-style names
    if (name.startsWith('@')) {
      final parts = name.split('/');
      if (parts.length > 1) {
        return parts.first.substring(1);
      }
    }

    // Handle regular names with slashes
    if (name.contains('/')) {
      return name.split('/').first;
    }

    return 'community';
  }

  String _getPrimaryLanguage(String capability) {
    if (capability.contains('database') || capability.contains('sql')) return 'SQL';
    if (capability.contains('web') || capability.contains('http')) return 'TypeScript';
    if (capability.contains('file') || capability.contains('fs')) return 'Python';
    if (capability.contains('ai') || capability.contains('llm')) return 'Python';

    return capability.replaceAll('-', ' ').split(' ').first.capitalize();
  }

  Color _getLanguageColor(String capability) {
    final language = _getPrimaryLanguage(capability).toLowerCase();

    switch (language) {
      case 'typescript': return const Color(0xFF3178C6);
      case 'python': return const Color(0xFF3776AB);
      case 'sql': return const Color(0xFF336791);
      case 'mcp': return const Color(0xFF007ACC);
      default: return const Color(0xFF586069);
    }
  }

  String _getStarCount(MCPCatalogEntry server) {
    // Use real star count if available
    if (server.starCount != null) {
      final stars = server.starCount!;
      if (stars >= 1000) {
        return '${(stars / 1000).toStringAsFixed(1)}k';
      }
      return stars.toString();
    }

    // Fallback to fake calculation for servers without star count data
    int stars = 0;
    if (server.isOfficial) stars += 50;
    if (server.isFeatured) stars += 25;
    stars += server.capabilities.length * 3;

    if (stars > 100) return '${(stars / 100).round() * 100}';
    if (stars > 50) return '${(stars / 10).round() * 10}';

    return stars.toString();
  }

  IconData _getServerIcon(MCPCatalogEntry server) {
    final category = server.category;
    if (category == null) return Icons.extension;

    switch (category) {
      case MCPServerCategory.development: return Icons.code;
      case MCPServerCategory.productivity: return Icons.trending_up;
      case MCPServerCategory.communication: return Icons.chat;
      case MCPServerCategory.dataAnalysis: return Icons.analytics;
      case MCPServerCategory.automation: return Icons.auto_awesome;
      case MCPServerCategory.fileManagement: return Icons.folder;
      case MCPServerCategory.webServices: return Icons.language;
      case MCPServerCategory.cloud: return Icons.cloud;
      case MCPServerCategory.database: return Icons.storage;
      case MCPServerCategory.security: return Icons.security;
      case MCPServerCategory.monitoring: return Icons.monitor;
      case MCPServerCategory.ai: return Icons.psychology;
      case MCPServerCategory.utility: return Icons.build;
      case MCPServerCategory.experimental: return Icons.science;
      case MCPServerCategory.custom: return Icons.extension;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
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
                  widget.server.command,
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

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}