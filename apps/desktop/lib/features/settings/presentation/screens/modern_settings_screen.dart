import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../widgets/settings/settings_search_bar.dart';
import '../widgets/settings/settings_category_card.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../providers/agent_provider.dart';
import '../../../../providers/conversation_provider.dart';
import '../../../../core/services/integration_service.dart';
import 'agent_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'llm_configuration_screen.dart';

/// Modern Settings Screen - Card-based, searchable, progressive disclosure
/// Replaces the old tab-based interface with a cleaner, more intuitive design
class ModernSettingsScreen extends ConsumerStatefulWidget {
  const ModernSettingsScreen({super.key});

  @override
  ConsumerState<ModernSettingsScreen> createState() => _ModernSettingsScreenState();
}

class _ModernSettingsScreenState extends ConsumerState<ModernSettingsScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _expandedCategory;
  
  // Animation controllers for live indicators
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<SettingsCategory> _categories = [
    SettingsCategory(
      id: 'account',
      title: 'Account & Profile',
      description: 'Personal information and preferences',
      icon: Icons.person,
      color: Colors.blue,
      priority: 1,
    ),
    SettingsCategory(
      id: 'api',
      title: 'AI Models',
      description: 'Add AI assistants and language models',
      icon: Icons.auto_awesome,
      color: Colors.green,
      priority: 2,
    ),
    SettingsCategory(
      id: 'agents',
      title: 'AI Agents',
      description: 'Agent management and system prompts',
      icon: Icons.smart_toy,
      color: Colors.purple,
      priority: 3,
    ),
    SettingsCategory(
      id: 'appearance',
      title: 'Appearance',
      description: 'Theme, colors, and display options',
      icon: Icons.palette,
      color: Colors.orange,
      priority: 4,
    ),
    SettingsCategory(
      id: 'oauth',
      title: 'OAuth Connections',
      description: 'Configure GitHub, Google, Microsoft and other OAuth providers',
      icon: Icons.security,
      color: Colors.cyan,
      priority: 5,
      searchKeywords: ['oauth', 'github', 'google', 'microsoft', 'authentication', 'login', 'provider', 'integration', 'connection'],
    ),
    SettingsCategory(
      id: 'privacy',
      title: 'Privacy & Security',
      description: 'Data handling and security preferences',
      icon: Icons.shield,
      color: Colors.red,
      priority: 6,
    ),
    SettingsCategory(
      id: 'notifications',
      title: 'Notifications',
      description: 'Alert preferences and notification settings',
      icon: Icons.notifications,
      color: Colors.indigo,
      priority: 7,
    ),
    SettingsCategory(
      id: 'advanced',
      title: 'Advanced',
      description: 'Developer settings and experimental features',
      icon: Icons.settings_applications,
      color: Colors.grey,
      priority: 8,
      isAdvanced: true,
    ),
    SettingsCategory(
      id: 'about',
      title: 'About',
      description: 'App information, updates, and support',
      icon: Icons.info,
      color: Colors.teal,
      priority: 9,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final filteredCategories = _getFilteredCategories();

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.background,
              colors.background.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // App Navigation
            const AppNavigationBar(currentRoute: AppRoutes.settings),
            
            // Settings Header & Search
            _buildHeader(colors),
            
            // Main Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Settings Content
                  Expanded(
                    child: _buildMainContent(colors, filteredCategories),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          // Title & Search
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: SpacingTokens.xs_precise),
                    Text(
                      'Customize your Asmbli experience',
                      style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: SpacingTokens.sectionSpacing),
              
              // Search Bar
              SizedBox(
                width: 300,
                child: SettingsSearchBar(
                  controller: _searchController,
                  onChanged: (value) => _onSearchChanged(),
                ),
              ),
            ],
          ),
          
          // Quick Stats
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: SpacingTokens.sectionSpacing),
            _buildQuickStats(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeColors colors) {
    return Consumer(
      builder: (context, ref, child) {
        // Get live data from providers
        final apiConfigs = ref.watch(apiConfigsProvider);
        final agentsAsync = ref.watch(agentsProvider);  
        final conversationsAsync = ref.watch(conversationsProvider);
        final integrationService = ref.watch(integrationServiceProvider);
        
        final apiCount = apiConfigs.length;
        final connectedApis = apiConfigs.values.where((config) => config.isConfigured).length;
        final integrationStats = integrationService.getStats();
        
        return Row(
          children: [
            // Live API Keys count with connection status
            _buildLiveStatChip(
              '$apiCount API Key${apiCount != 1 ? 's' : ''}',
              '$connectedApis connected',
              Icons.key,
              connectedApis > 0 ? colors.primary : colors.onSurfaceVariant,
              colors,
              isLive: connectedApis > 0,
            ),
            const SizedBox(width: SpacingTokens.componentSpacing),
            
            // Live Agents count
            agentsAsync.when(
              data: (agents) => _buildLiveStatChip(
                '${agents.length} Agent${agents.length != 1 ? 's' : ''}',
                agents.isEmpty ? 'none configured' : 'configured',
                Icons.smart_toy,
                colors.success,
                colors,
                isLive: agents.isNotEmpty,
              ),
              loading: () => _buildStatChip('... Agents', Icons.smart_toy, colors.onSurfaceVariant, colors),
              error: (_, __) => _buildStatChip('0 Agents', Icons.smart_toy, colors.error, colors),
            ),
            const SizedBox(width: SpacingTokens.componentSpacing),
            
            // Live Integrations count  
            _buildLiveStatChip(
              '${integrationStats.total} Integration${integrationStats.total != 1 ? 's' : ''}',
              '${integrationStats.enabled} enabled',
              Icons.hub,
              colors.accent,
              colors,
              isLive: integrationStats.enabled > 0,
            ),
            const SizedBox(width: SpacingTokens.componentSpacing),
            
            // Live Activity indicator
            conversationsAsync.when(
              data: (conversations) => _buildLiveStatChip(
                '${conversations.length} Active Chat${conversations.length != 1 ? 's' : ''}',
                conversations.isEmpty ? 'no activity' : 'live',
                Icons.chat_bubble,
                conversations.isNotEmpty ? colors.success : colors.onSurfaceVariant,
                colors,
                isLive: conversations.isNotEmpty,
              ),
              loading: () => _buildStatChip('... Chats', Icons.chat_bubble, colors.onSurfaceVariant, colors),
              error: (_, __) => _buildStatChip('0 Chats', Icons.chat_bubble, colors.error, colors),
            ),
            
            const Spacer(),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.componentSpacing,
        vertical: SpacingTokens.iconSpacing,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: SpacingTokens.iconSpacing),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatChip(String label, String subtitle, IconData icon, Color color, ThemeColors colors, {bool isLive = false}) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.componentSpacing,
            vertical: SpacingTokens.iconSpacing,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
            border: Border.all(
              color: color.withValues(alpha: isLive ? _pulseAnimation.value * 0.5 + 0.3 : 0.3),
              width: isLive ? 1.5 : 1.0,
            ),
            boxShadow: isLive ? [
              BoxShadow(
                color: color.withValues(alpha: _pulseAnimation.value * 0.2),
                blurRadius: 3,
                spreadRadius: 0,
              )
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(icon, size: 16, color: color),
                  if (isLive)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.success.withValues(alpha: _pulseAnimation.value),
                              blurRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: SpacingTokens.iconSpacing),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(ThemeColors colors, List<SettingsCategory> categories) {
    if (_searchQuery.isNotEmpty && categories.isEmpty) {
      return _buildEmptySearchState(colors);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Results or Categories
          if (_searchQuery.isNotEmpty) ...[
            Text(
              'Search Results (${categories.length})',
              style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
          ],
          
          // Category Cards
          ...categories.map((category) => Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
            child: SettingsCategoryCard(
              category: category,
              isExpanded: _expandedCategory == category.id,
              onTap: () => _handleCategoryTap(category),
              onExpand: () => _toggleCategoryExpansion(category.id),
            ),
          )),
          
          // Advanced Settings Toggle
          if (_searchQuery.isEmpty && !_categories.any((c) => c.isAdvanced && _shouldShowCategory(c))) ...[
            const SizedBox(height: SpacingTokens.sectionSpacing),
            _buildAdvancedToggle(colors),
          ],
          
          const SizedBox(height: SpacingTokens.xxl), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildEmptySearchState(ThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: SpacingTokens.sectionSpacing),
            Text(
              'No settings found',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Try adjusting your search terms or browse categories below',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.sectionSpacing),
            AsmblButton.secondary(
              text: 'Clear Search',
              onPressed: () {
                _searchController.clear();
                _onSearchChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedToggle(ThemeColors colors) {
    return AsmblCard(
      child: Row(
        children: [
          Icon(
            Icons.engineering,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: SpacingTokens.componentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show Advanced Settings',
                  style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
                ),
                Text(
                  'Access developer tools and experimental features',
                  style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: _shouldShowAdvanced(),
            onChanged: _toggleAdvancedSettings,
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<SettingsCategory> _getFilteredCategories() {
    return _categories.where((category) {
      if (!_shouldShowCategory(category)) return false;
      
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      return category.title.toLowerCase().contains(query) ||
             category.description.toLowerCase().contains(query) ||
             category.searchKeywords.any((keyword) => keyword.toLowerCase().contains(query));
    }).toList()..sort((a, b) => a.priority.compareTo(b.priority));
  }

  bool _shouldShowCategory(SettingsCategory category) {
    if (!category.isAdvanced) return true;
    return _shouldShowAdvanced();
  }

  bool _shouldShowAdvanced() {
    // TODO: Check user preference
    return false;
  }

  void _toggleAdvancedSettings(bool value) {
    // TODO: Save preference
    setState(() {});
  }

  void _handleCategoryTap(SettingsCategory category) {
    // Navigate to specific settings page or expand inline
    _navigateToCategory(category);
  }

  void _toggleCategoryExpansion(String categoryId) {
    setState(() {
      _expandedCategory = _expandedCategory == categoryId ? null : categoryId;
    });
  }

  void _navigateToCategory(SettingsCategory category) {
    switch (category.id) {
      case 'api':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LLMConfigurationScreen()),
        );
        break;
      case 'agents':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AgentSettingsScreen()),
        );
        break;
      case 'appearance':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AppearanceSettingsScreen()),
        );
        break;
      case 'oauth':
        context.go(AppRoutes.oauthSettings);
        break;
      case 'privacy':
        _showComingSoonDialog(category.title);
        break;
      case 'notifications':
        _showComingSoonDialog(category.title);
        break;
      case 'advanced':
        _showComingSoonDialog(category.title);
        break;
      case 'about':
        _showAboutDialog();
        break;
      default:
        _showComingSoonDialog(category.title);
    }
  }

  void _showComingSoonDialog(String categoryTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$categoryTitle Settings'),
        content: Text('Detailed $categoryTitle settings are coming soon! For now, you can use the quick settings in the sidebar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Asmbli'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            Text('Build: Desktop'),
            SizedBox(height: 16),
            Text('Asmbli makes AI agents easy to create, manage, and deploy.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Export settings and quick setup functionality removed as requested
}

/// Settings Category Data Model
class SettingsCategory {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int priority;
  final String? badge;
  final bool isAdvanced;
  final List<String> searchKeywords;

  SettingsCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.priority,
    this.badge,
    this.isAdvanced = false,
    this.searchKeywords = const [],
  });
}