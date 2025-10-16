import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/constants/routes.dart';
import '../../../core/models/settings_models.dart';
import '../providers/settings_provider.dart';
import '../components/settings_category_card.dart';
import '../categories/ai_models_settings_category.dart';
import '../categories/mcp_tools_settings_category.dart';
import '../categories/appearance_settings_category.dart';
import '../categories/oauth_settings_category.dart';

/// Unified Settings Screen - Single entry point for all settings
/// Replaces the fragmented settings architecture with a clean, unified approach
class UnifiedSettingsScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const UnifiedSettingsScreen({
    super.key,
    this.initialCategory,
  });

  @override
  ConsumerState<UnifiedSettingsScreen> createState() => _UnifiedSettingsScreenState();
}

class _UnifiedSettingsScreenState extends ConsumerState<UnifiedSettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  SettingsCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    
    // Set initial category if provided
    if (widget.initialCategory != null) {
      _selectedCategory = _getCategoryFromString(widget.initialCategory!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final settingsState = ref.watch(settingsProvider);
    final searchQuery = ref.watch(settingsSearchProvider);
    final filteredCategories = ref.watch(filteredSettingsCategoriesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(colors),
            
            // Main content
            Expanded(
              child: _selectedCategory != null
                  ? _buildCategoryDetail(_selectedCategory!, colors)
                  : _buildCategoriesOverview(filteredCategories, colors, settingsState),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the header with title and search
  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.xxl,
        SpacingTokens.headerPadding,
        SpacingTokens.xxl,
        SpacingTokens.lg,
      ),
      child: Row(
        children: [
          // Back button (when in category view)
          if (_selectedCategory != null) ...[
            IconButton(
              onPressed: () => setState(() => _selectedCategory = null),
              icon: Icon(
                Icons.arrow_back,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(width: SpacingTokens.md),
          ],
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCategory != null 
                      ? _getCategoryDisplayName(_selectedCategory!)
                      : 'Settings',
                  style: TextStyles.pageTitle.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  _selectedCategory != null
                      ? _getCategoryDescription(_selectedCategory!)
                      : 'Customize your Asmbli experience',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar (only in overview)
          if (_selectedCategory == null) ...[
            const SizedBox(width: SpacingTokens.lg),
            SizedBox(
              width: 300,
              child: _buildSearchBar(colors),
            ),
          ],
        ],
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar(ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(settingsSearchProvider.notifier).state = value;
        },
        style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: 'Search settings...',
          hintStyle: TextStyles.bodyMedium.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colors.onSurfaceVariant,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
        ),
      ),
    );
  }

  /// Build categories overview
  Widget _buildCategoriesOverview(
    List<SettingsCategory> categories,
    ThemeColors colors,
    UnifiedSettingsState settingsState,
  ) {
    if (settingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (settingsState.error != null) {
      return _buildErrorState(settingsState.error!, colors);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick stats
              _buildQuickStats(colors, settingsState),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Categories grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: SpacingTokens.lg,
                  mainAxisSpacing: SpacingTokens.lg,
                  childAspectRatio: 1.8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) => _buildCategoryCard(categories[index]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build quick stats overview
  Widget _buildQuickStats(ThemeColors colors, UnifiedSettingsState settingsState) {
    final stats = [
      _StatItem(
        label: 'AI Models',
        value: settingsState.aiModels.configurations.length.toString(),
        color: Colors.blue,
      ),
      _StatItem(
        label: 'MCP Tools',
        value: settingsState.mcpTools.servers.where((s) => s.enabled).length.toString(),
        color: Colors.green,
      ),
      _StatItem(
        label: 'OAuth Connections',
        value: settingsState.oauth.connectedProviders.length.toString(),
        color: Colors.purple,
      ),
    ];

    return Row(
      children: stats.map((stat) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: SpacingTokens.lg),
          padding: const EdgeInsets.all(SpacingTokens.lg),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: TextStyles.headingLarge.copyWith(
                  color: stat.color,
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                stat.label,
                style: TextStyles.labelMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  /// Build individual category card
  Widget _buildCategoryCard(SettingsCategory category) {
    final categoryInfo = _getCategoryInfo(category);
    
    return SettingsCategoryCard(
      category: category,
      title: categoryInfo.title,
      description: categoryInfo.description,
      icon: categoryInfo.icon,
      color: categoryInfo.color,
      onTap: () => setState(() => _selectedCategory = category),
    );
  }

  /// Build category detail view
  Widget _buildCategoryDetail(SettingsCategory category, ThemeColors colors) {
    switch (category) {
      case SettingsCategory.aiModels:
        return const AiModelsSettingsCategory();
      case SettingsCategory.mcpTools:
        return const McpToolsSettingsCategory();
      case SettingsCategory.appearance:
        return const AppearanceSettingsCategory();
      case SettingsCategory.oauth:
        return const OAuthSettingsCategory();
      case SettingsCategory.agents:
        return _buildPlaceholderCategory('Agents', 'Agent management coming soon', colors);
      case SettingsCategory.account:
        return _buildPlaceholderCategory('Account', 'Account settings coming soon', colors);
    }
  }

  /// Build placeholder for unimplemented categories
  Widget _buildPlaceholderCategory(String title, String message, ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            title,
            style: TextStyles.headingLarge.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            message,
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error, ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colors.error,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Settings Error',
            style: TextStyles.headingLarge.copyWith(
              color: colors.error,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            error,
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.lg),
          AsmblButton.primary(
            text: 'Retry',
            icon: Icons.refresh,
            onPressed: () => ref.read(settingsProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  /// Get category info for display
  _CategoryInfo _getCategoryInfo(SettingsCategory category) {
    switch (category) {
      case SettingsCategory.account:
        return _CategoryInfo(
          title: 'Account & Profile',
          description: 'Personal information and preferences',
          icon: Icons.person,
          color: Colors.blue,
        );
      case SettingsCategory.aiModels:
        return _CategoryInfo(
          title: 'AI Models',
          description: 'Configure language models and API providers',
          icon: Icons.auto_awesome,
          color: Colors.green,
        );
      case SettingsCategory.agents:
        return _CategoryInfo(
          title: 'AI Agents',
          description: 'Manage agents and system prompts',
          icon: Icons.smart_toy,
          color: Colors.purple,
        );
      case SettingsCategory.mcpTools:
        return _CategoryInfo(
          title: 'MCP Tools',
          description: 'Install and configure tools and integrations',
          icon: Icons.extension,
          color: Colors.orange,
        );
      case SettingsCategory.oauth:
        return _CategoryInfo(
          title: 'OAuth & Security',
          description: 'Manage authentication and security settings',
          icon: Icons.security,
          color: Colors.red,
        );
      case SettingsCategory.appearance:
        return _CategoryInfo(
          title: 'Appearance',
          description: 'Customize themes, colors, and display options',
          icon: Icons.palette,
          color: Colors.indigo,
        );
    }
  }

  /// Get category from string
  SettingsCategory? _getCategoryFromString(String categoryName) {
    try {
      return SettingsCategory.values.firstWhere(
        (category) => category.name == categoryName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get category display name
  String _getCategoryDisplayName(SettingsCategory category) {
    return _getCategoryInfo(category).title;
  }

  /// Get category description
  String _getCategoryDescription(SettingsCategory category) {
    return _getCategoryInfo(category).description;
  }
}

/// Category info data class
class _CategoryInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _CategoryInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Stat item data class
class _StatItem {
  final String label;
  final String value;
  final Color color;

  _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });
}