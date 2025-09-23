import 'package:flutter/material.dart';
import '../../../../../core/design_system/design_system.dart';

/// Integration Search Bar - Clean search focused on finding integrations
class IntegrationSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final List<String> suggestions;

  const IntegrationSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.suggestions = const [],
  });

  @override
  State<IntegrationSearchBar> createState() => _IntegrationSearchBarState();
}

class _IntegrationSearchBarState extends State<IntegrationSearchBar> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
        border: Border.all(
          color: _isFocused ? colors.primary : colors.border,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Icon
          Padding(
            padding: const EdgeInsets.only(left: SpacingTokens.componentSpacing),
            child: Icon(
              Icons.search,
              color: _isFocused ? colors.primary : colors.onSurfaceVariant,
              size: 20,
            ),
          ),
          
          // Search Input
          Expanded(
            child: Focus(
              onFocusChange: (focused) {
                setState(() => _isFocused = focused);
              },
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search integrations...',
                  hintStyle: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.componentSpacing,
                    vertical: SpacingTokens.componentSpacing,
                  ),
                ),
              ),
            ),
          ),
          
          // Clear Button (when text exists)
          if (widget.controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: SpacingTokens.iconSpacing),
              child: IconButton(
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
                icon: Icon(
                  Icons.clear,
                  color: colors.onSurfaceVariant,
                  size: 18,
                ),
                tooltip: 'Clear search',
              ),
            ),
        ],
      ),
    );
  }
}