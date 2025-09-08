import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/theme_colors.dart';

// Card component matching your existing style
class AsmblCard extends StatefulWidget {
 final Widget child;
 final VoidCallback? onTap;
 final EdgeInsetsGeometry? padding;
 final bool isInteractive;

 const AsmblCard({
 super.key,
 required this.child,
 this.onTap,
 this.padding,
 this.isInteractive = true,
 });

 @override
 State<AsmblCard> createState() => _AsmblCardState();
}

class _AsmblCardState extends State<AsmblCard> {
 bool _isHovered = false;

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 final hasInteraction = widget.onTap != null && widget.isInteractive;
 final effectivePadding = widget.padding ?? const EdgeInsets.all(SpacingTokens.cardPadding);

 Widget card = Container(
 decoration: BoxDecoration(
 color: hasInteraction && _isHovered 
 ? colors.surfaceVariant
 : colors.surface,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
 border: Border.all(
 color: colors.border.withValues(alpha: 0.5),
 ),
 ),
 child: Material(
 color: Colors.transparent,
 child: hasInteraction
 ? InkWell(
 onTap: widget.onTap,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
 hoverColor: Colors.transparent,
 splashColor: colors.primary.withValues(alpha: 0.1),
 child: Padding(
 padding: effectivePadding,
 child: widget.child,
 ),
 )
 : Padding(
 padding: effectivePadding,
 child: widget.child,
 ),
 ),
 );

 if (hasInteraction) {
 return MouseRegion(
 onEnter: (_) => setState(() => _isHovered = true),
 onExit: (_) => setState(() => _isHovered = false),
 child: card,
 );
 }

 return card;
 }
}

// Stats card matching your existing aesthetic
class AsmblStatsCard extends StatelessWidget {
 final String title;
 final String value;
 final IconData icon;
 final VoidCallback? onTap;

 const AsmblStatsCard({
 super.key,
 required this.title,
 required this.value,
 required this.icon,
 this.onTap,
 });

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 return AsmblCard(
 onTap: onTap,
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 icon,
 size: 32,
 color: colors.primary,
 ),
 const SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 value,
 style: TextStyle(
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.xs_precise),
 Text(
 title,
 style: TextStyle(
 color: colors.onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 ],
 ),
 );
 }
}