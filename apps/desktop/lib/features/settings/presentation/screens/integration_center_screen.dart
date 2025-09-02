import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../widgets/integration_center/integration_search_bar.dart';
import '../widgets/integration_center/category_filter_bar.dart';
import '../widgets/integration_center/integration_cards_grid.dart';
import '../widgets/integration_center/collapsible_status_panel.dart';
import '../widgets/integration_center/collapsible_featured_panel.dart';

/// Integration Center - Cards-first unified integration experience
/// Focuses 90% of screen space on integration cards with collapsible extras
class IntegrationCenterScreen extends ConsumerStatefulWidget {
  const IntegrationCenterScreen({super.key});

  @override
  ConsumerState<IntegrationCenterScreen> createState() => _IntegrationCenterScreenState();
}

class _IntegrationCenterScreenState extends ConsumerState<IntegrationCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _showStatusPanel = false;
  bool _showFeaturedPanel = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            const AppNavigationBar(currentRoute: AppRoutes.integrationHub),
            
            // Header - Clean and minimal
            _buildHeader(colors),
            
            // Optional Collapsible Panels
            if (_showStatusPanel) 
              CollapsibleStatusPanel(onCollapse: () => setState(() => _showStatusPanel = false)),
            
            if (_showFeaturedPanel)
              CollapsibleFeaturedPanel(onCollapse: () => setState(() => _showFeaturedPanel = false)),
            
            // Main Content - Integration Cards (90% of space)
            Expanded(
              child: IntegrationCardsGrid(
                searchQuery: _searchQuery,
                selectedCategory: _selectedCategory,
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
          // Title and Action Buttons Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Integration Center',
                      style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: SpacingTokens.xs_precise),
                    Text(
                      'Configure and discover integrations',
                      style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              
              // Collapsible Panel Toggle Buttons
              _buildToggleButton(
                'Status',
                Icons.bar_chart,
                _showStatusPanel,
                () => setState(() => _showStatusPanel = !_showStatusPanel),
                colors,
              ),
              const SizedBox(width: SpacingTokens.componentSpacing),
              _buildToggleButton(
                'Featured',
                Icons.star,
                _showFeaturedPanel,
                () => setState(() => _showFeaturedPanel = !_showFeaturedPanel),
                colors,
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Search and Filters Row
          Row(
            children: [
              // Search Bar (Primary)
              Expanded(
                flex: 3,
                child: IntegrationSearchBar(
                  controller: _searchController,
                  onChanged: (value) => _onSearchChanged(),
                ),
              ),
              
              const SizedBox(width: SpacingTokens.componentSpacing),
              
              // Category Filters
              Expanded(
                flex: 2,
                child: CategoryFilterBar(
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (category) {
                    setState(() => _selectedCategory = category);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onPressed,
    ThemeColors colors,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isActive 
          ? colors.primary.withValues(alpha: 0.1)
          : colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: isActive ? colors.primary : colors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.componentSpacing,
              vertical: SpacingTokens.iconSpacing,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: SpacingTokens.iconSpacing),
                Text(
                  label,
                  style: TextStyles.caption.copyWith(
                    color: isActive ? colors.primary : colors.onSurface,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}