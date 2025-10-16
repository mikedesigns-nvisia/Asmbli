import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/marketplace_workflow.dart';
import '../../services/workflow_marketplace_service.dart';
import '../../providers/canvas_provider.dart';
import '../widgets/marketplace_workflow_card.dart';
import '../widgets/marketplace_category_filter.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';

/// Screen for browsing and discovering workflows from the marketplace
class WorkflowMarketplaceScreen extends ConsumerStatefulWidget {
  const WorkflowMarketplaceScreen({super.key});

  @override
  ConsumerState<WorkflowMarketplaceScreen> createState() => _WorkflowMarketplaceScreenState();
}

class _WorkflowMarketplaceScreenState extends ConsumerState<WorkflowMarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final WorkflowMarketplaceService _marketplaceService = WorkflowMarketplaceService.instance;
  
  List<MarketplaceWorkflow> _featuredWorkflows = [];
  List<MarketplaceWorkflow> _searchResults = [];
  bool _isLoadingFeatured = true;
  bool _isSearching = false;
  String _sortBy = 'popularity';
  WorkflowMarketplaceCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadFeaturedWorkflows();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFeaturedWorkflows() async {
    setState(() => _isLoadingFeatured = true);
    
    try {
      final featured = await _marketplaceService.getFeaturedWorkflows();
      setState(() {
        _featuredWorkflows = featured;
        _isLoadingFeatured = false;
      });
    } catch (e) {
      setState(() => _isLoadingFeatured = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading featured workflows: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty && _selectedCategory == null) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final results = await _marketplaceService.searchWorkflows(
        query: query.isEmpty ? null : query,
        category: _selectedCategory?.name,
        sortBy: _sortBy,
        limit: 50,
      );
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching workflows: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  Future<void> _importWorkflow(MarketplaceWorkflow marketplaceWorkflow) async {
    try {
      final workflow = await _marketplaceService.importWorkflow(marketplaceWorkflow.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow "${workflow.name}" imported successfully'),
            backgroundColor: ThemeColors(context).success,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                ref.read(canvasProvider.notifier).loadWorkflow(workflow);
                Navigator.of(context).pushReplacementNamed(AppRoutes.orchestration);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import workflow: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  void _onCategorySelected(WorkflowMarketplaceCategory? category) {
    setState(() => _selectedCategory = category);
    _performSearch();
  }

  void _onSortChanged(String sortBy) {
    setState(() => _sortBy = sortBy);
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final isSearchActive = _searchController.text.isNotEmpty || _selectedCategory != null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: colors.onSurface),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: SpacingTokens.md),
                        Expanded(
                          child: Text(
                            'Workflow Marketplace',
                            style: TextStyles.pageTitle.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        AsmblButton.primary(
                          text: 'My Library',
                          icon: Icons.folder,
                          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.workflowBrowser),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.lg),
                    
                    // Search and filters
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search workflows, tags, or authors...',
                              hintStyle: TextStyles.bodyMedium.copyWith(
                                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
                              suffixIcon: _searchController.text.isNotEmpty 
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: colors.onSurfaceVariant),
                                      onPressed: () {
                                        _searchController.clear();
                                        _performSearch();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: colors.surface,
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
                                borderSide: BorderSide(color: colors.primary),
                              ),
                            ),
                            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.lg),
                        
                        // Category filter
                        MarketplaceCategoryFilter(
                          selectedCategory: _selectedCategory,
                          onCategorySelected: _onCategorySelected,
                        ),
                        const SizedBox(width: SpacingTokens.lg),
                        
                        // Sort dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                            border: Border.all(color: colors.border),
                          ),
                          child: DropdownButton<String>(
                            value: _sortBy,
                            items: const [
                              DropdownMenuItem(value: 'popularity', child: Text('Most Popular')),
                              DropdownMenuItem(value: 'rating', child: Text('Highest Rated')),
                              DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                              DropdownMenuItem(value: 'name', child: Text('Name A-Z')),
                            ],
                            onChanged: (value) {
                              if (value != null) _onSortChanged(value);
                            },
                            underline: const SizedBox(),
                            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                            dropdownColor: colors.surface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _buildContent(isSearchActive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isSearchActive) {
    if (isSearchActive) {
      return _buildSearchResults();
    } else {
      return _buildFeaturedContent();
    }
  }

  Widget _buildFeaturedContent() {
    if (_isLoadingFeatured) {
      return Center(
        child: CircularProgressIndicator(color: ThemeColors(context).primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured section
          if (_featuredWorkflows.isNotEmpty) ...[
            Text(
              'Featured Workflows',
              style: TextStyles.sectionTitle.copyWith(
                color: ThemeColors(context).onSurface,
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            SizedBox(
              height: 320,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _featuredWorkflows.length,
                itemBuilder: (context, index) {
                  final workflow = _featuredWorkflows[index];
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: SpacingTokens.lg),
                    child: MarketplaceWorkflowCard(
                      workflow: workflow,
                      onImport: () => _importWorkflow(workflow),
                      isFeatured: true,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: SpacingTokens.xxl),
          ],
          
          // Categories section
          Text(
            'Browse by Category',
            style: TextStyles.sectionTitle.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          _buildCategoryGrid(),
          const SizedBox(height: SpacingTokens.xxl),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(color: ThemeColors(context).primary),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptySearchState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results (${_searchResults.length})',
            style: TextStyles.sectionTitle.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: SpacingTokens.lg,
                mainAxisSpacing: SpacingTokens.lg,
                childAspectRatio: 0.8,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final workflow = _searchResults[index];
                return MarketplaceWorkflowCard(
                  workflow: workflow,
                  onImport: () => _importWorkflow(workflow),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    final colors = ThemeColors(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'No workflows found',
            style: TextStyles.sectionTitle.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Try adjusting your search terms or filters',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final colors = ThemeColors(context);
    final categories = WorkflowMarketplaceCategory.values;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: SpacingTokens.lg,
        mainAxisSpacing: SpacingTokens.lg,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return AsmblCard(
          child: InkWell(
            onTap: () => _onCategorySelected(category),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 32,
                    color: colors.primary,
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    category.displayName,
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(WorkflowMarketplaceCategory category) {
    switch (category) {
      case WorkflowMarketplaceCategory.general:
        return Icons.apps;
      case WorkflowMarketplaceCategory.research:
        return Icons.search;
      case WorkflowMarketplaceCategory.creative:
        return Icons.palette;
      case WorkflowMarketplaceCategory.development:
        return Icons.code;
      case WorkflowMarketplaceCategory.dataScience:
        return Icons.analytics;
      case WorkflowMarketplaceCategory.business:
        return Icons.business;
      case WorkflowMarketplaceCategory.marketing:
        return Icons.campaign;
      case WorkflowMarketplaceCategory.education:
        return Icons.school;
      case WorkflowMarketplaceCategory.healthcare:
        return Icons.local_hospital;
      case WorkflowMarketplaceCategory.finance:
        return Icons.account_balance;
    }
  }
}