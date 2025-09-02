import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../widgets/integration_hub/quick_actions_bar.dart';
import '../widgets/integration_hub/status_overview.dart';
import '../widgets/integration_hub/integration_grid.dart';
import '../widgets/integration_hub/advanced_management_panel.dart';

/// Unified Integration Hub - Single source of truth for all integration management
/// Replaces the fragmented experience with a cohesive, progressive disclosure system
class IntegrationHubScreen extends ConsumerStatefulWidget {
  const IntegrationHubScreen({super.key});

  @override
  ConsumerState<IntegrationHubScreen> createState() => _IntegrationHubScreenState();
}

class _IntegrationHubScreenState extends ConsumerState<IntegrationHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _showAdvancedPanel = false;
  bool _isExpertMode = false;

  // Categories for integration filtering
  final Map<String, String> _categories = {
    'all': 'All Integrations',
    'active': 'Active',
    'configured': 'Configured', 
    'available': 'Available',
    'suggested': 'Suggested',
    'development': 'Development',
    'productivity': 'Productivity',
    'communication': 'Communication',
    'data': 'Data & Storage',
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            // App Navigation Bar
            const AppNavigationBar(currentRoute: AppRoutes.integrationHub),
            
            // Header with navigation and controls
            _buildHeader(colors),
            
            // Main content area
            Expanded(
              child: Row(
                children: [
                  // Main integration management area
                  Expanded(
                    child: _buildMainContent(colors),
                  ),
                  
                  // Advanced management panel (slide-out)
                  if (_showAdvancedPanel)
                    _buildAdvancedPanel(colors),
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
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back navigation
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
            tooltip: 'Back to Settings',
          ),
          
          const SizedBox(width: SpacingTokens.componentSpacing),
          
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Integrations Hub',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.xs_precise),
                Text(
                  'Connect your tools and services to enhance your AI agents',
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          // Header controls
          Row(
            children: [
              // Expert mode toggle
              Tooltip(
                message: _isExpertMode ? 'Switch to Simple Mode' : 'Switch to Expert Mode',
                child: IconButton(
                  onPressed: () => setState(() => _isExpertMode = !_isExpertMode),
                  icon: Icon(
                    _isExpertMode ? Icons.psychology : Icons.psychology_outlined,
                    color: _isExpertMode ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
              ),
              
              const SizedBox(width: SpacingTokens.iconSpacing),
              
              // Advanced panel toggle
              Tooltip(
                message: _showAdvancedPanel ? 'Hide Advanced Tools' : 'Show Advanced Tools',
                child: IconButton(
                  onPressed: () => setState(() => _showAdvancedPanel = !_showAdvancedPanel),
                  icon: Icon(
                    _showAdvancedPanel ? Icons.tune : Icons.tune_outlined,
                    color: _showAdvancedPanel ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
              ),
              
              const SizedBox(width: SpacingTokens.iconSpacing),
              
              // Help button
              IconButton(
                onPressed: _showHelpDialog,
                icon: Icon(Icons.help_outline, color: colors.onSurfaceVariant),
                tooltip: 'Help & Documentation',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        children: [
          // Quick Actions Bar
          QuickActionsBar(
            onDetectionRequested: _handleDetection,
            onAddIntegrationRequested: _handleAddIntegration,
            onImportRequested: _handleImport,
            onSuggestionsRequested: _handleSuggestions,
            isExpertMode: _isExpertMode,
          ),
          
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Status Overview (collapsible)
          StatusOverview(
            onStatusClicked: _handleStatusClick,
            showDetailed: _isExpertMode,
          ),
          
          const SizedBox(height: SpacingTokens.sectionSpacing),
          
          // Search and Filter Bar
          _buildSearchAndFilter(colors),
          
          const SizedBox(height: SpacingTokens.componentSpacing),
          
          // Main Integration Grid
          Expanded(
            child: IntegrationGrid(
              searchQuery: _searchQuery,
              selectedCategory: _selectedCategory,
              isExpertMode: _isExpertMode,
              onIntegrationTap: _handleIntegrationTap,
              onIntegrationAction: _handleIntegrationAction,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(ThemeColors colors) {
    return Row(
      children: [
        // Search field
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.border),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search integrations...',
                prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: Icon(Icons.clear, color: colors.onSurfaceVariant),
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(SpacingTokens.componentSpacing),
              ),
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ),
        
        const SizedBox(width: SpacingTokens.componentSpacing),
        
        // Category filter dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.componentSpacing),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(color: colors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              icon: Icon(Icons.arrow_drop_down, color: colors.onSurface),
              items: _categories.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ),
        ),
        
        const SizedBox(width: SpacingTokens.componentSpacing),
        
        // Filter button for advanced options
        IconButton(
          onPressed: _showAdvancedFilters,
          icon: Icon(Icons.filter_list, color: colors.onSurfaceVariant),
          tooltip: 'Advanced Filters',
        ),
      ],
    );
  }

  Widget _buildAdvancedPanel(ThemeColors colors) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.95),
        border: Border(
          left: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: AdvancedManagementPanel(
        onClose: () => setState(() => _showAdvancedPanel = false),
      ),
    );
  }

  // Event Handlers
  void _handleDetection() {
    // Implement smart detection flow
    // TODO: Integrate with detection services
  }

  void _handleAddIntegration() {
    // Show smart integration selection
    // TODO: Implement smart integration selection flow
  }

  void _handleImport() {
    // Show import configuration dialog
    // TODO: Implement import functionality
  }

  void _handleSuggestions() {
    // Show AI-powered suggestions
    // TODO: Implement suggestion system
  }

  void _handleStatusClick(String status) {
    // Filter by status when status overview is clicked
    setState(() => _selectedCategory = status);
  }

  void _handleIntegrationTap(String integrationId) {
    // Show integration details or configuration
    // TODO: Implement integration detail view
  }

  void _handleIntegrationAction(String integrationId, String action) {
    // Handle integration actions (enable, configure, remove, etc.)
    // TODO: Implement integration actions
  }

  void _showAdvancedFilters() {
    // Show advanced filter options
    // TODO: Implement advanced filter dialog
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Integrations Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to the Integrations Hub!'),
            SizedBox(height: SpacingTokens.componentSpacing),
            Text('• Use Quick Actions to add integrations rapidly'),
            Text('• Click cards to configure or manage integrations'),
            Text('• Toggle Expert Mode for advanced options'),
            Text('• Use the Advanced Panel for system monitoring'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}