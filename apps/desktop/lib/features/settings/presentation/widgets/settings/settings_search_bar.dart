import 'package:flutter/material.dart';
import '../../../../../core/design_system/design_system.dart';

/// Modern search bar for settings - with autocomplete and suggestions
class SettingsSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final List<String> suggestions;

  const SettingsSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.suggestions = const [],
  });

  @override
  State<SettingsSearchBar> createState() => _SettingsSearchBarState();
}

class _SettingsSearchBarState extends State<SettingsSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  final List<String> _commonSearches = [
    'API key',
    'theme',
    'notifications',
    'agent',
    'model',
    'privacy',
    'export',
    'backup',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Search Input
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            border: Border.all(
              color: _isFocused ? colors.primary : colors.border,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused ? [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
            decoration: InputDecoration(
              hintText: 'Search settings...',
              hintStyle: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              prefixIcon: Icon(
                Icons.search,
                color: _isFocused ? colors.primary : colors.onSurfaceVariant,
              ),
              suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: colors.onSurfaceVariant),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
                  )
                : _isFocused
                    ? Icon(
                        Icons.keyboard_return,
                        color: colors.onSurfaceVariant,
                        size: 16,
                      )
                    : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.componentSpacing,
                vertical: SpacingTokens.componentSpacing,
              ),
            ),
          ),
        ),
        
        // Quick Search Suggestions (when focused and empty)
        if (_isFocused && widget.controller.text.isEmpty) ...[
          const SizedBox(height: SpacingTokens.iconSpacing),
          _buildQuickSuggestions(colors),
        ],
      ],
    );
  }

  Widget _buildQuickSuggestions(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick searches',
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.iconSpacing),
          
          Wrap(
            spacing: SpacingTokens.iconSpacing,
            runSpacing: SpacingTokens.iconSpacing,
            children: _commonSearches.map((search) => _buildSuggestionChip(search, colors)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, ThemeColors colors) {
    return GestureDetector(
      onTap: () {
        widget.controller.text = text;
        widget.onChanged(text);
        _focusNode.unfocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.componentSpacing,
          vertical: SpacingTokens.iconSpacing,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 12,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: SpacingTokens.xs_precise),
            Text(
              text,
              style: TextStyles.caption.copyWith(
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}