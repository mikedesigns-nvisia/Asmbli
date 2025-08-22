import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/theme_colors.dart';

/// Enhanced card component with professional styling and outlines
class AsmblCardEnhanced extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isInteractive;
  final AsmblCardVariant variant;
  final bool hasBorder;
  final bool hasElevation;
  final EdgeInsets? padding;
  final double? borderRadius;

  const AsmblCardEnhanced({
    super.key,
    required this.child,
    this.onTap,
    this.isInteractive = true,
    this.variant = AsmblCardVariant.surface,
    this.hasBorder = true,
    this.hasElevation = false,
    this.padding,
    this.borderRadius,
  });

  factory AsmblCardEnhanced.elevated({
    required Widget child,
    VoidCallback? onTap,
    bool isInteractive = true,
    EdgeInsets? padding,
    double? borderRadius,
  }) {
    return AsmblCardEnhanced(
      child: child,
      onTap: onTap,
      isInteractive: isInteractive,
      variant: AsmblCardVariant.elevated,
      hasBorder: false,
      hasElevation: true,
      padding: padding,
      borderRadius: borderRadius,
    );
  }

  factory AsmblCardEnhanced.accent({
    required Widget child,
    VoidCallback? onTap,
    bool isInteractive = true,
    EdgeInsets? padding,
    double? borderRadius,
  }) {
    return AsmblCardEnhanced(
      child: child,
      onTap: onTap,
      isInteractive: isInteractive,
      variant: AsmblCardVariant.accent,
      hasBorder: true,
      hasElevation: false,
      padding: padding,
      borderRadius: borderRadius,
    );
  }

  factory AsmblCardEnhanced.outlined({
    required Widget child,
    VoidCallback? onTap,
    bool isInteractive = true,
    EdgeInsets? padding,
    double? borderRadius,
  }) {
    return AsmblCardEnhanced(
      child: child,
      onTap: onTap,
      isInteractive: isInteractive,
      variant: AsmblCardVariant.outlined,
      hasBorder: true,
      hasElevation: false,
      padding: padding,
      borderRadius: borderRadius,
    );
  }

  @override
  State<AsmblCardEnhanced> createState() => _AsmblCardEnhancedState();
}

class _AsmblCardEnhancedState extends State<AsmblCardEnhanced>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.995,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final isClickable = widget.onTap != null && widget.isInteractive;

    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: widget.padding ?? const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: _getBackgroundColor(colors),
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? 12.0,
        ),
        border: widget.hasBorder
            ? Border.all(
                color: _getBorderColor(colors),
                width: _getBorderWidth(),
              )
            : null,
        boxShadow: _getShadow(colors),
      ),
      child: widget.child,
    );

    if (!isClickable) {
      return cardContent;
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _animationController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: cardContent,
            );
          },
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeColors colors) {
    switch (widget.variant) {
      case AsmblCardVariant.surface:
        if (_isPressed) return colors.surfaceVariant.withOpacity(0.8);
        if (_isHovered) return colors.surfaceVariant.withOpacity(0.6);
        return colors.surface;
      
      case AsmblCardVariant.elevated:
        if (_isPressed) return colors.surface.withOpacity(0.95);
        if (_isHovered) return colors.surface;
        return colors.surface;
      
      case AsmblCardVariant.accent:
        if (_isPressed) return colors.accent.withOpacity(0.1);
        if (_isHovered) return colors.accent.withOpacity(0.08);
        return colors.accent.withOpacity(0.05);
      
      case AsmblCardVariant.outlined:
        if (_isPressed) return colors.surfaceVariant.withOpacity(0.3);
        if (_isHovered) return colors.surfaceVariant.withOpacity(0.2);
        return Colors.transparent;
    }
  }

  Color _getBorderColor(ThemeColors colors) {
    switch (widget.variant) {
      case AsmblCardVariant.surface:
        if (_isHovered) return colors.border.withOpacity(0.8);
        return colors.border.withOpacity(0.6);
      
      case AsmblCardVariant.accent:
        if (_isHovered) return colors.accent.withOpacity(0.8);
        return colors.accent.withOpacity(0.4);
      
      case AsmblCardVariant.outlined:
        if (_isHovered) return colors.accent.withOpacity(0.6);
        return colors.border;
      
      case AsmblCardVariant.elevated:
        return colors.border.withOpacity(0.3);
    }
  }

  double _getBorderWidth() {
    if (_isHovered && widget.variant == AsmblCardVariant.accent) {
      return 2.0;
    }
    return 1.0;
  }

  List<BoxShadow>? _getShadow(ThemeColors colors) {
    if (!widget.hasElevation && !_isHovered) {
      return null;
    }

    switch (widget.variant) {
      case AsmblCardVariant.elevated:
        return [
          BoxShadow(
            color: colors.primary.withOpacity(0.08),
            blurRadius: _isHovered ? 16 : 8,
            offset: Offset(0, _isHovered ? 4 : 2),
          ),
          BoxShadow(
            color: colors.primary.withOpacity(0.04),
            blurRadius: _isHovered ? 32 : 16,
            offset: Offset(0, _isHovered ? 8 : 4),
          ),
        ];
      
      case AsmblCardVariant.accent:
        if (_isHovered) {
          return [
            BoxShadow(
              color: colors.accent.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];
        }
        return null;
      
      default:
        if (_isHovered) {
          return [
            BoxShadow(
              color: colors.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];
        }
        return null;
    }
  }
}

enum AsmblCardVariant {
  surface,
  elevated,
  accent,
  outlined,
}