import 'package:flutter/material.dart';

/// A card component that matches the web app's design system
/// Uses theme colors and Fustat typography
class AsmblCard extends StatelessWidget {
 final Widget? child;
 final EdgeInsetsGeometry? padding;
 final double? elevation;
 final BorderRadius? borderRadius;
 final Color? backgroundColor;
 final Border? border;
 final VoidCallback? onTap;
 final bool isSelected;
 final Widget? header;
 final Widget? action;
 final Widget? footer;

 const AsmblCard({
 super.key,
 this.child,
 this.padding = const EdgeInsets.all(24),
 this.elevation,
 this.borderRadius,
 this.backgroundColor,
 this.border,
 this.onTap,
 this.isSelected = false,
 this.header,
 this.action,
 this.footer,
 });

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final colorScheme = theme.colorScheme;
 
 // Default styling to match web design
 final effectiveElevation = elevation ?? (isSelected ? 4 : 2);
 final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);
 final effectiveBackgroundColor = backgroundColor ?? 
 (isSelected 
 ? colorScheme.primary.withOpacity( 0.05)
 : colorScheme.surface);

 Widget cardContent = Container(
 decoration: BoxDecoration(
 color: effectiveBackgroundColor,
 borderRadius: effectiveBorderRadius,
 border: border ?? 
 (isSelected 
 ? Border.all(color: colorScheme.primary.withOpacity( 0.3))
 : Border.all(color: colorScheme.outline.withOpacity( 0.2))),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withOpacity( 0.08),
 blurRadius: effectiveElevation * 2,
 offset: Offset(0, effectiveElevation),
 ),
 ],
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: [
 if (header != null || action != null)
 Container(
 padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 if (header != null) Expanded(child: header!),
 if (action != null) action!,
 ],
 ),
 ),
 if (child != null)
 Padding(
 padding: padding!,
 child: child!,
 ),
 if (footer != null)
 Container(
 padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
 child: footer!,
 ),
 ],
 ),
 );

 if (onTap != null) {
 return Material(
 color: Colors.transparent,
 child: InkWell(
 onTap: onTap,
 borderRadius: effectiveBorderRadius,
 hoverColor: colorScheme.primary.withOpacity( 0.04),
 splashColor: colorScheme.primary.withOpacity( 0.12),
 child: cardContent,
 ),
 );
 }

 return cardContent;
 }
}

/// Card header component
class AsmblCardHeader extends StatelessWidget {
 final Widget? title;
 final Widget? description;
 final Widget? action;

 const AsmblCardHeader({
 super.key,
 this.title,
 this.description,
 this.action,
 });

 @override
 Widget build(BuildContext context) {
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: [
 if (title != null) title!,
 if (description != null) ...[
 const SizedBox(height: 6),
 description!,
 ],
 ],
 );
 }
}

/// Card title component
class AsmblCardTitle extends StatelessWidget {
 final String text;
 final TextStyle? style;

 const AsmblCardTitle({
 super.key,
 required this.text,
 this.style,
 });

 @override
 Widget build(BuildContext context) {
 return Text(
 text,
 style: style ?? Theme.of(context).textTheme.titleLarge?.copyWith(
 fontWeight: FontWeight.w600,
  ),
 );
 }
}

/// Card description component
class AsmblCardDescription extends StatelessWidget {
 final String text;
 final TextStyle? style;

 const AsmblCardDescription({
 super.key,
 required this.text,
 this.style,
 });

 @override
 Widget build(BuildContext context) {
 return Text(
 text,
 style: style ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
 color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.7),
  ),
 );
 }
}

/// Selection card for wizard steps and options
class AsmblSelectionCard extends StatelessWidget {
 final String title;
 final String? description;
 final Widget? icon;
 final bool isSelected;
 final VoidCallback? onTap;
 final Widget? trailing;

 const AsmblSelectionCard({
 super.key,
 required this.title,
 this.description,
 this.icon,
 this.isSelected = false,
 this.onTap,
 this.trailing,
 });

 @override
 Widget build(BuildContext context) {
 return AsmblCard(
 isSelected: isSelected,
 onTap: onTap,
 child: Row(
 children: [
 if (icon != null) ...[
 icon!,
 const SizedBox(width: 16),
 ],
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: [
 AsmblCardTitle(text: title),
 if (description != null) ...[
 const SizedBox(height: 4),
 AsmblCardDescription(text: description!),
 ],
 ],
 ),
 ),
 if (trailing != null) ...[
 const SizedBox(width: 16),
 trailing!,
 ],
 ],
 ),
 );
 }
}