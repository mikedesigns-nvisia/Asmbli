import 'package:flutter/material.dart';
import '../../../../../core/design_system/design_system.dart';

/// Category Filter Bar - Horizontal scrollable category filters
class CategoryFilterBar extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  static const List<CategoryFilter> _categories = [
    CategoryFilter('all', 'All', Icons.apps),
    CategoryFilter('development', 'Development', Icons.code),
    CategoryFilter('productivity', 'Productivity', Icons.work),
    CategoryFilter('communication', 'Communication', Icons.chat),
    CategoryFilter('ai', 'AI & ML', Icons.psychology),
    CategoryFilter('data', 'Data', Icons.storage),
    CategoryFilter('security', 'Security', Icons.security),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = selectedCategory == category.id;
          return Padding(
            padding: EdgeInsets.only(right: SpacingTokens.iconSpacing),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: isSelected ? colors.primary : colors.onSurfaceVariant,
                  ),
                  SizedBox(width: SpacingTokens.iconSpacing),
                  Text(category.label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) => onCategoryChanged(category.id),
              backgroundColor: colors.surface,
              selectedColor: colors.primary.withValues(alpha: 0.1),
              checkmarkColor: colors.primary,
              labelStyle: TextStyles.caption.copyWith(
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? colors.primary : colors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CategoryFilter {
  final String id;
  final String label;
  final IconData icon;

  const CategoryFilter(this.id, this.label, this.icon);
}