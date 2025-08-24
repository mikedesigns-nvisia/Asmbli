import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/theme_colors.dart';

// Button component matching your existing AppTheme button style
class AsmblButton extends StatefulWidget {
 final String text;
 final IconData? icon;
 final VoidCallback? onPressed;
 final bool isPrimary;
 final bool isLoading;
 final bool isFullWidth;

 const AsmblButton({
 super.key,
 required this.text,
 this.icon,
 this.onPressed,
 this.isPrimary = true,
 this.isLoading = false,
 this.isFullWidth = false,
 });

 const AsmblButton.primary({
 super.key,
 required this.text,
 this.icon,
 this.onPressed,
 this.isLoading = false,
 this.isFullWidth = false,
 }) : isPrimary = true;

 const AsmblButton.secondary({
 super.key,
 required this.text,
 this.icon,
 this.onPressed,
 this.isLoading = false,
 this.isFullWidth = false,
 }) : isPrimary = false;

 @override
 State<AsmblButton> createState() => _AsmblButtonState();
}

class _AsmblButtonState extends State<AsmblButton> {
 bool _isHovered = false;
 bool _isPressed = false;

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 final isDisabled = widget.onPressed == null;
 
 // Colors based on your existing theme
 final backgroundColor = widget.isPrimary
 ? (isDisabled 
 ? colors.onSurfaceVariant
 : _isPressed
 ? colors.primary.withValues(alpha: 0.9)
 : _isHovered
 ? colors.primary.withValues(alpha: 0.95)
 : colors.primary)
 : Colors.transparent;
 
 final foregroundColor = widget.isPrimary
 ? colors.onPrimary
 : (isDisabled 
 ? colors.onSurfaceVariant
 : colors.primary);
 
 final borderColor = widget.isPrimary 
 ? Colors.transparent 
 : colors.border;

 Widget content = widget.isLoading
 ? SizedBox(
 width: 16,
 height: 16,
 child: CircularProgressIndicator(
 strokeWidth: 2,
 valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
 ),
 )
 : Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 if (widget.icon != null) ...[
 Icon(
 widget.icon,
 size: 16,
 color: foregroundColor,
 ),
 SizedBox(width: SpacingTokens.iconSpacing),
 ],
 Text(
 widget.text,
 style: TextStyles.button.copyWith(
 color: foregroundColor,
 ),
 ),
 ],
 );

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
 borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
 hoverColor: Colors.transparent,
 splashColor: Colors.transparent,
 highlightColor: Colors.transparent,
 child: AnimatedContainer(
 duration: Duration(milliseconds: 150),
 width: widget.isFullWidth ? double.infinity : null,
 padding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.buttonPadding,
 vertical: SpacingTokens.buttonPaddingVertical,
 ),
 decoration: BoxDecoration(
 color: backgroundColor,
 border: borderColor != Colors.transparent 
 ? Border.all(color: borderColor)
 : null,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
 ),
 child: content,
 ),
 ),
 ),
 );
 }
}