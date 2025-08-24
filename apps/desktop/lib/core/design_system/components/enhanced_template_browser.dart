import 'package:flutter/material.dart';
import '../design_system.dart';
import '../../models/enhanced_mcp_template.dart';

/// Enhanced template browser with category filtering, search, and smart recommendations
class EnhancedTemplateBrowser extends StatefulWidget {
  final ValueChanged<EnhancedMCPTemplate>? onTemplateSelected;
  final List<String>? recommendedTags; // For context-aware recommendations
  final String? userRole; // For role-based recommendations
  final bool showPopularFirst;

  const EnhancedTemplateBrowser({
    super.key,
    this.onTemplateSelected,
    this.recommendedTags,
    this.userRole,
    this.showPopularFirst = true,
  });

  @override
  State<EnhancedTemplateBrowser> createState() => _EnhancedTemplateBrowserState();
}

class _EnhancedTemplateBrowserState extends State<EnhancedTemplateBrowser> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  bool _showRecommendedOnly = false;

  List<EnhancedMCPTemplate> get _filteredTemplates {
    var templates = EnhancedMCPTemplates.allTemplates;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      templates = templates.where((template) {
        return template.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               template.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               template.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    
    // Filter by category
    if (_selectedCategory != 'All') {
      templates = templates.where((template) => template.category == _selectedCategory).toList();
    }
    
    // Filter by difficulty
    if (_selectedDifficulty != 'All') {
      templates = templates.where((template) => template.difficulty == _selectedDifficulty).toList();
    }
    
    // Filter by recommended
    if (_showRecommendedOnly) {
      templates = templates.where((template) => 
        template.isRecommended || 
        (widget.recommendedTags?.any((tag) => template.tags.contains(tag)) ?? false)
      ).toList();
    }
    
    // Sort by popularity and recommendation
    templates.sort((a, b) {
      if (widget.showPopularFirst) {
        if (a.isPopular && !b.isPopular) return -1;
        if (!a.isPopular && b.isPopular) return 1;
      }
      if (a.isRecommended && !b.isRecommended) return -1;
      if (!a.isRecommended && b.isRecommended) return 1;
      return a.name.compareTo(b.name);
    });
    
    return templates;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header and search
        _buildHeader(context),
        
        SizedBox(height: SpacingTokens.sectionSpacing),
        
        // Filters
        _buildFilters(context),
        
        SizedBox(height: SpacingTokens.sectionSpacing),
        
        // Quick recommendations
        if (widget.recommendedTags != null || widget.userRole != null) ...[
          _buildRecommendations(context),
          SizedBox(height: SpacingTokens.sectionSpacing),
        ],
        
        // Template grid
        Expanded(
          child: _buildTemplateGrid(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Integration',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Connect your agent to external services and tools',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 16),
        // Search bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search integrations...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        // Category filter
        _buildFilterDropdown(
          context,
          label: 'Category',
          value: _selectedCategory,
          items: ['All', ...TemplateCategories.all],
          onChanged: (value) => setState(() => _selectedCategory = value!),
        ),
        
        // Difficulty filter
        _buildFilterDropdown(
          context,
          label: 'Difficulty',
          value: _selectedDifficulty,
          items: ['All', 'Easy', 'Medium', 'Hard'],
          onChanged: (value) => setState(() => _selectedDifficulty = value!),
        ),
        
        // Recommended toggle
        FilterChip(
          selected: _showRecommendedOnly,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 14),
              SizedBox(width: 4),
              Text('Recommended'),
            ],
          ),
          onSelected: (selected) => setState(() => _showRecommendedOnly = selected),
          selectedColor: SemanticColors.primary.withValues(alpha: 0.2),
          checkmarkColor: SemanticColors.primary,
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: SizedBox.shrink(),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: TextStyle(fontSize: 12),
          ),
        )).toList(),
        hint: Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    final recommendations = _getRecommendationsForUser();
    if (recommendations.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 16,
              color: SemanticColors.primary,
            ),
            SizedBox(width: 8),
            Text(
              'Recommended for you',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: SemanticColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final template = recommendations[index];
              return Container(
                width: 200,
                margin: EdgeInsets.only(right: 12),
                child: _buildCompactTemplateCard(context, template, isRecommended: true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateGrid(BuildContext context) {
    final templates = _filteredTemplates;
    
    if (templates.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        return _buildTemplateCard(context, templates[index]);
      },
    );
  }

  Widget _buildTemplateCard(BuildContext context, EnhancedMCPTemplate template) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onTemplateSelected?.call(template),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and badges
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (template.brandColor ?? SemanticColors.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      template.icon,
                      color: template.brandColor ?? SemanticColors.primary,
                      size: 20,
                    ),
                  ),
                  Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (template.isPopular) _buildPopularBadge(),
                      if (template.isRecommended) ...[
                        if (template.isPopular) SizedBox(height: 2),
                        _buildRecommendedBadge(),
                      ],
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Title and category
              Text(
                template.name,
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 4),
              
              Row(
                children: [
                  Text(
                    template.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: template.brandColor ?? SemanticColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 8),
                  _buildDifficultyBadge(template.difficulty),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Description
              Expanded(
                child: Text(
                  template.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: 12),
              
              // Capabilities
              if (template.capabilities.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: template.capabilities.take(2).map((capability) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        capability,
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTemplateCard(BuildContext context, EnhancedMCPTemplate template, {bool isRecommended = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.onTemplateSelected?.call(template),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isRecommended 
              ? SemanticColors.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isRecommended
                ? SemanticColors.primary.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (template.brandColor ?? SemanticColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  template.icon,
                  color: template.brandColor ?? SemanticColors.primary,
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      template.name,
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isRecommended 
                          ? SemanticColors.primary 
                          : Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      template.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 16),
          Text(
            'No integrations found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16),
          AsmblButton.secondary(
            text: 'Clear Filters',
            icon: Icons.clear,
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'All';
                _selectedDifficulty = 'All';
                _showRecommendedOnly = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPopularBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 8,
            color: Colors.orange,
          ),
          SizedBox(width: 2),
          Text(
            'Popular',
            style: TextStyle(
              fontSize: 8,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: SemanticColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Recommended',
        style: TextStyle(
          fontSize: 8,
          color: SemanticColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color badgeColor;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        badgeColor = SemanticColors.success;
        break;
      case 'medium':
        badgeColor = Colors.orange;
        break;
      case 'hard':
        badgeColor = SemanticColors.error;
        break;
      default:
        badgeColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 8,
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<EnhancedMCPTemplate> _getRecommendationsForUser() {
    final recommendations = <EnhancedMCPTemplate>[];
    
    // Role-based recommendations
    switch (widget.userRole?.toLowerCase()) {
      case 'designer':
        recommendations.addAll([
          EnhancedMCPTemplates.figma,
          EnhancedMCPTemplates.filesystem,
        ]);
        break;
      case 'developer':
        recommendations.addAll([
          EnhancedMCPTemplates.github,
          EnhancedMCPTemplates.git,
          EnhancedMCPTemplates.postgresql,
        ]);
        break;
      case 'business':
        recommendations.addAll([
          EnhancedMCPTemplates.microsoftGraph,
          EnhancedMCPTemplates.openai,
        ]);
        break;
    }
    
    // Tag-based recommendations
    if (widget.recommendedTags != null) {
      final tagRecommendations = EnhancedMCPTemplates.searchByTags(widget.recommendedTags!);
      recommendations.addAll(tagRecommendations);
    }
    
    // Remove duplicates and limit
    final uniqueRecommendations = recommendations.toSet().toList();
    return uniqueRecommendations.take(4).toList();
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }
}