import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/theme_colors.dart';

/// Enhanced button component with accent color and professional styling
class AsmblButtonEnhanced extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AsmblButtonVariant variant;
  final AsmblButtonSize size;
  final bool isLoading;
  final bool hasBorder;
  final Widget? suffix;

  const AsmblButtonEnhanced({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.variant = AsmblButtonVariant.primary,
    this.size = AsmblButtonSize.medium,
    this.isLoading = false,
    this.hasBorder = false,
    this.suffix,
  });

  // Factory constructors for common variants
  factory AsmblButtonEnhanced.primary({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    AsmblButtonSize size = AsmblButtonSize.medium,
    bool isLoading = false,
    Widget? suffix,
  }) {
    return AsmblButtonEnhanced(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AsmblButtonVariant.primary,
      size: size,
      isLoading: isLoading,
      suffix: suffix,
    );
  }

  factory AsmblButtonEnhanced.accent({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    AsmblButtonSize size = AsmblButtonSize.medium,
    bool isLoading = false,
    Widget? suffix,
  }) {
    return AsmblButtonEnhanced(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AsmblButtonVariant.accent,
      size: size,
      isLoading: isLoading,
      suffix: suffix,
    );
  }

  factory AsmblButtonEnhanced.secondary({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    AsmblButtonSize size = AsmblButtonSize.medium,
    bool isLoading = false,
    Widget? suffix,
  }) {
    return AsmblButtonEnhanced(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AsmblButtonVariant.secondary,
      size: size,
      isLoading: isLoading,
      hasBorder: true,
      suffix: suffix,
    );
  }

  factory AsmblButtonEnhanced.outline({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    AsmblButtonSize size = AsmblButtonSize.medium,
    bool isLoading = false,
    Widget? suffix,
  }) {
    return AsmblButtonEnhanced(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AsmblButtonVariant.outline,
      size: size,
      isLoading: isLoading,
      hasBorder: true,
      suffix: suffix,
    );
  }

  @override
  State<AsmblButtonEnhanced> createState() => _AsmblButtonEnhancedState();
}

class _AsmblButtonEnhancedState extends State<AsmblButtonEnhanced>
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
      end: 0.98,
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
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return MouseRegion(
      onEnter: (_) {
        if (isEnabled) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (isEnabled) {
            setState(() => _isPressed = true);
            _animationController.forward();
          }
        },
        onTapUp: (_) {
          if (isEnabled) {
            setState(() => _isPressed = false);
            _animationController.reverse();
          }
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: _getPadding(),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(colors),
                  borderRadius: BorderRadius.circular(_getBorderRadius()),
                  border: widget.hasBorder || widget.variant == AsmblButtonVariant.outline
                      ? Border.all(
                          color: _getBorderColor(colors),
                          width: _getBorderWidth(),
                        )
                      : null,
                  boxShadow: _getShadow(colors),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isLoading) ...[
                      SizedBox(
                        width: _getIconSize(),
                        height: _getIconSize(),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getTextColor(colors),
                          ),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                    ] else if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: _getIconSize(),
                        color: _getTextColor(colors),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                    ],
                    Text(
                      widget.text,
                      style: _getTextStyle(colors),
                    ),
                    if (widget.suffix != null) ...[
                      const SizedBox(width: SpacingTokens.sm),
                      widget.suffix!,
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case AsmblButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        );
      case AsmblButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: SpacingTokens.lg,
          vertical: SpacingTokens.sm,
        );
      case AsmblButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: SpacingTokens.xl,
          vertical: SpacingTokens.md,
        );
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case AsmblButtonSize.small:
        return 6.0;
      case AsmblButtonSize.medium:
        return 8.0;
      case AsmblButtonSize.large:
        return 10.0;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case AsmblButtonSize.small:
        return 14.0;
      case AsmblButtonSize.medium:
        return 16.0;
      case AsmblButtonSize.large:
        return 18.0;
    }
  }

  double _getBorderWidth() {
    return _isHovered ? 2.0 : 1.5;
  }

  Color _getBackgroundColor(ThemeColors colors) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    if (!isEnabled) {
      return colors.surfaceVariant.withOpacity(0.5);
    }

    switch (widget.variant) {
      case AsmblButtonVariant.primary:
        if (_isPressed) return colors.primary.withOpacity(0.9);
        if (_isHovered) return colors.primary.withOpacity(0.95);
        return colors.primary;
      
      case AsmblButtonVariant.accent:
        if (_isPressed) return colors.accent.withOpacity(0.9);
        if (_isHovered) return colors.accent.withOpacity(0.95);
        return colors.accent;
      
      case AsmblButtonVariant.secondary:
        if (_isPressed) return colors.surfaceVariant.withOpacity(0.8);
        if (_isHovered) return colors.surfaceVariant.withOpacity(0.6);
        return colors.surfaceVariant.withOpacity(0.4);
      
      case AsmblButtonVariant.outline:
        if (_isPressed) return colors.accent.withOpacity(0.1);
        if (_isHovered) return colors.accent.withOpacity(0.05);
        return Colors.transparent;
    }
  }

  Color _getBorderColor(ThemeColors colors) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    if (!isEnabled) {
      return colors.border.withOpacity(0.5);
    }

    switch (widget.variant) {
      case AsmblButtonVariant.outline:
        if (_isHovered) return colors.accent;
        return colors.border;
      
      case AsmblButtonVariant.secondary:
        if (_isHovered) return colors.accent.withOpacity(0.6);
        return colors.border;
      
      default:
        return colors.border;
    }
  }

  Color _getTextColor(ThemeColors colors) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    if (!isEnabled) {
      return colors.onSurfaceVariant.withOpacity(0.5);
    }

    switch (widget.variant) {
      case AsmblButtonVariant.primary:
        return colors.onPrimary;
      
      case AsmblButtonVariant.accent:
        return colors.onAccent;
      
      case AsmblButtonVariant.secondary:
      case AsmblButtonVariant.outline:
        return colors.onSurface;
    }
  }

  TextStyle _getTextStyle(ThemeColors colors) {
    final baseStyle = widget.size == AsmblButtonSize.small
        ? TextStyles.bodySmall
        : widget.size == AsmblButtonSize.large
            ? TextStyles.bodyLarge
            : TextStyles.bodyMedium;

    return baseStyle.copyWith(
      color: _getTextColor(colors),
      fontWeight: FontWeight.w600,
    );
  }

  List<BoxShadow>? _getShadow(ThemeColors colors) {
    if (!_isHovered || widget.variant == AsmblButtonVariant.outline) {
      return null;
    }

    return [
      BoxShadow(
        color: colors.primary.withOpacity(0.15),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

enum AsmblButtonVariant {
  primary,
  accent,
  secondary,
  outline,
}

enum AsmblButtonSize {
  small,
  medium,
  large,
}