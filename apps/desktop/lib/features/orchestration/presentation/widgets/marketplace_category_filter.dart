import 'package:flutter/material.dart';

import '../../models/marketplace_workflow.dart';
import '../../../../core/design_system/design_system.dart';

/// Filter widget for selecting workflow marketplace categories
class MarketplaceCategoryFilter extends StatelessWidget {
  final WorkflowMarketplaceCategory? selectedCategory;
  final ValueChanged<WorkflowMarketplaceCategory?> onCategorySelected;

  const MarketplaceCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButton<WorkflowMarketplaceCategory?>(
        value: selectedCategory,
        hint: Text(
          'All Categories',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        items: [
          DropdownMenuItem<WorkflowMarketplaceCategory?>(
            value: null,
            child: Text(
              'All Categories',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          ...WorkflowMarketplaceCategory.values.map(
            (category) => DropdownMenuItem<WorkflowMarketplaceCategory?>(
              value: category,
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    category.displayName,
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        onChanged: onCategorySelected,
        underline: const SizedBox(),
        style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
        dropdownColor: colors.surface,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: colors.onSurfaceVariant,
        ),
      ),
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