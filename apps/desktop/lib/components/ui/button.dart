import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AsmblButtonVariant {
 primary, // Default - banana pudding primary color
 secondary, // Outlined style
 ghost, // Text-only style
 destructive, // Error/danger style
}

enum AsmblButtonSize {
 small,
 medium,
 large,
}

/// A button component that matches the web app's design system
/// Uses theme colors and Fustat typography
class AsmblButton extends StatelessWidget {
 final String? text;
 final Widget? child;
 final VoidCallback? onPressed;
 final AsmblButtonVariant variant;
 final AsmblButtonSize size;
 final IconData? leadingIcon;
 final IconData? trailingIcon;
 final bool isLoading;
 final double? width;

 const AsmblButton({
 super.key,
 this.text,
 this.child,
 required this.onPressed,
 this.variant = AsmblButtonVariant.primary,
 this.size = AsmblButtonSize.medium,
 this.leadingIcon,
 this.trailingIcon,
 this.isLoading = false,
 this.width,
 }) : assert(text != null || child != null, 'Either text or child must be provided');

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final colorScheme = theme.colorScheme;
 
 // Size configurations
 final (height, horizontalPadding, fontSize) = switch (size) {
 AsmblButtonSize.small => (32.0, 12.0, 12.0),
 AsmblButtonSize.medium => (40.0, 16.0, 14.0),
 AsmblButtonSize.large => (48.0, 24.0, 16.0),
 };

 // Variant configurations
 final (backgroundColor, foregroundColor, borderColor) = switch (variant) {
 AsmblButtonVariant.primary => (
 colorScheme.primary,
 colorScheme.onPrimary,
 Colors.transparent,
 ),
 AsmblButtonVariant.secondary => (
 Colors.transparent,
 colorScheme.primary,
 colorScheme.outline,
 ),
 AsmblButtonVariant.ghost => (
 Colors.transparent,
 colorScheme.onSurface,
 Colors.transparent,
 ),
 AsmblButtonVariant.destructive => (
 colorScheme.error,
 colorScheme.onError,
 Colors.transparent,
 ),
 };

 Widget buttonChild;
 if (isLoading) {
 buttonChild = SizedBox(
 height: 16,
 width: 16,
 child: CircularProgressIndicator(
 strokeWidth: 2,
 valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
 ),
 );
 } else {
 List<Widget> rowChildren = [];
 
 if (leadingIcon != null) {
 rowChildren.add(Icon(leadingIcon, size: 16));
 rowChildren.add(const SizedBox(width: 8));
 }
 
 rowChildren.add(
 child ?? Text(
 text!,
 style: GoogleFonts.fustat(
 fontSize: fontSize,
 fontWeight: FontWeight.w500,
 color: foregroundColor,
 ),
 ),
 );
 
 if (trailingIcon != null) {
 rowChildren.add(const SizedBox(width: 8));
 rowChildren.add(Icon(trailingIcon, size: 16));
 }

 buttonChild = Row(
 mainAxisSize: MainAxisSize.min,
 mainAxisAlignment: MainAxisAlignment.center,
 children: rowChildren,
 );
 }

 Widget button = AnimatedContainer(
 duration: const Duration(milliseconds: 200),
 height: height,
 width: width,
 decoration: BoxDecoration(
 color: onPressed == null ? backgroundColor.withValues(alpha: 0.5) : backgroundColor,
 border: borderColor != Colors.transparent 
 ? Border.all(color: borderColor) 
 : null,
 borderRadius: BorderRadius.circular(8),
 boxShadow: variant == AsmblButtonVariant.primary && onPressed != null
 ? [
 BoxShadow(
 color: backgroundColor.withValues(alpha: 0.3),
 blurRadius: 4,
 offset: const Offset(0, 2),
 ),
 ]
 : null,
 ),
 child: Material(
 color: Colors.transparent,
 child: InkWell(
 onTap: onPressed,
 borderRadius: BorderRadius.circular(8),
 hoverColor: foregroundColor.withValues(alpha: 0.08),
 splashColor: foregroundColor.withValues(alpha: 0.16),
 child: Container(
 padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
 child: Center(child: buttonChild),
 ),
 ),
 ),
 );

 return button;
 }
}

/// Primary button - matches web's main CTA buttons
class AsmblPrimaryButton extends StatelessWidget {
 final String text;
 final VoidCallback? onPressed;
 final IconData? icon;
 final bool isLoading;
 final AsmblButtonSize size;
 final double? width;

 const AsmblPrimaryButton({
 super.key,
 required this.text,
 required this.onPressed,
 this.icon,
 this.isLoading = false,
 this.size = AsmblButtonSize.medium,
 this.width,
 });

 @override
 Widget build(BuildContext context) {
 return AsmblButton(
 text: text,
 onPressed: onPressed,
 variant: AsmblButtonVariant.primary,
 size: size,
 leadingIcon: icon,
 isLoading: isLoading,
 width: width,
 );
 }
}

/// Secondary button - matches web's outline buttons
class AsmblSecondaryButton extends StatelessWidget {
 final String text;
 final VoidCallback? onPressed;
 final IconData? icon;
 final AsmblButtonSize size;
 final double? width;

 const AsmblSecondaryButton({
 super.key,
 required this.text,
 required this.onPressed,
 this.icon,
 this.size = AsmblButtonSize.medium,
 this.width,
 });

 @override
 Widget build(BuildContext context) {
 return AsmblButton(
 text: text,
 onPressed: onPressed,
 variant: AsmblButtonVariant.secondary,
 size: size,
 leadingIcon: icon,
 width: width,
 );
 }
}

/// Ghost button - matches web's text-only buttons
class AsmblGhostButton extends StatelessWidget {
 final String text;
 final VoidCallback? onPressed;
 final IconData? icon;
 final AsmblButtonSize size;

 const AsmblGhostButton({
 super.key,
 required this.text,
 required this.onPressed,
 this.icon,
 this.size = AsmblButtonSize.medium,
 });

 @override
 Widget build(BuildContext context) {
 return AsmblButton(
 text: text,
 onPressed: onPressed,
 variant: AsmblButtonVariant.ghost,
 size: size,
 leadingIcon: icon,
 );
 }
}