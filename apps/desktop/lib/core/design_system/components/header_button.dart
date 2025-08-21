import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';

// Header button component matching your existing _HeaderButton pattern
class HeaderButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  const HeaderButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  State<HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<HeaderButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          hoverColor: SemanticColors.primary.withOpacity(0.08),
          splashColor: SemanticColors.primary.withOpacity(0.16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            decoration: BoxDecoration(
              color: widget.isActive
                ? SemanticColors.surfaceVariant
                : _isHovered
                  ? SemanticColors.surfaceVariant.withOpacity(0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isActive || _isHovered
                    ? SemanticColors.primary
                    : SemanticColors.onSurfaceVariant,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  widget.text,
                  style: TextStyles.navButton.copyWith(
                    color: widget.isActive || _isHovered
                      ? SemanticColors.primary
                      : SemanticColors.onSurfaceVariant,
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