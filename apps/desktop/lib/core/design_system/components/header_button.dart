import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/theme_colors.dart';

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
 bool _isPressed = false;

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 return MouseRegion(
 onEnter: (_) => setState(() => _isHovered = true),
 onExit: (_) => setState(() => _isHovered = false),
 child: Material(
 color: Colors.transparent,
 child: InkWell(
 onTap: widget.onPressed,
 onTapDown: (_) => setState(() => _isPressed = true),
 onTapUp: (_) => setState(() => _isPressed = false),
 onTapCancel: () => setState(() => _isPressed = false),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 hoverColor: Colors.transparent,
 splashColor: Colors.transparent,
 highlightColor: Colors.transparent,
 child: AnimatedContainer(
 duration: const Duration(milliseconds: 150),
 padding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.md,
 vertical: SpacingTokens.sm,
 ),
 decoration: BoxDecoration(
 color: widget.isActive
 ? colors.accent.withOpacity( 0.12)
 : _isPressed
 ? colors.accent.withOpacity( 0.1)
 : _isHovered
 ? colors.accent.withOpacity( 0.06)
 : Colors.transparent,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 border: widget.isActive ? Border.all(
 color: colors.accent.withOpacity( 0.3),
 width: 1.0,
 ) : null,
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 widget.icon,
 size: 16,
 color: widget.isActive || _isHovered || _isPressed
 ? colors.accent
 : colors.onSurfaceVariant,
 ),
 const SizedBox(width: SpacingTokens.sm),
 Text(
 widget.text,
 style: TextStyle(
 color: widget.isActive || _isHovered || _isPressed
 ? colors.accent
 : colors.onSurfaceVariant,
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